pragma ComponentBehavior: Bound

import Caelestia.Config as CC // caelestia4: Tokens as CC.Tokens (unaliased, Caelestia's Config would shadow end-4's)
import qs.modules.caelestia.adapters // caelestia4: Colours (end-4 services below win shared names)
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.modules.caelestia.components // caelestia4: last, so StyledText is Caelestia's
import "../../../common/functions/untrusted.js" as Untrusted // caelestia4: images and tags from the reply, link schemes

ColumnLayout {
    id: root
    // These are needed on the parent loader
    property bool editing: false
    property bool renderMarkdown: true
    property bool enableMouseSelection: false
    property var segmentContent: ({})
    property var messageData: {}
    property bool done: true
    property bool forceDisableChunkSplitting: false

    property list<string> renderedLatexHashes: []
    property string renderedSegmentContent: ""
    property string shownText: ""
    // caelestia4: while editing, the text area holds segmentContent itself as plain text (Markdown isn't rendered,
    // so nothing loads, and the edit keeps the raw text, not the sanitised one shown). switchingFormat: text changes
    // the switch makes aren't edits
    property bool plainEditing: false
    property bool switchingFormat: false
    property bool fadeChunkSplitting: !forceDisableChunkSplitting && !editing && !/\n\|/.test(shownText) && Config.options.sidebar.ai.textFadeIn

    Layout.fillWidth: true

    Timer {
        id: renderTimer
        interval: 1000
        repeat: false
        onTriggered: {
            renderLatex()
            for (const hash of renderedLatexHashes) {
                handleRenderedLatex(hash, true);
            }
        }
    }

    function renderLatex() {
        // Regex for $...$, $$...$$, \[...\]
        // Note: This is a simple approach and may need refinement for edge cases
        let regex = /(\$\$([\s\S]+?)\$\$)|(\$([^\$]+?)\$)|(\\\[((?:.|\n)+?)\\\])|(\\\(([\s\S]+?)\\\))/g;
        let match;
        while ((match = regex.exec(segmentContent)) !== null) {
            let expression = match[1] || match[2] || match[3] || match[4] || match[5] || match[6] || match[7] || match[8];
            if (expression) {
                Qt.callLater(() => {
                    const [renderHash, isNew] = LatexRenderer.requestRender(expression.trim());
                    if (!renderedLatexHashes.includes(renderHash)) {
                        renderedLatexHashes.push(renderHash);
                    }
                });
            }
        }
    }

    function handleRenderedLatex(hash, force = false) {
        if (renderedLatexHashes.includes(hash) || force) {
            const imagePath = LatexRenderer.renderedImagePaths[hash];
            if (!imagePath) return; // caelestia4: not rendered (yet, or MicroTeX failed): keep the text
            const markdownImage = `![latex](${imagePath})`;

            const expression = LatexRenderer.processedExpressions[hash];
            renderedSegmentContent = renderedSegmentContent.replace(expression, markdownImage);
        }
    }

    onDoneChanged: {
        renderTimer.restart();
    }
    onEditingChanged: {
        if (!editing) {
            // caelestia4: the edited text first (still shown as plain text), then back to Markdown (sanitised as shown)
            renderedSegmentContent = segmentContent;
            root.shownText = renderedSegmentContent;
            root.plainEditing = false;
            renderLatex()
        } else {
            // console.log("Editing mode enabled", segmentContent)
            root.switchingFormat = true;
            root.plainEditing = true; // caelestia4: plain text before the raw text goes in
            root.shownText = segmentContent;
            root.switchingFormat = false;
        }
    }

    onSegmentContentChanged: {
        // console.log("Segment content changed: " + segmentContent);
        if (root.plainEditing) return; // caelestia4: the user's edit, already in the text area
        // caelestia4: no image or HTML tag in the reply loads anything when shown: the text area shows it through
        // Untrusted.markdownSafe, which keeps only the rendered LaTeX images put in here
        renderedSegmentContent = segmentContent;
        if (!root.editing && segmentContent) {
            root.renderLatex();
        }
    }

    onRenderedSegmentContentChanged: {
        // console.log("Rendered segment content changed: " + renderedSegmentContent);
        if (renderedSegmentContent && !root.plainEditing) { // caelestia4: not over the text being edited
            root.shownText = renderedSegmentContent;
        }
    }

    // When something finishes rendering
    // 1. Check if the hash is in the list
    // 2. If it is, replace the expression with the image path
    Connections {
        target: LatexRenderer
        function onRenderFinished(hash, imagePath) {
            const expression = LatexRenderer.processedExpressions[hash];
            // console.log("Render finished: " + hash + " " + expression);
            handleRenderedLatex(hash);
        }
    }

    spacing: 0
    Repeater {
        id: textLinesRepeater
        property list<real> textLineOpacities: []
        model: ScriptModel {
            // Split by either double newlines or single newlines in a list
            values: root.fadeChunkSplitting ? root.shownText.split(/\n\n(?= {0,2})|\n(?= {0,2}[-\*])/g).filter(line => line.trim() !== "") : [root.shownText]
            onValuesChanged: {
                while (textLinesRepeater.textLineOpacities.length < values.length) {
                    textLinesRepeater.textLineOpacities.push(root.messageData.done ? 1 : 0);
                }
            }
        }
        delegate: TextArea {
            id: textArea
            required property int index
            required property string modelData

            // Fade in animation
            visible: opacity > 0
            opacity: fadeChunkSplitting ? (textLinesRepeater.textLineOpacities[index] ?? (root.messageData.done ? 1 : 0)) : 1
            Connections {
                target: root.messageData
                function onDoneChanged() {
                    if (root.messageData.done) {
                        textLinesRepeater.textLineOpacities[textArea.index] = 1
                    }
                }
            }
            Connections {
                target: textLinesRepeater.model
                function onValuesChanged() {
                    if (textLinesRepeater.model.values.length > textArea.index + 1) {
                        textLinesRepeater.textLineOpacities[textArea.index] = 1
                    }
                }
            }
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            Layout.fillWidth: true
            readOnly: !editing
            selectByMouse: enableMouseSelection || editing
            renderType: Text.NativeRendering
            font.family: Appearance.font.family.reading
            font.hintingPreference: Font.PreferNoHinting // Prevent weird bold text
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: Colours.palette.m3onSecondaryContainer
            selectionColor: Colours.palette.m3secondaryContainer
            wrapMode: TextEdit.Wrap
            color: root.messageData?.thinking ? Colours.palette.m3outline : Colours.palette.m3onSurface
            // caelestia4: a reply loads nothing from the network as it shows (an image URL could carry the chat away):
            // images become links, HTML other than formatting tags is shown as text; the rendered LaTeX (<hex>.svg in
            // LatexRenderer's folder) stays.
            // While editing (plainEditing) the raw segmentContent is shown as plain text, so what is saved is what was typed.
            readonly property bool showMarkdown: root.renderMarkdown && !root.plainEditing
            // Formatting tags only, rebuilt without attributes (<br> in table cells, H<sub>2</sub>O): they load nothing
            readonly property var allowTags: ["br", "b", "i", "u", "em", "strong", "sub", "sup", "tt", "code"]
            readonly property string safeText: showMarkdown ? Untrusted.markdownSafe(modelData, { localImageDir: LatexRenderer.latexOutputPath, allowTags: allowTags }) : modelData
            textFormat: showMarkdown ? TextEdit.MarkdownText : TextEdit.PlainText
            text: safeText
            // caelestia4: a format switch rewrites the text (Qt converts the document): back to safeText
            onTextFormatChanged: text = Qt.binding(() => textArea.safeText)

            onTextChanged: {
                if (!root.editing || !root.plainEditing || root.switchingFormat) return // caelestia4: only the user's edits
                segmentContent = text
            }

            onLinkActivated: (link) => {
                if (!Untrusted.isWebUrl(link)) return // caelestia4: web links only, no file:, smb: or app handlers
                Qt.openUrlExternally(link)
                GlobalStates.sidebarLeftOpen = false
            }

            // caelestia4: where a link goes, on hover before the click (its text, chosen by the reply, may say otherwise)
            StyledToolTip {
                extraVisibleCondition: false
                alternativeVisibleCondition: Untrusted.linkPreview(textArea.hoveredLink) !== ""
                text: Untrusted.linkPreview(textArea.hoveredLink)
            }

            MouseArea { // Pointing hand for links
                anchors.fill: parent
                acceptedButtons: Qt.NoButton // Only for hover
                hoverEnabled: true
                cursorShape: parent.hoveredLink !== "" ? Qt.PointingHandCursor : 
                    (enableMouseSelection || editing) ? Qt.IBeamCursor : Qt.ArrowCursor
            }

            // Rectangle {
            //     anchors.fill: parent
            //     color: "#22786378"
            //     border.width: 1
            //     border.color: "#7E7E7E"
            // }
        }
    }
}
