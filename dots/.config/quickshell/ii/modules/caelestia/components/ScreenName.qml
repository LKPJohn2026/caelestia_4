import QtQuick
import Quickshell

// caelestia4: the name a window gives its content's Config.screen / Tokens.screen (Caelestia's config is per screen; an
// empty name means "no screen" and every Config.* / Tokens.* read then warns). When the window's output goes (a monitor
// dropping off its link on resume), Qt moves the window to a nameless placeholder screen until an output is back or the
// window is destroyed. This keeps the last real name meanwhile. A ShellScreen whose QScreen is already gone (dangling)
// names itself "{ NULL SCREEN }" (quickshell core/qmlscreen.cpp): not a real name either, and the plugin would make a
// config layer for it. It takes the window, not its screen: the window's `screen` is always its current one, while a
// ShellScreen held here would be read once more after its QScreen is destroyed ("attempted to use dangling screen
// object").
QtObject {
    property QtObject window // a Quickshell window (PanelWindow, FloatingWindow, PopupWindow)

    readonly property string current: window?.screen?.name ?? ""
    readonly property string name: current !== "" && current !== "{ NULL SCREEN }" ? current : last
    property string last

    onNameChanged: if (name !== "") last = name
}
