pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    title: Tr.tr("Clock")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: General and Style, as on the other taskbar pages
        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:bar.clock.showDate"
        }

        ToggleRow {
            setting: "c:bar.clock.showSeconds"
        }

        SectionHeader {
            text: Tr.tr("Style")
        }

        ToggleRow {
            setting: "c:bar.clock.showIcon"
        }

        ToggleRow {
            setting: "c:bar.clock.background"
        }
    }
}
