pragma Singleton

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages
import qs.modules.caelestia.nexus.pages.about
import qs.modules.caelestia.nexus.pages.apps
import qs.modules.caelestia.nexus.pages.audio
import qs.modules.caelestia.nexus.pages.hyprland
import qs.modules.caelestia.nexus.pages.bluetooth
import qs.modules.caelestia.nexus.pages.network
import qs.modules.caelestia.nexus.pages.panels
import qs.modules.caelestia.nexus.pages.services
import qs.modules.caelestia.nexus.pages.wallandstyle
import qs.modules.caelestia.nexus.pages.panels.taskbar
import qs.modules.caelestia.nexus.pages.power
import qs.modules.caelestia.nexus.pages.wallandstyle.widgets

QtObject {
    id: root

    readonly property list<Component> pageComps: [
        // Appearance
        Component {
            // Wallpaper & style
            StackPage {
                Component {
                    WallpaperAndStyle {}
                }
                Component {
                    WallpaperSelect {}
                }
                Component {
                    WallpaperCategory {}
                }
                Component {
                    ColourSelect {}
                }
                Component {
                    PresetSelect {} // caelestia4
                }
                Component {
                    LookPage {} // caelestia4: "look"
                }
                Component {
                    WallpaperSourcesPage {} // caelestia4: "sources"
                }
                Component {
                    DesktopPage {} // caelestia4: "desktop"
                }
                Component {
                    FontsPage {} // caelestia4: "fonts"
                }
                // caelestia4: one sub-page per desktop widget ("widget.<key>", opened from Desktop)
                Component {
                    ClockWidgetPage {}
                }
                Component {
                    WeatherWidgetPage {}
                }
                Component {
                    CalendarWidgetPage {}
                }
                Component {
                    MediaWidgetPage {}
                }
                Component {
                    VisualizerWidgetPage {}
                }
                Component {
                    WorldClockWidgetPage {}
                }
                Component {
                    ResourcesWidgetPage {}
                }
                Component {
                    UserCardWidgetPage {}
                }
                Component {
                    NotesWidgetPage {}
                }
                Component {
                    TodoWidgetPage {}
                }
                Component {
                    TimersWidgetPage {}
                }
                Component {
                    CustomTextWidgetPage {}
                }
                Component {
                    CustomImageWidgetPage {}
                }
                Component {
                    ImageCardWidgetPage {}
                }
                Component {
                    StickerWidgetPage {}
                }
                Component {
                    ImagesWidgetPage {}
                }
                Component {
                    TypeScalePage {} // caelestia4: "scale" (Fonts > Type scale)
                }
            }
        },

        // Connectivity
        Component {
            // Display (caelestia4)
            StackPage {
                Component {
                    DisplayPage {}
                }
            }
        },
        Component {
            // Network
            StackPage {
                Component {
                    NetworkPage {}
                }
                Component {
                    EthernetDetailPage {}
                }
                Component {
                    AddNetworkPage {}
                }
                Component {
                    NetworkDetailPage {}
                }
                Component {
                    AddVpnPage {}
                }
                Component {
                    AllNetworksPage {}
                }
                Component {
                    SavedNetworksPage {}
                }
            }
        },
        Component {
            // Bluetooth
            StackPage {
                Component {
                    BluetoothPage {}
                }
                Component {
                    BtDeviceInfo {}
                }
                Component {
                    BluetoothPairing {}
                }
            }
        },
        Component {
            // Audio
            StackPage {
                Component {
                    AudioPage {}
                }
                Component {
                    AppVolumes {}
                }
            }
        },

        // System (caelestia4: upstream has placeholders for Updates and Plugins)
        Component {
            // Power & idle (caelestia4)
            StackPage {
                Component {
                    PowerPage {}
                }
                Component {
                    LockPage {} // caelestia4: "lock"
                }
            }
        },
        Component {
            // Updates
            StackPage {
                Component {
                    UpdatesPage {}
                }
            }
        },
        Component {
            // Plugins: shell components here (upstream's plugin system is unmerged)
            StackPage {
                Component {
                    PluginsPage {}
                }
            }
        },
        Component {
            // Hyprland (caelestia4)
            StackPage {
                Component {
                    HyprlandPage {}
                }
                Component {
                    HyprInputPage {} // caelestia4: "input"
                }
                Component {
                    HyprWindowsPage {} // caelestia4: "windows"
                }
                Component {
                    HyprRenderingPage {} // caelestia4: "rendering"
                }
                Component {
                    KeybindsPage {} // caelestia4: "keybinds"
                }
            }
        },

        // Shell
        Component {
            // Panels
            StackPage {
                Component {
                    PanelsPage {}
                }
                Component {
                    DashboardPanel {}
                }
                Component {
                    TaskbarPanel {}
                }
                Component {
                    LauncherPanel {}
                }
                Component {
                    SidebarPanel {}
                }
                Component {
                    UtilitiesPanel {}
                }

                // Taskbar component sub-pages
                Component {
                    BarWorkspaces {}
                }
                Component {
                    BarActiveWindow {}
                }
                Component {
                    BarTray {}
                }
                Component {
                    BarStatusIcons {}
                }
                Component {
                    BarClock {}
                }
                // caelestia4: 11 bar layout (Taskbar > Layout), 12 session menu (Panels > Session menu)
                Component {
                    BarLayout {}
                }
                Component {
                    SessionPanel {}
                }
                // caelestia4: 13 on-screen display (Panels > OSD)
                Component {
                    OsdPanel {}
                }
                // caelestia4: 14 assistant, 15 overview & overlay, 16 keybind cheatsheet (Panels)
                Component {
                    AssistantPanel {}
                }
                Component {
                    OverviewPanel {}
                }
                Component {
                    CheatsheetPanel {}
                }
            }
        },
        Component {
            // Apps
            StackPage {
                Component {
                    AppsPage {}
                }
                Component {
                    AllApps {}
                }
                Component {
                    AppInfo {}
                }
            }
        },
        Component {
            // Services
            StackPage {
                Component {
                    ServicesPage {}
                }
                Component {
                    NotificationsPage {}
                }
                Component {
                    ServicesPolling {} // caelestia4: "polling"
                }
                Component {
                    ServicesMedia {} // caelestia4: "media"
                }
                Component {
                    ServicesCapture {} // caelestia4: "capture"
                }
                Component {
                    ServicesAdvanced {} // caelestia4: "advanced"
                }
            }
        },
        Component {
            // Language & region
            StackPage {
                Component {
                    LanguageAndRegion {}
                }
            }
        },

        // About
        Component {
            StackPage {
                Component {
                    AboutPage {}
                }
                // caelestia4: about/changed (P6)
                Component {
                    ChangedPage {}
                }
                // caelestia4: about/profiles (named settings profiles)
                Component {
                    ProfilesPage {}
                }
            }
        }
    ]

    readonly property Component placeholderComp: Component {
        PlaceholderComp {}
    }

    component PlaceholderComp: Item {
        property NexusState nState // To avoid the warning from non-existent property

        ColumnLayout {
            anchors.centerIn: parent
            spacing: Tokens.padding.extraSmall

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "handyman"
                color: Colours.palette.m3outlineVariant
                fontStyle: Tokens.font.icon.extraLarge
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("Page under construction")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Tr.tr("This page will be available in a future update.")
                color: Colours.palette.m3outlineVariant
                font: Tokens.font.body.large
            }
        }
    }
}
