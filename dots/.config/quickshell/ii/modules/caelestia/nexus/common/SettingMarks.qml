import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: a Nexus row's "modified" marks, left of its control: a 6 px primary dot and a reset button (tooltip
// "Reset to <default>"). Shown while the row's setting differs from its default; the button is dimmed unless the row
// is hovered or focused (`hot`). The button takes Tab focus.
// caelestia4: right-click on the row (or on these marks) opens a small menu: "Reset" (while changed) and "Copy setting
// id" (e.g. c:bar.tray.compact, what search and routes take after "#")
RowLayout {
    id: root

    property RowSetting link
    property bool hot
    // The row's own link (not a second one, as TimeRangeRow's end time): the right-click covers the whole row
    readonly property bool primary: !!link && !!link.row && link.row.link === link

    // Opens the menu at (x, y) of `item`
    function openMenu(item: Item, x: real, y: real): void {
        if (!root.link?.active || !item)
            return;
        _menuComp.createObject(item, {
            x,
            y,
            marks: root
        });
    }

    function copyId(): void {
        Quickshell.clipboardText = root.link.sid;
        NexusActions.toast(Tr.tr("Setting id copied"));
    }

    // On the row, while these are its marks (they may be hidden: the row stays right-clickable)
    TapHandler {
        parent: root.primary ? root.link.row : root
        enabled: !!root.link?.active
        acceptedButtons: Qt.RightButton
        onTapped: (point, button) => root.openMenu(parent, point.position.x, point.position.y)
    }

    readonly property Component _menuComp: Component {
        // A 1 px spot where the click was; the menu opens from it and is destroyed once closed
        Item {
            id: spot

            required property Item marks
            readonly property bool rightHalf: parent ? x > parent.width / 2 : false

            width: 1
            height: 1

            Menu {
                id: menu

                attachTo: spot
                attachSideX: spot.rightHalf ? Menu.Right : Menu.Left
                thisSideX: spot.rightHalf ? Menu.Right : Menu.Left
                active: null
                // caelestia4: set once at open, not bound: "Reset" makes the row unchanged, and a bound list dropped
                // that item while the menu faded out
                Component.onCompleted: {
                    items = spot.marks.link.modified ? [resetItem, copyItem] : [copyItem];
                    expanded = true;
                }
                onExpandedChanged: {
                    if (!expanded)
                        closeTimer.start();
                }

                readonly property MenuItem resetItem: MenuItem {
                    text: spot.marks.link.resetTip
                    icon: "restart_alt"
                    onClicked: spot.marks.link.reset()
                }
                readonly property MenuItem copyItem: MenuItem {
                    text: Tr.tr("Copy setting id")
                    icon: "content_copy"
                    onClicked: spot.marks.copyId()
                }

                // caelestia4: Esc closes it
                Shortcut {
                    sequence: "Escape"
                    enabled: menu.expanded
                    onActivated: menu.expanded = false
                }

                Timer {
                    id: closeTimer

                    interval: 500
                    onTriggered: spot.destroy()
                }
            }

            // caelestia4: the menu's own click catcher takes only the left button. A right press anywhere in the
            // window closes this menu and goes on to what is under it, so a right-click on a row opens that row's
            // menu and only one menu is ever open
            MouseArea {
                parent: menu.parent
                anchors.fill: parent
                enabled: menu.expanded
                acceptedButtons: Qt.RightButton
                onPressed: mouse => {
                    menu.expanded = false;
                    mouse.accepted = false;
                }
            }
        }
    }

    visible: !!link && link.modified
    spacing: Tokens.spacing.small

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: 6
        implicitHeight: 6
        radius: 3
        color: Colours.palette.m3primary
    }

    IconButton {
        id: resetBtn

        Layout.alignment: Qt.AlignVCenter
        icon: "restart_alt"
        type: IconButton.Text
        font: Tokens.font.icon.small
        opacity: hovered || activeFocus || root.hot ? 1 : 0.5
        // caelestia4: Tab reaches it (Enter or Space resets); it hides after a reset, so focus goes back to the row
        // first: the row itself when it holds the focus (ToggleRow, SelectRow: just before this button in the tab
        // chain), else the row's control (just after it: the spin box, slider, field)
        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.link?.resetTip ?? ""
        Accessible.onPressAction: resetBtn.resetNow()
        ToolTip.visible: hovered || ring.show
        ToolTip.delay: 500
        ToolTip.text: root.link?.resetTip ?? ""
        onClicked: root.link.reset()

        function resetNow(): void {
            if (resetBtn.activeFocus) {
                const prev = resetBtn.nextItemInFocusChain(false);
                let p = resetBtn.parent;
                while (p && p !== prev)
                    p = p.parent;
                (p ? prev : resetBtn.nextItemInFocusChain(true))?.forceActiveFocus(Qt.TabFocusReason);
            }
            root.link.reset();
        }

        Keys.onReturnPressed: resetNow()
        Keys.onEnterPressed: resetNow()
        Keys.onSpacePressed: resetNow()

        FocusRing {
            id: ring

            focusItem: resetBtn
        }

        Behavior on opacity {
            Anim {}
        }
    }
}
