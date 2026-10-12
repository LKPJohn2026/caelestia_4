pragma Singleton

// caelestia4 STAND-IN for Caelestia's `nexus` settings app (not ported; see docs/phase3.md).
// Every "open settings" in the Caelestia UI opens end-4's settings app instead.
import QtQuick
import Quickshell
import qs.services as E4 // caelestia4: AppLauncher (apps get their own unit under uwsm)

Singleton {
    function create(parent = null, props = null): void {
        E4.AppLauncher.exec(["qs", "-p", Quickshell.shellPath("settings.qml")]);
    }
}
