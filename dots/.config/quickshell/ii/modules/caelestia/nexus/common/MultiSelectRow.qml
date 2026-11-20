pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a list setting that holds some of a known set of values (screens to leave out: c:bar.excludedScreens),
// as DialogMultiSelectButton does for a page's own list. The row shows what is chosen; its button opens a dialog with
// a check box per option (`options`: [{value, label: Tr.mark or text}], the entry's or the page's, e.g. the screens
// connected now), All / None, and Apply, which writes the list once (one undo step), in the options' order. Values in
// the setting that are not among the options (a screen not connected now) stay listed and chosen until unticked.
// `allowEmpty` false needs at least one. Keyboard in the dialog: Up/Down move, Space ticks, Enter applies, Esc
// cancels. Without `setting`, bind `value` and handle edited(list)
SettingRow {
    id: root

    property var value: link.active ? (link.value ?? []) : []
    property var options: link.entry?.options ?? []
    property bool allowEmpty: true
    property string noneText: Tr.trCtx("None", "an empty list setting")
    property string allText: Tr.trCtx("All", "every option chosen")
    readonly property alias dialog: dialog

    signal edited(list: var)

    function labelFor(v: var): string {
        const o = root.options.find(o => root.link.s.same(o.value, v));
        return o ? Tr.tr(o.label ?? String(o.value)) : String(v);
    }

    function openDialog(): void {
        if (root.link.blocked)
            root.link.followReason();
        else
            dialog.open();
    }

    readonly property var _chosenNow: Array.isArray(value) ? value : []

    focusItem: button

    StyledRect {
        id: button

        Layout.fillWidth: root.controlBelow
        Layout.maximumWidth: root.controlBelow ? -1 : Math.max(160, root.width * 0.45)
        implicitWidth: buttonRow.implicitWidth + Tokens.padding.large * 2
        implicitHeight: buttonRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.label + ": " + summary.text
        Accessible.description: root.accessibleDescription
        Accessible.onPressAction: root.openDialog()
        Keys.onSpacePressed: root.openDialog()
        Keys.onReturnPressed: root.openDialog()
        Keys.onEnterPressed: root.openDialog()
        onActiveFocusChanged: {
            if (!activeFocus)
                root.focusRing.pointerFocus = false;
        }

        StateLayer {
            radius: button.radius
            color: Colours.palette.m3onSecondaryContainer
            onPressed: {
                if (button.activeFocus)
                    root.focusRing.pointerFocus = true;
            }
            onClicked: root.openDialog()
        }

        RowLayout {
            id: buttonRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            StyledText {
                id: summary

                Layout.fillWidth: true
                text: {
                    const chosen = root._chosenNow;
                    if (!chosen.length)
                        return root.noneText;
                    if (root.options.length > 1 && root.options.every(o => chosen.some(v => root.link.s.same(v, o.value))))
                        return root.allText;
                    const names = chosen.slice(0, 2).map(v => root.labelFor(v)).join(", ");
                    // TRANSLATORS: the first chosen items, then how many more (two screen names, then "+2")
                    return chosen.length > 2 ? Tr.trCtx("%1 +%2", "chosen items and how many more").arg(names).arg(chosen.length - 2) : names;
                }
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "expand_more"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    NexusDialog {
        id: dialog

        // [{value, label, gone}]: the options, then chosen values that are not among them
        property var items: []
        property var chosen: []
        property int cursor: -1

        function isChosen(v: var): bool {
            return dialog.chosen.some(c => root.link.s.same(c, v));
        }

        function toggle(v: var): void {
            dialog.chosen = dialog.isChosen(v) ? dialog.chosen.filter(c => !root.link.s.same(c, v)) : [...dialog.chosen, v];
        }

        title: root.label
        tall: true
        acceptText: Tr.trCtx("Apply", "button")
        acceptEnabled: root.allowEmpty || chosen.length > 0
        initialFocus: list

        onOpenedChanged: {
            if (!opened)
                return;
            const items = root.options.map(o => ({
                        value: o.value,
                        label: Tr.tr(o.label ?? String(o.value)),
                        gone: false
                    }));
            for (const v of root._chosenNow)
                if (!items.some(it => root.link.s.same(it.value, v)))
                    items.push({
                        value: v,
                        label: String(v),
                        gone: true
                    });
            dialog.items = items;
            dialog.chosen = [...root._chosenNow];
            dialog.cursor = -1;
        }
        onAccepted: {
            const out = dialog.items.filter(it => dialog.isChosen(it.value)).map(it => it.value);
            if (!root.link.s.same(out, root._chosenNow)) {
                if (root.link.active)
                    root.link.set(out);
                root.edited(out);
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "select_all"
                text: Tr.tr("All")
                type: IconTextButton.Tonal
                onClicked: dialog.chosen = dialog.items.map(it => it.value)
            }

            IconTextButton {
                icon: "deselect"
                text: Tr.tr("None")
                type: IconTextButton.Tonal
                onClicked: dialog.chosen = []
            }

            Item {
                Layout.fillWidth: true
            }

            StyledText {
                // TRANSLATORS: %1 chosen out of %2
                text: Tr.tr("%1 of %2").arg(dialog.chosen.length).arg(dialog.items.length)
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        VerticalFadeListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            focus: true
            model: dialog.opened || dialog.visible ? dialog.items : []
            currentIndex: dialog.cursor
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, ListView.Contain);
            }

            Keys.onUpPressed: dialog.cursor = Math.max(0, dialog.cursor - 1)
            Keys.onDownPressed: dialog.cursor = Math.min(dialog.items.length - 1, dialog.cursor + 1)
            Keys.onSpacePressed: {
                if (dialog.cursor < 0)
                    dialog.cursor = 0;
                else
                    dialog.toggle(dialog.items[dialog.cursor].value);
            }

            delegate: StyledRect {
                id: optItem

                required property var modelData
                required property int index
                readonly property bool selected: dialog.isChosen(modelData.value)

                width: ListView.view.width
                implicitHeight: optLabel.implicitHeight + Tokens.padding.medium * 2
                radius: Tokens.rounding.medium
                color: Qt.alpha(Colours.palette.m3tertiaryContainer, selected ? 1 : 0)
                border.width: index === dialog.cursor ? 2 : 0
                border.color: Colours.palette.m3primary

                Accessible.role: Accessible.CheckBox
                Accessible.name: optLabel.text
                Accessible.checkable: true
                Accessible.checked: selected

                StateLayer {
                    radius: optItem.radius
                    onClicked: dialog.toggle(optItem.modelData.value)
                }

                StyledText {
                    id: optLabel

                    anchors.left: parent.left
                    anchors.right: checkIcon.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    anchors.rightMargin: Tokens.spacing.medium
                    // TRANSLATORS: a chosen value that is not among the options now (a screen not connected)
                    text: optItem.modelData.gone ? Tr.trCtx("%1 (not here now)", "a chosen value that is not available").arg(optItem.modelData.label) : optItem.modelData.label
                    color: optItem.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                    wrapMode: Text.WordWrap
                }

                MaterialIcon {
                    id: checkIcon

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    text: optItem.selected ? "check_box" : "check_box_outline_blank"
                    color: optItem.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }
            }
        }
    }
}
