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
import qs.modules.common as E4C

// caelestia4: Nexus > Power & idle, as end-4's Settings app (Power & idle). The idle timers are hypridle's (Caelestia's
// own general.idle isn't used here): written to ~/.config/hypr/hypridle-timeouts.conf by
// scripts/caelestia4/hypridle-timeouts.sh, which restarts hypridle. Keep awake (utilities) pauses them all.
// Battery warnings are Caelestia's BatteryMonitor (general.battery in shell.json).
PageBase {
    id: root

    readonly property list<MenuItem> minuteItems: [0, 1, 2, 3, 5, 10, 15, 20, 30, 45, 60, 90, 120].map(m => menuItemComp.createObject(root, {
            text: m === 0 ? Tr.tr("Never") : (m < 60 ? Tr.tr("%1 min").arg(m) : Tr.tr("%1 h").arg(m / 60)),
            value: m
        }))

    // A property: PageBase's default property takes the page's one content item
    readonly property Component menuItemComp: Component {
        MenuItem {}
    }

    // caelestia4: end-4's battery service (services/Battery.qml: sleep at, and its notices) is a singleton that only
    // starts when something reads it, today only the desktop resources widget and the daily clock. Its rows are
    // greyed with a reason when neither is on, as they would do nothing
    readonly property bool hasBattery: UPower.displayDevice.isLaptopBattery
    readonly property bool e4BatteryRuns: {
        const w = E4C.Config.options.background.widgets;
        return w.resources.enable || (w.clock.enable && w.clock.style === "daily");
    }
    readonly property bool e4BatteryUsable: hasBattery && e4BatteryRuns

    title: Tr.tr("Power & idle")

    // caelestia4: the idle rows write end-4's options through the registry; RegPower.qml hands every change to
    // hypridle (a pick, a reset, Undo, Reset page), also after this page is gone
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: the lock screen's options are on their own sub-page (pages/power/LockPage.qml). A link on its
        // own at the top, not under a "Lock screen" header that says the same as the row
        NavRow {
            icon: "lock"
            text: Tr.tr("Lock screen")
            subtext: Tr.tr("Picture, blur, password box, hyprlock")
            onClicked: root.nState.openSubPage("lock")
        }

        SectionHeader {
            text: Tr.tr("When idle")
        }

        SelectRow {
            setting: "e4:caelestia.idle.lockMinutes"
            menuItems: root.minuteItems
        }

        SelectRow {
            setting: "e4:caelestia.idle.screenOffMinutes"
            menuItems: root.minuteItems
        }

        SelectRow {
            setting: "e4:caelestia.idle.suspendMinutes"
            menuItems: root.minuteItems
        }

        ToggleRow {
            setting: "e4:caelestia.idle.lockBeforeSleep"
        }

        InfoRow {
            icon: "coffee"
            label: Tr.tr("Keep awake")
            subtext: Tr.tr("The Keep awake card in the utilities drawer pauses all of the above while it is on")
        }

        SectionHeader {
            text: Tr.tr("Battery")
        }

        InfoRow {
            visible: !root.hasBattery
            icon: "power"
            label: Tr.tr("No battery detected")
            subtext: Tr.tr("These only apply to laptops")
        }

        // caelestia4: the whole general.battery.warnLevels list in one row (a dialog edits it)
        KeyValueListRow {
            id: warnLevelsRow

            enabled: root.hasBattery
            // caelestia4: greyed like the steppers' boxes below while there is no battery
            controlBox.opacity: root.hasBattery ? 1 : 0.5
            setting: "c:general.battery.warnLevels"
            // caelestia4: a level added here has no title, message or icon. Caelestia keeps them as "", which
            // BatteryMonitor's `??` fallback does not catch, so the toast would be empty: give it plain ones
            // caelestia4: the summary reads "20 %, 10 % Critical": the level with its unit
            function itemLabel(item: var): string {
                const level = Tr.tr("%1 %").arg(item.level ?? "");
                return item.critical ? Tr.trCtx("%1 Critical", "battery warning level").arg(level) : level;
            }

            onEdited: list => {
                const filled = list.map(it => Object.assign({}, it, {
                    title: it.title || (it.critical ? Tr.mark("Critical battery level") : Tr.mark("Low battery")),
                    message: it.message || Tr.mark("Battery level is low"),
                    icon: it.icon || "battery_android_alert"
                }));
                if (!warnLevelsRow.link.s.same(filled, list))
                    warnLevelsRow.link.s.set(filled);
            }
        }

        StepperRow {
            enabled: root.hasBattery
            setting: "c:general.battery.criticalLevel"
        }

        InfoRow {
            visible: root.hasBattery && !root.e4BatteryRuns
            icon: "info"
            label: Tr.tr("Sleep and the extra notices are off")
            subtext: Tr.tr("They only run while the desktop Resources widget or the Daily clock style is on")
        }

        // caelestia4: `disabled`, not `enabled: false`: only `disabled` greys the switch, like the steppers' boxes
        ToggleRow {
            disabled: !root.e4BatteryUsable
            setting: "e4:battery.automaticSuspend"
        }

        StepperRow {
            enabled: root.e4BatteryUsable
            setting: "e4:battery.suspend"
        }

        // caelestia4: one Battery section for both services: Caelestia's BatteryMonitor (warn at, hibernate at) and
        // end-4's services/Battery.qml (sleep at). end-4's own notices, which repeat the warnings above with a sound,
        // are in Advanced
        AdvancedSection {
            StepperRow {
                enabled: root.e4BatteryUsable
                setting: "e4:battery.low"
            }

            StepperRow {
                enabled: root.e4BatteryUsable
                setting: "e4:battery.critical"
            }

            StepperRow {
                enabled: root.e4BatteryUsable
                setting: "e4:battery.full"
            }
        }
    }
}
