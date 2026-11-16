pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import Caelestia.Models
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.filedialog
import qs.modules.caelestia.adapters
import qs.modules.caelestia.utils
import qs.modules.caelestia.nexus.common

// caelestia4: the Wallpapers sub-page (route appearance/wallpapers). A folder with no pictures shows where it looked and
// how to pick another folder; the grid's columns are the last row
PageBase {
    id: root

    title: Tr.tr("Wallpapers")
    isSubPage: true

    // caelestia4: the grid's pictures (one per category folder), before the empty places that keep the columns' width
    readonly property var localList: {
        const walls = Wallpapers.list;
        const baseDir = Paths.wallsdir;
        const categories = {};
        const list = [];
        for (const w of walls) {
            if (w.parentDir !== baseDir) {
                const category = Wallpapers.getCategoryFor(w);
                if (category && (!(category in categories) || categories[category].name.localeCompare(w.name) > 0))
                    categories[category] = w;
            } else {
                list.push(w);
            }
        }
        list.push(...Object.values(categories));
        list.sort((a, b) => ((a.parentDir === baseDir) - (b.parentDir === baseDir)) || a.name.localeCompare(b.name));
        return list;
    }
    readonly property Setting folderSetting: Setting {
        sid: "c:paths.wallpaperDir"
    }

    // caelestia4: whether the folder is there at all, so the empty state doesn't say "put pictures there" about a
    // folder that doesn't exist. A property: PageBase's default property takes the page's one content item
    property bool folderExists: true
    readonly property Process folderCheck: Process {
        command: ["test", "-d", Paths.wallsdir]
        onExited: code => root.folderExists = code === 0
    }

    function checkFolder(): void {
        root.folderCheck.running = false;
        root.folderCheck.running = true;
    }

    readonly property string wallsdir: Paths.wallsdir

    onWallsdirChanged: checkFolder()
    Component.onCompleted: checkFolder()

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: Tokens.spacing.small

        ButtonRow {
            Layout.bottomMargin: Tokens.spacing.medium
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.small

            IconTextButton {
                icon: "photo_library"
                text: Tr.tr("Browse")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                onClicked: browseDialog.open()

                FileDialog {
                    id: browseDialog

                    title: Tr.tr("Select an image")
                    filterLabel: Tr.tr("Image files")
                    filters: Images.validImageExtensions
                    onAccepted: path => {
                        Wallpapers.setWallpaper(path);
                        root.nState.closeSubPage();
                    }
                }
            }

            IconTextButton {
                icon: "shuffle"
                text: Tr.tr("Random")
                font: Tokens.font.body.large
                isRound: true
                shapeMorph: true
                horizontalPadding: Tokens.padding.extraLarge
                verticalPadding: Tokens.padding.medium
                type: IconTextButton.Tonal
                onClicked: {
                    Wallpapers.setRandom();
                    root.nState.closeSubPage();
                }
            }
        }

        WallItem {
            imgHeight: Math.round(width * 0.3)
            radius: Tokens.rounding.extraLarge
            source: Wallpapers.fallback /* caelestia4: assets live under modules/caelestia */
            text: Tr.tr("Featured wallpaper")
            fillLabel: false
            onClicked: {
                Wallpapers.setWallpaper(Wallpapers.fallback /* caelestia4: assets live under modules/caelestia */);
                root.nState.closeSubPage();
            }
        }

        StyledText {
            Layout.topMargin: Tokens.spacing.large
            text: Tr.tr("Local wallpapers")
            font: Tokens.font.title.small
        }

        GridLayout {
            Layout.fillWidth: true
            visible: root.localList.length > 0

            columns: Config.nexus.wallpapersPerRow
            rowSpacing: Tokens.spacing.medium
            columnSpacing: Tokens.spacing.large

            Repeater {
                id: localWalls

                model: {
                    const list = root.localList.slice();
                    while (list.length < Config.nexus.wallpapersPerRow)
                        list.push(null);
                    return list;
                }

                WallItem {
                    required property FileSystemEntry modelData

                    // Empty placeholders for sizing
                    opacity: modelData ? 1 : 0
                    enabled: modelData

                    source: String(modelData?.path ?? "")
                    text: {
                        if (!modelData)
                            return "";

                        if (modelData.parentDir !== Paths.wallsdir) {
                            const category = Wallpapers.getCategoryFor(modelData);
                            return category.slice(0, 1).toUpperCase() + category.slice(1);
                        }
                        return modelData.name;
                    }
                    onClicked: {
                        if (modelData.parentDir !== Paths.wallsdir) {
                            root.nState.selectedWallpaperCategory = Wallpapers.getCategoryFor(modelData);
                            root.nState.openSubPage("category");
                        } else {
                            Wallpapers.setWallpaper(modelData.path);
                            root.nState.closeSubPage();
                        }
                    }
                }
            }
        }

        // caelestia4: no pictures in the folder: which folder, and a way to pick another (here, or on Wallpaper options)
        StyledRect {
            Layout.fillWidth: true
            visible: root.localList.length === 0
            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.extraLarge
            implicitHeight: noWallsLayout.implicitHeight + Tokens.padding.extraExtraLarge * 2

            ColumnLayout {
                id: noWallsLayout

                anchors.centerIn: parent
                width: parent.width - Tokens.padding.extraLarge * 2
                spacing: Tokens.spacing.small

                MaterialIcon {
                    Layout.alignment: Qt.AlignHCenter
                    text: "hide_image"
                    color: Colours.palette.m3outline
                    fontStyle: Tokens.font.icon.extraLarge
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    // TRANSLATORS: %1 = a folder, e.g. ~/Pictures/Wallpapers
                    text: root.folderExists ? Tr.tr("No wallpapers in %1").arg(Paths.shortenHome(Paths.wallsdir)) : Tr.tr("The folder %1 doesn't exist").arg(Paths.shortenHome(Paths.wallsdir))
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.title.small
                    wrapMode: Text.WordWrap
                }

                StyledText {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.folderExists ? Tr.tr("Put pictures there, or choose the folder that has them") : Tr.tr("Choose the folder that has your wallpapers")
                    color: Colours.palette.m3outline
                    font: Tokens.font.label.medium
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Tokens.spacing.small
                    Layout.maximumWidth: noWallsLayout.width
                    spacing: Tokens.spacing.small

                    IconTextButton {
                        icon: "folder_open"
                        text: Tr.tr("Choose a folder")
                        isRound: true
                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.small
                        onClicked: folderDialog.openAt(Paths.wallsdir)
                    }

                    IconTextButton {
                        icon: "photo_library"
                        text: Tr.tr("Wallpaper options")
                        isRound: true
                        type: IconTextButton.Tonal
                        horizontalPadding: Tokens.padding.large
                        verticalPadding: Tokens.padding.small
                        onClicked: root.nState.navigate("appearance/sources#c:paths.wallpaperDir")
                    }
                }
            }

            FolderPickerDialog {
                id: folderDialog

                title: Tr.tr("Wallpaper folder")
                onPicked: path => root.folderSetting.set(path)
            }
        }

        // caelestia4: the grid's columns (registry/RegAppearance.qml): one plain row, no Advanced section for it
        RowGroup {
            Layout.fillWidth: true
            Layout.topMargin: Tokens.spacing.large

            StepperRow {
                setting: "c:nexus.wallpapersPerRow"
            }
        }
    }
}
