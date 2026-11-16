import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext: link.desc
    property alias menuItems: splitButton.menuItems
    // caelestia4: the row shows `active`, usually bound to the setting. The menu sets its own active item when one is
    // picked, which replaced that binding (an alias), so the row stopped following the setting after the first pick
    property MenuItem active: link.active ? (menuItems.find(i => link.s.same(i.value, link.value)) ?? null) : null
    // The row keeps the picked item itself instead (no setting behind it): `active` starts as the first item
    property bool holdsSelection
    property alias fallbackText: splitButton.fallbackText
    property alias fallbackIcon: splitButton.fallbackIcon
    property alias menuOnTop: splitButton.menuOnTop

    // caelestia4: a registry id: the row shows the item whose `value` equals the setting and writes the picked item's
    // value (onSelected still runs). Without menuItems from the page, the items are made from the entry's `options`
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }
    property var _optionItems: []

    function _buildOptions(): void {
        for (const item of root._optionItems)
            item.destroy();
        const opts = link.active ? (link.entry?.options ?? []) : [];
        root._optionItems = opts.map(o => optionComp.createObject(root, {
                text: Tr.tr(o.label),
                icon: o.icon ?? "",
                value: o.value
            }));
    }

    Connections {
        function onEntryChanged(): void {
            root._buildOptions();
        }

        target: root.link
    }

    Component {
        id: optionComp

        MenuItem {}
    }

    signal selected(item: MenuItem)

    onSelected: item => {
        if (link.active && item && item.value !== undefined)
            link.set(item.value);
    }

    // caelestia4: keyboard: Tab focuses the row, Space/Enter open or close the menu, Up/Down pick the previous/next
    // item (as a click on it would), Esc closes the menu
    function pick(item: MenuItem): void {
        root.selected(item);
        item.clicked();
        if (root.holdsSelection)
            root.active = item;
    }

    function step(delta: int): void {
        if (root.link.blocked)
            return;
        const items = root.menuItems;
        if (!items.length)
            return;
        const cur = items.indexOf(root.active);
        const next = items[cur < 0 ? (delta > 0 ? 0 : items.length - 1) : Math.max(0, Math.min(items.length - 1, cur + delta))];
        if (next && next !== root.active)
            root.pick(next);
    }

    activeFocusOnTab: true
    Keys.onSpacePressed: toggleMenu()
    Keys.onReturnPressed: toggleMenu()
    Keys.onEnterPressed: toggleMenu()
    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onEscapePressed: event => {
        if (splitButton.expanded)
            splitButton.expanded = false;
        else
            event.accepted = false;
    }
    onActiveFocusChanged: {
        if (!activeFocus)
            focusRing.pointerFocus = false;
    }

    function toggleMenu(): void {
        if (root.link.blocked)
            root.link.followReason();
        else
            splitButton.expanded = !splitButton.expanded;
    }

    Accessible.role: Accessible.ComboBox
    Accessible.name: label.text
    Accessible.description: link.blocked ? subtext + " " + link.disabledReason : subtext

    Component.onCompleted: {
        root._buildOptions();
        if (holdsSelection && !active)
            active = menuItems[0] ?? null;
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2
    clip: false
    z: splitButton.expanded ? 1 : 0

    HoverHandler {
        id: hover
    }

    RowPulse {
        link: root.link
    }

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                text: root.link.title
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            SettingNotes {
                Layout.fillWidth: true
                link: root.link
            }
        }

        SettingMarks {
            link: root.link
            hot: hover.hovered || root.activeFocus
        }

        SplitButton {
            id: splitButton

            type: SplitButton.Tonal
            active: root.active
            menuItems: root._optionItems
            disabled: root.link.blocked
            opacity: root.link.blocked ? 0.5 : 1
            stateLayer.onClicked: splitButton.expanded = !splitButton.expanded
            // Opened with the mouse: take focus (no ring) so Esc closes it
            onExpandedChanged: {
                if (expanded && !root.activeFocus) {
                    focusRing.pointerFocus = true;
                    root.forceActiveFocus();
                }
            }
            menu.onItemSelected: item => {
                root.selected(item);
                if (root.holdsSelection)
                    root.active = item;
                // After this the menu sets its active item, which replaces the binding above: put it back
                Qt.callLater(() => splitButton.active = Qt.binding(() => root.active));
            }
        }
    }

    FocusRing {
        id: focusRing

        focusItem: root
    }
}
