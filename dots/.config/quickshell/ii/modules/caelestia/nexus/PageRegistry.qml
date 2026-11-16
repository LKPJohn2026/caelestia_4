pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

    // PageCompRegistry.pageComps has each page's component at the same index (and `subPages` its sub-pages'). `id` is how other code finds a page
    // (indexOf), so pages can be inserted without renumbering
    function indexOf(id: string): int {
        return pages.findIndex(p => p.id === id);
    }

    // caelestia4: sub-pages by name. `subPages` lists a page's StackPage components after its main one, in
    // PageCompRegistry's order: the name at i is sub-page index i + 1. -1 when the page or name is unknown
    function subPageIndex(pageIdx: int, name: string): int {
        const i = (pages[pageIdx]?.subPages ?? []).indexOf(name);
        return i < 0 ? -1 : i + 1;
    }

    function subPageName(pageIdx: int, idx: int): string {
        return (pages[pageIdx]?.subPages ?? [])[idx - 1] ?? "";
    }

    readonly property list<var> pages: [
        // Appearance
        {
            id: "appearance",
            subPages: ["wallpapers", "category", "colours", "presets", "look", "sources", "desktop", "fonts", "widget.clock", "widget.weather", "widget.calendar", "widget.media", "widget.visualizer", "widget.worldClock", "widget.resources", "widget.userCard", "widget.notes", "widget.todo", "widget.timers", "widget.customText", "widget.customImage", "widget.imageCard", "widget.sticker", "widget.images", "scale"],
            // caelestia4: search labels of the sub-pages SearchIndex's own table doesn't name
            subPageLabels: ({
                "fonts": Tr.mark("Fonts"),
                "fonts/scale": Tr.mark("Type scale"),
                "desktop/widget.clock": Tr.mark("Clock"),
                "desktop/widget.weather": Tr.mark("Weather"),
                "desktop/widget.calendar": Tr.mark("Calendar"),
                "desktop/widget.media": Tr.mark("Media player"),
                "desktop/widget.visualizer": Tr.mark("Audio visualiser"),
                "desktop/widget.worldClock": Tr.mark("World clock"),
                "desktop/widget.resources": Tr.mark("System resources"),
                "desktop/widget.userCard": Tr.mark("User card"),
                "desktop/widget.notes": Tr.mark("Notes"),
                "desktop/widget.todo": Tr.mark("To-do list"),
                "desktop/widget.timers": Tr.mark("Timers"),
                "desktop/widget.customText": Tr.mark("Text"),
                "desktop/widget.customImage": Tr.mark("Picture"),
                "desktop/widget.imageCard": Tr.mark("Picture card"),
                "desktop/widget.sticker": Tr.mark("Sticker"),
                "desktop/widget.images": Tr.mark("Image converter")
            }),
            label: Tr.tr("Wallpaper & style"),
            icon: "palette",
            description: Tr.tr("Wallpaper, fonts, colours"),
            category: "appearance"
        },

        // Connectivity
        // caelestia4: upstream's commented-out Display page, filled in (pages/DisplayPage.qml)
        {
            id: "display",
            label: Tr.tr("Display"),
            icon: "monitor",
            description: Tr.tr("Resolution, scale, refresh rate"),
            category: "connectivity"
        },
        {
            id: "network",
            subPages: ["ethernet", "add", "detail", "vpn", "all", "saved"],
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            id: "bluetooth",
            subPages: ["device", "pairing"],
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            id: "audio",
            subPages: ["apps"],
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        // caelestia4: Power & idle (pages/PowerPage.qml): hypridle timers, lock screen, battery
        {
            id: "power",
            subPages: ["lock"],
            subPageLabels: ({
                "lock": Tr.mark("Lock screen")
            }),
            label: Tr.tr("Power & idle"),
            icon: "power_settings_new",
            description: Tr.tr("Idle timers, lock screen, battery"),
            category: "system"
        },
        {
            id: "updates",
            label: Tr.tr("Updates"),
            icon: "update",
            description: Tr.tr("Arch, AUR and caelestia_4 updates"),
            category: "system"
        },
        {
            id: "plugins",
            label: Tr.tr("Plugins"),
            icon: "extension",
            description: Tr.tr("Shell components, Qt, rebuilds"),
            category: "system"
        },
        // caelestia4: Hyprland options (windows, input, cursor, rendering)
        {
            id: "hyprland",
            subPages: ["input", "windows", "rendering", "keybinds"],
            subPageLabels: ({
                "keybinds": Tr.mark("Keyboard shortcuts")
            }),
            label: Tr.tr("Hyprland"),
            icon: "desktop_windows",
            description: Tr.tr("Windows, keyboard, mouse, rendering"),
            category: "system"
        },

        // Shell
        {
            id: "panels",
            subPages: ["dashboard", "taskbar", "launcher", "sidebar", "utilities", "workspaces", "activeWindow", "tray", "statusIcons", "clock", "barLayout", "session", "osd", "assistant", "overview", "cheatsheet"],
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            id: "apps",
            subPages: ["all", "info"],
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            id: "services",
            subPages: ["notifications", "polling", "media", "capture", "advanced"],
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Notifications, media, screenshots, polling"),
            category: "shell"
        },
        {
            id: "language",
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("Languages, time and date, units, weather"),
            category: "shell"
        },

        // About
        {
            id: "about",
            subPages: ["changed", "profiles"],
            // caelestia4: search label of About's sub-page (P6)
            subPageLabels: ({
                "changed": Tr.mark("Changed settings"),
                "profiles": Tr.mark("Profiles")
            }),
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, credits"),
            category: "about"
        },
    ]
}
