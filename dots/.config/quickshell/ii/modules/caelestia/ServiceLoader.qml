import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Scope {
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

        if (GlobalConfig.utilities.vpn.enabled)
            VPN;
    }
}
