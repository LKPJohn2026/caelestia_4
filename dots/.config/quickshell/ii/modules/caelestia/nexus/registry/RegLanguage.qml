import QtQuick
import Caelestia.Config
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "language" page (merged by Registry.qml). See RegPanels.qml for the format
QtObject {
    readonly property var entries: ({
            // Language & region (pages/LanguageAndRegion.qml)
            // The page lists the languages (Tr.supportedLanguages); the option here names the default
            "c:general.language": {
                route: "language",
                section: Tr.mark("Language"),
                title: Tr.mark("Panels and settings language"),
                desc: Tr.mark("The bar, dashboard, launcher, notifications and these settings"),
                keywords: [Tr.mark("language"), Tr.mark("locale"), Tr.mark("translation"), Tr.mark("vietnamese"), Tr.mark("english"), Tr.mark("ui")],
                type: "enum",
                options: [
                    {
                        value: "",
                        label: Tr.mark("Automatic")
                    }
                ]
            },
            // The page lists end-4's languages (E4.Translation)
            "e4:language.ui": {
                route: "language",
                section: Tr.mark("Language"),
                title: Tr.mark("Widgets and assistant language"),
                desc: Tr.mark("Desktop widgets, the assistant, overlay, region selector and lock screen, which have their own translations"),
                keywords: [Tr.mark("language"), Tr.mark("locale"), Tr.mark("translation"), Tr.mark("assistant"), Tr.mark("overlay"), Tr.mark("widgets"), Tr.mark("lock screen"), Tr.mark("translator"), Tr.mark("end-4")],
                type: "enum",
                options: [
                    {
                        value: "auto",
                        label: Tr.mark("Automatic")
                    }
                ]
            },
            "c:services.weatherLocation": {
                route: "language",
                section: Tr.mark("Weather"),
                title: Tr.mark("Weather location"),
                desc: Tr.mark("City name, or empty to detect it automatically. With GPS on, the desktop widgets and lock screen use GPS instead"),
                keywords: [Tr.mark("weather"), Tr.mark("city"), Tr.mark("location"), Tr.mark("place"), Tr.mark("forecast")],
                type: "string"
            },
            "c:services.weatherUnits": {
                route: "language",
                section: Tr.mark("Units"),
                title: Tr.mark("Weather temperatures"),
                desc: Tr.mark("Units for the weather forecast"),
                keywords: [Tr.mark("temperature"), Tr.mark("celsius"), Tr.mark("fahrenheit"), Tr.mark("kelvin"), Tr.mark("weather"), Tr.mark("units")],
                type: "enum",
                options: [
                    {
                        value: TemperatureUnit.Auto,
                        label: Tr.mark("Automatic")
                    },
                    {
                        value: TemperatureUnit.Celsius,
                        label: Tr.mark("°C")
                    },
                    {
                        value: TemperatureUnit.Fahrenheit,
                        label: Tr.mark("°F")
                    },
                    {
                        value: TemperatureUnit.Kelvin,
                        label: Tr.mark("K")
                    }
                ]
            },
            "c:services.sensorUnits": {
                route: "language",
                section: Tr.mark("Units"),
                title: Tr.mark("System temperatures"),
                desc: Tr.mark("Units for CPU and GPU temperatures"),
                keywords: [Tr.mark("temperature"), Tr.mark("celsius"), Tr.mark("fahrenheit"), Tr.mark("kelvin"), Tr.mark("cpu"), Tr.mark("gpu"), Tr.mark("sensors"), Tr.mark("units")],
                type: "enum",
                options: [
                    {
                        value: TemperatureUnit.Auto,
                        label: Tr.mark("Automatic")
                    },
                    {
                        value: TemperatureUnit.Celsius,
                        label: Tr.mark("°C")
                    },
                    {
                        value: TemperatureUnit.Fahrenheit,
                        label: Tr.mark("°F")
                    },
                    {
                        value: TemperatureUnit.Kelvin,
                        label: Tr.mark("K")
                    }
                ]
            },
            "c:services.dataUnits": {
                route: "language",
                section: Tr.mark("Units"),
                title: Tr.mark("Data sizes"),
                desc: Tr.mark("Units for data sizes and network speeds"),
                keywords: [Tr.mark("data"), Tr.mark("size"), Tr.mark("bytes"), Tr.mark("kib"), Tr.mark("mib"), Tr.mark("kb"), Tr.mark("mb"), Tr.mark("binary"), Tr.mark("decimal"), Tr.mark("network speed"), Tr.mark("units")],
                type: "enum",
                options: [
                    {
                        value: DataUnit.Binary,
                        label: Tr.mark("Binary (KiB, MiB)")
                    },
                    {
                        value: DataUnit.Decimal,
                        label: Tr.mark("Decimal (KB, MB)")
                    }
                ]
            },
            "c:services.clockFormat": {
                route: "language",
                section: Tr.mark("Time & date"),
                title: Tr.mark("Clock format"),
                desc: Tr.mark("How times are shown across the shell"),
                keywords: [Tr.mark("clock"), Tr.mark("time"), Tr.mark("12-hour"), Tr.mark("24-hour"), Tr.mark("am"), Tr.mark("pm"), Tr.mark("format")],
                type: "enum",
                options: [
                    {
                        value: ClockFormat.Auto,
                        label: Tr.mark("Automatic")
                    },
                    {
                        value: ClockFormat.TwelveHour,
                        label: Tr.mark("12-hour")
                    },
                    {
                        value: ClockFormat.TwentyFourHour,
                        label: Tr.mark("24-hour")
                    }
                ]
            },
            // caelestia4: with the weather location (it was an Advanced section of two rows). The location row stays
            // usable with GPS on: Caelestia's own weather (adapters/Weather.qml) still reads it
            "e4:bar.weather.enableGPS": {
                route: "language",
                section: Tr.mark("Weather"),
                title: Tr.mark("Find weather location by GPS"),
                desc: Tr.mark("The desktop widgets and the lock screen find the place by GPS (GeoClue) instead of the weather location. Off: they use the weather location"),
                keywords: [Tr.mark("weather"), Tr.mark("gps"), Tr.mark("location"), Tr.mark("geoclue"), Tr.mark("position"), Tr.mark("automatic")],
                type: "bool"
            },
            "e4:time.dateFormat": {
                route: "language",
                section: Tr.mark("Time & date"),
                title: Tr.mark("Long date format"),
                desc: Tr.mark("How the date reads on the desktop's digital clock"),
                keywords: [Tr.mark("date"), Tr.mark("format"), Tr.mark("day"), Tr.mark("month"), Tr.mark("year"), Tr.mark("clock"), Tr.mark("desktop"), Tr.mark("widget")],
                type: "string",
                // caelestia4: Qt date formats (QLocale::toString). The page (LanguageAndRegion.qml) shows each as
                // today's date and has a "Custom…" item for any other format
                options: [
                    {
                        value: "ddd, dd/MM",
                        label: Tr.mark("Short day, day/month")
                    },
                    {
                        value: "dddd, d MMMM",
                        label: Tr.mark("Day name, day and month name")
                    },
                    {
                        value: "dd/MM/yyyy",
                        label: Tr.mark("Day/month/year")
                    },
                    {
                        value: "MM/dd/yyyy",
                        label: Tr.mark("Month/day/year")
                    },
                    {
                        value: "yyyy-MM-dd",
                        label: Tr.mark("Year-month-day")
                    },
                    {
                        value: "d MMM yyyy",
                        label: Tr.mark("Day, short month name, year")
                    }
                ]
            }
        })
}
