#!/usr/bin/env python3
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

WS = Path("/home/kamil-paluszkiewicz/VajbOrbit")
SPEC = WS / "docs/design/UI_CHROME_ASSETS_SPEC.md"
SLICE = WS / ".agents/gen/slices/D21-chrome-family"
OUTROOT = WS / "asset-library/raw/chrome-family"
REVIEW = WS / "asset-library/_review"
KIE = os.environ["KIE_GENERATE"]
MODEL = "gpt-image-2-5-flare-text-to-image"
DEADLINE_S = 100 * 60

RUNS = [
    ("C1", "4:3", "2K", True), ("C2", "4:3", "2K", True), ("C3", "21:9", "1K", True),
    ("C4", "4:3", "2K", True), ("C5", "4:3", "2K", True), ("C6", "4:3", "4K", True),
    ("C7", "3:2", "2K", True), ("C8", "1:1", "2K", True), ("C9", "4:3", "2K", True),
    ("C10", "21:9", "1K", True), ("C11", "1:1", "2K", True), ("C12", "1:1", "2K", True),
    ("BG-1", "21:9", "2K", False), ("BG-2", "21:9", "2K", False),
    ("BG-3", "21:9", "2K", False), ("BG-4", "21:9", "2K", False),
]


def extract(spec_text):
    lines = spec_text.splitlines()
    start = next(i for i, ln in enumerate(lines) if ln.startswith("## 13."))
    lines = lines[start:]
    blocks = {}
    anchor = None
    inside = False
    buf = []
    for ln in lines:
        s = ln.strip()
        if not inside and s == "```":
            inside = True
            buf = []
            continue
        if inside:
            if s == "```":
                blocks[anchor] = "\n".join(buf).strip()
                inside = False
                anchor = None
            else:
                buf.append(ln)
            continue
        if s.startswith("**") and ("C1 " in s or s.startswith("**C") or "shared style block" in s):
            anchor = s
    style = next(v for k, v in blocks.items() if k and "shared style block" in k)
    classes = {}
    for k, v in blocks.items():
        m = re.match(r"\*\*(C\d+) ", k or "")
        if m:
            classes[m.group(1)] = v
    subjects = {}
    for ln in lines:
        m = re.match(r"^\d+\.\s+(BG-\d):\s+\"(.+)\"\s*$", ln.strip())
        if m:
            subjects[m.group(1)] = m.group(2)
    return style, classes, subjects


def build_prompts():
    style, classes, subjects = extract(SPEC.read_text(encoding="utf-8"))
    assert "SUBJECT BELOW" in classes["C13"], "C13 shell lost its SUBJECT BELOW slot"
    assert len(subjects) == 4, f"expected 4 BG subjects, got {len(subjects)}"
    pdir = SLICE / "prompts"
    pdir.mkdir(parents=True, exist_ok=True)
    plan = []
    for rid, aspect, res, transp in RUNS:
        if rid.startswith("BG"):
            body = classes["C13"].replace("SUBJECT BELOW", subjects[rid])
        else:
            body = classes[rid]
        text = style + "\n" + body
        (pdir / f"{rid}.txt").write_text(text + "\n", encoding="utf-8")
        plan.append({"id": rid, "aspect": aspect, "resolution": res,
                     "transparent": transp, "prompt_file": str(pdir / f"{rid}.txt"),
                     "prompt_chars": len(text)})
    (SLICE / "g1_plan.json").write_text(json.dumps(plan, indent=2), encoding="utf-8")
    return plan


def kie_args(plan_entry, dry=False):
    prompt = Path(plan_entry["prompt_file"]).read_text(encoding="utf-8").strip()
    cmd = [sys.executable, KIE, "--model", MODEL,
           "--prompt", prompt,
           "--aspect", plan_entry["aspect"], "--resolution", plan_entry["resolution"],
           "--out", str(OUTROOT)]
    if plan_entry["transparent"]:
        cmd.append("--transparent")
    if dry:
        cmd.append("--dry-run")
    else:
        cmd.append("--yes")
    return cmd


def cmd_dryrun():
    plan = build_prompts()
    c1 = plan[0]
    print("=== dry-run C1 (4:3 2K transparent, flare) ===")
    r = subprocess.run(kie_args(c1, dry=True), capture_output=True, text=True, timeout=120)
    print(r.stdout)
    if r.returncode != 0:
        print("STDERR:", r.stderr, file=sys.stderr)
    print("=== refusal evidence: C3 spec aspect 3:1 on flare ===")
    c3 = dict(plan[2])
    bad = kie_args(c3, dry=True)
    bad[bad.index("--aspect") + 1] = "3:1"
    r2 = subprocess.run(bad, capture_output=True, text=True, timeout=120)
    print("exit:", r2.returncode)
    print((r2.stdout or "") + (r2.stderr or ""))


def cmd_run():
    plan = json.loads((SLICE / "g1_plan.json").read_text(encoding="utf-8"))
    logs = SLICE / "logs"
    logs.mkdir(exist_ok=True)
    status_path = SLICE / "g1_batch_status.json"
    status = {"started_utc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
              "model": MODEL, "runs": {}}
    deadline = time.time() + DEADLINE_S
    for entry in plan:
        rid = entry["id"]
        if time.time() > deadline:
            status["runs"][rid] = {"skipped": "global deadline hit"}
            continue
        t0 = time.time()
        log = logs / f"{rid}.log"
        try:
            with open(log, "w") as fh:
                p = subprocess.run(kie_args(entry), stdout=fh, stderr=subprocess.STDOUT,
                                   timeout=480)
            rc = p.returncode
        except subprocess.TimeoutExpired:
            rc = -9
            with open(log, "a") as fh:
                fh.write("\nDRIVER TIMEOUT 480s\n")
        out = {}
        try:
            out = json.loads(log.read_text(encoding="utf-8"))
        except Exception:
            text = log.read_text(encoding="utf-8")
            try:
                out = json.loads(text[text.index("{"):text.rindex("}") + 1])
            except Exception:
                out = {"ok": False, "error": text.strip()[:400]}
        status["runs"][rid] = {
            "rc": rc, "seconds": round(time.time() - t0, 1),
            "task_id": out.get("task_id"), "estimate": out.get("estimate"),
            "local_paths": out.get("local_paths"), "urls": out.get("urls"),
            "ok": rc == 0 and bool(out.get("ok")),
        }
        status["updated_utc"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        status_path.write_text(json.dumps(status, indent=2), encoding="utf-8")
        print(rid, "rc", rc, round(time.time() - t0, 1), "s", flush=True)
    status_path.write_text(json.dumps(status, indent=2), encoding="utf-8")
    print("batch done")


def cmd_qc():
    from PIL import Image
    plan = json.loads((SLICE / "g1_plan.json").read_text(encoding="utf-8"))
    status = json.loads((SLICE / "g1_batch_status.json").read_text(encoding="utf-8"))
    rows = []
    for entry in plan:
        rid = entry["id"]
        run = status["runs"].get(rid, {})
        row = {"id": rid, "aspect_arg": entry["aspect"], "resolution": entry["resolution"]}
        paths = run.get("local_paths") or []
        if not run.get("ok") or not paths:
            row["result"] = "NO OUTPUT"
            row["detail"] = f"rc={run.get('rc')}"
            rows.append(row)
            continue
        img_path = Path(paths[0])
        with Image.open(img_path) as im:
            w, h = im.size
            mode = im.mode
            alpha0 = None
            if "A" in im.mode:
                a = im.getchannel("A")
                hist = a.histogram()
                alpha0 = round(hist[0] / (w * h) * 100, 1)
        want = entry["aspect"]
        wn, hd = (int(x) for x in want.split(":"))
        diff = abs(w / h - wn / hd) / (wn / hd) * 100
        row["file"] = str(img_path.relative_to(WS))
        row["pixels"] = f"{w}x{h}"
        row["mode"] = mode
        row["alpha0_pct"] = alpha0
        row["aspect_diff_pct"] = round(diff, 2)
        row["result"] = "PASS" if diff <= 2.0 else "FAIL"
        rows.append(row)
    (SLICE / "g1_qc.json").write_text(json.dumps(rows, indent=2), encoding="utf-8")
    for r in rows:
        print(r)


def cmd_sheet():
    from PIL import Image, ImageDraw
    qc = json.loads((SLICE / "g1_qc.json").read_text(encoding="utf-8"))
    REVIEW.mkdir(parents=True, exist_ok=True)
    cell_w, cell_h, label_h = 320, 240, 22
    cols = 4
    n = len(qc)
    rows_n = (n + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows_n * (cell_h + label_h)), (16, 18, 22))
    d = ImageDraw.Draw(sheet)
    for i, r in enumerate(qc):
        x = (i % cols) * cell_w
        y = (i // cols) * (cell_h + label_h)
        label = f"{r['id']} {r.get('pixels','')} {r.get('result','NO OUTPUT')}"
        d.text((x + 4, y + 4), label, fill=(210, 214, 220))
        d.rectangle([x, y + label_h, x + cell_w - 1, y + label_h + cell_h - 1],
                    outline=(70, 76, 84))
        f = r.get("file")
        if not f:
            d.text((x + 8, y + label_h + 40), "no output", fill=(200, 70, 27))
            continue
        with Image.open(WS / f) as im:
            im = im.convert("RGBA")
            im.thumbnail((cell_w - 8, cell_h - 8))
            bg = Image.new("RGBA", (cell_w, cell_h), (26, 34, 48, 255))
            bg.paste(im, ((cell_w - im.width) // 2, (cell_h - im.height) // 2), im)
            sheet.paste(bg.convert("RGB"), (x, y + label_h))
    dest = REVIEW / "chrome_family_2026-10-05.png"
    sheet.save(dest)
    print(dest)


if __name__ == "__main__":
    {"prep": build_prompts, "dryrun": cmd_dryrun, "run": cmd_run,
     "qc": cmd_qc, "sheet": cmd_sheet}[sys.argv[1]]()
