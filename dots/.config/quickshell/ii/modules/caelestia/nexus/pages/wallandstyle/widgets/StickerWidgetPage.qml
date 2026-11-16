pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Sticker (route appearance/desktop/widget.sticker): end4-pC's desktop widget
// e4:background.widgets.sticker. Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("Sticker")
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
                step.undoFn = () => pl.setWidgetEnabled("sticker", on);
        });
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.sticker.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.sticker.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("sticker", !!newValue);
                    root.undoThroughPreset(!!oldValue);
                }

                target: enableRow.link.s
            }
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: what it shows comes first in General (not in the Show card)
        PathRow {
            setting: "e4:background.widgets.sticker.path"
        }

        StepperRow {
            setting: "e4:background.widgets.sticker.size"
            // caelestia4: dragging the corner has no upper limit: a bigger sticker raises the top, so the box shows
            // its real size and +/- step from it
            to: Math.max(800, value)
        }

        SelectRow {
            setting: "e4:background.widgets.sticker.placementStrategy"
        }

        SectionHeader {
            text: Tr.tr("Look")
        }

        SliderRow {
            setting: "e4:background.widgets.sticker.rotation"
            // caelestia4: turning the sticker by hand keeps adding up (400 looks like 40): shown within one turn, from
            // -180° to 180°, so the slider starts from what the sticker looks like
            value: link.active ? ((Number(link.shownValue ?? 0) % 360) + 540) % 360 - 180 : 0
            // TRANSLATORS: an angle, e.g. "45°"
            valueLabel: link.active ? Tr.tr("%1°").arg(Math.round(value)) : ""
        }

        ColourRow {
            setting: "e4:background.widgets.sticker.outlineColor"
        }

        StepperRow {
            setting: "e4:background.widgets.sticker.outlineWidth"
        }

        // caelestia4: no Advanced section: every option of the sticker is above
    }
}
