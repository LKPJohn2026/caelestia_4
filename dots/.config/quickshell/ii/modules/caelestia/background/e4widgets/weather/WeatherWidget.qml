import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.caelestia.background.e4widgets // caelestia4: keep
import qs.modules.caelestia.adapters as CA // caelestia4: keep (Caelestia's weather: auto location, Nexus units)

AbstractBackgroundWidget {
    id: root

    configEntryName: "weather"

    implicitHeight: backgroundShape.implicitHeight
    implicitWidth: backgroundShape.implicitWidth

    StyledDropShadow {
        target: backgroundShape
    }

    MaterialShape {
        id: backgroundShape
        anchors.fill: parent
        shape: MaterialShape.Shape.Pill
        color: Appearance.colors.colPrimaryContainer
        implicitSize: 200

        StyledText {
            font {
                pixelSize: 80
                family: Appearance.font.family.expressive
                weight: Font.Medium
            }
            color: Appearance.colors.colPrimary
            text: CA.Weather.cc ? CA.Weather.formatTemp(CA.Weather.cc.tempC, true) : "--°" // caelestia4: one weather source
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: 16
                topMargin: 20
            }
        }

        MaterialSymbol {
            iconSize: 80
            color: Appearance.colors.colOnPrimaryContainer
            text: CA.Weather.cc ? CA.Weather.icon : "cloud"
            anchors {
                left: parent.left
                bottom: parent.bottom

                leftMargin: 16
                bottomMargin: 20
            }
        }
    }
}
