import QtQuick
import qs.modules.caelestia.nexus.common

// caelestia4: lets a route's "#x:..." key (a search hit for a device action, e.g. "x:network.addNetwork" in
// registry/RegNetwork.qml) land on a row that has no setting: it registers the row with its PageBase and pulses it.
// Put it inside the row (for a ToggleRow: `parent: theToggle.bg`, `row: theToggle`). Holds no value: the row keeps
// working on live device state as before
RowPulse {
    id: root

    required property string sid
    // The row that scrolls into view; the item this fills by default
    property Item row: parent

    link: RowSetting {
        sid: root.sid
        row: root.row
    }
}
