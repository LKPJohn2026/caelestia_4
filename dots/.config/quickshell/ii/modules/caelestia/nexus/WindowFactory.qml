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

    QtObject {
        id: dummy
    }

    Component {
        id: nexusComp

        FloatingWindow {
            id: win

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

            contentItem.Config.screen: screen.name
            contentItem.Tokens.screen: screen.name

            title: Tr.tr("Nexus — %1").arg(PageRegistry.pages[nexus.nState.currentPageIdx].label)

            Component.onDestruction: {
                if (root.openWindow === win)
                    root.openWindow = null;
            }

            Nexus {
                id: nexus

                anchors.fill: parent
                nState.screen: win.screen
                nState.isWindow: true
                onClose: win.destroy()
            }

            Behavior on color {
                CAnim {}
            }
        }
    }
}
