pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (caelestia.idle and lock.useHyprlock live in end-4's config)

// caelestia4: Nexus > Power & idle, as end-4's Settings app (Power & idle). The idle timers are hypridle's (Caelestia's
// own general.idle isn't used here): written to ~/.config/hypr/hypridle-timeouts.conf by
// scripts/caelestia4/hypridle-timeouts.sh, which restarts hypridle. Keep awake (utilities) pauses them all.
// Battery warnings are Caelestia's BatteryMonitor (general.battery in shell.json).
PageBase {
    id: root

    readonly property var idle: E4C.Config.options.caelestia.idle

    readonly property list<MenuItem> minuteItems: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120].map(m => menuItemComp.createObject(root, {
            text: m === 0 ? Tr.tr("Never") : (m < 60 ? Tr.tr("%1 min").arg(m) : Tr.tr("%1 h").arg(m / 60)),
            value: m
        }))

    // A property: PageBase's default property takes the page's one content item
    readonly property Component menuItemComp: Component {
        MenuItem {}
    }

    function applyIdle(): void {
        // Config writes are delayed a little; pass the values explicitly
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/hypridle-timeouts.sh"), String(idle.lockMinutes), String(idle.screenOffMinutes), String(idle.suspendMinutes), idle.lockBeforeSleep ? "true" : "false"]);
    }

    title: Tr.tr("Power & idle")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("When idle")
        }

        SelectRow {
            first: true
            label: Tr.tr("Lock the screen after")
            menuItems: root.minuteItems
            active: root.minuteItems.find(i => i.value === root.idle.lockMinutes) ?? null
            onSelected: item => {
                root.idle.lockMinutes = item.value;
                root.applyIdle();
            }
        }

        SelectRow {
            label: Tr.tr("Turn off the screen after")
            menuItems: root.minuteItems
            active: root.minuteItems.find(i => i.value === root.idle.screenOffMinutes) ?? null
            onSelected: item => {
                root.idle.screenOffMinutes = item.value;
                root.applyIdle();
            }
        }

        SelectRow {
            label: Tr.tr("Sleep after")
            menuItems: root.minuteItems
            active: root.minuteItems.find(i => i.value === root.idle.suspendMinutes) ?? null
            onSelected: item => {
                root.idle.suspendMinutes = item.value;
                root.applyIdle();
            }
        }

        ToggleRow {
            text: Tr.tr("Lock before sleeping")
            value: root.idle.lockBeforeSleep
            onToggled: {
                root.idle.lockBeforeSleep = checked;
                root.applyIdle();
            }
        }

        InfoRow {
            last: true
            icon: "coffee"
            label: Tr.tr("Keep awake")
            subtext: Tr.tr("The Keep awake card in the utilities drawer pauses all of the above while it is on")
        }

        SectionHeader {
            text: Tr.tr("Lock screen")
        }

        ToggleRow {
            first: true
            last: true
            text: Tr.tr("Use hyprlock")
            subtext: Tr.tr("Recommended: survives the monitor dropping off on wake. Off: the shell's own lock screen")
            value: E4C.Config.options.lock.useHyprlock
            onToggled: E4C.Config.options.lock.useHyprlock = checked
        }

        SectionHeader {
            text: Tr.tr("Battery")
        }

        InfoRow {
            visible: !UPower.displayDevice.isLaptopBattery
            first: true
            icon: "power"
            label: Tr.tr("No battery detected")
            subtext: Tr.tr("These only apply to laptops")
        }

        Repeater {
            model: GlobalConfig.general.battery.warnLevels.values

            StepperRow {
                required property var modelData
                required property int index

                enabled: UPower.displayDevice.isLaptopBattery
                label: modelData.critical ? Tr.tr("Critical warning at (%)") : Tr.tr("Low battery warning at (%)")
                value: modelData.level
                from: 1
                to: 50
                onMoved: v => GlobalConfig.general.battery.warnLevels.at(index).level = v
            }
        }

        StepperRow {
            last: true
            enabled: UPower.displayDevice.isLaptopBattery
            label: Tr.tr("Hibernate at (%)")
            subtext: Tr.tr("Saves the session to disk before the battery runs out (needs hibernation set up). 0 = never")
            value: GlobalConfig.general.battery.criticalLevel
            from: 0
            to: 15
            onMoved: v => GlobalConfig.general.battery.criticalLevel = v
        }
    }
}
