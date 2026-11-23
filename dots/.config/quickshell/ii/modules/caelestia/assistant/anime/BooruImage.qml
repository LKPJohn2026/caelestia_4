import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.utils
import qs.modules.common.widgets
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's
import qs.modules.caelestia.components.controls as CCtl // caelestia4: Caelestia buttons
import "../../../common/functions/untrusted.js" as Untrusted

Button {
    id: root
    property var imageData
    property var rowHeight
    property bool manualDownload: false
    property string referer: "" // caelestia4: sent with preview and full-size downloads (Gelbooru)
    property string previewDownloadPath
    property string downloadPath
    property string nsfwPath
    // caelestia4: the API's URL picks the name, so it is cleaned: a decoded %2F..%2F wrote outside the folder, a quote ran code
    property string fileName: Untrusted.safeFileName(imageData.file_url, "image")
    property string filePath: `${root.previewDownloadPath}/${root.fileName}`
    property int maxTagStringLineLength: 50
    property real imageRadius: CC.Tokens.rounding.small

    property bool showActions: false
    ImageDownloaderProcess {
        id: imageDownloader
        running: root.manualDownload
        filePath: root.filePath
        referer: root.referer
        // caelestia4: web URLs only (the API sets it: no file://, no curl option)
        sourceUrl: Untrusted.isHttpUrl(root.imageData.preview_url ?? root.imageData.sample_url) ? (root.imageData.preview_url ?? root.imageData.sample_url) : ""
        onDone: (path, width, height) => {
            imageObject.source = ""
            imageObject.source = path
            if (!modelData.width || !modelData.height) {
                modelData.width = width
                modelData.height = height
                modelData.aspect_ratio = width / height
            }
        }
    }

    StyledToolTip {
        text: `${StringUtils.wordWrap(root.imageData.tags, root.maxTagStringLineLength)}`
    }

    padding: 0
    implicitWidth: root.rowHeight * modelData.aspect_ratio
    implicitHeight: root.rowHeight

    background: Rectangle {
        implicitWidth: root.rowHeight * modelData.aspect_ratio
        implicitHeight: root.rowHeight
        radius: imageRadius
        color: Colours.tPalette.m3surfaceContainerHigh
    }

    contentItem: Item {
        anchors.fill: parent

        StyledImage {
            id: imageObject
            anchors.fill: parent
            width: root.rowHeight * modelData.aspect_ratio
            height: root.rowHeight
            fillMode: Image.PreserveAspectFit
            source: modelData.preview_url

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: root.rowHeight * modelData.aspect_ratio
                    height: root.rowHeight
                    radius: imageRadius
                }
            }
        }

        CCtl.IconButton { // caelestia4: Caelestia icon button
            id: menuButton
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: Math.max(root.imageRadius - height / 2, 8)
            type: CCtl.IconButton.Tonal
            isRound: true
            padding: CC.Tokens.padding.extraSmall
            icon: "more_vert"
            onClicked: root.showActions = !root.showActions
        }

        Loader {
            id: contextMenuLoader
            active: root.showActions
            anchors.top: menuButton.bottom
            anchors.right: parent.right
            anchors.margins: 8

            sourceComponent: Item {
                width: contextMenu.width
                height: contextMenu.height

                StyledRectangularShadow {
                    target: contextMenu
                }
                Rectangle {
                    id: contextMenu
                    anchors.centerIn: parent
                    opacity: root.showActions ? 1 : 0
                    visible: opacity > 0
                    radius: CC.Tokens.rounding.medium // caelestia4
                    color: Colours.palette.m3surfaceContainerHigh
                    implicitHeight: contextMenuColumnLayout.implicitHeight + CC.Tokens.padding.small * 2
                    implicitWidth: contextMenuColumnLayout.implicitWidth

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Appearance.animation.elementMoveFast.duration
                            easing.type: Appearance.animation.elementMoveFast.type
                            easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
                        }
                    }

                    ColumnLayout {
                        id: contextMenuColumnLayout
                        anchors.centerIn: parent
                        spacing: 0

                        MenuRow {
                            id: openFileLinkButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Open file link")
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                if (Untrusted.isWebUrl(root.imageData.file_url)) // caelestia4: no file:, smb: or app handlers
                                    Qt.openUrlExternally(root.imageData.file_url)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuRow {
                            id: sourceButton
                            visible: Untrusted.isWebUrl(root.imageData.source)
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Go to source (%1)").arg(StringUtils.getDomain(root.imageData.source))
                            enabled: Untrusted.isWebUrl(root.imageData.source)
                            onClicked: {
                                root.showActions = false
                                Hyprland.dispatch("hl.config({cursor = {no_warps = true}})")
                                if (Untrusted.isWebUrl(root.imageData.source)) // caelestia4: an uploader sets it; web links only
                                    Qt.openUrlExternally(root.imageData.source)
                                Hyprland.dispatch("hl.config({cursor = {no_warps = false}})")
                            }
                        }
                        MenuRow {
                            id: downloadButton
                            Layout.fillWidth: true
                            buttonText: Translation.tr("Download")
                            onClicked: {
                                root.showActions = false;
                                const targetPath = root.imageData.is_nsfw ? root.nsfwPath : root.downloadPath;
                                if (!Untrusted.isHttpUrl(root.imageData.file_url)) // caelestia4: http(s) only, never a curl option
                                    return;
                                const userAgent = Config.options?.networking?.userAgent ?? ""
                                const curlArgs = (userAgent ? ["-H", `User-Agent: ${userAgent}`] : []).concat(root.referer ? ["-e", root.referer] : [])
                                // caelestia4: every value goes in as an argument, never into the shell code
                                Quickshell.execDetached(["bash", "-c",
                                    'mkdir -p -- "$1" && curl "${@:5}" -o "$1/$2" -- "$3" && notify-send -a Shell -- "$4" "$1/$2"',
                                    "bash", targetPath, root.fileName, root.imageData.file_url, Translation.tr("Download complete")].concat(curlArgs))
                            }
                        }
                    }
                }
            }
        }
    }
}