pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.common as E4C // caelestia4: keep (end-4 config.json: transparency follows Caelestia's)
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.components.effects
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.about

// caelestia4: Nexus's first-run welcome: a card over the window with a few first choices (language, dark theme,
// transparency, a wallpaper), the search shortcut, and Done / Skip. It shows when Nexus opens without a route while
// the welcome was never finished (pages/about/WelcomeState.qml), or right away after About's "Show welcome again".
// Done and Skip both end it for good; Esc skips, Ctrl+F ends it and opens the search (Nexus.qml)
Item {
    id: root

    required property NexusState nState
    // Opened with no route (a window or the popout as it opens by default)
    property bool plainOpen
    readonly property bool shown: WelcomeState.known && !WelcomeState.done && (plainOpen || WelcomeState.requested)

    function finish(): void {
        WelcomeState.finish();
    }

    // caelestia4: Tab and Shift+Tab (Nexus.qml) stay in the card: the next focusable item in the card, wrapping around,
    // scrolled into view when it is one of the choices
    function moveFocus(forward: bool): void {
        const start = root.Window.activeFocusItem;
        let item = root.inCard(start) ? start : (forward ? skipBtn : doneBtn);
        for (let i = 0; i < 200; i++) {
            item = item.nextItemInFocusChain(forward);
            if (!item || item === start)
                break;
            if (root.inCard(item) && item.visible && item.enabled && item.activeFocusOnTab) {
                item.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason);
                root.reveal(item);
                return;
            }
        }
        (forward ? skipBtn : doneBtn).forceActiveFocus();
    }

    function inCard(item: Item): bool {
        for (let p = item; p; p = p.parent)
            if (p === card)
                return true;
        return false;
    }

    function reveal(item: Item): void {
        for (let p = item; p; p = p.parent) {
            if (p !== choices)
                continue;
            const y = item.mapToItem(choices, 0, 0).y;
            if (y < flick.contentY)
                flick.contentY = y;
            else if (y + item.height > flick.contentY + flick.height)
                flick.contentY = Math.min(y + item.height - flick.height, flick.contentHeight - flick.height);
            return;
        }
    }

    Component.onCompleted: root.plainOpen = !root.nState.initialRoute

    // caelestia4: a route opened from outside while the card is up (Nexus asked to open a page, e.g. "Open in
    // settings" while the window is open) hides it until the next plain open; the welcome is not finished. The user
    // can't move by themselves while it is up: the scrim takes the clicks and Nexus.qml the page keys
    Connections {
        function onCurrentPageIdxChanged(): void {
            root.leftByRoute();
        }
        function onSubPagesReset(): void {
            root.leftByRoute();
        }
        function onSearchFocusRequested(): void {
            root.leftByRoute();
        }

        target: root.nState
    }

    function leftByRoute(): void {
        if (root.shown && !WelcomeState.requested)
            root.plainOpen = false;
    }

    onShownChanged: {
        if (shown)
            Qt.callLater(() => card.forceActiveFocus());
    }

    visible: opacity > 0
    opacity: shown ? 1 : 0

    Behavior on opacity {
        Anim {
            type: Anim.DefaultEffects
        }
    }

    // The scrim: clicks and scrolls stay here (only Done or Skip close the card)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onWheel: event => event.accepted = true

        Rectangle {
            anchors.fill: parent
            radius: Tokens.rounding.large
            color: Qt.alpha(Colours.palette.m3shadow, 0.4)
        }
    }

    Elevation {
        anchors.fill: card
        radius: card.radius
        level: 3
    }

    StyledRect {
        id: card

        anchors.centerIn: parent
        width: Math.min(560, root.width - Tokens.padding.large * 2)
        height: Math.min(root.height - Tokens.padding.large * 2, content.implicitHeight + Tokens.padding.extraLarge + Tokens.padding.largeIncreased)
        radius: Tokens.rounding.extraLargeIncreased
        color: Colours.palette.m3surfaceContainerHigh
        scale: root.shown ? 1 : 0.95

        Accessible.role: Accessible.Dialog
        Accessible.name: Tr.tr("Welcome to Nexus")

        Keys.onEscapePressed: root.finish()

        Behavior on scale {
            Anim {
                type: Anim.DefaultEffects
            }
        }

        MouseArea {
            anchors.fill: parent
        }

        // The choices scroll when the window is low; the title and the buttons stay
        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: Tokens.padding.extraLarge
            anchors.bottomMargin: Tokens.padding.largeIncreased
            spacing: Tokens.spacing.medium

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("Welcome to Nexus")
                wrapMode: Text.WordWrap
                font: Tokens.font.title.builders.large.weight(Font.Normal).build()
            }

            StyledText {
                Layout.fillWidth: true
                text: Tr.tr("A few choices to start with. You can change them any time.")
                color: Colours.palette.m3onSurfaceVariant
                font: Tokens.font.body.small
                wrapMode: Text.WordWrap
            }

            StyledFlickable {
                id: flick

                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: Tokens.spacing.small
                Layout.preferredHeight: choices.implicitHeight
                Layout.maximumHeight: choices.implicitHeight
                Layout.minimumHeight: Math.min(choices.implicitHeight, 64)
                contentHeight: choices.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // caelestia4: when the choices don't all fit, the scroll bar stays shown and the cut edge fades
                readonly property bool overflows: contentHeight > height + 1

                StyledScrollBar.vertical: StyledScrollBar {
                    flickable: flick
                    policy: flick.overflows ? T.ScrollBar.AlwaysOn : T.ScrollBar.AsNeeded
                }

                Rectangle {
                    parent: flick
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: Tokens.padding.extraLarge
                    visible: flick.overflows && !flick.atYEnd
                    gradient: Gradient {
                        GradientStop {
                            position: 0
                            color: Qt.alpha(Colours.palette.m3surfaceContainerHigh, 0)
                        }
                        GradientStop {
                            position: 1
                            color: Colours.palette.m3surfaceContainerHigh
                        }
                    }
                }

                RowGroup {
                    id: choices

                    // caelestia4: room for the scroll bar when it shows
                    width: flick.width - (flick.overflows ? Tokens.padding.extraSmall + Tokens.padding.small : 0)

                    SelectRow {
                        setting: "c:general.language"
                        label: Tr.tr("Language")
                        subtext: Tr.tr("For the panels and these settings")
                        menuItems: [autoLang, ...langItems.instances]

                        MenuItem {
                            id: autoLang

                            text: Tr.tr("Automatic")
                            value: ""
                        }

                        Variants {
                            id: langItems

                            model: Tr.supportedLanguages

                            MenuItem {
                                required property string modelData

                                value: modelData
                                text: {
                                    const locale = Qt.locale(modelData);
                                    return locale.name === "C" ? modelData : locale.nativeLanguageName || locale.name;
                                }
                            }
                        }
                    }

                    // x:appearance.darkTheme: the colour scheme's mode, as Wallpaper & style sets it
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

                    // Panel style: see-through or solid. end-4's parts follow, as on Wallpaper & style
                    ToggleRow {
                        id: transparencyRow

                        setting: "c:appearance.transparency.enabled"
                        subtext: Tr.tr("See-through panels with the wallpaper behind them")

                        Connections {
                            function onChangedByUser(oldValue: var, newValue: var): void {
                                if (typeof newValue === "boolean" && E4C.Config.options.appearance.transparency.enable !== newValue)
                                    E4C.Config.options.appearance.transparency.enable = newValue;
                            }

                            target: transparencyRow.link.s
                        }
                    }

                    NavRow {
                        icon: "wallpaper"
                        text: Tr.tr("Choose a wallpaper")
                        subtext: Tr.tr("Its colours become the colours of the shell")
                        onClicked: {
                            root.finish();
                            root.nState.navigate("appearance");
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.medium

                MaterialIcon {
                    text: "search"
                    color: Colours.palette.m3onSurfaceVariant
                    fontStyle: Tokens.font.icon.medium
                }

                StyledText {
                    Layout.fillWidth: true
                    // TRANSLATORS: Ctrl+F is a key combination: keep it
                    text: Tr.tr("Search any setting with Ctrl+F")
                    color: Colours.palette.m3onSurfaceVariant
                    font: Tokens.font.body.small
                    wrapMode: Text.WordWrap
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Layout.topMargin: Tokens.spacing.small
                spacing: Tokens.spacing.extraSmall

                TextButton {
                    id: skipBtn

                    // caelestia4: from the implicit height: the height in this layout gave a binding loop
                    radius: pressed ? Tokens.rounding.small : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
                    type: TextButton.Text
                    isRound: true
                    horizontalPadding: Tokens.padding.largeIncreased
                    verticalPadding: Tokens.padding.medium
                    text: Tr.trCtx("Skip", "button")
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    onClicked: root.finish()
                    Keys.onReturnPressed: root.finish()
                    Keys.onEnterPressed: root.finish()
                    Keys.onSpacePressed: root.finish()

                    FocusRing {
                        focusItem: skipBtn
                    }
                }

                TextButton {
                    id: doneBtn

                    // caelestia4: from the implicit height: the height in this layout gave a binding loop
                    radius: pressed ? Tokens.rounding.small : implicitHeight / 2 * Math.min(1, Tokens.rounding.scale)
                    type: TextButton.Filled
                    isRound: true
                    horizontalPadding: Tokens.padding.extraLarge
                    verticalPadding: Tokens.padding.medium
                    text: Tr.trCtx("Done", "button")
                    activeFocusOnTab: true
                    Accessible.role: Accessible.Button
                    Accessible.name: text
                    onClicked: root.finish()
                    Keys.onReturnPressed: root.finish()
                    Keys.onEnterPressed: root.finish()
                    Keys.onSpacePressed: root.finish()

                    FocusRing {
                        focusItem: doneBtn
                    }
                }
            }
        }
    }
}
