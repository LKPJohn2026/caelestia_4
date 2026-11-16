pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import Caelestia.I18n
import qs.modules.caelestia.adapters
import qs.modules.caelestia.nexus.common
import qs.modules.common as E4C // caelestia4: keep (end-4's desktop clock)
import qs.services as E4 // caelestia4: keep (PresetLayout: widget on or off, saved to the preset)

// caelestia4: Wallpaper & style > Desktop > Clock (route appearance/desktop/widget.clock). One clock on the desktop:
// Caelestia's (background.desktopClock) or end4-pC's widget (background.widgets.clock) in one of its styles. Show
// (on/off) first, as on the other widget pages, then General (style, size, placement), a section for the chosen clock
// only, Font (end-4's clocks), and Advanced with that clock's details (none for the daily and pixel clocks, so no
// Advanced there). While the clock is off, the rows are the style it comes back in. Rows name their registry setting
// (registry/RegWidgetsA.qml)
PageBase {
    id: root

    title: Tr.tr("Clock")
    isSubPage: true

    readonly property var clock: E4C.Config.options.background.widgets.clock
    readonly property string desktopClock: clock.enable ? clock.style : (Config.background.desktopClock.enabled ? "caelestia" : "none")
    readonly property bool clockOn: desktopClock !== "none"
    // caelestia4: the style Show turns the clock back on in: the one it had when turned off here, or one picked since
    property string pickedStyle
    // The style the rows are for: the clock's, or (off) the one Show brings back: the picked one, else end-4's last
    // style, as Desktop's widget list does
    readonly property string shownStyle: clockOn ? desktopClock : (pickedStyle || clock.style)
    readonly property bool caelestiaClock: shownStyle === "caelestia"
    readonly property bool end4Clock: !caelestiaClock
    readonly property string styleTitle: {
        switch (shownStyle) {
        case "caelestia":
            return Tr.tr("Caelestia's clock");
        case "cookie":
            return Tr.tr("Cookie clock");
        case "digital":
            return Tr.tr("Digital clock");
        case "daily":
            return Tr.tr("Daily clock");
        case "pixel":
            return Tr.tr("Pixel clock");
        }
        return "";
    }

    // x:desktop.clock: Caelestia's clock, one of end-4's styles, or none. end-4's goes on through PresetLayout, so a
    // new widget isn't left under another and the preset is saved
    function setDesktopClock(v: string): void {
        // caelestia4: off keeps the style it had, so Show (or undo) brings back the same clock, Caelestia's too
        if (v === "none" && root.clockOn)
            root.pickedStyle = root.desktopClock;
        const end4 = ["cookie", "digital", "daily", "pixel"].includes(v);
        GlobalConfig.background.desktopClock.enabled = v === "caelestia";
        if (end4) {
            root.clock.style = v;
            root.clock.styleLocked = v;
        }
        if (end4 !== root.clock.enable)
            E4.PresetLayout.setWidgetEnabled("clock", end4);
        else
            E4.PresetLayout.requestSave();
    }

    // x:desktop.clock: the style. While the clock is off it is only remembered (end-4's in its own key)
    function pickStyle(v: string): void {
        if (root.clockOn) {
            root.setDesktopClock(v);
            return;
        }
        root.pickedStyle = v;
        if (v !== "caelestia") {
            root.clock.style = v;
            root.clock.styleLocked = v;
        }
    }

    // caelestia4: rows shown for one clock or one style only. A route or search result that names a hidden one lands
    // on the picker that shows it (PageBase can't scroll to a hidden row). end-4's own on/off and style are the picker
    readonly property var shownFor: ({
            "e4:background.widgets.clock.enable": "show",
            "e4:background.widgets.clock.style": "never",
            "c:background.desktopClock.scale": "caelestia",
            "c:background.desktopClock.position": "caelestia",
            "e4:caelestia.desktopWeather": "caelestia",
            "c:background.desktopClock.background.enabled": "caelestia",
            "c:background.desktopClock.shadow.enabled": "caelestia",
            "c:background.desktopClock.invertColors": "caelestia",
            "c:background.desktopClock.background.blur": "caelestia",
            "c:background.desktopClock.background.opacity": "caelestia",
            "c:background.desktopClock.shadow.opacity": "caelestia",
            "c:background.desktopClock.shadow.blur": "caelestia",
            "e4:background.widgets.clock.placementStrategy": "end4",
            "e4:background.widgets.clock.quote.followClock": "end4",
            "e4:background.widgets.clock.cookie.aiStyling": "cookie",
            "e4:background.widgets.clock.cookie.dialNumberStyle": "cookie",
            "e4:background.widgets.clock.cookie.dateStyle": "cookie",
            "e4:background.widgets.clock.cookie.timeIndicators": "cookie",
            "e4:background.widgets.clock.cookie.hourMarks": "cookie",
            "e4:background.widgets.clock.cookie.hourHandStyle": "cookie",
            "e4:background.widgets.clock.cookie.minuteHandStyle": "cookie",
            "e4:time.secondPrecision": "cookie",
            "e4:background.widgets.clock.cookie.secondHandStyle": "cookie",
            "e4:background.widgets.clock.cookie.sides": "cookie",
            "e4:background.widgets.clock.cookie.useSineCookie": "cookie",
            "e4:background.widgets.clock.cookie.constantlyRotate": "cookie",
            "e4:background.widgets.clock.digital.showDate": "digital",
            "e4:background.widgets.clock.digital.vertical": "digital",
            "e4:background.widgets.clock.digital.animateChange": "digital",
            "e4:background.widgets.clock.digital.font.family": "font",
            "e4:background.widgets.clock.digital.font.size": "digital",
            "e4:background.widgets.clock.digital.font.weight": "digital",
            "e4:background.widgets.clock.digital.font.width": "digital",
            "e4:background.widgets.clock.digital.font.roundness": "digital",
            "e4:background.widgets.clock.digital.adaptiveAlignment": "digital",
            "e4:background.widgets.clock.daily.variant": "daily",
            "e4:background.widgets.clock.pixel.orientation": "pixel",
            "e4:background.widgets.clock.color": "colour",
            "e4:background.widgets.clock.quote.enable": "quote",
            "e4:background.widgets.clock.quote.text": "quote"
        })

    function shown(group: string): bool {
        switch (group) {
        case "never":
        case "show":
            return false;
        case "end4":
            return root.end4Clock;
        case "font":
            // caelestia4: the digital clock's time always uses it; every end-4 clock's text does with followClock on
            return root.shownStyle === "digital" || (root.end4Clock && root.clock.quote.followClock);
        case "advanced":
            return ["caelestia", "cookie", "digital"].includes(root.shownStyle);
        case "colour":
            return root.shownStyle === "digital" || root.shownStyle === "daily";
        case "quote":
            return ["cookie", "digital", "pixel"].includes(root.shownStyle);
        }
        return root.shownStyle === group;
    }

    function landOnShown(): void {
        const key = root.nState?.focusKey ?? "";
        const group = root.shownFor[key];
        if (group && !root.shown(group))
            // caelestia4: the hidden Font row is turned on by followClock, so land there when it is on screen
            root.nState.focusKey = group === "show" ? "x:desktop.clock.show" : group === "font" && root.end4Clock ? "e4:background.widgets.clock.quote.followClock" : "x:desktop.clock";
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
            id: showRow

            setting: "x:desktop.clock.show"

            Binding {
                target: showRow.link.s
                property: "customValue"
                value: root.clockOn
            }

            Binding {
                target: showRow.link.s
                property: "customDefault"
                value: false
            }

            Connections {
                function onCustomSet(v: var): void {
                    root.setDesktopClock(v ? root.shownStyle : "none");
                }

                function onCustomReset(): void {
                    root.setDesktopClock("none");
                }

                target: showRow.link.s
            }
        }

        SectionHeader {
            text: Tr.tr("General")
        }

        SelectRow {
            id: clockRow

            setting: "x:desktop.clock"

            Binding {
                target: clockRow.link.s
                property: "customValue"
                value: root.shownStyle
            }

            // end-4's clock in its first style, as a new install has it
            Binding {
                target: clockRow.link.s
                property: "customDefault"
                value: "cookie"
            }

            Connections {
                function onCustomSet(v: var): void {
                    root.pickStyle(v);
                }

                function onCustomReset(): void {
                    root.pickStyle("cookie");
                }

                target: clockRow.link.s
            }
        }

        StepperRow {
            visible: root.shown("caelestia")
            setting: "c:background.desktopClock.scale"
        }

        SelectRow {
            visible: root.shown("caelestia")
            setting: "c:background.desktopClock.position"
        }

        StepperRow {
            visible: root.shown("digital")
            setting: "e4:background.widgets.clock.digital.font.size"
        }

        // caelestia4: the cookie, daily and pixel clocks have a set size (no option), so say so where Size would be
        InfoRow {
            visible: ["cookie", "daily", "pixel"].includes(root.shownStyle)
            label: Tr.tr("Size")
            value: Tr.tr("Fixed")
            subtext: Tr.tr("This clock has one size. The digital clock and Caelestia's clock can be resized")
        }

        SelectRow {
            visible: root.shown("end4")
            setting: "e4:background.widgets.clock.placementStrategy"
        }

        // The chosen clock's own options
        SectionHeader {
            text: root.styleTitle
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "e4:caelestia.desktopWeather"
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "c:background.desktopClock.background.enabled"
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "c:background.desktopClock.shadow.enabled"
        }

        ToggleRow {
            visible: root.shown("caelestia")
            setting: "c:background.desktopClock.invertColors"
        }

        ToggleRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.aiStyling"
        }

        SelectRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.dialNumberStyle"
        }

        SelectRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.dateStyle"
        }

        ToggleRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.timeIndicators"
        }

        ToggleRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.hourMarks"
        }

        ToggleRow {
            visible: root.shown("digital")
            setting: "e4:background.widgets.clock.digital.showDate"
        }

        ToggleRow {
            visible: root.shown("digital")
            setting: "e4:background.widgets.clock.digital.vertical"
        }

        ToggleRow {
            visible: root.shown("digital")
            setting: "e4:background.widgets.clock.digital.animateChange"
        }

        SelectRow {
            visible: root.shown("daily")
            setting: "e4:background.widgets.clock.daily.variant"
        }

        SegmentedRow {
            visible: root.shown("pixel")
            setting: "e4:background.widgets.clock.pixel.orientation"
        }

        // The digital and daily clocks
        SelectRow {
            visible: root.shown("colour")
            setting: "e4:background.widgets.clock.color"
        }

        SectionHeader {
            visible: root.shown("cookie")
            text: Tr.tr("Hands")
        }

        SelectRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.hourHandStyle"
        }

        SelectRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.minuteHandStyle"
        }

        ToggleRow {
            visible: root.shown("cookie")
            setting: "e4:time.secondPrecision"
        }

        SelectRow {
            visible: root.shown("cookie")
            setting: "e4:background.widgets.clock.cookie.secondHandStyle"
        }

        // caelestia4: end-4's clocks share one font (digital.font.family): the digital clock's time, and all clock text
        // with followClock on (ClockText.qml, CookieQuote.qml). The Font row shows whenever that font is in use
        SectionHeader {
            visible: root.shown("end4")
            text: Tr.tr("Font")
        }

        ToggleRow {
            visible: root.shown("end4")
            setting: "e4:background.widgets.clock.quote.followClock"
            subtext: root.shownStyle === "daily" ? Tr.tr("The daily clock's words and the status line use the font below, not the usual one") : link.desc
        }

        FontRow {
            visible: root.shown("font")
            setting: "e4:background.widgets.clock.digital.font.family"
            subtext: root.shownStyle === "digital" ? Tr.tr("The time's font. With the switch above on, the other clock text uses it too") : Tr.tr("Used for all of the clock's text")
        }

        // The cookie, digital and pixel clocks show it (ClockWidget.qml, DigitalClock.qml)
        SectionHeader {
            visible: root.shown("quote")
            text: Tr.tr("Quote")
        }

        ToggleRow {
            visible: root.shown("quote")
            setting: "e4:background.widgets.clock.quote.enable"
        }

        TextFieldRow {
            visible: root.shown("quote")
            setting: "e4:background.widgets.clock.quote.text"
            placeholderText: Tr.tr("Your quote")
        }

        // The chosen clock's details only (Caelestia's: card and shadow; end-4's: shape, font axes, fonts)
        AdvancedSection {
            visible: root.shown("advanced")

            ToggleRow {
                visible: root.shown("caelestia")
                setting: "c:background.desktopClock.background.blur"
            }

            SliderRow {
                visible: root.shown("caelestia")
                setting: "c:background.desktopClock.background.opacity"
            }

            SliderRow {
                visible: root.shown("caelestia")
                setting: "c:background.desktopClock.shadow.opacity"
            }

            SliderRow {
                visible: root.shown("caelestia")
                setting: "c:background.desktopClock.shadow.blur"
            }

            StepperRow {
                visible: root.shown("cookie")
                setting: "e4:background.widgets.clock.cookie.sides"
            }

            ToggleRow {
                visible: root.shown("cookie")
                setting: "e4:background.widgets.clock.cookie.useSineCookie"
            }

            ToggleRow {
                visible: root.shown("cookie")
                setting: "e4:background.widgets.clock.cookie.constantlyRotate"
            }

            SliderRow {
                visible: root.shown("digital")
                setting: "e4:background.widgets.clock.digital.font.weight"
            }

            SliderRow {
                visible: root.shown("digital")
                setting: "e4:background.widgets.clock.digital.font.width"
            }

            SliderRow {
                visible: root.shown("digital")
                setting: "e4:background.widgets.clock.digital.font.roundness"
            }

            ToggleRow {
                visible: root.shown("digital")
                setting: "e4:background.widgets.clock.digital.adaptiveAlignment"
            }

            // The digital clock's date: its format is Language & region's
            SettingLinkRow {
                visible: root.shown("digital") && !!entry
                nState: root.nState
                target: "e4:time.dateFormat"
            }
        }
    }
}
