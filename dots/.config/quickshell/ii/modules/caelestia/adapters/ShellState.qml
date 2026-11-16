pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

Singleton {
    property ShellRoot shellRoot

    function anySidebarOpen(): bool {
        return states.instances.some(s => s.sidebar);
    }

    function forScreen(screen: ShellScreen): ScreenState {
        for (const s of states.instances)
            if (s.modelData === screen)
                return s;
        // caelestia4: a screen that is going away (a monitor drop on resume) loses its ScreenState before the windows on
        // it are destroyed, and their bindings read screenState.<drawer> once more: give them one with every drawer shut.
        return detached;
    }

    // caelestia4: forScreen's stand-in for a screen with no state. It is shared, so a drawer opened on it (a
    // shortcut on a screen the config turns off) would show as open wherever it is used next: every drawer
    // stays shut.
    readonly property ScreenState detached: ScreenState {
        modelData: null
        reloadableId: "caelestia4-detached-screen-state"

        onBarChanged: bar = false
        onOsdChanged: osd = false
        onSessionChanged: session = false
        onLauncherChanged: launcher = false
        onDashboardChanged: dashboard = false
        onUtilitiesChanged: utilities = false
        onSidebarChanged: sidebar = false
        onAssistantChanged: assistant = false
        onBarHiddenChanged: barHidden = false
    }

    function forActive(): ScreenState {
        const mon = Hypr.focusedMonitor;
        for (const s of states.instances)
            if (Hypr.monitorFor(s.modelData) === mon)
                return s;
        return null;
    }

    function componentsFor(screen: ShellScreen): Components {
        for (const c of components.instances)
            if (c.modelData === screen)
                return c;
        return null;
    }

    function componentsForActive(): Components {
        const mon = Hypr.focusedMonitor;
        for (const c of components.instances)
            if (Hypr.monitorFor(c.modelData) === mon)
                return c;
        return null;
    }

    Variants {
        id: states

        model: Screens.screens

        ScreenState {}
    }

    Variants {
        id: components

        model: Screens.screens

        Components {}
    }

    component Components: QtObject {
        required property ShellScreen modelData

        property var background
        property var rootWindow
        property var interactionWrapper
        property var bar
        property var panels

        function find(name: string, rootItem: Item): var {
            return CUtils.findChild(rootItem ?? rootWindow?.contentItem, name);
        }

        function findAll(name: string, rootItem: Item): var {
            return CUtils.findChildren(rootItem ?? rootWindow?.contentItem, name);
        }

        function findMatching(pattern: string, rootItem: Item): var {
            return CUtils.findChildrenMatching(rootItem ?? rootWindow?.contentItem, pattern);
        }
    }

    component ComponentRef: QtObject {
        required property ShellScreen screen
        required property string slot
        required property var component

        readonly property QtObject target: ShellState.componentsFor(screen)

        onTargetChanged: {
            if (target)
                target[slot] = component;
        }
        Component.onDestruction: {
            if (target && target[slot] === component)
                target[slot] = null;
        }
    }
}
