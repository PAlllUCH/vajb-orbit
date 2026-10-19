#!/usr/bin/env python3
"""Measure the codebase: inventory, duplicate code, class usage.

Why: the tree crosses 175k GDScript lines and several UI panels carry their own
copy of the same helper suite. This script is the repeatable half of
`docs/CODE_AUDIT.md`: it prints the inventory and the exact-duplicate numbers
the doc cites, so a later pass can compare instead of re-deriving them by hand.

Usage:

    python3 staging/code_audit.py            # Markdown-style report
    python3 staging/code_audit.py --json     # machine-readable report
    python3 staging/code_audit.py --min-lines 40   # function-body threshold

Scope: `vajb-orbit/{autoload,game,ui,tools,tests}`; `addons/`, `.godot/` and
`assets/` are excluded. Deterministic output: paths sorted, no timestamps.
Stdlib only; `python3` on Linux, `py -3.14` on Windows.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parent.parent
PROJ = ROOT / "vajb-orbit"
SKIP = {"addons", ".godot", "assets"}
LAYERS = ("autoload", "game", "ui", "tools", "tests")

FUNC = re.compile(r"^(\t*)func\s+([A-Za-z_]\w*)\s*\(")
CLASS = re.compile(r"^class_name\s+([A-Za-z0-9_]+)", re.M)
AUTOLOAD = re.compile(r"^([A-Za-z0-9_]+)=[\"']?\*?[\"']?(res://[^\"'\s]+)", re.M)


def scripts() -> dict[str, list[pathlib.Path]]:
    out: dict[str, list[pathlib.Path]] = {}
    for layer in LAYERS:
        base = PROJ / layer
        if not base.is_dir():
            continue
        found = []
        for path in sorted(base.rglob("*.gd")):
            rel = path.relative_to(PROJ)
            if rel.parts[0] in SKIP:
                continue
            found.append(path)
        out[layer] = found
    return out


def rel(path: pathlib.Path) -> str:
    return path.relative_to(PROJ).as_posix()


def read(path: pathlib.Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def functions(path: pathlib.Path) -> list[tuple[str, str, int, str, int, int]]:
    """(hash, file, line, name, body-lines, body-chars) for each function."""
    rows = []
    lines = read(path).splitlines()
    for index, line in enumerate(lines):
        match = FUNC.match(line)
        if not match:
            continue
        indent = len(match.group(1))
        body: list[str] = []
        cursor = index + 1
        while cursor < len(lines):
            candidate = lines[cursor]
            if not candidate.strip():
                body.append("")
                cursor += 1
                continue
            depth = len(candidate) - len(candidate.lstrip("\t"))
            if depth <= indent and not candidate.lstrip().startswith("#"):
                break
            body.append(candidate.strip())
            cursor += 1
        normalized = "\n".join(x for x in body if x and not x.startswith("#"))
        rows.append((
            hashlib.md5(normalized.encode()).hexdigest(),
            rel(path),
            index + 1,
            match.group(2),
            len(body),
            len(normalized),
        ))
    return rows


def duplicate_functions(paths: list[pathlib.Path], min_chars: int) -> dict:
    groups: dict[str, list[tuple]] = defaultdict(list)
    for path in paths:
        for row in functions(path):
            if row[5] > min_chars:
                groups[row[0]].append(row)
    clusters = []
    redundant_lines = 0
    names: Counter[str] = Counter()
    per_file: Counter[str] = Counter()
    for group in groups.values():
        if len(group) < 2:
            continue
        group.sort(key=lambda r: r[1])
        waste = (len(group) - 1) * group[0][4]
        redundant_lines += waste
        names[group[0][3]] += len(group) - 1
        for row in group[1:]:
            per_file[row[1]] += row[4]
        clusters.append({
            "copies": len(group),
            "name": group[0][3],
            "body_lines": group[0][4],
            "redundant_lines": waste,
            "where": [f"{r[1]}:{r[2]}" for r in group],
        })
    clusters.sort(key=lambda c: (-c["redundant_lines"], c["name"]))
    return {
        "clusters": len(clusters),
        "redundant_lines": redundant_lines,
        "names": names.most_common(20),
        "top_files": per_file.most_common(15),
        "top_clusters": clusters[:20],
    }


def duplicate_blocks(paths: list[pathlib.Path], window: int = 8) -> dict:
    occurrences: dict[str, list[tuple[str, int, str]]] = defaultdict(list)
    for path in paths:
        lines = [l.strip() for l in read(path).splitlines()]
        lines = [l for l in lines if l and not l.startswith("#")]
        for index in range(len(lines) - window + 1):
            chunk = tuple(lines[index:index + window])
            if sum(len(x) for x in chunk) < 160:
                continue
            digest = hashlib.md5("\n".join(chunk).encode()).hexdigest()
            occurrences[digest].append((rel(path), index, chunk[0]))
    clusters = [v for v in occurrences.values() if len(v) > 1]
    clusters.sort(key=lambda c: -len(c))
    return {
        "clusters": len(clusters),
        "top": [
            {
                "copies": len(group),
                "files": len(set(r[0] for r in group)),
                "first_line": group[0][2],
                "where": sorted(set(r[0] for r in group))[:12],
            }
            for group in clusters[:20]
        ],
    }


def class_usage(paths: list[pathlib.Path]) -> dict:
    texts = {rel(path): read(path) for path in paths}
    declared = {}
    for name, text in texts.items():
        match = CLASS.search(text)
        if match:
            declared[match.group(1)] = name
    usage: Counter[str] = Counter()
    files: dict[str, set[str]] = defaultdict(set)
    for name, text in texts.items():
        for cls in declared:
            count = len(re.findall(r"\b" + re.escape(cls) + r"\b", text))
            if count:
                usage[cls] += count
                files[cls].add(name)
    rows = [
        {"class": cls, "file": declared[cls], "refs": usage[cls],
         "files": len(files[cls])}
        for cls in declared
    ]
    rows.sort(key=lambda r: r["refs"])
    autoloads = []
    project = (PROJ / "project.godot").read_text(encoding="utf-8")
    at = project.find("[autoload]")
    if at >= 0:
        chunk = project[at:].split("\n[", 1)[0]
        autoloads = [m.group(1) for m in AUTOLOAD.finditer(chunk)]
    return {
        "classes": rows,
        "declared": len(declared),
        "autoloads": autoloads,
        "class_name_only": [r for r in rows
                            if r["files"] == 1 and r["refs"] == 1],
    }


def inventory(groups: dict[str, list[pathlib.Path]]) -> dict:
    out = {}
    for layer, paths in groups.items():
        out[layer] = {
            "files": len(paths),
            "lines": sum(len(read(p).splitlines()) for p in paths),
        }
    scenes = [p for p in sorted(PROJ.rglob("*.tscn"))
              if p.relative_to(PROJ).parts[0] not in SKIP]
    production_scenes = [p for p in scenes
                         if p.relative_to(PROJ).parts[0] != "tests"]
    tests = groups.get("tests", [])
    out["scenes"] = {
        "total": len(scenes),
        "production": len(production_scenes),
        "test": len(scenes) - len(production_scenes),
    }
    out["suite_mix"] = {
        "suites": sum(1 for p in tests if p.name.startswith("test_")),
        "probes": sum(1 for p in tests if p.name.startswith("probe_")),
        "other": sum(1 for p in tests
                     if not p.name.startswith(("test_", "probe_"))),
    }
    return out


def build(min_chars: int) -> dict:
    groups = scripts()
    production = [p for layer in ("autoload", "game", "ui", "tools")
                  for p in groups.get(layer, [])]
    return {
        "inventory": inventory(groups),
        "duplicates_production": duplicate_functions(production, min_chars),
        "duplicates_tests": duplicate_functions(groups.get("tests", []), min_chars),
        "blocks_production": duplicate_blocks(production),
        "class_usage": class_usage(production),
    }


def report(data: dict) -> str:
    lines = ["# Code audit (measured)", ""]
    inv = data["inventory"]
    lines.append("## Inventory")
    for layer in ("autoload", "game", "ui", "tools", "tests"):
        row = inv[layer]
        lines.append(f"- {layer}: {row['files']} files, {row['lines']} lines")
    lines.append(f"- scenes: {inv['scenes']['production']} production, "
                 f"{inv['scenes']['test']} test")
    lines.append(f"- tests: {inv['suite_mix']['suites']} suites, "
                 f"{inv['suite_mix']['probes']} probes, {inv['suite_mix']['other']} other")
    lines.append("")
    for label, key in (("Production", "duplicates_production"),
                       ("Tests", "duplicates_tests")):
        dup = data[key]
        lines.append(f"## Duplicate functions ({label})")
        lines.append(f"- {dup['clusters']} clusters, "
                     f"{dup['redundant_lines']} redundant lines")
        lines.append("- most copied helpers: " + ", ".join(
            f"{name} x{count}" for name, count in dup["names"][:12]))
        lines.append("")
    blocks = data["blocks_production"]
    lines.append("## Duplicate 8-line blocks (production)")
    lines.append(f"- {blocks['clusters']} clusters")
    for entry in blocks["top"][:10]:
        lines.append(f"- x{entry['copies']} across {entry['files']} files: "
                     f"{entry['first_line'][:80]}")
    lines.append("")
    usage = data["class_usage"]
    lines.append("## Class usage (production, least referenced first)")
    lines.append(f"- {usage['declared']} classes; autoloads: "
                 + ", ".join(usage["autoloads"]))
    for row in usage["classes"][:20]:
        lines.append(f"- {row['class']} ({row['file']}): "
                     f"{row['refs']} refs in {row['files']} files")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--json", action="store_true", help="machine-readable output")
    parser.add_argument("--min-lines", type=int, default=40,
                        help="minimum normalized function-body characters")
    args = parser.parse_args()
    data = build(args.min_lines)
    if args.json:
        print(json.dumps(data, indent=1, sort_keys=True))
    else:
        print(report(data))
    return 0


if __name__ == "__main__":
    sys.exit(main())
