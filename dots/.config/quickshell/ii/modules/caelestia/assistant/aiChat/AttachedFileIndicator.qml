pragma ComponentBehavior: Bound

import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Io
import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's

Rectangle {
    id: root

    signal remove()
    property bool canRemove: true
    property string filePath: ""
    property string mimeType: ""
    property real maxHeight: 200
    property real imageWidth: -1
    property real imageHeight: -1
    property real scale: Math.min(root.maxHeight / imageHeight, root.width / imageWidth)
    onFilePathChanged: refresh()
    visible: filePath !== ""

    function refresh() {
        root.mimeType = "";
        root.imageWidth = -1;
        root.imageHeight = -1;
        fileTypeProc.exec(["file", "-b", "--mime-type", filePath]);
    }

    Process {
        id: fileTypeProc
        command: ["file", "-b", "--mime-type", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                root.mimeType = this.text;
                if (root.mimeType.startsWith("image/"))
                    imageSizeProc.exec(["identify", "-format", "%wx%h", filePath]);
            }
        }
    }

    Process {
        id: imageSizeProc
        command: ["identify", "-format", "%wx%h", filePath]
        stdout: StdioCollector {
            onStreamFinished: {
                const dimensions = this.text.split("x");
                root.imageWidth = parseInt(dimensions[0]);
                root.imageHeight = parseInt(dimensions[1]);
            }
        }
    }

    // Styles/widgets
    property real horizontalPadding: 10
    property real verticalPadding: 10
    radius: CC.Tokens.rounding.small - anchors.margins
    color: Colours.tPalette.m3surfaceContainerHigh
    implicitHeight: visible ? (contentItem.implicitHeight + verticalPadding * 2) : 0

    ColumnLayout {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        RowLayout {
            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: {
                    if (root.mimeType.startsWith("image/"))
                        return "image";
                    if (root.mimeType.startsWith("audio/"))
                        return "music_note";
                    if (root.mimeType.startsWith("video/"))
                        return "movie";
                    if (root.mimeType === "application/pdf")
                        return "picture_as_pdf";
                    if (root.mimeType.startsWith("text/"))
                        return "description";
                    return "file_present";
                }
                iconSize: Appearance.font.pixelSize.hugeass
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: root.filePath
                font.pixelSize: Appearance.font.pixelSize.smaller
                font.family: Appearance.font.family.monospace
                wrapMode: Text.Wrap
            }

            RippleButton {
                visible: root.canRemove
                Layout.alignment: Qt.AlignTop
                buttonRadius: CC.Tokens.rounding.full
                colBackground: Colours.tPalette.m3surfaceContainerHigh
                implicitHeight: 28
                implicitWidth: 28
                contentItem: MaterialSymbol {
                    anchors.centerIn: parent
                    text: "close"
                    horizontalAlignment: Text.AlignHCenter
                    iconSize: Appearance.font.pixelSize.larger
                    color: Colours.palette.m3onSurfaceVariant
                }

                onClicked: root.remove()
            }
        }

        Loader {
            id: imagePreviewLoader
            visible: (root.imageWidth != -1) && (root.imageHeight != -1)
            Layout.alignment: Qt.AlignHCenter
            sourceComponent: Item {
                implicitHeight: root.imageHeight * root.scale
                implicitWidth: imagePreview.implicitWidth
                StyledImage {
                    id: imagePreview
                    anchors.fill: parent
                    source: Qt.resolvedUrl(root.filePath)
                    fillMode: Image.PreserveAspectFit
                    antialiasing: true
                    width: root.imageWidth * root.scale
                    height: root.imageHeight * root.scale
                    sourceSize.width: root.imageWidth * root.scale
                    sourceSize.height: root.imageHeight * root.scale

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: imagePreview.width
                            height: imagePreview.height
                            radius: CC.Tokens.rounding.medium
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outlineVariant
                        radius: CC.Tokens.rounding.medium
                    }
                }
            }
        }
    }
}
