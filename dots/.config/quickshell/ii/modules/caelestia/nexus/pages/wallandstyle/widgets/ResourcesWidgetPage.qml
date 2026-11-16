pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > System resources (route appearance/desktop/widget.resources): end4-pC's
// desktop widget e4:background.widgets.resources. Rows name their registry
// setting (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("System resources")
    isSubPage: true

    // caelestia4: ToggleRow has written `enable` already (its own onToggled runs first). Turning it on goes through
    // PresetLayout again, so a new widget isn't left under another and the preset is saved
    function enableToggled(on: bool): void {
        if (on) {
            E4C.Config.options.background.widgets.resources.enable = false;
            E4.PresetLayout.setWidgetEnabled("resources", true);
        } else {
            E4.PresetLayout.requestSave();
        }
    }

    // caelestia4: the widget saves its own flip into the preset (PresetLayout.requestSave); a change made here
    // (or its reset or undo) is saved the same way, so re-applying the preset doesn't undo it
    readonly property Connections layoutSave: Connections {
        function onChangedByUser(): void {
            E4.PresetLayout.requestSave();
        }

        target: verticalRow.link.s
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            setting: "e4:background.widgets.resources.enable"
            onToggled: root.enableToggled(checked)
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: Size is in the same place on every widget page, just before Placement; this widget has one
        InfoRow {
            label: Tr.tr("Size")
            value: Tr.tr("Fixed")
            subtext: Tr.tr("This widget has one size. Widget size on the Desktop page scales all widgets")
        }

        SelectRow {
            setting: "e4:background.widgets.resources.placementStrategy"
        }

        ToggleRow {
            id: verticalRow

            setting: "e4:background.widgets.resources.vertical"
        }

        // caelestia4: how often it reads the processor and memory: shared with the overlay, so kept with the other
        // refresh rates. A plain link at the end of General (no one-row Advanced section)
        SettingLinkRow {
            nState: root.nState
            target: "e4:resources.updateInterval"
        }
    }
}
