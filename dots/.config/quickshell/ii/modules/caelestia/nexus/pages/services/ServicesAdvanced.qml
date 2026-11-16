pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of ServicesPage (route services/advanced): end-4's Advanced options and the config files.
// Setting rows name registry ids (registry/RegServices.qml)
PageBase {
    id: root

    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`

    title: Tr.tr("Advanced")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: end-4's scroll handling in the shell's lists (StyledFlickable / StyledListView)
        SectionHeader {
            text: Tr.tr("Scrolling")
        }

        ToggleRow {
            setting: "e4:interactions.scrolling.fasterTouchpadScroll"
        }

        SliderRow {
            setting: "e4:interactions.scrolling.mouseScrollFactor"
        }

        SliderRow {
            setting: "e4:interactions.scrolling.touchpadScrollFactor"
        }

        // caelestia4: no Advanced section on this page (it is the advanced page): the finer rows sit in their groups
        StepperRow {
            setting: "e4:interactions.scrolling.mouseScrollDeltaThreshold"
        }

        SliderRow {
            setting: "e4:interactions.scrolling.touchpadSensitivity"
        }

        // caelestia4: ConflictKiller runs once at startup (shell.qml)
        SectionHeader {
            text: Tr.tr("Conflicting programs")
        }

        ToggleRow {
            setting: "e4:conflictKiller.autoKillNotificationDaemons"
        }

        ToggleRow {
            setting: "e4:windows.showTitlebar"
        }

        ToggleRow {
            setting: "e4:windows.centerTitle"
        }

        SectionHeader {
            text: Tr.tr("Network")
        }

        TextFieldRow {
            setting: "e4:networking.userAgent"
        }

        SectionHeader {
            text: Tr.tr("Workarounds")
        }

        DurationRow {
            setting: "e4:hacks.arbitraryRaceConditionDelay"
            maxUnit: "s"
        }

        SectionHeader {
            text: Tr.tr("Config files")
        }

        RowButton {
            icon: "data_object"
            text: Tr.tr("Shell settings file")
            subtext: "~/.config/illogical-impulse/config.json"
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/illogical-impulse/config.json`])
        }

        RowButton {
            icon: "data_object"
            text: Tr.tr("Panel settings file")
            subtext: "~/.config/caelestia/shell.json"
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/caelestia/shell.json`])
        }

        RowButton {
            icon: "folder_open"
            text: Tr.tr("Your Hyprland config")
            subtext: Tr.tr("~/.config/hypr/custom: keybinds, rules, startup apps")
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/hypr/custom`])
        }
    }
}
