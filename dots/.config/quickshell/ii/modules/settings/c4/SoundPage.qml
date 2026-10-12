import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Caelestia.Config as CC
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Sound — volume limits and steps, sudden-volume protection, system sounds.
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "volume_up"
        title: Translation.tr("Volume")

        SpinRow {
            icon: "volume_up"
            title: Translation.tr("Maximum volume (%)")
            description: Translation.tr("Above 100 % boosts quiet sources but can distort")
            from: 50
            to: 150
            stepSize: 5
            value: Math.round(CC.GlobalConfig.services.maxVolume * 100)
            onMoved: v => CC.GlobalConfig.services.maxVolume = v / 100
        }

        SpinRow {
            icon: "stairs"
            title: Translation.tr("Volume step (%)")
            description: Translation.tr("Change per scroll on the bar and per volume key in the panels")
            from: 1
            to: 20
            value: Math.round(CC.GlobalConfig.services.audioIncrement * 100)
            onMoved: v => CC.GlobalConfig.services.audioIncrement = v / 100
        }
    }

    ContentSection {
        icon: "hearing"
        title: Translation.tr("Hearing protection")

        SwitchRow {
            icon: "shield"
            title: Translation.tr("Block sudden loud jumps")
            description: Translation.tr("Undo volume changes that are too big or go over the limit, whoever makes them")
            checked: Config.options.audio.protection.enable
            onToggled: v => Config.options.audio.protection.enable = v
        }

        SpinRow {
            enabled: Config.options.audio.protection.enable
            icon: "trending_up"
            title: Translation.tr("Largest allowed jump (%)")
            from: 1
            to: 100
            value: Config.options.audio.protection.maxAllowedIncrease
            onMoved: v => Config.options.audio.protection.maxAllowedIncrease = v
        }

        SpinRow {
            enabled: Config.options.audio.protection.enable
            icon: "volume_off"
            title: Translation.tr("Volume limit (%)")
            from: 10
            to: 150
            value: Config.options.audio.protection.maxAllowed
            onMoved: v => Config.options.audio.protection.maxAllowed = v
        }
    }

    ContentSection {
        icon: "notifications_active"
        title: Translation.tr("System sounds")

        SwitchRow {
            icon: "battery_alert"
            title: Translation.tr("Battery warnings")
            checked: Config.options.sounds.battery
            onToggled: v => Config.options.sounds.battery = v
        }

        SwitchRow {
            icon: "timer"
            title: Translation.tr("Timer and Pomodoro")
            checked: Config.options.sounds.pomodoro
            onToggled: v => Config.options.sounds.pomodoro = v
        }
    }
}
