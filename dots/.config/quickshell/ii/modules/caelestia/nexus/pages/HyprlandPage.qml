import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common

// caelestia4: Hyprland options that neither Caelestia nor end-4's Settings app had. Read live from Hyprland, saved to
// hypr/hyprland/shellOverrides/main.lua (end-4's HyprlandConfig), which Hyprland reloads on change.
PageBase {
    id: root

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
            text: Tr.tr("Keyboard & mouse")
        }

        HyprToggleRow {
            first: true
            key: "input:numlock_by_default"
            text: Tr.tr("Num Lock on at login")
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

        SectionHeader {
            text: Tr.tr("Windows")
        }

        HyprToggleRow {
            first: true
            key: "misc:middle_click_paste"
            text: Tr.tr("Middle-click paste")
            subtext: Tr.tr("Paste the last selected text with the middle mouse button")
        }

        ToggleRow {
            last: true
            text: Tr.tr("Super+S closes any special workspace")
            subtext: Tr.tr("Off: Super+S only shows or hides the scratchpad")
            checked: !root.scratchpadOnly.exists
            onToggled: {
                if (checked)
                    Quickshell.execDetached(["rm", "-f", root.scratchpadOnly.path]);
                else
                    Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"", "sh", root.scratchpadOnly.path]);
                root.scratchpadOnly.exists = !checked;
            }
        }
    }
}
