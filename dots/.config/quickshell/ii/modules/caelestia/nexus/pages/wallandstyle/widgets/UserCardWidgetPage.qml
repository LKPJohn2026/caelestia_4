pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.I18n
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop widgets)
import qs.services as E4 // caelestia4: keep (PresetLayout: widgets on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > User card (route appearance/desktop/widget.userCard): end4-pC's desktop
// widget e4:background.widgets.userCard. Rows name their registry setting
// (registry/RegWidgetsB.qml)
PageBase {
    id: root

    title: Tr.tr("User card")
    isSubPage: true

    // caelestia4: the row's undo step writes `enable` back by itself, and once this page is closed nothing sends that
    // through PresetLayout (no preset save, no shift off another widget). So after the row records its step (or its
    // reset's), its undo is swapped for one through PresetLayout. It holds no reference to this page
    function undoThroughPreset(on: bool): void {
        if (NexusActions.undoing)
            return;
        const pl = E4.PresetLayout;
        const before = NexusActions.steps[NexusActions.steps.length - 1];
        Qt.callLater(() => {
            const step = NexusActions.steps[NexusActions.steps.length - 1];
            if (step && step !== before)
                step.undoFn = () => pl.setWidgetEnabled("userCard", on);
        });
    }

    // caelestia4: end-4's avatar shows Picture only while avatarPath is set too (UserAvatar.qml), so that row is only
    // shown when it is the reason the picture doesn't show (Picture set, avatarPath empty). A route or search result
    // that names it while hidden lands on Picture (PageBase can't scroll to a hidden row)
    readonly property bool needsAvatarPath: E4C.Config.options.profile.avatarPicture !== "" && E4C.Config.options.profile.avatarPath === ""

    function landOnShown(): void {
        if (root.nState?.focusKey === "e4:profile.avatarPath" && !root.needsAvatarPath)
            root.nState.focusKey = "e4:profile.avatarPicture";
    }

    // A property: PageBase's default property takes the page's one content item
    readonly property Connections focusWatch: Connections {
        function onFocusKeyChanged(): void {
            root.landOnShown();
        }

        target: root.nState
    }

    Component.onCompleted: landOnShown()

    RowGroup {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: root.cappedWidth

        ToggleRow {
            id: enableRow

            setting: "e4:background.widgets.userCard.enable"

            // caelestia4: on or off through PresetLayout, as Desktop's widget list does (a new one isn't left under
            // another, and it goes into the preset). The row has written the key already: take it back first
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    E4C.Config.options.background.widgets.userCard.enable = !newValue;
                    E4.PresetLayout.setWidgetEnabled("userCard", !!newValue);
                    root.undoThroughPreset(!!oldValue);
                }

                target: enableRow.link.s
            }
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        // caelestia4: Size is in the same place on every widget page, just before Placement: buttons for named
        // sizes, a stepper for pixels, "Fixed" for a widget with one size
        SegmentedRow {
            stacked: true
            setting: "e4:background.widgets.userCard.sizeMode"
        }

        SelectRow {
            setting: "e4:background.widgets.userCard.placementStrategy"
        }

        SectionHeader {
            text: Tr.tr("Profile")
        }

        TextFieldRow {
            setting: "e4:profile.displayName"
            placeholderText: E4.SystemInfo.username
        }

        PathRow {
            id: pictureRow

            setting: "e4:profile.avatarPicture"

            // caelestia4: end-4's avatar shows the picture only while avatarPath is set too (UserAvatar.qml): a
            // picture picked here sets it when it is empty
            Connections {
                function onChangedByUser(oldValue: var, newValue: var): void {
                    if (newValue && !E4C.Config.options.profile.avatarPath)
                        E4C.Config.options.profile.avatarPath = newValue;
                }

                target: pictureRow.link.s
            }
        }

        // caelestia4: set by picking a picture above. Shown only while the picture is held back by it being empty
        PathRow {
            visible: root.needsAvatarPath
            setting: "e4:profile.avatarPath"
        }

        PathRow {
            setting: "e4:sidebar.bannerImage"
        }
    }
}
