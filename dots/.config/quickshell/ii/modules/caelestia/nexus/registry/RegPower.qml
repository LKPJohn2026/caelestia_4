import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C

// caelestia4: Nexus registry entries for the "power" page (merged by Registry.qml). See RegPanels.qml for the format.
// The idle timers are end-4 options handed to scripts/caelestia4/hypridle-timeouts.sh (it writes hypridle's timers and
// restarts hypridle) whenever they change. That watch lives here, not on PowerPage: Registry is a singleton, so an Undo
// (Ctrl+Z is window-wide) or a reset made after leaving the page still reaches hypridle
QtObject {
    id: root

    readonly property var idle: E4C.Config.options.caelestia.idle

    function applyIdle(): void {
        // Config writes are delayed a little; pass the values explicitly
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/hypridle-timeouts.sh"), String(idle.lockMinutes), String(idle.screenOffMinutes), String(idle.suspendMinutes), idle.lockBeforeSleep ? "true" : "false"]);
    }

    // Short delay: a page reset changes several at once, which is one script run
    readonly property Timer applyIdleTimer: Timer {
        interval: 100
        onTriggered: root.applyIdle()
    }

    readonly property Connections idleWatch: Connections {
        function queue(): void {
            // Not while config.json is first loading: that is not a change
            if (E4C.Config.ready)
                root.applyIdleTimer.restart();
        }

        function onLockMinutesChanged(): void {
            queue();
        }

        function onScreenOffMinutesChanged(): void {
            queue();
        }

        function onSuspendMinutesChanged(): void {
            queue();
        }

        function onLockBeforeSleepChanged(): void {
            queue();
        }

        target: root.idle
    }

    // caelestia4: the default warning levels as the shell.json node gives them (every key, "critical": false too),
    // or the list would always read as changed
    readonly property var warnLevelsDefault: {
        const d = GlobalConfig.general.battery.descriptorFor("warnLevels").defaultValue;
        return Array.from(d ?? [], x => Object.assign({
                level: -1,
                title: "",
                message: "",
                icon: "",
                critical: false
            }, JSON.parse(JSON.stringify(x))));
    }

    readonly property var entries: ({
            // Power & idle > When idle (pages/PowerPage.qml)
            "e4:caelestia.idle.lockMinutes": {
                route: "power",
                section: Tr.mark("When idle"),
                title: Tr.mark("Lock the screen after"),
                desc: Tr.mark("How long the computer can sit unused before the screen locks"),
                keywords: [Tr.mark("idle"), Tr.mark("lock"), Tr.mark("timeout"), Tr.mark("away"), Tr.mark("hypridle"), Tr.mark("auto lock")],
                type: "int",
                unit: "min",
                min: 0,
                max: 120
            },
            "e4:caelestia.idle.screenOffMinutes": {
                route: "power",
                section: Tr.mark("When idle"),
                title: Tr.mark("Turn off the screen after"),
                desc: Tr.mark("Turns the screens off to save power. Any key or mouse move turns them back on"),
                keywords: [Tr.mark("idle"), Tr.mark("screen off"), Tr.mark("monitor"), Tr.mark("dpms"), Tr.mark("blank"), Tr.mark("timeout"), Tr.mark("hypridle")],
                type: "int",
                unit: "min",
                min: 0,
                max: 120
            },
            "e4:caelestia.idle.suspendMinutes": {
                route: "power",
                section: Tr.mark("When idle"),
                title: Tr.mark("Sleep after"),
                desc: Tr.mark("Suspends the computer. Downloads and other running work stop until it wakes"),
                keywords: [Tr.mark("idle"), Tr.mark("sleep"), Tr.mark("suspend"), Tr.mark("timeout"), Tr.mark("hypridle"), Tr.mark("standby")],
                type: "int",
                unit: "min",
                min: 0,
                max: 120
            },
            "e4:caelestia.idle.lockBeforeSleep": {
                route: "power",
                section: Tr.mark("When idle"),
                title: Tr.mark("Lock before sleeping"),
                desc: Tr.mark("Lock the screen whenever the computer goes to sleep, so it wakes up locked"),
                keywords: [Tr.mark("lock"), Tr.mark("sleep"), Tr.mark("suspend"), Tr.mark("wake"), Tr.mark("security")],
                type: "bool"
            },

            // Power & idle > Battery. Caelestia's warnings (BatteryMonitor.qml: a toast per level) and hibernate
            "c:general.battery.warnLevels": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Warn at"),
                desc: Tr.mark("A message pops up when the battery drops to each of these levels"),
                keywords: [Tr.mark("battery"), Tr.mark("warning"), Tr.mark("low"), Tr.mark("critical"), Tr.mark("toast"), Tr.mark("alert"), Tr.mark("laptop"), Tr.mark("levels")],
                type: "list",
                // caelestia4: title, message and icon are kept as they are but not edited here: the default ones are
                // marked for translation, and PowerPage gives a new level plain ones (Caelestia stores "" for them)
                fields: [
                    {
                        key: "level",
                        title: Tr.mark("Battery percent"),
                        type: "int"
                    },
                    {
                        key: "critical",
                        title: Tr.mark("Critical (red message)"),
                        type: "bool"
                    }
                ],
                default: root.warnLevelsDefault
            },
            "c:general.battery.criticalLevel": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Hibernate at"),
                desc: Tr.mark("Battery percent at which the session is saved to disk before the battery runs out (needs hibernation set up). 0 = never"),
                keywords: [Tr.mark("battery"), Tr.mark("hibernate"), Tr.mark("critical"), Tr.mark("shutdown"), Tr.mark("laptop")],
                type: "int",
                unit: "%",
                min: 0,
                max: 15,
                step: 1
            },

            // Power & idle > Battery: end-4's Battery service (services/Battery.qml): suspend, and its own
            // notifications (with sounds when Audio > Battery warnings is on)
            "e4:battery.automaticSuspend": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Sleep when almost empty"),
                desc: Tr.mark("Suspends the computer at the level below while it is not charging"),
                keywords: [Tr.mark("battery"), Tr.mark("suspend"), Tr.mark("sleep"), Tr.mark("empty"), Tr.mark("low"), Tr.mark("laptop"), Tr.mark("automatic")],
                type: "bool"
            },
            "e4:battery.suspend": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Sleep at"),
                desc: Tr.mark("Battery percent at which the computer suspends. At or above “Hibernate at”, it sleeps before it can hibernate"),
                keywords: [Tr.mark("battery"), Tr.mark("suspend"), Tr.mark("sleep"), Tr.mark("level"), Tr.mark("percent"), Tr.mark("laptop")],
                type: "int",
                unit: "%",
                min: 1,
                max: 20,
                step: 1,
                requires: {
                    id: "e4:battery.automaticSuspend",
                    value: true
                }
            },
            "e4:battery.low": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Low battery notice at"),
                desc: Tr.mark("A second notice, with a sound if Audio > Battery warnings is on, when the battery drops to this level"),
                keywords: [Tr.mark("battery"), Tr.mark("low"), Tr.mark("notification"), Tr.mark("sound"), Tr.mark("level"), Tr.mark("percent")],
                type: "int",
                unit: "%",
                min: 1,
                max: 50,
                step: 1,
                advanced: true
            },
            "e4:battery.critical": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Critical battery notice at"),
                desc: Tr.mark("An urgent notice, with a sound if battery sounds are on, saying when the computer will sleep"),
                keywords: [Tr.mark("battery"), Tr.mark("critical"), Tr.mark("notification"), Tr.mark("sound"), Tr.mark("level"), Tr.mark("percent")],
                type: "int",
                unit: "%",
                min: 1,
                max: 30,
                step: 1,
                advanced: true
            },
            "e4:battery.full": {
                route: "power",
                section: Tr.mark("Battery"),
                title: Tr.mark("Charged notice at"),
                desc: Tr.mark("A notification to unplug the charger when charging reaches this level. 101 = never"),
                keywords: [Tr.mark("battery"), Tr.mark("full"), Tr.mark("charged"), Tr.mark("unplug"), Tr.mark("charger"), Tr.mark("notification"), Tr.mark("level")],
                type: "int",
                unit: "%",
                min: 50,
                max: 101,
                step: 1,
                advanced: true
            }
        })
}
