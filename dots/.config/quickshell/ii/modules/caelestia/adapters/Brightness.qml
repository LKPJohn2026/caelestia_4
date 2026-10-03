// caelestia4 ADAPTER: Brightness
// Backed by end-4's Brightness service, so only ONE ddcutil/brightnessctl manager touches the monitors
// (two would race on the DDC/CI bus). Caelestia's UI declares `Brightness.Monitor`, so this file keeps a
// `Monitor` type: a thin wrapper around end-4's per-screen monitor object.
// Contract used by Caelestia UI: Monitor, getMonitorForScreen(screen), monitor.brightness, monitor.setBrightness(v),
// increaseBrightness(), decreaseBrightness().
// Brightness keys and IPC stay owned by end-4 (IPC target "brightness"); nothing is registered here.
pragma Singleton

import QtQuick
import Quickshell
import qs.services as E4 // caelestia4: keep

Singleton {
    id: root

    property var wrappers: ({})

    function getMonitorForScreen(screen: ShellScreen): var {
        if (!screen)
            return null;
        const name = screen.name;
        const source = E4.Brightness.getMonitorForScreen(screen);
        const cached = wrappers[name];
        if (cached && cached.source === source)
            return cached;
        const w = monitorComp.createObject(root, {
            screen: screen,
            source: source
        });
        wrappers[name] = w;
        return w;
    }

    function increaseBrightness(): void {
        E4.Brightness.increaseBrightness();
    }

    function decreaseBrightness(): void {
        E4.Brightness.decreaseBrightness();
    }

    component Monitor: QtObject {
        property ShellScreen screen
        property var source
        readonly property real brightness: source?.brightness ?? 0
        readonly property bool isDdc: source?.isDdc ?? false
        readonly property bool ready: source?.ready ?? false

        function setBrightness(value: real): void {
            source?.setBrightness(value);
        }
    }

    Component {
        id: monitorComp

        Monitor {}
    }
}
