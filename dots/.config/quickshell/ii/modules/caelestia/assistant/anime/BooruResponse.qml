import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.caelestia.assistant
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Qt5Compat.GraphicalEffects
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's
import qs.modules.caelestia.components.controls as CCtl // caelestia4: Caelestia buttons (aliased: other control names clash with end-4 widgets)

Rectangle {
    id: root
    property var responseData
    property var tagInputField

    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath

    property real availableWidth: parent.width
    property real rowTooShortThreshold: 190
    property real imageSpacing: 5
    property real responsePadding: 5

    anchors.left: parent?.left
    anchors.right: parent?.right
    implicitHeight: columnLayout.implicitHeight + root.responsePadding * 2

    Component.onCompleted: {
        // Break property bind to prevent aggressive updates
        availableWidth = parent.width
    }

    Connections {
        target: parent
        function onWidthChanged() {
            updateWidthTimer.restart()
        }
    }

    Timer {
        id: updateWidthTimer
        interval: 100
        onTriggered: {
            availableWidth = parent.width
        }
    }

    radius: CC.Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: columnLayout
        
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: responsePadding
        spacing: root.imageSpacing

        RowLayout { // Header
            Rectangle { // Provider name
                id: providerNameWrapper
                color: Colours.palette.m3secondaryContainer
                radius: CC.Tokens.rounding.small
                implicitWidth: providerName.implicitWidth + 10 * 2
                implicitHeight: Math.max(providerName.implicitHeight + 5 * 2, 30)
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: providerName
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.large
                    color: Colours.palette.m3onSecondaryContainer
                    text: Booru.providers[root.responseData.provider].name
                }
            }
            Item { Layout.fillWidth: true }
            Item { // Page number
                visible: root.responseData.page != "" && root.responseData.page > 0
                implicitWidth: Math.max(pageNumber.implicitWidth + 10 * 2, 30)
                implicitHeight: pageNumber.implicitHeight + 5 * 2
                Layout.alignment: Qt.AlignVCenter

                StyledText {
                    id: pageNumber
                    anchors.centerIn: parent
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: Colours.palette.m3onSurface
                    // text: `Page ${root.responseData.page}`
                    text: Translation.tr("Page %1").arg(root.responseData.page)
                }
            }
        }

        StyledFlickable { // Tag strip
            id: tagsFlickable
            visible: root.responseData.tags.length > 0
            Layout.alignment: Qt.AlignLeft
            Layout.fillWidth: true
            implicitHeight: tagRowLayout.implicitHeight
            contentWidth: tagRowLayout.implicitWidth

            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: tagsFlickable.width
                    height: tagsFlickable.height
                    radius: CC.Tokens.rounding.small
                }
            }

            Behavior on implicitHeight {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            RowLayout {
                id: tagRowLayout
                Layout.alignment: Qt.AlignBottom

                Repeater {
                    id: tagRepeater
                    model: root.responseData.tags

                    ApiCommandButton {
                        Layout.fillWidth: false
                        buttonText: modelData
                        onClicked: {
                            if(root.tagInputField.text.length !== 0) root.tagInputField.text += " "
                            root.tagInputField.text += modelData
                        }
                    }
                }
                
            }
        }

        StyledText { // Message
            id: messageText
            Layout.fillWidth: true
            visible: root.responseData.message.length > 0
            font.pixelSize: Appearance.font.pixelSize.small
            color: Colours.palette.m3onSurface
            text: root.responseData.message
            wrapMode: Text.WordWrap
            Layout.margins: responsePadding
            textFormat: Text.MarkdownText
            onLinkActivated: (link) => {
                Qt.openUrlExternally(link)
                GlobalStates.sidebarLeftOpen = false
            }
            PointingHandLinkHover {}
        }

        Repeater {
            model: ScriptModel {
                values: {
                    // Greedily add images to a row as long as rowHeight >= rowTooShortThreshold
                    let i = 0;
                    let rows = [];
                    const responseList = root.responseData.images;
                    const minRowHeight = rowTooShortThreshold;
                    const availableImageWidth = availableWidth - root.imageSpacing - (responsePadding * 2);

                    while (i < responseList.length) {
                        let row = {
                            height: 0,
                            images: [],
                        };
                        let j = i;
                        let combinedAspect = 0;
                        let rowHeight = 0;

                        // Try to add as many images as possible without going below minRowHeight
                        while (j < responseList.length) {
                            combinedAspect += responseList[j].aspect_ratio;
                            // Subtract imageSpacing for each gap between images in the row
                            let imagesInRow = j - i + 1;
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);
                            let rowAvailableWidth = availableImageWidth - totalSpacing;
                            rowHeight = rowAvailableWidth / combinedAspect;
                            if (rowHeight < minRowHeight) {
                                combinedAspect -= responseList[j].aspect_ratio;
                                imagesInRow -= 1;
                                totalSpacing = root.imageSpacing * (imagesInRow - 1);
                                rowAvailableWidth = availableImageWidth - totalSpacing;
                                rowHeight = rowAvailableWidth / combinedAspect;
                                break;
                            }
                            j++;
                        }

                        // If we couldn't add any image (shouldn't happen), add at least one
                        if (j === i) {
                            row.images.push(responseList[i]);
                            row.height = availableImageWidth / responseList[i].aspect_ratio;
                            rows.push(row);
                            i++;
                        } else {
                            for (let k = i; k < j; k++) {
                                row.images.push(responseList[k]);
                            }
                            // Recalculate spacing for the final row
                            let imagesInRow = j - i;
                            let totalSpacing = root.imageSpacing * (imagesInRow - 1);
                            let rowAvailableWidth = availableImageWidth - totalSpacing;
                            row.height = rowAvailableWidth / combinedAspect;
                            rows.push(row);
                            i = j;
                        }
                    }
                    return rows;
                }
            }
            delegate: RowLayout {
                id: imageRow
                required property var modelData
                property var rowHeight: modelData.height
                spacing: root.imageSpacing

                Repeater {
                    model: modelData.images
                    delegate: BooruImage {
                        required property var modelData
                        imageData: modelData
                        rowHeight: imageRow.rowHeight
                        imageRadius: imageRow.modelData.images.length == 1 ? 50 : CC.Tokens.rounding.medium
                        // Download manually to reduce redundant requests or make sure downloading works
                        manualDownload: ["danbooru", "waifu.im", "t.alcy.cc", "konachan", "gelbooru"].includes(root.responseData.provider)
                        referer: Booru.providers[root.responseData.provider]?.imageReferer ?? ""
                        previewDownloadPath: root.previewDownloadPath
                        downloadPath: root.downloadPath
                        nsfwPath: root.nsfwPath
                    }
                }
            }
        }

        CCtl.IconTextButton { // Next page button (caelestia4: Caelestia tonal button)
            id: button
            visible: root.responseData.page != "" && root.responseData.page > 0
            Layout.alignment: Qt.AlignRight
            type: CCtl.IconTextButton.Tonal
            icon: "chevron_right"
            text: Translation.tr("Next page")
            onClicked: {
                tagInputField.text = `${responseData.tags.join(" ")} ${parseInt(root.responseData.page) + 1}`
                tagInputField.accept()
            }
        }
    }
}
