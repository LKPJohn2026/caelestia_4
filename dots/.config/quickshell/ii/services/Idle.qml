pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

/**
 * A nice wrapper for date and time strings.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.isNewHyprlandInstance) {
                root.inhibit = Persistent.states.idle.inhibit;
            } else {
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    // caelestia4: the Wayland inhibitor below only counts while its surface is "alive and visible" to Hyprland, and it
    // can be lost when the monitor drops off (G95NC DP link drops -> "dangling screen"). Also hold a logind idle
    // inhibitor: hypridle honours it (general:ignore_systemd_inhibit defaults to false) and it doesn't depend on any
    // surface or screen. Only "idle": a deliberate suspend (Super+Shift+L, session menu) still works.
    Process {
        running: root.inhibit
        command: ["systemd-inhibit", "--what=idle", "--mode=block", "--who=Caelestia shell", "--why=Keep awake is on", "sleep", "infinity"]
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // caelestia4: follow the current screen list, so the surface is recreated after a monitor drop
            screen: Quickshell.screens[0] ?? null
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
}
