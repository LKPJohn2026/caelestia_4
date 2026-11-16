import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.services as E4 // caelestia4: keep (HyprlandConfig)
import qs.modules.caelestia.nexus.common
import qs.modules.caelestia.nexus.pages.display // caelestia4: TrialTime, the same time as Display's

// caelestia4: keep/revert prompt for a risky Hyprland option (registry `risky: true`), like DisplayPage's "Keep these
// display settings?": after the user changes the row's setting, a countdown (TrialTime, 15 s) shows under the row;
// without Keep the old value comes back, so a change that blanks the screen undoes itself. Put it right after the row:
//   SelectRow { id: scanout; setting: "h:render:direct_scanout" }
//   KeepRevert { link: scanout.link }
// It is its own RowGroup (no first/last of its own), so in the page's RowGroup it splits the section while shown.
// A change back to the default (reset, or picking the default option) is not put on trial: the default is the safe
// value. A revert says so in a toast and drops the undo steps of the reverted change, which no longer match.
RowGroup {
    id: root

    required property RowSetting link
    property int seconds: TrialTime.seconds

    readonly property bool pending: countdown > 0
    property int countdown: 0

    // The value and whether the key was in the overrides file before the change on trial
    property var _old
    property bool _oldModified
    property bool _reverting
    // Taken when a trial starts, so a revert after the row is gone still knows what to write and what to say
    property string _key
    property string _title
    // The undo stack before the trial: steps recorded after it are for the change on trial
    property var _stepsBefore: []
    // Follows link.modified while nothing is on trial (it updates a moment after a write, once the file is re-read)
    property bool _modifiedNow

    function keep(): void {
        countdownTimer.stop();
        countdown = 0;
    }

    function revert(): void {
        countdownTimer.stop();
        countdown = 0;
        _restore();
        _reverted();
    }

    function _reverted(): void {
        const before = root._stepsBefore;
        NexusActions.steps = NexusActions.steps.filter(st => before.indexOf(st) >= 0 || !(st.label ?? "").includes(root._title));
        NexusActions.toast(Tr.tr("“%1” went back to its old value").arg(root._title));
    }

    function _restore(): void {
        _reverting = true;
        try {
            if (_oldModified)
                root.link.s.set(_old);
            else
                root.link.s.reset();
        } finally {
            _reverting = false;
        }
    }

    visible: pending

    Binding {
        target: root
        property: "_modifiedNow"
        value: root.link.modified
        when: !root.pending
    }

    Connections {
        function onChangedByUser(oldValue: var, newValue: var): void {
            if (root._reverting || root.link.s.same(oldValue, newValue))
                return;
            // Back to the default: that is the safe value, so nothing to try out (and a trial already running ends)
            if (root.link.s.defaultValue !== undefined && root.link.s.same(newValue, root.link.s.defaultValue)) {
                root.keep();
                return;
            }
            if (!root.pending) {
                root._old = oldValue === undefined ? undefined : JSON.parse(JSON.stringify(oldValue));
                root._oldModified = root._modifiedNow;
                root._key = root.link.s.key;
                root._title = root.link.title;
                root._stepsBefore = NexusActions.steps;
            } else if (root.link.s.same(newValue, root._old)) {
                // Changed back by hand: nothing left on trial
                root.keep();
                return;
            }
            root.countdown = root.seconds;
            countdownTimer.restart();
        }

        target: root.link.s
    }

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown -= 1;
            if (root.countdown <= 0)
                root.revert();
        }
    }

    // The page went away (closed, or a sub-page popped) before Keep: put the old value back, by key, since the
    // row's Setting goes away with it
    Component.onDestruction: {
        if (!root.pending)
            return;
        countdownTimer.stop();
        const key = root._key;
        if (root._oldModified)
            E4.HyprlandConfig.set(key, typeof root._old === "boolean" ? (root._old ? "true" : "false") : String(root._old));
        else
            E4.HyprlandConfig.reset(key);
        root._reverted();
    }

    InfoRow {
        icon: "timer"
        label: Tr.tr("Reverting in %1 s").arg(root.countdown)
        subtext: Tr.tr("If the screen looks wrong, wait and it goes back by itself")
    }

    RowButton {
        icon: "check"
        text: Tr.tr("Keep")
        onClicked: root.keep()
    }

    RowButton {
        icon: "undo"
        text: Tr.tr("Revert")
        onClicked: root.revert()
    }
}
