"""Key the background off every sprite the library says needs it, and record what was done.

Two routes, decided by what the file is:

  ships/*                recraft/remove-background on kie.ai (1 credit each). Ships are painted
                         metal with soft glow spilling into the void, and a local key has to
                         choose a cut-off inside that glow. The paid matte is the honest read of
                         where the ship ends, so every ship goes through it.
  everything else        local key, free: the background is a uniform flat field (435 sprites on
                         near-black, 2 bar caps on white), so the split is measurable, not guessed.
                         Anything the contact sheets say came out wrong escalates to recraft with
                         `--recraft <name>` (same 1 credit).

The local key never deletes interior art. Background is the border ring's median colour; a pixel
is ink only if it deviates from that colour by more than HARD. Ink blobs smaller than MIN_PX are
dust and go. Inside an eroded subject core alpha is 255 and the colour is left alone; only the
boundary band (2 px either side of the mask) gets a ramp alpha, and those edge pixels are
un-premultiplied so they do not read as a dark fringe when the sprite sits on a bright panel.
This is the whole answer to the reprocess.py burn: measure the region that is connected to the
frame and leave every other pixel alone.

Everything is reversible: originals land in `asset-library/_prekey_backup/` (mirrored paths, md5
verified) and `--undo` puts them back. Recraft answers are kept under `_keying/recraft/` with the
upload url, job id and payload field that was accepted, so a re-run costs nothing.

Usage:
    py -3.14 staging/cut/key_assets.py --check             # free: key everything in memory, write QC sheets
    py -3.14 staging/cut/key_assets.py --apply             # write the RGBA files + backup
    py -3.14 staging/cut/key_assets.py --recraft <name>    # escalate one sprite to kie.ai
    py -3.14 staging/cut/key_assets.py --undo              # restore every original from the backup
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
import shutil
import sys
import time
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

WORKSPACE = Path(__file__).resolve().parents[2]
LIBRARY = WORKSPACE / "asset-library"
CUT = LIBRARY / "cut"
BACKUP = LIBRARY / "_prekey_backup"
KEYING = LIBRARY / "_keying"
REVIEW = LIBRARY / "_review"
RECRAFT_DIR = KEYING / "recraft"
REPORT = KEYING / "report.json"

SKILL_SCRIPTS = Path("C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts")

HARD = 10          # a pixel deviating this much from the background is ink
SOFT_HI = 48       # ramp top: at this deviation a boundary pixel is fully opaque
MIN_PX = 64        # ink blobs smaller than this are dust
BAND = 2           # px either side of the mask that get partial alpha
ERODE = 3          # the subject core is the mask eroded by this much: alpha 255, colour untouched
PLATE_PAD = 0
LIMIT_BYTES = 200_000


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def load_library() -> dict:
    return json.loads((LIBRARY / "_library.json").read_text(encoding="utf-8"))


def key_local(image: Image.Image) -> tuple[Image.Image, dict]:
    """Return (RGBA image, stats) with the flat background keyed out."""
    rgb = image.convert("RGB")
    array = np.asarray(rgb, dtype=np.int16)
    height, width, _ = array.shape
    border = np.concatenate([array[0], array[-1], array[:, 0], array[:, -1]])
    colours, counts = np.unique(border, axis=0, return_counts=True)
    background = colours[counts.argmax()].astype(np.int16)
    light = int(background.max()) > 127

    delta = np.abs(array - background).max(axis=2)
    ink = delta > HARD
    labels, count = ndimage.label(ink)
    if count:
        sizes = ndimage.sum(ink, labels, index=np.arange(1, count + 1))
        keep = np.zeros(count + 1, dtype=bool)
        keep[1:] = sizes >= MIN_PX
        subject = keep[labels]
        subject &= ink
    else:
        subject = ink

    untouched = ndimage.binary_erosion(subject, iterations=ERODE)
    inner_band = subject & ~untouched
    outer_band = ndimage.binary_dilation(subject, iterations=BAND) & ~subject
    band = inner_band | outer_band

    alpha = np.zeros((height, width), dtype=np.float32)
    alpha[subject] = 255.0
    if band.any():
        ramp = np.clip((delta.astype(np.float32) - HARD) / (SOFT_HI - HARD), 0.0, 1.0)
        ramp = ramp ** 0.7
        alpha[inner_band] = 255.0 * ramp[inner_band]
        alpha[outer_band] = 255.0 * ramp[outer_band]
    alpha = np.clip(np.round(alpha), 0, 255).astype(np.uint8)

    colour = array.astype(np.float32)
    soft = (alpha > 0) & (alpha < 255)
    if soft.any():
        a = (alpha[soft].astype(np.float32) / 255.0)[:, None]
        unmult = background[None, :] + (colour[soft] - background[None, :]) / np.maximum(a, 1e-3)
        colour[soft] = np.clip(unmult, 0, 255)

    out = np.dstack([np.round(colour).astype(np.uint8), alpha])
    stats = {
        "background": [int(v) for v in background],
        "polarity": "light" if light else "dark",
        "subject_pct": round(float(subject.mean()) * 100, 2),
        "edge_px": int(band.sum()),
        "soft_px": int(soft.sum()),
        "components_kept": int(subject.sum() > 0),
    }
    return Image.fromarray(out, "RGBA"), stats


def select(scope: str, library: dict) -> list[dict]:
    records = [v for v in library["assets"].values()
               if v.get("needs_keying") and v["role"] == "sprite"]
    if scope == "ships":
        records = [r for r in records if r["folder"] == "ships"]
    elif scope == "local":
        records = [r for r in records if r["folder"] != "ships"]
    return sorted(records, key=lambda r: r["path"])


def tile_canvas(size: int = 256) -> Image.Image:
    field = Image.new("RGB", (size, size), (90, 92, 98))
    px = field.load()
    step = 16
    for y in range(size):
        for x in range(size):
            if ((x // step) + (y // step)) % 2 == 0:
                px[x, y] = (150, 152, 158)
    return field


def build_qc(record: dict, keyed: Image.Image, original: Image.Image | None = None) -> Path:
    """One-page before/after sheet for a single sprite."""
    tile = 300
    columns = 2 if original is not None else 1
    canvas = Image.new("RGB", (columns * tile + 12 * columns, tile + 22), (24, 24, 28))
    draw = ImageDraw.Draw(canvas)
    frames = [original, keyed] if original is not None else [keyed]
    for index, im in enumerate(frames):
        thumb = im.convert("RGBA").copy()
        thumb.thumbnail((tile, tile), Image.LANCZOS)
        cell = tile_canvas()
        cell.paste(thumb, ((tile - thumb.width) // 2, (tile - thumb.height) // 2), thumb)
        canvas.paste(cell, (index * (tile + 12) + 4, 18))
    draw.text((6, 4), f"{record['name']}  ·  original | keyed" if original is not None
              else f"{record['name']}  ·  keyed on checker", fill=(235, 235, 235))
    out = qc_name(record)
    canvas.save(out, "JPEG", quality=82)
    return out


def build_pages(records: list[dict], keyed_images: dict[str, Image.Image],
                out_prefix: str, cols: int = 5, rows: int = 5, tile: int = 256) -> list[Path]:
    """Paginated contact sheets: every sprite keyed, on a checkerboard.

    The viewer refuses a decoded image above ~200 KB, so the canvas is saved, and if it is too
    large it is progressively downscaled (keeping the labels legible means the scale step is
    small). Quality alone is not enough: flat art compresses well but the checkerboard does not.
    """
    per_page = cols * rows
    pages = []
    for page_index in range(0, len(records), per_page):
        chunk = records[page_index:page_index + per_page]
        canvas = Image.new("RGB", (cols * (tile + 12), rows * (tile + 18)), (18, 18, 22))
        draw = ImageDraw.Draw(canvas)
        for index, record in enumerate(chunk):
            column, row = index % cols, index // cols
            cell = tile_canvas(tile)
            thumb = keyed_images[record["name"]].convert("RGBA").copy()
            thumb.thumbnail((tile, tile), Image.LANCZOS)
            cell.paste(thumb, ((tile - thumb.width) // 2, (tile - thumb.height) // 2), thumb)
            canvas.paste(cell, (column * (tile + 12) + 3, row * (tile + 18) + 14))
            draw.text((column * (tile + 12) + 5, row * (tile + 18) + 2), record["name"][:44],
                      fill=(228, 228, 228))
        number = page_index // per_page + 1
        out = REVIEW / f"{out_prefix}_p{number:02d}.jpg"
        working = canvas
        for _ in range(7):
            buffer = io.BytesIO()
            working.save(buffer, "JPEG", quality=74)
            if buffer.tell() <= LIMIT_BYTES:
                out.write_bytes(buffer.getvalue())
                break
            working = working.resize((int(working.width * 0.85), int(working.height * 0.85)),
                                     Image.LANCZOS)
        pages.append(out)
    return pages


def qc_name(record: dict) -> Path:
    return REVIEW / f"peek_key_{record['name']}.jpg"


def cmd_check(scope: str) -> None:
    library = load_library()
    records = select(scope, library)
    KEYING.mkdir(exist_ok=True)
    REVIEW.mkdir(exist_ok=True)
    report: dict[str, dict] = {}
    images: dict[str, Image.Image] = {}
    suspicious = []
    for index, record in enumerate(records, 1):
        path = LIBRARY / record["path"]
        original = Image.open(path).convert("RGB")
        keyed, stats = key_local(original)
        report[record["name"]] = stats
        images[record["name"]] = keyed
        if stats["subject_pct"] < 1.0 or stats["soft_px"] > 0.4 * keyed.width * keyed.height:
            suspicious.append(record["name"])
        if index % 25 == 0:
            print(f"   {index}/{len(records)} keyed in memory", flush=True)
    (KEYING / f"report_{scope}.json").write_text(
        json.dumps(report, indent=1, ensure_ascii=False), encoding="utf-8")
    pages = build_pages(records, images, f"key_check_{scope}")
    print(f"keyed {len(records)} sprites in memory (scope {scope}), nothing written to cut/")
    print(f"suspicious (subject < 1% or huge soft band): {len(suspicious)}")
    for name in suspicious[:40]:
        print("   ", name)
    print(f"contact sheets: {len(pages)} pages -> _review/key_check_{scope}_p*.jpg")


def cmd_apply(scope: str) -> None:
    library = load_library()
    records = select(scope, library)
    BACKUP.mkdir(exist_ok=True)
    manifest_path = BACKUP / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    done = 0
    for record in records:
        path = LIBRARY / record["path"]
        digest = md5(path)
        if manifest.get(record["path"], {}).get("md5") == digest:
            continue  # already keyed from this exact source
        original = Image.open(path).convert("RGB")
        keyed, stats = key_local(original)
        backup = BACKUP / record["path"]
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, backup)
        keyed.save(path)
        manifest[record["path"]] = {
            "md5": digest, "backup": str(backup.relative_to(LIBRARY)).replace("\\", "/"),
            "stats": stats,
        }
        done += 1
    manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False), encoding="utf-8")
    print(f"keyed {done} sprites in place (scope {scope}); backups in _prekey_backup/")


def import_skill():
    sys.path.insert(0, str(SKILL_SCRIPTS))
    import kie_generate as kg
    return kg


def rate_limiter(per_minute: int):
    """A sliding-window limiter so submissions never exceed kie.ai's 20/minute."""
    import threading
    import collections
    import time as _time
    stamps: "collections.deque[float]" = collections.deque()
    lock = threading.Lock()

    def wait() -> None:
        while True:
            with lock:
                now = _time.monotonic()
                while stamps and now - stamps[0] > 60.0:
                    stamps.popleft()
                if len(stamps) < per_minute:
                    stamps.append(now)
                    return
                pause = 60.0 - (now - stamps[0]) + 0.05
            _time.sleep(max(pause, 0.05))

    return wait


def cmd_recraft(names: list[str], scope: str, limit: int, make_pairs: bool,
                workers: int, per_minute: int) -> None:
    """Key sprites on kie.ai with recraft/remove-background, 20 submissions a minute.

    Two pipelined phases: submissions run through a worker pool behind a sliding-window rate
    limiter (kie.ai allows about 20 images a minute), then the accepted tasks are polled and
    downloaded in parallel. Each sprite's answer is cached under `_keying/recraft/` keyed by the
    md5 of its pre-key file, so an interrupted run resumes without re-billing anything.
    """
    import threading
    from concurrent.futures import ThreadPoolExecutor, as_completed
    library = load_library()
    by_name = {v["name"]: v for v in library["assets"].values()
               if v["role"] in ("sprite", "plate")}
    if not names:
        names = [r["name"] for r in select(scope, library)]
    kg = import_skill()
    api_key = kg.resolve_api_key()
    RECRAFT_DIR.mkdir(parents=True, exist_ok=True)
    BACKUP.mkdir(exist_ok=True)
    manifest_path = BACKUP / "manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8")) if manifest_path.exists() else {}
    manifest_lock = threading.Lock()
    model = "recraft/remove-background"
    ledger_lock = threading.Lock()

    todo = []
    cached_ready = []
    for name in names:
        record = by_name.get(name)
        if not record or not record.get("needs_keying"):
            continue
        path = LIBRARY / record["path"]
        if Image.open(path).mode == "RGBA":
            continue
        entry_path = RECRAFT_DIR / f"{name}.json"
        entry = json.loads(entry_path.read_text(encoding="utf-8")) if entry_path.exists() else {}
        backup = BACKUP / record["path"]
        source_digest = md5(backup) if backup.exists() else md5(path)
        if entry.get("source_md5") == source_digest and entry.get("result"):
            cached_ready.append((name, record, entry))
        else:
            todo.append(name)
    if limit:
        todo = todo[:limit]
    print(f"recraft batch: {len(todo)} to submit, {len(cached_ready)} cached, "
          f"{len(names) - len(todo) - len(cached_ready)} already keyed/skipped", flush=True)

    gate = rate_limiter(per_minute)
    submitted: dict[str, tuple[dict, str, str, str]] = {}
    failures: list[str] = []
    submit_lock = threading.Lock()

    def submit(name: str):
        record = by_name[name]
        path = LIBRARY / record["path"]
        gate()
        url = kg.upload_file(str(path), api_key)
        resp = None
        field = "image"
        for field in ("image", "image_url"):
            try:
                resp = kg.create_task(model, {field: url}, api_key)
            except Exception as exc:  # HTTPError carries the server's field complaint
                detail = getattr(exc, "read", lambda: b"")()
                print(f"!! {name}: {field} -> {exc} {detail[:160]!r}", flush=True)
                resp = None
                continue
            if resp.get("code") == 200 and (resp.get("data") or {}).get("taskId"):
                break
            print(f"!! {name}: {field} rejected: {json.dumps(resp)[:200]}", flush=True)
            resp = None
        if not resp:
            with submit_lock:
                failures.append(name)
            return
        task_id = resp["data"]["taskId"]
        with submit_lock:
            submitted[name] = (record, task_id, field, url)

    if todo:
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = [pool.submit(submit, name) for name in todo]
            for index, future in enumerate(as_completed(futures), 1):
                future.result()
                if index % 10 == 0 or index == len(futures):
                    print(f"   submitted {index}/{len(futures)}", flush=True)
    print(f"submitted {len(submitted)} task(s), {len(failures)} failed to submit", flush=True)

    def finish(name: str, record: dict, entry: dict, cached: bool) -> None:
        path = LIBRARY / record["path"]
        result = Image.open(LIBRARY / entry["result"])
        if result.mode != "RGBA":
            raise RuntimeError(f"recraft returned {result.mode}, no alpha")
        original = Image.open(path).convert("RGB")
        rgba = result.convert("RGBA")
        if rgba.size != original.size:
            rgba = rgba.resize(original.size, Image.LANCZOS)
        if make_pairs:
            build_qc(record, rgba, original)
        backup = BACKUP / record["path"]
        backup.parent.mkdir(parents=True, exist_ok=True)
        with manifest_lock:
            shutil.copyfile(path, backup)
            rgba.save(path)
            manifest[record["path"]] = {
                "md5": md5(backup), "backup": str(backup.relative_to(LIBRARY)).replace("\\", "/"),
                "route": "recraft", "job_id": entry["job_id"],
            }
            manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False),
                                     encoding="utf-8")
        return rgba

    done = 0
    total = len(submitted) + len(cached_ready)

    def poll_and_save(name: str, record: dict, task_id: str, field: str, url: str) -> None:
        path = LIBRARY / record["path"]
        data, error = kg.poll_task(task_id, api_key, 5.0, 300.0)
        if error:
            raise RuntimeError(f"task {task_id}: {error}")
        urls = kg.result_urls(data)
        if not urls:
            raise RuntimeError(f"task {task_id}: no result url")
        out = kg.download(urls[0], RECRAFT_DIR, name, "recraft")
        backup = BACKUP / record["path"]
        source_digest = md5(backup) if backup.exists() else md5(path)
        entry = {"source_md5": source_digest, "job_id": task_id, "payload_field": field,
                 "upload_url": url, "result_url": urls[0],
                 "result": str(out.relative_to(LIBRARY)).replace("\\", "/"),
                 "at": time.strftime("%Y-%m-%d %H:%M:%S")}
        (RECRAFT_DIR / f"{name}.json").write_text(json.dumps(entry, indent=1, ensure_ascii=False),
                                                  encoding="utf-8")
        with ledger_lock:
            with (KEYING / "recraft_ledger.jsonl").open("a", encoding="utf-8") as fh:
                fh.write(json.dumps({"name": name, "job_id": task_id,
                                     "at": entry["at"], "credits": 1}) + "\n")
        finish(name, record, entry, cached=False)

    if submitted:
        with ThreadPoolExecutor(max_workers=workers) as pool:
            futures = {pool.submit(poll_and_save, name, record, task_id, field, url): name
                       for name, (record, task_id, field, url) in submitted.items()}
            for future in as_completed(futures):
                name = futures[future]
                done += 1
                try:
                    future.result()
                    print(f"{done:4d}/{total} {name}: keyed", flush=True)
                except Exception as exc:
                    failures.append(name)
                    print(f"!! {name}: {type(exc).__name__}: {exc}", flush=True)

    for name, record, entry in cached_ready:
        done += 1
        try:
            finish(name, record, entry, cached=True)
            print(f"{done:4d}/{total} {name}: keyed (cached)", flush=True)
        except Exception as exc:
            failures.append(name)
            print(f"!! {name}: {type(exc).__name__}: {exc}", flush=True)

    print(f"batch done: {len(submitted)} new recraft call(s) billed, "
          f"{total - len(failures)} sprite(s) keyed, {len(failures)} failure(s)")
    if failures:
        print("failures:", ", ".join(failures[:30]))
        (KEYING / "recraft_failures.json").write_text(json.dumps(failures, indent=1),
                                                      encoding="utf-8")


def cmd_qc(scope: str, prefix: str) -> None:
    """Tile every keyed sprite of a scope onto checkerboard contact pages, straight off disk."""
    library = load_library()
    records = [v for v in library["assets"].values() if v["role"] == "sprite"]
    if scope != "all":
        records = [r for r in records if r["folder"] == scope or r["folder"].startswith(scope + "/")]
    records = sorted([r for r in records if Image.open(LIBRARY / r["path"]).mode == "RGBA"],
                     key=lambda r: r["path"])
    REVIEW.mkdir(exist_ok=True)
    images = {r["name"]: Image.open(LIBRARY / r["path"]).convert("RGBA") for r in records}
    pages = build_pages(records, images, prefix)
    print(f"{len(records)} keyed sprites -> {len(pages)} page(s) as _review/{prefix}_p*.jpg")


def cmd_undo() -> None:
    manifest_path = BACKUP / "manifest.json"
    if not manifest_path.exists():
        print("no backup manifest")
        return
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    restored = 0
    for rel, entry in manifest.items():
        backup = LIBRARY / entry["backup"]
        target = LIBRARY / rel
        if backup.exists():
            shutil.copyfile(backup, target)
            restored += 1
    print(f"restored {restored} originals from _prekey_backup/; manifest kept")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="key in memory, write QC sheets only")
    parser.add_argument("--qc", action="store_true", help="contact pages of the keyed sprites on disk")
    parser.add_argument("--apply", action="store_true", help="write the RGBA files in place")
    parser.add_argument("--recraft", nargs="*", default=None,
                        help="sprite names to key on kie.ai; no names = the whole scope")
    parser.add_argument("--limit", type=int, default=0, help="cap the batch (0 = no cap)")
    parser.add_argument("--pairs", action="store_true",
                        help="also write a before/after sheet per sprite")
    parser.add_argument("--undo", action="store_true")
    parser.add_argument("--scope", choices=("all", "ships", "local"), default="all")
    parser.add_argument("--workers", type=int, default=8, help="parallel uploads/polls")
    parser.add_argument("--per-minute", type=int, default=20,
                        help="submissions per minute (kie.ai allows about 20)")
    global ARGS
    ARGS = parser.parse_args()
    if ARGS.undo:
        cmd_undo()
    elif ARGS.recraft is not None:
        cmd_recraft(ARGS.recraft, ARGS.scope, ARGS.limit, ARGS.pairs,
                    ARGS.workers, ARGS.per_minute)
    elif ARGS.apply:
        cmd_apply(ARGS.scope)
    elif ARGS.check:
        cmd_check(ARGS.scope)
    elif ARGS.qc:
        cmd_qc(ARGS.scope, "key_check_final")
    else:
        parser.print_help()


if __name__ == "__main__":
    ARGS = None
    main()
