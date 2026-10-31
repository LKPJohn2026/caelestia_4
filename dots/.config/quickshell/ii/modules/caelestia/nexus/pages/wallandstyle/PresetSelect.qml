pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: end4-pC presets (Blapples/wallpapers): a wallpaper, desktop widgets, a lock screen wallpaper and an
// avatar each, applied by scripts/presets/preset-import.py, which keeps a backup for Undo
PageBase {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/presets/preset-import.py")
    property var presets: []
    property string current
    property bool canUndo
    property string status
    property string doneStatus

    // label while it runs (the script's own lines follow), done once it exits
    function run(args: list<string>, label: string, done: string): void {
        if (runProc.running)
            return;
        root.status = label;
        root.doneStatus = done;
        runProc.command = [root.script, ...args];
        runProc.running = true;
    }

    title: Tr.tr("Presets")
    isSubPage: true

    Component.onCompleted: listProc.running = true

    // Properties: PageBase's default property takes the page's one content item
    readonly property Process listProc: Process {
        command: [root.script, "--list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.presets = d.presets;
                    root.current = d.current;
                    root.canUndo = d.canUndo;
                } catch (e) {
                    root.presets = [];
                }
            }
        }
    }

    readonly property Process runProc: Process {
        stdout: SplitParser {
            onRead: data => root.status = data.trim()
        }
        onExited: code => {
            root.status = code === 0 ? root.doneStatus : Tr.tr("Failed (exit code %1)").arg(code);
            root.listProc.running = true;
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        RowButton {
            first: true
            disabled: root.runProc.running
            icon: root.runProc.running ? "hourglass_top" : "cloud_sync"
            text: root.presets.length > 0 ? Tr.tr("Update presets") : Tr.tr("Get presets")
            subtext: root.status || Tr.tr("From Blapples/wallpapers on GitHub, with all its wallpapers; pictures stay on this computer")
            onClicked: root.run(["--sync"], Tr.tr("Downloading…"), Tr.tr("Presets and wallpapers are up to date"))
        }

        RowButton {
            last: true
            disabled: root.runProc.running || !root.canUndo
            icon: "undo"
            text: Tr.tr("Undo the last preset")
            subtext: Tr.tr("Back to the wallpaper, widgets and lock screen from before it")
            onClicked: root.run(["--undo"], Tr.tr("Restoring…"), Tr.tr("Restored"))
        }

        SectionHeader {
            visible: root.presets.length > 0
            // TRANSLATORS: %1 = how many presets are installed
            text: Tr.tr("%1 presets: click one to apply it").arg(root.presets.length)
        }

        GridLayout {
            Layout.fillWidth: true

            columns: Math.max(1, Config.nexus.wallpapersPerRow - 1)
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                model: root.presets

                WallItem {
                    required property var modelData

                    imgHeight: width * 9 / 16
                    enabled: !root.runProc.running
                    opacity: enabled ? 1 : 0.6
                    source: modelData.preview
                    text: modelData.name === root.current ? "✓ " + modelData.name : modelData.name
                    onClicked: root.run([modelData.name], Tr.tr("Applying %1…").arg(modelData.name), Tr.tr("Applied %1").arg(modelData.name))
                }
            }
        }
    }
}
