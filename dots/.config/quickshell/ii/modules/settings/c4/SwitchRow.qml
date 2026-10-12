import QtQuick
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: on/off setting; the whole row toggles it. Emits toggled(newValue); the owner writes the config.
SettingRow {
    id: root

    property bool checked
    signal toggled(bool checked)

    clickable: true
    onRowClicked: root.toggled(!root.checked)

    StyledSwitch {
        checked: root.checked
        onClicked: {
            root.toggled(checked);
            checked = Qt.binding(() => root.checked);
        }
    }
}
