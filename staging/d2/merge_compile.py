#!/usr/bin/env python3
"""Merge the owner's compile picks into the project icon set.

Reads staging/d2/svg_compile.csv (id, name, keep with B1/B2/B3/none) and copies
the chosen batch file into vajb-orbit/assets/icons/<fam>/<name>.svg. The three
batch folders stay untouched as evidence; keep=none (or blank) leaves the
current project file (B1) in place and reports the row as pending.

    python3 staging/d2/merge_compile.py [--apply]
"""

import csv
import os
import shutil
import sys

WORKSPACE = os.environ.get("VAJB_WORKSPACE", "/home/kamil-paluszkiewicz/VajbOrbit")
CSV = os.path.join(WORKSPACE, "staging/d2/svg_compile.csv")
RESULT = os.path.join(WORKSPACE, "staging/d2/svg_compile_result.csv")
PICKED = {p["id"]: p for p in csv.DictReader(
    open(os.path.join(WORKSPACE, "staging/d2/svg_picked.tsv")), delimiter="\t")}
BATCH_DIR = {
    "B1": "staging/d2/svg",
    "B2": "staging/d2/svg_v2",
    "B3": "staging/d2/svg_v3",
}
VALID = {"B1", "B2", "B3", "none", ""}


def main():
    apply = "--apply" in sys.argv
    rows = list(csv.DictReader(open(CSV)))
    counts, pending, errors, plan = {}, [], [], []

    for r in rows:
        raw = (r.get("keep") or "").strip().upper()
        keep = {"1": "B1", "2": "B2", "3": "B3"}.get(raw, raw)
        if keep not in VALID:
            errors.append((r["id"], r["name"], r["keep"]))
            continue
        name = r["name"]
        p = PICKED.get(r["id"])
        if p is None:
            errors.append((r["id"], name, "id not in picked set"))
            continue
        target = os.path.join(WORKSPACE, "vajb-orbit/assets/icons", p["family"],
                              name + ".svg")
        if keep in ("B1", "B2", "B3"):
            src = os.path.join(WORKSPACE, BATCH_DIR[keep], name + ".svg")
            if not os.path.isfile(src):
                errors.append((r["id"], name, f"{keep} file missing"))
                continue
            counts[keep] = counts.get(keep, 0) + 1
            plan.append((r["id"], name, keep, os.path.relpath(src, WORKSPACE),
                         os.path.relpath(target, WORKSPACE), "merged"))
            if apply:
                shutil.copy2(src, target)
        else:
            pending.append((r["id"], name))
            plan.append((r["id"], name, keep or "blank",
                         "", os.path.relpath(target, WORKSPACE),
                         "pending - current project file kept"))

    print(f"rows: {len(rows)}  picks: {counts}  pending: {len(pending)}  errors: {len(errors)}")
    for e in errors:
        print("  ERROR", e)
    for pid, name in pending:
        print(f"  PENDING #{pid} {name}")
    if apply:
        with open(RESULT, "w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["id", "name", "keep", "source", "target", "status"])
            w.writerows(plan)
        print("wrote", RESULT)
    else:
        print("(check mode - rerun with --apply)")


if __name__ == "__main__":
    main()
