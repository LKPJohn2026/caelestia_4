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

// caelestia4: a list setting edited in a dialog: a list of strings (no `fields`), a list of small objects (`fields`:
// [{key, title: Tr.mark, type: "string"|"int"|"real"|"bool"|"icon", hint?}], from the entry or the page), or a map
// {name: value} (`mapMode`: entry type "map", or the value is an object; edited as key/value pairs, fields "key" and
// "value"). The row shows how many items there are and the first ones; Edit opens the dialog: add, remove, move up
// and down, edit. Save writes the whole list once (one undo step); Cancel or Esc drops the changes. Keyboard in the
// dialog: Tab moves between fields, Alt+Up/Alt+Down move the item, Alt+Delete removes it. Without `setting`, bind
// `value` and handle edited(list)
SettingRow {
    id: root

    property var value: link.active ? link.value : []
    property var fields: link.entry?.fields ?? []
    property bool mapMode: link.entry?.type === "map" || (!!value && typeof value === "object" && !Array.isArray(value))
    property string dialogTitle: label
    property string addText: Tr.tr("Add")
    property string emptyText: Tr.trCtx("None", "an empty list setting")
    readonly property alias dialog: dialog

    signal edited(list: var)

    // The fields an item has: the page's or entry's, else one text ("value") for a list of strings, or key/value
    readonly property var effectiveFields: {
        if (root.fields && root.fields.length)
            return root.fields;
        if (root.mapMode)
            return [
                {
                    key: "key",
                    title: Tr.mark("Name"),
                    type: "string"
                },
                {
                    key: "value",
                    title: Tr.mark("Value"),
                    type: "string"
                }
            ];
        return [
            {
                key: "value",
                title: Tr.mark("Value"),
                type: "string"
            }
        ];
    }
    readonly property bool stringList: !root.mapMode && !(root.fields && root.fields.length)
    readonly property var items: root._toWorking(root.value)

    function itemLabel(item: var): string {
        return root.effectiveFields.map(f => {
            const v = item[f.key];
            if (f.type === "bool")
                return v ? Tr.tr(f.title) : "";
            return v === undefined || v === null ? "" : String(v);
        }).filter(s => s.length > 0).join(root.mapMode ? " " : " · ");
    }

    function save(list: var): void {
        if (root.link.active)
            root.link.set(list);
        root.edited(list);
    }

    function openDialog(): void {
        if (root.link.blocked)
            root.link.followReason();
        else
            dialog.open();
    }

    // The value as a list of plain objects with the fields' keys (a copy)
    function _toWorking(v: var): var {
        if (root.mapMode) {
            const m = v && typeof v === "object" ? v : {};
            return Object.keys(m).map(k => ({
                        key: k,
                        value: m[k]
                    }));
        }
        const list = Array.isArray(v) ? v : [];
        if (root.stringList)
            return list.map(s => ({
                        value: s
                    }));
        return list.map(o => JSON.parse(JSON.stringify(o ?? {})));
    }

    // A field's text back to its type; undefined when it isn't valid
    function _convert(f: var, v: var): var {
        switch (f.type) {
        case "int":
        case "real":
            {
                if (typeof v === "number")
                    return f.type === "int" ? (Number.isInteger(v) ? v : undefined) : v;
                const s = String(v ?? "").trim();
                const n = Number(s);
                if (!s || isNaN(n) || (f.type === "int" && !Number.isInteger(n)))
                    return undefined;
                return n;
            }
        case "bool":
            return !!v;
        }
        return v === undefined || v === null ? "" : String(v);
    }

    function _fromWorking(items: var): var {
        if (root.mapMode) {
            const m = {};
            for (const it of items) {
                const k = String(it.key ?? "").trim();
                if (k)
                    m[k] = root._convert(root.effectiveFields[1] ?? {}, it.value);
            }
            return m;
        }
        if (root.stringList)
            return items.map(it => String(it.value ?? "")).filter(s => s.trim().length > 0);
        return items.map(it => {
            const o = Object.assign({}, it);
            for (const f of root.effectiveFields)
                o[f.key] = root._convert(f, it[f.key]);
            return o;
        });
    }

    function _valid(items: var): bool {
        for (const it of items) {
            if (root.mapMode && !String(it.key ?? "").trim())
                continue;
            for (const f of root.effectiveFields) {
                if ((f.type === "int" || f.type === "real") && root._convert(f, it[f.key]) === undefined && !(root.mapMode && f.key === "key"))
                    return false;
            }
        }
        return true;
    }

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
                    const items = root.items;
                    if (!items.length)
                        return root.emptyText;
                    const first = items.slice(0, 2).map(it => root.itemLabel(it)).filter(s => s).join(", ");
                    // TRANSLATORS: %1 how many items a list setting has ("3 items"), %2 the first of them
                    return first ? Tr.trCtx("%1: %2", "a list setting's summary").arg(Tr.trN("%n item", "%n items", items.length)).arg(first) + (items.length > 2 ? "…" : "") : Tr.trN("%n item", "%n items", items.length);
                }
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "edit"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    NexusDialog {
        id: dialog

        property var working: []
        // Bumped on every edit, so acceptEnabled re-checks the items (they are changed in place)
        property int revision

        function moveItem(from: int, to: int): void {
            if (to < 0 || to >= dialog.working.length || from === to)
                return;
            const w = dialog.working.slice();
            const [it] = w.splice(from, 1);
            w.splice(to, 0, it);
            dialog.working = w;
            dialog.revision++;
            Qt.callLater(() => editors.focusItemAt(to));
        }

        function removeItem(i: int): void {
            const w = dialog.working.slice();
            w.splice(i, 1);
            dialog.working = w;
            dialog.revision++;
            Qt.callLater(() => editors.focusItemAt(Math.min(i, w.length - 1)));
        }

        function addItem(): void {
            const it = {};
            for (const f of root.effectiveFields)
                it[f.key] = f.type === "bool" ? false : "";
            dialog.working = [...dialog.working, it];
            dialog.revision++;
            Qt.callLater(() => editors.focusItemAt(dialog.working.length - 1));
        }

        title: root.dialogTitle
        tall: true
        enterAccepts: false
        acceptText: Tr.trCtx("Save", "button")
        acceptEnabled: revision >= 0 && root._valid(working)

        onOpenedChanged: {
            if (opened) {
                dialog.working = root._toWorking(root.value);
                dialog.revision = 0;
            }
        }
        onAccepted: {
            const out = root._fromWorking(dialog.working);
            if (!root.link.s.same(out, root.value))
                root.save(out);
        }

        StyledText {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.subtext
            color: Colours.palette.m3onSurfaceVariant
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        VerticalFadeListView {
            id: editors

            function focusItemAt(i: int): void {
                if (i < 0)
                    return;
                editors.positionViewAtIndex(i, ListView.Contain);
                const item = editors.itemAtIndex(i);
                item?.focusFirst();
            }

            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Tokens.spacing.small
            model: dialog.opened || dialog.visible ? dialog.working.length : 0

            delegate: StyledRect {
                id: editor

                required property int index
                readonly property var item: dialog.working[index] ?? {}

                function focusFirst(): void {
                    for (let i = 0; i < fieldRepeater.count; i++) {
                        const f = fieldRepeater.itemAt(i);
                        if (f?.input) {
                            f.input.forceActiveFocus(Qt.TabFocusReason);
                            return;
                        }
                    }
                }

                width: ListView.view.width
                implicitHeight: editorRow.implicitHeight + Tokens.padding.small * 2
                radius: Tokens.rounding.medium
                color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                Keys.onPressed: event => {
                    if (!(event.modifiers & Qt.AltModifier))
                        return;
                    if (event.key === Qt.Key_Up) {
                        dialog.moveItem(editor.index, editor.index - 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        dialog.moveItem(editor.index, editor.index + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Delete) {
                        dialog.removeItem(editor.index);
                        event.accepted = true;
                    }
                }

                RowLayout {
                    id: editorRow

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.medium
                    anchors.rightMargin: Tokens.padding.small
                    spacing: Tokens.spacing.small

                    // The fields side by side when there is room, else one under another
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Tokens.padding.small
                        columns: editor.width > 140 * root.effectiveFields.length + 120 ? root.effectiveFields.length : 1
                        columnSpacing: Tokens.spacing.small
                        rowSpacing: Tokens.spacing.small

                        Repeater {
                            id: fieldRepeater

                            model: root.effectiveFields

                            RowLayout {
                                id: fieldBox

                                required property var modelData
                                readonly property Item input: modelData.type === "bool" ? toggle : textInput

                                Layout.fillWidth: true
                                // Equal shares of the width
                                Layout.preferredWidth: 1
                                spacing: Tokens.spacing.small

                                StyledTextField {
                                    id: textInput

                                    readonly property var conv: root._convert(fieldBox.modelData, textInput.text)

                                    visible: fieldBox.modelData.type !== "bool"
                                    Layout.fillWidth: true
                                    verticalPadding: Tokens.padding.small
                                    placeholderText: Tr.tr(fieldBox.modelData.title ?? "")
                                    text: {
                                        const v = editor.item[fieldBox.modelData.key];
                                        return v === undefined || v === null ? "" : String(v);
                                    }
                                    inputMethodHints: fieldBox.modelData.type === "int" || fieldBox.modelData.type === "real" ? Qt.ImhFormattedNumbersOnly : Qt.ImhNone
                                    isError: (fieldBox.modelData.type === "int" || fieldBox.modelData.type === "real") && textInput.text.length > 0 && conv === undefined
                                    Accessible.name: placeholderText
                                    onTextEdited: {
                                        editor.item[fieldBox.modelData.key] = text;
                                        dialog.revision++;
                                    }
                                    // A long value shows from its start while not being edited
                                    onActiveFocusChanged: if (!activeFocus) cursorPosition = 0
                                    Component.onCompleted: cursorPosition = 0
                                }

                                MaterialIcon {
                                    visible: fieldBox.modelData.type === "icon" && textInput.text.length > 0
                                    text: textInput.text
                                    color: Colours.palette.m3onSurfaceVariant
                                    fontStyle: Tokens.font.icon.medium
                                }

                                StyledText {
                                    visible: fieldBox.modelData.type === "bool"
                                    Layout.fillWidth: true
                                    text: Tr.tr(fieldBox.modelData.title ?? "")
                                    font: Tokens.font.body.small
                                    elide: Text.ElideRight
                                }

                                StyledSwitch {
                                    id: toggle

                                    visible: fieldBox.modelData.type === "bool"
                                    value: !!editor.item[fieldBox.modelData.key]
                                    Accessible.name: Tr.tr(fieldBox.modelData.title ?? "")
                                    onToggled: {
                                        editor.item[fieldBox.modelData.key] = checked;
                                        dialog.revision++;
                                    }
                                }
                            }
                        }
                    }

                    IconButton {
                        icon: "arrow_upward"
                        type: IconButton.Text
                        // A map has no order
                        visible: !root.mapMode
                        disabled: editor.index === 0
                        Accessible.name: Tr.tr("Move up")
                        onClicked: dialog.moveItem(editor.index, editor.index - 1)
                    }

                    IconButton {
                        icon: "arrow_downward"
                        type: IconButton.Text
                        // A map has no order
                        visible: !root.mapMode
                        disabled: editor.index === dialog.working.length - 1
                        Accessible.name: Tr.tr("Move down")
                        onClicked: dialog.moveItem(editor.index, editor.index + 1)
                    }

                    IconButton {
                        icon: "delete"
                        type: IconButton.Text
                        inactiveOnColour: Colours.palette.m3error
                        Accessible.name: Tr.tr("Remove")
                        onClicked: dialog.removeItem(editor.index)
                    }
                }
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: dialog.working.length === 0
            text: Tr.tr("Nothing here yet")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
        }

        IconTextButton {
            Layout.alignment: Qt.AlignLeft
            icon: "add"
            text: root.addText
            type: IconTextButton.Tonal
            onClicked: dialog.addItem()
        }
    }
}
