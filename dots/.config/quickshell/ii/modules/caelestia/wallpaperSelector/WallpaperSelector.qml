// caelestia4: end-4's wallpaper selector (Ctrl+Super+T) in Caelestia style. Same service (end-4 Wallpapers: folder
// model with history, search, apply through switchwall.sh), same IPC / shortcuts / keys; Caelestia's cached thumbnails
// (CachingImage) instead of end-4's thumbnail script. Videos are listed too (mpvpaper plays them).
// Keys: type to search (/ focuses it), arrows move, Enter applies or opens a folder, Alt+Left/Right/Up back/forward/up,
// Ctrl+L edits the path, Ctrl+V with a copied file/folder goes there, Esc closes. Mouse back/forward buttons work.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs as E4G // caelestia4: keep (GlobalStates)
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.functions as E4F // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.images
import qs.modules.caelestia.adapters

Scope {
    id: root

    function toggle(): void {
        if (E4C.Config.options.wallpaperSelector.useSystemFileDialog) {
            E4.Wallpapers.openFallbackPicker(E4C.Appearance.m3colors.darkmode);
            return;
        }
        E4G.GlobalStates.wallpaperSelectorOpen = !E4G.GlobalStates.wallpaperSelectorOpen;
    }

    LazyLoader {
        active: E4G.GlobalStates.wallpaperSelectorOpen

        StyledWindow {
            id: win

            screen: Quickshell.screens.find(s => s.name === Hypr.focusedMonitor?.name) ?? Quickshell.screens[0]
            name: "wallpaper-selector"
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            // Scrim: click outside the panel to close
            Rectangle {
                anchors.fill: parent
                color: Qt.alpha(Colours.palette.m3scrim, 0.35)
                opacity: 0
                Component.onCompleted: opacity = 1

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: E4G.GlobalStates.wallpaperSelectorOpen = false
                }
            }

            Panel {
                anchors.centerIn: parent
                width: Math.min(win.width * 0.7, 1400)
                height: Math.min(win.height * 0.78, 880)
            }
        }
    }

    component Panel: StyledRect {
        id: panel

        property bool darkMode: E4C.Appearance.m3colors.darkmode
        property bool editingPath: false
        readonly property int columns: Math.max(3, Math.floor(grid.width / 280))

        function choose(path: string): void {
            if (!path)
                return;
            E4.Wallpapers.select(path, panel.darkMode);
            search.text = "";
        }

        function pasteLocation(event: var): void {
            const entry = E4.Cliphist.entries[0] ?? "";
            if (/^\d+\tfile:\/\/\S+/.test(entry)) {
                E4.Wallpapers.setDirectory(E4F.FileUtils.trimFileProtocol(decodeURIComponent(E4F.StringUtils.cleanCliphistEntry(entry))));
                event.accepted = true;
            } else {
                event.accepted = false;
            }
        }

        radius: Tokens.rounding.extraLarge
        color: Colours.palette.m3surface
        focus: true
        scale: 0.94
        opacity: 0
        Component.onCompleted: {
            scale = 1;
            opacity = 1;
            search.forceActiveFocus();
        }

        Behavior on scale {
            Anim {}
        }

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        // Swallow clicks so they don't reach the scrim; mouse back/forward navigate
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.BackButton | Qt.ForwardButton
            onPressed: event => {
                if (event.button === Qt.BackButton)
                    E4.Wallpapers.navigateBack();
                else if (event.button === Qt.ForwardButton)
                    E4.Wallpapers.navigateForward();
            }
        }

        Keys.onPressed: event => event.accepted = panel.handleKey(event)

        // Shared by the panel and the search field (which forwards navigation keys here). true = handled.
        function handleKey(event: var): bool {
            const alt = event.modifiers & Qt.AltModifier;
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
                E4G.GlobalStates.wallpaperSelectorOpen = false;
            } else if (ctrl && event.key === Qt.Key_V) {
                panel.pasteLocation(event);
                return event.accepted;
            } else if (alt && event.key === Qt.Key_Up) {
                E4.Wallpapers.navigateUp();
            } else if (alt && event.key === Qt.Key_Left) {
                E4.Wallpapers.navigateBack();
            } else if (alt && event.key === Qt.Key_Right) {
                E4.Wallpapers.navigateForward();
            } else if (ctrl && event.key === Qt.Key_L) {
                panel.editingPath = true;
            } else if (event.key === Qt.Key_Left) {
                grid.move(-1);
            } else if (event.key === Qt.Key_Right) {
                grid.move(1);
            } else if (event.key === Qt.Key_Up) {
                grid.move(-panel.columns);
            } else if (event.key === Qt.Key_Down) {
                grid.move(panel.columns);
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                grid.activate();
            } else {
                return false;
            }
            return true;
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.padding.large
            spacing: Tokens.spacing.large

            // ---- Places
            StyledRect {
                Layout.fillHeight: true
                Layout.preferredWidth: 200
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer

                ColumnLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Tokens.padding.medium
                    spacing: Tokens.spacing.extraSmall

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: Tokens.padding.small
                        Layout.bottomMargin: Tokens.spacing.medium
                        text: Tr.tr("Wallpapers")
                        color: Colours.palette.m3onSurface
                        font: Tokens.font.body.builders.large.weight(Font.Bold).build()
                    }

                    Repeater {
                        model: [
                            {
                                icon: "wallpaper",
                                name: Tr.tr("Wallpapers"),
                                path: `${E4C.Directories.pictures}/Wallpapers`
                            },
                            ...(E4C.Config.options.policies.weeb === 1 ? [
                                    {
                                        icon: "favorite",
                                        name: Tr.tr("Homework"),
                                        path: `${E4C.Directories.pictures}/homework`
                                    }
                                ] : []),
                            {
                                icon: "image",
                                name: Tr.tr("Pictures"),
                                path: E4C.Directories.pictures
                            },
                            {
                                icon: "movie",
                                name: Tr.tr("Videos"),
                                path: E4C.Directories.videos
                            },
                            {
                                icon: "download",
                                name: Tr.tr("Downloads"),
                                path: E4C.Directories.downloads
                            },
                            {
                                icon: "description",
                                name: Tr.tr("Documents"),
                                path: E4C.Directories.documents
                            },
                            {
                                icon: "home",
                                name: Tr.tr("Home"),
                                path: E4C.Directories.home
                            }
                        ]

                        StyledRect {
                            id: place

                            required property var modelData
                            readonly property bool selected: E4.Wallpapers.effectiveDirectory === E4F.FileUtils.trimFileProtocol(modelData.path)

                            Layout.fillWidth: true
                            implicitHeight: placeRow.implicitHeight + Tokens.padding.medium * 2
                            radius: Tokens.rounding.full
                            color: Qt.alpha(Colours.palette.m3secondaryContainer, selected ? 1 : 0)

                            StateLayer {
                                color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                onClicked: E4.Wallpapers.setDirectory(place.modelData.path)
                            }

                            RowLayout {
                                id: placeRow

                                anchors.fill: parent
                                anchors.leftMargin: Tokens.padding.large
                                anchors.rightMargin: Tokens.padding.large
                                spacing: Tokens.spacing.medium

                                MaterialIcon {
                                    text: place.modelData.icon
                                    fill: place.selected ? 1 : 0
                                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    text: place.modelData.name
                                    elide: Text.ElideRight
                                    color: place.selected ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurface
                                }
                            }
                        }
                    }
                }
            }

            // ---- Path bar, grid, toolbar
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Tokens.spacing.medium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    IconButton {
                        type: IconButton.Text
                        icon: "arrow_back"
                        onClicked: E4.Wallpapers.navigateBack()
                    }

                    IconButton {
                        type: IconButton.Text
                        icon: "arrow_forward"
                        onClicked: E4.Wallpapers.navigateForward()
                    }

                    IconButton {
                        type: IconButton.Text
                        icon: "arrow_upward"
                        disabled: E4.Wallpapers.effectiveDirectory === "/"
                        onClicked: E4.Wallpapers.navigateUp()
                    }

                    // Path: click (or Ctrl+L) to type one
                    StyledRect {
                        Layout.fillWidth: true
                        implicitHeight: Math.max(pathText.implicitHeight, pathField.implicitHeight) + Tokens.padding.small * 2
                        radius: Tokens.rounding.full
                        color: Colours.tPalette.m3surfaceContainer

                        StateLayer {
                            visible: !panel.editingPath
                            radius: parent.radius
                            onClicked: panel.editingPath = true
                        }

                        RowLayout {
                            visible: !panel.editingPath
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.large
                            anchors.rightMargin: Tokens.padding.large
                            spacing: Tokens.spacing.small

                            MaterialIcon {
                                text: "folder"
                                fill: 1
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                id: pathText

                                Layout.fillWidth: true
                                text: E4.Wallpapers.effectiveDirectory.replace(E4C.Directories.home.replace("file://", ""), "~")
                                elide: Text.ElideMiddle
                                color: Colours.palette.m3onSurface
                            }
                        }

                        StyledTextField {
                            id: pathField

                            visible: panel.editingPath
                            anchors.fill: parent
                            type: StyledTextField.Filled
                            verticalPadding: Tokens.padding.small
                            radius: Tokens.rounding.full
                            leadingIcon: "edit"
                            onVisibleChanged: {
                                if (visible) {
                                    text = E4.Wallpapers.effectiveDirectory;
                                    forceActiveFocus();
                                    selectAll();
                                }
                            }
                            onAccepted: {
                                E4.Wallpapers.setDirectory(text.trim().replace(/^~/, E4C.Directories.home.replace("file://", "")));
                                panel.editingPath = false;
                                search.forceActiveFocus();
                            }
                            Keys.onEscapePressed: {
                                panel.editingPath = false;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }

                StyledRect {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Tokens.rounding.large
                    color: Colours.tPalette.m3surfaceContainerLow
                    clip: true

                    GridView {
                        id: grid

                        property int current: 0

                        function move(delta: int): void {
                            current = Math.max(0, Math.min(count - 1, current + delta));
                            positionViewAtIndex(current, GridView.Contain);
                        }

                        function activate(): void {
                            if (count > 0)
                                panel.choose(model.get(current, "filePath"));
                        }

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.small
                        cellWidth: width / panel.columns
                        cellHeight: cellWidth * 0.72
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: E4.Wallpapers.folderModel
                        onCountChanged: current = 0

                        delegate: Item {
                            id: tile

                            required property int index
                            required property string filePath
                            required property string fileName
                            required property bool fileIsDir
                            readonly property bool isVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(fileName)
                            readonly property bool isCurrent: filePath === E4C.Config.options.background.wallpaperPath
                            readonly property bool isSelected: index === grid.current

                            width: grid.cellWidth
                            height: grid.cellHeight

                            StyledRect {
                                id: card

                                anchors.fill: parent
                                anchors.margins: Tokens.padding.small
                                radius: Tokens.rounding.medium
                                color: tile.isSelected ? Colours.palette.m3primaryContainer : tile.isCurrent ? Colours.palette.m3secondaryContainer : "transparent"

                                Behavior on color {
                                    CAnim {}
                                }

                                StateLayer {
                                    radius: card.radius
                                    onEntered: grid.current = tile.index
                                    onClicked: panel.choose(tile.filePath)
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: Tokens.padding.small
                                    spacing: Tokens.spacing.extraSmall

                                    ClipRect {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: Tokens.rounding.small
                                        color: Colours.tPalette.m3surfaceContainerHigh

                                        Loader {
                                            anchors.fill: parent
                                            active: !tile.fileIsDir && !tile.isVideo
                                            asynchronous: true

                                            sourceComponent: CachingImage {
                                                path: tile.filePath
                                            }
                                        }

                                        MaterialIcon {
                                            visible: tile.fileIsDir || tile.isVideo
                                            anchors.centerIn: parent
                                            text: tile.fileIsDir ? "folder" : "movie"
                                            fill: 1
                                            color: tile.fileIsDir ? Colours.palette.m3primary : Colours.palette.m3tertiary
                                            fontStyle: Tokens.font.icon.builders.extraLarge.scale(1.6).build()
                                        }

                                        // Applied now
                                        StyledRect {
                                            visible: tile.isCurrent
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.margins: Tokens.padding.small
                                            implicitWidth: implicitHeight
                                            implicitHeight: checkIcon.implicitHeight + Tokens.padding.small
                                            radius: Tokens.rounding.full
                                            color: Colours.palette.m3primary

                                            MaterialIcon {
                                                id: checkIcon

                                                anchors.centerIn: parent
                                                text: "check"
                                                color: Colours.palette.m3onPrimary
                                            }
                                        }
                                    }

                                    StyledText {
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                        text: tile.fileName
                                        elide: Text.ElideMiddle
                                        font: Tokens.font.body.small
                                        color: tile.isSelected ? Colours.palette.m3onPrimaryContainer : tile.isCurrent ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                                    }
                                }
                            }
                        }

                        StyledScrollBar.vertical: StyledScrollBar {
                            flickable: grid
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: grid.count === 0
                        spacing: Tokens.spacing.small

                        MaterialIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: search.text ? "search_off" : "hide_image"
                            color: Colours.palette.m3outline
                            fontStyle: Tokens.font.icon.builders.extraLarge.scale(2).build()
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: search.text ? Tr.tr("No wallpapers match “%1”").arg(search.text) : Tr.tr("No images or videos in this folder")
                            color: Colours.palette.m3outline
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Tokens.spacing.small

                    StyledTextField {
                        id: search

                        Layout.fillWidth: true
                        type: StyledTextField.Filled
                        radius: Tokens.rounding.full
                        verticalPadding: Tokens.padding.medium
                        leadingIcon: "search"
                        placeholderText: Tr.tr("Search this folder")
                        onTextChanged: E4.Wallpapers.searchQuery = text
                        Keys.onPressed: event => {
                            // Arrows, Enter, Esc and shortcuts go to the panel; typing stays here
                            const nav = [Qt.Key_Up, Qt.Key_Down, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Escape].includes(event.key);
                            const ctrlV = (event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V;
                            if (ctrlV)
                                panel.pasteLocation(event);
                            else
                                event.accepted = (nav || (event.modifiers & (Qt.AltModifier | Qt.ControlModifier))) && panel.handleKey(event);
                        }
                    }

                    IconTextButton {
                        type: IconTextButton.Tonal
                        icon: "shuffle"
                        text: Tr.tr("Random")
                        padding: Tokens.padding.medium
                        onClicked: E4.Wallpapers.randomFromCurrentFolder(panel.darkMode)
                    }

                    IconTextButton {
                        type: IconTextButton.Tonal
                        isToggle: true
                        checked: panel.darkMode
                        icon: panel.darkMode ? "dark_mode" : "light_mode"
                        text: panel.darkMode ? Tr.tr("Dark") : Tr.tr("Light")
                        padding: Tokens.padding.medium
                        onClicked: panel.darkMode = !panel.darkMode
                    }

                    IconButton {
                        type: IconButton.Tonal
                        icon: "open_in_new"
                        onClicked: {
                            E4.Wallpapers.openFallbackPicker(panel.darkMode);
                            E4G.GlobalStates.wallpaperSelectorOpen = false;
                        }
                    }

                    IconButton {
                        icon: "close"
                        onClicked: E4G.GlobalStates.wallpaperSelectorOpen = false
                    }
                }
            }
        }

        // Applying a wallpaper closes the selector (end-4 behaviour)
        Connections {
            target: E4.Wallpapers

            function onChanged(): void {
                E4G.GlobalStates.wallpaperSelectorOpen = false;
            }
        }
    }

    IpcHandler {
        target: "wallpaperSelector"

        function toggle(): void {
            root.toggle();
        }

        function random(): void {
            E4.Wallpapers.randomFromCurrentFolder();
        }
    }

    GlobalShortcut {
        name: "wallpaperSelectorToggle"
        description: "Toggle wallpaper selector"
        onPressed: root.toggle()
    }

    GlobalShortcut {
        name: "wallpaperSelectorRandom"
        description: "Select random wallpaper in current folder"
        onPressed: E4.Wallpapers.randomFromCurrentFolder()
    }
}
