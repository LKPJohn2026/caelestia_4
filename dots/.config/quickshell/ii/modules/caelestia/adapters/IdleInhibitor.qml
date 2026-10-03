// caelestia4 ADAPTER: IdleInhibitor ("keep awake")
// Backed by end-4's Idle service, so both panel families share one inhibitor and one state.
// Contract used by Caelestia UI: enabled (read/write), enabledSince.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services as E4 // caelestia4: keep

Singleton {
    id: root

    property bool enabled: E4.Idle.inhibit
    property date enabledSince: new Date()

    onEnabledChanged: {
        if (enabled)
            enabledSince = new Date();
        if (E4.Idle.inhibit !== enabled)
            E4.Idle.toggleInhibit(enabled);
    }

    Connections {
        function onInhibitChanged(): void {
            if (root.enabled !== E4.Idle.inhibit)
                root.enabled = E4.Idle.inhibit;
        }

        target: E4.Idle
    }

    IpcHandler {
        function isEnabled(): bool {
            return root.enabled;
        }

        function toggle(): void {
            root.enabled = !root.enabled;
        }

        function enable(): void {
            root.enabled = true;
        }

        function disable(): void {
            root.enabled = false;
        }

        target: "idleInhibitor"
    }
}
