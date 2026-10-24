import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4's clock format follows Caelestia's)
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Scope {
    // caelestia4: one clock format. Caelestia's (Settings > Apps > Date & time, Nexus > Language & region; Auto follows
    // the locale) also sets end-4's time.format, which its clocks use (desktop cookie / digital clock, DateTime)
    readonly property string end4TimeFormat: Units.twelveHourClock ? "h:mm AP" : "hh:mm"
    readonly property bool end4ConfigReady: E4C.Config.ready

    function syncEnd4TimeFormat(): void {
        if (E4C.Config.ready && E4C.Config.options.time.format !== end4TimeFormat)
            E4C.Config.options.time.format = end4TimeFormat;
    }

    onEnd4TimeFormatChanged: syncEnd4TimeFormat()
    onEnd4ConfigReadyChanged: syncEnd4TimeFormat()

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
        syncEnd4TimeFormat();

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
