pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.filedialog
import qs.modules.common as E4C // caelestia4: keep

Item {
    id: root

    required property ScreenState screenState
    required property FileDialog facePicker

    readonly property var dashboardTabs: {
        const allTabs = [
            {
                component: dashComponent,
                iconName: "dashboard",
                text: Tr.tr("Dashboard"),
                enabled: Config.dashboard.showDashboard
            },
            {
                component: mediaComponent,
                iconName: "queue_music",
                text: Tr.tr("Media"),
                enabled: Config.dashboard.showMedia
            },
            {
                component: performanceComponent,
                iconName: "speed",
                text: Tr.tr("Performance"),
                enabled: Config.dashboard.showPerformance
            },
            {
                component: weatherComponent,
                iconName: "cloud",
                text: Tr.tr("Weather"),
                enabled: Config.dashboard.showWeather
            },
            // caelestia4: end-4 Todo and Timer (pomodoro + stopwatch) as dashboard tabs
            {
                component: todoComponent,
                iconName: "checklist",
                text: Tr.tr("Todo"),
                keepLoaded: true, // caelestia4: fixed-size pane, never lazy-unloaded (see Loader.active below)
                enabled: E4C.Config.options.caelestia.dashboardTodo
            },
            {
                component: timerComponent,
                iconName: "timer",
                text: Tr.tr("Timer"),
                keepLoaded: true,
                enabled: E4C.Config.options.caelestia.dashboardTimer
            }
        ];
        return allTabs.filter(tab => tab.enabled);
    }

    readonly property real nonAnimWidth: Math.max(view.implicitWidth, tabs.minimumWidth) + viewWrapper.anchors.margins * 2 // caelestia4: never narrower than the tab bar needs
    readonly property real nonAnimHeight: tabs.implicitHeight + tabs.anchors.topMargin + view.implicitHeight + viewWrapper.anchors.margins * 2

    implicitWidth: nonAnimWidth
    implicitHeight: nonAnimHeight

    Tabs {
        id: tabs

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: CUtils.clamp(anchors.margins - Config.border.thickness, 0, anchors.margins)
        anchors.margins: Tokens.padding.large

        nonAnimWidth: root.nonAnimWidth - anchors.margins * 2
        screenState: root.screenState
        tabs: root.dashboardTabs
    }

    ClippingRectangle {
        id: viewWrapper

        anchors.top: tabs.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.large

        radius: Tokens.rounding.large
        color: "transparent"

        Flickable {
            id: view

            readonly property int currentIndex: root.screenState.dashboardTab
            readonly property Item currentItem: {
                repeater.count; // Trigger update on count change
                return repeater.itemAt(currentIndex);
            }

            anchors.fill: parent

            flickableDirection: Flickable.HorizontalFlick

            implicitWidth: currentItem?.implicitWidth ?? 0
            implicitHeight: currentItem?.implicitHeight ?? 0

            contentX: currentItem?.x ?? 0
            contentWidth: row.implicitWidth
            contentHeight: row.implicitHeight

            onContentXChanged: {
                if (!moving || !currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 2)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 2)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
            }

            onDragEnded: {
                if (!currentItem)
                    return;

                const x = contentX - currentItem.x;
                if (x > currentItem.implicitWidth / 10)
                    root.screenState.dashboardTab = Math.min(root.screenState.dashboardTab + 1, tabs.count - 1);
                else if (x < -currentItem.implicitWidth / 10)
                    root.screenState.dashboardTab = Math.max(root.screenState.dashboardTab - 1, 0);
                else
                    contentX = Qt.binding(() => currentItem?.x ?? 0);
            }

            RowLayout {
                id: row

                Repeater {
                    id: repeater

                    model: ScriptModel {
                        values: root.dashboardTabs
                    }

                    // caelestia4: each pane is at least as wide as the tab bar, its content centred. The view is never
                    // narrower than the tab bar (long Vietnamese labels: ~920 px for 840 px panes), so a pane only as
                    // wide as its content let the next one show at the edge (Todo and Timer overlapped).
                    delegate: Item {
                        id: pane

                        required property int index
                        required property var modelData

                        Layout.alignment: Qt.AlignTop
                        implicitWidth: Math.max(paneLoader.implicitWidth, tabs.minimumWidth)
                        implicitHeight: paneLoader.implicitHeight
                        focus: index === view.currentIndex // caelestia4: Todo / Timer keys (N, Space, R, L, PgUp/PgDn)

                        Loader {
                            id: paneLoader

                            anchors.horizontalCenter: parent.horizontalCenter
                            focus: true

                            sourceComponent: pane.modelData.component

                            Component.onCompleted: active = Qt.binding(() => {
                                // caelestia4: end-4 panes stay loaded. Lazily (un)loading them changed their width,
                                // which fed back into this binding (binding loop) and collapsed the pane.
                                if (pane.modelData.keepLoaded)
                                    return true;
                                if (pane.index === view.currentIndex)
                                    return true;
                                const vx = Math.floor(view.visibleArea.xPosition * view.contentWidth);
                                const vex = Math.floor(vx + view.visibleArea.widthRatio * view.contentWidth);
                                return (vx >= pane.x && vx <= pane.x + pane.implicitWidth) || (vex >= pane.x && vex <= pane.x + pane.implicitWidth);
                            })
                        }
                    }
                }
            }

            Component {
                id: dashComponent

                Dash {
                    screenState: root.screenState
                    facePicker: root.facePicker
                }
            }

            Component {
                id: mediaComponent

                Media {
                    screenState: root.screenState
                }
            }

            Component {
                id: performanceComponent

                Performance {}
            }

            Component {
                id: weatherComponent

                WeatherTab {}
            }

            // caelestia4: Todo / Timer tabs (end-4's Todo and TimerService, Caelestia UI)
            Component {
                id: todoComponent

                TodoTab {}
            }

            Component {
                id: timerComponent

                TimerTab {}
            }

            Behavior on contentX {
                Anim {}
            }
        }
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Behavior on implicitHeight {
        Anim {}
    }
}
