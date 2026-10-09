pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.utils as E4U // caelestia4: keep
import qs.modules.common.functions as E4F // caelestia4: keep
import qs.modules.ii.regionSelector as E4R // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: end-4's region selector (modules/ii/regionSelector/RegionSelection.qml) in Caelestia style. Same
// logic: frozen screen, click a window / layer / detected image to take it, drag a rectangle or draw a circle,
// left button = action, right button = annotate (screenshot), recording is stopped by re-triggering.
// Caelestia parts: palette colours, rounded selection with corner handles and a size chip, cursor chip, region
// labels, and a floating toolbar where the shape (rect / circle) and the action (screenshot / Lens / text / record)
// can be switched while selecting.
PanelWindow {
    id: root

    enum SnipAction {
        Copy,
        Edit,
        Search,
        CharRecognition,
        Record,
        RecordWithSound
    }
    enum SelectionMode {
        RectCorners,
        Circle
    }
    enum Phase {
        Select,
        Post
    }

    property var action: RegionSelection.SnipAction.Copy
    property var selectionMode: RegionSelection.SelectionMode.RectCorners
    property var phase: RegionSelection.Phase.Select

    signal dismiss
    signal actionPicked(var action)
    signal selectionModePicked(var mode)

    visible: false
    color: "transparent"
    WlrLayershell.namespace: "quickshell:regionSelector"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    contentItem.Config.screen: screen.name
    contentItem.Tokens.screen: screen.name

    // Styles
    property string screenshotDir: E4C.Directories.screenshotTemp
    property color overlayColor: Qt.rgba(0, 0, 0, 0.5)
    property color selectionColor: Colours.palette.m3primary
    property color windowBorderColor: Colours.palette.m3secondary
    property color windowFillColor: Qt.alpha(windowBorderColor, 0.15)
    property color imageBorderColor: Colours.palette.m3tertiary
    property color imageFillColor: Qt.alpha(imageBorderColor, 0.15)
    property real targetRegionOpacity: E4C.Config.options.regionSelector.targetRegions.opacity
    property real contentRegionOpacity: E4C.Config.options.regionSelector.targetRegions.contentRegionOpacity

    // Vars for indicators
    readonly property var windows: [...E4.HyprlandData.windowList].sort((a, b) => {
        // floating windows first
        if (a.floating === b.floating)
            return 0;
        return a.floating ? -1 : 1;
    })
    readonly property var layers: E4.HyprlandData.layers
    readonly property real falsePositivePreventionRatio: 0.5

    // Screen & interaction vars
    readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(screen)
    readonly property real monitorScale: hyprlandMonitor.scale
    readonly property real monitorOffsetX: hyprlandMonitor.x
    readonly property real monitorOffsetY: hyprlandMonitor.y
    property int activeWorkspaceId: hyprlandMonitor.activeWorkspace?.id ?? 0
    property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    property real dragStartX: 0
    property real dragStartY: 0
    property real draggingX: 0
    property real draggingY: 0
    property real dragDiffX: 0
    property real dragDiffY: 0
    property bool draggedAway: (dragDiffX !== 0 || dragDiffY !== 0)
    property bool dragging: false
    property list<point> points: []
    property var mouseButton: null
    property var imageRegions: []
    readonly property list<var> windowRegions: E4R.RegionFunctions.filterWindowRegionsByLayers(root.windows.filter(w => w.workspace.id === root.activeWorkspaceId), root.layerRegions).map(window => {
        return {
            at: [window.at[0] - root.monitorOffsetX, window.at[1] - root.monitorOffsetY],
            size: [window.size[0], window.size[1]],
            class: window.class,
            title: window.title
        };
    })
    readonly property list<var> layerRegions: {
        const layersOfThisMonitor = root.layers[root.hyprlandMonitor.name];
        const topLayers = layersOfThisMonitor?.levels["2"];
        if (!topLayers)
            return [];
        // Not the bar / dock / frame (caelestia-* layers are the shell's own drawers and frame)
        return topLayers.filter(layer => !(layer.namespace.includes(":bar") || layer.namespace.includes(":verticalBar") || layer.namespace.includes(":dock") || layer.namespace.startsWith("caelestia-"))).map(layer => ({
                    at: [layer.x - root.monitorOffsetX, layer.y - root.monitorOffsetY],
                    size: [layer.w, layer.h],
                    namespace: layer.namespace
                }));
    }

    // Config
    property bool isCircleSelection: (root.selectionMode === RegionSelection.SelectionMode.Circle)
    property bool enableWindowRegions: E4C.Config.options.regionSelector.targetRegions.windows && !isCircleSelection
    property bool enableLayerRegions: E4C.Config.options.regionSelector.targetRegions.layers && !isCircleSelection
    property bool enableContentRegions: E4C.Config.options.regionSelector.targetRegions.content

    // Target
    property real targetedRegionX: -1
    property real targetedRegionY: -1
    property real targetedRegionWidth: 0
    property real targetedRegionHeight: 0

    function targetedRegionValid(): bool {
        return (root.targetedRegionX >= 0 && root.targetedRegionY >= 0);
    }

    function setRegionToTargeted(): void {
        const padding = E4C.Config.options.regionSelector.targetRegions.selectionPadding; // so borders aren't cut off
        root.regionX = root.targetedRegionX - padding;
        root.regionY = root.targetedRegionY - padding;
        root.regionWidth = root.targetedRegionWidth + padding * 2;
        root.regionHeight = root.targetedRegionHeight + padding * 2;
    }

    function isTargeted(r: var): bool {
        return !root.draggedAway && root.targetedRegionX === r.at[0] && root.targetedRegionY === r.at[1] && root.targetedRegionWidth === r.size[0] && root.targetedRegionHeight === r.size[1];
    }

    function updateTargetedRegion(x: real, y: real): void {
        const hit = region => region.at[0] <= x && x <= region.at[0] + region.size[0] && region.at[1] <= y && y <= region.at[1] + region.size[1];
        // Image regions, then layers, then windows
        const target = root.imageRegions.find(hit) ?? root.layerRegions.find(hit) ?? root.windowRegions.find(hit);
        if (target) {
            root.targetedRegionX = target.at[0];
            root.targetedRegionY = target.at[1];
            root.targetedRegionWidth = target.size[0];
            root.targetedRegionHeight = target.size[1];
        } else {
            root.targetedRegionX = -1;
            root.targetedRegionY = -1;
            root.targetedRegionWidth = 0;
            root.targetedRegionHeight = 0;
        }
    }

    property real regionWidth: Math.abs(draggingX - dragStartX)
    property real regionHeight: Math.abs(draggingY - dragStartY)
    property real regionX: Math.min(dragStartX, draggingX)
    property real regionY: Math.min(dragStartY, draggingY)

    // Screenshot stuff
    E4U.TempScreenshotProcess {
        id: screenshotProc

        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (exitCode, exitStatus) => {
            if (root.enableContentRegions)
                imageDetectionProcess.running = true;
            root.preparationDone = !checkRecordingProc.running;
        }
    }

    property bool isRecording: root.action === RegionSelection.SnipAction.Record || root.action === RegionSelection.SnipAction.RecordWithSound
    property bool recordingShouldStop: false

    Process {
        id: checkRecordingProc

        running: root.isRecording
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            root.preparationDone = !screenshotProc.running;
            root.recordingShouldStop = (exitCode === 0);
        }
    }

    property bool preparationDone: false
    onPreparationDoneChanged: {
        if (!preparationDone)
            return;
        if (root.isRecording && root.recordingShouldStop) {
            Quickshell.execDetached([E4C.Directories.recordScriptPath]);
            root.dismiss();
            return;
        }
        root.visible = true;
    }

    Process {
        id: imageDetectionProcess

        command: ["bash", "-c", `${E4C.Directories.scriptPath}/images/find-regions-venv.sh ` + `--hyprctl ` + `--image '${E4F.StringUtils.shellSingleQuoteEscape(root.screenshotPath)}' ` + `--max-width ${Math.round(root.screen.width * root.falsePositivePreventionRatio)} ` + `--max-height ${Math.round(root.screen.height * root.falsePositivePreventionRatio)} `]
        stdout: StdioCollector {
            id: imageDimensionCollector

            onStreamFinished: {
                try {
                    root.imageRegions = E4R.RegionFunctions.filterImageRegions(JSON.parse(imageDimensionCollector.text), root.windowRegions);
                } catch (e) {
                    // the detector needs end-4's Python venv (~/.local/state/quickshell/.venv); without it: no image regions
                    root.imageRegions = [];
                }
            }
        }
    }

    function getScreenshotAction(): var {
        switch (root.action) {
        case RegionSelection.SnipAction.Copy:
            return E4U.ScreenshotAction.Action.Copy;
        case RegionSelection.SnipAction.Edit:
            return E4U.ScreenshotAction.Action.Edit;
        case RegionSelection.SnipAction.Search:
            return E4U.ScreenshotAction.Action.Search;
        case RegionSelection.SnipAction.CharRecognition:
            return E4U.ScreenshotAction.Action.CharRecognition;
        case RegionSelection.SnipAction.Record:
            return E4U.ScreenshotAction.Action.Record;
        case RegionSelection.SnipAction.RecordWithSound:
            return E4U.ScreenshotAction.Action.RecordWithSound;
        default:
            console.warn("[Region Selector] Unknown snip action, skipping snip.");
            root.dismiss();
            return;
        }
    }

    // Execution after selection
    function snip(): void {
        if (root.regionWidth <= 0 || root.regionHeight <= 0) {
            console.warn("[Region Selector] Invalid region size, skipping snip.");
            root.dismiss();
            return;
        }

        // Clamp region to screen bounds
        root.regionX = Math.max(0, Math.min(root.regionX, root.screen.width - root.regionWidth));
        root.regionY = Math.max(0, Math.min(root.regionY, root.screen.height - root.regionHeight));
        root.regionWidth = Math.max(0, Math.min(root.regionWidth, root.screen.width - root.regionX));
        root.regionHeight = Math.max(0, Math.min(root.regionHeight, root.screen.height - root.regionY));

        // Right button = annotate
        if (root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit)
            root.action = root.mouseButton === Qt.RightButton ? RegionSelection.SnipAction.Edit : RegionSelection.SnipAction.Copy;

        const screenshotDir = E4C.Config.options.screenSnip.savePath !== "" ? E4C.Config.options.screenSnip.savePath : "";
        const command = E4U.ScreenshotAction.getCommand(root.regionX * root.monitorScale, root.regionY * root.monitorScale, root.regionWidth * root.monitorScale, root.regionHeight * root.monitorScale, root.screenshotPath, root.getScreenshotAction(), screenshotDir);
        Quickshell.execDetached(command);
        if (root.isRecording) {
            root.phase = RegionSelection.Phase.Post;
            root.selectionMode = RegionSelection.SelectionMode.RectCorners;
        } else {
            root.dismiss();
        }
    }

    // Only clickable while selecting
    mask: Region {
        item: root.phase === RegionSelection.Phase.Select ? mouseArea : null
    }

    ScreencopyView { // frozen screen
        anchors.fill: parent
        live: false
        captureSource: root.screen
        visible: root.phase === RegionSelection.Phase.Select

        focus: root.visible
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape)
                root.dismiss();
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true

        onPressed: mouse => {
            root.dragStartX = mouse.x;
            root.dragStartY = mouse.y;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragging = true;
            root.mouseButton = mouse.button;
        }
        onReleased: mouse => {
            if (root.draggingX === root.dragStartX && root.draggingY === root.dragStartY) {
                // A click: take the targeted region
                if (root.targetedRegionValid())
                    root.setRegionToTargeted();
            } else if (root.selectionMode === RegionSelection.SelectionMode.Circle) {
                const padding = E4C.Config.options.regionSelector.circle.padding + E4C.Config.options.regionSelector.circle.strokeWidth / 2;
                const dragPoints = (root.points.length > 0) ? root.points : [
                    {
                        x: mouseArea.mouseX,
                        y: mouseArea.mouseY
                    }
                ];
                const maxX = Math.max(...dragPoints.map(p => p.x));
                const minX = Math.min(...dragPoints.map(p => p.x));
                const maxY = Math.max(...dragPoints.map(p => p.y));
                const minY = Math.min(...dragPoints.map(p => p.y));
                root.regionX = minX - padding;
                root.regionY = minY - padding;
                root.regionWidth = maxX - minX + padding * 2;
                root.regionHeight = maxY - minY + padding * 2;
            }
            root.snip();
        }
        onPositionChanged: mouse => {
            root.updateTargetedRegion(mouse.x, mouse.y);
            if (!root.dragging)
                return;
            root.draggingX = mouse.x;
            root.draggingY = mouse.y;
            root.dragDiffX = mouse.x - root.dragStartX;
            root.dragDiffY = mouse.y - root.dragStartY;
            root.points.push({
                x: mouse.x,
                y: mouse.y
            });
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.RectCorners
            sourceComponent: RectSelection {
                regionX: root.regionX
                regionY: root.regionY
                regionWidth: root.regionWidth
                regionHeight: root.regionHeight
                mouseX: mouseArea.mouseX
                mouseY: mouseArea.mouseY
                color: root.selectionColor
                overlayColor: root.overlayColor
                showSize: root.dragging && root.draggedAway
                breathingBorderOnly: root.phase === RegionSelection.Phase.Post
            }
        }

        Loader {
            z: 2
            anchors.fill: parent
            active: root.selectionMode === RegionSelection.SelectionMode.Circle
            sourceComponent: E4R.CircleSelectionDetails {
                color: root.selectionColor
                overlayColor: root.overlayColor
                points: root.points
            }
        }

        // Chip next to the cursor: what the click will do
        CursorGuide {
            z: 9999
            visible: root.phase === RegionSelection.Phase.Select
            x: root.dragging ? root.regionX + root.regionWidth : mouseArea.mouseX
            y: root.dragging ? root.regionY + root.regionHeight : mouseArea.mouseY
            action: root.action
        }

        // Window regions
        Repeater {
            model: ScriptModel {
                values: root.phase === RegionSelection.Phase.Select && root.enableWindowRegions ? root.windowRegions : []
            }
            delegate: TargetRegion {
                required property var modelData

                z: 2
                clientDimensions: modelData
                showIcon: true
                targeted: root.isTargeted(modelData)
                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.class}`
                radius: E4C.Appearance.rounding.windowRounding
            }
        }

        // Layer regions
        Repeater {
            model: ScriptModel {
                values: root.phase === RegionSelection.Phase.Select && root.enableLayerRegions ? root.layerRegions : []
            }
            delegate: TargetRegion {
                required property var modelData

                z: 3
                clientDimensions: modelData
                targeted: root.isTargeted(modelData)
                opacity: root.draggedAway ? 0 : root.targetRegionOpacity
                borderColor: root.windowBorderColor
                fillColor: targeted ? root.windowFillColor : "transparent"
                text: `${modelData.namespace}`
                radius: E4C.Appearance.rounding.windowRounding
            }
        }

        // Content (image) regions
        Repeater {
            model: ScriptModel {
                values: root.phase === RegionSelection.Phase.Select && root.enableContentRegions ? root.imageRegions : []
            }
            delegate: TargetRegion {
                required property var modelData

                z: 4
                clientDimensions: modelData
                targeted: root.isTargeted(modelData)
                opacity: root.draggedAway ? 0 : root.contentRegionOpacity
                borderColor: root.imageBorderColor
                fillColor: targeted ? root.imageFillColor : "transparent"
                text: Tr.tr("Image")
                icon: "image"
            }
        }

        // Toolbar: shape + action + close
        StyledRect {
            id: toolbar

            readonly property bool shown: root.visible && root.phase === RegionSelection.Phase.Select && !root.dragging

            z: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: shown ? Tokens.padding.extraLarge : -height
            opacity: shown ? 1 : 0
            implicitWidth: toolRow.implicitWidth + Tokens.padding.small * 2
            implicitHeight: toolRow.implicitHeight + Tokens.padding.small * 2
            radius: Tokens.rounding.full
            color: Colours.tPalette.m3surfaceContainer

            Behavior on anchors.bottomMargin {
                Anim {
                    type: Anim.DefaultSpatial
                }
            }
            Behavior on opacity {
                Anim {
                    type: Anim.FastEffects
                }
            }

            Elevation {
                anchors.fill: parent
                radius: parent.radius
                z: -1
                level: 2
            }

            // Swallow clicks so they don't start a selection under the toolbar
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                cursorShape: Qt.ArrowCursor
            }

            RowLayout {
                id: toolRow

                anchors.centerIn: parent
                spacing: Tokens.spacing.extraSmall

                ToolChip {
                    icon: "crop_free"
                    checked: !root.isCircleSelection
                    onClicked: root.selectionModePicked(RegionSelection.SelectionMode.RectCorners)
                }

                ToolChip {
                    icon: "gesture"
                    checked: root.isCircleSelection
                    onClicked: root.selectionModePicked(RegionSelection.SelectionMode.Circle)
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.topMargin: Tokens.padding.medium
                    Layout.bottomMargin: Tokens.padding.medium
                    Layout.leftMargin: Tokens.spacing.small
                    Layout.rightMargin: Tokens.spacing.small
                    implicitWidth: 1
                    color: Colours.palette.m3outlineVariant
                }

                ToolChip {
                    icon: "screenshot_region"
                    text: Tr.tr("Screenshot")
                    checked: root.action === RegionSelection.SnipAction.Copy || root.action === RegionSelection.SnipAction.Edit
                    onClicked: root.actionPicked(RegionSelection.SnipAction.Copy)
                }

                ToolChip {
                    icon: "image_search"
                    text: Tr.tr("Lens")
                    checked: root.action === RegionSelection.SnipAction.Search
                    onClicked: root.actionPicked(RegionSelection.SnipAction.Search)
                }

                ToolChip {
                    icon: "document_scanner"
                    text: Tr.tr("Text")
                    checked: root.action === RegionSelection.SnipAction.CharRecognition
                    onClicked: root.actionPicked(RegionSelection.SnipAction.CharRecognition)
                }

                ToolChip {
                    icon: "videocam"
                    text: Tr.tr("Record")
                    checked: root.isRecording
                    onClicked: {
                        if (!root.isRecording)
                            root.actionPicked(RegionSelection.SnipAction.Record);
                    }
                }

                ToolChip {
                    visible: root.isRecording
                    icon: root.action === RegionSelection.SnipAction.RecordWithSound ? "volume_up" : "volume_off"
                    checked: root.action === RegionSelection.SnipAction.RecordWithSound
                    onClicked: root.actionPicked(checked ? RegionSelection.SnipAction.Record : RegionSelection.SnipAction.RecordWithSound)
                }

                Rectangle {
                    Layout.fillHeight: true
                    Layout.topMargin: Tokens.padding.medium
                    Layout.bottomMargin: Tokens.padding.medium
                    Layout.leftMargin: Tokens.spacing.small
                    Layout.rightMargin: Tokens.spacing.small
                    implicitWidth: 1
                    color: Colours.palette.m3outlineVariant
                }

                ToolChip {
                    icon: "close"
                    onClicked: root.dismiss()
                }
            }
        }
    }
}
