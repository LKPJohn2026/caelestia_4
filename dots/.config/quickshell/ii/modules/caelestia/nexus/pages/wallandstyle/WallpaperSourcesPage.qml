pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (random wallpaper settings, the Anime policy)
import qs.services as E4 // caelestia4: keep (HyprlandData: the largest monitor, for random wallpapers)
import Quickshell
import Quickshell.Io

// caelestia4: sub-page of WallpaperAndStyle (route appearance/sources): the wallpaper folder, random wallpapers from the
// internet, the Random transition's pool, fitting to the screen and parallax, most-used first; one Advanced section,
// last. Rows name their registry setting (registry/RegAppearance.qml)
PageBase {
    id: root

    title: Tr.tr("Wallpaper options")
    isSubPage: true

    readonly property WallTransitions wt: WallTransitions {}

    // caelestia4: random wallpaper from the internet (scripts/caelestia4/random-wallpaper.sh), as end-4's Settings app
    // (Appearance): a source, and "at least my screen size" / "my screen's shape" from the largest monitor
    readonly property var rw: E4C.Config.options.caelestia.randomWallpaper
    readonly property var biggestScreen: (E4.HyprlandData.monitors ?? []).reduce((best, m) => (m.width * m.height > best.w * best.h ? {
                w: m.width,
                h: m.height
            } : best), {
        w: 0,
        h: 0
    })
    readonly property string screenRatio: {
        const gcd = (a, b) => b ? gcd(b, a % b) : a;
        const w = biggestScreen.w, h = biggestScreen.h;
        return w > 0 ? `${w / gcd(w, h)}:${h / gcd(w, h)}` : "";
    }
    // Anime sources only while the Anime tab is shown (Panels > Assistant). caelestia4: short names, so the menu leaves
    // the row's description room in a narrow window; what each has is in the description
    readonly property list<MenuItem> randomSourceItems: [
        MenuItem {
            text: Tr.tr("Wallhaven")
            value: "wallhaven"
        },
        MenuItem {
            text: Tr.tr("Konachan")
            value: "konachan"
        },
        MenuItem {
            text: Tr.tr("yande.re")
            value: "yandere"
        }
    ]
    readonly property list<MenuItem> shownSourceItems: E4C.Config.options.policies.weeb === 1 ? randomSourceItems : [randomSourceItems[0]]

    function fetchRandom(): void {
        const source = shownSourceItems.some(i => i.value === rw.source) ? rw.source : "wallhaven";
        const known = biggestScreen.w > 0;
        const size = rw.matchScreen && known ? [String(biggestScreen.w), String(biggestScreen.h)] : ["0", "0"];
        const shape = rw.preferScreenRatio && known ? [String(biggestScreen.w), String(biggestScreen.h)] : [];
        randomWallProc.command = [Quickshell.shellPath("scripts/caelestia4/random-wallpaper.sh"), source, ...size, ...shape];
        randomWallProc.status = "";
        randomWallProc.running = true;
    }

    // A property: PageBase's default property takes the page's one content item
    readonly property Process randomWallProc: Process {
        property string status

        stdout: SplitParser {
            onRead: data => root.randomWallProc.status = data.trim()
        }
    }

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        // caelestia4: the folder the launcher, Wallpapers and end-4's wallpaper selector list (paths.wallpaperDir)
        SectionHeader {
            text: Tr.tr("Your wallpapers")
        }

        PathRow {
            setting: "c:paths.wallpaperDir"
            mode: "folder"
            allowEmpty: false
        }

        SectionHeader {
            text: Tr.tr("From the internet")
        }

        SelectRow {
            setting: "e4:caelestia.randomWallpaper.source"
            menuItems: root.shownSourceItems
            // a hidden anime source shows as Wallhaven, the one fetched then
            active: root.shownSourceItems.find(i => i.value === root.rw.source) ?? root.shownSourceItems[0]
            subtext: E4C.Config.options.policies.weeb === 1 ? Tr.tr("Wallhaven has all kinds of pictures; Konachan and yande.re have anime") : link.desc
        }

        ToggleRow {
            setting: "e4:caelestia.randomWallpaper.matchScreen"
            subtext: root.biggestScreen.w > 0 ? Tr.tr("At least %1 × %2, your largest monitor").arg(root.biggestScreen.w).arg(root.biggestScreen.h) : Tr.tr("At least your monitor's resolution")
        }

        ToggleRow {
            setting: "e4:caelestia.randomWallpaper.preferScreenRatio"
            text: root.screenRatio ? Tr.tr("Prefer my screen's shape (%1)").arg(root.screenRatio) : Tr.tr("Prefer my screen's shape")
        }

        RowButton {
            disabled: root.randomWallProc.running
            icon: root.randomWallProc.running ? "hourglass_top" : "cloud_download"
            text: root.randomWallProc.running ? Tr.tr("Working…") : Tr.tr("Get one")
            subtext: root.randomWallProc.status || Tr.tr("Saved to Wallpapers in your Pictures folder; colours follow")
            onClicked: root.fetchRandom()
        }

        // caelestia4: the Random transition (Wallpaper & style's Transition picker sets it too), not the same one twice
        // in a row, and which transitions it draws from
        SectionHeader {
            text: Tr.tr("Transitions")
        }

        ToggleRow {
            setting: "e4:background.transitionRandom.enable"
        }

        // Its "Turn on “Random transition” first" note is the only one: the pool button under it has none of its own
        ToggleRow {
            setting: "e4:background.transitionRandom.noRepeat"
        }

        // e4:background.transitionRandom.pool (a dialog: no `setting` yet). poolLink only registers it with the page,
        // so a search result or link lands on it
        DialogMultiSelectButton {
            id: poolButton

            readonly property RowSetting poolLink: RowSetting {
                sid: "e4:background.transitionRandom.pool"
                row: poolButton
            }

            Layout.topMargin: Tokens.spacing.small
            enabled: !poolLink.blocked
            opacity: enabled ? 1 : 0.5
            rootParent: root.flickable
            icon: "shuffle"
            // TRANSLATORS: %1 chosen out of %2
            label: Tr.tr("Pick from: %1 of %2").arg(root.wt.randomPool.length).arg(root.wt.transitions.length)
            header: Tr.tr("Random transitions")
            acceptLabel: Tr.trCtx("Apply", "button")
            model: root.wt.transitions
            selected: root.wt.randomPool

            onAccepted: root.wt.random.pool = chosen.filter(n => root.wt.isTransition(n))

            RowPulse {
                link: poolButton.poolLink
                // as the closed dialog's shape (DialogRowButton's dialogBg)
                radius: Tokens.rounding.extraSmall
                bottomLeftRadius: Tokens.rounding.extraLarge
                bottomRightRadius: Tokens.rounding.extraLarge
            }
        }

        // caelestia4: scripts/caelestia4/wallpaper-fit.py
        SectionHeader {
            text: Tr.tr("Fit to the screen")
        }

        ToggleRow {
            setting: "e4:background.wallpaperFit.enable"
        }

        SelectRow {
            setting: "e4:background.wallpaperFit.mode"
        }

        SectionHeader {
            text: Tr.tr("Parallax")
        }

        ToggleRow {
            setting: "e4:background.parallax.enableWorkspace"
        }

        ToggleRow {
            setting: "e4:background.parallax.vertical"
        }

        StepperRow {
            setting: "e4:background.parallax.workspaceZoom"
        }

        AdvancedSection {
            SelectRow {
                setting: "e4:background.wallpaperFit.model"
            }

            StepperRow {
                setting: "e4:background.parallax.widgetsFactor"
            }

            ToggleRow {
                setting: "e4:wallpaperSelector.useSystemFileDialog"
            }
        }
    }
}
