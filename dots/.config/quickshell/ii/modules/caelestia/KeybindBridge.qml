// caelestia4: makes end-4's existing Hyprland keybinds open the Caelestia drawers.
// end-4's keys call Quickshell global shortcuts (appid "quickshell") that are normally registered by
// ii panels. In the caelestia family those ii panels are not loaded, so the same names are
// registered here and routed to Caelestia's per-screen drawer state.
//   Ctrl+Alt+Delete  sessionToggle      -> session menu
//   Super+N          sidebarRightToggle -> notification sidebar
//   Super+M          mediaControlsToggle -> dashboard (media lives there)
//   Super (tap)      searchToggleRelease (+Interrupt) -> Caelestia launcher (merged with end-4 search)
//   Super+V / Super+.  overviewClipboardToggle / overviewEmojiToggle -> launcher pre-filled with ";" / ":"
//   Super+A/B/O      sidebarLeftToggle(+Open/Close/ToggleDetach) -> Assistant drawer (end-4 AI / translator)
//   Super+J          barToggle -> hide/show the bar (ScreenState.barHidden)
// Super+Tab / Alt+Tab (workspaces) is overview/Overview.qml. Cheatsheet, region tools, left sidebar, lock… are the
// end-4 modules the family loads as-is.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.adapters

Scope {
    id: root

    // Open/close the Caelestia launcher on the focused screen. With a prefix, (re)open it pre-filled
    // (e.g. ";" clipboard); pressing the same key again while showing that prefix closes it.
    function launcher(prefix: var): void {
        const s = ShellState.forActive();
        if (!s)
            return;
        if (prefix === undefined) {
            s.launcher = !s.launcher;
            return;
        }
        const field = ShellState.componentsForActive()?.find("launcherSearch");
        if (s.launcher && field && field.text === prefix) {
            s.launcher = false;
            return;
        }
        s.launcher = true;
        prefillTimer.prefix = prefix;
        prefillTimer.tries = 0;
        prefillTimer.restart();
    }

    // The launcher's search field only exists once the drawer has opened, so retry briefly
    Timer {
        id: prefillTimer

        property string prefix
        property int tries

        interval: 25
        repeat: true
        onTriggered: {
            const field = ShellState.componentsForActive()?.find("launcherSearch");
            if (field) {
                field.text = prefix;
                field.forceActiveFocus();
                stop();
            } else if (++tries > 40) {
                stop();
            }
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"
        onPressed: root.launcher(undefined)
    }

    GlobalShortcut {
        name: "searchToggleRelease"
        description: "Toggles search on release"
        onPressed: GlobalStates.superReleaseMightTrigger = true
        onReleased: {
            if (!GlobalStates.superReleaseMightTrigger) {
                GlobalStates.superReleaseMightTrigger = true;
                return;
            }
            root.launcher(undefined);
        }
    }

    GlobalShortcut {
        name: "searchToggleReleaseInterrupt"
        description: "Interrupts possibility of search being toggled on release"
        onPressed: GlobalStates.superReleaseMightTrigger = false
    }

    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query in the launcher"
        onPressed: root.launcher(E4C.Config.options.search.prefix.clipboard)
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query in the launcher"
        onPressed: root.launcher(E4C.Config.options.search.prefix.emojis)
    }

    function setDrawer(name: string, value: var): void {
        const s = ShellState.forActive();
        if (!s)
            return;
        s[name] = value === "toggle" ? !s[name] : value;
    }

    // Super+J: hide/show the bar on the focused screen (end-4 "barToggle"). Hidden = like Caelestia's
    // non-persistent bar: only the frame edge, and hovering the edge still reveals it.
    GlobalShortcut {
        name: "barToggle"
        description: "Toggles the bar"
        onPressed: root.setDrawer("barHidden", "toggle")
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

    // ---- Assistant drawer (end-4 left sidebar content) ----
    GlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggles left sidebar on press"
        onPressed: root.setDrawer("assistant", "toggle")
    }

    GlobalShortcut {
        name: "sidebarLeftOpen"
        description: "Opens left sidebar on press"
        onPressed: root.setDrawer("assistant", true)
    }

    GlobalShortcut {
        name: "sidebarLeftClose"
        description: "Closes left sidebar on press"
        onPressed: root.setDrawer("assistant", false)
    }

    GlobalShortcut {
        name: "sidebarLeftToggleDetach"
        description: "Toggles left sidebar (detach is not supported in the caelestia family)"
        onPressed: root.setDrawer("assistant", "toggle")
    }

    // end-4's AI chat closes "the sidebar" by setting GlobalStates.sidebarLeftOpen = false (e.g. after opening
    // a link). Keep that flag in sync with the Assistant drawer on the focused screen.
    Connections {
        function onSidebarLeftOpenChanged(): void {
            const s = ShellState.forActive();
            if (s && s.assistant !== GlobalStates.sidebarLeftOpen)
                s.assistant = GlobalStates.sidebarLeftOpen;
        }

        target: GlobalStates
    }

    Connections {
        function onAssistantChanged(): void {
            const s = ShellState.forActive();
            if (s && GlobalStates.sidebarLeftOpen !== s.assistant)
                GlobalStates.sidebarLeftOpen = s.assistant;
        }

        target: ShellState.forActive()
        ignoreUnknownSignals: true
    }

    // ---------------------------------------------------------------- end-4 aliases (manual use / scripts)
    // caelestia4: names end-4's ii panels register that nothing in our configs calls, mapped to Caelestia so
    // existing habits and scripts (`qs -c ii ipc call sidebarRight toggle`, …) keep working.
    GlobalShortcut {
        name: "barOpen"
        description: "Shows the bar"
        onPressed: root.setDrawer("barHidden", false)
    }

    GlobalShortcut {
        name: "barClose"
        description: "Hides the bar"
        onPressed: root.setDrawer("barHidden", true)
    }

    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Shows the volume OSD"
        onPressed: root.setDrawer("osd", true)
    }

    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides the volume OSD"
        onPressed: root.setDrawer("osd", false)
    }

    // bar: the state is barHidden, so open = not hidden
    IpcHandler {
        target: "bar"

        function toggle(): void {
            root.setDrawer("barHidden", "toggle");
        }
        function open(): void {
            root.setDrawer("barHidden", false);
        }
        function close(): void {
            root.setDrawer("barHidden", true);
        }
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void {
            root.setDrawer("assistant", "toggle");
        }
        function open(): void {
            root.setDrawer("assistant", true);
        }
        function close(): void {
            root.setDrawer("assistant", false);
        }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void {
            root.setDrawer("sidebar", "toggle");
        }
        function open(): void {
            root.setDrawer("sidebar", true);
        }
        function close(): void {
            root.setDrawer("sidebar", false);
        }
    }

    IpcHandler {
        target: "session"

        function toggle(): void {
            root.setDrawer("session", "toggle");
        }
        function open(): void {
            root.setDrawer("session", true);
        }
        function close(): void {
            root.setDrawer("session", false);
        }
    }

    IpcHandler {
        target: "mediaControls"

        function toggle(): void {
            root.setDrawer("dashboard", "toggle");
        }
        function open(): void {
            root.setDrawer("dashboard", true);
        }
        function close(): void {
            root.setDrawer("dashboard", false);
        }
    }

    IpcHandler {
        target: "osdVolume"

        function trigger(): void {
            root.setDrawer("osd", true);
        }
        function hide(): void {
            root.setDrawer("osd", false);
        }
        function toggle(): void {
            root.setDrawer("osd", "toggle");
        }
    }
}
