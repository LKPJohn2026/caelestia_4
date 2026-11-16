pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common

// caelestia4: picks a folder inside Nexus (the shell's file dialog, components/filedialog, only picks files): the
// folder's path with Up and Home, its sub-folders (click to go in), and "Use this folder", which emits picked(path).
// openAt(path) starts in that folder (or the home folder). Keyboard: Up/Down move the highlight, Enter goes into the
// highlighted folder, Backspace goes up, Esc cancels
NexusDialog {
    id: root

    property string folder: Paths.home
    property bool showHidden
    property int cursor: -1

    signal picked(path: string)

    function openAt(path: string): void {
        root.folder = path ? String(path).replace(/^~(?=\/|$)/, Paths.home).replace(/(.)\/+$/, "$1") : Paths.home;
        root.cursor = -1;
        root.open();
    }

    function goUp(): void {
        if (root.folder === "/")
            return;
        const i = root.folder.lastIndexOf("/");
        root.folder = i <= 0 ? "/" : root.folder.slice(0, i);
        root.cursor = -1;
    }

    function enter(path: string): void {
        root.folder = path;
        root.cursor = -1;
    }

    // ~ for the home folder
    function shortPath(path: string): string {
        return path === Paths.home ? "~" : path.startsWith(Paths.home + "/") ? "~" + path.slice(Paths.home.length) : path;
    }

    title: Tr.tr("Choose a folder")
    tall: true
    enterAccepts: false
    acceptText: Tr.trCtx("Use this folder", "button")
    initialFocus: list

    onAccepted: root.picked(root.folder)

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        IconButton {
            icon: "arrow_upward"
            type: IconButton.Tonal
            disabled: root.folder === "/"
            Accessible.name: Tr.tr("Up one folder")
            onClicked: root.goUp()
        }

        IconButton {
            icon: "home"
            type: IconButton.Tonal
            Accessible.name: Tr.tr("Home folder")
            onClicked: root.enter(Paths.home)
        }

        StyledText {
            Layout.fillWidth: true
            text: root.shortPath(root.folder)
            font: Tokens.font.body.small
            elide: Text.ElideLeft
        }

        IconButton {
            icon: root.showHidden ? "visibility" : "visibility_off"
            type: IconButton.Text
            Accessible.name: Tr.tr("Show hidden folders")
            onClicked: root.showHidden = !root.showHidden
        }
    }

    VerticalFadeListView {
        id: list

        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 0
        focus: true
        activeFocusOnTab: true
        currentIndex: root.cursor
        highlightFollowsCurrentItem: false
        onCurrentIndexChanged: {
            if (currentIndex >= 0)
                positionViewAtIndex(currentIndex, ListView.Contain);
        }

        Keys.onUpPressed: root.cursor = Math.max(0, root.cursor - 1)
        Keys.onDownPressed: root.cursor = Math.min(list.count - 1, root.cursor + 1)
        Keys.onReturnPressed: {
            const item = list.itemAtIndex(root.cursor);
            if (item)
                root.enter(item.modelData.path);
        }
        Keys.onEnterPressed: {
            const item = list.itemAtIndex(root.cursor);
            if (item)
                root.enter(item.modelData.path);
        }
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace) {
                root.goUp();
                event.accepted = true;
            }
        }

        model: FileSystemModel {
            path: root.opened || root.visible ? root.folder : ""
            filter: FileSystemModel.Dirs
            showHidden: root.showHidden
        }

        // Over the view, not in its content
        StyledText {
            parent: list
            anchors.centerIn: parent
            visible: list.count === 0
            text: Tr.tr("No folders in here")
            color: Colours.palette.m3onSurfaceVariant
        }

        delegate: StyledRect {
            id: dirItem

            required property FileSystemEntry modelData
            required property int index

            width: ListView.view.width
            implicitHeight: dirRow.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.medium
            color: Qt.alpha(Colours.palette.m3tertiaryContainer, index === root.cursor ? 1 : 0)

            StateLayer {
                radius: dirItem.radius
                onClicked: root.enter(dirItem.modelData.path)
            }

            RowLayout {
                id: dirRow

                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.medium
                anchors.rightMargin: Tokens.padding.medium
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "folder"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                    fill: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: dirItem.modelData.name
                    color: dirItem.index === root.cursor ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                    font: Tokens.font.body.small
                    elide: Text.ElideRight
                }

                MaterialIcon {
                    text: "chevron_right"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.small
                }
            }
        }
    }
}
