pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs // caelestia4: keep

// caelestia4: end-4's screen translator (modules/ii/screenTranslator) with the Caelestia-styled panel. Same IPC
// target ("screenTranslator") and global shortcut (screenTranslate). Needs a Google Cloud service account key
// (Vision + Translation APIs), set from the panel's key button.
Scope {
    id: root

    readonly property var currentScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null

    function dismiss(): void {
        GlobalStates.screenTranslatorOpen = false;
    }

    function translate(): void {
        GlobalStates.screenTranslatorOpen = true;
    }

    Loader {
        id: loader

        property var lockedScreen

        active: false

        Connections {
            target: GlobalStates

            function onScreenTranslatorOpenChanged(): void {
                if (!GlobalStates.screenTranslatorOpen) {
                    loader.active = false;
                } else {
                    loader.lockedScreen = root.currentScreen;
                    loader.active = true;
                }
            }
        }

        sourceComponent: ScreenTranslatorPanel {
            screen: loader.lockedScreen
            onDismiss: root.dismiss()
        }
    }

    IpcHandler {
        target: "screenTranslator"

        function translate(): void {
            root.translate();
        }
    }

    GlobalShortcut {
        name: "screenTranslate"
        description: "Translates screen content"
        onPressed: root.translate()
    }
}
