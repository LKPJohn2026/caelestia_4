#!/usr/bin/env python3
"""caelestia4: copy every KWallet entry into gnome-keyring's login keyring (docs/dev/kde-removal.md, phase 3).

  tools/kwallet-to-keyring.py --dry-run   read KWallet and print what would be written (never the values)
  tools/kwallet-to-keyring.py --write     write it; only when gnome-keyring owns org.freedesktop.secrets and the
                                          default (login) keyring is unlocked

KWallet is read through kwalletd6's own D-Bus API (KWallet asks once to let this script open the wallet); values stay
in memory. Entries made through the Secret Service (gh, Zed, Python keyring, the Assistant's keys...) are copied with
their label, attributes and content type (~/.local/share/kwalletd/<wallet>_attributes.json). Chromium / Electron keys
KWallet holds natively ("Brave Keys/Brave Safe Storage"...: what Brave and Claude decrypt their data with today) are
also written the way they look them up through libsecret (chrome_libsecret_os_crypt_password_v2, application=...), so
they keep working after the switch to --password-store=gnome-libsecret / XDG_CURRENT_DESKTOP=Hyprland. Where a
libsecret copy of such a key already exists in KWallet, the native one wins (it is the one in use); whether the two
match is printed. Other KWallet-only entries are kept as items with xdg:schema org.kde.kwallet.entry (folder, key).
"""
import json
import os
import sys

import gi

gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

WALLET = "kdewallet"
APPID = "caelestia4 kwallet-to-keyring"
TYPES = {0: "unknown", 1: "password", 2: "stream", 3: "map"}
V2 = "chrome_libsecret_os_crypt_password_v2"

bus = Gio.bus_get_sync(Gio.BusType.SESSION)


def kwallet(method, sig, args, ret):
    return bus.call_sync("org.kde.kwalletd6", "/modules/kwalletd6", "org.kde.KWallet", method,
                         GLib.Variant(sig, args), GLib.VariantType(ret), Gio.DBusCallFlags.NONE,
                         120000, None).unpack()[0]  # 2 min: the access prompt waits for you


def owner(name):
    try:
        pid = bus.call_sync("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
                            "GetConnectionUnixProcessID", GLib.Variant("(s)", (name,)), GLib.VariantType("(u)"),
                            Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
        return open(f"/proc/{pid}/comm").read().strip()
    except (GLib.Error, OSError):
        return None


def read_kwallet():
    """[(folder, key, type, bytes)] for every entry of the wallet"""
    handle = kwallet("open", "(sxs)", (WALLET, 0, APPID), "(i)")
    if handle < 0:
        sys.exit("KWallet didn't open the wallet (access refused?)")
    entries = []
    try:
        for folder in kwallet("folderList", "(is)", (handle, APPID), "(as)"):
            for key in kwallet("entryList", "(iss)", (handle, folder, APPID), "(as)"):
                kind = kwallet("entryType", "(isss)", (handle, folder, key, APPID), "(i)")
                if kind == 1:
                    data = kwallet("readPassword", "(isss)", (handle, folder, key, APPID), "(s)").encode()
                else:
                    data = bytes(kwallet("readEntry", "(isss)", (handle, folder, key, APPID), "(ay)"))
                entries.append((folder, key, TYPES.get(kind, str(kind)), data))
    finally:
        kwallet("close", "(ibs)", (handle, False, APPID), "(i)")
    return entries


def plan(entries):
    """[(label, attributes, content_type, value, note)] to write"""
    path = os.path.expanduser(f"~/.local/share/kwalletd/{WALLET}_attributes.json")
    meta = json.load(open(path)) if os.path.exists(path) else {}
    items, notes = [], []
    by_folder_key = {(f, k): v for f, k, _, v in entries}
    # Electron / Chromium apps' libsecret names, from the libsecret copies KWallet already has (else lowercase)
    v2_apps = {k: m["attributes"]["application"] for k, m in meta.get("Secret Service", {}).items()
               if isinstance(m, dict) and m.get("attributes", {}).get("xdg:schema") == V2}
    for folder, key, kind, value in entries:
        m = meta.get(folder, {}).get(key) if isinstance(meta.get(folder), dict) else None
        attrs = dict(m.get("attributes", {})) if isinstance(m, dict) else {}
        ctype = (m or {}).get("$fdo_mime_type") or ("text/plain" if kind == "password" else "application/octet-stream")
        if folder == "Secret Service" and attrs.get("xdg:schema") == V2:
            continue  # written from the native key below
        if not attrs:
            attrs = {"xdg:schema": "org.kde.kwallet.entry", "folder": folder, "key": key}
        items.append((key, attrs, ctype, value, f"{folder}/{key}"))
        # A native "<App> Keys/<App> Safe Storage": also as libsecret looks it up
        if folder.endswith(" Keys") and key.endswith(" Safe Storage"):
            # The libsecret name: as the existing copy has it; else both the Electron form (the KWallet folder's
            # name as is, e.g. Claude) and the browser form (lowercase, e.g. brave)
            name = folder[:-len(" Keys")]
            apps = [v2_apps[key]] if key in v2_apps else sorted({name, name.lower()})
            old = by_folder_key.get(("Secret Service", key))
            same = "no libsecret copy before" if old is None else ("same as the libsecret copy" if old == value
                                                                  else "DIFFERENT from the libsecret copy (native kept)")
            for app in apps:
                items.append((key, {"xdg:schema": V2, "application": app}, "text/plain", value,
                              f"{folder}/{key} -> libsecret application={app} ({same})"))
    # libsecret-only keys with no native twin: keep them as they were
    for key, m in meta.get("Secret Service", {}).items():
        if isinstance(m, dict) and m.get("attributes", {}).get("xdg:schema") == V2 \
                and not any(f.endswith(" Keys") and k == key for f, k, _, _ in entries):
            value = by_folder_key.get(("Secret Service", key))
            if value is not None:
                items.append((key, dict(m["attributes"]), "text/plain", value, f"Secret Service/{key} (libsecret only)"))
    return items


def secrets(path, iface, method, sig, args, ret):
    return bus.call_sync("org.freedesktop.secrets", path, f"org.freedesktop.Secret.{iface}", method,
                         GLib.Variant(sig, args) if sig else None, GLib.VariantType(ret), Gio.DBusCallFlags.NONE,
                         -1, None).unpack()


def write(items):
    """Through the Secret Service D-Bus API itself (libsecret's Python binding only takes text values): a "plain"
    session on the session bus, the way libsecret talks to a local keyring daemon"""
    who = owner("org.freedesktop.secrets")
    if who != "gnome-keyring-d":
        sys.exit(f"org.freedesktop.secrets is served by {who or 'nobody'}, not gnome-keyring: not writing")
    root = "/org/freedesktop/secrets"
    _, session = secrets(root, "Service", "OpenSession", "(sv)", ("plain", GLib.Variant("s", "")), "(vo)")
    (coll,) = secrets(root, "Service", "ReadAlias", "(s)", ("default",), "(o)")
    if coll == "/":
        sys.exit("gnome-keyring has no default keyring (log in again with pam_gnome_keyring)")
    props = lambda name: bus.call_sync("org.freedesktop.secrets", coll, "org.freedesktop.DBus.Properties", "Get",
                                       GLib.Variant("(ss)", ("org.freedesktop.Secret.Collection", name)),
                                       GLib.VariantType("(v)"), Gio.DBusCallFlags.NONE, -1, None).unpack()[0]
    if props("Locked"):
        sys.exit("gnome-keyring's default keyring is locked (log in again with pam_gnome_keyring)")
    print(f"writing to the \"{props('Label')}\" keyring ({coll})")
    for label, attrs, ctype, value, note in items:
        properties = {"org.freedesktop.Secret.Item.Label": GLib.Variant("s", label),
                      "org.freedesktop.Secret.Item.Attributes": GLib.Variant("a{ss}", attrs)}
        item, prompt = secrets(coll, "Collection", "CreateItem", "(a{sv}(oayays)b)",
                            (properties, (session, b"", value, ctype), True), "(oo)")
        if prompt != "/":
            sys.exit(f"gnome-keyring wants a prompt for {note}: unlock the keyring and run again")
        # Read it back and compare byte for byte
        (secret,) = secrets(item, "Item", "GetSecret", "(o)", (session,), "((oayays))")
        if bytes(secret[2]) != value:
            sys.exit(f"read-back mismatch for {note}: stopped (KWallet is untouched)")
        print(f"  ok  {note} (read back, identical)")
    secrets(session, "Session", "Close", None, None, "()")


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in ("--dry-run", "--write"):
        sys.exit(__doc__)
    entries = read_kwallet()
    print(f"KWallet \"{WALLET}\": {len(entries)} entries in {len({f for f, *_ in entries})} folders "
          f"(Secret Service now: {owner('org.freedesktop.secrets') or 'nobody'})")
    for folder, key, kind, value in entries:
        print(f"  {kind:8} {len(value):5d} B  {folder}/{key}")
    items = plan(entries)
    print(f"\n{len(items)} items for gnome-keyring:")
    for label, attrs, ctype, value, note in items:
        shown = ", ".join(f"{k}={v}" for k, v in attrs.items())
        print(f"  {note}\n      label \"{label}\", {ctype}, {len(value)} B, {shown}")
    if sys.argv[1] == "--write":
        print()
        write(items)


main()
