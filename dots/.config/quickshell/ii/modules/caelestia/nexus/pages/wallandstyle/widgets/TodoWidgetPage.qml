pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > To-do list (route appearance/desktop/widget.todo): end4-pC's desktop widget
// e4:background.widgets.todo. Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("To-do list")
    isSubPage: true

    // caelestia4: the row's undo step writes `enable` back by itself, and once this page is closed nothing sends that
    // through PresetLayout (no preset save, no shift off another widget). So after the row records its step (or its
    // reset's), its undo is swapped for one through PresetLayout. It holds no reference to this page
    function undoThroughPreset(on: bool): void {
        if (NexusActions.undoing)
            return;
        const pl = E4.PresetLayout;
        const before = NexusActions.steps[NexusActions.steps.length - 1];
        Qt.callLater(() => {
            const step = NexusActions.steps[NexusActions.steps.length - 1];
            if (step && step !== before)
                step.undoFn = () => pl.setWidgetEnabled("todo", on);
        });
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.todo.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.todo.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("todo", !!newValue);
                    root.undoThroughPreset(!!oldValue);
                }

                target: enableRow.link.s
            }
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
            setting: "e4:background.widgets.todo.placementStrategy"
        }

        // caelestia4: no Advanced section: the list has no other options (you add items on the widget)
    }
}
