pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common

DialogRowButton {
    id: root

    required property var model
    property var selectedItem

    function keyFor(item: var): string {
        return item.id;
    }

    function labelFor(item: var): string {
        return item.label;
    }

    onOpenChanged: {
        if (open)
            selectedItem = null;
    }

    // caelestia4: Up/Down in the open dialog move the selection (Enter then accepts it)
    onKeyNavigated: delta => {
        const keys = (root.model ?? []).map(m => root.keyFor(m));
        if (!keys.length)
            return;
        const cur = keys.indexOf(root.selectedItem);
        root.selectedItem = keys[cur < 0 ? (delta > 0 ? 0 : keys.length - 1) : Math.max(0, Math.min(keys.length - 1, cur + delta))];
    }

    acceptAllowed: !!selectedItem
    separateContent: true
    horizontalContentMargin: -Tokens.padding.small

    content: Component {
        VerticalFadeListView {
            spacing: 0
            topMargin: Tokens.padding.large
            bottomMargin: Tokens.padding.large

            model: root.model
            currentIndex: (root.model ?? []).findIndex(m => root.keyFor(m) === root.selectedItem)
            highlightFollowsCurrentItem: false
            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, ListView.Contain);
            }

            delegate: StyledRect {
                id: item

                required property var modelData
                readonly property bool selected: root.selectedItem === root.keyFor(modelData)

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

                StateLayer {
                    id: stateLayer

                    onClicked: root.selectedItem = root.keyFor(item.modelData)
                }

                StyledText {
                    id: label

                    anchors.left: parent.left
                    anchors.right: item.selected ? checkIcon.left : parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large
                    anchors.rightMargin: item.selected ? Tokens.spacing.medium : anchors.margins

                    text: root.labelFor(item.modelData)
                    color: item.selected ? Colours.palette.m3onTertiaryContainer : Colours.palette.m3onSurface
                    wrapMode: Text.WordWrap
                }

                MaterialIcon {
                    id: checkIcon

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Tokens.padding.large

                    text: "check"
                    color: Colours.palette.m3onTertiaryContainer
                    fontStyle: Tokens.font.icon.medium
                    opacity: item.selected ? 1 : 0

                    Behavior on opacity {
                        Anim {
                            type: Anim.SlowEffects
                        }
                    }
                }
            }
        }
    }
}
