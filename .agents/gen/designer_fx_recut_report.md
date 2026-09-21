# FX re-cut report — 2026-09-21

Owner brief, in order: "i want all fx to have at least 4 frames like explosion"; "first split the
pane ones, remove background and put them back in assets/fx"; "all cuts from pane need to be added
to project like transparent or do needed changes to make them working in game"; "give a review
sheet before deploy"; and, at the end, "if its slightly transparent and near black background
propably not visible in game".

## What shipped

`staging/cut/ship_fx.py --apply` → **122 files** into `vajb-orbit/assets/fx/`
(`staging/cut/_fx_ship_report.json` is the per-file record: source, destination, md5, replaced
state). Every one is RGBA.

| Group | Count | Route |
|---|---|---|
| Split frames of the eight existing sheets | 25 | luminance key (`staging/cut/key_luminance.py`) |
| Cycle frames of 21 new four-frame sheets | 92 | matte for the 14 solid-object effects, luminance for the rest |
| The four alpha masters (`fx_smoke_plume`, `fx_acid_burn`, `fx_dust_streak`, `fx_hull_critical_vignette`) | 4 | matte, except the vignette (luminance — the matte kept 99.7 % of the frame) |
| `fx_mine.png` (new, L58) | 1 | matte |

**Every FX the game draws now has four or more frames**: 29 effects, explosion 5, `fx_laser_bolt`
4 (light bright/dimming, medium bright/dimming), everything else 4. Verified on disk:
`fx files: 146, RGBA: 122, effects with frames: 29, effects with <4: []`.

## How a frame is cut

`staging/cut/split_fx.py`, in this order (each step exists because a simpler one failed on a real
render):

1. **Objects by ink**, never by cutting on a divider. Components are labelled on an 8x block
   reduction and re-measured at full resolution; the nominal grid only decides which cell a
   component belongs to.
2. **Grain is not an effect.** A per-component area floor (80 px, scaled against the cell's own
   biggest component) drops the starfield specks; without it a 44 px speck stretched
   `fx_mining_beam`'s first cell to 1263 px of empty black.
3. **The spec owns the frame count**: the first N cells in reading order that hold ink. A cell
   under 100 ink px gets a second pass with a 12 px floor, so a spec'd frame that is "nearly
   empty" (the fourth chip-spark release frame) is still that frame.
4. **Object mask** (14 grey levels, 4 px per block, grown 16 px): the generator draws a faint dark
   card behind some effects, and no key can tell that card from background.
5. **Shared canvas per sheet**, object centred, so relative size within a sequence survives.
6. **Key**, then **defringe** (`staging/cut/defringe_alpha.py`): the semi-transparent band takes
   the nearest opaque pixel's colour, so a MIX draw fades out in the effect's own colour instead
   of into black.

## Measurements

- **`fx_laser_bolt`** (L57): v1 objects measured 16.4:1 and 9.4:1; `fx_laser_bolt_v2` cuts to
  3.2:1 and 6.4:1, and `fx_laser_bolt_v3` is the four-frame sheet that shipped.
- **`fx_mining_beam`** (L52/L65): v1's cells resolve 29 248 / 12 116 / 2 379 / 467 ink px (the
  fourth is grain); `fx_mining_beam_v2` resolves four real cells and cuts to four frames.
- **QC**: `staging/cut/qc_fx_alpha.py` (box containment, enclosed transparency, inverted matte)
  passes on every shipped frame; `staging/cut/verify_fx_alpha.py` (deepseek-chat vision, majority
  of three reads) passes **23 of 34** sampled frames. The 6 it still flags are the dim/dark
  effects whose soft band keeps a few percent of alpha over near-black pixels — the owner's
  ruling was that this is not visible in game, so it is recorded rather than chased further.
- **Gate**: `[SUMMARY] passed=307 failed=0`, unchanged from before the ship (no code changed).
- **Review sheets**: `staging/cut/_fx_review/fx_deploy_all.jpg` (the four alpha files, route per
  file), `fx_new_all.jpg` (regenerated mining/bolt sheets and the mine), `panes_page1..6.jpg`
  (every pane's frames as they ship, on magenta), `fx_alpha_all.jpg` (both keying routes).

## Routes, and why

| Route | Used for | Reason |
|---|---|---|
| `recraft/remove-background` (paid) | the solid-object effects: smoke, acid, dust, mine, cargo pulse, dash charge, ember pulse, both ember rings, jump portal, lock channel, repair pulse, shield ripple, anomaly shimmer | a dark mass must stay opaque; the luminance key turns it into a hole |
| `staging/cut/key_luminance.py` (free) | the pure-light effects: explosion, muzzle flash, missile trail, shield break, arc, secondary explosion, mining chip sparks, laser bolt, anomaly rift/grave glow, bio plasma, EMP arc, engine trail, tractor beam, and the hull-critical vignette | the effect's own brightness *is* its opacity on void black; the paid matte keeps fringes and boxes on these, measured on `fx_arc_spark`, `fx_missile_trail`, `fx_shield_break` |

## Spend

| Item | Calls | Cost |
|---|---|---|
| 22 cycle sheets + 3 re-cut masters (`gpt-image-2-5-flare-text-to-image`, 2K) | 25 | ~125 credits ≈ $0.63 |
| recraft matte on frames and the four alpha masters | ~150 across the iterations | ~$0.75 |
| deepseek-chat vision verification | ~150 small reads | < $0.05 |

## Open items

1. **Swap the v1 masters** (`fx_laser_bolt.png`, `fx_mining_beam.png`) for their v2/v3 art —
   owner routed this to the coder lane: `projectile.gd`'s `SHEETS`/`FEEDBACK` region tables were
   measured against v1, so the swap is a wiring change first. Both v2 masters and every frame are
   on disk, staged and shipped.
2. **Wiring the frames** is the coder lane's (the WAVEBOARD's slice-2.5 S3 was paused for this
   re-cut). The frames are named `fx_<effect>_f1.._fN.png` per FX_SPEC §3, all RGBA, each sheet's
   frames sharing one canvas, so `Fx.scale_for(frame_size, world)` reads one size per sequence.
3. **Doc ticks done**: FX_SPEC §0.1 (alpha carve-out), §2 (split to files), §3 (frame names),
   §7.2 (the mine row and the four-frame amendment naming the rows it supersedes), and
   `AGENTS.md`'s two "never key FX" lines.
4. The backlog's remaining items are unchanged and listed in `.agents/gen/designer_generation_backlog.md`
   (§1 items 1, 2, 5; §2 items 6–8, 10, 11; §3 items 12–14).
