import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of HyprlandPage (route hyprland/input): keyboard, mouse, touchpad and cursor options. Rows take
// title, range and default from registry/RegHyprland.qml and save to the shell overrides file (HyprlandConfig).
// Sections: Keyboard, Mouse, Cursor, Touchpad (only a note when there is none), then Advanced (rarely changed keyboard
// and cursor options)
PageBase {
    id: root

    // caelestia4: whether a touchpad is connected (read-only `hyprctl devices -j`: Hyprland lists touchpads with the
    // mice). Unknown (the command failed) counts as yes, so the rows only hide when we know there is none
    property bool hasTouchpad: true
    // caelestia4: a search result or link to a touchpad row shows the rows even with no touchpad (latched, since
    // landing clears focusKey)
    property bool _touchpadAsked
    readonly property bool showTouchpad: hasTouchpad || _touchpadAsked
    readonly property var touchpadIds: ["h:input:touchpad:tap_to_click", "h:input:touchpad:clickfinger_behavior", "h:input:touchpad:disable_while_typing", "h:input:touchpad:natural_scroll", "h:input:touchpad:scroll_factor", "h:gestures:workspace_swipe_invert", "h:gestures:workspace_swipe_create_new"]

    readonly property Connections focusWatch: Connections {
        target: root.nState
        function onFocusKeyChanged(): void {
            root._checkTouchpadAsked();
        }
    }

    function _checkTouchpadAsked(): void {
        if (root.touchpadIds.includes(root.nState?.focusKey ?? ""))
            root._touchpadAsked = true;
    }

    Component.onCompleted: _checkTouchpadAsked()
    // A touchpad plugged in later: look again each time the page is opened
    onIsCurrentChanged: if (isCurrent && !touchpadScan.running)
        touchpadScan.running = true

    // As a property: PageBase's default property takes the page's one content item
    readonly property Process touchpadScan: Process {
        running: true
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const mice = JSON.parse(text).mice ?? [];
                    root.hasTouchpad = mice.some(m => /touchpad|trackpad|synaptics|glidepoint/i.test(m.name ?? ""));
                } catch (e) {
                    root.hasTouchpad = true;
                }
            }
        }
    }

    title: Tr.tr("Keyboard, mouse & touchpad")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Keyboard")
        }

        TextFieldRow {
            setting: "h:input:kb_layout"
            placeholderText: "us"
        }

        StepperRow {
            setting: "h:input:repeat_delay"
        }

        StepperRow {
            setting: "h:input:repeat_rate"
        }

        ToggleRow {
            setting: "h:input:numlock_by_default"
        }

        SectionHeader {
            text: Tr.tr("Mouse")
        }

        StepperRow {
            setting: "h:input:sensitivity"
        }

        SelectRow {
            setting: "h:input:accel_profile"
        }

        StepperRow {
            setting: "h:input:scroll_factor"
        }

        ToggleRow {
            setting: "h:input:natural_scroll"
        }

        SelectRow {
            setting: "h:input:follow_mouse"
        }

        ToggleRow {
            setting: "h:input:left_handed"
        }

        SectionHeader {
            text: Tr.tr("Cursor")
        }

        StepperRow {
            setting: "h:cursor:inactive_timeout"
        }

        ToggleRow {
            setting: "h:cursor:hide_on_key_press"
        }

        SectionHeader {
            text: Tr.tr("Touchpad")
        }

        // caelestia4: with no touchpad the section is only this note (the rows come back when one is connected)
        InfoRow {
            visible: !root.showTouchpad
            icon: "info"
            label: Tr.tr("No touchpad found")
            subtext: Tr.tr("Touchpad settings show here once a touchpad is connected")
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:input:touchpad:tap_to_click"
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:input:touchpad:clickfinger_behavior"
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:input:touchpad:disable_while_typing"
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:input:touchpad:natural_scroll"
        }

        StepperRow {
            visible: root.showTouchpad
            setting: "h:input:touchpad:scroll_factor"
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:gestures:workspace_swipe_invert"
        }

        ToggleRow {
            visible: root.showTouchpad
            setting: "h:gestures:workspace_swipe_create_new"
        }

        AdvancedSection {
            TextFieldRow {
                setting: "h:input:kb_variant"
            }

            TextFieldRow {
                setting: "h:input:kb_options"
            }

            // Risky: a broken cursor can leave you without a pointer, so a change reverts after 10 s unless kept
            SelectRow {
                id: hwCursor

                setting: "h:cursor:no_hardware_cursors"
            }

            KeepRevert {
                link: hwCursor.link
            }
        }
    }
}
