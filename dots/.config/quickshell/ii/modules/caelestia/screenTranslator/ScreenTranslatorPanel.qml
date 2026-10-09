pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.utils as E4U // caelestia4: keep
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters
import qs.modules.caelestia.regionSelector as CRegion

// caelestia4: end-4's ScreenTranslatorPanel in Caelestia style. Frozen screen with the translated text on top;
// drag to pan, scroll to zoom. Status / error card at the top, floating toolbar at the bottom: service account
// key (paste the JSON, Enter), reset zoom, close. Esc closes.
PanelWindow {
    id: root

    signal dismiss

    visible: false
    color: "black"
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

    readonly property string screenshotDir: E4C.Directories.screenshotTemp
    readonly property string screenshotPath: `${root.screenshotDir}/image-${screen.name}`
    property bool screenshotReady: false
    property bool keyFieldOpen: false

    // Pan / zoom
    property real scale: 1.0
    property real contentX: 0
    property real contentY: 0

    function resetView(): void {
        scale = 1;
        contentX = 0;
        contentY = 0;
    }

    function submitKey(): void {
        if (E4.GoogleCloud.setKeyJson(keyInput.text)) {
            keyInput.text = "";
            root.keyFieldOpen = false;
        } else {
            keyShake.restart();
        }
    }

    E4U.TempScreenshotProcess {
        running: true
        screen: root.screen
        screenshotDir: root.screenshotDir
        screenshotPath: root.screenshotPath
        onExited: (_, __) => {
            root.visible = true;
            root.screenshotReady = true;
        }
    }

    MouseArea {
        anchors.fill: parent
        clip: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real lastX: 0
        property real lastY: 0

        onPressed: mouse => {
            lastX = mouse.x;
            lastY = mouse.y;
        }
        onPositionChanged: mouse => {
            if (!pressed)
                return;
            root.contentX += mouse.x - lastX;
            root.contentY += mouse.y - lastY;
            lastX = mouse.x;
            lastY = mouse.y;
        }
        onWheel: event => {
            const oldScale = root.scale;
            const newScale = Math.min(Math.max(0.1, oldScale * (event.angleDelta.y > 0 ? 1.1 : 0.9)), 5);
            if (newScale === oldScale)
                return;
            // keep the point under the cursor in place
            const localX = (event.x - root.contentX) / oldScale;
            const localY = (event.y - root.contentY) / oldScale;
            root.scale = newScale;
            root.contentX = event.x - localX * newScale;
            root.contentY = event.y - localY * newScale;
        }

        // Frozen screen: the screenshot already taken for the translation (a static ScreencopyView can come up
        // black on the first open after a shell start)
        Image {
            width: parent.width
            height: parent.height
            x: root.contentX
            y: root.contentY
            scale: root.scale
            transformOrigin: Item.TopLeft
            source: root.screenshotReady ? `file://${root.screenshotPath}` : ""
            sourceSize.width: root.screen.width * (Hyprland.monitorFor(root.screen)?.scale ?? 1)
            cache: false
            smooth: true
            mipmap: true
        }

        Loader {
            id: overlayLoader

            width: parent.width * root.scale
            height: parent.height * root.scale
            x: root.contentX
            y: root.contentY
            active: root.screenshotReady
            sourceComponent: ScreenTextOverlay {
                screenshotPath: root.screenshotPath
                scaleFactor: root.scale
            }
        }

        // Dim while working / on error
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            opacity: (overlayLoader.item?.loading ?? true) ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                Anim {
                    type: Anim.DefaultEffects
                }
            }
        }
    }

    // Status / error card
    StyledRect {
        id: statusCard

        readonly property bool error: overlayLoader.item?.error ?? false
        readonly property bool shown: root.visible && (overlayLoader.item?.loading ?? true)

        anchors.centerIn: parent
        implicitWidth: error ? 520 : statusRow.implicitWidth + Tokens.padding.extraLarge * 2
        implicitHeight: (error ? errorCol.implicitHeight : statusRow.implicitHeight) + Tokens.padding.extraLarge * 2
        radius: Tokens.rounding.extraLarge
        color: Colours.tPalette.m3surface
        opacity: shown ? 1 : 0
        scale: shown ? 1 : 0.9
        visible: opacity > 0

        Behavior on opacity {
            Anim {
                type: Anim.DefaultEffects
            }
        }
        Behavior on scale {
            Anim {
                type: Anim.DefaultSpatial
            }
        }

        Elevation {
            anchors.fill: parent
            radius: parent.radius
            z: -1
            level: 3
        }

        RowLayout {
            id: statusRow

            anchors.centerIn: parent
            visible: !statusCard.error
            spacing: Tokens.spacing.large

            LoadingIndicator {
                implicitWidth: 48
                implicitHeight: 48
            }

            ColumnLayout {
                spacing: 0

                StyledText {
                    text: Tr.tr("Screen translator")
                    font: Tokens.font.title.medium
                }

                StyledText {
                    text: overlayLoader.item?.statusText ?? Tr.tr("Taking a screenshot")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.medium
                }
            }
        }

        ColumnLayout {
            id: errorCol

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Tokens.padding.extraLarge
            visible: statusCard.error
            spacing: Tokens.spacing.medium

            StyledRect {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                radius: Tokens.rounding.full
                color: Colours.palette.m3errorContainer

                MaterialIcon {
                    anchors.centerIn: parent
                    text: "translate"
                    color: Colours.palette.m3onErrorContainer
                    fontStyle: Tokens.font.icon.large
                }
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: Tr.tr("Screen translator")
                font: Tokens.font.title.large
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: overlayLoader.item?.errorMessage || Tr.tr("Set your Google Cloud service account key")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                text: Tr.tr("It needs a service account key with the Cloud Vision and Cloud Translation APIs enabled. Paste the key's JSON with the key button below.")
                color: Colours.palette.m3outline
                font: Tokens.font.body.small
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.small

                TextButton {
                    type: TextButton.Text
                    text: Tr.tr("Setup guide")
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.medium
                    onClicked: {
                        Qt.openUrlExternally(overlayLoader.item.wikiLink);
                        root.dismiss();
                    }
                }

                TextButton {
                    type: TextButton.Filled
                    text: Tr.tr("Set key")
                    horizontalPadding: Tokens.padding.large
                    verticalPadding: Tokens.padding.medium
                    onClicked: {
                        root.keyFieldOpen = true;
                        keyInput.forceActiveFocus();
                    }
                }
            }
        }
    }

    // Toolbar
    StyledRect {
        id: toolbar

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.visible ? Tokens.padding.extraLarge : -height
        implicitWidth: toolRow.implicitWidth + Tokens.padding.small * 2
        implicitHeight: toolRow.implicitHeight + Tokens.padding.small * 2
        radius: Tokens.rounding.full
        color: Colours.tPalette.m3surfaceContainer
        focus: root.visible

        Keys.onEscapePressed: root.dismiss()

        Behavior on anchors.bottomMargin {
            Anim {
                type: Anim.DefaultSpatial
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
            id: toolRow

            anchors.centerIn: parent
            spacing: Tokens.spacing.extraSmall

            CRegion.ToolChip {
                icon: "key"
                text: root.keyFieldOpen ? "" : Tr.tr("Key")
                checked: root.keyFieldOpen
                onClicked: {
                    root.keyFieldOpen = !root.keyFieldOpen;
                    if (root.keyFieldOpen)
                        keyInput.forceActiveFocus();
                    else
                        toolbar.forceActiveFocus();
                }
            }

            // Key JSON field
            StyledRect {
                id: keyPill

                Layout.preferredWidth: root.keyFieldOpen ? 460 : 0
                implicitHeight: 44
                visible: Layout.preferredWidth > 0
                clip: true
                radius: Tokens.rounding.full
                color: Colours.palette.m3surfaceContainerHigh
                border.width: keyInput.activeFocus ? 2 : 0
                border.color: Colours.palette.m3primary

                transform: Translate {
                    id: keyShakeOffset
                }

                Behavior on Layout.preferredWidth {
                    Anim {
                        type: Anim.DefaultSpatial
                    }
                }

                SequentialAnimation {
                    id: keyShake

                    NumberAnimation {
                        target: keyShakeOffset
                        property: "x"
                        to: -10
                        duration: 50
                    }
                    NumberAnimation {
                        target: keyShakeOffset
                        property: "x"
                        to: 8
                        duration: 70
                    }
                    NumberAnimation {
                        target: keyShakeOffset
                        property: "x"
                        to: 0
                        duration: 60
                    }
                }

                TextInput {
                    id: keyInput

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Tokens.padding.large
                    anchors.rightMargin: Tokens.padding.large
                    clip: true
                    color: Colours.palette.m3onSurface
                    selectionColor: Qt.alpha(Colours.palette.m3primary, 0.4)
                    font: Tokens.font.body.medium
                    echoMode: TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    onAccepted: root.submitKey()
                    Keys.onEscapePressed: {
                        root.keyFieldOpen = false;
                        toolbar.forceActiveFocus();
                    }

                    StyledText {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: keyInput.text.length === 0
                        text: Tr.tr("Paste the service account key JSON")
                        color: Colours.palette.m3outline
                        font: Tokens.font.body.medium
                    }
                }
            }

            CRegion.ToolChip {
                visible: root.keyFieldOpen
                icon: "check"
                checked: keyInput.text.length > 0
                onClicked: root.submitKey()
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

            StyledText {
                Layout.rightMargin: Tokens.spacing.small
                visible: !root.keyFieldOpen
                text: root.scale === 1 ? Tr.tr("Drag to pan • scroll to zoom") : `${Math.round(root.scale * 100)}%`
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
            }

            CRegion.ToolChip {
                visible: root.scale !== 1 || root.contentX !== 0 || root.contentY !== 0
                icon: "fit_screen"
                onClicked: root.resetView()
            }

            CRegion.ToolChip {
                icon: "close"
                onClicked: root.dismiss()
            }
        }
    }
}
