// caelestia4: model / tool indicator chip under the Assistant input (Caelestia style). Hover shows the hint.
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.common.widgets as E4W // caelestia4: keep (StyledToolTip)
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    property string icon: "api"
    property string text: ""
    property string tooltipText: ""

    implicitHeight: row.implicitHeight + Tokens.padding.extraSmall * 2
    implicitWidth: row.implicitWidth + Tokens.padding.medium * 2
    radius: Tokens.rounding.full
    color: Colours.tPalette.m3surfaceContainerHighest

    // Shrinks (eliding the text) when the row is short of space: give it Layout.fillWidth + maximumWidth: implicitWidth
    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        MaterialIcon {
            text: root.icon
            color: Colours.palette.m3primary
            fontStyle: Tokens.font.icon.small
        }

        StyledText {
            Layout.fillWidth: true
            text: root.text
            font: Tokens.font.label.medium
            color: Colours.palette.m3onSurface
            elide: Text.ElideRight
            animate: true
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        visible: root.tooltipText.length > 0

        E4W.StyledToolTip {
            extraVisibleCondition: false
            alternativeVisibleCondition: mouseArea.containsMouse
            text: root.tooltipText
        }
    }
}
