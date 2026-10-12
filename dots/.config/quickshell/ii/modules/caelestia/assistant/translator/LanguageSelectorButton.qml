import QtQuick
import Caelestia.Config as CC
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.assistant

// caelestia4: translator language picker, a Caelestia chip with a drop-down arrow
ChipBase {
    id: root

    property string displayText: ""

    colBackground: Colours.tPalette.m3surfaceContainerHigh

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        font: CC.Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: "arrow_drop_down"
        color: Colours.palette.m3onSurfaceVariant
    }
}
