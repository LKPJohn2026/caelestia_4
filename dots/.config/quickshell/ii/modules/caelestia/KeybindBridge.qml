// caelestia4: makes end-4's existing Hyprland keybinds open the Caelestia drawers.
// end-4's keys call Quickshell global shortcuts (appid "quickshell") that are normally registered by
// ii panels. In the caelestia family those ii panels are not loaded, so the same names are
// registered here and routed to Caelestia's per-screen drawer state.
//   Ctrl+Alt+Delete  sessionToggle      -> session menu
//   Super+N          sidebarRightToggle -> notification sidebar
//   Super+M          mediaControlsToggle -> dashboard (media lives there)
// Everything else (Super search/overview, clipboard, emoji, cheatsheet, region tools, left sidebar, lock…)
// is handled by the end-4 modules the family loads as-is.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.modules.caelestia.adapters

Scope {
    id: root

    function setDrawer(name: string, value: var): void {
        const s = ShellState.forActive();
        if (!s)
            return;
        s[name] = value === "toggle" ? !s[name] : value;
    }

    GlobalShortcut {
        name: "sessionToggle"
        description: "Toggles session screen on press"
        onPressed: root.setDrawer("session", "toggle")
    }

    GlobalShortcut {
        name: "sessionOpen"
        description: "Opens session screen on press"
        onPressed: root.setDrawer("session", true)
    }

    GlobalShortcut {
        name: "sessionClose"
        description: "Closes session screen on press"
        onPressed: root.setDrawer("session", false)
    }

    GlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles right sidebar on press"
        onPressed: root.setDrawer("sidebar", "toggle")
    }

    GlobalShortcut {
        name: "sidebarRightOpen"
        description: "Opens right sidebar on press"
        onPressed: root.setDrawer("sidebar", true)
    }

    GlobalShortcut {
        name: "sidebarRightClose"
        description: "Closes right sidebar on press"
        onPressed: root.setDrawer("sidebar", false)
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Toggles media controls on press"
        onPressed: root.setDrawer("dashboard", "toggle")
    }

    GlobalShortcut {
        name: "mediaControlsOpen"
        description: "Opens media controls on press"
        onPressed: root.setDrawer("dashboard", true)
    }

    GlobalShortcut {
        name: "mediaControlsClose"
        description: "Closes media controls on press"
        onPressed: root.setDrawer("dashboard", false)
    }
}
