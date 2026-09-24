# D6_BRIEF — Cockpit instruments (cluster + ship status screen)

Wave `D6`, slice `D6-cockpit-instruments`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder in the format rules; the folder law)
2. `docs/design/UI_SPEC.md` **§3.7** and **§3.8** (this wave's pins), then
   §3.1/§3.1b/§3.6 (the rules reused verbatim) and §1 (tokens)
3. `docs/design/UI_CHROME_ASSETS_SPEC.md` **§11** (assets, per-run prompts, digit QC)
4. `docs/design/ASSET_NAMING_SPEC.md` §11 (the `ui_seg_*` ruling)
5. `docs/CONTRACTS.md` **§18** (seams) and §7 (the frozen HUD API this wave adds to)
6. this brief end to end

## Owner findings, verbatim (2026-09-23)

1. "With current graphics lane i want to implement speedometer and come kind of a
   compass made in sprites. look how no mans sky looks. 7 segment displays which
   get filled with numbers for speed, hull life, shield, % of fuel and energy. all
   in one nice looking cockpit menu at bottom left maybe."
2. "maybe also computer screen with current ship layout/damaged modules somthing
   like this."

The NMS reference is **mood and layout only** (dial + compass + segmented
readouts gathered in one bottom-left cluster). The STYLE_BIBLE fixed palette and
its one-accent law win every conflict — see owner tick 1.

## What is already measured (file:line)

- `vajb-orbit/ui/hud/hud.gd:593-605` — `_build_speedometer` already builds the
  120×120 dial into `CanvasLayer/BottomLeft/Blocks` (the column below the ammo
  panel). `hud.gd:588-592` carries its own report of the spec's
  bottom-centre-vs-bottom-left discrepancy — **this wave resolves it bottom-left**.
- `vajb-orbit/ui/hud/hud.gd:419-427` — `set_speedometer(ratio, prograde, heading)`;
  `game.gd:_push_speedometer` feeds the **actual velocity** as `prograde` and
  `Vector2.RIGHT.rotated(rotation)` as `heading` (CONTRACTS §7). So the cluster
  needs no new feed: speed u/s = `prograde.length()`, bearing = `heading.angle()`.
- `vajb-orbit/ui/hud/hud.gd:290-293` — the four pool handlers are already wired;
  `vajb-orbit/game/player_state.gd:24-29` declares `hull/shield/energy/fuel_changed
  (current, maximum)` and `player_state.gd:71-109` holds the pools. `set_pool` is
  frozen API (CONTRACTS §7).
- `vajb-orbit/tests/test_engine2_hud.gd:188-237` — the five §3.6 rows that pin the
  gauge contract: 120×120 `custom_minimum_size`, `SEGMENTS` 10, `SWEEP` = 1.5π,
  `OVERDRIVE` 0.9, the `filled_segments` map (0.0→1, 0.05→1, 0.55→6, 0.95→10,
  1.0→10), `overdrive_segment` (9 at 0.95, −1 at exactly 0.9), `needle_colour`.
  **All five stay green unmodified.**
- `vajb-orbit/ui/station/repairs_panel.gd:39,289-296` — the damaged-side suffix
  rule (`_side.png` → `_damaged_side.png`, intact when no damaged cut exists on
  disk). The status screen reuses this rule as-is.
- **There is no per-module damage model in the sim** (measured 2026-09-23:
  `game/` and `autoload/` carry hull/shield points only; `repairs.gd:64-91` reads
  hull/shield pairs; no module condition field exists anywhere). The status screen
  therefore lists modules and their powered state; per-module damage is staged
  (owner tick 5).
- S5 (in flight) adds `ShipFit.HARDPOINTS` (CONTRACTS §17, 09 §11). Consume it
  read-only behind a `has()` guard — do not wait on it and do not write it.

## The pinned interface (CONTRACTS §18 is the source of truth; nothing here may drift)

```gdscript
# D6 — cockpit instruments. Additive to §7: every frozen method survives as-is,
# and NO new feed is introduced — the cluster derives everything HUD already gets.
#
# ui/hud/cockpit_cluster.gd — class_name CockpitCluster extends Control (new file,
# built in code by hud.gd in the §7 inner-widget idiom; hud.tscn stays untouched).
# Read-backs (the probe precedent):
#   cockpit() / compass() -> Control
#   compass_heading() -> float        # 0..359 as drawn
#   readouts() -> Dictionary          # {spd, hull, shield, fuel_pct, energy_pct},
#                                     # each the clamped int the digits show
# §3.6's Speedometer contract survives BYTE-IDENTICAL (test_engine2_hud.gd:188-237
# unmodified): SEGMENTS 10, SWEEP 1.5*pi, OVERDRIVE 0.9, 120x120, filled_segments(),
# overdrive_segment(), needle_colour(). Only its _draw surface changes: the painted
# ui_gauge_face/ui_gauge_needle sprites sit under the marks; the segment fill, the
# prograde needle and the heading tick stay code-drawn in their theme tokens.
#
# ui/hud/ship_status_screen.gd — class_name ShipStatusScreen extends Control (new).
# Toggled by &"ship_status" behind InputMap.has_action (the project.godot row is
# orchestrator-applied at close-out — workers never touch project.godot).
# Reads only: resolved_fit + set_hull_slots cells, ModuleCatalog names, the fitting
# panel's own power arithmetic (cite the reused expression in the report), the
# repairs-panel damaged-side suffix rule, and ShipFit.HARDPOINTS markers behind
# ShipFit.HARDPOINTS.has(hull_id). Writes nothing.
```

Rules that fix every ambiguity:

- **Digit semantics** (UI_SPEC §3.7): SPD = `int(round(prograde.length()))` u/s,
  3 cells, clamp 0..999. HULL / SHLD = `int(round(current))` points, 4 cells,
  clamp 0..9999 (owner tick 3 flips these to %). FUEL / ENRG =
  `int(round(100 × value / maximum))`, clamp 0..100, 3 cells + the `%` cell lit.
  HDG = `int(round(rad_to_deg(heading.angle())))` mapped into 0..359, 3 cells.
  All rows right-aligned with **leading blanks** (`ui_seg_blank`), never leading
  zeros. `maximum == 0` reads 0.
- **Danger rows** (reusing §3.1/§3.1b verbatim as row treatments): hull < 25 % →
  row label `accent_danger_bright` + a script-drawn 1 px `accent_danger` frame on
  the row; fuel ≤ 15 % → label `accent_danger` + the frame; fuel == 0 → frame
  `accent_danger_bright` (the existing `EMERGENCY FLIGHT` banner is untouched).
  Overdrive (`ratio > 0.9`, strict — at exactly 0.9 nothing is in overdrive): the
  needle modulates `accent_danger_bright` and the SPD row gets the frame.
  **Digits themselves never recolour** — textures stay palette-neutral (§3.2's
  precedent).
- **Compass**: the rose rotates `-heading.angle()`; the lubber triangle is fixed at
  top. No cardinal letters (UI_CHROME §1.7 no-text law) — staged with the owner.
- **Status screen**: 720×520 centred modal (owner tick 4), `ui_cockpit_frame`
  nine-slice; left = side render at 320 px with the damaged-cut swap (the
  repairs-panel rule, nothing invented); right = the slot grid on the shipyard
  plate recipe with each fitted module's glyph + cell ref; footer = HULL/SHLD
  `cur / max` and POWER draw / capacity from the fitting panel's own arithmetic.
  Close via the toggle action or the `icon_close` button. Esc stays Pause-only
  (MENU_FLOW §3.9). Hidden while docked, like the gauge.
- **Cluster box**: 404×216 (owner tick 2); left bay = the unchanged 120×120 gauge,
  middle bay = 96×96 rose + HDG row, right bay = the five readout rows. Reversal:
  340×184 compact.
- **Route is yours** (bucket 1): inner class vs sibling file for the widgets,
  sprite loading idiom, digit-row node shape — anything inside the pinned
  acceptance. What is NOT yours: any number above, any `game/`/`autoload/`/
  `project.godot`/theme write, any existing test's expectations.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| D6-M0 | sprite generation + cut/key/trim + digit QC | `staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/` | the 18 masters + panel provenance + `D6-M0_report.md` + review sheet (STOP) |
| D6-M1 | instrument cluster | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `test_d6_cluster.gd` + `D6-M1_report.md` |
| D6-M2 | ship status screen | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `test_d6_status.gd` + `D6-M2_report.md` |
| D6-R1 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/` | `D6-R1_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| D6-F1 | fixer | union of M0–M2 sets | only if R1 leaves HIGH/MED |

**Run order:** M0a (generate → stage → digit QC → review sheet) → **STOP, owner
approves the sheet** → M0b (ship → editor reimport) → M1 → M2 → R1 → (F1 only on
HIGH/MED). M1 before M2 (both hold `ui/hud/` and `hud.gd`); M2's hardpoint
markers are a guarded read of S5-J4's table and never block on it. Each builder
writes only its own `test_d6_*.gd`.

**Parallel safety with S5 (coder item 11, in flight):** this wave writes
`ui/hud/**`, `assets/ui/**`, `assets/icons/**` provenance panels, `staging/**`,
`asset-library/**` and `tests/test_d6_*.gd` only. S5 holds `ui/station/**`,
`ui/screens/station.gd`, `game/**`, `autoload/**`, `docs/CONTRACTS.md` and the
`test_s5_*.gd` names — **the sets are disjoint**. Shared surfaces: the `tests/`
dir (file names disjoint) and gate runs (run them bound, scratch stores, and
editor reimports only in quiet windows between S5 gate runs; one editor session).

## Tests that move, and why

- **None of the existing counts move.** `test_engine2_hud.gd`'s five §3.6 rows
  (188-237) stay byte-green because the gauge contract is pinned byte-identical;
  `test_engine2_wiring.gd`/`test_slice2_5_feel.gd` read `speedometer_ratio` and are
  untouched.
- New: `test_d6_cluster.gd` (the readouts map incl. clamps and blank padding, the
  danger-row rules, the overdrive strict boundary, compass rotation + heading map,
  the §3.6 rows re-asserted through the cluster) ≈ 12 assertions groups;
  `test_d6_status.gd` (toggle guard with no input row present, fit/grid rendering
  from a seeded profile, the damaged-side swap, the no-write proof) ≈ 10 groups.
- Expected gate: S5's close figure (its brief projects 524 → ~565) **plus ~22**;
  the measured number at close-out goes into CONTRACTS §9.

## Hard rules

- Frozen for workers: `project.godot` (the `ship_status` row is orchestrator-applied
  at close-out, proposed key **U** — the `weapon_6`/`weapon_7` precedent),
  `docs/gameplay/18_engine_spec.md`, `docs/gameplay/08_ship_slots_modules.md`,
  `docs/CONTRACTS.md`, `vajb-orbit/addons/`, `vajb-orbit/ui/theme/vajb_theme.tres`,
  and **all of `game/` and `autoload/`** — the wave introduces zero sim feeds.
- `assets/` writes are confined to `vajb-orbit/assets/ui/` (new masters) and
  `vajb-orbit/assets/icons/` (panel provenance files only). Never re-cut or
  overwrite any other family.
- No balance number moves; no hex literals in code beyond the one §7 precedent
  already there (`needle_colour`'s `accent_nav` fallback); tokens only.
- Pipeline law (AGENTS.md "Phase G lane" + UI_CHROME §1.1): one family per panel,
  render → `panels.py --detect` → cut each → key each → trim; never key a panel
  holding more than one object; `cells` in the driver is the authority. Digit QC
  (AC5) gates the ship step.
- Generation logs beside the shipped family (`vajb-orbit/assets/ui/`). Price
  basis: 4 × 2K runs = 40 credits ≈ **$0.20** real (the script's printed estimate
  over-reports 3×).
- Scratch stores for every probe/gate (T-93 class); bounded probes (L82); no shell
  file edits; workspace-relative `VAJB_WORKER_FILES` (L92a); never leave a
  background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- Per-module damage model (needs an `18_engine_spec.md` amendment — owner-locked).
- Compass cardinal letters as engine `Label`s (no baked text law keeps them out
  of the art).
- 4th SPD digit (current clamp is 999; boost × 1.6 tops out under it — revisit if
  a class ever exceeds).
- Moving the cluster widgets into `hud.tscn` (the standing §7 follow-up).

## Owner ticks owed after this wave

1. **The NMS palette reading.** Shipped on the STYLE_BIBLE palette (Bone/Panel
   Steel digits, one ember accent). NMS's teal holographic tint would need a
   STYLE_BIBLE amendment = owner ruling. Tick = keep, or sanction teal for
   instruments only.
2. **Cluster placement + size**: bottom-left, 404×216 (HUD had already reported the
   bottom-centre/bottom-left ambiguity). Alternatives: bottom-centre, 340×184.
3. **HULL/SHLD as points** (as worded) vs % like FUEL/ENRG.
4. **`ship_status` key = U** (proposed; G/T/B/J/K/L/V/Y/N/M/I/O/P are also free).
5. **Schedule the per-module damage model** (screen currently shows module list +
   powered state only, honest to the sim).

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline d6_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md --tests --expect-reports .agents/gen/slices/D6-cockpit-instruments/D6-M0_report.md .agents/gen/slices/D6-cockpit-instruments/D6-M1_report.md .agents/gen/slices/D6-cockpit-instruments/D6-M2_report.md .agents/gen/slices/D6-cockpit-instruments/D6-R1_review.md`
   (`validate_names.py --library` is environment-deferred on the Linux host, the
   D2 close-out note.)
3. `docs/CONTRACTS.md` §9/§10 measured notes + the `ship_status` input-map row
   applied by the orchestrator (godot-ai or the owner's `project.godot` pass) —
   sequenced after S5-R1's own §9/§10 pass so that file has one writer at a time.
4. `_state/WAVEBOARD.md` closed; LOW rows at the next free ids.
5. Wave-boundary commit.
