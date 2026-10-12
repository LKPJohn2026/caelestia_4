import QtQuick
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: short text setting (font family, path, URL). Saved when Enter is pressed or the field loses focus.
SettingRow {
    id: root

    property string value
    property string placeholder
    property int fieldWidth: 300
    signal edited(string value)

    MaterialTextField {
        implicitWidth: root.fieldWidth
        text: root.value
        placeholderText: root.placeholder
        onEditingFinished: {
            if (text !== root.value)
                root.edited(text);
        }
    }
}
