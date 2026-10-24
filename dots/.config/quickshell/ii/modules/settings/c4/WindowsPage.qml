import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Windows & workspaces — Hyprland look and behaviour (wiki: Configuring/Variables). Values are read live
// from Hyprland and saved to hypr/hyprland/shellOverrides/main.lua, which loads last, so they win over custom/*.lua.
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "space_dashboard"
        title: Translation.tr("Spacing & borders")

        HyprSpinRow {
            key: "general:gaps_in"
            icon: "border_inner"
            title: Translation.tr("Gap between windows (px)")
            from: 0
            to: 40
        }

        HyprSpinRow {
            key: "general:gaps_out"
            icon: "border_outer"
            title: Translation.tr("Gap to the screen edge (px)")
            from: 0
            to: 60
        }

        HyprSpinRow {
            key: "general:border_size"
            icon: "border_style"
            title: Translation.tr("Window border (px)")
            from: 0
            to: 10
        }

        HyprSpinRow {
            key: "decoration:rounding"
            icon: "rounded_corner"
            title: Translation.tr("Window corner radius (px)")
            from: 0
            to: 40
        }
    }

    ContentSection {
        icon: "blur_on"
        title: Translation.tr("Effects")

        HyprSliderRow {
            key: "decoration:active_opacity"
            icon: "opacity"
            title: Translation.tr("Focused window opacity")
            from: 0.3
            to: 1
            format: v => `${Math.round(v * 100)} %`
        }

        HyprSliderRow {
            key: "decoration:inactive_opacity"
            icon: "opacity"
            title: Translation.tr("Other windows opacity")
            from: 0.3
            to: 1
            format: v => `${Math.round(v * 100)} %`
        }

        HyprSwitchRow {
            key: "decoration:dim_inactive"
            icon: "brightness_low"
            title: Translation.tr("Dim unfocused windows")
        }

        HyprSwitchRow {
            key: "decoration:blur:enabled"
            icon: "blur_on"
            title: Translation.tr("Blur behind transparent windows")
        }

        HyprSpinRow {
            key: "decoration:blur:size"
            icon: "lens_blur"
            title: Translation.tr("Blur radius")
            from: 1
            to: 20
        }

        HyprSpinRow {
            key: "decoration:blur:passes"
            icon: "layers"
            title: Translation.tr("Blur passes")
            description: Translation.tr("More is smoother but uses more GPU")
            from: 1
            to: 6
        }

        HyprSwitchRow {
            key: "decoration:shadow:enabled"
            icon: "shadow"
            title: Translation.tr("Window shadows")
        }

        HyprSwitchRow {
            key: "animations:enabled"
            icon: "animation"
            title: Translation.tr("Window animations")
        }
    }

    ContentSection {
        icon: "dashboard"
        title: Translation.tr("Behaviour")

        HyprChoiceRow {
            key: "general:layout"
            icon: "view_quilt"
            title: Translation.tr("Tiling layout")
            options: [
                {
                    label: Translation.tr("Dwindle (split in two)"),
                    value: "dwindle"
                },
                {
                    label: Translation.tr("Master (one big window)"),
                    value: "master"
                }
            ]
        }

        HyprSwitchRow {
            key: "general:resize_on_border"
            icon: "open_in_full"
            title: Translation.tr("Resize windows by dragging their border")
        }

        HyprSwitchRow {
            key: "misc:focus_on_activate"
            icon: "ads_click"
            title: Translation.tr("Focus apps that ask for attention")
            description: Translation.tr("e.g. a browser opened from a link jumps to the front")
        }

        HyprSwitchRow {
            key: "dwindle:preserve_split"
            icon: "splitscreen"
            title: Translation.tr("Keep split direction")
            description: Translation.tr("Dwindle layout: splits don't flip when windows move")
        }
    }
}
