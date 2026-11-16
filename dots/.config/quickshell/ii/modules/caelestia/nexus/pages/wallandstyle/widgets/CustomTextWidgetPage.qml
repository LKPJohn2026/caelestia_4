pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Text (route appearance/desktop/widget.customText): end4-pC's desktop widget
// e4:background.widgets.customText. Rows name their registry setting
// (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Text")
    isSubPage: true

    // caelestia4: ToggleRow has written `enable` already (its own onToggled runs first). Turning it on goes through
    // PresetLayout again, so a new widget isn't left under another and the preset is saved
    function enableToggled(on: bool): void {
        if (on) {
            E4C.Config.options.background.widgets.customText.enable = false;
            E4.PresetLayout.setWidgetEnabled("customText", true);
        } else {
            E4.PresetLayout.requestSave();
        }
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            setting: "e4:background.widgets.customText.enable"
            onToggled: root.enableToggled(checked)
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: what it shows comes first in General, as the pictures on the other widget pages
        TextAreaRow {
            setting: "e4:background.widgets.customText.content"
        }

        StepperRow {
            id: sizeRow

            setting: "e4:background.widgets.customText.fontSize"
        }

        SelectRow {
            setting: "e4:background.widgets.customText.placementStrategy"
        }

        SectionHeader {
            text: Tr.tr("Look")
        }

        FontRow {
            setting: "e4:background.widgets.customText.fontFamily"
        }

        SelectRow {
            setting: "e4:background.widgets.customText.color"
        }

        SegmentedRow {
            setting: "e4:background.widgets.customText.alignment"
        }

        ToggleRow {
            setting: "e4:background.widgets.customText.shadow"
        }

        // caelestia4: no Advanced section: every option of the text is above
    }
}
