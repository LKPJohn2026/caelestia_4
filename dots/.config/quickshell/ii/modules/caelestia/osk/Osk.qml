pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs // caelestia4: keep
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters
import "../../ii/onScreenKeyboard/layouts.js" as Layouts

// caelestia4: end-4's on-screen keyboard (modules/ii/onScreenKeyboard) restyled for the Caelestia family.
// Same behaviour: keys go through ydotool (E4.Ydotool; needs ydotoold), layouts from end-4's layouts.js
// (osk.layout), Shift once = next key, Shift twice quickly = caps lock, Ctrl/Alt/… are sticky.
// Same IPC target ("osk") and global shortcuts (oskToggle/oskOpen/oskClose) as end-4's module, which this replaces.
Scope {
    id: root

    property bool pinned: E4C.Config.options?.osk.pinnedOnStartup ?? false

    readonly property var layout: {
        const name = E4C.Config.options?.osk.layout;
        return Layouts.byName[Layouts.byName.hasOwnProperty(name) ? name : Layouts.defaultLayout];
    }

    Loader {
        active: GlobalStates.oskOpen
        onActiveChanged: {
            if (!active)
                E4.Ydotool.releaseAllKeys();
        }

        sourceComponent: StyledWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "osk"
            visible: !GlobalStates.screenLocked
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            WlrLayershell.layer: WlrLayer.Overlay
            exclusiveZone: root.pinned ? implicitHeight : 0
            implicitHeight: panel.implicitHeight + panel.gap * 2
            mask: Region {
                item: panel
            }

            // Usable together with other panels (end-4 focus grab)
            Component.onCompleted: E4.GlobalFocusGrab.addPersistent(win)
            Component.onDestruction: E4.GlobalFocusGrab.removePersistent(win)

            StyledRect {
                id: panel

                readonly property real gap: Tokens.spacing.medium

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: gap
                implicitWidth: row.implicitWidth + Tokens.padding.large * 2
                implicitHeight: row.implicitHeight + Tokens.padding.large * 2
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer

                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 3
                }

                RowLayout {
                    id: row

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.medium

                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        spacing: Tokens.spacing.small

                        IconButton {
                            type: IconButton.Tonal
                            icon: "keep"
                            isToggle: true
                            checked: root.pinned
                            onClicked: root.pinned = !root.pinned
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                            ToolTip.text: root.pinned ? Tr.tr("Unpin (stop reserving space)") : Tr.tr("Pin (windows make room)")
                        }

                        IconButton {
                            type: IconButton.Tonal
                            icon: "keyboard_hide"
                            onClicked: GlobalStates.oskOpen = false
                            ToolTip.visible: hovered
                            ToolTip.delay: 500
                            ToolTip.text: Tr.tr("Hide keyboard")
                        }
                    }

                    StyledRect {
                        Layout.fillHeight: true
                        Layout.topMargin: Tokens.padding.large
                        Layout.bottomMargin: Tokens.padding.large
                        implicitWidth: 1
                        color: Colours.palette.m3outlineVariant
                    }

                    ColumnLayout {
                        spacing: Tokens.spacing.small

                        Repeater {
                            model: root.layout.keys

                            RowLayout {
                                id: keyRow

                                required property var modelData

                                spacing: Tokens.spacing.small

                                Repeater {
                                    model: keyRow.modelData

                                    OskKey {}
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osk"

        function toggle(): void {
            GlobalStates.oskOpen = !GlobalStates.oskOpen;
        }

        function close(): void {
            GlobalStates.oskOpen = false;
        }

        function open(): void {
            GlobalStates.oskOpen = true;
        }
    }

    GlobalShortcut {
        name: "oskToggle"
        description: "Toggles on screen keyboard on press"
        onPressed: GlobalStates.oskOpen = !GlobalStates.oskOpen
    }

    GlobalShortcut {
        name: "oskOpen"
        description: "Opens on screen keyboard on press"
        onPressed: GlobalStates.oskOpen = true
    }

    GlobalShortcut {
        name: "oskClose"
        description: "Closes on screen keyboard on press"
        onPressed: GlobalStates.oskOpen = false
    }

    // One key. Logic is end-4's OskKey (press on down, release/shift/caps/modkey handling on up).
    component OskKey: StyledRect {
        id: key

        required property var modelData // { label, labelShift?, labelCaps?, shape, keycode, keytype }
        readonly property string label: modelData.label
        readonly property string shape: modelData.shape
        readonly property var keycode: modelData.keycode
        readonly property bool isShift: E4.Ydotool.shiftKeys.includes(keycode)
        readonly property bool isBackspace: label.toLowerCase() === "backspace"
        readonly property bool isEnter: label.toLowerCase() === "enter" || label.toLowerCase() === "return"
        readonly property bool isEmpty: shape === "empty"
        property bool toggled: isShift ? E4.Ydotool.shiftMode > 0 : false
        readonly property real unit: 46
        readonly property var widthMultiplier: ({
                normal: 1,
                fn: 1,
                tab: 1.6,
                caps: 1.9,
                shift: 2.5,
                control: 1.3
            })

        implicitWidth: unit * (widthMultiplier[shape] ?? 1)
        implicitHeight: shape === "fn" ? unit * 0.7 : unit
        Layout.fillWidth: shape === "space" || shape === "expand"
        radius: mouse.pressed ? Tokens.rounding.small : Tokens.rounding.medium
        color: {
            if (isEmpty)
                return "transparent";
            if (toggled)
                return Colours.palette.m3primary;
            if (mouse.pressed)
                return Colours.palette.m3secondaryContainer;
            if (shape !== "normal" && shape !== "fn")
                return Colours.layer(Colours.palette.m3surfaceContainerHighest, 2);
            return Colours.layer(Colours.palette.m3surfaceContainerHigh, 2);
        }

        Behavior on radius {
            Anim {
                type: Anim.FastSpatial
            }
        }

        Connections {
            target: E4.Ydotool
            enabled: key.isShift

            function onShiftModeChanged(): void {
                if (E4.Ydotool.shiftMode === 0)
                    capsTimer.hasStarted = false;
            }
        }

        Timer {
            id: capsTimer

            property bool hasStarted: false
            property bool canCaps: false

            function startWaiting(): void {
                hasStarted = true;
                canCaps = true;
                start();
            }

            interval: 300
            onTriggered: canCaps = false
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            enabled: !key.isEmpty
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onPressed: {
                E4.Ydotool.press(key.keycode);
                if (key.isShift && E4.Ydotool.shiftMode === 0)
                    E4.Ydotool.shiftMode = 1;
            }
            onReleased: {
                if (key.modelData.keytype === "normal") {
                    E4.Ydotool.release(key.keycode);
                    if (E4.Ydotool.shiftMode === 1)
                        E4.Ydotool.releaseShiftKeys();
                } else if (key.isShift) {
                    if (E4.Ydotool.shiftMode === 1) {
                        if (!capsTimer.hasStarted)
                            capsTimer.startWaiting();
                        else if (capsTimer.canCaps)
                            E4.Ydotool.shiftMode = 2; // caps lock
                        else
                            E4.Ydotool.releaseShiftKeys();
                    } else if (E4.Ydotool.shiftMode === 2) {
                        E4.Ydotool.releaseShiftKeys();
                    }
                } else if (key.modelData.keytype === "modkey") {
                    key.toggled = !key.toggled;
                    if (!key.toggled)
                        E4.Ydotool.release(key.keycode);
                }
            }
        }

        StyledRect {
            anchors.fill: parent
            radius: parent.radius
            color: Colours.palette.m3onSurface
            opacity: mouse.containsMouse && !mouse.pressed && !key.isEmpty ? 0.08 : 0
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: key.isBackspace || key.isEnter
            text: key.isBackspace ? "backspace" : "keyboard_return"
            color: key.toggled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        }

        StyledText {
            anchors.centerIn: parent
            visible: !key.isBackspace && !key.isEnter && !key.isEmpty
            text: {
                const d = key.modelData;
                if (E4.Ydotool.shiftMode === 2)
                    return d.labelCaps || d.labelShift || d.label;
                if (E4.Ydotool.shiftMode === 1)
                    return d.labelShift || d.label;
                return d.label;
            }
            font: key.shape === "fn" ? Tokens.font.body.small : Tokens.font.body.medium
            color: key.toggled ? Colours.palette.m3onPrimary : key.shape === "normal" ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        }
    }
}
