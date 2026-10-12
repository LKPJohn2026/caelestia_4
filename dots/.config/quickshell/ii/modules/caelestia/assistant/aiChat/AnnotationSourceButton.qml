import QtQuick
import Caelestia.Config as CC
import qs // caelestia4: keep (GlobalStates)
import qs.modules.common // caelestia4: keep (Config)
import qs.modules.common.widgets as E4W // caelestia4: keep (Favicon)
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.assistant

// caelestia4: a source the AI cited, as a Caelestia chip with the site's favicon; click opens it
ChipBase {
    id: root

    property string displayText
    property string url
    property real faviconSize: 20

    horizontalPadding: CC.Tokens.padding.small

    onClicked: {
        if (url) {
            Qt.openUrlExternally(url);
            GlobalStates.sidebarLeftOpen = false;
        }
    }

    E4W.Favicon {
        anchors.verticalCenter: parent.verticalCenter
        url: root.url
        size: root.faviconSize
        displayText: root.displayText
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.displayText
        font: CC.Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }
}
