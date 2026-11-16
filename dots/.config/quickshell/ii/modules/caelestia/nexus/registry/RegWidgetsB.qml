import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the desktop widget sub-pages sticker, timers, todo, userCard, visualizer, weather and worldClock (routes appearance/desktop/widget.<w>) (merged by Registry.qml). See RegPanels.qml for the format.
// Owned by the widgetsB group; filled in P5. The widgets' on/off rows write through PresetLayout (the pages do it)
QtObject {
    id: root

    // Every widget's placement, as RegWidgetsA's
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
    readonly property var pictureFilters: ["png", "jpg", "jpeg", "webp", "svg", "gif"]

    readonly property var entries: ({
            // Desktop > Sticker (pages/wallandstyle/widgets/StickerWidgetPage.qml)
            "e4:background.widgets.sticker.enable": {
                route: "appearance/desktop/widget.sticker",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("A cut-out picture with an outline"),
                keywords: [Tr.mark("sticker"), Tr.mark("widget"), Tr.mark("desktop"), Tr.mark("show"), Tr.mark("enable")],
                type: "bool"
            },
            "e4:background.widgets.sticker.path": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("General"),
                title: Tr.mark("Picture"),
                desc: Tr.mark("A PNG, SVG, WebP or GIF. You can also drop one on the sticker"),
                keywords: [Tr.mark("sticker"), Tr.mark("picture"), Tr.mark("image"), Tr.mark("file"), Tr.mark("png")],
                type: "path",
                pathMode: "file",
                filters: ["png", "svg", "webp", "gif"],
                thumbnail: true
            },
            "e4:background.widgets.sticker.size": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("How big the sticker is. You can also drag its corner"),
                keywords: [Tr.mark("sticker"), Tr.mark("size"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "real",
                unit: "px",
                min: 60,
                max: 800,
                step: 10
            },
            "e4:background.widgets.sticker.placementStrategy": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("sticker"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.sticker.rotation": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("Look"),
                title: Tr.mark("Rotation"),
                desc: Tr.mark("Clockwise. Double-click the sticker to straighten it"),
                keywords: [Tr.mark("sticker"), Tr.mark("rotation"), Tr.mark("rotate"), Tr.mark("angle"), Tr.mark("tilt")],
                type: "real",
                // caelestia4: degrees. The page's slider shows "45°"; search, reset and undo show it once the shared
                // formatters (RowSetting.format, SearchIndex) know "°"
                unit: "°",
                min: -180,
                max: 180,
                step: 5
            },
            "e4:background.widgets.sticker.outlineColor": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("Look"),
                title: Tr.mark("Outline colour"),
                desc: Tr.mark("The line around the cut-out"),
                keywords: [Tr.mark("sticker"), Tr.mark("outline"), Tr.mark("border"), Tr.mark("colour"), Tr.mark("color")],
                type: "colour"
            },
            "e4:background.widgets.sticker.outlineWidth": {
                route: "appearance/desktop/widget.sticker",
                section: Tr.mark("Look"),
                title: Tr.mark("Outline width"),
                desc: Tr.mark("0 for no outline"),
                keywords: [Tr.mark("sticker"), Tr.mark("outline"), Tr.mark("border"), Tr.mark("width"), Tr.mark("thickness")],
                type: "real",
                unit: "px",
                min: 0,
                max: 24,
                step: 1
            },

            // Desktop > Timers (pages/wallandstyle/widgets/TimersWidgetPage.qml)
            "e4:background.widgets.timers.enable": {
                route: "appearance/desktop/widget.timers",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("Pomodoro, countdown and stopwatch cards"),
                keywords: [Tr.mark("timers"), Tr.mark("timer"), Tr.mark("pomodoro"), Tr.mark("stopwatch"), Tr.mark("countdown"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.timers.placementStrategy": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("timers"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.timers.vertical": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("General"),
                title: Tr.mark("Stacked"),
                desc: Tr.mark("The cards one above the other. The arrow on the widget switches it too"),
                keywords: [Tr.mark("timers"), Tr.mark("vertical"), Tr.mark("stacked"), Tr.mark("layout")],
                type: "bool"
            },
            "e4:time.pomodoro.focus": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("Pomodoro"),
                title: Tr.mark("Focus"),
                desc: Tr.mark("How long each focus round lasts, here and on the dashboard"),
                keywords: [Tr.mark("pomodoro"), Tr.mark("focus"), Tr.mark("work"), Tr.mark("timer"), Tr.mark("length")],
                type: "duration",
                unit: "s",
                min: 60,
                max: 7200,
                step: 60
            },
            "e4:time.pomodoro.breakTime": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("Pomodoro"),
                title: Tr.mark("Short break"),
                desc: Tr.mark("The break after each focus round"),
                keywords: [Tr.mark("pomodoro"), Tr.mark("break"), Tr.mark("rest"), Tr.mark("timer")],
                type: "duration",
                unit: "s",
                min: 60,
                max: 3600,
                step: 60
            },
            "e4:time.pomodoro.longBreak": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("Pomodoro"),
                title: Tr.mark("Long break"),
                desc: Tr.mark("The longer break after several focus rounds"),
                keywords: [Tr.mark("pomodoro"), Tr.mark("long"), Tr.mark("break"), Tr.mark("rest"), Tr.mark("timer")],
                type: "duration",
                unit: "s",
                min: 60,
                max: 7200,
                step: 60
            },
            "e4:time.pomodoro.cyclesBeforeLongBreak": {
                route: "appearance/desktop/widget.timers",
                section: Tr.mark("Pomodoro"),
                title: Tr.mark("Rounds before a long break"),
                desc: Tr.mark("Focus rounds until the long break"),
                keywords: [Tr.mark("pomodoro"), Tr.mark("cycles"), Tr.mark("rounds"), Tr.mark("long"), Tr.mark("break")],
                type: "int",
                min: 1,
                max: 10,
                step: 1
            },

            // Desktop > To-do list (pages/wallandstyle/widgets/TodoWidgetPage.qml)
            "e4:background.widgets.todo.enable": {
                route: "appearance/desktop/widget.todo",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("Your to-do list on the wallpaper"),
                keywords: [Tr.mark("todo"), Tr.mark("to-do"), Tr.mark("tasks"), Tr.mark("list"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.todo.placementStrategy": {
                route: "appearance/desktop/widget.todo",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("todo"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },

            // Desktop > User card (pages/wallandstyle/widgets/UserCardWidgetPage.qml)
            "e4:background.widgets.userCard.enable": {
                route: "appearance/desktop/widget.userCard",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("Your picture and name on a card"),
                keywords: [Tr.mark("user"), Tr.mark("card"), Tr.mark("profile"), Tr.mark("avatar"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.userCard.sizeMode": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("You can also drag its corner on the desktop"),
                keywords: [Tr.mark("user"), Tr.mark("card"), Tr.mark("size"), Tr.mark("resize")],
                type: "enum",
                options: [
                    {
                        value: "1x1",
                        label: Tr.mark("Small")
                    },
                    {
                        value: "1x2",
                        label: Tr.mark("Wide")
                    },
                    {
                        value: "2x2",
                        label: Tr.mark("Large")
                    },
                    {
                        value: "2x3",
                        label: Tr.mark("Extra large")
                    }
                ]
            },
            "e4:background.widgets.userCard.placementStrategy": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("user"), Tr.mark("card"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:profile.displayName": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("Profile"),
                title: Tr.mark("Name"),
                desc: Tr.mark("Shown on the card. Empty: your user name"),
                keywords: [Tr.mark("name"), Tr.mark("display"), Tr.mark("user"), Tr.mark("profile")],
                type: "string"
            },
            "e4:profile.avatarPicture": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("Profile"),
                title: Tr.mark("Picture"),
                desc: Tr.mark("Empty: ~/.face, the picture other apps use too"),
                keywords: [Tr.mark("avatar"), Tr.mark("picture"), Tr.mark("photo"), Tr.mark("face"), Tr.mark("profile")],
                type: "path",
                pathMode: "file",
                filters: root.pictureFilters,
                thumbnail: true
            },
            "e4:sidebar.bannerImage": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("Profile"),
                title: Tr.mark("Banner"),
                desc: Tr.mark("The picture across the top of the extra large card. Empty: the wallpaper"),
                keywords: [Tr.mark("banner"), Tr.mark("header"), Tr.mark("picture"), Tr.mark("user"), Tr.mark("card")],
                type: "path",
                pathMode: "file",
                filters: root.pictureFilters,
                thumbnail: true
            },
            "e4:profile.avatarPath": {
                route: "appearance/desktop/widget.userCard",
                section: Tr.mark("Profile"),
                title: Tr.mark("Turn on the picture"),
                desc: Tr.mark("Your picture shows only once this is set too. Pick the same file here"),
                keywords: [Tr.mark("avatar"), Tr.mark("picture"), Tr.mark("original"), Tr.mark("source"), Tr.mark("profile")],
                type: "path",
                pathMode: "file",
                filters: root.pictureFilters
            },

            // Desktop > Audio visualiser (pages/wallandstyle/widgets/VisualizerWidgetPage.qml). x:desktop.visualiser.show
            // (on/off) and x:desktop.visualiser (style) stand for Caelestia's own on/off and end-4's widget on/off and
            // style together (one visualiser on the desktop)
            "x:desktop.visualiser.show": {
                route: "appearance/desktop/widget.visualizer",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("One visualiser at a time, in the style below"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("audio"), Tr.mark("music"), Tr.mark("desktop"), Tr.mark("show")],
                type: "bool"
            },
            "x:desktop.visualiser": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("General"),
                title: Tr.mark("Style"),
                desc: Tr.mark("Caelestia's bars or one of end-4's"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("audio"), Tr.mark("music"), Tr.mark("bars"), Tr.mark("cava"), Tr.mark("spectrum")],
                type: "enum",
                options: [
                    {
                        value: "caelestia",
                        label: "Caelestia"
                    },
                    {
                        value: "bars",
                        label: Tr.mark("Bars")
                    },
                    {
                        value: "mirror",
                        label: Tr.mark("Mirror")
                    },
                    {
                        value: "aurora",
                        label: Tr.mark("Aurora")
                    },
                    {
                        value: "dots",
                        label: Tr.mark("Dots")
                    },
                    {
                        value: "ring",
                        label: Tr.mark("Ring")
                    }
                ]
            },
            "e4:background.widgets.visualizer.enable": {
                route: "appearance/desktop/widget.visualizer",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("end-4's visualiser. Turning it on turns Caelestia's off"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("audio"), Tr.mark("music"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool",
                shownBy: "x:desktop.visualiser.show"
            },
            "e4:background.widgets.visualizer.style": {
                route: "appearance/desktop/widget.visualizer",
                title: Tr.mark("Style"),
                desc: Tr.mark("The ring sits anywhere; the others run along the bottom of the screen"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("style"), Tr.mark("bars"), Tr.mark("mirror"), Tr.mark("aurora"), Tr.mark("ring"), Tr.mark("dots")],
                type: "enum",
                options: [
                    {
                        value: "bars",
                        label: Tr.mark("Bars")
                    },
                    {
                        value: "mirror",
                        label: Tr.mark("Mirror")
                    },
                    {
                        value: "aurora",
                        label: Tr.mark("Aurora")
                    },
                    {
                        value: "dots",
                        label: Tr.mark("Dots")
                    },
                    {
                        value: "ring",
                        label: Tr.mark("Ring")
                    }
                ],
                shownBy: "x:desktop.visualiser"
            },
            "e4:background.widgets.visualizer.placementStrategy": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("ring"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions,
                requires: {
                    id: "e4:background.widgets.visualizer.style",
                    value: "ring"
                }
            },
            "e4:background.widgets.visualizer.ringSize": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("How wide the ring is. You can also drag its corner"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("ring"), Tr.mark("size")],
                type: "int",
                unit: "px",
                min: 200,
                max: 900,
                step: 10
            },
            "e4:background.widgets.visualizer.height": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("How tall the visualiser is"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("height"), Tr.mark("size")],
                type: "int",
                unit: "px",
                min: 80,
                max: 600,
                step: 10
            },
            "e4:background.widgets.visualizer.colorSource": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Look"),
                title: Tr.mark("Colours"),
                desc: Tr.mark("The theme's colours or the album cover's"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("album"), Tr.mark("cover")],
                type: "enum",
                options: [
                    {
                        value: "theme",
                        label: Tr.mark("Theme")
                    },
                    {
                        value: "cover",
                        label: Tr.mark("Album cover")
                    }
                ]
            },
            "e4:background.widgets.visualizer.sensitivity": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Look"),
                title: Tr.mark("Sensitivity"),
                desc: Tr.mark("Higher makes quiet music move it more"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("sensitivity"), Tr.mark("gain")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.3,
                max: 3,
                step: 0.05
            },
            "c:background.visualiser.autoHide": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Caelestia's visualiser"),
                title: Tr.mark("Only on empty desktops"),
                desc: Tr.mark("Hidden while tiled windows cover the workspace"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("hide"), Tr.mark("windows"), Tr.mark("empty")],
                type: "bool"
            },
            "c:background.visualiser.blur": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Caelestia's visualiser"),
                title: Tr.mark("Blur behind the bars"),
                desc: Tr.mark("Costs GPU on every frame while music plays"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("blur"), Tr.mark("glass")],
                type: "bool"
            },
            "c:background.visualiser.rounding": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Bar roundness"),
                desc: Tr.mark("0 gives square bars"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("rounding"), Tr.mark("corners")],
                type: "real",
                min: 0,
                max: 3,
                step: 0.1,
                advanced: true
            },
            "c:background.visualiser.spacing": {
                route: "appearance/desktop/widget.visualizer",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Gap between bars"),
                desc: Tr.mark("Space between the visualiser's bars"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("spacing"), Tr.mark("gap")],
                type: "real",
                min: 0,
                max: 4,
                step: 0.1,
                advanced: true
            },

            // Desktop > Weather (pages/wallandstyle/widgets/WeatherWidgetPage.qml)
            "e4:background.widgets.weather.enable": {
                route: "appearance/desktop/widget.weather",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("end-4's weather card, separate from the clock"),
                keywords: [Tr.mark("weather"), Tr.mark("forecast"), Tr.mark("temperature"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.weather.sizeMode": {
                route: "appearance/desktop/widget.weather",
                section: Tr.mark("General"),
                title: Tr.mark("Size"),
                desc: Tr.mark("You can also drag its corner on the desktop"),
                keywords: [Tr.mark("weather"), Tr.mark("card"), Tr.mark("size"), Tr.mark("resize")],
                type: "enum",
                options: [
                    {
                        value: "1x1",
                        label: Tr.mark("Small")
                    },
                    {
                        value: "1x2",
                        label: Tr.mark("Wide")
                    },
                    {
                        value: "1x3",
                        label: Tr.mark("Extra wide")
                    },
                    {
                        value: "2x2",
                        label: Tr.mark("Large")
                    },
                    {
                        value: "2x3",
                        label: Tr.mark("Extra large")
                    }
                ]
            },
            "e4:background.widgets.weather.placementStrategy": {
                route: "appearance/desktop/widget.weather",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: Tr.mark("Free: drag it on the desktop. Otherwise it moves to the calmest (or busiest) part of the wallpaper"),
                keywords: [Tr.mark("weather"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("widget")],
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

            // Desktop > World clock (pages/wallandstyle/widgets/WorldClockWidgetPage.qml)
            "e4:background.widgets.worldClock.enable": {
                route: "appearance/desktop/widget.worldClock",
                title: Tr.mark("Show on the desktop"),
                desc: Tr.mark("The time in other places"),
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("time"), Tr.mark("zone"), Tr.mark("widget"), Tr.mark("desktop")],
                type: "bool"
            },
            "e4:background.widgets.worldClock.sizeMode": {
                route: "appearance/desktop/widget.worldClock",
                section: Tr.mark("General"),
                // caelestia4: titled Size like every other widget's sizeMode (R6); the options say the shape
                title: Tr.mark("Size"),
                desc: Tr.mark("A square card, or a wide row of clocks. You can also drag its corner on the desktop"),
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("size"), Tr.mark("layout"), Tr.mark("row")],
                type: "enum",
                options: [
                    {
                        value: "2x2",
                        label: Tr.mark("Square")
                    },
                    {
                        value: "4x1",
                        label: Tr.mark("In a row")
                    }
                ]
            },
            "e4:background.widgets.worldClock.placementStrategy": {
                route: "appearance/desktop/widget.worldClock",
                section: Tr.mark("General"),
                title: Tr.mark("Placement"),
                desc: root.placementDesc,
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("placement"), Tr.mark("position"), Tr.mark("auto"), Tr.mark("drag")],
                type: "enum",
                options: root.placementOptions
            },
            "e4:background.widgets.worldClock.vertical": {
                route: "appearance/desktop/widget.worldClock",
                section: Tr.mark("General"),
                title: Tr.mark("Stacked"),
                desc: Tr.mark("The clocks one above the other. The arrow on the widget switches it too"),
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("vertical"), Tr.mark("stacked"), Tr.mark("layout")],
                type: "bool",
                requires: {
                    id: "e4:background.widgets.worldClock.sizeMode",
                    value: "4x1"
                }
            },
            "e4:background.widgets.worldClock.timezones": {
                route: "appearance/desktop/widget.worldClock",
                section: Tr.mark("Clocks"),
                title: Tr.mark("Time zones"),
                desc: Tr.mark("One per clock, such as Europe/London. The widget's own settings can pick them too"),
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("time"), Tr.mark("zone"), Tr.mark("timezone"), Tr.mark("city")],
                type: "list"
            },
            "e4:background.widgets.worldClock.clockCount": {
                route: "appearance/desktop/widget.worldClock",
                section: Tr.mark("Clocks"),
                title: Tr.mark("Number of clocks"),
                desc: Tr.mark("How many time zones it shows, from the list above"),
                keywords: [Tr.mark("world"), Tr.mark("clock"), Tr.mark("count"), Tr.mark("number")],
                type: "int",
                min: 1,
                max: 4,
                step: 1
            }
        })
}
