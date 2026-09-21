"""Key a rendered PNG that is not a library sprite yet, through recraft/remove-background.

The 2026-09-20 pass keyed the library in place because every file already had a name and a record.
New renders (Phase G hulls and FX in `staging/phase_g/`) have neither, so this runs the same paid
matte over explicit file paths and writes `<stem>-keyed.png` beside each source, leaving the
render itself untouched as the record. Answers are cached in `asset-library/_keying/recraft/`
keyed by the source md5, and every submission goes through the same sliding-window limiter at
kie.ai's 20 images a minute, so a resume never re-bills.

Usage:
    py -3.14 staging/phase_g/key_new.py <file.png> [<file.png> ...]
    py -3.14 staging/phase_g/key_new.py --scope staging/phase_g/ships
    py -3.14 staging/phase_g/key_new.py --scope staging/phase_g/ships --workers 10 --per-minute 20
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
LIBRARY = ROOT / "asset-library"
KEYING = LIBRARY / "_keying"
RECRAFT_DIR = KEYING / "recraft"
SKILL_SCRIPTS = Path("C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts")
MODEL = "recraft/remove-background"


def md5(path: Path) -> str:
    return hashlib.md5(path.read_bytes()).hexdigest()


def cache_key(path: Path) -> str:
    """A per-file cache name. The render's own slug is useless here: every prompt in a family
    starts with the same style block, so four different hulls came back as the same
    `grimdark-painted-sci-fi-semi-realistic-1.png`. Content decides the key.
    """
    return f"{path.stem[:48]}-{md5(path)[:8]}"


def import_skill():
    sys.path.insert(0, str(SKILL_SCRIPTS))
    import kie_generate as kg
    return kg


def rate_limiter(per_minute: int):
    import collections
    import threading
    stamps: "collections.deque[float]" = collections.deque()
    lock = threading.Lock()

    def wait() -> None:
        while True:
            with lock:
                now = time.monotonic()
                while stamps and now - stamps[0] > 60.0:
                    stamps.popleft()
                if len(stamps) < per_minute:
                    stamps.append(now)
                    return
                pause = 60.0 - (now - stamps[0]) + 0.05
            time.sleep(max(pause, 0.05))

    return wait


def alpha_share(path: Path) -> float:
    img = Image.open(path)
    if img.mode not in ("RGBA", "LA"):
        return 0.0
    arr = np.asarray(img.convert("RGBA").getchannel("A"))
    return float((arr == 0).mean())


def targets(paths: list[str], scopes: list[str]) -> list[Path]:
    found: list[Path] = []
    for raw in paths:
        found.append(Path(raw).resolve())
    for scope in scopes:
        found += [p.resolve() for p in sorted(Path(scope).rglob("*.png"))
                  if not p.stem.endswith("-keyed") and not p.stem.endswith("-matte")]
    return [p for p in found if p.is_file()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("paths", nargs="*")
    parser.add_argument("--scope", action="append", default=[])
    parser.add_argument("--workers", type=int, default=10)
    parser.add_argument("--per-minute", type=int, default=20)
    parser.add_argument("--force", action="store_true", help="re-key files that already carry alpha")
    args = parser.parse_args()

    files = targets(args.paths, args.scope)
    if not files:
        print("nothing to do: pass file paths or --scope <dir>")
        return 1
    RECRAFT_DIR.mkdir(parents=True, exist_ok=True)
    kg = import_skill()
    api_key = kg.resolve_api_key()
    gate = rate_limiter(args.per_minute)

    todo: list[Path] = []
    cached: list[tuple[Path, dict]] = []
    skipped = 0
    for path in files:
        stem = path.stem
        out = path.with_name(f"{stem}-keyed.png")
        if out.exists() and not args.force:
            skipped += 1
            continue
        if not args.force and alpha_share(path) > 0.10:
            print(f"   {stem}: already carries alpha, skipped (--force to re-key)")
            skipped += 1
            continue
        entry_path = RECRAFT_DIR / f"{cache_key(path)}.json"
        entry = json.loads(entry_path.read_text(encoding="utf-8")) if entry_path.exists() else {}
        if entry.get("source_md5") == md5(path) and entry.get("result"):
            cached.append((path, entry))
        else:
            todo.append(path)
    print(f"key_new: {len(todo)} to submit, {len(cached)} cached, {skipped} skipped", flush=True)

    submitted: dict[str, tuple[Path, str, str]] = {}
    failures: list[str] = []
    lock = __import__("threading").Lock()

    def submit(path: Path) -> None:
        gate()
        url = kg.upload_file(str(path), api_key)
        resp = None
        field = "image"
        for field in ("image", "image_url"):
            try:
                resp = kg.create_task(MODEL, {field: url}, api_key)
            except Exception as exc:
                detail = getattr(exc, "read", lambda: b"")()
                print(f"!! {path.name}: {field} -> {exc} {detail[:160]!r}", flush=True)
                resp = None
                continue
            if resp.get("code") == 200 and (resp.get("data") or {}).get("taskId"):
                break
            print(f"!! {path.name}: {field} rejected: {json.dumps(resp)[:200]}", flush=True)
            resp = None
        if not resp:
            with lock:
                failures.append(path.name)
            return
        with lock:
            submitted[str(path)] = (path, resp["data"]["taskId"], url)

    if todo:
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = [pool.submit(submit, path) for path in todo]
            for index, future in enumerate(as_completed(futures), 1):
                future.result()
                if index % 5 == 0 or index == len(futures):
                    print(f"   submitted {index}/{len(futures)}", flush=True)
    print(f"submitted {len(submitted)} task(s), {len(failures)} failed to submit", flush=True)

    def save(path: Path, entry: dict) -> None:
        result = Image.open(LIBRARY / entry["result"])
        if result.mode != "RGBA":
            raise RuntimeError(f"recraft returned {result.mode}, no alpha")
        original = Image.open(path)
        rgba = result.convert("RGBA")
        if rgba.size != original.size:
            rgba = rgba.resize(original.size, Image.LANCZOS)
        rgba.save(path.with_name(f"{path.stem}-keyed.png"))
        print(f"   {path.stem}: keyed ({entry['result'].rsplit('/', 1)[-1]})", flush=True)

    def poll_and_save(path: Path, task_id: str, url: str) -> None:
        data, error = kg.poll_task(task_id, api_key, 5.0, 300.0)
        if error:
            raise RuntimeError(f"task {task_id}: {error}")
        urls = kg.result_urls(data)
        if not urls:
            raise RuntimeError(f"task {task_id}: no result url")
        out = kg.download(urls[0], RECRAFT_DIR, cache_key(path), "recraft")
        entry = {"source_md5": md5(path), "job_id": task_id, "payload_field": "image",
                 "upload_url": url, "result_url": urls[0],
                 "result": str(out.relative_to(LIBRARY)).replace("\\", "/"),
                 "source": str(path.relative_to(ROOT)).replace("\\", "/"),
                 "at": time.strftime("%Y-%m-%d %H:%M:%S")}
        (RECRAFT_DIR / f"{cache_key(path)}.json").write_text(
            json.dumps(entry, indent=1, ensure_ascii=False), encoding="utf-8")
        with (KEYING / "recraft_ledger.jsonl").open("a", encoding="utf-8") as fh:
            fh.write(json.dumps({"name": path.stem, "job_id": task_id,
                                 "at": entry["at"], "credits": 1}) + "\n")
        save(path, entry)

    done = 0
    total = len(submitted) + len(cached)
    if submitted:
        with ThreadPoolExecutor(max_workers=args.workers) as pool:
            futures = {pool.submit(poll_and_save, path, task_id, url): path.name
                       for path, task_id, url in submitted.values()}
            for future in as_completed(futures):
                name = futures[future]
                done += 1
                try:
                    future.result()
                except Exception as exc:
                    failures.append(name)
                    print(f"!! {name}: {type(exc).__name__}: {exc}", flush=True)
    for path, entry in cached:
        done += 1
        try:
            save(path, entry)
        except Exception as exc:
            failures.append(path.name)
            print(f"!! {path.name}: {type(exc).__name__}: {exc}", flush=True)

    print(f"key_new done: {len(submitted)} billed call(s), {total - len(failures)} keyed, "
          f"{len(failures)} failure(s)")
    if failures:
        print("failures:", ", ".join(failures[:30]))
    return 0 if not failures else 1


if __name__ == "__main__":
    raise SystemExit(main())
