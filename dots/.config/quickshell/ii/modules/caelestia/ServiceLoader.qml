import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4 keys that follow Caelestia's, see end4Wanted)
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Scope {
    id: root

    // caelestia4: settings that exist as a Caelestia key (shell.json) and an end-4 key (config.json) are shown once in
    // Nexus, as the Caelestia key (decision D2). Here the end-4 key follows it, one way: on start, when the Caelestia
    // value changes, and when config.json is (re)loaded with another value. Keys are end-4 option paths; a value of
    // undefined means "leave it alone". Reads the global layer (GlobalConfig), not a screen's Config.
    // Clock format: Auto follows the locale; end-4's clocks use time.format (desktop cookie / digital clock, DateTime)
    readonly property var end4Wanted: ({
            "time.format": Units.twelveHourClock ? "h:mm AP" : "hh:mm",
            // AI chat, settings app, overlay
            "appearance.transparency.enable": GlobalConfig.appearance.transparency.enabled,
            // end-4 widgets' fixed-width text; an empty family would break their fonts, so keep the last good one
            "appearance.fonts.monospace": GlobalConfig.appearance.font.mono.family.trim() || undefined,
            // end-4's weather service (desktop weather, daily clock, user card); empty = automatic location
            "bar.weather.city": GlobalConfig.services.weatherLocation.trim(),
            // end-4 has only metric or US units: Fahrenheit (also Auto in a US/UK locale) -> US, °C and K -> metric
            "bar.weather.useUSCS": Units.resolveTempUnit(GlobalConfig.services.weatherUnits) === TemperatureUnit.Fahrenheit
        })

    // caelestia4: the end-4 values now, so a reload of config.json with other values syncs again
    readonly property var end4Current: E4C.Config.ready ? Object.keys(end4Wanted).map(k => end4Value(k)) : []

    function end4Value(path: string): var {
        let node = E4C.Config.options;
        for (const part of path.split("."))
            node = node?.[part];
        return node;
    }

    function syncEnd4(): void {
        // caelestia4: before config.json is loaded the options are end-4's defaults; a write then would be lost
        if (!E4C.Config.ready)
            return;
        for (const [path, want] of Object.entries(end4Wanted)) {
            if (want === undefined || end4Value(path) === want)
                continue;
            const parts = path.split(".");
            const leaf = parts.pop();
            let node = E4C.Config.options;
            for (const part of parts)
                node = node?.[part];
            // Plain assignment: setNestedValue would turn a string like "10001" into a number
            if (node)
                node[leaf] = want;
        }
    }

    onEnd4WantedChanged: Qt.callLater(syncEnd4)
    onEnd4CurrentChanged: Qt.callLater(syncEnd4)

    Component.onCompleted: {
        // caelestia4: caelestia-cli normally creates these; without them the plugin's app DB (apps.sqlite) can't open
        Quickshell.execDetached(["mkdir", "-p", Paths.state, Paths.cache, Paths.notifimagecache]);
        // Force certain singletons to load on shell init instead of lazily

        IdleInhibitor;
        GameMode;
        Notifs;
        Players;
        Brightness;
        Weather.reload();
        syncEnd4();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
