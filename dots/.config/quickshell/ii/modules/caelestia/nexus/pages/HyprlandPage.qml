import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

// caelestia4: Hyprland options (Caelestia has none): end-4 Settings' Windows and Input pages plus options neither app
// had. Read live from Hyprland, saved to hypr/hyprland/shellOverrides/main.lua (end-4's HyprlandConfig, loaded last,
// so it wins over custom/*.lua), which Hyprland reloads on change. The same keys as end-4's Settings app, so both stay
// in step.
PageBase {
    id: root

    readonly property list<MenuItem> accelItems: [
        MenuItem {
            text: Tr.tr("Device default")
            value: ""
        },
        MenuItem {
            text: Tr.tr("Adaptive")
            value: "adaptive"
        },
        MenuItem {
            text: Tr.tr("Flat (raw, for games)")
            value: "flat"
        }
    ]

    readonly property list<MenuItem> followMouseItems: [
        MenuItem {
            text: Tr.tr("Off (click to focus)")
            value: 0
        },
        MenuItem {
            text: Tr.tr("Always")
            value: 1
        },
        MenuItem {
            text: Tr.tr("Loose (keyboard stays)")
            value: 2
        },
        MenuItem {
            text: Tr.tr("Only on click")
            value: 3
        }
    ]

    readonly property list<MenuItem> hwCursorItems: [
        MenuItem {
            text: Tr.tr("Automatic")
            value: 2
        },
        MenuItem {
            text: Tr.tr("Hardware cursor")
            value: 0
        },
        MenuItem {
            text: Tr.tr("Software cursor")
            value: 1
        }
    ]

    readonly property list<MenuItem> scanoutItems: [
        MenuItem {
            text: Tr.tr("Off")
            value: 0
        },
        MenuItem {
            text: Tr.tr("On")
            value: 1
        },
        MenuItem {
            text: Tr.tr("Games only")
            value: 2
        }
    ]

    readonly property list<MenuItem> layoutItems: [
        MenuItem {
            text: Tr.tr("Dwindle (split in two)")
            value: "dwindle"
        },
        MenuItem {
            text: Tr.tr("Master (one big window)")
            value: "master"
        }
    ]

    // caelestia4: while this file exists Super+S only toggles the scratchpad (hypr/hyprland/specialws.lua, upstream's
    // specialWsCloseAny = false). A property: PageBase's default property takes the page's one content item
    readonly property FileView scratchpadOnly: FileView {
        property bool exists

        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/caelestia4/special-ws-scratchpad-only`
        printErrors: false
        onLoaded: exists = true
        onLoadFailed: exists = false
    }

    title: Tr.tr("Hyprland")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Keyboard")
        }

        HyprTextRow {
            first: true
            key: "input:kb_layout"
            label: Tr.tr("Layouts")
            subtext: Tr.tr("Comma separated, e.g. us,de. Vietnamese typing is fcitx5 (Super+Space)")
            placeholderText: "us"
        }

        HyprTextRow {
            key: "input:kb_options"
            label: Tr.tr("Layout options")
            subtext: Tr.tr("XKB options, e.g. grp:alt_shift_toggle, caps:escape")
        }

        HyprStepperRow {
            key: "input:repeat_delay"
            label: Tr.tr("Key repeat delay (ms)")
            subtext: Tr.tr("How long to hold a key before it repeats")
            from: 100
            to: 1000
            stepSize: 25
        }

        HyprStepperRow {
            key: "input:repeat_rate"
            label: Tr.tr("Key repeat rate (per second)")
            from: 5
            to: 80
        }

        HyprToggleRow {
            last: true
            key: "input:numlock_by_default"
            text: Tr.tr("Num Lock on at login")
        }

        SectionHeader {
            text: Tr.tr("Mouse & touchpad")
        }

        HyprStepperRow {
            first: true
            key: "input:sensitivity"
            label: Tr.tr("Pointer speed")
            subtext: Tr.tr("-1 to 1; 0 = unchanged")
            from: -1
            to: 1
            stepSize: 0.05
        }

        HyprSelectRow {
            key: "input:accel_profile"
            label: Tr.tr("Acceleration")
            menuItems: root.accelItems
        }

        HyprStepperRow {
            key: "input:scroll_factor"
            label: Tr.tr("Scroll speed (mouse)")
            subtext: Tr.tr("Multiplier for external mice; 1 = unchanged")
            from: 0.2
            to: 2
            stepSize: 0.1
        }

        HyprToggleRow {
            key: "input:natural_scroll"
            text: Tr.tr("Natural scrolling (mouse)")
            subtext: Tr.tr("Content moves with the wheel, like a touchscreen")
        }

        HyprToggleRow {
            key: "input:touchpad:natural_scroll"
            text: Tr.tr("Natural scrolling (touchpad)")
        }

        HyprSelectRow {
            key: "input:follow_mouse"
            label: Tr.tr("Focus follows the mouse")
            menuItems: root.followMouseItems
        }

        HyprToggleRow {
            last: true
            key: "input:left_handed"
            text: Tr.tr("Left-handed (swap buttons)")
        }

        SectionHeader {
            text: Tr.tr("Cursor")
        }

        HyprStepperRow {
            first: true
            key: "cursor:inactive_timeout"
            label: Tr.tr("Hide after inactivity (s)")
            subtext: Tr.tr("0 = never")
            from: 0
            to: 20
        }

        HyprToggleRow {
            key: "cursor:hide_on_key_press"
            text: Tr.tr("Hide while typing")
            subtext: Tr.tr("Comes back when the mouse moves")
        }

        HyprSelectRow {
            last: true
            key: "cursor:no_hardware_cursors"
            label: Tr.tr("Software cursor")
            subtext: Tr.tr("Automatic turns it on where hardware cursors misbehave (NVIDIA)")
            menuItems: root.hwCursorItems
        }

        SectionHeader {
            text: Tr.tr("Spacing & borders")
        }

        HyprStepperRow {
            first: true
            key: "general:gaps_in"
            label: Tr.tr("Gap between windows (px)")
            from: 0
            to: 40
        }

        HyprStepperRow {
            key: "general:gaps_out"
            label: Tr.tr("Gap to the screen edge (px)")
            from: 0
            to: 60
        }

        HyprStepperRow {
            key: "general:border_size"
            label: Tr.tr("Window border (px)")
            from: 0
            to: 10
        }

        HyprStepperRow {
            last: true
            key: "decoration:rounding"
            label: Tr.tr("Window corner radius (px)")
            from: 0
            to: 40
        }

        SectionHeader {
            text: Tr.tr("Effects")
        }

        HyprStepperRow {
            first: true
            key: "decoration:active_opacity"
            label: Tr.tr("Focused window opacity")
            from: 0.3
            to: 1
            stepSize: 0.05
        }

        HyprStepperRow {
            key: "decoration:inactive_opacity"
            label: Tr.tr("Other windows opacity")
            from: 0.3
            to: 1
            stepSize: 0.05
        }

        HyprToggleRow {
            key: "decoration:dim_inactive"
            text: Tr.tr("Dim unfocused windows")
        }

        HyprToggleRow {
            key: "decoration:blur:enabled"
            text: Tr.tr("Blur behind transparent windows")
        }

        HyprStepperRow {
            key: "decoration:blur:size"
            label: Tr.tr("Blur radius")
            from: 1
            to: 20
        }

        HyprStepperRow {
            key: "decoration:blur:passes"
            label: Tr.tr("Blur passes")
            subtext: Tr.tr("More is smoother but uses more GPU")
            from: 1
            to: 6
        }

        HyprToggleRow {
            key: "decoration:shadow:enabled"
            text: Tr.tr("Window shadows")
        }

        HyprToggleRow {
            last: true
            key: "animations:enabled"
            text: Tr.tr("Window animations")
        }

        SectionHeader {
            text: Tr.tr("Windows")
        }

        HyprSelectRow {
            first: true
            key: "general:layout"
            label: Tr.tr("Tiling layout")
            menuItems: root.layoutItems
        }

        HyprToggleRow {
            key: "dwindle:preserve_split"
            text: Tr.tr("Keep split direction")
            subtext: Tr.tr("Dwindle layout: splits don't flip when windows move")
        }

        HyprToggleRow {
            key: "general:resize_on_border"
            text: Tr.tr("Resize windows by dragging their border")
        }

        HyprToggleRow {
            key: "misc:focus_on_activate"
            text: Tr.tr("Focus apps that ask for attention")
            subtext: Tr.tr("e.g. a browser opened from a link jumps to the front")
        }

        HyprToggleRow {
            key: "misc:middle_click_paste"
            text: Tr.tr("Middle-click paste")
            subtext: Tr.tr("Paste the last selected text with the middle mouse button")
        }

        ToggleRow {
            last: true
            text: Tr.tr("Super+S closes any special workspace")
            subtext: Tr.tr("Off: Super+S only shows or hides the scratchpad")
            value: !root.scratchpadOnly.exists
            onToggled: {
                if (checked)
                    Quickshell.execDetached(["rm", "-f", root.scratchpadOnly.path]);
                else
                    Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"", "sh", root.scratchpadOnly.path]);
                root.scratchpadOnly.exists = !checked;
            }
        }

        SectionHeader {
            text: Tr.tr("Rendering")
        }

        HyprSelectRow {
            first: true
            key: "render:direct_scanout"
            label: Tr.tr("Direct scanout")
            subtext: Tr.tr("Fullscreen windows go straight to the display: less latency; may flicker on some GPUs")
            menuItems: root.scanoutItems
        }

        HyprToggleRow {
            key: "general:allow_tearing"
            text: Tr.tr("Allow tearing")
            subtext: Tr.tr("Games marked \"immediate\" skip vsync for the lowest latency")
        }

        HyprToggleRow {
            last: true
            key: "xwayland:force_zero_scaling"
            text: Tr.tr("Sharp X11 apps on scaled displays")
            subtext: Tr.tr("X11 apps draw at scale 1 instead of being stretched (they may look smaller)")
        }

        // caelestia4: from end-4's Settings app (Games); VRR is on the Display page
        SectionHeader {
            text: Tr.tr("Games in the background")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Mute games while in the background")
            subtext: Tr.tr("A game's sound stops when you switch away and comes back when you click into it")
            value: E4C.Config.options.caelestia.backgroundMute.enable
            onToggled: E4C.Config.options.caelestia.backgroundMute.enable = checked
        }

        TextFieldRow {
            enabled: E4C.Config.options.caelestia.backgroundMute.enable
            label: Tr.tr("Which windows are games")
            subtext: Tr.tr("Window class pattern (regex). Steam/Proton games are steam_app_<id>")
            value: E4C.Config.options.caelestia.backgroundMute.classes
            onEditingFinished: v => {
                try {
                    new RegExp(v);
                    if (v !== value)
                        E4C.Config.options.caelestia.backgroundMute.classes = v;
                } catch (e) {} // invalid pattern: keep the old one
            }
        }

        HyprStepperRow {
            last: true
            key: "misc:render_unfocused_fps"
            label: Tr.tr("Frame rate in the background (fps)")
            subtext: Tr.tr("For games kept running while you use another window")
            from: 1
            to: 240
            stepSize: 5
        }
    }
}
