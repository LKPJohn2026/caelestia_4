pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (the dock's settings live in end-4's config)

// caelestia4: Panels > Dock (modules/caelestia/dock: a Caelestia-style dock with end-4's dock features). The same keys
// as end-4's Settings app (Desktop > Dock)
PageBase {
    id: root

    readonly property var dock: E4C.Config.options.caelestia.dock

    title: Tr.tr("Dock")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Enabled", "toggle label")
            checked: root.dock.enable
            onToggled: root.dock.enable = checked
        }

        ToggleRow {
            disabled: !root.dock.enable
            text: Tr.tr("Keep shown after login")
            subtext: Tr.tr("Off: the dock stays hidden until you reveal it")
            checked: root.dock.pinnedOnStartup
            onToggled: root.dock.pinnedOnStartup = checked
        }

        ToggleRow {
            disabled: !root.dock.enable
            text: Tr.tr("Reveal at the bottom edge")
            checked: root.dock.hoverToReveal
            onToggled: root.dock.hoverToReveal = checked
        }

        ToggleRow {
            disabled: !root.dock.enable
            text: Tr.tr("Show on empty workspaces")
            checked: root.dock.revealOnEmptyWorkspace
            onToggled: root.dock.revealOnEmptyWorkspace = checked
        }

        StepperRow {
            enabled: root.dock.enable
            label: Tr.tr("Icon size (px)")
            value: root.dock.iconSize
            from: 24
            to: 96
            stepSize: 2
            onMoved: v => root.dock.iconSize = v
        }

        TextFieldRow {
            last: true
            enabled: root.dock.enable
            label: Tr.tr("Pinned apps")
            subtext: Tr.tr("App IDs, comma separated (e.g. atlas, kitty)")
            value: (E4C.Config.options.dock.pinnedApps ?? []).join(", ")
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.dock.pinnedApps = v.split(",").map(s => s.trim()).filter(s => s.length > 0);
            }
        }
    }
}
