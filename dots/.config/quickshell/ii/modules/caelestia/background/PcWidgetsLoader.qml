pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.caelestia.background.pcwidgets.clock
import qs.modules.caelestia.background.pcwidgets.weather
import qs.modules.caelestia.background.pcwidgets.media
import qs.modules.caelestia.background.pcwidgets.images
import qs.modules.caelestia.background.pcwidgets.calendar
import qs.modules.caelestia.background.pcwidgets.usercard
import qs.modules.caelestia.background.pcwidgets.worldclock
import qs.modules.caelestia.background.pcwidgets.resources
import qs.modules.caelestia.background.pcwidgets.notes
import qs.modules.caelestia.background.pcwidgets.timers
import qs.modules.caelestia.background.pcwidgets.todo

// caelestia4: end4-pC's desktop widgets (pctrade/end4-pC 8840bd0, GPL-3), the ones its presets use most.
// Only some are ported; a preset's other widgets are left off. Settings > Desktop.
Item {
    id: root

    required property var screen
    required property Item wallpaperItem

    Repeater {
        model: ["customImage", "calendar", "weather", "clock", "media", "userCard", "worldClock", "resources", "notes", "timers", "todo", "images"]

        delegate: FadeLoader {
            id: loader

            required property string modelData

            shown: Config.options.background.widgets[loader.modelData].enable
            sourceComponent: ({
                    customImage: customImageComp,
                    calendar: calendarComp,
                    weather: weatherComp,
                    clock: clockComp,
                    media: mediaComp,
                    userCard: userCardComp,
                    worldClock: worldClockComp,
                    resources: resourcesComp,
                    notes: notesComp,
                    timers: timersComp,
                    todo: todoComp,
                    images: imagesComp
                })[loader.modelData]
        }
    }

    Component {
        id: customImageComp
        CustomImage {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: calendarComp
        CalendarWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: weatherComp
        WeatherWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: clockComp
        ClockWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: mediaComp
        MediaWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: userCardComp
        UserCardWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: worldClockComp
        WorldClockWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: resourcesComp
        ResourcesWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: notesComp
        NotesWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: timersComp
        TimerWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: todoComp
        TodoWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: imagesComp
        ImageConverterWidget {
            screenWidth: root.screen.width
            screenHeight: root.screen.height
            scaledScreenWidth: root.screen.width
            scaledScreenHeight: root.screen.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
}
