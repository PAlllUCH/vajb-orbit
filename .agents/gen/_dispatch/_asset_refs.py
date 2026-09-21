"""Measure every res://assets/... reference in code/scene files that no longer resolves.

Read-only recon for the slice-0 orchestrator: the graphics lane re-laid the
asset tree, so this counts the code-side fallout the wave has to work around.
"""
import io
import os
import re

ROOT = "vajb-orbit"
SKIP = (".godot", "addons", ".import")
PAT = re.compile(r"res://assets/[A-Za-z0-9_./@-]+")

hits = {}
missing = {}
for base, dirs, files in os.walk(ROOT):
    dirs[:] = [d for d in dirs if d not in SKIP]
    for name in files:
        if not name.endswith((".gd", ".tscn", ".tres")):
            continue
        path = os.path.join(base, name)
        try:
            text = io.open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        for ref in set(PAT.findall(text)):
            rel = ref[len("res://"):]
            hits[path] = hits.get(path, 0) + 1
            if not os.path.exists(os.path.join(ROOT, rel)):
                missing.setdefault(path.replace("\\", "/"), []).append(ref)

print("files referencing res://assets :", len(hits))
print("files with dangling references :", len(missing))
print("dangling reference count       :", sum(len(v) for v in missing.values()))
print()
for path in sorted(missing, key=lambda p: -len(missing[p])):
    print("%3d  %s" % (len(missing[path]), path))
    for ref in sorted(missing[path])[:4]:
        print("       %s" % ref)
