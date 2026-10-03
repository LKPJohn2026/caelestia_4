// caelestia4 ADAPTER: Colours
// Caelestia's colour logic is kept (transparency layers, tPalette, blur layer rules, wallpaper luminance).
// Data source changed: the palette is bound live to end-4's Appearance.m3colors, so end-4's matugen
// pipeline is the only colour source (Caelestia normally reads caelestia-cli's generated scheme file).
// Contract used by Caelestia UI: palette, tPalette, layer(), on(), light, transparency{enabled,base,layers},
// scheme, setMode(), showPreview, wallLuminance.
// Not supported: colour *preview* (needs caelestia-cli). `preview` mirrors `current`; showPreview stays false.
// term0..15 keep Caelestia's defaults (end-4 has no terminal palette here).
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Images
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Singleton {
    id: root

    property bool showPreview
    property string scheme: "dynamic" // caelestia4: end-4 always derives colours from the wallpaper
    property string flavour
    readonly property bool light: showPreview ? previewLight : currentLight
    readonly property bool currentLight: !E4C.Appearance.m3colors.darkmode
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {
        m3primary_paletteKeyColor: E4C.Appearance.m3colors.m3primary // caelestia4: end-4 has no palette key colors
        m3secondary_paletteKeyColor: E4C.Appearance.m3colors.m3secondary // caelestia4: end-4 has no palette key colors
        m3tertiary_paletteKeyColor: E4C.Appearance.m3colors.m3tertiary // caelestia4: end-4 has no palette key colors
        m3neutral_paletteKeyColor: E4C.Appearance.m3colors.m3outline // caelestia4: end-4 has no palette key colors
        m3neutral_variant_paletteKeyColor: E4C.Appearance.m3colors.m3outlineVariant // caelestia4: end-4 has no palette key colors
        m3background: E4C.Appearance.m3colors.m3background
        m3onBackground: E4C.Appearance.m3colors.m3onBackground
        m3surface: E4C.Appearance.m3colors.m3surface
        m3surfaceDim: E4C.Appearance.m3colors.m3surfaceDim
        m3surfaceBright: E4C.Appearance.m3colors.m3surfaceBright
        m3surfaceContainerLowest: E4C.Appearance.m3colors.m3surfaceContainerLowest
        m3surfaceContainerLow: E4C.Appearance.m3colors.m3surfaceContainerLow
        m3surfaceContainer: E4C.Appearance.m3colors.m3surfaceContainer
        m3surfaceContainerHigh: E4C.Appearance.m3colors.m3surfaceContainerHigh
        m3surfaceContainerHighest: E4C.Appearance.m3colors.m3surfaceContainerHighest
        m3onSurface: E4C.Appearance.m3colors.m3onSurface
        m3surfaceVariant: E4C.Appearance.m3colors.m3surfaceVariant
        m3onSurfaceVariant: E4C.Appearance.m3colors.m3onSurfaceVariant
        m3inverseSurface: E4C.Appearance.m3colors.m3inverseSurface
        m3inverseOnSurface: E4C.Appearance.m3colors.m3inverseOnSurface
        m3outline: E4C.Appearance.m3colors.m3outline
        m3outlineVariant: E4C.Appearance.m3colors.m3outlineVariant
        m3shadow: E4C.Appearance.m3colors.m3shadow
        m3scrim: E4C.Appearance.m3colors.m3scrim
        m3surfaceTint: E4C.Appearance.m3colors.m3surfaceTint
        m3primary: E4C.Appearance.m3colors.m3primary
        m3onPrimary: E4C.Appearance.m3colors.m3onPrimary
        m3primaryContainer: E4C.Appearance.m3colors.m3primaryContainer
        m3onPrimaryContainer: E4C.Appearance.m3colors.m3onPrimaryContainer
        m3inversePrimary: E4C.Appearance.m3colors.m3inversePrimary
        m3secondary: E4C.Appearance.m3colors.m3secondary
        m3onSecondary: E4C.Appearance.m3colors.m3onSecondary
        m3secondaryContainer: E4C.Appearance.m3colors.m3secondaryContainer
        m3onSecondaryContainer: E4C.Appearance.m3colors.m3onSecondaryContainer
        m3tertiary: E4C.Appearance.m3colors.m3tertiary
        m3onTertiary: E4C.Appearance.m3colors.m3onTertiary
        m3tertiaryContainer: E4C.Appearance.m3colors.m3tertiaryContainer
        m3onTertiaryContainer: E4C.Appearance.m3colors.m3onTertiaryContainer
        m3error: E4C.Appearance.m3colors.m3error
        m3onError: E4C.Appearance.m3colors.m3onError
        m3errorContainer: E4C.Appearance.m3colors.m3errorContainer
        m3onErrorContainer: E4C.Appearance.m3colors.m3onErrorContainer
        m3success: E4C.Appearance.m3colors.m3success
        m3onSuccess: E4C.Appearance.m3colors.m3onSuccess
        m3successContainer: E4C.Appearance.m3colors.m3successContainer
        m3onSuccessContainer: E4C.Appearance.m3colors.m3onSuccessContainer
        m3primaryFixed: E4C.Appearance.m3colors.m3primaryFixed
        m3primaryFixedDim: E4C.Appearance.m3colors.m3primaryFixedDim
        m3onPrimaryFixed: E4C.Appearance.m3colors.m3onPrimaryFixed
        m3onPrimaryFixedVariant: E4C.Appearance.m3colors.m3onPrimaryFixedVariant
        m3secondaryFixed: E4C.Appearance.m3colors.m3secondaryFixed
        m3secondaryFixedDim: E4C.Appearance.m3colors.m3secondaryFixedDim
        m3onSecondaryFixed: E4C.Appearance.m3colors.m3onSecondaryFixed
        m3onSecondaryFixedVariant: E4C.Appearance.m3colors.m3onSecondaryFixedVariant
        m3tertiaryFixed: E4C.Appearance.m3colors.m3tertiaryFixed
        m3tertiaryFixedDim: E4C.Appearance.m3colors.m3tertiaryFixedDim
        m3onTertiaryFixed: E4C.Appearance.m3colors.m3onTertiaryFixed
        m3onTertiaryFixedVariant: E4C.Appearance.m3colors.m3onTertiaryFixedVariant
    }
    readonly property M3Palette preview: current
    readonly property Transparency transparency: Transparency {}
    readonly property alias wallLuminance: analyser.luminance

    property bool cooldownPending
    property real lastBaseTransparency

    function getLuminance(c: color): real {
        if (c.r == 0 && c.g == 0 && c.b == 0)
            return 0;
        return Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
    }

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = getLuminance(c);

        const offset = (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.2 : 0.3) * (1 - transparency.base) * (1 + wallLuminance * (light ? (layer == 1 ? 3 : 1) : 2.5));
        const scale = (luminance + offset) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));

        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function setMode(mode: string): void {
        // caelestia4: regenerate end-4's scheme from the current wallpaper in the requested mode
        E4.Wallpapers.apply(E4C.Config.options.background.wallpaperPath, mode === "dark");
    }

    function reloadHyprRules(): void {
        let rule, trEnabled;
        if (Hypr.usingLua) {
            rule = `eval hl.layer_rule({ match = { namespace = "caelestia-drawers" }, %1 = %2 })`;
            trEnabled = transparency.enabled;
        } else {
            rule = "keyword layerrule %1 %2, match:namespace caelestia-drawers";
            trEnabled = transparency.enabled ? 1 : 0;
        }
        Hypr.extras.batchMessage([rule.arg("blur").arg(trEnabled), rule.arg("ignore_alpha").arg(Math.max(0, transparency.base - 0.03))]);
    }

    function requestReloadHyprRules(): void {
        if (cooldownTimer.running) {
            root.cooldownPending = true;
        } else {
            root.reloadHyprRules();
            cooldownTimer.restart();
        }
    }

    Component.onCompleted: root.requestReloadHyprRules()

    Connections {
        function onConfigReloaded(): void {
            root.reloadHyprRules();
        }

        target: Hypr
    }


    ImageAnalyser {
        id: analyser

        source: Wallpapers.current
    }

    Timer {
        id: cooldownTimer

        interval: 30
        onTriggered: {
            if (root.cooldownPending) {
                root.cooldownPending = false;
                root.reloadHyprRules();
                restart();
            }
        }
    }

    Timer {
        id: cAnimCompleteTimer

        interval: Tokens.anim.durations.expressiveSlowEffects
        onTriggered: root.requestReloadHyprRules()
    }

    component Transparency: QtObject {
        readonly property bool enabled: Tokens.transparency.enabled
        readonly property real base: Math.max(0, Math.min(1, Tokens.transparency.base - (root.light ? 0.1 : 0)))
        readonly property real layers: Math.max(0, Math.min(1, Tokens.transparency.layers))

        onEnabledChanged: {
            if (enabled)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
        }
        onBaseChanged: {
            if (root.lastBaseTransparency > base)
                root.requestReloadHyprRules();
            else
                cAnimCompleteTimer.start();
            root.lastBaseTransparency = base;
        }
    }

    component M3TPalette: QtObject {
        readonly property color m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        readonly property color m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        readonly property color m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        readonly property color m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        readonly property color m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        readonly property color m3background: root.layer(root.palette.m3background, 0)
        readonly property color m3onBackground: root.layer(root.palette.m3onBackground)
        readonly property color m3surface: root.layer(root.palette.m3surface, 0)
        readonly property color m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        readonly property color m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        readonly property color m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        readonly property color m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        readonly property color m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        readonly property color m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        readonly property color m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        readonly property color m3onSurface: root.layer(root.palette.m3onSurface)
        readonly property color m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        readonly property color m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        readonly property color m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        readonly property color m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        readonly property color m3outline: root.layer(root.palette.m3outline)
        readonly property color m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        readonly property color m3shadow: root.layer(root.palette.m3shadow)
        readonly property color m3scrim: root.layer(root.palette.m3scrim)
        readonly property color m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        readonly property color m3primary: root.layer(root.palette.m3primary)
        readonly property color m3onPrimary: root.layer(root.palette.m3onPrimary)
        readonly property color m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        readonly property color m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        readonly property color m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        readonly property color m3secondary: root.layer(root.palette.m3secondary)
        readonly property color m3onSecondary: root.layer(root.palette.m3onSecondary)
        readonly property color m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        readonly property color m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        readonly property color m3tertiary: root.layer(root.palette.m3tertiary)
        readonly property color m3onTertiary: root.layer(root.palette.m3onTertiary)
        readonly property color m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        readonly property color m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        readonly property color m3error: root.layer(root.palette.m3error)
        readonly property color m3onError: root.layer(root.palette.m3onError)
        readonly property color m3errorContainer: root.layer(root.palette.m3errorContainer)
        readonly property color m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        readonly property color m3success: root.layer(root.palette.m3success)
        readonly property color m3onSuccess: root.layer(root.palette.m3onSuccess)
        readonly property color m3successContainer: root.layer(root.palette.m3successContainer)
        readonly property color m3onSuccessContainer: root.layer(root.palette.m3onSuccessContainer)
        readonly property color m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        readonly property color m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        readonly property color m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        readonly property color m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        readonly property color m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        readonly property color m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        readonly property color m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        readonly property color m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        readonly property color m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        readonly property color m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        readonly property color m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        readonly property color m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#a8627b"
        property color m3secondary_paletteKeyColor: "#8e6f78"
        property color m3tertiary_paletteKeyColor: "#986e4c"
        property color m3neutral_paletteKeyColor: "#807477"
        property color m3neutral_variant_paletteKeyColor: "#837377"
        property color m3background: "#191114"
        property color m3onBackground: "#efdfe2"
        property color m3surface: "#191114"
        property color m3surfaceDim: "#191114"
        property color m3surfaceBright: "#403739"
        property color m3surfaceContainerLowest: "#130c0e"
        property color m3surfaceContainerLow: "#22191c"
        property color m3surfaceContainer: "#261d20"
        property color m3surfaceContainerHigh: "#31282a"
        property color m3surfaceContainerHighest: "#3c3235"
        property color m3onSurface: "#efdfe2"
        property color m3surfaceVariant: "#514347"
        property color m3onSurfaceVariant: "#d5c2c6"
        property color m3inverseSurface: "#efdfe2"
        property color m3inverseOnSurface: "#372e30"
        property color m3outline: "#9e8c91"
        property color m3outlineVariant: "#514347"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#ffb0ca"
        property color m3primary: "#ffb0ca"
        property color m3onPrimary: "#541d34"
        property color m3primaryContainer: "#6f334a"
        property color m3onPrimaryContainer: "#ffd9e3"
        property color m3inversePrimary: "#8b4a62"
        property color m3secondary: "#e2bdc7"
        property color m3onSecondary: "#422932"
        property color m3secondaryContainer: "#5a3f48"
        property color m3onSecondaryContainer: "#ffd9e3"
        property color m3tertiary: "#f0bc95"
        property color m3onTertiary: "#48290c"
        property color m3tertiaryContainer: "#b58763"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#ffb4ab"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000a"
        property color m3onErrorContainer: "#ffdad6"
        property color m3success: "#B5CCBA"
        property color m3onSuccess: "#213528"
        property color m3successContainer: "#374B3E"
        property color m3onSuccessContainer: "#D1E9D6"
        property color m3primaryFixed: "#ffd9e3"
        property color m3primaryFixedDim: "#ffb0ca"
        property color m3onPrimaryFixed: "#39071f"
        property color m3onPrimaryFixedVariant: "#6f334a"
        property color m3secondaryFixed: "#ffd9e3"
        property color m3secondaryFixedDim: "#e2bdc7"
        property color m3onSecondaryFixed: "#2b151d"
        property color m3onSecondaryFixedVariant: "#5a3f48"
        property color m3tertiaryFixed: "#ffdcc3"
        property color m3tertiaryFixedDim: "#f0bc95"
        property color m3onTertiaryFixed: "#2f1500"
        property color m3onTertiaryFixedVariant: "#623f21"
        property color term0: "#353434"
        property color term1: "#ff4c8a"
        property color term2: "#ffbbb7"
        property color term3: "#ffdedf"
        property color term4: "#b3a2d5"
        property color term5: "#e98fb0"
        property color term6: "#ffba93"
        property color term7: "#eed1d2"
        property color term8: "#b39e9e"
        property color term9: "#ff80a3"
        property color term10: "#ffd3d0"
        property color term11: "#fff1f0"
        property color term12: "#dcbc93"
        property color term13: "#f9a8c2"
        property color term14: "#ffd1c0"
        property color term15: "#ffffff"
    }
}
