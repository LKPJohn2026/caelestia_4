import QtQuick
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: an action (open a file, reset something, apply).
SettingRow {
    id: root

    property string buttonText
    property string buttonIcon
    signal clicked

    RippleButtonWithIcon {
        materialIcon: root.buttonIcon
        mainText: root.buttonText
        onClicked: root.clicked()
    }
}
