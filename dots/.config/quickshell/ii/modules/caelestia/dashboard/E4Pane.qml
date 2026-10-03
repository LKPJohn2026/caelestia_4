// caelestia4: a dashboard pane hosting an end-4 widget (Todo, Timer) at a fixed, Caelestia-proportioned size.
// end-4's sidebar widgets fill their parent, so the pane provides the implicit size the dashboard layout needs.
import QtQuick
import Caelestia.Config

Item {
    id: root

    default property alias content: holder.data

    implicitWidth: Tokens.sizes.dashboard?.mediaWidth ? Tokens.sizes.dashboard.mediaWidth * 1.6 : 520
    implicitHeight: 420

    Item {
        id: holder

        anchors.fill: parent
        anchors.margins: Tokens.padding.normal ?? 10
    }
}
