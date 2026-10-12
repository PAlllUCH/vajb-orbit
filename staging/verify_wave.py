#!/usr/bin/env python3
"""Wave-state snapshot/verify for agent worker waves.

Mechanical gates for review workers, so reviews spend their tokens on judgment
(gameplay, spec conformance) instead of bookkeeping. Stdlib only; run with
`python3` (Linux) or `py -3.14` (Windows) from anywhere.

Modes:
  snapshot --name <tag>            hash the current text state -> .agents/gen/_state/_wave_state/<tag>.json
  verify   --baseline <tag>        diff current state against <tag>.json:
                                     - modified / added / deleted files
                                     - fails (exit 1) if any modified file is in --forbidden
                                     - fails if any --expect-reports file is missing/empty
                                     - optionally runs the headless test gate (--tests) through
                                       staging/gate.py (SCRIPT ERROR guard included, T-183)

Examples:
  py -3.14 staging/verify_wave.py snapshot --name wave2_start
  py -3.14 staging/verify_wave.py verify --baseline wave2_start --forbidden project.godot --expect-reports .agents/gen/slice2_w9_report.md --tests
"""

import argparse
import hashlib
import json
import os
import sys

WORKSPACE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE_DIR = os.path.join(WORKSPACE, ".agents", "gen", "_state", "_wave_state")

SKIP_DIRS = {
    ".git", ".godot", "assets", "asset-library", "node_modules", "__pycache__",
    "skills", "_fringe_backup", "_preview", "previews", "_wave_state",
}
MAX_FILE_BYTES = 10 * 1024 * 1024

def _gate():
    """The shared gate wrapper (staging/gate.py) - the single owner of the
    pinned CONTRACTS section 9 command, the SCRIPT ERROR guard (T-183) and
    the scratch-store hermeticity.
    """
    here = os.path.dirname(os.path.abspath(__file__))
    sys.path.insert(0, here)
    import gate
    return gate


SKIP_FILES = {"crush.log"}


def is_text(path):
    try:
        with open(path, "rb") as f:
            head = f.read(4096)
    except OSError:
        return False
    if b"\x00" in head:
        return False
    return True


def walk_state():
    state = {}
    for dirpath, dirnames, filenames in os.walk(WORKSPACE):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS and not d.startswith(".git")]
        for name in filenames:
            if name in SKIP_FILES:
                continue
            full = os.path.join(dirpath, name)
            rel = os.path.relpath(full, WORKSPACE).replace(os.sep, "/")
            try:
                size = os.path.getsize(full)
            except OSError:
                continue
            if size == 0:
                state[rel] = {"size": 0, "sha256": ""}
                continue
            if not is_text(full) or size > MAX_FILE_BYTES:
                state[rel] = {"size": size, "sha256": "BINARY"}
                continue
            h = hashlib.sha256()
            with open(full, "rb") as f:
                for chunk in iter(lambda: f.read(65536), b""):
                    h.update(chunk)
            state[rel] = {"size": size, "sha256": h.hexdigest()}
    return state


def cmd_snapshot(args):
    os.makedirs(STATE_DIR, exist_ok=True)
    out = os.path.join(STATE_DIR, args.name + ".json")
    state = walk_state()
    with open(out, "w", encoding="utf-8", newline="\n") as f:
        json.dump({"name": args.name, "files": state}, f, indent=1)
    print(f"snapshot '{args.name}': {len(state)} files -> {os.path.relpath(out, WORKSPACE)}")
    return 0


def cmd_verify(args):
    baseline_path = os.path.join(STATE_DIR, args.baseline + ".json")
    if not os.path.isfile(baseline_path):
        print(f"FAIL: baseline '{args.baseline}' not found in {STATE_DIR}")
        return 2
    with open(baseline_path, encoding="utf-8") as f:
        base = json.load(f)["files"]
    now = walk_state()

    modified, added, deleted = [], [], []
    for rel, info in now.items():
        if rel not in base:
            added.append(rel)
        elif base[rel]["sha256"] != info["sha256"]:
            modified.append(rel)
    for rel in base:
        if rel not in now:
            deleted.append(rel)

    forbidden = {x.replace("\\", "/") for x in (args.forbidden or [])}
    reports = [x.replace("\\", "/") for x in (args.expect_reports or [])]
    problems = []

    hits = sorted(modified)
    violations = [rel for rel in hits + added if rel in forbidden]
    if violations:
        problems.append(f"forbidden files touched: {', '.join(violations)}")

    for rel in reports:
        full = os.path.join(WORKSPACE, rel)
        if not os.path.isfile(full) or os.path.getsize(full) == 0:
            problems.append(f"expected report missing/empty: {rel}")

    summary = {
        "baseline": args.baseline,
        "modified": sorted(modified),
        "added": sorted(added),
        "deleted": sorted(deleted),
        "problems": problems,
    }
    print(json.dumps(summary, indent=1))

    if args.tests:
        print("--- running headless test gate ---")
        ok, _ = _gate().run_once("verify")
        print("--- gate %s ---" % ("ok" if ok else "FAIL"))
        if not ok:
            problems.append("headless test gate failed")
            summary["problems"] = problems
            print(json.dumps({"problems": problems}, indent=1))

    return 1 if problems else 0


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="mode", required=True)

    s = sub.add_parser("snapshot")
    s.add_argument("--name", required=True)

    v = sub.add_parser("verify")
    v.add_argument("--baseline", required=True)
    v.add_argument("--forbidden", nargs="*")
    v.add_argument("--expect-reports", nargs="*")
    v.add_argument("--tests", action="store_true")

    args = p.parse_args()
    if args.mode == "snapshot":
        sys.exit(cmd_snapshot(args))
    sys.exit(cmd_verify(args))


if __name__ == "__main__":
    main()
