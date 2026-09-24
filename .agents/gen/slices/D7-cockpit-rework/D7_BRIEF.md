# D7_BRIEF — Cockpit rework + battery window (the analog instrument pass)

Wave `D7`, slice `D7-cockpit-rework`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder; the folder law; the Phase G lane)
2. `docs/design/UI_SPEC.md` **§3.6/§3.7 as amended 2026-09-24**, **§3.9**,
   **§3.10** (this wave's pins), then §3.1/§3.1b (the row treatments reused) and
   §1 (tokens)
3. `docs/design/UI_CHROME_ASSETS_SPEC.md` **§12** (art prompts + QC), §1 (style)
4. `docs/design/ASSET_NAMING_SPEC.md` §12 (names)
5. `docs/design/STATION_HUB.md` §5.11 restyle block + §12.4 (the panel contract)
6. `docs/CONTRACTS.md` §7 (frozen HUD API) + §18 + §17 (armory seams) — **note:
   where §18 lags UI_SPEC §3.7's 2026-09-24 amendments, UI_SPEC is the law and
   the §18 mirror is close-out-updated** (one writer at a time; S6 may hold it)
7. this brief end to end

## Owner findings, verbatim (2026-09-24)

1. "I dont get why there are two compasses that seem to work the same?"
2. "i dont like the cockpit background, it looks like a computer screen while we
   have analog clocks etc, make sure that everything looks analog, so they are
   placed on a metal panel of something like that."
3. "take a screenshot and look at the cockpit, there is overlap and generaly
   doesnt look too pleasing to the eye" (measured on the live frame 2026-09-24:
   every digit row's glyphs collide — the `ui_seg_*` sprites draw wider than
   their cell pitch)
4. "on the left side of the game we have some weird big icons. all of old HUD
   should be gone i think" (the §3.1 crest bars, §3.2 `AmmoPanel`, §3.4 cargo
   block — HULL/SHLD already duplicate the cluster rows)
5. "While we are designing, lets go out of the developer loop and rework the gun
   battery selection window to new cockpit like one." (the ARMORY's BATTERY
   RACKS window — `armory_panel.gd`)

## What is already measured (file:line)

- `vajb-orbit/ui/hud/hud.gd:471-479` — `set_speedometer` feeds the cluster and
  the dial from one call; `hud.gd:517-522` `compass()`/`compass_heading()`. The
  two compasses are §3.6's code-drawn **heading tick** (UI_SPEC §3.6 pre-D7) and
  §3.7's **compass bay** — one feed, two instruments. D7 retires the tick
  (§3.6 amendment).
- The overlap: `ui_seg_*` masters are 48×88 (ASSET_NAMING §11, §11 table) and
  the cells are 20×36 logical on a 22 px pitch — the drawn rect must be
  fill-fitted (UI_SPEC §3.7 D7 amendment's digit fit law).
- D6's measured content box **396×190** vs the frame interior **340×152**
  (D6-R1 MED-2; `_review_probes/cluster_composite.png`) — the new 464×256 /
  400×192 box cures it as one call (UI_SPEC §3.7 D7 amendment).
- `vajb-orbit/ui/station/armory_panel.gd:1-42` — the pane's contract and its
  three groups (BATTERY RACKS `B1..B7` per `weapon_1..7`, INVENTORY, AMMUNITION);
  `status_requested`/`refresh_profile`/`focus_primary` are the shell seams; the
  panel writes only through `PlayerProfile` composed APIs (STATION_HUB §12.4).
- `vajb-orbit/tests/test_engine2_hud.gd:188-237` — the §3.6 rows. Per the §3.6
  amendment, **exactly the heading-tick rows move**; every other row stays
  byte-green. The worker reports which rows it changed and why.
- S5-R1's ammo rack-ordinal MED (hud.gd:1122,1128) dies with the `AmmoPanel`;
  the battery readout resolves racks through the corrected tables.

## The pinned interface (UI_SPEC §3.6/§3.7/§3.9/§3.10 as amended 2026-09-24 are
the source of truth; nothing here may drift)

```gdscript
# D7 — additive to D6's pinned interface (CONTRACTS §18). Every read-back
# survives: cockpit(), compass(), compass_heading(), readouts().
#
# ui/hud/cockpit_cluster.gd — same class, reworked surface:
#   - backing: ui_cockpit_panel (928x512 master, fill-fit to the 464x256 box;
#     NO nine-slice), gauge/compass/rows in the panel's recessed wells
#   - box 464x256, interior 400x192, band 32; bays left 126 / middle 104 /
#     right 156, 7 px gutters
#   - left bay foot: battery readout — Label "B1 · CANNON" + AMMO row (34 label
#     + 4 cells, clamp 0..9999, blanks) on the existing ammo feed
#   - digits: ui_seg_* fill-fitted to 20x36, 22 px pitch (the overlap cure)
#   - dial: ui_gauge_face v2 (8-tick speed scale) + code-drawn segment fill +
#     prograde needle; NO heading tick
#   - compass bay: ui_compass_rose (-heading.angle()) under fixed lubber + HDG
#     row 0..359 — the one heading instrument
#
# ui/station/armory_panel.gd — SURFACE ONLY. Same signals, same APIs, same
# transactions; chrome becomes ui_armory_console + ui_armory_rack_plate +
# ui_armory_row_plate; the SALVO line gains a 3-cell ui_seg_* readout
# (proposed: seconds x10, "0.73 s" reads 073, Label "SALVO s"; reversal: plain
# Label).
#
# hud.gd — the §3.1 crest bars, §3.2 AmmoPanel and §3.4 cargo block are removed
# from the flight HUD. Every §7 frozen method keeps its signature and stays
# callable (hidden/no-op widgets where nothing remains to drive).
```

Rules that fix every ambiguity:

- **Digit semantics** are UI_SPEC §3.7 as amended (SPD 4 cells clamp 0..9999 —
  the 2026-09-24 owner ruling; HULL/SHLD 4 cells points; FUEL/ENRG 3 + `%`). The
  battery readout's AMMO row: `int(round(loaded))` clamp 0..9999, 4 cells.
- **Danger rows** reuse §3.1/§3.1b verbatim as row treatments (label + 1 px
  code-drawn frame; **digits never recolour**). Overdrive stays `ratio > 0.9`
  strict.
- **No baked text** anywhere in the new art (UI_CHROME §1.7). All words are
  engine `Label`s in the §3.7 row-label style (12 px `text_dim`).
- **Art is one object per panel cut** (Phase G lane law; `cells` is the
  authority). `flare` needs `--post-only` keying. Generation logs beside the
  family. Price basis: 4 × 2K = 40 credits ≈ **$0.20** real (the script's
  estimate over-reports 3×).
- **The armory's numbers are measured, not invented**: `ui_armory_console` /
  `ui_armory_rack_plate` masters are 2× the pane's own measured rects (from
  `armory_panel.gd`'s constants), and the measurements go in the report.
- **Route is yours** (bucket 1): widget node shape, sprite loading idiom, how
  the wells mount. **NOT yours**: any pinned number above, any `game/`/
  `autoload/`/`project.godot`/theme/docs write, any existing test's expectations
  beyond the two named sets (`test_engine2_hud.gd`'s heading-tick rows and
  `test_d6_cluster.gd`'s compass rows), any armory transaction.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| D7-A0 | art batch (generate → detect → cut → key → trim → QC → review sheet) | `staging/,asset-library/,vajb-orbit/assets/ui/,vajb-orbit/assets/icons/` | 5 masters + provenance + `D7-A0_report.md` + review sheet (STOP) |
| D7-A0b | ship reconcile + import (after owner approval) | same | reconcile + reimport + report append |
| D7-C1 | cluster rework + digit fix + compass dedup + battery readout + old-HUD removal | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `test_d7_cockpit.gd` + `D7-C1_report.md` |
| D7-C2 | ARMORY cockpit restyle (surface only) | `vajb-orbit/ui/station/,vajb-orbit/tests/` | `test_d7_armory.gd` + `D7-C2_report.md` |
| D7-C3 | ship status modal restyle (Mockup C; after C1 — shared `ui/hud/`) | `vajb-orbit/ui/hud/,vajb-orbit/tests/` | `test_d7_status.gd` + `D7-C3_report.md` |
| D7-R1 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/` | `D7-R1_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| D7-F1 | fixer | union of A0–C3 sets | only if R1 leaves HIGH/MED |

**Run order:** A0 → **STOP, owner approves the review sheet** → A0b → C1 → C2 →
C3 → R1 → (F1 only on HIGH/MED). C1 before C2 and C3 (C1 owns `hud.gd`'s column
removal; C3 shares `ui/hud/` and runs after C1). Each builder writes only its own
`test_d7_*.gd`.

**Parallel safety (S6 travel, coder item 12, in flight):** this wave writes
`ui/hud/**`, `ui/station/**`, `assets/ui/**`, `assets/icons/**` provenance,
`staging/**`, `asset-library/**`, `tests/test_d7_*.gd` plus the two named
existing test sets. S6 holds `game/**`, `autoload/player_profile.gd`,
`tests/test_s6_*.gd` (+ its own close-out CONTRACTS pass) — **disjoint except
the `tests/` dir** (file names disjoint) and gate runs (bound, scratch stores,
`XDG_DATA_HOME`; one editor session; reimports only in quiet windows).

## Tests that move, and why

- `test_engine2_hud.gd`'s §3.6 rows (188-237): **only the heading-tick rows**
  move (UI_SPEC §3.6's 2026-09-24 amendment retires the tick — the yardstick
  moves with the docs, owner-routed). Segment/needle/overdrive rows byte-green.
- `test_d6_cluster.gd`: compass rows re-aim at rose-only heading
  (`compass_heading()` survives); any heading-tick assertion drops per the same
  amendment. **No other row changes.**
- Old-HUD tests (rows asserting `AmmoPanel`/crest bars/cargo widgets): re-aim at
  the battery readout or retire — the builder reports every row it touches.
- New `test_d7_cockpit.gd` ≈ 12 groups: digit-fit rect disjointness + in-row
  containment, battery readout mapping (rack ordinal → family, AMMO clamps/blank
  padding), old-column absence, well-mount rects vs the §3.7 bays, §3.6 rows
  re-asserted minus the tick.
- New `test_d7_armory.gd` ≈ 8 groups: surface-only proof — the pane's
  transactions byte-behave (refusal writes nothing), drag-drop ordering intact,
  console/rack/row plates mount at the measured rects, SALVO cells render the
  cycle figure, danger rows follow §3.1/§3.1b.
- New `test_d7_status.gd` ≈ 6 groups: the Mockup C surface (well mounts at the
  §3.8 rects, marker dots on the render, slot grid refs, footer figures) —
  behaviour rows stay in `test_d6_status.gd` **byte-green**.
- `test_d6_status.gd`, `test_p2b*`, `test_s5_*`: **untouched, all green.**
- Expected gate: 608 + ~20; the measured number goes into CONTRACTS §9 at
  close-out.

## Hard rules

- Frozen for workers: `project.godot`, `docs/gameplay/18_engine_spec.md`,
  `docs/gameplay/08_ship_slots_modules.md`, `docs/CONTRACTS.md`, all `docs/`
  text (the docs-first is landed; workers implement it),
  `vajb-orbit/addons/`, `vajb-orbit/ui/theme/vajb_theme.tres`, all of `game/`
  and `autoload/`. Zero new sim feeds.
- `assets/` writes: `vajb-orbit/assets/ui/` (new/re-cut masters) and
  `vajb-orbit/assets/icons/` (panel provenance only). Never re-cut another
  family; `ui_seg_*`, `ui_compass_*`, `ui_gauge_needle` stay byte-identical.
- No balance number moves. Tokens only — no hex literals beyond §3.6's existing
  `needle_colour` precedent.
- Pipeline law: render → `panels.py --detect` → cut each → key each → trim;
  never key a multi-object panel; `cells` in the driver is the authority;
  2×2 fourth-cell IoU check (0.80 line). Generation logs beside the family.
- Scratch stores for every probe/gate (`XDG_DATA_HOME`); bounded probes; no
  shell file edits; workspace-relative `VAJB_WORKER_FILES`; never leave a
  background job; a number not in the pinned docs: **report it, never invent
  it**.

## Staged / deferred

- `ship_status` (§3.8) restyle onto the §3.9 language (it keeps
  `ui_cockpit_frame` for now).
- Compass cardinal letters (engine `Label`s; no baked text law keeps them out of
  art).
- The D6 carry-over ticks (NMS teal, HULL/SHLD %, key U, per-module damage).

## Owner ticks owed after this wave (the design calls made, each reversible)

**Resolved by the approved mockups (2026-09-24: "Looks good. lets do this"):**
compass survivor (the rose + rotating N/E/S/W Labels), cluster box + look (464×256
metal panel), battery lamps B1..B5 + AMMO, the unified 36 px foot band, the SALVO
drum format (seconds ×10, `073` = 0.73 s), the §3.8 restyle (Mockup C joins the
wave). Still open: the D6 carry-overs (NMS teal, HULL/SHLD %, key U, per-module
damage) and the armory's `OWNED ×n` / HELD-MAX copy rows if the owner wants
wording changes.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store, `XDG_DATA_HOME`; identical counts) + the
   live-profile untouched check.
2. `python3 staging/verify_wave.py snapshot/verify --baseline d7_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/gameplay/08_ship_slots_modules.md docs/CONTRACTS.md --tests --expect-reports <the four reports>` (attribute other lanes' deltas as at D6).
3. `docs/CONTRACTS.md` §9/§10 measured notes + the §18 mirror catch-up
   (sequenced for one writer at a time against S6's close-out pass).
4. `_state/WAVEBOARD.md` closed; LOW rows at the next free ids.
5. Wave-boundary commit.
