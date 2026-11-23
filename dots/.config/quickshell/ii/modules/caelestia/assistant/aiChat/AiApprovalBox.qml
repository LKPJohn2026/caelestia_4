pragma ComponentBehavior: Bound

import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs.services
import qs.modules.common
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's
import qs.modules.caelestia.components.controls as CCtl // caelestia4: Caelestia buttons (aliased: other control names clash with end-4 widgets)
import "../../../../services/ai/safety.js" as Safety

// caelestia4: what the model asks to run (run_shell_command) or change (set_shell_config), waiting for the user.
// It is read from functionCall.args, not from the reply's Markdown, so the model can't hide part of it or show
// buttons of its own: plain text, wrapped, with control and invisible characters shown, and its size. It can't be
// edited, and Approve runs (or sets) exactly this text.
Rectangle {
    id: root

    property var messageData
    readonly property string functionName: messageData ? Ai.pendingFunctionName(messageData) : ""
    readonly property var args: messageData?.functionCall?.args ?? ({})
    readonly property bool isConfig: functionName === "set_shell_config"
    readonly property string requestText: String((isConfig ? args.value : args.command) ?? "")

    function currentValue(key) {
        let obj = Config.options;
        for (const part of String(key ?? "").split(".")) {
            if (obj === undefined || obj === null || obj[part] === undefined)
                return Translation.tr("(not set)");
            obj = obj[part];
        }
        try {
            return JSON.stringify(typeof obj === "object" ? ObjectUtils.toPlainObject(obj) : obj) ?? String(obj);
        } catch (e) {
            return String(obj);
        }
    }

    implicitHeight: column.implicitHeight + CC.Tokens.padding.normal * 2
    radius: CC.Tokens.rounding.small
    color: Colours.palette.m3surfaceContainerHighest

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: CC.Tokens.padding.normal
        spacing: CC.Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            font: CC.Tokens.font.body.medium
            color: Colours.palette.m3onSurface
            text: root.isConfig ? Translation.tr("The AI wants to change this setting") : Translation.tr("The AI wants to run this command")
        }

        StyledText {
            visible: root.isConfig
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.small
            color: Colours.palette.m3onSurface
            text: Translation.tr("Key: %1").arg(Safety.visibleText(root.args.key ?? ""))
        }

        StyledText {
            visible: root.isConfig
            Layout.fillWidth: true
            wrapMode: Text.WrapAnywhere
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.small
            color: Colours.palette.m3outline
            text: Translation.tr("Current value: %1").arg(Safety.visibleText(root.currentValue(root.args.key)))
        }

        StyledText {
            visible: root.isConfig
            Layout.fillWidth: true
            font: CC.Tokens.font.body.small
            color: Colours.palette.m3onSurface
            text: Translation.tr("New value:")
        }

        TextArea { // The command or value, as it runs
            Layout.fillWidth: true
            readOnly: true
            selectByMouse: true
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.WrapAnywhere
            renderType: Text.NativeRendering
            font.family: Appearance.font.family.monospace
            font.pixelSize: Appearance.font.pixelSize.small
            color: Colours.palette.m3onSurface
            selectedTextColor: Colours.palette.m3onSecondaryContainer
            selectionColor: Colours.palette.m3secondaryContainer
            background: Rectangle {
                radius: CC.Tokens.rounding.extraSmall
                color: Colours.tPalette.m3surfaceContainerHigh
            }
            text: Safety.visibleText(root.requestText)
        }

        RowLayout {
            Layout.fillWidth: true

            StyledText {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                font: CC.Tokens.font.body.small
                color: Colours.palette.m3outline
                text: Translation.tr("%1 lines, %2 characters").arg(Safety.lineCount(root.requestText)).arg(Safety.charCount(root.requestText))
            }

            CCtl.TextButton {
                type: CCtl.TextButton.Tonal
                text: Translation.tr("Reject")
                onClicked: Ai.rejectCommand(root.messageData)
            }
            CCtl.TextButton {
                enabled: root.messageData?.done ?? false // only once the whole reply is in
                text: Translation.tr("Approve")
                onClicked: Ai.approveCommand(root.messageData)
            }
        }
    }
}
