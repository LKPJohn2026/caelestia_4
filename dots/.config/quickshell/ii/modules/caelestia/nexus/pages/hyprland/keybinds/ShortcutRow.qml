pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: one shortcut: what it does, its state under it (changed, off, added), its keys on the right. Click (or
// Enter) opens the editor
ConnectedRect {
    id: root

    required property var modelData
    required property KeyNames names
    // caelestia4: another working shortcut on the same keys (both run), or null
    property var clashWith: null

    readonly property var s: modelData
    readonly property bool off: s.status === "disabled"
    readonly property string stateText: {
        if (clashWith && !off)
            return Tr.tr("Same keys as “%1”").arg(names.actionWords(clashWith));
        switch (s.status) {
        case "changed":
            return Tr.tr("Changed · was %1").arg(names.label(s.keys));
        case "disabled":
            return Tr.tr("Off");
        case "added":
            return Tr.tr("Added in Nexus");
        case "other":
            return Tr.tr("Made outside Nexus");
        }
        if (s.variant === "keypad")
            return Tr.tr("Number pad");
        if (s.variant === "keycode")
            return Tr.tr("Any keyboard layout");
        if (s.variant === "also")
            return Tr.tr("Second shortcut");
        return s.source === "custom" ? Tr.tr("Your shortcut") : "";
    }

    signal clicked

    Layout.fillWidth: true
    implicitHeight: row.implicitHeight + Tokens.padding.medium * 2

    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()
    onActiveFocusChanged: {
        if (!activeFocus)
            ring.pointerFocus = false;
    }

    Accessible.role: Accessible.Button
    Accessible.name: `${names.actionWords(s)}: ${names.label(s.currentKeys)}`
    Accessible.description: stateText
    Accessible.onPressAction: root.clicked()

    StateLayer {
        onPressed: {
            if (root.activeFocus)
                ring.pointerFocus = true;
        }
        onClicked: root.clicked()
    }

    FocusRing {
        id: ring

        focusItem: root
    }

    RowLayout {
        id: row

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        Column {
            Layout.fillWidth: true
            spacing: 0
            opacity: root.off ? 0.6 : 1

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                text: root.names.actionWords(root.s)
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledText {
                anchors.left: parent.left
                anchors.right: parent.right
                visible: text
                text: root.stateText
                color: root.clashWith && !root.off ? Colours.palette.m3error : root.s.status === "changed" || root.s.status === "added" ? Colours.palette.m3primary : Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
            }
        }

        // The keys, one chip each
        Flow {
            Layout.maximumWidth: root.width * 0.55
            Layout.preferredWidth: Math.min(implicitW, root.width * 0.55)
            layoutDirection: Qt.RightToLeft
            spacing: Tokens.spacing.extraSmall
            opacity: root.off ? 0.5 : 1

            readonly property var parts: root.names.parts(root.s.currentKeys).reverse()
            readonly property real implicitW: {
                let w = 0;
                for (let i = 0; i < chips.count; i++)
                    w += (chips.itemAt(i)?.implicitWidth ?? 0) + spacing;
                return Math.max(0, w - spacing);
            }

            Repeater {
                id: chips

                model: parent.parts

                StyledRect {
                    required property string modelData

                    implicitWidth: Math.max(implicitHeight, chipText.implicitWidth + Tokens.padding.small * 2)
                    implicitHeight: chipText.implicitHeight + Tokens.padding.extraSmall * 2
                    radius: Tokens.rounding.extraSmall
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
                    border.width: 1
                    border.color: Colours.palette.m3outlineVariant

                    StyledText {
                        id: chipText

                        anchors.centerIn: parent
                        text: parent.modelData
                        font: Tokens.font.label.medium
                        color: Colours.palette.m3onSurfaceVariant
                    }
                }
            }
        }
    }
}
