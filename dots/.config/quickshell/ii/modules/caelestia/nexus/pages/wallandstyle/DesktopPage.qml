pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: sub-page of WallpaperAndStyle (route appearance/desktop): the desktop's widgets (Caelestia's clock and
// visualiser, end4-pC's widgets), each with its own sub-page (widgets/), and what they all share: their look and how
// they are moved. Rows name their registry setting (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Desktop")
    isSubPage: true

    // caelestia4: one clock on the desktop: Caelestia's (background.desktopClock) or end-4's widget in one of its styles
    // (widgets/ClockWidgetPage.qml picks it)
    readonly property string desktopClock: E4C.Config.options.background.widgets.clock.enable ? E4C.Config.options.background.widgets.clock.style : (Config.background.desktopClock.enabled ? "caelestia" : "none")

    // caelestia4: one visualiser on the desktop, the same way (widgets/VisualizerWidgetPage.qml picks it)
    readonly property var e4Vis: E4C.Config.options.background.widgets.visualizer
    readonly property string desktopVisualiser: e4Vis.enable ? e4Vis.style : (Config.background.visualiser.enabled ? "caelestia" : "none")

    // caelestia4: end4-pC's desktop widgets, by hand (Widgets on the desktop): your own layout with presets off; with
    // them on, a preset applied replaces it
    readonly property var desktopWidgets: [
        {
            key: "clock",
            name: Tr.tr("Clock"),
            icon: "schedule"
        },
        {
            key: "weather",
            name: Tr.tr("Weather"),
            icon: "partly_cloudy_day"
        },
        {
            key: "calendar",
            name: Tr.tr("Calendar"),
            icon: "calendar_month"
        },
        {
            key: "media",
            name: Tr.tr("Media player"),
            icon: "music_note"
        },
        {
            key: "visualizer",
            name: Tr.tr("Audio visualiser"),
            icon: "graphic_eq"
        },
        {
            key: "worldClock",
            name: Tr.tr("World clock"),
            icon: "public"
        },
        {
            key: "resources",
            name: Tr.tr("System resources"),
            icon: "memory"
        },
        {
            key: "userCard",
            name: Tr.tr("User card"),
            icon: "account_box"
        },
        {
            key: "notes",
            name: Tr.tr("Notes"),
            icon: "sticky_note_2"
        },
        {
            key: "todo",
            name: Tr.tr("To-do list"),
            icon: "checklist"
        },
        {
            key: "timers",
            name: Tr.tr("Timers"),
            icon: "timer"
        },
        {
            key: "customText",
            name: Tr.tr("Text"),
            icon: "text_fields"
        },
        {
            key: "customImage",
            name: Tr.tr("Picture"),
            icon: "image"
        },
        {
            key: "imageCard",
            name: Tr.tr("Picture card"),
            icon: "photo"
        },
        {
            key: "sticker",
            name: Tr.tr("Sticker"),
            icon: "emoji_emotions"
        },
        {
            key: "images",
            name: Tr.tr("Image converter"),
            icon: "transform"
        }
    ]

    // caelestia4: what the widget list says under the clock and the visualiser: which one is on
    function styleName(key: string, v: string): string {
        switch (v) {
        case "caelestia":
            return Tr.tr("Classic");
        case "cookie":
            return Tr.tr("Cookie");
        case "digital":
            return Tr.tr("Digital");
        case "daily":
            return Tr.tr("Daily");
        case "pixel":
            return Tr.tr("Pixel");
        case "bars":
            return Tr.tr("Bars");
        case "mirror":
            return Tr.tr("Mirror");
        case "aurora":
            return Tr.tr("Aurora");
        case "dots":
            return Tr.tr("Dots");
        case "ring":
            return Tr.tr("Ring");
        }
        return "";
    }

    function widgetOn(key: string): bool {
        if (key === "clock")
            return root.desktopClock !== "none";
        if (key === "visualizer")
            return root.desktopVisualiser !== "none";
        return E4C.Config.options.background.widgets[key].enable;
    }

    // caelestia4: the list's switch. The clock and the visualiser count Caelestia's too: off takes both off, on shows
    // end-4's in its last style (the sub-page picks Caelestia's)
    function setWidget(key: string, on: bool): void {
        if (key === "clock")
            GlobalConfig.background.desktopClock.enabled = false;
        if (key === "visualizer")
            GlobalConfig.background.visualiser.enabled = false;
        E4.PresetLayout.setWidgetEnabled(key, on);
        E4.PresetLayout.requestSave(); // Caelestia's on or off is in the preset too
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: the widgets, put on or taken off by hand (PresetLayout.setWidgetEnabled: a new one isn't left
        // under another, and with "Save moves to the preset" it goes into the preset too). The chevron opens the
        // widget's own sub-page with all its options
        SectionHeader {
            text: Tr.tr("Widgets")
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Tokens.padding.small
            Layout.bottomMargin: Tokens.spacing.small
            text: E4C.Config.options.background.presetsEnabled ? Tr.tr("Applying a preset replaces these. With “Save moves to the preset” on, a widget added or removed here goes into the preset applied last.") : Tr.tr("Presets are off: this is your own layout, kept until you change it.")
            color: Colours.palette.m3outline
            font: Tokens.font.label.medium
            wrapMode: Text.WordWrap
        }

        // Not registry rows: PresetLayout.setWidgetEnabled places the widget and saves it to the preset
        Repeater {
            model: root.desktopWidgets

            WidgetToggleRow {
                required property var modelData

                iconName: modelData.icon
                landingId: "e4:background.widgets." + modelData.key + ".enable"
                openName: "widget." + modelData.key
                onOpenRequested: root.nState.openSubPage(openName)
                text: modelData.name
                subtext: modelData.key === "clock" && root.desktopClock !== "none" ? root.styleName("clock", root.desktopClock) : modelData.key === "visualizer" && root.desktopVisualiser !== "none" ? root.styleName("visualizer", root.desktopVisualiser) : ""
                value: root.widgetOn(modelData.key)
                onToggled: root.setWidget(modelData.key, checked)
            }
        }

        RowButton {
            disabled: !root.desktopWidgets.some(w => root.widgetOn(w.key))
            icon: "clear_all"
            text: Tr.tr("Remove all from the desktop")
            subtext: Tr.tr("Every widget, the clock and the visualiser too")
            onClicked: {
                GlobalConfig.background.desktopClock.enabled = false;
                GlobalConfig.background.visualiser.enabled = false;
                for (const w of root.desktopWidgets)
                    E4.PresetLayout.setWidgetEnabled(w.key, false);
                E4.PresetLayout.requestSave();
            }
        }

        // caelestia4: every widget card (WidgetCard.qml)
        SectionHeader {
            text: Tr.tr("Look")
        }

        SliderRow {
            setting: "e4:background.widgets.scale"
        }

        ToggleRow {
            setting: "e4:background.widgets.blurWidgets"
        }

        SliderRow {
            setting: "e4:background.widgets.blurRadius"
        }

        ToggleRow {
            setting: "e4:background.widgets.shadow"
        }

        // caelestia4: end4-pC's widget canvas: right-click a widget to lock or unlock them all
        SectionHeader {
            text: Tr.tr("Arranging")
        }

        ToggleRow {
            setting: "e4:background.widgetsLocked"
        }

        ToggleRow {
            setting: "e4:background.showGrid"
        }

        ToggleRow {
            setting: "e4:background.saveToPreset"
        }

        AdvancedSection {
            ToggleRow {
                setting: "e4:background.showSnapLines"
            }

            // The whole background window on each screen (Background.qml): wallpaper and everything on it
            ToggleRow {
                setting: "c:background.enabled"
            }
        }
    }
}
