pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia
import Caelestia.Components
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.widgets
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.wallandstyle
import qs.modules.common as E4C // caelestia4: keep (end-4's transparency follows this toggle)

// caelestia4: the hero, the Wallpapers / Colours / Presets pills, the transition and the basic toggles; the rest is on
// sub-pages: Look & feel (look), Fonts (fonts), Wallpaper options (sources), Desktop (desktop). "What gets coloured"
// is on Colours. Rows name their registry setting (registry/RegAppearance.qml)
PageBase {
    id: root

    title: Tr.tr("Wallpaper & style")

    readonly property WallTransitions wt: WallTransitions {}
    // caelestia4: a short window (the page under 700 px): a smaller preview and pills, so the
    // settings under them show without scrolling
    readonly property bool shortWindow: flickable.height > 0 && flickable.height < 700

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth
        spacing: root.shortWindow ? Tokens.spacing.medium : Tokens.spacing.large

        ClipRect {
            id: wallWrapper

            Layout.alignment: Qt.AlignHCenter
            implicitWidth: {
                const screen = root.nState.screen;
                if (!screen)
                    return 0; // caelestia4: the output went (resume); the window goes too
                return implicitHeight / screen.height * screen.width;
            }
            implicitHeight: {
                const screen = root.nState.screen;
                const cWidth = root.cappedWidth;
                if (!screen)
                    return 0; // caelestia4: as above
                // caelestia4: at most half the page's height, a third in a short window, so the pills, the
                // transition and the first settings show under it
                return Math.min(Math.round(cWidth * 0.4), cWidth / screen.width * screen.height, Math.max(120, Math.round(root.flickable.height * (root.shortWindow ? 0.3 : 0.5))));
            }

            color: Colours.tPalette.m3surfaceContainer
            radius: Tokens.rounding.large

            Loader {
                anchors.centerIn: parent
                opacity: Config.background.wallpaperEnabled ? 0 : 1
                active: opacity > 0

                sourceComponent: ColumnLayout {
                    spacing: Tokens.spacing.extraSmall

                    MaterialIcon {
                        Layout.alignment: Qt.AlignHCenter
                        text: "hide_image"
                        color: Colours.palette.m3onSurfaceVariant
                        fontStyle: Tokens.font.icon.extraLarge
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: Tr.tr("Wallpaper disabled")
                        color: Colours.palette.m3onSurfaceVariant
                        font: Tokens.font.body.large
                    }
                }

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }

            WallpaperImpl {
                anchors.fill: parent
                source: Wallpapers.forScreen(root.nState.screen) // caelestia4: upstream #2210
                opacity: Config.background.wallpaperEnabled ? 1 : 0

                Behavior on opacity {
                    Anim {
                        type: Anim.SlowEffects
                    }
                }
            }
        }

        // caelestia4: the pills wrap (a Flow, not a ButtonRow) and take less padding in a narrow column, so they never
        // run past the content's edges
        Flow {
            id: pills

            readonly property bool narrow: root.cappedWidth < 560 || root.shortWindow
            readonly property real oneLine: wallPill.implicitWidth + colourPill.implicitWidth + presetPill.implicitWidth + spacing * 2

            Layout.alignment: Qt.AlignHCenter
            readonly property real twoFirst: wallPill.implicitWidth + colourPill.implicitWidth + spacing

            // As wide as the pills that fit on a line, so the block stays centred when it wraps
            Layout.preferredWidth: oneLine <= root.cappedWidth ? oneLine : twoFirst <= root.cappedWidth ? twoFirst : Math.min(root.cappedWidth, Math.max(wallPill.implicitWidth, colourPill.implicitWidth, presetPill.implicitWidth))
            spacing: Tokens.spacing.small

            IconTextButton {
                id: wallPill

                icon: "wallpaper"
                text: Tr.tr("Wallpapers")
                font: pills.narrow ? Tokens.font.body.medium : Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: pills.narrow ? Tokens.padding.large : Tokens.padding.extraLarge
                verticalPadding: root.shortWindow ? Tokens.padding.small : Tokens.padding.medium
                disabled: !Config.background.wallpaperEnabled
                onClicked: root.nState.openSubPage("wallpapers")
            }

            IconTextButton {
                id: colourPill

                icon: "palette"
                text: Tr.tr("Colours")
                font: pills.narrow ? Tokens.font.body.medium : Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: pills.narrow ? Tokens.padding.large : Tokens.padding.extraLarge
                verticalPadding: root.shortWindow ? Tokens.padding.small : Tokens.padding.medium
                onClicked: root.nState.openSubPage("colours")
            }

            // caelestia4: end4-pC presets (wallpaper, desktop widgets, lock screen, avatar)
            IconTextButton {
                id: presetPill

                icon: "style"
                text: Tr.tr("Presets")
                font: pills.narrow ? Tokens.font.body.medium : Tokens.font.body.large
                isRound: true
                shapeMorph: true
                type: IconTextButton.Tonal
                horizontalPadding: pills.narrow ? Tokens.padding.large : Tokens.padding.extraLarge
                verticalPadding: root.shortWindow ? Tokens.padding.small : Tokens.padding.medium
                onClicked: root.nState.openSubPage("presets")
            }
        }

        // c:background.wallpaperTransition and e4:background.transitionRandom.enable (a dialog: no `setting` yet).
        // Which transitions Random picks from: Wallpaper options. transitionLink only registers it with the page, so
        // a search result or link lands on it
        DialogSelectButton {
            id: transitionButton

            readonly property RowSetting transitionLink: RowSetting {
                sid: "c:background.wallpaperTransition"
                row: transitionButton
            }

            Layout.fillWidth: true
            rootParent: root.flickable
            icon: "animation"
            label: root.wt.random.enable
                // TRANSLATORS: %1 transitions to pick from out of %2
                ? Tr.tr("Transition: Random (%1 of %2)").arg(root.wt.randomPool.length).arg(root.wt.transitions.length)
                : Tr.tr("Transition: %1").arg(root.wt.transitions.find(t => t.id === root.wt.current)?.label ?? root.wt.current)
            header: Tr.tr("Wallpaper transition")
            acceptLabel: Tr.trCtx("Apply", "button")
            model: root.wt.choices

            onAccepted: {
                if (!selectedItem)
                    return;
                // caelestia4: Random draws from the pool at each change; any other choice turns it off
                root.wt.random.enable = selectedItem === "Random";
                if (selectedItem !== "Random")
                    GlobalConfig.background.wallpaperTransition = WallpaperTransition[selectedItem];
            }

            RowPulse {
                link: transitionButton.transitionLink
                // as the closed dialog's shape (DialogRowButton's dialogBg)
                radius: Tokens.rounding.extraSmall
                bottomLeftRadius: Tokens.rounding.extraLarge
                bottomRightRadius: Tokens.rounding.extraLarge
            }
        }

        RowGroup {
            Layout.fillWidth: true

            ToggleRow {
                setting: "c:background.wallpaperEnabled"
            }

            // caelestia4: upstream #2210
            ToggleRow {
                setting: "c:background.workspaceWallpapers.enabled"
            }

            ToggleRow {
                id: transparencyRow

                setting: "c:appearance.transparency.enabled"
                // caelestia4: the registry's description, then the values as Look & feel shows them (the saved
                // values, in %; Colours.transparency.base is lowered in light mode)
                // TRANSLATORS: %1/%2 = whole percentages, the same numbers as "Panel opacity" and "Inner layer opacity" in Look & feel
                subtext: transparencyRow.link.desc + ". " + Tr.tr("Panel opacity %1 %, inner layers %2 %").arg(Math.round(Tokens.transparency.base * 100)).arg(Math.round(Tokens.transparency.layers * 100))

                // caelestia4: end-4 parts (AI chat, settings app, overlay) follow it, also after a reset or Undo
                MirrorWatch {
                    setting: transparencyRow.link.s
                    onFollow: v => {
                        if (typeof v === "boolean" && E4C.Config.options.appearance.transparency.enable !== v)
                            E4C.Config.options.appearance.transparency.enable = v;
                    }
                }
            }

            // x:appearance.darkTheme: the scheme's mode (caelestia-cli or end-4's matugen), not a config key
            ToggleRow {
                id: darkRow

                setting: "x:appearance.darkTheme"

                Binding {
                    target: darkRow.link.s
                    property: "customValue"
                    value: !Colours.light
                }

                Connections {
                    function onCustomSet(v: var): void {
                        Colours.setMode(v ? "dark" : "light");
                    }

                    target: darkRow.link.s
                }
            }
        }

        RowGroup {
            Layout.fillWidth: true

            NavRow {
                icon: "tune"
                text: Tr.tr("Look & feel")
                subtext: Tr.tr("Size, shape, transparency, motion, screen frame")
                onClicked: root.nState.openSubPage("look")
            }

            // caelestia4: pages/wallandstyle/FontsPage.qml
            NavRow {
                icon: "font_download"
                text: Tr.tr("Fonts")
                subtext: Tr.tr("Panel, monospace, icon and widget fonts, type scale")
                onClicked: root.nState.openSubPage("fonts")
            }

            NavRow {
                icon: "photo_library"
                text: Tr.tr("Wallpaper options")
                subtext: Tr.tr("Folder, random wallpapers, transitions, fitting, parallax")
                onClicked: root.nState.openSubPage("sources")
            }

            NavRow {
                icon: "widgets"
                text: Tr.tr("Desktop")
                subtext: Tr.tr("Clock, audio visualiser, widgets")
                onClicked: root.nState.openSubPage("desktop")
            }
        }
    }
}
