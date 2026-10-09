import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.models.hyprland

// caelestia4: settings for everything caelestia_4 adds (config.json "caelestia", "panelFamily", shared "dock.pinnedApps")
// plus the Hyprland options it tunes (written to the shell's Hyprland overrides, which load last).
ContentPage {
    forceWidth: true

    // ---------------------------------------------------------------- panel style
    ContentSection {
        icon: "dashboard_customize"
        title: Translation.tr("Panel style")

        ContentSubsection {
            title: Translation.tr("Panel family")
            tooltip: Translation.tr("Also Ctrl+Super+P to cycle")

            ConfigSelectionArray {
                currentValue: Config.options.panelFamily
                onSelected: newValue => {
                    Config.options.panelFamily = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("Caelestia"),
                        icon: "auto_awesome",
                        value: "caelestia"
                    },
                    {
                        displayName: Translation.tr("illogical-impulse"),
                        icon: "toast",
                        value: "ii"
                    },
                    {
                        displayName: Translation.tr("Waffle"),
                        icon: "window",
                        value: "waffle"
                    }
                ]
            }
        }
    }

    // ---------------------------------------------------------------- dock
    ContentSection {
        icon: "call_to_action"
        title: Translation.tr("Dock (Caelestia)")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.caelestia.dock.enable
            onCheckedChanged: {
                Config.options.caelestia.dock.enable = checked;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "keep"
                text: Translation.tr("Keep shown on startup")
                checked: Config.options.caelestia.dock.pinnedOnStartup
                onCheckedChanged: {
                    Config.options.caelestia.dock.pinnedOnStartup = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Pinned: always visible and windows make room for it")
                }
            }
            ConfigSwitch {
                buttonIcon: "vertical_align_bottom"
                text: Translation.tr("Reveal at bottom edge")
                checked: Config.options.caelestia.dock.hoverToReveal
                onCheckedChanged: {
                    Config.options.caelestia.dock.hoverToReveal = checked;
                }
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "desktop_windows"
                text: Translation.tr("Show on empty workspace")
                checked: Config.options.caelestia.dock.revealOnEmptyWorkspace
                onCheckedChanged: {
                    Config.options.caelestia.dock.revealOnEmptyWorkspace = checked;
                }
            }
            ConfigSpinBox {
                icon: "photo_size_select_small"
                text: Translation.tr("Icon size")
                value: Config.options.caelestia.dock.iconSize
                from: 24
                to: 72
                stepSize: 4
                onValueChanged: {
                    Config.options.caelestia.dock.iconSize = value;
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Pinned apps")
            tooltip: Translation.tr("App IDs (window classes), comma separated. Right-click an app in the dock to pin/unpin it.")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("e.g. org.kde.dolphin, kitty, brave-origin")
                text: Config.options.dock.pinnedApps.join(", ")
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    Config.options.dock.pinnedApps = text.split(",").map(s => s.trim()).filter(s => s.length > 0);
                }
            }
        }
    }

    // ---------------------------------------------------------------- utilities drawer
    ContentSection {
        icon: "grid_view"
        title: Translation.tr("Overview (Super+Tab / Alt+Tab)")

        ConfigSwitch {
            buttonIcon: "filter_none"
            text: Translation.tr("Alt+Tab skips empty workspaces")
            checked: Config.options.caelestia.overview.altTabSkipEmpty
            onCheckedChanged: {
                Config.options.caelestia.overview.altTabSkipEmpty = checked;
            }
            StyledToolTip {
                text: Translation.tr("Hold Alt and press Tab to step through workspaces in order, release Alt to switch.\nOn: only workspaces with windows (and the current one). Off: every workspace in the grid.\nGrid size and scale are under Interface > Overview.")
            }
        }
    }

    ContentSection {
        icon: "tune"
        title: Translation.tr("Utilities drawer")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "schedule"
                text: Translation.tr("System card")
                checked: Config.options.caelestia.utilitiesSystem
                onCheckedChanged: {
                    Config.options.caelestia.utilitiesSystem = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Uptime, reload, end-4 settings, session")
                }
            }
            ConfigSwitch {
                buttonIcon: "linear_scale"
                text: Translation.tr("Quick sliders")
                checked: Config.options.caelestia.utilitiesSliders
                onCheckedChanged: {
                    Config.options.caelestia.utilitiesSliders = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Brightness, volume, microphone")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Quick toggles")
            tooltip: Translation.tr("Order and visibility are edited in the drawer (pencil button)")

            RippleButtonWithIcon {
                materialIcon: "restart_alt"
                mainText: Translation.tr("Reset order and visibility (%1 saved)").arg(Config.options.caelestia.quickToggles.length)
                onClicked: {
                    Config.options.caelestia.quickToggles = [];
                }
            }
        }
    }

    // ---------------------------------------------------------------- dashboard
    ContentSection {
        icon: "space_dashboard"
        title: Translation.tr("Dashboard tabs")

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "checklist"
                text: Translation.tr("To do")
                checked: Config.options.caelestia.dashboardTodo
                onCheckedChanged: {
                    Config.options.caelestia.dashboardTodo = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "timer"
                text: Translation.tr("Timer")
                checked: Config.options.caelestia.dashboardTimer
                onCheckedChanged: {
                    Config.options.caelestia.dashboardTimer = checked;
                }
            }
        }
    }

    // ---------------------------------------------------------------- games
    ContentSection {
        icon: "sports_esports"
        title: Translation.tr("Games")

        ConfigSwitch {
            buttonIcon: "volume_off"
            text: Translation.tr("Mute games while in the background")
            checked: Config.options.caelestia.backgroundMute.enable
            onCheckedChanged: {
                Config.options.caelestia.backgroundMute.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("A game's sound is muted while its window isn't focused, and comes back when you click into it")
            }
        }

        ContentSubsection {
            title: Translation.tr("Game window classes (regex)")
            tooltip: Translation.tr("Windows whose class matches are treated as games (background mute). Steam/Proton games are steam_app_<id>.")

            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: "^(steam_app_\\d+|gamescope)$"
                text: Config.options.caelestia.backgroundMute.classes
                wrapMode: TextEdit.Wrap
                onEditingFinished: {
                    try {
                        new RegExp(text);
                        Config.options.caelestia.backgroundMute.classes = text;
                    } catch (e) {
                        text = Config.options.caelestia.backgroundMute.classes; // invalid regex: keep the old one
                    }
                }
            }
        }

        HyprlandConfigOption {
            id: unfocusedFps
            key: "misc:render_unfocused_fps"
        }

        ContentSubsection {
            title: Translation.tr("Background game FPS")
            tooltip: Translation.tr("Frame rate for games rendering while hidden (Hyprland render_unfocused_fps). Games get render_unfocused from custom/rules.lua.")

            ConfigSpinBox {
                icon: "speed"
                text: Translation.tr("Frames per second")
                value: unfocusedFps.value ?? 15
                from: 1
                to: 240
                stepSize: 5
                onValueChanged: {
                    if (unfocusedFps.value !== undefined && value !== unfocusedFps.value)
                        unfocusedFps.setValue(value);
                }
            }
        }
    }

    // ---------------------------------------------------------------- display
    ContentSection {
        icon: "monitor"
        title: Translation.tr("Display")

        HyprlandConfigOption {
            id: vrr
            key: "misc:vrr"
        }

        ContentSubsection {
            title: Translation.tr("Variable refresh rate (VRR)")

            ConfigSelectionArray {
                currentValue: vrr.value
                onSelected: newValue => {
                    vrr.setValue(newValue);
                }
                options: [
                    {
                        displayName: Translation.tr("Off"),
                        icon: "close",
                        value: 0
                    },
                    {
                        displayName: Translation.tr("Always"),
                        icon: "check",
                        value: 1
                    },
                    {
                        displayName: Translation.tr("Fullscreen only"),
                        icon: "fullscreen",
                        value: 2
                    },
                    {
                        displayName: Translation.tr("Fullscreen games"),
                        icon: "sports_esports",
                        value: 3
                    }
                ]
            }
        }
    }

    // ---------------------------------------------------------------- debug
    ContentSection {
        icon: "bug_report"
        title: Translation.tr("Debug")

        ConfigSwitch {
            buttonIcon: "fact_check"
            text: Translation.tr("Log adapter self-test on load")
            checked: Config.options.caelestia.debugProbe
            onCheckedChanged: {
                Config.options.caelestia.debugProbe = checked;
            }
        }
    }
}
