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
import Caelestia.State
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
    Component.onCompleted: {
        videoCheck.recheck();
        checkWorkspaceWallpapers();
    }

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
        assignToFocusedWorkspace(path);
        E4.Wallpapers.apply(path);
    }

    // caelestia4 (upstream #2210): a wallpaper per workspace (Nexus > Wallpaper & style > Workspace wallpapers).
    // Picking a wallpaper (launcher, Nexus, end-4's selector, random) also gives it to the focused workspace, and each
    // screen shows its workspace's wallpaper, else the global one. Colours follow the last pick, not the workspace.
    // Videos stay global (one mpvpaper for every screen): picking one clears the workspace's own wallpaper, so it
    // shows the video like every workspace without one
    readonly property bool workspaceWallsEnabled: GlobalConfig.background.workspaceWallpapers.enabled
    property list<string> missingWorkspaceWallpapers
    property string seenEnd4Current

    // The workspace's own wallpaper on that screen, or "" (none, option off, or the file is gone)
    function workspaceWallFor(screen: ShellScreen): string {
        if (!workspaceWallsEnabled)
            return "";
        const wall = PersistentState.workspaceWallpapers[Hypr.monitorFor(screen)?.activeWorkspace?.name];
        return wall && !missingWorkspaceWallpapers.includes(wall) ? wall : "";
    }

    // What a workspace shows (the overview's tiles), by name
    function forWorkspace(name: string): string {
        const wall = workspaceWallsEnabled ? PersistentState.workspaceWallpapers[name] : "";
        return wall && !missingWorkspaceWallpapers.includes(wall) ? wall : actualCurrent;
    }

    // The preview while one shows, otherwise what the screen shows
    function forScreen(screen: ShellScreen): string {
        return showPreview ? previewPath : actualForScreen(screen);
    }

    // What the screen shows, ignoring any preview
    function actualForScreen(screen: ShellScreen): string {
        return workspaceWallFor(screen) || actualCurrent;
    }

    // The video wallpaper shows through on that screen (its workspace has no still of its own)
    function videoShowingOn(screen: ShellScreen): bool {
        return videoPlaying && !showPreview && !workspaceWallFor(screen);
    }

    function assignToFocusedWorkspace(path: string): void {
        const name = Hypr.focusedMonitor?.activeWorkspace?.name;
        if (!workspaceWallsEnabled || !name || !path)
            return;
        const walls = Object.assign({}, PersistentState.workspaceWallpapers);
        if (/\.(mp4|webm|mkv|avi|mov)$/i.test(path))
            delete walls[name];
        else
            walls[name] = path;
        PersistentState.workspaceWallpapers = walls;
    }

    function checkWorkspaceWallpapers(): void {
        if (!workspaceWallsEnabled)
            return;
        missingCheckProc.exec(["sh", "-c", 'for p; do [ -e "$p" ] || printf "%s\\n" "$p"; done', "sh", ...Object.values(PersistentState.workspaceWallpapers)]);
    }

    onWorkspaceWallsEnabledChanged: checkWorkspaceWallpapers()

    Connections {
        function onWorkspaceWallpapersChanged(): void {
            root.checkWorkspaceWallpapers();
        }

        target: PersistentState
    }

    Connections {
        function onEntriesChanged(): void {
            root.checkWorkspaceWallpapers();
        }

        target: wallpapers
    }

    Process {
        id: missingCheckProc

        stdout: StdioCollector {
            onStreamFinished: root.missingWorkspaceWallpapers = text.split("\n").filter(p => p)
        }
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
    onEnd4CurrentChanged: {
        actualCurrent = end4Current || fallback;
        // caelestia4: a wallpaper set elsewhere (end-4's selector, random, switchwall.sh) goes to the focused
        // workspace too; the first load at startup is not a change
        if (seenEnd4Current && end4Current && end4Current !== seenEnd4Current)
            assignToFocusedWorkspace(end4Current);
        seenEnd4Current = end4Current;
    }

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

        // caelestia4 (upstream #2210): forget one workspace's wallpaper, or all of them
        function clearWorkspace(name: string): void {
            if (!PersistentState.workspaceWallpapers.hasOwnProperty(name))
                return;
            const walls = Object.assign({}, PersistentState.workspaceWallpapers);
            delete walls[name];
            PersistentState.workspaceWallpapers = walls;
        }

        function clearWorkspaces(): void {
            PersistentState.workspaceWallpapers = {};
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
