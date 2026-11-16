pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    title: Tr.tr("Active window")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: General and Style, as on the other taskbar pages
        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: upstream #2097
        ToggleRow {
            setting: "c:bar.activeWindow.showTitle"
        }

        ToggleRow {
            setting: "c:bar.activeWindow.showOnHover"
        }

        ToggleRow {
            setting: "c:bar.popouts.activeWindow"
        }

        SectionHeader {
            text: Tr.tr("Style")
        }

        ToggleRow {
            setting: "c:bar.activeWindow.compact"
        }

        ToggleRow {
            setting: "c:bar.activeWindow.inverted"
        }
    }
}
