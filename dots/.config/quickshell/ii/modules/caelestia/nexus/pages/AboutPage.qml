import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.about

PageBase {
    id: root

    // Plugin support is not wired up yet; always 0 for now
    readonly property int pluginCount: 0

    property string quickshellVersion
    property string cliVersion

    // caelestia4: Your settings: the two settings files and the scripts that export them
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    readonly property string shellJson: `${configDir}/caelestia/shell.json`
    readonly property string configJson: `${configDir}/illogical-impulse/config.json`

    function copyPath(path: string): void {
        Quickshell.clipboardText = path;
        NexusActions.toast(Tr.tr("Path copied"));
    }

    // Into the home folder, or `folder`
    function exportChanges(folder: string): void {
        if (exportProc.running)
            return;
        exportProc.command = [Quickshell.shellPath("scripts/caelestia4/nexus-export.sh"), ...(folder ? [folder] : [])];
        exportProc.running = true;
    }

    function fileName(path: string): string {
        return path.slice(path.lastIndexOf("/") + 1);
    }

    // caelestia4: a short window (the page under 700 px, as on a 1280x720 screen) gets the small hero
    readonly property bool compactHero: height > 0 && height < 700

    title: Tr.tr("About")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // e.g. "Quickshell 0.3.0 (revision ...)"
        Process {
            running: true
            command: ["quickshell", "--version"]
            stdout: StdioCollector {
                onStreamFinished: root.quickshellVersion = text.trim().split(" ")[1] ?? ""
            }
        }

        // Parsed from the caelestia CLI's package listing; the sh wrapper avoids a
        // warning when the (optional) CLI isn't installed
        Process {
            running: true
            command: ["sh", "-c", "caelestia --version 2>/dev/null"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const m = text.match(/caelestia-cli\S*\s+(\d+(?:\.\d+)*)/);
                    root.cliVersion = m ? m[1] : "";
                }
            }
        }

        // Hero. caelestia4: on a short window (a 1280x720 screen) a small logo with the name beside it, so the
        // settings show without scrolling
        ConnectedRect {
            Layout.fillWidth: true
            first: true
            last: true
            implicitHeight: hero.implicitHeight + (root.compactHero ? Tokens.padding.large : Tokens.padding.extraLarge) * 2

            GridLayout {
                id: hero

                anchors.centerIn: parent
                width: root.compactHero ? implicitWidth : parent.width - Tokens.padding.largeIncreased * 2
                columns: root.compactHero ? 2 : 1
                columnSpacing: Tokens.spacing.large
                rowSpacing: root.compactHero ? 0 : Tokens.spacing.small

                Item {
                    readonly property real logoScale: root.compactHero ? 0.5 : 1

                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    Layout.rowSpan: root.compactHero ? 2 : 1
                    implicitWidth: logo.implicitWidth * logoScale
                    implicitHeight: logo.implicitHeight * logoScale

                    AnimatedLogo {
                        id: logo

                        anchors.centerIn: parent
                        width: implicitWidth
                        height: implicitHeight
                        scale: parent.logoScale
                    }
                }

                StyledText {
                    Layout.alignment: root.compactHero ? Qt.AlignLeft | Qt.AlignBottom : Qt.AlignHCenter
                    Layout.topMargin: root.compactHero ? 0 : Tokens.spacing.small
                    text: "Caelestia"
                    font: root.compactHero ? Tokens.font.headline.builders.small.width(110).build() : Tokens.font.headline.builders.large.width(110).build()
                }

                StyledText {
                    Layout.alignment: root.compactHero ? Qt.AlignLeft | Qt.AlignTop : Qt.AlignHCenter
                    text: CUtils.version ? `v${CUtils.version}` : "…"
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        // caelestia4: Your settings (P6): what you changed, the files, export and diagnostics
        SectionHeader {
            text: Tr.tr("Your settings")
        }

        ActionRow {
            first: true
            icon: "tune"
            text: Tr.tr("Changed settings")
            subtext: Tr.tr("See and reset what differs from the defaults")
            trailingIcon: "chevron_right"
            onClicked: root.nState.openSubPage("changed")
        }

        // caelestia4: named settings profiles (about/ProfilesPage.qml)
        ActionRow {
            icon: "bookmarks"
            text: Tr.tr("Profiles")
            subtext: Tr.tr("Save and switch between sets of settings")
            trailingIcon: "chevron_right"
            onClicked: root.nState.openSubPage("profiles")
        }

        ActionRow {
            icon: "upload_file"
            text: Tr.tr("Export my changes")
            subtext: Tr.tr("Saves your changed settings to a file in your home folder, without passwords or keys")
            actionIcon: "folder_open"
            actionText: Tr.tr("Save in another folder")
            busy: exportProc.running
            onClicked: root.exportChanges("")
            onActionClicked: exportFolder.openAt("")
        }

        ActionRow {
            icon: "bug_report"
            text: Tr.tr("Save diagnostics")
            subtext: Tr.tr("Versions, your changes and the recent log in a file for a bug report")
            busy: diagProc.running
            onClicked: {
                if (!diagProc.running)
                    diagProc.running = true;
            }
        }

        ActionRow {
            icon: "data_object"
            // TRANSLATORS: shell.json is a file name: keep it
            text: Tr.tr("Open shell.json")
            subtext: Tr.tr("Caelestia's settings: bar, panels, launcher")
            actionIcon: "content_copy"
            actionText: Tr.tr("Copy path")
            onClicked: Quickshell.execDetached(["xdg-open", root.shellJson])
            onActionClicked: root.copyPath(root.shellJson)
        }

        ActionRow {
            icon: "data_object"
            // TRANSLATORS: config.json is a file name: keep it
            text: Tr.tr("Open config.json")
            subtext: Tr.tr("end-4's settings: desktop widgets, lock screen, AI")
            actionIcon: "content_copy"
            actionText: Tr.tr("Copy path")
            onClicked: Quickshell.execDetached(["xdg-open", root.configJson])
            onActionClicked: root.copyPath(root.configJson)
        }

        // caelestia4: the first-run welcome (navpane/Welcome.qml), shown again over this page
        ActionRow {
            last: true
            icon: "waving_hand"
            text: Tr.tr("Show welcome again")
            subtext: Tr.tr("The first-run card with a few key choices")
            onClicked: WelcomeState.showAgain()
        }

        Process {
            id: exportProc

            stdout: StdioCollector {
                id: exportOut
            }
            stderr: StdioCollector {
                id: exportErr
            }
            onExited: code => {
                const path = exportOut.text.trim();
                if (code === 0 && path)
                    NexusActions.message(Tr.tr("Saved as %1").arg(root.fileName(path)), Tr.trCtx("Open", "snackbar button"), () => Quickshell.execDetached(["xdg-open", path]));
                else {
                    console.warn(`Nexus: export failed (${code}): ${exportErr.text.trim()}`);
                    NexusActions.toast(Tr.tr("Could not export your settings"));
                }
            }
        }

        Process {
            id: diagProc

            command: [Quickshell.shellPath("scripts/caelestia4/nexus-diagnostics.sh")]
            stdout: StdioCollector {
                id: diagOut
            }
            onExited: code => {
                const path = diagOut.text.trim();
                if (code === 0 && path) {
                    Quickshell.clipboardText = path;
                    NexusActions.message(Tr.tr("Diagnostics saved, path copied"), Tr.trCtx("Open", "snackbar button"), () => Quickshell.execDetached(["xdg-open", path]));
                } else {
                    NexusActions.toast(Tr.tr("Could not collect diagnostics"));
                }
            }
        }

        FolderPickerDialog {
            id: exportFolder

            title: Tr.tr("Export to a folder")
            onPicked: path => root.exportChanges(path)
        }

        // System
        SectionHeader {
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            label: Tr.tr("Hostname")
            value: SysInfo.hostname
        }

        InfoRow {
            label: Tr.trCtx("Device", "system model name")
            value: SysInfo.device
        }

        InfoRow {
            label: Tr.tr("Distro")
            value: SysInfo.osPrettyName || SysInfo.osName
        }

        InfoRow {
            label: Tr.tr("Kernel")
            value: SysInfo.kernel
        }

        InfoRow {
            last: true
            // TRANSLATORS: BIOS or UEFI firmware version
            label: Tr.tr("Firmware")
            value: SysInfo.firmware
        }

        // Software
        SectionHeader {
            text: Tr.tr("Software")
        }

        InfoRow {
            first: true
            label: Tr.trCtx("Shell", "the caelestia shell itself, not a unix shell")
            value: CUtils.version || "…"
        }

        InfoRow {
            label: Tr.trCtx("CLI", "the caelestia command line tool")
            value: root.cliVersion || "…"
        }

        InfoRow {
            label: "Quickshell"
            value: root.quickshellVersion || "…"
        }

        InfoRow {
            last: true
            label: "Qt"
            value: CUtils.qtVersion || "…"
        }

        // Plugins
        SectionHeader {
            text: Tr.tr("Plugins")
        }

        InfoRow {
            first: true
            last: true
            label: Tr.tr("Loaded plugins")
            value: root.pluginCount.toString()
        }
    }
}
