import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Advanced — panel family, terminal colour tuning, polling, network identity, config files.
ContentPage {
    forceWidth: true

    readonly property list<string> hyprKeys: ["general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "decoration:active_opacity", "decoration:inactive_opacity", "decoration:dim_inactive", "decoration:blur:enabled", "decoration:blur:size", "decoration:blur:passes", "decoration:shadow:enabled", "animations:enabled", "general:layout", "general:resize_on_border", "misc:focus_on_activate", "dwindle:preserve_split", "input:kb_layout", "input:kb_options", "input:repeat_delay", "input:repeat_rate", "input:sensitivity", "input:accel_profile", "input:natural_scroll", "input:touchpad:natural_scroll", "input:follow_mouse", "misc:vrr", "misc:render_unfocused_fps"]

    function open(path): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    ContentSection {
        icon: "dashboard_customize"
        title: Translation.tr("Panels")

        ChoiceRow {
            icon: "swap_horiz"
            title: Translation.tr("Panel set")
            description: Translation.tr("end-4's own panels are a fallback if something in the Caelestia panels breaks (Ctrl+Super+P switches)")
            options: [
                {
                    label: Translation.tr("Caelestia"),
                    value: "caelestia"
                },
                {
                    label: Translation.tr("end-4 (fallback)"),
                    value: "ii"
                }
            ]
            value: Config.options.panelFamily
            onSelected: v => Config.options.panelFamily = v
        }
    }

    ContentSection {
        icon: "terminal"
        title: Translation.tr("Terminal colours")

        SwitchRow {
            icon: "dark_mode"
            title: Translation.tr("Always dark terminal")
            description: Translation.tr("Even when the shell is in light mode")
            checked: Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
            onToggled: v => Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = v
        }

        SpinRow {
            icon: "join"
            title: Translation.tr("Colour harmony (%)")
            description: Translation.tr("How much terminal colours lean towards the wallpaper colour")
            from: 0
            to: 100
            value: Math.round(Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100)
            onMoved: v => Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = v / 100
        }

        SpinRow {
            icon: "contrast"
            title: Translation.tr("Text brightness boost (%)")
            from: 0
            to: 100
            value: Math.round(Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100)
            onMoved: v => Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = v / 100
        }
    }

    ContentSection {
        icon: "settings_ethernet"
        title: Translation.tr("Services")

        SpinRow {
            icon: "monitor_heart"
            title: Translation.tr("CPU / memory refresh (ms)")
            from: 500
            to: 10000
            stepSize: 250
            value: Config.options.resources.updateInterval
            onMoved: v => Config.options.resources.updateInterval = v
        }

        TextRow {
            icon: "badge"
            title: Translation.tr("Web user agent")
            description: Translation.tr("Sent to services that require one (image boards, weather)")
            fieldWidth: 340
            value: Config.options.networking.userAgent
            onEdited: v => Config.options.networking.userAgent = v
        }
    }

    ContentSection {
        icon: "description"
        title: Translation.tr("Config files")

        ButtonRow {
            icon: "data_object"
            title: Translation.tr("Shell settings (end-4 part)")
            description: "~/.config/illogical-impulse/config.json"
            buttonIcon: "open_in_new"
            buttonText: Translation.tr("Open")
            onClicked: open(`${Directories.config}/illogical-impulse/config.json`)
        }

        ButtonRow {
            icon: "data_object"
            title: Translation.tr("Panel settings (Caelestia part)")
            description: "~/.config/caelestia/shell.json"
            buttonIcon: "open_in_new"
            buttonText: Translation.tr("Open")
            onClicked: open(`${Directories.config}/caelestia/shell.json`)
        }

        ButtonRow {
            icon: "folder_open"
            title: Translation.tr("Your Hyprland config")
            description: Translation.tr("~/.config/hypr/custom: keybinds, rules, startup apps")
            buttonIcon: "open_in_new"
            buttonText: Translation.tr("Open")
            onClicked: open(`${Directories.config}/hypr/custom`)
        }

        ButtonRow {
            icon: "restart_alt"
            title: Translation.tr("Reset window, input and display options")
            description: Translation.tr("Undo everything changed on the Windows, Input, Display and Games pages")
            buttonIcon: "restart_alt"
            buttonText: Translation.tr("Reset")
            onClicked: HyprlandConfig.resetMany(hyprKeys)
        }
    }
}
