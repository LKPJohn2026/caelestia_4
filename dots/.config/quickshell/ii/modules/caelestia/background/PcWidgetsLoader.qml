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
import qs.modules.caelestia.background.pcwidgets.customtext

// caelestia4: end4-pC's desktop widgets (pctrade/end4-pC 8840bd0, GPL-3), the ones its presets use most.
// A preset's widgets not ported here are left off. Settings > Desktop.
Item {
    id: root

    required property Item wallpaperItem

    Repeater {
        // end4-pC's order: widgets with the same z are stacked like this (in a preset's preview too)
        model: ["customImage", "imageCard", "sticker", "calendar", "weather", "clock", "notes", "media", "images", "resources", "worldClock", "userCard", "todo", "timers", "customText"]

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
                    images: imagesComp,
                    imageCard: imageCardComp,
                    sticker: stickerComp,
                    customText: customTextComp
                })[loader.modelData]
        }
    }

    Component {
        id: customImageComp
        CustomImage {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: calendarComp
        CalendarWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: weatherComp
        WeatherWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: clockComp
        ClockWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: mediaComp
        MediaWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: userCardComp
        UserCardWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: worldClockComp
        WorldClockWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: resourcesComp
        ResourcesWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: notesComp
        NotesWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: timersComp
        TimerWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: todoComp
        TodoWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: imagesComp
        ImageConverterWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: imageCardComp
        ImageCardWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: stickerComp
        StickerWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
    Component {
        id: customTextComp
        CustomTextWidget {
            screenWidth: root.width
            screenHeight: root.height
            scaledScreenWidth: root.width
            scaledScreenHeight: root.height
            wallpaperScale: 1
            wallpaperItem: root.wallpaperItem
        }
    }
}
