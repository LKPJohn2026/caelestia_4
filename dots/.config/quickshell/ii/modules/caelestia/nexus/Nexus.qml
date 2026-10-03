// caelestia4 STAND-IN for Caelestia's docked `Nexus` settings popout (bar/popouts/Wrapper.qml, detached mode "any").
// Opens end-4's settings app and immediately asks the popout to close. Keeps the properties the wrapper sets.
import QtQuick
import Quickshell

Item {
    id: root

    signal close

    property QtObject nState: QtObject {
        property ShellScreen screen
        property bool animatingContainer
        property int currentPageIdx: -1
    }

    implicitWidth: 0
    implicitHeight: 0

    Component.onCompleted: {
        WindowFactory.create();
        Qt.callLater(() => root.close());
    }
}
