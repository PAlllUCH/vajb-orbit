"""Recraft background-removal probe + A/B helper (uses the skill's own API helpers).

The skill submits `image_url` as a list for utilities, which recraft/remove-background
rejects with `{"code":500,"msg":"image is required"}`. Rejected submissions cost nothing,
so this tries the plausible field shapes in order and stops at the first acceptance.

Usage:
    py -3.14 ab_recraft.py <local-image> <out-dir>
"""
import importlib.util
import json
import sys
from pathlib import Path

SKILL = Path(r"C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py")
spec = importlib.util.spec_from_file_location("kg", SKILL)
kg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kg)

MODEL = "recraft/remove-background"


def main():
    src = Path(sys.argv[1])
    out = Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    api_key = kg.resolve_api_key()
    url = kg.upload_file(src, api_key)
    print(json.dumps({"uploaded": url})[:200], flush=True)

    shapes = [
        ("image_url:string", {"image_url": url}),
        ("image_urls:list", {"image_urls": [url]}),
        ("image:string", {"image": url}),
    ]
    task_id = None
    for label, payload in shapes:
        try:
            resp = kg.create_task(MODEL, payload, api_key)
        except Exception as exc:  # noqa: BLE001
            print(f"{label} -> exception {type(exc).__name__}: {exc}", flush=True)
            continue
        ok = resp.get("code") == 200 and (resp.get("data") or {}).get("taskId")
        print(f"{label} -> {json.dumps(resp)[:200]}", flush=True)
        if ok:
            task_id = resp["data"]["taskId"]
            print(f"ACCEPTED with {label}", flush=True)
            break
    if not task_id:
        print("all field shapes rejected (nothing billed)", flush=True)
        return 1

    data, error = kg.poll_task(task_id, api_key, 5.0, 300.0)
    if error:
        print(f"task failed: {error}", flush=True)
        return 1
    urls = kg.result_urls(data)
    print(f"result urls: {urls}", flush=True)
    if not urls:
        return 1
    local = kg.download(urls[0], out, f"{src.stem}-recraft", 1)
    print(f"downloaded {local}", flush=True)
    cuts = kg.split_components(Path(local), out, f"{src.stem}-recraft-cut")
    print(f"cuts: {len(cuts)}", flush=True)
    for path in cuts:
        print(f"  {Path(path).name}", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
