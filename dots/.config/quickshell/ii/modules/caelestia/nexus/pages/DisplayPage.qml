pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (HyprlandData: monitors)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common

// caelestia4: Nexus > Display (upstream has it commented out as a TODO): per-monitor resolution / refresh rate / scale /
// rotation and adaptive sync, as end-4's Settings app (Display). Apply changes the monitor live (hl.monitor via
// hyprctl), then a 15 s countdown: Keep saves to ~/.config/hypr/monitors.lua (scripts/caelestia4/monitors-save.sh),
// anything else restores the previous setup, so a mode the screen can't show fixes itself.
PageBase {
    id: root

    property var pending: ({}) // monitor name -> { mode, scale, transform }
    property var previous: null // { name, mode, scale, transform, position } while confirming
    property int countdown: 0

    readonly property list<real> scales: [1, 1.25, 1.5, 1.6, 1.75, 2, 2.5, 3]

    readonly property list<MenuItem> rotationItems: [
        MenuItem {
            text: Tr.tr("Normal")
            value: 0
        },
        MenuItem {
            text: Tr.tr("90°")
            value: 1
        },
        MenuItem {
            text: Tr.tr("180°")
            value: 2
        },
        MenuItem {
            text: Tr.tr("270°")
            value: 3
        }
    ]

    readonly property list<MenuItem> vrrItems: [
        MenuItem {
            text: Tr.tr("Off")
            value: 0
        },
        MenuItem {
            text: Tr.tr("Always on")
            value: 1
        },
        MenuItem {
            text: Tr.tr("Fullscreen only")
            value: 2
        },
        MenuItem {
            text: Tr.tr("Fullscreen games and video")
            value: 3
        }
    ]

    function modeOf(m): string {
        return `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}`;
    }

    function monitorCall(name: string, mode: string, position: string, scale: real, transform: int): void {
        Quickshell.execDetached(["hyprctl", "dispatch", `function() hl.monitor({ output = "${name}", mode = "${mode}", position = "${position}", scale = ${scale}, transform = ${transform} }) end`]);
    }

    function apply(m): void {
        const p = pending[m.name];
        previous = {
            name: m.name,
            mode: modeOf(m),
            scale: m.scale,
            transform: m.transform,
            position: `${m.x}x${m.y}`
        };
        monitorCall(m.name, p.mode ?? modeOf(m), `${m.x}x${m.y}`, p.scale ?? m.scale, p.transform ?? m.transform);
        countdown = 15;
        countdownTimer.restart();
    }

    function keep(): void {
        countdownTimer.stop();
        countdown = 0;
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/monitors-save.sh")]);
        pending = ({});
        previous = null;
        E4.HyprlandData.updateMonitors();
    }

    function revert(): void {
        countdownTimer.stop();
        countdown = 0;
        const o = previous;
        if (o)
            monitorCall(o.name, o.mode, o.position, o.scale, o.transform);
        pending = ({});
        previous = null;
        refreshTimer.restart();
    }

    function setPending(name: string, key: string, value: var): void {
        const all = Object.assign({}, pending);
        all[name] = Object.assign({}, all[name] ?? {}, {
            [key]: value
        });
        pending = all;
    }

    title: Tr.tr("Display")

    Component.onCompleted: E4.HyprlandData.updateMonitors()

    // Timers and the menu item factory as properties: PageBase's default property takes the page's one content item
    readonly property Timer countdownTimer: Timer {
        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0)
                root.revert();
        }
    }

    readonly property Timer refreshTimer: Timer {
        interval: 1500
        onTriggered: E4.HyprlandData.updateMonitors()
    }

    readonly property Component menuItemComp: Component {
        MenuItem {}
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Confirmation while a change is on trial
        SectionHeader {
            visible: root.previous !== null
            first: true
            text: Tr.tr("Keep these display settings?")
        }

        InfoRow {
            visible: root.previous !== null
            first: true
            icon: "timer"
            label: Tr.tr("Reverting in %1 s").arg(root.countdown)
            subtext: Tr.tr("If the screen looks wrong, wait and it goes back by itself")
        }

        RowButton {
            visible: root.previous !== null
            icon: "check"
            text: Tr.tr("Keep")
            onClicked: root.keep()
        }

        RowButton {
            visible: root.previous !== null
            last: true
            icon: "undo"
            text: Tr.tr("Revert")
            onClicked: root.revert()
        }

        Repeater {
            model: E4.HyprlandData.monitors

            ColumnLayout {
                id: monitor

                required property var modelData
                required property int index
                readonly property var p: root.pending[modelData.name] ?? {}
                readonly property bool dirty: Object.keys(p).length > 0
                readonly property string mode: p.mode ?? root.modeOf(modelData)
                readonly property real curScale: p.scale ?? modelData.scale
                readonly property int curTransform: p.transform ?? modelData.transform

                // One MenuItem per mode the monitor reports ("7680x2160@240.00Hz")
                readonly property list<MenuItem> modeItems: (modelData.availableModes ?? []).map(s => {
                    const [res, hz] = s.replace(/Hz$/, "").split("@");
                    return root.menuItemComp.createObject(monitor, {
                        text: `${res.replace("x", " × ")}  ·  ${Math.round(Number(hz))} Hz`,
                        value: `${res}@${Number(hz).toFixed(2)}`
                    });
                })
                readonly property list<MenuItem> scaleItems: root.scales.map(s => root.menuItemComp.createObject(monitor, {
                        text: `${Math.round(s * 100)} %`,
                        value: s
                    }))

                Layout.fillWidth: true
                spacing: Tokens.spacing.extraSmall / 2

                SectionHeader {
                    first: monitor.index === 0 && root.previous === null
                    text: `${monitor.modelData.name} · ${monitor.modelData.description}`
                }

                SelectRow {
                    first: true
                    label: Tr.tr("Resolution & refresh rate")
                    menuItems: monitor.modeItems
                    active: monitor.modeItems.find(i => i.value === monitor.mode) ?? null
                    fallbackText: monitor.mode
                    onSelected: item => root.setPending(monitor.modelData.name, "mode", item.value)
                }

                SelectRow {
                    label: Tr.tr("Scale")
                    subtext: Tr.tr("Size of everything on this screen")
                    menuItems: monitor.scaleItems
                    active: monitor.scaleItems.find(i => Math.abs(i.value - monitor.curScale) < 0.001) ?? null
                    fallbackText: `${Math.round(monitor.curScale * 100)} %`
                    onSelected: item => root.setPending(monitor.modelData.name, "scale", item.value)
                }

                SelectRow {
                    label: Tr.tr("Rotation")
                    menuItems: root.rotationItems
                    active: root.rotationItems.find(i => i.value === monitor.curTransform) ?? null
                    onSelected: item => root.setPending(monitor.modelData.name, "transform", item.value)
                }

                RowButton {
                    last: true
                    disabled: !monitor.dirty || root.previous !== null
                    icon: "done_all"
                    text: monitor.dirty ? Tr.tr("Apply changes") : Tr.tr("No changes")
                    subtext: Tr.tr("You'll have 15 seconds to keep or revert them")
                    onClicked: root.apply(monitor.modelData)
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Adaptive sync")
        }

        HyprSelectRow {
            first: true
            last: true
            key: "misc:vrr"
            label: Tr.tr("Variable refresh rate (VRR / FreeSync / G-Sync)")
            subtext: Tr.tr("Matches the refresh rate to the game's frame rate to avoid tearing")
            menuItems: root.vrrItems
        }
    }
}
