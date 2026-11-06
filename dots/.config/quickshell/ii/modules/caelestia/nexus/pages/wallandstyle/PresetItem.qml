import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a preset in Nexus > Wallpaper & style > Presets: a WallItem with a badge on its picture (Community,
// Installed) and, for an installed one, Update and Uninstall buttons over it while hovered. Uninstall asks for a
// second click (the label says so for a few seconds)
Item {
    id: root

    property alias source: wall.source
    property string text
    property string badge
    property bool actions // the Update and Uninstall buttons
    property bool confirming

    signal clicked
    signal updateClicked
    signal uninstallClicked

    Layout.fillWidth: true
    implicitHeight: wall.implicitHeight

    WallItem {
        id: wall

        anchors.left: parent.left
        anchors.right: parent.right

        imgHeight: width * 9 / 16
        text: root.confirming ? Tr.tr("Uninstall? Click again") : root.text
        onClicked: root.clicked()
    }

    HoverHandler {
        id: hover
    }

    StyledRect {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.padding.small

        visible: root.badge
        implicitWidth: badgeText.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: badgeText.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer

        StyledText {
            id: badgeText

            anchors.centerIn: parent
            text: root.badge
            color: Colours.palette.m3onSecondaryContainer
            font: Tokens.font.label.small
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.small
        spacing: Tokens.spacing.extraSmall

        visible: root.actions && root.enabled && (hover.hovered || root.confirming)

        IconButton {
            icon: "cloud_sync"
            type: IconButton.Tonal
            isRound: true
            onClicked: root.updateClicked()
        }

        IconButton {
            icon: root.confirming ? "delete_forever" : "delete"
            type: IconButton.Tonal
            isRound: true
            inactiveColour: root.confirming ? Colours.palette.m3errorContainer : Colours.palette.m3secondaryContainer
            inactiveOnColour: root.confirming ? Colours.palette.m3onErrorContainer : Colours.palette.m3onSecondaryContainer
            onClicked: {
                if (root.confirming) {
                    root.confirming = false;
                    confirmTimer.stop();
                    root.uninstallClicked();
                } else {
                    root.confirming = true;
                    confirmTimer.restart();
                }
            }
        }
    }

    Timer {
        id: confirmTimer

        interval: 4000
        onTriggered: root.confirming = false
    }
}
