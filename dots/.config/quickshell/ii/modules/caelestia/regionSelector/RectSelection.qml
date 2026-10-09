import QtQuick
import Caelestia.Config
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: rectangle selection in Caelestia style (replaces end-4's RectCornersSelectionDetails): dimmed
// surroundings, solid primary outline with round corner handles, a size chip while dragging, faint aim lines.
// After a recording starts (breathingBorderOnly) only the outline stays, breathing.
Item {
    id: root

    required property real regionX
    required property real regionY
    required property real regionWidth
    required property real regionHeight
    required property real mouseX
    required property real mouseY
    required property color color
    required property color overlayColor
    property bool showSize: true
    property bool showAimLines: E4C.Config.options.regionSelector.rect.showAimLines
    property bool breathingBorderOnly: false

    readonly property bool hasRegion: regionWidth > 0 && regionHeight > 0

    // Darken around the region: four rectangles (above, below, left, right)
    Item {
        z: 1
        anchors.fill: parent
        visible: !root.breathingBorderOnly

        readonly property real rx: Math.max(0, root.regionX)
        readonly property real ry: Math.max(0, root.regionY)
        readonly property real rr: Math.min(width, root.regionX + root.regionWidth)
        readonly property real rb: Math.min(height, root.regionY + root.regionHeight)

        Rectangle {
            x: 0
            y: 0
            width: parent.width
            height: parent.ry
            color: root.overlayColor
        }
        Rectangle {
            x: 0
            y: parent.rb
            width: parent.width
            height: Math.max(0, parent.height - parent.rb)
            color: root.overlayColor
        }
        Rectangle {
            x: 0
            y: parent.ry
            width: parent.rx
            height: Math.max(0, parent.rb - parent.ry)
            color: root.overlayColor
        }
        Rectangle {
            x: parent.rr
            y: parent.ry
            width: Math.max(0, parent.width - parent.rr)
            height: Math.max(0, parent.rb - parent.ry)
            color: root.overlayColor
        }
    }

    Rectangle {
        id: outline

        z: 9
        visible: root.hasRegion
        x: Math.round(root.regionX) - border.width
        y: Math.round(root.regionY) - border.width
        width: Math.round(root.regionWidth) + border.width * 2
        height: Math.round(root.regionHeight) + border.width * 2
        color: "transparent"
        border.color: root.color
        border.width: 2
        radius: Tokens.rounding.extraSmall

        opacity: 1
        SequentialAnimation on opacity {
            running: root.breathingBorderOnly
            loops: Animation.Infinite

            NumberAnimation {
                from: 1
                to: 0.3
                duration: 1200
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 0.3
                to: 1
                duration: 1200
                easing.type: Easing.InOutQuad
            }
        }

        Repeater {
            model: root.breathingBorderOnly ? 0 : 4

            Rectangle {
                required property int index

                readonly property real size: 12

                x: (index % 2 === 0 ? 0 : outline.width) - size / 2
                y: (index < 2 ? 0 : outline.height) - size / 2
                width: size
                height: size
                radius: size / 2
                color: root.color
                border.width: 2
                border.color: Colours.palette.m3onPrimary
            }
        }
    }

    // Size chip under the bottom-right corner
    StyledRect {
        z: 10
        visible: root.showSize && root.hasRegion && !root.breathingBorderOnly
        x: Math.min(outline.x + outline.width - width, root.width - width - Tokens.padding.small)
        y: Math.min(outline.y + outline.height + Tokens.spacing.medium, root.height - height - Tokens.padding.small)
        implicitWidth: sizeText.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: sizeText.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.full
        color: root.color

        StyledText {
            id: sizeText

            anchors.centerIn: parent
            text: `${Math.round(root.regionWidth)} × ${Math.round(root.regionHeight)}`
            color: Colours.palette.m3onPrimary
            font: Tokens.font.label.medium
        }
    }

    // Aim lines
    Rectangle {
        z: 2
        visible: root.showAimLines && !root.breathingBorderOnly
        opacity: 0.35
        x: root.mouseX
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: root.color
    }
    Rectangle {
        z: 2
        visible: root.showAimLines && !root.breathingBorderOnly
        opacity: 0.35
        y: root.mouseY
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: root.color
    }
}
