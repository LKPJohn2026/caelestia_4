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

// caelestia4: DialogSelectButton choosing several: `selected` is what's chosen now (keys); the dialog edits a copy,
// `chosen`, and accepted() hands it over (at least one). For the random wallpaper transition's pool (WallpaperAndStyle).
DialogRowButton {
    id: root

    required property var model
    property list<string> selected
    property list<string> chosen
    // caelestia4: keyboard cursor in the open dialog: Up/Down move it (outlined), Space toggles the item under it
    property int cursor: -1

    function keyFor(item: var): string {
        return item.id;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    function toggle(key: string): void {
        root.chosen = root.chosen.includes(key) ? root.chosen.filter(k => k !== key) : [...root.chosen, key];
    }

    onOpenChanged: {
        if (open) {
            chosen = [...selected];
            cursor = -1;
        }
    }

    onKeyNavigated: delta => {
        const n = (root.model ?? []).length;
        if (!n)
            return;
        root.cursor = root.cursor < 0 ? (delta > 0 ? 0 : n - 1) : Math.max(0, Math.min(n - 1, root.cursor + delta));
    }

    onKeyToggled: {
        const n = (root.model ?? []).length;
        if (!n)
            return;
        if (root.cursor < 0)
            root.cursor = 0;
        else
            root.toggle(root.keyFor(root.model[root.cursor]));
    }

    acceptAllowed: chosen.length > 0
    separateContent: true
    horizontalContentMargin: -Tokens.padding.small

    content: Component {
        ColumnLayout {
            spacing: Tokens.spacing.small

            RowLayout {
                Layout.leftMargin: Tokens.padding.large
                Layout.rightMargin: Tokens.padding.large
                Layout.topMargin: Tokens.padding.large
                spacing: Tokens.spacing.small

                IconTextButton {
                    icon: "select_all"
                    text: Tr.tr("All")
                    type: IconTextButton.Tonal
                    onClicked: root.chosen = root.model.map(m => root.keyFor(m))
                }

                IconTextButton {
                    icon: "deselect"
                    text: Tr.tr("None")
                    type: IconTextButton.Tonal
                    onClicked: root.chosen = []
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    // TRANSLATORS: %1 chosen out of %2
                    text: Tr.tr("%1 of %2").arg(root.chosen.length).arg(root.model.length)
                    color: Colours.palette.m3onSurfaceVariant
                }
            }

            VerticalFadeListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
                topMargin: Tokens.padding.small
                bottomMargin: Tokens.padding.large

                model: root.model
                currentIndex: root.cursor
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: StyledRect {
                    id: item

                    required property var modelData
                    required property int index
                    readonly property bool selected: root.chosen.includes(root.keyFor(modelData))

                    anchors.left: ListView.view.contentItem.left
                    anchors.right: ListView.view.contentItem.right
                    anchors.margins: 1 // Gets cut off for some reason without this
                    implicitHeight: label.implicitHeight + Tokens.padding.medium * 2

                    radius: stateLayer.pressed ? Tokens.rounding.extraSmall : selected ? Tokens.rounding.largeIncreased : Tokens.rounding.medium
                    color: Qt.alpha(Colours.palette.m3tertiaryContainer, selected ? 1 : 0)

                    Behavior on radius {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }

                    Behavior on color {
                        CAnim {}
                    }

                    StateLayer {
                        id: stateLayer

                        onClicked: root.toggle(root.keyFor(item.modelData))
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: item.index === root.cursor
                        radius: item.radius
                        color: "transparent"
                        border.width: 2
                        border.color: Colours.palette.m3primary
                    }

                    StyledText {
                        id: label

                        anchors.left: parent.left
                        anchors.right: checkIcon.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.large
                        anchors.rightMargin: Tokens.spacing.medium

                        text: root.labelFor(item.modelData)
                        color: item.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                        wrapMode: Text.WordWrap
                    }

                    MaterialIcon {
                        id: checkIcon

                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Tokens.padding.large

                        text: item.selected ? "check_box" : "check_box_outline_blank"
                        color: item.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }
    }
}
