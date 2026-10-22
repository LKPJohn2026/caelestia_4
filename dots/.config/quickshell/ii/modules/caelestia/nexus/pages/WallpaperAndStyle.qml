pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.widgets
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's transparency follows this toggle)

PageBase {
    id: root

    title: Tr.tr("Wallpaper & style")

    // caelestia4: names for Caelestia's wallpaper transitions (enum WallpaperTransition, shell.json
    // background.wallpaperTransition); upstream has no picker for it yet
    readonly property var transitions: [
        {
            id: "ChromaticBloom",
            label: Tr.tr("Chromatic bloom")
        },
        {
            id: "ColourDistance",
            label: Tr.tr("Colour distance")
        },
        {
            id: "Crossfade",
            label: Tr.tr("Crossfade")
        },
        {
            id: "Crosshatch",
            label: Tr.tr("Crosshatch")
        },
        {
            id: "Crosswarp",
            label: Tr.tr("Crosswarp")
        },
        {
            id: "Directional",
            label: Tr.tr("Slide")
        },
        {
            id: "DirectionalWipe",
            label: Tr.tr("Wipe")
        },
        {
            id: "FadeColour",
            label: Tr.tr("Fade through colour")
        },
        {
            id: "Glitch",
            label: Tr.tr("Glitch")
        },
        {
            id: "GlitchDisplace",
            label: Tr.tr("Glitch displace")
        },
        {
            id: "HeatMelt",
            label: Tr.tr("Heat melt")
        },
        {
            id: "InkSplash",
            label: Tr.tr("Ink splash")
        },
        {
            id: "InkwellDrop",
            label: Tr.tr("Ink drop")
        },
        {
            id: "Iris",
            label: Tr.tr("Iris")
        },
        {
            id: "Morph",
            label: Tr.tr("Morph")
        },
        {
            id: "ParametricGlitch",
            label: Tr.tr("Parametric glitch")
        },
        {
            id: "Perlin",
            label: Tr.tr("Perlin noise")
        },
        {
            id: "Pixelate",
            label: Tr.tr("Pixelate")
        },
        {
            id: "PixelfadeWave",
            label: Tr.tr("Pixel wave")
        },
        {
            id: "PlasmaFlow",
            label: Tr.tr("Plasma flow")
        },
        {
            id: "PolkaDotsCurtain",
            label: Tr.tr("Polka-dot curtain")
        },
        {
            id: "PuzzleRight",
            label: Tr.tr("Puzzle")
        },
        {
            id: "RandomSquares",
            label: Tr.tr("Random squares")
        },
        {
            id: "Smoke",
            label: Tr.tr("Smoke")
        },
        {
            id: "SoftWarpFade",
            label: Tr.tr("Soft warp")
        },
        {
            id: "VoronoiShatter",
            label: Tr.tr("Shatter")
        },
        {
            id: "ZoomBlurPull",
            label: Tr.tr("Zoom blur")
        }
    ]
    readonly property string currentTransition: {
        CUtils.dependency(Config.background.wallpaperTransition);
        return CUtils.enumToString(Config.background, "wallpaperTransition");
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.large

        ClipRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height);
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            WallpaperImpl {
                anchors.fill: parent
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }
        }

        ButtonRow {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "wallpaper"
                text: Tr.tr("Wallpapers")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage(1) // Wallpaper page
            }

            IconTextButton {
                icon: "palette"
                text: Tr.tr("Colours")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(3) // Colours page
            }
        }

        DialogSelectButton {
            rootParent: root.flickable
            icon: "animation"
            label: Tr.tr("Transition: %1").arg(root.transitions.find(t => t.id === root.currentTransition)?.label ?? root.currentTransition)
            header: Tr.tr("Wallpaper transition")
            acceptLabel: Tr.trCtx("Apply", "button")
            model: root.transitions

            onAccepted: {
                if (selectedItem)
                    GlobalConfig.background.wallpaperTransition = WallpaperTransition[selectedItem];
            }
        }

        ToggleRow {
            first: true
            text: Tr.tr("Display wallpaper")
            checked: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Transparency")
            // TRANSLATORS: %1/%2 = opacity values from 0 to 1 for the base surface and layered surfaces
            subtext: Tr.tr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            checked: Colours.transparency.enabled
            onToggled: {
                GlobalConfig.appearance.transparency.enabled = checked;
                E4C.Config.options.appearance.transparency.enable = checked; // caelestia4: end-4 parts (AI chat, settings app, overlay) too
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            text: Tr.tr("Dark theme")
            checked: !Colours.light
            onToggled: Colours.setMode(checked ? "dark" : "light")
        }
    }
}
