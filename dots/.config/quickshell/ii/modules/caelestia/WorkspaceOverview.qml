// caelestia4: end-4's workspace overview (window previews per workspace), WITHOUT end-4's search bar.
// In the caelestia family, search lives in Caelestia's launcher (merged with end-4's LauncherSearch), so
// end-4's Overview module (which also owns the Super/search shortcuts) is not loaded. This keeps Super+Tab.
// Based on end-4 modules/ii/overview/Overview.qml (search parts removed).
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs // caelestia4: keep
import qs.services // caelestia4: keep
import qs.modules.common // caelestia4: keep
import qs.modules.ii.overview // caelestia4: keep

Scope {
    id: root

    PanelWindow {
        id: panelWindow

        visible: GlobalStates.overviewOpen

        WlrLayershell.namespace: "quickshell:overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.overviewOpen ? content : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen)
                    GlobalFocusGrab.dismiss();
                else
                    GlobalFocusGrab.addDismissable(panelWindow);
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }

        Item {
            id: content

            visible: GlobalStates.overviewOpen
            focus: GlobalStates.overviewOpen
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 40
            implicitWidth: loader.implicitWidth
            implicitHeight: loader.implicitHeight

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape)
                    GlobalStates.overviewOpen = false;
            }

            Loader {
                id: loader

                active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                sourceComponent: OverviewWidget {
                    screen: panelWindow.screen
                }
            }
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"
        onPressed: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"
        onPressed: GlobalStates.overviewOpen = false
    }

    IpcHandler {
        function toggle(): void {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }

        function workspacesToggle(): void {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }

        function close(): void {
            GlobalStates.overviewOpen = false;
        }

        function open(): void {
            GlobalStates.overviewOpen = true;
        }

        target: "search" // same IPC target name end-4 uses, so existing scripts/keybinds keep working
    }
}
