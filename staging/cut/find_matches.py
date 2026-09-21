"""Find which already-named sprite each unnamed sprite actually duplicates, from the pixels.

The names in this library were assigned per generation run, and the same panel was rendered more
than once across phases, so several sheets hold the same artwork twice under different names. A
rename that ignores this puts a sanctioned name on a second copy of the art, or drops the only
copy. Both are worse than a placeholder.

This compares every sprite against every already-named sprite in its family using a normalised
32x32 grey signature, so a second render of the same subject scores high even when the lighting
or the crop differs. Results are evidence for a human decision, not an automatic rename: a high
score means "look at these two", not "these are the same file".

Usage:
    py -3.14 staging/cut/find_matches.py                  # table + asset-library/_matches.json
    py -3.14 staging/cut/find_matches.py --top 3
    py -3.14 staging/cut/find_matches.py --only placeholder
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
CUT = LIBRARY / "cut"
OUT = LIBRARY / "_matches.json"
SIDE = 32


def signature(path: Path) -> np.ndarray:
    """A 32x32 grey signature with the mean removed, so a dark and a light render still match."""
    with Image.open(path) as image:
        small = image.convert("L").resize((SIDE, SIDE), Image.BILINEAR)
    vector = np.asarray(small, dtype=np.float32).ravel()
    vector -= vector.mean()
    norm = float(np.linalg.norm(vector))
    return vector / norm if norm else vector


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--top", type=int, default=3)
    parser.add_argument("--only", default="", help="restrict to one name_issue class")
    parser.add_argument("--threshold", type=float, default=0.0,
                        help="minimum score to report")
    args = parser.parse_args()

    library = json.loads((LIBRARY / "_library.json").read_text(encoding="utf-8"))
    assets = library["assets"]
    issues = library["name_issues"]

    broken = {rel for key, rels in issues.items() for rel in rels}
    if args.only:
        broken = set(issues.get(args.only) or [])

    sprites = {rel: r for rel, r in assets.items()
               if rel.startswith("cut/") and r["role"] == "sprite"}
    named = {rel: r for rel, r in sprites.items() if not r["name_issue"]}

    print(f"signatures for {len(sprites)} sprites, {len(named)} of them already named")
    sigs = {rel: signature(LIBRARY / rel) for rel in sprites}
    named_by_family: dict[str, list[str]] = {}
    for rel, r in named.items():
        named_by_family.setdefault(r["family"], []).append(rel)

    matches: dict[str, list[dict]] = {}
    rows = []
    for rel in sorted(broken):
        if rel not in sigs:
            continue
        r = assets[rel]
        pool = named_by_family.get(r["family"], [])
        scored = []
        for other in pool:
            score = float(np.dot(sigs[rel], sigs[other]))
            scored.append((score, other))
        scored.sort(reverse=True)
        top = [{"sprite": o, "name": assets[o]["name"], "score": round(s, 4),
                "subject": assets[o]["subject"]} for s, o in scored[:args.top] if s >= args.threshold]
        matches[rel] = top
        if top:
            rows.append((r["name"], r["name_issue"], top[0]["name"], top[0]["score"],
                         top[0]["subject"] or ""))

    print(f"\n{'unnamed sprite':<46} {'issue':<17} {'closest named sprite':<34} score  its subject")
    for name, issue, other, score, subject in sorted(rows, key=lambda x: -x[3]):
        print(f"{name:<46} {issue or '-':<17} {other:<34} {score:>5.3f}  {subject[:44]}")

    strong = [r for r in rows if r[3] >= 0.85]
    print(f"\n{len(rows)} unnamed sprite(s) have a named neighbour; {len(strong)} score 0.85 or "
          "above, which is a duplicate render worth looking at before it is named")

    OUT.write_text(json.dumps({
        "note": ("Each unnamed sprite with its closest already-named sprites in the same family, "
                 "by a normalised 32x32 grey signature. Evidence for a decision, not a rename."),
        "threshold_strong": 0.85,
        "matches": matches,
    }, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {OUT.relative_to(WORKSPACE)}")


if __name__ == "__main__":
    main()
