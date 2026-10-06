pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: one keybind category as a Caelestia card. Filtering/naming logic is end-4's
// (modules/ii/cheatsheet/CheatsheetKeybindsCategory): binds whose description is "Category: text"; numbered and
// directional repeats collapse to one "<Number>"/"<Direction>" row; key-name substitutions follow end-4's
// cheatsheet options (superKey, useMacSymbol, useFnSymbol, useMouseSymbol, splitButtons).
StyledRect {
    id: root

    required property string modelData // category name; "" = uncategorized
    readonly property string categoryName: modelData
    readonly property bool isCategorized: categoryName.length > 0
    readonly property var opts: E4C.Config.options.cheatsheet
    property real maxModsWidth: 0

    readonly property var macSymbolMap: ({
            Ctrl: "󰘴",
            Alt: "󰘵",
            Shift: "󰘶",
            Space: "󱁐",
            Tab: "↹",
            Equal: "󰇼",
            Minus: "",
            Print: "",
            BackSpace: "󰭜",
            Delete: "⌦",
            Return: "󰌑",
            Period: ".",
            Escape: "⎋"
        })
    readonly property var functionSymbolMap: ({
            F1: "󱊫",
            F2: "󱊬",
            F3: "󱊭",
            F4: "󱊮",
            F5: "󱊯",
            F6: "󱊰",
            F7: "󱊱",
            F8: "󱊲",
            F9: "󱊳",
            F10: "󱊴",
            F11: "󱊵",
            F12: "󱊶"
        })
    readonly property var mouseSymbolMap: ({
            mouse_up: "󱕐",
            mouse_down: "󱕑",
            "mouse:272": "L󰍽",
            "mouse:273": "R󰍽",
            "Scroll ↑/↓": "󱕒",
            "Page_↑/↓": "⇞/⇟"
        })
    readonly property list<string> keyBlacklist: ["SUPER_L", "SUPER_R"]
    readonly property var keySubstitutions: Object.assign({
        Super: "Super",
        mouse_up: "Scroll ↓",
        mouse_down: "Scroll ↑",
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        Slash: "/",
        Hash: "#",
        Return: "Enter"
    }, opts.superKey ? {
        Super: opts.superKey
    } : {}, opts.useMacSymbol ? macSymbolMap : {}, opts.useFnSymbol ? functionSymbolMap : {}, opts.useMouseSymbol ? mouseSymbolMap : {})

    readonly property var binds: E4.HyprlandKeybinds.keybinds.filter(b => b.description?.length > 0 && (isCategorized ? b.description.substring(0, b.description.indexOf(":")) === categoryName : b.description.indexOf(":") === -1) && !nonFirstRepetitive(b))

    function modMaskToList(mask: int): list<string> {
        const list = [];
        if (mask & (1 << 2))
            list.push("Ctrl");
        if (mask & (1 << 6))
            list.push("Super");
        if (mask & (1 << 0))
            list.push("Shift");
        if (mask & (1 << 3))
            list.push("Alt");
        if (mask & (1 << 1))
            list.push("Caps");
        if (mask & (1 << 4))
            list.push("Mod2");
        if (mask & (1 << 5))
            list.push("Mod3");
        if (mask & (1 << 7))
            list.push("Mod5");
        return list;
    }

    function nonFirstRepetitive(bind: var): bool {
        const key = bind.key;
        if (key.includes("mouse") || key.includes("page"))
            return false;
        if (/\d/.test(key) && !key.includes("1"))
            return true;
        return /^(right|up|down)\b/i.test(key);
    }

    function firstRepetitive(bind: var): bool {
        return bind.key.includes("1") || /left/i.test(bind.key);
    }

    function transformKey(key: string): string {
        return (keySubstitutions[key] || key).replace("1", "<Number>").replace("Left", "<Direction>");
    }

    function transformDescription(bind: var): string {
        const text = bind.description.replace(new RegExp("\\s*" + categoryName + "\\s*:\\s*"), "");
        if (!firstRepetitive(bind))
            return text;
        return text.replace("1", "<Number>").replace(/ \b(left|right|up|down)\b/i, " <Direction>");
    }

    visible: binds.length > 0
    implicitWidth: column.implicitWidth + Tokens.padding.large * 2
    implicitHeight: column.implicitHeight + Tokens.padding.large * 2
    radius: Tokens.rounding.large
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: Tokens.padding.large
        spacing: Tokens.spacing.small

        StyledText {
            Layout.bottomMargin: Tokens.spacing.extraSmall
            text: root.isCategorized ? root.categoryName : Tr.tr("Other")
            font: Tokens.font.title.small
            color: Colours.palette.m3primary
        }

        Repeater {
            model: root.binds

            RowLayout {
                id: bindRow

                required property var modelData
                readonly property var mods: {
                    const list = root.modMaskToList(modelData.modmask).map(m => root.keySubstitutions[m] || m);
                    if (list.length === 0)
                        return [];
                    return root.opts.splitButtons ? list : [list.join(" ")];
                }
                readonly property bool showKey: !root.keyBlacklist.includes(modelData.key)

                spacing: Tokens.spacing.large

                Row {
                    id: keys

                    Layout.preferredWidth: root.maxModsWidth
                    spacing: Tokens.spacing.extraSmall
                    Component.onCompleted: root.maxModsWidth = Math.max(root.maxModsWidth, implicitWidth)
                    onImplicitWidthChanged: root.maxModsWidth = Math.max(root.maxModsWidth, implicitWidth)

                    Repeater {
                        model: bindRow.mods

                        KeyCap {
                            required property string modelData

                            text: root.transformKey(modelData)
                        }
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: bindRow.showKey && bindRow.modelData.modmask > 0
                        text: "+"
                        color: Colours.palette.m3outline
                    }

                    KeyCap {
                        visible: bindRow.showKey
                        text: root.transformKey(bindRow.modelData.key)
                        primary: true
                    }
                }

                StyledText {
                    text: root.transformDescription(bindRow.modelData)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                }
            }
        }
    }

    component KeyCap: StyledRect {
        property alias text: label.text
        property bool primary: false

        implicitWidth: Math.max(implicitHeight, label.implicitWidth + Tokens.padding.medium * 2)
        implicitHeight: label.implicitHeight + Tokens.padding.extraSmall * 2
        radius: Tokens.rounding.small
        color: primary ? Colours.palette.m3secondaryContainer : Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

        StyledText {
            id: label

            anchors.centerIn: parent
            font: Tokens.font.mono.small
            color: parent.primary ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
        }
    }
}
