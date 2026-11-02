#!/usr/bin/env python3
"""caelestia4: wallpapers at the screen's own resolution. A still smaller than the screen (in device pixels: 7680x2160
for a 5120x1440 screen at 1.5x) is upscaled by Upscayl's AI (upscayl-bin, its 4x models) and one larger is downscaled,
to the smallest size that covers the screen, the whole picture kept (a 16:9 one on a 32:9 screen: 7680x4352). Only a
copy that Qt couldn't load (over MAX_PIXELS: tall pictures, 7680x10240 for a phone photo) loses the ends of its long
side, kept centred. The copy goes to ~/.cache/caelestia4/wallpaper-fit, the original stays as it is; index.json says
which copy is whose, and the shell shows the copy once it's there (modules/caelestia/adapters/Wallpapers.qml).
Caelestia's renderer never upscales (its texture is at most the picture's own size, stretched when drawn), so this is
what makes it sharp.

The renderer fills the screen as "cover": what doesn't fit the screen's shape is cut off (a 16:9 picture on a 32:9
screen loses a quarter at the top and one at the bottom). The other modes make a copy of exactly the screen's size:
  cover         the above (default)
  contain-blur  the whole picture, as high (or as wide) as the screen, on a blurred, dimmed copy of itself
  seam          the same, widened (or heightened) first by seam carving (ImageMagick's -liquid-rescale): the parts with
                the least detail (sky, a blurred background) are stretched, faces and edges keep their shape; at most
                SEAM_MAX times, the rest blurred as above. ~25 s a picture on top of the upscale
A picture already within CLOSE of the screen's shape is made as "cover" in every mode (nothing to fill).

Usage: wallpaper-fit.py IMAGE...   copies for these (made once, then reused until the picture, the screen or the model
                                   changes; a failure is remembered the same way, so it isn't retried on every switch).
                                   The KEEP copies shown last stay, older ones go
       wallpaper-fit.py --keep IMAGE...
                                   the same, and these copies stay for good (a whole folder made ahead of time:
                                   ~6 MB each at 7680x4352); only a picture that's gone loses its copy
Settings: illogical-impulse config.json background.wallpaperFit {enable, model, mode} (Nexus > Wallpaper & style)."""
import ctypes
import fcntl
import hashlib
import json
import math
import os
import shutil
import signal
import subprocess
import sys
import tempfile
import time

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
CACHE = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.join(HOME, ".cache"), "caelestia4/wallpaper-fit")
INDEX = os.path.join(CACHE, "index.json")
II_CONFIG = os.path.join(CONFIG, "illogical-impulse/config.json")
UPSCAYL = shutil.which("upscayl-bin") or "/usr/share/upscayl/bin/upscayl-bin"
MODELS = "/usr/share/upscayl/models"
VIDEOS = (".mp4", ".webm", ".mkv", ".avi", ".mov", ".gif")
KEEP = 40  # copies kept (the most recently shown): ~5-10 MB each at 7680x4352
CLOSE = 0.02  # within 2% of the screen already: shown as it is
# Qt reads a picture whole before Caelestia's renderer crops it to the screen, and refuses one over 256 MiB (4 bytes a
# pixel); JPEG stops at 65500 px a side
MAX_PIXELS = 56_000_000
MAX_SIDE = 65_000
RETRIES = 2  # an upscale that fell back to Lanczos is tried again on the next runs, this many times
MODES = ("cover", "contain-blur", "seam")
SEAM_MAX = 2.0  # seam carving past twice the width (or height) bends and repeats what it keeps
SEAM_TIMEOUT = 600  # a 3840x2160 picture widened to 7680x2160 takes ~25 s
BLUR_SHRINK = 8  # the background is blurred at 1/8 of the screen's size and scaled up: the same look, ~60x faster
# upscayl-bin can stall on a picture (one ran for 50 minutes at 2x on a 5000x1803 PNG): past this, Lanczos instead
UPSCAYL_TIMEOUT = 300


def settings():
    try:
        with open(II_CONFIG) as f:
            fit = json.load(f).get("background", {}).get("wallpaperFit", {})
    except (OSError, ValueError):
        fit = {}
    mode = fit.get("mode") if fit.get("mode") in MODES else "cover"
    return fit.get("enable", True) is not False, fit.get("model") or "digital-art-4x", mode


def screen_size():
    """The largest width and height over the monitors, in device pixels (one copy covers every screen)"""
    out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, text=True, check=True).stdout
    width = height = 0
    for m in json.loads(out):
        w, h = m["width"], m["height"]
        if m.get("transform", 0) % 2:  # turned a quarter
            w, h = h, w
        width, height = max(width, w), max(height, h)
    if not width or not height:
        raise SystemExit("no monitors")
    return width, height


def picture_size(path):
    """(width, height, frames) as shown: after the EXIF rotation (a camera's portrait photo is stored landscape)"""
    out = subprocess.run(["magick", path, "-auto-orient", "-format", "%w %h\n", "info:"],
                         capture_output=True, text=True, check=True)
    lines = out.stdout.split()
    return int(lines[0]), int(lines[1]), len(lines) // 2


def stamp(path):
    st = os.stat(path)
    return {"mtime": int(st.st_mtime), "bytes": st.st_size}


def load_index():
    try:
        with open(INDEX) as f:
            index = json.load(f)
        if isinstance(index.get("walls"), dict):
            return index
    except (OSError, ValueError):
        pass
    return {"target": "", "walls": {}}


def save_index(index):
    with tempfile.NamedTemporaryFile("w", dir=CACHE, suffix=".tmp", delete=False) as f:
        json.dump(index, f, ensure_ascii=False, indent=1)
    os.replace(f.name, INDEX)


def any_mode(entry, target):
    """A picture of the screen's shape is made the same in every mode (a cover with nothing cut off): its copy stays
    when the mode changes. Copies made before the modes have no "anymode": theirs is in the name, at the screen's size"""
    if "anymode" in entry:
        return entry["anymode"]
    return entry.get("fitted", "").endswith(f"-{target}.jpg")


def valid(entry, path, target, model, mode):
    """The entry still answers for this picture, screen, model and mode (a copy, "as it is", or a remembered failure)"""
    if not entry or entry.get("target") != target or entry.get("source") != stamp(path):
        return False
    if entry.get("mode", "cover") != mode and not any_mode(entry, target):
        return False
    if entry.get("fitted") and not os.path.isfile(entry["fitted"]):
        return False
    if entry.get("upscale") and entry.get("model") != model:
        return False
    # an upscale Upscayl failed on (Lanczos stood in), or a seam carving that failed (blurred room instead): again, a
    # few times
    stood_in = (entry.get("upscale") and entry.get("how") == "lanczos") or entry.get("seamFailed")
    return not (stood_in and entry.get("tries", 0) < RETRIES)


def cover(w, h, target):
    """The copy's size and the part of the scaled picture it keeps: the whole of it, unless that's too big to load"""
    factor = max(target[0] / w, target[1] / h)
    scaled = (math.ceil(w * factor), math.ceil(h * factor))
    out = list(scaled)
    long = 0 if scaled[0] / target[0] > scaled[1] / target[1] else 1  # the side with room to spare
    room = min(MAX_SIDE, MAX_PIXELS // out[1 - long])
    out[long] = max(target[long], min(out[long], room))
    return factor, scaled, tuple(out)


def magick_fit(src, dst, scaled, out):
    """Lanczos to the scaled size, then the centre `out` of it (the same size, unless it was too big)"""
    subprocess.run(["magick", f"{src}[0]", "-auto-orient", "-background", "black", "-flatten", "-filter", "Lanczos",
                    "-resize", f"{scaled[0]}x{scaled[1]}!", "-gravity", "center", "-extent", f"{out[0]}x{out[1]}",
                    "-quality", "95", "-sampling-factor", "4:4:4", dst], check=True)


def die_with_parent():
    # upscayl-bin goes when this script does (a killed shell, a timeout): no GPU job left running for nobody
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)  # PR_SET_PDEATHSIG


def upscale(src, dst, factor, scaled, out, model):
    """Upscayl to the next model scale up (2, 3 or 4), then Lanczos to the exact size; Lanczos alone if it can't"""
    scale = 2 if factor <= 2 else 3 if factor <= 3 else 4
    with tempfile.TemporaryDirectory(dir=CACHE, prefix="tmp-") as tmp:
        # upscayl-bin reads jpg/png/webp only and knows no EXIF rotation: a plain upright PNG, and opaque (an alpha
        # channel is upscaled on its own, and the copy is flattened on black anyway)
        flat, big = os.path.join(tmp, "in.png"), os.path.join(tmp, "big.png")
        try:
            subprocess.run(["magick", f"{src}[0]", "-auto-orient", "-background", "black", "-flatten", "-alpha", "off",
                            flat], check=True)
            r = subprocess.run([UPSCAYL, "-i", flat, "-o", big, "-m", MODELS, "-n", model, "-z", "4", "-s", str(scale),
                                "-f", "png"], capture_output=True, text=True, preexec_fn=die_with_parent,
                               timeout=UPSCAYL_TIMEOUT)
            if r.returncode == 0 and os.path.isfile(big):
                magick_fit(big, dst, scaled, out)
                return "upscayl"
            print(f"upscayl-bin failed ({r.returncode}), Lanczos instead: {r.stderr.strip()[-300:]}", file=sys.stderr)
        except subprocess.TimeoutExpired:  # killed by subprocess.run; tried again on a later run (RETRIES)
            print(f"upscayl-bin took over {UPSCAYL_TIMEOUT} s, Lanczos instead", file=sys.stderr)
        except OSError as e:  # not installed
            print(f"upscayl-bin: {e}, Lanczos instead", file=sys.stderr)
    magick_fit(src, dst, scaled, out)
    return "lanczos"


def contain(w, h, target, mode):
    """For contain-blur and seam: the picture's size scaled to fit inside the screen, and that size after seam carving
    along the short side (the same in contain-blur, or when seam carving would stretch it past SEAM_MAX)"""
    factor = min(target[0] / w, target[1] / h)
    inside = (min(target[0], round(w * factor)), min(target[1], round(h * factor)))
    if mode != "seam":
        return factor, inside, inside
    carved = (min(target[0], round(inside[0] * SEAM_MAX)), min(target[1], round(inside[1] * SEAM_MAX)))
    return factor, inside, carved


def fill(src, fg, dst, target, inside, carved):
    """The copy: `fg` (the picture at `inside`), seam-carved to `carved`, centred on the blurred picture; returns how
    the room was filled"""
    how = "blur"
    if carved != inside:
        wide = fg + ".seam.miff"
        try:
            subprocess.run(["magick", fg, "-liquid-rescale", f"{carved[0]}x{carved[1]}!", wide], check=True,
                           timeout=SEAM_TIMEOUT, preexec_fn=die_with_parent)
            fg, inside = wide, carved
            how = "seam"
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired) as e:
            print(f"seam carving failed ({e}), blurred room instead", file=sys.stderr)
    if inside == target:
        subprocess.run(["magick", fg, "-quality", "95", "-sampling-factor", "4:4:4", dst], check=True)
        return how
    if how == "seam":
        how = "seam+blur"
    small = (max(1, target[0] // BLUR_SHRINK), max(1, target[1] // BLUR_SHRINK))
    subprocess.run(["magick", f"{src}[0]", "-auto-orient", "-background", "black", "-flatten",
                    "-resize", f"{small[0]}x{small[1]}^", "-gravity", "center", "-extent", f"{small[0]}x{small[1]}",
                    "-blur", "0x6", "-modulate", "70", "-filter", "Lanczos", "-resize", f"{target[0]}x{target[1]}!",
                    fg, "-gravity", "center", "-composite",
                    "-quality", "95", "-sampling-factor", "4:4:4", dst], check=True)
    return how


def fit(path, target_size, model, index, keep=False, mode="cover"):
    """Make (or reuse) the copy of one picture; returns a line for the log"""
    target = f"{target_size[0]}x{target_size[1]}"
    walls = index["walls"]
    old = walls.get(path)
    if valid(old, path, target, model, mode):
        old["used"] = time.time()
        if keep:
            old["keep"] = True
        return f"{path}: kept" + (f" (failed before: {old['error']})" if old.get("error") else "")
    source = stamp(path)
    entry = {"target": target, "source": source, "fitted": "", "used": time.time(), "mode": mode}
    if keep or (old or {}).get("keep"):
        entry["keep"] = True
    walls[path] = entry
    try:
        w, h, frames = picture_size(path)
        factor, scaled, out = cover(w, h, target_size)
        inner, inside, carved = contain(w, h, target_size, mode)
        # the screen's shape already (to CLOSE): nothing to fill, every mode makes the same cover
        same_shape = inner / factor >= 1 - CLOSE
        filled = mode != "cover" and not same_shape
        entry.update(mode=mode if filled else "cover", anymode=same_shape or frames > 1)
        if frames > 1 or (not filled and abs(factor - 1) <= CLOSE):
            return f"{path}: as it is ({w}x{h})"  # animated, or already the screen's size
        if filled:
            factor, scaled, out = inner, inside, target_size
        entry.update(upscale=factor > 1, model=model)
        # a new name for each version of the picture: the renderer reloads only when the path changes
        # (a cover's name as before the modes: those copies stay good)
        version = f"{path}|{source['mtime']}|{source['bytes']}|{model}" + (f"|{mode}" if filled else "")
        key = hashlib.sha1(version.encode()).hexdigest()[:16]
        dst = os.path.join(CACHE, f"{key}-{out[0]}x{out[1]}.jpg")
        part = dst + ".part.jpg"
        if filled:
            with tempfile.TemporaryDirectory(dir=CACHE, prefix="tmp-") as tmp:
                fg = os.path.join(tmp, "fg.miff")  # the picture at its size inside the screen, uncompressed
                how = upscale(path, fg, factor, inside, inside, model) if factor > 1 else magick_fit(path, fg, inside, inside) or "lanczos"
                entry["fill"] = fill(path, fg, part, target_size, inside, carved)
        else:
            how = upscale(path, part, factor, scaled, out, model) if factor > 1 else magick_fit(path, part, scaled, out) or "lanczos"
        os.replace(part, dst)
        entry.update(fitted=dst, how=how)
        if filled and carved != inside and not entry["fill"].startswith("seam"):
            entry["seamFailed"] = True
        if (how == "lanczos" and factor > 1) or entry.get("seamFailed"):
            entry["tries"] = (old or {}).get("tries", 0) + 1 if (old or {}).get("source") == source else 1
        return (f"{path}: {w}x{h} -> {out[0]}x{out[1]} ({how}{' ' + model if how == 'upscayl' else ''}"
                f"{', ' + entry['fill'] if filled else ''})")
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired, OSError, ValueError, IndexError) as e:
        entry["error"] = str(e)[-300:]  # remembered: not tried again until the picture, screen or model changes
        return f"{path}: failed, shown as it is: {entry['error']}"


def prune(index, asked):
    """Keep the copies made with --keep, the ones this run was asked for and the KEEP others shown last; remove the
    entries of pictures that are gone, files no entry points at, and what a killed run left behind"""
    walls = index["walls"]
    for path in [p for p in walls if not os.path.isfile(p)]:
        del walls[path]
    others = [p for p in walls if not walls[p].get("keep") and p not in asked]
    for path in sorted(others, key=lambda p: walls[p].get("used", 0), reverse=True)[KEEP:]:
        del walls[path]
    kept = {e["fitted"] for e in walls.values() if e.get("fitted")}
    for name in os.listdir(CACHE):
        full = os.path.join(CACHE, name)
        if name.startswith("tmp-") and os.path.isdir(full):
            shutil.rmtree(full, ignore_errors=True)
        elif (name.endswith(".jpg") and full not in kept) or (name.endswith(".tmp") and full != INDEX):
            os.remove(full)


def main():
    keep = "--keep" in sys.argv[1:]
    paths = [os.path.abspath(p) for p in sys.argv[1:] if p != "--keep"]
    if not paths:
        print(__doc__, file=sys.stderr)
        sys.exit(2)
    enabled, model, mode = settings()
    if not enabled:
        return
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(1))  # so the temporary files are cleaned up
    os.makedirs(CACHE, exist_ok=True)
    with open(os.path.join(CACHE, ".lock"), "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # one at a time: wallpapers picked in a row queue up, the GPU isn't shared
        size = screen_size()
        index = load_index()
        index["target"] = f"{size[0]}x{size[1]}"
        for path in dict.fromkeys(paths):
            if not os.path.isfile(path) or path.lower().endswith(VIDEOS) or path.startswith(CACHE + os.sep):
                continue
            print(fit(path, size, model, index, keep, mode))
            save_index(index)  # after each: the shell shows each copy as soon as it's made
        prune(index, set(paths))
        save_index(index)


if __name__ == "__main__":
    main()
