pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Weather (route appearance/desktop/widget.weather): end4-pC's desktop widget
// e4:background.widgets.weather. Show, then General (size, placement, and links to the weather options it shares with
// the rest of the shell: location, units, refresh). Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("Weather")
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
                step.undoFn = () => pl.setWidgetEnabled("weather", on);
        });
    }

    // caelestia4: the widget saves its own resize into the preset (PresetLayout.requestSave); a change made here
    // (or its reset or undo) is saved the same way, so re-applying the preset doesn't undo it
    readonly property Connections layoutSave: Connections {
        function onChangedByUser(): void {
            E4.PresetLayout.requestSave();
        }

        target: sizeRow.link.s
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.weather.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.weather.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("weather", !!newValue);
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
            id: sizeRow

            stacked: true
            setting: "e4:background.widgets.weather.sizeMode"
        }

        SelectRow {
            setting: "e4:background.widgets.weather.placementStrategy"
        }

        // caelestia4: shared with the clocks and the lock screen, so kept where the other weather options are. Plain
        // links at the end of General, as on System resources (no Advanced section of links only)
        SettingLinkRow {
            nState: root.nState
            target: "c:services.weatherLocation"
        }

        SettingLinkRow {
            nState: root.nState
            target: "e4:bar.weather.enableGPS"
        }

        SettingLinkRow {
            nState: root.nState
            target: "c:services.weatherUnits"
            text: Tr.tr("Temperature units")
        }

        SettingLinkRow {
            nState: root.nState
            target: "e4:bar.weather.fetchInterval"
        }
    }
}
