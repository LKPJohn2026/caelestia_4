.pragma library
// caelestia4: checks for what the AI (and the pages it read) can put on screen or ask to run. Pure functions, no
// QML, so tools/tests/ai-safety/checks.js can load this file in node. Link schemes and the Markdown of replies are
// checked by modules/common/functions/untrusted.js (isWebUrl, markdownSafe), shared with the rest of the shell.

// Characters that are invisible or change how the text around them looks: zero-width and bidi controls, odd
// spaces, the blank braille pattern, the object replacement character, tag characters, variation selectors, musical
// formatting controls
const INVISIBLE = /[\u00A0\u00AD\u034F\u061C\u115F\u1160\u1680\u17B4\u17B5\u180E\u2000-\u200F\u2028-\u202F\u205F-\u206F\u2800\u3000\u3164\uFE00-\uFE0F\uFEFF\uFFA0\uFFF9-\uFFFC]|\uDB40[\uDC00-\uDDEF]|\uD834[\uDD73-\uDD7A]/;

function codePointLabel(ch) {
    return "\u27E8U+" + ch.codePointAt(0).toString(16).toUpperCase().padStart(4, "0") + "\u27E9";
}

// The text of a command or value as the approval box shows it: one character on screen for every character that
// runs. Control characters become their Unicode pictures (\r is ␍, ESC is ␛), tabs ⇥, runs of 3 or more spaces
// middle dots, and invisible characters ⟨U+XXXX⟩. Newlines stay newlines (the box also gives the line count), but more
// than 2 empty lines in a row become one line "⏎×N" (N newlines), so they can't push the rest out of sight.
function visibleText(text) {
    const s = String(text ?? "");
    let out = "";
    for (const ch of s) {
        const c = ch.codePointAt(0);
        if (ch === "\n") out += "\n";
        else if (ch === "\t") out += "\u21E5";
        else if (c < 0x20) out += String.fromCharCode(0x2400 + c);
        else if (c === 0x7F) out += "\u2421";
        else if (c >= 0x80 && c <= 0x9F) out += codePointLabel(ch);
        else if (INVISIBLE.test(ch)) out += codePointLabel(ch);
        else out += ch;
    }
    return out.replace(/ {3,}/g, m => "\u00B7".repeat(m.length))
        .replace(/\n{4,}/g, m => "\n\u23CE\u00D7" + m.length + "\n");
}

function lineCount(text) {
    return String(text ?? "").split("\n").length;
}

function charCount(text) {
    return Array.from(String(text ?? "")).length;
}

// Config keys the model may never ask to set, even with an approval: a value the shell runs (apps.* go through
// bash -c), sends to the network, reads or writes as a file, or that turns a safeguard off. One click on a box that
// shows the value faithfully is still one click on a value a page the model read wrote: these are changed in Nexus.
// A key is protected when it is one of these or under one
const PROTECTED_KEYS = [
    "apps",                         // commands run with bash -c (Session.qml, the quick toggles, the bar)
    "ai",                           // the system prompt, models, endpoints, tool mode
    "policies",                     // whether the AI (and its tools) are on at all
    "search",                       // engine URLs and the launcher's prefixes (search.prefix.shellCommand runs a shell)
    "networking",                   // the user agent of every request
    "overlay.floatingImage",        // imageSource: a URL fetched at start-up
    "lock.security",                // keyring unlock, a password to power off
    "profile",                      // avatar paths
    "language.translator",          // the engine and languages passed to trans
    "caelestia.randomWallpaper",    // the site wallpapers are downloaded from
    "caelestia.backgroundMute",     // a regex of window classes
    "background.wallpaperPath", "background.thumbnailPath", "background.lockWall",
];
// The last part of a key that holds a path, a URL or a command, wherever it is (savePath, imageSource, ...)
const PROTECTED_LEAF = /(^|[a-z])(path|Path|dir|Dir|folder|Folder|url|Url|URL|uri|Uri|imageSource|command|Command|cmd|Cmd|exec|Exec|script|Script|program|Program|endpoint|Endpoint|userAgent)$/;

// "" when the model may ask to set this config key, or why not ("invalid key", "protected key"). The user still
// approves every change.
function configKeyProblem(key) {
    const k = String(key ?? "");
    if (k.length === 0) return "empty key";
    const parts = k.split(".");
    for (const p of parts) {
        if (!/^[A-Za-z_][A-Za-z0-9_]*$/.test(p)) return "invalid key";
        if (p === "__proto__" || p === "constructor" || p === "prototype") return "invalid key";
    }
    if (PROTECTED_KEYS.some(p => k === p || k.startsWith(p + "."))) return "protected key";
    if (PROTECTED_LEAF.test(parts[parts.length - 1])) return "protected key";
    return "";
}

// A /key get message (the "API key:" template in any language: a short label, then the key alone in a txt fence).
// Chats saved before /key get became ephemeral hold the key in plain text: such a message is never saved, and is
// dropped from a chat file when it loads (Ai.qml loadChat)
function isApiKeyMessage(role, rawContent) {
    return role === "interface" && /^[^\n`]{1,40}\n\n```txt\n[^\n`]*\n```\s*$/.test(String(rawContent ?? ""));
}

// Text that goes into the chat's history around a command request: fenced only when the fence can't be closed early
// or hide part of it in a collapsed think block. The approval box shows the command itself either way.
function canFence(text) {
    const s = String(text ?? "");
    return !s.includes("```") && !/<\/?think>/i.test(s);
}

// A command that can't be fenced as it is, for the chat's history: a zero-width space between backticks that touch
// and after the "<" of think tags, so it stays inside its fence. Only a record of what ran; Approve runs the command
// from functionCall.args.
function breakFences(text) {
    return String(text ?? "").replace(/`(?=`)/g, "`\u200B").replace(/<(\/?think>)/gi, "<\u200B$1");
}
