import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

RippleButton {
    id: root
    property string displayText: ""
    colBackground: Colours.tPalette.m3surfaceContainerHigh

    implicitWidth: contentItem.implicitWidth + horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + verticalPadding * 2

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: languageRow.implicitWidth
        implicitHeight: languageText.implicitHeight
        RowLayout {
            id: languageRow
            anchors.centerIn: parent
            spacing: 0
            StyledText {
                id: languageText
                Layout.alignment: Qt.AlignVCenter
                Layout.leftMargin: 5
                text: root.displayText
                color: Colours.palette.m3onSurface
                font.pixelSize: Appearance.font.pixelSize.small
            }
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                iconSize: Appearance.font.pixelSize.hugeass
                text: "arrow_drop_down"
                color: Colours.palette.m3onSurface
            }
        }
    }
}
