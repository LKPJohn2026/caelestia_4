pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.components
import qs.modules.caelestia.components.containers
import qs.modules.caelestia.components.controls
import qs.modules.caelestia.adapters
import qs.modules.caelestia.launcher.items
import qs.modules.caelestia.launcher.services
import qs.services as E4 // caelestia4: keep
import qs.modules.common as E4C // caelestia4: keep
import qs.modules.common.models as E4M // caelestia4: keep

StyledListView {
    id: root

    required property SearchBar search
    required property ScreenState screenState

    property string displayText

    readonly property string requestedState: stateForText(search.text)
    readonly property string displayState: stateForText(displayText)

    function syncDisplayText(): void {
        if (screenState.launcher && requestedState === displayState)
            displayText = search.text;
    }

    // caelestia4: end-4 search prefixes (clipboard ; emoji : math = command $ web ? actions /) route to end-4's
    // LauncherSearch ("e4" state). end-4's app prefix is skipped: it clashes with Caelestia's actionPrefix (">").
    function isE4Text(text: string): bool {
        const p = E4C.Config.options.search.prefix;
        const caelestiaPrefix = GlobalConfig.launcher.actionPrefix;
        for (const e4p of [p.clipboard, p.emojis, p.math, p.shellCommand, p.webSearch, p.action])
            if (e4p && e4p !== caelestiaPrefix && text.startsWith(e4p))
                return true;
        return false;
    }

    function stateForText(text: string): string {
        const prefix = GlobalConfig.launcher.actionPrefix;
        if (isE4Text(text))
            return "e4";
        if (text.startsWith(prefix)) {
            for (const action of ["calc", "scheme", "variant"])
                if (text.startsWith(`${prefix}${action} `))
                    return action;

            return "actions";
        }

        // caelestia4: no app matches -> end-4 fallbacks (math result, run command, web search, actions)
        if (text.trim() !== "" && Apps.search(text).length === 0)
            return "e4";

        return "apps";
    }

    // caelestia4: the run prefix ($) gets its own results instead of end-4's (which runs the command invisibly
    // and adds a calculator/web-search row for "$…"): a hint while only "$" is typed, else one row that runs
    // the command in the launcher's terminal (Caelestia general.apps.terminal) with an interactive fish left
    // open afterwards, so the output stays visible.
    function shellResults(text: string): var {
        const command = text.slice(E4C.Config.options.search.prefix.shellCommand.length).trim();
        const terminal = GlobalConfig.general.apps.terminal;
        const base = {
            iconType: E4M.LauncherSearchResult.IconType.Material,
            iconName: "terminal",
            fontType: E4M.LauncherSearchResult.FontType.Monospace
        };
        if (command.length === 0)
            return [Object.assign({}, base, {
                    name: Tr.tr("Type a command to run"),
                    type: Tr.tr("Opens in %1, window stays open").arg(terminal[0] ?? "terminal"),
                    verb: "",
                    execute: () => {}
                })];
        return [Object.assign({}, base, {
                name: command,
                type: Tr.tr("Run in %1").arg(terminal[0] ?? "terminal"),
                verb: Tr.tr("Run"),
                execute: () => Quickshell.execDetached([...terminal, "fish", "-C", command])
            })];
    }

    function resultsForText(text: string): var {
        const runPrefix = E4C.Config.options.search.prefix.shellCommand;
        if (runPrefix.length > 0 && text.startsWith(runPrefix))
            return shellResults(text);
        switch (stateForText(text)) {
        case "actions":
            return Actions.query(text);
        case "calc":
            return [0];
        case "scheme":
            return Schemes.query(text);
        case "variant":
            return M3Variants.query(text);
        case "e4":
            return E4.LauncherSearch.results;
        default:
            return Apps.search(text);
        }
    }

    // caelestia4: feed the typed text to end-4's search while in the "e4" state
    property Binding e4QueryBinding: Binding {
        target: E4.LauncherSearch
        property: "query"
        value: root.displayText
        when: root.displayState === "e4"
    }

    model: ScriptModel {
        values: root.resultsForText(root.displayText)
        onValuesChanged: root.currentIndex = 0
    }

    spacing: Tokens.spacing.small
    orientation: Qt.Vertical
    implicitHeight: (Tokens.sizes.launcher.itemHeight + spacing) * Math.min(Config.launcher.maxShown, count) - spacing

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    highlightFollowsCurrentItem: false
    highlight: StyledRect {
        radius: Tokens.rounding.large
        color: Colours.palette.m3onSurface
        opacity: 0.08

        y: root.currentItem?.y ?? 0
        implicitWidth: root.width
        implicitHeight: root.currentItem?.implicitHeight ?? 0

        Behavior on y {
            Anim {}
        }
    }

    state: screenState.launcher ? requestedState : displayState

    onStateChanged: {
        if (state === "scheme" || state === "variant")
            Schemes.reload();
    }

    Component.onCompleted: displayText = search.text

    states: [
        State {
            name: "apps"

            PropertyChanges {
                root.delegate: appItem
            }
        },
        State {
            name: "actions"

            PropertyChanges {
                root.delegate: actionItem
            }
        },
        State {
            name: "calc"

            PropertyChanges {
                root.delegate: calcItem
            }
        },
        State {
            name: "scheme"

            PropertyChanges {
                root.delegate: schemeItem
            }
        },
        State {
            name: "variant"

            PropertyChanges {
                root.delegate: variantItem
            }
        },
        State {
            name: "e4"

            PropertyChanges {
                root.delegate: e4Item
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 1
                    to: 0.9
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                target: root
                property: "delegate"
                value: null
            }
            ScriptAction {
                script: root.displayText = root.search.text
            }
            PropertyAction {
                target: root
                property: "delegate"
            }
            ParallelAnimation {
                Anim {
                    target: root
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: root
                    property: "scale"
                    from: 0.9
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
            PropertyAction {
                targets: [root.add, root.remove]
                property: "enabled"
                value: true
            }
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 0
            to: 1
        }
    }

    remove: Transition {
        enabled: !root.state

        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            from: 1
            to: 0
        }
    }

    move: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    addDisplaced: Transition {
        Anim {
            property: "y"
            type: Anim.StandardSmall
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    displaced: Transition {
        Anim {
            property: "y"
        }
        Anim {
            type: Anim.DefaultEffects
            property: "opacity"
            to: 1
        }
    }

    Component {
        id: e4Item

        E4ResultItem {
            screenState: root.screenState
        }
    }

    Component {
        id: appItem

        AppItem {
            screenState: root.screenState
        }
    }

    Component {
        id: actionItem

        ActionItem {
            list: root
        }
    }

    Component {
        id: calcItem

        CalcItem {
            list: root
        }
    }

    Component {
        id: schemeItem

        SchemeItem {
            list: root
        }
    }

    Component {
        id: variantItem

        VariantItem {
            list: root
        }
    }

    Connections {
        function onTextChanged() {
            root.syncDisplayText();
        }

        target: root.search
    }

    Connections {
        function onLauncherChanged() {
            root.syncDisplayText();
        }

        target: root.screenState
    }
}
