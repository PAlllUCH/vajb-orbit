---
slice: D11
worker: D11-A0
model: mimo-v2.6-flash
status: complete (v2 mockup; STOP for owner approval per D11_BRIEF)
gate: "none owed (A0 holds no game source; nothing rendered, 0 paid calls)"
---

# D11-A0 report — station mockup + element render plan (STOP for owner approval)

## Result
All deliverables are done at **v2**; the gate stands (A0 rendered 0 = $0.00; ceiling A0+A1 ≤ $1.50).
`staging/mockup/station_mockup.py` renders the geometry spec below verbatim to
`staging/mockup/out/station_mockup_v2.png` + `.jpg` (3455x2660, 3 px/u = the 2x sheet: today's station
art in place as the much-bigger main sprite at footprint x 2.2 with the 6 static kinds composed
onto/around it, the 3 moving kinds' paths, the DockZone ring + spawn arrow) and bakes the owner sheet
at **`staging/phase_g/_review/d11_mockup.png`** (1600x2473: pins + both v2 revisions, the mockup, the
15-row plan table as text, totals + owner ticks). Render plan unchanged (15 files = 150 cr = **$0.75**);
no paid renders, no `game/`/`docs/` writes; nothing ships before owner approval (v1 pair kept).

## Owner feedback on v1 (verbatim) and its disposition
> "Okay but i wanted to implement the currect space station into new composition (as spawnpoint) not next to it. Everythin else looks good."

Disposition — both revisions applied in v2, nothing else moved:
1. **The composition IS the current station:** `env_station.png`'s design language (hull silhouette,
   welded platework, window bands, gunmetal palette) is the much-bigger MAIN SPRITE (frame 298.8 u)
   with the 6 static kinds composed onto and around it — not a new object beside today's station. The
   scale comparison is a caption + a true-scale steel square only (today ~67.9 u half / 135.8 u frame
   vs 298.8 u); the spawn arrow and DockZone ring mark the dock as today — it stays the spawnpoint.
2. **Strobe lane re-spaced to 55 u dot spacing** (the orchestrator's ruling on this report's 45-vs-55
   flag: §11's "55 u apart" text is the pin; the drawn 45 u was wrong) — dots are now `160/215/270/325/380`.

Everything else stays EXACTLY as approved: hero footprint x2.2 = 298.8 u frame, 6 static kinds / 12
instances, 3 moving kinds, STROBE_PERIOD 1.2 / SHUTTLE_SPEED 30 / SLEW_RATE 4, the 15-row render plan at 150 cr = $0.75.
Jump gates asked in the same breath are a separate queued wave, not this one. A0 stops again: the owner approves the v2 sheet before A1.

## Proposed pins for the owner's ticks (AC7) — final; v2 changed no planned number
- **Hero scale = today's footprint x 2.2** — frame `298.8 u` across (half `149.4`), effective
  `STATION_SCALE 0.0663 x 2.2 = 0.1459`. Today's footprint pin `135.8 u` (half `67.9`,
  `sector.gd:71`); pin is `>= 2.2x` (ENVIRONMENT_SPEC §11), **reversal:** `STATION_SCALE` shipped.
- Measured today: file `2060x2073 px` (`sector.gd:61` says 2048x2048, +0.6 % — report-only), alpha
  content bbox `(127,129,1934,1944)` → trim `87.7 %`, visible hull `119.1 u` (half `59.5`). Same
  trim on the hero → visible hull `261.9 u` (half `131.0`) = `2.20x` today's visible hull.
- **Ring flag (owner tick):** shipped `DOCK_RING_RADIUS 120` (`sector.gd:73`) falls `11.0 u` inside the hero hull at full trim.
  **(B, proposed):** ring `175 u` = hull `131.0 + ship half 29.5` (hull len `59.0 = 135.8/2.3`, `sector.gd:63`) `+ 14.5 margin`
  — **reversal:** `120`; it sits outside C1's `_spawn_station` grant, so B needs its own ratification. **(A):** trim hero
  to `<= 116 u` half (77.6 %) keeps `120`; visible hull drops to `1.95x`.
- **Inventory:** static x6 kinds / 12 instances — docking-arm trusses x2, antenna/mast clusters x2, gantry
  cranes x2, lit-window bands x2, hull-plate spines x2, ember lamp runs x2 (the ONLY emissive); moving x3
  kinds — approach strobe positions (5), shuttle loop (2 shuttles), crane slew arc (1 pivot). Reversal: drop
  any kind to zero.
- **Motion constants:** `STROBE_PERIOD := 1.2` s · `SHUTTLE_SPEED := 30.0` u/s · `SLEW_RATE := 4.0`
  deg/s — code in `station_scene.gd`, no new `Timer`; reversal: stand still.

## Mockup geometry spec v2 (source of truth for the rebuild; cockpit-mockup idiom, 3 px/u = 2x sheet)
- ONE composition, no second station: canvas `3455x2660 px`, hero at the placement centre (world x `0`),
  content band `y -300..+450 u`; scale = header caption + true-scale steel square `±67.9` on the art;
  DockZone ring solid steel `r=120` (dark backing), ring B ember-dashed `r=175`, spawn arrow
  `(0,120)->(0,420)` (`PLAYER_SPAWN_OFFSET 300`, `+Y`). Main sprite: `env_station.png` full-bleed into
  the `298.8 u` frame (dashed `±149.4`; content dashed `±131` = 87.7 % trim), today's design language, with the 6 static kinds composed onto/around it.
- Static placement (hero-relative u): arms `y=0`, tips `±193`; masts at corners `(-113,-113)` and
  `(113,113)` to tips `∓147`; gantry_a top rail `x -95..-15`, body `y -157..-137`, jib to `-197`;
  gantry_b pivot `(62,-131)`; window bands `y=-52 / +52`, `x -85..+85`; plate spines `x=-107 / +51`
  (22 u wide, full height); lamp runs `y=±123`, `x -100..+100` step 20 (11 lamps each).
- Moving paths: strobe lane `x=0`, dots `y=160,215,270,325,380` (55 u apart), dashed to `410` + spawn ref
  `420`; shuttle loop rounded rect `l-255 r+340 t-225 b+190 corner90` → path `1866 u`, lap `62 s`,
  2 glyphs; gate arrow `+X` `215..470` with break, labelled `GATE 900 u (_gate_bearing(dest),
  sector.gd:96,581)`; slew arc r`42` around `(62,-131)`, `-150°..-30°` (=±60°, 30 s at 4°/s).
  Annotations: steel = shipped, dim dashed = art content, ember = motion + proposals (canvas legend = inventory, constants and ring A/B choice).

## Implementation notes (report-only; no pin or spec number changed)
- **Strobe spacing (bucket 2, resolved):** §11's "55 u apart" text is the pin; v1's drawn `370`
  left a 45 u last gap — wrong. v2 draws `380`; the flag is dispositioned above, A0 wrote no docs.
- Illustrative only, NOT pins: today's art shown enlarged in place (A1's hero render carries the same
  design language), gantry_a legs to reach the hull (pinned body y -157..-137), label/leader placements
  and annotation crossings — every pinned number appears in full in the legend and on the sheet.

## Element render plan (task 2; §11 naming with `_*` resolved to `_a`/`_b`)
Every row: **2K 1:1 panel, 1 object per panel (keyed Void Black→transparent), 1 cell, no grid**; panel
order is law — render → `panels.py --detect` → cut → key → trim; `flare --post-only`; 2K run = 10 credits = $0.05.

| file | subject (ENVIRONMENT vocabulary, verbatim terms) | run x cr |
|---|---|---|
| `env_station_hero.png` | top-down station hero: welded platework in gunmetal mid/dark, panel seams + rivet lines, heavy hull grime films, rust streaks from seams and rivets, pitted metal, cold steel rim, one value step darker than ships; ember warning lamps the ONLY emissive (Burnt Ember points, no halo) | 1x10 |
| `env_station_arm_a.png` | truss docking arm of welded platework in gunmetal mid/dark, weld beads over the joints, hull grime, rust streaks from the seams, cold steel rim; no emissive | 1x10 |
| `env_station_arm_b.png` | same subject as `arm_a` (distinct weathering pass) | 1x10 |
| `env_station_mast_a.png` | antenna/mast cluster on a welded platework base, gunmetal mid/dark, hull grime, rust streaks at the foot, cold steel rim; no emissive | 1x10 |
| `env_station_mast_b.png` | same subject as `mast_a` (distinct weathering pass) | 1x10 |
| `env_station_gantry_a.png` | rail gantry crane of welded platework in gunmetal mid/dark, heavy hull grime along the rail, rust streaks at the wheels; no emissive | 1x10 |
| `env_station_gantry_b.png` | same crane on its slew pivot (pivot plate + counterweight jib), welded platework gunmetal mid/dark, grime, rust streaks at the pivot; no emissive — rotates in code | 1x10 |
| `env_station_windows_a.png` | band of lit hull windows painted pale steel-highlight on gunmetal mid/dark plating, grime around the frames, rust streaks below the sills; no emissive (painted light only) | 1x10 |
| `env_station_windows_b.png` | same subject as `windows_a` (distinct weathering pass) | 1x10 |
| `env_station_plate_a.png` | raised hull-plate spine: welded platework seams and rivet lines in gunmetal mid/dark, hull grime film, rust streaks bleeding from the rivets; no emissive | 1x10 |
| `env_station_plate_b.png` | same subject as `plate_a` (distinct weathering pass) | 1x10 |
| `env_station_lamp_a.png` | run of ember warning lamps: small hot Burnt Ember points on a gunmetal dark strip, rivets + grime; ember warning lamps the ONLY emissive, no halo beyond the points (§6 exception) | 1x10 |
| `env_station_lamp_b.png` | same subject as `lamp_a` (distinct lamp spacing) | 1x10 |
| `env_station_shuttle_a.png` | top-down service shuttle, gunmetal mid/dark hull with cold steel rim, hull grime, rust streaks on the aft plating; no emissive (engines stay dark — palette-lit only) | 1x10 |
| `env_station_shuttle_b.png` | same subject as `shuttle_a` (distinct weathering pass) | 1x10 |

**Totals: 15 files, 15 runs, 150 credits = $0.75; A0 renders 0 = $0.00; ceiling A0+A1 <= $1.50.**
Moving elements need NO new file: strobes reuse `env_station_lamp_*` toggled in code; the slew rotates
`env_station_gantry_b`. Style source: `vajb-orbit/assets/style-block.txt` verbatim preamble per §8; generation log beside the family at ship (A1); AI art is not CC0.

## Evidence
- `python3 staging/mockup/station_mockup.py` → `wrote staging/mockup/out/station_mockup_v2.png + .jpg (3455x2660)`
  and `wrote staging/phase_g/_review/d11_mockup.png (1600x2473)`; labels checked at native resolution; pixel checks:
  steel square ±67.9, ring A solid r=120, all 5 strobe dots at 55 u steps.
- Geometry pins read: `sector.gd:54-77,96`; ENVIRONMENT_SPEC §11/§1.1/§6/§8/§9; CONTRACTS §21 O6; `env_station.png`
  measured `2060x2073 RGBA`, alpha bbox `(127,129,1934,1944)` as above.

## Files touched
- `staging/mockup/station_mockup.py` — mockup script + review-sheet builder (new);
  `staging/mockup/out/station_mockup_v2.png` / `.jpg` — mockup pair at 3455x2660 (v1 kept);
  `staging/phase_g/_review/d11_mockup.png` — owner sheet refreshed to v2; this report updated.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Ring choice A vs B (and ratifying B's const if picked) | owner tick | this report §Proposed pins + the sheet |
| Owner approval of the v2 sheet, then A1 runs | mockup gate | `staging/phase_g/_review/d11_mockup.png` |
