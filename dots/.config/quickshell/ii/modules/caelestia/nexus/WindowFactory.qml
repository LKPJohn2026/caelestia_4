pragma Singleton

// caelestia4 STAND-IN for Caelestia's `nexus` settings app (not ported; see docs/phase3.md).
// Every "open settings" in the Caelestia UI opens end-4's settings app instead.
import QtQuick
import Quickshell

Singleton {
    function create(parent = null, props = null): void {
        Quickshell.execDetached(["qs", "-p", Quickshell.shellPath("settings.qml")]);
    }
}
