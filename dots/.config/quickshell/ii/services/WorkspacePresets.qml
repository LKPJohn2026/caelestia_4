pragma Singleton

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

/**
 * caelestia4: a preset per workspace (Nexus > Wallpaper & style > Presets, background.workspacePresets). A preset
 * applied is the focused workspace's (scripts/presets/preset-import.py keeps preset-workspaces.json), and switching to
 * a workspace applies its preset again: wallpaper, widgets, colours and lock screen, all of it. Colours take a few
 * seconds, so a run of switches applies only the workspace landed on. Widgets and colours are the whole desktop's: the
 * focused screen's workspace decides. A workspace without a preset keeps the one on.
 */
Singleton {
    id: root

    readonly property bool enabled: Config.options.background.workspacePresets
    readonly property string script: FileUtils.trimFileProtocol(`${Directories.scriptPath}/presets/preset-import.py`)
    readonly property string stateDir: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia4`
    // a special workspace is never a monitor's active one: under it, the workspace beneath keeps its preset
    readonly property string focused: Hyprland.focusedMonitor?.activeWorkspace?.name ?? ""
    property var presets: ({}) // workspace -> preset
    property string current // the preset on now

    // The workspace whose preset is going on, until the shell has followed it: the wallpaper it sets is that
    // workspace's (Wallpapers.qml), though the focus may have moved on by then
    property string applyingFor
    property string failed // "workspace|preset" the script failed on: not tried on every switch back

    function load(): void {
        // started with the shell (shell.qml): a singleton is made when first used
    }

    onFocusedChanged: settle.restart()
    onEnabledChanged: settle.restart()
    onPresetsChanged: {
        failed = ""; // a preset given again is tried again
        settle.restart();
    }

    Timer {
        id: settle

        interval: 400 // workspaces flicked through: only the last
        onTriggered: root.check()
    }

    function check(): void {
        if (!enabled || !focused)
            return;
        const preset = presets[focused];
        if (!preset || preset === current || failed === `${focused}|${preset}`)
            return;
        if (applyProc.running || PresetLayout.busy) {
            // after the one going on, or after a widget just moved is saved into the preset it was moved on
            PresetLayout.flush();
            retry.start();
            return;
        }
        applyingFor = focused;
        applyProc.command = ["python3", script, "--workspace", focused];
        applyProc.preset = preset;
        applyProc.running = true;
    }

    // Asked again while something else holds the presets' lock: soon, then less often (an update of the presets
    // holds it for minutes)
    Timer {
        id: retry

        property int tries

        function start(): void {
            interval = Math.min(5000, 300 * Math.pow(2, tries));
            tries++;
            restart();
        }

        onTriggered: root.check()
    }

    Process {
        id: applyProc

        property string preset

        onExited: code => {
            if (code === 75) {
                root.applyingFor = ""; // nothing done: the wallpapers picked meanwhile are the focused workspace's
                retry.start(); // another apply held the lock (Nexus, a key, an update): asked again after it
                return;
            }
            retry.tries = 0;
            following.restart();
            if (code !== 0) {
                root.failed = `${root.applyingFor}|${preset}`;
                console.warn(`WorkspacePresets: ${preset} on workspace ${root.applyingFor} failed (exit ${code})`);
            } else {
                root.current = preset; // before the file watch has it: not applied twice
            }
            root.check(); // switched again meanwhile
        }
    }

    Timer {
        id: following

        interval: 1500 // the config and wallpaper reloads land after the script is done
        onTriggered: {
            if (!applyProc.running)
                root.applyingFor = "";
        }
    }

    FileView {
        path: `${root.stateDir}/preset-workspaces.json`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const mapping = JSON.parse(text());
                root.presets = mapping && typeof mapping === "object" ? mapping : {};
            } catch (e) {
                // half written: the next change brings it whole
            }
        }
        onLoadFailed: root.presets = {}
    }

    FileView {
        path: `${root.stateDir}/preset-current`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
        onLoadFailed: root.current = ""
    }
}
