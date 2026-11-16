import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for Desktop (appearance/desktop) and the desktop widget sub-pages clock, calendar, customImage, customText, imageCard, images, media, notes and resources (routes appearance/desktop/widget.<w>) (merged by Registry.qml). See RegPanels.qml for the format.
// Owned by the widgetsA group. Entries are in the order of the rows on each page
QtObject {
    id: root

    // Shared option lists (end4-pC's AbstractBackgroundWidget placement; the card sizes, rows x columns)
    readonly property var placementOptions: [
        {
            value: "free",
            label: Tr.mark("Free")
        },
        {
            value: "leastBusy",
            label: Tr.mark("Least busy")
        },
        {
            value: "mostBusy",
            label: Tr.mark("Most busy")
        }
    ]
    readonly property string placementDesc: Tr.mark("Free: drag it on the desktop. Otherwise it moves to the calmest (or busiest) part of the wallpaper")
    readonly property string sizeDesc: Tr.mark("You can also drag its corner on the desktop")
    readonly property var sizeLabels: ({
            "1x1": Tr.mark("Small"),
            "1x2": Tr.mark("Wide"),
            "1x3": Tr.mark("Extra wide"),
            "2x2": Tr.mark("Large"),
            "2x3": Tr.mark("Extra large")
        })
    // The theme colours end-4's widgets take by name ("" = picked from the wallpaper)
    readonly property var colourOptions: [
        {
            value: "",
            label: Tr.mark("Automatic")
        },
        {
            value: "primary",
            label: Tr.mark("Primary")
        },
        {
            value: "secondary",
            label: Tr.mark("Secondary")
        },
        {
            value: "tertiary",
            label: Tr.mark("Tertiary")
        },
        {
            value: "primaryContainer",
            label: Tr.mark("Primary container")
        },
        {
            value: "secondaryContainer",
            label: Tr.mark("Secondary container")
        },
        {
            value: "tertiaryContainer",
            label: Tr.mark("Tertiary container")
        }
    ]

    function sizeOptions(modes: var): var {
        return modes.map(m => ({
                    value: m,
                    label: root.sizeLabels[m]
                }));
    }

    function shapeOption(value: string, label: string): var {
        return {
            value: value,
            label: label
        };
    }

    readonly property var entries: ({
            // Desktop (pages/wallandstyle/DesktopPage.qml): what every widget shares. The list of widgets there is
            // not registry rows (PresetLayout turns them on); each widget's options are on its own sub-page below
            "e4:background.widgets.scale": {
                route: "appearance/desktop",
                section: Tr.mark("Look"),
                title: Tr.mark("Widget size"),
                desc: Tr.mark("How large all widgets are drawn. Automatic (the reset button): as large as in the preset's preview"),
                keywords: [Tr.mark("scale"), Tr.mark("size"), Tr.mark("widgets"), Tr.mark("bigger"), Tr.mark("smaller"), Tr.mark("zoom")],
                type: "real",
                unit: "%",
                scale: 100,
                // caelestia4: 0 is Automatic (the default, so the reset button gives it); the slider starts at 25 %, so
                // a drag off the left end doesn't draw the widgets at 5 %,
                min: 0.25,
                max: 3,
                step: 0.05,
                options: [
                    {
                        value: 0,
                        label: Tr.mark("Automatic")
                    }
                ]
            },
            "e4:background.widgets.blurWidgets": {
                route: "appearance/desktop",
                section: Tr.mark("Look"),
                title: Tr.mark("Blurred backgrounds"),
                desc: Tr.mark("Widget cards show the wallpaper blurred behind them"),
                keywords: [Tr.mark("blur"), Tr.mark("widgets"), Tr.mark("background"), Tr.mark("glass"), Tr.mark("frosted")],
                type: "bool"
            },
            "e4:background.widgets.blurRadius": {
                route: "appearance/desktop",
                section: Tr.mark("Look"),
                title: Tr.mark("Blur strength"),
                desc: Tr.mark("How blurred the wallpaper behind the widget cards is"),
                keywords: [Tr.mark("blur"), Tr.mark("radius"), Tr.mark("strength"), Tr.mark("widgets"), Tr.mark("glass")],
                type: "real",
                unit: "px",
                min: 0,
                max: 64,
                step: 1,
                requires: {
                    id: "e4:background.widgets.blurWidgets",
                    value: true
                }
            },
            "e4:background.widgets.shadow": {
                route: "appearance/desktop",
                section: Tr.mark("Look"),
                title: Tr.mark("Shadows"),
                desc: Tr.mark("A soft shadow under each widget card"),
                keywords: [Tr.mark("shadow"), Tr.mark("widgets"), Tr.mark("depth"), Tr.mark("drop shadow")],
                type: "bool"
            },
            "e4:background.widgetsLocked": {
                route: "appearance/desktop",
                section: Tr.mark("Arranging"),
                title: Tr.mark("Lock widgets"),
                desc: Tr.mark("They can't be dragged or resized. Right-click a widget to switch"),
                keywords: [Tr.mark("widgets"), Tr.mark("lock"), Tr.mark("drag"), Tr.mark("move"), Tr.mark("resize")],
                type: "bool"
            },
            "e4:background.showGrid": {
                route: "appearance/desktop",
                section: Tr.mark("Arranging"),
                title: Tr.mark("Grid while dragging"),
                desc: Tr.mark("Widgets snap to it either way"),
                keywords: [Tr.mark("widgets"), Tr.mark("grid"), Tr.mark("snap"), Tr.mark("drag")],
                type: "bool"
            },
            "e4:background.saveToPreset": {
                route: "appearance/desktop",
                section: Tr.mark("Arranging"),
                title: Tr.mark("Save moves to the preset"),
                desc: Tr.mark("Moving, resizing or turning a widget also changes the preset applied last, so it opens as you left it"),
                keywords: [Tr.mark("widgets"), Tr.mark("preset"), Tr.mark("save"), Tr.mark("layout")],
                type: "bool"
            },
            "e4:background.showSnapLines": {
                route: "appearance/desktop",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Show snap lines"),
                desc: Tr.mark("Lines flash where a dropped widget lines up with others or the screen's middle"),
                keywords: [Tr.mark("snap"), Tr.mark("lines"), Tr.mark("guides"), Tr.mark("align"), Tr.mark("drag"), Tr.mark("widgets")],
                type: "bool",
                advanced: true
            },
            "c:background.enabled": {
                route: "appearance/desktop",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Wallpaper and widgets"),
                desc: Tr.mark("Off: no wallpaper, clock, visualiser or widgets on any screen; Hyprland's own background shows"),
                keywords: [Tr.mark("background"), Tr.mark("desktop"), Tr.mark("layer"), Tr.mark("wallpaper"), Tr.mark("widgets"), Tr.mark("hide"), Tr.mark("off")],
                type: "bool",
                advanced: true
            },

            // Desktop > Clock (pages/wallandstyle/widgets/ClockWidgetPage.qml). x:desktop.clock.show (on/off) and
            // x:desktop.clock (style) stand for several keys together: Caelestia's own on/off and end-4's widget on/off
            // and style (one clock on the desktop)
            "x:desktop.clock.show": {
                route: "appearance/desktop/widget.clock",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("One clock at a time, in the style below"),
                keywords: [Tr.mark("clock"), Tr.mark("time"), Tr.mark("desktop"), Tr.mark("widget"), Tr.mark("show")],
                type: "bool"
            },
            "x:desktop.clock": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("General"),
                title: Tr.mark("Style"),
                desc: Tr.mark("How the clock looks"),
                keywords: [Tr.mark("clock"), Tr.mark("time"), Tr.mark("desktop"), Tr.mark("widget"), Tr.mark("style"), Tr.mark("cookie"), Tr.mark("digital"), Tr.mark("daily"), Tr.mark("pixel")],
                type: "enum",
                options: [
                    {
                        value: "caelestia",
                        label: Tr.mark("Classic")
                    },
                    {
                        value: "cookie",
                        label: Tr.mark("Cookie")
                    },
                    {
                        value: "digital",
                        label: Tr.mark("Digital")
                    },
                    {
                        value: "daily",
                        label: Tr.mark("Daily")
                    },
                    {
                        value: "pixel",
                        label: Tr.mark("Pixel")
                    }
                ]
            },
            "e4:background.widgets.clock.enable": {
                route: "appearance/desktop/widget.clock",
                // caelestia4: same title and description as the row that shows it (x:desktop.clock.show), so search
                // and Changed name it the same way
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("One clock at a time, in the style below"),
                keywords: [Tr.mark("clock"), Tr.mark("widget"), Tr.mark("desktop"), Tr.mark("show"), Tr.mark("cookie"), Tr.mark("digital")],
                type: "bool",
                shownBy: "x:desktop.clock.show"
            },
            "e4:background.widgets.clock.style": {
                route: "appearance/desktop/widget.clock",
                // caelestia4: as x:desktop.clock, the row that shows it
                title: Tr.mark("Style"),
                desc: Tr.mark("How the clock looks"),
                keywords: [Tr.mark("clock"), Tr.mark("style"), Tr.mark("cookie"), Tr.mark("digital"), Tr.mark("daily"), Tr.mark("pixel"), Tr.mark("analog")],
                type: "enum",
                options: [
                    {
                        value: "cookie",
                        label: Tr.mark("Cookie")
                    },
                    {
                        value: "digital",
                        label: Tr.mark("Digital")
                    },
                    {
                        value: "daily",
                        label: Tr.mark("Daily")
                    },
                    {
                        value: "pixel",
                        label: Tr.mark("Pixel")
                    }
                ],
                shownBy: "x:desktop.clock"
            },
            "c:background.desktopClock.scale": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("How big the classic clock is"),
                keywords: [Tr.mark("clock"), Tr.mark("size"), Tr.mark("scale"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.5,
                max: 2,
                step: 0.1
            },
            "c:background.desktopClock.position": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: Tr.mark("Where on the screen the classic clock sits"),
                keywords: [Tr.mark("clock"), Tr.mark("position"), Tr.mark("corner"), Tr.mark("place")],
                type: "enum",
                options: [
                    {
                        value: "top-left",
                        label: Tr.mark("Top left")
                    },
                    {
                        value: "top-center",
                        label: Tr.mark("Top centre")
                    },
                    {
                        value: "top-right",
                        label: Tr.mark("Top right")
                    },
                    {
                        value: "middle-left",
                        label: Tr.mark("Middle left")
                    },
                    {
                        value: "middle-center",
                        label: Tr.mark("Centre")
                    },
                    {
                        value: "middle-right",
                        label: Tr.mark("Middle right")
                    },
                    {
                        value: "bottom-left",
                        label: Tr.mark("Bottom left")
                    },
                    {
                        value: "bottom-center",
                        label: Tr.mark("Bottom centre")
                    },
                    {
                        value: "bottom-right",
                        label: Tr.mark("Bottom right")
                    }
                ]
            },
            "e4:background.widgets.clock.placementStrategy": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: Tr.mark("Free: drag it on the desktop. Otherwise it moves to the calmest (or busiest) part of the wallpaper"),
                keywords: [Tr.mark("clock"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: [
                    {
                        value: "free",
                        label: Tr.mark("Free")
                    },
                    {
                        value: "leastBusy",
                        label: Tr.mark("Least busy")
                    },
                    {
                        value: "mostBusy",
                        label: Tr.mark("Most busy")
                    }
                ]
            },
            // Caelestia's clock, "Classic" to users (shown while it is the desktop clock)
            "e4:caelestia.desktopWeather": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Classic clock"),
                title: Tr.mark("Weather beside it"),
                desc: Tr.mark("The temperature and sky next to the time"),
                keywords: [Tr.mark("weather"), Tr.mark("clock"), Tr.mark("desktop"), Tr.mark("temperature")],
                type: "bool"
            },
            "c:background.desktopClock.background.enabled": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Classic clock"),
                title: Tr.mark("Card behind it"),
                desc: Tr.mark("A blurred card behind the clock, easier to read on busy wallpapers"),
                keywords: [Tr.mark("clock"), Tr.mark("background"), Tr.mark("card"), Tr.mark("blur"), Tr.mark("readability")],
                type: "bool"
            },
            "c:background.desktopClock.shadow.enabled": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Classic clock"),
                title: Tr.mark("Shadow"),
                desc: Tr.mark("A soft shadow under the clock, easier to read on light wallpapers"),
                keywords: [Tr.mark("clock"), Tr.mark("shadow"), Tr.mark("readability"), Tr.mark("caelestia")],
                type: "bool"
            },
            "c:background.desktopClock.invertColors": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Classic clock"),
                title: Tr.mark("Swap light and dark colours"),
                desc: Tr.mark("Light text on a dark theme becomes dark, and the other way round"),
                keywords: [Tr.mark("clock"), Tr.mark("invert"), Tr.mark("colours"), Tr.mark("colors"), Tr.mark("contrast"), Tr.mark("caelestia")],
                type: "bool"
            },
            // end-4's clock, by style
            "e4:background.widgets.clock.cookie.aiStyling": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Cookie clock"),
                title: Tr.mark("Match the wallpaper"),
                desc: Tr.mark("Picks the shape, hands and date style from the wallpaper's category (sorted by Gemini). Overwrites the choices below"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("ai"), Tr.mark("gemini"), Tr.mark("wallpaper"), Tr.mark("style"), Tr.mark("auto")],
                type: "bool"
            },
            "e4:background.widgets.clock.cookie.dialNumberStyle": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Cookie clock"),
                title: Tr.mark("Dial marks"),
                desc: Tr.mark("What goes around the edge of the dial"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("dial"), Tr.mark("numbers"), Tr.mark("marks"), Tr.mark("dots")],
                type: "enum",
                options: [
                    {
                        value: "full",
                        label: Tr.mark("Lines")
                    },
                    {
                        value: "dots",
                        label: Tr.mark("Dots")
                    },
                    {
                        value: "numbers",
                        label: Tr.mark("Numbers")
                    },
                    {
                        value: "none",
                        label: Tr.mark("None")
                    }
                ]
            },
            "e4:background.widgets.clock.cookie.dateStyle": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Cookie clock"),
                title: Tr.mark("Date"),
                desc: Tr.mark("How the date is shown on the dial"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("date"), Tr.mark("day")],
                type: "enum",
                options: [
                    {
                        value: "bubble",
                        label: Tr.mark("Bubble")
                    },
                    {
                        value: "border",
                        label: Tr.mark("Around the edge")
                    },
                    {
                        value: "rect",
                        label: Tr.mark("Box")
                    },
                    {
                        value: "hide",
                        label: Tr.mark("Hidden")
                    }
                ]
            },
            "e4:background.widgets.clock.cookie.timeIndicators": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Cookie clock"),
                title: Tr.mark("Time in the middle"),
                desc: Tr.mark("The hour and minute as numbers in the centre of the dial"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("time"), Tr.mark("numbers"), Tr.mark("indicators")],
                type: "bool"
            },
            "e4:background.widgets.clock.cookie.hourMarks": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Cookie clock"),
                title: Tr.mark("Hour marks"),
                desc: Tr.mark("A mark for each hour inside the dial"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("hour"), Tr.mark("marks"), Tr.mark("ticks")],
                type: "bool"
            },
            "e4:background.widgets.clock.cookie.hourHandStyle": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Hands"),
                title: Tr.mark("Hour hand"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("hour"), Tr.mark("hand")],
                type: "enum",
                options: [
                    {
                        value: "fill",
                        label: Tr.mark("Filled")
                    },
                    {
                        value: "hollow",
                        label: Tr.mark("Outline")
                    },
                    {
                        value: "classic",
                        label: Tr.mark("Classic")
                    },
                    {
                        value: "hide",
                        label: Tr.mark("Hidden")
                    }
                ]
            },
            "e4:background.widgets.clock.cookie.minuteHandStyle": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Hands"),
                title: Tr.mark("Minute hand"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("minute"), Tr.mark("hand")],
                type: "enum",
                options: [
                    {
                        value: "medium",
                        label: Tr.mark("Medium")
                    },
                    {
                        value: "thin",
                        label: Tr.mark("Thin")
                    },
                    {
                        value: "bold",
                        label: Tr.mark("Bold")
                    },
                    {
                        value: "classic",
                        label: Tr.mark("Classic")
                    },
                    {
                        value: "hide",
                        label: Tr.mark("Hidden")
                    }
                ]
            },
            "e4:time.secondPrecision": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Hands"),
                title: Tr.mark("Tick every second"),
                desc: Tr.mark("Shows the cookie clock's second hand and moves its date each second. Uses a little more power"),
                keywords: [Tr.mark("seconds"), Tr.mark("second hand"), Tr.mark("clock"), Tr.mark("time"), Tr.mark("precision")],
                type: "bool"
            },
            "e4:background.widgets.clock.cookie.secondHandStyle": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Hands"),
                title: Tr.mark("Second hand"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("second"), Tr.mark("hand")],
                type: "enum",
                options: [
                    {
                        value: "dot",
                        label: Tr.mark("Dot")
                    },
                    {
                        value: "line",
                        label: Tr.mark("Line")
                    },
                    {
                        value: "classic",
                        label: Tr.mark("Classic")
                    },
                    {
                        value: "hide",
                        label: Tr.mark("Hidden")
                    }
                ],
                requires: {
                    id: "e4:time.secondPrecision",
                    value: true
                }
            },
            "e4:background.widgets.clock.digital.showDate": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Digital clock"),
                title: Tr.mark("Show the date"),
                desc: Tr.mark("The date under the time"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("date"), Tr.mark("day")],
                type: "bool"
            },
            "e4:background.widgets.clock.digital.vertical": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Digital clock"),
                title: Tr.mark("Stacked"),
                desc: Tr.mark("Hours above minutes"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("vertical"), Tr.mark("stacked"), Tr.mark("layout")],
                type: "bool"
            },
            "e4:background.widgets.clock.digital.animateChange": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Digital clock"),
                title: Tr.mark("Animate changes"),
                desc: Tr.mark("The digits animate when the time changes"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("animation"), Tr.mark("animate")],
                type: "bool"
            },
            "e4:background.widgets.clock.digital.font.family": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Font"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Used for the digital clock's time, and for all clock text when the switch above is on"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("font"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "e4:background.widgets.clock.digital.font.size": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("How big the digital clock's time is"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("font"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "real",
                unit: "px",
                min: 30,
                max: 300,
                step: 5
            },
            "e4:background.widgets.clock.daily.variant": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Daily clock"),
                title: Tr.mark("Layout"),
                desc: Tr.mark("How the daily clock lays out the time, greeting and weather"),
                keywords: [Tr.mark("daily"), Tr.mark("clock"), Tr.mark("variant"), Tr.mark("layout"), Tr.mark("greeting")],
                type: "enum",
                options: [
                    {
                        value: "badge",
                        label: Tr.mark("Badge")
                    },
                    {
                        value: "morning",
                        label: Tr.mark("Morning")
                    },
                    {
                        value: "script",
                        label: Tr.mark("Script")
                    },
                    {
                        value: "bold",
                        label: Tr.mark("Bold")
                    }
                ]
            },
            "e4:background.widgets.clock.pixel.orientation": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Pixel clock"),
                title: Tr.mark("Direction"),
                desc: Tr.mark("Digits stacked or side by side"),
                keywords: [Tr.mark("pixel"), Tr.mark("clock"), Tr.mark("orientation"), Tr.mark("vertical"), Tr.mark("horizontal")],
                type: "enum",
                options: [
                    {
                        value: "vertical",
                        label: Tr.mark("Vertical")
                    },
                    {
                        value: "horizontal",
                        label: Tr.mark("Horizontal")
                    }
                ]
            },
            "e4:background.widgets.clock.color": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Digital and daily clocks"),
                title: Tr.mark("Text colour"),
                desc: Tr.mark("Automatic picks one that reads well on the wallpaper"),
                keywords: [Tr.mark("clock"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("text"), Tr.mark("theme")],
                type: "enum",
                options: root.colourOptions
            },
            "e4:background.widgets.clock.quote.enable": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Quote"),
                title: Tr.mark("Show a quote"),
                desc: Tr.mark("A line of your own text under the cookie, digital or pixel clock"),
                keywords: [Tr.mark("quote"), Tr.mark("text"), Tr.mark("clock"), Tr.mark("cookie")],
                type: "bool"
            },
            "e4:background.widgets.clock.quote.text": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Quote"),
                title: Tr.mark("Quote text"),
                desc: Tr.mark("What the line under the clock says"),
                keywords: [Tr.mark("quote"), Tr.mark("text"), Tr.mark("clock")],
                type: "string",
                requires: {
                    id: "e4:background.widgets.clock.quote.enable",
                    value: true
                }
            },
            // Advanced: the chosen clock's details
            "c:background.desktopClock.background.blur": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Blur behind the card"),
                desc: Tr.mark("Blurs the wallpaper under the clock's card. Off in game mode"),
                keywords: [Tr.mark("clock"), Tr.mark("blur"), Tr.mark("card"), Tr.mark("background"), Tr.mark("glass"), Tr.mark("caelestia")],
                type: "bool",
                advanced: true,
                requires: {
                    id: "c:background.desktopClock.background.enabled",
                    value: true
                }
            },
            "c:background.desktopClock.background.opacity": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Card opacity"),
                desc: Tr.mark("How solid the card behind the clock is"),
                keywords: [Tr.mark("clock"), Tr.mark("card"), Tr.mark("background"), Tr.mark("opacity"), Tr.mark("transparency"), Tr.mark("caelestia")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                advanced: true,
                requires: {
                    id: "c:background.desktopClock.background.enabled",
                    value: true
                }
            },
            "c:background.desktopClock.shadow.opacity": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Shadow strength"),
                desc: Tr.mark("How dark the shadow is"),
                keywords: [Tr.mark("clock"), Tr.mark("shadow"), Tr.mark("opacity"), Tr.mark("caelestia")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                advanced: true,
                requires: {
                    id: "c:background.desktopClock.shadow.enabled",
                    value: true
                }
            },
            "c:background.desktopClock.shadow.blur": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Shadow softness"),
                desc: Tr.mark("Higher spreads the shadow wider and softer"),
                keywords: [Tr.mark("clock"), Tr.mark("shadow"), Tr.mark("blur"), Tr.mark("soft"), Tr.mark("caelestia")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                advanced: true,
                requires: {
                    id: "c:background.desktopClock.shadow.enabled",
                    value: true
                }
            },
            "e4:background.widgets.clock.cookie.sides": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Bumps"),
                desc: Tr.mark("How many bumps the cookie shape has around its edge"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("sides"), Tr.mark("shape"), Tr.mark("bumps")],
                type: "int",
                min: 3,
                max: 40,
                step: 1,
                advanced: true
            },
            "e4:background.widgets.clock.cookie.useSineCookie": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Wavy edge"),
                desc: Tr.mark("Smooth waves instead of rounded bumps"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("sine"), Tr.mark("wave"), Tr.mark("shape")],
                type: "bool",
                advanced: true
            },
            "e4:background.widgets.clock.cookie.constantlyRotate": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Keep turning"),
                desc: Tr.mark("The cookie shape spins slowly and the second hand sweeps. Costs GPU all the time"),
                keywords: [Tr.mark("cookie"), Tr.mark("clock"), Tr.mark("rotate"), Tr.mark("spin"), Tr.mark("animation")],
                type: "bool",
                advanced: true
            },
            "e4:background.widgets.clock.digital.font.weight": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("Thin to bold; 400 is regular"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("font"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin")],
                type: "real",
                min: 100,
                max: 1000,
                step: 10,
                advanced: true
            },
            "e4:background.widgets.clock.digital.font.width": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Width"),
                desc: Tr.mark("Narrow to wide; 100 is normal. Only fonts with a width axis change"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("font"), Tr.mark("width"), Tr.mark("narrow"), Tr.mark("wide"), Tr.mark("wdth")],
                type: "real",
                min: 25,
                max: 150,
                step: 1,
                advanced: true
            },
            "e4:background.widgets.clock.digital.font.roundness": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Roundness"),
                desc: Tr.mark("Rounder letter ends. Only fonts with a roundness axis change, like Google Sans Flex"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("font"), Tr.mark("roundness"), Tr.mark("round"), Tr.mark("rond")],
                type: "real",
                min: 0,
                max: 100,
                step: 1,
                advanced: true
            },
            "e4:background.widgets.clock.digital.adaptiveAlignment": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Align to the side it's on"),
                desc: Tr.mark("Text lines up left near the left edge and right near the right edge. Off: always centred"),
                keywords: [Tr.mark("digital"), Tr.mark("clock"), Tr.mark("alignment"), Tr.mark("align"), Tr.mark("left"), Tr.mark("right")],
                type: "bool",
                advanced: true
            },
            "e4:background.widgets.clock.quote.followClock": {
                route: "appearance/desktop/widget.clock",
                section: Tr.mark("Font"),
                // caelestia4: ClockText.qml (every clock text: the daily clock, the date line, the status line) and
                // the quote read it, so it works with the quote off too: no `requires`. A look option, so not in
                // Advanced; the page shows the Font row under it while it is on
                title: Tr.mark("Same font for all text"),
                desc: Tr.mark("The clock's other text (date, quote, status line) uses the font below, not the usual one"),
                keywords: [Tr.mark("quote"), Tr.mark("font"), Tr.mark("clock"), Tr.mark("text"), Tr.mark("date"), Tr.mark("follow")],
                type: "bool"
            },

            // Desktop > Calendar (CalendarWidgetPage.qml)
            "e4:background.widgets.calendar.enable": {
                route: "appearance/desktop/widget.calendar",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A month calendar card"),
                keywords: [Tr.mark("calendar"), Tr.mark("widget"), Tr.mark("desktop"), Tr.mark("month"), Tr.mark("date")],
                type: "bool"
            },
            "e4:background.widgets.calendar.sizeMode": {
                route: "appearance/desktop/widget.calendar",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: root.sizeDesc,
                keywords: [Tr.mark("calendar"), Tr.mark("size"), Tr.mark("card"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "enum",
                options: root.sizeOptions(["1x1", "1x2", "2x2", "2x3"])
            },
            "e4:background.widgets.calendar.placementStrategy": {
                route: "appearance/desktop/widget.calendar",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("calendar"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > Picture (CustomImageWidgetPage.qml)
            "e4:background.widgets.customImage.enable": {
                route: "appearance/desktop/widget.customImage",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A picture of your own, cut to a shape"),
                keywords: [Tr.mark("picture"), Tr.mark("image"), Tr.mark("photo"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.customImage.path": {
                route: "appearance/desktop/widget.customImage",
                section: Tr.mark("General"),
                title: Tr.mark("Picture"),
                desc: Tr.mark("Or drop a picture file on the widget"),
                keywords: [Tr.mark("picture"), Tr.mark("image"), Tr.mark("photo"), Tr.mark("file"), Tr.mark("path")],
                type: "path",
                pathMode: "file",
                filters: ["png", "jpg", "jpeg", "webp", "avif", "bmp", "gif", "tiff", "tif"],
                thumbnail: true
            },
            "e4:background.widgets.customImage.size": {
                route: "appearance/desktop/widget.customImage",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: root.sizeDesc,
                keywords: [Tr.mark("picture"), Tr.mark("image"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "real",
                unit: "px",
                min: 80,
                max: 800,
                step: 10
            },
            "e4:background.widgets.customImage.placementStrategy": {
                route: "appearance/desktop/widget.customImage",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("picture"), Tr.mark("image"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.customImage.shape": {
                route: "appearance/desktop/widget.customImage",
                section: Tr.mark("Look"),
                title: Tr.mark("Shape"),
                desc: Tr.mark("The shape the picture is cut to"),
                keywords: [Tr.mark("picture"), Tr.mark("image"), Tr.mark("shape"), Tr.mark("mask"), Tr.mark("cookie"), Tr.mark("circle")],
                type: "enum",
                // pcwidgets/ShapeUtils.qml names,
                options: [root.shapeOption("Cookie4Sided", Tr.mark("Cookie, 4 sides")), root.shapeOption("Cookie6Sided", Tr.mark("Cookie, 6 sides")), root.shapeOption("Cookie7Sided", Tr.mark("Cookie, 7 sides")), root.shapeOption("Cookie9Sided", Tr.mark("Cookie, 9 sides")), root.shapeOption("Cookie12Sided", Tr.mark("Cookie, 12 sides")), root.shapeOption("Circle", Tr.mark("Circle")), root.shapeOption("Square", Tr.mark("Square")), root.shapeOption("Oval", Tr.mark("Oval")), root.shapeOption("Pill", Tr.mark("Pill")), root.shapeOption("SemiCircle", Tr.mark("Half circle")), root.shapeOption("Arch", Tr.mark("Arch")), root.shapeOption("Slanted", Tr.mark("Slanted")), root.shapeOption("Fan", Tr.mark("Fan")), root.shapeOption("Arrow", Tr.mark("Arrow")), root.shapeOption("Triangle", Tr.mark("Triangle")), root.shapeOption("Diamond", Tr.mark("Diamond")), root.shapeOption("PuffyDiamond", Tr.mark("Puffy diamond")), root.shapeOption("Pentagon", Tr.mark("Pentagon")), root.shapeOption("Gem", Tr.mark("Gem")), root.shapeOption("ClamShell", Tr.mark("Clam shell")), root.shapeOption("Sunny", Tr.mark("Sun")), root.shapeOption("VerySunny", Tr.mark("Big sun")), root.shapeOption("Burst", Tr.mark("Burst")), root.shapeOption("SoftBurst", Tr.mark("Soft burst")), root.shapeOption("Boom", Tr.mark("Boom")), root.shapeOption("SoftBoom", Tr.mark("Soft boom")), root.shapeOption("Flower", Tr.mark("Flower")), root.shapeOption("Clover4Leaf", Tr.mark("Clover, 4 leaves")), root.shapeOption("Clover8Leaf", Tr.mark("Clover, 8 leaves")), root.shapeOption("Puffy", Tr.mark("Cloud")), root.shapeOption("Ghostish", Tr.mark("Ghost")), root.shapeOption("Bun", Tr.mark("Bun")), root.shapeOption("Heart", Tr.mark("Heart")), root.shapeOption("PixelCircle", Tr.mark("Pixel circle")), root.shapeOption("PixelTriangle", Tr.mark("Pixel triangle"))]
            },

            // Desktop > Text (CustomTextWidgetPage.qml)
            "e4:background.widgets.customText.enable": {
                route: "appearance/desktop/widget.customText",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A line or two of your own text. Double-click it on the desktop to edit"),
                keywords: [Tr.mark("text"), Tr.mark("note"), Tr.mark("words"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.customText.content": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("General"),
                title: Tr.mark("Text"),
                desc: Tr.mark("What the widget says"),
                keywords: [Tr.mark("text"), Tr.mark("content"), Tr.mark("words"), Tr.mark("message")],
                type: "string"
            },
            "e4:background.widgets.customText.fontSize": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: root.sizeDesc,
                keywords: [Tr.mark("text"), Tr.mark("font"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                unit: "px",
                min: 12,
                max: 400,
                step: 4
            },
            "e4:background.widgets.customText.placementStrategy": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("text"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.customText.fontFamily": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("Look"),
                title: Tr.mark("Font"),
                keywords: [Tr.mark("text"), Tr.mark("font"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "e4:background.widgets.customText.color": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("Look"),
                title: Tr.mark("Text colour"),
                desc: Tr.mark("Automatic picks one that reads well on the wallpaper"),
                keywords: [Tr.mark("text"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("theme")],
                type: "enum",
                options: root.colourOptions.concat([
                    {
                        value: "black",
                        label: Tr.mark("Black")
                    }
                ])
            },
            "e4:background.widgets.customText.alignment": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("Look"),
                title: Tr.mark("Alignment"),
                desc: Tr.mark("How lines line up when there are several"),
                keywords: [Tr.mark("text"), Tr.mark("alignment"), Tr.mark("align"), Tr.mark("left"), Tr.mark("right"), Tr.mark("centre"), Tr.mark("center")],
                type: "enum",
                options: [
                    {
                        value: "left",
                        label: Tr.mark("Left")
                    },
                    {
                        value: "center",
                        label: Tr.mark("Centre")
                    },
                    {
                        value: "right",
                        label: Tr.mark("Right")
                    }
                ]
            },
            "e4:background.widgets.customText.shadow": {
                route: "appearance/desktop/widget.customText",
                section: Tr.mark("Look"),
                title: Tr.mark("Shadow"),
                desc: Tr.mark("A soft shadow under the text, easier to read on busy wallpapers"),
                keywords: [Tr.mark("text"), Tr.mark("shadow"), Tr.mark("readability")],
                type: "bool"
            },

            // Desktop > Picture card (ImageCardWidgetPage.qml)
            "e4:background.widgets.imageCard.enable": {
                route: "appearance/desktop/widget.imageCard",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A picture in a rounded card, like the other widgets"),
                keywords: [Tr.mark("picture"), Tr.mark("card"), Tr.mark("image"), Tr.mark("photo"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.imageCard.path": {
                route: "appearance/desktop/widget.imageCard",
                section: Tr.mark("General"),
                title: Tr.mark("Picture"),
                desc: Tr.mark("Or drop a picture file on the card"),
                keywords: [Tr.mark("picture"), Tr.mark("card"), Tr.mark("image"), Tr.mark("photo"), Tr.mark("file"), Tr.mark("path")],
                type: "path",
                pathMode: "file",
                filters: ["png", "jpg", "jpeg", "webp", "avif", "bmp", "gif", "tiff", "tif"],
                thumbnail: true
            },
            "e4:background.widgets.imageCard.sizeMode": {
                route: "appearance/desktop/widget.imageCard",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: root.sizeDesc,
                keywords: [Tr.mark("picture"), Tr.mark("card"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "enum",
                options: root.sizeOptions(["1x1", "1x2", "1x3", "2x2", "2x3"])
            },
            "e4:background.widgets.imageCard.placementStrategy": {
                route: "appearance/desktop/widget.imageCard",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("picture"), Tr.mark("card"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > Image converter (ImagesWidgetPage.qml)
            "e4:background.widgets.images.enable": {
                route: "appearance/desktop/widget.images",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("Drop pictures on it to convert them to another format, or to one PDF"),
                keywords: [Tr.mark("image"), Tr.mark("converter"), Tr.mark("convert"), Tr.mark("pdf"), Tr.mark("webp"), Tr.mark("imagemagick"), Tr.mark("widget")],
                type: "bool"
            },
            "e4:background.widgets.images.placementStrategy": {
                route: "appearance/desktop/widget.images",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("image"), Tr.mark("converter"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > Media player (MediaWidgetPage.qml)
            "e4:background.widgets.media.enable": {
                route: "appearance/desktop/widget.media",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("The song playing, its cover and controls"),
                keywords: [Tr.mark("media"), Tr.mark("music"), Tr.mark("player"), Tr.mark("song"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.media.sizeMode": {
                route: "appearance/desktop/widget.media",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: root.sizeDesc,
                keywords: [Tr.mark("media"), Tr.mark("music"), Tr.mark("player"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "enum",
                options: root.sizeOptions(["1x1", "1x2", "1x3", "2x2", "2x3"])
            },
            "e4:background.widgets.media.placementStrategy": {
                route: "appearance/desktop/widget.media",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("media"), Tr.mark("music"), Tr.mark("player"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > Notes (NotesWidgetPage.qml)
            "e4:background.widgets.notes.enable": {
                route: "appearance/desktop/widget.notes",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A sticky note to type in"),
                keywords: [Tr.mark("notes"), Tr.mark("note"), Tr.mark("sticky"), Tr.mark("memo"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.notes.placementStrategy": {
                route: "appearance/desktop/widget.notes",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("notes"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > System resources (ResourcesWidgetPage.qml)
            "e4:background.widgets.resources.enable": {
                route: "appearance/desktop/widget.resources",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("Processor, memory and disk use"),
                keywords: [Tr.mark("resources"), Tr.mark("cpu"), Tr.mark("memory"), Tr.mark("ram"), Tr.mark("disk"), Tr.mark("usage"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.resources.placementStrategy": {
                route: "appearance/desktop/widget.resources",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("resources"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.resources.vertical": {
                route: "appearance/desktop/widget.resources",
                section: Tr.mark("General"),
                title: Tr.mark("Stacked"),
                desc: Tr.mark("One above the other instead of side by side. The widget's own button switches it too"),
                keywords: [Tr.mark("resources"), Tr.mark("vertical"), Tr.mark("stacked"), Tr.mark("layout")],
                type: "bool"
            }
        })
}
