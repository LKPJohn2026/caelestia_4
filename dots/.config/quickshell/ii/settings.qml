//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Adjust this to make the app smaller or larger
//@ pragma Env QT_SCALE_FACTOR=1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions as CF
import qs.modules.caelestia.settings as CSettings // caelestia4: Caelestia-style frame
import qs.modules.settings.c4 // caelestia4: registers the c4 pages/rows module with Quickshell's scanner (pages load by path)

ApplicationWindow {
    id: root
    property string firstRunFilePath: CF.FileUtils.trimFileProtocol(`${Directories.state}/user/first_run.txt`)
    property string firstRunFileContent: "This file is just here to confirm you've been greeted :>"
    property real contentPadding: 8
    property bool showNextTime: false
    // caelestia4: standard settings pages (modules/settings/c4, one setting per row). end-4's original page files
    // (QuickConfig, GeneralConfig, BarConfig, …) stay in the repo unlisted so upstream syncs merge cleanly.
    property var pages: [
        {
            name: Translation.tr("Appearance"),
            icon: "palette",
            component: "modules/settings/c4/AppearancePage.qml"
        },
        {
            name: Translation.tr("Desktop"),
            icon: "dock_to_bottom",
            component: "modules/settings/c4/DesktopPage.qml"
        },
        {
            name: Translation.tr("Windows"),
            icon: "select_window",
            component: "modules/settings/c4/WindowsPage.qml"
        },
        {
            name: Translation.tr("Input"),
            icon: "keyboard",
            component: "modules/settings/c4/InputPage.qml"
        },
        {
            name: Translation.tr("Display"),
            icon: "monitor",
            component: "modules/settings/c4/DisplayPage.qml"
        },
        {
            name: Translation.tr("Sound"),
            icon: "volume_up",
            component: "modules/settings/c4/SoundPage.qml"
        },
        {
            name: Translation.tr("Power & idle"),
            icon: "battery_charging_full",
            component: "modules/settings/c4/PowerPage.qml"
        },
        {
            name: Translation.tr("Apps & services"),
            icon: "apps",
            component: "modules/settings/c4/AppsPage.qml"
        },
        {
            name: Translation.tr("Games"),
            icon: "sports_esports",
            component: "modules/settings/c4/GamesPage.qml"
        },
        {
            name: Translation.tr("Advanced"),
            icon: "construction",
            component: "modules/settings/c4/AdvancedPage.qml"
        },
        {
            name: Translation.tr("end-4 panels"),
            icon: "history",
            component: "modules/settings/c4/FallbackPage.qml"
        },
        {
            name: Translation.tr("About"),
            icon: "info",
            component: "modules/settings/About.qml"
        }
    ]
    property alias currentPage: frame.currentPage // caelestia4

    visible: true
    onClosing: Qt.quit()
    title: "illogical-impulse Settings"

    Component.onCompleted: {
        MaterialThemeLoader.reapplyTheme()
        Config.readWriteDelay = 0 // Settings app always only sets one var at a time so delay isn't needed
    }

    minimumWidth: 750
    minimumHeight: 500
    width: 1100
    height: 750
    color: Appearance.m3colors.m3surface // caelestia4: Caelestia background

    ColumnLayout {
        anchors {
            fill: parent
            margins: 14 // caelestia4
        }
        focus: true // caelestia4: keeps Ctrl+PgUp/PgDn/Tab page switching working

        Keys.onPressed: (event) => {
            if (event.modifiers === Qt.ControlModifier) {
                if (event.key === Qt.Key_PageDown) {
                    root.currentPage = Math.min(root.currentPage + 1, root.pages.length - 1)
                    event.accepted = true;
                } 
                else if (event.key === Qt.Key_PageUp) {
                    root.currentPage = Math.max(root.currentPage - 1, 0)
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Tab) {
                    root.currentPage = (root.currentPage + 1) % root.pages.length;
                    event.accepted = true;
                }
                else if (event.key === Qt.Key_Backtab) {
                    root.currentPage = (root.currentPage - 1 + root.pages.length) % root.pages.length;
                    event.accepted = true;
                }
            }
        }

        // caelestia4: Caelestia-style frame (sidebar + rounded page container); pages are end-4's, unchanged
        CSettings.SettingsFrame {
            id: frame

            Layout.fillWidth: true
            Layout.fillHeight: true
            pages: root.pages
            screenName: root.screen?.name ?? ""
            onCloseRequested: root.close()
        }
    }
}
