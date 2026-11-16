pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Panels > OSD (shell.json osd.*), which upstream's Nexus has no page for; the same keys as end-4's
// Settings app (Desktop > On-screen display). The other rows need "Show when volume or brightness changes" (registry
// `requires`)
PageBase {
    id: root

    title: Tr.tr("On-screen display")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:osd.enabled"
        }

        DurationRow {
            setting: "c:osd.hideDelay"
        }

        ToggleRow {
            setting: "c:osd.enableBrightness"
        }

        ToggleRow {
            setting: "c:osd.enableMicrophone"
        }
    }
}
