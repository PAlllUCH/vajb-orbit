#!/usr/bin/env python3
"""Generate docs/CODE_MAP.md + docs/CODE_MAP.json — what lies where in the code.

Why: coders asked "what do I wire into?" and had to grep 700 scripts and 100
scenes to answer it. This map is the code-side twin of asset-library/_library.json:
one entry per scene (root type, script, instanced sub-scenes, groups, signal
wiring) and per script (extends, signals, res:// refs, where it is attached or
preloaded), plus the orphan scripts nothing references.

Usage (run after any scene or script change):

    python3 staging/build_code_map.py            # Linux
    py -3.14 staging/build_code_map.py           # Windows

Output is deterministic (sorted, no timestamps) so a re-run with no source
change produces no diff. addons/ is vendored and excluded everywhere;
tests/ is mapped but never listed as orphan (the runner discovers it).
"""

from __future__ import annotations

import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJ = ROOT / "vajb-orbit"
OUT_MD = ROOT / "docs" / "CODE_MAP.md"
OUT_JSON = ROOT / "docs" / "CODE_MAP.json"

SKIP_DIRS = {"addons", ".godot"}
ORPHAN_EXEMPT_PREFIX = ("tests/",)

EXT_RESOURCE = re.compile(r'^\[ext_resource[^\]]*type="([^"]+)"[^\]]*path="([^"]+)"', re.M)
NODE_HEADER = re.compile(r'^\[node name="([^"]+)"(?: type="([^"]+)")?([^\]]*)\]', re.M)
CONNECTION = re.compile(
    r'^\[connection signal="([^"]+)" from="([^"]+)" to="([^"]+)" method="([^"]+)"\]', re.M)
GROUPS = re.compile(r'groups=\[([^\]]*)\]')
EXTENDS = re.compile(r"^extends\s+([A-Za-z0-9_\"/.:]+)", re.M)
CLASS_NAME = re.compile(r"^class_name\s+([A-Za-z0-9_]+)", re.M)
SIGNAL_DEF = re.compile(r"^signal\s+([A-Za-z0-9_]+)", re.M)
RES_REF = re.compile(r'res://[A-Za-z0-9_\-./ %]+')
AUTOLOAD_LINE = re.compile(r"^([A-Za-z0-9_]+)=[\"']?\*?[\"']?(res://[^\"'\s]+)", re.M)
CONNECT_CALL = re.compile(r"([\w.$\[\]]+)\.connect\(\s*([\w.:()\"$ ]+?)[,)]")


def walk(suffix: str) -> list[pathlib.Path]:
    out = []
    for p in sorted(PROJ.rglob(f"*{suffix}")):
        rel = p.relative_to(PROJ).as_posix()
        if rel.split("/")[0] in SKIP_DIRS:
            continue
        out.append(p)
    return out


def autoloads() -> dict[str, str]:
    text = (PROJ / "project.godot").read_text(encoding="utf-8")
    at = text.find("[autoload]")
    if at < 0:
        return {}
    chunk = text[at:].split("\n[", 1)[0]
    return {m.group(1): m.group(2) for m in AUTOLOAD_LINE.finditer(chunk)}


def parse_scene(path: pathlib.Path) -> dict:
    text = path.read_text(encoding="utf-8")
    resources = [{"type": t, "path": p} for t, p in EXT_RESOURCE.findall(text)]
    root_type = ""
    for name, ntype, rest in NODE_HEADER.findall(text):
        if "parent=" not in rest:
            root_type = ntype or "(inherited)"
            break
    groups = []
    for g in GROUPS.findall(text):
        groups.extend(x.strip().strip('"') for x in g.split(",") if x.strip())
    connections = [
        {"signal": s, "from": f, "to": t, "method": m}
        for s, f, t, m in CONNECTION.findall(text)
    ]
    scripts = [r["path"] for r in resources if r["type"] == "Script"]
    scenes = [r["path"] for r in resources if r["type"] == "PackedScene"]
    assets = [r["path"] for r in resources
              if r["type"] not in ("Script", "PackedScene")]
    return {
        "root_type": root_type,
        "scripts": sorted(set(scripts)),
        "instanced": sorted(set(scenes)),
        "assets": sorted(set(assets)),
        "groups": sorted(set(groups)),
        "connections": connections,
    }


def parse_script(path: pathlib.Path, autoload_names: dict[str, str]) -> dict:
    text = path.read_text(encoding="utf-8")
    res = path.relative_to(PROJ).as_posix()
    res_uri = "res://" + res
    extends = (EXTENDS.search(text).group(1) if EXTENDS.search(text) else "?")
    cls = (CLASS_NAME.search(text).group(1) if CLASS_NAME.search(text) else "")
    refs = sorted({r.rstrip(".,);") for r in RES_REF.findall(text)
                   if r.rstrip(".,);") != res_uri})
    connects = sorted({f"{m.group(1)} → {m.group(2).strip()}"
                       for m in CONNECT_CALL.finditer(text)})
    return {
        "extends": extends,
        "class_name": cls,
        "signals": sorted(set(SIGNAL_DEF.findall(text))),
        "refs": refs,
        "connects": connects,
        "autoload": next((n for n, p in autoload_names.items() if p == res_uri), ""),
    }


def esc(s: str) -> str:
    return s.replace("|", "/")


def cell(items: list[str], cap: int = 110) -> str:
    out = ""
    for i, item in enumerate(items):
        cand = item if not out else out + ", " + item
        if len(cand) > cap:
            return out + f" …(+{len(items) - i})"
        out = cand
    return out or "—"


def build() -> tuple[str, dict]:
    autos = autoloads()
    scenes = {("res://" + p.relative_to(PROJ).as_posix()): parse_scene(p)
              for p in walk(".tscn")}
    scripts = {("res://" + p.relative_to(PROJ).as_posix()): parse_script(p, autos)
               for p in walk(".gd")}

    attached: dict[str, list[str]] = {}
    preloaded: dict[str, list[str]] = {}
    for scene_uri, s in scenes.items():
        for ref in s["scripts"] + s["instanced"] + s["assets"]:
            preloaded.setdefault(ref, []).append(scene_uri + " (ext_resource)")
    for script_uri, s in scripts.items():
        for ref in s["refs"]:
            preloaded.setdefault(ref, []).append(script_uri)
    for scene_uri, s in scenes.items():
        for ref in s["scripts"]:
            attached.setdefault(ref, []).append(scene_uri)

    orphans = sorted(u for u, s in scripts.items()
                     if not s["autoload"]
                     and u not in attached
                     and u not in preloaded
                     and not u[len("res://"):].startswith(ORPHAN_EXEMPT_PREFIX))

    body: list[str] = []

    def emit(line: str = "") -> None:
        body.append(line)

    emit("## 1. Autoloads (project.godot)")
    emit("| Name | Path |")
    emit("|---|---|")
    for name in sorted(autos):
        emit(f"| {esc(name)} | {esc(autos[name])} |")
    emit()
    emit("## 2. Scenes")
    emit("| Scene | Root | Scripts | Instanced | Groups |")
    emit("|---|---|---|---|---|")
    for uri in sorted(scenes):
        s = scenes[uri]
        emit(f"| {esc(uri)} | {esc(s['root_type'])} | {cell(s['scripts'])} | "
             f"{cell(s['instanced'])} | {cell(s['groups'])} |")
    emit()
    emit("## 3. Signal wiring")
    emit("Scenes carry no `[connection]` entries: every signal is wired in code.")
    emit("Rows are `.connect()` calls, scene `[connection]` rows if any ever appear.")
    emit("| Where | From → callable |")
    emit("|---|---|")
    rows = [(uri, c) for uri, s in scenes.items() for c in s["connections"]]
    call_rows = [(uri, call) for uri, s in sorted(scripts.items())
                 for call in s["connects"]]
    for uri, c in sorted(rows, key=lambda r: (r[0], r[1]["signal"], r[1]["from"])):
        emit(f"| {esc(uri)} | {esc(c['signal'])}: "
             f"{esc(c['from'])} → {esc(c['to'])}.{esc(c['method'])} |")
    for uri, call in call_rows:
        emit(f"| {esc(uri)} | {esc(call)} |")
    emit()
    emit("## 4. Scripts")
    emit("| Script | Extends | Signals | res:// refs | Attached in / preloaded by |")
    emit("|---|---|---|---|---|")
    for uri in sorted(scripts):
        s = scripts[uri]
        users = sorted(set(attached.get(uri, []) + preloaded.get(uri, [])))
        mark = f" **[{s['autoload']}]**" if s["autoload"] else ""
        emit(f"| {esc(uri)}{mark} | {esc(s['extends'])} | {cell(s['signals'])} | "
             f"{cell(s['refs'])} | {cell(users)} |")
    emit()
    emit("## 5. Orphan scripts (attached nowhere, referenced by nothing)")
    emit("Deletion or archival candidates; tests/ is exempt (the runner discovers it).")
    emit()
    if orphans:
        for uri in orphans:
            emit(f"- {esc(uri)}")
    else:
        emit("(none)")
    emit()

    n_conn = sum(len(s["connections"]) for s in scenes.values()) + \
        sum(len(s["connects"]) for s in scripts.values())
    index_rows = [
        ("1. Autoloads", 3 + len(autos)),
        ("2. Scenes", 3 + len(scenes)),
        ("3. Signal wiring", 5 + n_conn),
        ("4. Scripts", 3 + len(scripts)),
        ("5. Orphan scripts", 4 + max(len(orphans), 1)),
    ]
    header = [
        "# CODE_MAP — what lies where (generated)",
        "",
        "Generated by `staging/build_code_map.py`; do not hand-edit. Re-run after",
        "any scene or script change. Read by range, or `rg -n 'res://…'` for one",
        "entry. addons/ is vendored and excluded. The JSON twin",
        "(`docs/CODE_MAP.json`) carries the full ref lists this table truncates.",
        "",
        "| Section | Lines |",
        "|---|---|",
    ]
    at = len(header) + len(index_rows) + 3  # rows + blank + first '## ' offset
    for label, span in index_rows:
        header.append(f"| {label} | L{at + 1}–L{at + span} |")
        at += span
    header += ["", ""]

    md = "\n".join(header + body)
    data = {
        "autoloads": autos,
        "scenes": dict(sorted(scenes.items())),
        "scripts": dict(sorted(scripts.items())),
        "orphans": orphans,
    }
    return md, data


def main() -> int:
    md, data = build()
    OUT_JSON.write_text(json.dumps(data, indent=1, sort_keys=True) + "\n",
                        encoding="utf-8")
    changed = not OUT_MD.exists() or OUT_MD.read_text(encoding="utf-8") != md
    OUT_MD.write_text(md, encoding="utf-8")
    print(f"CODE_MAP: {len(data['scenes'])} scenes, {len(data['scripts'])} scripts, "
          f"{len(data['autoloads'])} autoloads, {len(data['orphans'])} orphans"
          + ("" if changed else " (no change)"))
    return 0


if __name__ == "__main__":
    sys.exit(main())
