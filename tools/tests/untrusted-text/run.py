#!/usr/bin/env python3
"""caelestia4: checks that text and names from outside never become shell code, paths or remote loads.

  python3 -I tools/tests/untrusted-text/run.py

1. untrusted.js (modules/common/functions), with node: file names from a booru's file_url (no path, no shell
   characters), host names for favicons, the links a click may open (http, https, mailto), StyledText escaping, and
   Markdown that loads nothing from the network (images become links, HTML is text; a local LaTeX image stays).
2. The shell commands of the wallpaper folder check, the weather fetch, the favicon download, the image preview download
   (ImageDownloaderProcess) and the booru Download button: their code is a fixed string (never a `template`), and run
   in a temporary HOME with stub curl, jq, file and notify-send, a folder named $(...), a city or name with quotes and
   $(...) only ever reach a command as one argument, and a URL that starts with "-" comes after curl's "--".
3. Static checks: the places that show Markdown or StyledText from outside, or open a link from it, go through
   untrusted.js; Booru.qml doesn't log its request URL (the Gelbooru key and user ID are in it); the weather is https.

Never starts the shell, touches the desktop or the real HOME, or uses the network.
"""
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
II = REPO / "dots/.config/quickshell/ii"
UNTRUSTED = II / "modules/common/functions/untrusted.js"

failures = []


def check(ok, what):
    print(f"  {'ok  ' if ok else 'FAIL'} {what}")
    if not ok:
        failures.append(what)


def read(rel):
    return (II / rel).read_text(encoding="utf-8")


def shell_code(rel, marker):
    """The shell code string that follows "bash", "-c", in rel, on the statement holding marker (unquoted from JS)"""
    text = read(rel)
    i = text.find(marker)
    if i < 0:
        return None
    j = text.rfind('"-c",', 0, i)
    m = re.match(r'"-c",\s*(\'(?:[^\'\\]|\\.)*\'|"(?:[^"\\]|\\.)*"|`)', text[j:], re.S)
    if not m or m.group(1) == "`":
        return None
    return re.sub(r"\\(.)", r"\1", m.group(1)[1:-1])


print("== untrusted.js (node)")
node = shutil.which("node")
if node is None:
    if os.environ.get("CI") == "true":
        check(False, "node is installed")
    else:
        print("  skip: node is not installed")
else:
    r = subprocess.run([node, str(HERE / "untrusted.test.js"), str(UNTRUSTED)], capture_output=True, text=True)
    for line in r.stdout.splitlines():
        if not line.startswith("  ok"):
            print(line)
    check(r.returncode == 0, f"untrusted.test.js ({r.stdout.count('  ok')} checks)")
    if r.stderr.strip():
        print(r.stderr.strip())

print("== shell commands take values as arguments")
sb = Path(tempfile.mkdtemp(prefix="c4untrusted."))
try:
    home = sb / "home"
    stubs = sb / "stubs"
    home.mkdir()
    stubs.mkdir()
    log = sb / "args.log"
    # Each stub writes its argv, one argument per line, after a marker, to a log of its own (args.log.curl...); curl
    # writes -o's file. Not one shared log: curl and jq run at once in a pipe, and bash writes a line at a time, so
    # jq's marker could land between curl's marker and its arguments
    stub = f"""#!/bin/bash
printf '%s\\n' "== $(basename "$0")" "$@" >> '{log}.'"$(basename "$0")"
if [ "$(basename "$0")" = curl ]; then
  while [ $# -gt 0 ]; do [ "$1" = -o ] && {{ printf 'GIF89a' > "$2"; }}; shift; done
  printf '{{"current_condition":[{{}}],"nearest_area":[{{}}],"weather":[{{"astronomy":[{{}}]}}]}}'
fi
if [ "$(basename "$0")" = jq ]; then cat >/dev/null; echo '{{}}'; fi
"""
    for name in ("curl", "jq", "notify-send"):  # the stubs that log (run's logged)
        (stubs / name).write_text(stub)
        (stubs / name).chmod(0o755)
    # file: an image of 2 x 3 (with -b --mime-type, its type)
    (stubs / "file").write_text("""#!/bin/bash
case "$1" in -b) echo image/gif ;; *) echo "${@: -1}: GIF image data, version 89a, 2 x 3" ;; esac
""")
    (stubs / "file").chmod(0o755)
    for name in ("bash", "mkdir", "basename", "cat", "printf", "dirname", "grep", "mv"):
        real = shutil.which(name)
        if real:
            os.symlink(real, stubs / name)
    env = {"HOME": str(home), "PATH": str(stubs), "LANG": "C.UTF-8"}
    marker = home / "PWNED"
    # no "/" in it, so it can be a file name too (the commands run in HOME, where the marker would land)
    evil = "x';touch PWNED;'$(touch PWNED)`touch PWNED`\"$(touch PWNED)\"${IFS}"

    logged = ("curl", "jq", "notify-send")

    def run(code, *args):
        """code's output, and the stubs' records: curl's, then jq's, then notify-send's"""
        for name in logged:
            Path(f"{log}.{name}").write_text("")
        r = subprocess.run(["bash", "-c", code, "bash", *args], env=env, cwd=home, capture_output=True, text=True,
                           timeout=20)
        return r.stdout.strip(), [l for name in logged for l in Path(f"{log}.{name}").read_text().splitlines()]

    # Wallpapers.qml: validateDirProc
    code = shell_code("services/Wallpapers.qml", 'echo dir; elif')
    check(code is not None, "Wallpapers.qml: the folder check's code is a fixed string")
    if code:
        folder = home / "Pictures" / f"nature $(touch {marker})"
        folder.mkdir(parents=True)
        out, _ = run(code, str(folder))
        check(out == "dir" and not marker.exists(), "a folder named $(touch ...) is a folder, and nothing runs")
        out, _ = run(code, evil)
        check(out == "invalid" and not marker.exists(), "a pasted path with quotes and $(...) runs nothing")

    # Weather.qml: getData
    code = shell_code("services/Weather.qml", "current_condition[0]")
    check(code is not None, "Weather.qml: the fetch's code is a fixed string")
    if code:
        url = "https://wttr.in/" + evil + "?format=j1&lang=en"
        out, args = run(code, url)
        at = args.index("== curl") if "== curl" in args else 0
        check(not marker.exists() and args[at:at + 4] == ["== curl", "-s", "--", url], "a city with quotes and $(...) reaches curl as one argument")
    weather = read("services/Weather.qml")
    check("curl -s wttr.in" not in weather and '"https://wttr.in"' in weather, "Weather.qml asks wttr.in over https")
    check("encodeURIComponent(w)" in weather, "Weather.qml URL-encodes the city")

    # Favicon.qml
    code = shell_code("modules/common/widgets/Favicon.qml", "User-Agent")
    check(code is not None, "Favicon.qml: the download's code is a fixed string")
    if code:
        path = str(home / f"{evil}.ico")
        out, args = run(code, path, evil, evil)
        check(not marker.exists() and args[:7] == ["== curl", "-s", "-o", path, "-L", "-H", f"User-Agent: {evil}"]
              and args[7:9] == ["--", evil], "a host, path and user agent with quotes and $(...) reach curl as arguments")
    favicon = read("modules/common/widgets/Favicon.qml")
    check("Untrusted.hostName(" in favicon and "domainName.length === 0" in favicon, "Favicon.qml takes only a plain host name")

    # BooruImage.qml: Download
    code = shell_code("modules/caelestia/assistant/anime/BooruImage.qml", 'notify-send -a Shell')
    check(code is not None, "BooruImage.qml: the Download command's code is a fixed string")
    if code:
        target = home / "Pictures" / "homework"
        out, args = run(code, str(target), evil, evil, evil, "-H", "User-Agent: ua", "-e", "https://ref.example/")
        check(not marker.exists() and (target / evil).is_file(), "a file name with quotes and $(...) is only a name in the folder")
        check(args[:9] == ["== curl", "-H", "User-Agent: ua", "-e", "https://ref.example/", "-o", f"{target}/{evil}", "--", evil],
              "curl gets the user agent, referer, file and URL as arguments")
        check(args[9:] == ["== notify-send", "-a", "Shell", "--", evil, f"{target}/{evil}"], "notify-send gets the message as arguments")
    booru_image = read("modules/caelestia/assistant/anime/BooruImage.qml")
    check("decodeURIComponent" not in booru_image and "Untrusted.safeFileName(imageData.file_url" in booru_image,
          "BooruImage.qml names files with safeFileName, never a decoded URL")
    check("sourceUrl: Untrusted.isHttpUrl(" in booru_image and "!Untrusted.isHttpUrl(root.imageData.file_url)" in booru_image,
          "BooruImage.qml previews and downloads http(s) URLs only")

    # ImageDownloaderProcess.qml (booru previews, the floating image)
    code = shell_code("modules/common/utils/ImageDownloaderProcess.qml", "file -b --mime-type")
    check(code is not None, "ImageDownloaderProcess.qml: the download's code is a fixed string")
    if code:
        path = str(home / "cache" / f"{evil} dir" / f"{evil}.png")
        for url in (evil, "-K/etc/passwd"):
            out, args = run(code, path, url, "-H", "User-Agent: ua", "-e", "https://ref.example/")
            check(not marker.exists() and args[:10] == ["== curl", "-fsSL", "-H", "User-Agent: ua", "-e", "https://ref.example/",
                                                       "-o", f"{path}.part", "--", url],
                  f"the URL {url[:12]!r}... reaches curl after --, with the path and headers as arguments")
            check(Path(path).is_file() and out.endswith("2 x 3"), "the image lands at its path and its size is read")
            Path(path).unlink()
finally:
    shutil.rmtree(sb, ignore_errors=True)

print("== static checks")
for rel in ("services/Wallpapers.qml", "services/Weather.qml", "modules/common/widgets/Favicon.qml",
            "modules/caelestia/assistant/anime/BooruImage.qml", "modules/common/utils/ImageDownloaderProcess.qml"):
    check(not re.search(r'"(?:ba)?sh",\s*"-c",\s*`', read(rel)), f"{rel}: no bash -c `template`")
booru = read("services/Booru.qml")
logs = re.findall(r"console\.(?:log|info|warn|error|debug)\(([^\n]*)", booru)
check(not any(re.search(r"\burl\b", l) and not l.lstrip().startswith("//") for l in logs), "Booru.qml logs no request URL")

renders = {
    "modules/caelestia/assistant/aiChat/MessageTextBlock.qml": "Untrusted.markdownSafe(modelData, { localImageDir: LatexRenderer.latexOutputPath, allowTags: allowTags })",
    "modules/caelestia/assistant/anime/BooruResponse.qml": "Untrusted.markdownSafe(root.responseData.message)",
    "modules/caelestia/notifications/Notification.qml": "Untrusted.notificationMarkdown(root.modelData.body)",
    "modules/caelestia/sidebar/Notif.qml": "Untrusted.notificationMarkdown(",
}
for rel, needle in renders.items():
    text = read(rel)
    check(needle in text, f"{rel}: Markdown goes through untrusted.js")
    # every onLinkActivated checks the link before it opens it
    for m in re.finditer(r"onLinkActivated:[^{]*\{(.*?)Qt\.openUrlExternally\(link\)", text, re.S):
        check("Untrusted.isWebUrl(link)" in m.group(1), f"{rel}: a clicked link must be http, https or mailto")
    # and a hover shows where it goes before the click (link text is the sender's)
    check(re.search(r"StyledToolTip \{[^}]*text: Untrusted\.linkPreview\(\w+\.hoveredLink\)", text) is not None,
          f"{rel}: a hovered link shows its target")
check(len(re.findall(r"Untrusted\.isWebUrl", booru_image)) >= 3, "BooruImage.qml opens and downloads web links only")
check("Untrusted.isWebUrl(url)" in read("modules/caelestia/assistant/aiChat/AnnotationSourceButton.qml"),
      "AnnotationSourceButton.qml opens web links only")
for rel in ("modules/caelestia/adapters/Players.qml", "modules/caelestia/adapters/Audio.qml"):
    text = read(rel)
    toasts = re.findall(r"Toaster\.toast\([^\n]*", text)
    check(toasts and all(".arg(" not in t or ".arg(Untrusted.escapeHtml(" in t for t in toasts),
          f"{rel}: a toast escapes what it puts into StyledText")
vpn = read("modules/caelestia/adapters/VPN.qml")
check(all(n in vpn for n in ("const displayName = Untrusted.escapeHtml(", "const authMsg = Untrusted.escapeHtml(",
                             "const errMsg = Untrusted.escapeHtml(")) and len(re.findall(r"Toaster\.toast\([^\n]*, Untrusted\.escapeHtml\(reason\)", vpn)) == 2,
      "VPN.qml: a toast escapes the VPN's name and reasons")

if failures:
    print(f"untrusted-text tests: {len(failures)} FAILED")
    sys.exit(1)
print("untrusted-text tests: OK")
