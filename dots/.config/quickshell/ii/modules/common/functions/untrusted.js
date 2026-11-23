.pragma library

// caelestia4: helpers for text and names that come from outside (notifications, AI replies, booru and search
// results, media players), kept apart from QML so they can be tested with node (tools/tests/untrusted-text).
//   safeFileName(url)        a file name for something downloaded from url: no path, no shell characters
//   hostName(text)           text if it is a plain host name (letters, digits, dots, dashes), else ""
//   urlHost(url)             the host of a URL, checked as hostName() ("" when there isn't a good one)
//   isWebUrl(url)            true for http, https and plain mailto links: the only ones a click may open
//   isHttpUrl(url)           true for http and https URLs: the only ones to download from
//   linkPreview(url)         what a hover shows of a link before the click: the URL a click opens (shortened), or ""
//                            when a click opens nothing; link text chosen by the sender can't hide where it goes
//   escapeHtml(text)         text made safe to put into StyledText or rich text
//   markdownSafe(text, opts) Markdown (or the HTML Qt's Markdown takes) that loads nothing from the network:
//                            images become links (a rendered LaTeX image, <hex>.svg right in opts.localImageDir,
//                            may stay) and HTML tags other than opts.allowTags are shown as text; code (spans,
//                            fenced and indented blocks) is copied as it is wherever the parser is sure to read it as
//                            code, and hedged elsewhere (codeParts)

// A short, stable hash, so names that had to be cleaned stay apart
function shortHash(text) {
    let h = 5381;
    const s = String(text);
    for (let i = 0; i < s.length; i++)
        h = ((h * 33) ^ s.charCodeAt(i)) >>> 0;
    return h.toString(16).padStart(8, "0");
}

function safeFileName(url, fallback) {
    const raw = String(url ?? "");
    let name = raw.replace(/[?#].*$/, "");
    name = name.substring(name.lastIndexOf("/") + 1);
    let decoded = name;
    try {
        decoded = decodeURIComponent(name);
    } catch (e) {
        // a bad % sequence: keep the name as it came
    }
    // a decoded %2F or %5C is a path again: keep only what comes after the last one
    decoded = decoded.substring(Math.max(decoded.lastIndexOf("/"), decoded.lastIndexOf("\\")) + 1);
    let clean = decoded.replace(/[^A-Za-z0-9._-]/g, "_").replace(/^[.\-_]+/, "");
    if (clean.length > 120) {
        const dot = clean.lastIndexOf(".");
        const ext = dot > 0 && clean.length - dot <= 8 ? clean.substring(dot) : "";
        clean = clean.substring(0, 120 - ext.length) + ext;
    }
    if (!/[A-Za-z0-9]/.test(clean))
        return `${fallback || "file"}-${shortHash(raw)}`;
    if (clean !== decoded) {
        // cleaned: add a hash of the URL before the extension, so two different names don't become one file
        const dot = clean.lastIndexOf(".");
        return dot > 0 ? `${clean.substring(0, dot)}-${shortHash(raw)}${clean.substring(dot)}` : `${clean}-${shortHash(raw)}`;
    }
    return clean;
}

function hostName(text) {
    const s = String(text ?? "").trim().toLowerCase();
    if (s.length === 0 || s.length > 253) return "";
    if (!/^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*$/.test(s)) return "";
    return s;
}

function urlHost(url) {
    const m = String(url ?? "").match(/^(?:[A-Za-z][A-Za-z0-9+.-]*:)?\/\/([^\/?#\\]*)/) || String(url ?? "").match(/^([^\/?#\\:@]*)/);
    if (!m) return "";
    let host = m[1];
    host = host.substring(host.lastIndexOf("@") + 1).replace(/:\d*$/, "").replace(/^www\./i, "");
    return hostName(host);
}

function isWebUrl(url) {
    const s = String(url ?? "");
    // no spaces or control characters anywhere, so what is shown is what opens
    if (/[\s\x00-\x1f\x7f]/.test(s)) return false;
    // mailto: an address only, no query (some mail clients take ?attach=/a/local/file)
    return isHttpUrl(s) || /^mailto:[^\/?#%&\\]+$/i.test(s);
}

function linkPreview(url) {
    const s = String(url ?? "");
    if (!isWebUrl(s)) return "";
    return s.length > 160 ? s.substring(0, 159) + "\u2026" : s;
}

function isHttpUrl(url) {
    const s = String(url ?? "");
    if (/[\s\x00-\x1f\x7f]/.test(s)) return false;
    return /^https?:\/\/[^\/?#]+/i.test(s);
}

function escapeHtml(text) {
    return String(text ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");
}

// A local image a Markdown image may still show: a rendered LaTeX image, <hex>.svg right in dir (never /dev/zero, a
// FIFO or any other file a reply names)
function isLocalImage(dest, dir) {
    const d = String(dir ?? "").replace(/\/+$/, "");
    if (!d.startsWith("/") || !dest.startsWith(d + "/")) return false;
    return /^[0-9a-f]+\.svg$/.test(dest.substring(d.length + 1));
}

// The destination of the Markdown image that starts at text[i] ("![") or null when it isn't a plain inline one
function imageDestination(text, i) {
    let j = i + 2, depth = 1;
    for (; j < text.length && depth > 0; j++) {
        const c = text[j];
        if (c === "\\") j++;
        else if (c === "[") depth++;
        else if (c === "]") depth--;
        else if (c === "`" || c === "<") return null; // a code span or a tag binds tighter: Markdown's "]" may be later
        else if (c === "\n" && text[j + 1] === "\n") return null;
    }
    if (depth !== 0 || text[j] !== "(") return null;
    const m = text.substring(j + 1).match(/^[ \t]*([^\s()<>\\]*)[ \t]*\)/);
    return m ? m[1] : null;
}

function neutraliseImages(text, localImageDir) {
    let out = "";
    let i = 0;
    while (true) {
        const k = text.indexOf("![", i);
        if (k < 0) break;
        const dest = localImageDir ? imageDestination(text, k) : null;
        if (dest !== null && isLocalImage(dest, localImageDir)) {
            out += text.substring(i, k + 2);
        } else {
            // never a "!" right before the new "[" ("!![x](url)" would be an image again): a kept segment ends in
            // "![" and a replaced one in "[", so only the text in between can end in one
            const before = text.substring(i, k);
            out += (before.endsWith("!") ? before.slice(0, -1) + "&#33;" : before) + "[";
        }
        i = k + 2;
    }
    return out + text.substring(i);
}

function cleanTag(tag, allowTags) {
    const m = tag.match(/^<(\/?)([A-Za-z][A-Za-z0-9]*)(\s[^<>]*)?\/?>$/);
    if (!m) return null;
    const closing = m[1], name = m[2].toLowerCase(), attrs = m[3] ?? "";
    if (!allowTags.includes(name)) return null;
    if (name === "a" && !closing) {
        const h = attrs.match(/\shref\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'=<>`]+))/i);
        const href = h ? (h[1] ?? h[2] ?? h[3]) : "";
        return isWebUrl(href) ? `<a href="${escapeHtml(href)}">` : "<a>";
    }
    // A void tag as <br/>: Qt counts each "<" + letter as an open tag until a "/>" or "</", and reads everything
    // after an unclosed one as HTML (the text after a plain <br> was lost)
    if (name === "br") return "<br/>";
    return `<${closing}${name}>`;
}

// Autolinks as CommonMark reads them (<scheme:...>, <local@host>): taken before a code span that starts inside one, as
// the parser does (leftmost first), so a backtick in <1`x@e.example> doesn't open a span here that isn't one there
const AUTOLINK_URI = /^<[A-Za-z][A-Za-z0-9+.-]{1,31}:[^\s<>]*>/;
const AUTOLINK_EMAIL = /^<[A-Za-z0-9.!#$%&'*+\/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)*>/;

// The inline code spans of text, as [start, end) pairs: a run of backticks up to the next run of the same length
// (a backslash outside code escapes a backtick; a blank line ends the paragraph, and the span with it; an autolink
// is read first)
function codeSpans(text) {
    const spans = [];
    let i = 0;
    while (i < text.length) {
        const c = text[i];
        if (c === "\\") {
            i += 2;
            continue;
        }
        if (c === "<") {
            const rest = text.substring(i, i + 400);
            const m = rest.match(AUTOLINK_URI) || rest.match(AUTOLINK_EMAIL);
            i += m ? m[0].length : 1;
            continue;
        }
        if (c !== "`") {
            i++;
            continue;
        }
        let n = 0;
        while (text[i + n] === "`") n++;
        const para = text.substring(i + n).search(/\n[ \t]*\n/);
        const limit = para < 0 ? text.length : i + n + para;
        let j = i + n, end = -1;
        while (j < limit) {
            if (text[j] !== "`") {
                j++;
                continue;
            }
            let m = 0;
            while (text[j + m] === "`") m++;
            if (m === n) {
                end = j + m;
                break;
            }
            j += m;
        }
        if (end < 0) {
            i += n; // no closing run: the backticks are text
            continue;
        }
        spans.push([i, end]);
        i = end;
    }
    return spans;
}

// Code that may be copied as it is (Qt parses neither HTML nor images in code, and shows no entity there either, so an
// escaped "<" would show as "&lt;"): only where the Markdown parser is sure to read it as code too. Anything less sure
// is "hedged" code: its images become links and its tags are escaped (attribute-free ones kept when no tags are
// allowed), which is safe whatever the parser makes of it.
//
// A line that may open an HTML block (after any quote or list markers, a "<" then a letter, "/", "!" or "?": wider
// than CommonMark's 7 kinds, on purpose). In one, the parser reads no Markdown (a code span there is raw HTML) until
// the next blank line
const HTML_BLOCK_START = /^[ \t>]*(?:(?:[-+*]|\d{1,9}[.)])[ \t]+[ \t>]*)*<[A-Za-z\/!?]/;
// A line that starts a list item or a quote: an indented block after one may be part of it, not code
const CONTAINER_LINE = /^ {0,3}(?:>|(?:[-+*]|\d{1,9}[.)])(?:[ \t]|$))/m;

// The lines of text with their offsets: [start, end) without the newline
function lines(text) {
    const out = [];
    let at = 0;
    while (at <= text.length) {
        const nl = text.indexOf("\n", at);
        const end = nl < 0 ? text.length : nl;
        out.push([at, end]);
        if (nl < 0) break;
        at = nl + 1;
    }
    return out;
}

const blank = line => /^[ \t]*$/.test(line);

// The code blocks of text that are sure to be code blocks, as [start, end) pairs: a fence at the start of a line
// (``` or ~~~, no backtick in a ``` fence's info string) to its closing fence (up to 3 spaces before it, as the parser
// takes it) or the end, and a block indented by 4 spaces or a tab after a blank line, with no list or quote before
// it. Neither in a stretch of lines (since the last blank one) that may hold an HTML block.
function codeBlocks(text) {
    const ls = lines(text), blocks = [];
    let chunkHtml = false, sawContainer = false, prevBlank = true;
    for (let k = 0; k < ls.length; k++) {
        const line = text.substring(ls[k][0], ls[k][1]);
        if (blank(line)) {
            chunkHtml = false;
            prevBlank = true;
            continue;
        }
        const fence = line.match(/^(`{3,}|~{3,})(.*)$/);
        if (fence && !chunkHtml && !(fence[1][0] === "`" && fence[2].includes("`"))) {
            let e = k + 1;
            const close = new RegExp("^ {0,3}" + (fence[1][0] === "`" ? "`" : "~") + "{" + fence[1].length + ",}[ \\t]*$");
            while (e < ls.length && !close.test(text.substring(ls[e][0], ls[e][1]))) e++;
            const stop = e < ls.length ? ls[e][1] : text.length;
            blocks.push([ls[k][0], stop]);
            k = e;
            prevBlank = false;
            continue;
        }
        if (prevBlank && !sawContainer && /^(?: {4}|\t)/.test(line)) {
            let e = k, last = k;
            while (e < ls.length) {
                const l = text.substring(ls[e][0], ls[e][1]);
                if (blank(l)) { e++; continue; }
                if (!/^(?: {4}|\t)/.test(l)) break;
                last = e++;
            }
            blocks.push([ls[k][0], ls[last][1]]);
            k = last;
            prevBlank = false;
            continue;
        }
        if (HTML_BLOCK_START.test(line)) chunkHtml = true;
        if (CONTAINER_LINE.test(line)) sawContainer = true;
        prevBlank = false;
    }
    return blocks;
}

// The stretches of text (blank-line to blank-line) that may hold an HTML block, as [start, end) pairs
function htmlChunks(text) {
    const ls = lines(text), out = [];
    let chunk = null, html = false;
    for (const [a, b] of ls) {
        const line = text.substring(a, b);
        if (blank(line)) {
            if (chunk !== null && html) out.push([chunk, a]);
            chunk = null;
            html = false;
            continue;
        }
        if (chunk === null) chunk = a;
        if (HTML_BLOCK_START.test(line)) html = true;
    }
    if (chunk !== null && html) out.push([chunk, text.length]);
    return out;
}

// Hedged code: as escapeInCode with no tags allowed; with tags allowed, every "<" but an allowed tag's is escaped
function hedgedCode(code, allowTags, localImageDir) {
    const s = neutraliseImages(code, localImageDir);
    return allowTags.length > 0 ? escapeTags(s, allowTags) : escapeInCode(s);
}

// In hedged code (with no tags allowed) a "<" stays as typed (`Vec<T>`, `#include <stdio.h>`) as long as what is
// kept is only a tag with no attribute values ("=") and no <style>, which loads nothing; anything else is escaped.
function escapeInCode(code) {
    return code.replace(/<([^<>]*)(>?)/g, (match, inner, close) => {
        if (!/^[A-Za-z\/!?]/.test(inner)) return match;
        if (close && !inner.includes("=") && !/^\/?style\b/i.test(inner)) return match;
        return "&lt;" + match.substring(1);
    });
}

// The parts of text that are code, in order: [start, end, verbatim]. Blocks first, then the inline spans of the text
// between them; a span is verbatim when it is on one line and not in a stretch that may hold an HTML block
function codeParts(text) {
    const parts = [], html = htmlChunks(text);
    const inHtml = (a, b) => html.some(([x, y]) => a < y && b > x);
    let at = 0;
    const spansIn = (from, to) => {
        const seg = text.substring(from, to);
        for (const [a, b] of codeSpans(seg))
            parts.push([from + a, from + b, !seg.substring(a, b).includes("\n") && !inHtml(from + a, from + b)]);
    };
    for (const [a, b] of codeBlocks(text)) {
        spansIn(at, a);
        parts.push([a, b, true]);
        at = b;
    }
    spansIn(at, text.length);
    return parts;
}

function markdownSafe(text, opts) {
    const allowTags = (opts?.allowTags ?? []).map(t => String(t).toLowerCase());
    const localImageDir = opts?.localImageDir ?? "";
    const s = String(text ?? "");
    // Code is found first and copied as it is where that is sure to be safe (codeParts); images and tags are
    // handled only in the text around it, so code keeps its "![x](y)" and "<div class=...>"
    const outside = t => escapeTags(neutraliseImages(t, localImageDir), allowTags);
    let out = "", at = 0;
    for (const [start, end, verbatim] of codeParts(s)) {
        const code = s.substring(start, end);
        out += outside(s.substring(at, start)) + (verbatim ? code : hedgedCode(code, allowTags, localImageDir));
        at = end;
    }
    return out + outside(s.substring(at));
}

function escapeTags(s, allowTags) {
    // A "<" that could start HTML is shown as text, unless it starts an allowed tag (rebuilt without attributes) or
    // an autolink. An entity, not a backslash: Qt hands the text inside an HTML tag to its HTML parser as it is, and
    // that parser skips spaces after "<", so once any tag is allowed every other "<" is escaped.
    return s.replace(/<(?:[^<>]*>)?/g, match => {
        if (match.length > 1) {
            if (/^<[A-Za-z][A-Za-z0-9+.-]{1,31}:[^\s<>`"']*>$/.test(match) || /^<[A-Za-z0-9.!#$%&*+=?^_{|}~-]+@[A-Za-z0-9.-]+>$/.test(match))
                return match; // an autolink: a link, it loads nothing
            const tag = cleanTag(match, allowTags);
            if (tag !== null) return tag;
        }
        if (allowTags.length === 0 && !/^<[A-Za-z\/!?]/.test(match))
            return match; // "a < b": no HTML starts here, and without allowed tags Qt never parses text as HTML
        return "&lt;" + match.substring(1);
    });
}

// The tags a notification body may use (the freedesktop markup, less <img>)
const notificationTags = ["a", "b", "i", "u", "br", "em", "strong", "p"];

function notificationMarkdown(text) {
    return markdownSafe(text, { allowTags: notificationTags });
}

// In QML, `import "untrusted.js" as Untrusted` gives these; in node the test reads this file into a context
