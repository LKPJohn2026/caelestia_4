pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Image converter (route appearance/desktop/widget.images): end4-pC's
// desktop widget e4:background.widgets.images. Rows name their registry setting (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Image converter")
    isSubPage: true

    // caelestia4: ToggleRow has written `enable` already (its own onToggled runs first). Turning it on goes through
    // PresetLayout again, so a new widget isn't left under another and the preset is saved
    function enableToggled(on: bool): void {
        if (on) {
            E4C.Config.options.background.widgets.images.enable = false;
            E4.PresetLayout.setWidgetEnabled("images", true);
        } else {
            E4.PresetLayout.requestSave();
        }
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            setting: "e4:background.widgets.images.enable"
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
            setting: "e4:background.widgets.images.placementStrategy"
        }

        // caelestia4: no Advanced section: the converter is set up on the widget itself (drop pictures on it)
    }
}
