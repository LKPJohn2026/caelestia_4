import Quickshell
import Quickshell.Wayland
import Caelestia.Config
import qs.modules.caelestia.components

// qmllint disable uncreatable-type
PanelWindow {
    // qmllint enable uncreatable-type
    id: styledWindow

    required property string name

    // caelestia4: the screen's name for the per-screen config, kept while Qt has the window on its nameless placeholder
    // screen (the output went; see ScreenName). Popups of this window use it too.
    readonly property string configScreen: configScreenName.name
    readonly property ScreenName configScreenName: ScreenName {
        window: styledWindow
    }

    WlrLayershell.namespace: `caelestia-${name}`
    color: "transparent"

    contentItem.Config.screen: configScreen
    contentItem.Tokens.screen: configScreen
}
