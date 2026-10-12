// caelestia4: a row in the image actions menu (Anime tab), Caelestia style (was end-4's MenuButton)
import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    property string buttonText

    signal clicked

    implicitWidth: label.implicitWidth + Tokens.padding.large * 2
    implicitHeight: label.implicitHeight + Tokens.padding.medium * 2
    radius: Tokens.rounding.small
    color: "transparent"
    opacity: enabled ? 1 : 0.4

    StateLayer {
        radius: root.radius
        onClicked: root.clicked()
    }

    StyledText {
        id: label

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Tokens.padding.large
        text: root.buttonText
        font: Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }
}
