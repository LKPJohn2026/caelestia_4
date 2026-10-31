pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    title: Tr.tr("Launcher")
    isSubPage: true

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // General
        SectionHeader {
            first: true
            text: Tr.tr("General")
        }

        ToggleRow {
            first: true
            text: Tr.trCtx("Enabled", "toggle label")
            value: Config.launcher.enabled
            onToggled: GlobalConfig.launcher.enabled = checked
        }

        ToggleRow {
            text: Tr.tr("Show on hover")
            subtext: Tr.tr("Reveal when the cursor reaches the screen edge")
            value: Config.launcher.showOnHover
            onToggled: GlobalConfig.launcher.showOnHover = checked
        }

        TextFieldRow {
            id: prefixRow

            last: true
            label: Tr.tr("Action prefix")
            subtext: Tr.tr("Prefix used to run actions in the launcher")
            errorText: Tr.tr("Prefix must not be alphanumeric")
            value: GlobalConfig.launcher.actionPrefix === ">" ? "" : GlobalConfig.launcher.actionPrefix // TODO: replace with empty only when not loaded once loaded state is exposed
            placeholderText: ">"
            maximumLength: 1
            smallField: true
            validate: /^[^a-zA-Z0-9\s]$/
            onEditingFinished: value => {
                if (!field.valid)
                    return;
                /// TODO: replace with GlobalConfig.launcher.resetOption("actionPrefix") on empty commit when reset is fixed
                GlobalConfig.launcher.actionPrefix = value || ">";
                if (GlobalConfig.launcher.actionPrefix === ">")
                    clear();
            }
        }

        // Display
        SectionHeader {
            text: Tr.tr("Display")
        }

        StepperRow {
            first: true
            label: Tr.tr("Max items shown")
            value: Config.launcher.maxShown
            from: 1
            to: 20
            stepSize: 1
            onMoved: v => GlobalConfig.launcher.maxShown = v
        }

        StepperRow {
            label: Tr.tr("Max wallpapers")
            value: Config.launcher.maxWallpapers
            from: 1
            to: 30
            stepSize: 1
            onMoved: v => GlobalConfig.launcher.maxWallpapers = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Drag threshold")
            subtext: Tr.tr("Pixels dragged before the launcher opens")
            value: Config.launcher.dragThreshold
            from: 0
            to: 200
            stepSize: 5
            onMoved: v => GlobalConfig.launcher.dragThreshold = v
        }

        // Behaviour
        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Vim keybinds")
            subtext: Tr.tr("Navigate results with Ctrl+hjkl")
            value: GlobalConfig.launcher.vimKeybinds
            onToggled: GlobalConfig.launcher.vimKeybinds = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Enable dangerous actions")
            subtext: Tr.tr("Allow actions that shut down or log out")
            value: GlobalConfig.launcher.enableDangerousActions
            onToggled: GlobalConfig.launcher.enableDangerousActions = checked
        }

        // Fuzzy search
        SectionHeader {
            text: Tr.tr("Fuzzy search")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Apps")
            value: GlobalConfig.launcher.useFuzzy.apps
            onToggled: GlobalConfig.launcher.useFuzzy.apps = checked
        }

        ToggleRow {
            text: Tr.tr("Actions")
            value: GlobalConfig.launcher.useFuzzy.actions
            onToggled: GlobalConfig.launcher.useFuzzy.actions = checked
        }

        ToggleRow {
            text: Tr.tr("Schemes")
            value: GlobalConfig.launcher.useFuzzy.schemes
            onToggled: GlobalConfig.launcher.useFuzzy.schemes = checked
        }

        ToggleRow {
            text: Tr.tr("Variants")
            value: GlobalConfig.launcher.useFuzzy.variants
            onToggled: GlobalConfig.launcher.useFuzzy.variants = checked
        }

        ToggleRow {
            last: true
            text: Tr.tr("Wallpapers")
            value: GlobalConfig.launcher.useFuzzy.wallpapers
            onToggled: GlobalConfig.launcher.useFuzzy.wallpapers = checked
        }

        // caelestia4: end-4's search (LauncherSearch, merged into this launcher)
        SectionHeader {
            text: Tr.tr("Search")
        }

        TextFieldRow {
            first: true
            smallField: true
            label: Tr.tr("Run command prefix")
            value: E4C.Config.options.search.prefix.shellCommand
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.search.prefix.shellCommand = v;
            }
        }

        TextFieldRow {
            smallField: true
            label: Tr.tr("Clipboard prefix")
            value: E4C.Config.options.search.prefix.clipboard
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.search.prefix.clipboard = v;
            }
        }

        TextFieldRow {
            smallField: true
            label: Tr.tr("Emoji prefix")
            value: E4C.Config.options.search.prefix.emojis
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.search.prefix.emojis = v;
            }
        }

        TextFieldRow {
            smallField: true
            label: Tr.tr("Calculator prefix")
            value: E4C.Config.options.search.prefix.math
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.search.prefix.math = v;
            }
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Web search address")
            subtext: Tr.tr("Your search text is added at the end")
            value: E4C.Config.options.search.engineBaseUrl
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.search.engineBaseUrl = v;
            }
        }
    }
}
