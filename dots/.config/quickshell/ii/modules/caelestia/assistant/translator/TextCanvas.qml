import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

Rectangle {
    id: root
    property bool isInput: true // true for input, false for output
    property string placeholderText
    property string text: ""
    property var inputTextArea: isInput ? inputLoader.item : undefined
    readonly property string displayedText: isInput ? inputLoader.item.text : 
        root.text.length > 0 ? outputLoader.item.text : ""
    default property alias actionButtons: actions.data
    Layout.fillWidth: true
    implicitHeight: Math.max(150, inputColumn.implicitHeight)
    color: Colours.tPalette.m3surfaceContainerHigh
    radius: CC.Tokens.rounding.medium

    signal inputTextChanged(); // Signal emitted when text changes

    ColumnLayout {
        id: inputColumn
        anchors.fill: parent
        spacing: 0

        Loader {
            id: inputLoader
            active: root.isInput
            visible: root.isInput
            Layout.fillWidth: true
            sourceComponent: StyledTextArea { // Input area
                id: inputTextArea
                placeholderText: root.placeholderText
                wrapMode: TextEdit.Wrap
                textFormat: TextEdit.PlainText
                font.pixelSize: Appearance.font.pixelSize.small
                color: Colours.palette.m3onSurface
                padding: 15
                background: null
                onTextChanged: root.inputTextChanged()
            }
        }

        Loader {
            id: outputLoader
            active: !root.isInput
            visible: !root.isInput
            Layout.fillWidth: true
            sourceComponent: StyledText { // Output area
                id: outputTextArea
                padding: 15
                wrapMode: Text.Wrap
                font.pixelSize: Appearance.font.pixelSize.small
                color: root.text.length > 0 ? Colours.palette.m3onSurface : Colours.palette.m3outline
                text: root.text.length > 0 ? root.text : root.placeholderText
            }
        }

        Item { Layout.fillHeight: true } 

        RowLayout { // Status row
            Layout.fillWidth: true
            Layout.margins: 10
            spacing: 10

            Loader {
                active: root.isInput
                visible: root.isInput
                Layout.leftMargin: 10
                sourceComponent: Text {
                    text: Translation.tr("%1 characters").arg(inputLoader.item.text.length)
                    color: Colours.palette.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
            Item { Layout.fillWidth: true }
            RowLayout { // caelestia4: was end-4 ButtonGroup
                id: actions
            }
        }
    }
}