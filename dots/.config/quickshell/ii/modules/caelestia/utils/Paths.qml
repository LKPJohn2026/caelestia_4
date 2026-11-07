pragma Singleton

import QtCore
import QtQuick
import Quickshell
import qs.modules.common as E4C
import Caelestia
import Caelestia.Config

Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    // caelestia4: these folders have other names in other languages, and a session's environment rarely has the variables
    readonly property string pictures: Quickshell.env("XDG_PICTURES_DIR") || toLocalFile(StandardPaths.standardLocations(StandardPaths.PicturesLocation)[0])
    readonly property string videos: {
        const dir = (Quickshell.env("XDG_VIDEOS_DIR") || toLocalFile(StandardPaths.standardLocations(StandardPaths.MoviesLocation)[0])).replace(/\/$/, "");
        return dir === home ? `${home}/Videos` : dir; // as record.sh: the home folder means none is set
    }

    readonly property string data: `${Quickshell.env("XDG_DATA_HOME") || `${home}/.local/share`}/caelestia`
    readonly property string state: `${Quickshell.env("XDG_STATE_HOME") || `${home}/.local/state`}/caelestia`
    readonly property string cache: `${Quickshell.env("XDG_CACHE_HOME") || `${home}/.cache`}/caelestia`
    readonly property string config: `${Quickshell.env("XDG_CONFIG_HOME") || `${home}/.config`}/caelestia`

    readonly property string imagecache: `${cache}/imagecache`
    readonly property string notifimagecache: `${imagecache}/notifs`
    readonly property string wallsdir: Quickshell.env("CAELESTIA_WALLPAPERS_DIR") || absolutePath(GlobalConfig.paths.wallpaperDir)
    readonly property string recsdir: Quickshell.env("CAELESTIA_RECORDINGS_DIR") || (E4C.Config.options.screenRecord.savePath || videos).replace(/^~(?=\/|$)/, home) // caelestia4: where record.sh writes
    readonly property string libdir: Quickshell.env("CAELESTIA_LIB_DIR") || "/usr/lib/caelestia"

    function toLocalFile(path: url): string {
        path = Qt.resolvedUrl(path);
        return path.toString() ? CUtils.toLocalFile(path) : "";
    }

    function absolutePath(path: string): string {
        // caelestia4: Caelestia's config defaults use root:/assets/… (shell root). The shell root is now
        // end-4's ii/, and Caelestia's assets live in modules/caelestia/assets/.
        path = path.replace(/^root:\/assets\//, "root:/modules/caelestia/assets/");
        return toLocalFile(path.replace(/~|(\$({?)HOME(}?))+/, home));
    }

    function shortenHome(path: string): string {
        return path.replace(home, "~");
    }
}
