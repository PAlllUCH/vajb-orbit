"""Free local re-matte + re-split for Phase D masters. No API calls.

The generator ignored `background=transparent` (the project style block names a
void-black background, which wins), so every master came back opaque. This pass:

  1. estimates the background colour from a border-ring median,
  2. builds a hard matte from the max per-channel difference (threshold 16),
  3. removes the starfield speckle the renders bake in with a median filter
     (icon strokes are 3 px at 32 px source scale, i.e. ~96 px at 2K, so a 7x7
     median cannot erode legitimate detail),
  4. feathers the matte by 0.8 px, splits on the alpha channel and renames the cuts.

Usage:
    py -3.14 reprocess.py <run-id> [<run-id> ...]
    py -3.14 reprocess.py --all
"""
import importlib.util
import json
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageChops, ImageFilter

from wave1 import RUNS, STAGE, SKILL, CUT_PAD, STYLE_FILE, log_run, downscale

MATTE_THRESHOLD = 16
MEDIAN_SIZE = 7
FEATHER_RADIUS = 0.8
BORDER_STEP = 8
SPECK_AREA_FRAC = 0.0002  # drop matte islands smaller than this share of the frame
SPECK_MEDIAN = {"env_debris_field": 21}
SPECK_AREA = {"env_debris_field": 0.0006}
# Renders whose torn edges catch the rim light against a white source background keep a
# bright 1-3 px outline after keying; shrinking the matte drops it.
MATTE_ERODE = {"env_debris_field": 1}
# Outer shell thickness (px) in which bright rim-light pixels are dropped, so a white source
# background cannot leave a sticker-like outline.
DEFRINGE_RADIUS = {"env_debris_field": 5}
DEFRINGE_BRIGHTNESS = 165
STYLE_TEXT = STYLE_FILE.read_text(encoding="utf-8").strip()


def load_kg():
    spec = importlib.util.spec_from_file_location("kg", SKILL)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


KG = load_kg()


def background_colour(img):
    px = img.load()
    w, h = img.size
    samples = []
    for x in range(0, w, BORDER_STEP):
        samples += [px[x, 1], px[x, 3], px[x, h - 2], px[x, h - 4]]
    for y in range(0, h, BORDER_STEP):
        samples += [px[1, y], px[3, y], px[w - 2, y], px[w - 4, y]]
    samples.sort()
    mid = samples[len(samples) // 2]
    return (mid[0], mid[1], mid[2])


def max_channel_distance(img, bg):
    solid = Image.new("RGB", img.size, bg)
    diff = ImageChops.difference(img, solid)
    r, g, b = diff.split()
    return ImageChops.lighter(ImageChops.lighter(r, g), b)


def drop_specks(mask, min_area):
    """Blank matte islands smaller than min_area (baked-in stars and dust)."""
    from collections import deque
    mask = mask.copy()
    width, height = mask.size
    data = bytearray(mask.tobytes())
    visited = bytearray(width * height)
    dropped = 0
    for start in range(width * height):
        if data[start] and not visited[start]:
            visited[start] = 1
            queue = deque([start])
            pixels = []
            while queue:
                idx = queue.popleft()
                pixels.append(idx)
                x = idx % width
                y = idx // width
                for ny in (y - 1, y, y + 1):
                    if ny < 0 or ny >= height:
                        continue
                    for nx in (x - 1, x, x + 1):
                        if nx < 0 or nx >= width:
                            continue
                        nidx = ny * width + nx
                        if data[nidx] and not visited[nidx]:
                            visited[nidx] = 1
                            queue.append(nidx)
            if len(pixels) < min_area:
                for idx in pixels:
                    data[idx] = 0
                dropped += 1
    return Image.frombytes("L", (width, height), bytes(data)), dropped


def defringe(img, mask, radius, brightness=DEFRINGE_BRIGHTNESS):
    """Clear bright rim-light pixels inside the outer shell of the matte."""
    inner = mask.filter(ImageFilter.MinFilter(2 * radius + 1))
    shell = ImageChops.subtract(mask, inner)
    grey = img.convert("L").point(lambda v: 255 if v > brightness else 0)
    return ImageChops.subtract(mask, ImageChops.multiply(shell, grey))


def matte(path, out_path, median=MEDIAN_SIZE, area_frac=SPECK_AREA_FRAC, erode=0, defringe_radius=0):
    img = Image.open(path).convert("RGB")
    bg = background_colour(img)
    mask = max_channel_distance(img, bg).point(lambda v: 255 if v > MATTE_THRESHOLD else 0)
    mask = mask.filter(ImageFilter.MedianFilter(median))
    mask, dropped = drop_specks(mask, int(area_frac * img.size[0] * img.size[1]))
    if erode:
        mask = mask.filter(ImageFilter.MinFilter(2 * erode + 1))
    if defringe_radius:
        mask = defringe(img, mask, defringe_radius)
    alpha = mask.filter(ImageFilter.GaussianBlur(FEATHER_RADIUS))
    out = img.convert("RGBA")
    out.putalpha(alpha)
    out.save(out_path)
    hist = alpha.histogram()
    total = img.size[0] * img.size[1]
    return out_path, bg, 100 * hist[0] / total, 100 * hist[255] / total, dropped


def grid_split(path, cols, rows, pad=CUT_PAD):
    """Cut a grid panel by cell geometry, then alpha-trim inside each cell.

    Component splitting merges or splits cells when one object is drawn as several
    disconnected pieces (the gate's two arcs, the route line and its ticks), so grid
    panels that contain such shapes are cut on the grid instead.
    """
    img = Image.open(path).convert("RGBA")
    w, h = img.size
    outs = []
    index = 1
    for row in range(rows):
        for col in range(cols):
            cell = img.crop((round(col * w / cols), round(row * h / rows),
                             round((col + 1) * w / cols), round((row + 1) * h / rows)))
            bbox = cell.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
            if bbox:
                cell = cell.crop((max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                                  min(cell.size[0], bbox[2] + pad), min(cell.size[1], bbox[3] + pad)))
            dest = path.with_name(f"{path.stem}-cell-{index:02d}.png")
            cell.save(dest)
            outs.append(dest)
            index += 1
    return outs


def master_for(run_id, spec):
    """Locate this run's own master by matching the exact prompt stored in job.json.

    Filename slugs are not unique (the two flat-vector icon panels share a 40-char
    prompt prefix), so the recorded prompt is the only safe key.
    """
    expected = (spec["subject"] + "\n" + STYLE_TEXT).strip()
    family_dir = STAGE / spec["family"]
    for run_dir in sorted(p for p in family_dir.iterdir() if p.is_dir()):
        job = run_dir / "job.json"
        if not job.exists():
            continue
        try:
            payload = json.loads(job.read_text(encoding="utf-8"))
        except ValueError:
            continue
        if (payload.get("input", {}).get("prompt") or "").strip() != expected:
            continue
        for path in sorted(run_dir.glob("*.png")):
            name = path.name
            if "-cut-asset" in name or "-matte" in name or "-keyed" in name or "-trim" in name:
                continue
            if payload.get("alpha_paths") and path in [Path(p) for p in payload["alpha_paths"]]:
                return path
            if name.endswith("-1.png"):
                return path
        for path in sorted(run_dir.glob("*.png")):
            if "-cut-asset" not in path.name and "-matte" not in path.name:
                return path
    return None


def reprocess(run_id):
    spec = RUNS[run_id]
    family_dir = STAGE / spec["family"]
    master = master_for(run_id, spec)
    if master is None:
        print(f"[{run_id}] NO MASTER FOUND", flush=True)
        return False
    print(f"[{run_id}] master {master.name}", flush=True)

    finals = []
    if spec["family"] == "fx" or spec.get("mode") == "single_full":
        # FX stay RGB on void black for additive blending, and the nebula veil is an
        # opaque tiling layer: neither may be keyed.
        dest = family_dir / f"{run_id}.png"
        Image.open(master).convert("RGB").save(dest)
        bg, zero, opaque = None, 0.0, 0.0
        finals.append(dest)
    else:
        keyed = master.with_name(master.stem + "-matte.png")
        median = SPECK_MEDIAN.get(run_id, MEDIAN_SIZE)
        area_frac = SPECK_AREA.get(run_id, SPECK_AREA_FRAC)
        erode = MATTE_ERODE.get(run_id, 0)
        deffringe = DEFRINGE_RADIUS.get(run_id, 0)
        _, bg, zero, opaque, dropped = matte(master, keyed, median, area_frac, erode, deffringe)
        print(f"[{run_id}] bg=#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} median={median} specks_dropped={dropped} "
              f"alpha0={zero:.1f}% opaque={opaque:.1f}%", flush=True)
        if spec.get("mode") in ("ship_sheet", "i2i_sheet", "panel_white"):
            if spec.get("grid"):
                cuts = grid_split(keyed, *spec["grid"])
            else:
                cuts = KG.split_components(keyed, keyed.parent, keyed.stem + "-cut")
            print(f"[{run_id}] cuts={len(cuts)} expected={len(spec['cuts'])}", flush=True)
            if len(cuts) != len(spec["cuts"]):
                print(f"[{run_id}] cut count mismatch, nothing renamed", flush=True)
                return False
            for cut_path, name in zip(cuts, spec["cuts"]):
                dest = family_dir / f"{name}.png"
                Image.open(cut_path).convert("RGBA").save(dest)
                finals.append(dest)
                if spec.get("downscale"):
                    downscale(dest, spec["downscale"], name, family_dir)
        else:
            img = Image.open(keyed)
            if spec["mode"] in ("single_trim", "i2i_single"):
                bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
                if bbox:
                    img = img.crop((max(0, bbox[0] - CUT_PAD), max(0, bbox[1] - CUT_PAD),
                                    min(img.size[0], bbox[2] + CUT_PAD), min(img.size[1], bbox[3] + CUT_PAD)))
            dest = family_dir / f"{spec.get('out', run_id)}.png"
            img.save(dest)
            finals.append(dest)

    job_src = master.parent / "job.json"
    task_id = "?"
    if job_src.exists():
        try:
            task_id = json.loads(job_src.read_text(encoding="utf-8")).get("task_id", "?")
        except ValueError:
            task_id = "?"
        for dest in finals:
            Path(str(dest).replace(".png", ".job.json")).write_text(job_src.read_text(encoding="utf-8"), encoding="utf-8")

    for path in finals:
        im = Image.open(path)
        hist = im.convert("RGBA").getchannel("A").histogram() if im.mode == "RGBA" else None
        total = im.size[0] * im.size[1]
        cover = f" alpha0={100 * hist[0] / total:.0f}%" if hist else " opaque"
        print(f"[{run_id}] final {path.name} {im.size} {im.mode}{cover}", flush=True)

    alpha_note = ("kept RGB on void black, no keying (additive blend asset)"
                  if bg is None else
                  f"local matte, background estimated `#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X}`, threshold "
                  f"{MATTE_THRESHOLD}, {SPECK_MEDIAN.get(run_id, MEDIAN_SIZE)}x{SPECK_MEDIAN.get(run_id, MEDIAN_SIZE)} "
                  f"median plus tiny-island removal ({dropped} specks dropped), {FEATHER_RADIUS} px "
                  f"feather; achieved alpha0={zero:.1f}% and fully-opaque={opaque:.1f}%. `--transparent` was "
                  f"requested but the rendered void background won, so the matte is derived locally (free).")
    log_run(dict(family=spec["family"], markdown=(
        f"## {run_id}\n\n"
        f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
        f"- Model: `{'gpt-image-2-5-flare-image-to-image' if spec.get('ref') else 'gpt-image-2-5-flare-text-to-image'}` "
        f"(`{'flare-i2i' if spec.get('ref') else 'flare'}`), 2K, {spec['aspect']}\n"
        f"- Job id: `{task_id}`\n"
        f"- Run folder: `{master.parent.name}` (job.json kept alongside the sprites)\n"
        f"- Alpha: {alpha_note}\n"
        f"- Final files: {', '.join(p.name for p in finals)}\n"
        f"- Status: success (reprocessing pass)\n\n"
        f"Full SUBJECT text:\n\n> {spec['subject']}\n")))
    return True


if __name__ == "__main__":
    args = sys.argv[1:]
    ids = list(RUNS) if (not args or args[0] == "--all") else args
    ok = True
    for run_id in ids:
        ok = reprocess(run_id) and ok
    sys.exit(0 if ok else 1)
