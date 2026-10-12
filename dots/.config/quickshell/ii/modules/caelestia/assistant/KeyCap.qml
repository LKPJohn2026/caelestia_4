// caelestia4: a small key cap ("Tab", "↑") for the Assistant's suggestion hints
import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    property alias text: keyLabel.text

    implicitWidth: Math.max(implicitHeight, keyLabel.implicitWidth + Tokens.padding.small * 2)
    implicitHeight: keyLabel.implicitHeight + Tokens.padding.extraSmall * 2
    radius: Tokens.rounding.small
    color: Colours.palette.m3surfaceContainerHighest

    StyledText {
        id: keyLabel

        anchors.centerIn: parent
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }
}
