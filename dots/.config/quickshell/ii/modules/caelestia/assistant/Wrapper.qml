// caelestia4: the Assistant drawer. end-4's left-sidebar content (AI chat, Translator, optional Anime)
// hosted in a Caelestia drawer that slides out of the frame next to the bar (like Caelestia's right sidebar).
// The drawer surface/shape comes from ContentWindow's blob (PanelBg "assistantBg"); the content keeps
// end-4's widgets, which already use the same Material You palette (end-4 Appearance = Colours adapter source).
// Opened by end-4's keys (Super+A/B/O via KeybindBridge). Esc or clicking outside closes it.
// Ctrl+O toggles the wide width (end-4's sidebarWidthExtended). Ctrl+D (or Super+Alt+A) detaches it into a window
// (DetachedWindow.qml).
pragma ComponentBehavior: Bound

import QtQuick
import Caelestia
import Caelestia.Config
import qs.modules.caelestia.components
import qs as E4G // caelestia4: keep (GlobalStates)
import qs.modules.common as E4C // caelestia4: keep

Item {
    id: root

    required property ScreenState screenState

    property bool extended: false
    readonly property bool shouldBeActive: screenState.assistant
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.leftMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: extended ? E4C.Appearance.sizes.sidebarWidthExtended : E4C.Appearance.sizes.sidebarWidth
    opacity: 1 - offsetScale

    onShouldBeActiveChanged: {
        if (shouldBeActive)
            Qt.callLater(() => content.item?.focusActiveItem());
    }

    Behavior on offsetScale {
        Anim {}
    }

    Behavior on implicitWidth {
        Anim {}
    }

    Loader {
        id: content

        anchors.fill: parent
        anchors.topMargin: Tokens.padding.large
        anchors.bottomMargin: Tokens.padding.large
        anchors.rightMargin: Tokens.padding.large
        anchors.leftMargin: CUtils.clamp(Tokens.padding.large - Config.border.thickness, 0, Tokens.padding.large)

        active: root.shouldBeActive || root.visible
        focus: root.shouldBeActive

        sourceComponent: SidebarLeftContent {
            scopeRoot: root
        }

        Keys.onEscapePressed: root.screenState.assistant = false
        Keys.onPressed: event => {
            if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_O) {
                root.extended = !root.extended;
                event.accepted = true;
            } else if (event.modifiers === Qt.ControlModifier && event.key === Qt.Key_D) {
                E4G.GlobalStates.assistantDetached = true;
                event.accepted = true;
            }
        }
    }
}
