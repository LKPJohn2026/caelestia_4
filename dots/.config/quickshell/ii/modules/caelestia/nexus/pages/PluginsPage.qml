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
        return c.builtQt ? Tr.tr("Built with Qt %1").arg(c.builtQt) : Tr.tr("Built with an unknown Qt version (rebuild once to record it)");
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
            value: root.data.qtInstalled ?? "…"
        }

        InfoRow {
            last: true
            label: Tr.tr("Running in the shell")
            value: root.qtRunning || "…"
            subtext: root.data.qtInstalled && root.qtRunning && root.qtRunning !== root.data.qtInstalled ? Tr.tr("Qt was updated: restart the shell (Ctrl+Super+R) after rebuilding") : ""
        }

        SectionHeader {
            text: Tr.tr("Shell components")
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
                    label: comp.modelData.name
                    value: [comp.modelData.version, comp.modelData.revision].filter(s => s).join(" · ") || "…"
                    subtext: root.statusFor(comp.modelData)
                }

                InfoRow {
                    visible: (comp.modelData.modules ?? []).length > 0
                    label: Tr.tr("QML modules")
                    subtext: (comp.modelData.modules ?? []).map(m => `Caelestia.${m}`).join(", ")
                }

                RowButton {
                    last: true
                    icon: "build"
                    text: Tr.tr("Rebuild")
                    subtext: comp.modelData.name === "Quickshell" ? Tr.tr("makepkg in packaging/caelestia4-quickshell, in a terminal (asks for sudo)") : Tr.tr("tools/build-caelestia-plugin.sh, then reinstalls it with the shell stopped")
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
