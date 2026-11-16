pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a duration. It is stored in the entry's `unit` ("ms", "s" or "min"; min/max/step in that unit too) and
// shown in the largest unit that holds it a whole number of times (300 s reads 5 min); the unit buttons next to the
// number box switch what it counts (not below the stored unit). A change is written 300 ms after the last click
// (RowSetting.setLater), as steppers do. Without `setting`, set `unit` and `value` and handle moved(value) (stored
// units)
SettingRow {
    id: root

    property real value: link.active ? Number(link.shownValue ?? 0) : 0
    property string unit: link.entry?.unit ?? "ms"
    property real from: link.entry?.min ?? 0
    property real to: link.entry?.max ?? 86400000 / (link.durationUnits[unit] ?? 1)
    // The units offered: the stored one and the larger ones up to `maxUnit`
    property string maxUnit: "h"
    readonly property var units: {
        const all = ["ms", "s", "min", "h"];
        const lo = Math.max(0, all.indexOf(root.unit));
        const hi = Math.max(lo, all.indexOf(root.maxUnit));
        return all.slice(lo, hi + 1);
    }
    // The unit the box counts in: the one picked, else the best for the value
    readonly property string shownUnit: _picked || link.bestDurationUnit(value, unit)
    readonly property real factor: (link.durationUnits[shownUnit] ?? 1) / (link.durationUnits[unit] ?? 1)

    signal moved(value: real)

    property string _picked

    function _toStored(shown: real): real {
        const v = shown * root.factor;
        return root.link.entry?.type === "real" ? Math.round(v * 1000) / 1000 : Math.round(v);
    }

    focusItem: spin

    StyledSpinBox {
        id: spin

        readonly property real shown: Math.round(root.value / root.factor * 1000) / 1000

        Accessible.name: root.label
        Accessible.description: root.accessibleDescription
        from: Math.ceil(root.from / root.factor * 1000) / 1000
        to: Math.floor(root.to / root.factor * 1000) / 1000
        stepSize: 1
        decimals: Number.isInteger(shown) ? 0 : 2
        value: shown
        cLayer: 2
        onValueModified: {
            const stored = root._toStored(value);
            if (root.link.active)
                root.link.setLater(stored);
            root.moved(stored);
            if (root.link.active)
                Qt.callLater(() => spin.value = Qt.binding(() => spin.shown));
        }
    }

    // The unit buttons. Tab reaches them; Left/Right switch the unit
    RowLayout {
        id: unitGroup

        function stepUnit(delta: int): void {
            const i = root.units.indexOf(root.shownUnit) + delta;
            if (i >= 0 && i < root.units.length)
                root._picked = root.units[i];
        }

        spacing: Tokens.spacing.extraSmall / 2
        visible: root.units.length > 1
        activeFocusOnTab: true
        Accessible.role: Accessible.Grouping
        Accessible.name: Tr.tr("Unit")
        Keys.onLeftPressed: stepUnit(-1)
        Keys.onRightPressed: stepUnit(1)

        Repeater {
            model: root.units

            StyledRect {
                id: unitChip

                required property string modelData
                required property int index
                readonly property bool selected: modelData === root.shownUnit
                readonly property real outer: height / 2 * Math.min(1, Tokens.rounding.scale)
                readonly property real inner: Tokens.rounding.extraSmall

                implicitWidth: Math.max(unitText.implicitWidth + Tokens.padding.medium * 2, implicitHeight)
                implicitHeight: unitText.implicitHeight + Tokens.padding.small * 2
                topLeftRadius: index === 0 ? outer : inner
                bottomLeftRadius: index === 0 ? outer : inner
                topRightRadius: index === root.units.length - 1 ? outer : inner
                bottomRightRadius: index === root.units.length - 1 ? outer : inner
                color: selected ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                border.width: selected && unitGroup.activeFocus ? 2 : 0
                border.color: Colours.palette.m3primary

                Accessible.role: Accessible.RadioButton
                Accessible.name: unitText.text
                Accessible.checkable: true
                Accessible.checked: selected

                StateLayer {
                    topLeftRadius: unitChip.topLeftRadius
                    bottomLeftRadius: unitChip.bottomLeftRadius
                    topRightRadius: unitChip.topRightRadius
                    bottomRightRadius: unitChip.bottomRightRadius
                    onClicked: root._picked = unitChip.modelData
                }

                StyledText {
                    id: unitText

                    anchors.centerIn: parent
                    text: root.link.durationUnitText(unitChip.modelData)
                    color: unitChip.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.label.medium
                }
            }
        }
    }
}
