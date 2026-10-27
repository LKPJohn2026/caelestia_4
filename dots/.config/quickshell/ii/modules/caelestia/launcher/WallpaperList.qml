pragma ComponentBehavior: Bound

import "items"
import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

PathView {
    id: root

    required property SearchBar search
    required property var screenState
    required property var panels
    required property var content

    // caelestia4 (upstream #2135): the folder being browsed; a search looks through every folder
    property string currentDir: Paths.wallsdir
    readonly property ShellScreen launcherScreen: (QsWindow.window as QsWindow)?.screen ?? null // upstream #2210
    readonly property int itemWidth: Tokens.sizes.launcher.wallpaperWidth * 0.8 + Tokens.padding.medium * 2

    readonly property int numItems: {
        const screen = launcherScreen;
        if (!screen)
            return 0;

        // Screen width - 4x outer rounding - 2x max side thickness (cause centered)
        const barMargins = Math.max(Config.border.thickness, panels.bar.implicitWidth);
        let outerMargins = 0;
        if (panels.popouts.hasCurrent && panels.popouts.currentCenter + panels.popouts.nonAnimHeight / 2 > screen.height - content.implicitHeight - Config.border.thickness * 2)
            outerMargins = panels.popouts.nonAnimWidth;
        if ((screenState.utilities || screenState.sidebar) && panels.utilities.implicitWidth > outerMargins)
            outerMargins = panels.utilities.implicitWidth;
        const maxWidth = screen.width - Config.border.rounding * 4 - (barMargins + outerMargins) * 2;

        if (maxWidth <= 0)
            return 0;

        const maxItemsOnScreen = Math.floor(maxWidth / itemWidth);
        const visible = Math.min(maxItemsOnScreen, Config.launcher.maxWallpapers, scriptModel.values.length);

        if (visible === 2)
            return 1;
        if (visible > 1 && visible % 2 === 0)
            return visible - 1;
        return visible;
    }

    function navigateTo(path: string): void {
        if (path !== Paths.wallsdir && !path.startsWith(`${Paths.wallsdir}/`))
            return;
        currentDir = path; // the list's new values pick the card
    }

    // Enter and clicks: open a folder, or set the wallpaper
    function activateEntry(entry: var): void {
        if (entry.isDir) {
            navigateTo(entry.path);
            return;
        }
        // Hold the colours this card previews until end-4's arrive, so the old scheme doesn't flash in between
        if (Colours.scheme === "dynamic" && entry.path === Wallpapers.previewPath && entry.path !== Wallpapers.actualCurrent)
            Wallpapers.previewColourLock = true;
        Wallpapers.setWallpaper(entry.path);
        screenState.launcher = false;
    }

    function activateCurrent(): void {
        if (currentItem)
            activateEntry((currentItem as WallpaperItem).modelData);
    }

    // On the card of what this screen shows (upstream #2210), else the first entry after ".."
    function resetSelection(): void {
        const values = scriptModel.values;
        const wallpaper = Wallpapers.actualForScreen(launcherScreen);
        const index = scriptModel.search ? -1 : values.findIndex(w => w.path === wallpaper);
        currentIndex = index >= 0 ? index : (values[0]?.isParent && values.length > 1 ? 1 : 0);
    }

    model: ScriptModel {
        id: scriptModel

        readonly property string search: root.search.text.split(" ").slice(1).join(" ")

        values: {
            if (search)
                return Wallpapers.query(search);

            const parentEntry = root.currentDir === Paths.wallsdir ? [] : [
                {
                    path: root.currentDir.slice(0, root.currentDir.lastIndexOf("/")),
                    relativePath: "..",
                    name: "..",
                    isDir: true,
                    isParent: true
                }
            ];
            return [...parentEntry, ...folders.entries, ...Wallpapers.list.filter(w => w.parentDir === root.currentDir)];
        }
        onValuesChanged: root.resetSelection()
    }

    // Open in the folder of what this screen shows; completing under an asynchronous Loader resets the index to 0
    Component.onCompleted: {
        const wallpaper = Wallpapers.actualForScreen(launcherScreen);
        const dir = wallpaper.slice(0, wallpaper.lastIndexOf("/"));
        if (dir.startsWith(`${Paths.wallsdir}/`))
            currentDir = dir;
        resetSelection();
    }
    Component.onDestruction: Wallpapers.stopPreview()

    onCurrentItemChanged: {
        if (currentItem && !(currentItem as WallpaperItem).modelData.isDir)
            Wallpapers.preview((currentItem as WallpaperItem).modelData.path);
    }

    implicitWidth: Math.min(numItems, count) * itemWidth
    pathItemCount: numItems
    cacheItemCount: 4

    snapMode: PathView.SnapToItem
    preferredHighlightBegin: 0.5
    preferredHighlightEnd: 0.5
    highlightRangeMode: PathView.StrictlyEnforceRange

    delegate: WallpaperItem {
        wallpaperList: root
    }

    path: Path {
        startY: root.height / 2

        PathAttribute {
            name: "z"
            value: 0
        }
        PathLine {
            x: root.width / 2
            relativeY: 0
        }
        PathAttribute {
            name: "z"
            value: 1
        }
        PathLine {
            x: root.width
            relativeY: 0
        }
    }

    CustomMouseArea {
        function onWheel(event: WheelEvent): void {
            if (event.angleDelta.y > 0)
                root.decrementCurrentIndex();
            else if (event.angleDelta.y < 0)
                root.incrementCurrentIndex();
        }

        anchors.fill: parent
    }

    // Folders of the one being browsed (hidden ones such as .git left out)
    FileSystemModel {
        id: folders

        path: root.currentDir
        filter: FileSystemModel.Dirs
    }
}
