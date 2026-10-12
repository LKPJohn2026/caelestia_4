import QtQuick
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: pick one of several values from a dropdown. options: [{ label, value }]. Emits selected(value).
SettingRow {
    id: root

    property var options: []
    property var value
    signal selected(var value)

    StyledComboBox {
        implicitWidth: 240
        model: root.options
        textRole: "label"
        currentIndex: Math.max(0, root.options.findIndex(o => o.value === root.value))
        onActivated: index => {
            root.selected(root.options[index].value);
            currentIndex = Qt.binding(() => Math.max(0, root.options.findIndex(o => o.value === root.value)));
        }
    }
}
