import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

ConnectedRect {
    id: root

    property alias label: label.text
    property string subtext
    property alias menuItems: splitButton.menuItems
    // caelestia4: the row shows `active`, usually bound to the setting. The menu sets its own active item when one is
    // picked, which replaced that binding (an alias), so the row stopped following the setting after the first pick
    property MenuItem active
    // The row keeps the picked item itself instead (no setting behind it): `active` starts as the first item
    property bool holdsSelection
    property alias fallbackText: splitButton.fallbackText
    property alias fallbackIcon: splitButton.fallbackIcon
    property alias menuOnTop: splitButton.menuOnTop

    signal selected(item: MenuItem)

    Component.onCompleted: {
        if (holdsSelection && !active)
            active = menuItems[0] ?? null;
    }

    Layout.fillWidth: true
    implicitHeight: rowLayout.implicitHeight + rowLayout.anchors.margins * 2
    clip: false
    z: splitButton.expanded ? 1 : 0

    RowLayout {
        id: rowLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            StyledText {
                Layout.fillWidth: true
                visible: root.subtext
                text: root.subtext
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                elide: Text.ElideRight
            }
        }

        SplitButton {
            id: splitButton

            type: SplitButton.Tonal
            active: root.active
            stateLayer.onClicked: splitButton.expanded = !splitButton.expanded
            menu.onItemSelected: item => {
                root.selected(item);
                if (root.holdsSelection)
                    root.active = item;
                // After this the menu sets its active item, which replaces the binding above: put it back
                Qt.callLater(() => splitButton.active = Qt.binding(() => root.active));
            }
        }
    }
}
