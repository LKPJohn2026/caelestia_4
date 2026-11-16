import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "apps" page (merged by Registry.qml). See RegPanels.qml for the format
QtObject {
    readonly property var entries: ({
            // Apps > Default applications (pages/AppsPage.qml). Each row (DefaultRow) has its id: search lands on it,
            // and the c: ones show the modified dot and reset button that match "Reset page"
            // The terminal is ~/.config/xdg-terminals.list (what the session uses); c:general.apps.terminal is kept in
            // step by the row, so it has no entry of its own (a reset would leave the list file as it is). x:apps.terminal
            // has no default, so the row shows no modified mark and "Reset page" leaves it alone
            "x:apps.terminal": {
                route: "apps",
                section: Tr.mark("Default applications"),
                title: Tr.markCtx("Terminal", "default app category"),
                desc: Tr.mark("The terminal for Super+Return, terminal apps and commands"),
                keywords: [Tr.mark("terminal"), Tr.mark("console"), Tr.mark("shell"), Tr.mark("foot"), Tr.mark("kitty"), Tr.mark("default app"), Tr.mark("xdg-terminals")],
                type: "string"
            },
            "c:general.apps.playback": {
                route: "apps",
                section: Tr.mark("Default applications"),
                title: Tr.markCtx("Media playback", "default app category"),
                desc: Tr.mark("The app that plays media files"),
                keywords: [Tr.mark("media"), Tr.mark("video"), Tr.mark("music"), Tr.mark("player"), Tr.mark("mpv"), Tr.mark("playback"), Tr.mark("default app")],
                type: "list"
            },
            "c:general.apps.explorer": {
                route: "apps",
                section: Tr.mark("Default applications"),
                title: Tr.markCtx("File manager", "default app category"),
                desc: Tr.mark("The app that opens folders"),
                keywords: [Tr.mark("files"), Tr.mark("file manager"), Tr.mark("explorer"), Tr.mark("folders"), Tr.mark("thunar"), Tr.mark("nautilus"), Tr.mark("dolphin"), Tr.mark("default app")],
                type: "list"
            },
            // Apps > All apps > App info (pages/apps/AppInfo.qml): per app, so the toggles have no registry id; these
            // entries let a search find where favourites and hidden apps are set. Known limitation: no row has these ids,
            // so a search result opens All apps (where you pick the app; apps/info needs one picked) at the top, with
            // nothing to scroll to or pulse
            "x:apps.favourite": {
                route: "apps/all",
                title: Tr.mark("Favourite"),
                desc: Tr.mark("Pin to the top of the launcher"),
                keywords: [Tr.mark("favourite"), Tr.mark("favorite"), Tr.mark("pin"), Tr.mark("launcher"), Tr.mark("apps"), Tr.mark("star")],
                type: "bool"
            },
            "x:apps.hidden": {
                route: "apps/all",
                title: Tr.mark("Hidden"),
                desc: Tr.mark("Hide from the launcher"),
                keywords: [Tr.mark("hide"), Tr.mark("hidden"), Tr.mark("launcher"), Tr.mark("apps"), Tr.mark("remove")],
                type: "bool"
            },
            // Apps > Default applications: the task manager command
            "e4:apps.taskManager": {
                route: "apps",
                section: Tr.mark("Default applications"),
                title: Tr.mark("Task manager"),
                desc: Tr.mark("The command the session menu and Ctrl+Shift+Esc run"),
                keywords: [Tr.mark("task manager"), Tr.mark("btop"), Tr.mark("htop"), Tr.mark("processes"), Tr.mark("system monitor"), Tr.mark("ctrl+shift+esc")],
                type: "string"
            }
        })
}
