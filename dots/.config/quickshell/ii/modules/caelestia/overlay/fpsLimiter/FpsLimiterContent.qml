import qs.services
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.caelestia.overlay
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

OverlayBackground {
    id: root

    enum State { Normal, Success, Error }

    property real padding: Tokens.padding.large
    property var currentState: FpsLimiterContent.State.Normal
    implicitWidth: content.implicitWidth + (padding * 2)
    implicitHeight: content.implicitHeight + (padding * 2)

    Timer {
        id: iconResetTimer
        interval: 1000
        onTriggered: {
            root.currentState = FpsLimiterContent.State.Normal;
        }
    }

    function applyLimit() {
        var fpsValue = parseInt(fpsField.text);
        if (isNaN(fpsValue) || fpsValue < 0) {
            root.currentState = FpsLimiterContent.State.Error;
            iconResetTimer.restart();
            fpsField.text = "";
            return;
        }

        var cfgPaths = [
            "~/.config/MangoHud/MangoHud.conf",
        ]; // MangoHud config files

        var updateCommands = cfgPaths.map(path => {
            return "if grep -q '^fps_limit=' " + path + "; " +
            "then sed -i 's/^fps_limit=.*/fps_limit=" + fpsValue + "/' " + path + "; " +
            "else echo 'fps_limit=" + fpsValue + "' >> " + path + "; fi";
        }).join("; ");

        var cmd = updateCommands + "; pkill -SIGUSR2 mangohud";

        fpsSetter.command = ["bash", "-c", cmd];
        fpsSetter.startDetached();

        root.currentState = FpsLimiterContent.State.Success;
        iconResetTimer.restart();

        // Clear the field after applying
        fpsField.text = "";
    }

    Process {
        id: fpsSetter
    }

    // caelestia4: Caelestia text field + round apply button (shows a check / cross for a second after applying)
    RowLayout {
        id: content

        anchors.centerIn: parent
        spacing: Tokens.spacing.small

        StyledTextField {
            id: fpsField

            Layout.preferredWidth: 200
            leadingIcon: "speed"
            placeholderText: root.currentState === FpsLimiterContent.State.Error ? Translation.tr("Enter a valid number") : Translation.tr("FPS limit (0 = off)")
            inputMethodHints: Qt.ImhDigitsOnly
            focus: true
            onAccepted: root.applyLimit()
        }

        IconButton {
            id: applyButton

            isRound: true
            icon: switch (root.currentState) {
            case FpsLimiterContent.State.Error:
                return "close";
            case FpsLimiterContent.State.Success:
                return "check";
            default:
                return "save";
            }
            disabled: !(root.currentState === FpsLimiterContent.State.Normal && fpsField.text.length > 0)
            onClicked: root.applyLimit()
        }
    }
}
