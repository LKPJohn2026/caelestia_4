import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import qs.modules.caelestia.background.pcwidgets

AbstractBackgroundWidget {
    Component.onCompleted: ResourceUsage.consumers++
    Component.onDestruction: ResourceUsage.consumers--
    id: root
    configEntryName: "resources"
    hoverEnabled: true

    property real widgetWidth: 420
    property real cardSpacing: 12
    property real cardHeight: 120
    property real cardWidth: (widgetWidth - cardSpacing * 2) / 3
    property bool isVertical: root.configEntry.vertical ?? false
    property bool hasBattery: Battery.available

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    component StatCard: WidgetCard {
        id: statCard
        property string icon: ""
        property string value: ""
        property string label: ""
        property int shape: MaterialShape.Shape.Cookie12Sided
        property color bgColor: Appearance.colors.colPrimaryContainer
        property color shapeColor: Appearance.colors.colPrimary
        // caelestia4: each card's own "on" colours, not the primary ones on all three: a container of another kind
        // can be light where primary's is dark (Material's 2025 spec makes a dark scheme's tertiary container light)
        property color symbolColor: Appearance.colors.colOnPrimary
        property color textColor: Appearance.colors.colOnPrimaryContainer

        implicitWidth: root.cardWidth
        implicitHeight: root.cardHeight
        widget: root
        color: statCard.bgColor

        ColumnLayout {
            anchors {
                fill: parent
                margins: 14
            }
            spacing: -4

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignRight
                shape: statCard.shape
                color: statCard.shapeColor
                colSymbol: statCard.symbolColor
                text: statCard.icon
                iconSize: 18
                fill: 1
                padding: 6
                implicitWidth: 34
                implicitHeight: 34
            }

            Item { Layout.fillHeight: true }

            StyledText {
                text: statCard.value
                font.pixelSize: Appearance.font.pixelSize.hugeass
                font.weight: Font.Bold
                color: statCard.textColor
            }

            StyledText {
                text: statCard.label
                font.pixelSize: Appearance.font.pixelSize.small
                color: statCard.textColor
                opacity: 0.6
            }
        }
    }

    Grid {
        id: row
        columns: root.isVertical ? 1 : 3
        rows: root.isVertical ? 3 : 1
        spacing: root.cardSpacing

        Behavior on columns {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        StatCard {
            icon: "planner_review"
            value: Math.round(ResourceUsage.cpuUsage * 100) + "%"
            label: Translation.tr("CPU")
            shape: MaterialShape.Shape.Gem
        }
        StatCard {
            icon: "memory"
            value: Math.round(ResourceUsage.memoryUsedPercentage * 100) + "%"
            label: Translation.tr("RAM")
            shape: MaterialShape.Shape.Cookie4Sided
            bgColor: Appearance.colors.colSecondaryContainer
            shapeColor: Appearance.colors.colSecondary
            symbolColor: Appearance.colors.colOnSecondary
            textColor: Appearance.colors.colOnSecondaryContainer
        }
        StatCard {
            icon: root.hasBattery ? "battery_full" : "storage"
            value: root.hasBattery
                ? Math.round(Battery.percentage * 100) + "%"
                : Math.round(ResourceUsage.diskUsedPercentage * 100) + "%"
            label: root.hasBattery ? Translation.tr("Battery") : Translation.tr("Disk")
            shape: MaterialShape.Shape.Cookie12Sided
            bgColor: Appearance.colors.colTertiaryContainer
            shapeColor: Appearance.colors.colTertiary
            symbolColor: Appearance.colors.colOnTertiary
            textColor: Appearance.colors.colOnTertiaryContainer
        }
    }
    WidgetFlipHandle {
        anchorItem: root
        hoverActive: root.containsMouse
        locked: Config.options.background.widgetsLocked
        onClicked: {
            root.isVertical = !root.isVertical
            root.configEntry.vertical = root.isVertical
            PresetLayout.requestSave()
        }
    }
}
