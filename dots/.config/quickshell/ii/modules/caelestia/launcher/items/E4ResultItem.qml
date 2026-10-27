// caelestia4: a Caelestia-styled launcher row for ONE end-4 search result (LauncherSearchResult).
// Used by AppList's "e4" state: clipboard (;), emoji (:), math (=), shell command ($), web search (?),
// end-4 actions (/), and the fallback when no app matches. Layout mirrors AppItem/ActionItem.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.common.models as E4M // caelestia4: keep

Item {
    id: root

    required property var modelData // end-4 LauncherSearchResult
    required property ScreenState screenState

    readonly property var iconType: modelData?.iconType ?? E4M.LauncherSearchResult.IconType.None
    readonly property string iconName: modelData?.iconName ?? ""
    readonly property bool mono: modelData?.fontType === E4M.LauncherSearchResult.FontType.Monospace
    readonly property string subtitle: [modelData?.type, modelData?.comment].filter(s => s && s.length).join(" · ")
    // caelestia4: the result's own actions (clipboard: pin to favourites / copy / delete, end-4 PR #3716) as buttons on
    // the right, shown on the selected or hovered row
    readonly property var actions: (modelData?.actions ?? []).filter(a => a?.iconType === E4M.LauncherSearchResult.IconType.Material)
    readonly property bool showActions: actions.length > 0 && (hover.hovered || (ListView.isCurrentItem ?? false))

    function activate(): void {
        const result = root.modelData;
        root.screenState.launcher = false;
        result?.execute?.();
    }

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    HoverHandler {
        id: hover
    }

    StateLayer {
        radius: Tokens.rounding.large
        onClicked: root.activate()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.medium
        anchors.rightMargin: Tokens.padding.medium
        anchors.margins: Tokens.padding.small

        Item {
            id: icon

            implicitWidth: parent.height * 0.8
            implicitHeight: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            IconImage {
                anchors.fill: parent
                visible: root.iconType === E4M.LauncherSearchResult.IconType.System
                asynchronous: true
                source: visible ? Quickshell.iconPath(root.iconName, "image-missing") : ""
            }

            MaterialIcon {
                anchors.centerIn: parent
                visible: root.iconType === E4M.LauncherSearchResult.IconType.Material
                    || root.iconType === E4M.LauncherSearchResult.IconType.None
                text: root.iconType === E4M.LauncherSearchResult.IconType.Material ? root.iconName : "search"
                color: Colours.palette.m3onSurfaceVariant
                fontStyle: Tokens.font.icon.builders.large.scale(1.3).build()
            }

            StyledText {
                anchors.centerIn: parent
                visible: root.iconType === E4M.LauncherSearchResult.IconType.Text
                text: root.iconName
                font.pixelSize: icon.height * 0.7
            }
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.medium
            anchors.right: verb.left
            anchors.rightMargin: Tokens.spacing.medium
            anchors.verticalCenter: icon.verticalCenter

            implicitHeight: name.implicitHeight + sub.implicitHeight

            StyledText {
                id: name

                width: parent.width
                text: root.modelData?.name ?? ""
                font: root.mono ? Tokens.font.mono.medium : Tokens.font.body.medium
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            StyledText {
                id: sub

                width: parent.width
                anchors.top: name.bottom
                text: root.subtitle
                font: Tokens.font.body.small
                color: Colours.palette.m3outline
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }

        StyledText {
            id: verb

            anchors.right: actionRow.left
            anchors.rightMargin: actionRow.width > 0 ? Tokens.spacing.small : 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?.verb ?? ""
            font: Tokens.font.label.medium
            color: Colours.palette.m3primary
        }

        Row {
            id: actionRow

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Tokens.spacing.extraSmall
            visible: root.showActions
            width: visible ? implicitWidth : 0

            Repeater {
                model: root.actions

                IconButton {
                    required property var modelData

                    icon: modelData.iconName
                    type: IconButton.Text
                    onClicked: {
                        // Pin / unpin / delete keep the launcher open (the list refreshes itself); others close it
                        if (!["keep", "keep_off", "delete"].includes(modelData.iconName))
                            root.screenState.launcher = false;
                        modelData.execute?.();
                    }
                }
            }
        }
    }
}
