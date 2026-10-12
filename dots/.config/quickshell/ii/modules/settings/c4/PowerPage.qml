import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Power & idle — hypridle timers (written to ~/.config/hypr/hypridle-timeouts.conf, hypridle restarted),
// lock screen, battery. Keep awake (utilities drawer) pauses all idle timers.
ContentPage {
    forceWidth: true

    readonly property var idle: Config.options.caelestia.idle
    readonly property var minuteOptions: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120].map(m => ({
                label: m === 0 ? Translation.tr("Never") : (m < 60 ? Translation.tr("%1 min").arg(m) : Translation.tr("%1 h").arg(m / 60)),
                value: m
            }))

    function applyIdle(): void {
        // Config writes are delayed a little; pass the values explicitly
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/hypridle-timeouts.sh"), String(idle.lockMinutes), String(idle.screenOffMinutes), String(idle.suspendMinutes), idle.lockBeforeSleep ? "true" : "false"]);
    }

    ContentSection {
        icon: "bedtime"
        title: Translation.tr("When idle")

        ChoiceRow {
            icon: "lock"
            title: Translation.tr("Lock the screen after")
            options: minuteOptions
            value: idle.lockMinutes
            onSelected: v => {
                idle.lockMinutes = v;
                applyIdle();
            }
        }

        ChoiceRow {
            icon: "desktop_access_disabled"
            title: Translation.tr("Turn off the screen after")
            options: minuteOptions
            value: idle.screenOffMinutes
            onSelected: v => {
                idle.screenOffMinutes = v;
                applyIdle();
            }
        }

        ChoiceRow {
            icon: "dark_mode"
            title: Translation.tr("Sleep after")
            options: minuteOptions
            value: idle.suspendMinutes
            onSelected: v => {
                idle.suspendMinutes = v;
                applyIdle();
            }
        }

        SwitchRow {
            icon: "lock_clock"
            title: Translation.tr("Lock before sleeping")
            checked: idle.lockBeforeSleep
            onToggled: v => {
                idle.lockBeforeSleep = v;
                applyIdle();
            }
        }

        SettingRow {
            icon: "coffee"
            title: Translation.tr("Keep awake")
            description: Translation.tr("The Keep awake card in the utilities drawer pauses all of the above while it is on")
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Lock screen")

        SwitchRow {
            icon: "lock_person"
            title: Translation.tr("Use hyprlock")
            description: Translation.tr("Recommended: survives the monitor dropping off on wake. Off: the shell's own lock screen")
            checked: Config.options.lock.useHyprlock
            onToggled: v => Config.options.lock.useHyprlock = v
        }
    }

    ContentSection {
        icon: "battery_full"
        title: Translation.tr("Battery")

        SettingRow {
            visible: !Battery.available
            icon: "power"
            title: Translation.tr("No battery detected")
            description: Translation.tr("These only apply to laptops")
        }

        SpinRow {
            icon: "battery_3_bar"
            enabled: Battery.available
            title: Translation.tr("Low battery warning at (%)")
            from: 5
            to: 50
            value: Config.options.battery.low
            onMoved: v => Config.options.battery.low = v
        }

        SpinRow {
            icon: "battery_alert"
            enabled: Battery.available
            title: Translation.tr("Critical warning at (%)")
            from: 1
            to: 20
            value: Config.options.battery.critical
            onMoved: v => Config.options.battery.critical = v
        }

        SwitchRow {
            icon: "power_settings_new"
            enabled: Battery.available
            title: Translation.tr("Sleep when almost empty")
            checked: Config.options.battery.automaticSuspend
            onToggled: v => Config.options.battery.automaticSuspend = v
        }

        SpinRow {
            enabled: Battery.available && Config.options.battery.automaticSuspend
            icon: "battery_0_bar"
            title: Translation.tr("Sleep at (%)")
            from: 1
            to: 15
            value: Config.options.battery.suspend
            onMoved: v => Config.options.battery.suspend = v
        }
    }
}
