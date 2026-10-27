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
    property string subtext
    property string value
    property alias placeholderText: area.placeholderText

    signal editingFinished(value: string)

    Component.onDestruction: {
        if (area.text !== value)
            editingFinished(area.text);
    }

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        StyledText {
            id: label

            Layout.fillWidth: true
            font: Tokens.font.body.small
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.subtext
            text: root.subtext
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: Math.max(area.implicitHeight, Tokens.font.body.small.pixelSize * 8)
            radius: Tokens.rounding.small
            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

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

                onActiveFocusChanged: {
                    if (!activeFocus && text !== root.value)
                        root.editingFinished(text);
                }
            }
        }
    }
}
