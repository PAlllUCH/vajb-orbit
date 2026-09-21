#!/usr/bin/env python3
"""W5 independent (non-engine) uid cross-check.

For every ext_resource line in every .tscn/.tres under a project tree, compare the
declared uid against the authoritative declaration for that path:
  - an imported asset (.png/.ogg/...) -> uid="..." line in <path>.import
  - a GDScript                        -> the contents of <path>.uid
  - a scene/resource with a [gd_resource] header -> the uid in that header
Prints one line per ext_resource and a summary line.

Usage: python3 vajb-orbit/tools/w5_uidcheck.py [project_root] [only_suffix ...]
"""
import os
import re
import sys

RE_EXT_HEAD = re.compile(r'^\[ext_resource\b')
RE_ATTR = re.compile(r'(\w+)="([^"]*)"')
RE_IMPORT_UID = re.compile(r'^uid="(uid://[^"]+)"')
RE_RES_UID = re.compile(r'^\[gd_(?:resource|scene)[^]]*uid="(uid://[^"]+)"')


def parse_ext(line: str):
    """Return (type, uid_or_None, path) for an ext_resource line, uid may sit before or
    after path depending on which Godot writer last touched the file."""
    if not RE_EXT_HEAD.match(line.strip()):
        return None
    attrs = dict(RE_ATTR.findall(line))
    if "path" not in attrs:
        return None
    return (attrs.get("type", ""), attrs.get("uid"), attrs.get("path", ""))


def declared_uid(root: str, rel: str):
    full = os.path.join(root, rel)
    if not os.path.exists(full):
        return ("MISSING_PATH", None)
    sidecar_uid = full + ".uid"
    if os.path.exists(sidecar_uid):
        return ("gd.uid", open(sidecar_uid, encoding="utf-8").read().strip())
    import_file = full + ".import"
    if os.path.exists(import_file):
        for line in open(import_file, encoding="utf-8", errors="replace"):
            m = RE_IMPORT_UID.match(line.strip())
            if m:
                return (".import", m.group(1))
        return ("MISSING_IMPORT_UID", None)
    if rel.endswith((".tscn", ".tres", ".res")):
        with open(full, encoding="utf-8", errors="replace") as handle:
            for line in handle:
                m = RE_RES_UID.match(line.strip())
                if m:
                    return ("gd_resource", m.group(1))
        return ("NO_RES_UID", None)
    return ("NO_AUTHORITY", None)


def main() -> int:
    root = sys.argv[1] if len(sys.argv) > 1 else "vajb-orbit"
    only = sys.argv[2:] if len(sys.argv) > 2 else []
    checked = 0
    stale = 0
    missing = 0
    noauth = 0
    undeclared = 0
    for dirpath, dirnames, filenames in os.walk(root):
        if "addons" in dirpath.split(os.sep) or ".godot" in dirpath.split(os.sep):
            continue
        for name in sorted(filenames):
            if not name.endswith((".tscn", ".tres")):
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, root)
            if only and not any(rel.endswith(o) for o in only):
                continue
            with open(full, encoding="utf-8", errors="replace") as handle:
                for lineno, line in enumerate(handle, 1):
                    parsed = parse_ext(line)
                    if parsed is None:
                        continue
                    etype, want, epath = parsed
                    if not epath.startswith("res://"):
                        continue
                    kind, declared = declared_uid(root, epath[len("res://"):])
                    checked += 1
                    status = "OK"
                    if kind == "MISSING_PATH":
                        status = "MISSING_PATH"
                        missing += 1
                    elif declared is None:
                        status = "NO_AUTHORITY(%s)" % kind
                        noauth += 1
                    elif want is None:
                        status = "NO_UID_DECLARED(%s=%s)" % (kind, declared)
                        undeclared += 1
                    elif want != declared:
                        status = "STALE"
                        stale += 1
                    print("[UIDCHK] %s:%d %s type=%s src=%s declared=%s %s" % (
                        rel, lineno, epath, etype, kind, declared, status))
    print("[UIDCHK] SUMMARY scope=%s ext_resources=%d stale=%d no_uid_declared=%d missing_paths=%d no_authority=%d"
          % (only or "ALL", checked, stale, undeclared, missing, noauth))
    return 0


if __name__ == "__main__":
    sys.exit(main())
