import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Caelestia.Config as CC
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Desktop — the Caelestia panels: desktop clock & weather, bar, dock, dashboard, launcher, notifications, on-screen display,
// utilities drawer, workspace overview, overlay widgets. Caelestia options live in shell.json (CC.GlobalConfig),
// the caelestia4 additions and end-4 services in config.json (Config.options).
ContentPage {
    forceWidth: true

    readonly property var statusIconNames: ({
            lockStatus: [Translation.tr("Caps Lock / Num Lock"), "keyboard_capslock"],
            audio: [Translation.tr("Volume"), "volume_up"],
            microphone: [Translation.tr("Microphone"), "mic"],
            kbLayout: [Translation.tr("Keyboard layout"), "language"],
            network: [Translation.tr("Network"), "wifi"],
            bluetooth: [Translation.tr("Bluetooth"), "bluetooth"],
            battery: [Translation.tr("Battery"), "battery_full"],
            privacy: [Translation.tr("Privacy (mic / screen in use)"), "privacy_tip"],
            updates: [Translation.tr("Updates"), "system_update_alt"]
        })

    ContentSection {
        icon: "schedule"
        title: Translation.tr("Desktop clock & weather")

        SwitchRow {
            icon: "nest_clock_farsight_analog"
            title: Translation.tr("Show the clock on the desktop")
            checked: CC.GlobalConfig.background.desktopClock.enabled
            onToggled: v => CC.GlobalConfig.background.desktopClock.enabled = v
        }

        SwitchRow {
            enabled: CC.GlobalConfig.background.desktopClock.enabled
            icon: "partly_cloudy_day"
            title: Translation.tr("Show the weather beside it")
            description: Translation.tr("Location and units: Apps > Weather")
            checked: Config.options.caelestia.desktopWeather
            onToggled: v => Config.options.caelestia.desktopWeather = v
        }

        ChoiceRow {
            enabled: CC.GlobalConfig.background.desktopClock.enabled
            icon: "picture_in_picture_alt"
            title: Translation.tr("Position")
            options: [
                {
                    label: Translation.tr("Top left"),
                    value: "top-left"
                },
                {
                    label: Translation.tr("Top centre"),
                    value: "top-center"
                },
                {
                    label: Translation.tr("Top right"),
                    value: "top-right"
                },
                {
                    label: Translation.tr("Middle left"),
                    value: "middle-left"
                },
                {
                    label: Translation.tr("Centre"),
                    value: "middle-center"
                },
                {
                    label: Translation.tr("Middle right"),
                    value: "middle-right"
                },
                {
                    label: Translation.tr("Bottom left"),
                    value: "bottom-left"
                },
                {
                    label: Translation.tr("Bottom centre"),
                    value: "bottom-center"
                },
                {
                    label: Translation.tr("Bottom right"),
                    value: "bottom-right"
                }
            ]
            value: CC.GlobalConfig.background.desktopClock.position
            onSelected: v => CC.GlobalConfig.background.desktopClock.position = v
        }

        SliderRow {
            enabled: CC.GlobalConfig.background.desktopClock.enabled
            icon: "format_size"
            title: Translation.tr("Size")
            from: 0.5
            to: 2
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.background.desktopClock.scale
            onMoved: v => CC.GlobalConfig.background.desktopClock.scale = v
        }

        SwitchRow {
            enabled: CC.GlobalConfig.background.desktopClock.enabled
            icon: "rectangle"
            title: Translation.tr("Background behind it")
            description: Translation.tr("A blurred plate, for busy wallpapers")
            checked: CC.GlobalConfig.background.desktopClock.background.enabled
            onToggled: v => CC.GlobalConfig.background.desktopClock.background.enabled = v
        }
    }

    ContentSection {
        icon: "toast"
        title: Translation.tr("Bar")

        SwitchRow {
            icon: "push_pin"
            title: Translation.tr("Always show the bar")
            description: Translation.tr("Off: the bar hides and appears when you move to the screen edge. Super+J toggles it")
            checked: CC.GlobalConfig.bar.persistent
            onToggled: v => CC.GlobalConfig.bar.persistent = v
        }

        SwitchRow {
            enabled: !CC.GlobalConfig.bar.persistent
            icon: "mouse"
            title: Translation.tr("Show on hover")
            checked: CC.GlobalConfig.bar.showOnHover
            onToggled: v => CC.GlobalConfig.bar.showOnHover = v
        }

        SwitchRow {
            icon: "swap_vert"
            title: Translation.tr("Scroll on workspaces to switch")
            checked: CC.GlobalConfig.bar.scrollActions.workspaces
            onToggled: v => CC.GlobalConfig.bar.scrollActions.workspaces = v
        }

        SwitchRow {
            icon: "volume_up"
            title: Translation.tr("Scroll at the top to change volume")
            checked: CC.GlobalConfig.bar.scrollActions.volume
            onToggled: v => CC.GlobalConfig.bar.scrollActions.volume = v
        }

        SwitchRow {
            icon: "brightness_6"
            title: Translation.tr("Scroll at the bottom to change brightness")
            checked: CC.GlobalConfig.bar.scrollActions.brightness
            onToggled: v => CC.GlobalConfig.bar.scrollActions.brightness = v
        }

        SwitchRow {
            icon: "calendar_today"
            title: Translation.tr("Show the date under the clock")
            checked: CC.GlobalConfig.bar.clock.showDate
            onToggled: v => CC.GlobalConfig.bar.clock.showDate = v
        }

        SwitchRow {
            icon: "compress"
            title: Translation.tr("Compact tray")
            description: Translation.tr("Collapse tray icons behind one button")
            checked: CC.GlobalConfig.bar.tray.compact
            onToggled: v => CC.GlobalConfig.bar.tray.compact = v
        }

        SwitchRow {
            icon: "format_color_fill"
            title: Translation.tr("Recolour tray icons")
            description: Translation.tr("Tint app icons in the tray with the theme colour")
            checked: CC.GlobalConfig.bar.tray.recolour
            onToggled: v => CC.GlobalConfig.bar.tray.recolour = v
        }
    }

    ContentSection {
        icon: "workspaces"
        title: Translation.tr("Bar: workspaces")

        SpinRow {
            icon: "filter_9_plus"
            title: Translation.tr("Workspaces shown")
            from: 1
            to: 20
            value: CC.GlobalConfig.bar.workspaces.shown
            onMoved: v => CC.GlobalConfig.bar.workspaces.shown = v
        }

        ChoiceRow {
            icon: "category"
            title: Translation.tr("Style")
            options: [
                {
                    label: Translation.tr("Shapes"),
                    value: CC.BarWorkspaceDisplay.Shapes
                },
                {
                    label: Translation.tr("Numbers"),
                    value: CC.BarWorkspaceDisplay.Text
                },
                {
                    label: Translation.tr("Icons"),
                    value: CC.BarWorkspaceDisplay.Icons
                }
            ]
            value: CC.GlobalConfig.bar.workspaces.displayType
            onSelected: v => CC.GlobalConfig.bar.workspaces.displayType = v
        }

        SwitchRow {
            icon: "apps"
            title: Translation.tr("Show app icons")
            description: Translation.tr("Icons of the windows on each workspace")
            checked: CC.GlobalConfig.bar.workspaces.showWindows
            onToggled: v => CC.GlobalConfig.bar.workspaces.showWindows = v
        }

        SwitchRow {
            icon: "check_box_outline_blank"
            title: Translation.tr("Show empty workspaces")
            checked: CC.GlobalConfig.bar.workspaces.showUnoccupied
            onToggled: v => CC.GlobalConfig.bar.workspaces.showUnoccupied = v
        }

        SwitchRow {
            icon: "monitor"
            title: Translation.tr("Only this monitor's workspaces")
            checked: CC.GlobalConfig.bar.workspaces.perMonitor
            onToggled: v => CC.GlobalConfig.bar.workspaces.perMonitor = v
        }

        SpinRow {
            icon: "keyboard_command_key"
            title: Translation.tr("Hold Super to show numbers after (ms)")
            description: Translation.tr("Workspace numbers appear while Super is held")
            from: 0
            to: 2000
            stepSize: 50
            value: Config.options.bar.workspaces.showNumberDelay
            onMoved: v => Config.options.bar.workspaces.showNumberDelay = v
        }
    }

    ContentSection {
        icon: "widgets"
        title: Translation.tr("Bar: status icons")

        Repeater {
            model: CC.GlobalConfig.bar.statusIcons.values

            SwitchRow {
                required property var modelData
                required property int index

                icon: (statusIconNames[modelData.id] ?? [modelData.id, "circle"])[1]
                title: (statusIconNames[modelData.id] ?? [modelData.id])[0]
                checked: modelData.enabled
                onToggled: v => CC.GlobalConfig.bar.statusIcons.at(index).enabled = v
            }
        }
    }

    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock")

        SwitchRow {
            icon: "dock_to_bottom"
            title: Translation.tr("Dock")
            checked: Config.options.caelestia.dock.enable
            onToggled: v => Config.options.caelestia.dock.enable = v
        }

        SwitchRow {
            enabled: Config.options.caelestia.dock.enable
            icon: "push_pin"
            title: Translation.tr("Keep shown after login")
            description: Translation.tr("Off: the dock stays hidden until you reveal it")
            checked: Config.options.caelestia.dock.pinnedOnStartup
            onToggled: v => Config.options.caelestia.dock.pinnedOnStartup = v
        }

        SwitchRow {
            enabled: Config.options.caelestia.dock.enable
            icon: "mouse"
            title: Translation.tr("Reveal at the bottom edge")
            checked: Config.options.caelestia.dock.hoverToReveal
            onToggled: v => Config.options.caelestia.dock.hoverToReveal = v
        }

        SwitchRow {
            enabled: Config.options.caelestia.dock.enable
            icon: "check_box_outline_blank"
            title: Translation.tr("Show on empty workspaces")
            checked: Config.options.caelestia.dock.revealOnEmptyWorkspace
            onToggled: v => Config.options.caelestia.dock.revealOnEmptyWorkspace = v
        }

        SpinRow {
            enabled: Config.options.caelestia.dock.enable
            icon: "photo_size_select_large"
            title: Translation.tr("Icon size (px)")
            from: 24
            to: 96
            stepSize: 2
            value: Config.options.caelestia.dock.iconSize
            onMoved: v => Config.options.caelestia.dock.iconSize = v
        }

        TextRow {
            enabled: Config.options.caelestia.dock.enable
            icon: "keep"
            title: Translation.tr("Pinned apps")
            description: Translation.tr("App IDs, comma separated (e.g. org.kde.dolphin, kitty)")
            fieldWidth: 340
            value: (Config.options.dock.pinnedApps ?? []).join(", ")
            onEdited: v => Config.options.dock.pinnedApps = v.split(",").map(s => s.trim()).filter(s => s.length > 0)
        }
    }

    ContentSection {
        icon: "space_dashboard"
        title: Translation.tr("Dashboard")

        SwitchRow {
            icon: "mouse"
            title: Translation.tr("Open on hover")
            description: Translation.tr("Hovering the top edge opens the dashboard")
            checked: CC.GlobalConfig.dashboard.showOnHover
            onToggled: v => CC.GlobalConfig.dashboard.showOnHover = v
        }

        SwitchRow {
            icon: "music_note"
            title: Translation.tr("Media tab")
            checked: CC.GlobalConfig.dashboard.showMedia
            onToggled: v => CC.GlobalConfig.dashboard.showMedia = v
        }

        SwitchRow {
            icon: "speed"
            title: Translation.tr("Performance tab")
            checked: CC.GlobalConfig.dashboard.showPerformance
            onToggled: v => CC.GlobalConfig.dashboard.showPerformance = v
        }

        SwitchRow {
            icon: "partly_cloudy_day"
            title: Translation.tr("Weather tab")
            checked: CC.GlobalConfig.dashboard.showWeather
            onToggled: v => CC.GlobalConfig.dashboard.showWeather = v
        }

        SwitchRow {
            icon: "checklist"
            title: Translation.tr("To-do tab")
            checked: Config.options.caelestia.dashboardTodo
            onToggled: v => Config.options.caelestia.dashboardTodo = v
        }

        SwitchRow {
            icon: "timer"
            title: Translation.tr("Timer tab")
            description: Translation.tr("Pomodoro and stopwatch")
            checked: Config.options.caelestia.dashboardTimer
            onToggled: v => Config.options.caelestia.dashboardTimer = v
        }
    }

    ContentSection {
        icon: "search"
        title: Translation.tr("Launcher")

        SpinRow {
            icon: "format_list_numbered"
            title: Translation.tr("Results shown")
            from: 3
            to: 20
            value: CC.GlobalConfig.launcher.maxShown
            onMoved: v => CC.GlobalConfig.launcher.maxShown = v
        }

        SwitchRow {
            icon: "keyboard"
            title: Translation.tr("Vim keys")
            description: Translation.tr("Ctrl+J / Ctrl+K to move through results")
            checked: CC.GlobalConfig.launcher.vimKeybinds
            onToggled: v => CC.GlobalConfig.launcher.vimKeybinds = v
        }

        SwitchRow {
            icon: "blur_linear"
            title: Translation.tr("Fuzzy app search")
            description: Translation.tr("Match apps even with typos")
            checked: CC.GlobalConfig.launcher.useFuzzy.apps
            onToggled: v => CC.GlobalConfig.launcher.useFuzzy.apps = v
        }

        TextRow {
            icon: "bolt"
            title: Translation.tr("Actions prefix")
            description: Translation.tr("Start with this to run launcher actions (wallpaper, settings, …)")
            fieldWidth: 80
            value: CC.GlobalConfig.launcher.actionPrefix
            onEdited: v => CC.GlobalConfig.launcher.actionPrefix = v
        }

        TextRow {
            icon: "terminal"
            title: Translation.tr("Run command prefix")
            fieldWidth: 80
            value: Config.options.search.prefix.shellCommand
            onEdited: v => Config.options.search.prefix.shellCommand = v
        }

        TextRow {
            icon: "content_paste"
            title: Translation.tr("Clipboard prefix")
            fieldWidth: 80
            value: Config.options.search.prefix.clipboard
            onEdited: v => Config.options.search.prefix.clipboard = v
        }

        TextRow {
            icon: "mood"
            title: Translation.tr("Emoji prefix")
            fieldWidth: 80
            value: Config.options.search.prefix.emojis
            onEdited: v => Config.options.search.prefix.emojis = v
        }

        TextRow {
            icon: "calculate"
            title: Translation.tr("Calculator prefix")
            fieldWidth: 80
            value: Config.options.search.prefix.math
            onEdited: v => Config.options.search.prefix.math = v
        }

        TextRow {
            icon: "travel_explore"
            title: Translation.tr("Web search address")
            description: Translation.tr("Your search text is added at the end")
            fieldWidth: 340
            value: Config.options.search.engineBaseUrl
            onEdited: v => Config.options.search.engineBaseUrl = v
        }
    }

    ContentSection {
        icon: "notifications"
        title: Translation.tr("Notifications")

        SwitchRow {
            icon: "timer_off"
            title: Translation.tr("Hide popups automatically")
            checked: CC.GlobalConfig.notifs.expire
            onToggled: v => CC.GlobalConfig.notifs.expire = v
        }

        SpinRow {
            enabled: CC.GlobalConfig.notifs.expire
            icon: "hourglass_empty"
            title: Translation.tr("Popup duration (seconds)")
            description: Translation.tr("For notifications that don't set their own")
            from: 1
            to: 60
            value: Math.round(CC.GlobalConfig.notifs.defaultExpireTimeout / 1000)
            onMoved: v => CC.GlobalConfig.notifs.defaultExpireTimeout = v * 1000
        }

        ChoiceRow {
            icon: "fullscreen"
            title: Translation.tr("Popups over fullscreen apps")
            options: [
                {
                    label: Translation.tr("Show"),
                    value: CC.NotifsFullscreen.On
                },
                {
                    label: Translation.tr("Don't show"),
                    value: CC.NotifsFullscreen.Off
                }
            ]
            value: CC.GlobalConfig.notifs.fullscreen
            onSelected: v => CC.GlobalConfig.notifs.fullscreen = v
        }

        SwitchRow {
            icon: "ads_click"
            title: Translation.tr("Click runs the default action")
            description: Translation.tr("Off: clicking only expands the notification")
            checked: CC.GlobalConfig.notifs.actionOnClick
            onToggled: v => CC.GlobalConfig.notifs.actionOnClick = v
        }

        SwitchRow {
            icon: "unfold_more"
            title: Translation.tr("Open expanded")
            checked: CC.GlobalConfig.notifs.openExpanded
            onToggled: v => CC.GlobalConfig.notifs.openExpanded = v
        }

        SwitchRow {
            icon: "mouse"
            title: Translation.tr("Open notification panel on hover")
            description: Translation.tr("Hovering the right edge opens the notification sidebar")
            checked: CC.GlobalConfig.sidebar.showOnHover
            onToggled: v => CC.GlobalConfig.sidebar.showOnHover = v
        }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("On-screen display")

        SwitchRow {
            icon: "slideshow"
            title: Translation.tr("Show when volume or brightness changes")
            checked: CC.GlobalConfig.osd.enabled
            onToggled: v => CC.GlobalConfig.osd.enabled = v
        }

        SpinRow {
            enabled: CC.GlobalConfig.osd.enabled
            icon: "hourglass_empty"
            title: Translation.tr("Hide after (ms)")
            from: 500
            to: 10000
            stepSize: 250
            value: CC.GlobalConfig.osd.hideDelay
            onMoved: v => CC.GlobalConfig.osd.hideDelay = v
        }

        SwitchRow {
            enabled: CC.GlobalConfig.osd.enabled
            icon: "brightness_6"
            title: Translation.tr("Brightness slider")
            checked: CC.GlobalConfig.osd.enableBrightness
            onToggled: v => CC.GlobalConfig.osd.enableBrightness = v
        }

        SwitchRow {
            enabled: CC.GlobalConfig.osd.enabled
            icon: "mic"
            title: Translation.tr("Microphone slider")
            checked: CC.GlobalConfig.osd.enableMicrophone
            onToggled: v => CC.GlobalConfig.osd.enableMicrophone = v
        }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("Utilities drawer")

        SwitchRow {
            icon: "info"
            title: Translation.tr("System card")
            description: Translation.tr("Uptime, reload, settings and session buttons")
            checked: Config.options.caelestia.utilitiesSystem
            onToggled: v => Config.options.caelestia.utilitiesSystem = v
        }

        SwitchRow {
            icon: "linear_scale"
            title: Translation.tr("Volume, microphone and brightness sliders")
            checked: Config.options.caelestia.utilitiesSliders
            onToggled: v => Config.options.caelestia.utilitiesSliders = v
        }

        ButtonRow {
            icon: "restart_alt"
            title: Translation.tr("Quick toggles")
            description: Translation.tr("Order and visibility are edited in the drawer (pencil button). %1 saved").arg((Config.options.caelestia.quickToggles ?? []).length)
            buttonIcon: "restart_alt"
            buttonText: Translation.tr("Reset")
            onClicked: Config.options.caelestia.quickToggles = []
        }

        SwitchRow {
            icon: "notifications_active"
            title: Translation.tr("Toast when audio output changes")
            checked: CC.GlobalConfig.utilities.toasts.audioOutputChanged
            onToggled: v => CC.GlobalConfig.utilities.toasts.audioOutputChanged = v
        }

        SwitchRow {
            icon: "language"
            title: Translation.tr("Toast when keyboard layout changes")
            checked: CC.GlobalConfig.utilities.toasts.kbLayoutChanged
            onToggled: v => CC.GlobalConfig.utilities.toasts.kbLayoutChanged = v
        }

        SwitchRow {
            icon: "keyboard_capslock"
            title: Translation.tr("Toast for Caps Lock / Num Lock")
            checked: CC.GlobalConfig.utilities.toasts.capsLockChanged
            onToggled: v => {
                CC.GlobalConfig.utilities.toasts.capsLockChanged = v;
                CC.GlobalConfig.utilities.toasts.numLockChanged = v;
            }
        }

        SwitchRow {
            icon: "music_note"
            title: Translation.tr("Toast for the song now playing")
            checked: CC.GlobalConfig.utilities.toasts.nowPlaying
            onToggled: v => CC.GlobalConfig.utilities.toasts.nowPlaying = v
        }
    }

    ContentSection {
        icon: "grid_view"
        title: Translation.tr("Workspace overview")

        SpinRow {
            icon: "table_rows"
            title: Translation.tr("Rows")
            from: 1
            to: 5
            value: Config.options.overview.rows
            onMoved: v => Config.options.overview.rows = v
        }

        SpinRow {
            icon: "view_column"
            title: Translation.tr("Columns")
            from: 1
            to: 10
            value: Config.options.overview.columns
            onMoved: v => Config.options.overview.columns = v
        }

        SpinRow {
            icon: "zoom_in"
            title: Translation.tr("Preview size (% of screen)")
            from: 5
            to: 40
            value: Math.round(Config.options.overview.scale * 100)
            onMoved: v => Config.options.overview.scale = v / 100
        }

        SwitchRow {
            icon: "filter_none"
            title: Translation.tr("Alt+Tab skips empty workspaces")
            description: Translation.tr("Hold Alt, press Tab to step through workspaces, release Alt to switch")
            checked: Config.options.caelestia.overview.altTabSkipEmpty
            onToggled: v => Config.options.caelestia.overview.altTabSkipEmpty = v
        }
    }

    ContentSection {
        icon: "layers"
        title: Translation.tr("Overlay widgets (Super+G)")

        SwitchRow {
            icon: "contrast"
            title: Translation.tr("Darken the screen behind")
            checked: Config.options.overlay.darkenScreen
            onToggled: v => Config.options.overlay.darkenScreen = v
        }

        SwitchRow {
            icon: "zoom_out_map"
            title: Translation.tr("Zoom animation when opening")
            checked: Config.options.overlay.openingZoomAnimation
            onToggled: v => Config.options.overlay.openingZoomAnimation = v
        }

        TextRow {
            icon: "my_location"
            title: Translation.tr("Crosshair code")
            description: Translation.tr("In Valorant's format")
            fieldWidth: 340
            value: Config.options.crosshair.code
            onEdited: v => Config.options.crosshair.code = v
        }
    }
}
