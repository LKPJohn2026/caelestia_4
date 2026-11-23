// Phase 1 smoke test: the user-local Caelestia plugin loads under our pinned Quickshell.
// Run: tools/ci-qml.sh (or by hand: QT_QPA_PLATFORM=offscreen QML_IMPORT_PATH=$HOME/.local/lib/qt6/qml qs -p tools/tests/plugin-smoke)
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

    Component.onCompleted: console.log("SMOKE OK: Caelestia, Caelestia.Config, Caelestia.Blobs, Caelestia.Components imported; BlobRect =", blob)

    // caelestia4: Quickshell connects Qt.quit() only once the root is built (EngineGeneration::onReload, after every
    // Component.onCompleted): called from there it has no receivers and the run lasts until its timeout. A timer fires
    // after that, so the test ends by itself
    Timer {
        interval: 0
        running: true
        onTriggered: Qt.quit()
    }
}
