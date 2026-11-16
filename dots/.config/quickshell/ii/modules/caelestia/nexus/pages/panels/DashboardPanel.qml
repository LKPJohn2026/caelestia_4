pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    // caelestia4: presets on = the top edge opens no dashboard (drawers/Interactions.qml)
    readonly property bool presetsOn: E4C.Config.options.background.presetsEnabled

    title: Tr.tr("Dashboard")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            id: enabledRow

            setting: "c:dashboard.enabled"
        }

        ToggleRow {
            id: hoverRow

            // caelestia4: off while presets are on: the registry's `requires` gives the "Turn off" link. Super+M opens
            // nothing while the dashboard itself is off (dashboard/Wrapper.qml), so the hint needs both
            setting: "c:dashboard.showOnHover"
            subtext: root.presetsOn && enabledRow.link.value === true ? Tr.tr("Super+M still opens the dashboard") : hoverRow.link.desc
        }

        ToggleRow {
            setting: "c:dashboard.showClockSeconds"
        }

        // caelestia4: presets on = a drag only closes it (drawers/Interactions.qml)
        StepperRow {
            id: dragRow

            setting: "c:dashboard.dragThreshold"
            subtext: root.presetsOn ? Tr.tr("How far to drag up to close the dashboard. Opening by drag is off while presets are on") : dragRow.link.desc
        }

        SectionHeader {
            text: Tr.tr("Tabs")
        }

        ToggleRow {
            setting: "c:dashboard.showDashboard"
        }

        ToggleRow {
            setting: "c:dashboard.showMedia"
        }

        ToggleRow {
            setting: "c:dashboard.showPerformance"
        }

        ToggleRow {
            setting: "c:dashboard.showWeather"
        }

        // caelestia4: end-4's to-do and timer as dashboard tabs
        ToggleRow {
            setting: "e4:caelestia.dashboardTodo"
        }

        ToggleRow {
            setting: "e4:caelestia.dashboardTimer"
        }

        SectionHeader {
            text: Tr.tr("Performance widgets")
        }

        ToggleRow {
            setting: "c:dashboard.performance.showBattery"
        }

        ToggleRow {
            setting: "c:dashboard.performance.showGpu"
        }

        ToggleRow {
            setting: "c:dashboard.performance.showCpu"
        }

        ToggleRow {
            setting: "c:dashboard.performance.showMemory"
        }

        ToggleRow {
            setting: "c:dashboard.performance.showStorage"
        }

        ToggleRow {
            setting: "c:dashboard.performance.showNetwork"
        }

        // caelestia4: the GIF next to the player (dash/Media.qml)
        SectionHeader {
            text: Tr.tr("Media card")
        }

        AssetPathRow {
            setting: "c:paths.mediaGif"
            hint: Tr.tr("None")
        }

        SliderRow {
            setting: "c:general.mediaGifSpeedAdjustment"
        }
    }
}
