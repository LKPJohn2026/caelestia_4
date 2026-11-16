pragma ComponentBehavior: Bound

import QtQuick.Layouts
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    // caelestia4: the sub-page rows' live summaries
    function summary(parts: var, empty: string): string {
        const shown = parts.filter(p => p);
        return shown.length ? shown.join(" · ") : empty;
    }

    readonly property string workspaceStyle: {
        switch (Config.bar.workspaces.displayType) {
        case BarWorkspaceDisplay.Text:
            return Tr.tr("Numbers");
        case BarWorkspaceDisplay.Icons:
            return Tr.tr("Icons");
        }
        return Tr.tr("Shapes");
    }

    title: Tr.tr("Taskbar")
    isSubPage: true

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        SectionHeader {
            text: Tr.tr("Behaviour")
        }

        ToggleRow {
            setting: "c:bar.persistent"
        }

        ToggleRow {
            setting: "c:bar.showOnHover"
        }

        StepperRow {
            setting: "c:bar.dragThreshold"
        }

        // caelestia4: saved names are regexes; typed ones that match no screen stay listed until unticked
        MultiSelectRow {
            setting: "c:bar.excludedScreens"
            options: Quickshell.screens.map(s => ({
                        value: s.name,
                        label: s.model ? `${s.name} (${s.model})` : s.name
                    }))
        }

        SectionHeader {
            text: Tr.tr("Components")
        }

        NavRow {
            icon: "view_agenda"
            text: Tr.tr("Layout")
            subtext: Tr.trN("%n item shown", "%n items shown", Config.bar.entries.values.filter(e => e.enabled).length)
            onClicked: root.nState.openSubPage("barLayout")
        }

        NavRow {
            icon: "workspaces"
            text: Tr.tr("Workspaces")
            subtext: root.summary([Tr.trN("%n workspace", "%n workspaces", Config.bar.workspaces.shown), root.workspaceStyle, Config.bar.workspaces.showWindows ? Tr.tr("window icons") : ""], "")
            onClicked: root.nState.openSubPage("workspaces")
        }

        NavRow {
            icon: "web_asset"
            text: Tr.tr("Active window")
            subtext: root.summary([Config.bar.activeWindow.showTitle ? Tr.tr("Title and icon") : Tr.tr("Icon only"), Config.bar.popouts.activeWindow ? Tr.tr("popout on hover") : ""], "")
            onClicked: root.nState.openSubPage("activeWindow")
        }

        NavRow {
            icon: "widgets"
            text: Tr.tr("Tray")
            subtext: root.summary([Config.bar.tray.compact ? Tr.trCtx("Compact", "taskbar tray layout") : "", Config.bar.tray.recolour ? Tr.tr("Recolour icons") : ""], Tr.tr("System tray icons"))
            onClicked: root.nState.openSubPage("tray")
        }

        NavRow {
            icon: "signal_cellular_alt"
            text: Tr.tr("Status icons")
            subtext: Tr.trN("%n icon shown", "%n icons shown", Config.bar.statusIcons.values.filter(e => e.enabled).length)
            onClicked: root.nState.openSubPage("statusIcons")
        }

        NavRow {
            icon: "schedule"
            text: Tr.tr("Clock")
            // TRANSLATORS: what the taskbar clock shows, e.g. "Time and date · seconds · icon"
            subtext: root.summary([Config.bar.clock.showDate ? Tr.tr("Time and date") : Tr.tr("Time only"), Config.bar.clock.showSeconds ? Tr.tr("seconds") : "", Config.bar.clock.showIcon ? Tr.tr("icon") : ""], "")
            onClicked: root.nState.openSubPage("clock")
        }

        SectionHeader {
            text: Tr.tr("Scroll actions")
        }

        ToggleRow {
            setting: "c:bar.scrollActions.workspaces"
        }

        ToggleRow {
            setting: "c:bar.scrollActions.volume"
        }

        ToggleRow {
            setting: "c:bar.scrollActions.brightness"
        }
    }
}
