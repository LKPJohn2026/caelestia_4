pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common
import "AppSearch.js" as AppSearch

PageBase {
    id: root

    title: Tr.tr("All apps")
    isSubPage: true

    // caelestia4: every installed app by name; the search field below filters it (AppSearch.js)
    readonly property var allApps: [...DesktopEntries.applications.values].sort((a, b) => a.name.localeCompare(b.name))
    readonly property var shownApps: AppSearch.filter(allApps, searchField.text)

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.extraSmall / 2

        // caelestia4: filters by name, generic name, keywords and description, ignoring case and accents
        SearchBar {
            id: searchField

            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.medium

            placeholderText: Tr.tr("Search apps")
            font: Tokens.font.body.medium
            bg.color: Colours.tPalette.m3surfaceContainerLowest
            bg.border.color: Colours.palette.m3outlineVariant

            Accessible.name: Tr.tr("Search apps")

            // caelestia4: Esc clears the text; with no text it goes on to Nexus (leave the field, then back)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape && text.length > 0) {
                    clear();
                    event.accepted = true;
                } else {
                    event.accepted = false;
                }
            }
        }

        // caelestia4: empty state while the search matches nothing
        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.padding.large
            visible: searchField.text.trim().length > 0 && root.shownApps.length === 0
            spacing: Tokens.spacing.small

            MaterialIcon {
                Layout.alignment: Qt.AlignHCenter
                text: "search_off"
                color: Colours.palette.m3outline
                fontStyle: Tokens.font.icon.large
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("No apps match “%1”").arg(searchField.text.trim())
                font: Tokens.font.body.medium
            }

            StyledText {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: Tr.tr("Try the app's name, or what it does, such as “browser”.")
                color: Colours.palette.m3outline
                font: Tokens.font.label.medium
            }
        }

        Repeater {
            id: list

            model: root.shownApps

            ConnectedRect {
                id: appItem

                required property DesktopEntry modelData
                required property int index

                Layout.fillWidth: true
                first: index === 0
                last: index === list.count - 1
                implicitHeight: appRow.implicitHeight + appRow.anchors.margins * 2

                StateLayer {
                    onClicked: {
                        root.nState.selectedApp = appItem.modelData;
                        root.nState.openSubPage("info");
                    }
                }

                RowLayout {
                    id: appRow

                    anchors.fill: parent
                    anchors.margins: Tokens.padding.medium
                    anchors.leftMargin: Tokens.padding.largeIncreased
                    anchors.rightMargin: Tokens.padding.largeIncreased
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

                    // caelestia4: hidden from the launcher (still listed here, so it can be shown again)
                    MaterialIcon {
                        visible: Strings.testRegexList(GlobalConfig.launcher.hiddenApps, appItem.modelData.id)
                        text: "visibility_off"
                        color: Colours.palette.m3outline
                        fontStyle: Tokens.font.icon.small
                    }

                    MaterialIcon {
                        visible: Strings.testRegexList(GlobalConfig.launcher.favouriteApps, appItem.modelData.id)
                        text: "favorite"
                        fill: 1
                        color: Colours.palette.m3primary
                        fontStyle: Tokens.font.icon.small
                    }

                    MaterialIcon {
                        text: "chevron_right"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.medium
                    }
                }
            }
        }
    }
}
