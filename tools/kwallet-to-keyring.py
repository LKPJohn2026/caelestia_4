#!/usr/bin/env python3
"""caelestia4: copy every KWallet secret into gnome-keyring's login keyring (docs/dev/kde-removal.md, phase 3).

  tools/kwallet-to-keyring.py --dry-run   list what would be written (never the values)
  tools/kwallet-to-keyring.py --write     write it, each item read back and compared; only when gnome-keyring owns
                                          org.freedesktop.secrets and its default (login) keyring is unlocked

KWallet is read through its Secret Service daemon under its own name (ksecretd, org.kde.secretservicecompat): it shows
every item there, KWallet's native entries included, and keeps that name when its org.freedesktop.secrets side is off
(kwalletrc apiEnabled=false). kwalletd6's own API misses the items made through the Secret Service (gh, Zed, Python
keyring, the Assistant's keys) and lists each folder several times. Values stay in memory.

Items are copied with their label, attributes and content type. KWallet's native Chromium / Electron keys ("Brave
Keys/Brave Safe Storage"...: what Brave and Claude decrypt their data with today) are also written the way libsecret
looks them up (chrome_libsecret_os_crypt_password_v2, application=...), so they keep working with
--password-store=gnome-libsecret; that copy replaces an older libsecret one, and whether the two matched is printed.
"""
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

KWALLET = "org.kde.secretservicecompat"
KEYRING = "org.freedesktop.secrets"
ROOT = "/org/freedesktop/secrets"
V2 = "chrome_libsecret_os_crypt_password_v2"

bus = Gio.bus_get_sync(Gio.BusType.SESSION)


def call(name, path, iface, method, sig, args, ret):
    return bus.call_sync(name, path, iface, method, GLib.Variant(sig, args) if sig else None,
                         GLib.VariantType(ret), Gio.DBusCallFlags.NONE, 60000, None).unpack()


def prop(name, path, iface, key):
    return call(name, path, "org.freedesktop.DBus.Properties", "Get", "(ss)", (iface, key), "(v)")[0]


def owner(name):
    try:
        pid = call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                   "GetConnectionUnixProcessID", "(s)", (name,), "(u)")[0]
        return open(f"/proc/{pid}/comm").read().strip()
    except (GLib.Error, OSError):
        return None


def session(name):
    """A "plain" session: the way libsecret talks to a keyring daemon on the session bus"""
    return call(name, ROOT, "org.freedesktop.Secret.Service", "OpenSession", "(sv)",
                ("plain", GLib.Variant("s", "")), "(vo)")[1]


def unlock(name, coll):
    """Unlock a collection; when the daemon wants a prompt (KWallet asks for the wallet password in its own dialog,
    which never passes through here), show it and wait for the answer"""
    _, prompt = call(name, ROOT, "org.freedesktop.Secret.Service", "Unlock", "(ao)", ([coll],), "(aoo)")
    if prompt != "/":
        loop, result = GLib.MainLoop(), {}

        def done(_c, _s, _p, _i, _sig, params):
            result["dismissed"] = params.unpack()[0]
            loop.quit()

        sub = bus.signal_subscribe(name, "org.freedesktop.Secret.Prompt", "Completed", prompt, None,
                                   Gio.DBusSignalFlags.NONE, done)
        print("KWallet is locked: enter the wallet password (your login password) in its dialog")
        call(name, prompt, "org.freedesktop.Secret.Prompt", "Prompt", "(s)", ("",), "()")
        loop.run()
        bus.signal_unsubscribe(sub)
        if result.get("dismissed"):
            sys.exit("the unlock prompt was dismissed")
    if prop(name, coll, "org.freedesktop.Secret.Collection", "Locked"):
        sys.exit(f"{coll} is still locked")


def read_kwallet():
    """[(label, attributes, content_type, bytes)] of every item of KWallet's collections"""
    if owner(KWALLET) is None:  # D-Bus starts ksecretd (org.kde.secretservicecompat.service)
        call("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "StartServiceByName", "(su)",
             (KWALLET, 0), "(u)")
    sess = session(KWALLET)
    items = []
    for coll in prop(KWALLET, ROOT, "org.freedesktop.Secret.Service", "Collections"):
        if prop(KWALLET, coll, "org.freedesktop.Secret.Collection", "Locked"):
            unlock(KWALLET, coll)
        for path in prop(KWALLET, coll, "org.freedesktop.Secret.Collection", "Items"):
            label = prop(KWALLET, path, "org.freedesktop.Secret.Item", "Label")
            attrs = dict(prop(KWALLET, path, "org.freedesktop.Secret.Item", "Attributes"))
            _, _, value, ctype = call(KWALLET, path, "org.freedesktop.Secret.Item", "GetSecret", "(o)", (sess,),
                                      "((oayays))")[0]
            items.append((label, attrs, ctype or "text/plain", bytes(value)))
    call(KWALLET, sess, "org.freedesktop.Secret.Session", "Close", None, None, "()")
    return items


def plan(items):
    """[(label, attributes, content_type, value, note)] to write"""
    out = []
    v2 = {(a.get("application") or ""): (label, value) for label, a, _, value in items if a.get("xdg:schema") == V2}
    native_v2 = set()
    for label, attrs, ctype, value in items:
        if attrs.get("xdg:schema") == "org.qt.keychain" and attrs.get("server", "").endswith(" Keys") \
                and attrs.get("user", "").endswith(" Safe Storage"):
            # libsecret's name: as the existing libsecret copy has it, else both the Electron form (the KWallet
            # folder's name as is, e.g. Claude) and the browser form (lowercase, e.g. brave)
            name = attrs["server"][:-len(" Keys")]
            known = [a for a in v2 if a.lower() == name.lower()]
            for app in known or sorted({name, name.lower()}):
                old = v2.get(app)
                same = "no libsecret copy before" if old is None else (
                    "same as the libsecret copy" if old[1] == value else "DIFFERENT from the libsecret copy: native kept")
                out.append((attrs["user"], {"xdg:schema": V2, "application": app}, "text/plain", value,
                            f"{label} -> libsecret application={app} ({same})"))
                native_v2.add(app)
                # A different older libsecret key encrypted what the app wrote while it used libsecret: kept under
                # another schema (no app looks it up), in case that data is wanted back
                if old is not None and old[1] != value:
                    out.append((f"{old[0]} (replaced libsecret key)",
                                {"xdg:schema": "org.caelestia4.replaced", "application": app,
                                 "replaced-schema": V2}, "text/plain", old[1],
                                f"the older libsecret {old[0]} (application={app}) kept as a backup"))
    for label, attrs, ctype, value in items:
        if attrs.get("xdg:schema") == V2 and attrs.get("application") in native_v2:
            continue  # replaced by the native key above
        out.append((label, attrs, ctype, value, label))
    return out


def write(items):
    who = owner(KEYRING)
    if who != "gnome-keyring-d":
        sys.exit(f"{KEYRING} is served by {who or 'nobody'}, not gnome-keyring: not writing")
    sess = session(KEYRING)
    (coll,) = call(KEYRING, ROOT, "org.freedesktop.Secret.Service", "ReadAlias", "(s)", ("default",), "(o)")
    if coll == "/":
        sys.exit("gnome-keyring has no default keyring (log in again: pam_gnome_keyring creates it)")
    if prop(KEYRING, coll, "org.freedesktop.Secret.Collection", "Locked"):
        sys.exit("gnome-keyring's default keyring is locked (log in again: pam_gnome_keyring unlocks it)")
    print(f"writing to the \"{prop(KEYRING, coll, 'org.freedesktop.Secret.Collection', 'Label')}\" keyring ({coll})")
    for label, attrs, ctype, value, note in items:
        properties = {"org.freedesktop.Secret.Item.Label": GLib.Variant("s", label),
                      "org.freedesktop.Secret.Item.Attributes": GLib.Variant("a{ss}", attrs)}
        item, prompt = call(KEYRING, coll, "org.freedesktop.Secret.Collection", "CreateItem", "(a{sv}(oayays)b)",
                            (properties, (sess, b"", value, ctype), True), "(oo)")
        if prompt != "/":
            sys.exit(f"gnome-keyring wants a prompt for {note}: unlock the keyring and run again")
        # Read it back and compare byte for byte
        if bytes(call(KEYRING, item, "org.freedesktop.Secret.Item", "GetSecret", "(o)", (sess,),
                      "((oayays))")[0][2]) != value:
            sys.exit(f"read-back mismatch for {note}: stopped (KWallet is untouched)")
        print(f"  ok  {note} (read back, identical)")
    call(KEYRING, sess, "org.freedesktop.Secret.Session", "Close", None, None, "()")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("--dry-run", "--write"):
        sys.exit(__doc__)
    items = read_kwallet()
    print(f"KWallet: {len(items)} items ({KEYRING} now: {owner(KEYRING) or 'nobody'})")
    out = plan(items)
    print(f"\n{len(out)} items for gnome-keyring:")
    for label, attrs, ctype, value, note in out:
        shown = ", ".join(f"{k}={v}" for k, v in attrs.items()) or "(no attributes)"
        print(f"  {note}\n      \"{label}\", {ctype}, {len(value)} B, {shown}")
    if sys.argv[1] == "--write":
        print()
        write(out)


main()
