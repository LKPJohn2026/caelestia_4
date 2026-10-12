// caelestia4: base for the Assistant's small pill buttons (search query, source, language): Caelestia surface,
// state layer, clicked signal. Put the content inside; size follows it.
import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    default property alias content: row.data
    property color colBackground: Colours.palette.m3surfaceContainerHighest
    property real horizontalPadding: Tokens.padding.medium
    readonly property alias hovered: stateLayer.containsMouse

    signal clicked

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: Math.max(30, row.implicitHeight + Tokens.padding.small * 2)
    radius: Tokens.rounding.full
    color: colBackground

    StateLayer {
        id: stateLayer

        radius: root.radius
        onClicked: root.clicked()
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: Tokens.spacing.extraSmall
    }
}
