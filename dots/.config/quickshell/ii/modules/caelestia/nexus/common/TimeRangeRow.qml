pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a daily time range as two 24-hour "HH:MM" fields (night light from/to: e4:light.night.from/.to).
// `setting` is the start's id (it gives the title and description), `toSetting` the end's; both land on this row and
// each field has its own modified dot and reset. A field saves on Enter or focus loss when it is a valid time ("7:5"
// is refused, "7:05" is saved as "07:05"); Esc puts the saved time back. An end before the start notes that it ends
// the next day. Without settings, bind `fromValue` and `toValue` and handle edited(from, to)
SettingRow {
    id: root

    property string toSetting
    readonly property RowSetting toLink: RowSetting {
        sid: root.toSetting
        row: root
        screen: root.Config.screen
    }
    property string fromValue: link.active ? String(link.value ?? "") : ""
    property string toValue: toLink.active ? String(toLink.value ?? "") : ""
    readonly property bool overnight: _minutes(toValue) >= 0 && _minutes(fromValue) >= 0 && _minutes(toValue) <= _minutes(fromValue)

    signal edited(from: string, to: string)

    readonly property var _timeRe: /^([01]?\d|2[0-3]):([0-5]\d)$/

    // "7:05" -> "07:05"; undefined when not a time
    function normalise(text: string): var {
        const m = root._timeRe.exec(String(text ?? "").trim());
        return m ? `${m[1].padStart(2, "0")}:${m[2]}` : undefined;
    }

    function _minutes(t: string): int {
        const m = root._timeRe.exec(t ?? "");
        return m ? Number(m[1]) * 60 + Number(m[2]) : -1;
    }

    function _save(which: string, text: string): void {
        const v = root.normalise(text);
        const field = which === "from" ? fromField : toField;
        if (v === undefined) {
            field.fail();
            return;
        }
        const link = which === "from" ? root.link : root.toLink;
        const old = which === "from" ? root.fromValue : root.toValue;
        if (v !== old) {
            if (link.active)
                link.set(v);
            root.edited(which === "from" ? v : root.fromValue, which === "to" ? v : root.toValue);
        }
        field.settle();
    }

    showMarks: false
    focusItem: fromField.activeFocus ? fromField : toField
    hot: false
    subtext: {
        const d = link.desc;
        if (!root.overnight)
            return d;
        const note = Tr.tr("Ends the next day");
        return d ? d + " " + note : note;
    }

    RowPulse {
        parent: root
        link: root.toLink
    }

    RowTextField {
        id: fromField

        Layout.preferredWidth: Tokens.sizes.nexus.smallTextFieldWidth * 1.3
        Layout.fillWidth: root.controlBelow
        savedText: root.fromValue
        hint: Tr.trCtx("HH:MM", "a 24-hour time field hint")
        horizontalAlignment: TextInput.AlignHCenter
        validate: text => root.normalise(text) !== undefined
        inputMethodHints: Qt.ImhPreferNumbers
        Accessible.name: Tr.trCtx("From", "start of a time range") + ", " + root.label
        Accessible.description: root.accessibleDescription
        onCommit: text => root._save("from", text)

        HoverHandler {
            id: fromHover
        }
    }

    SettingMarks {
        link: root.link
        hot: fromHover.hovered || fromField.activeFocus
    }

    StyledText {
        // TRANSLATORS: between the start and end of a time range
        text: Tr.trCtx("to", "time range")
        color: Colours.palette.m3onSurfaceVariant
        font: Tokens.font.body.small
    }

    RowTextField {
        id: toField

        Layout.preferredWidth: Tokens.sizes.nexus.smallTextFieldWidth * 1.3
        Layout.fillWidth: root.controlBelow
        savedText: root.toValue
        hint: Tr.trCtx("HH:MM", "a 24-hour time field hint")
        horizontalAlignment: TextInput.AlignHCenter
        validate: text => root.normalise(text) !== undefined
        inputMethodHints: Qt.ImhPreferNumbers
        Accessible.name: Tr.trCtx("To", "end of a time range") + ", " + root.label
        Accessible.description: root.accessibleDescription
        onCommit: text => root._save("to", text)

        HoverHandler {
            id: toHover
        }
    }

    SettingMarks {
        link: root.toLink
        hot: toHover.hovered || toField.activeFocus
    }
}
