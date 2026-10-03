// caelestia4: a dashboard pane hosting an end-4 widget (Todo, Timer) at a fixed size.
// end-4's sidebar widgets fill their parent and have no implicit size of their own, so the pane must
// provide a stable one. The Loader for these panes is kept active (Content.qml, keepLoaded) so the size
// never flips between 0 and full width.
import QtQuick

Item {
    id: root

    default property alias content: holder.data

    implicitWidth: 840 // same as Caelestia's Weather tab, so the dashboard width stays steady
    implicitHeight: 480

    Item {
        id: holder

        anchors.fill: parent
        anchors.margins: 12
    }
}
