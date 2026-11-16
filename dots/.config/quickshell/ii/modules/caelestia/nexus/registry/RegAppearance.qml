import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 mirrors, palette type, switchwall.sh path)

// caelestia4: Nexus registry entries for the "appearance" page (merged by Registry.qml). See RegPanels.qml for the format.
// caelestia4: `advanced: true` rows have section "Advanced", the header they show under (the page's AdvancedSection)
// Two fields only this file uses so far:
//   scale    the row shows and steps value × scale (a stored 0.85 reads 85 %); min/max/step stay in stored units.
//            common/StepperRow and RowSetting.format read it
//   mirrors  other keys the page writes along with this one (same value), so they stay in step
// The watchers at the bottom do the page's follow-up writes for an Undo run after the row's page was closed
QtObject {
    readonly property var entries: ({
            // Wallpaper & style (pages/WallpaperAndStyle.qml)
            "c:background.wallpaperTransition": {
                route: "appearance",
                title: Tr.mark("Wallpaper transition"),
                desc: Tr.mark("The animation shown when the wallpaper changes"),
                keywords: [Tr.mark("transition"), Tr.mark("animation"), Tr.mark("wallpaper"), Tr.mark("effect"), Tr.mark("fade")],
                type: "enum"
            },
            "c:background.wallpaperEnabled": {
                route: "appearance",
                title: Tr.mark("Display wallpaper"),
                desc: Tr.mark("Off: a plain background instead of the picture"),
                keywords: [Tr.mark("wallpaper"), Tr.mark("background"), Tr.mark("picture"), Tr.mark("hide"), Tr.mark("show")],
                type: "bool"
            },
            "c:background.workspaceWallpapers.enabled": {
                route: "appearance",
                title: Tr.mark("Workspace wallpapers"),
                desc: Tr.mark("Remember the wallpaper set on each workspace (videos stay on every workspace)"),
                keywords: [Tr.mark("workspace"), Tr.mark("wallpaper"), Tr.mark("per workspace"), Tr.mark("different")],
                type: "bool"
            },
            "c:appearance.transparency.enabled": {
                route: "appearance",
                title: Tr.mark("Transparency"),
                desc: Tr.mark("See-through panels with the wallpaper blurred behind them; uses a little more GPU"),
                keywords: [Tr.mark("transparency"), Tr.mark("transparent"), Tr.mark("opacity"), Tr.mark("blur"), Tr.mark("glass"), Tr.mark("see-through")],
                type: "bool",
                mirrors: ["e4:appearance.transparency.enable"]
            },
            "x:appearance.darkTheme": {
                route: "appearance",
                title: Tr.mark("Dark theme"),
                desc: Tr.mark("Dark or light colours for the shell and apps"),
                keywords: [Tr.mark("dark"), Tr.mark("light"), Tr.mark("mode"), Tr.mark("theme"), Tr.mark("night")],
                type: "bool"
            },

            // Wallpaper & style > Look & feel (pages/wallandstyle/LookPage.qml)
            "c:appearance.transparency.base": {
                route: "appearance/look",
                section: Tr.mark("Transparency"),
                title: Tr.mark("Panel opacity"),
                desc: Tr.mark("How solid the bar, drawers and launcher are"),
                keywords: [Tr.mark("opacity"), Tr.mark("transparency"), Tr.mark("panel"), Tr.mark("alpha"), Tr.mark("background")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.3,
                max: 1,
                step: 0.05,
                requires: {
                    id: "c:appearance.transparency.enabled",
                    value: true
                }
            },
            "c:appearance.transparency.layers": {
                route: "appearance/look",
                section: Tr.mark("Transparency"),
                title: Tr.mark("Inner layer opacity"),
                desc: Tr.mark("Cards and buttons inside panels"),
                keywords: [Tr.mark("opacity"), Tr.mark("transparency"), Tr.mark("layers"), Tr.mark("cards"), Tr.mark("buttons")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.05,
                requires: {
                    id: "c:appearance.transparency.enabled",
                    value: true
                }
            },
            // caelestia4: end-4's own layer transparency (Appearance.qml), for the end-4 parts kept: the assistant,
            // the overlay and the desktop widgets. Not the same numbers as the panel opacity above
            "e4:appearance.transparency.automatic": {
                route: "appearance/look",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Assistant: automatic transparency"),
                desc: Tr.mark("The assistant, overlay and desktop widgets pick how see-through they are from the wallpaper"),
                keywords: [Tr.mark("transparency"), Tr.mark("automatic"), Tr.mark("assistant"), Tr.mark("overlay"), Tr.mark("widgets"), Tr.mark("end-4"), Tr.mark("opacity")],
                type: "bool",
                // caelestia4: no `requires`: end-4 uses automatic and the content transparency with Transparency off
                // too (Appearance.qml); only the background transparency needs it on
                advanced: true
            },
            "e4:appearance.transparency.backgroundTransparency": {
                route: "appearance/look",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Assistant background transparency"),
                desc: Tr.mark("How see-through the assistant and overlay backgrounds are. Higher is clearer"),
                keywords: [Tr.mark("transparency"), Tr.mark("background"), Tr.mark("assistant"), Tr.mark("overlay"), Tr.mark("end-4"), Tr.mark("opacity")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.01,
                advanced: true,
                requires: {
                    id: "e4:appearance.transparency.automatic",
                    value: false
                }
            },
            "e4:appearance.transparency.contentTransparency": {
                route: "appearance/look",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Assistant content transparency"),
                desc: Tr.mark("Cards and buttons inside the assistant, overlay and desktop widgets. Higher is clearer"),
                keywords: [Tr.mark("transparency"), Tr.mark("content"), Tr.mark("cards"), Tr.mark("assistant"), Tr.mark("overlay"), Tr.mark("widgets"), Tr.mark("end-4"), Tr.mark("opacity")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.01,
                advanced: true,
                requires: {
                    id: "e4:appearance.transparency.automatic",
                    value: false
                }
            },
            "e4:appearance.extraBackgroundTint": {
                route: "appearance/look",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Tint the assistant background"),
                desc: Tr.mark("Mixes a touch of the accent colour into the assistant and overlay background"),
                keywords: [Tr.mark("tint"), Tr.mark("background"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("assistant"), Tr.mark("overlay"), Tr.mark("end-4")],
                type: "bool",
                advanced: true
            },
            "c:appearance.font.scale": {
                route: "appearance/look",
                section: Tr.mark("Size & shape"),
                title: Tr.mark("Text size"),
                desc: Tr.mark("Size of all text in the panels"),
                keywords: [Tr.mark("font"), Tr.mark("text"), Tr.mark("size"), Tr.mark("scale"), Tr.mark("bigger"), Tr.mark("smaller"), Tr.mark("zoom")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.7,
                max: 1.5,
                step: 0.05
            },
            "c:appearance.rounding.scale": {
                route: "appearance/look",
                section: Tr.mark("Size & shape"),
                title: Tr.mark("Corner roundness"),
                desc: Tr.mark("0 gives square corners"),
                keywords: [Tr.mark("rounding"), Tr.mark("corners"), Tr.mark("radius"), Tr.mark("round"), Tr.mark("square")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 2,
                step: 0.1
            },
            "c:appearance.spacing.scale": {
                route: "appearance/look",
                section: Tr.mark("Size & shape"),
                title: Tr.mark("Spacing"),
                desc: Tr.mark("Space between items"),
                keywords: [Tr.mark("spacing"), Tr.mark("gaps"), Tr.mark("space"), Tr.mark("density"), Tr.mark("compact")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.5,
                max: 2,
                step: 0.1
            },
            "c:appearance.padding.scale": {
                route: "appearance/look",
                section: Tr.mark("Size & shape"),
                title: Tr.mark("Padding"),
                desc: Tr.mark("Space inside panels and buttons"),
                keywords: [Tr.mark("padding"), Tr.mark("space"), Tr.mark("density"), Tr.mark("compact"), Tr.mark("margins")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0.5,
                max: 2,
                step: 0.1
            },
            "c:appearance.anim.durations.scale": {
                route: "appearance/look",
                section: Tr.mark("Motion"),
                title: Tr.mark("Animation duration"),
                desc: Tr.mark("Lower is faster; 0 turns panel animations off"),
                keywords: [Tr.mark("animation"), Tr.mark("speed"), Tr.mark("duration"), Tr.mark("motion"), Tr.mark("fast"), Tr.mark("slow"), Tr.mark("reduce motion")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 2,
                step: 0.1
            },
            "c:border.thickness": {
                route: "appearance/look",
                section: Tr.mark("Screen frame"),
                title: Tr.mark("Screen frame thickness"),
                desc: Tr.mark("The border around the screen that holds the bar and drawers"),
                keywords: [Tr.mark("border"), Tr.mark("frame"), Tr.mark("thickness"), Tr.mark("edge"), Tr.mark("gap")],
                type: "int",
                unit: "px",
                min: 0,
                max: 40,
                step: 1
            },
            "c:border.rounding": {
                route: "appearance/look",
                section: Tr.mark("Screen frame"),
                title: Tr.mark("Screen frame corner radius"),
                desc: Tr.mark("How round the inner corners of the screen frame are"),
                keywords: [Tr.mark("border"), Tr.mark("frame"), Tr.mark("corners"), Tr.mark("radius"), Tr.mark("rounding")],
                type: "int",
                unit: "px",
                min: 0,
                max: 80,
                step: 1
            },
            "c:appearance.deformScale": {
                route: "appearance/look",
                section: Tr.mark("Motion"),
                title: Tr.mark("Drawer stretch"),
                desc: Tr.mark("How much drawers stretch and wobble as they open and close; 0 turns it off"),
                keywords: [Tr.mark("deform"), Tr.mark("wobble"), Tr.mark("stretch"), Tr.mark("jelly"), Tr.mark("drawers"), Tr.mark("animation"), Tr.mark("blob")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 3,
                step: 0.1
            },
            "c:border.smoothing": {
                route: "appearance/look",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Screen frame smoothing"),
                desc: Tr.mark("How softly the drawers melt into the screen frame where they meet it"),
                keywords: [Tr.mark("border"), Tr.mark("frame"), Tr.mark("smoothing"), Tr.mark("blend"), Tr.mark("drawers"), Tr.mark("corners")],
                type: "int",
                unit: "px",
                min: 0,
                max: 50,
                step: 1,
                advanced: true
            },

            // Fonts: registry/RegFonts.qml (route appearance/fonts)

            // Wallpaper & style > Colours (pages/wallandstyle/ColourSelect.qml)
            "e4:appearance.palette.type": {
                route: "appearance/colours",
                section: Tr.mark("Wallpaper colours"),
                title: Tr.mark("Colour style"),
                desc: Tr.mark("How colours are picked from the wallpaper"),
                keywords: [Tr.mark("colour"), Tr.mark("color"), Tr.mark("scheme"), Tr.mark("palette"), Tr.mark("material"), Tr.mark("variant"), Tr.mark("style")],
                type: "enum",
                options: [
                    {
                        value: "auto",
                        label: Tr.markCtx("Auto", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-tonal-spot",
                        label: Tr.markCtx("Tonal Spot", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-expressive",
                        label: Tr.markCtx("Expressive", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-fidelity",
                        label: Tr.markCtx("Fidelity", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-content",
                        label: Tr.markCtx("Content", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-fruit-salad",
                        label: Tr.markCtx("Fruit Salad", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-rainbow",
                        label: Tr.markCtx("Rainbow", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-neutral",
                        label: Tr.markCtx("Neutral", "M3 scheme variant name")
                    },
                    {
                        value: "scheme-monochrome",
                        label: Tr.markCtx("Monochrome", "M3 scheme variant name")
                    }
                ]
            },
            "e4:appearance.palette.accentColor": {
                route: "appearance/colours",
                section: Tr.mark("Wallpaper colours"),
                title: Tr.mark("Accent colour"),
                desc: Tr.mark("Make the colours from this colour instead of the wallpaper. Picking a new wallpaper clears it"),
                keywords: [Tr.mark("accent"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("seed"), Tr.mark("source"), Tr.mark("custom"), Tr.mark("hex"), Tr.mark("scheme")],
                type: "colour",
                // caelestia4: #rrggbb only (switchwall.sh and scheme.py take 6 digits); ColourSelect.qml's row checks it
                validate: "^#?[0-9a-fA-F]{6}$"
            },
            "e4:appearance.wallpaperTheming.enableAppsAndShell": {
                route: "appearance/colours",
                section: Tr.mark("What gets coloured"),
                title: Tr.mark("Colour the shell"),
                desc: Tr.mark("Panels, launcher and widgets follow the wallpaper. Applies the next time the colours are made (a new wallpaper or scheme)"),
                keywords: [Tr.mark("colour"), Tr.mark("color"), Tr.mark("theming"), Tr.mark("shell"), Tr.mark("panels"), Tr.mark("wallpaper")],
                type: "bool"
            },
            "e4:appearance.wallpaperTheming.enableQtApps": {
                route: "appearance/colours",
                section: Tr.mark("What gets coloured"),
                title: Tr.mark("Colour Qt and KDE apps"),
                desc: Tr.mark("Qt and KDE apps use the wallpaper colours"),
                keywords: [Tr.mark("colour"), Tr.mark("color"), Tr.mark("qt"), Tr.mark("kde"), Tr.mark("apps"), Tr.mark("theming"), Tr.mark("kvantum")],
                type: "bool",
                applies: "appRestart"
            },
            "e4:appearance.wallpaperTheming.enableTerminal": {
                route: "appearance/colours",
                section: Tr.mark("What gets coloured"),
                title: Tr.mark("Colour terminals"),
                desc: Tr.mark("kitty and other terminals use the wallpaper colours. Applies the next time the colours are made (a new wallpaper or scheme)"),
                keywords: [Tr.mark("colour"), Tr.mark("color"), Tr.mark("terminal"), Tr.mark("kitty"), Tr.mark("foot"), Tr.mark("theming")],
                type: "bool"
            },
            "e4:appearance.wallpaperTheming.terminalGenerationProps.forceDarkMode": {
                route: "appearance/colours",
                section: Tr.mark("What gets coloured"),
                title: Tr.mark("Always dark terminal"),
                desc: Tr.mark("Even when the shell is in light mode. Applies the next time the colours are made (a new wallpaper or scheme)"),
                keywords: [Tr.mark("terminal"), Tr.mark("dark"), Tr.mark("light"), Tr.mark("mode")],
                type: "bool",
                requires: {
                    id: "e4:appearance.wallpaperTheming.enableTerminal",
                    value: true
                }
            },
            "e4:appearance.wallpaperTheming.terminalGenerationProps.harmony": {
                route: "appearance/colours",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Colour harmony"),
                desc: Tr.mark("How much terminal colours lean towards the wallpaper colour. Applies the next time the colours are made (a new wallpaper or scheme)"),
                keywords: [Tr.mark("terminal"), Tr.mark("harmony"), Tr.mark("colour"), Tr.mark("color"), Tr.mark("blend")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.01,
                advanced: true,
                requires: {
                    id: "e4:appearance.wallpaperTheming.enableTerminal",
                    value: true
                }
            },
            "e4:appearance.wallpaperTheming.terminalGenerationProps.termFgBoost": {
                route: "appearance/colours",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Text brightness boost"),
                desc: Tr.mark("Makes terminal text brighter so it stands out from the background. Applies the next time the colours are made (a new wallpaper or scheme)"),
                keywords: [Tr.mark("terminal"), Tr.mark("text"), Tr.mark("brightness"), Tr.mark("contrast"), Tr.mark("foreground")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 1,
                step: 0.01,
                advanced: true,
                requires: {
                    id: "e4:appearance.wallpaperTheming.enableTerminal",
                    value: true
                }
            },

            // Wallpaper & style > Wallpapers (pages/wallandstyle/WallpaperSelect.qml)
            "c:nexus.wallpapersPerRow": {
                route: "appearance/wallpapers",
                title: Tr.mark("Wallpapers per row"),
                desc: Tr.mark("How many pictures each row of the wallpaper and preset grids holds"),
                keywords: [Tr.mark("wallpapers"), Tr.mark("grid"), Tr.mark("columns"), Tr.mark("per row"), Tr.mark("thumbnails")],
                type: "int",
                min: 2,
                max: 8,
                step: 1
            },

            // Wallpaper & style > Presets (pages/wallandstyle/PresetSelect.qml)
            // caelestia4: the page's switch runs preset-import.py --enable / --disable (it sets the key and puts the
            // layout in place); the row registers this id for landing and search, it doesn't write the key itself
            "e4:background.presetsEnabled": {
                route: "appearance/presets",
                title: Tr.mark("Use presets"),
                desc: Tr.mark("A preset sets the wallpaper, widgets, colours, lock screen and avatar. Off: your own"),
                keywords: [Tr.mark("preset"), Tr.mark("presets"), Tr.mark("theme"), Tr.mark("layout"), Tr.mark("on"), Tr.mark("off"), Tr.mark("own desktop")],
                type: "bool",
                // caelestia4: the page's Reset must not write it (only the script may): common/PageBase.qml is to
                // leave out entries with this flag
                noPageReset: true
            },
            "e4:background.workspacePresets": {
                route: "appearance/presets",
                title: Tr.mark("A preset per workspace"),
                desc: Tr.mark("Going back to a workspace applies its preset again, colours too"),
                keywords: [Tr.mark("preset"), Tr.mark("workspace"), Tr.mark("per workspace"), Tr.mark("theme")],
                type: "bool"
            },

            // Wallpaper & style > Wallpaper options (pages/wallandstyle/WallpaperSourcesPage.qml)
            "e4:background.transitionRandom.enable": {
                route: "appearance/sources",
                section: Tr.mark("Transitions"),
                title: Tr.mark("Random transition"),
                desc: Tr.mark("Each wallpaper change uses a transition picked at random from the ones chosen below"),
                keywords: [Tr.mark("transition"), Tr.mark("random"), Tr.mark("shuffle"), Tr.mark("animation"), Tr.mark("wallpaper")],
                type: "bool"
            },
            "e4:background.transitionRandom.noRepeat": {
                route: "appearance/sources",
                section: Tr.mark("Transitions"),
                title: Tr.mark("Never the same twice in a row"),
                desc: Tr.mark("The next transition is always a different one"),
                keywords: [Tr.mark("transition"), Tr.mark("random"), Tr.mark("repeat")],
                type: "bool",
                requires: {
                    id: "e4:background.transitionRandom.enable",
                    value: true
                }
            },
            "e4:background.transitionRandom.pool": {
                route: "appearance/sources",
                section: Tr.mark("Transitions"),
                title: Tr.mark("Random transitions"),
                desc: Tr.mark("Which transitions Random picks from"),
                keywords: [Tr.mark("transition"), Tr.mark("random"), Tr.mark("pool"), Tr.mark("list")],
                type: "list",
                requires: {
                    id: "e4:background.transitionRandom.enable",
                    value: true
                }
            },
            "e4:background.wallpaperFit.enable": {
                route: "appearance/sources",
                section: Tr.mark("Fit to the screen"),
                title: Tr.mark("Fit wallpapers to the screen"),
                desc: Tr.mark("Upscale (AI, Upscayl) or downscale each wallpaper to the screen's resolution, the whole picture kept. The originals stay as they are"),
                keywords: [Tr.mark("fit"), Tr.mark("upscale"), Tr.mark("resolution"), Tr.mark("scale"), Tr.mark("upscayl"), Tr.mark("ai"), Tr.mark("sharp")],
                type: "bool"
            },
            "e4:background.wallpaperFit.mode": {
                route: "appearance/sources",
                section: Tr.mark("Fit to the screen"),
                title: Tr.mark("Other shapes"),
                desc: Tr.mark("A wallpaper whose shape isn't the screen's (wider or taller)"),
                keywords: [Tr.mark("fit"), Tr.mark("aspect ratio"), Tr.mark("crop"), Tr.mark("blur"), Tr.mark("ultrawide"), Tr.mark("stretch")],
                type: "enum",
                options: [
                    {
                        value: "cover",
                        label: Tr.mark("Fill, cut off the rest")
                    },
                    {
                        value: "contain-blur",
                        label: Tr.mark("Whole, blurred sides")
                    },
                    {
                        value: "seam",
                        label: Tr.mark("Stretch the background")
                    }
                ],
                requires: {
                    id: "e4:background.wallpaperFit.enable",
                    value: true
                }
            },
            "e4:background.wallpaperFit.model": {
                route: "appearance/sources",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Upscaling model"),
                desc: Tr.mark("The AI model that enlarges small wallpapers. Changing it makes new copies of the ones shown"),
                keywords: [Tr.mark("upscale"), Tr.mark("model"), Tr.mark("upscayl"), Tr.mark("ai"), Tr.mark("sharp"), Tr.mark("quality")],
                type: "enum",
                options: [
                    {
                        value: "digital-art-4x",
                        label: Tr.mark("Digital art")
                    },
                    {
                        value: "high-fidelity-4x",
                        label: Tr.mark("High fidelity")
                    },
                    {
                        value: "remacri-4x",
                        label: Tr.mark("Remacri")
                    },
                    {
                        value: "ultramix-balanced-4x",
                        label: Tr.mark("Ultramix balanced")
                    },
                    {
                        value: "ultrasharp-4x",
                        label: Tr.mark("Ultrasharp")
                    },
                    {
                        value: "upscayl-standard-4x",
                        label: Tr.mark("Upscayl standard")
                    },
                    {
                        value: "upscayl-lite-4x",
                        label: Tr.mark("Upscayl lite (faster)")
                    }
                ],
                advanced: true,
                requires: {
                    id: "e4:background.wallpaperFit.enable",
                    value: true
                }
            },
            "c:paths.wallpaperDir": {
                route: "appearance/sources",
                section: Tr.mark("Your wallpapers"),
                title: Tr.mark("Wallpaper folder"),
                desc: Tr.mark("Where your wallpapers are. The launcher and Wallpapers list it"),
                keywords: [Tr.mark("wallpaper"), Tr.mark("folder"), Tr.mark("directory"), Tr.mark("path"), Tr.mark("pictures")],
                type: "path",
                pathMode: "folder",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:wallpaperSelector.useSystemFileDialog": {
                route: "appearance/sources",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Use the system file picker"),
                desc: Tr.mark("end-4's wallpaper selector (Ctrl+Super+T) opens the desktop's file dialog instead of its own browser"),
                keywords: [Tr.mark("file picker"), Tr.mark("dialog"), Tr.mark("portal"), Tr.mark("wallpaper selector"), Tr.mark("browse")],
                type: "bool",
                advanced: true
            },
            "e4:caelestia.randomWallpaper.source": {
                route: "appearance/sources",
                section: Tr.mark("From the internet"),
                title: Tr.mark("Source"),
                desc: Tr.mark("Wallhaven has all kinds of pictures. Anime sources appear when the Anime tab is shown (Panels > Assistant)"),
                keywords: [Tr.mark("random"), Tr.mark("wallpaper"), Tr.mark("download"), Tr.mark("internet"), Tr.mark("wallhaven"), Tr.mark("konachan"), Tr.mark("yandere"), Tr.mark("anime")],
                type: "enum",
                options: [
                    {
                        value: "wallhaven",
                        label: Tr.mark("Wallhaven")
                    },
                    {
                        value: "konachan",
                        label: Tr.mark("Konachan")
                    },
                    {
                        value: "yandere",
                        label: Tr.mark("yande.re")
                    }
                ]
            },
            "e4:caelestia.randomWallpaper.matchScreen": {
                route: "appearance/sources",
                section: Tr.mark("From the internet"),
                title: Tr.mark("Only wallpapers that fill my screen"),
                desc: Tr.mark("At least your monitor's resolution"),
                keywords: [Tr.mark("random"), Tr.mark("wallpaper"), Tr.mark("resolution"), Tr.mark("size"), Tr.mark("screen")],
                type: "bool"
            },
            "e4:caelestia.randomWallpaper.preferScreenRatio": {
                route: "appearance/sources",
                section: Tr.mark("From the internet"),
                title: Tr.mark("Prefer my screen's shape"),
                desc: Tr.mark("Wallpapers with the same aspect ratio as your largest monitor come first, then the closest shape, so less gets cropped"),
                keywords: [Tr.mark("random"), Tr.mark("wallpaper"), Tr.mark("aspect ratio"), Tr.mark("shape"), Tr.mark("crop")],
                type: "bool"
            },
            "e4:background.parallax.enableWorkspace": {
                route: "appearance/sources",
                section: Tr.mark("Parallax"),
                title: Tr.mark("Move the wallpaper with workspaces"),
                desc: Tr.mark("The wallpaper is zoomed in a little and slides as you switch workspaces"),
                keywords: [Tr.mark("parallax"), Tr.mark("wallpaper"), Tr.mark("workspace"), Tr.mark("slide"), Tr.mark("move"), Tr.mark("zoom")],
                type: "bool"
            },
            "e4:background.parallax.vertical": {
                route: "appearance/sources",
                section: Tr.mark("Parallax"),
                title: Tr.mark("Slide vertically"),
                desc: Tr.mark("Up and down instead of left and right"),
                keywords: [Tr.mark("parallax"), Tr.mark("vertical"), Tr.mark("direction")],
                type: "bool",
                requires: {
                    id: "e4:background.parallax.enableWorkspace",
                    value: true
                }
            },
            "e4:background.parallax.workspaceZoom": {
                route: "appearance/sources",
                section: Tr.mark("Parallax"),
                title: Tr.mark("Zoom"),
                desc: Tr.mark("How far the wallpaper is zoomed in; more zoom leaves more room to slide"),
                keywords: [Tr.mark("parallax"), Tr.mark("zoom"), Tr.mark("scale"), Tr.mark("wallpaper")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 1.01,
                max: 1.5,
                step: 0.01,
                requires: {
                    id: "e4:background.parallax.enableWorkspace",
                    value: true
                }
            },
            "e4:background.parallax.widgetsFactor": {
                route: "appearance/sources",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Widget movement"),
                desc: Tr.mark("How far the desktop widgets move compared with the wallpaper"),
                keywords: [Tr.mark("parallax"), Tr.mark("widgets"), Tr.mark("movement"), Tr.mark("factor")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 0,
                max: 2,
                step: 0.1,
                advanced: true,
                requires: {
                    id: "e4:background.parallax.enableWorkspace",
                    value: true
                }
            }
        })

    // caelestia4: an Undo from the snackbar or Ctrl+Z writes the key alone when the row's page is gone (RowSetting
    // writes it by id then), so the page's MirrorWatch and the Colour style row's colour run are not there. These do
    // the same while an undo step runs (NexusActions.undoing); the pages skip theirs then, or write the same value
    readonly property Connections _bodyFontUndo: Connections {
        function onFamilyChanged(): void {
            const v = GlobalConfig.appearance.font.body.family;
            if (!NexusActions.undoing || typeof v !== "string" || !v.trim())
                return;
            const f = GlobalConfig.appearance.font;
            if (f.headline.family !== v)
                f.headline.family = v;
            if (f.title.family !== v)
                f.title.family = v;
            if (f.label.family !== v)
                f.label.family = v;
        }

        target: GlobalConfig.appearance.font.body
    }

    readonly property Connections _monoFontUndo: Connections {
        function onFamilyChanged(): void {
            const v = GlobalConfig.appearance.font.mono.family;
            if (NexusActions.undoing && typeof v === "string" && v.trim() && E4C.Config.options.appearance.fonts.monospace !== v)
                E4C.Config.options.appearance.fonts.monospace = v;
        }

        target: GlobalConfig.appearance.font.mono
    }

    readonly property Connections _transparencyUndo: Connections {
        function onEnabledChanged(): void {
            const v = GlobalConfig.appearance.transparency.enabled;
            if (NexusActions.undoing && typeof v === "boolean" && E4C.Config.options.appearance.transparency.enable !== v)
                E4C.Config.options.appearance.transparency.enable = v;
        }

        target: GlobalConfig.appearance.transparency
    }

    // Colour style: make the colours again with the style put back (ColourSelect.qml does it for every other change)
    readonly property Connections _paletteTypeUndo: Connections {
        function onTypeChanged(): void {
            const v = E4C.Config.options.appearance.palette.type;
            if (NexusActions.undoing && typeof v === "string" && v)
                Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--type", v, "--mode", Colours.light ? "light" : "dark"]);
        }

        target: E4C.Config.options.appearance.palette
    }

    // Accent colour: make the colours from the colour put back, or from the wallpaper (ColourSelect.qml's recolour)
    readonly property Connections _accentUndo: Connections {
        function onAccentColorChanged(): void {
            const v = E4C.Config.options.appearance.palette.accentColor;
            if (!NexusActions.undoing || typeof v !== "string")
                return;
            const c = v.replace(/^#/, "");
            if (c && !/^[0-9a-fA-F]{6}$/.test(c))
                return;
            Quickshell.execDetached([E4C.Directories.wallpaperSwitchScriptPath, "--noswitch", "--color", c ? "#" + c : "clear", "--mode", Colours.light ? "light" : "dark"]);
        }

        target: E4C.Config.options.appearance.palette
    }
}
