import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "updates" page (merged by Registry.qml). See RegPanels.qml for the format
QtObject {
    readonly property var entries: ({
            // Updates (pages/UpdatesPage.qml). A sudoers rule, not a config option: the page gives the value
            // (SystemUpdates.passwordlessUpdates) and turns it on or off with tools/update-sudo-rule.sh
            "x:updates.passwordless": {
                route: "updates",
                section: Tr.mark("System"),
                title: Tr.mark("Update without a password"),
                desc: Tr.mark("Adds a sudoers rule so updates never ask for the password. Any program under this account could then run pacman as root"),
                keywords: [Tr.mark("sudo"), Tr.mark("sudoers"), Tr.mark("password"), Tr.mark("pacman"), Tr.mark("root"), Tr.mark("passwordless"), Tr.mark("updates")],
                type: "bool",
                default: false
            },
            // caelestia4: end-4's update check settings, used by SystemUpdates (the bar icon, its popout, this page)
            "e4:updates.enableCheck": {
                route: "updates",
                section: Tr.mark("Automatic checks"),
                title: Tr.mark("Check for updates"),
                desc: Tr.mark("Look for new packages on a schedule. Off: only when you press Check now"),
                keywords: [Tr.mark("updates"), Tr.mark("check"), Tr.mark("automatic"), Tr.mark("schedule"), Tr.mark("pacman"), Tr.mark("aur"), Tr.mark("packages")],
                type: "bool"
            },
            "e4:updates.checkInterval": {
                route: "updates",
                section: Tr.mark("Automatic checks"),
                title: Tr.mark("Check every"),
                desc: Tr.mark("Time between update checks"),
                keywords: [Tr.mark("updates"), Tr.mark("check"), Tr.mark("interval"), Tr.mark("frequency"), Tr.mark("schedule"), Tr.mark("hours")],
                type: "duration",
                unit: "min",
                min: 5,
                max: 1440,
                requires: {
                    id: "e4:updates.enableCheck",
                    value: true
                }
            },
            "e4:updates.adviseUpdateThreshold": {
                route: "updates",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Suggest updating at"),
                desc: Tr.mark("With more pending packages than this, the bar's updates popout says updating soon is advised"),
                keywords: [Tr.mark("updates"), Tr.mark("advise"), Tr.mark("threshold"), Tr.mark("pending"), Tr.mark("packages"), Tr.mark("warning")],
                type: "int",
                min: 1,
                max: 1000,
                step: 5,
                advanced: true
            },
            "e4:updates.stronglyAdviseUpdateThreshold": {
                route: "updates",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Warn about updates at"),
                desc: Tr.mark("With more pending packages than this, the bar's updates icon turns red"),
                keywords: [Tr.mark("updates"), Tr.mark("advise"), Tr.mark("threshold"), Tr.mark("pending"), Tr.mark("packages"), Tr.mark("warning"), Tr.mark("red")],
                type: "int",
                min: 1,
                max: 2000,
                step: 10,
                advanced: true
            }
        })
}
