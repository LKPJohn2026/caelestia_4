pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: a clickable window / layer / image region in the region selector (end-4's TargetRegion, Caelestia
// style): outline (thicker + tinted when targeted) and a label chip with the app icon.
Rectangle {
    id: root

    required property var clientDimensions
    property bool showLabel: E4C.Config.options.regionSelector.targetRegions.showLabel
    property bool showIcon: false
    property string icon // Material icon when there's no app icon
    property bool targeted: false
    property color borderColor
    property color fillColor: "transparent"
    property string text: ""

    x: clientDimensions.at[0]
    y: clientDimensions.at[1]
    width: clientDimensions.size[0]
    height: clientDimensions.size[1]
    color: fillColor
    border.color: borderColor
    border.width: targeted ? 3 : 2
    visible: opacity > 0

    Behavior on color {
        CAnim {}
    }
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    StyledRect {
        visible: root.showLabel
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        implicitWidth: labelRow.implicitWidth + Tokens.padding.medium * 2
        implicitHeight: labelRow.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.full
        color: root.targeted ? root.borderColor : Colours.tPalette.m3surfaceContainer

        RowLayout {
            id: labelRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            IconImage {
                visible: root.showIcon
                implicitSize: 18
                source: root.showIcon ? Quickshell.iconPath(E4.AppSearch.guessIcon(root.text), "image-missing") : ""
            }

            MaterialIcon {
                visible: !root.showIcon && root.icon !== ""
                text: root.icon
                color: root.targeted ? Colours.palette.m3surface : root.borderColor
            }

            StyledText {
                text: root.text
                color: root.targeted ? Colours.palette.m3surface : Colours.palette.m3onSurface
                font: Tokens.font.body.small
            }
        }
    }
}
