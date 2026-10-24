import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Input — keyboard and mouse (Hyprland input:*). Vietnamese typing is fcitx5 (Super+Space), not a layout.
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keyboard")

        HyprTextRow {
            key: "input:kb_layout"
            icon: "language"
            title: Translation.tr("Layouts")
            description: Translation.tr("Comma separated, e.g. us,de. Vietnamese typing is fcitx5 (Super+Space)")
            fieldWidth: 200
        }

        HyprTextRow {
            key: "input:kb_options"
            icon: "settings"
            title: Translation.tr("Layout options")
            description: Translation.tr("XKB options, e.g. grp:alt_shift_toggle, caps:escape")
            fieldWidth: 300
        }

        HyprSpinRow {
            key: "input:repeat_delay"
            icon: "timer"
            title: Translation.tr("Key repeat delay (ms)")
            description: Translation.tr("How long to hold a key before it repeats")
            from: 100
            to: 1000
            stepSize: 25
        }

        HyprSpinRow {
            key: "input:repeat_rate"
            icon: "speed"
            title: Translation.tr("Key repeat rate (per second)")
            from: 5
            to: 80
        }

        HyprSwitchRow {
            key: "input:numlock_by_default"
            icon: "dialpad"
            title: Translation.tr("Num Lock on at login")
        }
    }

    ContentSection {
        icon: "mouse"
        title: Translation.tr("Mouse & touchpad")

        HyprSliderRow {
            key: "input:sensitivity"
            icon: "speed"
            title: Translation.tr("Pointer speed")
            from: -1
            to: 1
            format: v => (v > 0 ? "+" : "") + (Math.round(v * 100) / 100)
        }

        HyprChoiceRow {
            key: "input:accel_profile"
            icon: "trending_up"
            title: Translation.tr("Acceleration")
            options: [
                {
                    label: Translation.tr("Device default"),
                    value: ""
                },
                {
                    label: Translation.tr("Adaptive"),
                    value: "adaptive"
                },
                {
                    label: Translation.tr("Flat (raw, for games)"),
                    value: "flat"
                }
            ]
        }

        HyprSwitchRow {
            key: "input:natural_scroll"
            icon: "swap_vert"
            title: Translation.tr("Natural scrolling (mouse)")
            description: Translation.tr("Content moves with the wheel, like a touchscreen")
        }

        HyprSwitchRow {
            key: "input:touchpad:natural_scroll"
            icon: "touch_app"
            title: Translation.tr("Natural scrolling (touchpad)")
        }

        HyprChoiceRow {
            key: "input:follow_mouse"
            icon: "ads_click"
            title: Translation.tr("Focus follows the mouse")
            options: [
                {
                    label: Translation.tr("Off (click to focus)"),
                    value: 0
                },
                {
                    label: Translation.tr("Always"),
                    value: 1
                },
                {
                    label: Translation.tr("Loose (keyboard stays)"),
                    value: 2
                },
                {
                    label: Translation.tr("Only on click"),
                    value: 3
                }
            ]
        }

        HyprSliderRow {
            key: "input:scroll_factor"
            icon: "swap_vert"
            title: Translation.tr("Scroll speed (mouse)")
            description: Translation.tr("Multiplier for external mice; 1 = unchanged")
            from: 0.2
            to: 2
            stepSize: 0.1
        }

        HyprSwitchRow {
            key: "input:left_handed"
            icon: "back_hand"
            title: Translation.tr("Left-handed (swap buttons)")
        }
    }

    ContentSection {
        icon: "arrow_selector_tool"
        title: Translation.tr("Cursor")

        HyprSpinRow {
            key: "cursor:inactive_timeout"
            icon: "visibility_off"
            title: Translation.tr("Hide after inactivity (s)")
            description: Translation.tr("0 = never")
            from: 0
            to: 20
        }

        HyprSwitchRow {
            key: "cursor:hide_on_key_press"
            icon: "keyboard"
            title: Translation.tr("Hide while typing")
            description: Translation.tr("Comes back when the mouse moves")
        }

        HyprChoiceRow {
            key: "cursor:no_hardware_cursors"
            icon: "memory"
            title: Translation.tr("Software cursor")
            description: Translation.tr("Draw the cursor in software; Auto turns it on where hardware cursors misbehave (NVIDIA)")
            options: [
                {
                    label: Translation.tr("Automatic"),
                    value: 2
                },
                {
                    label: Translation.tr("Hardware cursor"),
                    value: 0
                },
                {
                    label: Translation.tr("Software cursor"),
                    value: 1
                }
            ]
        }
    }
}
