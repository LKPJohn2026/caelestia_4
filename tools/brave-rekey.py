# Re-encrypt Brave data that was written with the libsecret key (Hyprland, no KWallet) with the KWallet key
# (what Brave uses in both sessions now). Scans Preferences / Local State strings and the v11 columns of the
# profile's SQLite DBs. Default: report only. --apply: rewrite (Brave must be closed; backups are made).
# Never prints secrets.
import base64, glob, hashlib, json, os, shutil, sqlite3, subprocess, sys, time

APPLY = "--apply" in sys.argv
ROOT = os.path.expanduser("~/.config/BraveSoftware/Brave-Origin")
BACKUP = os.path.expanduser(f"~/.local/state/caelestia4/backup-brave-rekey-{time.strftime('%Y%m%d-%H%M%S')}")


def lookup(*attrs):
    r = subprocess.run(["secret-tool", "lookup", *attrs], capture_output=True)
    if r.returncode != 0 or not r.stdout:
        sys.exit(f"wallet item not found: {attrs}")
    return r.stdout.rstrip(b"\n")


def derive(pw):
    return hashlib.pbkdf2_hmac("sha1", pw, b"saltysalt", 1, 16)


OLD = derive(lookup("application", "brave", "xdg:schema", "chrome_libsecret_os_crypt_password_v2"))
NEW = derive(lookup("server", "Brave Keys", "user", "Brave Safe Storage"))
IV = (b" " * 16).hex()


def dec(key, data):
    r = subprocess.run(["openssl", "enc", "-d", "-aes-128-cbc", "-K", key.hex(), "-iv", IV], input=data, capture_output=True)
    return r.stdout if r.returncode == 0 else None


def enc(key, data):
    return subprocess.run(["openssl", "enc", "-e", "-aes-128-cbc", "-K", key.hex(), "-iv", IV], input=data,
                          capture_output=True, check=True).stdout


def rekey(blob):
    """v11 blob -> re-encrypted blob if it is on the old key (and not already readable with the new one)."""
    if blob[:3] != b"v11" or dec(NEW, blob[3:]) is not None:
        return None
    plain = dec(OLD, blob[3:])
    if plain is None:
        return None
    return b"v11" + enc(NEW, plain)


if APPLY and subprocess.run(["pgrep", "-x", "brave"], capture_output=True).returncode == 0:
    sys.exit("Brave is running: close every Brave window (including web apps) first.")

total = 0


def backup(path):
    if APPLY:
        dst = os.path.join(BACKUP, os.path.relpath(path, ROOT))
        os.makedirs(os.path.dirname(dst), exist_ok=True)
        shutil.copy2(path, dst)


# JSON prefs: base64 strings starting with "v11"
def walk(node, path, hits):
    if isinstance(node, dict):
        for k, v in node.items():
            if isinstance(v, str):
                try:
                    raw = base64.b64decode(v, validate=True)
                except Exception:
                    continue
                new = rekey(raw)
                if new:
                    hits.append(path + [k])
                    node[k] = base64.b64encode(new).decode()
            else:
                walk(v, path + [k], hits)
    elif isinstance(node, list):
        for i, v in enumerate(node):
            walk(v, path + [i], hits)


for f in [os.path.join(ROOT, "Local State")] + glob.glob(os.path.join(ROOT, "*", "Preferences")):
    data = json.load(open(f))
    hits = []
    walk(data, [], hits)
    if hits:
        total += len(hits)
        print(f"{os.path.relpath(f, ROOT)}: {len(hits)} value(s) on the old key: {['.'.join(map(str, h))[:80] for h in hits]}")
        if APPLY:
            backup(f)
            json.dump(data, open(f, "w"), separators=(",", ":"))

# SQLite: every BLOB column whose value starts with v11
for f in glob.glob(os.path.join(ROOT, "*", "*")):
    if not os.path.isfile(f) or open(f, "rb").read(16) != b"SQLite format 3\x00":
        continue
    try:
        con = sqlite3.connect(f if APPLY else f"file:{f}?mode=ro&immutable=1", uri=not APPLY)
        tables = [r[0] for r in con.execute("select name from sqlite_master where type='table'")]
    except Exception:
        continue
    fixes = []
    for t in tables:
        cols = [r[1] for r in con.execute(f'pragma table_info("{t}")')]
        for c in cols:
            try:
                rows = con.execute(f'select rowid, "{c}" from "{t}" where typeof("{c}")=\'blob\' and hex(substr("{c}",1,3))=\'763131\'').fetchall()
            except Exception:
                continue
            for rowid, blob in rows:
                new = rekey(bytes(blob))
                if new:
                    fixes.append((t, c, rowid, new))
    if fixes:
        total += len(fixes)
        summary = {}
        for t, c, _, _ in fixes:
            summary[f"{t}.{c}"] = summary.get(f"{t}.{c}", 0) + 1
        print(f"{os.path.relpath(f, ROOT)}: {summary}")
        if APPLY:
            con.close()
            backup(f)
            for side in ("-journal", "-wal"):
                if os.path.exists(f + side):
                    backup(f + side)
            con = sqlite3.connect(f)
            for t, c, rowid, new in fixes:
                con.execute(f'update "{t}" set "{c}"=? where rowid=?', (new, rowid))
            con.commit()
    con.close()

print(f"total on the old key: {total}" + (f"  -> re-encrypted, backup in {BACKUP}" if APPLY and total else ""))
