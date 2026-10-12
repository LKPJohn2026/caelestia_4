import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import Caelestia.Config as CC
import qs.modules.settings.c4 // caelestia4: explicit, so Quickshell's scanner registers every row type

// caelestia4: Appearance — wallpaper, colours, transparency, size & shape, fonts.
// Sources: end-4 config.json (wallpaper theming, palette, fonts for end-4 widgets) and Caelestia shell.json
// (panel transparency, scales, border, panel fonts).
ContentPage {
    forceWidth: true

    function regenerateColours(extraArgs) {
        Quickshell.execDetached(["bash", "-c", `${Directories.wallpaperSwitchScriptPath} --noswitch ${extraArgs ?? ""}`]);
    }

    // ---------------------------------------------------------------- wallpaper
    readonly property string wallpaperPath: {
        const p = Config.options.background.wallpaperPath ?? "";
        const isVideo = /\.(mp4|webm|mkv|avi|mov)$/i.test(p);
        return isVideo ? (Config.options.background.thumbnailPath || p) : p;
    }
    readonly property string wallpaperFile: wallpaperPath.split("/").pop()
    readonly property string wallpaperFolder: wallpaperPath.substring(0, wallpaperPath.lastIndexOf("/"))
    readonly property string wallpaperSource: {
        if (wallpaperFile.startsWith("random_wallpaper"))
            return Translation.tr("Downloaded by Random from the internet");
        if (wallpaperFolder.includes("/Wallhaven"))
            return Translation.tr("Saved from Wallhaven");
        return Translation.tr("From your files");
    }

    // end-4's online random wallpapers (scripts/colors/random): download to Pictures/Wallpapers, then apply
    Process {
        id: randomWallProc

        property string source
        property string status

        command: ["bash", "-c", FileUtils.trimFileProtocol(`${Directories.scriptPath}/colors/random/random_${source}_wall.sh`)]
        stdout: SplitParser {
            onRead: data => randomWallProc.status = data.trim()
        }
    }

    // Image size from the file header (magick identify; doesn't decode the whole image)
    property string wallpaperSize
    // The command is set here, not bound: a binding may not have updated yet when the path-change handler runs
    function probeSize(): void {
        wallpaperSize = "";
        if (!wallpaperPath)
            return;
        sizeProc.command = ["magick", "identify", "-ping", "-format", "%w × %h", `${wallpaperPath}[0]`];
        sizeProc.running = true;
    }
    onWallpaperPathChanged: probeSize()
    Component.onCompleted: probeSize()

    Process {
        id: sizeProc

        stdout: StdioCollector {
            onStreamFinished: wallpaperSize = text.trim()
        }
    }

    function fetchRandom(source): void {
        randomWallProc.source = source;
        randomWallProc.status = "";
        randomWallProc.running = true;
    }

    ContentSection {
        icon: "wallpaper"
        title: Translation.tr("Wallpaper")

        // Current wallpaper and where it comes from
        ClippingRectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(width * 9 / 32)
            Layout.maximumHeight: 300
            radius: Appearance.rounding.normal
            color: Appearance.m3colors.m3surfaceContainerHigh

            Image {
                anchors.fill: parent
                source: wallpaperPath ? `file://${wallpaperPath}` : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 1280
                asynchronous: true
                cache: false
            }
        }

        SettingRow {
            icon: "image"
            title: wallpaperFile || Translation.tr("No wallpaper set")
            description: [wallpaperSource, wallpaperSize, wallpaperFolder.replace(Directories.home.replace("file://", ""), "~")].filter(s => s).join("  ·  ")

            RippleButtonWithIcon {
                enabled: wallpaperFolder !== ""
                materialIcon: "folder_open"
                mainText: Translation.tr("Show in folder")
                onClicked: Quickshell.execDetached(["xdg-open", wallpaperFolder])
            }
        }

        ButtonRow {
            icon: "photo_library"
            title: Translation.tr("Choose from your wallpapers")
            description: Translation.tr("Browse the wallpaper folder · Ctrl+Super+T")
            buttonIcon: "open_in_new"
            buttonText: Translation.tr("Browse")
            onClicked: Quickshell.execDetached(["qs", "-c", "ii", "ipc", "call", "wallpaperSelector", "toggle"])
        }

        ButtonRow {
            icon: "add_photo_alternate"
            title: Translation.tr("Use an image file")
            description: Translation.tr("Pick any image on your computer")
            buttonIcon: "folder_open"
            buttonText: Translation.tr("Choose file")
            onClicked: Quickshell.execDetached([Directories.wallpaperSwitchScriptPath])
        }

        ButtonRow {
            icon: "shuffle"
            title: Translation.tr("Shuffle")
            description: Translation.tr("A random wallpaper from the current folder")
            buttonIcon: "casino"
            buttonText: Translation.tr("Shuffle")
            onClicked: Wallpapers.randomFromCurrentFolder()
        }

        SettingRow {
            visible: Config.options.policies.weeb === 1
            icon: "cloud_download"
            title: Translation.tr("Random from the internet")
            description: randomWallProc.running ? Translation.tr("Downloading… %1").arg(randomWallProc.status) : Translation.tr("Saved to %1").arg(`${Directories.pictures.replace(Directories.home, "~").replace("file://", "")}/Wallpapers`)

            RowLayout {
                spacing: 8

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    materialIcon: "ifl"
                    mainText: Translation.tr("Konachan")
                    onClicked: fetchRandom("konachan")
                    StyledToolTip {
                        text: Translation.tr("Safe-for-work anime artwork from konachan.net")
                    }
                }

                RippleButtonWithIcon {
                    enabled: !randomWallProc.running
                    materialIcon: "ifl"
                    mainText: Translation.tr("osu! seasonal")
                    onClicked: fetchRandom("osu")
                    StyledToolTip {
                        text: Translation.tr("A seasonal background from osu!")
                    }
                }
            }
        }

        SwitchRow {
            icon: "folder_managed"
            title: Translation.tr("Use the system file picker")
            description: Translation.tr("Browse opens your desktop's file dialog instead of the built-in browser")
            checked: Config.options.wallpaperSelector.useSystemFileDialog
            onToggled: v => Config.options.wallpaperSelector.useSystemFileDialog = v
        }
    }

    ContentSection {
        icon: "palette"
        title: Translation.tr("Colours")

        ChoiceRow {
            icon: "dark_mode"
            title: Translation.tr("Mode")
            options: [
                {
                    label: Translation.tr("Dark"),
                    value: true
                },
                {
                    label: Translation.tr("Light"),
                    value: false
                }
            ]
            value: Appearance.m3colors.darkmode
            onSelected: v => regenerateColours(`--mode ${v ? "dark" : "light"}`)
        }

        ChoiceRow {
            icon: "format_paint"
            title: Translation.tr("Colour style")
            description: Translation.tr("How colours are picked from the wallpaper")
            options: [
                {
                    label: Translation.tr("Automatic"),
                    value: "auto"
                },
                {
                    label: Translation.tr("Tonal spot"),
                    value: "scheme-tonal-spot"
                },
                {
                    label: Translation.tr("Content"),
                    value: "scheme-content"
                },
                {
                    label: Translation.tr("Expressive"),
                    value: "scheme-expressive"
                },
                {
                    label: Translation.tr("Fidelity"),
                    value: "scheme-fidelity"
                },
                {
                    label: Translation.tr("Fruit salad"),
                    value: "scheme-fruit-salad"
                },
                {
                    label: Translation.tr("Rainbow"),
                    value: "scheme-rainbow"
                },
                {
                    label: Translation.tr("Neutral"),
                    value: "scheme-neutral"
                },
                {
                    label: Translation.tr("Monochrome"),
                    value: "scheme-monochrome"
                }
            ]
            value: Config.options.appearance.palette.type
            onSelected: v => {
                Config.options.appearance.palette.type = v;
                // --type explicitly: config.json is written with a delay, switchwall would read the old value
                regenerateColours(`--type ${v}`);
            }
        }

        SwitchRow {
            icon: "desktop_windows"
            title: Translation.tr("Colour the shell")
            description: Translation.tr("Panels, launcher and widgets follow the wallpaper")
            checked: Config.options.appearance.wallpaperTheming.enableAppsAndShell
            onToggled: v => Config.options.appearance.wallpaperTheming.enableAppsAndShell = v
        }

        SwitchRow {
            icon: "apps"
            title: Translation.tr("Colour Qt and KDE apps")
            checked: Config.options.appearance.wallpaperTheming.enableQtApps
            onToggled: v => Config.options.appearance.wallpaperTheming.enableQtApps = v
        }

        SwitchRow {
            icon: "terminal"
            title: Translation.tr("Colour terminals")
            description: Translation.tr("kitty and other terminals use the wallpaper colours")
            checked: Config.options.appearance.wallpaperTheming.enableTerminal
            onToggled: v => Config.options.appearance.wallpaperTheming.enableTerminal = v
        }
    }

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Transparency")

        SwitchRow {
            icon: "blur_on"
            title: Translation.tr("Transparent panels")
            description: Translation.tr("Bar, drawers and widgets let the wallpaper show through")
            checked: CC.GlobalConfig.appearance.transparency.enabled
            onToggled: v => {
                CC.GlobalConfig.appearance.transparency.enabled = v;
                Config.options.appearance.transparency.enable = v; // end-4 widgets (AI chat, settings app)
            }
        }

        SliderRow {
            enabled: CC.GlobalConfig.appearance.transparency.enabled
            icon: "gradient"
            title: Translation.tr("Panel opacity")
            from: 0.3
            to: 1
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.transparency.base
            onMoved: v => CC.GlobalConfig.appearance.transparency.base = v
        }

        SliderRow {
            enabled: CC.GlobalConfig.appearance.transparency.enabled
            icon: "layers"
            title: Translation.tr("Inner layer opacity")
            description: Translation.tr("Cards and buttons inside panels")
            from: 0
            to: 1
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.transparency.layers
            onMoved: v => CC.GlobalConfig.appearance.transparency.layers = v
        }
    }

    ContentSection {
        icon: "aspect_ratio"
        title: Translation.tr("Size & shape")

        SliderRow {
            icon: "format_size"
            title: Translation.tr("Text size")
            from: 0.7
            to: 1.5
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.font.scale
            onMoved: v => CC.GlobalConfig.appearance.font.scale = v
        }

        SliderRow {
            icon: "rounded_corner"
            title: Translation.tr("Corner roundness")
            from: 0
            to: 2
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.rounding.scale
            onMoved: v => CC.GlobalConfig.appearance.rounding.scale = v
        }

        SliderRow {
            icon: "space_bar"
            title: Translation.tr("Spacing")
            description: Translation.tr("Space between items")
            from: 0.5
            to: 2
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.spacing.scale
            onMoved: v => CC.GlobalConfig.appearance.spacing.scale = v
        }

        SliderRow {
            icon: "padding"
            title: Translation.tr("Padding")
            description: Translation.tr("Space inside panels and buttons")
            from: 0.5
            to: 2
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.padding.scale
            onMoved: v => CC.GlobalConfig.appearance.padding.scale = v
        }

        SliderRow {
            icon: "animation"
            title: Translation.tr("Animation duration")
            description: Translation.tr("Lower is faster; 0 turns panel animations off")
            from: 0
            to: 2
            format: v => `${Math.round(v * 100)} %`
            value: CC.GlobalConfig.appearance.anim.durations.scale
            onMoved: v => CC.GlobalConfig.appearance.anim.durations.scale = v
        }

        SpinRow {
            icon: "border_outer"
            title: Translation.tr("Screen frame thickness (px)")
            description: Translation.tr("The border around the screen that holds the bar and drawers")
            from: 0
            to: 40
            value: CC.GlobalConfig.border.thickness
            onMoved: v => CC.GlobalConfig.border.thickness = v
        }

        SpinRow {
            icon: "rounded_corner"
            title: Translation.tr("Screen frame corner radius (px)")
            from: 0
            to: 80
            value: CC.GlobalConfig.border.rounding
            onMoved: v => CC.GlobalConfig.border.rounding = v
        }
    }

    ContentSection {
        icon: "font_download"
        title: Translation.tr("Fonts")

        TextRow {
            icon: "text_fields"
            title: Translation.tr("Panel font")
            description: Translation.tr("Bar, drawers, launcher, notifications")
            placeholder: "Google Sans Flex"
            value: CC.GlobalConfig.appearance.font.body.family
            onEdited: v => {
                CC.GlobalConfig.appearance.font.headline.family = v;
                CC.GlobalConfig.appearance.font.title.family = v;
                CC.GlobalConfig.appearance.font.body.family = v;
                CC.GlobalConfig.appearance.font.label.family = v;
            }
        }

        TextRow {
            icon: "schedule"
            title: Translation.tr("Clock font")
            value: CC.GlobalConfig.appearance.font.clock
            onEdited: v => CC.GlobalConfig.appearance.font.clock = v
        }

        TextRow {
            icon: "code"
            title: Translation.tr("Monospace font")
            value: CC.GlobalConfig.appearance.font.mono.family
            onEdited: v => {
                CC.GlobalConfig.appearance.font.mono.family = v;
                Config.options.appearance.fonts.monospace = v;
            }
        }

        TextRow {
            icon: "chat"
            title: Translation.tr("App font")
            description: Translation.tr("Settings app, AI chat, translator and other end-4 widgets")
            value: Config.options.appearance.fonts.main
            onEdited: v => Config.options.appearance.fonts.main = v
        }

        TextRow {
            icon: "menu_book"
            title: Translation.tr("Reading font")
            description: Translation.tr("Long text such as AI answers")
            value: Config.options.appearance.fonts.reading
            onEdited: v => Config.options.appearance.fonts.reading = v
        }
    }
}
