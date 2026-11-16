pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common

// caelestia4: one Caelestia font (a FONT_CONFIG node of appearanceconfig.hpp: family, size, weight, italic, vaxes),
// by `prefix`, e.g. "c:appearance.font.body.medium": a FontRow for "<prefix>.family", a size stepper (points), a
// weight menu (Thin 100 to Black 900), an italic switch and, in an "Advanced" part, the variable font axes
// ("<prefix>.vaxes", a name → value map). Titles come from the registry entries; ones without an entry get plain
// titles here. `title` adds a section header above. It is a RowGroup of its own: put it in a page's RowGroup
RowGroup {
    id: root

    property string prefix
    property string title
    property bool showItalic: true
    property bool showAxes: true
    // An empty family follows the style's family (FONT_CONFIG nodes); a style node's family has no such meaning
    property string emptyFamilyText: Tr.tr("Same as the style")

    readonly property alias familyRow: familyRow
    readonly property alias sizeRow: sizeRow
    readonly property alias weightRow: weightRow

    readonly property list<MenuItem> weightItems: [
        MenuItem {
            text: Tr.trCtx("Thin", "font weight")
            value: 100
        },
        MenuItem {
            text: Tr.trCtx("Extra light", "font weight")
            value: 200
        },
        MenuItem {
            text: Tr.trCtx("Light", "font weight")
            value: 300
        },
        MenuItem {
            text: Tr.trCtx("Regular", "font weight")
            value: 400
        },
        MenuItem {
            text: Tr.trCtx("Medium", "font weight")
            value: 500
        },
        MenuItem {
            text: Tr.trCtx("Semi-bold", "font weight")
            value: 600
        },
        MenuItem {
            text: Tr.trCtx("Bold", "font weight")
            value: 700
        },
        MenuItem {
            text: Tr.trCtx("Extra bold", "font weight")
            value: 800
        },
        MenuItem {
            text: Tr.trCtx("Black", "font weight")
            value: 900
        }
    ]

    Layout.fillWidth: true
    // Its own header is the group's first item, which gets no top margin: keep the room a section header has
    Layout.topMargin: title ? Tokens.spacing.largeIncreased - Tokens.spacing.extraSmall / 2 : 0

    SectionHeader {
        visible: root.title.length > 0
        text: root.title
    }

    FontRow {
        id: familyRow

        setting: root.prefix ? root.prefix + ".family" : ""
        label: link.title || Tr.tr("Font")
        emptyText: root.emptyFamilyText
    }

    StepperRow {
        id: sizeRow

        setting: root.prefix ? root.prefix + ".size" : ""
        label: link.title || Tr.tr("Size")
        subtext: link.desc
        from: _shown(link.entry?.min ?? 4)
        to: _shown(link.entry?.max ?? 96)
    }

    SelectRow {
        id: weightRow

        setting: root.prefix ? root.prefix + ".weight" : ""
        label: link.title || Tr.tr("Weight")
        menuItems: root.weightItems
    }

    ToggleRow {
        visible: root.showItalic
        setting: root.prefix ? root.prefix + ".italic" : ""
        text: link.title || Tr.tr("Italic")
    }

    AdvancedSection {
        visible: root.showAxes
        key: root.prefix

        KeyValueListRow {
            setting: root.prefix ? root.prefix + ".vaxes" : ""
            label: link.title || Tr.tr("Variable font axes")
            subtext: link.desc || Tr.tr("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters")
            fields: [
                {
                    key: "key",
                    title: Tr.mark("Axis"),
                    type: "string"
                },
                {
                    key: "value",
                    title: Tr.mark("Value"),
                    type: "real"
                }
            ]
        }
    }
}
