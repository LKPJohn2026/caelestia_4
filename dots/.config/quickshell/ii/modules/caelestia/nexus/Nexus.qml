// caelestia4 STAND-IN for Caelestia's docked `Nexus` settings popout (bar/popouts/Wrapper.qml, detached mode "any").
// Opens end-4's settings app and immediately asks the popout to close.
// `nState` must be a *declared component type*: the wrapper uses grouped assignments
// (`nState.currentPageIdx: …`), which QML checks against the property's static type. A plain
// `property QtObject` broke the whole family at load (Phase 3 test 1).
import QtQuick
import Quickshell

Item {
    id: root

    component NexusState: QtObject {
        property ShellScreen screen
        property bool animatingContainer
        property int currentPageIdx: -1
    }

    signal close

    property NexusState nState: NexusState {}

    implicitWidth: 0
    implicitHeight: 0

    Component.onCompleted: {
        WindowFactory.create();
        Qt.callLater(() => root.close());
    }
}
