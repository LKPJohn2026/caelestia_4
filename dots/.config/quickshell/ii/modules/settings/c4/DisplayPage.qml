pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Display — per-monitor resolution / refresh rate / scale / rotation, plus adaptive sync.
// Standard "keep these settings?" flow: Apply changes the monitor live (hl.monitor via hyprctl), then a 15 s countdown;
// Keep saves to ~/.config/hypr/monitors.lua (scripts/caelestia4/monitors-save.sh), anything else restores the
// previous setup, so a mode the screen can't show fixes itself.
ContentPage {
    id: page

    forceWidth: true

    property var pending: ({}) // monitor name -> { mode, scale, transform }
    property var previous: null // { name, mode, scale, transform, position } while confirming
    property int countdown: 0

    function modeOf(m): string {
        return `${m.width}x${m.height}@${m.refreshRate.toFixed(2)}`;
    }

    function monitorCall(name, mode, position, scale, transform): void {
        Quickshell.execDetached(["hyprctl", "dispatch", `function() hl.monitor({ output = "${name}", mode = "${mode}", position = "${position}", scale = ${scale}, transform = ${transform} }) end`]);
    }

    function apply(m): void {
        const p = page.pending[m.name];
        page.previous = {
            name: m.name,
            mode: page.modeOf(m),
            scale: m.scale,
            transform: m.transform,
            position: `${m.x}x${m.y}`
        };
        page.monitorCall(m.name, p.mode ?? page.modeOf(m), `${m.x}x${m.y}`, p.scale ?? m.scale, p.transform ?? m.transform);
        page.countdown = 15;
        countdownTimer.restart();
    }

    function keep(): void {
        countdownTimer.stop();
        page.countdown = 0;
        Quickshell.execDetached([Quickshell.shellPath("scripts/caelestia4/monitors-save.sh")]);
        page.pending = ({});
        page.previous = null;
        HyprlandData.updateMonitors();
    }

    function revert(): void {
        countdownTimer.stop();
        page.countdown = 0;
        const o = page.previous;
        if (o)
            page.monitorCall(o.name, o.mode, o.position, o.scale, o.transform);
        page.pending = ({});
        page.previous = null;
        refreshTimer.restart();
    }

    function setPending(name, key, value): void {
        const all = Object.assign({}, page.pending);
        all[name] = Object.assign({}, all[name] ?? {}, {
            [key]: value
        });
        page.pending = all;
    }

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        onTriggered: {
            page.countdown -= 1;
            if (page.countdown <= 0)
                page.revert();
        }
    }

    Timer {
        id: refreshTimer

        interval: 1500
        onTriggered: HyprlandData.updateMonitors()
    }

    Component.onCompleted: HyprlandData.updateMonitors()

    // Confirmation card while a change is on trial
    ContentSection {
        visible: page.previous !== null
        icon: "help"
        title: Translation.tr("Keep these display settings?")

        SettingRow {
            icon: "timer"
            title: Translation.tr("Reverting in %1 s").arg(page.countdown)
            description: Translation.tr("If the screen looks wrong, wait and it goes back by itself")

            RowLayout {
                spacing: 8

                RippleButtonWithIcon {
                    materialIcon: "undo"
                    mainText: Translation.tr("Revert")
                    onClicked: page.revert()
                }

                RippleButtonWithIcon {
                    materialIcon: "check"
                    mainText: Translation.tr("Keep")
                    onClicked: page.keep()
                }
            }
        }
    }

    Repeater {
        model: HyprlandData.monitors

        ContentSection {
            id: monitorSection

            required property var modelData
            readonly property var p: page.pending[modelData.name] ?? {}
            readonly property bool dirty: Object.keys(p).length > 0

            icon: "monitor"
            title: `${modelData.name} · ${modelData.description}`

            ChoiceRow {
                icon: "aspect_ratio"
                title: Translation.tr("Resolution & refresh rate")
                options: (monitorSection.modelData.availableModes ?? []).map(s => {
                    const v = s.replace(/Hz$/, "");
                    const [res, hz] = v.split("@");
                    return {
                        label: `${res.replace("x", " × ")}  ·  ${Math.round(Number(hz))} Hz`,
                        value: `${res}@${Number(hz).toFixed(2)}`
                    };
                })
                value: monitorSection.p.mode ?? page.modeOf(monitorSection.modelData)
                onSelected: v => page.setPending(monitorSection.modelData.name, "mode", v)
            }

            ChoiceRow {
                icon: "zoom_in"
                title: Translation.tr("Scale")
                description: Translation.tr("Size of everything on this screen")
                options: [1, 1.25, 1.5, 1.6, 1.75, 2, 2.5, 3].map(s => ({
                            label: `${Math.round(s * 100)} %`,
                            value: s
                        }))
                value: monitorSection.p.scale ?? monitorSection.modelData.scale
                onSelected: v => page.setPending(monitorSection.modelData.name, "scale", v)
            }

            ChoiceRow {
                icon: "screen_rotation"
                title: Translation.tr("Rotation")
                options: [
                    {
                        label: Translation.tr("Normal"),
                        value: 0
                    },
                    {
                        label: Translation.tr("90°"),
                        value: 1
                    },
                    {
                        label: Translation.tr("180°"),
                        value: 2
                    },
                    {
                        label: Translation.tr("270°"),
                        value: 3
                    }
                ]
                value: monitorSection.p.transform ?? monitorSection.modelData.transform
                onSelected: v => page.setPending(monitorSection.modelData.name, "transform", v)
            }

            ButtonRow {
                enabled: monitorSection.dirty && page.previous === null
                icon: "done_all"
                title: monitorSection.dirty ? Translation.tr("Changes not applied yet") : Translation.tr("No changes")
                description: Translation.tr("You'll have 15 seconds to keep or revert them")
                buttonIcon: "check"
                buttonText: Translation.tr("Apply")
                onClicked: page.apply(monitorSection.modelData)
            }
        }
    }

    ContentSection {
        icon: "speed"
        title: Translation.tr("Adaptive sync")

        HyprChoiceRow {
            key: "misc:vrr"
            icon: "sync"
            title: Translation.tr("Variable refresh rate (VRR / FreeSync / G-Sync)")
            description: Translation.tr("Matches the refresh rate to the game's frame rate to avoid tearing")
            options: [
                {
                    label: Translation.tr("Off"),
                    value: 0
                },
                {
                    label: Translation.tr("Always on"),
                    value: 1
                },
                {
                    label: Translation.tr("Fullscreen only"),
                    value: 2
                },
                {
                    label: Translation.tr("Fullscreen games and video"),
                    value: 3
                }
            ]
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Rendering")

        HyprChoiceRow {
            key: "render:direct_scanout"
            icon: "bolt"
            title: Translation.tr("Direct scanout")
            description: Translation.tr("A fullscreen window goes straight to the display: less latency in games; may flicker on some GPUs")
            options: [
                {
                    label: Translation.tr("Off"),
                    value: 0
                },
                {
                    label: Translation.tr("On"),
                    value: 1
                },
                {
                    label: Translation.tr("Games only"),
                    value: 2
                }
            ]
        }

        HyprSwitchRow {
            key: "general:allow_tearing"
            icon: "splitscreen"
            title: Translation.tr("Allow tearing")
            description: Translation.tr("Games marked \"immediate\" skip vsync for the lowest latency")
        }

        HyprSwitchRow {
            key: "xwayland:force_zero_scaling"
            icon: "aspect_ratio"
            title: Translation.tr("Sharp X11 apps on scaled displays")
            description: Translation.tr("X11 apps draw at scale 1 instead of being stretched (they may look smaller)")
        }
    }
}
