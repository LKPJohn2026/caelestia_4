import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

RippleButton {
    id: root
    property string query

    implicitHeight: 30
    leftPadding: 6
    rightPadding: 10
    buttonRadius: CC.Tokens.rounding.extraSmall
    colBackground: Colours.palette.m3surfaceContainerHighest
    colBackgroundHover: Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.alpha(Colours.palette.m3onSurface, 0.08))
    colRipple: Qt.tint(Colours.palette.m3surfaceContainerHighest, Qt.alpha(Colours.palette.m3onSurface, 0.12))

    PointingHandInteraction {}
    onClicked: {
        let url = Config.options.search.engineBaseUrl + root.query;
        for (let site of (Config?.options?.search.excludedSites ?? [])) {
            url += ` -site:${site}`;
        }
        Qt.openUrlExternally(url);
        GlobalStates.sidebarLeftOpen = false;
    }

    contentItem: Item {
        anchors.centerIn: parent
        implicitWidth: rowLayout.implicitWidth
        implicitHeight: rowLayout.implicitHeight
        RowLayout {
            id: rowLayout
            anchors.centerIn: parent
            spacing: 5
            MaterialSymbol {
                text: "search"
                iconSize: 20
                color: Colours.palette.m3onSurface
            }
            StyledText {
                id: text
                horizontalAlignment: Text.AlignHCenter
                text: root.query
                color: Colours.palette.m3onSurface
            }
        }
    }
}
