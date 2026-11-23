pragma Singleton

import QtQuick
import Quickshell

/**
 * caelestia4: the results of scripts/images/least-busy-region-venv.sh (a widget's leastBusy/mostBusy place and the
 * wallpaper's dominant colour, for colText), kept by the script's arguments. The lock screen draws a second set of
 * desktop widgets (modules/ii/lock/LockBackdrop.qml), made at every lock: while locked a widget takes the result the
 * desktop's already has for the same wallpaper and size at once, instead of starting the script again and jumping
 * from its default place and colour a second later. Unlocked, a widget always runs the script (and keeps its result
 * here), so a wallpaper file changed in place is read again.
 */
Singleton {
    id: root

    property var results: ({})
    property var order: [] // the keys, oldest first
    readonly property int limit: 64

    function key(command: var): string {
        return JSON.stringify(command);
    }

    function get(command: var): var {
        return root.results[root.key(command)] ?? null;
    }

    function put(command: var, result: var) {
        const k = root.key(command);
        if (!(k in root.results)) {
            root.order.push(k);
            while (root.order.length > root.limit)
                delete root.results[root.order.shift()];
        }
        root.results[k] = result;
    }
}
