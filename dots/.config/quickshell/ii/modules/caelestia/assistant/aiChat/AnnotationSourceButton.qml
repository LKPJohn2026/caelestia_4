import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import QtQuick
import QtQuick.Layouts

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

RippleButton {
    id: root
    property string displayText
    property string url

    property real faviconSize: 20
    implicitHeight: 30
    leftPadding: (implicitHeight - faviconSize) / 2
    rightPadding: 10
    buttonRadius: CC.Tokens.rounding.full
    colBackground: Colours.palette.m3surfaceContainerHighest
    colBackgroundHover: Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.alpha(Colours.palette.m3onSurface, 0.08))
    colRipple: Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.alpha(Colours.palette.m3onSurface, 0.12))

    PointingHandInteraction {}
    onClicked: {
        if (url) {
            Qt.openUrlExternally(url)
            GlobalStates.sidebarLeftOpen = false
        }
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        RowLayout {
            id: rowLayout
            anchors.fill: parent
            spacing: 5
            Favicon {
                url: root.url
                size: root.faviconSize
                displayText: root.displayText
            }
            StyledText {
                id: text
                horizontalAlignment: Text.AlignHCenter
                text: displayText
                color: Colours.palette.m3onSurface
            }
        }
    }
}
