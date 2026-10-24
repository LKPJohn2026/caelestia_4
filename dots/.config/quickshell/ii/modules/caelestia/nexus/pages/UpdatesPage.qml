pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (end-4's Updates count drives the bar's updates icon)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Nexus > Updates (upstream has only a placeholder): pending Arch repo and AUR updates and new commits
// for this caelestia_4 clone, from utils/scripts/system.py. Updating runs in a terminal (sudo prompts, yay's
// questions); the page checks again when asked.
PageBase {
    id: root

    readonly property string script: Quickshell.shellPath("modules/caelestia/utils/scripts/system.py")
    property var data: ({})
    readonly property var repoPkgs: data.repo?.packages ?? []
    readonly property var aurPkgs: data.aur?.packages ?? []
    readonly property var c4: data.caelestia4 ?? ({})
    readonly property int total: repoPkgs.length + aurPkgs.length
    readonly property bool checking: checkProc.running

    function check(): void {
        checkProc.running = true;
    }

    // Commands run in the default terminal (uwsm -T), which stays open at the end so the output can be read
    function inTerminal(command: string): void {
        Quickshell.execDetached(["uwsm-app", "-T", "--", "bash", "-c", `${command}; echo; read -rp "${Tr.tr("Done. Press Enter to close.")}"`]);
    }

    function since(iso: string): string {
        if (!iso)
            return Tr.tr("Never checked");
        const mins = Math.round((Date.now() - new Date(iso).getTime()) / 60000);
        if (mins < 1)
            return Tr.tr("Checked just now");
        if (mins < 60)
            return Tr.tr("Checked %1 min ago").arg(mins);
        return Tr.tr("Checked %1").arg(Qt.formatDateTime(new Date(iso), "ddd hh:mm"));
    }

    title: Tr.tr("Updates")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // The last result at once; a fresh check when it's older than 30 minutes
        Process {
            running: true
            command: [root.script, "cached"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.data = JSON.parse(text);
                    } catch (e) {
                        root.data = {};
                    }
                    if (!root.data.checked || Date.now() - new Date(root.data.checked).getTime() > 30 * 60000)
                        root.check();
                }
            }
        }

        Process {
            id: checkProc

            command: [root.script, "updates"]
            stdout: StdioCollector {
                onStreamFinished: {
                    try {
                        root.data = JSON.parse(text);
                    } catch (e) {}
                    E4.Updates.refresh(); // the bar's updates icon
                }
            }
        }

        SectionHeader {
            first: true
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            icon: root.checking ? "sync" : root.total > 0 ? "system_update_alt" : "check_circle"
            label: root.checking ? Tr.tr("Checking for updates…") : root.total > 0 ? Tr.trN("%n update available", "%n updates available", root.total) : Tr.tr("Up to date")
            subtext: root.since(root.data.checked ?? "")
        }

        RowButton {
            icon: "refresh"
            text: Tr.tr("Check now")
            disabled: root.checking
            onClicked: root.check()
        }

        RowButton {
            last: true
            icon: "download"
            text: Tr.tr("Update everything")
            subtext: root.data.aur?.helper ? Tr.tr("Runs %1 in a terminal (repo and AUR packages)").arg(root.data.aur.helper) : Tr.tr("Runs pacman -Syu in a terminal")
            disabled: root.checking || root.total === 0
            onClicked: root.inTerminal(root.data.aur?.helper ? root.data.aur.helper : "sudo pacman -Syu")
        }

        SectionHeader {
            visible: root.repoPkgs.length > 0 || !!root.data.repo?.error
            text: Tr.tr("Arch packages (%1)").arg(root.repoPkgs.length)
        }

        InfoRow {
            visible: !!root.data.repo?.error
            first: true
            last: true
            icon: "error"
            label: root.data.repo?.error ?? ""
        }

        Repeater {
            model: root.repoPkgs

            InfoRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.repoPkgs.length - 1
                label: modelData.name
                value: `${modelData.from} → ${modelData.to}`
            }
        }

        SectionHeader {
            visible: root.aurPkgs.length > 0 || !!root.data.aur?.error
            text: Tr.tr("AUR packages (%1)").arg(root.aurPkgs.length)
        }

        InfoRow {
            visible: !!root.data.aur?.error
            first: true
            last: true
            icon: "error"
            label: root.data.aur?.error ?? ""
        }

        Repeater {
            model: root.aurPkgs

            InfoRow {
                required property var modelData
                required property int index

                first: index === 0
                last: index === root.aurPkgs.length - 1
                label: modelData.name
                value: `${modelData.from} → ${modelData.to}`
            }
        }

        SectionHeader {
            text: "caelestia_4"
        }

        InfoRow {
            first: true
            icon: root.c4.error && !root.c4.branch ? "error" : (root.c4.behind ?? 0) > 0 ? "upgrade" : "check_circle"
            label: !root.c4.path ? (root.c4.error ?? Tr.tr("Not checked yet")) : (root.c4.behind ?? 0) > 0 ? Tr.trN("%n new commit", "%n new commits", root.c4.behind) : Tr.tr("Up to date")
            subtext: [root.c4.path ? `${root.c4.path} · ${root.c4.branch} → ${root.c4.upstream ?? ""}` : "", root.c4.dirty ? Tr.tr("uncommitted changes") : "", (root.c4.ahead ?? 0) > 0 ? Tr.trN("%n local commit not pushed", "%n local commits not pushed", root.c4.ahead) : "", root.c4.path ? (root.c4.error ?? "") : ""].filter(s => s).join(" · ")
        }

        Repeater {
            model: root.c4.commits ?? []

            InfoRow {
                required property var modelData

                label: modelData.subject
                value: modelData.hash
                subtext: Qt.formatDateTime(new Date(modelData.date), "ddd dd/MM hh:mm")
            }
        }

        RowButton {
            last: true
            icon: "download"
            text: Tr.tr("Update caelestia_4")
            subtext: root.c4.dirty ? Tr.tr("Commit or stash the uncommitted changes first") : Tr.tr("git pull, then tools/install-main.sh, in a terminal")
            disabled: root.checking || !root.c4.path || (root.c4.behind ?? 0) === 0 || root.c4.dirty
            onClicked: root.inTerminal(`cd '${root.c4.path}' && git pull --ff-only && tools/install-main.sh`)
        }
    }
}
