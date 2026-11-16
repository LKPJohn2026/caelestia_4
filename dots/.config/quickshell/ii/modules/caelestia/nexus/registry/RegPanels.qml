import QtQuick
import Caelestia.Config
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "panels" page (merged by Registry.qml).
// Format, one entry per setting id ("c:" shell.json, "e4:" end-4 config.json, "h:" Hyprland option, "x:" custom):
//   route     the page route the row lives on (NexusState.navigate takes it), required
//   title     Tr.mark / Tr.markCtx string (rows show Tr.tr(title)), required
//   section   Tr.mark string of the SectionHeader above the row, if any
//   desc      Tr.mark string shown under the title
//   keywords  plain English search words
//   type      "bool" | "int" | "real" | "string" | "enum" | "list" | "path" | "font" | "colour" | "duration"
//   unit      "ms" | "s" | "min" | "%" | "px" | "K"        min, max, step: for int/real
//   options   [{ value, label: Tr.mark(...) }] for enum
//   applies   "now" (default) | "nextLock" | "appRestart" | "relogin" | "rebuild"
//   advanced  true when the row sits in an "Advanced" section
//   validate  a regexp string a text field's value must match
//   requires  { id, value }: the row is disabled unless that setting holds that value
//   default   overrides the computed default (needed for "h:" ids, which have none)
// A store id whose row cannot take `setting` (a list editor) still gets an entry: search finds it and the page's Reset
// page resets it. A value the row shows transformed (a fraction as a percent, a list as one line) is an x: id instead.
// Keep the entries in the order the rows appear on the page: Registry.idsForRoute returns them in this order.
QtObject {
    readonly property var entries: ({
            // Panels > Dashboard (pages/panels/DashboardPanel.qml)
            "c:dashboard.enabled": {
                route: "panels/dashboard",
                section: Tr.mark("General"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Show the dashboard panel"),
                keywords: [Tr.mark("dashboard"), Tr.mark("enable"), Tr.mark("panel"), Tr.mark("top")],
                type: "bool"
            },
            "c:dashboard.showOnHover": {
                route: "panels/dashboard",
                section: Tr.mark("General"),
                title: Tr.mark("Show on hover"),
                desc: Tr.mark("Reveal when the cursor reaches the screen edge"),
                keywords: [Tr.mark("dashboard"), Tr.mark("hover"), Tr.mark("edge"), Tr.mark("reveal")],
                type: "bool",
                // caelestia4: with presets on, the top edge opens no dashboard (drawers/Interactions.qml)
                requires: {
                    id: "e4:background.presetsEnabled",
                    value: false
                }
            },
            "c:dashboard.showClockSeconds": {
                route: "panels/dashboard",
                section: Tr.mark("General"),
                title: Tr.mark("Show clock seconds"),
                desc: Tr.mark("Display seconds for the clock in the main panel"),
                keywords: [Tr.mark("dashboard"), Tr.mark("clock"), Tr.mark("seconds"), Tr.mark("time")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            // caelestia4: drawers/Interactions.qml: a drag down from the top edge opens it, a drag up closes it
            "c:dashboard.dragThreshold": {
                route: "panels/dashboard",
                section: Tr.mark("General"),
                title: Tr.mark("Drag threshold"),
                desc: Tr.mark("How far to drag down from the top edge to open the dashboard, or up to close it"),
                keywords: [Tr.mark("dashboard"), Tr.mark("drag"), Tr.mark("swipe"), Tr.mark("threshold")],
                type: "int",
                unit: "px",
                min: 0,
                max: 200,
                step: 5,
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:dashboard.showDashboard": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("Dashboard"),
                desc: Tr.mark("Show the main tab with the clock, calendar and media"),
                keywords: [Tr.mark("dashboard"), Tr.mark("tab"), Tr.mark("home"), Tr.mark("calendar")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:dashboard.showMedia": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("Media"),
                desc: Tr.mark("Show the media player tab"),
                keywords: [Tr.mark("dashboard"), Tr.mark("tab"), Tr.mark("media"), Tr.mark("music"), Tr.mark("player")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:dashboard.showPerformance": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("Performance"),
                desc: Tr.mark("Show the tab with CPU, memory and other resource use"),
                keywords: [Tr.mark("dashboard"), Tr.mark("tab"), Tr.mark("performance"), Tr.mark("resources"), Tr.mark("system monitor")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:dashboard.showWeather": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("Weather"),
                desc: Tr.mark("Show the weather forecast tab"),
                keywords: [Tr.mark("dashboard"), Tr.mark("tab"), Tr.mark("weather"), Tr.mark("forecast")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "e4:caelestia.dashboardTodo": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("To-do"),
                desc: Tr.mark("Show the to-do list tab"),
                keywords: [Tr.mark("dashboard"), Tr.mark("todo"), Tr.mark("tasks"), Tr.mark("list")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "e4:caelestia.dashboardTimer": {
                route: "panels/dashboard",
                section: Tr.mark("Tabs"),
                title: Tr.mark("Timer"),
                desc: Tr.mark("Show the Pomodoro and stopwatch tab"),
                keywords: [Tr.mark("dashboard"), Tr.mark("timer"), Tr.mark("pomodoro"), Tr.mark("stopwatch")],
                type: "bool",
                requires: {
                    id: "c:dashboard.enabled",
                    value: true
                }
            },
            "c:dashboard.performance.showBattery": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("Battery"),
                desc: Tr.mark("Battery charge and time left"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("battery"), Tr.mark("power")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },
            "c:dashboard.performance.showGpu": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("GPU"),
                desc: Tr.mark("Graphics card use and temperature"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("gpu"), Tr.mark("graphics"), Tr.mark("temperature")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },
            "c:dashboard.performance.showCpu": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("CPU"),
                desc: Tr.mark("Processor use and temperature"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("cpu"), Tr.mark("processor"), Tr.mark("temperature")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },
            "c:dashboard.performance.showMemory": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("Memory"),
                desc: Tr.mark("RAM in use"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("memory"), Tr.mark("ram")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },
            "c:dashboard.performance.showStorage": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("Storage"),
                desc: Tr.mark("Disk space in use"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("storage"), Tr.mark("disk"), Tr.mark("space")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },
            "c:dashboard.performance.showNetwork": {
                route: "panels/dashboard",
                section: Tr.mark("Performance widgets"),
                title: Tr.mark("Network"),
                desc: Tr.mark("Download and upload speed"),
                keywords: [Tr.mark("dashboard"), Tr.mark("performance"), Tr.mark("network"), Tr.mark("speed"), Tr.mark("traffic"), Tr.mark("bandwidth")],
                type: "bool",
                requires: {
                    id: "c:dashboard.showPerformance",
                    value: true
                }
            },

            // Panels > Taskbar (pages/panels/TaskbarPanel.qml)
            "c:bar.persistent": {
                route: "panels/taskbar",
                section: Tr.mark("Behaviour"),
                title: Tr.mark("Persistent"),
                desc: Tr.mark("Keep the bar visible at all times"),
                keywords: [Tr.mark("bar"), Tr.mark("taskbar"), Tr.mark("always"), Tr.mark("visible"), Tr.mark("autohide")],
                type: "bool"
            },
            "c:bar.showOnHover": {
                route: "panels/taskbar",
                section: Tr.mark("Behaviour"),
                title: Tr.mark("Show on hover"),
                desc: Tr.mark("Reveal the bar when the cursor reaches the screen edge"),
                keywords: [Tr.mark("bar"), Tr.mark("taskbar"), Tr.mark("hover"), Tr.mark("edge"), Tr.mark("reveal")],
                type: "bool"
            },
            "c:bar.dragThreshold": {
                route: "panels/taskbar",
                section: Tr.mark("Behaviour"),
                title: Tr.mark("Drag threshold"),
                desc: Tr.mark("How far to drag right from the left edge to show the bar, or left to hide it"),
                keywords: [Tr.mark("bar"), Tr.mark("taskbar"), Tr.mark("drag"), Tr.mark("swipe"), Tr.mark("threshold")],
                type: "int",
                unit: "px",
                min: 0,
                max: 200,
                step: 5
            },
            // caelestia4: names are regexes (Strings.testRegexList, bar/BarWrapper.qml); the page offers the connected
            // screens and keeps typed ones
            "c:bar.excludedScreens": {
                route: "panels/taskbar",
                section: Tr.mark("Behaviour"),
                title: Tr.mark("Screens without a bar"),
                desc: Tr.mark("The bar is not shown on these screens"),
                keywords: [Tr.mark("bar"), Tr.mark("taskbar"), Tr.mark("screen"), Tr.mark("monitor"), Tr.mark("display"), Tr.mark("exclude"), Tr.mark("hide")],
                type: "list"
            },
            // caelestia4: drawers/ContentWindow.qml puts the panels on the overlay layer while a window is fullscreen.
            // Not a taskbar thing: on the Panels page (all panels)
            "c:general.showOverFullscreen": {
                route: "panels",
                section: Tr.mark("General"),
                title: Tr.mark("Panels over fullscreen"),
                desc: Tr.mark("Panels you open (launcher, dashboard…) show above fullscreen windows instead of behind them"),
                keywords: [Tr.mark("bar"), Tr.mark("panels"), Tr.mark("fullscreen"), Tr.mark("overlay"), Tr.mark("game"), Tr.mark("video"), Tr.mark("above")],
                type: "bool"
            },
            // caelestia4: utils/SysInfo.qml: "caelestia", an icon name or an image path; empty = the distro's logo
            "c:general.logo": {
                route: "panels",
                section: Tr.mark("General"),
                title: Tr.mark("Logo"),
                desc: Tr.mark("Shown in the bar and the dashboard. “caelestia”, an icon name or an image; empty uses your distro's logo"),
                keywords: [Tr.mark("logo"), Tr.mark("os"), Tr.mark("distro"), Tr.mark("icon"), Tr.mark("bar"), Tr.mark("dashboard"), Tr.mark("image"), Tr.mark("arch")],
                type: "path",
                pathMode: "file",
                filters: ["png", "svg", "jpg", "jpeg", "webp"]
            },
            "c:bar.scrollActions.workspaces": {
                route: "panels/taskbar",
                section: Tr.mark("Scroll actions"),
                title: Tr.mark("Workspaces"),
                desc: Tr.mark("Scroll over the workspace indicator to switch workspaces"),
                keywords: [Tr.mark("bar"), Tr.mark("scroll"), Tr.mark("wheel"), Tr.mark("workspaces")],
                type: "bool"
            },
            "c:bar.scrollActions.volume": {
                route: "panels/taskbar",
                section: Tr.mark("Scroll actions"),
                title: Tr.mark("Volume"),
                desc: Tr.mark("Scroll on the top half of the bar to adjust volume"),
                keywords: [Tr.mark("bar"), Tr.mark("scroll"), Tr.mark("wheel"), Tr.mark("volume"), Tr.mark("sound")],
                type: "bool"
            },
            "c:bar.scrollActions.brightness": {
                route: "panels/taskbar",
                section: Tr.mark("Scroll actions"),
                title: Tr.mark("Brightness"),
                desc: Tr.mark("Scroll on the bottom half of the bar to adjust brightness"),
                keywords: [Tr.mark("bar"), Tr.mark("scroll"), Tr.mark("wheel"), Tr.mark("brightness"), Tr.mark("screen")],
                type: "bool"
            },

            // Panels > Taskbar > Layout (pages/panels/taskbar/BarLayout.qml): edited by its ListEditor, which has no `setting`;
            // the entry gives search and Reset page
            "c:bar.entries": {
                route: "panels/taskbar/barLayout",
                section: Tr.mark("Bar items"),
                title: Tr.mark("Bar items"),
                desc: Tr.mark("Order and visibility of the bar's items"),
                keywords: [Tr.mark("bar"), Tr.mark("taskbar"), Tr.mark("layout"), Tr.mark("order"), Tr.mark("items"), Tr.mark("modules")],
                type: "list"
            },

            // Panels > Taskbar > Workspaces (pages/panels/taskbar/BarWorkspaces.qml)
            "c:bar.workspaces.shown": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("General"),
                // TRANSLATORS: the number of workspaces shown on the bar
                title: Tr.markCtx("Shown", "bar workspaces"),
                desc: Tr.mark("Number of workspaces displayed"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("count"), Tr.mark("number")],
                type: "int",
                min: 1,
                max: 20,
                step: 1
            },
            "c:bar.workspaces.showUnoccupied": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("General"),
                title: Tr.markCtx("Show unoccupied", "bar workspaces"),
                desc: Tr.mark("Show workspaces that are inactive and empty"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("empty"), Tr.mark("unoccupied")],
                type: "bool"
            },
            "c:bar.workspaces.perMonitor": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("General"),
                title: Tr.markCtx("Per monitor", "bar workspaces"),
                desc: Tr.mark("Hide workspaces not on the current monitor"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("monitor"), Tr.mark("screen"), Tr.mark("display")],
                type: "bool"
            },
            "c:bar.workspaces.displayType": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.mark("Workspace style"),
                desc: Tr.mark("How each workspace is drawn. “Always show numbers” overrides it with numbers"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("style"), Tr.mark("numbers"), Tr.mark("icons"), Tr.mark("shapes"), Tr.mark("dots")],
                type: "enum",
                options: [
                    {
                        value: BarWorkspaceDisplay.Shapes,
                        label: Tr.mark("Shapes")
                    },
                    {
                        value: BarWorkspaceDisplay.Text,
                        label: Tr.mark("Numbers")
                    },
                    {
                        value: BarWorkspaceDisplay.Icons,
                        label: Tr.mark("Icons")
                    }
                ]
            },
            // caelestia4: IconRule nodes (Config/common.hpp): an exact name or a regex, and a Material icon
            "c:bar.workspaces.workspaceIcons": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.mark("Workspace icons"),
                desc: Tr.mark("Icons for workspaces in the Icons style, by workspace name or a name pattern. Not used while “Always show numbers” is on"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("icons"), Tr.mark("rules"), Tr.mark("name"), Tr.mark("regex")],
                type: "list",
                fields: [
                    {
                        key: "name",
                        title: Tr.mark("Workspace"),
                        type: "string"
                    },
                    {
                        key: "regex",
                        title: Tr.mark("Or a pattern"),
                        type: "string"
                    },
                    {
                        key: "icon",
                        title: Tr.mark("Icon"),
                        type: "icon"
                    }
                ],
                requires: {
                    id: "c:bar.workspaces.displayType",
                    value: BarWorkspaceDisplay.Icons
                }
            },
            "c:bar.workspaces.activeIndicator": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.markCtx("Active indicator", "bar workspaces"),
                desc: Tr.mark("Highlight the workspace you are on"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("active"), Tr.mark("current"), Tr.mark("highlight")],
                type: "bool"
            },
            "c:bar.workspaces.activeTrail": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.markCtx("Active trail", "bar workspaces"),
                desc: Tr.mark("Animate the highlight as it moves between workspaces"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("trail"), Tr.mark("animation")],
                type: "bool"
            },
            "c:bar.workspaces.occupiedBg": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.markCtx("Occupied background", "bar workspaces"),
                desc: Tr.mark("Draw a background behind workspaces that have windows"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("occupied"), Tr.mark("background")],
                type: "bool"
            },
            // caelestia4: bar/components/workspaces/Workspaces.qml (showNumbers)
            "e4:bar.workspaces.alwaysShowNumbers": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.mark("Always show numbers"),
                desc: Tr.mark("Workspaces show their numbers all the time, not only while Super is held. This overrides the workspace style, labels and icons"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("numbers"), Tr.mark("super"), Tr.mark("always")],
                type: "bool"
            },
            "e4:bar.workspaces.showNumberDelay": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Style"),
                title: Tr.mark("Hold Super to show numbers after"),
                desc: Tr.mark("How long Super must be held before workspace numbers appear"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("numbers"), Tr.mark("super"), Tr.mark("delay"), Tr.mark("hold")],
                type: "duration",
                unit: "ms",
                min: 0,
                max: 2000,
                step: 50,
                requires: {
                    id: "e4:bar.workspaces.alwaysShowNumbers",
                    value: false
                }
            },
            "c:bar.workspaces.showWindows": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Window icons"),
                title: Tr.markCtx("Show windows", "bar workspaces"),
                desc: Tr.mark("Show icons of open windows on each workspace"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("windows"), Tr.mark("icons"), Tr.mark("apps")],
                type: "bool"
            },
            "c:bar.workspaces.maxWindowIcons": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Window icons"),
                // TRANSLATORS: maximum number of window icons shown per workspace
                title: Tr.markCtx("Max window icons", "bar workspaces"),
                // caelestia4: no `requires`: the limit also covers special workspaces (showWindowsOnSpecialWorkspaces)
                desc: Tr.mark("Most window icons shown on one workspace, normal or special"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("windows"), Tr.mark("icons"), Tr.mark("limit")],
                type: "int",
                min: 0,
                max: 20,
                step: 1
            },
            // caelestia4: Icons.getAppCategoryIcon: window icons on workspaces and the bar's active window icon
            "c:bar.workspaces.windowIcons": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Window icons"),
                title: Tr.mark("Window icons"),
                desc: Tr.mark("Icons for apps' windows, by app ID or an ID pattern. Other apps get an icon from their category"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("windows"), Tr.mark("icons"), Tr.mark("class"), Tr.mark("app"), Tr.mark("rules"), Tr.mark("regex")],
                type: "list",
                fields: [
                    {
                        key: "name",
                        title: Tr.mark("Window class"),
                        type: "string"
                    },
                    {
                        key: "regex",
                        title: Tr.mark("Or a pattern"),
                        type: "string"
                    },
                    {
                        key: "icon",
                        title: Tr.mark("Icon"),
                        type: "icon"
                    }
                ],
                // caelestia4: the plugin's default rules (Config/barconfig.hpp) with every IconRule key, as the list
                // nodes report them, so an untouched list does not read as changed
                default: [
                    {
                        name: "",
                        regex: "steam(_app_(default|[0-9]+))?",
                        flags: "",
                        icon: "sports_esports"
                    }
                ]
            },
            "c:bar.workspaces.showWindowsOnSpecialWorkspaces": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Special workspaces"),
                title: Tr.markCtx("Windows on special workspaces", "bar workspaces"),
                desc: Tr.mark("Also show window icons on special (scratchpad) workspaces"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("special"), Tr.mark("scratchpad"), Tr.mark("windows")],
                type: "bool"
            },
            "c:bar.workspaces.specialDisplayType": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Special workspaces"),
                title: Tr.mark("Special workspace style"),
                desc: Tr.mark("How special (scratchpad) workspaces are drawn"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("special"), Tr.mark("scratchpad"), Tr.mark("style"), Tr.mark("icons"), Tr.mark("numbers"), Tr.mark("shapes")],
                type: "enum",
                options: [
                    {
                        value: BarWorkspaceDisplay.Shapes,
                        label: Tr.mark("Shapes")
                    },
                    {
                        value: BarWorkspaceDisplay.Text,
                        label: Tr.mark("Names")
                    },
                    {
                        value: BarWorkspaceDisplay.Icons,
                        label: Tr.mark("Icons")
                    }
                ]
            },
            "c:bar.workspaces.specialWorkspaceIcons": {
                route: "panels/taskbar/workspaces",
                section: Tr.mark("Special workspaces"),
                title: Tr.mark("Special workspace icons"),
                desc: Tr.mark("Icons for special workspaces, by name or a name pattern"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("special"), Tr.mark("scratchpad"), Tr.mark("icons"), Tr.mark("rules"), Tr.mark("regex")],
                type: "list",
                fields: [
                    {
                        key: "name",
                        title: Tr.mark("Workspace"),
                        type: "string"
                    },
                    {
                        key: "regex",
                        title: Tr.mark("Or a pattern"),
                        type: "string"
                    },
                    {
                        key: "icon",
                        title: Tr.mark("Icon"),
                        type: "icon"
                    }
                ],
                // caelestia4: the plugin's default rules (Config/barconfig.hpp) with every IconRule key, as the list
                // nodes report them, so an untouched list does not read as changed
                default: [
                    {
                        name: "special",
                        regex: "",
                        flags: "",
                        icon: "star"
                    },
                    {
                        name: "communication",
                        regex: "",
                        flags: "",
                        icon: "forum"
                    },
                    {
                        name: "music",
                        regex: "",
                        flags: "",
                        icon: "music_cast"
                    },
                    {
                        name: "todo",
                        regex: "",
                        flags: "",
                        icon: "checklist"
                    },
                    {
                        name: "sysmon",
                        regex: "",
                        flags: "",
                        icon: "monitor_heart"
                    }
                ],
                requires: {
                    id: "c:bar.workspaces.specialDisplayType",
                    value: BarWorkspaceDisplay.Icons
                }
            },
            // caelestia4: Workspace.qml's text: active, then occupied, then empty label; a blank one shows the
            // workspace's number or name (Numbers style, and Icons style when no icon rule matches)
            "c:bar.workspaces.label": {
                route: "panels/taskbar/workspaces",
                title: Tr.mark("Empty workspace label"),
                desc: Tr.mark("Character shown for an empty workspace in the Numbers style, and in the Icons style when no icon rule matches. Leave blank to show its number"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("label"), Tr.mark("glyph"), Tr.mark("character"), Tr.mark("empty"), Tr.mark("text")],
                type: "string",
                advanced: true,
                requires: {
                    id: "e4:bar.workspaces.alwaysShowNumbers",
                    value: false
                }
            },
            "c:bar.workspaces.occupiedLabel": {
                route: "panels/taskbar/workspaces",
                title: Tr.mark("Occupied workspace label"),
                desc: Tr.mark("Character shown for a workspace with windows in the Numbers style, and in the Icons style when no icon rule matches. Leave blank to show its number"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("label"), Tr.mark("glyph"), Tr.mark("character"), Tr.mark("occupied"), Tr.mark("text")],
                type: "string",
                advanced: true,
                requires: {
                    id: "e4:bar.workspaces.alwaysShowNumbers",
                    value: false
                }
            },
            "c:bar.workspaces.activeLabel": {
                route: "panels/taskbar/workspaces",
                title: Tr.mark("Current workspace label"),
                desc: Tr.mark("Character shown for the workspace you are on in the Numbers style, and in the Icons style when no icon rule matches. Leave blank to show its number"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("label"), Tr.mark("glyph"), Tr.mark("character"), Tr.mark("active"), Tr.mark("current"), Tr.mark("text")],
                type: "string",
                advanced: true,
                requires: {
                    id: "e4:bar.workspaces.alwaysShowNumbers",
                    value: false
                }
            },
            "c:bar.workspaces.capitalisation": {
                route: "panels/taskbar/workspaces",
                title: Tr.mark("Name case"),
                desc: Tr.mark("Letter case of named workspaces when no label is set"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("name"), Tr.mark("case"), Tr.mark("upper"), Tr.mark("lower"), Tr.mark("capital")],
                type: "enum",
                options: [
                    {
                        value: BarWorkspaceCapitalisation.Preserve,
                        label: Tr.markCtx("As written", "letter case")
                    },
                    {
                        value: BarWorkspaceCapitalisation.Upper,
                        label: Tr.markCtx("Upper case", "letter case")
                    },
                    {
                        value: BarWorkspaceCapitalisation.Lower,
                        label: Tr.markCtx("Lower case", "letter case")
                    }
                ],
                advanced: true
            },
            // caelestia4: Hypr.isToplevelIgnored (bar/components/workspaces/Workspaces.qml)
            "c:bar.workspaces.ignoredTags": {
                route: "panels/taskbar/workspaces",
                title: Tr.mark("Ignored window tags"),
                desc: Tr.mark("Windows with these Hyprland tags don't count as open on a workspace"),
                keywords: [Tr.mark("bar"), Tr.mark("workspaces"), Tr.mark("tags"), Tr.mark("ignore"), Tr.mark("hidden"), Tr.mark("windows"), Tr.mark("occupied")],
                type: "list",
                advanced: true
            },

            // Panels > Taskbar > Active window (pages/panels/taskbar/BarActiveWindow.qml)
            "c:bar.activeWindow.showTitle": {
                route: "panels/taskbar/activeWindow",
                title: Tr.mark("Show title"),
                desc: Tr.mark("Off: only the app's icon"),
                keywords: [Tr.mark("bar"), Tr.mark("active window"), Tr.mark("title"), Tr.mark("name")],
                type: "bool"
            },
            "c:bar.activeWindow.compact": {
                route: "panels/taskbar/activeWindow",
                title: Tr.markCtx("Compact", "taskbar active window layout"),
                desc: Tr.mark("Show only the last part of the title, such as the app name"),
                keywords: [Tr.mark("bar"), Tr.mark("active window"), Tr.mark("compact"), Tr.mark("small")],
                type: "bool",
                requires: {
                    id: "c:bar.activeWindow.showTitle",
                    value: true
                }
            },
            "c:bar.activeWindow.inverted": {
                route: "panels/taskbar/activeWindow",
                title: Tr.markCtx("Inverted", "taskbar active window: turn the vertical title the other way"),
                desc: Tr.mark("The title reads from bottom to top"),
                keywords: [Tr.mark("bar"), Tr.mark("active window"), Tr.mark("invert"), Tr.mark("swap"), Tr.mark("order")],
                type: "bool",
                requires: {
                    id: "c:bar.activeWindow.showTitle",
                    value: true
                }
            },
            "c:bar.activeWindow.showOnHover": {
                route: "panels/taskbar/activeWindow",
                title: Tr.mark("Show on hover"),
                desc: Tr.mark("Only show the active window title while hovering"),
                keywords: [Tr.mark("bar"), Tr.mark("active window"), Tr.mark("hover"), Tr.mark("title")],
                type: "bool"
            },
            "c:bar.popouts.activeWindow": {
                route: "panels/taskbar/activeWindow",
                title: Tr.mark("Popout on hover"),
                desc: Tr.mark("Show a window details popout when hovering"),
                keywords: [Tr.mark("bar"), Tr.mark("active window"), Tr.mark("popout"), Tr.mark("hover"), Tr.mark("preview")],
                type: "bool"
            },

            // Panels > Taskbar > Tray (pages/panels/taskbar/BarTray.qml)
            "c:bar.tray.background": {
                route: "panels/taskbar/tray",
                title: Tr.markCtx("Background", "taskbar tray: draw a background behind the tray"),
                desc: Tr.mark("Draw a rounded background behind the tray icons"),
                keywords: [Tr.mark("tray"), Tr.mark("background"), Tr.mark("pill")],
                type: "bool"
            },
            "c:bar.tray.recolour": {
                route: "panels/taskbar/tray",
                // TRANSLATORS: tint system tray icons with the theme accent colour
                title: Tr.mark("Recolour icons"),
                desc: Tr.mark("Tint the tray icons with the theme colour"),
                keywords: [Tr.mark("tray"), Tr.mark("icons"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("tint"), Tr.mark("monochrome")],
                type: "bool"
            },
            "c:bar.tray.compact": {
                route: "panels/taskbar/tray",
                title: Tr.markCtx("Compact", "taskbar tray layout"),
                desc: Tr.mark("Less space around the tray icons"),
                keywords: [Tr.mark("tray"), Tr.mark("compact"), Tr.mark("collapse")],
                type: "bool"
            },
            "c:bar.popouts.tray": {
                route: "panels/taskbar/tray",
                title: Tr.mark("Popout on hover"),
                desc: Tr.mark("Show the tray menu popout when hovering"),
                keywords: [Tr.mark("tray"), Tr.mark("popout"), Tr.mark("hover"), Tr.mark("menu")],
                type: "bool"
            },
            // caelestia4: bar/components/Tray.qml and the tray popout (bar/popouts/Content.qml) skip these item ids
            "c:bar.tray.hiddenIcons": {
                route: "panels/taskbar/tray",
                title: Tr.mark("Hidden icons"),
                desc: Tr.mark("Apps whose tray icon is not shown on the bar or in the tray popout"),
                keywords: [Tr.mark("tray"), Tr.mark("hide"), Tr.mark("hidden"), Tr.mark("icons"), Tr.mark("apps"), Tr.mark("blacklist")],
                type: "list"
            },
            // caelestia4: end-4's pinning, through services/TrayService.qml (pin from an icon's menu or middle-click it).
            // end-4's default swaps them (invertPinnedItems true: the list holds the icons kept behind the arrow)
            "e4:tray.invertPinnedItems": {
                route: "panels/taskbar/tray",
                title: Tr.mark("Swap pinned and unpinned"),
                desc: Tr.mark("Flips which icons stay on the bar and which go behind the expand arrow"),
                keywords: [Tr.mark("tray"), Tr.mark("pin"), Tr.mark("pinned"), Tr.mark("invert"), Tr.mark("swap"), Tr.mark("overflow")],
                type: "bool",
                advanced: true
            },
            "e4:tray.pinnedItems": {
                route: "panels/taskbar/tray",
                title: Tr.mark("Pin list"),
                desc: Tr.mark("Tray item ids that pinning adds and removes. They stay on the bar, or go behind the expand arrow while “Swap pinned and unpinned” is on"),
                keywords: [Tr.mark("tray"), Tr.mark("pin"), Tr.mark("pinned"), Tr.mark("items"), Tr.mark("ids")],
                type: "list",
                advanced: true
            },
            // caelestia4: BarTrayIconSub nodes (Config/barconfig.hpp), read by Icons.getTrayIcon
            "c:bar.tray.iconSubs": {
                route: "panels/taskbar/tray",
                title: Tr.mark("Icon replacements"),
                desc: Tr.mark("Show another icon for a tray item: a theme icon name or an image file"),
                keywords: [Tr.mark("tray"), Tr.mark("icons"), Tr.mark("replace"), Tr.mark("substitute"), Tr.mark("custom"), Tr.mark("theme")],
                type: "list",
                fields: [
                    {
                        key: "id",
                        title: Tr.mark("Item id"),
                        type: "string"
                    },
                    {
                        key: "icon",
                        title: Tr.mark("Theme icon"),
                        type: "string"
                    },
                    {
                        key: "image",
                        title: Tr.mark("Or image file"),
                        type: "string"
                    }
                ],
                advanced: true
            },

            // Panels > Taskbar > Status icons (pages/panels/taskbar/BarStatusIcons.qml)
            "c:bar.statusIcons": {
                route: "panels/taskbar/statusIcons",
                section: Tr.mark("Visible icons"),
                title: Tr.mark("Visible icons"),
                desc: Tr.mark("Which status icons the bar shows, in order"),
                keywords: [Tr.mark("bar"), Tr.mark("status"), Tr.mark("icons"), Tr.mark("battery"), Tr.mark("network"), Tr.mark("bluetooth"), Tr.mark("indicators")],
                type: "list"
            },
            "c:bar.popouts.statusIcons": {
                route: "panels/taskbar/statusIcons",
                section: Tr.mark("Behaviour"),
                title: Tr.mark("Popout on hover"),
                desc: Tr.mark("Show a details popout when hovering the status icons"),
                keywords: [Tr.mark("bar"), Tr.mark("status"), Tr.mark("popout"), Tr.mark("hover")],
                type: "bool"
            },

            // Panels > Taskbar > Clock (pages/panels/taskbar/BarClock.qml)
            "c:bar.clock.background": {
                route: "panels/taskbar/clock",
                title: Tr.markCtx("Background", "taskbar clock: draw a background behind the clock"),
                desc: Tr.mark("Draw a background behind the clock"),
                keywords: [Tr.mark("bar"), Tr.mark("clock"), Tr.mark("background"), Tr.mark("pill")],
                type: "bool"
            },
            "c:bar.clock.showDate": {
                route: "panels/taskbar/clock",
                title: Tr.mark("Show date"),
                desc: Tr.mark("Show the date next to the time"),
                keywords: [Tr.mark("bar"), Tr.mark("clock"), Tr.mark("date"), Tr.mark("day")],
                type: "bool"
            },
            "c:bar.clock.showIcon": {
                route: "panels/taskbar/clock",
                title: Tr.mark("Show icon"),
                desc: Tr.mark("Show a clock icon next to the time"),
                keywords: [Tr.mark("bar"), Tr.mark("clock"), Tr.mark("icon")],
                type: "bool"
            },
            "c:bar.clock.showSeconds": {
                route: "panels/taskbar/clock",
                title: Tr.mark("Show seconds"),
                desc: Tr.mark("Show seconds in the time"),
                keywords: [Tr.mark("bar"), Tr.mark("clock"), Tr.mark("seconds"), Tr.mark("time")],
                type: "bool"
            },

            // Panels > Launcher (pages/panels/LauncherPanel.qml)
            "c:launcher.enabled": {
                route: "panels/launcher",
                section: Tr.mark("General"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Show the app launcher"),
                keywords: [Tr.mark("launcher"), Tr.mark("enable"), Tr.mark("apps"), Tr.mark("menu"), Tr.mark("start")],
                type: "bool"
            },
            "c:launcher.showOnHover": {
                route: "panels/launcher",
                section: Tr.mark("General"),
                title: Tr.mark("Show on hover"),
                desc: Tr.mark("Reveal when the cursor reaches the screen edge"),
                keywords: [Tr.mark("launcher"), Tr.mark("hover"), Tr.mark("edge"), Tr.mark("reveal")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.dragThreshold": {
                route: "panels/launcher",
                section: Tr.mark("General"),
                title: Tr.mark("Drag threshold"),
                desc: Tr.mark("How far to drag up from the bottom edge to open the launcher, or down to close it. Not used while it shows on hover"),
                keywords: [Tr.mark("launcher"), Tr.mark("drag"), Tr.mark("swipe"), Tr.mark("threshold")],
                type: "int",
                unit: "px",
                min: 0,
                max: 200,
                step: 5,
                requires: {
                    id: "c:launcher.showOnHover",
                    value: false
                }
            },
            "c:launcher.vimKeybinds": {
                route: "panels/launcher",
                section: Tr.mark("General"),
                title: Tr.mark("Vim keys"),
                desc: Tr.mark("Ctrl+J and Ctrl+K move through the results, as do Ctrl+N and Ctrl+P"),
                keywords: [Tr.mark("launcher"), Tr.mark("vim"), Tr.mark("keys"), Tr.mark("hjkl")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.maxShown": {
                route: "panels/launcher",
                section: Tr.mark("Results"),
                title: Tr.mark("Max items shown"),
                desc: Tr.mark("Most results listed at once"),
                keywords: [Tr.mark("launcher"), Tr.mark("results"), Tr.mark("items"), Tr.mark("limit")],
                type: "int",
                min: 1,
                max: 20,
                step: 1,
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.maxWallpapers": {
                route: "panels/launcher",
                section: Tr.mark("Results"),
                title: Tr.mark("Max wallpapers"),
                desc: Tr.mark("Most wallpapers shown at once when picking one"),
                keywords: [Tr.mark("launcher"), Tr.mark("wallpapers"), Tr.mark("limit")],
                type: "int",
                min: 1,
                max: 30,
                step: 1,
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.enableDangerousActions": {
                route: "panels/launcher",
                section: Tr.mark("Actions"),
                title: Tr.mark("Enable dangerous actions"),
                desc: Tr.mark("Allow actions that shut down or log out"),
                keywords: [Tr.mark("launcher"), Tr.mark("dangerous"), Tr.mark("shutdown"), Tr.mark("logout"), Tr.mark("actions")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "e4:search.engineBaseUrl": {
                route: "panels/launcher",
                section: Tr.mark("Search"),
                title: Tr.mark("Web search address"),
                desc: Tr.mark("Your search text is added at the end"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("web"), Tr.mark("engine"), Tr.mark("google"), Tr.mark("url")],
                type: "string"
            },
            "c:launcher.useFuzzy.apps": {
                route: "panels/launcher",
                section: Tr.mark("Fuzzy search"),
                title: Tr.mark("Apps"),
                desc: Tr.mark("Match app names even with typos or missing letters"),
                keywords: [Tr.mark("launcher"), Tr.mark("fuzzy"), Tr.mark("search"), Tr.mark("typo"), Tr.mark("apps")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.useFuzzy.actions": {
                route: "panels/launcher",
                section: Tr.mark("Fuzzy search"),
                title: Tr.mark("Actions"),
                desc: Tr.mark("Match actions even with typos or missing letters"),
                keywords: [Tr.mark("launcher"), Tr.mark("fuzzy"), Tr.mark("search"), Tr.mark("typo"), Tr.mark("actions")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.useFuzzy.schemes": {
                route: "panels/launcher",
                section: Tr.mark("Fuzzy search"),
                title: Tr.mark("Schemes"),
                desc: Tr.mark("Match colour schemes even with typos or missing letters"),
                keywords: [Tr.mark("launcher"), Tr.mark("fuzzy"), Tr.mark("search"), Tr.mark("typo"), Tr.mark("schemes")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.useFuzzy.variants": {
                route: "panels/launcher",
                section: Tr.mark("Fuzzy search"),
                title: Tr.mark("Variants"),
                desc: Tr.mark("Match scheme variants even with typos or missing letters"),
                keywords: [Tr.mark("launcher"), Tr.mark("fuzzy"), Tr.mark("search"), Tr.mark("typo"), Tr.mark("variants")],
                type: "bool",
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "c:launcher.useFuzzy.wallpapers": {
                route: "panels/launcher",
                section: Tr.mark("Fuzzy search"),
                title: Tr.mark("Wallpapers"),
                desc: Tr.mark("Match wallpaper names even with typos or missing letters"),
                keywords: [Tr.mark("launcher"), Tr.mark("fuzzy"), Tr.mark("search"), Tr.mark("typo"), Tr.mark("wallpapers")],
                type: "bool",
                // caelestia4: adapters/Wallpapers.qml's search is only used by the launcher (launcher/WallpaperList.qml)
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            // The default ">" shows as an empty field and an empty field saves ">": the page provides that as an x: id
            // over c:launcher.actionPrefix
            "x:launcher.actionPrefix": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Action prefix"),
                desc: Tr.mark("Prefix used to run actions in the launcher"),
                keywords: [Tr.mark("launcher"), Tr.mark("action"), Tr.mark("prefix"), Tr.mark("command")],
                type: "string",
                validate: "^[^a-zA-Z0-9\\s]$",
                advanced: true,
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            // Row-less: the store option behind the row above, so the page's Reset page counts and resets it
            "c:launcher.actionPrefix": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Action prefix"),
                desc: Tr.mark("Prefix used to run actions in the launcher"),
                type: "string",
                advanced: true,
                requires: {
                    id: "c:launcher.enabled",
                    value: true
                }
            },
            "e4:search.prefix.shellCommand": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Run command prefix"),
                desc: Tr.mark("Type this first to run a shell command"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("shellcommand")],
                type: "string",
                advanced: true
            },
            "e4:search.prefix.clipboard": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Clipboard prefix"),
                desc: Tr.mark("Type this first to search clipboard history"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("clipboard")],
                type: "string",
                advanced: true
            },
            "e4:search.prefix.emojis": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Emoji prefix"),
                desc: Tr.mark("Type this first to search emoji"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("emojis")],
                type: "string",
                advanced: true
            },
            "e4:search.prefix.math": {
                route: "panels/launcher",
                section: Tr.mark("Prefixes"),
                title: Tr.mark("Calculator prefix"),
                desc: Tr.mark("Type this first to calculate"),
                keywords: [Tr.mark("launcher"), Tr.mark("search"), Tr.mark("prefix"), Tr.mark("math")],
                type: "string",
                advanced: true
            },

            // Panels > Sidebar (pages/panels/SidebarPanel.qml)
            "c:sidebar.enabled": {
                route: "panels/sidebar",
                section: Tr.mark("General"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Show the notification sidebar on the right edge"),
                keywords: [Tr.mark("sidebar"), Tr.mark("enable"), Tr.mark("notifications")],
                type: "bool"
            },
            "c:sidebar.showOnHover": {
                route: "panels/sidebar",
                section: Tr.mark("General"),
                title: Tr.mark("Show on hover"),
                desc: Tr.mark("Reveal when the cursor reaches the screen edge"),
                keywords: [Tr.mark("sidebar"), Tr.mark("hover"), Tr.mark("edge"), Tr.mark("reveal")],
                type: "bool",
                requires: {
                    id: "c:sidebar.enabled",
                    value: true
                }
            },
            "c:sidebar.dragThreshold": {
                route: "panels/sidebar",
                section: Tr.mark("General"),
                title: Tr.mark("Drag threshold"),
                desc: Tr.mark("How far to drag left from the right edge to open the sidebar, or right to close it"),
                keywords: [Tr.mark("sidebar"), Tr.mark("drag"), Tr.mark("swipe"), Tr.mark("threshold")],
                type: "int",
                unit: "px",
                min: 0,
                max: 200,
                step: 5,
                requires: {
                    id: "c:sidebar.enabled",
                    value: true
                }
            },

            // Panels > Utilities (pages/panels/UtilitiesPanel.qml)
            "c:utilities.enabled": {
                route: "panels/utilities",
                section: Tr.mark("General"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Show the utilities panel"),
                keywords: [Tr.mark("utilities"), Tr.mark("enable"), Tr.mark("panel"), Tr.mark("toggles")],
                type: "bool"
            },
            "c:utilities.cards.keepAwake": {
                route: "panels/utilities",
                section: Tr.mark("Cards"),
                title: Tr.mark("Keep awake"),
                desc: Tr.mark("Show the “Keep awake” card, which stops the screen from dimming or locking"),
                keywords: [Tr.mark("utilities"), Tr.mark("keep awake"), Tr.mark("idle"), Tr.mark("inhibit"), Tr.mark("caffeine")],
                type: "bool"
            },
            "c:utilities.cards.recorder": {
                route: "panels/utilities",
                section: Tr.mark("Cards"),
                title: Tr.mark("Screen recorder"),
                desc: Tr.mark("Show the screen recorder card"),
                keywords: [Tr.mark("utilities"), Tr.mark("recorder"), Tr.mark("record"), Tr.mark("screen capture")],
                type: "bool"
            },
            "c:utilities.cards.quickToggles": {
                route: "panels/utilities",
                section: Tr.mark("Cards"),
                title: Tr.mark("Quick toggles"),
                desc: Tr.mark("Show the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("buttons")],
                type: "bool"
            },
            "e4:caelestia.utilitiesSystem": {
                route: "panels/utilities",
                section: Tr.mark("Cards"),
                title: Tr.mark("System card"),
                desc: Tr.mark("Uptime, reload, settings and session buttons"),
                keywords: [Tr.mark("utilities"), Tr.mark("system"), Tr.mark("uptime"), Tr.mark("reload")],
                type: "bool"
            },
            "e4:caelestia.utilitiesSliders": {
                route: "panels/utilities",
                section: Tr.mark("Cards"),
                title: Tr.mark("Volume, microphone and brightness sliders"),
                desc: Tr.mark("Sliders at the top of the utilities panel"),
                keywords: [Tr.mark("utilities"), Tr.mark("sliders"), Tr.mark("volume"), Tr.mark("brightness"), Tr.mark("microphone")],
                type: "bool"
            },
            "c:utilities.quickToggles": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Quick toggle buttons"),
                desc: Tr.mark("Which buttons the quick toggles card shows"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("buttons")],
                type: "list"
            },
            "x:utilities.quickToggles.wifi": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Wi-Fi"),
                desc: Tr.mark("Show the Wi-Fi button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("wifi"), Tr.mark("wireless")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.bluetooth": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Bluetooth"),
                desc: Tr.mark("Show the Bluetooth button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("bluetooth")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.mic": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Microphone"),
                desc: Tr.mark("Show the microphone mute button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("microphone"), Tr.mark("mic"), Tr.mark("mute")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.settings": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Settings"),
                desc: Tr.mark("Show the button that opens Settings on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("settings")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.gameMode": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Game mode"),
                desc: Tr.mark("Show the game mode button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("game mode"), Tr.mark("gaming")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.dnd": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Do not disturb"),
                desc: Tr.mark("Show the Do not disturb button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("do not disturb"), Tr.mark("dnd"), Tr.mark("silence")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "x:utilities.quickToggles.vpn": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("VPN"),
                desc: Tr.mark("Show the VPN button on the quick toggles card"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("vpn")],
                type: "bool",
                requires: {
                    id: "c:utilities.cards.quickToggles",
                    value: true
                }
            },
            "e4:caelestia.quickToggles": {
                route: "panels/utilities",
                section: Tr.mark("Quick toggles"),
                title: Tr.mark("Quick toggles layout"),
                desc: Tr.mark("Order and visibility set in the drawer (pencil button)"),
                keywords: [Tr.mark("utilities"), Tr.mark("quick toggles"), Tr.mark("order"), Tr.mark("layout")],
                type: "list"
            },

            // Panels > Session menu (pages/panels/SessionPanel.qml)
            "c:session.enabled": {
                route: "panels/session",
                section: Tr.mark("General"),
                title: Tr.markCtx("Enabled", "toggle label"),
                desc: Tr.mark("Lock, sleep, log out, restart and shut down from the screen edge"),
                keywords: [Tr.mark("session"), Tr.mark("power"), Tr.mark("logout"), Tr.mark("shutdown"), Tr.mark("menu")],
                type: "bool"
            },
            "c:session.vimKeybinds": {
                route: "panels/session",
                section: Tr.mark("General"),
                title: Tr.mark("Vim keys"),
                desc: Tr.mark("Ctrl+J and Ctrl+K move between the buttons, as do Ctrl+N and Ctrl+P"),
                keywords: [Tr.mark("session"), Tr.mark("vim"), Tr.mark("keys"), Tr.mark("hjkl")],
                type: "bool",
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            // The commands are lists (session.commands.*) shown as one line: TextFieldRow writes text, so the page
            // provides them as x: ids over the c: options, split on spaces
            "x:session.commands.logout": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Log out"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                keywords: [Tr.mark("session"), Tr.mark("command"), Tr.mark("logout"), Tr.mark("log out")],
                type: "string",
                validate: "\\S",
                advanced: true,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "x:session.commands.hibernate": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Hibernate"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                keywords: [Tr.mark("session"), Tr.mark("command"), Tr.mark("hibernate")],
                type: "string",
                validate: "\\S",
                advanced: true,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "x:session.commands.reboot": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Restart"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                keywords: [Tr.mark("session"), Tr.mark("command"), Tr.mark("reboot"), Tr.mark("restart")],
                type: "string",
                validate: "\\S",
                advanced: true,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },
            "x:session.commands.shutdown": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Shut down"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                keywords: [Tr.mark("session"), Tr.mark("command"), Tr.mark("shutdown"), Tr.mark("shut down")],
                type: "string",
                validate: "\\S",
                advanced: true,
                requires: {
                    id: "c:session.enabled",
                    value: true
                }
            },

            // Row-less: the store options behind the four command rows, so the page's Reset page counts and resets them
            "c:session.commands.logout": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Log out"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                type: "list",
                advanced: true
            },
            "c:session.commands.hibernate": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Hibernate"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                type: "list",
                advanced: true
            },
            "c:session.commands.reboot": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Restart"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                type: "list",
                advanced: true
            },
            "c:session.commands.shutdown": {
                route: "panels/session",
                section: Tr.mark("Commands"),
                title: Tr.mark("Shut down"),
                desc: Tr.mark("Command to run, split on spaces (no shell)"),
                type: "list",
                advanced: true
            },

            // Panels > On-screen display (pages/panels/OsdPanel.qml)
            "c:osd.enabled": {
                route: "panels/osd",
                section: Tr.mark("General"),
                title: Tr.mark("Show when volume or brightness changes"),
                desc: Tr.mark("A small popup with a slider for the new level"),
                keywords: [Tr.mark("osd"), Tr.mark("on-screen display"), Tr.mark("popup"), Tr.mark("volume"), Tr.mark("brightness")],
                type: "bool"
            },
            "c:osd.hideDelay": {
                route: "panels/osd",
                section: Tr.mark("General"),
                title: Tr.mark("Hide after"),
                desc: Tr.mark("How long the popup stays after the last change"),
                keywords: [Tr.mark("osd"), Tr.mark("hide"), Tr.mark("delay"), Tr.mark("timeout")],
                type: "duration",
                unit: "ms",
                min: 500,
                max: 10000,
                step: 250,
                requires: {
                    id: "c:osd.enabled",
                    value: true
                }
            },
            "c:osd.enableBrightness": {
                route: "panels/osd",
                section: Tr.mark("General"),
                title: Tr.mark("Brightness slider"),
                desc: Tr.mark("Show the popup when the brightness changes"),
                keywords: [Tr.mark("osd"), Tr.mark("brightness"), Tr.mark("screen")],
                type: "bool",
                requires: {
                    id: "c:osd.enabled",
                    value: true
                }
            },
            "c:osd.enableMicrophone": {
                route: "panels/osd",
                section: Tr.mark("General"),
                title: Tr.mark("Microphone slider"),
                desc: Tr.mark("Show the popup when the microphone volume changes"),
                keywords: [Tr.mark("osd"), Tr.mark("microphone"), Tr.mark("mic"), Tr.mark("input")],
                type: "bool",
                requires: {
                    id: "c:osd.enabled",
                    value: true
                }
            },

            // Panels > Assistant (pages/panels/AssistantPanel.qml)
            "e4:policies.ai": {
                route: "panels/assistant",
                section: Tr.mark("AI assistant"),
                title: Tr.mark("Allow AI"),
                desc: Tr.mark("Whether the AI chat tab is offered"),
                keywords: [Tr.mark("ai"), Tr.mark("assistant"), Tr.mark("chat"), Tr.mark("llm"), Tr.mark("policy")],
                type: "enum",
                options: [
                    {
                        value: 1,
                        label: Tr.mark("Yes")
                    },
                    {
                        value: 2,
                        label: Tr.mark("Local models only")
                    },
                    {
                        value: 0,
                        label: Tr.mark("No")
                    }
                ]
            },
            "e4:ai.tool": {
                route: "panels/assistant",
                section: Tr.mark("AI assistant"),
                title: Tr.mark("What the AI may use"),
                desc: Tr.mark("Tools let the AI run commands and change settings"),
                keywords: [Tr.mark("ai"), Tr.mark("tools"), Tr.mark("functions"), Tr.mark("web search")],
                type: "enum",
                options: [
                    {
                        value: "functions",
                        label: Tr.mark("Tools (shell, settings)")
                    },
                    {
                        value: "search",
                        label: Tr.mark("Web search")
                    },
                    {
                        value: "none",
                        label: Tr.mark("Nothing")
                    }
                ]
            },
            "e4:ai.systemPrompt": {
                route: "panels/assistant",
                section: Tr.mark("Prompt and models"),
                title: Tr.mark("Instructions for the AI"),
                desc: Tr.mark("System prompt. {DISTRO}, {DE}, {DATETIME} and {WINDOWCLASS} are filled in"),
                keywords: [Tr.mark("ai"), Tr.mark("prompt"), Tr.mark("system prompt"), Tr.mark("instructions")],
                type: "string",
                advanced: true
            },
            "e4:policies.weeb": {
                route: "panels/assistant",
                section: Tr.mark("Image boards"),
                title: Tr.mark("Anime tab"),
                desc: Tr.mark("Show the tab with anime image boards in the Assistant"),
                keywords: [Tr.mark("anime"), Tr.mark("weeb"), Tr.mark("booru"), Tr.mark("images")],
                type: "enum",
                options: [
                    {
                        value: 1,
                        label: Tr.mark("Shown")
                    },
                    {
                        value: 2,
                        label: Tr.mark("Hidden tab")
                    },
                    {
                        value: 0,
                        label: Tr.mark("Off")
                    }
                ]
            },
            // caelestia4: read only by the launcher's clipboard search (services/LauncherSearch.qml)
            "e4:workSafety.enable.clipboard": {
                route: "panels/launcher",
                section: Tr.mark("Work safety"),
                title: Tr.mark("Hide unsafe images in the clipboard"),
                desc: Tr.mark("On public Wi-Fi, blur clipboard images copied next to an unsafe link in the launcher's clipboard search"),
                keywords: [Tr.mark("work safety"), Tr.mark("nsfw"), Tr.mark("clipboard"), Tr.mark("blur")],
                type: "bool"
            },

            // Panels > Overview & overlay (pages/panels/OverviewPanel.qml)
            "e4:overview.rows": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Rows"),
                desc: Tr.mark("Rows of workspaces in the overview"),
                keywords: [Tr.mark("overview"), Tr.mark("rows"), Tr.mark("grid"), Tr.mark("workspaces")],
                type: "int",
                min: 1,
                max: 5,
                step: 1,
                requires: {
                    id: "e4:overview.enable",
                    value: true
                }
            },
            "e4:overview.columns": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Columns"),
                desc: Tr.mark("Columns of workspaces in the overview"),
                keywords: [Tr.mark("overview"), Tr.mark("columns"), Tr.mark("grid"), Tr.mark("workspaces")],
                type: "int",
                min: 1,
                max: 10,
                step: 1,
                requires: {
                    id: "e4:overview.enable",
                    value: true
                }
            },
            // overview.scale is stored as a fraction (0.18) but shown as a percent, which the registry can't scale yet:
            // the page provides it as an x: id over e4:overview.scale
            "x:overview.scalePercent": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Preview size"),
                desc: Tr.mark("Each workspace preview, as a share of the screen size"),
                keywords: [Tr.mark("overview"), Tr.mark("scale"), Tr.mark("size"), Tr.mark("preview")],
                type: "int",
                unit: "%",
                min: 5,
                max: 40,
                step: 1,
                requires: {
                    id: "e4:overview.enable",
                    value: true
                }
            },
            // Row-less: the stored fraction behind the preview size row, so the page's Reset page counts and resets it
            "e4:overview.scale": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Preview size"),
                desc: Tr.mark("Each workspace preview, as a share of the screen size"),
                type: "real"
            },
            "e4:caelestia.overview.altTabSkipEmpty": {
                route: "panels/overview",
                section: Tr.mark("Workspace overview"),
                title: Tr.mark("Alt+Tab skips empty workspaces"),
                desc: Tr.mark("Hold Alt, press Tab to step through workspaces, release Alt to switch"),
                keywords: [Tr.mark("overview"), Tr.mark("alt tab"), Tr.mark("switch"), Tr.mark("empty"), Tr.mark("workspaces")],
                type: "bool"
            },
            "e4:overlay.darkenScreen": {
                route: "panels/overview",
                section: Tr.mark("Overlay widgets (Super+G)"),
                title: Tr.mark("Darken the screen behind"),
                desc: Tr.mark("Dim everything under the overlay widgets"),
                keywords: [Tr.mark("overlay"), Tr.mark("darken"), Tr.mark("dim"), Tr.mark("background")],
                type: "bool"
            },
            "e4:overlay.openingZoomAnimation": {
                route: "panels/overview",
                section: Tr.mark("Overlay widgets (Super+G)"),
                title: Tr.mark("Zoom animation when opening"),
                desc: Tr.mark("The overlay grows in from the centre"),
                keywords: [Tr.mark("overlay"), Tr.mark("zoom"), Tr.mark("animation")],
                type: "bool"
            },
            "e4:crosshair.code": {
                route: "panels/overview",
                section: Tr.mark("Overlay widgets (Super+G)"),
                title: Tr.mark("Crosshair code"),
                desc: Tr.mark("In Valorant's format"),
                keywords: [Tr.mark("crosshair"), Tr.mark("valorant"), Tr.mark("gaming"), Tr.mark("aim")],
                type: "string",
                advanced: true
            },

            // Panels > Keybind cheatsheet (pages/panels/CheatsheetPanel.qml)
            "e4:cheatsheet.useMacSymbol": {
                route: "panels/cheatsheet",
                section: Tr.mark("Keys"),
                title: Tr.mark("macOS-style key symbols"),
                desc: Tr.mark("⌘ ⌥ ⇧ instead of Super, Alt, Shift"),
                keywords: [Tr.mark("cheatsheet"), Tr.mark("keybinds"), Tr.mark("mac"), Tr.mark("symbols")],
                type: "bool"
            },
            "e4:cheatsheet.useFnSymbol": {
                route: "panels/cheatsheet",
                section: Tr.mark("Keys"),
                title: Tr.mark("Symbols for function keys"),
                desc: Tr.mark("Icons instead of names for F1 to F12"),
                keywords: [Tr.mark("cheatsheet"), Tr.mark("keybinds"), Tr.mark("function keys"), Tr.mark("symbols")],
                type: "bool"
            },
            "e4:cheatsheet.useMouseSymbol": {
                route: "panels/cheatsheet",
                section: Tr.mark("Keys"),
                title: Tr.mark("Symbols for mouse buttons"),
                desc: Tr.mark("Icons instead of names for mouse buttons and the wheel"),
                keywords: [Tr.mark("cheatsheet"), Tr.mark("keybinds"), Tr.mark("mouse"), Tr.mark("symbols")],
                type: "bool"
            },
            "e4:cheatsheet.splitButtons": {
                route: "panels/cheatsheet",
                section: Tr.mark("Keys"),
                title: Tr.mark("One key per box"),
                desc: Tr.mark("Draw each modifier key (Super, Ctrl…) in its own box"),
                keywords: [Tr.mark("cheatsheet"), Tr.mark("keybinds"), Tr.mark("boxes"), Tr.mark("keys")],
                type: "bool"
            }
        })
}
