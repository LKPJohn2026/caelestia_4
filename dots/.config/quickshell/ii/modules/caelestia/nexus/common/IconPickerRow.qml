pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import "IconPickerNames.js" as IconNames

// caelestia4: a Material Symbols icon name. The row's button shows the icon and its name; it opens a dialog with a
// searchable grid of common icons (IconPickerNames.js). The search field also takes any other symbol name: it shows
// as the first tile, and is only accepted when the font knows it. The big preview shows the highlighted icon. With
// `setting` a pick writes it (one undo step); without it, bind `value` and handle picked(name). Keyboard: Enter/Space
// on the button opens the dialog; arrows in the search field move the highlight, Enter picks it, Esc cancels
SettingRow {
    id: root

    property string value: link.active ? String(link.value ?? "") : ""
    property string emptyText: Tr.tr("None")
    readonly property alias dialog: dialog

    signal picked(name: string)

    function pick(name: string): void {
        if (root.link.active)
            root.link.set(name);
        root.picked(name);
    }

    function openDialog(): void {
        if (root.link.blocked)
            root.link.followReason();
        else
            dialog.open();
    }

    // caelestia4: a symbol name draws one glyph as wide as a known one ("home"); an unknown name draws its letters,
    // one glyph each. A single letter is as wide as a glyph too, and no symbol name is one character, so need two
    function fitsOneGlyph(name: string, width: real): bool {
        return name.length >= 2 && /^[a-z0-9_]+$/.test(name) && width > 0 && Math.abs(width - refProbe.implicitWidth) <= refProbe.implicitWidth * 0.15;
    }

    function isSymbol(name: string): bool {
        if (!/^[a-z0-9_]+$/.test(name))
            return false;
        probe.text = name;
        return root.fitsOneGlyph(name, probe.implicitWidth);
    }

    // caelestia4: names show with spaces, like the grid tiles
    function shownName(name: string): string {
        return name.replace(/_/g, " ");
    }

    readonly property bool valueKnown: !value || fitsOneGlyph(value, valueProbe.implicitWidth)

    errorText: valueKnown ? "" : Tr.tr("This name isn't an icon the font knows, so the button shows its letters")
    focusItem: button

    // Not shown: measure names (the saved one, and others for isSymbol())
    MaterialIcon {
        id: valueProbe

        visible: false
        text: root.value
        fontStyle: Tokens.font.icon.small
    }

    MaterialIcon {
        id: refProbe

        visible: false
        text: "home"
        fontStyle: Tokens.font.icon.small
    }

    MaterialIcon {
        id: probe

        visible: false
        fontStyle: Tokens.font.icon.small
    }

    StyledRect {
        id: button

        Layout.fillWidth: root.controlBelow
        Layout.maximumWidth: root.controlBelow ? -1 : Math.max(160, root.width * 0.45)
        implicitWidth: buttonRow.implicitWidth + Tokens.padding.large * 2
        implicitHeight: buttonRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.palette.m3secondaryContainer

        activeFocusOnTab: true
        Accessible.role: Accessible.Button
        Accessible.name: root.label + ": " + (root.value ? root.shownName(root.value) : root.emptyText)
        Accessible.description: root.accessibleDescription
        Accessible.onPressAction: root.openDialog()
        Keys.onSpacePressed: root.openDialog()
        Keys.onReturnPressed: root.openDialog()
        Keys.onEnterPressed: root.openDialog()
        onActiveFocusChanged: {
            if (!activeFocus)
                root.focusRing.pointerFocus = false;
        }

        StateLayer {
            radius: button.radius
            color: Colours.palette.m3onSecondaryContainer
            onPressed: {
                if (button.activeFocus)
                    root.focusRing.pointerFocus = true;
            }
            onClicked: root.openDialog()
        }

        RowLayout {
            id: buttonRow

            anchors.fill: parent
            anchors.leftMargin: Tokens.padding.medium
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            MaterialIcon {
                visible: !!root.value && root.valueKnown
                text: root.value
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.small
            }

            StyledText {
                Layout.fillWidth: true
                text: root.value ? root.shownName(root.value) : root.emptyText
                color: Colours.palette.m3onSecondaryContainer
                font: Tokens.font.body.small
                elide: Text.ElideRight
            }

            MaterialIcon {
                text: "expand_more"
                color: Colours.palette.m3onSecondaryContainer
                fontStyle: Tokens.font.icon.small
            }
        }
    }

    NexusDialog {
        id: dialog

        property string chosen
        property var shown: []
        property int columns: 1

        // The common names matching the query; a valid name typed in full that isn't among them comes first
        function refilter(query: string): void {
            const q = query.trim().toLowerCase().replace(/[\s-]+/g, "_");
            const all = IconNames.names;
            let list = q ? all.filter(n => n.indexOf(q) >= 0) : all.slice();
            if (q && all.indexOf(q) < 0 && root.isSymbol(q))
                list.unshift(q);
            // The saved name shows too when it isn't a common one
            if (!q && root.value && all.indexOf(root.value) < 0 && root.valueKnown)
                list.unshift(root.value);
            dialog.shown = list;
            if (list.indexOf(dialog.chosen) < 0 && q)
                dialog.chosen = list.length ? list[0] : "";
        }

        function move(delta: int): void {
            const list = dialog.shown;
            if (!list.length)
                return;
            const cur = list.indexOf(dialog.chosen);
            dialog.chosen = list[cur < 0 ? 0 : Math.max(0, Math.min(list.length - 1, cur + delta))];
        }

        title: root.label || Tr.tr("Choose an icon")
        tall: true
        acceptText: Tr.trCtx("Select", "button")
        acceptEnabled: chosen.length > 0 && shown.indexOf(chosen) >= 0
        extraText: root.link.active ? Tr.tr("Reset to default") : ""

        onOpenedChanged: {
            if (opened) {
                dialog.chosen = root.value && root.valueKnown ? root.value : "";
                dialog.refilter("");
            }
        }
        onAccepted: {
            if (dialog.chosen && dialog.chosen !== root.value)
                root.pick(dialog.chosen);
        }
        onExtraClicked: {
            dialog.reject();
            root.link.reset();
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: dialog.opened || dialog.visible
            onLoaded: dialog.initialFocus = item.searchField

            sourceComponent: ColumnLayout {
                readonly property alias searchField: search

                spacing: Tokens.spacing.small

                RowTextField {
                    id: search

                    Layout.fillWidth: true
                    leadingIcon: "search"
                    hint: Tr.tr("Search, or type any icon name")
                    commitOnDestruction: false
                    Accessible.name: Tr.tr("Search icons")
                    onTextChanged: dialog.refilter(text)
                    Keys.onLeftPressed: event => {
                        if (search.text.length > 0 && search.cursorPosition > 0) {
                            event.accepted = false;
                            return;
                        }
                        dialog.move(-1);
                    }
                    Keys.onRightPressed: event => {
                        if (search.text.length > 0 && search.cursorPosition < search.text.length) {
                            event.accepted = false;
                            return;
                        }
                        dialog.move(1);
                    }
                    Keys.onUpPressed: dialog.move(-dialog.columns)
                    Keys.onDownPressed: dialog.move(dialog.columns)
                }

                StyledText {
                    Layout.fillWidth: true
                    // TRANSLATORS: how many icons match the search
                    text: dialog.shown.length ? Tr.trN("%n icon", "%n icons", dialog.shown.length) : Tr.tr("No icon with that name")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                GridView {
                    id: grid

                    readonly property real minCell: 100

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: width / Math.max(1, Math.floor(width / minCell))
                    cellHeight: 84
                    model: dialog.shown
                    currentIndex: dialog.shown.indexOf(dialog.chosen)
                    highlightFollowsCurrentItem: false
                    boundsBehavior: Flickable.StopAtBounds
                    property bool placed

                    onWidthChanged: dialog.columns = Math.max(1, Math.floor(width / minCell))
                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && placed)
                            positionViewAtIndex(currentIndex, GridView.Contain);
                    }
                    Component.onCompleted: Qt.callLater(() => {
                        if (grid.currentIndex >= 0)
                            grid.positionViewAtIndex(grid.currentIndex, GridView.Center);
                        grid.placed = true;
                    })

                    delegate: Item {
                        id: tile

                        required property string modelData
                        readonly property bool selected: dialog.chosen === modelData

                        width: grid.cellWidth
                        height: grid.cellHeight

                        StyledRect {
                            anchors.fill: parent
                            anchors.margins: 2
                            radius: Tokens.rounding.medium
                            color: Qt.alpha(Colours.palette.m3tertiaryContainer, tile.selected ? 1 : 0)

                            StateLayer {
                                radius: parent.radius
                                onClicked: dialog.chosen = tile.modelData
                                onDoubleClicked: {
                                    dialog.chosen = tile.modelData;
                                    dialog.accept();
                                }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Tokens.padding.small
                                spacing: 2

                                MaterialIcon {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: tile.modelData
                                    color: tile.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                    fontStyle: Tokens.font.icon.medium
                                }

                                StyledText {
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    text: root.shownName(tile.modelData)
                                    color: tile.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                    font: Tokens.font.label.small
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                // The highlighted icon, large
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: previewRow.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    RowLayout {
                        id: previewRow

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        MaterialIcon {
                            visible: !!dialog.chosen
                            text: dialog.chosen
                            color: Colours.palette.m3onSurface
                            fontStyle: Tokens.font.icon.large
                        }

                        StyledText {
                            Layout.fillWidth: true
                            text: dialog.chosen ? root.shownName(dialog.chosen) : Tr.tr("Pick an icon")
                            color: dialog.chosen ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
                            font: Tokens.font.body.medium
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
