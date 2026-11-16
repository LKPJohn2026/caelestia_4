import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: the shortcuts for KeybindsPage, from scripts/caelestia4/nexus-keybinds.py (it reads keybinds.lua and
// custom/keybinds.lua, never writes them; changes go to ~/.config/hypr/custom/nexus-keybinds.lua). Each change is one
// call of the script, which reloads Hyprland; Undo puts the saved state from before back
QtObject {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/caelestia4/nexus-keybinds.py")
    property var shortcuts: []
    property bool loaded
    // false: hyprland.lua does not load nexus-keybinds.lua (dotfiles older than this page): changes are saved but do
    // nothing until it does
    property bool sourced: true
    // caelestia4: changes take effect: Hyprland runs a Lua config that loads nexus-keybinds.lua. Without it, waiting for
    // keys would let the pressed shortcut act on the desktop, and saving would do nothing
    readonly property bool canApply: sourced && Hypr.usingLua
    property bool fileExists
    property string error
    readonly property int changedCount: shortcuts.filter(s => s.status === "changed" || s.status === "disabled" || s.status === "added").length

    // Every capture or list refresh after a change
    signal changed

    function reload(): void {
        listProc.running = false;
        listProc.running = true;
    }

    // A shortcut by id, or null
    function byId(id: string): var {
        return root.shortcuts.find(s => s.id === id) ?? null;
    }

    // The working shortcut that already uses `keys` (other than `exceptId`), or null. caelestia4: only one that works at
    // the same time: in `submap`, or in every submap (universal); a digit's key-code twin counts as its digit's keys
    function conflict(keys: string, exceptId: string, names: KeyNames, submap: string, universal: bool): var {
        const n = names.norm(keys);
        return root.shortcuts.find(s => s.id !== exceptId && s.status !== "disabled" && !s.internal && ((s.submap ?? "") === submap || !!s.universal || universal) && (names.norm(s.currentKeys) === n || (!!s.twinKeys && s.status !== "changed" && names.norm(s.twinKeys) === n))) ?? null;
    }

    // Runs the script with `args`, records an undo step named `label`, then lists again
    function run(label: string, args: var): void {
        stateProc.label = label;
        stateProc.then = args;
        stateProc.running = true;
    }

    function setState(json: string): void {
        _write(["set-state", json]);
    }

    function _write(args: var): void {
        const p = writeComp.createObject(root, {
            command: ["python3", root.script, "--reload", ...args]
        });
        p.running = true;
    }

    // Before Nexus waits for keys: the file must exist, as it defines the empty submap that keeps shortcuts off
    function ensureFile(): void {
        if (!root.fileExists)
            _write(["ensure"]);
    }

    readonly property Process listProc: Process {
        command: ["python3", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.shortcuts = d.shortcuts ?? [];
                    root.sourced = !!d.sourced;
                    root.fileExists = !!d.fileExists;
                    root.error = (d.errors ?? []).join("\n");
                } catch (e) {
                    root.error = String(e);
                }
                root.loaded = true;
                root.changed();
            }
        }
    }

    // Reads the saved state first, so the change can be undone
    readonly property Process stateProc: Process {
        property string label
        property var then: []

        command: ["python3", root.script, "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                const before = text.trim();
                const label = root.stateProc.label;
                root._write(root.stateProc.then);
                const step = NexusActions.record(label, () => root.setState(before));
                NexusActions.message(label, step ? Tr.trCtx("Undo", "snackbar button") : "", step ? () => NexusActions.undoStep(step) : null);
            }
        }
    }

    readonly property Component writeComp: Component {
        Process {
            id: wp

            onExited: {
                root.reload();
                wp.destroy();
            }
        }
    }

    // Hyprland reloaded (a change here, or the user's own edit of keybinds.lua)
    readonly property Connections hyprReload: Connections {
        function onConfigReloaded(): void {
            root.reload();
        }

        target: Hypr
    }

    Component.onCompleted: reload()
}
