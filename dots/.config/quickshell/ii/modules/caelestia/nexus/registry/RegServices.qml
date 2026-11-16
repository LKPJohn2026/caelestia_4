import QtQuick
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4 Directories, for a default)

// caelestia4: Nexus registry entries for the "services" page (merged by Registry.qml). See RegPanels.qml for the format
QtObject {
    readonly property var entries: ({
            // Services > Notifications (pages/services/NotificationsPage.qml)
            "c:notifs.fullscreen": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Show over fullscreen apps"),
                desc: Tr.mark("Whether notifications pop up over games and fullscreen video"),
                keywords: [Tr.mark("notifications"), Tr.mark("fullscreen"), Tr.mark("games"), Tr.mark("video"), Tr.mark("popup")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.markCtx("On", "show notifications over fullscreen apps")
                    },
                    {
                        value: 1,
                        label: Tr.markCtx("Off", "show notifications over fullscreen apps")
                    }
                ]
            },
            "c:notifs.expire": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Hide pop-ups by themselves"),
                desc: Tr.mark("Pop-ups go away after a while. They stay in the notification list"),
                keywords: [Tr.mark("notifications"), Tr.mark("expire"), Tr.mark("dismiss"), Tr.mark("timeout"), Tr.mark("auto hide")],
                type: "bool"
            },
            "c:notifs.openExpanded": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Open expanded"),
                desc: Tr.mark("Show notifications expanded by default"),
                keywords: [Tr.mark("notifications"), Tr.mark("expanded"), Tr.mark("collapse"), Tr.mark("details")],
                type: "bool"
            },
            "c:notifs.defaultExpireTimeout": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Hide pop-ups after"),
                desc: Tr.mark("When the app doesn't say how long its pop-up stays"),
                keywords: [Tr.mark("notifications"), Tr.mark("timeout"), Tr.mark("duration"), Tr.mark("expire"), Tr.mark("dismiss")],
                // caelestia4: stored in ms, shown in seconds (DurationRow)
                type: "duration",
                unit: "ms",
                min: 1000,
                max: 60000,
                requires: {
                    id: "c:notifs.expire",
                    value: true
                }
            },
            // caelestia4: read by NotifData.qml (its timer): a pop-up shown while a fullscreen app is open hides after
            // this, even with "Hide pop-ups by themselves" off
            "c:notifs.fullscreenExpireTimeout": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Over fullscreen apps, hide after"),
                desc: Tr.mark("Pop-ups over a game or fullscreen video go away sooner"),
                keywords: [Tr.mark("notifications"), Tr.mark("fullscreen"), Tr.mark("timeout"), Tr.mark("games"), Tr.mark("video"), Tr.mark("expire")],
                type: "duration",
                unit: "ms",
                min: 500,
                max: 60000,
                requires: {
                    id: "c:notifs.fullscreen",
                    value: 0
                }
            },
            "c:notifs.groupPreviewNum": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Group preview count"),
                desc: Tr.mark("Notifications shown per group before collapsing"),
                keywords: [Tr.mark("notifications"), Tr.mark("group"), Tr.mark("stack"), Tr.mark("preview"), Tr.mark("collapse")],
                type: "int",
                min: 1,
                max: 10,
                step: 1
            },
            "c:utilities.toasts.fullscreen": {
                route: "services/notifications",
                section: Tr.mark("Toasts"),
                title: Tr.mark("Show over fullscreen apps"),
                desc: Tr.mark("Whether toasts pop up over games and fullscreen video"),
                keywords: [Tr.mark("toasts"), Tr.mark("fullscreen"), Tr.mark("games"), Tr.mark("video"), Tr.mark("popup")],
                type: "enum",
                options: [
                    {
                        value: "off",
                        label: Tr.markCtx("Off", "show toasts over fullscreen apps")
                    },
                    {
                        value: "important",
                        label: Tr.markCtx("Important", "show toasts over fullscreen apps: important ones only")
                    },
                    {
                        value: "all",
                        label: Tr.markCtx("On", "show toasts over fullscreen apps")
                    }
                ]
            },
            "c:utilities.maxToasts": {
                route: "services/notifications",
                section: Tr.mark("Toasts"),
                title: Tr.mark("Visible toasts"),
                desc: Tr.mark("Maximum number of toasts shown at once"),
                keywords: [Tr.mark("toasts"), Tr.mark("maximum"), Tr.mark("count"), Tr.mark("limit"), Tr.mark("popup")],
                type: "int",
                min: 1,
                max: 10,
                step: 1
            },
            "c:utilities.toasts.chargingChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Charging changes"),
                desc: Tr.mark("When the charger is plugged in or out"),
                keywords: [Tr.mark("toast"), Tr.mark("charging"), Tr.mark("battery"), Tr.mark("power"), Tr.mark("plugged")],
                type: "bool"
            },
            "c:utilities.toasts.gameModeChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Game mode changes"),
                desc: Tr.mark("When game mode turns on or off"),
                keywords: [Tr.mark("toast"), Tr.mark("game mode"), Tr.mark("gaming")],
                type: "bool"
            },
            "c:utilities.toasts.dndChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Do not disturb changes"),
                desc: Tr.mark("When do not disturb turns on or off"),
                keywords: [Tr.mark("toast"), Tr.mark("do not disturb"), Tr.mark("dnd"), Tr.mark("silent"), Tr.mark("quiet")],
                type: "bool"
            },
            "c:utilities.toasts.audioOutputChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Audio output changes"),
                desc: Tr.mark("When sound moves to other speakers or headphones"),
                keywords: [Tr.mark("toast"), Tr.mark("audio"), Tr.mark("output"), Tr.mark("speakers"), Tr.mark("headphones"), Tr.mark("sink")],
                type: "bool"
            },
            "c:utilities.toasts.audioInputChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Audio input changes"),
                desc: Tr.mark("When the microphone in use changes"),
                keywords: [Tr.mark("toast"), Tr.mark("audio"), Tr.mark("input"), Tr.mark("microphone"), Tr.mark("mic"), Tr.mark("source")],
                type: "bool"
            },
            "c:utilities.toasts.capsLockChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Caps lock changes"),
                desc: Tr.mark("When caps lock turns on or off"),
                keywords: [Tr.mark("toast"), Tr.mark("caps lock"), Tr.mark("keyboard")],
                type: "bool"
            },
            "c:utilities.toasts.numLockChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Num lock changes"),
                desc: Tr.mark("When num lock turns on or off"),
                keywords: [Tr.mark("toast"), Tr.mark("num lock"), Tr.mark("numpad"), Tr.mark("keyboard")],
                type: "bool"
            },
            "c:utilities.toasts.kbLayoutChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Keyboard layout changes"),
                desc: Tr.mark("When you switch to another keyboard layout"),
                keywords: [Tr.mark("toast"), Tr.mark("keyboard"), Tr.mark("layout"), Tr.mark("language"), Tr.mark("input method")],
                type: "bool"
            },
            "c:utilities.toasts.vpnChanged": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("VPN changes"),
                desc: Tr.mark("When a VPN connects or disconnects"),
                keywords: [Tr.mark("toast"), Tr.mark("vpn"), Tr.mark("network"), Tr.mark("tunnel")],
                type: "bool"
            },
            "c:utilities.toasts.nowPlaying": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Now playing"),
                desc: Tr.mark("When a new song or video starts playing"),
                keywords: [Tr.mark("toast"), Tr.mark("now playing"), Tr.mark("music"), Tr.mark("media"), Tr.mark("song"), Tr.mark("track")],
                type: "bool"
            },
            // caelestia4: read by the plugin (Config/rootnodes.cpp, detail::loaded): a toast each time shell.json loads
            "c:utilities.toasts.configLoaded": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Settings file loaded"),
                desc: Tr.mark("When the panel settings file is loaded, with any problems found in it"),
                keywords: [Tr.mark("toast"), Tr.mark("config"), Tr.mark("settings"), Tr.mark("loaded"), Tr.mark("shell.json"), Tr.mark("reload")],
                type: "bool"
            },
            // caelestia4: read by bar/popouts/kblayout/KbLayoutModel.qml: warns when more than 4 layouts are set
            "c:utilities.toasts.kbLimit": {
                route: "services/notifications",
                section: Tr.mark("Toast events"),
                title: Tr.mark("Too many keyboard layouts"),
                desc: Tr.mark("When more than 4 keyboard layouts are set; only 4 work at a time"),
                keywords: [Tr.mark("toast"), Tr.mark("keyboard"), Tr.mark("layout"), Tr.mark("limit"), Tr.mark("xkb"), Tr.mark("warning")],
                type: "bool"
            },
            // caelestia4: Advanced section of Notifications: how far a pop-up is dragged (Notification.qml,
            // sidebar/NotifDockList.qml, NotifGroupList.qml)
            "c:notifs.clearThreshold": {
                route: "services/notifications",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Swipe to dismiss distance"),
                desc: Tr.mark("How far a notification must be swiped sideways, as a share of its width, before it is dismissed"),
                keywords: [Tr.mark("notifications"), Tr.mark("swipe"), Tr.mark("drag"), Tr.mark("dismiss"), Tr.mark("clear"), Tr.mark("threshold")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.1,
                max: 0.9,
                step: 0.05,
                advanced: true
            },
            "c:notifs.expandThreshold": {
                route: "services/notifications",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Drag to expand distance"),
                desc: Tr.mark("How far a notification must be dragged up or down before it expands or collapses"),
                keywords: [Tr.mark("notifications"), Tr.mark("drag"), Tr.mark("expand"), Tr.mark("threshold"), Tr.mark("swipe")],
                type: "int",
                unit: "px",
                min: 5,
                max: 200,
                step: 5,
                advanced: true
            },
            "c:notifs.actionOnClick": {
                route: "services/notifications",
                section: Tr.mark("Pop-ups"),
                title: Tr.mark("Click runs the app's action"),
                desc: Tr.mark("Off: clicking only expands the notification"),
                keywords: [Tr.mark("notifications"), Tr.mark("click"), Tr.mark("action"), Tr.mark("open"), Tr.mark("default")],
                type: "bool"
            },

            // Services > Polling & tuning (pages/services/ServicesPolling.qml)
            // caelestia4: the polling intervals are all stored in ms; each row shows seconds (scale 0.001, min/max/step
            // stay in ms), so they read the same way
            "c:dashboard.mediaUpdateInterval": {
                route: "services/polling",
                section: Tr.mark("Polling"),
                title: Tr.mark("Media refresh"),
                desc: Tr.mark("How often the media position updates. Lower is smoother but uses more CPU"),
                keywords: [Tr.mark("media"), Tr.mark("refresh"), Tr.mark("interval"), Tr.mark("polling"), Tr.mark("position"), Tr.mark("progress")],
                type: "int",
                unit: "s",
                scale: 0.001,
                min: 100,
                max: 2000,
                step: 100
            },
            "c:dashboard.resourceUpdateInterval": {
                route: "services/polling",
                section: Tr.mark("Polling"),
                title: Tr.mark("Dashboard stats refresh"),
                // TRANSLATORS: CPU and GPU are hardware abbreviations, leave them untranslated
                desc: Tr.mark("How often CPU, memory and GPU use update in the dashboard. Lower uses more CPU"),
                keywords: [Tr.mark("cpu"), Tr.mark("memory"), Tr.mark("ram"), Tr.mark("gpu"), Tr.mark("stats"), Tr.mark("resources"), Tr.mark("refresh"), Tr.mark("interval"), Tr.mark("polling")],
                type: "int",
                unit: "s",
                scale: 0.001,
                min: 500,
                max: 10000,
                step: 500
            },
            "c:services.visualiserBars": {
                route: "services/polling",
                section: Tr.mark("Service tuning"),
                // TRANSLATORS: bars of a spectrum analyser, not the taskbar
                title: Tr.mark("Visualiser bars"),
                desc: Tr.mark("Number of bars in the audio visualisers. More bars use more CPU"),
                keywords: [Tr.mark("visualiser"), Tr.mark("visualizer"), Tr.mark("bars"), Tr.mark("spectrum"), Tr.mark("audio"), Tr.mark("cava")],
                type: "int",
                min: 10,
                max: 120,
                step: 2
            },
            "c:services.smartScheme": {
                route: "services/polling",
                section: Tr.mark("Service tuning"),
                title: Tr.mark("Smart colour scheme"),
                desc: Tr.mark("Derive theme mode and variant from the wallpaper"),
                keywords: [Tr.mark("colour"), Tr.mark("color"), Tr.mark("scheme"), Tr.mark("theme"), Tr.mark("wallpaper"), Tr.mark("dark"), Tr.mark("light"), Tr.mark("auto")],
                type: "bool"
            },
            "c:services.gpuType": {
                route: "services/polling",
                section: Tr.mark("Service tuning"),
                // TRANSLATORS: GPU is a hardware abbreviation, leave it untranslated
                title: Tr.mark("GPU"),
                desc: Tr.mark("Override for GPU type"),
                keywords: [Tr.mark("gpu"), Tr.mark("graphics"), Tr.mark("nvidia"), Tr.mark("amd"), Tr.mark("intel"), Tr.mark("monitoring"), Tr.mark("stats")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.markCtx("Auto", "gpu type")
                    },
                    {
                        value: 1,
                        label: "NVIDIA"
                    },
                    {
                        value: 2,
                        label: Tr.markCtx("Generic", "gpu type")
                    },
                    {
                        value: 3,
                        label: Tr.markCtx("None", "gpu type")
                    }
                ]
            },

            // caelestia4: Advanced section of Polling & tuning
            "e4:resources.historyLength": {
                route: "services/polling",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Resource graph length"),
                desc: Tr.mark("How many past readings the overlay's resource graphs keep. Each reading is one widget and overlay stats refresh"),
                keywords: [Tr.mark("cpu"), Tr.mark("memory"), Tr.mark("resources"), Tr.mark("graph"), Tr.mark("history"), Tr.mark("samples"), Tr.mark("overlay")],
                type: "int",
                min: 10,
                max: 600,
                step: 10,
                advanced: true
            },
            "e4:bar.weather.fetchInterval": {
                route: "services/polling",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Weather refresh"),
                desc: Tr.mark("How often the desktop weather and clock widgets fetch the weather"),
                keywords: [Tr.mark("weather"), Tr.mark("refresh"), Tr.mark("interval"), Tr.mark("polling"), Tr.mark("forecast"), Tr.mark("widget")],
                type: "int",
                unit: "min",
                min: 5,
                max: 180,
                step: 5,
                advanced: true
            },

            // Services > Media & music recognition (pages/services/ServicesMedia.qml)
            "c:services.lyricsBackend": {
                route: "services/media",
                section: Tr.mark("Media & lyrics"),
                title: Tr.mark("Lyrics backend"),
                desc: Tr.mark("Source used to fetch synced lyrics"),
                keywords: [Tr.mark("lyrics"), Tr.mark("backend"), Tr.mark("source"), Tr.mark("lrclib"), Tr.mark("netease"), Tr.mark("kugou"), Tr.mark("qq music"), Tr.mark("karaoke")],
                type: "enum",
                // Ordered to match config::LyricsBackend (Auto, Local, LRCLIB, NetEase, Kugou, QQMusic)
                options: [
                    {
                        value: 0,
                        label: Tr.markCtx("Auto", "lyrics backend")
                    },
                    {
                        value: 1,
                        label: Tr.markCtx("Local", "lyrics backend")
                    },
                    {
                        value: 2,
                        label: "LRCLIB"
                    },
                    {
                        value: 3,
                        label: "NetEase"
                    },
                    {
                        value: 4,
                        label: "Kugou"
                    },
                    {
                        value: 5,
                        label: "QQ Music"
                    }
                ]
            },
            "c:services.defaultPlayer": {
                route: "services/media",
                section: Tr.mark("Media & lyrics"),
                title: Tr.mark("Default player"),
                desc: Tr.mark("Preferred media player when several are open"),
                keywords: [Tr.mark("media"), Tr.mark("player"), Tr.mark("default"), Tr.mark("music"), Tr.mark("spotify"), Tr.mark("mpris")],
                type: "string"
            },
            "e4:musicRecognition.timeout": {
                route: "services/media",
                section: Tr.mark("Music recognition"),
                title: Tr.mark("Give up after"),
                desc: Tr.mark("How long to listen before saying no song was found"),
                keywords: [Tr.mark("music"), Tr.mark("recognition"), Tr.mark("song"), Tr.mark("identify"), Tr.mark("shazam"), Tr.mark("songrec"), Tr.mark("timeout")],
                type: "int",
                unit: "s",
                min: 5,
                max: 120,
                step: 1
            },
            "e4:musicRecognition.interval": {
                route: "services/media",
                section: Tr.mark("Music recognition"),
                title: Tr.mark("Listen again every"),
                desc: Tr.mark("Time between tries while listening. Lower finds songs sooner but uses more CPU"),
                keywords: [Tr.mark("music"), Tr.mark("recognition"), Tr.mark("song"), Tr.mark("identify"), Tr.mark("shazam"), Tr.mark("songrec"), Tr.mark("interval")],
                type: "int",
                unit: "s",
                min: 1,
                max: 30,
                step: 1
            },

            // caelestia4: Advanced section of Media
            "c:services.playerAliases": {
                route: "services/media",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Player names"),
                desc: Tr.mark("Show a media player under another name, such as YT Music for com.github.th_ch.youtube_music"),
                keywords: [Tr.mark("media"), Tr.mark("player"), Tr.mark("alias"), Tr.mark("name"), Tr.mark("rename"), Tr.mark("mpris"), Tr.mark("identity")],
                type: "list",
                fields: [
                    {
                        key: "from",
                        title: Tr.mark("Player"),
                        type: "string"
                    },
                    {
                        key: "to",
                        title: Tr.mark("Shown as"),
                        type: "string"
                    }
                ],
                advanced: true
            },
            "c:paths.lyricsDir": {
                route: "services/media",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Lyrics folder"),
                desc: Tr.mark("Where local .lrc lyrics files are looked for"),
                keywords: [Tr.mark("lyrics"), Tr.mark("folder"), Tr.mark("directory"), Tr.mark("path"), Tr.mark("lrc"), Tr.mark("local"), Tr.mark("karaoke")],
                type: "path",
                pathMode: "folder",
                advanced: true
            },
            "e4:media.filterDuplicatePlayers": {
                route: "services/media",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Hide duplicate players"),
                desc: Tr.mark("The desktop media widget hides copies of the same player, such as a browser that also shows through Plasma browser integration or playerctld"),
                keywords: [Tr.mark("media"), Tr.mark("player"), Tr.mark("duplicate"), Tr.mark("mpris"), Tr.mark("browser"), Tr.mark("plasma"), Tr.mark("playerctld"), Tr.mark("widget")],
                type: "bool",
                advanced: true
            },

            // Services > Screenshots & recording (pages/services/ServicesCapture.qml)
            "e4:screenSnip.savePath": {
                route: "services/capture",
                section: Tr.mark("Saving"),
                title: Tr.mark("Save screenshots to"),
                desc: Tr.mark("Empty: copy to the clipboard only"),
                keywords: [Tr.mark("screenshot"), Tr.mark("save"), Tr.mark("folder"), Tr.mark("path"), Tr.mark("directory"), Tr.mark("capture"), Tr.mark("snip")],
                type: "path",
                pathMode: "folder"
            },
            "e4:screenRecord.savePath": {
                route: "services/capture",
                section: Tr.mark("Saving"),
                title: Tr.mark("Save recordings to"),
                desc: Tr.mark("Folder for screen recordings. Made if it doesn't exist yet"),
                keywords: [Tr.mark("recording"), Tr.mark("screen record"), Tr.mark("video"), Tr.mark("save"), Tr.mark("folder"), Tr.mark("path"), Tr.mark("directory")],
                type: "path",
                pathMode: "folder",
                // Config.qml computes it, so E4Defaults.js has none
                default: E4C.Directories.videos.replace("file://", "")
            },
            "e4:search.imageSearch.useCircleSelection": {
                route: "services/capture",
                section: Tr.mark("Region selector"),
                title: Tr.mark("Circle to search"),
                desc: Tr.mark("Google Lens starts with a freehand circle instead of a rectangle"),
                keywords: [Tr.mark("circle"), Tr.mark("search"), Tr.mark("google lens"), Tr.mark("image search"), Tr.mark("selection"), Tr.mark("freehand")],
                type: "bool"
            },
            "e4:regionSelector.targetRegions.windows": {
                route: "services/capture",
                section: Tr.mark("Region selector"),
                title: Tr.mark("Highlight windows to capture"),
                desc: Tr.mark("Click a highlighted window to select it"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("window"), Tr.mark("highlight"), Tr.mark("screenshot"), Tr.mark("capture")],
                type: "bool"
            },
            "e4:regionSelector.rect.showAimLines": {
                route: "services/capture",
                section: Tr.mark("Region selector"),
                title: Tr.mark("Aim lines"),
                desc: Tr.mark("Show lines through the cursor while selecting a region"),
                keywords: [Tr.mark("aim"), Tr.mark("lines"), Tr.mark("crosshair"), Tr.mark("guides"), Tr.mark("region"), Tr.mark("selector"), Tr.mark("screenshot")],
                type: "bool"
            },

            "e4:regionSelector.annotation.useSatty": {
                route: "services/capture",
                section: Tr.mark("Saving"),
                title: Tr.mark("Edit with Satty"),
                desc: Tr.mark("The region selector's Edit action opens Satty instead of Swappy"),
                keywords: [Tr.mark("screenshot"), Tr.mark("edit"), Tr.mark("annotate"), Tr.mark("draw"), Tr.mark("satty"), Tr.mark("swappy"), Tr.mark("markup")],
                type: "bool"
            },
            "e4:regionSelector.targetRegions.layers": {
                route: "services/capture",
                section: Tr.mark("Region selector"),
                title: Tr.mark("Highlight other apps' panels"),
                desc: Tr.mark("Panels of other programs, such as docks and widgets, can be clicked to select them. The shell's own bar and panels are never picked"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("layer"), Tr.mark("panel"), Tr.mark("bar"), Tr.mark("highlight"), Tr.mark("screenshot"), Tr.mark("capture")],
                type: "bool"
            },
            "e4:regionSelector.targetRegions.content": {
                route: "services/capture",
                section: Tr.mark("Region selector"),
                title: Tr.mark("Highlight pictures and text"),
                desc: Tr.mark("Suggest areas found inside windows, such as images and blocks of text"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("content"), Tr.mark("image"), Tr.mark("text"), Tr.mark("detect"), Tr.mark("highlight"), Tr.mark("screenshot")],
                type: "bool"
            },
            // caelestia4: Advanced section of Screenshots & recording
            "e4:regionSelector.targetRegions.showLabel": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Name highlighted areas"),
                desc: Tr.mark("Show the window or panel name on each highlighted area"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("label"), Tr.mark("name"), Tr.mark("title"), Tr.mark("highlight")],
                type: "bool",
                advanced: true
            },
            "e4:regionSelector.targetRegions.opacity": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Window highlight strength"),
                desc: Tr.mark("How strongly windows and panels are highlighted"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("opacity"), Tr.mark("highlight"), Tr.mark("window"), Tr.mark("transparency")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                advanced: true
            },
            "e4:regionSelector.targetRegions.contentRegionOpacity": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Picture and text highlight strength"),
                desc: Tr.mark("How strongly the areas found inside windows are highlighted"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("opacity"), Tr.mark("highlight"), Tr.mark("content"), Tr.mark("transparency")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                advanced: true,
                requires: {
                    id: "e4:regionSelector.targetRegions.content",
                    value: true
                }
            },
            "e4:regionSelector.targetRegions.selectionPadding": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Margin around picked areas"),
                desc: Tr.mark("Extra space added around a highlighted area you click, so its borders are not cut off"),
                keywords: [Tr.mark("region"), Tr.mark("selector"), Tr.mark("padding"), Tr.mark("margin"), Tr.mark("border"), Tr.mark("screenshot")],
                type: "int",
                unit: "px",
                min: 0,
                max: 50,
                step: 1,
                advanced: true
            },
            "e4:regionSelector.circle.strokeWidth": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Circle line width"),
                desc: Tr.mark("Thickness of the line you draw for circle to search"),
                keywords: [Tr.mark("circle"), Tr.mark("search"), Tr.mark("stroke"), Tr.mark("line"), Tr.mark("width"), Tr.mark("thickness"), Tr.mark("google lens")],
                type: "int",
                unit: "px",
                min: 1,
                max: 30,
                step: 1,
                advanced: true
            },
            "e4:regionSelector.circle.padding": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Margin around circles"),
                desc: Tr.mark("Extra space added around a circle to search selection"),
                keywords: [Tr.mark("circle"), Tr.mark("search"), Tr.mark("padding"), Tr.mark("margin"), Tr.mark("google lens")],
                type: "int",
                unit: "px",
                min: 0,
                max: 100,
                step: 1,
                advanced: true
            },
            "e4:search.imageSearch.imageSearchEngineBaseUrl": {
                route: "services/capture",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Image search address"),
                desc: Tr.mark("The Search action opens this address with the picture's link added at the end"),
                keywords: [Tr.mark("image search"), Tr.mark("reverse"), Tr.mark("google lens"), Tr.mark("url"), Tr.mark("engine"), Tr.mark("search")],
                type: "string",
                validate: "^https?://\\S+$",
                advanced: true
            },

            // caelestia4: Services > Polling (pages/services/ServicesPolling.qml). end-4's resource monitor
            // (services/ResourceUsage.qml), a second poller next to Caelestia's dashboard one above: both run, so both
            // rows stay, titled by where the numbers show
            "e4:resources.updateInterval": {
                route: "services/polling",
                section: Tr.mark("Polling"),
                title: Tr.mark("Widget and overlay stats refresh"),
                desc: Tr.mark("How often CPU and memory use update in the desktop resources widget and the overlay. Lower uses more CPU"),
                keywords: [Tr.mark("cpu"), Tr.mark("memory"), Tr.mark("ram"), Tr.mark("resources"), Tr.mark("refresh"), Tr.mark("interval"), Tr.mark("polling"), Tr.mark("widget"), Tr.mark("overlay")],
                type: "int",
                unit: "s",
                scale: 0.001,
                min: 500,
                max: 10000,
                step: 500
            },

            // Services > Advanced (pages/services/ServicesAdvanced.qml)
            "e4:networking.userAgent": {
                route: "services/advanced",
                section: Tr.mark("Network"),
                title: Tr.mark("Web user agent"),
                desc: Tr.mark("Sent to services that require one (image boards, weather)"),
                keywords: [Tr.mark("user agent"), Tr.mark("browser"), Tr.mark("http"), Tr.mark("web"), Tr.mark("network"), Tr.mark("useragent")],
                type: "string"
            },

            // caelestia4: scrolling in the shell's lists (end-4's StyledFlickable / StyledListView, the base of
            // Caelestia's scroll views). The speeds are only used while the toggle is on
            "e4:interactions.scrolling.fasterTouchpadScroll": {
                route: "services/advanced",
                section: Tr.mark("Scrolling"),
                title: Tr.mark("Custom scroll speed"),
                desc: Tr.mark("Lists in the shell's panels scroll by the speeds below, for both mouse wheels and touchpads"),
                keywords: [Tr.mark("scroll"), Tr.mark("speed"), Tr.mark("touchpad"), Tr.mark("mouse"), Tr.mark("wheel"), Tr.mark("faster"), Tr.mark("smooth")],
                type: "bool"
            },
            "e4:interactions.scrolling.mouseScrollFactor": {
                route: "services/advanced",
                section: Tr.mark("Scrolling"),
                title: Tr.mark("Mouse wheel speed"),
                desc: Tr.mark("How far one wheel notch scrolls"),
                keywords: [Tr.mark("scroll"), Tr.mark("speed"), Tr.mark("mouse"), Tr.mark("wheel"), Tr.mark("notch")],
                type: "int",
                unit: "px",
                min: 20,
                max: 500,
                step: 10,
                requires: {
                    id: "e4:interactions.scrolling.fasterTouchpadScroll",
                    value: true
                }
            },
            "e4:interactions.scrolling.touchpadScrollFactor": {
                route: "services/advanced",
                section: Tr.mark("Scrolling"),
                title: Tr.mark("Touchpad speed"),
                desc: Tr.mark("How far a list moves for a swipe as long as one wheel notch"),
                keywords: [Tr.mark("scroll"), Tr.mark("speed"), Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("swipe")],
                // caelestia4: StyledFlickable moves (swipe delta / wheel detection value) × this, in px: with the
                // detection at 120 (one notch), it is the px for a swipe as long as one notch
                type: "int",
                unit: "px",
                min: 50,
                max: 1500,
                step: 50,
                requires: {
                    id: "e4:interactions.scrolling.fasterTouchpadScroll",
                    value: true
                }
            },
            "e4:conflictKiller.autoKillNotificationDaemons": {
                route: "services/advanced",
                section: Tr.mark("Conflicting programs"),
                title: Tr.mark("Stop other notification apps"),
                desc: Tr.mark("At startup, quit mako or dunst without asking. Off: a dialog asks"),
                keywords: [Tr.mark("conflict"), Tr.mark("notification"), Tr.mark("daemon"), Tr.mark("mako"), Tr.mark("dunst"), Tr.mark("kill"), Tr.mark("startup")],
                type: "bool",
                // caelestia4: ConflictKiller checks once, when the shell starts
                applies: "relogin"
            },
            // caelestia4: finer rows of Services > Advanced, in their own groups (no Advanced section on the advanced page)
            "e4:interactions.scrolling.mouseScrollDeltaThreshold": {
                route: "services/advanced",
                section: Tr.mark("Scrolling"),
                title: Tr.mark("Mouse wheel detection"),
                desc: Tr.mark("A scroll step at least this big counts as a mouse wheel, smaller ones as a touchpad. Higher also scrolls less per wheel click. 120 suits most mice"),
                keywords: [Tr.mark("scroll"), Tr.mark("mouse"), Tr.mark("wheel"), Tr.mark("touchpad"), Tr.mark("delta"), Tr.mark("threshold"), Tr.mark("detect")],
                type: "int",
                min: 10,
                max: 480,
                step: 10,
                requires: {
                    id: "e4:interactions.scrolling.fasterTouchpadScroll",
                    value: true
                }
            },
            "e4:interactions.scrolling.touchpadSensitivity": {
                route: "services/advanced",
                section: Tr.mark("Scrolling"),
                title: Tr.mark("Touchpad sensitivity"),
                desc: Tr.mark("Extra touchpad speed for lists inside desktop widgets, such as the world clock's city list"),
                keywords: [Tr.mark("scroll"), Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("sensitivity"), Tr.mark("speed"), Tr.mark("widget")],
                type: "real",
                min: 0.5,
                max: 10,
                step: 0.5,
                requires: {
                    id: "e4:interactions.scrolling.fasterTouchpadScroll",
                    value: true
                }
            },
            "e4:windows.showTitlebar": {
                route: "services/advanced",
                section: Tr.mark("Conflicting programs"),
                title: Tr.mark("Title bar on the conflict dialog"),
                desc: Tr.mark("The dialog that asks to stop conflicting programs shows a title and a close button"),
                keywords: [Tr.mark("title bar"), Tr.mark("titlebar"), Tr.mark("dialog"), Tr.mark("conflict"), Tr.mark("window"), Tr.mark("decoration")],
                type: "bool"
            },
            "e4:windows.centerTitle": {
                route: "services/advanced",
                section: Tr.mark("Conflicting programs"),
                title: Tr.mark("Centre the dialog title"),
                desc: Tr.mark("Off: the title sits on the left"),
                keywords: [Tr.mark("title"), Tr.mark("centre"), Tr.mark("center"), Tr.mark("dialog"), Tr.mark("conflict"), Tr.mark("align")],
                type: "bool",
                requires: {
                    id: "e4:windows.showTitlebar",
                    value: true
                }
            },
            "e4:hacks.arbitraryRaceConditionDelay": {
                route: "services/advanced",
                section: Tr.mark("Workarounds"),
                title: Tr.mark("Clipboard and colour reload delay"),
                desc: Tr.mark("Wait this long after a copy before reading the clipboard history, and after new colours are made before loading them. Raise it if new copies or colours are missing; a higher value slows every colour change"),
                keywords: [Tr.mark("clipboard"), Tr.mark("history"), Tr.mark("cliphist"), Tr.mark("delay"), Tr.mark("copy"), Tr.mark("race"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("theme"), Tr.mark("wallpaper")],
                type: "duration",
                unit: "ms",
                min: 0,
                max: 2000
            }
        })
}
