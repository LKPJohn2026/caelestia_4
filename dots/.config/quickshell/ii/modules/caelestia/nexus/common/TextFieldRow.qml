pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
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
    property string value: link.active ? String(link.value ?? "") : ""
    // caelestia4: shown inside the empty field only. It used to float up into the border as a second label once the
    // field had text (the row has its own label), and left a gap in the border when empty
    property string placeholderText
    property string errorText: link.entry?.validate ? Tr.tr("This value isn't valid") : ""
    property alias maximumLength: input.maximumLength
    property alias validate: input.validate
    property alias validator: input.validator
    property bool smallField
    readonly property alias field: input
    // caelestia4: below this width the field goes under the label, full width
    readonly property bool narrow: width > 0 && width < 520

    // caelestia4: a registry id: the field shows the setting and saves it on Enter or when it loses focus (with a ✓),
    // if it passes the entry's `validate` (a regexp string; else the error shows and nothing is saved). Esc puts the
    // saved value back. Numbers ("int"/"real" entries) are saved as numbers. onEditingFinished still runs
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }

    signal valueEdited(value: string)
    signal editingFinished(value: string)

    function clear(): void {
        input.clear();
    }

    function _save(text: string): void {
        if (!link.active || text === root.value)
            return;
        if (!input.valid) {
            input.isError = true;
            return;
        }
        let v = text;
        const type = link.entry?.type;
        if (type === "int" || type === "real") {
            v = Number(text);
            if (text.trim() === "" || isNaN(v) || (type === "int" && !Number.isInteger(v))) {
                input.isError = true;
                return;
            }
        }
        link.set(v);
        savedTimer.restart();
    }

    onEditingFinished: v => _save(v)

    Component.onDestruction: {
        if (value !== input.text)
            editingFinished(input.text);
    }

    Layout.fillWidth: true
    implicitHeight: grid.implicitHeight + Tokens.padding.medium + Math.max(0, Tokens.padding.large - input.verticalPadding) * 2

    HoverHandler {
        id: hover
    }

    RowPulse {
        link: root.link
    }

    Timer {
        id: savedTimer

        interval: 1500
    }

    GridLayout {
        id: grid

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        columns: root.narrow ? 1 : 3
        columnSpacing: Tokens.spacing.medium
        rowSpacing: Tokens.spacing.small

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
                visible: text.length > 0
                text: input.isError && root.errorText ? root.errorText : root.subtext
                color: input.isError && root.errorText ? Colours.palette.m3error : Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                animate: root.errorText
                opacity: root.link.blocked ? 0.5 : 1
            }

            SettingNotes {
                Layout.fillWidth: true
                link: root.link
            }
        }

        SettingMarks {
            Layout.alignment: Qt.AlignVCenter | (root.narrow ? Qt.AlignRight : 0)
            link: root.link
            hot: hover.hovered || input.activeFocus
        }

        StyledTextField {
            id: input

            Layout.fillWidth: root.narrow
            Layout.preferredWidth: root.narrow ? -1 : (root.smallField ? Tokens.sizes.nexus.smallTextFieldWidth : Tokens.sizes.nexus.textFieldWidth)
            Layout.maximumWidth: root.narrow ? Number.POSITIVE_INFINITY : root.width / 2
            Layout.alignment: Qt.AlignVCenter
            verticalPadding: Tokens.padding.small

            text: root.value
            placeholderText: text || activeFocus ? "" : root.placeholderText
            trailingIcon: savedTimer.running ? "check" : ""
            validate: root.link.entry?.validate ? new RegExp(root.link.entry.validate) : undefined
            enabled: !root.link.blocked
            opacity: root.link.blocked ? 0.5 : 1
            Accessible.name: root.label
            Accessible.description: root.link.blocked ? root.subtext + " " + root.link.disabledReason : root.subtext

            onTextEdited: root.valueEdited(text)
            onEditingFinished: root.editingFinished(text)
            // caelestia4: a long value (a path, a regexp) shows from its start while the field isn't being edited
            onActiveFocusChanged: if (!activeFocus) cursorPosition = 0
            onTextChanged: if (!activeFocus) cursorPosition = 0

            Keys.onEscapePressed: event => {
                if (root.link.active && input.text !== root.value) {
                    // caelestia4: a binding, not a copy, so a later reset or Undo still shows in the field
                    input.text = Qt.binding(() => root.value);
                    input.isError = false;
                } else {
                    event.accepted = false;
                }
            }

            // caelestia4: the outline leaves a gap at its top left for a floating label; with no label floating there
            // (above) it is an empty notch, so draw the border's line over it, the way the outline draws it
            // Only while the gap is open (the outline's outlineGapScale): over a closed outline it would draw twice
            Shape {
                anchors.fill: parent
                z: 1
                visible: input.activeFocus || input.text.length > 0
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    id: notchLine

                    readonly property real inset: strokeWidth / 2
                    readonly property real gapStart: inset + input.horizontalPadding - input.clampedRadius

                    strokeWidth: input.activeFocus ? 2 : 1
                    strokeColor: input.isError ? Colours.palette.m3error : (input.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline)
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    // Half a pixel up, as the outline lands (measured in nexus-shot: same two-row antialiasing)
                    startX: notchLine.gapStart - 0.5
                    startY: notchLine.inset - 0.5

                    PathLine {
                        x: notchLine.gapStart + root.Tokens.spacing.extraSmall * 2 + 0.5
                        y: notchLine.inset - 0.5
                    }
                }
            }
        }
    }

    FocusRing {
        focusItem: input
    }
}
