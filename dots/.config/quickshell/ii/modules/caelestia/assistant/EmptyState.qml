// caelestia4: empty-page message for the Assistant tabs (replaces end-4's PagePlaceholder with its pixel-cookie shape):
// an icon in a tonal circle, a title and a hint, fading out once there is content.
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

Item {
    id: root

    property bool shown: true
    property string icon
    property string title
    property string description

    anchors.fill: parent
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - Tokens.padding.extraLarge * 2, 360)
        spacing: Tokens.spacing.medium

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 88
            implicitHeight: 88
            radius: Tokens.rounding.full
            color: Colours.palette.m3secondaryContainer

            MaterialIcon {
                anchors.centerIn: parent
                text: root.icon
                fill: 1
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.4).build()
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.title
            wrapMode: Text.Wrap
            font: Tokens.font.title.large
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: text.length > 0
            text: root.description
            wrapMode: Text.Wrap
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurfaceVariant
            lineHeight: 1.3
        }
    }
}
