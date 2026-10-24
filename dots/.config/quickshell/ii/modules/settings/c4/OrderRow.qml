import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: one entry of an ordered on/off list (the bar's layout): move up / down, and a switch. Emits
// moveRequested(delta) and toggled(newValue); the owner moves / writes the config.
SettingRow {
    id: root

    property bool checked
    property bool canMoveUp: true
    property bool canMoveDown: true
    signal toggled(bool checked)
    signal moveRequested(int delta)

    RowLayout {
        spacing: 4

        IconToolbarButton {
            implicitHeight: 36
            enabled: root.canMoveUp
            opacity: enabled ? 1 : 0.35
            text: "keyboard_arrow_up"
            onClicked: root.moveRequested(-1)
        }

        IconToolbarButton {
            implicitHeight: 36
            enabled: root.canMoveDown
            opacity: enabled ? 1 : 0.35
            text: "keyboard_arrow_down"
            onClicked: root.moveRequested(1)
        }

        StyledSwitch {
            Layout.leftMargin: 6
            checked: root.checked
            onClicked: {
                root.toggled(checked);
                checked = Qt.binding(() => root.checked);
            }
        }
    }
}
