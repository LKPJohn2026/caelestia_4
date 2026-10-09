pragma Singleton

import ".."
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.utils
import qs.modules.common as E4C // caelestia4: keep

Searcher {
    id: root

    function transformSearch(search: string): string {
        return search.slice(`${GlobalConfig.launcher.actionPrefix}variant `.length);
    }

    list: [
        Variant { // caelestia4: end-4 has no "vibrant"; its "auto" picks a variant from the wallpaper instead
            variant: "auto"
            icon: "auto_awesome"
            name: Tr.trCtx("Auto", "M3 scheme variant name")
            description: Tr.tr("Pick the variant that suits the current wallpaper (end-4 default).")
        },
        Variant {
            variant: "tonalspot"
            icon: "android"
            name: Tr.trCtx("Tonal Spot", "M3 scheme variant name")
            description: Tr.tr("Default for Material theme colours. A pastel palette with a low chroma.")
        },
        Variant {
            variant: "expressive"
            icon: "compare_arrows"
            name: Tr.trCtx("Expressive", "M3 scheme variant name")
            description: Tr.tr("A medium chroma palette. The primary palette's hue is different from the seed colour, for variety.")
        },
        Variant {
            variant: "fidelity"
            icon: "compare"
            name: Tr.trCtx("Fidelity", "M3 scheme variant name")
            description: Tr.tr("Matches the seed colour, even if the seed colour is very bright (high chroma).")
        },
        Variant {
            variant: "content"
            icon: "sentiment_calm"
            name: Tr.trCtx("Content", "M3 scheme variant name")
            description: Tr.tr("Almost identical to fidelity.")
        },
        Variant {
            variant: "fruitsalad"
            icon: "nutrition"
            name: Tr.trCtx("Fruit Salad", "M3 scheme variant name")
            description: Tr.tr("A playful theme - the seed colour's hue does not appear in the theme.")
        },
        Variant {
            variant: "rainbow"
            icon: "looks"
            name: Tr.trCtx("Rainbow", "M3 scheme variant name")
            description: Tr.tr("A playful theme - the seed colour's hue does not appear in the theme.")
        },
        Variant {
            variant: "neutral"
            icon: "contrast"
            name: Tr.trCtx("Neutral", "M3 scheme variant name")
            description: Tr.tr("Close to greyscale, a hint of chroma.")
        },
        Variant {
            variant: "monochrome"
            icon: "filter_b_and_w"
            name: Tr.trCtx("Monochrome", "M3 scheme variant name")
            description: Tr.tr("All colours are greyscale, no chroma.")
        }
    ]
    useFuzzy: GlobalConfig.launcher.useFuzzy.variants

    component Variant: QtObject {
        required property string variant
        required property string icon
        required property string name
        required property string description

        function onClicked(list: AppList): void {
            list.screenState.launcher = false;
            // caelestia4: end-4 palette type ("tonalspot" -> "scheme-tonal-spot"), then regenerate colours
            // from the current wallpaper exactly like end-4's Quick settings page
            const types = {
                auto: "auto",
                tonalspot: "scheme-tonal-spot",
                expressive: "scheme-expressive",
                fidelity: "scheme-fidelity",
                content: "scheme-content",
                fruitsalad: "scheme-fruit-salad",
                rainbow: "scheme-rainbow",
                neutral: "scheme-neutral",
                monochrome: "scheme-monochrome"
            };
            const type = types[variant] ?? "auto";
            E4C.Config.options.appearance.palette.type = type;
            // Pass the type explicitly: the shell writes config.json after a delay, so switchwall would still read the old one
            Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--type", type]);
        }
    }
}
