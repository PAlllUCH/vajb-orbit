# D11_BRIEF — the space-station scene rework (the owner's O6)

Wave `D11`, slice `D11-station-scene`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder; the folder law; **Asset
   Generation + Phase G lane** — panel order, `flare --post-only`, review-sheet
   → owner approval → ship)
2. `docs/CONTRACTS.md` **§21's O6 row** (the owner's verbatim ask) and §22
   (context: the parallel item-15 proposals — not this lane's)
3. `docs/design/ENVIRONMENT_SPEC.md` **§11** (this wave's pin) + **§1.1/§6**
   (vocabulary + the one-emissive rule) + §8/§9 (plan, negative list)
4. `docs/design/ASSET_NAMING_SPEC.md` + `docs/design/STYLE_BIBLE.md` (palette law)
5. this brief end to end

## Owner request, verbatim

`dispatch_designer.md` item 13 / CONTRACTS §21 O6: **"make space station
bigger with more details (not a single sprite, more static and moving elements,
but the main sprite should be much bigger as well)."**

**The mockup gate is the point:** A0 stops at the review sheet; nothing
renders, ships or wires before the owner approves the mockup (D7's loop,
"Looks good. lets do this").

## What is already measured (file:line)

- `game/sector.gd:54-57` — `StationTexture := preload("res://assets/env/poi/
  env_station.png")`; one `Sprite2D` at `STATION_SCALE`, ~67.9 u half-extent
  (`:71`), described by `ASSET_WIRING_HANDOFF` §2 as "roughly 2× hull scale".
- `sector.gd:_spawn_station` — the sprite, then the **DockZone as a sibling**
  Area2D with `DOCK_RING_RADIUS` in world units; the comment at `:62-64`
  records why a collision child under the 0.0663-scaled sprite would shrink to
  ~8 u. The sprite joins `&"station"`; `blips()` and the dock checks key off
  the groups.
- `ENVIRONMENT_SPEC §6` — the dockable station's own art law: welded
  platework, gunmetal mid/dark, grime/rust, **ember warning lamps are the only
  emissive**; §1.1 keeps environment one value step darker than ships.
- The parallel lane: coder item 14 (S8) holds every `game/` file **except**
  `sector.gd`/`station_scene.gd` and all `tests/test_s8_*`; both lanes run the
  shared gate — attribute the other lane's mid-wave rows, never fix them.

## The pinned interface (ENVIRONMENT_SPEC §11 is the source of truth)

```gdscript
# game/station_scene.gd — NEW file (the owner's grant; class_name StationScene extends Node2D):
#   setup(hero: Texture2D, elements: Array[Dictionary]) -> void   # builds the tree
#   # Motion constants, proposed (each reversal = the element stands still):
#   const STROBE_PERIOD := 1.2     # approach beacon strobe, seconds
#   const SHUTTLE_SPEED := 30.0    # u/s along the approved path
#   const SLEW_RATE := 4.0         # degrees/second, crane/turret slew
#
# game/sector.gd:_spawn_station — the swap: the composed scene replaces the
#   single Sprite2D. INVARIANTS (violation = defect, no tick): the node keeps
#   `&"station"`, keeps the placement centre, and the DockZone stays a SIBLING
#   with its world-unit radius (the :62-71 rule). Hero scale = the approved
#   mockup's pin (proposed floor: >= 2.2x today's footprint; reversal:
#   STATION_SCALE as shipped).
```

Rules that fix every ambiguity:

- **Approval before pixels:** A0's review sheet is a hard stop; re-renders after
  approval that change layout need a second sheet (D7's A1/A2 precedent — each
  pass gets its own `build_review` page and QC log).
- **Panel order is law** (AGENTS Phase G): render → `panels.py --detect` → cut
  each object → key each → trim; `flare` never returns native alpha →
  `--post-only`; 2K = 10 credits = $0.05, the wave's art ≈ **$1–2** (hero +
  element sheet passes) against a review sheet per pass.
- **The one-emissive rule survives:** no new glow beyond §6's ember lamps;
  strobes and shuttles use palette colours, not bloom.
- **Moving elements are code**, not sprite sheets: paths/constants live in
  `station_scene.gd`; no new `Timer` nodes (17 §4's one-timer law is
  respawn bookkeeping and is untouched).
- **Files nobody else holds:** S8's sets are disjoint and enumerated in
  `SLICE.md`; `ui/**` stays out entirely (D7/D6's wake), `project.godot` and
  `docs/` outside this wave's own stay out.
- Bucket ladder: mechanism = worker; pin/number/docs = orchestrator/developer;
  taste = the mockup gate + owner ticks.

## Worker table and run order

| ID | Role | Deliverable |
|---|---|---|
| D11-A0 | mockup + plan (**STOP**) | `staging/mockup/station_mockup.py` + `out/station_mockup_v1.png/.jpg` (hero footprint ≥2.2×, element layout, motion paths), the element render plan (names per §11, cell/panel plan), one review sheet — **hand to the owner and stop** |
| D11-A1 | renders (after approval) | hero + element sheets through the panel-order pipeline, QC (containment/alpha/negative list), ship to `assets/env/poi/`, generation log, import settings (mipmaps/lossless, 3D detection off), reimport |
| D11-C1 | wiring | `game/station_scene.gd` (tree + the three proposed constants + `_process` motion) + the `_spawn_station` swap honouring every invariant; pre-grep `tests/` for rows pinning `STATION_SCALE`/`env_station`/the old sprite and disposition any hit **before** editing (report, don't weaken); `tests/test_d11_station.gd` (AC3/AC4) |
| D11-R1 | mandatory review | re-measure AC1–AC7 (W8 method), tier findings, LOW rows (read next free from the file), CONTRACTS §9/§10 (next free row, **sequenced after S8's**) |
| D11-F1 | fixer (HIGH/MED only) | named fixes + the gate |

**Run order: A0 → OWNER APPROVAL → A1 → C1 → R1 → (F1 only on HIGH/MED).**

## Tests that move

Expected: **none.** C1's pre-grep (`STATION_SCALE`, `env_station`,
`StationTexture`, the `&"station"` group) names any row that pins the old
single sprite; a hit is dispositioned in C1's report and ratified before the
edit (S6's `test_engine2_wiring` precedent). The group/DockZone invariants mean
`test_s6_*` dock/blip rows must stay green untouched — they are the guard.

## Hard rules

- Write sets exactly as `SLICE.md`; `.agents/` reports always allowed; no bash
  file edits. The `game/sector.gd` + `game/station_scene.gd` grant is the
  owner's, carried by this dispatch's handoff — two files, one function each
  side (`_spawn_station`); anything more is a report.
- No S8 files, no `ui/**`, no `project.godot`, no `docs/` beyond
  ENVIRONMENT_SPEC §11's own future ticks (its amendment is already landed) and
  R1's §9/§10.
- Every probe/gate on a scratch store; the live `user://` is the owner's.
- If a pinned number seems wrong: report it, leave it. Taste goes through the
  mockup gate, not around it.

## Staged / deferred

`env_base_*`/`env_station_mmo` variants stay parked (the naming-overhaul
block); §6's "hostile station" wording is not this wave's to fix; the
`validate_names --library` pass stays host-deferred (L147 class); the old
`env_station.png` stays on disk as provenance.

## Owner ticks owed after this wave

1. **The mockup approval** (the A0 stop — layout, hero footprint, which
   elements move).
2. **The hero scale as approved** (proposed floor 2.2×; reversal:
   `STATION_SCALE` shipped).
3. **The element inventory** (≥6 static + ≥3 moving proposed; reversal: drop to
   zero).
4. **The three motion constants** (`STROBE_PERIOD` 1.2 / `SHUTTLE_SPEED` 30 /
   `SLEW_RATE` 4; reversal: stand still).
5. **The `game/` grant** — ratified by pasting the handoff (sector.gd +
   station_scene.gd, one function each; S6-K3 precedent).

## Close-out (the orchestrator runs these, in order)

1. Gate **twice** on scratch stores:
   `source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot --headless --path
   vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` → identical
   counts, `753 + test_d11_station`, 0 failed once both lanes settle; live
   md5s unchanged; the parallel S8 lane's rows attributed, never fixed.
2. Verify:

   ```bash
   python3 staging/verify_wave.py verify --baseline d11_start \
     --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
       docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md \
       docs/gameplay/04_refinery.md docs/design/ENVIRONMENT_SPEC.md \
     --tests \
     --expect-reports .agents/gen/slices/D11-station-scene/D11-A0_report.md \
       .agents/gen/slices/D11-station-scene/D11-R1_review.md
   ```

   (CONTRACTS deliberately not forbidden — R1's own §9/§10 writes it; D7's
   brief made that mistake.) A parallel-lane forbidden hit is accepted with
   attribution, never reverted (L157/L167 class).
3. R1 updates §9 + §10 with the **next free** changelog row (read the file at
   close-out — S8's v0.20 may already be taken) and appends LOW rows at the
   **next free ids read from `LOW_BACKLOG.md`** (L167's lesson: reserve
   nothing while a lane runs parallel).
4. WAVEBOARD: D11 row closed with numbers, owner ticks recorded.
5. Wave-boundary commit (untracked strays excluded).
