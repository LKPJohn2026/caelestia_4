import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for Wallpaper & style > Fonts (route appearance/fonts) and its Type scale sub-page
// (appearance/fonts/scale) (merged by Registry.qml). See RegPanels.qml for the format; `mirrors` as in RegAppearance.qml.
// The per-size entries ("c:appearance.font.<style>.<size>.*") are one Caelestia FONT_CONFIG node each
// (appearanceconfig.hpp), shown by a FontGroup on Type scale; the style fonts (headline, title, label) are there too.
// Fonts apply at once: Tokens.font is rebuilt when a node changes (plugin font.cpp)
QtObject {
    id: root

    // Thin 100 to Black 900, as FontGroup's weight menu
    readonly property var weightOptions: [
        {
            value: 100,
            label: Tr.markCtx("Thin", "font weight")
        },
        {
            value: 200,
            label: Tr.markCtx("Extra light", "font weight")
        },
        {
            value: 300,
            label: Tr.markCtx("Light", "font weight")
        },
        {
            value: 400,
            label: Tr.markCtx("Regular", "font weight")
        },
        {
            value: 500,
            label: Tr.markCtx("Medium", "font weight")
        },
        {
            value: 600,
            label: Tr.markCtx("Semi-bold", "font weight")
        },
        {
            value: 700,
            label: Tr.markCtx("Bold", "font weight")
        },
        {
            value: 800,
            label: Tr.markCtx("Extra bold", "font weight")
        },
        {
            value: 900,
            label: Tr.markCtx("Black", "font weight")
        }
    ]

    readonly property var entries: ({
            "c:appearance.font.body.family": {
                route: "appearance/fonts",
                section: Tr.mark("Panels"),
                title: Tr.mark("Panel font"),
                desc: Tr.mark("Bar, drawers, launcher and notifications. Also sets the headline, title and label fonts (Type scale)"),
                keywords: [Tr.mark("font"), Tr.mark("typeface"), Tr.mark("family"), Tr.mark("panel"), Tr.mark("text"), Tr.mark("body")],
                type: "font",
                validate: "^\\S(.*\\S)?$",
                mirrors: ["c:appearance.font.headline.family", "c:appearance.font.title.family", "c:appearance.font.label.family"]
            },
            "c:appearance.font.mono.family": {
                route: "appearance/fonts",
                section: Tr.mark("Panels"),
                title: Tr.mark("Monospace font"),
                desc: Tr.mark("Code, numbers and fixed-width text"),
                keywords: [Tr.mark("font"), Tr.mark("monospace"), Tr.mark("mono"), Tr.mark("code"), Tr.mark("fixed width"), Tr.mark("terminal")],
                type: "font",
                validate: "^\\S(.*\\S)?$",
                mirrors: ["e4:appearance.fonts.monospace"]
            },
            // caelestia4: a desktop font (background/DesktopClock.qml only), so with the end-4 clock widgets' font
            "c:appearance.font.clock": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("Caelestia clock font"),
                desc: Tr.mark("The time and date on Caelestia's desktop clock"),
                keywords: [Tr.mark("font"), Tr.mark("clock"), Tr.mark("time"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.workspaces": {
                route: "appearance/fonts",
                section: Tr.mark("Panels"),
                title: Tr.mark("Workspace font"),
                desc: Tr.mark("The workspace numbers and names in the bar. Pick a font with the symbols you use"),
                keywords: [Tr.mark("font"), Tr.mark("workspace"), Tr.mark("bar"), Tr.mark("numbers"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:appearance.fonts.main": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("App font"),
                desc: Tr.mark("Assistant, overlay, translator and desktop widgets"),
                keywords: [Tr.mark("font"), Tr.mark("app"), Tr.mark("widgets"), Tr.mark("assistant"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:appearance.fonts.title": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("Widget title font"),
                desc: Tr.mark("Titles in the desktop widgets, such as the clock's rotating date"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("widgets"), Tr.mark("desktop"), Tr.mark("date"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:appearance.fonts.numbers": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("Numbers font"),
                desc: Tr.mark("Text made only of numbers in the desktop widgets and the assistant, such as dates and slider values"),
                keywords: [Tr.mark("font"), Tr.mark("numbers"), Tr.mark("digits"), Tr.mark("date"), Tr.mark("widgets"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:appearance.fonts.expressive": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("Cookie and digital clock font"),
                desc: Tr.mark("The time and date on end-4's cookie and digital desktop clocks"),
                keywords: [Tr.mark("font"), Tr.mark("clock"), Tr.mark("widget"), Tr.mark("time"), Tr.mark("cookie"), Tr.mark("digital"), Tr.mark("expressive"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "e4:appearance.fonts.reading": {
                route: "appearance/fonts",
                section: Tr.mark("Desktop widgets and apps"),
                title: Tr.mark("Reading font"),
                desc: Tr.mark("Long text such as AI answers"),
                keywords: [Tr.mark("font"), Tr.mark("reading"), Tr.mark("ai"), Tr.mark("chat"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.headline.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines"),
                title: Tr.mark("Headline font"),
                desc: Tr.mark("Big text: the desktop clock, dashboard numbers, page titles. The panel font sets it too"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.headline.large.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.headline.large.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.headline.large.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.headline.large.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.headline.large.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.headline.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.headline.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.headline.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.headline.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.headline.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.headline.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.headline.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.headline.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.headline.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.headline.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Headlines, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("headline"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.title.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles"),
                title: Tr.mark("Title font"),
                desc: Tr.mark("Titles of cards, dialogs and the calendar. The panel font sets it too"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.title.large.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.title.large.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.title.large.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.title.large.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.title.large.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.title.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.title.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.title.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.title.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.title.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.title.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.title.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.title.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.title.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.title.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Titles, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("title"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.body.large.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.body.large.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.body.large.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.body.large.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.body.large.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.body.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.body.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.body.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.body.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.body.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.body.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.body.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.body.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.body.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.body.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Body text, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("body"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.label.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels"),
                title: Tr.mark("Label font"),
                desc: Tr.mark("Small text: buttons, the bar's status, notification details. The panel font sets it too"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.label.large.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.label.large.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.label.large.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.label.large.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.label.large.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.label.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.label.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.label.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.label.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.label.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.label.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.label.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.label.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.label.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.label.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Labels, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("label"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.mono.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.mono.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.mono.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.mono.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.mono.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.mono.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.mono.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.mono.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.mono.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.mono.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Monospace, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("mono"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.icon.family": {
                route: "appearance/fonts",
                section: Tr.mark("Panels"),
                title: Tr.mark("Icon font"),
                desc: Tr.mark("A Material Symbols font. Other fonts show the icons' names as words instead"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("family"), Tr.mark("typeface"), Tr.mark("symbols"), Tr.mark("material")],
                type: "font",
                validate: "^\\S(.*\\S)?$"
            },
            "c:appearance.font.icon.extraLarge.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, extra large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("extra large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.icon.extraLarge.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, extra large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("extra large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.icon.extraLarge.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, extra large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("extra large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.icon.extraLarge.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, extra large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("extra large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.icon.extraLarge.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, extra large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("extra large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.icon.large.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, large"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("large"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.icon.large.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, large"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("large"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.icon.large.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, large"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("large"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.icon.large.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, large"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("large"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.icon.large.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, large"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("large"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.icon.medium.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, medium"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("medium"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.icon.medium.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, medium"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("medium"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.icon.medium.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, medium"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("medium"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.icon.medium.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, medium"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("medium"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.icon.medium.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, medium"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("medium"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            },
            "c:appearance.font.icon.small.family": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, small"),
                title: Tr.mark("Font"),
                desc: Tr.mark("Only for this size"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("small"), Tr.mark("family"), Tr.mark("typeface")],
                type: "font"
            },
            "c:appearance.font.icon.small.size": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, small"),
                title: Tr.mark("Size"),
                desc: Tr.mark("Text size on Look & feel scales it"),
                unit: "pt",
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("small"), Tr.mark("size"), Tr.mark("points"), Tr.mark("bigger"), Tr.mark("smaller")],
                type: "int",
                min: 4,
                max: 96,
                step: 1
            },
            "c:appearance.font.icon.small.weight": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, small"),
                title: Tr.mark("Weight"),
                desc: Tr.mark("How thick the letters are"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("small"), Tr.mark("weight"), Tr.mark("bold"), Tr.mark("thin"), Tr.mark("light")],
                type: "int",
                options: root.weightOptions
            },
            "c:appearance.font.icon.small.italic": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, small"),
                title: Tr.mark("Italic"),
                desc: Tr.mark("Slanted letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("small"), Tr.mark("italic"), Tr.mark("slanted"), Tr.mark("oblique")],
                type: "bool"
            },
            "c:appearance.font.icon.small.vaxes": {
                route: "appearance/fonts/scale",
                section: Tr.mark("Icons, small"),
                title: Tr.mark("Variable font axes"),
                desc: Tr.mark("Four-letter axis tags and their values, e.g. ROND 25 for rounder letters"),
                keywords: [Tr.mark("font"), Tr.mark("icon"), Tr.mark("small"), Tr.mark("variable"), Tr.mark("axes"), Tr.mark("axis"), Tr.mark("rond"), Tr.mark("fill"), Tr.mark("grade"), Tr.mark("opsz")],
                type: "map"
            }
        })
}
