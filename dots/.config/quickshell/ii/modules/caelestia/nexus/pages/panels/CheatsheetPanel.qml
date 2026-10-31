pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (the cheatsheet's settings live in end-4's config)

// caelestia4: Panels > Keybind cheatsheet (Super+/, modules/caelestia/cheatsheet). The same keys as end-4's Settings
// app (Apps & services)
PageBase {
    id: root

    readonly property var cs: E4C.Config.options.cheatsheet

    title: Tr.tr("Keybind cheatsheet")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Keys")
        }

        ToggleRow {
            first: true
            text: Tr.tr("macOS-style key symbols")
            subtext: Tr.tr("⌘ ⌥ ⇧ instead of Super, Alt, Shift")
            value: root.cs.useMacSymbol
            onToggled: root.cs.useMacSymbol = checked
        }

        ToggleRow {
            text: Tr.tr("Symbols for function keys")
            value: root.cs.useFnSymbol
            onToggled: root.cs.useFnSymbol = checked
        }

        ToggleRow {
            text: Tr.tr("Symbols for mouse buttons")
            value: root.cs.useMouseSymbol
            onToggled: root.cs.useMouseSymbol = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("One key per box")
            value: root.cs.splitButtons
            onToggled: root.cs.splitButtons = checked
        }
    }
}
