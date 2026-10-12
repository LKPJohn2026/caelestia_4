import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: long text (prompt, list of patterns): title/description row with a full-width text area below.
ColumnLayout {
    id: root

    property string title
    property string description
    property string icon
    property string value
    property string placeholder
    signal edited(string value)

    Layout.fillWidth: true
    spacing: 4

    SettingRow {
        title: root.title
        description: root.description
        icon: root.icon
    }

    MaterialTextArea {
        Layout.fillWidth: true
        wrapMode: TextEdit.Wrap
        placeholderText: root.placeholder
        text: root.value
        onEditingFinished: {
            if (text !== root.value)
                root.edited(text);
        }
    }
}
