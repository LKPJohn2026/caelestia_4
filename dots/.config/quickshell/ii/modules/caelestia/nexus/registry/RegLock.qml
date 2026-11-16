import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for Power & idle > Lock screen (route power/lock) (merged by Registry.qml). See RegPanels.qml for the format.
// The shell's own lock (modules/common/panels/lock, modules/ii/lock). Its look applies the next time it locks; with
// "Use hyprlock" on, hyprlock draws the lock instead, so the look rows need it off.
// caelestia4: no `applies: "nextLock"` here: every row would show the same chip, so LockPage.qml says it once under its
// title instead
QtObject {
    readonly property var entries: ({
            // Lock screen > General
            "e4:lock.useHyprlock": {
                route: "power/lock",
                section: Tr.mark("General"),
                title: Tr.mark("Use hyprlock"),
                desc: Tr.mark("Recommended: survives the monitor dropping off on wake. Off: the shell's own lock screen"),
                keywords: [Tr.mark("lock screen"), Tr.mark("hyprlock"), Tr.mark("locker"), Tr.mark("security")],
                type: "bool"
            },
            "e4:lock.launchOnStartup": {
                route: "power/lock",
                section: Tr.mark("General"),
                title: Tr.mark("Lock when the session starts"),
                desc: Tr.mark("Locks the screen right after you log in, so the desktop is never shown unlocked"),
                keywords: [Tr.mark("lock screen"), Tr.mark("startup"), Tr.mark("login"), Tr.mark("boot"), Tr.mark("autologin"), Tr.mark("security")],
                type: "bool",
                applies: "relogin"
            },

            // Lock screen > Picture
            "e4:lock.blur.enable": {
                route: "power/lock",
                section: Tr.mark("Picture"),
                title: Tr.mark("Blur the picture"),
                desc: Tr.mark("Blurs the lock screen picture and tints it a little"),
                keywords: [Tr.mark("lock screen"), Tr.mark("blur"), Tr.mark("background"), Tr.mark("frosted")],
                type: "bool",
                requires: {
                    id: "e4:lock.useHyprlock",
                    value: false
                }
            },
            "e4:lock.blur.radius": {
                route: "power/lock",
                section: Tr.mark("Picture"),
                // caelestia4: its own title and a unit, so it doesn't read like the desktop's blur
                title: Tr.mark("Lock screen blur"),
                desc: Tr.mark("How strongly the picture is blurred"),
                keywords: [Tr.mark("lock screen"), Tr.mark("blur"), Tr.mark("radius"), Tr.mark("strength"), Tr.mark("amount")],
                type: "real",
                unit: "px",
                min: 0,
                // caelestia4: up to end-4's default (100), so the default fits the slider
                max: 100,
                step: 1,
                requires: {
                    id: "e4:lock.blur.enable",
                    value: true
                }
            },

            // caelestia4: these two were an Advanced section of two rows; now in their groups (Password, Picture)
            "e4:lock.materialShapeChars": {
                route: "power/lock",
                section: Tr.mark("Password"),
                title: Tr.mark("Shaped password dots"),
                desc: Tr.mark("Shows each typed character as a different Material shape instead of a plain dot"),
                keywords: [Tr.mark("lock screen"), Tr.mark("password"), Tr.mark("dots"), Tr.mark("shapes"), Tr.mark("characters"), Tr.mark("material")],
                type: "bool",
                requires: {
                    id: "e4:lock.useHyprlock",
                    value: false
                }
            },
            "e4:lock.blur.extraZoom": {
                route: "power/lock",
                section: Tr.mark("Picture"),
                title: Tr.mark("Zoom for the blur"),
                desc: Tr.mark("Zooms the blurred picture in a little so its soft edges stay off the screen"),
                keywords: [Tr.mark("lock screen"), Tr.mark("blur"), Tr.mark("zoom"), Tr.mark("edges"), Tr.mark("scale")],
                type: "real",
                unit: "%",
                scale: 100,
                min: 1,
                max: 1.5,
                step: 0.01,
                requires: {
                    id: "e4:lock.blur.enable",
                    value: true
                }
            }
        })
}
