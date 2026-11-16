pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a choice of 2-4 values as connected buttons (an enum with few values: clock hand style, VRR). With
// `setting` the buttons are the entry's `options` ([{value, label: Tr.mark, icon?}]) and a click writes the value
// (one undo step). Without it, set `options` and `value` and handle selected(value). Keyboard: Tab focuses the group,
// Left/Right (Home/End) pick the previous/next value. Narrow rows put the buttons under the text, full width
SettingRow {
    id: root

    property var options: link.entry?.options ?? []
    property var value: link.active ? link.value : undefined
    readonly property int currentIndex: options.findIndex(o => link.s.same(o.value, root.value))

    signal selected(value: var)

    function pick(i: int): void {
        if (i < 0 || i >= root.options.length || i === root.currentIndex)
            return;
        const v = root.options[i].value;
        if (root.link.active)
            root.link.set(v);
        root.selected(v);
    }

    function step(delta: int): void {
        const n = root.options.length;
        if (!n)
            return;
        const cur = root.currentIndex;
        root.pick(cur < 0 ? (delta > 0 ? 0 : n - 1) : Math.max(0, Math.min(n - 1, cur + delta)));
    }

    focusItem: group

    RowLayout {
        id: group

        Layout.fillWidth: root.controlBelow
        spacing: Tokens.spacing.extraSmall / 2

        activeFocusOnTab: true
        Accessible.role: Accessible.Grouping
        Accessible.name: root.label
        Accessible.description: root.accessibleDescription
        Keys.onLeftPressed: root.step(-1)
        Keys.onRightPressed: root.step(1)
        Keys.onUpPressed: root.step(-1)
        Keys.onDownPressed: root.step(1)
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Home) {
                root.pick(0);
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                root.pick(root.options.length - 1);
                event.accepted = true;
            }
        }
        onActiveFocusChanged: {
            if (!activeFocus)
                root.focusRing.pointerFocus = false;
        }

        Repeater {
            model: root.options

            StyledRect {
                id: seg

                required property var modelData
                required property int index
                readonly property bool selected: index === root.currentIndex
                readonly property bool isFirst: index === 0
                readonly property bool isLast: index === root.options.length - 1
                readonly property real outer: height / 2 * Math.min(1, Tokens.rounding.scale)
                readonly property real inner: Tokens.rounding.extraSmall

                // Under the text: they share the row's width, each from its own size (the check mark needs room)
                Layout.fillWidth: root.controlBelow
                implicitWidth: segRow.implicitWidth + Tokens.padding.large * 2
                implicitHeight: segRow.implicitHeight + Tokens.padding.small * 2

                topLeftRadius: isFirst ? outer : inner
                bottomLeftRadius: isFirst ? outer : inner
                topRightRadius: isLast ? outer : inner
                bottomRightRadius: isLast ? outer : inner
                color: selected ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                Accessible.role: Accessible.RadioButton
                Accessible.name: label.text
                Accessible.checkable: true
                Accessible.checked: selected

                Behavior on color {
                    CAnim {}
                }

                StateLayer {
                    topLeftRadius: seg.topLeftRadius
                    bottomLeftRadius: seg.bottomLeftRadius
                    topRightRadius: seg.topRightRadius
                    bottomRightRadius: seg.bottomRightRadius
                    color: seg.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                    onPressed: {
                        if (group.activeFocus)
                            root.focusRing.pointerFocus = true;
                    }
                    onClicked: root.pick(seg.index)
                }

                RowLayout {
                    id: segRow

                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, seg.width - Tokens.padding.medium * 2)
                    spacing: Tokens.spacing.small

                    MaterialIcon {
                        visible: text.length > 0
                        text: seg.modelData.icon ?? (seg.selected ? "check" : "")
                        color: seg.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.small
                    }

                    StyledText {
                        id: label

                        Layout.fillWidth: true
                        text: Tr.tr(seg.modelData.label ?? String(seg.modelData.value))
                        color: seg.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                        font: Tokens.font.label.medium
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }
}
