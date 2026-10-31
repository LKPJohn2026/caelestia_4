pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.caelestia.overlay
import Caelestia.Config
import qs.modules.common as E4C // caelestia4: end-4 Persistent
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

StyledOverlayWidget {
    id: root
    Component.onCompleted: ResourceUsage.consumers++ // caelestia4: ResourceUsage (end4-pC's) polls only while used
    Component.onDestruction: ResourceUsage.consumers--
    minimumWidth: 300
    minimumHeight: 200
    property list<var> resources: [
        {
            "icon": "planner_review",
            "name": Translation.tr("CPU"),
            "history": ResourceUsage.cpuUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableCpuString
        },
        {
            "icon": "memory",
            "name": Translation.tr("RAM"),
            "history": ResourceUsage.memoryUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableMemoryString
        },
        {
            "icon": "swap_horiz",
            "name": Translation.tr("Swap"),
            "history": ResourceUsage.swapUsageHistory,
            "maxAvailableString": ResourceUsage.maxAvailableSwapString
        },
    ]

    // caelestia4: Caelestia style: chips for CPU / RAM / Swap, big value, history graph
    contentItem: OverlayBackground {
        id: contentItem

        radius: root.contentRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.medium
            spacing: Tokens.spacing.medium

            RowLayout {
                Layout.fillWidth: true
                spacing: Tokens.spacing.small

                Repeater {
                    model: root.resources.length

                    IconTextButton {
                        required property int index

                        Layout.fillWidth: true
                        type: IconTextButton.Tonal
                        isToggle: true
                        checked: E4C.Persistent.states.overlay.resources.tabIndex === index
                        icon: root.resources[index].icon
                        text: root.resources[index].name
                        onClicked: E4C.Persistent.states.overlay.resources.tabIndex = index
                    }
                }
            }

            ResourceSummary {
                history: root.resources[E4C.Persistent.states.overlay.resources.tabIndex]?.history ?? []
                maxAvailableString: root.resources[E4C.Persistent.states.overlay.resources.tabIndex]?.maxAvailableString ?? "--"
            }
        }
    }

    component ResourceSummary: RowLayout {
        id: resourceSummary

        required property list<real> history
        required property string maxAvailableString

        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Tokens.spacing.large

        ColumnLayout {
            spacing: 0

            StyledText {
                text: `${((resourceSummary.history[resourceSummary.history.length - 1] ?? 0) * 100).toFixed(1)}%`
                font: Tokens.font.clock.size(Tokens.font.headline.medium.pointSize * 1.3).weight(Font.Bold).build()
                color: Colours.palette.m3primary
            }

            StyledText {
                text: Translation.tr("of %1").arg(resourceSummary.maxAvailableString)
                font: Tokens.font.body.small
                color: Colours.palette.m3onSurfaceVariant
            }

            Item {
                Layout.fillHeight: true
            }
        }

        ClipRect {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Tokens.rounding.medium
            color: Colours.tPalette.m3surfaceContainerHigh

            Graph {
                anchors.fill: parent
                values: resourceSummary.history
                points: ResourceUsage.historyLength
                alignment: Graph.Alignment.Right
                color: Colours.palette.m3primary
                fillOpacity: 0.35
            }
        }
    }
}
