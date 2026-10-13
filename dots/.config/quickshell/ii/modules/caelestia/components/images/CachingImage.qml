import QtQuick
import Quickshell
import Caelestia.Images

Image {
    id: root

    property string path

    asynchronous: true
    fillMode: Image.PreserveAspectCrop
    source: IUtils.urlForPath(path, fillMode)
    // caelestia4: Qt already multiplies sourceSize by the window's devicePixelRatio; multiplying here too decoded
    // images at dpr^2 (11520x3240 for the 7680x2160 / 1.5 screen, ~150 MB per wallpaper)
    sourceSize: Qt.size(width, height)
}
