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

    // caelestia4: one clock on the desktop: Caelestia's (background.desktopClock) or end-4's cookie / digital clock
    // (background widgets), as in end-4's Settings app (Desktop)
    readonly property string desktopClock: E4C.Config.options.background.widgets.clock.enable ? E4C.Config.options.background.widgets.clock.style : (Config.background.desktopClock.enabled ? "caelestia" : "none")

    readonly property list<MenuItem> clockItems: [
        MenuItem {
            text: "Caelestia"
            value: "caelestia"
        },
        MenuItem {
            text: Tr.tr("Cookie")
            value: "cookie"
        },
        MenuItem {
            text: Tr.tr("Digital")
            value: "digital"
        },
        MenuItem {
            text: Tr.tr("Off")
            value: "none"
        }
    ]

    readonly property list<MenuItem> clockPositionItems: [
        MenuItem {
            text: Tr.tr("Top left")
            value: "top-left"
        },
        MenuItem {
            text: Tr.tr("Top centre")
            value: "top-center"
        },
        MenuItem {
            text: Tr.tr("Top right")
            value: "top-right"
        },
        MenuItem {
            text: Tr.tr("Middle left")
            value: "middle-left"
        },
        MenuItem {
            text: Tr.tr("Centre")
            value: "middle-center"
        },
        MenuItem {
            text: Tr.tr("Middle right")
            value: "middle-right"
        },
        MenuItem {
            text: Tr.tr("Bottom left")
            value: "bottom-left"
        },
        MenuItem {
            text: Tr.tr("Bottom centre")
            value: "bottom-center"
        },
        MenuItem {
            text: Tr.tr("Bottom right")
            value: "bottom-right"
        }
    ]

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

        // caelestia4: Caelestia's appearance scales, frame and fonts (shell.json), which upstream's Nexus has no rows
        // for; the same keys as end-4's Settings app (Appearance), so both stay in step. Percent steppers over 0-2 scales
        SectionHeader {
            text: Tr.tr("Transparency")
        }

        StepperRow {
            first: true
            enabled: Colours.transparency.enabled
            label: Tr.tr("Panel opacity (%)")
            value: Math.round(Config.appearance.transparency.base * 100)
            from: 30
            to: 100
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.transparency.base = v / 100
        }

        StepperRow {
            last: true
            enabled: Colours.transparency.enabled
            label: Tr.tr("Inner layer opacity (%)")
            subtext: Tr.tr("Cards and buttons inside panels")
            value: Math.round(Config.appearance.transparency.layers * 100)
            from: 0
            to: 100
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.transparency.layers = v / 100
        }

        SectionHeader {
            text: Tr.tr("Size & shape")
        }

        StepperRow {
            first: true
            label: Tr.tr("Text size (%)")
            value: Math.round(Config.appearance.font.scale * 100)
            from: 70
            to: 150
            stepSize: 5
            onMoved: v => GlobalConfig.appearance.font.scale = v / 100
        }

        StepperRow {
            label: Tr.tr("Corner roundness (%)")
            value: Math.round(Config.appearance.rounding.scale * 100)
            from: 0
            to: 200
            stepSize: 10
            onMoved: v => GlobalConfig.appearance.rounding.scale = v / 100
        }

        StepperRow {
            label: Tr.tr("Spacing (%)")
            subtext: Tr.tr("Space between items")
            value: Math.round(Config.appearance.spacing.scale * 100)
            from: 50
            to: 200
            stepSize: 10
            onMoved: v => GlobalConfig.appearance.spacing.scale = v / 100
        }

        StepperRow {
            label: Tr.tr("Padding (%)")
            subtext: Tr.tr("Space inside panels and buttons")
            value: Math.round(Config.appearance.padding.scale * 100)
            from: 50
            to: 200
            stepSize: 10
            onMoved: v => GlobalConfig.appearance.padding.scale = v / 100
        }

        StepperRow {
            label: Tr.tr("Animation duration (%)")
            subtext: Tr.tr("Lower is faster; 0 turns panel animations off")
            value: Math.round(Config.appearance.anim.durations.scale * 100)
            from: 0
            to: 200
            stepSize: 10
            onMoved: v => GlobalConfig.appearance.anim.durations.scale = v / 100
        }

        StepperRow {
            label: Tr.tr("Screen frame thickness (px)")
            subtext: Tr.tr("The border around the screen that holds the bar and drawers")
            value: Config.border.thickness
            from: 0
            to: 40
            onMoved: v => GlobalConfig.border.thickness = v
        }

        StepperRow {
            last: true
            label: Tr.tr("Screen frame corner radius (px)")
            value: Config.border.rounding
            from: 0
            to: 80
            onMoved: v => GlobalConfig.border.rounding = v
        }

        SectionHeader {
            text: Tr.tr("Fonts")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Panel font")
            subtext: Tr.tr("Bar, drawers, launcher, notifications")
            value: Config.appearance.font.body.family
            onEditingFinished: v => {
                if (!v.trim() || v.trim() === Config.appearance.font.body.family)
                    return;
                GlobalConfig.appearance.font.headline.family = v.trim();
                GlobalConfig.appearance.font.title.family = v.trim();
                GlobalConfig.appearance.font.body.family = v.trim();
                GlobalConfig.appearance.font.label.family = v.trim();
            }
        }

        TextFieldRow {
            label: Tr.tr("Clock font")
            value: Config.appearance.font.clock
            onEditingFinished: v => {
                if (v.trim() && v.trim() !== Config.appearance.font.clock)
                    GlobalConfig.appearance.font.clock = v.trim();
            }
        }

        TextFieldRow {
            label: Tr.tr("Monospace font")
            value: Config.appearance.font.mono.family
            onEditingFinished: v => {
                if (!v.trim() || v.trim() === Config.appearance.font.mono.family)
                    return;
                GlobalConfig.appearance.font.mono.family = v.trim();
                E4C.Config.options.appearance.fonts.monospace = v.trim(); // caelestia4: end-4 widgets too
            }
        }

        TextFieldRow {
            label: Tr.tr("App font")
            subtext: Tr.tr("Settings app, AI chat, translator and other end-4 widgets")
            value: E4C.Config.options.appearance.fonts.main
            onEditingFinished: v => {
                if (v.trim() && v.trim() !== E4C.Config.options.appearance.fonts.main)
                    E4C.Config.options.appearance.fonts.main = v.trim();
            }
        }

        TextFieldRow {
            last: true
            label: Tr.tr("Reading font")
            subtext: Tr.tr("Long text such as AI answers")
            value: E4C.Config.options.appearance.fonts.reading
            onEditingFinished: v => {
                if (v.trim() && v.trim() !== E4C.Config.options.appearance.fonts.reading)
                    E4C.Config.options.appearance.fonts.reading = v.trim();
            }
        }

        // caelestia4: the folder the launcher, this page and end-4's wallpaper selector list (paths.wallpaperDir)
        SectionHeader {
            text: Tr.tr("Wallpaper folder")
        }

        TextFieldRow {
            first: true
            last: true
            label: Tr.tr("Folder")
            subtext: Tr.tr("~ = your home folder")
            value: GlobalConfig.paths.wallpaperDir
            onEditingFinished: v => {
                if (v.trim())
                    GlobalConfig.paths.wallpaperDir = v.trim();
            }
        }

        // caelestia4: Caelestia's audio visualiser on the desktop (background.visualiser)
        SectionHeader {
            text: Tr.tr("Audio visualiser")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Visualiser on the desktop")
            subtext: Tr.tr("Bars along the bottom of the wallpaper that move with the sound")
            checked: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            disabled: !Config.background.visualiser.enabled
            text: Tr.tr("Only on empty desktops")
            subtext: Tr.tr("Hidden while tiled windows cover the workspace")
            checked: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            disabled: !Config.background.visualiser.enabled
            text: Tr.tr("Blur behind the bars")
            checked: Config.background.visualiser.blur
            onToggled: GlobalConfig.background.visualiser.blur = checked
        }

        StepperRow {
            enabled: Config.background.visualiser.enabled
            label: Tr.tr("Bar roundness")
            value: Config.background.visualiser.rounding
            from: 0
            to: 3
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.visualiser.rounding = v
        }

        StepperRow {
            last: true
            enabled: Config.background.visualiser.enabled
            label: Tr.tr("Gap between bars")
            value: Config.background.visualiser.spacing
            from: 0
            to: 4
            stepSize: 0.1
            onMoved: v => GlobalConfig.background.visualiser.spacing = v
        }

        SectionHeader {
            text: Tr.tr("Desktop clock")
        }

        SelectRow {
            first: true
            last: root.desktopClock !== "caelestia"
            label: Tr.tr("Desktop clock")
            menuItems: root.clockItems
            active: root.clockItems.find(i => i.value === root.desktopClock) ?? null
            onSelected: item => {
                const v = item.value;
                GlobalConfig.background.desktopClock.enabled = v === "caelestia";
                E4C.Config.options.background.widgets.clock.enable = v === "cookie" || v === "digital";
                if (v === "cookie" || v === "digital") {
                    E4C.Config.options.background.widgets.clock.style = v;
                    E4C.Config.options.background.widgets.clock.styleLocked = v;
                }
            }
        }

        ToggleRow {
            visible: root.desktopClock === "caelestia"
            text: Tr.tr("Show the weather beside it")
            subtext: Tr.tr("Location: end-4 Settings > Apps & services; units: Language & region")
            checked: E4C.Config.options.caelestia.desktopWeather
            onToggled: E4C.Config.options.caelestia.desktopWeather = checked
        }

        SelectRow {
            visible: root.desktopClock === "caelestia"
            label: Tr.tr("Position")
            menuItems: root.clockPositionItems
            active: root.clockPositionItems.find(i => i.value === Config.background.desktopClock.position) ?? null
            onSelected: item => GlobalConfig.background.desktopClock.position = item.value
        }

        StepperRow {
            visible: root.desktopClock === "caelestia"
            label: Tr.tr("Size (%)")
            value: Math.round(Config.background.desktopClock.scale * 100)
            from: 50
            to: 200
            stepSize: 10
            onMoved: v => GlobalConfig.background.desktopClock.scale = v / 100
        }

        ToggleRow {
            visible: root.desktopClock === "caelestia"
            last: true
            text: Tr.tr("Background behind it")
            checked: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }
    }
}
