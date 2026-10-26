pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Nexus > Updates (upstream has only a placeholder): pending Arch repo and AUR updates and new commits
// for this caelestia_4 clone, from SystemUpdates (shared with the bar's updates icon and popout). Updating runs in a
// terminal (sudo prompts, yay's questions); a check follows when the terminal closes.
PageBase {
    id: root

    // caelestia4: SystemUpdates is shared with the bar's updates icon and popout, so all three show the same check
    readonly property var data: SystemUpdates.data
    readonly property var repoPkgs: SystemUpdates.repoPackages
    readonly property var aurPkgs: SystemUpdates.aurPackages
    readonly property var c4: SystemUpdates.caelestia4
    readonly property int total: SystemUpdates.count
    readonly property bool checking: SystemUpdates.checking

    title: Tr.tr("Updates")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("System")
        }

        InfoRow {
            first: true
            icon: root.checking ? "sync" : root.total > 0 ? "system_update_alt" : "check_circle"
            label: root.checking ? Tr.tr("Checking for updates…") : root.total > 0 ? Tr.trN("%n update available", "%n updates available", root.total) : Tr.tr("Up to date")
            subtext: SystemUpdates.since()
        }

        RowButton {
            icon: "refresh"
            text: Tr.tr("Check now")
            disabled: root.checking
            onClicked: SystemUpdates.refresh()
        }

        RowButton {
            last: true
            icon: "download"
            text: Tr.tr("Update everything")
            subtext: root.data.aur?.helper ? Tr.tr("Runs %1 in a terminal (repo and AUR packages)").arg(root.data.aur.helper) : Tr.tr("Runs pacman -Syu in a terminal")
            disabled: root.checking || root.total === 0
            onClicked: SystemUpdates.updatePackages()
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
            onClicked: SystemUpdates.updateCaelestia4()
        }
    }
}
