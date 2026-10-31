pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.components.controls
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    readonly property list<MenuItem> displayItems: [
        MenuItem {
            text: Tr.tr("Shapes")
            value: BarWorkspaceDisplay.Shapes
        },
        MenuItem {
            text: Tr.tr("Numbers")
            value: BarWorkspaceDisplay.Text
        },
        MenuItem {
            text: Tr.tr("Icons")
            value: BarWorkspaceDisplay.Icons
        }
    ]

    title: Tr.tr("Workspaces")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        StepperRow {
            first: true
            // TRANSLATORS: the number of workspaces shown on the bar
            label: Tr.trCtx("Shown", "bar workspaces")
            subtext: Tr.tr("Number of workspaces displayed")
            value: Config.bar.workspaces.shown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.shown = v
        }

        ToggleRow {
            text: Tr.trCtx("Active indicator", "bar workspaces")
            value: Config.bar.workspaces.activeIndicator
            onToggled: GlobalConfig.bar.workspaces.activeIndicator = checked
        }

        ToggleRow {
            text: Tr.trCtx("Active trail", "bar workspaces")
            value: Config.bar.workspaces.activeTrail
            onToggled: GlobalConfig.bar.workspaces.activeTrail = checked
        }

        ToggleRow {
            text: Tr.trCtx("Occupied background", "bar workspaces")
            value: Config.bar.workspaces.occupiedBg
            onToggled: GlobalConfig.bar.workspaces.occupiedBg = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show unoccupied", "bar workspaces")
            subtext: Tr.tr("Show workspaces that are inactive and empty")
            value: Config.bar.workspaces.showUnoccupied
            onToggled: GlobalConfig.bar.workspaces.showUnoccupied = checked
        }

        ToggleRow {
            text: Tr.trCtx("Per monitor", "bar workspaces")
            subtext: Tr.tr("Hide workspaces not on the current monitor")
            value: Config.bar.workspaces.perMonitor
            onToggled: GlobalConfig.bar.workspaces.perMonitor = checked
        }

        ToggleRow {
            text: Tr.trCtx("Show windows", "bar workspaces")
            subtext: Tr.tr("Show icons of open windows on each workspace")
            value: Config.bar.workspaces.showWindows
            onToggled: GlobalConfig.bar.workspaces.showWindows = checked
        }

        ToggleRow {
            text: Tr.trCtx("Windows on special workspaces", "bar workspaces")
            value: Config.bar.workspaces.showWindowsOnSpecialWorkspaces
            onToggled: GlobalConfig.bar.workspaces.showWindowsOnSpecialWorkspaces = checked
        }

        StepperRow {
            last: true
            // TRANSLATORS: maximum number of window icons shown per workspace
            label: Tr.trCtx("Max window icons", "bar workspaces")
            value: Config.bar.workspaces.maxWindowIcons
            from: 0
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.bar.workspaces.maxWindowIcons = v
        }

        // caelestia4: from end-4's Settings app (Desktop > Bar: workspaces)
        SectionHeader {
            text: Tr.tr("Style")
        }

        SelectRow {
            first: true
            label: Tr.tr("Workspace style")
            menuItems: root.displayItems
            active: root.displayItems.find(i => i.value === Config.bar.workspaces.displayType) ?? null
            onSelected: item => GlobalConfig.bar.workspaces.displayType = item.value
        }

        StepperRow {
            last: true
            label: Tr.tr("Hold Super to show numbers after (ms)")
            subtext: Tr.tr("Workspace numbers appear while Super is held")
            value: E4C.Config.options.bar.workspaces.showNumberDelay
            from: 0
            to: 2000
            stepSize: 50
            onMoved: v => E4C.Config.options.bar.workspaces.showNumberDelay = v
        }
    }
}
