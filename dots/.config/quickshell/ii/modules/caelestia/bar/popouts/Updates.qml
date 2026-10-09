pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep

// caelestia4: updates popout (end-4 Updates service: `checkupdates` every updates.checkInterval minutes).
// "Update now" runs end-4's apps.update command (kitty + pkexec pacman -Syu by default).
ColumnLayout {
    id: root

    required property PopoutState popouts

    spacing: Tokens.spacing.medium

    StyledText {
        text: E4.Updates.checking ? Tr.tr("Checking for updates…") : E4.Updates.count > 0 ? Tr.tr("%1 package updates available").arg(E4.Updates.count) : Tr.tr("System is up to date")
        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
    }

    StyledText {
        visible: E4.Updates.updateStronglyAdvised || E4.Updates.updateAdvised
        text: E4.Updates.updateStronglyAdvised ? Tr.tr("Many updates pending, updating soon is strongly advised") : Tr.tr("Updating soon is advised")
        color: E4.Updates.updateStronglyAdvised ? Colours.palette.m3error : Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    RowLayout {
        spacing: Tokens.spacing.small

        IconTextButton {
            visible: E4.Updates.count > 0
            inactiveColour: Colours.palette.m3primaryContainer
            inactiveOnColour: Colours.palette.m3onPrimaryContainer
            verticalPadding: Tokens.padding.extraSmall
            icon: "system_update_alt"
            text: Tr.tr("Update now")
            onClicked: {
                root.popouts.hasCurrent = false;
                Quickshell.execDetached(["bash", "-c", E4C.Config.options.apps.update]);
            }
        }

        IconTextButton {
            type: IconTextButton.Tonal
            verticalPadding: Tokens.padding.extraSmall
            icon: "refresh"
            text: Tr.tr("Check again")
            disabled: E4.Updates.checking
            onClicked: E4.Updates.refresh()
        }
    }
}
