import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of HyprlandPage (route hyprland/windows): spacing, effects and window behaviour. Rows take
// title, range and default from registry/RegHyprland.qml and save to the shell overrides file (HyprlandConfig)
PageBase {
    id: root

    // caelestia4: while this file exists Super+S only toggles the scratchpad (hypr/hyprland/specialws.lua, upstream's
    // specialWsCloseAny = false). A property: PageBase's default property takes the page's one content item
    readonly property FileView scratchpadOnly: FileView {
        property bool exists

        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/caelestia4/special-ws-scratchpad-only`
        printErrors: false
        onLoaded: exists = true
        onLoadFailed: exists = false
    }

    function setCloseAny(on: bool): void {
        if (on)
            Quickshell.execDetached(["rm", "-f", root.scratchpadOnly.path]);
        else
            Quickshell.execDetached(["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"", "sh", root.scratchpadOnly.path]);
        root.scratchpadOnly.exists = !on;
    }

    // gaps_in/gaps_out are CSS-style ("4 4 4 4"): show the first number
    function firstNumber(v: var): real {
        return parseFloat(v) || 0;
    }

    // The x: setting behind the Super+S row: its value is the file's absence; writes create or remove the file
    readonly property Connections closeAnyHandler: Connections {
        function onCustomSet(v: var): void {
            root.setCloseAny(!!v);
        }

        function onCustomReset(): void {
            root.setCloseAny(true);
        }

        target: closeAny.link.s
    }
    readonly property Binding closeAnyValue: Binding {
        target: closeAny.link.s
        property: "customValue"
        value: !root.scratchpadOnly.exists
    }
    readonly property Binding closeAnyDefault: Binding {
        target: closeAny.link.s
        property: "customDefault"
        value: true
    }

    title: Tr.tr("Windows & effects")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Spacing & borders")
        }

        StepperRow {
            setting: "h:general:gaps_in"
            value: root.firstNumber(link.shownValue)
        }

        StepperRow {
            setting: "h:general:gaps_out"
            value: root.firstNumber(link.shownValue)
        }

        StepperRow {
            setting: "h:general:border_size"
        }

        StepperRow {
            setting: "h:decoration:rounding"
        }

        SectionHeader {
            text: Tr.tr("Effects")
        }

        StepperRow {
            setting: "h:decoration:active_opacity"
        }

        StepperRow {
            setting: "h:decoration:inactive_opacity"
        }

        ToggleRow {
            setting: "h:decoration:dim_inactive"
        }

        ToggleRow {
            setting: "h:decoration:blur:enabled"
        }

        StepperRow {
            setting: "h:decoration:blur:size"
        }

        StepperRow {
            setting: "h:decoration:blur:passes"
        }

        ToggleRow {
            setting: "h:decoration:shadow:enabled"
        }

        ToggleRow {
            setting: "h:animations:enabled"
        }

        SectionHeader {
            text: Tr.tr("Tiling & focus")
        }

        SelectRow {
            setting: "h:general:layout"
        }

        ToggleRow {
            setting: "h:dwindle:preserve_split"
        }

        ToggleRow {
            setting: "h:general:resize_on_border"
        }

        ToggleRow {
            setting: "h:misc:focus_on_activate"
        }

        ToggleRow {
            setting: "h:misc:middle_click_paste"
        }

        ToggleRow {
            id: closeAny

            setting: "x:hyprland.specialWsCloseAny"
        }
    }
}
