// Phase 1 smoke test: the user-local Caelestia plugin loads under our pinned Quickshell.
// Run: QT_QPA_PLATFORM=offscreen QML_IMPORT_PATH=$HOME/.local/lib/qt6/qml qs -p tools/tests/plugin-smoke
import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import Caelestia.Blobs
import Caelestia.Components

ShellRoot {
    Item {
        id: holder
        BlobRect { id: blob }
    }

    Component.onCompleted: {
        console.log("SMOKE OK: Caelestia, Caelestia.Config, Caelestia.Blobs, Caelestia.Components imported; BlobRect =", blob);
        Qt.quit();
    }
}
