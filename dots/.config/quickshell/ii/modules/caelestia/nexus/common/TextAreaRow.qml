pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

// caelestia4: multi-line text setting (e.g. the AI's system prompt): label and subtext above a text area. Emits
// editingFinished(text) when it loses focus or the page closes, if the text changed. Upstream's Nexus has no such row
ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext: link.desc
    property string value: link.active ? String(link.value ?? "") : ""
    property alias placeholderText: area.placeholderText

    // caelestia4: a registry id: the area shows the setting and saves it when it loses focus (onEditingFinished still
    // runs); modified/reset, the applies chip and the disabled reason as on the other rows
    property string setting
    readonly property RowSetting link: RowSetting {
        sid: root.setting
        row: root
        screen: root.Config.screen
    }

    signal editingFinished(value: string)

    onEditingFinished: v => {
        if (link.active && v !== root.value)
            link.set(v);
    }

    Component.onDestruction: {
        if (area.text !== value)
            editingFinished(area.text);
    }

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + Tokens.padding.medium * 2

    HoverHandler {
        id: hover
    }

    RowPulse {
        link: root.link
    }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        RowLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.medium

            StyledText {
                id: label

                Layout.fillWidth: true
                text: root.link.title
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
                opacity: root.link.blocked ? 0.5 : 1
            }

            SettingMarks {
                link: root.link
                hot: hover.hovered || area.activeFocus
            }
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

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Math.max(area.implicitHeight, Tokens.font.body.small.pixelSize * 8)
            radius: Tokens.rounding.small
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)
            opacity: root.link.blocked ? 0.5 : 1

            T.TextArea {
                id: area

                anchors.fill: parent
                padding: Tokens.padding.medium
                text: root.value
                wrapMode: TextEdit.Wrap
                color: Colours.palette.m3onSurface
                placeholderTextColor: Colours.palette.m3onSurfaceVariant
                selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                selectedTextColor: color
                font: Tokens.font.body.small
                readOnly: root.link.blocked
                Accessible.name: root.label
                Accessible.description: root.subtext

                onActiveFocusChanged: {
                    if (!activeFocus && text !== root.value)
                        root.editingFinished(text);
                }
            }
        }
    }

    FocusRing {
        focusItem: area
    }
}
