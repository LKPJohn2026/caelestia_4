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
    }
}
