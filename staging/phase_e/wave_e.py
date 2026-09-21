"""Phase E driver (docs/design/ASSET_EXPANSION_SPEC_E.md).

Usage:
    py -3.14 staging/phase_e/wave_e.py <run-id> [<run-id> ...]
    py -3.14 staging/phase_e/wave_e.py --list

One paid skill call per run, then free local alpha/split/rename/log work.
Wave 1: env_base_* and env_outpost_* (plus the base_mining A/B pair).
Wave 2: env_body_*, env_bg_body_plate, panel_boosters, panel_status,
        panel_asteroids_b, env_mine.
"""
import importlib.util
import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path

from PIL import Image

WORKSPACE = Path(r"G:/Mój dysk/Projekty/Vajb Orbit")
PROJECT = WORKSPACE / "vajb-orbit"
STAGE = WORKSPACE / "staging" / "phase_e"
PHASE_D = WORKSPACE / "staging" / "phase_d"
STYLE_FILE = PROJECT / "assets" / "style-block.txt"
STYLE_ALPHA = STAGE / "style-block-alpha.txt"
SKILL = Path(r"C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py")
PY = sys.executable
CA_BUNDLE = r"C:/Users/Kamil/AppData/Local/Python/pythoncore-3.14-64/Lib/site-packages/certifi/cacert.pem"

sys.path.insert(0, str(PHASE_D))
from reprocess import matte, grid_split  # noqa: E402

SHIP_NEG = ("no chrome, no neon, no saturated colours, no second accent, no perspective, "
            "no tilt, no text, no watermark, no grid lines, no labels.")
ICON_NEG = ("no chrome, no neon, no saturated colours, no second accent, no gradient, no glow, "
            "no shadows, no text, no watermark, no grid lines, no labels, no multicolour.")
ENV_NEG = ("no planets with atmospheres, no clouds, no bright nebula, no saturated colours, "
           "no second accent colour, no chrome, no neon, no text, no watermark, no grid lines, "
           "no ships, no figures.")

ENV_FRAME = ("one single centred top-down orthographic render, the {what} occupying about {cover} of the frame "
             "width, no tilt and no perspective, isolated on a fully transparent background, no background "
             "colour, no backdrop, no ground shadow. ")
ENV_STYLE = ("Platework in gunmetal mid #3A3F46 and gunmetal dark #2B2F35 with cold steel highlight #565C63 rim "
             "on the shadow side, harsh directional key light from the upper left, heavy hull grime, oil stains, "
             "rust streaks, pitted metal, weld beads over old repairs, subtle film grain, everything one value "
             "step darker than ships. ")


def env_single(subject, cover="60 percent"):
    return (subject + " " + ENV_FRAME.format(what="structure", cover=cover) + ENV_STYLE + ENV_NEG)


RUNS = {
    # ---------------- wave 1: base A/B pair ----------------
    "base_mining": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_base_mining_control",
        subject=env_single(
            "Mining base structure, a station-scale industrial platform built around ore processing. Silhouette: "
            "a row of three riveted cylindrical ore silos standing around a central crusher derrick with a heavy "
            "rotating boom arm, segmented conveyor arms reaching outward ending in claw grapples, thick mooring "
            "clamp legs folded inward as if clamping onto a rock, a squat command drum at the rear. The silo row "
            "and crusher derrick dominate the outline; no weapon batteries, no docking ring. Weathering: heaviest "
            "industrial grime, scorch marks around the derrick exhaust, ore dust staining, rust streaks. Emissive: "
            "a few small hot burnt ember C8461B warning lamps along the silo rims and the derrick tip only, "
            "contained, no ember glow halo, no floodlights.")),
    "base_mining_alpha": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_base_mining_alpha", style="alpha",
        subject=env_single(
            "Mining base structure, a station-scale industrial platform built around ore processing. Silhouette: "
            "a row of three riveted cylindrical ore silos standing around a central crusher derrick with a heavy "
            "rotating boom arm, segmented conveyor arms reaching outward ending in claw grapples, thick mooring "
            "clamp legs folded inward as if clamping onto a rock, a squat command drum at the rear. The silo row "
            "and crusher derrick dominate the outline; no weapon batteries, no docking ring. Weathering: heaviest "
            "industrial grime, scorch marks around the derrick exhaust, ore dust staining, rust streaks. Emissive: "
            "a few small hot burnt ember C8461B warning lamps along the silo rims and the derrick tip only, "
            "contained, no ember glow halo, no floodlights.")),
    # ---------------- wave 1: bases ----------------
    "base_trade": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_base_trade",
        subject=env_single(
            "Trade and refinery base structure, a station-scale commercial platform. Silhouette: a wide circular "
            "docking ring with mooring arms projecting left and right, a central plaza deck inside the ring with "
            "two cargo transfer cranes swinging over it, clusters of fuel cell drums mounted along the ring's "
            "outer rim, a small control cupola on the ring. The docking ring and crane gantries dominate the "
            "outline; no ore silos, no weapon batteries. Weathering: busy industrial wear, oil stains around the "
            "cranes, rust streaks from the rivet lines, hull grime. Emissive: a few small hot burnt ember C8461B "
            "docking lamps spaced along the ring only, contained, no ember glow halo, no floodlights.")),
    "base_defense": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_base_defense",
        subject=env_single(
            "Defense fortress structure, a station-scale military platform. Silhouette: layered armoured "
            "casemates stacked into a broad terraced pyramid, a row of four heavy gun batteries along the top "
            "terrace with thick barrel shrouds, sensor masts and a segmented shield-plate collar around the "
            "mid-terrace, armoured blast shutters instead of windows. The terrace stack and battery row dominate "
            "the outline; no cranes, no silos, no docking ring. Weathering: battle-damaged fortification, dents "
            "and scorch-blackened craters on the armour faces, weld beads over old repairs, rust streaks, pitted "
            "metal. Emissive: a few small hot burnt ember C8461B warning lamps beside the batteries and one "
            "beacon at the mast top only, contained, no ember glow halo, no floodlights.")),
    "base_shipyard": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_base_shipyard",
        subject=env_single(
            "Shipyard and drydock structure, a station-scale construction platform, the cradle empty. Silhouette: "
            "two tall gantry towers flanking an open construction cradle with skeletal scaffolding and clamp "
            "frames where a hull would sit, but the cradle is completely empty, tug rails running along the spine "
            "between the towers, a small foundry block at one end with exhaust stacks. The empty cradle between "
            "the gantry towers is the read; no finished ship, no hull inside, no cranes carrying anything. "
            "Weathering: industrial grime, scorch marks at the foundry stacks, oil stains along the rails, rust "
            "streaks. Emissive: a few small hot burnt ember C8461B work lamps on the gantry towers and rail "
            "ends only, contained, no ember glow halo, no floodlights.")),
    # ---------------- wave 1: outposts ----------------
    "outpost_mining": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_outpost_mining", cover="45 percent",
        subject=env_single(
            "Mining outpost, a compact small platform about half the footprint of a base, anchored onto a small "
            "asteroid chunk beneath it. Silhouette: a rectangular deck with a tapered drill tower rising from its "
            "centre, two clamp arms biting into the rock chunk below, one small ore hopper and a short conveyor "
            "stub on the deck. The drill tower on its rock anchor is the read; no silos, no docking ring. "
            "Weathering: ore dust staining, oil stains, rust streaks, pitted metal. Emissive: exactly one small "
            "hot burnt ember C8461B lamp at the drill tower base, contained, no ember glow halo.",
            cover="45 percent")),
    "outpost_defense": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_outpost_defense",
        subject=env_single(
            "Defense outpost, a compact small platform about half the footprint of a base. Silhouette: a squat "
            "armoured drum with two stacked gun turrets on top, a segmented shield-plate collar that is slightly "
            "raised around the drum's mid-line, stubby stabiliser feet folded under the body. The stacked turrets "
            "on the armoured drum are the read; no cranes, no masts, no docking ring. Weathering: scorch marks "
            "at the barrel muzzles, dents, rust streaks, pitted metal. Emissive: exactly two small hot burnt "
            "ember C8461B lamps beside the turret rings, contained, no ember glow halo.")),
    "outpost_relay": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_outpost_relay",
        subject=env_single(
            "Communications relay outpost, a compact small platform about half the footprint of a base. "
            "Silhouette: a tall thin lattice mast rising from a small cross-braced platform, three dish "
            "antennas mounted at different heights on the mast, thin guy cables bracing the mast, a small "
            "equipment drum at the platform centre. The tall mast with its three dishes is the read; thin, "
            "delicate silhouette unlike any other structure. Weathering: hull grime, oil stains along the mast "
            "joints, rust streaks, pitted metal. Emissive: exactly one small hot burnt ember C8461B lamp at the "
            "mast top, contained, no ember glow halo.")),
    "outpost_repair": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_outpost_repair",
        subject=env_single(
            "Repair post, a compact small platform about half the footprint of a base. Silhouette: an open "
            "docking cradle with two articulated clamp arms reaching inward, a short tool rack beside the "
            "cradle, a small hangar front with a dark rectangular aperture at the back, hazard-striped landing "
            "pad markings painted on the deck, stubby stabiliser feet. The open cradle with its clamp arms is "
            "the read; the hangar aperture stays dark, no interior light, no warm glow. Weathering: oil stains, "
            "scuff marks, rust streaks, pitted metal. Emissive: exactly two small hot burnt ember C8461B lamps "
            "beside the cradle mouth, contained, no ember glow halo.")),
    # ---------------- wave 2: bodies ----------------
    "body_ice_moon": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_body_ice_moon",
        subject=env_single(
            "Airless ice moon, a dead spherical body seen from above with no atmosphere. Surface: a pale "
            "desaturated ice-crusted crust one value step darker than ships, cracked into polygonal plates with "
            "frost speckle catching the cold steel highlight #565C63 rim along the cracks, ancient impact "
            "craters with raised rims, dirty streaks of grey rock between the ice fields, no blue tint, no "
            "atmosphere, no clouds, no terminator glow, no emissive. The moon surface fills the frame edge to "
            "edge with the round limb of the body visible.",
            cover="70 percent")),
    "body_ore_moon": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_body_ore_moon",
        subject=env_single(
            "Airless mining-scarred moon, a dead spherical body seen from above with no atmosphere. Surface: "
            "dark grey stone one value step darker than ships, cut open by three open-cast mining pits with "
            "terraced benches and spoil ridges of rubble around them, rich ore veins in rusted ochre #6E5B4A "
            "and dry rust #8A6A50 running through the cracked rock, haul tracks scratched into the surface "
            "between the pits, no atmosphere, no clouds, no terminator glow, no emissive, veins do not glow. "
            "The moon surface fills the frame edge to edge with the round limb of the body visible.",
            cover="70 percent")),
    "body_shattered": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_body_shattered",
        subject=env_single(
            "Airless shattered moon, a fractured dead body with no atmosphere. A broken moon mass with deep "
            "dark fissures splitting the crust into large sections, a loose ring of separated shattered chunks "
            "drifting around the main mass with clear dark gaps between them, exposed dark layered rock in the "
            "fracture faces, dust and rubble on the plate surfaces, no atmosphere, no clouds, no terminator "
            "glow, no emissive, everything in the fixed desaturated palette.",
            cover="70 percent")),
    "bg_body_plate": dict(
        family="env", aspect="16:9", mode="single_full", out="env_bg_body_plate",
        subject=(
            "Background body plate, a wide 16:9 painted layer for a space playfield, extremely low contrast. "
            "A huge airless rocky body limb entering the frame from the upper right corner, only its curved "
            "limb and a narrow band of dark cratered surface visible, the rest of the frame is deep dark void, "
            "no atmosphere rim, no clouds, no terminator glow, no emissive, absolutely no surface detail in "
            "the frame centre so gameplay reads on top of it, subtle film grain, desaturated, one value step "
            "darker than ships. " + ENV_NEG)),
    # ---------------- wave 2: panels ----------------
    "panel_boosters": dict(
        family="icons", aspect="1:1", mode="panel_white", grid=(2, 3), sizes=(16, 48, 96, 192),
        cuts=["icon_booster_speed", "icon_booster_damage", "icon_booster_shield",
              "icon_booster_repair", "icon_booster_emp", "icon_booster_teleport"],
        subject=(
            "Icon sheet for ship booster consumables in a grimdark painted sci-fi style, 2x3 grid (icons arranged "
            "left to right, top to bottom), generous even gaps between icons, each icon a single isolated object "
            "centred in its cell, plain solid pure white background. Subjects in reading order: a twin-vent speed "
            "pod with stacked chevron vents; a squared damage amplifier block with a barbed emitter stud; a field "
            "shield emitter with a segmented protective collar; a compact repair bot drone with two small tool "
            "arms and no face; an EMP charge, a capped cylinder with radiating stub antennas; a teleport beacon, a "
            "small tripod beacon with a ring aperture and one tiny burnt ember C8461B lamp. Painted weathered "
            "metal in gunmetal mid #3A3F46, gunmetal dark #2B2F35 and iron black #232629 with cold steel "
            "highlight #565C63 edges and rusted ochre #6E5B4A accents, small and readable at icon size. "
            + ICON_NEG)),
    "panel_status": dict(
        family="icons", aspect="1:1", mode="panel_white", grid=(3, 3), sizes=(16, 48, 96, 192),
        cuts=["icon_status_burning", "icon_status_slowed", "icon_status_disabled",
              "icon_status_shielded", "icon_status_repairing", "icon_status_locked",
              "icon_status_cloaked", "icon_status_radiated", "icon_status_drained"],
        subject=(
            "HUD status effect icon sheet in a grimdark painted sci-fi style, 3x3 grid (icons arranged left to "
            "right, top to bottom), generous even gaps between icons, each icon a single isolated symbol centred "
            "in its cell, plain solid pure white background. Subjects in reading order: a small ember flame bite "
            "on a plate corner (burnt ember #C8461B only as the flame); a chevron chain dragging a weight block; "
            "a cracked lightning bolt inside a hex plate; a domed shield plate in cold steel highlight #565C63; "
            "a wrench crossed over a small pulse ring; a targeting bracket around a hex core with one ember tick; "
            "a shimmering outline with a missing middle section; a hazard starburst inside a ring; a battery "
            "outline with a hollow drained centre. Painted weathered iron black #232629 and gunmetal #2B2F35 "
            "with cold steel highlight #565C63, ember used only on the flame and the single targeting tick, "
            "readable at icon size. " + ICON_NEG)),
    "panel_asteroids_b": dict(
        family="env", aspect="1:1", mode="panel_white", grid=(3, 2), sizes=None,
        cuts=["env_asteroid_b1", "env_asteroid_b2", "env_asteroid_b3",
              "env_asteroid_b4", "env_asteroid_b5", "env_asteroid_b6"],
        subject=(
            "Asteroid sheet, 3x2 grid of six separate asteroid rocks arranged left to right, top to bottom, "
            "generous even gaps between them, each rock a single isolated object centred in its cell, plain "
            "solid pure white background. Reading order: a large elongated cigar-shaped rock; a large twin-lobed "
            "peanut rock; a medium heavily pitted rock covered in deep impact craters; a medium ore-flecked rock "
            "with rusted ochre #6E5B4A veins in its cracks; a small flat shard rock; a small rubble cluster of "
            "fused fragments. All are desaturated gunmetal-grey stone in the #2B2F35 to #3A3F46 range, one "
            "value step darker than ships, with cracked rock faces, iron black #232629 core shadows, speckle "
            "catching the cold steel highlight #565C63 rim, harsh directional key light from the upper left, "
            "subtle film grain, no emissive, no glow of any kind. " + ENV_NEG)),
    # ---------------- wave 2: world object ----------------
    "env_mine": dict(
        family="env", aspect="1:1", mode="single_trim", out="env_mine", cover="40 percent",
        subject=env_single(
            "Deployed space mine, a single small weaponised world object. Silhouette: a spiked spherical mine "
            "with twelve short pyramid spikes radiating evenly, a riveted seam ring around its equator, four "
            "stub detonator caps between the spikes, one small mounting lug where it was released. The spiked "
            "sphere is the read; compact and hostile, clearly smaller than a ship. Weathering: oil stains, "
            "scratches, rust streaks, pitted metal. Emissive: exactly one small hot burnt ember C8461B lamp at "
            "the equator seam, contained, no ember glow halo.",
            cover="40 percent")),
}


def log_run(family, markdown):
    log_path = STAGE / family / "generation_log_phase_e.md"
    log_path.parent.mkdir(parents=True, exist_ok=True)
    if not log_path.exists():
        log_path.write_text(
            "# Phase E - generation log\n\n"
            "Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K. Spec: `docs/design/ASSET_EXPANSION_SPEC_E.md`.\n"
            "Style block: `vajb-orbit/assets/style-block.txt` verbatim, except the two `base_mining` A/B runs "
            "(one uses `staging/phase_e/style-block-alpha.txt`).\n"
            "Alpha: `--transparent` requested; fallback local matte (`staging/phase_d/reprocess.py`). "
            "AI-generated art is not CC0 (AGENTS.md).\n\n---\n\n",
            encoding="utf-8")
    with log_path.open("a", encoding="utf-8") as fh:
        fh.write(markdown)
        fh.write("\n---\n\n")


def trim_to(src, dest, pad=10):
    img = Image.open(src).convert("RGBA")
    bbox = img.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        left = max(0, bbox[0] - pad)
        top = max(0, bbox[1] - pad)
        right = min(img.size[0], bbox[2] + pad)
        bottom = min(img.size[1], bbox[3] + pad)
        img = img.crop((left, top, right, bottom))
    img.save(dest)
    return dest


def cut_size(master, size):
    """Aspect-preserving contain cut for the icon quartet, ICONS_SPEC section 9.6 (F.1).

    The pre-F.1 code stretched the trimmed master to a square, which distorted every
    non-square glyph by up to 2.6x. Kept as a function (not a lambda) so the law has one
    definition per driver; `staging/phase_f/wave_f.py` holds the same rule.
    """
    scaled = master.convert("RGBA").copy()
    scaled.thumbnail((size, size), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(scaled, ((size - scaled.size[0]) // 2, (size - scaled.size[1]) // 2))
    return canvas


def ensure_alpha(master):
    """Return (path, note) with a usable alpha channel; native first, local matte fallback."""
    img = Image.open(master)
    if img.mode in ("RGBA", "LA"):
        alpha = img.convert("RGBA").getchannel("A").histogram()
        total = img.size[0] * img.size[1]
        if alpha[0] / total > 0.10:
            return master, "native-alpha"
    out = Path(master).with_name(Path(master).stem + "-matte.png")
    _, bg, alpha0, _, dropped = matte(master, out)
    return out, (f"local matte bg=#{bg[0]:02X}{bg[1]:02X}{bg[2]:02X} alpha0={alpha0:.0f}% dropped={dropped}")


def load_kg():
    spec_mod = importlib.util.spec_from_file_location("kg", SKILL)
    kg = importlib.util.module_from_spec(spec_mod)
    spec_mod.loader.exec_module(kg)
    return kg


def find_master(spec):
    """Locate this run's own master by matching the prompt stored in job.json."""
    expected = (spec["subject"] + "\n" + STYLE_FILE.read_text(encoding="utf-8").strip()).strip()
    for run_dir in sorted((STAGE / spec["family"]).iterdir(), reverse=True):
        if not run_dir.is_dir():
            continue
        job = run_dir / "job.json"
        if not job.exists():
            continue
        payload = json.loads(job.read_text(encoding="utf-8"))
        if (payload.get("input", {}).get("prompt") or "").strip() != expected:
            continue
        for path in sorted(run_dir.glob("*-1.png")):
            return path
    return None


def split_cuts(source, cuts, grid):
    kg = load_kg()
    got = kg.split_components(Path(source), Path(source).parent, Path(source).stem + "-cut")
    if len(got) != len(cuts):
        print(f"  component split gave {len(got)} of {len(cuts)} cells; using grid cut {grid}", flush=True)
        got = grid_split(Path(source), cols=grid[0], rows=grid[1])
    return got


def run_one(run_id, post_only=False):
    spec = RUNS[run_id]
    family_dir = STAGE / spec["family"]
    family_dir.mkdir(parents=True, exist_ok=True)
    style_file = STYLE_ALPHA if spec.get("style") == "alpha" else STYLE_FILE

    if post_only:
        master = find_master(spec)
        if master is None:
            print(f"[{run_id}] NO MASTER FOUND", flush=True)
            return False
        job_rec = json.loads((master.parent / "job.json").read_text(encoding="utf-8"))
        task_id = job_rec.get("task_id", "?")
        elapsed = "post-only"
        print(f"[{run_id}] post-only master={master}", flush=True)
        payload = {}
    else:
        cmd = [PY, str(SKILL), "--model", "flare", "--prompt", spec["subject"],
               "--aspect", spec["aspect"], "--resolution", "2K",
               "--style-file", str(style_file), "--out", str(family_dir), "--yes"]
        if spec["mode"] == "panel_white":
            cmd += ["--strip-bg", "local", "--bg-color", "FFFFFF"]
        else:
            cmd.append("--transparent")

        print(f"[{run_id}] submitting", flush=True)
        env = dict(os.environ)
        if Path(CA_BUNDLE).is_file():
            env["SSL_CERT_FILE"] = CA_BUNDLE
        proc = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8",
                              errors="replace", env=env)
        if proc.returncode != 0:
            print(f"[{run_id}] FAILED rc={proc.returncode}\n{proc.stdout}\n{proc.stderr}", flush=True)
            return False
        payload = json.loads(proc.stdout)
        master = payload["local_paths"][0]
        if payload.get("alpha_paths"):
            master = payload["alpha_paths"][0]
        task_id = payload.get("task_id", "?")
        elapsed = payload.get("elapsed_s", "?")
        print(f"[{run_id}] ok task={task_id} {elapsed}s master={master}", flush=True)

    notes = []
    finals = []
    mode = spec["mode"]
    if mode == "panel_white":
        # The skill's --strip-bg local does not key these renders (off-white source
        # background); matte the master locally, then split on that alpha.
        source, how = ensure_alpha(master)
        notes.append(how)
        cuts = split_cuts(source, spec["cuts"], spec["grid"])
        if len(cuts) != len(spec["cuts"]):
            print(f"[{run_id}] WARNING expected {len(spec['cuts'])} cuts, got {len(cuts)}: {cuts}", flush=True)
        for cut_path, name in zip(cuts, spec["cuts"]):
            dest = family_dir / f"{name}.png"
            trim_to(cut_path, dest)
            finals.append(dest)
            if spec["family"] == "icons" and spec.get("sizes"):
                img = Image.open(dest).convert("RGBA")
                for size in spec["sizes"]:
                    cut_size(img, size).save(family_dir / f"{name}_{size}.png")
    else:
        source, how = ensure_alpha(master)
        notes.append(how)
        dest = family_dir / f"{spec.get('out', run_id)}.png"
        if mode == "single_trim":
            trim_to(source, dest)
        else:  # single_full
            Image.open(source).convert("RGB").save(dest)
        finals.append(dest)

    job_src = Path(master).parent / "job.json"
    if job_src.exists():
        for path in finals:
            (family_dir / f"{path.stem}.job.json").write_text(
                job_src.read_text(encoding="utf-8"), encoding="utf-8")

    for path in finals:
        img = Image.open(path)
        alpha = img.convert("RGBA").getchannel("A").histogram() if img.mode == "RGBA" else None
        total = img.size[0] * img.size[1]
        cover = f" alpha0={100 * alpha[0] / total:.0f}%" if alpha else " opaque"
        print(f"[{run_id}] final {path.name} {img.size} {img.mode}{cover}", flush=True)

    log_run(spec["family"], (
        (f"## {run_id} - post-only re-run\n\n"
         f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
         f"- Reason: the generator's `--strip-bg local` left the panel background opaque "
         f"(off-white source), so the matte and split were redone locally (free).\n"
         if post_only else
         f"## {run_id}\n\n"
         f"- Date/time: {datetime.now().strftime('%Y-%m-%d %H:%M')} local\n"
         f"- Model: `gpt-image-2-5-flare-text-to-image` (`flare`), 2K, {spec['aspect']}\n"
         f"- Job id: `{task_id}` (elapsed {elapsed}s)\n"
         f"- Style block: `{style_file.name}`\n") +
        f"- Alpha: {', '.join(notes)}; run folder `{Path(master).parent.name}` keeps `job.json`\n"
        f"- Final files: {', '.join(p.name for p in finals)}"
        f"{' (+ 16/48 splits)' if spec['family'] == 'icons' else ''}\n"
        f"- Status: success\n\n"
        f"Full SUBJECT text:\n\n> {spec['subject']}\n"))
    return True


if __name__ == "__main__":
    args = sys.argv[1:]
    post_only = "--post-only" in args
    args = [a for a in args if not a.startswith("--")]
    if not args:
        for key in RUNS:
            print(key)
        sys.exit(0)
    ok = all(run_one(run_id, post_only=post_only) for run_id in args)
    sys.exit(0 if ok else 1)
