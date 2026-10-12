// caelestia4: description of the highlighted command / tag suggestion, with key hints (Caelestia style)
import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.services as E4 // caelestia4: keep (Translation)
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

StyledRect {
    id: root

    property alias text: descriptionText.text
    property bool showArrows: true
    property bool showTab: true

    visible: descriptionText.text.length > 0
    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.small * 2
    radius: Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainerHigh

    RowLayout {
        id: row

        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        spacing: Tokens.spacing.extraSmall

        StyledText {
            id: descriptionText

            Layout.fillWidth: true
            font: Tokens.font.body.small
            color: Colours.palette.m3onSurface
            wrapMode: Text.Wrap
        }

        KeyCap {
            visible: root.showArrows
            text: "↑"
        }

        KeyCap {
            visible: root.showArrows
            text: "↓"
        }

        StyledText {
            visible: root.showArrows && root.showTab
            text: E4.Translation.tr("or")
            font: Tokens.font.label.small
            color: Colours.palette.m3outline
        }

        KeyCap {
            visible: root.showTab
            text: "Tab"
        }
    }
}
