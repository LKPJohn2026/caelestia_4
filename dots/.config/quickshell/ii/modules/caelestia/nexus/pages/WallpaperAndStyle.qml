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
import qs.services as E4 // caelestia4: keep (HyprlandData: the largest monitor, for random wallpapers)
import Quickshell
import Quickshell.Io

PageBase {
    id: root

    title: Tr.tr("Wallpaper & style")

    // caelestia4: random wallpaper from the internet (scripts/caelestia4/random-wallpaper.sh), as end-4's Settings app
    // (Appearance): a source, and "at least my screen size" / "my screen's shape" from the largest monitor
    readonly property var rw: E4C.Config.options.caelestia.randomWallpaper
    readonly property var biggestScreen: (E4.HyprlandData.monitors ?? []).reduce((best, m) => (m.width * m.height > best.w * best.h ? {
                w: m.width,
                h: m.height
            } : best), {
        w: 0,
        h: 0
    })
    readonly property string screenRatio: {
        const gcd = (a, b) => b ? gcd(b, a % b) : a;
        const w = biggestScreen.w, h = biggestScreen.h;
        return w > 0 ? `${w / gcd(w, h)}:${h / gcd(w, h)}` : "";
    }
    // Anime sources only while the Anime tab is shown (Panels > Assistant)
    readonly property list<MenuItem> randomSourceItems: [
        MenuItem {
            text: Tr.tr("Wallhaven (general & anime)")
            value: "wallhaven"
        },
        MenuItem {
            text: Tr.tr("Konachan (anime)")
            value: "konachan"
        },
        MenuItem {
            text: Tr.tr("yande.re (anime)")
            value: "yandere"
        }
    ]
    readonly property list<MenuItem> shownSourceItems: E4C.Config.options.policies.weeb === 1 ? randomSourceItems : [randomSourceItems[0]]

    readonly property list<MenuItem> placementItems: [
        MenuItem {
            text: Tr.tr("Free")
            value: "free"
        },
        MenuItem {
            text: Tr.tr("Least busy")
            value: "leastBusy"
        },
        MenuItem {
            text: Tr.tr("Most busy")
            value: "mostBusy"
        }
    ]

    function fetchRandom(): void {
        const source = shownSourceItems.some(i => i.value === rw.source) ? rw.source : "wallhaven";
        const known = biggestScreen.w > 0;
        const size = rw.matchScreen && known ? [String(biggestScreen.w), String(biggestScreen.h)] : ["0", "0"];
        const shape = rw.preferScreenRatio && known ? [String(biggestScreen.w), String(biggestScreen.h)] : [];
        randomWallProc.command = [Quickshell.shellPath("scripts/caelestia4/random-wallpaper.sh"), source, ...size, ...shape];
        randomWallProc.status = "";
        randomWallProc.running = true;
    }

    // A property: PageBase's default property takes the page's one content item
    readonly property Process randomWallProc: Process {
        property string status

        stdout: SplitParser {
            onRead: data => root.randomWallProc.status = data.trim()
        }
    }

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
                source: Wallpapers.forScreen(root.nState.screen) // caelestia4: upstream #2210
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

            // caelestia4: end4-pC presets (wallpaper, desktop widgets, lock screen, avatar)
            IconTextButton {
                icon: "style"
                text: Tr.tr("Presets")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: root.nState.openSubPage(4) // Presets page
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
            value: Config.background.wallpaperEnabled
            onToggled: GlobalConfig.background.wallpaperEnabled = checked
        }

        // caelestia4: upstream #2210
        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Workspace wallpapers")
            subtext: Tr.tr("Remember the wallpaper set on each workspace (videos stay on every workspace)")
            value: GlobalConfig.background.workspaceWallpapers.enabled
            onToggled: GlobalConfig.background.workspaceWallpapers.enabled = checked
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            text: Tr.tr("Transparency")
            // TRANSLATORS: %1/%2 = opacity values from 0 to 1 for the base surface and layered surfaces
            subtext: Tr.tr("Base %1, layers %2").arg(Colours.transparency.base).arg(Colours.transparency.layers)
            value: Colours.transparency.enabled
            onToggled: {
                GlobalConfig.appearance.transparency.enabled = checked;
                E4C.Config.options.appearance.transparency.enable = checked; // caelestia4: end-4 parts (AI chat, settings app, overlay) too
            }
        }

        ToggleRow {
            Layout.topMargin: Tokens.spacing.extraSmall / 2 - parent.spacing

            last: true
            text: Tr.tr("Dark theme")
            value: !Colours.light
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

        // caelestia4: what follows the colours, and the terminal palette (end-4's colour pipeline, fed by scheme.py bridge)
        SectionHeader {
            text: Tr.tr("What gets coloured")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Colour the shell")
            subtext: Tr.tr("Panels, launcher and widgets follow the wallpaper")
            value: E4C.Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onToggled: E4C.Config.options.appearance.wallpaperTheming.enableAppsAndShell = checked
        }

        ToggleRow {
            text: Tr.tr("Colour Qt and KDE apps")
            value: E4C.Config.options.appearance.wallpaperTheming.enableQtApps
            onToggled: E4C.Config.options.appearance.wallpaperTheming.enableQtApps = checked
        }

        ToggleRow {
            text: Tr.tr("Colour terminals")
            subtext: Tr.tr("kitty and other terminals use the wallpaper colours")
            value: E4C.Config.options.appearance.wallpaperTheming.enableTerminal
            onToggled: E4C.Config.options.appearance.wallpaperTheming.enableTerminal = checked
        }

        ToggleRow {
            disabled: !E4C.Config.options.appearance.wallpaperTheming.enableTerminal
            text: Tr.tr("Always dark terminal")
            subtext: Tr.tr("Even when the shell is in light mode")
            value: E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode
            onToggled: E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode = checked
        }

        StepperRow {
            enabled: E4C.Config.options.appearance.wallpaperTheming.enableTerminal
            label: Tr.tr("Colour harmony (%)")
            subtext: Tr.tr("How much terminal colours lean towards the wallpaper colour")
            value: Math.round(E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony * 100)
            from: 0
            to: 100
            onMoved: v => E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.harmony = v / 100
        }

        StepperRow {
            last: true
            enabled: E4C.Config.options.appearance.wallpaperTheming.enableTerminal
            label: Tr.tr("Text brightness boost (%)")
            value: Math.round(E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost * 100)
            from: 0
            to: 100
            onMoved: v => E4C.Config.options.appearance.wallpaperTheming.terminalGenerationProps.termFgBoost = v / 100
        }

        // caelestia4: the folder the launcher, this page and end-4's wallpaper selector list (paths.wallpaperDir)
        SectionHeader {
            text: Tr.tr("Wallpaper folder")
        }

        TextFieldRow {
            first: true
            label: Tr.tr("Folder")
            subtext: Tr.tr("~ = your home folder")
            value: GlobalConfig.paths.wallpaperDir
            onEditingFinished: v => {
                if (v.trim())
                    GlobalConfig.paths.wallpaperDir = v.trim();
            }
        }

        ToggleRow {
            last: true
            text: Tr.tr("Use the system file picker")
            subtext: Tr.tr("end-4's wallpaper selector (Ctrl+Super+T) opens the desktop's file dialog instead of its own browser")
            value: E4C.Config.options.wallpaperSelector.useSystemFileDialog
            onToggled: E4C.Config.options.wallpaperSelector.useSystemFileDialog = checked
        }

        SectionHeader {
            text: Tr.tr("Random wallpaper from the internet")
        }

        SelectRow {
            first: true
            label: Tr.tr("Source")
            subtext: Tr.tr("Anime sources appear when the Anime tab is shown (Panels > Assistant)")
            menuItems: root.shownSourceItems
            active: root.shownSourceItems.find(i => i.value === root.rw.source) ?? root.shownSourceItems[0]
            onSelected: item => root.rw.source = item.value
        }

        ToggleRow {
            text: Tr.tr("Only wallpapers that fill my screen")
            subtext: root.biggestScreen.w > 0 ? Tr.tr("At least %1 × %2, your largest monitor").arg(root.biggestScreen.w).arg(root.biggestScreen.h) : Tr.tr("At least your monitor's resolution")
            value: root.rw.matchScreen
            onToggled: root.rw.matchScreen = checked
        }

        ToggleRow {
            text: root.screenRatio ? Tr.tr("Prefer my screen's shape (%1)").arg(root.screenRatio) : Tr.tr("Prefer my screen's shape")
            subtext: Tr.tr("Wallpapers with the same aspect ratio as your largest monitor come first, then the closest shape, so less gets cropped")
            value: root.rw.preferScreenRatio
            onToggled: root.rw.preferScreenRatio = checked
        }

        RowButton {
            last: true
            disabled: root.randomWallProc.running
            icon: root.randomWallProc.running ? "hourglass_top" : "cloud_download"
            text: root.randomWallProc.running ? Tr.tr("Working…") : Tr.tr("Get one")
            subtext: root.randomWallProc.status || Tr.tr("Saved to Wallpapers in your Pictures folder; colours follow")
            onClicked: root.fetchRandom()
        }

        // caelestia4: Caelestia's audio visualiser on the desktop (background.visualiser)
        SectionHeader {
            text: Tr.tr("Audio visualiser")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Visualiser on the desktop")
            subtext: Tr.tr("Bars along the bottom of the wallpaper that move with the sound")
            value: Config.background.visualiser.enabled
            onToggled: GlobalConfig.background.visualiser.enabled = checked
        }

        ToggleRow {
            disabled: !Config.background.visualiser.enabled
            text: Tr.tr("Only on empty desktops")
            subtext: Tr.tr("Hidden while tiled windows cover the workspace")
            value: Config.background.visualiser.autoHide
            onToggled: GlobalConfig.background.visualiser.autoHide = checked
        }

        ToggleRow {
            disabled: !Config.background.visualiser.enabled
            text: Tr.tr("Blur behind the bars")
            value: Config.background.visualiser.blur
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
            last: root.desktopClock === "none"
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
            value: E4C.Config.options.caelestia.desktopWeather
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
            value: Config.background.desktopClock.background.enabled
            onToggled: GlobalConfig.background.desktopClock.background.enabled = checked
        }

        // end-4's cookie / digital clock (background widgets)
        SelectRow {
            visible: root.desktopClock === "cookie" || root.desktopClock === "digital"
            last: root.desktopClock === "digital"
            label: Tr.tr("Clock placement")
            subtext: Tr.tr("Free: drag it on the desktop. Otherwise it moves to the calmest (or busiest) part of the wallpaper")
            menuItems: root.placementItems
            active: root.placementItems.find(i => i.value === E4C.Config.options.background.widgets.clock.placementStrategy) ?? null
            onSelected: item => E4C.Config.options.background.widgets.clock.placementStrategy = item.value
        }

        ToggleRow {
            visible: root.desktopClock === "cookie"
            text: Tr.tr("Quote under the cookie clock")
            value: E4C.Config.options.background.widgets.clock.quote.enable
            onToggled: E4C.Config.options.background.widgets.clock.quote.enable = checked
        }

        TextFieldRow {
            visible: root.desktopClock === "cookie"
            last: true
            enabled: E4C.Config.options.background.widgets.clock.quote.enable
            label: Tr.tr("Quote")
            placeholderText: Tr.tr("Your quote")
            value: E4C.Config.options.background.widgets.clock.quote.text
            onEditingFinished: v => {
                if (v !== value)
                    E4C.Config.options.background.widgets.clock.quote.text = v;
            }
        }

        SectionHeader {
            text: Tr.tr("Weather widget")
        }

        ToggleRow {
            first: true
            last: !E4C.Config.options.background.widgets.weather.enable
            text: Tr.tr("Weather widget")
            subtext: Tr.tr("end-4's weather card, separate from the clock; drag it when its placement is free")
            value: E4C.Config.options.background.widgets.weather.enable
            onToggled: E4C.Config.options.background.widgets.weather.enable = checked
        }

        SelectRow {
            visible: E4C.Config.options.background.widgets.weather.enable
            last: true
            label: Tr.tr("Weather placement")
            menuItems: root.placementItems
            active: root.placementItems.find(i => i.value === E4C.Config.options.background.widgets.weather.placementStrategy) ?? null
            onSelected: item => E4C.Config.options.background.widgets.weather.placementStrategy = item.value
        }

        SectionHeader {
            text: Tr.tr("Wallpaper parallax")
        }

        ToggleRow {
            first: true
            text: Tr.tr("Move the wallpaper with workspaces")
            subtext: Tr.tr("The wallpaper is zoomed in a little and slides as you switch workspaces")
            value: E4C.Config.options.background.parallax.enableWorkspace
            onToggled: E4C.Config.options.background.parallax.enableWorkspace = checked
        }

        ToggleRow {
            disabled: !E4C.Config.options.background.parallax.enableWorkspace
            text: Tr.tr("Slide vertically")
            value: E4C.Config.options.background.parallax.vertical
            onToggled: E4C.Config.options.background.parallax.vertical = checked
        }

        StepperRow {
            enabled: E4C.Config.options.background.parallax.enableWorkspace
            label: Tr.tr("Zoom (%)")
            value: Math.round(E4C.Config.options.background.parallax.workspaceZoom * 100)
            from: 101
            to: 150
            onMoved: v => E4C.Config.options.background.parallax.workspaceZoom = v / 100
        }

        StepperRow {
            last: true
            enabled: E4C.Config.options.background.parallax.enableWorkspace
            label: Tr.tr("Widget movement (%)")
            subtext: Tr.tr("How far the desktop widgets move compared with the wallpaper")
            value: Math.round(E4C.Config.options.background.parallax.widgetsFactor * 100)
            from: 0
            to: 200
            stepSize: 10
            onMoved: v => E4C.Config.options.background.parallax.widgetsFactor = v / 100
        }
    }
}
