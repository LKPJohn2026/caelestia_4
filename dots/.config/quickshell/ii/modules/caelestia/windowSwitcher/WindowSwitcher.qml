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
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: window switcher on Super+Tab, in Caelestia style (end-4 PR #3693's Alt+Tab switcher; Alt+Tab stays the
// workspace switcher here, overview/Overview.qml).
// Hold Super and press Tab to move forward (Shift+Tab back, arrows, Enter; Esc or a click outside cancels; hover or
// click with the mouse); releasing Super switches to the selected window.
//  - Every workspace's windows in a fixed order: by workspace, then left to right and top to bottom, so the cards
//    don't reshuffle with every switch. Special workspaces go last.
//  - Opens on the previously used window, so a quick Super+Tab flips between the last two.
//  - Live previews (the app icon until one arrives); windows on another workspace carry its name.
// The Super release comes from a transparent Hyprland bind on SUPER_L / SUPER_R (keybinds.lua), with a Qt
// key-release on the focused layer as the fallback. Each step also cancels the Super-tap launcher.
Scope {
    id: root

    property bool open: false
    property var cards: [] // [{ address, title, wsName, otherWs, toplevel, icon }]
    property int sel: 0
    property bool mouseArmed: false // don't select the card under the cursor just because the switcher opened there

    readonly property int cardWidth: 320

    function build(reverse: bool): void {
        const wsKey = id => id < 0 ? 100000 - id : id;
        const list = E4.HyprlandData.windowList.filter(w => w.mapped && !w.hidden && w.workspace && w.workspace.id !== -1).sort((a, b) => wsKey(a.workspace.id) - wsKey(b.workspace.id) || a.at[0] - b.at[0] || a.at[1] - b.at[1]);
        const current = list.findIndex(w => w.focusHistoryID === 0);
        const previous = list.findIndex(w => w.focusHistoryID === 1);
        const activeWs = Hyprland.focusedMonitor?.activeWorkspace?.id;
        cards = list.map(w => ({
                    address: w.address,
                    title: w.title || w.class,
                    wsName: w.workspace.name.replace(/^special:/, ""),
                    otherWs: w.workspace.id !== activeWs,
                    toplevel: Hyprland.toplevels.values.find(t => `0x${t.address}` === w.address)?.wayland ?? null,
                    icon: Quickshell.iconPath(E4.AppSearch.guessIcon(w.class), "image-missing")
                }));
        // Tab starts on the previously used window; Shift+Tab on the card before the focused one
        const n = cards.length;
        const from = Math.max(0, current);
        if (n <= 1)
            sel = 0;
        else if (!reverse && previous >= 0)
            sel = previous;
        else
            sel = ((from + (reverse ? -1 : 1)) % n + n) % n;
    }

    function step(d: int): void {
        GlobalStates.superReleaseMightTrigger = false; // Super was held for a combo, not tapped: no launcher
        if (!open) {
            mouseArmed = false;
            build(d < 0);
            if (cards.length > 0)
                open = true;
            return;
        }
        const n = cards.length;
        if (n > 0)
            sel = ((sel + d) % n + n) % n;
    }

    function stepRow(dy: int, perRow: int): void {
        const t = sel + dy * perRow;
        if (t >= 0 && t < cards.length)
            sel = t;
    }

    function commit(): void {
        if (!open)
            return;
        const card = cards[sel];
        close();
        if (!card)
            return;
        // Focus once the layer is gone: when it unmaps, Hyprland gives keyboard focus back to the window that had it,
        // and if that lands after this focus the focus history (and the next Super+Tab) gets mixed up
        focusLater.address = card.address;
        focusLater.restart();
    }

    function close(): void {
        open = false;
        cards = [];
    }

    Timer {
        id: focusLater

        property string address

        interval: 60
        onTriggered: Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`)
    }

    Loader {
        active: root.open

        sourceComponent: StyledWindow {
            id: win

            readonly property int thumbWidth: root.cardWidth - Tokens.padding.medium * 2
            readonly property int thumbHeight: Math.round(thumbWidth * 9 / 16)
            readonly property int perRow: Math.max(1, Math.min(root.cards.length, Math.floor((width * 0.9 - Tokens.padding.extraLarge * 2 + Tokens.spacing.medium) / (root.cardWidth + Tokens.spacing.medium))))

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "windowSwitcher"
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusiveZone: 0
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // A click outside cancels
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            StyledRect {
                id: panel

                anchors.centerIn: parent
                implicitWidth: content.implicitWidth + Tokens.padding.extraLarge * 2
                implicitHeight: content.implicitHeight + Tokens.padding.extraLarge * 2
                radius: Tokens.rounding.extraLarge
                color: Colours.tPalette.m3surface
                focus: true

                Component.onCompleted: forceActiveFocus()

                Keys.onPressed: event => {
                    switch (event.key) {
                    case Qt.Key_Right:
                    case Qt.Key_Tab:
                        root.step(1);
                        break;
                    case Qt.Key_Left:
                    case Qt.Key_Backtab:
                        root.step(-1);
                        break;
                    case Qt.Key_Down:
                        root.stepRow(1, win.perRow);
                        break;
                    case Qt.Key_Up:
                        root.stepRow(-1, win.perRow);
                        break;
                    case Qt.Key_Return:
                    case Qt.Key_Enter:
                        root.commit();
                        break;
                    case Qt.Key_Escape:
                        root.close();
                        break;
                    default:
                        return;
                    }
                    event.accepted = true;
                }
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Meta) {
                        root.commit(); // fallback for the Hyprland release bind
                        event.accepted = true;
                    }
                }

                // Clicks inside the panel don't cancel
                MouseArea {
                    anchors.fill: parent
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

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: Tokens.padding.small
                        Layout.rightMargin: Tokens.padding.small
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            text: "select_window"
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            text: Tr.tr("Windows")
                            font: Tokens.font.title.medium
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        StyledText {
                            text: Tr.tr("Tab  next   •   Shift+Tab  previous   •   release Super  switch   •   Esc  cancel")
                            color: Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.small
                        }
                    }

                    Grid {
                        columns: win.perRow
                        spacing: Tokens.spacing.medium

                        Repeater {
                            model: root.cards

                            delegate: StyledRect {
                                id: card

                                required property var modelData
                                required property int index
                                readonly property bool selected: index === root.sel

                                implicitWidth: root.cardWidth
                                implicitHeight: cardContent.implicitHeight + Tokens.padding.medium * 2
                                radius: Tokens.rounding.large
                                color: selected ? Colours.palette.m3primaryContainer : Colours.tPalette.m3surfaceContainer
                                border.width: selected ? 2 : 0
                                border.color: Colours.palette.m3primary

                                ColumnLayout {
                                    id: cardContent

                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.medium
                                    spacing: Tokens.spacing.small

                                    ClipRect {
                                        Layout.preferredWidth: win.thumbWidth
                                        Layout.preferredHeight: win.thumbHeight
                                        radius: Tokens.rounding.medium
                                        color: Colours.tPalette.m3surfaceContainerHigh

                                        ScreencopyView {
                                            id: preview

                                            // Stop capturing when the window closes while the switcher is open:
                                            // capturing a dead toplevel crashes Quickshell
                                            readonly property bool alive: card.modelData.toplevel !== null && ToplevelManager.toplevels.values.indexOf(card.modelData.toplevel) >= 0
                                            readonly property real k: sourceSize.width > 0 && sourceSize.height > 0 ? Math.min(win.thumbWidth / sourceSize.width, win.thumbHeight / sourceSize.height) : 1

                                            anchors.centerIn: parent
                                            width: sourceSize.width > 0 ? sourceSize.width * k : win.thumbWidth
                                            height: sourceSize.height > 0 ? sourceSize.height * k : win.thumbHeight
                                            captureSource: root.open && alive ? card.modelData.toplevel : null
                                            live: true
                                            visible: alive && hasContent
                                        }

                                        IconImage {
                                            anchors.centerIn: parent
                                            visible: !preview.visible
                                            source: card.modelData.icon
                                            implicitSize: Math.round(win.thumbHeight * 0.4)
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: Tokens.spacing.small

                                        IconImage {
                                            source: card.modelData.icon
                                            implicitSize: Math.round(Tokens.font.icon.medium.pointSize * 1.6)
                                        }

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: card.modelData.title
                                            color: card.selected ? Colours.palette.m3onPrimaryContainer : Colours.palette.m3onSurface
                                            elide: Text.ElideRight
                                            font: Tokens.font.label.medium
                                        }

                                        // The workspace of a window on another one
                                        StyledRect {
                                            visible: card.modelData.otherWs
                                            implicitWidth: wsText.implicitWidth + Tokens.padding.medium * 2
                                            implicitHeight: wsText.implicitHeight + Tokens.padding.extraSmall * 2
                                            radius: Tokens.rounding.full
                                            color: Colours.palette.m3secondaryContainer

                                            StyledText {
                                                id: wsText

                                                anchors.centerIn: parent
                                                text: card.modelData.wsName
                                                color: Colours.palette.m3onSecondaryContainer
                                                font: Tokens.font.label.small
                                            }
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onPositionChanged: {
                                        if (root.mouseArmed)
                                            root.sel = card.index;
                                        else
                                            root.mouseArmed = true;
                                    }
                                    onClicked: {
                                        root.sel = card.index;
                                        root.commit();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "windowSwitcher"

        function next(): void {
            root.step(1);
        }

        function prev(): void {
            root.step(-1);
        }

        function commit(): void {
            root.commit();
        }

        function cancel(): void {
            root.close();
        }
    }

    GlobalShortcut {
        name: "windowSwitcherNext"
        description: "Super+Tab: open the window switcher / next window"
        onPressed: root.step(1)
    }

    GlobalShortcut {
        name: "windowSwitcherPrev"
        description: "Super+Shift+Tab: open the window switcher / previous window"
        onPressed: root.step(-1)
    }

    GlobalShortcut {
        // A transparent bind on Super itself: its release is caught even if Super goes up before the layer has
        // keyboard focus, and apps still get Super
        name: "windowSwitcherSuper"
        description: "Super released: switch to the selected window (only while the switcher is open)"
        onReleased: root.commit()
    }
}
