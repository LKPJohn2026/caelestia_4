import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "display" page (merged by Registry.qml). See RegPanels.qml for the format.
// The per-monitor rows (mode, scale, rotation) are not settings: they are applied live and saved to monitors.lua
QtObject {
    readonly property var entries: ({
            // caelestia4: Display > Brightness (pages/DisplayPage.qml), moved from Services (proposal 2.3; id kept).
            // Stored as a fraction, shown as a percent: an x: row over the c: option (ScaledOption), as on Audio
            "x:services.brightnessIncrementPercent": {
                route: "display",
                section: Tr.mark("Brightness"),
                title: Tr.mark("Brightness step"),
                desc: Tr.mark("How much the brightness changes per scroll or key press"),
                keywords: [Tr.mark("brightness"), Tr.mark("step"), Tr.mark("increment"), Tr.mark("scroll"), Tr.mark("backlight"), Tr.mark("screen")],
                type: "int",
                unit: "%",
                min: 1,
                max: 50,
                step: 1
            },
            "c:services.brightnessIncrement": {
                route: "display",
                section: Tr.mark("Brightness"),
                title: Tr.mark("Brightness step"),
                type: "real",
                shownBy: "x:services.brightnessIncrementPercent"
            },

            // Display > Night light (pages/DisplayPage.qml): end-4's Hyprsunset service
            "e4:light.night.automatic": {
                route: "display",
                section: Tr.mark("Night light"),
                title: Tr.mark("Night light on a schedule"),
                desc: Tr.mark("Turns warmer colours on and off by itself at the times below"),
                keywords: [Tr.mark("night light"), Tr.mark("schedule"), Tr.mark("automatic"), Tr.mark("blue light"), Tr.mark("hyprsunset"), Tr.mark("warm"), Tr.mark("evening")],
                type: "bool"
            },
            "e4:light.night.from": {
                route: "display",
                section: Tr.mark("Night light"),
                title: Tr.mark("Night light hours"),
                desc: Tr.mark("From when to when the night light is on, in 24-hour time."),
                keywords: [Tr.mark("night light"), Tr.mark("schedule"), Tr.mark("time"), Tr.mark("from"), Tr.mark("to"), Tr.mark("start"), Tr.mark("end"), Tr.mark("hours")],
                type: "string",
                requires: {
                    id: "e4:light.night.automatic",
                    value: true
                }
            },
            "e4:light.night.to": {
                route: "display",
                section: Tr.mark("Night light"),
                title: Tr.mark("Night light ends"),
                keywords: [Tr.mark("night light"), Tr.mark("schedule"), Tr.mark("time"), Tr.mark("end"), Tr.mark("morning")],
                type: "string",
                requires: {
                    id: "e4:light.night.automatic",
                    value: true
                }
            },
            "e4:light.night.colorTemperature": {
                route: "display",
                section: Tr.mark("Night light"),
                title: Tr.mark("Night light warmth"),
                desc: Tr.mark("Colour temperature while the night light is on. Lower is warmer and more orange"),
                keywords: [Tr.mark("night light"), Tr.mark("temperature"), Tr.mark("warmth"), Tr.mark("kelvin"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("orange"), Tr.mark("hyprsunset")],
                type: "int",
                unit: "K",
                min: 1200,
                max: 6500,
                step: 100
            },

            // Display > Adaptive sync
            "h:misc:vrr": {
                route: "display",
                section: Tr.mark("Adaptive sync"),
                title: Tr.mark("Variable refresh rate"),
                desc: Tr.mark("Matches the refresh rate to the game's frame rate to avoid tearing. Some screens flicker with it"),
                keywords: [Tr.mark("vrr"), Tr.mark("freesync"), Tr.mark("g-sync"), Tr.mark("gsync"), Tr.mark("adaptive sync"), Tr.mark("refresh rate"), Tr.mark("tearing"), Tr.mark("games")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.mark("Off")
                    },
                    {
                        value: 1,
                        label: Tr.mark("Always on")
                    },
                    {
                        value: 2,
                        label: Tr.mark("Fullscreen only")
                    },
                    {
                        value: 3,
                        label: Tr.mark("Fullscreen games and video")
                    }
                ],
                default: 0
            },
            "h:render:cm_auto_hdr": {
                route: "display",
                section: Tr.mark("HDR"),
                title: Tr.mark("Switch to HDR for fullscreen HDR video"),
                desc: Tr.mark("When a fullscreen window plays HDR (a browser on YouTube), the screen goes into HDR mode. On many screens that looks grey and washed out; off, the video is shown in SDR"),
                keywords: [Tr.mark("hdr"), Tr.mark("auto hdr"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("grey"), Tr.mark("gray"), Tr.mark("washed out"), Tr.mark("youtube"), Tr.mark("video"), Tr.mark("fullscreen")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.mark("Off")
                    },
                    {
                        value: 1,
                        label: Tr.mark("HDR")
                    },
                    {
                        value: 2,
                        label: Tr.mark("HDR, brightness from the screen's EDID")
                    }
                ],
                default: 0
            }
        })
}
