import QtQuick
import Caelestia.I18n

// caelestia4: Nexus registry entries for the "hyprland" page (merged by Registry.qml). See RegPanels.qml for the format.
// "h:" defaults are what dots/.config/hypr/hyprland/general.lua sets (Hyprland's own default where it sets nothing):
// a reset removes the key from the shell overrides file, so the option goes back to that.
// `risky: true`: the option can blank or break the display on some GPUs; the row asks to keep the change and reverts it
// after 10 s (pages/hyprland/KeepRevert.qml).
QtObject {
    readonly property var entries: ({
            // Hyprland > Keyboard, mouse & touchpad (pages/hyprland/HyprInputPage.qml)
            "h:input:kb_layout": {
                route: "hyprland/input",
                section: Tr.mark("Keyboard"),
                title: Tr.mark("Layouts"),
                desc: Tr.mark("Comma separated, e.g. us,de. An input method (fcitx5) is separate: Super+Space switches it"),
                keywords: [Tr.mark("keyboard"), Tr.mark("layout"), Tr.mark("language"), Tr.mark("xkb"), Tr.mark("keymap")],
                type: "string",
                validate: "^[A-Za-z0-9_,-]*$",
                default: "us"
            },
            "h:input:kb_variant": {
                route: "hyprland/input",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Layout variants"),
                desc: Tr.mark("One per layout, comma separated in the same order, e.g. nodeadkeys"),
                keywords: [Tr.mark("keyboard"), Tr.mark("variant"), Tr.mark("xkb"), Tr.mark("dead keys")],
                type: "string",
                validate: "^[A-Za-z0-9_,-]*$",
                advanced: true,
                default: ""
            },
            "h:input:kb_options": {
                route: "hyprland/input",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Layout options"),
                desc: Tr.mark("Extra keyboard rules, e.g. grp:alt_shift_toggle (Alt+Shift switches layout) or caps:escape"),
                keywords: [Tr.mark("keyboard"), Tr.mark("xkb"), Tr.mark("options"), Tr.mark("caps lock"), Tr.mark("compose"), Tr.mark("switch layout")],
                type: "string",
                advanced: true,
                default: ""
            },
            "h:input:repeat_delay": {
                route: "hyprland/input",
                section: Tr.mark("Keyboard"),
                title: Tr.mark("Key repeat delay"),
                desc: Tr.mark("How long to hold a key before it starts repeating"),
                keywords: [Tr.mark("keyboard"), Tr.mark("repeat"), Tr.mark("delay"), Tr.mark("hold")],
                type: "int",
                unit: "ms",
                min: 100,
                max: 1000,
                step: 25,
                default: 250
            },
            "h:input:repeat_rate": {
                route: "hyprland/input",
                section: Tr.mark("Keyboard"),
                title: Tr.mark("Key repeat rate"),
                desc: Tr.mark("Characters per second while a key is held"),
                keywords: [Tr.mark("keyboard"), Tr.mark("repeat"), Tr.mark("rate"), Tr.mark("speed")],
                type: "int",
                min: 5,
                max: 80,
                step: 1,
                default: 35
            },
            "h:input:numlock_by_default": {
                route: "hyprland/input",
                section: Tr.mark("Keyboard"),
                title: Tr.mark("Num Lock on at login"),
                desc: Tr.mark("The number pad types numbers right away"),
                keywords: [Tr.mark("keyboard"), Tr.mark("num lock"), Tr.mark("numpad"), Tr.mark("login")],
                type: "bool",
                default: true
            },
            "h:input:sensitivity": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Pointer speed"),
                desc: Tr.mark("Mouse and touchpad. Below 0 is slower, above 0 faster; 0 keeps the device's speed"),
                keywords: [Tr.mark("mouse"), Tr.mark("touchpad"), Tr.mark("pointer"), Tr.mark("speed"), Tr.mark("sensitivity"), Tr.mark("dpi")],
                type: "real",
                min: -1,
                max: 1,
                step: 0.05,
                default: 0
            },
            "h:input:accel_profile": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Acceleration"),
                desc: Tr.mark("How the pointer speeds up when you move the mouse fast"),
                keywords: [Tr.mark("mouse"), Tr.mark("acceleration"), Tr.mark("flat"), Tr.mark("raw input"), Tr.mark("adaptive")],
                type: "enum",
                options: [
                    {
                        value: "",
                        label: Tr.mark("Device default")
                    },
                    {
                        value: "adaptive",
                        label: Tr.mark("Adaptive")
                    },
                    {
                        value: "flat",
                        label: Tr.mark("Flat (raw, for games)")
                    }
                ],
                default: ""
            },
            "h:input:scroll_factor": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Scroll speed"),
                desc: Tr.mark("How far one wheel step scrolls; 1 keeps the normal distance"),
                keywords: [Tr.mark("mouse"), Tr.mark("scroll"), Tr.mark("wheel"), Tr.mark("speed")],
                type: "real",
                min: 0.2,
                max: 2,
                step: 0.1,
                default: 1
            },
            "h:input:natural_scroll": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Natural scrolling"),
                desc: Tr.mark("Content moves with the wheel, like a touchscreen"),
                keywords: [Tr.mark("mouse"), Tr.mark("scroll"), Tr.mark("natural"), Tr.mark("reverse"), Tr.mark("invert")],
                type: "bool",
                default: false
            },
            "h:input:follow_mouse": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Focus follows the mouse"),
                desc: Tr.mark("Whether pointing at a window is enough to type into it"),
                keywords: [Tr.mark("focus"), Tr.mark("mouse"), Tr.mark("hover"), Tr.mark("click to focus"), Tr.mark("sloppy")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.mark("Off (click to focus)")
                    },
                    {
                        value: 1,
                        label: Tr.mark("Always")
                    },
                    {
                        value: 2,
                        label: Tr.mark("Loose (keyboard stays)")
                    },
                    {
                        value: 3,
                        label: Tr.mark("Only on click")
                    }
                ],
                default: 1
            },
            "h:input:left_handed": {
                route: "hyprland/input",
                section: Tr.mark("Mouse"),
                title: Tr.mark("Left-handed"),
                desc: Tr.mark("Swaps the left and right buttons"),
                keywords: [Tr.mark("mouse"), Tr.mark("left handed"), Tr.mark("swap buttons"), Tr.mark("primary button")],
                type: "bool",
                default: false
            },
            // caelestia4: touchpad (HyprInputPage's "Touchpad" section; it notes when no touchpad is connected).
            // Defaults: what general.lua sets, else Hyprland's. Hyprland 0.57 sets the swipe itself with hl.gesture
            // lines in general.lua (4 fingers sideways = workspaces), so only its options are here
            "h:input:touchpad:tap_to_click": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Tap to click"),
                desc: Tr.mark("A light tap clicks, without pressing the pad down"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("tap"), Tr.mark("click"), Tr.mark("laptop")],
                type: "bool",
                default: true
            },
            "h:input:touchpad:clickfinger_behavior": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Right-click with two fingers"),
                desc: Tr.mark("Pressing the pad with two fingers right-clicks, three fingers middle-clicks. Off: click the pad's corners"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("right click"), Tr.mark("two fingers"), Tr.mark("clickfinger")],
                type: "bool",
                default: true
            },
            "h:input:touchpad:disable_while_typing": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Ignore the touchpad while typing"),
                desc: Tr.mark("Your palm can't move the pointer while you type"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("typing"), Tr.mark("palm"), Tr.mark("disable")],
                type: "bool",
                default: true
            },
            "h:input:touchpad:natural_scroll": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Natural scrolling"),
                desc: Tr.mark("Content follows your fingers, like a phone"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("scroll"), Tr.mark("natural"), Tr.mark("reverse"), Tr.mark("invert")],
                type: "bool",
                default: true
            },
            "h:input:touchpad:scroll_factor": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Scroll speed"),
                desc: Tr.mark("How far a two-finger swipe scrolls; 1 keeps the normal distance"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("scroll"), Tr.mark("speed"), Tr.mark("two fingers")],
                type: "real",
                min: 0.1,
                max: 2,
                step: 0.05,
                default: 0.7
            },
            "h:gestures:workspace_swipe_invert": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Workspaces follow your fingers"),
                desc: Tr.mark("A four-finger swipe sideways drags the workspaces with it. Off: they move the other way"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("gesture"), Tr.mark("swipe"), Tr.mark("workspace"), Tr.mark("invert")],
                type: "bool",
                default: true
            },
            "h:gestures:workspace_swipe_create_new": {
                route: "hyprland/input",
                section: Tr.mark("Touchpad"),
                title: Tr.mark("Swipe past the last workspace for a new one"),
                keywords: [Tr.mark("touchpad"), Tr.mark("trackpad"), Tr.mark("gesture"), Tr.mark("swipe"), Tr.mark("workspace"), Tr.mark("new")],
                type: "bool",
                default: true
            },
            "h:cursor:inactive_timeout": {
                route: "hyprland/input",
                section: Tr.mark("Cursor"),
                title: Tr.mark("Hide when the mouse is still"),
                desc: Tr.mark("Hides the pointer after this long; 0 never hides it"),
                keywords: [Tr.mark("cursor"), Tr.mark("pointer"), Tr.mark("hide"), Tr.mark("timeout"), Tr.mark("idle")],
                type: "int",
                unit: "s",
                min: 0,
                max: 20,
                step: 1,
                default: 0
            },
            "h:cursor:hide_on_key_press": {
                route: "hyprland/input",
                section: Tr.mark("Cursor"),
                title: Tr.mark("Hide while typing"),
                desc: Tr.mark("The pointer comes back when the mouse moves"),
                keywords: [Tr.mark("cursor"), Tr.mark("pointer"), Tr.mark("hide"), Tr.mark("typing"), Tr.mark("keyboard")],
                type: "bool",
                default: false
            },
            "h:cursor:no_hardware_cursors": {
                route: "hyprland/input",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Software cursor"),
                desc: Tr.mark("Fixes an invisible or flickering pointer. Automatic turns it on where needed (NVIDIA)"),
                keywords: [Tr.mark("cursor"), Tr.mark("hardware cursor"), Tr.mark("software cursor"), Tr.mark("nvidia"), Tr.mark("invisible cursor"), Tr.mark("flicker")],
                type: "enum",
                options: [
                    {
                        value: 2,
                        label: Tr.mark("Automatic")
                    },
                    {
                        value: 0,
                        label: Tr.mark("Hardware cursor")
                    },
                    {
                        value: 1,
                        label: Tr.mark("Software cursor")
                    }
                ],
                advanced: true,
                risky: true,
                default: 2
            },

            // Hyprland > Windows & effects (pages/hyprland/HyprWindowsPage.qml)
            "h:general:gaps_in": {
                route: "hyprland/windows",
                section: Tr.mark("Spacing & borders"),
                title: Tr.mark("Gap between windows"),
                desc: Tr.mark("Space between tiled windows"),
                keywords: [Tr.mark("gaps"), Tr.mark("spacing"), Tr.mark("padding"), Tr.mark("windows")],
                type: "int",
                unit: "px",
                min: 0,
                max: 40,
                step: 1,
                default: 4
            },
            "h:general:gaps_out": {
                route: "hyprland/windows",
                section: Tr.mark("Spacing & borders"),
                title: Tr.mark("Gap to the screen edge"),
                desc: Tr.mark("Space between windows and the edges of the screen"),
                keywords: [Tr.mark("gaps"), Tr.mark("spacing"), Tr.mark("margin"), Tr.mark("screen edge")],
                type: "int",
                unit: "px",
                min: 0,
                max: 60,
                step: 1,
                default: 5
            },
            "h:general:border_size": {
                route: "hyprland/windows",
                section: Tr.mark("Spacing & borders"),
                title: Tr.mark("Window border"),
                desc: Tr.mark("Width of the coloured line around windows; 0 = none"),
                keywords: [Tr.mark("border"), Tr.mark("outline"), Tr.mark("width"), Tr.mark("windows")],
                type: "int",
                unit: "px",
                min: 0,
                max: 10,
                step: 1,
                default: 1
            },
            "h:decoration:rounding": {
                route: "hyprland/windows",
                section: Tr.mark("Spacing & borders"),
                title: Tr.mark("Window corner radius"),
                desc: Tr.mark("0 = square corners"),
                keywords: [Tr.mark("rounding"), Tr.mark("corners"), Tr.mark("radius"), Tr.mark("rounded")],
                type: "int",
                unit: "px",
                min: 0,
                max: 40,
                step: 1,
                default: 18
            },
            "h:decoration:active_opacity": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Focused window opacity"),
                desc: Tr.mark("100 % is solid; lower lets the desktop show through"),
                keywords: [Tr.mark("opacity"), Tr.mark("transparency"), Tr.mark("transparent"), Tr.mark("focused"), Tr.mark("active")],
                type: "real",
                min: 0.3,
                max: 1,
                step: 0.05,
                unit: "%",
                scale: 100,
                default: 1
            },
            "h:decoration:inactive_opacity": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Other windows opacity"),
                desc: Tr.mark("100 % is solid; lower lets the desktop show through"),
                keywords: [Tr.mark("opacity"), Tr.mark("transparency"), Tr.mark("transparent"), Tr.mark("unfocused"), Tr.mark("inactive")],
                type: "real",
                min: 0.3,
                max: 1,
                step: 0.05,
                unit: "%",
                scale: 100,
                default: 1
            },
            "h:decoration:dim_inactive": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Dim unfocused windows"),
                desc: Tr.mark("Windows you aren't using are drawn a little darker"),
                keywords: [Tr.mark("dim"), Tr.mark("darken"), Tr.mark("unfocused"), Tr.mark("inactive")],
                type: "bool",
                default: true
            },
            "h:decoration:blur:enabled": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Blur behind transparent windows"),
                desc: Tr.mark("Costs some GPU on every frame"),
                keywords: [Tr.mark("blur"), Tr.mark("frosted glass"), Tr.mark("transparency"), Tr.mark("gpu")],
                type: "bool",
                default: true
            },
            "h:decoration:blur:size": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Blur radius"),
                desc: Tr.mark("Larger is softer but uses more GPU"),
                keywords: [Tr.mark("blur"), Tr.mark("radius"), Tr.mark("size"), Tr.mark("strength")],
                type: "int",
                min: 1,
                max: 20,
                step: 1,
                default: 10,
                requires: {
                    id: "h:decoration:blur:enabled",
                    value: true
                }
            },
            "h:decoration:blur:passes": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Blur passes"),
                desc: Tr.mark("More is smoother but uses more GPU"),
                keywords: [Tr.mark("blur"), Tr.mark("passes"), Tr.mark("quality"), Tr.mark("gpu")],
                type: "int",
                min: 1,
                max: 6,
                step: 1,
                default: 3,
                requires: {
                    id: "h:decoration:blur:enabled",
                    value: true
                }
            },
            "h:decoration:shadow:enabled": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Window shadows"),
                desc: Tr.mark("A soft shadow around each window"),
                keywords: [Tr.mark("shadow"), Tr.mark("drop shadow"), Tr.mark("windows")],
                type: "bool",
                default: true
            },
            "h:animations:enabled": {
                route: "hyprland/windows",
                section: Tr.mark("Effects"),
                title: Tr.mark("Window animations"),
                desc: Tr.mark("Windows and workspaces slide and fade; off makes everything instant"),
                keywords: [Tr.mark("animations"), Tr.mark("motion"), Tr.mark("transitions"), Tr.mark("effects"), Tr.mark("fast")],
                type: "bool",
                default: true
            },
            "h:general:layout": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Tiling layout"),
                desc: Tr.mark("How new windows share the screen"),
                keywords: [Tr.mark("layout"), Tr.mark("tiling"), Tr.mark("dwindle"), Tr.mark("master"), Tr.mark("windows")],
                type: "enum",
                options: [
                    {
                        value: "dwindle",
                        label: Tr.mark("Dwindle (split in two)")
                    },
                    {
                        value: "master",
                        label: Tr.mark("Master (one big window)")
                    }
                ],
                default: "dwindle"
            },
            "h:dwindle:preserve_split": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Keep split direction"),
                desc: Tr.mark("Dwindle layout: splits don't flip when windows move"),
                keywords: [Tr.mark("dwindle"), Tr.mark("split"), Tr.mark("direction"), Tr.mark("tiling")],
                type: "bool",
                default: true,
                requires: {
                    id: "h:general:layout",
                    value: "dwindle"
                }
            },
            "h:general:resize_on_border": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Resize by dragging the border"),
                desc: Tr.mark("Grab a window's edge with the mouse to resize it"),
                keywords: [Tr.mark("resize"), Tr.mark("border"), Tr.mark("drag"), Tr.mark("windows")],
                type: "bool",
                default: true
            },
            "h:misc:focus_on_activate": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Focus apps that ask for attention"),
                desc: Tr.mark("e.g. a browser opened from a link jumps to the front"),
                keywords: [Tr.mark("focus"), Tr.mark("activate"), Tr.mark("attention"), Tr.mark("urgent"), Tr.mark("steal focus")],
                type: "bool",
                default: true
            },
            "h:misc:middle_click_paste": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Middle-click paste"),
                desc: Tr.mark("Paste the last selected text with the middle mouse button"),
                keywords: [Tr.mark("middle click"), Tr.mark("paste"), Tr.mark("primary selection"), Tr.mark("clipboard")],
                type: "bool",
                default: true
            },
            // While ~/.config/caelestia4/special-ws-scratchpad-only exists, Super+S only toggles the scratchpad
            "x:hyprland.specialWsCloseAny": {
                route: "hyprland/windows",
                section: Tr.mark("Tiling & focus"),
                title: Tr.mark("Super+S closes any special workspace"),
                desc: Tr.mark("Off: Super+S only shows or hides the scratchpad"),
                keywords: [Tr.mark("special workspace"), Tr.mark("scratchpad"), Tr.mark("super+s"), Tr.mark("shortcut")],
                type: "bool",
                default: true
            },

            // Hyprland > Rendering & games (pages/hyprland/HyprRenderingPage.qml)
            "h:render:direct_scanout": {
                route: "hyprland/rendering",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Direct scanout"),
                desc: Tr.mark("Fullscreen windows go straight to the display: less latency; may flicker on some GPUs"),
                keywords: [Tr.mark("direct scanout"), Tr.mark("latency"), Tr.mark("fullscreen"), Tr.mark("games"), Tr.mark("flicker")],
                type: "enum",
                options: [
                    {
                        value: 0,
                        label: Tr.mark("Off")
                    },
                    {
                        value: 1,
                        label: Tr.mark("On")
                    },
                    {
                        value: 2,
                        label: Tr.mark("Games only")
                    }
                ],
                advanced: true,
                risky: true,
                default: 0
            },
            "h:general:allow_tearing": {
                route: "hyprland/rendering",
                section: Tr.mark("Latency"),
                title: Tr.mark("Allow tearing"),
                desc: Tr.mark("Games that ask for it skip vsync: lowest input lag, with a visible tear line"),
                keywords: [Tr.mark("tearing"), Tr.mark("vsync"), Tr.mark("latency"), Tr.mark("immediate"), Tr.mark("games")],
                type: "bool",
                risky: true,
                default: true
            },
            "h:xwayland:force_zero_scaling": {
                route: "hyprland/rendering",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Sharp X11 apps on scaled displays"),
                desc: Tr.mark("X11 apps draw at scale 1 instead of being stretched (they may look smaller)"),
                keywords: [Tr.mark("xwayland"), Tr.mark("x11"), Tr.mark("scaling"), Tr.mark("blurry"), Tr.mark("hidpi")],
                type: "bool",
                applies: "appRestart",
                advanced: true,
                default: true
            },
            "e4:caelestia.backgroundMute.enable": {
                route: "hyprland/rendering",
                section: Tr.mark("Games in the background"),
                title: Tr.mark("Mute games while in the background"),
                desc: Tr.mark("A game's sound stops when you switch away and comes back when you click into it"),
                keywords: [Tr.mark("games"), Tr.mark("mute"), Tr.mark("sound"), Tr.mark("audio"), Tr.mark("background"), Tr.mark("focus")],
                type: "bool"
            },
            "e4:caelestia.backgroundMute.classes": {
                route: "hyprland/rendering",
                section: Tr.mark("Advanced"),
                title: Tr.mark("Which windows are games"),
                desc: Tr.mark("A window class, or a pattern such as steam_app_.* (Steam and Proton games)"),
                keywords: [Tr.mark("games"), Tr.mark("window class"), Tr.mark("regex"), Tr.mark("steam"), Tr.mark("proton"), Tr.mark("mute")],
                type: "string",
                advanced: true,
                requires: {
                    id: "e4:caelestia.backgroundMute.enable",
                    value: true
                }
            },
            "h:misc:render_unfocused_fps": {
                route: "hyprland/rendering",
                section: Tr.mark("Games in the background"),
                title: Tr.mark("Frame rate in the background"),
                desc: Tr.mark("Frames per second for apps you can't see, such as a game behind another window. Lower saves power"),
                keywords: [Tr.mark("fps"), Tr.mark("frame rate"), Tr.mark("background"), Tr.mark("unfocused"), Tr.mark("games"), Tr.mark("power")],
                type: "int",
                min: 1,
                max: 240,
                step: 5,
                default: 15
            },

            // Hyprland > Keyboard shortcuts (pages/hyprland/KeybindsPage.qml): a list editor, so no row of its own;
            // changes go to ~/.config/hypr/custom/nexus-keybinds.lua (scripts/caelestia4/nexus-keybinds.py)
            "x:hyprland.keybinds": {
                route: "hyprland/keybinds",
                title: Tr.mark("Keyboard shortcuts"),
                desc: Tr.mark("Change, turn off or add shortcuts"),
                keywords: [Tr.mark("shortcut"), Tr.mark("keybind"), Tr.mark("hotkey"), Tr.mark("keys"), Tr.mark("super"), Tr.mark("bind"), Tr.mark("rebind")],
                type: "list",
                noRow: true
            }
        })
}
