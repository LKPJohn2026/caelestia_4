import QtQuick
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (background.transitionRandom)

// caelestia4: Caelestia's wallpaper transitions by name (enum WallpaperTransition, shell.json
// background.wallpaperTransition) and end-4's Random pool (background.transitionRandom, adapters/WallTransition.qml),
// shared by Wallpaper & style's Transition picker and Wallpaper options' "Pick from"
QtObject {
    id: root

    // caelestia4: names for Caelestia's wallpaper transitions; upstream has no picker for it yet
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
    // "Random" first, then the transitions
    readonly property var choices: [
        {
            id: "Random",
            label: Tr.tr("Random")
        },
        ...transitions
    ]
    readonly property var random: E4C.Config.options.background.transitionRandom
    // the pool's names that are transitions here (a hand edit or an upstream rename can leave others)
    readonly property list<string> randomPool: [...new Set(random.pool.filter(n => transitions.some(t => t.id === n)))]
    readonly property string current: {
        CUtils.dependency(Config.background.wallpaperTransition);
        return CUtils.enumToString(Config.background, "wallpaperTransition");
    }

    function isTransition(name: string): bool {
        return root.transitions.some(t => t.id === name);
    }
}
