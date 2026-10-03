pragma Singleton
pragma ComponentBehavior: Bound

// caelestia4 ADAPTER: Notifs
// end-4's Notifications service stays the ONLY notification server (D-Bus org.freedesktop.Notifications),
// with its own history file and popup timeouts. This singleton mirrors end-4's list as NotifData wrappers,
// newest first, so both panel families show the same notifications.
// Contract used by Caelestia UI: list, notClosed, popups, dnd (read/write), hasFullscreen().
// dnd <-> end-4 `silent`. IPC target "notifs" (no clash with end-4).

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.adapters
import qs.modules.caelestia.components.misc

Singleton {
    id: root

    property list<NotifData> list: []
    readonly property list<NotifData> notClosed: list.filter(n => !n.closed)
    readonly property list<NotifData> popups: list.filter(n => n.popup)
    property bool dnd: E4.Notifications.silent

    property var byId: ({})

    function sync(): void {
        const seen = {};
        const next = [];
        for (const s of E4.Notifications.list) {
            const id = s.notificationId;
            seen[id] = true;
            let w = byId[id];
            if (!w || w.source !== s) {
                w = notifComp.createObject(root, {
                    source: s
                });
                byId[id] = w;
            }
            next.push(w);
        }
        for (const id of Object.keys(byId)) {
            if (!seen[id]) {
                const w = byId[id];
                delete byId[id];
                w.closed = true;
                Qt.callLater(() => w.destroy(1000)); // let removal animations finish
            }
        }
        next.sort((a, b) => b.time - a.time);
        list = next;
    }

    function hasFullscreen(): bool {
        for (const monitor of Hypr.monitors.values) {
            if (monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1))
                return true;
        }
        return false;
    }

    onDndChanged: {
        if (E4.Notifications.silent !== dnd)
            E4.Notifications.silent = dnd;

        if (!GlobalConfig.utilities.toasts.dndChanged)
            return;

        if (dnd)
            Toaster.toast(Tr.tr("Do not disturb enabled"), Tr.tr("Popup notifications are now disabled"), "do_not_disturb_on");
        else
            Toaster.toast(Tr.tr("Do not disturb disabled"), Tr.tr("Popup notifications are now enabled"), "do_not_disturb_off");
    }

    Component.onCompleted: sync()

    Connections {
        function onListChanged(): void {
            root.sync();
        }

        function onSilentChanged(): void {
            if (root.dnd !== E4.Notifications.silent)
                root.dnd = E4.Notifications.silent;
        }

        target: E4.Notifications
    }

    // qmllint disable unresolved-type
    CustomShortcut {
        // qmllint enable unresolved-type
        name: "clearNotifs"
        description: "Clear all notifications"
        onPressed: E4.Notifications.discardAllNotifications()
    }

    IpcHandler {
        function clear(): void {
            E4.Notifications.discardAllNotifications();
        }

        function isDndEnabled(): bool {
            return root.dnd;
        }

        function toggleDnd(): void {
            root.dnd = !root.dnd;
        }

        function enableDnd(): void {
            root.dnd = true;
        }

        function disableDnd(): void {
            root.dnd = false;
        }

        target: "notifs"
    }

    Component {
        id: notifComp

        NotifData {}
    }
}
