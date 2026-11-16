pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common

// caelestia4: sub-page of ServicesPage (route services/notifications). Rows name registry ids
// (registry/RegServices.qml); the menus keep their icons
PageBase {
    id: root

    // Notification fullscreen visibility, values of config::NotifsFullscreen (On, Off)
    readonly property list<MenuItem> notifFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("On", "show notifications over fullscreen apps")
            icon: "notifications"
            value: 0
        },
        MenuItem {
            text: Tr.trCtx("Off", "show notifications over fullscreen apps")
            icon: "notifications_off"
            value: 1
        }
    ]

    // Toast fullscreen visibility (GlobalConfig.utilities.toasts.fullscreen)
    readonly property list<MenuItem> toastFullscreenItems: [
        MenuItem {
            text: Tr.trCtx("Off", "show toasts over fullscreen apps")
            icon: "notifications_off"
            value: "off"
        },
        MenuItem {
            text: Tr.trCtx("Important", "show toasts over fullscreen apps: important ones only")
            icon: "priority_high"
            value: "important"
        },
        MenuItem {
            text: Tr.trCtx("On", "show toasts over fullscreen apps")
            icon: "notifications"
            value: "all"
        }
    ]

    title: Tr.tr("Notifications")
    isSubPage: true

    // caelestia4: pop-ups first (what most people change), then toasts, then the drag distances in Advanced. The
    // timeouts are stored in ms and shown in seconds (DurationRow)
    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Pop-ups")
        }

        ToggleRow {
            setting: "c:notifs.expire"
        }

        DurationRow {
            setting: "c:notifs.defaultExpireTimeout"
            maxUnit: "s"
        }

        SelectRow {
            setting: "c:notifs.fullscreen"
            menuItems: root.notifFullscreenItems
        }

        DurationRow {
            setting: "c:notifs.fullscreenExpireTimeout"
            maxUnit: "s"
        }

        ToggleRow {
            setting: "c:notifs.openExpanded"
        }

        StepperRow {
            setting: "c:notifs.groupPreviewNum"
        }

        // caelestia4: from end-4's Settings app (Desktop > Notifications)
        ToggleRow {
            setting: "c:notifs.actionOnClick"
        }

        SectionHeader {
            text: Tr.tr("Toasts")
        }

        SelectRow {
            setting: "c:utilities.toasts.fullscreen"
            menuItems: root.toastFullscreenItems
        }

        StepperRow {
            setting: "c:utilities.maxToasts"
        }

        SectionHeader {
            text: Tr.tr("Toast events")
        }

        ToggleRow {
            setting: "c:utilities.toasts.chargingChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.gameModeChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.dndChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.audioOutputChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.audioInputChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.capsLockChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.numLockChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.kbLayoutChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.kbLimit"
        }

        ToggleRow {
            setting: "c:utilities.toasts.vpnChanged"
        }

        ToggleRow {
            setting: "c:utilities.toasts.nowPlaying"
        }

        ToggleRow {
            setting: "c:utilities.toasts.configLoaded"
        }

        AdvancedSection {
            StepperRow {
                setting: "c:notifs.clearThreshold"
            }

            StepperRow {
                setting: "c:notifs.expandThreshold"
            }
        }
    }
}
