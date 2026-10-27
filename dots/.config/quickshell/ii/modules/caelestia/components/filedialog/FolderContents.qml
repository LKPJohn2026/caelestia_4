pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.components.filedialog
import Caelestia.Multimedia
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Item {
    id: root

    required property var dialog

    // caelestia4 (upstream #2100): home folder name -> freedesktop folder icon, the English names and the XDG user
    // dirs' (localised) names
    readonly property var userDirIcons: {
        const icons = {
            Desktop: "desktop",
            Documents: "documents",
            Downloads: "downloads",
            Music: "music",
            Pictures: "pictures",
            Public: "public",
            Templates: "templates",
            Videos: "videos"
        };
        const xdg = [[StandardPaths.DesktopLocation, "desktop"], [StandardPaths.DocumentsLocation, "documents"], [StandardPaths.DownloadLocation, "downloads"], [StandardPaths.MusicLocation, "music"], [StandardPaths.PicturesLocation, "pictures"], [StandardPaths.MoviesLocation, "videos"]];
        for (const [location, icon] of xdg) {
            const name = Paths.toLocalFile(StandardPaths.writableLocation(location)).split("/").pop();
            if (name && !(name in icons))
                icons[name] = icon;
        }
        return icons;
    }
    readonly property FileEntry currentItem: view.currentItem as FileEntry

    StyledRect {
        anchors.fill: parent
        color: Colours.tPalette.m3surfaceContainer

        layer.enabled: true
        layer.effect: Mask {
            maskSource: mask
            maskInverted: true
        }
    }

    Item {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        Rectangle {
            anchors.fill: parent
            anchors.margins: Tokens.padding.extraSmall
            radius: Tokens.rounding.medium
        }
    }

    Loader {
        asynchronous: true
        anchors.centerIn: parent

        opacity: view.count === 0 ? 1 : 0
        active: opacity > 0

        sourceComponent: ColumnLayout {
            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "scan_delete"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).weight(Font.Medium).build()
            }

            StyledText {
                text: Tr.tr("This folder is empty")
                color: Colours.palette.m3outline
                font: Tokens.font.body.builders.large.weight(Font.Medium).build()
            }
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
    }

    GridView {
        id: view

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraSmall + Tokens.padding.medium

        cellWidth: Sizes.itemWidth + Tokens.spacing.small
        cellHeight: Sizes.itemWidth + Tokens.spacing.large + Tokens.padding.medium * 2 + 1

        clip: true
        focus: true
        currentIndex: -1
        Keys.onEscapePressed: currentIndex = -1

        Keys.onReturnPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted((currentItem as FileEntry).modelData.path);
        }
        Keys.onEnterPressed: {
            if (root.dialog.selectionValid)
                root.dialog.accepted((currentItem as FileEntry).modelData.path);
        }

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: view
        }

        model: FileSystemModel {
            path: {
                if (root.dialog.cwd[0] === "Home")
                    return Paths.home + `/${root.dialog.cwd.slice(1).join("/")}`;
                else
                    return root.dialog.cwd.join("/");
            }
            onPathChanged: view.currentIndex = -1
        }

        delegate: FileEntry {}

        add: Transition {
            Anim {
                properties: "opacity,scale"
                from: 0
                to: 1
            }
        }

        remove: Transition {
            Anim {
                type: Anim.DefaultEffects
                property: "opacity"
                to: 0
            }
            Anim {
                property: "scale"
                to: 0.5
            }
        }

        displaced: Transition {
            Anim {
                type: Anim.DefaultEffects
                properties: "opacity,scale"
                to: 1
                easing: Tokens.anim.standardDecel
            }
            Anim {
                properties: "x,y"
            }
        }
    }

    CurrentItem {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: Tokens.padding.extraSmall

        currentItem: view.currentItem
    }

    component FileEntry: StyledRect {
        id: item

        required property int index
        required property FileSystemEntry modelData

        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Tokens.padding.medium * 2

        implicitWidth: Sizes.itemWidth
        implicitHeight: nonAnimHeight

        radius: Tokens.rounding.large
        color: Qt.alpha(Colours.tPalette.m3surfaceContainerHighest, GridView.isCurrentItem ? Colours.tPalette.m3surfaceContainerHighest.a : 0)
        z: GridView.isCurrentItem || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        StateLayer {
            onClicked: view.currentIndex = item.index
            onDoubleClicked: {
                if (item.modelData.isDir)
                    root.dialog.cwd.push(item.modelData.name);
                else if (root.dialog.selectionValid)
                    root.dialog.accepted(item.modelData.path);
            }
        }

        // caelestia4: pictures through Caelestia.Multimedia's Visual (cached, sized to the tile), as upstream 35f3d210;
        // file / folder icons through Quickshell's IconImage: Visual hands image:// URLs to an asynchronous Image, which
        // runs Quickshell's icon provider off the GUI thread ("Cannot create children for a parent ... different thread")
        Item {
            id: icon

            readonly property string iconSource: {
                const file = item.modelData;
                if (file.isImage)
                    return "";
                if (!file.isDir)
                    return Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
                // caelestia4 (upstream #2100): the XDG user dirs' own names (~/Ảnh here) get their folder icons too
                if (root.dialog.cwd.length === 1) {
                    const icon = root.userDirIcons[file.name];
                    if (icon)
                        return Quickshell.iconPath(`folder-${icon}`);
                }
                return Quickshell.iconPath("inode-directory");
            }

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Tokens.padding.medium

            implicitWidth: Sizes.itemWidth - Tokens.padding.medium * 2
            implicitHeight: implicitWidth

            Loader {
                anchors.fill: parent
                active: item.modelData.isImage

                sourceComponent: Visual {
                    source: Qt.resolvedUrl(item.modelData.path)
                    fillMode: VisualSource.PreserveAspectFit
                }
            }

            IconImage {
                anchors.fill: parent
                visible: !item.modelData.isImage
                source: icon.iconSource
                asynchronous: false
            }
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Tokens.spacing.small
            anchors.margins: Tokens.padding.medium

            horizontalAlignment: Text.AlignHCenter
            elide: item.GridView.isCurrentItem ? Text.ElideNone : Text.ElideRight
            wrapMode: item.GridView.isCurrentItem ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap

            Component.onCompleted: text = item.modelData.name
        }

        Behavior on implicitHeight {
            Anim {}
        }
    }
}
