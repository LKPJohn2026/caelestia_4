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
    property string errorText: Translation.tr("Enter a valid number")
    // caelestia4: the limit is a line in MangoHud's config, read by MangoHud. Only a hint: a Flatpak's MangoHud reads the same
    // file with nothing on this side to find, and writing it does no harm
    property bool mangohudMissing: false
    onVisibleChanged: if (visible) mangohudCheck.running = true
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
            root.errorText = Translation.tr("Enter a valid number");
            root.currentState = FpsLimiterContent.State.Error;
            iconResetTimer.restart();
            fpsField.text = "";
            return;
        }

        // caelestia4: the outcome is the command's, so a limit that wasn't written doesn't show as done. pkill only tells
        // a running MangoHud to reload: none running isn't a failure
        fpsSetter.command = ["bash", "-c", `path="\${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud/MangoHud.conf"
            mkdir -p "$(dirname "$path")" || exit 1
            if grep -qs '^fps_limit=' "$path"; then sed -i 's/^fps_limit=.*/fps_limit=${fpsValue}/' "$path" || exit 1
            else { [ ! -s "$path" ] || [ -z "$(tail -c1 "$path")" ] || echo; echo 'fps_limit=${fpsValue}'; } >> "$path" || exit 1; fi
            pkill -SIGUSR2 mangohud; exit 0`];
        fpsSetter.running = true;

        // Clear the field after applying
        fpsField.text = "";
    }

    Process {
        id: fpsSetter
        onExited: exitCode => {
            root.errorText = Translation.tr("Couldn't save the limit");
            root.currentState = exitCode === 0 ? FpsLimiterContent.State.Success : FpsLimiterContent.State.Error;
            iconResetTimer.restart();
            mangohudCheck.running = true;
        }
    }

    Process {
        id: mangohudCheck
        running: true
        command: ["bash", "-c", `command -v mangohud || [ -s "\${XDG_CONFIG_HOME:-$HOME/.config}/MangoHud/MangoHud.conf" ]`]
        onExited: exitCode => root.mangohudMissing = exitCode !== 0
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
            placeholderText: root.currentState === FpsLimiterContent.State.Error ? root.errorText : root.mangohudMissing ? Translation.tr("FPS limit (needs MangoHud)") : Translation.tr("FPS limit (0 = off)")
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
