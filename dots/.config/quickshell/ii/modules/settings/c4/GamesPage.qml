import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Games — background mute and background frame rate (see Display for VRR).
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "sports_esports"
        title: Translation.tr("Games in the background")

        SwitchRow {
            icon: "volume_off"
            title: Translation.tr("Mute games while in the background")
            description: Translation.tr("A game's sound stops when you switch away and comes back when you click into it")
            checked: Config.options.caelestia.backgroundMute.enable
            onToggled: v => Config.options.caelestia.backgroundMute.enable = v
        }

        TextRow {
            enabled: Config.options.caelestia.backgroundMute.enable
            icon: "rule"
            title: Translation.tr("Which windows are games")
            description: Translation.tr("Window class pattern (regex). Steam/Proton games are steam_app_<id>")
            fieldWidth: 320
            value: Config.options.caelestia.backgroundMute.classes
            onEdited: v => {
                try {
                    new RegExp(v);
                    Config.options.caelestia.backgroundMute.classes = v;
                } catch (e) {} // invalid pattern: keep the old one
            }
        }

        HyprSpinRow {
            key: "misc:render_unfocused_fps"
            icon: "speed"
            title: Translation.tr("Frame rate in the background (fps)")
            description: Translation.tr("For games kept running while you use another window")
            from: 1
            to: 240
            stepSize: 5
        }
    }
}
