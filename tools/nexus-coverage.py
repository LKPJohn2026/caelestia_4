#!/usr/bin/env python3
"""caelestia4: Nexus settings coverage.

Lists every end-4 option (modules/common/Config.qml, ids "e4:<path>") and every Caelestia option
(third_party/caelestia-shell/plugin/src/Caelestia/Config/*.hpp, ids "c:<path>"), and compares them with the ids the
Nexus registry has (keys in nexus/registry/Reg*.qml) plus nexus/registry/ignored.json ({id or glob: reason}).

Usage: tools/nexus-coverage.py [--strict] [--emit-defaults] [--check-defaults] [--check-mirrors] [--list]
  (none)            counts, then the missing ids grouped by top-level key
  --strict          exit 1 when an id is missing
  --emit-defaults   write nexus/registry/E4Defaults.js (end-4 defaults by dotted path)
  --check-defaults  exit 1 when E4Defaults.js is not what --emit-defaults would write
  --check-mirrors   exit 1 when a setting kept in both shell.json and config.json could be written to one only
                    (see check_mirrors)
  --list            print every option id with its default (debugging the parsers)
"""
import argparse
import fnmatch
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
II = ROOT / "dots/.config/quickshell/ii"
E4_CONFIG = II / "modules/common/Config.qml"
C_CONFIG_DIR = ROOT / "third_party/caelestia-shell/plugin/src/Caelestia/Config"
REGISTRY = II / "modules/caelestia/nexus/registry"
DEFAULTS_JS = REGISTRY / "E4Defaults.js"
IGNORED = REGISTRY / "ignored.json"
SERVICE_LOADER = II / "modules/caelestia/ServiceLoader.qml"


# ---------------------------------------------------------------------------------------------------------------------
# A small scanner for QML / C++ text: strings and comments are skipped as units, brackets are balanced

class Scanner:
    def __init__(self, text):
        self.s = text
        self.i = 0

    def eof(self):
        return self.i >= len(self.s)

    def skip_ws(self, newlines=True):
        """Skips spaces and comments. With newlines=False, stops at a newline (statement end in QML)."""
        s = self.s
        while self.i < len(s):
            c = s[self.i]
            if c == "\n" and not newlines:
                return
            if c in " \t\r\n":
                self.i += 1
            elif s.startswith("//", self.i):
                j = s.find("\n", self.i)
                self.i = len(s) if j < 0 else j
            elif s.startswith("/*", self.i):
                j = s.find("*/", self.i + 2)
                self.i = len(s) if j < 0 else j + 2
            else:
                return

    def skip_string(self):
        """At a quote: moves past the string literal (', ", ` or a C++ R"(...)" is not needed here)."""
        s = self.s
        q = s[self.i]
        self.i += 1
        while self.i < len(s):
            c = s[self.i]
            if c == "\\":
                self.i += 2
                continue
            self.i += 1
            if c == q:
                return

    def read_expr(self, stop_at_newline):
        """Reads up to the end of an expression: a newline/';' (QML) or ',' / ')' (macro argument) at depth 0."""
        s = self.s
        start = self.i
        depth = 0
        while self.i < len(s):
            c = s[self.i]
            if c in "\"'`":
                self.skip_string()
                continue
            if s.startswith("//", self.i) or s.startswith("/*", self.i):
                if depth == 0 and stop_at_newline:
                    break
                self.skip_ws()
                continue
            if c in "([{":
                depth += 1
            elif c in ")]}":
                if depth == 0:
                    break
                depth -= 1
            elif depth == 0:
                if stop_at_newline and c in "\n;":
                    # a line ending in an operator goes on (`"a" +` newline `"b"`)
                    if c == "\n" and re.search(r"[+\-*/%?:|&,]\s*$", s[start:self.i]):
                        self.i += 1
                        continue
                    break
                if not stop_at_newline and c == ",":
                    break
            self.i += 1
        return s[start:self.i].strip()

    def skip_balanced(self):
        """At an opening bracket: moves past its closing one."""
        s = self.s
        depth = 0
        while self.i < len(s):
            c = s[self.i]
            if c in "\"'`":
                self.skip_string()
                continue
            if s.startswith("//", self.i) or s.startswith("/*", self.i):
                self.skip_ws()
                continue
            if c in "([{":
                depth += 1
            elif c in ")]}":
                depth -= 1
                if depth == 0:
                    self.i += 1
                    return
            self.i += 1


# ---------------------------------------------------------------------------------------------------------------------
# end-4 Config.qml

def strip_js_comments(text):
    out, sc = [], Scanner(text)
    while not sc.eof():
        c = sc.s[sc.i]
        if c in "\"'`":
            j = sc.i
            sc.skip_string()
            out.append(sc.s[j:sc.i])
        elif sc.s.startswith("//", sc.i) or sc.s.startswith("/*", sc.i):
            sc.skip_ws()
            out.append(" ")
        else:
            out.append(c)
            sc.i += 1
    return "".join(out)


def js_string(lit):
    """A JS string literal (any quote) as a Python string."""
    body = lit[1:-1]
    if lit[0] == "`" and "${" in body:
        raise ValueError("template with substitutions")
    if lit[0] == "'":
        body = body.replace("\\'", "'").replace('"', '\\"')
    elif lit[0] == "`":
        body = body.replace("\\`", "`").replace('"', '\\"').replace("\n", "\\n")
    return json.loads('"' + body + '"')


def js_value(expr):
    """A JS literal (number, bool, string, list/object of those, string concatenation) as a Python value.
    Raises ValueError for anything computed."""
    expr = strip_js_comments(expr).strip()
    # strings in any quote style become JSON strings
    out, sc = [], Scanner(expr)
    while not sc.eof():
        c = sc.s[sc.i]
        if c in "\"'`":
            j = sc.i
            sc.skip_string()
            out.append(json.dumps(js_string(sc.s[j:sc.i])))
        else:
            out.append(c)
            sc.i += 1
    t = "".join(out)
    t = re.sub(r",\s*([\]}])", r"\1", t)  # trailing commas
    t = re.sub(r'"\s*\+\s*"', "", t)  # "a" + "b"
    t = re.sub(r"([{,]\s*)([A-Za-z_$][\w$]*)\s*:", r'\1"\2":', t)  # unquoted object keys
    try:
        return json.loads(t)
    except json.JSONDecodeError:
        pass
    if re.fullmatch(r"[\d\s.+\-*/()]+", t):  # plain arithmetic (1000 * 60)
        return eval(t, {"__builtins__": {}}, {})  # noqa: S307 - digits and operators only
    raise ValueError(expr)


PROP_RE = re.compile(r"(?:(?:readonly|required|default)\s+)*property\s+([\w.]+(?:<[\w.]+>)?)\s+(\w+)\s*")


def parse_e4_block(sc, prefix, out):
    """Reads QML object members up to the closing brace; fills out[path] = (type, default or Ellipsis)."""
    while True:
        sc.skip_ws()
        if sc.eof():
            return
        if sc.s[sc.i] == "}":
            sc.i += 1
            return
        m = PROP_RE.match(sc.s, sc.i)
        if m:
            ptype, name = m.group(1), m.group(2)
            sc.i = m.end()
            path = prefix + name
            if sc.s[sc.i] != ":":  # declared without a value
                out[path] = (ptype, None)
                continue
            sc.i += 1
            sc.skip_ws(newlines=False)
            obj = re.match(r"(\w+)\s*\{", sc.s[sc.i:])
            if ptype == "JsonObject" and obj:
                sc.i += obj.end()
                parse_e4_block(sc, path + ".", out)
                continue
            expr = sc.read_expr(stop_at_newline=True)
            try:
                out[path] = (ptype, js_value(expr))
            except (ValueError, SyntaxError):
                out[path] = (ptype, Ellipsis)  # computed: no static default
            continue
        # anything else (function, signal, id:, handlers, nested objects): skip the statement
        if re.match(r"function\b", sc.s[sc.i:]):
            j = sc.s.find("{", sc.i)
            sc.i = j
            sc.skip_balanced()
            continue
        sc.read_expr(stop_at_newline=True)
        if not sc.eof() and sc.s[sc.i] in "{":
            sc.skip_balanced()
        elif not sc.eof() and sc.s[sc.i] in "\n;":
            sc.i += 1
        elif not sc.eof() and sc.s[sc.i] in ")]":
            sc.i += 1


def e4_options():
    text = E4_CONFIG.read_text()
    m = re.search(r"JsonAdapter\s*\{", text)
    if not m:
        sys.exit("nexus-coverage: no JsonAdapter in " + str(E4_CONFIG))
    sc = Scanner(text)
    sc.i = m.end()
    out = {}
    parse_e4_block(sc, "", out)
    return out


# ---------------------------------------------------------------------------------------------------------------------
# Caelestia Config/*.hpp

MACRO_RE = re.compile(r"\b(CONFIG_(?:GLOBAL_)?(?:PROPERTY|ENUM_PROPERTY|SUBOBJECT|LIST))\s*\(")
CLASS_RE = re.compile(r"\bclass\s+(\w+)\s*:\s*public\s+[\w:]+\s*\{")


def macro_args(sc):
    """At '(': the macro's arguments, split at depth-0 commas."""
    sc.i += 1
    args = []
    while True:
        sc.skip_ws()
        args.append(sc.read_expr(stop_at_newline=False))
        if sc.eof():
            return args
        c = sc.s[sc.i]
        sc.i += 1
        if c == ")":
            return args


def c_classes():
    """{class name: [(kind, type, name, default text)]}"""
    classes = {}
    for hpp in sorted(C_CONFIG_DIR.glob("*.hpp")):
        text = hpp.read_text()
        for cm in CLASS_RE.finditer(text):
            sc = Scanner(text)
            sc.i = cm.end() - 1
            start = sc.i
            sc.skip_balanced()
            body = text[start:sc.i]
            members = []
            for mm in MACRO_RE.finditer(body):
                bs = Scanner(body)
                bs.i = mm.end() - 1
                args = macro_args(bs)
                if len(args) < 2:
                    continue
                members.append((mm.group(1), args[0], args[1], args[2] if len(args) > 2 else None))
            if members:
                classes[cm.group(1)] = members
        font_macro_classes(text, classes)
    return classes


def strip_defines(text):
    """The text without its preprocessor lines (and their backslash continuations)."""
    out, cont = [], False
    for line in text.splitlines():
        if cont or line.lstrip().startswith("#"):
            cont = line.rstrip().endswith("\\")
            out.append("")
        else:
            out.append(line)
    return "\n".join(out)


FONT_MACRO_RE = re.compile(r"\b(FONT_STYLE|FONT_CONFIG)\s*\(")


def font_props(arg):
    """FONT({ .size = 32, .weight = QFont::Medium }) as FontConfig member defaults (detail::FontConfig's own
    defaults for the fields it leaves out)."""
    props = {"family": '""', "size": None, "weight": "QFont::Normal", "italic": "false", "vaxes": '{ { u"ROND"_s, 25 } }'}
    for field, val in re.findall(r"\.(\w+)\s*=\s*((?:\{[^{}]*\})|[^,}]+)", arg):
        props[field] = val.strip()
    return props


def font_macro_classes(text, classes):
    """caelestia4: appearanceconfig.hpp makes its font classes with FONT_STYLE / FONT_CONFIG #defines, which
    CLASS_RE cannot see (`class FontStyle##Style`). Expands each use of them into the classes the macros declare."""
    text = strip_defines(text)
    for mm in FONT_MACRO_RE.finditer(text):
        sc = Scanner(text)
        sc.i = mm.end() - 1
        args = macro_args(sc)
        if mm.group(1) == "FONT_CONFIG":
            if len(args) != 3:
                sys.exit(f"nexus-coverage: cannot read {text[mm.start():sc.i]!r}")
            style, size, props = args
            p = font_props(props)
            classes[f"FontConfig{style}{size}"] = [("CONFIG_PROPERTY", t, n, p[n]) for t, n in (
                ("QString", "family"), ("int", "size"), ("int", "weight"), ("bool", "italic"), ("QVariantMap", "vaxes"))]
        else:
            if len(args) != 5:
                sys.exit(f"nexus-coverage: cannot read {text[mm.start():sc.i]!r}")
            style, family = args[0], args[1]
            for size, props in zip(("Large", "Medium", "Small"), args[2:]):
                p = font_props(props)
                classes[f"FontConfig{style}{size}"] = [("CONFIG_PROPERTY", t, n, p[n]) for t, n in (
                    ("QString", "family"), ("int", "size"), ("int", "weight"), ("bool", "italic"),
                    ("QVariantMap", "vaxes"))]
            classes[f"FontStyle{style}"] = [("CONFIG_PROPERTY", "QString", "family", family)] + [
                ("CONFIG_SUBOBJECT", f"FontConfig{style}{size}", size.lower(), None) for size in ("Large", "Medium", "Small")]


def c_options():
    """({path: (type, default text)}, [subobject paths whose class the parser did not find])"""
    classes = c_classes()
    out = {}
    unresolved = []

    def walk(cls, prefix, seen):
        for kind, typ, name, default in classes.get(cls, []):
            path = prefix + name
            if kind.endswith("SUBOBJECT"):
                if typ in seen:
                    continue
                if typ not in classes:
                    unresolved.append(f"{path} ({typ})")
                    continue
                walk(typ, path + ".", seen | {typ})
            else:
                out[path] = (typ, default)

    walk("ConfigRoot", "", {"ConfigRoot"})
    return out, unresolved


# ---------------------------------------------------------------------------------------------------------------------

def registry_ids():
    ids = set()
    for f in sorted(REGISTRY.glob("Reg*.qml")):
        ids.update(re.findall(r'"((?:c|e4|h|x):[^"\s]+)"\s*:', f.read_text()))
    return ids


def ignored():
    if not IGNORED.exists():
        return {}
    data = json.loads(IGNORED.read_text())
    return {k: v for k, v in data.items() if not k.startswith("_")}


# ---------------------------------------------------------------------------------------------------------------------
# Settings kept in both files: Caelestia's shell.json and end-4's config.json

def end4_wanted():
    """ServiceLoader.qml's end4Wanted: {end-4 path: the expression its value comes from}"""
    text = SERVICE_LOADER.read_text()
    m = re.search(r"\bend4Wanted\s*:\s*\(\s*\{", text)
    if not m:
        sys.exit(f"nexus-coverage: no end4Wanted in {SERVICE_LOADER.relative_to(ROOT)}")
    sc = Scanner(text)
    sc.i = m.end()
    out = {}
    while True:
        sc.skip_ws()
        if sc.eof() or sc.s[sc.i] == "}":
            return out
        if sc.s[sc.i] not in "\"'":
            sys.exit(f"nexus-coverage: cannot read end4Wanted in {SERVICE_LOADER.relative_to(ROOT)} near "
                     f"{sc.s[sc.i:sc.i + 40]!r}")
        j = sc.i
        sc.skip_string()
        key = js_string(sc.s[j:sc.i])
        sc.skip_ws()
        if sc.eof() or sc.s[sc.i] != ":":
            sys.exit(f"nexus-coverage: cannot read end4Wanted[{key!r}] in {SERVICE_LOADER.relative_to(ROOT)}")
        sc.i += 1
        sc.skip_ws()
        out[key] = strip_js_comments(sc.read_expr(stop_at_newline=False))
        if not sc.eof() and sc.s[sc.i] == ",":
            sc.i += 1


def registry_mirrors():
    """{registry id: [the ids in its `mirrors`]}, for the entries that have one"""
    out = {}
    for f in sorted(REGISTRY.glob("Reg*.qml")):
        text = f.read_text()
        for m in re.finditer(r'"((?:c|e4|h|x):[^"\s]+)"\s*:\s*\{', text):
            sc = Scanner(text)
            sc.i = m.end() - 1
            sc.skip_balanced()
            body = strip_js_comments(text[m.end():sc.i - 1])
            mm = re.search(r"\bmirrors\s*:\s*\[([^\]]*)\]", body)
            if mm:
                out[m.group(1)] = re.findall(r'"([^"]+)"', mm.group(1))
    return out


def check_mirrors(e4, reg, ign):
    """Errors for the settings kept in both files, and how many there are. ServiceLoader.end4Wanted is the one place
    an end-4 key follows its Caelestia key, whatever wrote that (a Nexus row, a reset, Undo, a profile, an edit by
    hand), so:
      1. each end4Wanted key is an end-4 option with no Nexus row of its own (a row would write config.json alone,
         and the next sync puts the old value back), and ignored.json names its Caelestia key ("Synced from c:<id>
         (ServiceLoader)"), an id with a Nexus row
      2. each e4: id in a registry entry's `mirrors` (same value, also written by the page at once) is in
         end4Wanted, taken from that entry's key (GlobalConfig.<path>), and ignored.json names that entry
      3. QML that writes such an end-4 key itself (Config.options.<path> = ... or Config.setNestedValue("<path>", ...))
         names its Caelestia key in the same file (the setting id or GlobalConfig.<path>), so it copies that value
         rather than being a second source; and no QML outside the registry uses the end-4 key as a Nexus setting id
      4. no other ignored.json reason says "Synced from c:<id> (ServiceLoader)": that key isn't in end4Wanted
    Not seen: writes with a key built at run time (services/Ai.qml's set_shell_config calls setNestedValue(key, ...)),
    a bracket path (Config.options.bar.weather["city"]) or an assignment split over lines. The next sync puts such
    a write back. Per-screen files (caelestia/monitors/*/shell.json) aren't synced: end4Wanted reads the global layer."""
    errors = []
    wanted = end4_wanted()
    source = {}
    for path, expr in sorted(wanted.items()):
        eid = "e4:" + path
        if path not in e4:
            errors.append(f"ServiceLoader.end4Wanted: {eid} is not an end-4 option (modules/common/Config.qml)")
        if eid in reg:
            errors.append(f"{eid} has a Nexus row and ServiceLoader.end4Wanted syncs it: the row's writes are undone")
        m = re.search(r"Synced from (c:[\w.]+) \(ServiceLoader\)", ign.get(eid, ""))
        if not m:
            errors.append(f'ignored.json: {eid} needs "Synced from c:<id> (ServiceLoader)" (it is in end4Wanted)')
            continue
        source[path] = m.group(1)
        if m.group(1) not in reg:
            errors.append(f"ignored.json: {eid} is synced from {m.group(1)}, which has no Nexus row")
    for eid, reason in sorted(ign.items()):
        m = re.search(r"Synced from (c:[\w.]+) \(ServiceLoader\)", reason)
        if m and (not eid.startswith("e4:") or eid[3:] not in wanted):
            errors.append(f"ignored.json: {eid} says it is synced from {m.group(1)}, but it isn't in "
                          "ServiceLoader.end4Wanted")
    for cid, targets in sorted(registry_mirrors().items()):
        for t in targets:
            if not t.startswith("e4:"):
                continue  # a key of the same file, which the page writes
            path = t[3:]
            if path not in wanted:
                errors.append(f"{cid} mirrors {t}, which isn't in ServiceLoader.end4Wanted: only the page writes it")
                continue
            if not cid.startswith("c:") or not re.search(r"\bGlobalConfig\." + re.escape(cid[2:]) + r"\b", wanted[path]):
                errors.append(f"ServiceLoader.end4Wanted[{path!r}] isn't taken from {cid} (GlobalConfig.{cid[2:]})")
            if source.get(path, cid) != cid:
                errors.append(f"ignored.json: {t} is synced from {source[path]}, but the registry mirrors it from {cid}")
    for f in sorted(II.rglob("*.qml")) + sorted(II.rglob("*.js")):
        if f == SERVICE_LOADER or f == DEFAULTS_JS:
            continue
        text = strip_js_comments(f.read_text(errors="replace"))
        rel = f.relative_to(ROOT)
        for path, cid in sorted(source.items()):
            if f.parent != REGISTRY and f'"e4:{path}"' in text:
                errors.append(f"{rel}: uses e4:{path} as a setting, which writes config.json alone; use {cid}")
            if not (re.search(r"\bConfig\.options\??\." + re.escape(path) + r"\s*=(?!=)", text)
                    or re.search(r"\bsetNestedValue\(\s*[\"']" + re.escape(path) + r"[\"']", text)):
                continue
            if f'"{cid}"' not in text and not re.search(r"\bGlobalConfig\." + re.escape(cid[2:]) + r"\b", text):
                errors.append(f"{rel}: writes e4:{path} without naming its Caelestia key {cid}: the next sync undoes it")
    return errors, len(source)


def defaults_js(e4):
    defaults = {k: v for k, (_, v) in sorted(e4.items()) if v is not Ellipsis and v is not None}
    body = json.dumps(defaults, indent=4, ensure_ascii=False)
    return ("// caelestia4: GENERATED by tools/nexus-coverage.py --emit-defaults from modules/common/Config.qml.\n"
            "// Do not edit: run the script again after changing Config.qml (CI checks it with --check-defaults).\n"
            ".pragma library\n\n"
            f"var defaults = {body};\n")


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--strict", action="store_true")
    ap.add_argument("--emit-defaults", action="store_true")
    ap.add_argument("--check-defaults", action="store_true")
    ap.add_argument("--check-mirrors", action="store_true")
    ap.add_argument("--list", action="store_true")
    a = ap.parse_args()

    e4 = e4_options()
    c, unresolved = c_options()
    rc = 0
    if unresolved:
        # the options under these are left out of every count below: fix the parser
        print(f"nexus-coverage: ERROR: {len(unresolved)} Caelestia subobject(s) of an unknown class:", file=sys.stderr)
        for u in unresolved:
            print("  c:" + u, file=sys.stderr)
        if a.strict:
            rc = 1

    if a.emit_defaults:
        DEFAULTS_JS.write_text(defaults_js(e4))
        print(f"nexus-coverage: wrote {DEFAULTS_JS.relative_to(ROOT)} ({len(e4)} options)")
    if a.check_defaults:
        if not DEFAULTS_JS.exists() or DEFAULTS_JS.read_text() != defaults_js(e4):
            print(f"nexus-coverage: {DEFAULTS_JS.relative_to(ROOT)} is stale: run tools/nexus-coverage.py --emit-defaults")
            rc = 1
        else:
            print("nexus-coverage: E4Defaults.js is up to date")
    if a.check_mirrors:
        errors, n = check_mirrors(e4, registry_ids(), ignored())
        for e in errors:
            print("nexus-coverage: " + e)
        if errors:
            rc = 1
        else:
            print(f"nexus-coverage: the {n} settings kept in shell.json and config.json follow their Caelestia key")
    if (a.emit_defaults or a.check_defaults or a.check_mirrors) and not a.strict:
        return rc
    if a.list:
        for k, (t, v) in sorted(e4.items()):
            print(f"e4:{k}\t{t}\t{'<computed>' if v is Ellipsis else json.dumps(v, ensure_ascii=False)[:80]}")
        for k, (t, v) in sorted(c.items()):
            print(f"c:{k}\t{t}\t{v}")
        return rc

    all_ids = {"e4:" + k for k in e4} | {"c:" + k for k in c}
    reg = registry_ids()
    ign = ignored()
    covered = all_ids & reg
    ignored_ids = {i for i in all_ids - covered if any(fnmatch.fnmatchcase(i, p) for p in ign)}
    missing = sorted(all_ids - covered - ignored_ids)
    unknown = sorted(i for i in reg if i.split(":", 1)[0] in ("c", "e4") and i not in all_ids)

    for store, n in (("e4", len(e4)), ("c", len(c))):
        cov = sum(1 for i in covered if i.startswith(store + ":"))
        ig = sum(1 for i in ignored_ids if i.startswith(store + ":"))
        print(f"{store}: {n} options, {cov} in the registry, {ig} ignored, {n - cov - ig} missing")
    print(f"h: {sum(1 for i in reg if i.startswith('h:'))} in the registry, x: {sum(1 for i in reg if i.startswith('x:'))}")

    if unknown:
        print(f"\nRegistry ids that are not options ({len(unknown)}):")
        for i in unknown:
            print("  " + i)
    if missing:
        print(f"\nMissing ({len(missing)}):")
        groups = {}
        for i in missing:
            store, path = i.split(":", 1)
            groups.setdefault(f"{store}:{path.split('.')[0]}", []).append(i)
        for g, ids in sorted(groups.items()):
            print(f"  {g} ({len(ids)})")
            for i in ids:
                print("    " + i)
    if a.strict and (missing or unknown):
        rc = 1
    return rc


if __name__ == "__main__":
    sys.exit(main())
