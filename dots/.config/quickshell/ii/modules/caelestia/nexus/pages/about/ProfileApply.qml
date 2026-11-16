pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.I18n
import qs.modules.caelestia.nexus.common

// caelestia4: applies a profile for About > Profiles (scripts/caelestia4/nexus-profile.sh apply). A singleton, so the
// Undo it records (snackbar or Ctrl+Z) still works after the Profiles page is closed: the step applies the backup the
// apply made. One apply at a time; one asked for while another runs waits for it. `finished` lets an open Profiles
// page reload its list
Singleton {
    id: root

    readonly property string script: Quickshell.shellPath("scripts/caelestia4/nexus-profile.sh")
    readonly property bool running: proc.running || queue.length > 0
    property var queue: []

    signal finished

    // p: {id, name}; undo: this apply puts back a backup (no new Undo step, and a "put back" message)
    function apply(p: var, undo: bool): void {
        root.queue = [...root.queue, {
                id: p.id,
                name: p.name,
                undo
            }];
        root.next();
    }

    function next(): void {
        if (proc.running || root.queue.length === 0)
            return;
        const job = root.queue[0];
        root.queue = root.queue.slice(1);
        // TRANSLATORS: the name of the backup made before a profile is applied; %1 is a date and time
        job.backupName = Tr.tr("Before %1").arg(new Date().toLocaleString(Qt.locale(), Locale.ShortFormat));
        proc.job = job;
        proc.command = [root.script, "apply", job.id, job.backupName];
        proc.running = true;
    }

    function done(job: var, code: int, out: string): void {
        const backup = out.trim();
        if (code === 0 && backup) {
            const label = job.undo ? Tr.tr("Settings put back") : Tr.tr("Applied “%1”").arg(job.name);
            const step = job.undo ? null : NexusActions.record(label, () => root.apply({
                    id: backup,
                    name: job.backupName
                }, true));
            NexusActions.message(label, step ? Tr.trCtx("Undo", "snackbar button") : "", step ? () => NexusActions.undoStep(step) : null);
        } else if (code === 4) {
            NexusActions.toast(job.undo ? Tr.tr("Your settings are already as they were") : Tr.tr("Your settings already match “%1”").arg(job.name));
        } else {
            NexusActions.toast(job.undo ? Tr.tr("Could not put your settings back") : Tr.tr("Could not apply the profile"));
        }
        root.finished();
    }

    Process {
        id: proc

        property var job: null

        stdout: StdioCollector {
            id: out
        }
        stderr: StdioCollector {
            id: err
        }
        onExited: code => {
            if (code !== 0)
                console.warn(`Nexus: profiles: apply failed (${code}): ${err.text.trim()}`);
            const job = proc.job;
            proc.job = null;
            root.done(job, code, out.text);
            Qt.callLater(root.next);
        }
    }
}
