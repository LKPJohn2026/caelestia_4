// caelestia4 ADAPTER: NotifData
// A Caelestia-shaped view of ONE end-4 notification (end-4's Notifications.Notif in `source`).
// end-4 owns the notification server, history, persistence and popup timeouts; this object only maps fields.
// Contract used by Caelestia UI: popup (read/write), closed, time, timeStr, ageMins, notification, notificationId,
// summary, body, appIcon, appName, image, hints, expireTimeout, urgency (NotificationUrgency), resident,
// hasActionIcons, actions[{identifier,text,invoke}], hasFullscreen, timer.start()/stop(), lock/unlock/close.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.adapters

QtObject {
    id: notif

    property var source // end-4 Notifications.Notif

    property bool popup: source?.popup ?? false
    property bool closed
    property var locks: new Set()

    readonly property date time: new Date(source?.time ?? Date.now())
    property int ageMins: 0
    readonly property string timeStr: {
        if (ageMins < 1)
            return Tr.tr("now");

        const h = Math.floor(ageMins / 60);
        const d = Math.floor(h / 24);

        if (d > 0)
            return Tr.trCtx("%1d", "abbreviated notification age, days").arg(d);
        if (h > 0)
            return Tr.trCtx("%1h", "abbreviated notification age, hours").arg(h);
        return Tr.trCtx("%1m", "abbreviated notification age, minutes").arg(ageMins);
    }

    readonly property Timer timeStrTimer: Timer {
        running: !notif.closed
        repeat: true
        interval: 5000
        onTriggered: notif.updateTimeStr()
    }

    readonly property Notification notification: source?.notification ?? null
    readonly property string notificationId: String(source?.notificationId ?? "")
    readonly property string summary: source?.summary ?? ""
    readonly property string body: source?.body ?? ""
    readonly property string appIcon: source?.appIcon ?? ""
    readonly property string appName: source?.appName ?? ""
    readonly property string image: source?.image ?? ""
    readonly property var hints: notification?.hints ?? ({})
    readonly property real expireTimeout: notification?.expireTimeout ?? GlobalConfig.notifs.defaultExpireTimeout
    readonly property int urgency: {
        if (notification)
            return notification.urgency;
        const u = String(source?.urgency ?? "normal").toLowerCase();
        if (u === "0" || u === "low")
            return NotificationUrgency.Low;
        if (u === "2" || u === "critical")
            return NotificationUrgency.Critical;
        return NotificationUrgency.Normal;
    }
    readonly property bool resident: notification?.resident ?? false
    readonly property bool hasActionIcons: notification?.hasActionIcons ?? false
    readonly property list<var> actions: (source?.actions ?? []).map(a => ({
                identifier: a.identifier,
                text: a.text,
                invoke: () => E4.Notifications.attemptInvokeAction(notif.source.notificationId, a.identifier)
            }))

    readonly property bool hasFullscreen: {
        const monitor = Hypr.focusedMonitor;
        const specialName = monitor?.lastIpcObject.specialWorkspace?.name;
        if (specialName) {
            const specialWs = Hypr.workspaces.values.find(ws => ws.name === specialName);
            return specialWs?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
        }
        return monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false;
    }

    // Hover pauses the popup timeout. end-4 owns the timer (it may not exist, e.g. expireTimeout == 0).
    readonly property QtObject timer: QtObject {
        function start(): void {
            notif.source?.timer?.start();
        }

        function stop(): void {
            notif.source?.timer?.stop();
        }
    }

    // UI hides a popup (swipe / click): tell end-4 so both families agree
    onPopupChanged: {
        if (!popup && source?.popup)
            E4.Notifications.timeoutNotification(source.notificationId);
    }

    readonly property Connections sourceConn: Connections {
        function onPopupChanged(): void {
            if (notif.popup !== notif.source.popup)
                notif.popup = notif.source.popup;
        }

        target: notif.source
        ignoreUnknownSignals: true
    }

    function updateTimeStr(): void {
        const diff = Date.now() - time.getTime();
        const m = Math.floor(diff / 60000);
        ageMins = m;

        if (m < 1) {
            timeStrTimer.interval = 5000;
        } else {
            const h = Math.floor(m / 60);
            const d = Math.floor(h / 24);

            if (d > 0)
                timeStrTimer.interval = 3600000;
            else if (h > 0)
                timeStrTimer.interval = 300000;
            else
                timeStrTimer.interval = m < 10 ? 30000 : 60000;
        }
    }

    function lock(item: Item): void {
        locks.add(item);
    }

    function unlock(item: Item): void {
        locks.delete(item);
        if (closed)
            close();
    }

    // Caelestia UI calls close(); the item is removed by end-4 and Notifs.sync() then drops this wrapper.
    function close(): void {
        closed = true;
        if (locks.size === 0 && source)
            E4.Notifications.discardNotification(source.notificationId);
    }

    Component.onCompleted: updateTimeStr()
}
