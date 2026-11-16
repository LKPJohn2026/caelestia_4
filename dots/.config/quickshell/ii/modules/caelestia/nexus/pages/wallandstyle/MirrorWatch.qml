import QtQuick

// caelestia4: keeps the keys a registry entry `mirrors` in step with it. Fires `follow(v)` when the setting's value
// changes after it was first known (a toggle, a reset, the page's Reset, Undo), never for the value read on load, so
// opening the page writes nothing
QtObject {
    id: root

    property QtObject setting
    property var _last

    signal follow(var value)

    readonly property Connections _watch: Connections {
        function onValueChanged(): void {
            const v = root.setting.value;
            const was = root._last;
            root._last = v;
            if (was !== undefined && v !== undefined && v !== was)
                root.follow(v);
        }

        target: root.setting
    }

    Component.onCompleted: root._last = root.setting?.value
}
