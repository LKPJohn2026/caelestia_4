pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Caelestia.Config
import qs.services as E4 // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters

// caelestia4: one window inside an overview workspace tile: live preview + app icon, Caelestia colours.
// Left click = focus the window, middle click = close it, drag = move it to another workspace (Overview handles
// the drop through dragStarted/dragMoved/dropped, a ghost copy follows the pointer above the grid).
Item {
    id: root

    required property var winData // end-4 HyprlandData window entry
    required property var toplevel // Quickshell Toplevel (for the live preview), may be null
    required property real ratio // tile pixels per logical screen pixel
    required property var monData // end-4 HyprlandData monitor entry of the window's monitor
    required property real tileWidth
    required property real tileHeight
    property bool live: true
    property bool dragging: false

    readonly property string iconPath: Quickshell.iconPath(E4.AppSearch.guessIcon(winData?.class ?? ""), "image-missing")
    readonly property real monX: monData?.x ?? 0
    readonly property real monY: monData?.y ?? 0

    signal activated
    signal closeRequested
    signal dragStarted(var item, real px, real py)
    signal dragMoved(real px, real py)
    signal dropped(real px, real py)

    width: Math.max(8, Math.min(tileWidth, (winData?.size[0] ?? 0) * ratio))
    height: Math.max(8, Math.min(tileHeight, (winData?.size[1] ?? 0) * ratio))
    x: Math.max(0, Math.min(tileWidth - width, ((winData?.at[0] ?? 0) - monX) * ratio))
    y: Math.max(0, Math.min(tileHeight - height, ((winData?.at[1] ?? 0) - monY) * ratio))
    z: (winData?.fullscreen ? 2 : 0) + (winData?.floating ? 1 : 0)
    opacity: dragging ? 0.3 : 1

    Behavior on x {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
    Behavior on y {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
    Behavior on width {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
    Behavior on height {
        Anim {
            type: Anim.DefaultSpatial
        }
    }
    Behavior on opacity {
        Anim {
            type: Anim.FastEffects
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: Tokens.rounding.small
        color: Colours.palette.m3surfaceContainerHigh

        ScreencopyView {
            anchors.fill: parent
            captureSource: root.live ? root.toplevel : null
            live: true
        }

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.small
            color: area.pressed ? Qt.alpha(Colours.palette.m3onSurface, 0.16) : area.containsMouse ? Qt.alpha(Colours.palette.m3onSurface, 0.08) : "transparent"
            border.width: area.containsMouse ? 2 : 1
            border.color: area.containsMouse ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3outline, 0.4)

            Behavior on color {
                CAnim {}
            }
        }

        IconImage {
            readonly property real size: Math.min(root.width, root.height) * (Math.min(root.width, root.height) < 60 ? 0.6 : 0.32)

            anchors.centerIn: parent
            implicitSize: Math.min(size, 96)
            source: root.iconPath
            mipmap: true
        }
    }

    MouseArea {
        id: area

        property point pressPos
        property bool moved
        property bool suppressClick

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor

        onPressed: event => {
            pressPos = Qt.point(event.x, event.y);
            moved = false;
            suppressClick = false;
        }
        onPositionChanged: event => {
            if (!pressed || !(event.buttons & Qt.LeftButton))
                return;
            if (!moved && Math.hypot(event.x - pressPos.x, event.y - pressPos.y) > 6) {
                moved = true;
                root.dragging = true;
                root.dragStarted(root, pressPos.x, pressPos.y);
            }
            if (moved)
                root.dragMoved(event.x, event.y);
        }
        onReleased: event => {
            if (moved) {
                root.dragging = false;
                moved = false;
                suppressClick = true;
                root.dropped(event.x, event.y);
            }
        }
        onClicked: event => {
            if (suppressClick)
                return;
            if (event.button === Qt.MiddleButton)
                root.closeRequested();
            else
                root.activated();
        }
    }
}
