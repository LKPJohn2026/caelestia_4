pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus

Singleton {
    id: root

    // caelestia4: one Nexus window (upstream #2208); opening it again focuses the open one
    property FloatingWindow openWindow: null

    function create(parent: Item, props: var): void {
        if (openWindow) {
            const toplevel = Hyprland.toplevels.values.find(t => t.title === openWindow.title);
            if (toplevel)
                Hyprland.dispatch(`hl.dsp.focus({ window = "address:0x${toplevel.address}" })`);
            return;
        }
        openWindow = nexusComp.createObject(parent ?? dummy, props);
    }

    // caelestia4: opens Nexus at a route ("page/sub#key", NexusState.navigate), or takes the open window there
    function openAt(route: string): void {
        if (openWindow) {
            openWindow.nState.navigate(route);
            create();
        } else {
            create(null, {
                initialRoute: route
            });
        }
    }

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

            property string initialRoute
            readonly property NexusState nState: nexus.nState

            color: Colours.tPalette.m3surface
            surfaceFormat.opaque: false

            onVisibleChanged: {
                if (!visible)
                    destroy();
            }

            implicitWidth: nexus.implicitWidth
            implicitHeight: nexus.implicitHeight

            minimumSize.width: contentItem.Tokens.sizes.nexus.minWidth
            minimumSize.height: contentItem.Tokens.sizes.nexus.minHeight

            // caelestia4: the screen's name, kept while Qt has the window on its nameless placeholder screen (ScreenName)
            readonly property ScreenName configScreenName: ScreenName {
                window: win
            }
            contentItem.Config.screen: configScreenName.name
            contentItem.Tokens.screen: configScreenName.name

            // caelestia4: "Nexus — " stays untranslated: hypr/hyprland/rules.lua floats and centres the window by it
            title: "Nexus — " + (PageRegistry.pages[nexus.nState.currentPageIdx]?.label ?? "")

            Component.onDestruction: {
                if (root.openWindow === win)
                    root.openWindow = null;
            }

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                nState.initialRoute: win.initialRoute
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
