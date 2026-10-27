import QtQuick
import Caelestia.Config
import Caelestia.Models
import Caelestia.Multimedia
import qs.modules.caelestia.components
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

Item {
    id: root

    // caelestia4 (upstream #2135): a wallpaper, a folder, or ".." back to the folder above
    required property var modelData
    required property var wallpaperList

    readonly property bool isDir: modelData.isDir
    readonly property bool isParent: modelData.isParent ?? false
    // A folder shows its first wallpaper (from any subfolder) behind its icon
    readonly property string folderThumbnail: isDir && !isParent ? (Wallpapers.list.find(w => w.path.startsWith(`${modelData.path}/`))?.path ?? "") : ""

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0 // qmllint disable missing-property

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Tokens.padding.medium * 2
    implicitHeight: image.height + label.height + Tokens.spacing.extraSmall + Tokens.padding.large + Tokens.padding.medium

    StateLayer {
        id: stateLayer

        radius: Tokens.rounding.large
        onClicked: root.wallpaperList.activateEntry(root.modelData)
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    ClipRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Tokens.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.large

        implicitWidth: Tokens.sizes.launcher.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            visible: !root.isDir
            text: "image"
            color: Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }

        Visual {
            anchors.fill: parent
            visible: source !== ""
            source: root.isDir ? root.folderThumbnail : root.modelData.path
            // upstream 28fcf7d3; the pause toggle is Wallpapers.videoPaused here (PersistentState upstream)
            playing: !root.isDir && ((root.PathView.isCurrentItem && !Wallpapers.videoPaused) || stateLayer.containsMouse)
        }

        // caelestia4 (upstream #2135): folders and ".." are an icon over a dimmed thumbnail
        StyledRect {
            anchors.fill: parent
            visible: root.isDir && root.folderThumbnail !== ""
            color: Qt.alpha(Colours.palette.m3scrim, 0.5)
        }

        MaterialIcon {
            anchors.centerIn: parent
            visible: root.isDir
            text: root.isParent ? "arrow_back" : "folder"
            color: root.folderThumbnail ? Colours.palette.m3onSurface : Colours.tPalette.m3outline
            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.DemiBold).build()
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Tokens.spacing.extraSmall
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Tokens.padding.medium * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        // A folder's name; a wallpaper's name, or its path in search results from other folders
        text: root.isDir || root.modelData.parentDir === root.wallpaperList.currentDir ? root.modelData.name : root.modelData.relativePath
        font: Tokens.font.label.medium
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }
}
