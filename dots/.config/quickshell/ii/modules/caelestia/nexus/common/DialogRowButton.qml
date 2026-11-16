pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Blobs
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

Item {
    id: root

    required property Item rootParent
    required property string icon
    required property string label
    required property string header
    required property Component content
    required property string acceptLabel
    property bool acceptAllowed: true
    property bool separateContent
    property int horizontalContentMargin

    property real openWidth: Math.min(rootParent.width * 0.8, Tokens.sizes.nexus.maxDialogWidth)
    property real openHeight: Math.min(rootParent.height * 0.8, Tokens.sizes.nexus.maxDialogHeight)
    property bool open

    // caelestia4: keyboard: Enter/Space on the row open the dialog, which then takes focus: Esc cancels, Enter accepts
    // (when allowed), Up/Down emit keyNavigated (DialogSelectButton moves its selection). Focus goes back to the row
    // on close if it had it
    property bool returnFocus
    // caelestia4: true when the row was clicked with the mouse, so the focus that comes back on close shows no ring
    property bool openedByPointer

    // caelestia4: while open, Tab/Backtab stay in the dialog (its buttons take no focus, so they do nothing) and the
    // hidden row leaves the Tab chain; Space emits keyToggled (DialogMultiSelectButton toggles the item under its cursor)

    signal accepted
    signal cancelled
    signal keyNavigated(delta: int)
    signal keyToggled

    function accept(): void {
        if (!root.acceptAllowed)
            return;
        root.accepted();
        root.open = false;
    }

    function cancel(): void {
        root.cancelled();
        root.open = false;
    }

    Connections {
        target: root

        function onOpenChanged(): void {
            if (root.open) {
                root.returnFocus = openButton.activeFocus;
                if (dialogContent.status === Loader.Ready)
                    dialogContent.forceActiveFocus();
            } else if (root.returnFocus) {
                if (root.openedByPointer)
                    openButton.pointerFocus = true;
                openButton.forceActiveFocus();
            }
        }
    }

    function reparentWrapper(): void {
        const newParent = open ? rootParent : root;
        const pos = dialogWrapper.mapToItem(newParent, 0, 0);
        dialogWrapper.parent = newParent;
        dialogWrapper.x = pos.x;
        dialogWrapper.y = pos.y;
    }

    Layout.fillWidth: true
    implicitHeight: openButton.implicitHeight
    z: open || dialogTransition.running ? 2 : 0

    BlobGroup {
        id: blobGroup

        color: root.open ? Colours.palette.m3surfaceContainerHighest : Colours.tPalette.m3surfaceContainer

        Behavior on color {
            CAnim {}
        }
    }

    MouseArea {
        id: backdrop

        anchors.fill: parent
        parent: root.open ? root.rootParent : root
        enabled: false
        hoverEnabled: enabled
        onClicked: root.open = false
    }

    Item {
        id: dialogWrapper

        z: 1
        width: root.width
        height: openButton.implicitHeight

        states: State {
            name: "open"
            when: root.open

            PropertyChanges {
                backdrop.enabled: true
                elevation.opacity: 1
                openButton.opacity: 0
                openButton.activeFocusOnTab: false
                dialogContent.opacity: 1
                dialogBg.radius: root.Tokens.rounding.extraLargeIncreased
                dialogBg.bottomLeftRadius: root.Tokens.rounding.extraLargeIncreased
                dialogBg.bottomRightRadius: root.Tokens.rounding.extraLargeIncreased
                dialogWrapper.x: (root.rootParent.width - root.openWidth) / 2
                dialogWrapper.y: (root.rootParent.height - root.openHeight) / 2
                dialogWrapper.width: root.openWidth
                dialogWrapper.height: root.openHeight
            }
        }

        transitions: Transition {
            id: dialogTransition

            SequentialAnimation {
                ScriptAction {
                    script: root.reparentWrapper()
                }
                Anim {
                    properties: "x,y"
                }
            }
            PropertyAction {
                property: "enabled"
            }
            Anim {
                properties: "opacity,radius,bottomLeftRadius,bottomRightRadius"
                type: Anim.DefaultEffects
            }
            Anim {
                properties: "width,height"
            }
        }

        Elevation {
            id: elevation

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent
            radius: dialogBg.radius
            bottomLeftRadius: dialogBg.bottomLeftRadius
            bottomRightRadius: dialogBg.bottomRightRadius
            level: 4
            opacity: 0
        }

        BlobRect {
            id: dialogBg

            anchors.fill: parent

            deformScale: 0.00005
            group: blobGroup
            opacity: blobGroup.color.a

            radius: Tokens.rounding.extraSmall
            bottomLeftRadius: Tokens.rounding.extraLarge
            bottomRightRadius: Tokens.rounding.extraLarge
        }

        RowButton {
            id: openButton

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.min(implicitHeight, parent.height) // Clamp to parent height due to overshoot anim
            color: "transparent"

            last: true
            icon: root.icon
            text: root.label
            onClicked: e => {
                root.openedByPointer = !!e;
                root.open = true;
            }
        }

        Loader {
            id: dialogContent

            transform: Matrix4x4 {
                matrix: dialogBg.deformMatrix
            }

            anchors.fill: parent

            opacity: 0
            active: opacity > 0
            asynchronous: true

            onLoaded: {
                if (root.open)
                    dialogContent.forceActiveFocus();
            }

            sourceComponent: MouseArea {
                focus: true
                onWheel: event => event.accepted = true
                Keys.onEscapePressed: root.cancel()
                Keys.onReturnPressed: root.accept()
                Keys.onEnterPressed: root.accept()
                Keys.onUpPressed: root.keyNavigated(-1)
                Keys.onDownPressed: root.keyNavigated(1)
                Keys.onSpacePressed: root.keyToggled()
                Keys.onTabPressed: event => event.accepted = true
                Keys.onBacktabPressed: event => event.accepted = true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Tokens.padding.extraLarge
                    anchors.bottomMargin: Tokens.padding.largeIncreased
                    spacing: 0

                    StyledText {
                        Layout.fillWidth: true
                        text: root.header
                        wrapMode: Text.WordWrap
                        font: Tokens.font.title.builders.large.weight(Font.Normal).build()
                    }

                    Loader {
                        Layout.topMargin: Tokens.spacing.medium
                        Layout.fillWidth: true
                        active: root.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.leftMargin: root.horizontalContentMargin
                        Layout.rightMargin: root.horizontalContentMargin
                        sourceComponent: root.content
                    }

                    Loader {
                        Layout.bottomMargin: Tokens.spacing.medium
                        Layout.fillWidth: true
                        active: root.separateContent
                        sourceComponent: StyledRect {
                            implicitHeight: 1
                            color: Colours.palette.m3outline
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Tokens.spacing.extraSmall

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding.largeIncreased
                            verticalPadding: Tokens.padding.medium
                            text: Tr.trCtx("Cancel", "button")
                            onClicked: root.cancel()
                        }

                        TextButton {
                            type: TextButton.Text
                            isRound: true
                            horizontalPadding: Tokens.padding.largeIncreased
                            verticalPadding: Tokens.padding.medium
                            disabled: !root.acceptAllowed
                            text: root.acceptLabel
                            onClicked: root.accept()
                        }
                    }
                }
            }
        }
    }
}
