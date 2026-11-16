import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4 settings)

PageBase {
    id: root

    // caelestia4: the rows' live summaries ("Enabled · 5 tabs · shows on hover")
    function status(on: bool): string {
        return on ? Tr.trCtx("Enabled", "panel status") : Tr.trCtx("Disabled", "panel status");
    }

    function summary(parts: var): string {
        return parts.filter(p => p).join(" · ");
    }

    readonly property string hoverText: Tr.tr("shows on hover")
    readonly property int dashboardTabs: [Config.dashboard.showDashboard, Config.dashboard.showMedia, Config.dashboard.showPerformance, Config.dashboard.showWeather, E4C.Config.options.caelestia.dashboardTodo, E4C.Config.options.caelestia.dashboardTimer].filter(t => t).length

    title: Tr.tr("Panels")

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        NavRow {
            icon: "dashboard"
            text: Tr.tr("Dashboard")
            subtext: Config.dashboard.enabled ? root.summary([root.status(true), Tr.trN("%n tab", "%n tabs", root.dashboardTabs), Config.dashboard.showOnHover && !E4C.Config.options.background.presetsEnabled ? root.hoverText : ""]) : root.status(false)
            onClicked: root.nState.openSubPage("dashboard")
        }

        NavRow {
            icon: "dock_to_bottom"
            text: Tr.tr("Taskbar")
            subtext: root.summary([Config.bar.persistent ? Tr.tr("Always visible") : Config.bar.showOnHover ? Tr.tr("Reveal on hover") : Tr.tr("Reveal on drag"), Tr.trN("%n item", "%n items", Config.bar.entries.values.filter(e => e.enabled).length)])
            onClicked: root.nState.openSubPage("taskbar")
        }

        NavRow {
            icon: "apps"
            text: Tr.tr("Launcher")
            subtext: root.summary([root.status(Config.launcher.enabled), Config.launcher.enabled && Config.launcher.showOnHover ? root.hoverText : ""])
            onClicked: root.nState.openSubPage("launcher")
        }

        NavRow {
            icon: "dock_to_right"
            text: Tr.tr("Sidebar")
            subtext: root.summary([root.status(Config.sidebar.enabled), Config.sidebar.enabled && Config.sidebar.showOnHover ? root.hoverText : ""])
            onClicked: root.nState.openSubPage("sidebar")
        }

        // caelestia4: no toggle count: the card's buttons also come from end-4's extras and the saved drawer layout
        NavRow {
            icon: "construction"
            text: Tr.tr("Utilities")
            subtext: root.summary([root.status(Config.utilities.enabled), Config.utilities.enabled && Config.utilities.cards.quickToggles ? Tr.tr("Quick toggles") : ""])
            onClicked: root.nState.openSubPage("utilities")
        }

        NavRow {
            icon: "neurology"
            text: Tr.tr("Assistant")
            subtext: {
                switch (E4C.Config.options.policies.ai) {
                case 1:
                    return Tr.tr("AI on");
                case 2:
                    return Tr.tr("Local AI models only");
                }
                return Tr.tr("AI off");
            }
            onClicked: root.nState.openSubPage("assistant")
        }

        NavRow {
            icon: "grid_view"
            text: Tr.tr("Overview & overlay")
            // TRANSLATORS: %1 rows by %2 columns of workspaces in the overview
            subtext: root.summary([Tr.tr("Alt+Tab, Super+G"), Tr.tr("%1×%2 grid").arg(E4C.Config.options.overview.rows).arg(E4C.Config.options.overview.columns)])
            onClicked: root.nState.openSubPage("overview")
        }

        NavRow {
            icon: "keyboard"
            text: Tr.tr("Keybind cheatsheet")
            subtext: "Super+/"
            onClicked: root.nState.openSubPage("cheatsheet")
        }

        NavRow {
            icon: "tune"
            text: Tr.tr("On-screen display")
            subtext: root.summary([root.status(Config.osd.enabled), Config.osd.enabled ? Tr.tr("hides after %1 s").arg(Math.round(Config.osd.hideDelay / 100) / 10) : ""])
            onClicked: root.nState.openSubPage("osd")
        }

        NavRow {
            icon: "power_settings_new"
            text: Tr.tr("Session menu")
            subtext: root.status(Config.session.enabled)
            onClicked: root.nState.openSubPage("session")
        }

        // caelestia4: options for all panels, not one (they were on the taskbar page)
        SectionHeader {
            text: Tr.tr("General")
        }

        ToggleRow {
            setting: "c:general.showOverFullscreen"
        }

        // caelestia4: "caelestia" and icon names are not files: save what is typed. Empty shows the distro's logo
        PathRow {
            setting: "c:general.logo"
            mustExist: false
            hint: Tr.tr("Distro logo")
        }
    }
}
