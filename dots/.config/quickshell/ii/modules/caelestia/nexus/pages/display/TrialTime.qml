pragma Singleton

import QtQuick
import Quickshell

// caelestia4: how long a risky change stays on trial before it goes back by itself: Display's "Keep these display
// settings?" and the risky Hyprland rows (pages/hyprland/KeepRevert.qml) use the same time
Singleton {
    readonly property int seconds: 15
}
