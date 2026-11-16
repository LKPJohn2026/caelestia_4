pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import Caelestia.Services
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of ServicesPage (route services/polling). Rows name registry ids (registry/RegServices.qml)
PageBase {
    id: root

    title: Tr.tr("Polling & tuning")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Polling")
        }

        // caelestia4: all are stored in ms and shown in seconds (the entries' scale), so they read the same way
        StepperRow {
            setting: "c:dashboard.mediaUpdateInterval"
        }

        StepperRow {
            setting: "c:dashboard.resourceUpdateInterval"
        }

        StepperRow {
            setting: "e4:resources.updateInterval"
        }

        SectionHeader {
            text: Tr.tr("Service tuning")
        }

        StepperRow {
            setting: "c:services.visualiserBars"
        }

        ToggleRow {
            setting: "c:services.smartScheme"
        }

        SelectRow {
            id: gpuRow

            setting: "c:services.gpuType"
            subtext: Gpu.name ? Tr.tr("Monitoring: %1").arg(Gpu.name) : gpuRow.link.desc
            menuOnTop: true
        }

        AdvancedSection {
            StepperRow {
                setting: "e4:resources.historyLength"
            }

            StepperRow {
                setting: "e4:bar.weather.fetchInterval"
            }
        }
    }
}
