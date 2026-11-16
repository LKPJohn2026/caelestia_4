pragma ComponentBehavior: Bound

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
    // caelestia4: with `setting`, the value, range and step come from the registry entry (min/max/step), and a change
    // is written 300 ms after the last click (onMoved still runs at once)
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }
    // caelestia4: the entry's `scale` shows and steps value × scale (a stored 0.85 reads 85); min/max/step stay in
    // stored units. The entry's unit shows after the number ("85 %", "300 ms")
    readonly property real valueScale: link.entry?.scale ?? 1 // not "scale": an Item has one
    readonly property string unitText: {
        switch (link.entry?.unit) {
        case "ms":
            // TRANSLATORS: unit shown after a number box
            return Tr.trCtx("ms", "unit after a number");
        case "s":
            return Tr.trCtx("s", "unit after a number");
        case "min":
            return Tr.trCtx("min", "unit after a number");
        case "%":
            return "%";
        case "px":
            return Tr.trCtx("px", "unit after a number");
        case "K":
            return "K";
        case "pt":
            return Tr.trCtx("pt", "unit after a number");
        case "°":
            return "°";
        }
        return "";
    }
    // Shown units; rounded so 0.07 × 100 reads 7, not 7.000000000000001
    property real value: link.active ? _shown(Number(link.shownValue ?? 0)) : 0
    property real from: _shown(link.entry?.min ?? 0)
    property real to: _shown(link.entry?.max ?? 99)
    property real stepSize: _shown(link.entry?.step ?? 1)

    signal moved(value: real)

    function _shown(v: real): real {
        return Math.round(v * valueScale * 1000) / 1000;
    }

    onMoved: v => {
        if (!link.active)
            return;
        const stored = valueScale === 1 ? v : Math.round(v / valueScale * 10000) / 10000;
        link.setLater(root.setting.startsWith("h:") ? ((link.entry?.step ?? root.stepSize) < 1 ? Number(stored.toFixed(2)) : Math.round(stored)) : stored);
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2

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
            hot: hover.hovered || spin.activeFocus
        }

        StyledSpinBox {
            id: spin

            Accessible.name: root.label
            Accessible.description: root.link.blocked ? root.subtext + " " + root.link.disabledReason : root.subtext
            from: root.from
            to: root.to
            stepSize: root.stepSize
            value: root.value
            enabled: !root.link.blocked
            opacity: root.link.blocked ? 0.5 : 1
            cLayer: 2
            // caelestia4: +/- (StyledSpinBox.increase/decrease) assign `value` in JS, which drops the binding above, so
            // a reset, Undo or outside change would no longer show. With a setting, bind it again once onMoved has put
            // the new value in link.shownValue (rows without one keep the old way: their value may come back late)
            onValueModified: {
                root.moved(value);
                if (root.link.active)
                    Qt.callLater(() => spin.value = Qt.binding(() => root.value));
            }
        }

        StyledText {
            visible: root.unitText.length > 0
            Layout.minimumWidth: unitMetrics.width
            text: root.unitText
            color: Colours.palette.m3outline
            font: Tokens.font.body.small
            opacity: root.link.blocked ? 0.5 : 1

            // The short units take the same room, so the spin boxes line up
            TextMetrics {
                id: unitMetrics

                font: Tokens.font.body.small
                text: "min"
            }
        }
    }

    // caelestia4: Tab lands in the spin box (its text field; the spin box, a focus scope, has active focus too). Don't
    // touch spin.contentItem from a binding here: that builds it early and the spin box then reports value 0 as an edit
    FocusRing {
        focusItem: spin
    }
}
