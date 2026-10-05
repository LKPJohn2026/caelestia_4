pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: live window previews above a hovered dock app (end-4 DockApps preview popup, Caelestia style).
// Click a preview = focus that window, middle-click or ✕ = close it.
PopupWindow {
    id: root

    required property var dockWindow // the dock's StyledWindow
    required property Item dockContent

    property Item hoveredApp: null // DockApp under the pointer
    property Item shownApp: null // DockApp whose windows are shown
    property bool shown: false

    readonly property real previewWidth: 280
    readonly property real previewHeight: 160
    readonly property bool wanted: (hoveredApp !== null && hoveredApp.toplevels.length > 0) || (popupArea.containsMouse && shownApp !== null)

    onHoveredAppChanged: {
        if (hoveredApp && hoveredApp.toplevels.length > 0)
            shownApp = hoveredApp;
        timer.restart();
    }
    onWantedChanged: timer.restart()

    Timer {
        id: timer

        interval: root.shown ? 200 : 400
        onTriggered: {
            root.shown = root.wanted;
            if (!root.shown)
                root.shownApp = null;
        }
    }

    // Caelestia tokens/config are per screen (StyledWindow sets this for normal windows)
    contentItem.Config.screen: dockWindow.screen.name
    contentItem.Tokens.screen: dockWindow.screen.name

    anchor.window: dockWindow
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: dockWindow.width
    anchor.rect.height: 1
    anchor.edges: Edges.Top | Edges.Left
    anchor.gravity: Edges.Top | Edges.Right
    anchor.adjustment: PopupAdjustment.None

    implicitWidth: dockWindow.width
    implicitHeight: card.implicitHeight + 24 // room for the card's elevation (no Tokens at window level)
    color: "transparent"
    visible: shown || card.opacity > 0
    mask: Region {
        item: popupArea
    }

    MouseArea {
        id: popupArea

        x: card.x - Tokens.padding.medium
        y: card.y - Tokens.padding.medium
        width: card.width + Tokens.padding.medium * 2
        height: card.height + Tokens.padding.medium * 2
        hoverEnabled: true
    }

    StyledRect {
        id: card

        readonly property real centerX: {
            const app = root.shownApp;
            if (!app || !app.visible)
                return root.width / 2;
            return app.mapToItem(null, app.width / 2, 0).x;
        }

        x: Math.max(Tokens.padding.large, Math.min(root.width - width - Tokens.padding.large, centerX - width / 2))
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Tokens.padding.small
        implicitWidth: previews.implicitWidth + Tokens.padding.small * 2
        implicitHeight: previews.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.large
        color: Colours.tPalette.m3surfaceContainer
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.95
        transformOrigin: Item.Bottom

        Behavior on opacity {
            Anim {
                type: Anim.FastEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.FastSpatial
            }
        }
        Behavior on x {
            enabled: root.shown
            Anim {
                type: Anim.FastSpatial
            }
        }

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 2
        }

        RowLayout {
            id: previews

            anchors.centerIn: parent
            spacing: Tokens.spacing.small

            Repeater {
                model: ScriptModel {
                    values: root.shownApp?.toplevels ?? []
                }

                StyledRect {
                    id: windowCard

                    required property var modelData // Quickshell Toplevel

                    implicitWidth: root.previewWidth
                    implicitHeight: column.implicitHeight + Tokens.padding.small * 2
                    radius: Tokens.rounding.medium
                    color: windowCard.modelData.activated ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

                    StateLayer {
                        radius: Tokens.rounding.medium
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                        onClicked: event => {
                            if (event.button === Qt.MiddleButton)
                                windowCard.modelData.close();
                            else
                                windowCard.modelData.activate();
                        }
                    }

                    ColumnLayout {
                        id: column

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        spacing: Tokens.spacing.extraSmall

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Tokens.spacing.small

                            StyledText {
                                Layout.fillWidth: true
                                Layout.leftMargin: Tokens.padding.extraSmall
                                text: windowCard.modelData.title
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            IconButton {
                                type: IconButton.Text
                                icon: "close"
                                onClicked: windowCard.modelData.close()
                            }
                        }

                        StyledClippingRect {
                            Layout.fillWidth: true
                            implicitHeight: root.previewHeight
                            radius: Tokens.rounding.small
                            color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                            ScreencopyView {
                                anchors.centerIn: parent
                                captureSource: root.shown ? windowCard.modelData : null
                                live: root.shown
                                paintCursor: false
                                constraintSize: Qt.size(root.previewWidth - Tokens.padding.small * 2, root.previewHeight)
                            }
                        }
                    }
                }
            }
        }
    }
}
