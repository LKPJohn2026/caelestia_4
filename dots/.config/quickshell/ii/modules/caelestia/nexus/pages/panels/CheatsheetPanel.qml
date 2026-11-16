pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Panels > Keybind cheatsheet (Super+/, modules/caelestia/cheatsheet). The same keys as end-4's Settings
// app (Apps & services)
PageBase {
    id: root

    title: Tr.tr("Keybind cheatsheet")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Keys")
        }

        ToggleRow {
            setting: "e4:cheatsheet.useMacSymbol"
        }

        ToggleRow {
            setting: "e4:cheatsheet.useFnSymbol"
        }

        ToggleRow {
            setting: "e4:cheatsheet.useMouseSymbol"
        }

        ToggleRow {
            setting: "e4:cheatsheet.splitButtons"
        }

        TextFieldRow {
            setting: "e4:cheatsheet.superKey"
            placeholderText: "Super"
            smallField: true
        }
    }
}
