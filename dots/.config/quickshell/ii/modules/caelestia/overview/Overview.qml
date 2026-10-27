pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs // caelestia4: keep
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: workspace overview in Caelestia style (replaces the end-4 overview grid in the caelestia family).
// Same data and layout options as end-4's overview (overview.rows/columns/scale/orderRightLeft/orderBottomUp),
// live window previews, click a workspace/window to go there, drag a window onto another workspace to move it,
// middle-click a window to close it.
//
// Two ways in:
//  - Super+Tab (overviewWorkspacesToggle): opens/closes it. Arrows move the selection, Tab/Shift+Tab cycle,
//    Enter switches, Esc closes.
//  - Alt+Tab, Windows-style (overviewAltTabNext / overviewAltTabPrev / overviewAltTabCommit): the first Alt+Tab
//    opens it with the next workspace selected; each further Tab (Alt still held) moves to the next workspace in
//    order (Shift+Tab: previous); releasing Alt switches to the selected one. Esc while holding Alt cancels.
//    caelestia.overview.altTabSkipEmpty (default on) cycles only through workspaces that have windows (plus the
//    current one). A quick Alt+Tab tap switches without showing the overview (it appears after a short delay).
//    The Alt release comes from a Hyprland release bind on ALT_L/ALT_R (keybinds.lua); a Qt key-release on the
//    focused overview is the fallback.
Scope {
    id: root

    readonly property bool open: GlobalStates.overviewOpen
    property bool altTabbing: false
    property bool revealed: false
    property int selectedWs: 1

    readonly property var opts: E4C.Config.options.overview
    readonly property int rows: Math.max(1, opts.rows)
    readonly property int columns: Math.max(1, opts.columns)
    readonly property int shownCount: rows * columns
    // Clamp: the lock screen's temporary workspace (2147483647 - N) must not leak into the grid
    readonly property int activeWs: Math.max(1, Math.min(1000, Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1))
    readonly property int groupBase: Math.floor((activeWs - 1) / shownCount) * shownCount

    function wsForIndex(i: int): int {
        const row = Math.floor(i / columns);
        const col = i % columns;
        const r = opts.orderBottomUp ? rows - 1 - row : row;
        const c = opts.orderRightLeft ? columns - 1 - col : col;
        return groupBase + r * columns + c + 1;
    }

    function indexForWs(ws: int): int {
        for (let i = 0; i < shownCount; i++)
            if (wsForIndex(i) === ws)
                return i;
        return -1;
    }

    function windowCount(ws: int): int {
        return E4.HyprlandData.windowList.filter(w => w.workspace?.id === ws).length;
    }

    // Workspaces Tab cycles through, in workspace order
    function cycleList(): list<int> {
        const skip = E4C.Config.options.caelestia.overview.altTabSkipEmpty;
        const list = [];
        for (let ws = groupBase + 1; ws <= groupBase + shownCount; ws++)
            if (!skip || ws === activeWs || windowCount(ws) > 0)
                list.push(ws);
        return list;
    }

    function step(dir: int): void {
        const list = cycleList();
        if (list.length === 0)
            return;
        let idx = list.indexOf(selectedWs);
        if (idx < 0) {
            // selection isn't in the list (e.g. an empty workspace picked with the arrows): continue from its position
            // dir > 0: pretend we're on the last listed workspace below it; dir < 0: on the first one above it
            const above = list.findIndex(ws => ws > selectedWs);
            idx = dir > 0 ? (above < 0 ? list.length - 1 : above - 1) : (above < 0 ? list.length : above);
        }
        selectedWs = list[(idx + dir + list.length) % list.length];
    }

    function moveSelection(dRow: int, dCol: int): void {
        const i = Math.max(0, indexForWs(selectedWs));
        const row = Math.max(0, Math.min(rows - 1, Math.floor(i / columns) + dRow));
        const col = Math.max(0, Math.min(columns - 1, i % columns + dCol));
        selectedWs = wsForIndex(row * columns + col);
    }

    function show(altTab: bool): void {
        selectedWs = activeWs;
        altTabbing = altTab;
        revealed = !altTab;
        if (altTab)
            revealTimer.restart();
        GlobalStates.overviewOpen = true;
    }

    function close(): void {
        GlobalStates.overviewOpen = false;
    }

    function goTo(ws: int): void {
        close();
        if (ws !== activeWs)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${ws} })`);
    }

    function altTab(dir: int): void {
        if (!open || !altTabbing)
            show(true);
        step(dir);
    }

    function commitAltTab(): void {
        if (open && altTabbing)
            goTo(selectedWs);
    }

    onOpenChanged: {
        if (!open) {
            altTabbing = false;
            revealed = false;
            revealTimer.stop();
        }
    }

    Timer {
        id: revealTimer

        interval: 120
        onTriggered: root.revealed = true
    }

    Loader {
        active: root.open && (root.opts.enable ?? true)

        sourceComponent: StyledWindow {
            id: win

            readonly property var monData: E4.HyprlandData.monitors.find(m => m.name === screen.name) ?? null
            readonly property bool rotated: (monData?.transform ?? 0) % 2 === 1
            readonly property real logicalW: monData ? (rotated ? monData.height : monData.width) / monData.scale : screen.width
            readonly property real logicalH: monData ? (rotated ? monData.width : monData.height) / monData.scale : screen.height
            readonly property real tileW: Math.round(logicalW * root.opts.scale)
            readonly property real tileH: Math.round(logicalH * root.opts.scale)

            property Item dragItem: null
            property point dragOffset
            property int dropWs: -1

            function wsAt(p: point): int {
                for (let i = 0; i < tiles.count; i++) {
                    const t = tiles.itemAt(i);
                    const q = t.mapFromItem(panel, p.x, p.y);
                    if (q.x >= 0 && q.y >= 0 && q.x < t.width && q.y < t.height)
                        return t.ws;
                }
                return -1;
            }

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "overview"
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay // above fullscreen games too
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            mask: Region {
                item: panel
            }

            Component.onCompleted: E4.GlobalFocusGrab.addDismissable(win)
            Component.onDestruction: E4.GlobalFocusGrab.removeDismissable(win)

            Connections {
                target: E4.GlobalFocusGrab

                function onDismissed(): void {
                    root.close();
                }
            }

            StyledRect {
                id: panel

                anchors.centerIn: parent
                implicitWidth: content.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: content.implicitHeight + Tokens.padding.extraLarge * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surface
                focus: true

                scale: root.revealed ? 1 : 0.96
                opacity: root.revealed ? 1 : 0
                Component.onCompleted: forceActiveFocus()

                Behavior on scale {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape)
                        root.close();
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
                        root.goTo(root.selectedWs);
                    else if (k === Qt.Key_Tab)
                        root.step(1);
                    else if (k === Qt.Key_Backtab)
                        root.step(-1);
                    else if (k === Qt.Key_Left || k === Qt.Key_H)
                        root.moveSelection(0, -1);
                    else if (k === Qt.Key_Right || k === Qt.Key_L)
                        root.moveSelection(0, 1);
                    else if (k === Qt.Key_Up || k === Qt.Key_K)
                        root.moveSelection(-1, 0);
                    else if (k === Qt.Key_Down || k === Qt.Key_J)
                        root.moveSelection(1, 0);
                    else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_0 <= root.shownCount)
                        root.goTo(root.groupBase + k - Qt.Key_0);
                    else
                        return;
                    event.accepted = true;
                }
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr)
                        root.commitAltTab(); // fallback for the Hyprland release bind
                }

                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 3
                }

                ColumnLayout {
                    id: content

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.large

                    // Header: title, selected workspace, hints
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        Layout.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "grid_view"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            text: Tr.tr("Workspaces")
                            font: Tokens.font.title.medium
                        }

                        StyledRect {
                            implicitWidth: selLabel.implicitWidth + Tokens.padding.large * 2
                            implicitHeight: selLabel.implicitHeight + Tokens.padding.small * 2
                            radius: Tokens.rounding.full
                            color: Colours.palette.m3secondaryContainer

                            StyledText {
                                id: selLabel

                                readonly property int count: root.windowCount(root.selectedWs)

                                anchors.centerIn: parent
                                text: (root.selectedWs === root.activeWs ? Tr.tr("Workspace %1 (current)") : Tr.tr("Workspace %1")).arg(root.selectedWs) + "  •  " + (count === 1 ? Tr.tr("1 window") : Tr.tr("%1 windows").arg(count))
                                color: Colours.palette.m3onSecondaryContainer
                                font: Tokens.font.label.medium
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: root.altTabbing ? Tr.tr("Tab  next   •   Shift+Tab  previous   •   release Alt  switch   •   Esc  cancel") : Tr.tr("Click  go   •   Drag window  move   •   Middle-click  close   •   Arrows / Tab  select   •   Enter  switch")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }

                    GridLayout {
                        columns: root.columns
                        rowSpacing: Tokens.spacing.medium
                        columnSpacing: Tokens.spacing.medium

                        Repeater {
                            id: tiles

                            model: root.shownCount

                            ClipRect {
                                id: tile

                                required property int index
                                readonly property int ws: root.wsForIndex(index)
                                readonly property var wins: E4.HyprlandData.windowList.filter(w => w.workspace?.id === ws)
                                readonly property bool selected: root.selectedWs === ws
                                readonly property bool current: root.activeWs === ws
                                readonly property bool dropTarget: win.dropWs === ws && win.dragItem !== null && win.dragItem.winData?.workspace?.id !== ws

                                implicitWidth: win.tileW
                                implicitHeight: win.tileH
                                radius: Tokens.rounding.large
                                color: Colours.palette.m3surfaceContainer
                                scale: selected && root.altTabbing ? 1.02 : 1
                                z: selected ? 1 : 0

                                Behavior on scale {
                                    Anim {
                                        type: Anim.FastSpatial
                                    }
                                }

                                // Wallpaper, dimmed (less on the selected workspace)
                                Image {
                                    anchors.fill: parent
                                    source: Wallpapers.forWorkspace(String(parent.ws)) // caelestia4: upstream #2210
                                    sourceSize.width: win.tileW
                                    sourceSize.height: win.tileH
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    opacity: tile.selected ? 0.75 : 0.4

                                    Behavior on opacity {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }

                                StyledText {
                                    anchors.centerIn: parent
                                    visible: tile.wins.length === 0
                                    text: tile.ws
                                    color: Qt.alpha(Colours.palette.m3onSurface, 0.3)
                                    font.pixelSize: win.tileH * 0.4
                                    font.weight: Font.DemiBold
                                }

                                StateLayer {
                                    radius: tile.radius
                                    onClicked: root.goTo(tile.ws)
                                }

                                Item {
                                    anchors.fill: parent

                                    Repeater {
                                        model: ScriptModel {
                                            values: tile.wins
                                            objectProp: "address"
                                        }

                                        OverviewWindow {
                                            id: winItem

                                            required property var modelData

                                            winData: modelData
                                            toplevel: Hyprland.toplevels.values.find(t => `0x${t.address}` === modelData.address)?.wayland ?? null
                                            monData: E4.HyprlandData.monitors.find(m => m.id === modelData.monitor) ?? win.monData
                                            ratio: win.tileW / (monData ? ((monData.transform % 2 ? monData.height : monData.width) / monData.scale) : win.logicalW)
                                            tileWidth: tile.width
                                            tileHeight: tile.height
                                            live: root.revealed

                                            onActivated: {
                                                root.close();
                                                Hyprland.dispatch(`hl.dsp.focus({ window = "address:${modelData.address}" })`);
                                            }
                                            onCloseRequested: Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${modelData.address}" })`)
                                            onDragStarted: (item, px, py) => {
                                                win.dragItem = item;
                                                win.dragOffset = Qt.point(px, py);
                                                winItem.dragMoved(px, py);
                                            }
                                            onDragMoved: (px, py) => {
                                                const p = winItem.mapToItem(panel, px, py);
                                                ghost.x = p.x - win.dragOffset.x;
                                                ghost.y = p.y - win.dragOffset.y;
                                                win.dropWs = win.wsAt(p);
                                            }
                                            onDropped: (px, py) => {
                                                const target = win.wsAt(winItem.mapToItem(panel, px, py));
                                                if (target > 0 && target !== modelData.workspace?.id)
                                                    Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${target}, follow = false, window = "address:${modelData.address}" })`);
                                                win.dragItem = null;
                                                win.dropWs = -1;
                                            }
                                        }
                                    }
                                }

                                // Workspace number chip
                                StyledRect {
                                    anchors.left: parent.left
                                    anchors.bottom: parent.bottom
                                    anchors.margins: Tokens.padding.medium
                                    z: 5
                                    visible: tile.wins.length > 0 || tile.selected
                                    implicitWidth: chipRow.implicitWidth + Tokens.padding.medium * 2
                                    implicitHeight: chipRow.implicitHeight + Tokens.padding.extraSmall * 2
                                    radius: Tokens.rounding.full
                                    color: tile.selected ? Colours.palette.m3primary : Qt.alpha(Colours.palette.m3surfaceContainerHighest, 0.9)

                                    RowLayout {
                                        id: chipRow

                                        anchors.centerIn: parent
                                        spacing: Tokens.spacing.extraSmall

                                        MaterialIcon {
                                            visible: tile.current
                                            text: "radio_button_checked"
                                            color: tile.selected ? Colours.palette.m3onPrimary : Colours.palette.m3primary
                                            fontStyle: Tokens.font.icon.small
                                        }

                                        StyledText {
                                            text: tile.ws
                                            color: tile.selected ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
                                            font: Tokens.font.label.medium
                                        }
                                    }
                                }

                                // Selection / current / drop outline
                                Rectangle {
                                    anchors.fill: parent
                                    z: 6
                                    radius: tile.radius
                                    color: tile.dropTarget ? Qt.alpha(Colours.palette.m3tertiary, 0.15) : "transparent"
                                    border.width: tile.selected || tile.dropTarget ? 3 : tile.current ? 2 : 0
                                    border.color: tile.dropTarget ? Colours.palette.m3tertiary : tile.selected ? Colours.palette.m3primary : Colours.palette.m3outline

                                    Behavior on border.width {
                                        Anim {
                                            type: Anim.FastEffects
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Copy of the dragged window following the pointer (windows themselves stay clipped in their tile)
                ClippingRectangle {
                    id: ghost

                    visible: win.dragItem !== null
                    z: 100
                    width: win.dragItem?.width ?? 0
                    height: win.dragItem?.height ?? 0
                    radius: Tokens.rounding.small
                    color: Colours.palette.m3surfaceContainerHigh
                    border.width: 2
                    border.color: Colours.palette.m3primary

                    ScreencopyView {
                        anchors.fill: parent
                        captureSource: win.dragItem?.toplevel ?? null
                        live: true
                    }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: Math.min(parent.width, parent.height) * 0.4
                        source: win.dragItem?.iconPath ?? ""
                        mipmap: true
                    }
                }
            }
        }
    }

    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"
        onPressed: root.open ? root.close() : root.show(false)
    }

    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"
        onPressed: root.close()
    }

    GlobalShortcut {
        name: "overviewAltTabNext"
        description: "Alt+Tab: open the overview / select the next workspace"
        onPressed: root.altTab(1)
    }

    GlobalShortcut {
        name: "overviewAltTabPrev"
        description: "Alt+Shift+Tab: open the overview / select the previous workspace"
        onPressed: root.altTab(-1)
    }

    GlobalShortcut {
        name: "overviewAltPressed"
        description: "No-op: Hyprland needs a press bind on Alt for the Alt release bind to fire"
    }

    GlobalShortcut {
        name: "overviewAltTabCommit"
        description: "Alt released: switch to the selected workspace (only while Alt+Tabbing)"
        onPressed: root.commitAltTab()
    }

    IpcHandler {
        target: "search" // same IPC target name end-4 uses, so existing scripts/keybinds keep working

        function toggle(): void {
            root.open ? root.close() : root.show(false);
        }

        function workspacesToggle(): void {
            toggle();
        }

        function close(): void {
            root.close();
        }

        function open(): void {
            root.show(false);
        }

        function altTabNext(): void {
            root.altTab(1);
        }

        function altTabPrev(): void {
            root.altTab(-1);
        }

        function altTabCommit(): void {
            root.commitAltTab();
        }
    }
}
