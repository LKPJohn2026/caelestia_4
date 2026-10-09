pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Caelestia.Config
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.functions as E4F // caelestia4: keep
import qs.modules.common.models.gCloud // caelestia4: keep
import qs.modules.common.utils as E4U // caelestia4: keep
import qs.modules.common.widgets as E4W // caelestia4: keep
import qs.modules.caelestia.adapters

// caelestia4: end-4's ScreenTextOverlay (modules/ii/screenTranslator) without its own loading / error UI: the
// Caelestia panel (ScreenTranslatorPanel) shows status and errors in screen space from loading / error /
// errorMessage / statusText. Text boxes keep end-4's look (blurred original, translated text in the detected
// colours), with Caelestia rounding and palette fallback.
Item {
    id: root

    property double scaleFactor: 1
    required property string screenshotPath

    readonly property string wikiLink: "https://ii.clsty.link/en/ii-qs/02usage/#setting-it-up" // TODO: write a page for this
    readonly property string textColorDetectionScriptPath: Quickshell.shellPath("scripts/images/text-color-venv.sh")

    property bool loading: true
    property var visionParagraphs: []
    property list<string> translationKeys: []
    property var translation: ({})

    function translate(s: string): string {
        return translation[s] ?? s;
    }

    property bool error: false
    property string errorMessage: ""
    function showError() {
        error = true;
    }

    Component.onCompleted: {
        if (E4.GoogleCloud.tokenReady && E4.GoogleCloud.tokenError) {
            root.showError();
        }
        cloudVision.annotateImage(screenshotPath);
    }

    function reattemptAsNeeded() {
        if (root.visionParagraphs == [] && E4.GoogleCloud.tokenReady && !E4.GoogleCloud.tokenError) {
            root.error = false;
            cloudVision.annotateImage(root.screenshotPath);
        }
    }

    Connections {
        target: E4.GoogleCloud
        function onTokenReadyChanged() {
            root.reattemptAsNeeded();
        }
    }

    readonly property string statusText: {
        if (cloudVision.state == GCloudApi.State.Preparing)
            return qsTr("Uploading image");
        else if (cloudVision.state == GCloudApi.State.Processing)
            return qsTr("Reading text");
        else if (cloudTrans.state == GCloudApi.State.Preparing)
            return qsTr("Getting ready to translate");
        else if (cloudTrans.state == GCloudApi.State.Processing)
            return qsTr("Translating");
        return qsTr("Preparing");
    }

    GCloudVisionResult {
        id: gcr
    }

    function handleError(msg) {
        if (msg?.length > 0) root.errorMessage = msg;
        else root.errorMessage = qsTr("Set your Google Cloud service account key");
        root.showError();
    }

    GCloudVision {
        id: cloudVision
        onError: (msg) => {
            root.handleError(msg);
        }
        onFinished: {
            gcr.initializeWithData(outputData);
            root.visionParagraphs = gcr.coherentParagraphs;
            // print(gcr.coherentParagraphs)
            root.translationKeys = gcr.coherentParagraphs.map(p => p.text);
            // print("TRANSLATION KEYS:", JSON.stringify(root.translationKeys));
            cloudTrans.translateStrings(root.translationKeys);
        }
    }

    GCloudTranslate {
        id: cloudTrans
        onError: (msg) => {
            root.handleError(msg);
        }
        onFinished: {
            var values = outputData.translations.map(translation => translation.translatedText);
            const keys = root.translationKeys;
            root.translation = ({});
            for (var i = 0; i < keys.length; i++) {
                Object.assign(root.translation, {
                    [keys[i]]: values[i]
                });
            }
            // print("TRANSLATION:", JSON.stringify(root.translation));
            root.loading = false;
        }
    }

    property real windowWidth: QsWindow.window.screen.width
    property real windowHeight: QsWindow.window.screen.height

    E4W.StyledImage {
        id: screenshotImage
        z: 1
        asynchronous: false
        width: root.windowWidth
        height: root.windowHeight
        source: Qt.resolvedUrl(root.screenshotPath)
        visible: false
    }

    Item {
        id: blurMaskItem
        z: 2
        width: root.windowWidth
        height: root.windowHeight
        layer.enabled: true
        visible: false
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            delegate: VisionBoundingBoxRect {
                readonly property string text: modelData.text
                readonly property string translatedText: root.translate(text)
                visible: translatedText != text
                scaleFactor: 1
            }
        }
    }

    E4W.MaskMultiEffect {
        z: 4
        implicitWidth: parent.width
        implicitHeight: parent.height
        width: parent.width
        height: parent.height

        // Mask
        source: screenshotImage
        maskSource: blurMaskItem

        // Blur
        blurEnabled: true
        blur: 1
        blurMax: 50
        blurMultiplier: root.scaleFactor
        autoPaddingEnabled: false
    }

    Item {
        id: textItems
        z: 999
        Repeater {
            model: root.loading ? [] : root.visionParagraphs
            // An entry looks like this:
            delegate: TextItem {}
        }
    }

    component VisionBoundingBoxRect: Rectangle {
        required property var modelData
        property real scaleFactor: root.scaleFactor
        property list<var> boundingVertices: modelData.boundingBox.vertices
        property real unscaledX: boundingVertices[0].x
        property real unscaledY: boundingVertices[0].y
        property real unscaledWidth: boundingVertices[1].x - boundingVertices[0].x
        property real unscaledHeight: boundingVertices[3].y - boundingVertices[0].y
        
        // Calculate rotation based on first two vertices (top-left to top-right)
        property real dx: boundingVertices[1].x - boundingVertices[0].x
        property real dy: boundingVertices[1].y - boundingVertices[0].y
        transformOrigin: Item.TopLeft
        rotation: {
            // Note rotation in qml is degrees clockwise
            var angle = Math.atan2(dy, dx) * 180 / Math.PI;
            return angle;
        }
        
        x: unscaledX * scaleFactor
        y: unscaledY * scaleFactor
        width: unscaledWidth * scaleFactor
        height: unscaledHeight * scaleFactor
        radius: Tokens.rounding.extraSmall
    }

    component TextItem: VisionBoundingBoxRect {
        id: ti
        // {"boundingPoly": {"vertices": [{"x": 536,"y": 236},{"x": 583,"y": 236},{"x": 583,"y": 262},{"x": 536,"y": 262}]},"description": "宮坂"}
        readonly property string text: modelData.text
        readonly property string translatedText: root.translate(text)
        visible: translatedText != text

        color: Qt.alpha(Colours.palette.m3secondaryContainer, 0.6)
        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Loader {
            active: ti.visible
            sourceComponent: E4U.MultiTurnProcess {
                Component.onCompleted: {
                    runSequence([ //
                        [ //
                            "bash", "-c", //
                            `magick ${E4F.StringUtils.shellSingleQuoteEscape(root.screenshotPath)} +repage -crop ${E4F.StringUtils.shellSingleQuoteEscape(ti.unscaledWidth)}x${E4F.StringUtils.shellSingleQuoteEscape(ti.unscaledHeight)}+${E4F.StringUtils.shellSingleQuoteEscape(ti.unscaledX)}+${E4F.StringUtils.shellSingleQuoteEscape(ti.unscaledY)} png:- | ${root.textColorDetectionScriptPath}`
                        ],
                        (out => {
                            var colorData = JSON.parse(out);
                            ti.color = E4F.ColorUtils.transparentize(colorData.background, 0.4);
                            tiText.color = colorData.text;
                        })
                    ]);
                }
            }
        }

        E4W.SqueezedAnnotationStyledText {
            id: tiText
            width: parent.width
            height: parent.height
            text: ti.translatedText
            scaleFactor: root.scaleFactor

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
    }
}
