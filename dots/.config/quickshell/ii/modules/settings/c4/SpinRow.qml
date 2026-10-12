import QtQuick
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: whole-number setting with +/- buttons. Put the unit in the title, e.g. "Timeout (seconds)".
SettingRow {
    id: root

    property int value
    property int from: 0
    property int to: 100
    property int stepSize: 1
    signal moved(int value)

    StyledSpinBox {
        from: root.from
        to: root.to
        stepSize: root.stepSize
        value: root.value
        onValueModified: {
            root.moved(value);
            value = Qt.binding(() => root.value);
        }
    }
}
