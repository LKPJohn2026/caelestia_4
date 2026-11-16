import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "audio" page (merged by Registry.qml). See RegPanels.qml for the format.
// Volumes, mute and the chosen devices are not settings (they are the live PipeWire state), so they have no entries
QtObject {
    readonly property var entries: ({
            // caelestia4: Audio > Volume (pages/AudioPage.qml), moved from Services (proposal 2.3; ids kept). Stored as
            // fractions (0.05) but shown as percents: the rows are x: ids over the c: options (ScaledOption,
            // pages/services/ScaledOption.qml). Each c: option has an entry too (`shownBy` names the x: row, so a search
            // lands there): coverage counts it, and "Reset page" resets it
            "x:services.audioIncrementPercent": {
                route: "audio",
                section: Tr.mark("Volume"),
                title: Tr.mark("Volume step"),
                desc: Tr.mark("How much the volume changes per scroll or key press"),
                keywords: [Tr.mark("volume"), Tr.mark("step"), Tr.mark("increment"), Tr.mark("scroll"), Tr.mark("audio"), Tr.mark("sound")],
                type: "int",
                unit: "%",
                min: 1,
                max: 50,
                step: 1
            },
            "x:services.maxVolumePercent": {
                route: "audio",
                section: Tr.mark("Volume"),
                title: Tr.mark("Highest volume"),
                desc: Tr.mark("Sliders and volume keys stop here. Above 100 % the sound is boosted and can distort"),
                keywords: [Tr.mark("volume"), Tr.mark("maximum"), Tr.mark("limit"), Tr.mark("boost"), Tr.mark("amplify"), Tr.mark("loud")],
                type: "int",
                unit: "%",
                min: 50,
                max: 200,
                step: 5
            },
            "c:services.audioIncrement": {
                route: "audio",
                section: Tr.mark("Volume"),
                title: Tr.mark("Volume step"),
                type: "real",
                shownBy: "x:services.audioIncrementPercent"
            },
            "c:services.maxVolume": {
                route: "audio",
                section: Tr.mark("Volume"),
                title: Tr.mark("Highest volume"),
                type: "real",
                shownBy: "x:services.maxVolumePercent"
            },

            // Audio > Hearing protection (pages/AudioPage.qml)
            "e4:audio.protection.enable": {
                route: "audio",
                section: Tr.mark("Hearing protection"),
                title: Tr.mark("Block sudden loud jumps"),
                desc: Tr.mark("Undo volume changes that are too big or go over the limit, whoever makes them"),
                keywords: [Tr.mark("hearing"), Tr.mark("protection"), Tr.mark("loud"), Tr.mark("volume"), Tr.mark("limit"), Tr.mark("safety"), Tr.mark("ears")],
                type: "bool"
            },
            "e4:audio.protection.maxAllowedIncrease": {
                route: "audio",
                section: Tr.mark("Hearing protection"),
                title: Tr.mark("Largest allowed jump"),
                desc: Tr.mark("A bigger step up in volume at once is undone"),
                keywords: [Tr.mark("hearing"), Tr.mark("protection"), Tr.mark("jump"), Tr.mark("step"), Tr.mark("increase"), Tr.mark("volume")],
                type: "int",
                unit: "%",
                min: 1,
                max: 100,
                step: 1,
                requires: {
                    id: "e4:audio.protection.enable",
                    value: true
                }
            },
            "e4:audio.protection.maxAllowed": {
                route: "audio",
                section: Tr.mark("Hearing protection"),
                title: Tr.mark("Undo volume above"),
                desc: Tr.mark("A change that sets the output volume above this is undone"),
                keywords: [Tr.mark("hearing"), Tr.mark("protection"), Tr.mark("maximum"), Tr.mark("limit"), Tr.mark("cap"), Tr.mark("volume")],
                type: "int",
                unit: "%",
                min: 10,
                max: 150,
                step: 1,
                requires: {
                    id: "e4:audio.protection.enable",
                    value: true
                }
            },

            // Audio > System sounds
            "e4:sounds.battery": {
                route: "audio",
                section: Tr.mark("System sounds"),
                title: Tr.mark("Battery warnings"),
                desc: Tr.mark("Play sounds for low and critical battery, full charge, and plugging in or unplugging the charger"),
                keywords: [Tr.mark("sound"), Tr.mark("battery"), Tr.mark("warning"), Tr.mark("alert"), Tr.mark("beep"), Tr.mark("charger"), Tr.mark("plug"), Tr.mark("full charge")],
                type: "bool"
            },
            "e4:sounds.pomodoro": {
                route: "audio",
                section: Tr.mark("System sounds"),
                title: Tr.mark("Timer and Pomodoro"),
                desc: Tr.mark("Play a sound when a timer or Pomodoro session ends"),
                keywords: [Tr.mark("sound"), Tr.mark("timer"), Tr.mark("pomodoro"), Tr.mark("alarm"), Tr.mark("stopwatch")],
                type: "bool"
            },
            "e4:sounds.theme": {
                route: "audio",
                section: Tr.mark("System sounds"),
                title: Tr.mark("Sound theme"),
                desc: Tr.mark("The installed sound theme the system sounds come from"),
                keywords: [Tr.mark("sound"), Tr.mark("theme"), Tr.mark("freedesktop"), Tr.mark("system sounds"), Tr.mark("alert"), Tr.mark("beep")],
                type: "string"
            }
        })
}
