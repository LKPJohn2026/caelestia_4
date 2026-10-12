// caelestia4: the Assistant popped out of its drawer into a normal window (end-4's sidebarLeftToggleDetach).
// Super+Alt+A or Ctrl+D detaches / reattaches; Super+A shows / hides the window while detached. Hyprland tiles or
// floats it like any app window, so it can sit next to a browser while you chat. Same end-4 content as the drawer;
// the conversation lives in the Ai service, so it carries over (an unsent draft in the input box doesn't).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.common as E4C // caelestia4: keep

Scope {
    id: root

    LazyLoader {
        active: GlobalStates.assistantDetached

        FloatingWindow {
            id: window

            title: "Assistant"
            visible: GlobalStates.sidebarLeftOpen
            implicitWidth: E4C.Appearance.sizes.sidebarWidthExtended
            implicitHeight: 900
            color: Colours.palette.m3surface

            // Closing the window (Super+Q, the titlebar) hides the Assistant; it stays detached
            onVisibleChanged: {
                if (!visible)
                    GlobalStates.sidebarLeftOpen = false;
                else
                    Qt.callLater(() => content.item?.focusActiveItem());
            }

            Loader {
                id: content

                anchors.fill: parent
                anchors.margins: Tokens.padding.large
                focus: true

                sourceComponent: SidebarLeftContent {
                    scopeRoot: window
                }

                Keys.onPressed: event => {
                    if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_D) {
                        GlobalStates.assistantDetached = false;
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
