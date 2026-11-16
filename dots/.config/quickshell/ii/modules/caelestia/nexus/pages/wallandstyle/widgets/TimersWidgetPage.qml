pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Timers (route appearance/desktop/widget.timers): end4-pC's desktop widget
// e4:background.widgets.timers. Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("Timers")
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
                step.undoFn = () => pl.setWidgetEnabled("timers", on);
        });
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.timers.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.timers.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("timers", !!newValue);
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
            setting: "e4:background.widgets.timers.placementStrategy"
        }

        ToggleRow {
            setting: "e4:background.widgets.timers.vertical"
        }

        SectionHeader {
            text: Tr.tr("Pomodoro")
        }

        DurationRow {
            setting: "e4:time.pomodoro.focus"
        }

        DurationRow {
            setting: "e4:time.pomodoro.breakTime"
        }

        DurationRow {
            setting: "e4:time.pomodoro.longBreak"
        }

        StepperRow {
            setting: "e4:time.pomodoro.cyclesBeforeLongBreak"
        }

        // The sound at the end of a round is one of Audio's system sounds
        SettingLinkRow {
            nState: root.nState
            target: "e4:sounds.pomodoro"
            text: Tr.tr("Sound when a round ends")
        }

        // caelestia4: no Advanced section: every option of the timers is above
    }
}
