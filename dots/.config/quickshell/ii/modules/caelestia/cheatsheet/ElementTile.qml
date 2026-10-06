import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: periodic table tile (end-4 cheatsheet ElementTile) in Caelestia style
StyledRect {
    id: root

    required property var modelData // { number, symbol, name, weight, type }
    readonly property bool empty: modelData.type === "empty"

    implicitWidth: 66
    implicitHeight: 66
    radius: Tokens.rounding.small
    color: empty ? "transparent" : Colours.tPalette.m3surfaceContainer

    StyledText {
        visible: !root.empty
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 4
        text: root.modelData.number ?? ""
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }

    StyledText {
        visible: !root.empty
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 4
        text: root.modelData.weight ?? ""
        font: Tokens.font.label.small
        color: Colours.palette.m3outline
    }

    StyledText {
        visible: !root.empty
        anchors.centerIn: parent
        text: root.modelData.symbol ?? ""
        font: Tokens.font.title.medium
        color: Colours.palette.m3primary
    }

    StyledText {
        visible: !root.empty
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        width: parent.width - 6
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.modelData.name ?? ""
        font: Tokens.font.label.small
        color: Colours.palette.m3onSurfaceVariant
    }
}
