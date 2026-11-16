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

// caelestia4: a font family. The row's button shows the family in its own font; it opens a dialog listing the
// installed families (Qt.fontFamilies()) with a search field (case and accents folded) and a sample line in the
// highlighted font; "Reset to default" there resets the setting. Only installed families can be picked; a saved
// family that isn't installed shows a note. `emptyText` names an empty value ("Same as the style"). With `setting`
// a pick writes it (one undo step); without it, bind `value` and handle picked(family). Keyboard: Enter/Space on the
// button opens the dialog; Up/Down in the search field move the highlight, Enter picks it, Esc cancels
SettingRow {
    id: root

    property string value: link.active ? String(link.value ?? "") : ""
    property string emptyText: Tr.tr("Default")
    property string sampleText: Tr.tr("The quick brown fox jumps over the lazy dog. 0123456789")
    readonly property bool installed: !value || _families().indexOf(value) >= 0
    // caelestia4: an icon/symbol font can't draw its own name (it showed as "MATERIAL SYMBOLS…" in icons), so the
    // button writes those names in the normal UI font
    readonly property bool symbolFont: /symbol|icon|emoji|awesome|dingbat|wingding|codicon|webdings/i.test(value)
    readonly property alias dialog: dialog

    signal picked(family: string)

    function pick(family: string): void {
        if (root.link.active)
            root.link.set(family);
        root.picked(family);
    }

    function openDialog(): void {
        if (root.link.blocked)
            root.link.followReason();
        else
            dialog.open();
    }

    // Lowercase, accents off, đ to d (as the settings search folds text)
    function fold(s: string): string {
        return String(s ?? "").normalize("NFD").replace(/[̀-ͯ]/g, "").replace(/[đĐ]/g, "d").toLowerCase();
    }

    // The installed families, read again each time the dialog opens
    property var _fontFamilies: Qt.fontFamilies()

    function _families(): var {
        return root._fontFamilies;
    }

    errorText: value && !installed ? Tr.tr("“%1” isn't installed, so another font shows instead").arg(value) : ""
    focusItem: button

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
        Accessible.name: root.label + ": " + (root.value || root.emptyText)
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
            anchors.leftMargin: Tokens.padding.large
            anchors.rightMargin: Tokens.padding.medium
            spacing: Tokens.spacing.small

            StyledText {
                Layout.fillWidth: true
                text: root.value || root.emptyText
                color: Colours.palette.m3onSecondaryContainer
                font.family: root.value && root.installed && !root.symbolFont ? root.value : Tokens.font.body.small.family
                font.pointSize: Tokens.font.body.small.pointSize
                font.italic: !root.value
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

        function refilter(query: string): void {
            const q = root.fold(query.trim());
            const all = root._families();
            dialog.shown = q ? all.filter(f => root.fold(f).indexOf(q) >= 0) : all;
        }

        function move(delta: int): void {
            const list = dialog.shown;
            if (!list.length)
                return;
            const cur = list.indexOf(dialog.chosen);
            dialog.chosen = list[cur < 0 ? (delta > 0 ? 0 : list.length - 1) : Math.max(0, Math.min(list.length - 1, cur + delta))];
        }

        title: root.label || Tr.tr("Choose a font")
        tall: true
        acceptText: Tr.trCtx("Select", "button")
        acceptEnabled: chosen.length > 0 && shown.indexOf(chosen) >= 0
        extraText: root.link.active ? Tr.tr("Reset to default") : ""

        onOpenedChanged: {
            if (opened) {
                root._fontFamilies = Qt.fontFamilies();
                dialog.chosen = root.installed ? root.value : "";
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
                    hint: Tr.tr("Search fonts")
                    commitOnDestruction: false
                    Accessible.name: Tr.tr("Search fonts")
                    onTextChanged: dialog.refilter(text)
                    Keys.onUpPressed: dialog.move(-1)
                    Keys.onDownPressed: dialog.move(1)
                }

                StyledText {
                    Layout.fillWidth: true
                    // TRANSLATORS: how many installed font families match the search
                    text: Tr.trN("%n font", "%n fonts", dialog.shown.length)
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.label.small
                }

                VerticalFadeListView {
                    id: list

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 0
                    model: dialog.shown
                    currentIndex: dialog.shown.indexOf(dialog.chosen)
                    highlightFollowsCurrentItem: false
                    property bool placed

                    onCurrentIndexChanged: {
                        if (currentIndex >= 0 && placed)
                            positionViewAtIndex(currentIndex, ListView.Contain);
                    }
                    // The saved font in the middle at first, once the list has its size
                    Component.onCompleted: Qt.callLater(() => {
                        if (list.currentIndex >= 0)
                            list.positionViewAtIndex(list.currentIndex, ListView.Center);
                        list.placed = true;
                    })

                    delegate: StyledRect {
                        id: fontItem

                        required property string modelData
                        readonly property bool selected: dialog.chosen === modelData

                        width: ListView.view.width
                        implicitHeight: nameText.implicitHeight + Tokens.padding.small * 2
                        radius: Tokens.rounding.medium
                        color: Qt.alpha(Colours.palette.m3tertiaryContainer, selected ? 1 : 0)

                        StateLayer {
                            radius: fontItem.radius
                            onClicked: dialog.chosen = fontItem.modelData
                            onDoubleClicked: {
                                dialog.chosen = fontItem.modelData;
                                dialog.accept();
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Tokens.padding.medium
                            anchors.rightMargin: Tokens.padding.medium
                            spacing: Tokens.spacing.medium

                            StyledText {
                                id: nameText

                                Layout.fillWidth: true
                                text: fontItem.modelData
                                color: fontItem.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            // A few letters in the font itself (a symbol font's name could not be read in it)
                            StyledText {
                                text: "Aa Ăă 123"
                                color: fontItem.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                                font.family: fontItem.modelData
                                font.pointSize: Tokens.font.body.small.pointSize
                            }
                        }
                    }
                }

                // The sample line, in the highlighted font
                StyledRect {
                    Layout.fillWidth: true
                    implicitHeight: sample.implicitHeight + Tokens.padding.medium * 2
                    radius: Tokens.rounding.medium
                    color: Colours.layer(Colours.palette.m3surfaceContainerHighest, 2)

                    StyledText {
                        id: sample

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.medium
                        text: root.sampleText
                        font.family: dialog.chosen || Tokens.font.body.small.family
                        font.pointSize: Tokens.font.body.large.pointSize
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
