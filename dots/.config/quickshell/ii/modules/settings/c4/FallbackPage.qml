import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: end-4 panels (fallback) — settings that only affect end-4's own panel set (Ctrl+Super+P). They do
// nothing while the Caelestia panels are active.
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "info"
        title: Translation.tr("About this page")

        SettingRow {
            icon: "swap_horiz"
            title: Config.options.panelFamily === "ii" ? Translation.tr("end-4 panels are active") : Translation.tr("Not in use right now")
            description: Translation.tr("These settings only apply to end-4's own panels, the fallback set (Advanced > Panel set, or Ctrl+Super+P)")
        }
    }

    ContentSection {
        icon: "toast"
        title: Translation.tr("end-4 bar")

        ChoiceRow {
            icon: "vertical_align_top"
            title: Translation.tr("Position")
            options: [
                {
                    label: Translation.tr("Top"),
                    value: false
                },
                {
                    label: Translation.tr("Bottom"),
                    value: true
                }
            ]
            value: Config.options.bar.bottom
            onSelected: v => Config.options.bar.bottom = v
        }

        ChoiceRow {
            icon: "rounded_corner"
            title: Translation.tr("Shape")
            options: [
                {
                    label: Translation.tr("Hug the screen corners"),
                    value: 0
                },
                {
                    label: Translation.tr("Floating"),
                    value: 1
                },
                {
                    label: Translation.tr("Plain rectangle"),
                    value: 2
                }
            ]
            value: Config.options.bar.cornerStyle
            onSelected: v => Config.options.bar.cornerStyle = v
        }

        SwitchRow {
            icon: "visibility_off"
            title: Translation.tr("Hide automatically")
            checked: Config.options.bar.autoHide.enable
            onToggled: v => Config.options.bar.autoHide.enable = v
        }

        SwitchRow {
            icon: "partly_cloudy_day"
            title: Translation.tr("Weather on the bar")
            checked: Config.options.bar.weather.enable
            onToggled: v => Config.options.bar.weather.enable = v
        }

        SwitchRow {
            icon: "screenshot_region"
            title: Translation.tr("Screenshot button")
            checked: Config.options.bar.utilButtons.showScreenSnip
            onToggled: v => Config.options.bar.utilButtons.showScreenSnip = v
        }

        SwitchRow {
            icon: "keyboard"
            title: Translation.tr("On-screen keyboard button")
            checked: Config.options.bar.utilButtons.showKeyboardToggle
            onToggled: v => Config.options.bar.utilButtons.showKeyboardToggle = v
        }

        SwitchRow {
            icon: "dark_mode"
            title: Translation.tr("Dark / light button")
            checked: Config.options.bar.utilButtons.showDarkModeToggle
            onToggled: v => Config.options.bar.utilButtons.showDarkModeToggle = v
        }

        SpinRow {
            icon: "filter_9_plus"
            title: Translation.tr("Workspaces shown")
            from: 1
            to: 20
            value: Config.options.bar.workspaces.shown
            onMoved: v => Config.options.bar.workspaces.shown = v
        }
    }

    ContentSection {
        icon: "texture"
        title: Translation.tr("end-4 desktop widgets")

        SwitchRow {
            icon: "schedule"
            title: Translation.tr("Desktop clock")
            checked: Config.options.background.widgets.clock.enable
            onToggled: v => Config.options.background.widgets.clock.enable = v
        }

        ChoiceRow {
            enabled: Config.options.background.widgets.clock.enable
            icon: "style"
            title: Translation.tr("Clock style")
            options: [
                {
                    label: Translation.tr("Cookie"),
                    value: "cookie"
                },
                {
                    label: Translation.tr("Digital"),
                    value: "digital"
                }
            ]
            value: Config.options.background.widgets.clock.style
            onSelected: v => Config.options.background.widgets.clock.style = v
        }

        SwitchRow {
            icon: "partly_cloudy_day"
            title: Translation.tr("Desktop weather")
            checked: Config.options.background.widgets.weather.enable
            onToggled: v => Config.options.background.widgets.weather.enable = v
        }

        SwitchRow {
            icon: "3d_rotation"
            title: Translation.tr("Wallpaper moves with workspaces")
            checked: Config.options.background.parallax.enableWorkspace
            onToggled: v => Config.options.background.parallax.enableWorkspace = v
        }

        ChoiceRow {
            icon: "rounded_corner"
            title: Translation.tr("Rounded screen corners")
            options: [
                {
                    label: Translation.tr("Never"),
                    value: 0
                },
                {
                    label: Translation.tr("Always"),
                    value: 1
                },
                {
                    label: Translation.tr("Except fullscreen"),
                    value: 2
                }
            ]
            value: Config.options.appearance.fakeScreenRounding
            onSelected: v => Config.options.appearance.fakeScreenRounding = v
        }
    }

    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("end-4 dock, sidebars and popups")

        SwitchRow {
            icon: "dock_to_bottom"
            title: Translation.tr("end-4 dock")
            checked: Config.options.dock.enable
            onToggled: v => Config.options.dock.enable = v
        }

        ChoiceRow {
            icon: "toggle_on"
            title: Translation.tr("Quick toggle style")
            options: [
                {
                    label: Translation.tr("Android"),
                    value: "android"
                },
                {
                    label: Translation.tr("Classic"),
                    value: "classic"
                }
            ]
            value: Config.options.sidebar.quickToggles.style
            onSelected: v => Config.options.sidebar.quickToggles.style = v
        }

        SwitchRow {
            icon: "touch_app"
            title: Translation.tr("Open sidebars from screen corners")
            checked: Config.options.sidebar.cornerOpen.enable
            onToggled: v => Config.options.sidebar.cornerOpen.enable = v
        }

        SpinRow {
            icon: "hourglass_empty"
            title: Translation.tr("Notification popup duration (ms)")
            from: 1000
            to: 30000
            stepSize: 500
            value: Config.options.notifications.timeout
            onMoved: v => Config.options.notifications.timeout = v
        }

        SpinRow {
            icon: "tune"
            title: Translation.tr("Volume / brightness popup duration (ms)")
            from: 500
            to: 10000
            stepSize: 250
            value: Config.options.osd.timeout
            onMoved: v => Config.options.osd.timeout = v
        }
    }

    ContentSection {
        icon: "lock"
        title: Translation.tr("Shell lock screen (when hyprlock is off)")

        SwitchRow {
            icon: "key"
            title: Translation.tr("Unlock the keyring on login")
            description: Translation.tr("Lets browsers and the AI panel read saved passwords after unlocking")
            checked: Config.options.lock.security.unlockKeyring
            onToggled: v => Config.options.lock.security.unlockKeyring = v
        }

        SwitchRow {
            icon: "power_settings_new"
            title: Translation.tr("Ask for the password to power off")
            checked: Config.options.lock.security.requirePasswordToPower
            onToggled: v => Config.options.lock.security.requirePasswordToPower = v
        }

        SwitchRow {
            icon: "blur_on"
            title: Translation.tr("Blurred wallpaper")
            checked: Config.options.lock.blur.enable
            onToggled: v => Config.options.lock.blur.enable = v
        }

        SwitchRow {
            icon: "center_focus_strong"
            title: Translation.tr("Clock in the centre")
            checked: Config.options.lock.centerClock
            onToggled: v => Config.options.lock.centerClock = v
        }
    }
}
