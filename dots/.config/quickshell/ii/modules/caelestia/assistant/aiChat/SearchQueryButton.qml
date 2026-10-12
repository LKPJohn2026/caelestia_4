import QtQuick
import Caelestia.Config as CC
import qs // caelestia4: keep (GlobalStates)
import qs.modules.common // caelestia4: keep (Config)
import qs.modules.common.widgets as E4W // caelestia4: keep (Favicon)
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.assistant

// caelestia4: web-search query the AI used, as a Caelestia chip; click searches it in the browser
ChipBase {
    id: root

    property string query

    onClicked: {
        let url = Config.options.search.engineBaseUrl + root.query;
        for (let site of (Config?.options?.search.excludedSites ?? []))
            url += ` -site:${site}`;
        Qt.openUrlExternally(url);
        GlobalStates.sidebarLeftOpen = false;
    }

    MaterialIcon {
        anchors.verticalCenter: parent.verticalCenter
        text: "search"
        color: Colours.palette.m3primary
    }

    StyledText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.query
        font: CC.Tokens.font.body.small
        color: Colours.palette.m3onSurface
    }
}
