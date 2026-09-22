#!/usr/bin/env python3
"""D2 asset_path_fallout: every res://assets literal must resolve to a file.

Recreated 2026-09-22 for D2 (the original's tool did not survive the purge; its
report shape is preserved per MASTER_REPORT: "N asset literals, 0 unresolvable").
Scans GDScript, scenes and resources under vajb-orbit/ (addons/ and .godot/
excluded) for res://assets/... literals and resolves each against the real tree:

- full literal with extension  -> file must exist
- template literal with %s     -> the glob it expands to must match >= 1 file
- directory literal (ends /)   -> directory must exist and be non-empty
- concatenation base (ends _ or / followed by no extension) -> >= 1 file must
  share the prefix

    python3 staging/d2/asset_path_fallout.py [--out slices/D2-icon-unification/asset_path_fallout.md]

Exit code 1 if anything is unresolvable.
"""

import os
import re
import sys
import datetime

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
PROJ = os.path.join(WORKSPACE, "vajb-orbit")
ASSETS = os.path.join(PROJ, "assets")

LITERAL_RE = re.compile(r"res://assets/[A-Za-z0-9_\-./@ %]+")
SCAN_EXT = {".gd", ".tscn", ".tres", ".godot", ".cfg"}
SKIP_DIRS = {"addons", ".godot", ".git", "node_modules"}


def iter_files():
    for dirpath, dirs, files in os.walk(PROJ):
        dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
        for f in files:
            if os.path.splitext(f)[1] in SCAN_EXT or f == "project.godot":
                yield os.path.join(dirpath, f)


def classify(raw):
    s = raw.rstrip("\"')")
    if "..." in s:
        return "prose", s
    if s.endswith("/"):
        return "dir", s
    if "%s" in s or "%d" in s:
        return "template", s
    if os.path.splitext(s)[1]:
        return "literal", s
    return "prefix", s


def _walk_files(rel_root):
    root = os.path.join(PROJ, rel_root)
    if not os.path.isdir(root):
        return
    for dirpath, dirs, files in os.walk(root):
        for f in files:
            yield os.path.relpath(os.path.join(dirpath, f), PROJ).replace(os.sep, "/")


def resolve(kind, s):
    rel = s[len("res://"):]
    if kind == "prose":
        return True
    if kind == "literal":
        return os.path.isfile(os.path.join(PROJ, rel))
    if kind == "dir":
        p = os.path.join(PROJ, rel)
        return os.path.isdir(p) and bool(os.listdir(p))
    if kind == "prefix":
        return any(f.startswith(rel) for f in _walk_files(os.path.dirname(rel)))
    tmpl = rel.replace("%s", "\0").replace("%d", "\0")
    pattern = re.escape(tmpl).replace("\0", "[^/]*")
    rx = re.compile("^" + pattern + "$")
    return any(rx.match(f) for f in _walk_files(os.path.dirname(rel)))


def main():
    out_path = None
    if "--out" in sys.argv:
        out_path = sys.argv[sys.argv.index("--out") + 1]
    rows = []
    seen = set()
    for path in iter_files():
        try:
            text = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for ln, line in enumerate(text.splitlines(), 1):
            for m in LITERAL_RE.finditer(line):
                raw = m.group(0)
                kind, s = classify(raw)
                key = (os.path.relpath(path, WORKSPACE), ln, s)
                if key in seen:
                    continue
                seen.add(key)
                ok = resolve(kind, s)
                rows.append((os.path.relpath(path, WORKSPACE).replace(os.sep, "/"),
                             ln, kind, s, ok))

    unres = [r for r in rows if not r[4]]
    counts = {}
    for r in rows:
        counts[r[2]] = counts.get(r[2], 0) + 1
    summary = (f"{len(rows)} asset references "
               f"({counts.get('literal', 0)} literals, {counts.get('template', 0)} templates, "
               f"{counts.get('dir', 0)} directories, {counts.get('prefix', 0)} concat bases), "
               f"{len(unres)} unresolvable")

    print(summary)
    for f, ln, kind, s, ok in unres:
        print(f"  UNRESOLVED {f}:{ln} [{kind}] {s}")
    print(f"asset_path_fallout: {summary}")

    if out_path:
        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, "w") as fh:
            fh.write("# asset_path_fallout\n\n")
            fh.write(f"Generated {datetime.date.today().isoformat()} by "
                     "`staging/d2/asset_path_fallout.py`. Regenerate, never hand-edit.\n\n")
            fh.write(f"**{summary}.**\n\n")
            if unres:
                fh.write("| File | Line | Kind | Reference |\n|---|---|---|---|\n")
                for f, ln, kind, s, ok in unres:
                    fh.write(f"| `{f}` | {ln} | {kind} | `{s}` |\n")
            else:
                fh.write("Every reference resolves.\n")
        print("wrote", out_path)
    sys.exit(1 if unres else 0)


if __name__ == "__main__":
    main()
