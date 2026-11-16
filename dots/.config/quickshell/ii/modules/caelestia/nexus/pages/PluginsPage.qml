pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Nexus > Plugins. Upstream's page is a mock-up and its plugin system (Caelestia.Plugins) is unmerged, so
// here it shows what the shell is built from: Quickshell and the Caelestia QML plugin (both use Qt's private API and
// need a rebuild after a Qt minor update), the Qt they run on, and loaded Hyprland plugins. Data: system.py components.
PageBase {
    id: root

    readonly property string script: Quickshell.shellPath("modules/caelestia/utils/scripts/system.py")
    property var data: ({})
    // caelestia4: true once system.py answered (or failed): a missing value then reads "Unknown", not "Checking…"
    property bool loaded
    readonly property string missingValue: !loaded || proc.running ? Tr.tr("Checking…") : Tr.tr("Unknown")
    readonly property var components: data.components ?? []
    readonly property string repo: data.repo ?? ""
    // The Qt this shell process loaded; differs from the installed one after a Qt update until the shell restarts
    readonly property string qtRunning: CUtils.qtVersion

    function reload(): void {
        proc.running = true;
    }

    function inTerminal(command: string): void {
        Quickshell.execDetached(["uwsm-app", "-T", "--", "bash", "-c", `${command}; echo; read -rp "${Tr.tr("Done. Press Enter to close.")}"`]);
    }

    function statusFor(c: var): string {
        if (c.needsRebuild === true)
            return Tr.tr("Rebuild needed: built with Qt %1, Qt %2 is installed").arg(c.builtQt).arg(root.data.qtInstalled);
        if (c.needsRebuild === false)
            return Tr.tr("Built with Qt %1").arg(c.builtQt);
        if (c.builtQt)
            return Tr.tr("Built with Qt %1").arg(c.builtQt);
        // caelestia4: only ask for a rebuild the Rebuild button can do (it needs the source folder)
        return root.repo ? Tr.tr("Qt version it was built with is unknown. Rebuild once to record it") : Tr.tr("Qt version it was built with is unknown");
    }

    // Rebuild commands, run in a terminal. The plugin is installed with the shell stopped: replacing a loaded .so
    // can crash the running shell.
    function rebuildCommand(c: var): string {
        if (c.name === "Quickshell")
            return `cd '${root.repo}/packaging/caelestia4-quickshell' && makepkg -Cfsi && systemctl --user restart caelestia4-shell`;
        return `cd '${root.repo}' && PREFIX="$HOME/.cache/caelestia4/plugin-stage" tools/build-caelestia-plugin.sh && systemctl --user stop caelestia4-shell && cmake --install build/caelestia-plugin --prefix "$HOME/.local" && cp "$HOME/.cache/caelestia4/plugin-stage/lib/qt6/qml/Caelestia/caelestia4-build.json" "$HOME/.local/lib/qt6/qml/Caelestia/" && systemctl --user start caelestia4-shell`;
    }

    title: Tr.tr("Plugins")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        Process {
            id: proc

            running: true
            command: [root.script, "components"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.data = JSON.parse(text);
                    } catch (e) {
                        root.data = {};
                    }
                    root.loaded = true;
                }
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("Qt")
        }

        InfoRow {
            first: true
            label: Tr.tr("Installed")
            value: root.data.qtInstalled || root.missingValue
        }

        InfoRow {
            last: true
            label: Tr.tr("Running in the shell")
            value: root.qtRunning || Tr.tr("Unknown")
            subtext: root.data.qtInstalled && root.qtRunning && root.qtRunning !== root.data.qtInstalled ? Tr.tr("Qt was updated: restart the shell (Ctrl+Super+R) after rebuilding") : ""
        }

        SectionHeader {
            text: Tr.tr("Shell components")
        }

        // caelestia4: system.py gave no components (still checking, or it failed)
        InfoRow {
            visible: root.components.length === 0
            first: true
            last: true
            icon: root.loaded && !proc.running ? "error" : "sync"
            label: root.loaded && !proc.running ? Tr.tr("Couldn't read the shell components") : Tr.tr("Checking…")
        }

        Repeater {
            model: root.components

            ColumnLayout {
                id: comp

                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.topMargin: index > 0 ? Tokens.spacing.small : 0
                spacing: Tokens.spacing.extraSmall / 2

                InfoRow {
                    first: true
                    icon: comp.modelData.needsRebuild === true ? "warning" : "extension"
                    iconColour: comp.modelData.needsRebuild === true ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
                    label: comp.modelData.name === "Caelestia plugin" ? Tr.tr("Caelestia plugin") : comp.modelData.name // system.py's name
                    value: [comp.modelData.version, comp.modelData.revision].filter(s => s).join(" · ") || root.missingValue
                    subtext: root.statusFor(comp.modelData)
                }

                RowButton {
                    last: true
                    icon: "build"
                    text: Tr.tr("Rebuild")
                    // caelestia4: what it does, not the commands (rebuildCommand); disabled with the reason
                    subtext: !root.repo ? (root.loaded ? Tr.tr("Needs the caelestia_4 source folder, which wasn't found") : Tr.tr("Checking…")) : comp.modelData.name === "Quickshell" ? Tr.tr("Builds and reinstalls it in a terminal, then restarts the shell") : Tr.tr("Builds it in a terminal, then reinstalls it with the shell stopped for a moment")
                    disabled: !root.repo
                    onClicked: root.inTerminal(root.rebuildCommand(comp.modelData))
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Hyprland plugins")
        }

        InfoRow {
            visible: (root.data.hyprlandPlugins ?? []).length === 0
            first: true
            last: true
            label: Tr.tr("No Hyprland plugins loaded")
        }

        Repeater {
            model: root.data.hyprlandPlugins ?? []

            InfoRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.data.hyprlandPlugins.length - 1
                label: modelData.name
                value: modelData.version
                subtext: [modelData.author, modelData.description].filter(s => s).join(" · ")
            }
        }

        RowButton {
            Layout.topMargin: Tokens.spacing.small
            first: true
            last: true
            icon: "refresh"
            text: Tr.tr("Check again")
            disabled: proc.running
            onClicked: root.reload()
        }
    }
}
