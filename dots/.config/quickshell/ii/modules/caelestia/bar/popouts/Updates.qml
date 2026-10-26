pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: updates popout. Same data as Nexus > Updates (SystemUpdates: repo + AUR packages and new caelestia_4
// commits); "Details" opens that page in place of the popout.
ColumnLayout {
    id: root

    required property PopoutState popouts

    spacing: Tokens.spacing.medium

    StyledText {
        text: SystemUpdates.checking ? Tr.tr("Checking for updates…") : SystemUpdates.count > 0 ? Tr.trN("%n update available", "%n updates available", SystemUpdates.count) : Tr.tr("System is up to date")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        text: [SystemUpdates.repoPackages.length > 0 ? Tr.tr("Arch packages (%1)").arg(SystemUpdates.repoPackages.length) : "", SystemUpdates.aurPackages.length > 0 ? Tr.tr("AUR packages (%1)").arg(SystemUpdates.aurPackages.length) : "", SystemUpdates.caelestia4Behind > 0 ? `caelestia_4: ${Tr.trN("%n new commit", "%n new commits", SystemUpdates.caelestia4Behind)}` : "", SystemUpdates.since()].filter(s => s).join(" · ")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    StyledText {
        visible: SystemUpdates.updateStronglyAdvised || SystemUpdates.updateAdvised
        text: SystemUpdates.updateStronglyAdvised ? Tr.tr("Many updates pending, updating soon is strongly advised") : Tr.tr("Updating soon is advised")
        color: SystemUpdates.updateStronglyAdvised ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    RowLayout {
        spacing: Tokens.spacing.small

        IconTextButton {
            visible: SystemUpdates.count > 0
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            icon: "system_update_alt"
            text: Tr.tr("Update everything")
            onClicked: {
                root.popouts.hasCurrent = false;
                SystemUpdates.updatePackages();
            }
        }

        IconTextButton {
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            icon: "refresh"
            text: Tr.tr("Check again")
            disabled: SystemUpdates.checking
            onClicked: SystemUpdates.refresh()
        }

        IconTextButton {
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            icon: "open_in_new"
            text: Tr.tr("Details")
            onClicked: root.popouts.detachRequested("updates") // Nexus > Updates, in place of the popout
        }
    }
}
