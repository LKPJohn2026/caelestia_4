pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: Panels > OSD (shell.json osd.*), which upstream's Nexus has no page for; the same keys as end-4's
// Settings app (Desktop > On-screen display)
PageBase {
    id: root

    title: Tr.tr("On-screen display")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Show when volume or brightness changes")
            value: Config.osd.enabled
            onToggled: GlobalConfig.osd.enabled = checked
        }

        StepperRow {
            enabled: Config.osd.enabled
            label: Tr.tr("Hide after (ms)")
            value: Config.osd.hideDelay
            from: 500
            to: 10000
            stepSize: 250
            onMoved: v => GlobalConfig.osd.hideDelay = v
        }

        ToggleRow {
            disabled: !Config.osd.enabled
            text: Tr.tr("Brightness slider")
            value: Config.osd.enableBrightness
            onToggled: GlobalConfig.osd.enableBrightness = checked
        }

        ToggleRow {
            last: true
            disabled: !Config.osd.enabled
            text: Tr.tr("Microphone slider")
            value: Config.osd.enableMicrophone
            onToggled: GlobalConfig.osd.enableMicrophone = checked
        }
    }
}
