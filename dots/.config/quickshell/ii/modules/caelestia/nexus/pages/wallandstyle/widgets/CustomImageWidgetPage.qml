pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Picture (route appearance/desktop/widget.customImage): end4-pC's desktop
// widget e4:background.widgets.customImage. Rows name their registry
// setting (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Picture")
    isSubPage: true

    // caelestia4: ToggleRow has written `enable` already (its own onToggled runs first). Turning it on goes through
    // PresetLayout again, so a new widget isn't left under another and the preset is saved
    function enableToggled(on: bool): void {
        if (on) {
            E4C.Config.options.background.widgets.customImage.enable = false;
            E4.PresetLayout.setWidgetEnabled("customImage", true);
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
            setting: "e4:background.widgets.customImage.enable"
            onToggled: root.enableToggled(checked)
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: what it shows comes first in General (not in the Show card)
        PathRow {
            setting: "e4:background.widgets.customImage.path"
        }

        // caelestia4: pixel sizes are steppers on every widget page: the exact number with its unit, +/- steps, and
        // room past the top for a size dragged bigger on the desktop
        StepperRow {
            id: sizeRow

            setting: "e4:background.widgets.customImage.size"
            to: Math.max(_shown(link.entry?.max ?? 800), value)
        }

        SelectRow {
            setting: "e4:background.widgets.customImage.placementStrategy"
        }

        SectionHeader {
            text: Tr.tr("Look")
        }

        SelectRow {
            setting: "e4:background.widgets.customImage.shape"
        }

        // caelestia4: no Advanced section: the picture has no other options
    }
}
