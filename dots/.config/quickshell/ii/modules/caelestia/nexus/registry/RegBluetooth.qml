import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "bluetooth" page (merged by Registry.qml). See RegPanels.qml for the
// format. The Bluetooth rows show live adapter and device state, not settings: they are "x:" ids with a route and a
// title only, so search finds them and lands on the row (pages/network/ActionMark.qml)
QtObject {
    readonly property var entries: ({
            // Connected devices (pages/BluetoothPage.qml)
            "x:bluetooth.enabled": {
                route: "bluetooth",
                title: Tr.mark("Bluetooth"),
                keywords: [Tr.mark("bluetooth"), Tr.mark("bt"), Tr.mark("wireless"), Tr.mark("turn off bluetooth"), Tr.mark("adapter")]
            },
            "x:bluetooth.pair": {
                route: "bluetooth",
                title: Tr.mark("Pair new device"),
                keywords: [Tr.mark("bluetooth"), Tr.mark("pair"), Tr.mark("connect"), Tr.mark("headphones"), Tr.mark("mouse"), Tr.mark("keyboard"), Tr.mark("speaker"), Tr.mark("add device")]
            },
            "x:bluetooth.discoverable": {
                route: "bluetooth",
                title: Tr.markCtx("Discoverable", "bluetooth setting"),
                keywords: [Tr.mark("bluetooth"), Tr.mark("discoverable"), Tr.mark("visible"), Tr.mark("find")]
            },
            "x:bluetooth.pairable": {
                route: "bluetooth",
                title: Tr.markCtx("Pairable", "bluetooth setting"),
                keywords: [Tr.mark("bluetooth"), Tr.mark("pairable"), Tr.mark("pairing")]
            }
        })
}
