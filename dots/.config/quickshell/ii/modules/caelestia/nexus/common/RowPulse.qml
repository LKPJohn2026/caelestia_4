import QtQuick
import qs.modules.caelestia.adapters

// caelestia4: the highlight a Nexus row gets when a route lands on it (or a reason link points at it): primary at 0.16
// opacity, twice over 1.2 s. Fills its parent (the row's ConnectedRect), following its corner radii
Rectangle {
    id: root

    property RowSetting link

    function start(): void {
        anim.restart();
    }

    anchors.fill: parent
    z: 9
    color: Colours.palette.m3primary
    opacity: 0
    visible: opacity > 0

    // qmllint disable missing-property
    radius: parent?.radius ?? 0
    topLeftRadius: parent?.topLeftRadius ?? radius
    topRightRadius: parent?.topRightRadius ?? radius
    bottomLeftRadius: parent?.bottomLeftRadius ?? radius
    bottomRightRadius: parent?.bottomRightRadius ?? radius
    // qmllint enable missing-property

    SequentialAnimation {
        id: anim

        loops: 2

        NumberAnimation {
            target: root
            property: "opacity"
            to: 0.16
            duration: 300
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "opacity"
            to: 0
            duration: 300
            easing.type: Easing.InCubic
        }
    }

    Connections {
        function onPulse(): void {
            root.start();
        }

        target: root.link
    }
}
