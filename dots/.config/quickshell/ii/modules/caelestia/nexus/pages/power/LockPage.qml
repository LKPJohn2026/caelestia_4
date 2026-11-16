pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: Power & idle > Lock screen (route power/lock): end-4's lock screen (e4:lock.*). Rows name their registry
// setting (registry/RegLock.qml)
PageBase {
    id: root

    title: Tr.tr("Lock screen")
    isSubPage: true

    // caelestia4: a slider row's value moved to its entry's step (the slider itself writes any value in between)
    function snapped(row: Item, v: real): real {
        const step = row.link.entry?.step ?? 0;
        if (!(step > 0))
            return v;
        const n = row.from + Math.round((v - row.from) / step) * step;
        return Number(Math.max(row.from, Math.min(row.to, n)).toFixed(6));
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: said once here instead of an "Applies at next lock" chip on every row (registry/RegLock.qml)
        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("Changes here show the next time the screen locks.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.medium
            wrapMode: Text.WordWrap
        }

        // caelestia4: "General", not the page title again
        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            id: hyprlockRow

            setting: "e4:lock.useHyprlock"
        }

        ToggleRow {
            setting: "e4:lock.launchOnStartup"
        }

        SectionHeader {
            text: Tr.tr("Picture")
        }

        ToggleRow {
            setting: "e4:lock.blur.enable"
        }

        // caelestia4: `requires` only checks blur.enable, not what blur.enable needs, so dim these with hyprlock
        // here too (the blur row above says why)
        SliderRow {
            id: radiusRow

            enabled: !hyprlockRow.link.value
            setting: "e4:lock.blur.radius"
            onMoved: v => radiusRow.link.setLater(root.snapped(radiusRow, v))
        }

        // caelestia4: with the other blur rows; no Advanced section for two rows that fit their groups
        SliderRow {
            id: zoomRow

            enabled: !hyprlockRow.link.value
            setting: "e4:lock.blur.extraZoom"
            onMoved: v => zoomRow.link.setLater(root.snapped(zoomRow, v))
        }

        SectionHeader {
            text: Tr.tr("Password")
        }

        ToggleRow {
            setting: "e4:lock.materialShapeChars"
        }
    }
}
