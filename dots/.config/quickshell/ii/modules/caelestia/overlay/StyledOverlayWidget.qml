pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.common
import qs.modules.common as E4C // caelestia4: end-4 Config (Caelestia.Config also has a Config)
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.common.widgets.widgetCanvas
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters

// caelestia4: end-4's overlay widget frame (drag, resize, pin, click-through: unchanged) drawn in Caelestia style:
// a surface card with a title row of Caelestia icon buttons; while the overlay is closed only pinned content shows.
/*
 * To make an overlay widget:
 * 1. Create a modules/overlay/<yourWidget>/<YourWidget>.qml, using this as the base class and declare your widget content as contentItem
 * 2. Add an entry to OverlayContext.availableWidgets with identifier=<yourWidgetIdentifier>
 * 3. Add an entry in Persistent.states.overlay.<yourWidgetIdentifier> with x, y, width, height, pinned, clickthrough properties set to reasonable defaults
 * 4. Add an entry in OverlayWidgetDelegateChooser with roleValue=<yourWidgetIdentifier> and Declare your widget in there
 * Use existing entries as reference.
 */
AbstractOverlayWidget {
    id: root

    // To be defined by subclasses
    required property Item contentItem
    property bool fancyBorders: true
    property bool showCenterButton: false
    property bool showClickabilityButton: true

    // Defaults n stuff
    required property var modelData
    readonly property string identifier: modelData.identifier
    readonly property string materialSymbol: modelData.materialSymbol ?? "widgets"
    property string title: identifier.replace(/([A-Z])/g, " $1").replace(/^./, function(str){ return str.toUpperCase(); })
    property var persistentStateEntry: Persistent.states.overlay[identifier]
    property real radius: Tokens.rounding.large
    property real minimumWidth: contentItem.implicitWidth
    property real minimumHeight: contentItem.implicitHeight
    property real resizeMargin: 8
    property real padding: Tokens.padding.small
    property real contentRadius: radius - padding

    // Resizing
    function getXResizeDirection(x) {
        return (x < root.resizeMargin) ? -1 : (x > root.width - root.resizeMargin) ? 1 : 0
    }
    function getYResizeDirection(y) {
        return (y < root.resizeMargin) ? -1 : (y > root.height - root.resizeMargin) ? 1 : 0
    }
    hoverEnabled: true
    property bool resizable: true
    property bool resizing: false
    // caelestia4: a resize goes from what is on screen (not the saved values, which may not fit here) through these, which
    // x, y and the size read: assigning to those would end their bindings, and with them the fit to the screen
    property var resizeStart: null
    property bool resizeMoved: false
    property real resizeX: 0
    property real resizeY: 0
    property real resizeWidth: 0
    property real resizeHeight: 0
    property int resizeXDirection: getXResizeDirection(mouseX)
    property int resizeYDirection: getYResizeDirection(mouseY)
    draggable: GlobalStates.overlayOpen
    drag.target: undefined
    // caelestia4: not while the window first gets its size either, or a widget fitted to this screen slides there on each opening
    readonly property real canvasWidth: root.parent?.width ?? 0
    property bool placed: false
    onCanvasWidthChanged: root.settle()
    function settle() {
        if (canvasWidth > 0 && !placed)
            Qt.callLater(() => { root.placed = true; });
    }
    animateXPos: placed && !dragHandler.active && !resizing
    animateYPos: placed && !dragHandler.active && !resizing
    z: dragHandler.active ? 2 : 1
    cursorShape: {
        if (dragHandler.active) return root.resizing ? cursorShape : Qt.ArrowCursor;
        if (resizeMargin < mouseX && mouseX < width - resizeMargin &&
            resizeMargin < mouseY && mouseY < height - resizeMargin) {
            return Qt.ArrowCursor;
        } else {
            if (!root.resizable) return Qt.ArrowCursor;
            const dragIsLeft = mouseX < width / 2
            const dragIsTop = mouseY < height / 2
            if ((dragIsLeft && dragIsTop) || (!dragIsLeft && !dragIsTop)) {
                return Qt.SizeFDiagCursor
            } else {
                return Qt.SizeBDiagCursor
            }
        }
    }

    // Positioning & sizing
    // caelestia4: the saved position comes from whichever screen it was set on (or the defaults, made for a large one):
    // keep the widget on this one. Only for showing it: the saved values stay until the widget is moved
    function fitted(position: real, size: real, available: real): real {
        return available > 0 ? Math.max(0, Math.min(position, available - size)) : position;
    }
    x: Math.round(resizing ? resizeX : fitted(persistentStateEntry.x, width, canvasWidth)) // Round or it'll be blurry
    y: Math.round(resizing ? resizeY : fitted(persistentStateEntry.y, height, root.parent?.height ?? 0)) // Round or it'll be blurry
    pinned: persistentStateEntry.pinned
    clickthrough: persistentStateEntry.clickthrough
    drag {
        minimumX: 0
        minimumY: 0
        maximumX: root.parent?.width - root.width
        maximumY: root.parent?.height - root.height
    }
    opacity: (GlobalStates.overlayOpen || !clickthrough) ? 1.0 : E4C.Config.options.overlay.clickthroughOpacity

    // Guarded states & registration funcs
    property bool open: Persistent.states.overlay.open
    property bool actuallyPinned: pinned && open
    property bool actuallyClickable: !clickthrough && actuallyPinned && open
    onActuallyPinnedChanged: reportPinnedState();
    onActuallyClickableChanged: reportClickableState();
    function reportPinnedState() {
        OverlayContext.pin(identifier, actuallyPinned);
    }
    function reportClickableState() {
        OverlayContext.registerClickableWidget(contentItem, actuallyClickable);
    }

    // Self-registeration with OverlayContext
    Component.onCompleted: {
        reportPinnedState();
        reportClickableState();
        settle();
    }

    Connections {
        target: OverlayContext
        function onRequestCenter(identifier) {
            if (identifier === root.identifier) {
                root.center()
            }
        }
    }

    // Hooks
    onPressed: (event) => {
        // We're only interested in handling resize here
        // Early returns
        if (!root.resizable) return;
        if (root.resizeMargin < event.x && event.x < root.width - root.resizeMargin &&
            root.resizeMargin < event.y && event.y < root.height - root.resizeMargin) {
            return;
        }
        // Resizing setup
        root.resizeStart = { x: root.x, y: root.y, width: contentContainer.implicitWidth, height: contentContainer.implicitHeight };
        root.resizeX = root.x;
        root.resizeY = root.y;
        root.resizeWidth = contentContainer.implicitWidth;
        root.resizeHeight = contentContainer.implicitHeight;
        root.resizeMoved = false;
        root.resizing = true;
        root.resizeXDirection = getXResizeDirection(event.x);
        root.resizeYDirection = getYResizeDirection(event.y);
        if (root.resizeYDirection !== 0 && root.resizeXDirection === 0) {
            root.resizeXDirection = event.x < root.width / 2 ? -1 : 1;
        } else if (root.resizeXDirection !== 0 && root.resizeYDirection === 0) {
            root.resizeYDirection = event.y < root.height / 2 ? -1 : 1;
        }
    }
    onPositionChanged: (event) => {
        if (!resizing) return;
        const start = root.resizeStart;
        const roomed = (size, room) => room > 0 ? Math.min(size, room) : size;
        const newWidth = roomed(Math.max(start.width + dragHandler.xAxis.activeValue * root.resizeXDirection, root.minimumWidth), contentContainer.roomX);
        const newHeight = roomed(Math.max(start.height + dragHandler.yAxis.activeValue * root.resizeYDirection, root.minimumHeight), contentContainer.roomY);
        if (newWidth !== start.width || newHeight !== start.height)
            root.resizeMoved = true;
        const negativeXDrag = root.resizeXDirection === -1;
        const negativeYDrag = root.resizeYDirection === -1;
        const wantedX = start.x + (negativeXDrag ? dragHandler.xAxis.activeValue : 0)
        const wantedY = start.y + (negativeYDrag ? dragHandler.yAxis.activeValue : 0)
        const negativeXDragLimit = start.x + start.width - newWidth;
        const negativeYDragLimit = start.y + start.height - newHeight;
        root.resizeWidth = newWidth;
        root.resizeHeight = newHeight;
        root.resizeX = negativeXDrag ? Math.min(wantedX, negativeXDragLimit) : wantedX;
        root.resizeY = negativeYDrag ? Math.min(wantedY, negativeYDragLimit) : wantedY;
    }
    onReleased: root.finishResize()
    // Also what the DragHandler taking over the press looks like, and that's when a resize really starts: it isn't active yet
    onCanceled: Qt.callLater(() => {
        if (!dragHandler.active) root.finishResize();
    })
    function finishResize() {
        if (!resizing) return;
        if (resizeMoved) savePosition(resizeX, resizeY, resizeWidth, resizeHeight);
        resizing = false;
    }
    DragHandler {
        id: dragHandler
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        target: (root.draggable && !root.resizing) ? root : null
        onActiveChanged: { // Handle drag release
            if (!active) {
                if (root.resizing) root.finishResize();
                else root.savePosition();
            }
        }
        xAxis.minimum: 0
        xAxis.maximum: root.parent?.width - root.width
        yAxis.minimum: 0
        yAxis.maximum: root.parent?.height - root.height
    }

    function close() {
        Persistent.states.overlay.open = Persistent.states.overlay.open.filter(type => type !== root.identifier);
    }

    function togglePinned() {
        persistentStateEntry.pinned = !persistentStateEntry.pinned;
    }

    function toggleClickthrough() {
        persistentStateEntry.clickthrough = !persistentStateEntry.clickthrough;
    }

    function savePosition(xPos = root.x, yPos = root.y, width = persistentStateEntry.width, height = persistentStateEntry.height) {
        persistentStateEntry.x = Math.round(xPos);
        persistentStateEntry.y = Math.round(yPos);
        persistentStateEntry.width = Math.round(width);
        persistentStateEntry.height = Math.round(height);
    }

    function center() {
        const targetX = (root.parent.width - contentColumn.width) / 2 - root.resizeMargin
        const targetY = (root.parent.height - contentContainer.height) / 2 - titleBar.implicitHeight + border.border.width - root.resizeMargin
        root.savePosition(targetX, targetY) // x and y follow it
    }

    visible: GlobalStates.overlayOpen || actuallyPinned
    implicitWidth: contentColumn.implicitWidth + resizeMargin * 2
    implicitHeight: contentColumn.implicitHeight + resizeMargin * 2

    StyledRect {
        id: border

        anchors {
            fill: parent
            margins: root.resizeMargin
        }
        color: Qt.alpha(Colours.palette.m3surfaceContainer, (root.fancyBorders && GlobalStates.overlayOpen) ? 1 : 0)
        radius: root.radius
        border.color: Qt.alpha(Colours.palette.m3outlineVariant, (root.fancyBorders && GlobalStates.overlayOpen) ? 0.6 : 0)
        border.width: 1

        Behavior on color {
            CAnim {}
        }

        ColumnLayout {
            id: contentColumn

            z: root.fancyBorders ? 0 : -1
            anchors.fill: parent
            spacing: 0

            // Title bar (only while the overlay is open)
            Item {
                id: titleBar

                opacity: GlobalStates.overlayOpen ? 1 : 0
                Layout.fillWidth: true
                implicitWidth: titleBarRow.implicitWidth + root.padding * 2
                implicitHeight: titleBarRow.implicitHeight + root.padding * 2

                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }

                // A plate behind the title when the widget itself is see-through (crosshair)
                StyledRect {
                    visible: !root.fancyBorders
                    anchors.fill: parent
                    radius: root.radius
                    color: Colours.palette.m3surfaceContainer
                }

                RowLayout {
                    id: titleBarRow

                    anchors {
                        fill: parent
                        margins: root.padding
                    }
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        text: root.materialSymbol
                        color: Colours.palette.m3primary
                        Layout.leftMargin: Tokens.padding.small
                        Layout.rightMargin: Tokens.spacing.extraSmall
                        Layout.alignment: Qt.AlignVCenter
                    }

                    StyledText {
                        Layout.fillWidth: true
                        text: root.title
                        elide: Text.ElideRight
                        font: Tokens.font.body.builders.medium.weight(Font.Medium).build()
                        color: Colours.palette.m3onSurface
                    }

                    TitlebarButton {
                        visible: root.showCenterButton
                        icon: "recenter"
                        onClicked: root.center()
                    }

                    TitlebarButton {
                        visible: root.pinned && root.showClickabilityButton
                        icon: "mouse"
                        isToggle: true
                        checked: !root.clickthrough
                        onClicked: root.toggleClickthrough()
                    }

                    TitlebarButton {
                        icon: "keep"
                        isToggle: true
                        checked: root.pinned
                        onClicked: root.togglePinned()
                    }

                    TitlebarButton {
                        icon: "close"
                        onClicked: root.close()
                    }
                }
            }

            // Content
            Item {
                id: contentContainer

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: root.fancyBorders ? root.padding : 0
                Layout.topMargin: 0
                Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                // caelestia4: and no larger than this screen
                readonly property real roomX: (root.parent?.width ?? 0) - root.resizeMargin * 2 - (root.fancyBorders ? root.padding * 2 : 0)
                readonly property real roomY: (root.parent?.height ?? 0) - root.resizeMargin * 2 - titleBar.implicitHeight - (root.fancyBorders ? root.padding : 0)
                implicitWidth: {
                    if (root.resizing) return root.resizeWidth;
                    const wanted = Math.max(root.persistentStateEntry.width, root.minimumWidth);
                    return roomX > 0 ? Math.min(wanted, roomX) : wanted;
                }
                implicitHeight: {
                    if (root.resizing) return root.resizeHeight;
                    const wanted = Math.max(root.persistentStateEntry.height, root.minimumHeight);
                    return roomY > 0 ? Math.min(wanted, roomY) : wanted;
                }
                children: [root.contentItem]
            }
        }
    }

    component TitlebarButton: IconButton {
        type: IconButton.Text
        isRound: true
        padding: Tokens.padding.extraSmall
        font: Tokens.font.icon.builders.small.build()
    }
}
