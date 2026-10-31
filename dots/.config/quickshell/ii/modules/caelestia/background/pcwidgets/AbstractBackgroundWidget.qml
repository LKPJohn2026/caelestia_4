import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets.widgetCanvas

AbstractWidget {
    id: root

    required property string configEntryName
    required property int screenWidth
    required property int screenHeight
    required property int scaledScreenWidth
    required property int scaledScreenHeight
    required property real wallpaperScale

    property Item wallpaperItem: null

    property bool visibleWhenLocked: Config.options.lock.showWidgets
    property var configEntry: Config.options.background.widgets[configEntryName]
    property string placementStrategy: configEntry.placementStrategy
    // caelestia4: x and y are stored on Config's widget canvas (a preset's 1920x1080, say) and mapped to this screen
    readonly property var canvas: Config.options.background.widgets.canvas
    readonly property real canvasWidth: canvas.width > 0 ? canvas.width : scaledScreenWidth
    readonly property real canvasHeight: canvas.height > 0 ? canvas.height : scaledScreenHeight
    property real targetX: Math.max(0, Math.min(toScreen(configEntry.x, width, canvasWidth, scaledScreenWidth), scaledScreenWidth - width))
    property real targetY: Math.max(0, Math.min(toScreen(configEntry.y, height, canvasHeight, scaledScreenHeight), scaledScreenHeight - height))
    property real targetZ: configEntry.z
    x: targetX
    y: targetY
    z: targetZ
    visible: opacity > 0
    opacity: (GlobalStates.screenLocked && !visibleWhenLocked) ? 0 : 1
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
    scale: (draggable && containsPress) ? 1.05 : 1
    Behavior on scale {
        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
    }

    draggable: placementStrategy === "free" && !Config.options.background.widgetsLocked

    function requestDelete() {
        Config.options.background.widgets[root.configEntryName].enable = false
    }
    function restoreXYBinding() {
        root.x = Qt.binding(() => root.targetX);
        root.y = Qt.binding(() => root.targetY);
        root.z = Qt.binding(() => root.targetZ);
    }

    function commitPosition() {
        configEntry.x = toCanvas(root.x, width, canvasWidth, scaledScreenWidth);
        configEntry.y = toCanvas(root.y, height, canvasHeight, scaledScreenHeight);
        configEntry.z = root.z;
        root.targetX = Qt.binding(() => Math.max(0, Math.min(toScreen(configEntry.x, width, canvasWidth, scaledScreenWidth), scaledScreenWidth - width)));
        root.targetY = Qt.binding(() => Math.max(0, Math.min(toScreen(configEntry.y, height, canvasHeight, scaledScreenHeight), scaledScreenHeight - height)));
        root.targetZ = Qt.binding(() => configEntry.z);
        root.restoreXYBinding();
    }

    onReleased: root.commitPosition()

    // One axis: where a widget `size` long, at `pos` on a canvas `canvasSize` long, goes on a screen `screenSize` long.
    // The room left beside the widget is scaled, not its corner, so a widget against an edge stays against it
    // (and one in the middle stays in the middle) whatever the screen's aspect ratio
    function toScreen(pos: real, size: real, canvasSize: real, screenSize: real): real {
        const from = canvasSize - size, to = screenSize - size;
        if (from <= 0 || to <= 0) return pos * screenSize / canvasSize; // no room to scale: fall back to the corner
        return pos * to / from;
    }
    // The inverse of toScreen: a position on this screen back to the canvas (saved when a widget is dropped)
    function toCanvas(pos: real, size: real, canvasSize: real, screenSize: real): real {
        const from = canvasSize - size, to = screenSize - size;
        if (from <= 0 || to <= 0) return pos * canvasSize / screenSize;
        return pos * from / to;
    }

    property bool needsColText: false
    property color dominantColor: Appearance.colors.colPrimary
    property bool dominantColorIsDark: dominantColor.hslLightness < 0.5
    property color colText: {
        const onNormalBackground = (GlobalStates.screenLocked && Config.options.lock.blur.enable)
        const adaptiveColor = ColorUtils.colorWithLightness(Appearance.colors.colPrimary, (dominantColorIsDark ? 0.8 : 0.12))
        return onNormalBackground ? Appearance.colors.colOnLayer0 : adaptiveColor;
    }

    property bool wallpaperIsVideo: Config.options.background.wallpaperPath.endsWith(".mp4") || Config.options.background.wallpaperPath.endsWith(".webm") || Config.options.background.wallpaperPath.endsWith(".mkv") || Config.options.background.wallpaperPath.endsWith(".avi") || Config.options.background.wallpaperPath.endsWith(".mov")
    property string wallpaperPath: wallpaperIsVideo ? Config.options.background.thumbnailPath : Config.options.background.wallpaperPath
    
    onWallpaperPathChanged: refreshPlacementIfNeeded()
    onPlacementStrategyChanged: refreshPlacementIfNeeded()
    Connections {
        target: Config
        function onReadyChanged() { refreshPlacementIfNeeded() }
    }
    function refreshPlacementIfNeeded() {
        if (!Config.ready) return;
        if (root.placementStrategy === "free" && !root.needsColText) return;
        leastBusyRegionProc.wallpaperPath = root.wallpaperPath;
        leastBusyRegionProc.running = false;
        leastBusyRegionProc.running = true;
    }
    Process {
        id: leastBusyRegionProc
        property string wallpaperPath: root.wallpaperPath
        // TODO: make these less arbitrary
        property int contentWidth: 300
        property int contentHeight: 300
        property int horizontalPadding: 200
        property int verticalPadding: 200
        command: [Quickshell.shellPath("scripts/images/least-busy-region-venv.sh")
            , "--screen-width", Math.round(root.scaledScreenWidth)
            , "--screen-height", Math.round(root.scaledScreenHeight)
            , "--width", contentWidth
            , "--height", contentHeight
            , "--horizontal-padding", horizontalPadding
            , "--vertical-padding", verticalPadding
            , wallpaperPath
            , ...(root.placementStrategy === "mostBusy" ? ["--busiest"] : [])
        ]
        stdout: StdioCollector {
            id: leastBusyRegionOutputCollector
            onStreamFinished: {
                const output = leastBusyRegionOutputCollector.text;
                if (output.length === 0) return;
                const parsedContent = JSON.parse(output);
                root.dominantColor = parsedContent.dominant_color || Appearance.colors.colPrimary;
                if (root.placementStrategy === "free") return;
                root.targetX = parsedContent.center_x * root.wallpaperScale - root.width / 2;
                root.targetY  = parsedContent.center_y * root.wallpaperScale - root.height / 2;
            }
        }
    }
}