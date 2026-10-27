pragma Singleton

import QtQuick
import Caelestia.I18n

QtObject {
    id: root

    // PageCompRegistry.pageComps has each page's component at the same index. `id` is how other code finds a page
    // (indexOf), so pages can be inserted without renumbering
    function indexOf(id: string): int {
        return pages.findIndex(p => p.id === id);
    }

    readonly property list<var> pages: [
        // Appearance
        {
            id: "appearance",
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
            label: Tr.tr("Network"),
            icon: "wifi",
            description: Tr.tr("Wi-Fi, ethernet, VPN"),
            category: "connectivity"
        },
        {
            id: "bluetooth",
            label: Tr.tr("Connected devices"),
            icon: "devices_other",
            description: Tr.tr("Bluetooth, pairing"),
            category: "connectivity",
            noFill: true
        },
        {
            id: "audio",
            label: Tr.tr("Audio"),
            icon: "volume_up",
            description: Tr.tr("App volumes, sound devices"),
            category: "connectivity"
        },

        // System
        // caelestia4: Power & idle (pages/PowerPage.qml): hypridle timers, lock screen, battery
        {
            id: "power",
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
            label: Tr.tr("Hyprland"),
            icon: "desktop_windows",
            description: Tr.tr("Windows, keyboard, mouse, rendering"),
            category: "system"
        },

        // Shell
        {
            id: "panels",
            label: Tr.tr("Panels"),
            icon: "dock_to_bottom",
            description: Tr.tr("Dashboard, taskbar, launcher, sidebar"),
            category: "shell"
        },
        {
            id: "apps",
            label: Tr.tr("Apps"),
            icon: "apps",
            description: Tr.tr("Default apps, favourites, hidden apps"),
            category: "shell"
        },
        {
            id: "services",
            label: Tr.tr("Services"),
            icon: "build",
            description: Tr.tr("Poll intervals, lyrics backend"),
            category: "shell"
        },
        {
            id: "language",
            label: Tr.tr("Language & region"),
            icon: "globe",
            description: Tr.tr("UI language, weather location, display units"),
            category: "shell"
        },

        // About
        {
            id: "about",
            label: Tr.tr("About"),
            icon: "info",
            description: Tr.tr("System information, credits"),
            category: "about"
        },
    ]
}
