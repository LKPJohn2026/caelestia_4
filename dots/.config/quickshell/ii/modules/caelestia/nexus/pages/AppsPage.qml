pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Caelestia
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common

PageBase {
    id: root

    title: Tr.tr("Apps")

    // caelestia4: ~/.config/xdg-terminals.list, first entry = the default terminal (a property: PageBase's default
    // property takes the page's one content item)
    readonly property FileView terminalList: FileView {
        property string current

        path: `${Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config"}/xdg-terminals.list`
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.terminalList.current = text().split("\n").map(l => l.trim()).find(l => l && !l.startsWith("#")) ?? ""
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // Default applications
        SectionHeader {
            text: Tr.tr("Default applications")
        }

        // caelestia4: each row has its registry id (registry/RegApps.qml): search lands on it, and Media playback and
        // File manager show the modified dot and reset button that match "Reset page". The terminal is a file, not an
        // option (x:apps.terminal), so it has no default to reset to and "Reset page" leaves it alone
        DefaultRow {
            setting: "x:apps.terminal"
            link.s.customValue: root.terminalList.current
            icon: "terminal"
            label: Tr.trCtx("Terminal", "default app category")
            // caelestia4: the terminal the session uses is ~/.config/xdg-terminals.list (uwsm -T: Super+Return, terminal
            // apps, $ commands), as in Settings > Apps; Caelestia's own setting is kept in step
            status: DesktopEntries.applications.values.find(e => `${e.id}.desktop` === root.terminalList.current)?.name ?? (root.terminalList.current || GlobalConfig.general.apps.terminal.join(" "))
            onSelected: app => {
                root.terminalList.setText(`# caelestia4: default terminal (uwsm -T / xdg-terminal-exec). Settings > Apps > Terminal\n${app.id}.desktop\n`);
                GlobalConfig.general.apps.terminal = app.command;
            }
        }

        // caelestia4: no Audio row: general.apps.audio is read by nothing (upstream too)

        DefaultRow {
            setting: "c:general.apps.playback"
            icon: "play_circle"
            label: Tr.trCtx("Media playback", "default app category")
            status: GlobalConfig.general.apps.playback.join(" ")
            onSelected: app => link.set(app.command)
        }

        DefaultRow {
            setting: "c:general.apps.explorer"
            icon: "folder"
            label: Tr.trCtx("File manager", "default app category")
            status: GlobalConfig.general.apps.explorer.join(" ")
            onSelected: app => link.set(app.command)
        }

        // caelestia4: end-4's task manager command (session menu, Ctrl+Shift+Esc), from end-4's Settings app. With the
        // other default apps, not under a "Task manager" header that repeats the row
        TextFieldRow {
            setting: "e4:apps.taskManager"
        }

        // Library
        SectionHeader {
            text: Tr.trCtx("Library", "app library")
        }

        NavRow {
            icon: "apps"
            text: Tr.tr("All apps")
            subtext: Tr.tr("Browse installed apps, set favourites and hidden")
            onClicked: root.nState.openSubPage("all")
        }

    }

    component DefaultRow: PopupRow {
        id: row

        readonly property int popupHeight: root.flickable.height - y + root.flickable.contentY - Tokens.padding.large - Tokens.padding.extraExtraLarge

        // caelestia4: a registry id, as on the other rows: the page lands on the row and pulses it, and the row shows
        // the modified dot and reset button left of the popup button. PopupRow has no `setting` of its own, so these
        // are added here (not as children: PopupRow's default property is the popup's content)
        property string setting
        readonly property RowSetting link: RowSetting {
            sid: row.setting
            row: row
            screen: row.Config.screen
        }
        readonly property SettingMarks marks: SettingMarks {
            // x/y, not anchors: anchoring to `row` warns until `parent` is set
            parent: row
            x: row.width - width - Tokens.padding.largeIncreased - row.popup.implicitWidth - Tokens.spacing.medium
            y: (row.height - height) / 2
            link: row.link
            hot: row.activeFocus
        }
        readonly property RowPulse pulse: RowPulse {
            parent: row
            link: row.link
        }

        // caelestia4: keyboard choice in the open list (PopupRow only opens and closes it): Up/Down move the
        // highlight, Enter or Space picks the highlighted app, Esc closes. -1 = nothing highlighted yet
        property int kbIndex: -1
        readonly property var apps: {
            const all = [...DesktopEntries.applications.values];
            const favourited = new Set(all.filter(a => Strings.testRegexList(GlobalConfig.launcher.favouriteApps, a.id)));
            return all.sort((a, b) => (favourited.has(b) - favourited.has(a)) || a.name.localeCompare(b.name));
        }

        signal selected(app: DesktopEntry)

        Keys.onPressed: event => {
            if (!row.popup.open || !row.apps.length)
                return;
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                const step = event.key === Qt.Key_Down ? 1 : -1;
                row.kbIndex = row.kbIndex < 0 ? (step > 0 ? 0 : row.apps.length - 1) : Math.max(0, Math.min(row.apps.length - 1, row.kbIndex + step));
                event.accepted = true;
            } else if (row.kbIndex >= 0 && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
                const app = row.apps[row.kbIndex];
                row.popup.open = false;
                row.selected(app);
                event.accepted = true;
            }
        }

        // A property, not a child: PopupRow's default property is the popup's content
        readonly property Connections popupWatch: Connections {
            target: row.popup

            function onOpenChanged(): void {
                row.kbIndex = -1;
            }
        }

        keepPopupAsChild: {
            if (root.nState.animatingContainer || root.opacity < 1)
                return true;

            let p = root.parent;
            while (p && p.objectName !== "PageContainer")
                p = p.parent;
            return p?.opacity < 1;
        }
        // caelestia4: the button that opens the app list
        popup.icon: "swap_horiz"
        popup.tooltip: Tr.trCtx("Change", "button")
        popup.topMovement: Math.max(Tokens.sizes.nexus.minPopupHeight - popupHeight, Tokens.padding.large)

        Loader {
            anchors.centerIn: parent
            active: row.popup.animDriver > 0

            sourceComponent: VerticalFadeListView {
                id: list

                implicitWidth: Tokens.sizes.nexus.popupWidth
                implicitHeight: CUtils.clamp(row.popupHeight, Tokens.sizes.nexus.minPopupHeight, Tokens.sizes.nexus.maxPopupHeight)

                model: row.apps
                currentIndex: row.kbIndex
                onCurrentIndexChanged: {
                    if (currentIndex >= 0)
                        positionViewAtIndex(currentIndex, ListView.Contain);
                }

                delegate: StateLayer {
                    id: appItem

                    required property DesktopEntry modelData
                    required property int index

                    anchors.fill: undefined
                    anchors.left: list.contentItem.left
                    anchors.right: list.contentItem.right
                    implicitHeight: itemLayout.implicitHeight + itemLayout.anchors.margins * 2
                    radius: Tokens.rounding.small
                    manualHoverOverride: index === row.kbIndex

                    onClicked: {
                        row.popup.open = false;
                        row.selected(modelData);
                    }

                    RowLayout {
                        id: itemLayout

                        anchors.fill: parent
                        anchors.margins: Tokens.padding.medium
                        spacing: Tokens.spacing.medium

                        IconImage {
                            asynchronous: true
                            implicitSize: Math.round(Tokens.font.icon.large.pointSize * 1.8)
                            source: Quickshell.iconPath(appItem.modelData.icon, "image-missing")
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            StyledText {
                                Layout.fillWidth: true
                                text: appItem.modelData.name
                                font: Tokens.font.body.small
                                elide: Text.ElideRight
                            }

                            StyledText {
                                Layout.fillWidth: true
                                visible: text
                                text: (appItem.modelData.comment || appItem.modelData.genericName) ?? ""
                                color: Colours.palette.m3outline
                                font: Tokens.font.label.small
                                elide: Text.ElideRight
                            }
                        }

                        MaterialIcon {
                            visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                            text: "favorite"
                            fill: 1
                            color: Colours.palette.m3primary
                            fontStyle: Tokens.font.icon.small
                        }
                    }
                }
            }
        }
    }
}
