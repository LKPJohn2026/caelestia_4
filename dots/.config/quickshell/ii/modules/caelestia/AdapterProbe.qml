// caelestia4: Phase 2 self-test for the adapter layer. Non-visual.
// Reads every member of each adapter's contract (from the Caelestia UI usage inventory) and logs
// "[caelestia4 probe] OK <Adapter>" or the missing/undefined members. Also creates one Caelestia
// component to prove the plugin + ported components load.
// Turn off with Config.options.caelestia.debugProbe = false.
import QtQuick
import Quickshell
import qs.modules.caelestia.adapters
import qs.modules.caelestia.components

Scope {
    id: root

    function check(name: string, obj: var, members: list<string>): void {
        const missing = [];
        for (const m of members) {
            try {
                if (obj[m] === undefined)
                    missing.push(m);
            } catch (e) {
                missing.push(`${m} (${e})`);
            }
        }
        if (missing.length === 0)
            console.log(`[caelestia4 probe] OK ${name}`);
        else
            console.warn(`[caelestia4 probe] FAIL ${name}: missing ${missing.join(", ")}`);
    }

    Component.onCompleted: {
        console.log("[caelestia4 probe] start");
        // Backed by end-4
        check("Colours", Colours, ["palette", "tPalette", "layer", "on", "light", "transparency", "scheme", "setMode", "showPreview", "wallLuminance"]);
        check("Colours.palette", Colours.palette, ["m3primary", "m3onSurface", "m3surfaceContainer", "m3success", "m3primary_paletteKeyColor", "term0"]);
        check("Notifs", Notifs, ["list", "notClosed", "popups", "dnd", "hasFullscreen"]);
        check("Wallpapers", Wallpapers, ["list", "query", "current", "actualCurrent", "setWallpaper", "preview", "stopPreview", "previewColourLock"]);
        check("Recorder", Recorder, ["running", "paused", "elapsed", "start", "stop", "togglePause"]);
        check("IdleInhibitor", IdleInhibitor, ["enabled", "enabledSince"]);
        check("Brightness", Brightness, ["getMonitorForScreen", "increaseBrightness", "decreaseBrightness"]);
        // Caelestia's own (thin wrappers)
        check("Audio", Audio, ["volume", "muted", "sourceVolume", "sourceMuted", "setVolume", "incrementVolume", "decrementVolume", "sink", "source", "sinks", "sources", "cava", "beatTracker"]);
        check("Hypr", Hypr, ["workspaces", "activeToplevel", "dispatch", "monitorFor", "kbLayout", "capsLock", "numLock", "usingLua", "focusedWorkspace"]);
        check("Nmcli", Nmcli, ["active", "networks", "wifiEnabled", "scanning", "toggleWifi", "rescanWifi", "connectToNetwork"]);
        check("VPN", VPN, ["status", "toggle", "connected"]);
        check("Players", Players, ["active", "list", "getArtUrl", "getIdentity"]);
        check("Weather", Weather, ["temp", "icon", "description", "forecast", "reload", "formatTemp"]);
        check("Time", Time, ["format", "hourStr", "minuteStr", "amPmStr"]);
        check("Screens", Screens, ["screens"]);
        check("ShellState", ShellState, ["forActive", "forScreen", "componentsFor"]);
        check("GameMode", GameMode, ["enabled"]);

        const mon = Brightness.getMonitorForScreen(Quickshell.screens[0]);
        check("Brightness.Monitor", mon, ["brightness", "setBrightness", "isDdc"]);
        console.log(`[caelestia4 probe] notifs mirrored: ${Notifs.list.length}, wallpaper: ${Wallpapers.actualCurrent}, light: ${Colours.light}, primary: ${Colours.palette.m3primary}`);
        console.log(`[caelestia4 probe] component: ${probeText}`);
        console.log("[caelestia4 probe] done");
    }

    // One real Caelestia component (needs the Caelestia plugin on QML_IMPORT_PATH)
    property Item probeHolder: Item {
        visible: false

        StyledText {
            id: probeText

            text: "probe"
        }
    }
}
