pragma Singleton

// caelestia4 ADAPTER: Wallpapers
// Kept from Caelestia: the searchable wallpaper list (FileSystemModel over Paths.wallsdir + Searcher/fuzzy)
// and image preview for the launcher.
// Changed: applying a wallpaper goes through end-4 (E4.Wallpapers.apply -> end-4's matugen pipeline),
// and the current wallpaper is read from end-4's config, not caelestia-cli's path.txt.
// Contract used by Caelestia UI: list, query(search), current, actualCurrent, setWallpaper(path),
// preview(path), stopPreview(), previewColourLock, getCategoryFor(entry), setRandom().
// Not supported: *colour* preview while browsing (needs caelestia-cli); the image preview still works.
// Keep Caelestia's wallpaper dir (shell.json paths.wallpaperDir) and end-4's wallpaper folder the same.

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import Caelestia.Models
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils

Searcher {
    id: root

    readonly property string fallback: Quickshell.shellPath("modules/caelestia/assets/wallpaper.webp")
    readonly property string end4Current: E4C.Config.options.background.wallpaperPath

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent: end4Current || fallback
    property bool previewColourLock

    function getCategoryFor(w: FileSystemEntry): string {
        let category = w.parentDir.slice(Paths.wallsdir.length + 1);
        if (category.includes("/"))
            category = category.slice(0, category.indexOf("/"));
        return category;
    }

    function setRandom(): void {
        E4.Wallpapers.randomFromCurrentFolder();
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        E4.Wallpapers.apply(path);
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
    }

    function stopPreview(): void {
        showPreview = false;
    }

    // end-4 finished applying: follow its config and release the launcher's colour lock
    onEnd4CurrentChanged: {
        actualCurrent = end4Current || fallback;
        previewColourLock = false;
    }

    list: wallpapers.entries
    key: "relativePath"
    useFuzzy: GlobalConfig.launcher.useFuzzy.wallpapers
    extraOpts: useFuzzy ? ({}) : ({
            forward: false
        })

    IpcHandler {
        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }

        target: "wallpaper" // end-4 uses "wallpapers"/"wallpaperSelector"; no clash
    }

    FileSystemModel {
        id: wallpapers

        recursive: true
        path: Paths.wallsdir
        filter: FileSystemModel.Images
    }
}
