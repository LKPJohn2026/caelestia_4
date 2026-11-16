pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Media player (route appearance/desktop/widget.media): end4-pC's desktop
// widget e4:background.widgets.media. Rows name their registry setting (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Media player")
    isSubPage: true

    // caelestia4: ToggleRow has written `enable` already (its own onToggled runs first). Turning it on goes through
    // PresetLayout again, so a new widget isn't left under another and the preset is saved
    function enableToggled(on: bool): void {
        if (on) {
            E4C.Config.options.background.widgets.media.enable = false;
            E4.PresetLayout.setWidgetEnabled("media", true);
        } else {
            E4.PresetLayout.requestSave();
        }
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
            setting: "e4:background.widgets.media.enable"
            onToggled: root.enableToggled(checked)
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: Size is in the same place on every widget page, just before Placement: buttons for named
        // sizes, a stepper for pixels, "Fixed" for a widget with one size
        SegmentedRow {
            id: sizeRow

            stacked: true
            setting: "e4:background.widgets.media.sizeMode"
        }

        SelectRow {
            setting: "e4:background.widgets.media.placementStrategy"
        }

        // caelestia4: which player it shows: shared with the bar and the dashboard, so kept with the media services.
        // Plain links at the end of General, as on System resources (no Advanced section of links only)
        SettingLinkRow {
            nState: root.nState
            target: "c:services.defaultPlayer"
        }

        SettingLinkRow {
            nState: root.nState
            target: "e4:media.filterDuplicatePlayers"
        }
    }
}
