pragma Singleton

import QtQuick
import Caelestia.I18n

// caelestia4: Nexus's undo stack and messages. record(label, undoFn) pushes an undo step (and returns it); undo() runs
// the last one and says so in the snackbar; undoStep(step) runs one given step (a snackbar's Undo button). message(text,
// actionLabel, actionFn) asks Nexus.qml's Snackbar to show a message; toast(text) is a message without a button.
// While a step runs (`undoing`), record() does nothing, so undoing a change doesn't record a new step. Rows with a
// `setting` record their changes themselves (RowSetting.qml); batch(label, fn) turns every step fn records into one.
QtObject {
    id: root

    property var steps: []
    readonly property bool canUndo: steps.length > 0
    readonly property bool undoing: _undoing
    readonly property int maxSteps: 50

    signal message(text: string, actionLabel: string, actionFn: var)

    function record(label: string, undoFn: var): var {
        if (typeof undoFn !== "function" || root._undoing)
            return null;
        const step = {
            label,
            undoFn
        };
        if (root._batch) {
            root._batch.push(step);
            return step;
        }
        const s = steps.slice(-(maxSteps - 1));
        s.push(step);
        steps = s;
        return step;
    }

    // Runs fn; the steps it records become one step, undone together (last first). Returns that step, or null
    function batch(label: string, fn: var): var {
        const outer = root._batch;
        const inner = [];
        root._batch = inner;
        try {
            fn();
        } finally {
            root._batch = outer;
        }
        if (inner.length === 0)
            return null;
        return record(label, () => {
            for (let i = inner.length - 1; i >= 0; i--)
                inner[i].undoFn();
        });
    }

    function undo(): void {
        if (steps.length === 0)
            return;
        undoStep(steps[steps.length - 1]);
    }

    // Runs `step` (from record()) and takes it off the stack; nothing if it was already undone
    function undoStep(step: var): void {
        const i = steps.indexOf(step);
        if (!step || i < 0)
            return;
        const s = steps.slice();
        s.splice(i, 1);
        steps = s;
        root._undoing = true;
        try {
            step.undoFn();
        } catch (e) {
            console.warn(`Nexus: undo of "${step.label}" failed: ${e}`);
        } finally {
            root._undoing = false;
        }
        toast(step.label ? Tr.tr("Undone: %1").arg(step.label) : Tr.tr("Undone"));
    }

    function toast(text: string): void {
        message(text, "", null);
    }

    // Writes a registry setting by id (not "x:" ones, which need their page), e.g. from an undo step whose row is gone
    function writeSetting(sid: string, value: var): void {
        if (!root._settingComp)
            root._settingComp = Qt.createComponent("Setting.qml");
        const s = root._settingComp.createObject(root, {
            sid
        });
        if (!s) {
            console.warn(`Nexus: cannot write "${sid}": ${root._settingComp.errorString()}`);
            return;
        }
        s.set(value);
        s.destroy();
    }

    property bool _undoing
    property var _batch: null
    property Component _settingComp: null
}
