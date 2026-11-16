import QtQuick
import Caelestia.I18n

// caelestia4: Hyprland key names as people say them ("SUPER + SHIFT + Slash" reads "Super + Shift + /"), the words for
// a shortcut that has no description in keybinds.lua, and the Hyprland name of a key pressed in Nexus (fromEvent)
QtObject {
    id: root

    readonly property var modNames: ({
            SUPER: "Super",
            CTRL: "Ctrl",
            ALT: "Alt",
            SHIFT: "Shift",
            CAPS: "Caps Lock",
            MOD2: "Num Lock",
            MOD3: "Mod3",
            MOD5: "AltGr"
        })
    readonly property var keyNames: ({
            slash: "/",
            backslash: "\\",
            period: ".",
            comma: ",",
            minus: "-",
            equal: "=",
            semicolon: ";",
            apostrophe: "'",
            grave: "`",
            bracketleft: "[",
            bracketright: "]",
            hash: "#",
            return: "Enter",
            escape: "Esc",
            backspace: "Backspace",
            delete: "Delete",
            insert: "Insert",
            space: Tr.trCtx("Space", "key"),
            tab: "Tab",
            home: "Home",
            end: "End",
            page_up: "Page Up",
            page_down: "Page Down",
            print: "Print Screen",
            left: "←",
            right: "→",
            up: "↑",
            down: "↓",
            super_l: Tr.trCtx("Super (left)", "key"),
            super_r: Tr.trCtx("Super (right)", "key"),
            alt_l: Tr.trCtx("Alt (left)", "key"),
            alt_r: Tr.trCtx("Alt (right)", "key"),
            caps_lock: "Caps Lock",
            num_lock: "Num Lock",
            "mouse:272": Tr.trCtx("Left click", "mouse button"),
            "mouse:273": Tr.trCtx("Right click", "mouse button"),
            "mouse:274": Tr.trCtx("Middle click", "mouse button"),
            "mouse:275": Tr.trCtx("Back button", "mouse button"),
            "mouse:276": Tr.trCtx("Forward button", "mouse button"),
            mouse_up: Tr.trCtx("Scroll up", "mouse wheel"),
            mouse_down: Tr.trCtx("Scroll down", "mouse wheel"),
            xf86audioraisevolume: Tr.trCtx("Volume up", "key"),
            xf86audiolowervolume: Tr.trCtx("Volume down", "key"),
            xf86audiomute: Tr.trCtx("Mute", "key"),
            xf86audiomicmute: Tr.trCtx("Mic mute", "key"),
            xf86audioplay: Tr.trCtx("Play", "key"),
            xf86audiopause: Tr.trCtx("Pause", "key"),
            xf86audionext: Tr.trCtx("Next track", "key"),
            xf86audioprev: Tr.trCtx("Previous track", "key"),
            xf86monbrightnessup: Tr.trCtx("Brightness up", "key"),
            xf86monbrightnessdown: Tr.trCtx("Brightness down", "key")
        })
    // Number-row and keypad key codes keybinds.lua binds beside the digits
    readonly property var digitCodes: ({
            "10": "1",
            "11": "2",
            "12": "3",
            "13": "4",
            "14": "5",
            "15": "6",
            "16": "7",
            "17": "8",
            "18": "9",
            "19": "0",
            "87": "1",
            "88": "2",
            "89": "3",
            "83": "4",
            "84": "5",
            "85": "6",
            "79": "7",
            "80": "8",
            "81": "9",
            "90": "0",
            "82": "-",
            "86": "+"
        })

    // "SUPER + SHIFT + Q" -> ["SUPER", "SHIFT"], "Q"
    function split(keys: string): var {
        const parts = String(keys).split("+").map(p => p.trim()).filter(p => p);
        const mods = [];
        let key = "";
        parts.forEach((p, i) => {
            if (root.modNames[p.toUpperCase()] !== undefined && i < parts.length - 1)
                mods.push(p.toUpperCase());
            else
                key = p;
        });
        return {
            mods: mods,
            key: key
        };
    }

    function keyLabel(key: string): string {
        const low = key.toLowerCase();
        if (root.keyNames[low] !== undefined)
            return root.keyNames[low];
        const code = /^code:(\d+)$/.exec(low);
        if (code) {
            const n = parseInt(code[1]);
            const d = root.digitCodes[code[1]];
            if (d !== undefined)
                return n >= 79 ? Tr.trCtx("Keypad %1", "key").arg(d) : d;
            return Tr.trCtx("Key %1", "a key known only by its number").arg(n);
        }
        if (low.startsWith("xf86"))
            return key.slice(4).replace(/([a-z])([A-Z])/g, "$1 $2");
        if (key.length === 1)
            return key.toUpperCase();
        return key.replace(/_/g, " ");
    }

    // "Super + Shift + Q"
    function label(keys: string): string {
        return root.parts(keys).join(" + ");
    }

    // ["Super", "Shift", "Q"]. A modifier key with only its own modifier is just the key: SUPER + SUPER_L is Super
    // (left) pressed alone
    function parts(keys: string): var {
        const k = root.split(keys);
        const own = {
            super_l: "SUPER",
            super_r: "SUPER",
            alt_l: "ALT",
            alt_r: "ALT",
            control_l: "CTRL",
            control_r: "CTRL",
            shift_l: "SHIFT",
            shift_r: "SHIFT"
        }[k.key.toLowerCase()];
        const mods = own ? k.mods.filter(m => m !== own) : k.mods;
        return [...mods.map(m => root.modNames[m]), root.keyLabel(k.key)];
    }

    // The words for a shortcut keybinds.lua gives no description (s: a shortcut from nexus-keybinds.py list)
    function actionWords(s: var): string {
        if (s.title)
            return s.title;
        const a = s.action ?? {};
        const args = a.args ?? {};
        const ws = String(args.workspace ?? "");
        const next = ws.indexOf("+") >= 0;
        // caelestia4: plain words for the shell's actions and the commands keybinds.lua runs, never their raw names
        switch (a.name) {
        case "global":
            {
                const g = String(args["1"] ?? "").replace(/^[a-z]+:/, "");
                switch (g) {
                case "workspaceNumber":
                    return Tr.tr("Show workspace numbers while held");
                case "overviewAltTabPrev":
                    return Tr.tr("Switch windows, backwards");
                case "overviewAltPressed":
                    return Tr.tr("Window switcher (Alt held)");
                case "sidebarLeftToggleDetach":
                    return Tr.tr("Detach or attach the left sidebar");
                case "brightnessUp":
                    return Tr.tr("Brightness up");
                case "brightnessDown":
                    return Tr.tr("Brightness down");
                }
                return Tr.tr("A shell action");
            }
        case "exec_cmd":
            {
                const cmd = String(args["1"] ?? "");
                if (/^wpctl set-volume .*%\+/.test(cmd))
                    return Tr.tr("Volume up");
                if (/^wpctl set-volume .*%-/.test(cmd))
                    return Tr.tr("Volume down");
                if (/record\.sh/.test(cmd))
                    return /--sound/.test(cmd) ? Tr.tr("Record the screen with sound") : Tr.tr("Record the screen");
                if (/notify-send/.test(cmd))
                    return Tr.tr("Send a test notification");
                const words = cmd.replace(/^(uwsm-app( -[a-zA-Z]+)* --|env( \S+=\S+)*) /, "").split(/\s+/);
                const prog = (words[0] ?? "").split("/").pop();
                return prog === "bash" || prog === "sh" ? Tr.tr("Run a script") : Tr.tr("Run %1").arg(prog);
            }
        case "focus":
            if (args.direction)
                return Tr.tr("Focus the window on that side");
            if (ws.startsWith("m"))
                return next ? Tr.tr("Next workspace with windows") : Tr.tr("Previous workspace with windows");
            if (/5$/.test(ws))
                return next ? Tr.tr("Five workspaces forward") : Tr.tr("Five workspaces back");
            return next ? Tr.tr("Next workspace") : Tr.tr("Previous workspace");
        case "window.move":
            return next ? Tr.tr("Send the window to the next workspace") : Tr.tr("Send the window to the previous workspace");
        case "window.drag":
            return Tr.tr("Move the window");
        case "window.resize":
            return args.x && args.y ? Tr.tr("Resize the window to %1 × %2").arg(args.x).arg(args.y) : Tr.tr("Resize the window");
        case "workspace.toggle_special":
            return Tr.tr("Show or hide the scratchpad");
        case "layout":
            return Tr.tr("Change the split between windows");
        }
        const key = root.split(s.keys ?? "").key.toLowerCase();
        if (/^code:8[26]$/.test(key))
            return key === "code:82" ? Tr.tr("Zoom out (keypad)") : Tr.tr("Zoom in (keypad)");
        if (s.submap === "virtual-machine")
            return Tr.tr("Enter or leave virtual machine mode");
        if (key === "f4" && root.split(s.keys).mods.join("+") === "ALT")
            return Tr.tr("Remind that Super + Q closes windows");
        return Tr.tr("Custom action");
    }

    // The Hyprland key name of a pressed key, "" for a modifier alone (Shift-ed symbols go back to their key: Hyprland
    // matches binds on the key, Shift is a modifier)
    readonly property var qtKeys: ({
            [Qt.Key_Slash]: "Slash",
            [Qt.Key_Question]: "Slash",
            [Qt.Key_Backslash]: "Backslash",
            [Qt.Key_Bar]: "Backslash",
            [Qt.Key_Period]: "Period",
            [Qt.Key_Greater]: "Period",
            [Qt.Key_Comma]: "Comma",
            [Qt.Key_Less]: "Comma",
            [Qt.Key_Minus]: "Minus",
            [Qt.Key_Underscore]: "Minus",
            [Qt.Key_Equal]: "Equal",
            [Qt.Key_Plus]: "Equal",
            [Qt.Key_Semicolon]: "Semicolon",
            [Qt.Key_Colon]: "Semicolon",
            [Qt.Key_Apostrophe]: "Apostrophe",
            [Qt.Key_QuoteDbl]: "Apostrophe",
            [Qt.Key_QuoteLeft]: "grave",
            [Qt.Key_AsciiTilde]: "grave",
            [Qt.Key_BracketLeft]: "BracketLeft",
            [Qt.Key_BraceLeft]: "BracketLeft",
            [Qt.Key_BracketRight]: "BracketRight",
            [Qt.Key_BraceRight]: "BracketRight",
            [Qt.Key_Exclam]: "1",
            [Qt.Key_At]: "2",
            [Qt.Key_NumberSign]: "3",
            [Qt.Key_Dollar]: "4",
            [Qt.Key_Percent]: "5",
            [Qt.Key_AsciiCircum]: "6",
            [Qt.Key_Ampersand]: "7",
            [Qt.Key_Asterisk]: "8",
            [Qt.Key_ParenLeft]: "9",
            [Qt.Key_ParenRight]: "0",
            [Qt.Key_Return]: "Return",
            [Qt.Key_Enter]: "Return",
            [Qt.Key_Escape]: "Escape",
            [Qt.Key_Space]: "Space",
            [Qt.Key_Tab]: "Tab",
            [Qt.Key_Backtab]: "Tab",
            [Qt.Key_Backspace]: "BackSpace",
            [Qt.Key_Delete]: "Delete",
            [Qt.Key_Insert]: "Insert",
            [Qt.Key_Home]: "Home",
            [Qt.Key_End]: "End",
            [Qt.Key_PageUp]: "Page_Up",
            [Qt.Key_PageDown]: "Page_Down",
            [Qt.Key_Left]: "Left",
            [Qt.Key_Right]: "Right",
            [Qt.Key_Up]: "Up",
            [Qt.Key_Down]: "Down",
            [Qt.Key_Print]: "Print",
            [Qt.Key_VolumeUp]: "XF86AudioRaiseVolume",
            [Qt.Key_VolumeDown]: "XF86AudioLowerVolume",
            [Qt.Key_VolumeMute]: "XF86AudioMute",
            [Qt.Key_MicMute]: "XF86AudioMicMute",
            [Qt.Key_MediaPlay]: "XF86AudioPlay",
            [Qt.Key_MediaPause]: "XF86AudioPause",
            [Qt.Key_MediaTogglePlayPause]: "XF86AudioPlay",
            [Qt.Key_MediaNext]: "XF86AudioNext",
            [Qt.Key_MediaPrevious]: "XF86AudioPrev",
            [Qt.Key_MonBrightnessUp]: "XF86MonBrightnessUp",
            [Qt.Key_MonBrightnessDown]: "XF86MonBrightnessDown"
        })

    function fromEvent(key: int, modifiers: int, scanCode: int): string {
        if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_Hyper_L, Qt.Key_Hyper_R, Qt.Key_CapsLock, Qt.Key_NumLock].indexOf(key) >= 0)
            return "";
        let name = root.qtKeys[key];
        if (name === undefined) {
            if (key >= Qt.Key_A && key <= Qt.Key_Z || key >= Qt.Key_0 && key <= Qt.Key_9)
                name = String.fromCharCode(key);
            else if (key >= Qt.Key_F1 && key <= Qt.Key_F35)
                name = "F" + (key - Qt.Key_F1 + 1);
            else if (scanCode > 0)
                name = "code:" + scanCode;
            else
                return "";
        }
        const mods = [];
        if (modifiers & Qt.MetaModifier)
            mods.push("SUPER");
        if (modifiers & Qt.ControlModifier)
            mods.push("CTRL");
        if (modifiers & Qt.AltModifier)
            mods.push("ALT");
        if (modifiers & Qt.ShiftModifier)
            mods.push("SHIFT");
        return [...mods, name].join(" + ");
    }

    // Comparable form, as nexus-keybinds.py's norm(): "SUPER+SHIFT+q"
    function norm(keys: string): string {
        const k = root.split(keys);
        const order = ["SUPER", "CTRL", "ALT", "SHIFT", "CAPS", "MOD2", "MOD3", "MOD5"];
        return [...order.filter(m => k.mods.indexOf(m) >= 0), k.key.toLowerCase()].join("+");
    }
}
