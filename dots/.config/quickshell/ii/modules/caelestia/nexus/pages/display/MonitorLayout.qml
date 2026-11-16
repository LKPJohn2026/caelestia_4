pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import "MonitorGeometry.js" as Geo

// caelestia4: Display > Arrangement: each screen in use as a box, scaled down, with its name and resolution. Drag a box
// to move that screen; on drop it goes right next to another one (sharing part of an edge, so the pointer can cross) and
// lines up with nearby edges. Nothing changes on the screens here: `arranged` hands the new positions to the page,
// which applies them with its Keep / Revert countdown. With one screen the box is only shown.
// caelestia4: a box can also be moved with the keyboard: Tab to it, then the arrow keys.
ConnectedRect {
    id: root

    // Screens as Hyprland lists them (name, width, height, scale, transform, x, y)
    property var monitors: []
    // Positions not applied yet: name -> { x, y }
    property var positions: ({})
    property bool locked
    property string focusedName
    // caelestia4: screens that copy another one (not in `monitors`): [{ name, of }]
    property var mirrors: []

    // New positions for all screens (top-left corner at 0, 0)
    signal arranged(var positions)

    readonly property bool canDrag: monitors.length > 1 && !locked
    readonly property real pad: Tokens.padding.large
    // A drop this close to another screen's edge (on the canvas, in px) lines up with it
    readonly property real snapPx: 12

    readonly property var rects: monitors.map(m => {
        const size = Geo.logicalSize(m);
        const p = positions[m.name] ?? {
            x: m.x,
            y: m.y
        };
        return {
            name: m.name,
            x: p.x,
            y: p.y,
            w: size.w,
            h: size.h
        };
    })
    // Two screens on top of each other (e.g. both at 0, 0 after one was plugged in)
    readonly property bool stacked: rects.some((a, i) => rects.some((b, j) => j > i && Geo.overlaps(a, b)))
    // caelestia4: a screen (or a group) touches none of the others: the pointer can't move onto it
    readonly property bool apart: !Geo.connected(rects)
    // Fit the layout as it stands into the canvas, with room around it to drag a screen to any side
    readonly property var box: {
        const b = Geo.bounds(rects);
        if (rects.length < 2)
            return b;
        const roomX = Math.max(...rects.map(r => r.w)) * 0.5, roomY = Math.max(...rects.map(r => r.h)) * 0.6;
        return {
            x: b.x - roomX,
            y: b.y - roomY,
            w: b.w + roomX * 2,
            h: b.h + roomY * 2
        };
    }
    readonly property real fitFactor: Math.max(0.001, Math.min((canvas.width - pad * 2) / box.w, (canvas.height - pad * 2) / box.h))
    readonly property real fitX: (canvas.width - box.w * fitFactor) / 2 - box.x * fitFactor
    readonly property real fitY: (canvas.height - box.h * fitFactor) / 2 - box.y * fitFactor
    // Held still while a box is dragged, so the canvas doesn't move under the pointer
    property var frozen: null
    readonly property real factor: frozen?.factor ?? fitFactor
    readonly property real offX: frozen?.x ?? fitX
    readonly property real offY: frozen?.y ?? fitY

    // While dragging: the box's name and where it would land
    property string dragName
    property var dragAt: null

    function prettyRes(m): string {
        const size = (m.transform & 1) ? [m.height, m.width] : [m.width, m.height];
        return `${size[0]} × ${size[1]}`;
    }

    function landing(name: string, x: real, y: real): var {
        const self = rects.find(r => r.name === name);
        const others = rects.filter(r => r.name !== name);
        return Geo.place({
            x: Math.round(x),
            y: Math.round(y),
            w: self.w,
            h: self.h
        }, others, snapPx / factor);
    }

    // caelestia4: arrow keys: move the screen one step that way (dx, dy are -1, 0 or 1), to the next place it can go
    function nudge(name: string, dx: int, dy: int): void {
        const self = rects.find(r => r.name === name);
        const others = rects.filter(r => r.name !== name);
        if (!self || !others.length)
            return;
        const b = Geo.bounds(rects);
        const step = Math.max(50, Math.round(Math.max(b.w, b.h) / 20));
        for (let k = 1; k <= 60; k++) {
            const p = Geo.place({
                x: self.x + dx * step * k,
                y: self.y + dy * step * k,
                w: self.w,
                h: self.h
            }, others, step / 2);
            // Only a move in the asked direction counts (place() may put it back where it was)
            if ((dx && Math.sign(p.x - self.x) === dx) || (dy && Math.sign(p.y - self.y) === dy)) {
                dragAt = p;
                drop(name);
                const i = rects.findIndex(r => r.name === name);
                Qt.callLater(() => boxes.itemAt(i)?.forceActiveFocus());
                return;
            }
        }
    }

    function drop(name: string): void {
        const all = {};
        for (const r of rects)
            all[r.name] = r.name === name ? {
                x: dragAt.x,
                y: dragAt.y
            } : {
                x: r.x,
                y: r.y
            };
        dragName = "";
        dragAt = null;
        frozen = null;
        arranged(Geo.normalise(all));
    }

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight + Tokens.padding.medium * 2

    ColumnLayout {
        id: column

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            // caelestia4: Hyprland doesn't list a screen that copies another, so say why there is only one box
            text: root.monitors.length < 2 ? (root.mirrors.length ? Tr.tr("%1 shows the same picture as %2").arg(root.mirrors[0].name).arg(root.mirrors[0].of) : Tr.tr("Connect another screen to arrange them side by side")) : root.stacked ? Tr.tr("Some screens are on top of each other: drag one aside") : root.apart ? Tr.tr("Some screens don't touch the others: the pointer can't move onto them") : Tr.tr("Drag the screens to match where they sit on your desk")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        Item {
            id: canvas

            Layout.fillWidth: true
            // One screen is only a picture: keep it small
            // Several: as tall as the layout's shape wants, within limits
            Layout.preferredHeight: root.monitors.length > 1 ? Math.round(Math.min(320, Math.max(200, (width - root.pad * 2) * root.box.h / root.box.w + root.pad * 2))) : 96
            clip: true

            Repeater {
                id: boxes

                model: root.rects

                StyledRect {
                    id: screenBox

                    required property var modelData
                    readonly property var mon: root.monitors.find(m => m.name === modelData.name) ?? {}
                    readonly property bool dragging: root.dragName === modelData.name
                    readonly property var at: dragging && root.dragAt ? root.dragAt : modelData
                    readonly property bool focusedScreen: root.focusedName === modelData.name

                    x: Math.round(root.offX + at.x * root.factor) + 1
                    y: Math.round(root.offY + at.y * root.factor) + 1
                    width: Math.max(16, Math.round(modelData.w * root.factor) - 2)
                    height: Math.max(16, Math.round(modelData.h * root.factor) - 2)
                    z: dragging ? 2 : 1
                    radius: Tokens.rounding.small
                    color: dragging || area.containsMouse && root.canDrag ? Colours.palette.m3primaryContainer : Colours.palette.m3secondaryContainer
                    // caelestia4: keyboard focus shows as a thicker ring
                    border.width: activeFocus ? 3 : focusedScreen || dragging ? 2 : 1
                    border.color: activeFocus || focusedScreen || dragging ? Colours.palette.m3primary : Colours.palette.m3outline

                    // caelestia4: Tab to a box, arrow keys move it
                    activeFocusOnTab: root.canDrag
                    Keys.onLeftPressed: root.nudge(modelData.name, -1, 0)
                    Keys.onRightPressed: root.nudge(modelData.name, 1, 0)
                    Keys.onUpPressed: root.nudge(modelData.name, 0, -1)
                    Keys.onDownPressed: root.nudge(modelData.name, 0, 1)

                    Accessible.role: root.canDrag ? Accessible.Button : Accessible.Graphic
                    Accessible.name: `${modelData.name}, ${root.prettyRes(mon)}`
                    Accessible.description: root.canDrag ? Tr.tr("Use the arrow keys to move this screen") : ""

                    // caelestia4: the labels stay inside the box; a box too small for one is left without it (the
                    // name is still in the accessible name)
                    TextMetrics {
                        id: nameMetrics

                        font: Tokens.font.body.small
                        text: screenBox.modelData.name
                    }

                    Item {
                        anchors.fill: parent
                        anchors.margins: 2
                        clip: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            width: parent.width - Tokens.padding.small * 2
                            spacing: 0

                            StyledText {
                                id: nameText

                                Layout.fillWidth: true
                                // The whole name or none of it ("…" alone says nothing)
                                visible: screenBox.width - Tokens.padding.small * 2 - 4 >= nameMetrics.advanceWidth && screenBox.height >= implicitHeight + 6
                                horizontalAlignment: Text.AlignHCenter
                                text: screenBox.modelData.name
                                color: screenBox.dragging ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: nameText.visible && screenBox.width >= 56 && screenBox.height >= nameText.implicitHeight + implicitHeight + 10
                                horizontalAlignment: Text.AlignHCenter
                                text: root.prettyRes(screenBox.mon)
                                color: screenBox.dragging ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSecondaryContainer
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }
                    }

                    MouseArea {
                        id: area

                        property real pressX
                        property real pressY

                        // caelestia4: at least 32 px to grab, even when the box is drawn smaller
                        anchors.centerIn: parent
                        width: Math.max(parent.width, 32)
                        height: Math.max(parent.height, 32)
                        enabled: root.canDrag
                        hoverEnabled: true
                        cursorShape: root.canDrag ? (pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor) : Qt.ArrowCursor
                        preventStealing: true

                        onPressed: mouse => {
                            const p = mapToItem(canvas, mouse.x, mouse.y);
                            pressX = p.x;
                            pressY = p.y;
                            root.frozen = {
                                factor: root.fitFactor,
                                x: root.fitX,
                                y: root.fitY
                            };
                            root.dragName = screenBox.modelData.name;
                            root.dragAt = null;
                        }
                        onPositionChanged: mouse => {
                            if (!pressed)
                                return;
                            const p = mapToItem(canvas, mouse.x, mouse.y);
                            const dx = (p.x - pressX) / root.factor, dy = (p.y - pressY) / root.factor;
                            // A click that barely moves is not a drag
                            if (!root.dragAt && Math.hypot(p.x - pressX, p.y - pressY) < 4)
                                return;
                            root.dragAt = root.landing(screenBox.modelData.name, screenBox.modelData.x + dx, screenBox.modelData.y + dy);
                        }
                        onReleased: {
                            if (root.dragAt)
                                root.drop(screenBox.modelData.name);
                            else
                                cancel();
                        }
                        onCanceled: cancel()

                        function cancel(): void {
                            root.dragName = "";
                            root.dragAt = null;
                            root.frozen = null;
                        }
                    }
                }
            }
        }
    }
}
