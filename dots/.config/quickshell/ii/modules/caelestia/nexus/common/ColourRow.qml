pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: a colour: a swatch and a hex field (#RRGGBB or #AARRGGBB; saved on Enter or focus loss, only when
// valid), and under them chips of the current scheme's colours (`showPalette`) that save at a click. An empty value
// means "Automatic" when `allowAutomatic` (default: when the default value is empty); its chip clears the value.
// `withHash` false saves "rrggbb" (end-4's accent colour is read either way). Without `setting`, bind `value` and
// handle chosen(colour)
SettingRow {
    id: root

    property string value: link.active ? String(link.value ?? "") : ""
    property bool withHash: link.entry?.hash ?? true
    property bool showPalette: true
    property bool allowAutomatic: link.entry?.allowEmpty ?? (link.active && link.s.defaultValue === "")
    property string automaticText: Tr.tr("Automatic")
    readonly property bool isValid: _hexRe.test(value)
    readonly property alias field: field
    // The scheme colours offered as chips: [role, label]
    readonly property var paletteRoles: [["m3primary", Tr.tr("Primary")], ["m3secondary", Tr.tr("Secondary")], ["m3tertiary", Tr.tr("Tertiary")], ["m3error", Tr.tr("Error")], ["m3primaryContainer", Tr.tr("Primary container")], ["m3secondaryContainer", Tr.tr("Secondary container")], ["m3tertiaryContainer", Tr.tr("Tertiary container")], ["m3onSurface", Tr.tr("Text")], ["m3outline", Tr.tr("Outline")]]

    signal chosen(colour: string)

    readonly property var _hexRe: /^#?([0-9a-fA-F]{6}|[0-9a-fA-F]{8})$/

    // The text as it is saved ("#rrggbb", lowercase), "" for automatic, undefined when not a colour
    function normalise(text: string): var {
        const t = String(text ?? "").trim();
        if (!t)
            return root.allowAutomatic ? "" : undefined;
        if (!root._hexRe.test(t))
            return undefined;
        const hex = t.replace(/^#/, "").toLowerCase();
        return root.withHash ? "#" + hex : hex;
    }

    function write(v: string): void {
        if (v !== root.value) {
            if (root.link.active)
                root.link.set(v);
            root.chosen(v);
        }
        field.settle();
    }

    function hexOf(c: color): string {
        return root.normalise(String(c).slice(0, 9)) ?? "";
    }

    focusItem: field

    Rectangle {
        implicitWidth: 28
        implicitHeight: 28
        radius: 14
        color: root.isValid ? (root.value.startsWith("#") ? root.value : "#" + root.value) : "transparent"
        border.width: 1
        border.color: Colours.palette.m3outline

        MaterialIcon {
            anchors.centerIn: parent
            visible: !root.isValid
            text: root.value ? "question_mark" : "auto_awesome"
            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.small
        }
    }

    RowTextField {
        id: field

        Layout.fillWidth: root.controlBelow
        Layout.preferredWidth: root.controlBelow ? -1 : Tokens.sizes.nexus.smallTextFieldWidth * 1.4
        savedText: root.value
        hint: root.allowAutomatic ? root.automaticText : "#rrggbb"
        validate: text => root.normalise(text) !== undefined
        emptyIsValid: root.allowAutomatic
        font.family: Tokens.font.mono.small.family
        Accessible.name: root.label
        Accessible.description: root.accessibleDescription
        onCommit: text => root.write(root.normalise(text))
    }

    // The chips go in the full-width part under the row
    below: Flow {
        visible: root.showPalette
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        StyledRect {
            visible: root.allowAutomatic
            implicitWidth: autoRow.implicitWidth + Tokens.padding.medium * 2
            implicitHeight: 28
            radius: Tokens.rounding.full
            color: root.value === "" ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

            Accessible.role: Accessible.Button
            Accessible.name: root.automaticText
            Accessible.onPressAction: root.write("")

            StateLayer {
                radius: parent.radius
                onClicked: root.write("")
            }

            RowLayout {
                id: autoRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                MaterialIcon {
                    text: root.value === "" ? "check" : "auto_awesome"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }

                StyledText {
                    text: root.automaticText
                    font: Tokens.font.label.medium
                }
            }
        }

        Repeater {
            model: root.paletteRoles

            Rectangle {
                id: chip

                required property var modelData
                readonly property color chipColour: Colours.palette[modelData[0]]
                readonly property string hex: root.hexOf(chipColour)
                readonly property bool selected: hex !== "" && hex === root.normalise(root.value)

                implicitWidth: 28
                implicitHeight: 28
                radius: 14
                color: chipColour
                border.width: selected ? 2 : 1
                border.color: selected ? Colours.palette.m3onSurface : Colours.palette.m3outlineVariant

                Accessible.role: Accessible.Button
                Accessible.name: modelData[1]
                Accessible.onPressAction: root.write(chip.hex)

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: chip.selected
                    text: "check"
                    color: Colours.palette.m3surface
                    fontStyle: Tokens.font.icon.small
                }

                StateLayer {
                    radius: chip.radius
                    onClicked: root.write(chip.hex)
                }
            }
        }
    }
}
