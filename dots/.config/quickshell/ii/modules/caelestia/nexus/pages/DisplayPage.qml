pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io // caelestia4: mirrored screens (hyprctl monitors all)
import Quickshell.Hyprland // caelestia4: monitor events
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (HyprlandData: monitors)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.services // caelestia4: keep (ScaledOption)
import qs.modules.caelestia.nexus.pages.display // caelestia4: MonitorLayout, TrialTime

// caelestia4: Nexus > Display (upstream has it commented out as a TODO): per-monitor resolution / refresh rate / scale /
// rotation and adaptive sync, as end-4's Settings app (Display), and where the screens sit (Arrangement). Apply changes
// the monitors live (hl.monitor via hyprctl), then a countdown (TrialTime, 15 s): Keep saves to ~/.config/hypr/monitors.lua
// (scripts/caelestia4/monitors-save.py), anything else restores the previous setup, so a mode the screen can't show
// fixes itself. Leaving the page during the countdown restores the previous setup too, like KeepRevert.qml.
PageBase {
    id: root

    property var pending: ({}) // monitor name -> { mode, scale, transform }
    property var pendingPositions: ({}) // caelestia4: monitor name -> { x, y } from the Arrangement canvas
    property var previous: null // caelestia4: [{ name, mode, scale, transform, position }] of the screens on trial
    // caelestia4: what is on trial: one screen's name (Apply changes), or "" for the arrangement. Keep or Revert ends
    // only that change: picks not applied yet on the other one stay
    property string trialScreen
    // caelestia4: screens that copy another one: [{ name, of }]. Hyprland leaves them out of `hyprctl monitors`
    property var mirrors: []
    property int countdown: 0

    // caelestia4: mirrored screens sit where the screen they copy is: not in the arrangement
    readonly property var arrangeable: E4.HyprlandData.monitors.filter(m => !m.mirrorOf || m.mirrorOf === "none")
    readonly property var movedScreens: arrangeable.filter(m => {
        const p = pendingPositions[m.name];
        return p && (p.x !== m.x || p.y !== m.y);
    })

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

    function modeOf(m): string {
        return `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}`;
    }

    // caelestia4: "1280x720@60.00" as the mode menu shows it: "1280 × 720 · 60 Hz"
    function prettyMode(mode: string): string {
        const [res, hz] = mode.replace(/Hz$/, "").split("@");
        return hz ? `${res.replace("x", " × ")}  ·  ${Math.round(Number(hz))} Hz` : res.replace("x", " × ");
    }

    function monitorCall(name: string, mode: string, position: string, scale: real, transform: int): void {
        Quickshell.execDetached(["hyprctl", "dispatch", `function() hl.monitor({ output = "${name}", mode = "${mode}", position = "${position}", scale = ${scale}, transform = ${transform} }) end`]);
    }

    function snapshot(m): var {
        return {
            name: m.name,
            mode: modeOf(m),
            scale: m.scale,
            transform: m.transform,
            position: `${m.x}x${m.y}`
        };
    }

    function startTrial(): void {
        countdown = TrialTime.seconds;
        countdownTimer.restart();
    }

    function apply(m): void {
        const p = pending[m.name];
        previous = [snapshot(m)];
        trialScreen = m.name;
        monitorCall(m.name, p.mode ?? modeOf(m), `${m.x}x${m.y}`, p.scale ?? m.scale, p.transform ?? m.transform);
        startTrial();
    }

    // caelestia4: Arrangement: move every screen whose position changed, as one trial
    function applyLayout(): void {
        const moved = movedScreens;
        if (!moved.length)
            return;
        previous = moved.map(m => snapshot(m));
        trialScreen = "";
        for (const m of moved) {
            const p = pendingPositions[m.name];
            monitorCall(m.name, modeOf(m), `${p.x}x${p.y}`, m.scale, m.transform);
        }
        startTrial();
        refreshTimer.restart();
    }

    function keep(): void {
        countdownTimer.stop();
        countdown = 0;
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/monitors-save.py")]);
        endTrial();
        E4.HyprlandData.updateMonitors();
    }

    // caelestia4: forget only the change that was on trial
    function endTrial(): void {
        if (trialScreen) {
            const all = Object.assign({}, pending);
            delete all[trialScreen];
            pending = all;
        } else {
            pendingPositions = ({});
        }
        previous = null;
        trialScreen = "";
    }

    function revert(): void {
        countdownTimer.stop();
        countdown = 0;
        for (const o of previous ?? [])
            monitorCall(o.name, o.mode, o.position, o.scale, o.transform);
        endTrial();
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

    Component.onCompleted: {
        E4.HyprlandData.updateMonitors();
        mirrorsProc.running = true;
    }

    // caelestia4: the page went away (another page, or Nexus closed) before Keep: put the screens back, as Revert does
    Component.onDestruction: {
        if (previous === null)
            return;
        countdownTimer.stop();
        for (const o of previous)
            monitorCall(o.name, o.mode, o.position, o.scale, o.transform);
        NexusActions.toast(Tr.tr("The display settings went back to how they were"));
    }

    readonly property Process mirrorsProc: Process {
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    // mirrorOf is the copied screen's id, not its name
                    const all = JSON.parse(text);
                    root.mirrors = all.filter(m => m.mirrorOf && m.mirrorOf !== "none").map(m => ({
                                name: m.name,
                                of: all.find(o => String(o.id) === String(m.mirrorOf))?.name ?? m.mirrorOf
                            }));
                } catch (e) {
                    root.mirrors = [];
                }
            }
        }
    }

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
        onTriggered: {
            E4.HyprlandData.updateMonitors();
            root.mirrorsProc.running = true;
        }
    }

    // caelestia4: a screen plugged in or set up again: HyprlandData reads it at once, often before its rule applies, so
    // read it again a moment later (Apply sends each screen's mode too, and a stale one would undo its rule)
    readonly property Connections monitorEvents: Connections {
        function onRawEvent(event: var): void {
            if (event.name.startsWith("monitor") || event.name === "configreloaded")
                root.refreshTimer.restart();
        }

        target: Hyprland
    }

    // caelestia4: Display > Arrangement: where the screens sit (pages/display/MonitorLayout.qml)
    readonly property Component arrangementComp: Component {
        ColumnLayout {
            spacing: Tokens.spacing.extraSmall / 2

            SectionHeader {
                first: root.previous === null && root.arrangeable.length > 1
                text: Tr.tr("Arrangement")
            }

            MonitorLayout {
                first: true
                last: root.arrangeable.length < 2
                monitors: root.arrangeable
                positions: root.pendingPositions
                locked: root.previous !== null
                focusedName: E4.HyprlandData.monitors.find(m => m.focused)?.name ?? ""
                mirrors: root.mirrors
                onArranged: p => root.pendingPositions = p
            }

            RowButton {
                visible: root.arrangeable.length > 1
                disabled: root.movedScreens.length === 0 || root.previous !== null
                last: !putBack.visible
                icon: "done_all"
                text: root.movedScreens.length ? Tr.tr("Apply arrangement") : Tr.tr("No changes")
                subtext: Tr.tr("You'll have %1 seconds to keep or revert them").arg(TrialTime.seconds)
                onClicked: root.applyLayout()
            }

            RowButton {
                id: putBack

                visible: root.arrangeable.length > 1 && root.movedScreens.length > 0 && root.previous === null
                last: true
                icon: "undo"
                text: Tr.tr("Put the screens back")
                onClicked: root.pendingPositions = ({})
            }
        }
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

        // caelestia4: Arrangement comes first with two or more screens; with one it is only a picture, so after it
        Loader {
            Layout.fillWidth: true
            active: root.arrangeable.length > 1
            visible: active
            sourceComponent: root.arrangementComp
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

                // One MenuItem per mode the monitor reports (availableModes, e.g. "1920x1080@60.00Hz")
                readonly property list<MenuItem> modeItems: (modelData.availableModes ?? []).map(s => {
                    const [res, hz] = s.replace(/Hz$/, "").split("@");
                    return root.menuItemComp.createObject(monitor, {
                        text: root.prettyMode(s),
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
                    first: monitor.index === 0 && root.previous === null && root.arrangeable.length < 2
                    // caelestia4: no dangling " · " when the monitor reports no description
                    text: [monitor.modelData.name, monitor.modelData.description].filter(t => !!t).join(" · ")
                }

                SelectRow {
                    first: true
                    label: Tr.tr("Resolution & refresh rate")
                    menuItems: monitor.modeItems
                    active: monitor.modeItems.find(i => i.value === monitor.mode) ?? null
                    // caelestia4: a mode not in the list (a custom one) reads like the menu's, not "1280x720@60.00"
                    fallbackText: root.prettyMode(monitor.mode)
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
                    subtext: Tr.tr("You'll have %1 seconds to keep or revert them").arg(TrialTime.seconds)
                    onClicked: root.apply(monitor.modelData)
                }
            }
        }

        Loader {
            Layout.fillWidth: true
            active: root.arrangeable.length < 2
            visible: active
            sourceComponent: root.arrangementComp
        }

        // caelestia4: moved from Services (proposal 2.3). Stored as a fraction (0.05), shown as a percent: an x: id
        // over the c: option (ScaledOption)
        SectionHeader {
            text: Tr.tr("Brightness")
        }

        StepperRow {
            id: brightnessStep

            first: true
            last: true
            setting: "x:services.brightnessIncrementPercent"
        }

        // Not an item: it only feeds the row above
        ScaledOption {
            link: brightnessStep.link
            node: GlobalConfig.services
            key: "brightnessIncrement"
            factor: 100
        }

        // caelestia4: end-4's night light (services/Hyprsunset.qml); the Eye protection card edits the same options
        SectionHeader {
            text: Tr.tr("Night light")
        }

        ToggleRow {
            first: true
            setting: "e4:light.night.automatic"
        }

        TimeRangeRow {
            setting: "e4:light.night.from"
            toSetting: "e4:light.night.to"
        }

        // caelestia4: the slider writes any value in between: move it to the entry's step (100 K)
        SliderRow {
            id: warmthRow

            last: true
            setting: "e4:light.night.colorTemperature"
            onMoved: v => {
                const step = warmthRow.link.entry?.step ?? 100;
                const n = warmthRow.from + Math.round((v - warmthRow.from) / step) * step;
                warmthRow.link.setLater(Math.max(warmthRow.from, Math.min(warmthRow.to, n)));
            }
        }

        SectionHeader {
            text: Tr.tr("Adaptive sync")
        }

        SelectRow {
            first: true
            last: true
            setting: "h:misc:vrr"
        }
    }
}
