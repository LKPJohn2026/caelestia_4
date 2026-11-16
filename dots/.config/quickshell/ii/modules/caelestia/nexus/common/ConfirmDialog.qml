pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: a Nexus confirmation: open() covers the page area (or `rootParent`) with a scrim and a card with `title`,
// `text`, Cancel and `confirmText`. Esc or a click outside cancels (rejected), Enter confirms (accepted); `destructive`
// paints the confirm button in the error colour. Declare it anywhere in a page: it moves itself over the page area
// while open, and gives focus back to what had it when it closes
Item {
    id: root

    property string title
    property string text
    property string confirmText: Tr.trCtx("OK", "button")
    property string cancelText: Tr.trCtx("Cancel", "button")
    property bool destructive
    // What the dialog covers; default: Nexus's page area (Pages.qml's "PageContainer"), else the top item
    property Item rootParent
    readonly property bool opened: _open

    signal accepted
    signal rejected

    function open(): void {
        if (root._open)
            return;
        root._home = root.parent;
        root._returnFocus = root.Window.activeFocusItem;
        root.parent = root.rootParent ?? root._overlayParent();
        root._open = true;
        Qt.callLater(() => card.forceActiveFocus());
    }

    function close(): void {
        if (!root._open)
            return;
        root._open = false;
        root._returnFocus?.forceActiveFocus();
        root._returnFocus = null;
    }

    function accept(): void {
        if (!root._open)
            return;
        root.close();
        root.accepted();
    }

    function reject(): void {
        if (!root._open)
            return;
        root.close();
        root.rejected();
    }

    property bool _open
    property Item _home
    property Item _returnFocus

    function _overlayParent(): Item {
        let p = root.parent;
        let top = p;
        while (p) {
            if (p.objectName === "PageContainer")
                return p;
            top = p;
            p = p.parent;
        }
        return top;
    }

    // Back home once faded out, so a hidden dialog never sits in the overlay
    onVisibleChanged: {
        if (!visible && !root._open && root._home && root.parent !== root._home)
            root.parent = root._home;
    }

    x: 0
    y: 0
    z: 100
    width: parent?.width ?? 0
    height: parent?.height ?? 0
    visible: opacity > 0
    opacity: _open ? 1 : 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.reject()
        onWheel: event => event.accepted = true

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.palette.m3shadow, 0.4)
        }
    }

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 3
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        width: Math.min(Tokens.sizes.nexus.maxDialogWidth, root.width - Tokens.padding.large * 2)
        implicitHeight: content.implicitHeight + Tokens.padding.extraLarge + Tokens.padding.largeIncreased
        radius: Tokens.rounding.extraLargeIncreased
        color: Colours.palette.m3surfaceContainerHigh
        scale: root._open ? 1 : 0.95

        Accessible.role: Accessible.Dialog
        Accessible.name: root.title
        Accessible.description: root.text

        Keys.onEscapePressed: root.reject()
        Keys.onReturnPressed: root.accept()
        Keys.onEnterPressed: root.accept()
        Keys.onTabPressed: event => event.accepted = true
        Keys.onBacktabPressed: event => event.accepted = true

        Behavior on scale {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        // Clicks on the card don't reach the scrim
        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: content

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: Tokens.padding.extraLarge
            anchors.bottomMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: root.title
                wrapMode: Text.WordWrap
                font: Tokens.font.title.builders.large.weight(Font.Normal).build()
            }

            StyledText {
                Layout.fillWidth: true
                visible: text.length > 0
                text: root.text
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.largeIncreased
                    verticalPadding: Tokens.padding.medium
                    text: root.cancelText
                    onClicked: root.reject()
                }

                TextButton {
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.largeIncreased
                    verticalPadding: Tokens.padding.medium
                    text: root.confirmText
                    inactiveOnColour: root.destructive ? Colours.palette.m3error : Colours.palette.m3primary
                    onClicked: root.accept()
                }
            }
        }
    }
}
