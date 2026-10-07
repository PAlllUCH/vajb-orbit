#!/usr/bin/env python3
"""Verify the chrome family's fit: every wired surface's sprite against its own content.

Why: the S37-R1 probe (`vajb-orbit/tests/probe_s37_r1_scene.gd`) walks the live station
and prints one `[r37] SURF key=value ...` line per chrome-bearing surface. That probe is
the measurement; this is the GATE that reads it, so a future wave cannot quietly re-land a
sprite that is smaller than the text and graphics it carries. The rules are UI_SPEC §15.1
(the surface -> class census) and §15.3 (the margins law), measured as the probe reports:

  TOO SMALL  the drawn chrome (a canvas class letterboxed at its cut's aspect, or a
             nine-slice's flat band) is smaller than the content box = icon + font-measured
             text + 10 % padding (`PAD` in the probe). The owner's "text goes over them".
  STRETCH    the drawn rect's aspect differs from the cut's by more than `--stretch`
             (default 1.20x). A canvas class never stretches; a nine-slice stretches its
             middle between fixed caps. The owner's "slots are stretched".
  BAND       a nine-slice slot outside its class's legal band (`ChromeFamily.BANDS`).

Usage:
  python3 staging/verify_chrome_fit.py                    # run the probe, then report
  python3 staging/verify_chrome_fit.py --log /tmp/p.log   # parse an existing probe log
  python3 staging/verify_chrome_fit.py --only AUCTION --strict
  python3 staging/verify_chrome_fit.py --json > fit.json

Exit 0 when nothing fails (or every failure is waived), 1 otherwise (`--warn-only` always
exits 0). Waivers live in `staging/chrome_fit_waivers.txt`, one `<node-substring>=<reason>`
per line, `#` starts a comment.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJ = ROOT / "vajb-orbit"
PROBE_SCENE = "res://tests/probe_s37_r1_scene.tscn"
WAIVERS = ROOT / "staging" / "chrome_fit_waivers.txt"
GODOT_ENV = "GODOT_CONSOLE"

KEYS = [
    "deck", "kind", "cls", "flags", "slot", "drawn", "band", "need", "content",
    "def_drawn", "def_band", "stretch", "marg", "cm", "tex", "band_ok", "node",
]
KEY_RE = re.compile(r"\b(" + "|".join(KEYS) + r")=")
SURF_MARK = "[r37] SURF"


def godot_binary() -> str:
    for cand in (os.environ.get(GODOT_ENV), shutil.which("godot"), "~/.local/bin/godot"):
        if cand:
            path = Path(cand).expanduser()
            if path.exists():
                return str(path)
    return "godot"


def run_probe(timeout: int) -> str:
    scratch = tempfile.mkdtemp(prefix="chrome_fit_")
    env = dict(os.environ, XDG_DATA_HOME=scratch)
    cmd = [
        godot_binary(), "--headless", "--path", str(PROJ),
        PROBE_SCENE, "--quit-after", "3600",
    ]
    print(f"[verify_chrome_fit] running: {' '.join(cmd)}", file=sys.stderr)
    proc = subprocess.run(cmd, env=env, capture_output=True, text=True, timeout=timeout)
    if proc.returncode != 0:
        print(f"[verify_chrome_fit] probe exit={proc.returncode}", file=sys.stderr)
        sys.stderr.write(proc.stderr[-2000:])
    return proc.stdout + "\n" + proc.stderr


def parse_surfs(text: str) -> list[dict]:
    rows: list[dict] = []
    for line in text.splitlines():
        if SURF_MARK not in line:
            continue
        parts = KEY_RE.split(line.split(SURF_MARK, 1)[1])
        surf = {parts[i]: parts[i + 1].strip() for i in range(1, len(parts) - 1, 2)}
        if surf:
            rows.append(surf)
    return rows


def dim(pair: str, sep: str = "x") -> tuple[float, float]:
    try:
        a, b = pair.split(sep)
        return float(a), float(b)
    except (ValueError, AttributeError):
        return 0.0, 0.0


def nums(text: str, sep: str = "/") -> list[float]:
    try:
        return [float(x) for x in text.split(sep)]
    except ValueError:
        return []


def load_waivers() -> list[tuple[str, str]]:
    if not WAIVERS.exists():
        return []
    out: list[tuple[str, str]] = []
    for raw in WAIVERS.read_text().splitlines():
        line = raw.split("#", 1)[0].strip()
        if "=" in line:
            key, reason = line.split("=", 1)
            out.append((key.strip(), reason.strip()))
    return out


def waiver_for(node: str, waivers: list[tuple[str, str]]) -> str | None:
    for key, reason in waivers:
        if key and key in node:
            return reason
    return None


def judge(surf: dict, stretch_max: float) -> dict:
    dd = dim(surf.get("def_drawn", "0x0"), "/")
    db = dim(surf.get("def_band", "0x0"), "/")
    drawn = dim(surf.get("drawn", "0x0"))
    marg = nums(surf.get("marg", ""), "/")
    kind = surf.get("kind", "?")
    stretch = float(surf.get("stretch", "1") or 1)
    tol = stretch_max - 1.0
    ## A canvas class is drawn KEEP_ASPECT_CENTERED - its art always keeps its own aspect
    ## (letterboxed), so it can never be distorted. A nine-slice with real texture margins
    ## keeps its caps/edges and stretches only its middle band (the class's whole purpose).
    ## A nine-slice with ZERO margins scales the whole texture to the rect - that is the
    ## only true aspect violation, and it is what the legacy `ui_button_plate` does.
    zero_margins = bool(marg) and all(v <= 0.01 for v in marg)
    if kind == "canvas":
        distort, aspect = False, "kept (letterbox)"
    elif kind == "nine":
        distort = zero_margins and abs(stretch - 1.0) > tol
        aspect = "whole-texture smear" if distort else "caps kept (middle by design)"
    elif kind == "texrect":
        distort = abs(stretch - 1.0) > tol
        aspect = "scaled (check mode)" if distort else "1:1"
    else:
        distort = abs(stretch - 1.0) > tol
        aspect = "?"
    too_small = surf.get("flags", "").find("S") >= 0 or dd[0] > 0.5 or dd[1] > 0.5 or db[0] > 0.5 or db[1] > 0.5
    band_bad = surf.get("band_ok", "Y") == "n"
    why = [w for w, on in (("too-small", too_small), ("DISTORT", distort), ("band", band_bad)) if on]
    score = (10000.0 if distort else 0.0) + max(dd[0], dd[1], db[0], db[1], 0.0)
    return {
        "deck": surf.get("deck", "?"), "cls": surf.get("cls", "?"), "kind": kind,
        "slot": surf.get("slot", "?"), "drawn": surf.get("drawn", "?"), "band": surf.get("band", "?"),
        "need": surf.get("need", "?"), "deficit": f"{dd[0]:.0f}x/{dd[1]:.0f}y",
        "band_deficit": f"{db[0]:.0f}x/{db[1]:.0f}y", "aspect": aspect,
        "stretch": round(stretch, 2), "node": surf.get("node", "?"),
        "why": "+".join(why) or "ok", "score": round(score, 1), "fail": bool(why),
    }


def short_cls(cls: str) -> str:
    return cls[:-4].replace("ui_", "") if cls.endswith(".png") else cls


def main() -> int:
    ap = argparse.ArgumentParser(description="Verify chrome-family sprite fit against content.")
    ap.add_argument("--log", help="parse an existing probe log instead of running the probe")
    ap.add_argument("--only", default="", help="keep only rows whose node/deck contains this text")
    ap.add_argument("--stretch", type=float, default=1.20, help="max drawn/cut aspect ratio (default 1.20)")
    ap.add_argument("--strict", action="store_true", help="exit 1 on any failure (default: also 1, kept explicit)")
    ap.add_argument("--warn-only", action="store_true", help="always exit 0")
    ap.add_argument("--json", action="store_true", help="emit the judged rows as JSON")
    ap.add_argument("--timeout", type=int, default=600, help="probe timeout seconds")
    args = ap.parse_args()

    if args.log:
        text = Path(args.log).read_text(errors="replace")
    else:
        try:
            text = run_probe(args.timeout)
        except (subprocess.TimeoutExpired, FileNotFoundError) as exc:
            print(f"[verify_chrome_fit] probe unavailable: {exc}", file=sys.stderr)
            return 2
        saved = Path(tempfile.gettempdir()) / "chrome_fit_probe.log"
        saved.write_text(text)
        print(f"[verify_chrome_fit] probe log: {saved} (re-parse with --log)", file=sys.stderr)

    rows = [judge(s, args.stretch) for s in parse_surfs(text)]
    if args.only:
        rows = [r for r in rows if args.only.lower() in r["node"].lower() or args.only.lower() in r["deck"].lower()]

    waivers = load_waivers()
    failures = []
    for r in rows:
        reason = waiver_for(r["node"], waivers)
        r["waived"] = reason
        if r["fail"] and reason is None:
            failures.append(r)
    failures.sort(key=lambda r: -r["score"])

    if args.json:
        print(json.dumps({"surfaces": len(rows), "failures": len(failures), "rows": failures}, indent=2))
        return 0 if args.warn_only else (1 if failures else 0)

    too_small = sum(1 for r in rows if "too-small" in r["why"])
    distort = sum(1 for r in rows if "DISTORT" in r["why"])
    band = sum(1 for r in rows if "band" in r["why"])
    print(f"surfaces={len(rows)} too_small={too_small} DISTORT={distort} band={band} "
          f"failures={len(failures)} waived={sum(1 for r in rows if r['waived'])}")
    if failures:
        print(f"\n{'node':<38} {'deck':<9} {'class':<16} {'aspect':<30} {'band':<11} "
              f"{'need':<11} {'band_def':<12} {'why'}")
        for r in failures[:60]:
            print(f"{r['node'][-38:]:<38} {r['deck'][:9]:<9} {short_cls(r['cls'])[:16]:<16} "
                  f"{r['aspect'][:30]:<30} {r['band']:<11} {r['need']:<11} "
                  f"{r['band_deficit']:<12} {r['why']}")
        if len(failures) > 60:
            print(f"... {len(failures) - 60} more (use --json for all)")
    else:
        print("chrome fit clean - no surface draws a sprite smaller than its content")
    return 0 if args.warn_only else (1 if failures else 0)


if __name__ == "__main__":
    sys.exit(main())
