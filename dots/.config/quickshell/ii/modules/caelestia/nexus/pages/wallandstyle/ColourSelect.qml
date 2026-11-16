pragma ComponentBehavior: Bound

// caelestia4: Colours sub-page (upstream Caelestia ships it as "under construction"). Pick where the desktop's
// colours come from: the wallpaper (end-4's matugen pipeline, with its colour style) or one of Caelestia's preset
// schemes. Both go through the same end-4 outputs (shell, Hyprland, hyprlock, fuzzel, terminals); see
// utils/scripts/scheme.py. Light / dark stays on the parent page ("Dark theme"); "What gets coloured" is at the bottom.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 palette type, switchwall.sh path)

PageBase {
    id: root

    readonly property bool dynamic: Colours.scheme === "dynamic"

    // end-4's palette types ("auto" lets end-4 pick one for the wallpaper)
    readonly property list<MenuItem> styleItems: [
        MenuItem {
            text: Tr.trCtx("Auto", "M3 scheme variant name")
            value: "auto"
        },
        MenuItem {
            text: Tr.trCtx("Tonal Spot", "M3 scheme variant name")
            value: "scheme-tonal-spot"
        },
        MenuItem {
            text: Tr.trCtx("Expressive", "M3 scheme variant name")
            value: "scheme-expressive"
        },
        MenuItem {
            text: Tr.trCtx("Fidelity", "M3 scheme variant name")
            value: "scheme-fidelity"
        },
        MenuItem {
            text: Tr.trCtx("Content", "M3 scheme variant name")
            value: "scheme-content"
        },
        MenuItem {
            text: Tr.trCtx("Fruit Salad", "M3 scheme variant name")
            value: "scheme-fruit-salad"
        },
        MenuItem {
            text: Tr.trCtx("Rainbow", "M3 scheme variant name")
            value: "scheme-rainbow"
        },
        MenuItem {
            text: Tr.trCtx("Neutral", "M3 scheme variant name")
            value: "scheme-neutral"
        },
        MenuItem {
            text: Tr.trCtx("Monochrome", "M3 scheme variant name")
            value: "scheme-monochrome"
        }
    ]

    title: Tr.tr("Colours")
    isSubPage: true

    // Makes the colours again with colour style `type`
    function regen(type: string): void {
        root._regenType = type;
        Qt.callLater(root._regenNow);
    }

    property string _regenType

    // caelestia4: makes the colours from accent colour `hex` ("#rrggbb"), or from the wallpaper when it is ""
    function recolour(hex: string): void {
        const c = hex.replace(/^#/, "");
        if (c && !/^[0-9a-fA-F]{6}$/.test(c))
            return; // switchwall.sh takes 6 hex digits only
        // "#rrggbb" as the row saved it: the script writes the key again, the same way
        Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", c ? "#" + c : "clear", "--mode", Colours.light ? "light" : "dark"]);
    }

    function _regenNow(): void {
        // --type explicitly (config.json is written with a delay); switchwall.sh --type also leaves a preset
        Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--type", root._regenType, "--mode", Colours.light ? "light" : "dark"]);
    }

    Component.onCompleted: Colours.reloadSchemes()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        SectionHeader {
            first: true
            text: Tr.tr("Wallpaper colours")
        }

        // Use the wallpaper's colours (end-4's default)
        ConnectedRect {
            first: true
            Layout.fillWidth: true
            implicitHeight: wallRow.implicitHeight + Tokens.padding.medium * 2

            StateLayer {
                onClicked: Colours.setScheme("dynamic", "")
            }

            RowLayout {
                id: wallRow

                anchors.fill: parent
                anchors.margins: Tokens.padding.medium
                anchors.leftMargin: Tokens.padding.largeIncreased
                anchors.rightMargin: Tokens.padding.largeIncreased
                spacing: Tokens.spacing.medium

                ClipRect {
                    implicitWidth: 96
                    implicitHeight: 54
                    radius: Tokens.rounding.medium
                    color: Colours.tPalette.m3surfaceContainerHigh

                    Image {
                        anchors.fill: parent
                        source: Wallpapers.current
                        sourceSize: Qt.size(width, height)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Follow the wallpaper")
                        font: Tokens.font.body.small
                        elide: Text.ElideRight
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: Tr.tr("Colours are generated from the current wallpaper and change with it")
                        color: Colours.palette.m3outline
                        font: Tokens.font.label.small
                        wrapMode: Text.WordWrap
                    }
                }

                MaterialIcon {
                    text: root.dynamic ? "check_circle" : "radio_button_unchecked"
                    fill: root.dynamic ? 1 : 0
                    color: root.dynamic ? Colours.palette.m3primary : Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.large
                }
            }
        }

        // end-4's colour style; choosing one also switches back to wallpaper colours
        SelectRow {
            id: styleRow

            setting: "e4:appearance.palette.type"
            subtext: root.dynamic ? Tr.tr("How colours are picked from the wallpaper") : Tr.tr("Choosing a style switches back to wallpaper colours")
            menuItems: root.styleItems
            active: root.styleItems.find(i => i.value === E4C.Config.options.appearance.palette.type) ?? root.styleItems[0]
            // The row writes palette.type; this makes the colours again with it. A pick of the style already set
            // changes no value, so it is run from here too (once: regen() runs at most once per event loop turn)
            onSelected: item => root.regen(item.value)

            // caelestia4: and after the row's reset, the page's Reset and Undo, which write the key without `selected`.
            // An Undo is left to registry/RegAppearance.qml, which also runs when this page is gone
            MirrorWatch {
                setting: styleRow.link.s
                onFollow: v => {
                    if (!NexusActions.undoing && typeof v === "string" && v)
                        root.regen(v);
                }
            }
        }

        // caelestia4: an accent colour instead of the wallpaper (switchwall.sh --color; a new wallpaper clears it).
        // The row writes palette.accentColor; this makes the colours from it, or from the wallpaper again when it is
        // cleared (Automatic). An Undo is left to registry/RegAppearance.qml
        ColourRow {
            id: accentRow

            // caelestia4: the same colour in other capitals (scheme.py saves "#FF1814" for the row's "#ff1814") is no
            // change
            function _recolourIfNew(oldValue: var, v: var): void {
                if (NexusActions.undoing || typeof v !== "string" || v.toLowerCase() === String(oldValue ?? "").toLowerCase())
                    return;
                root.recolour(v);
            }

            last: true
            setting: "e4:appearance.palette.accentColor"
            // caelestia4: 6 hex digits only: switchwall.sh and scheme.py make no colours from #AARRGGBB
            field.validate: text => /^#?[0-9a-fA-F]{6}$/.test(text.trim())

            // caelestia4: only Nexus's own writes recolour: the row (a pick, its reset) and the page's Reset. Not every
            // value change: a wallpaper change elsewhere or a preset clears or sets the key too, and switchwall.sh
            // already makes the colours then (a second run here would race it with the old wallpaper)
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    accentRow._recolourIfNew(oldValue, newValue);
                }

                target: accentRow.link.s
            }

            MirrorWatch {
                setting: accentRow.link.s
                onFollow: v => {
                    // The page's Reset writes through its own Setting, inside a NexusActions batch (MirrorWatch fires
                    // only on a real change, so no capitals check here)
                    if (NexusActions._batch !== null && !NexusActions.undoing && typeof v === "string")
                        root.recolour(v);
                }
            }
        }

        SectionHeader {
            text: Tr.tr("Preset schemes")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: Tr.tr("A preset stays when the wallpaper changes. Presets with only one mode keep it when the theme is switched.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.small
            wrapMode: Text.WordWrap
        }

        GridLayout {
            Layout.fillWidth: true
            columns: Math.max(2, Math.floor(width / 190))
            columnSpacing: Tokens.spacing.small
            rowSpacing: Tokens.spacing.small

            Repeater {
                model: Colours.schemes

                SchemeCard {}
            }
        }

        // caelestia4: what follows the colours, and the terminal palette (end-4's colour pipeline, fed by scheme.py
        // bridge). Moved here from Wallpaper & style
        RowGroup {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.largeIncreased - Tokens.spacing.small // as a SectionHeader that isn't first

            SectionHeader {
                text: Tr.tr("What gets coloured")
            }

            ToggleRow {
                setting: "e4:appearance.wallpaperTheming.enableAppsAndShell"
            }

            ToggleRow {
                setting: "e4:appearance.wallpaperTheming.enableQtApps"
            }

            ToggleRow {
                setting: "e4:appearance.wallpaperTheming.enableTerminal"
            }

            ToggleRow {
                setting: "e4:appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode"
            }

            // caelestia4: the terminal palette's fine-tuning (registry: advanced), last on the page
            AdvancedSection {
                StepperRow {
                    setting: "e4:appearance.wallpaperTheming.terminalGenerationProps.harmony"
                }

                StepperRow {
                    setting: "e4:appearance.wallpaperTheming.terminalGenerationProps.termFgBoost"
                }
            }
        }
    }
}
