pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: a Nexus dialog with content, as ConfirmDialog is one without: open() covers the page area (or
// `rootParent`) with a scrim and a card with `title`, the children (laid out in a ColumnLayout), and Cancel /
// `acceptText` buttons, plus an optional `extraText` button on the left ("Reset to default"). Esc or a click outside
// cancels (rejected), Enter accepts while `enterAccepts` and `acceptEnabled`. Tab and Backtab go round the card's
// controls only. `tall` gives the card most of the height (lists). `initialFocus` takes the focus when it opens
Item {
    id: root

    property string title
    property string acceptText: Tr.trCtx("OK", "button")
    property string cancelText: Tr.trCtx("Cancel", "button")
    property string extraText
    property bool acceptEnabled: true
    property bool enterAccepts: true
    property bool tall
    property real preferredWidth: Tokens.sizes.nexus.maxDialogWidth * 1.4
    property Item initialFocus
    property Item rootParent
    readonly property bool opened: _open

    default property alias content: body.data
    readonly property alias body: body

    signal accepted
    signal rejected
    signal extraClicked

    function open(): void {
        if (root._open)
            return;
        root._home = root.parent;
        root._returnFocus = root.Window.activeFocusItem;
        root.parent = root.rootParent ?? root._overlayParent();
        root._open = true;
        Qt.callLater(() => (root.initialFocus ?? card).forceActiveFocus());
    }

    function close(): void {
        if (!root._open)
            return;
        root._open = false;
        root._returnFocus?.forceActiveFocus();
        root._returnFocus = null;
    }

    function accept(): void {
        if (!root._open || !root.acceptEnabled)
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

    function _inCard(item: Item): bool {
        let p = item;
        while (p && p !== card)
            p = p.parent;
        return !!p;
    }

    // Tab past the last control goes to the first, Backtab past the first to the last
    function _cycle(forward: bool): void {
        const from = root.Window.activeFocusItem ?? card;
        let next = from.nextItemInFocusChain(forward);
        if (!next || !root._inCard(next) || next === card) {
            if (forward) {
                next = card.nextItemInFocusChain(true);
            } else {
                // The last one in the card: walk forward from the first until the chain leaves the card
                let item = card.nextItemInFocusChain(true);
                let last = item;
                for (let i = 0; i < 200 && item && root._inCard(item) && item !== card; i++) {
                    last = item;
                    item = item.nextItemInFocusChain(true);
                    if (item === card.nextItemInFocusChain(true))
                        break;
                }
                next = last;
            }
        }
        if (next && root._inCard(next))
            next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
    }

    // Back home once faded out, so a hidden dialog never sits in the overlay
    onVisibleChanged: {
        if (!visible && !root._open && root._home && root.parent !== root._home)
            root.parent = root._home;
    }

    x: 0
    y: 0
    z: 100
    width: _open || opacity > 0 ? (parent?.width ?? 0) : 0
    height: _open || opacity > 0 ? (parent?.height ?? 0) : 0
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

        readonly property real maxHeight: Math.max(0, root.height - Tokens.padding.large * 2)

        anchors.centerIn: parent
        width: Math.min(root.preferredWidth, Math.max(0, root.width - Tokens.padding.large * 2))
        height: root.tall ? Math.min(maxHeight, Tokens.sizes.nexus.maxDialogHeight * 1.3) : Math.min(maxHeight, column.implicitHeight + Tokens.padding.extraLarge + Tokens.padding.largeIncreased)
        radius: Tokens.rounding.extraLargeIncreased
        color: Colours.palette.m3surfaceContainerHigh
        scale: root._open ? 1 : 0.95
        activeFocusOnTab: false

        Accessible.role: Accessible.Dialog
        Accessible.name: root.title

        Keys.onEscapePressed: root.reject()
        Keys.onReturnPressed: event => {
            if (root.enterAccepts)
                root.accept();
            else
                event.accepted = false;
        }
        Keys.onEnterPressed: event => {
            if (root.enterAccepts)
                root.accept();
            else
                event.accepted = false;
        }
        Keys.onTabPressed: root._cycle(true)
        Keys.onBacktabPressed: root._cycle(false)

        Behavior on scale {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        // Clicks on the card don't reach the scrim
        MouseArea {
            anchors.fill: parent
            onWheel: event => event.accepted = true
        }

        ColumnLayout {
            id: column

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            anchors.bottomMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: root.title
                wrapMode: Text.WordWrap
                font: Tokens.font.title.builders.large.weight(Font.Normal).build()
            }

            ColumnLayout {
                id: body

                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Tokens.spacing.small
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    visible: root.extraText.length > 0
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.largeIncreased
                    verticalPadding: Tokens.padding.medium
                    text: root.extraText
                    onClicked: root.extraClicked()
                }

                Item {
                    Layout.fillWidth: true
                }

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
                    disabled: !root.acceptEnabled
                    text: root.acceptText
                    onClicked: root.accept()
                }
            }
        }
    }
}
