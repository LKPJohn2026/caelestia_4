import QtQuick
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.adapters
import qs.modules.caelestia.drawers
import qs.modules.caelestia.nexus.common

ConnectedRect {
    id: root

    property alias icon: icon.text
    property alias label: label.text
    property alias status: status.text
    property bool keepPopupAsChild
    readonly property alias popup: popup
    default required property Item content

    Layout.fillWidth: true
    implicitHeight: navLayout.implicitHeight + navLayout.anchors.margins * 2

    // caelestia4: keyboard: Tab focuses the row, Space/Enter open or close the popup, Esc closes it. Opened with the
    // mouse, the row takes focus too (no ring) so Esc works. Keyboard support stops at open/close: focus stays on the
    // row and the popup content (any Item the page passes, e.g. the Apps page's default-app list) gets no keys, so
    // choosing inside the popup needs the mouse
    activeFocusOnTab: true
    Keys.onSpacePressed: popup.open = !popup.open
    Keys.onReturnPressed: popup.open = !popup.open
    Keys.onEnterPressed: popup.open = !popup.open
    Keys.onEscapePressed: event => {
        if (popup.open)
            popup.open = false;
        else
            event.accepted = false;
    }
    onActiveFocusChanged: {
        if (!activeFocus)
            focusRing.pointerFocus = false;
    }

    Accessible.role: Accessible.Button
    Accessible.name: label.text
    Accessible.description: status.text
    Accessible.onPressAction: popup.open = !popup.open

    Connections {
        target: popup

        function onOpenChanged(): void {
            if (popup.open && !root.activeFocus) {
                focusRing.pointerFocus = true;
                root.forceActiveFocus();
            }
        }
    }

    FocusRing {
        id: focusRing

        focusItem: root
    }

    StateLayer {
        id: stateLayer

        manualHoverOverride: popup.hovered && !popup.open
        onClicked: popup.open = true
    }

    RowLayout {
        id: navLayout

        anchors.fill: parent
        anchors.margins: Tokens.padding.medium
        anchors.leftMargin: Tokens.padding.largeIncreased
        anchors.rightMargin: Tokens.padding.largeIncreased
        spacing: Tokens.spacing.medium

        MaterialIcon {
            id: icon

            color: Colours.palette.m3onSurfaceVariant
            fontStyle: Tokens.font.icon.medium
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            StyledText {
                id: label

                Layout.fillWidth: true
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledText {
                id: status

                Layout.fillWidth: true
                visible: text
                color: Colours.palette.m3outline
                font: Tokens.font.label.small
                wrapMode: Text.WordWrap
                animate: true
            }
        }

        Item {
            id: triggerArea

            implicitWidth: popup.implicitWidth
            implicitHeight: popup.implicitHeight

            TransformWatcher {
                id: tWatcher

                a: area.parent
                b: triggerArea
            }

            MouseArea {
                id: area

                parent: {
                    if (root.keepPopupAsChild)
                        return triggerArea;

                    const win = QsWindow.window;
                    const contentWin = win as ContentWindow; // If inside the drawer content window, put it inside the interaction wrapper so hover works
                    return contentWin ? contentWin.interactionWrapper : (win as QsWindow).contentItem;
                }
                anchors.fill: parent
                enabled: popup.open
                hoverEnabled: popup.open
                cursorShape: popup.open ? Qt.ArrowCursor : undefined
                z: popup.animDriver > 0 ? 1 : 0

                onClicked: popup.open = false

                BlobPopup {
                    id: popup

                    x: {
                        tWatcher.transform;
                        return triggerArea.mapToItem(area.parent, 0, 0).x;
                    }
                    y: {
                        tWatcher.transform;
                        return triggerArea.mapToItem(area.parent, 0, 0).y;
                    }
                    padding: Tokens.padding.small
                    content: root.content
                    pressOverride: stateLayer.pressed
                    hoverOverride: stateLayer.containsMouse
                    color: open || hovered || stateLayer.containsMouse ? Colours.palette.m3secondaryContainer : Colours.palette.m3surfaceContainerHighest
                }
            }
        }
    }
}
