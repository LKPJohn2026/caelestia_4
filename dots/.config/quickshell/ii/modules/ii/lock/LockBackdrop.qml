pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Caelestia.Config
import qs.modules.common
import qs.modules.common.functions
import qs.modules.caelestia.adapters as CA
import qs.modules.caelestia.background as CB

// caelestia4: what the lock screen sits on. Hyprland's session_lock_xray is off (hyprland/general.lua), so nothing of
// the desktop is drawn under the lock surface, not even the background layer: the wallpaper and the desktop widgets
// shown while locked (the lock-style clock and "Locked" text, the rest with lock.showWidgets) are drawn here instead,
// opaque, and take no input. They are made at every lock (the lock's surfaces only exist while locked): a leastBusy
// place or a colText colour is the desktop's, at once (services/WallpaperRegions.qml), not worked out again. While the picture loads (or is missing) the surface is a plain colour, never see-through.
Item {
    id: root

    property ShellScreen screen
    readonly property var screenConfig: GlobalConfig.forScreen(root.screen?.name ?? "")
    readonly property real borderThickness: root.screenConfig?.border?.thickness ?? 0

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0Base // not colLayer0: that one is made see-through by the transparency setting
    }

    Image {
        id: wallpaper

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        source: root.screen ? FileUtils.fileUrl(CA.Wallpapers.forScreen(root.screen)) : ""
        sourceSize.width: root.width * (root.screen?.devicePixelRatio ?? 1)
        sourceSize.height: root.height * (root.screen?.devicePixelRatio ?? 1)
    }

    // as on the desktop (Background.qml): the room beside the bar and the border
    CB.PcWidgetsLoader {
        anchors.fill: parent
        anchors.margins: root.borderThickness
        anchors.leftMargin: Tokens.sizes.bar.innerWidth + Math.max(Tokens.padding.small, root.borderThickness)
        enabled: false
        wallpaperItem: wallpaper
    }
}
