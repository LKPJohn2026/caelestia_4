//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

// Remove two slashes below and adjust the value to change the UI scale
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/common"
import "services"
import "panelFamilies"

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    // Stuff for every panel family
    ReloadPopup {}

    Component.onCompleted: {
        // caelestia4: no hot reload when the config files change. After a reload, icons looked up through the icon
        // theme (tray items, launcher and dock app icons) render blank until a full restart (Qt icon engine state
        // doesn't survive Quickshell's in-process reload). Installs restart the unit instead (tools/install-main.sh,
        // Ctrl+Super+R: systemctl --user restart caelestia4-shell).
        Quickshell.watchFiles = false
        MaterialThemeLoader.reapplyTheme()
        Hyprsunset.load()
        FirstRunExperience.load()
        ConflictKiller.load()
        Cliphist.refresh()
        Wallpapers.load()
        Updates.load()
    }


    // caelestia4: one panel set. end-4's ii family (the Ctrl+Super+P fallback) was removed 2026-10-12, Waffle 2026-10-11;
    // under uwsm systemd restarts the shell if it crashes.
    LazyLoader {
        active: Config.ready
        component: CaelestiaFamily {}
    }
}

