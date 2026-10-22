pragma Singleton

// caelestia4 ADAPTER: Wallpapers
// Kept from Caelestia: the searchable wallpaper list (FileSystemModel over Paths.wallsdir + Searcher/fuzzy)
// and image preview for the launcher.
// Changed: applying a wallpaper goes through end-4 (E4.Wallpapers.apply -> end-4's matugen pipeline),
// and the current wallpaper is read from end-4's config, not caelestia-cli's path.txt.
// Contract used by Caelestia UI: list, query(search), current, actualCurrent, setWallpaper(path),
// preview(path), stopPreview(), previewColourLock, getCategoryFor(entry), setRandom().
// Colour preview while browsing: `caelestia wallpaper -p` (utils/scripts/wallpreview.sh's matugen dry run without
// caelestia-cli), and Colours shows the result until the preview stops (not for videos).
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

    // caelestia4: video wallpapers (end-4's switchwall.sh plays them with mpvpaper on the background layer and saves a
    // first-frame thumbnail). Show the thumbnail as the image (colours, previews, lock blur); while mpvpaper is running
    // the background goes transparent and moves up a layer so the video shows through (videoPlaying).
    readonly property bool isVideo: /\.(mp4|webm|mkv|avi|mov)$/i.test(end4Current)
    readonly property string end4Thumbnail: E4C.Config.options.background.thumbnailPath ?? ""
    property bool videoPlaying: false

    // caelestia4: pause / play the video wallpaper (Caelestia's "wallpaper playing" toggle). The state is a marker file
    // kept by scripts/caelestia4/wallpaper-pause.sh, which also tells each mpvpaper over its mpv IPC socket
    property bool videoPaused: false
    readonly property string pauseScript: Quickshell.shellPath("scripts/caelestia4/wallpaper-pause.sh")

    function setVideoPaused(paused: bool): void {
        videoPaused = paused; // optimistic; the marker file confirms
        Quickshell.execDetached([pauseScript, paused ? "pause" : "play"]);
    }

    FileView {
        path: `${Quickshell.env("XDG_STATE_HOME") || `${Quickshell.env("HOME")}/.local/state`}/caelestia4/wallpaper-paused`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.videoPaused = true
        onLoadFailed: root.videoPaused = false
    }

    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent: (isVideo ? end4Thumbnail : end4Current) || fallback

    // mpvpaper starts a moment after switchwall.sh / the login restore script: check now and twice more
    onIsVideoChanged: videoCheck.recheck()
    Component.onCompleted: videoCheck.recheck()

    Timer {
        id: videoCheck

        property int tries

        function recheck(): void {
            tries = 0;
            if (!root.isVideo) {
                stop();
                root.videoPlaying = false;
                return;
            }
            restart();
        }

        interval: 1500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (++tries >= 3)
                stop();
            mpvpaperCheck.running = true;
        }
    }

    Process {
        id: mpvpaperCheck

        command: ["pgrep", "-x", "mpvpaper"]
        onExited: code => root.videoPlaying = root.isVideo && code === 0
    }
    // Set by the launcher when a previewed wallpaper is picked: keep showing the preview colours until end-4's
    // regenerated colours arrive, so the old ones don't flash back in between
    property bool previewColourLock
    property bool pendingPreviewClear

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
        // Colours only follow the wallpaper with the "dynamic" scheme; videos have no frame to read here
        if (Colours.scheme === "dynamic" && !/\.(mp4|webm|mkv|avi|mov)$/i.test(path))
            previewDebounce.restart();
    }

    function stopPreview(): void {
        showPreview = false;
        previewDebounce.stop();
        previewProc.running = false;
        if (previewColourLock)
            pendingPreviewClear = true;
        else
            Colours.showPreview = false;
    }

    onPreviewColourLockChanged: {
        if (previewColourLock) {
            lockTimeout.restart();
        } else if (pendingPreviewClear) {
            pendingPreviewClear = false;
            Colours.showPreview = false;
        }
    }

    // end-4 wrote the new wallpaper path (colours are generated after this): follow it
    onEnd4CurrentChanged: actualCurrent = end4Current || fallback

    // end-4's colours changed: the applied wallpaper's palette is in, the preview can go
    Connections {
        target: E4C.Appearance.m3colors

        function onM3primaryChanged(): void {
            root.previewColourLock = false;
        }
        function onM3surfaceChanged(): void {
            root.previewColourLock = false;
        }
    }

    Timer {
        id: lockTimeout

        interval: 15000 // same colours (or theming off): don't keep the preview forever
        onTriggered: root.previewColourLock = false
    }

    Timer {
        id: previewDebounce

        interval: 120 // scrolling through the list only computes the one it stops on
        onTriggered: {
            previewProc.running = false;
            // caelestia-cli prints the scheme it would make (current mode and variant); without it, matugen dry run
            previewProc.command = Colours.cliAvailable ? ["caelestia", "wallpaper", "-p", root.previewPath, ...(GlobalConfig.services.smartScheme ? [] : ["--no-smart"])] : [Quickshell.shellPath("modules/caelestia/utils/scripts/wallpreview.sh"), root.previewPath, Colours.currentLight ? "light" : "dark"];
            previewProc.running = true;
        }
    }

    Process {
        id: previewProc

        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.showPreview || !text)
                    return;
                try {
                    if (Colours.cliAvailable)
                        Colours.load(text, true);
                    else
                        Colours.loadPreview(text, Colours.currentLight);
                    Colours.showPreview = true;
                } catch (e) {
                    // cut off by a newer preview (fast scrolling): its own result follows
                }
            }
        }
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
        filter: FileSystemModel.Images | FileSystemModel.Videos // videos too (upstream d6cc0d5d); applying one goes to mpvpaper
    }
}
