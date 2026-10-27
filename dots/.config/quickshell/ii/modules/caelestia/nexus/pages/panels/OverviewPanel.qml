pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (overview, overlay and crosshair live in end-4's config)

// caelestia4: Panels > Overview & overlay: the workspace overview (Super+Tab / Alt+Tab), the overlay widgets (Super+G)
// and its crosshair. The same keys as end-4's Settings app (Desktop)
PageBase {
    id: root

    title: Tr.tr("Overview & overlay")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("Workspace overview")
        }

        StepperRow {
            first: true
            label: Tr.tr("Rows")
            value: E4C.Config.options.overview.rows
            from: 1
            to: 5
            onMoved: v => E4C.Config.options.overview.rows = v
        }

        StepperRow {
            label: Tr.tr("Columns")
            value: E4C.Config.options.overview.columns
            from: 1
            to: 10
            onMoved: v => E4C.Config.options.overview.columns = v
        }

        StepperRow {
            label: Tr.tr("Preview size (% of screen)")
            value: Math.round(E4C.Config.options.overview.scale * 100)
            from: 5
            to: 40
            onMoved: v => E4C.Config.options.overview.scale = v / 100
        }

        ToggleRow {
            last: true
            text: Tr.tr("Alt+Tab skips empty workspaces")
            subtext: Tr.tr("Hold Alt, press Tab to step through workspaces, release Alt to switch")
            checked: E4C.Config.options.caelestia.overview.altTabSkipEmpty
            onToggled: E4C.Config.options.caelestia.overview.altTabSkipEmpty = checked
        }

        SectionHeader {
            text: Tr.tr("Overlay widgets (Super+G)")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Darken the screen behind")
            checked: E4C.Config.options.overlay.darkenScreen
            onToggled: E4C.Config.options.overlay.darkenScreen = checked
        }

        ToggleRow {
            text: Tr.tr("Zoom animation when opening")
            checked: E4C.Config.options.overlay.openingZoomAnimation
            onToggled: E4C.Config.options.overlay.openingZoomAnimation = checked
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Crosshair code")
            subtext: Tr.tr("In Valorant's format")
            value: E4C.Config.options.crosshair.code
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.crosshair.code = v;
            }
        }
    }
}
