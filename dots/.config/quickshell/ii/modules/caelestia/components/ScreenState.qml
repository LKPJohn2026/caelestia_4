import Quickshell

PersistentProperties {
    required property ShellScreen modelData

    // Drawer visibilities
    property bool bar
    property bool osd
    property bool session
    property bool launcher
    property bool dashboard
    property bool utilities
    property bool sidebar
    property bool assistant // caelestia4: end-4 AI/translator drawer (left)
    property bool barHidden // caelestia4: Super+J (end-4 barToggle) hides the persistent bar; hovering the edge still reveals it

    // Dashboard state
    property int dashboardTab
    property int dashboardTabCount // caelestia4: set by the dashboard, for the dashNext / dashPrev shortcuts
    property date dashboardDate: new Date()
}
