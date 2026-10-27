pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import qs.modules.common as E4C // caelestia4: keep (end-4 background widgets / parallax settings)
import qs.modules.common.widgets as E4W // caelestia4: keep (FadeLoader)
import qs.modules.common.widgets.widgetCanvas as E4Canvas // caelestia4: keep
import qs.modules.caelestia.background.e4widgets.clock as E4Clock
import qs.modules.caelestia.background.e4widgets.weather as E4Weather

Variants {
    model: Screens.screens.filter(s => GlobalConfig.forScreen(s.name).background.enabled)

    StyledWindow {
        id: win

        required property ShellScreen modelData

        screen: modelData
        name: "background"
        WlrLayershell.exclusionMode: ExclusionMode.Ignore
        // caelestia4: while a video wallpaper plays (mpvpaper, background layer), sit above it and stay transparent
        // (unless this screen's workspace has a still of its own, upstream #2210)
        readonly property bool videoShowing: Wallpapers.videoShowingOn(modelData)
        WlrLayershell.layer: contentItem.Config.background.wallpaperEnabled && !videoShowing ? WlrLayer.Background : WlrLayer.Bottom
        color: contentItem.Config.background.wallpaperEnabled && !videoShowing ? "black" : "transparent"
        surfaceFormat.opaque: false

        anchors.top: true
        anchors.bottom: true
        anchors.left: true
        anchors.right: true

        // caelestia4: end-4's workspace parallax (Settings > Desktop > Background): the wallpaper is zoomed in and
        // slides with the active workspace's place in its group; the background widgets follow at widgetsFactor
        readonly property var parallax: E4C.Config.options.background.parallax
        readonly property real zoom: parallax.enableWorkspace ? Math.max(1, parallax.workspaceZoom) : 1
        readonly property bool verticalParallax: parallax.vertical
        readonly property int groupSize: Math.max(1, contentItem.Config.bar.workspaces.shown)
        readonly property int wsId: Hypr.monitorFor(modelData)?.activeWorkspace?.id ?? 1
        readonly property real fraction: groupSize <= 1 ? 0.5 : ((Math.max(1, wsId) - 1) % groupSize) / (groupSize - 1)

        ShellState.ComponentRef {
            screen: win.screen
            slot: "background"
            component: win
        }

        Item {
            id: behindClock

            anchors.fill: parent

            Item {
                id: wallLayer

                readonly property real extraW: parent.width * (win.zoom - 1)
                readonly property real extraH: parent.height * (win.zoom - 1)

                width: parent.width * win.zoom
                height: parent.height * win.zoom
                x: win.verticalParallax ? -extraW / 2 : -extraW * win.fraction
                y: win.verticalParallax ? -extraH * win.fraction : -extraH / 2

                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }

                Loader {
                    id: wallpaper

                    asynchronous: true

                    anchors.fill: parent
                    active: Config.background.wallpaperEnabled && !win.videoShowing

                    sourceComponent: Wallpaper {}
                }
            }

            Visualiser {
                anchors.fill: parent
                screen: win.modelData
                wallpaper: wallpaper
            }
        }

        // caelestia4: end-4's background widgets: cookie / digital clock (+ quote) and weather, draggable when their
        // placement is "free", else put on the wallpaper's least / most busy area. Settings > Desktop.
        E4Canvas.WidgetCanvas {
            readonly property real factor: E4C.Config.options.background.parallax.widgetsFactor / win.zoom

            width: parent.width
            height: parent.height
            x: (wallLayer.x + wallLayer.extraW / 2) * factor
            y: (wallLayer.y + wallLayer.extraH / 2) * factor

            E4W.FadeLoader {
                shown: E4C.Config.options.background.widgets.weather.enable
                sourceComponent: E4Weather.WeatherWidget {
                    screenWidth: win.screen.width
                    screenHeight: win.screen.height
                    scaledScreenWidth: win.screen.width
                    scaledScreenHeight: win.screen.height
                    wallpaperScale: 1
                }
            }

            E4W.FadeLoader {
                shown: E4C.Config.options.background.widgets.clock.enable
                sourceComponent: E4Clock.ClockWidget {
                    screenWidth: win.screen.width
                    screenHeight: win.screen.height
                    scaledScreenWidth: win.screen.width
                    scaledScreenHeight: win.screen.height
                    wallpaperScale: 1
                }
            }
        }

        Loader {
            id: clockLoader

            asynchronous: true
            active: Config.background.desktopClock.enabled

            anchors.margins: Tokens.padding.extraLargeIncreased
            anchors.leftMargin: Tokens.padding.extraLargeIncreased + Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, Config.border.thickness)

            state: Config.background.desktopClock.position
            states: [
                State {
                    name: "top-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "top-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "top-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.top: parent.top
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "middle-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "middle-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "middle-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                    }
                },
                State {
                    name: "bottom-left"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                    }
                },
                State {
                    name: "bottom-center"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                },
                State {
                    name: "bottom-right"

                    AnchorChanges {
                        target: clockLoader
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                    }
                }
            ]

            transitions: Transition {
                AnchorAnim {}
            }

            sourceComponent: DesktopClock {
                wallpaper: behindClock
                absX: clockLoader.x
                absY: clockLoader.y
            }
        }
    }
}
