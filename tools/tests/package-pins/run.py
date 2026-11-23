#!/usr/bin/env python3
"""caelestia4: every package install.sh builds and installs as root takes a fixed source.

  python3 -I tools/tests/package-pins/run.py

For each tracked packaging/*/PKGBUILD and sdata/dist-arch/*/PKGBUILD, read in a bash with an empty environment (the
arrays only, nothing built), each source is paired with its checksum at the same index (sha256sums or b2sums, and
the _x86_64 ones):
- git+ sources name a full commit (#commit= and 40 hex digits), or a #tag= with validpgpkeys to check it by;
- downloads (http, https, ftp) and local files have a real checksum, not SKIP;
- any other kind of source (svn+, hg+, bzr+, ...) fails.
Offline; never runs makepkg.
"""
import os
import re
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
ARRAYS = ["source", "sha256sums", "b2sums", "source_x86_64", "sha256sums_x86_64", "b2sums_x86_64", "validpgpkeys"]
READ = "".join(f'printf "%s\\0" "{a}" "${{#{a}[@]}}" "${{{a}[@]}}"; ' for a in ARRAYS)


def read(pkgbuild):
    out = subprocess.run(["env", "-i", "PATH=/usr/bin:/bin", "CARCH=x86_64", "bash", "-c",
                          'set -e; source "$1" >/dev/null; ' + READ, "bash", pkgbuild],
                         cwd=os.path.dirname(pkgbuild), stdin=subprocess.DEVNULL, capture_output=True, check=True)
    items = out.stdout.decode().split("\0")[:-1]
    arrays = {}
    while items:
        name, count = items[0], int(items[1])
        arrays[name] = items[2:2 + count]
        items = items[2 + count:]
    return arrays


def problems(arrays):
    found = []
    for suffix in ("", "_x86_64"):
        sums = [arrays["sha256sums" + suffix], arrays["b2sums" + suffix]]
        for i, entry in enumerate(arrays["source" + suffix]):
            url = entry.split("::", 1)[1] if "::" in entry else entry
            checks = [s[i] for s in sums if i < len(s)]
            real = any(c and c != "SKIP" for c in checks)
            if url.startswith("git+"):
                if re.search(r"#commit=[0-9a-f]{40}$", url):
                    continue
                if re.search(r"#tag=[^#]+$", url) and arrays["validpgpkeys"]:
                    continue
                found.append(f"{entry}: a git source without #commit=<40 hex> (or a signed #tag=)")
            elif re.match(r"^(https?|ftp)://", url) or "://" not in url and "+" not in url.split("/", 1)[0]:
                if not real:
                    found.append(f"{entry}: no checksum (SKIP or missing)")
            else:
                found.append(f"{entry}: a kind of source this check can't pin")
    return found


def main():
    files = subprocess.run(["git", "-C", ROOT, "ls-files", "-z", "--", "packaging/*/PKGBUILD",
                            "sdata/dist-arch/*/PKGBUILD"], capture_output=True, check=True).stdout.decode().split("\0")
    files = [f for f in files if f]
    if not files:
        print("FAIL: no PKGBUILD found")
        return 1
    fails = 0
    for f in sorted(files):
        try:
            arrays = read(os.path.join(ROOT, f))
        except subprocess.CalledProcessError:
            print(f"FAIL: {f}: couldn't be read")
            fails += 1
            continue
        found = problems(arrays)
        for p in found:
            print(f"FAIL: {f}: {p}")
        fails += len(found)
        if not found:
            print(f"ok: {f} ({len(arrays['source']) + len(arrays['source_x86_64'])} sources)")

    # The check itself: what it must refuse
    bad = {"source": ["git+https://example.invalid/x.git", "x.tar.xz::https://example.invalid/x.tar.xz",
                      "git+https://example.invalid/y.git#branch=main", "svn+https://example.invalid/z",
                      "local.patch", "git+https://example.invalid/t.git#tag=v1"],
           "sha256sums": ["SKIP", "SKIP", "SKIP", "SKIP", "SKIP", "SKIP"]}
    bad.update({a: [] for a in ARRAYS if a not in bad})
    if len(problems(bad)) != 6:
        print(f"FAIL: the check refuses {len(problems(bad))} of 6 unpinned sources")
        fails += 1
    good = {"source": ["n::git+https://example.invalid/x.git#commit=" + "a" * 40, "https://example.invalid/x.tar.xz",
                       "local.patch"], "b2sums": ["SKIP", "f" * 128, "e" * 128]}
    good.update({a: [] for a in ARRAYS if a not in good})
    if problems(good):
        print(f"FAIL: the check refuses pinned sources: {problems(good)}")
        fails += 1

    if fails:
        print(f"package-pins tests: {fails} FAILED")
        return 1
    print("package-pins tests: OK")
    return 0


sys.exit(main())
