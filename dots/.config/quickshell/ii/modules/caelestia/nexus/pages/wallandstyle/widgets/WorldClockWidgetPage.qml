pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > World clock (route appearance/desktop/widget.worldClock): end4-pC's desktop
// widget e4:background.widgets.worldClock. Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("World clock")
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
                step.undoFn = () => pl.setWidgetEnabled("worldClock", on);
        });
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.worldClock.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.worldClock.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("worldClock", !!newValue);
                    root.undoThroughPreset(!!oldValue);
                }

                target: enableRow.link.s
            }
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: Size is in the same place on every widget page, just before Placement: buttons for named
        // sizes, a stepper for pixels, "Fixed" for a widget with one size
        SegmentedRow {
            stacked: true
            setting: "e4:background.widgets.worldClock.sizeMode"
        }

        SelectRow {
            setting: "e4:background.widgets.worldClock.placementStrategy"
        }

        ToggleRow {
            // caelestia4: the registry asks only for the row layout; the widget also needs two clocks or more
            // (one clock looks the same stacked)
            readonly property bool fewClocks: !link.blocked && (E4C.Config.options.background.widgets.worldClock.clockCount ?? 1) < 2

            setting: "e4:background.widgets.worldClock.vertical"
            disabled: fewClocks
            subtext: fewClocks ? Tr.tr("Needs two clocks or more") : link.desc
        }

        SectionHeader {
            text: Tr.tr("Clocks")
        }

        KeyValueListRow {
            setting: "e4:background.widgets.worldClock.timezones"
        }

        StepperRow {
            setting: "e4:background.widgets.worldClock.clockCount"
        }

        // caelestia4: no Advanced section: every option of the world clock is above
    }
}
