import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Caelestia.Config as CC
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Apps & services — default apps, AI, weather, clock, screenshots, music recognition, keybind cheatsheet,
// language, content policies.
ContentPage {
    forceWidth: true

    ContentSection {
        icon: "apps"
        title: Translation.tr("Default apps")

        TextRow {
            icon: "terminal"
            title: Translation.tr("Terminal")
            description: Translation.tr("Used by the launcher for commands and terminal apps")
            fieldWidth: 260
            value: CC.GlobalConfig.general.apps.terminal.join(" ")
            onEdited: v => CC.GlobalConfig.general.apps.terminal = v.trim().split(/\s+/)
        }

        TextRow {
            icon: "folder"
            title: Translation.tr("File manager")
            fieldWidth: 260
            value: CC.GlobalConfig.general.apps.explorer.join(" ")
            onEdited: v => CC.GlobalConfig.general.apps.explorer = v.trim().split(/\s+/)
        }

        TextRow {
            icon: "tune"
            title: Translation.tr("Volume mixer")
            fieldWidth: 260
            value: CC.GlobalConfig.general.apps.audio.join(" ")
            onEdited: v => CC.GlobalConfig.general.apps.audio = v.trim().split(/\s+/)
        }

        TextRow {
            icon: "monitoring"
            title: Translation.tr("Task manager")
            description: Translation.tr("Session menu and Ctrl+Shift+Esc")
            fieldWidth: 260
            value: Config.options.apps.taskManager
            onEdited: v => Config.options.apps.taskManager = v
        }
    }

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI assistant")

        ChoiceRow {
            icon: "policy"
            title: Translation.tr("Allow AI")
            options: [
                {
                    label: Translation.tr("Yes"),
                    value: 1
                },
                {
                    label: Translation.tr("Local models only"),
                    value: 2
                },
                {
                    label: Translation.tr("No"),
                    value: 0
                }
            ]
            value: Config.options.policies.ai
            onSelected: v => Config.options.policies.ai = v
        }

        ChoiceRow {
            icon: "build"
            title: Translation.tr("What the AI may use")
            options: [
                {
                    label: Translation.tr("Tools (shell, settings)"),
                    value: "functions"
                },
                {
                    label: Translation.tr("Web search"),
                    value: "search"
                },
                {
                    label: Translation.tr("Nothing"),
                    value: "none"
                }
            ]
            value: Config.options.ai.tool
            onSelected: v => Config.options.ai.tool = v
        }

        TextAreaRow {
            icon: "edit_note"
            title: Translation.tr("Instructions for the AI")
            description: Translation.tr("System prompt. {DISTRO}, {DE}, {DATETIME} and {WINDOWCLASS} are filled in")
            value: Config.options.ai.systemPrompt
            onEdited: v => Config.options.ai.systemPrompt = v
        }
    }

    ContentSection {
        icon: "partly_cloudy_day"
        title: Translation.tr("Weather")

        TextRow {
            icon: "location_on"
            title: Translation.tr("Location")
            description: Translation.tr("City name, or empty to detect it automatically")
            fieldWidth: 260
            value: CC.GlobalConfig.services.weatherLocation
            onEdited: v => CC.GlobalConfig.services.weatherLocation = v
        }

        ChoiceRow {
            icon: "thermostat"
            title: Translation.tr("Temperature unit")
            options: [
                {
                    label: Translation.tr("Automatic"),
                    value: CC.TemperatureUnit.Auto
                },
                {
                    label: Translation.tr("Celsius"),
                    value: CC.TemperatureUnit.Celsius
                },
                {
                    label: Translation.tr("Fahrenheit"),
                    value: CC.TemperatureUnit.Fahrenheit
                }
            ]
            value: CC.GlobalConfig.services.weatherUnits
            onSelected: v => CC.GlobalConfig.services.weatherUnits = v
        }
    }

    ContentSection {
        icon: "schedule"
        title: Translation.tr("Date & time")

        ChoiceRow {
            icon: "schedule"
            title: Translation.tr("Clock")
            options: [
                {
                    label: Translation.tr("Automatic"),
                    value: CC.ClockFormat.Auto
                },
                {
                    label: Translation.tr("24-hour"),
                    value: CC.ClockFormat.TwentyFourHour
                },
                {
                    label: Translation.tr("12-hour"),
                    value: CC.ClockFormat.TwelveHour
                }
            ]
            value: CC.GlobalConfig.services.clockFormat
            onSelected: v => CC.GlobalConfig.services.clockFormat = v
        }
    }

    ContentSection {
        icon: "screenshot_region"
        title: Translation.tr("Screenshots & recording")

        TextRow {
            icon: "folder"
            title: Translation.tr("Save screenshots to")
            description: Translation.tr("Empty: copy to the clipboard only")
            fieldWidth: 300
            value: Config.options.screenSnip.savePath
            onEdited: v => Config.options.screenSnip.savePath = v
        }

        TextRow {
            icon: "videocam"
            title: Translation.tr("Save recordings to")
            fieldWidth: 300
            value: Config.options.screenRecord.savePath
            onEdited: v => Config.options.screenRecord.savePath = v
        }

        SwitchRow {
            icon: "gesture"
            title: Translation.tr("Circle to search")
            description: Translation.tr("Google Lens starts with a freehand circle instead of a rectangle")
            checked: Config.options.search.imageSearch.useCircleSelection
            onToggled: v => Config.options.search.imageSearch.useCircleSelection = v
        }

        SwitchRow {
            icon: "web_asset"
            title: Translation.tr("Highlight windows to capture")
            description: Translation.tr("Click a highlighted window to select it")
            checked: Config.options.regionSelector.targetRegions.windows
            onToggled: v => Config.options.regionSelector.targetRegions.windows = v
        }

        SwitchRow {
            icon: "add"
            title: Translation.tr("Aim lines")
            checked: Config.options.regionSelector.rect.showAimLines
            onToggled: v => Config.options.regionSelector.rect.showAimLines = v
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Music recognition")

        SpinRow {
            icon: "hourglass_empty"
            title: Translation.tr("Give up after (seconds)")
            from: 5
            to: 120
            value: Config.options.musicRecognition.timeout
            onMoved: v => Config.options.musicRecognition.timeout = v
        }

        SpinRow {
            icon: "update"
            title: Translation.tr("Listen again every (seconds)")
            from: 1
            to: 30
            value: Config.options.musicRecognition.interval
            onMoved: v => Config.options.musicRecognition.interval = v
        }
    }

    ContentSection {
        icon: "keyboard"
        title: Translation.tr("Keybind cheatsheet (Super+/)")

        SwitchRow {
            icon: "keyboard_command_key"
            title: Translation.tr("macOS-style key symbols")
            description: Translation.tr("⌘ ⌥ ⇧ instead of Super, Alt, Shift")
            checked: Config.options.cheatsheet.useMacSymbol
            onToggled: v => Config.options.cheatsheet.useMacSymbol = v
        }

        SwitchRow {
            icon: "function"
            title: Translation.tr("Symbols for function keys")
            checked: Config.options.cheatsheet.useFnSymbol
            onToggled: v => Config.options.cheatsheet.useFnSymbol = v
        }

        SwitchRow {
            icon: "mouse"
            title: Translation.tr("Symbols for mouse buttons")
            checked: Config.options.cheatsheet.useMouseSymbol
            onToggled: v => Config.options.cheatsheet.useMouseSymbol = v
        }

        SwitchRow {
            icon: "splitscreen_add"
            title: Translation.tr("One key per box")
            checked: Config.options.cheatsheet.splitButtons
            onToggled: v => Config.options.cheatsheet.splitButtons = v
        }
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ChoiceRow {
            icon: "translate"
            title: Translation.tr("Interface language")
            description: Translation.tr("For the settings app, AI chat and other end-4 parts")
            options: [
                {
                    label: Translation.tr("Automatic (system)"),
                    value: "auto"
                },
                ...Translation.allAvailableLanguages.map(l => ({
                            label: l,
                            value: l
                        }))
            ]
            value: Config.options.language.ui
            onSelected: v => Config.options.language.ui = v
        }
    }

    ContentSection {
        icon: "shield_person"
        title: Translation.tr("Content")

        ChoiceRow {
            icon: "pets"
            title: Translation.tr("Anime tab")
            description: Translation.tr("Image boards in the assistant panel")
            options: [
                {
                    label: Translation.tr("Shown"),
                    value: 1
                },
                {
                    label: Translation.tr("Hidden tab"),
                    value: 2
                },
                {
                    label: Translation.tr("Off"),
                    value: 0
                }
            ]
            value: Config.options.policies.weeb
            onSelected: v => Config.options.policies.weeb = v
        }

        SwitchRow {
            icon: "hide_image"
            title: Translation.tr("Hide unsafe images in the clipboard")
            description: Translation.tr("Images copied from adult or anime sites show blurred in clipboard history")
            checked: Config.options.workSafety.enable.clipboard
            onToggled: v => Config.options.workSafety.enable.clipboard = v
        }

        SwitchRow {
            icon: "wallpaper"
            title: Translation.tr("Hide unsafe wallpapers")
            description: Translation.tr("Blur wallpapers whose name suggests adult or anime content")
            checked: Config.options.workSafety.enable.wallpaper
            onToggled: v => Config.options.workSafety.enable.wallpaper = v
        }
    }
}
