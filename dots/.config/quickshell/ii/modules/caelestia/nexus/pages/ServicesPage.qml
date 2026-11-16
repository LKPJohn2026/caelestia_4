pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: the Services page links to its sub-pages (notifications, polling, media, capture, advanced). The input
// increments moved to Audio > Volume and Display > Brightness (proposal 2.3). The old "Reset window, input and display
// options" row is gone: the Hyprland sub-pages and Display reset their own options from the registry ("Reset page")
PageBase {
    id: root

    title: Tr.tr("Services")

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        NavRow {
            icon: "notifications"
            text: Tr.tr("Notifications")
            subtext: Tr.tr("Pop-ups, toasts, timeouts")
            onClicked: root.nState.openSubPage("notifications")
        }

        NavRow {
            icon: "update"
            text: Tr.tr("Polling & tuning")
            subtext: Tr.tr("Refresh rates, visualiser, colour scheme, GPU")
            onClicked: root.nState.openSubPage("polling")
        }

        NavRow {
            icon: "music_note"
            text: Tr.tr("Media & music recognition")
            subtext: Tr.tr("Lyrics, default player, song recognition")
            onClicked: root.nState.openSubPage("media")
        }

        NavRow {
            icon: "screenshot_region"
            text: Tr.tr("Screenshots & recording")
            subtext: Tr.tr("Save folders, region selector, circle to search")
            onClicked: root.nState.openSubPage("capture")
        }

        NavRow {
            icon: "tune"
            text: Tr.tr("Advanced")
            subtext: Tr.tr("Scrolling, user agent, config files")
            onClicked: root.nState.openSubPage("advanced")
        }
    }
}
