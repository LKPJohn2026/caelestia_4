import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Services
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)
import qs.services as E4 // caelestia4: keep (HyprlandConfig.resetMany)

PageBase {
    id: root

    // Lyrics backends, ordered to match config::LyricsBackend (Auto, Local, LRCLIB, NetEase, Kugou, QQMusic)
    readonly property list<MenuItem> lyricsItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "lyrics backend")
        },
        MenuItem {
            text: Tr.trCtx("Local", "lyrics backend")
        },
        MenuItem {
            text: "LRCLIB"
        },
        MenuItem {
            text: "NetEase"
        },
        MenuItem {
            text: "Kugou"
        },
        MenuItem {
            text: "QQ Music"
        }
    ]

    // GPU types, ordered to match config::GpuType (Auto, Nvidia, Generic, None)
    readonly property list<MenuItem> gpuItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "gpu type")
        },
        MenuItem {
            text: "NVIDIA"
        },
        MenuItem {
            text: Tr.trCtx("Generic", "gpu type")
        },
        MenuItem {
            text: Tr.trCtx("None", "gpu type")
        }
    ]

    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || `${Quickshell.env("HOME")}/.config`
    // Every option the Hyprland and Display pages set (end-4's Settings Advanced page resets the same)
    readonly property list<string> hyprKeys: ["general:gaps_in", "general:gaps_out", "general:border_size", "decoration:rounding", "decoration:active_opacity", "decoration:inactive_opacity", "decoration:dim_inactive", "decoration:blur:enabled", "decoration:blur:size", "decoration:blur:passes", "decoration:shadow:enabled", "animations:enabled", "general:layout", "general:resize_on_border", "misc:focus_on_activate", "dwindle:preserve_split", "input:kb_layout", "input:kb_options", "input:repeat_delay", "input:repeat_rate", "input:sensitivity", "input:accel_profile", "input:natural_scroll", "input:touchpad:natural_scroll", "input:follow_mouse", "misc:vrr", "misc:render_unfocused_fps"]

    title: Tr.tr("Services")

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // Detected running players, used as default-player options
        Variants {
            id: playerVariants

            model: [...new Set(Players.list.map(p => Players.getIdentity(p)).filter(id => id))]

            MenuItem {
                required property string modelData

                text: modelData
                icon: modelData === GlobalConfig.services.defaultPlayer ? "check" : ""
                activeIcon: "music_note"
            }
        }

        // Notifications
        SectionHeader {
            first: true
            text: Tr.tr("Notifications")
        }

        NavRow {
            first: true
            last: true
            icon: "notifications"
            text: Tr.tr("Notifications")
            subtext: Tr.tr("Notifications, toasts, timeouts")
            onClicked: root.nState.openSubPage(1)
        }

        // Polling
        SectionHeader {
            text: Tr.tr("Polling")
        }

        StepperRow {
            first: true
            label: Tr.tr("Media refresh")
            // TRANSLATORS: ms is the millisecond unit, leave it untranslated
            subtext: Tr.tr("How often the media position updates (ms)")
            value: GlobalConfig.dashboard.mediaUpdateInterval
            from: 100
            to: 2000
            stepSize: 50
            onMoved: v => GlobalConfig.dashboard.mediaUpdateInterval = v
        }

        StepperRow {
            label: Tr.tr("System stats refresh")
            // TRANSLATORS: CPU and GPU are hardware abbreviations, leave them untranslated
            subtext: Tr.tr("CPU, memory and GPU update interval (seconds)")
            value: GlobalConfig.dashboard.resourceUpdateInterval / 1000
            from: 0.5
            to: 10
            stepSize: 0.5
            onMoved: v => GlobalConfig.dashboard.resourceUpdateInterval = Math.round(v * 1000)
        }

        StepperRow {
            last: true
            label: Tr.tr("Wi-Fi rescan")
            subtext: Tr.tr("How often available networks are rescanned (seconds)")
            value: GlobalConfig.nexus.networkRescanInterval / 1000
            from: 5
            to: 120
            stepSize: 5
            onMoved: v => GlobalConfig.nexus.networkRescanInterval = Math.round(v * 1000)
        }

        // Media & lyrics
        SectionHeader {
            text: Tr.tr("Media & lyrics")
        }

        SelectRow {
            first: true
            label: Tr.tr("Lyrics backend")
            subtext: Tr.tr("Source used to fetch synced lyrics")
            menuItems: root.lyricsItems
            active: root.lyricsItems[Lyrics.preferredBackend] ?? root.lyricsItems[0]
            onSelected: item => Lyrics.preferredBackend = root.lyricsItems.indexOf(item)
        }

        SelectRow {
            last: true
            label: Tr.tr("Default player")
            subtext: Tr.tr("Preferred media player when several are open")
            menuItems: playerVariants.instances
            active: menuItems.find(i => i.text === GlobalConfig.services.defaultPlayer) ?? null
            fallbackIcon: "music_note"
            fallbackText: GlobalConfig.services.defaultPlayer || Tr.trCtx("Auto", "default media player")
            onSelected: item => GlobalConfig.services.defaultPlayer = item.text
        }

        // Input increments
        SectionHeader {
            text: Tr.tr("Input increments")
        }

        StepperRow {
            first: true
            label: Tr.tr("Volume step")
            subtext: Tr.tr("Amount the volume changes per scroll (%)")
            value: Math.round(GlobalConfig.services.audioIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.audioIncrement = v / 100
        }

        StepperRow {
            label: Tr.tr("Brightness step")
            subtext: Tr.tr("Amount the brightness changes per scroll (%)")
            value: Math.round(GlobalConfig.services.brightnessIncrement * 100)
            from: 1
            to: 50
            stepSize: 1
            onMoved: v => GlobalConfig.services.brightnessIncrement = v / 100
        }

        StepperRow {
            last: true
            label: Tr.tr("Max volume")
            subtext: Tr.tr("Upper limit for output volume (%)")
            value: Math.round(GlobalConfig.services.maxVolume * 100)
            from: 50
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.services.maxVolume = v / 100
        }

        // Service tuning
        SectionHeader {
            text: Tr.tr("Service tuning")
        }

        StepperRow {
            first: true
            // TRANSLATORS: bars of a spectrum analyser, not the taskbar
            label: Tr.tr("Visualiser bars")
            subtext: Tr.tr("Number of bars in the audio visualisers")
            value: GlobalConfig.services.visualiserBars
            from: 10
            to: 120
            stepSize: 2
            onMoved: v => GlobalConfig.services.visualiserBars = v
        }

        ToggleRow {
            text: Tr.tr("Smart colour scheme")
            subtext: Tr.tr("Derive theme mode and variant from the wallpaper")
            checked: GlobalConfig.services.smartScheme
            onToggled: GlobalConfig.services.smartScheme = checked
        }

        SelectRow {
            last: true
            label: Tr.tr("GPU")
            subtext: Gpu.name ? Tr.tr("Monitoring: %1").arg(Gpu.name) : Tr.tr("Override for GPU type")
            menuOnTop: true
            menuItems: root.gpuItems
            active: root.gpuItems[GlobalConfig.services.gpuType]
            onSelected: item => GlobalConfig.services.gpuType = root.gpuItems.indexOf(item)
        }

        // caelestia4: end-4's services, from end-4's Settings app (Apps & services, Advanced)
        SectionHeader {
            text: Tr.tr("Screenshots & recording")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Save screenshots to")
            subtext: Tr.tr("Empty: copy to the clipboard only")
            value: E4C.Config.options.screenSnip.savePath
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.screenSnip.savePath = v;
            }
        }

        TextFieldRow {
            label: Tr.tr("Save recordings to")
            value: E4C.Config.options.screenRecord.savePath
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.screenRecord.savePath = v;
            }
        }

        ToggleRow {
            text: Tr.tr("Circle to search")
            subtext: Tr.tr("Google Lens starts with a freehand circle instead of a rectangle")
            checked: E4C.Config.options.search.imageSearch.useCircleSelection
            onToggled: E4C.Config.options.search.imageSearch.useCircleSelection = checked
        }

        ToggleRow {
            text: Tr.tr("Highlight windows to capture")
            subtext: Tr.tr("Click a highlighted window to select it")
            checked: E4C.Config.options.regionSelector.targetRegions.windows
            onToggled: E4C.Config.options.regionSelector.targetRegions.windows = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Aim lines")
            checked: E4C.Config.options.regionSelector.rect.showAimLines
            onToggled: E4C.Config.options.regionSelector.rect.showAimLines = checked
        }

        SectionHeader {
            text: Tr.tr("Music recognition")
        }

        StepperRow {
            first: true
            label: Tr.tr("Give up after (seconds)")
            value: E4C.Config.options.musicRecognition.timeout
            from: 5
            to: 120
            onMoved: v => E4C.Config.options.musicRecognition.timeout = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Listen again every (seconds)")
            value: E4C.Config.options.musicRecognition.interval
            from: 1
            to: 30
            onMoved: v => E4C.Config.options.musicRecognition.interval = v
        }

        SectionHeader {
            text: Tr.tr("Advanced")
        }

        StepperRow {
            first: true
            label: Tr.tr("CPU / memory refresh (ms)")
            subtext: Tr.tr("end-4's resource monitor (overlay, AI tools)")
            value: E4C.Config.options.resources.updateInterval
            from: 500
            to: 10000
            stepSize: 250
            onMoved: v => E4C.Config.options.resources.updateInterval = v
        }

        TextFieldRow {
            label: Tr.tr("Web user agent")
            subtext: Tr.tr("Sent to services that require one (image boards, weather)")
            value: E4C.Config.options.networking.userAgent
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.networking.userAgent = v;
            }
        }

        RowButton {
            icon: "data_object"
            text: Tr.tr("Shell settings (end-4 part)")
            subtext: "~/.config/illogical-impulse/config.json"
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/illogical-impulse/config.json`])
        }

        RowButton {
            icon: "data_object"
            text: Tr.tr("Panel settings (Caelestia part)")
            subtext: "~/.config/caelestia/shell.json"
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/caelestia/shell.json`])
        }

        RowButton {
            icon: "folder_open"
            text: Tr.tr("Your Hyprland config")
            subtext: Tr.tr("~/.config/hypr/custom: keybinds, rules, startup apps")
            onClicked: Quickshell.execDetached(["xdg-open", `${root.configDir}/hypr/custom`])
        }

        RowButton {
            last: true
            icon: "restart_alt"
            text: Tr.tr("Reset window, input and display options")
            subtext: Tr.tr("Undo the Hyprland and Display pages' changes (Hyprland's own config applies again)")
            onClicked: E4.HyprlandConfig.resetMany(root.hyprKeys)
        }
    }
}
