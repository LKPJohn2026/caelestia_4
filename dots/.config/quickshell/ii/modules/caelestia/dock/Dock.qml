pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs // caelestia4: keep
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters

// caelestia4: a Caelestia-style dock with end-4's dock features (modules/ii/dock), built on end-4's
// TaskbarApps service (pinned apps = Config.options.dock.pinnedApps, shared with the ii family).
//  - pin button keeps the dock shown and reserves space; otherwise it reveals on bottom-edge hover,
//    on an empty workspace, and hides for fullscreen / launcher / session / lock
//  - app: click = launch or cycle its windows, middle-click = new instance, right-click = pin/unpin,
//    dots = open windows (max 3), hover = live window previews (click = focus, middle-click/✕ = close)
//  - apps button: click = Caelestia launcher, right-click = workspace overview
// IPC: `qs -c ii ipc call dock togglePin`
Scope {
    id: root

    readonly property var cfg: E4C.Config.options.caelestia.dock
    property bool pinned: cfg.pinnedOnStartup

    IpcHandler {
        target: "dock"

        function togglePin(): void {
            root.pinned = !root.pinned;
        }
    }

    Variants {
        model: Quickshell.screens

        DockWindow {}
    }

    component DockWindow: StyledWindow {
        id: win

        required property ShellScreen modelData

        readonly property ScreenState screenState: ShellState.forScreen(modelData)
        readonly property HyprlandMonitor monitor: Hypr.monitorFor(modelData)
        readonly property bool fullscreen: monitor?.activeWorkspace?.toplevels.values.some(t => t.lastIpcObject.fullscreen > 1) ?? false
        readonly property bool workspaceEmpty: (monitor?.activeWorkspace?.toplevels.values.length ?? 1) === 0
        readonly property bool blocked: fullscreen || screenState.launcher || screenState.session || GlobalStates.screenLocked
        readonly property bool reveal: !blocked && (root.pinned || hoverArea.containsMouse || preview.shown || (root.cfg.revealOnEmptyWorkspace && workspaceEmpty))

        // Pinned: sit above Caelestia's border exclusion and reserve space. Otherwise overlap the border so the
        // very bottom pixels of the screen can reveal the dock.
        readonly property real borderOffset: root.pinned ? 0 : contentItem.Config.border.thickness

        screen: modelData
        name: "dock"
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.exclusionMode: root.pinned ? ExclusionMode.Normal : ExclusionMode.Ignore
        exclusiveZone: root.pinned && !blocked ? content.height + content.gap : 0
        implicitHeight: content.height + content.gap * 2 + borderOffset
        mask: Region {
            item: hoverArea
        }

        MouseArea {
            id: hoverArea

            readonly property real stripHeight: root.cfg.hoverToReveal ? 3 : 0

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            width: content.width + content.gap * 2
            height: win.reveal ? parent.height : stripHeight
            hoverEnabled: true

            StyledRect {
                id: content

                readonly property real gap: Tokens.spacing.medium
                readonly property real pad: Tokens.padding.small
                readonly property real itemSize: root.cfg.iconSize + Tokens.padding.medium * 2

                anchors.horizontalCenter: parent.horizontalCenter
                y: win.reveal ? hoverArea.height - height - gap - win.borderOffset : hoverArea.height + win.borderOffset + 2
                implicitWidth: row.implicitWidth + pad * 2
                implicitHeight: itemSize + pad * 2
                radius: Tokens.rounding.large
                color: Colours.tPalette.m3surfaceContainer
                opacity: win.reveal ? 1 : 0

                Behavior on y {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }
                Behavior on opacity {
                    Anim {
                        type: Anim.DefaultEffects
                    }
                }
                Behavior on implicitWidth {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                Elevation {
                    anchors.fill: parent
                    radius: parent.radius
                    z: -1
                    level: 2
                }

                RowLayout {
                    id: row

                    anchors.centerIn: parent
                    spacing: Tokens.spacing.extraSmall

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        type: IconButton.Text
                        icon: "keep"
                        isToggle: true
                        checked: root.pinned
                        onClicked: root.pinned = !root.pinned
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        ToolTip.text: root.pinned ? Tr.tr("Unpin dock") : Tr.tr("Keep dock shown")
                    }

                    Separator {
                        itemSize: content.itemSize
                    }

                    Repeater {
                        model: ScriptModel {
                            values: E4.TaskbarApps.apps
                            objectProp: "appId"
                        }

                        DockApp {
                            itemSize: content.itemSize
                            dockPreview: preview
                        }
                    }

                    Separator {
                        itemSize: content.itemSize
                        visible: E4.TaskbarApps.apps.length > 0
                    }

                    IconButton {
                        Layout.alignment: Qt.AlignVCenter
                        type: IconButton.Text
                        icon: "apps"
                        onClicked: win.screenState.launcher = !win.screenState.launcher
                        ToolTip.visible: hovered
                        ToolTip.delay: 500
                        ToolTip.text: Tr.tr("Apps · right-click for workspace overview")

                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: GlobalStates.overviewOpen = !GlobalStates.overviewOpen
                        }
                    }
                }
            }
        }

        DockPreview {
            id: preview

            dockWindow: win
            dockContent: content
        }
    }

    component Separator: StyledRect {
        property real itemSize: 48

        Layout.alignment: Qt.AlignVCenter
        Layout.leftMargin: Tokens.spacing.extraSmall
        Layout.rightMargin: Tokens.spacing.extraSmall
        implicitWidth: 1
        implicitHeight: itemSize * 0.5
        color: Colours.palette.m3outlineVariant
    }

    component DockApp: Item {
        id: app

        required property var modelData // end-4 TaskbarAppEntry { appId, toplevels, pinned }
        required property real itemSize
        required property DockPreview dockPreview
        readonly property string appId: modelData.appId
        readonly property bool isSeparator: appId === "SEPARATOR"
        readonly property var toplevels: modelData.toplevels
        readonly property bool appActive: toplevels.some(t => t.activated)
        property var entry: DesktopEntries.heuristicLookup(appId)
        property int lastFocused: -1

        function launch(): void {
            if (entry)
                E4.AppLauncher.launch(entry); // caelestia4: own unit under uwsm
            else
                E4.AppLauncher.exec(["sh", "-c", app.appId]);
        }

        Layout.alignment: Qt.AlignVCenter
        implicitWidth: isSeparator ? 1 + Tokens.spacing.extraSmall * 2 : itemSize
        implicitHeight: itemSize

        Connections {
            target: DesktopEntries

            function onApplicationsChanged(): void {
                app.entry = DesktopEntries.heuristicLookup(app.appId);
            }
        }

        // Separator between pinned and running apps (end-4 TaskbarApps inserts it)
        StyledRect {
            visible: app.isSeparator
            anchors.centerIn: parent
            implicitWidth: 1
            implicitHeight: app.itemSize * 0.5
            color: Colours.palette.m3outlineVariant
        }

        StyledRect {
            visible: !app.isSeparator
            anchors.fill: parent
            radius: Tokens.rounding.medium
            color: app.appActive ? Qt.alpha(Colours.palette.m3primary, 0.12) : "transparent"

            StateLayer {
                id: layer

                radius: Tokens.rounding.medium
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onContainsMouseChanged: {
                    if (containsMouse) {
                        app.dockPreview.hoveredApp = app;
                        app.lastFocused = app.toplevels.length - 1;
                    } else if (app.dockPreview.hoveredApp === app) {
                        app.dockPreview.hoveredApp = null;
                    }
                }

                onClicked: event => {
                    if (event.button === Qt.MiddleButton) {
                        app.launch();
                    } else if (event.button === Qt.RightButton) {
                        E4.TaskbarApps.togglePin(app.appId);
                    } else if (app.toplevels.length === 0) {
                        app.launch();
                    } else {
                        app.lastFocused = (app.lastFocused + 1) % app.toplevels.length;
                        app.toplevels[app.lastFocused].activate();
                    }
                }
            }

            IconImage {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -Tokens.padding.extraSmall / 2
                implicitSize: root.cfg.iconSize
                asynchronous: true
                source: Quickshell.iconPath(E4.AppSearch.guessIcon(app.appId), "image-missing")
            }

            // Open-window dots (max 3), primary when the app is focused
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                spacing: 3

                Repeater {
                    model: Math.min(app.toplevels.length, 3)

                    StyledRect {
                        implicitWidth: app.toplevels.length <= 3 ? 8 : 4
                        implicitHeight: 4
                        radius: Tokens.rounding.full
                        color: app.appActive ? Colours.palette.m3primary : Colours.palette.m3outline
                    }
                }
            }

            ToolTip.visible: layer.containsMouse && app.toplevels.length === 0
            ToolTip.delay: 500
            ToolTip.text: (app.entry?.name ?? app.appId) + (app.modelData.pinned ? Tr.tr(" · right-click to unpin") : Tr.tr(" · right-click to pin"))
        }
    }
}
