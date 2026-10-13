---
slice: S46
worker: S46-V0
role: coder
status: ready
tier: paid
---

# S46-V0 — the shipyard build view (P54 + 10 §3.5; the BUILD door rides A2)

## Context (read in this order, by range)
1. `docs/design/STATION_HUB.md` §23.8 (lines ~2164–2168, verbatim below) and
   §5.10 (the AUCTION shelf idiom), §5.6 (the refusal strip family).
2. `docs/gameplay/10_ship_acquisition.md` §3.5 (lines ~344–364, verbatim
   below), §3.1 (the nine recipes — untouched economics), §3.3 (the queue law).
3. `docs/design/UI_SPEC.md` §17 A4 door (6) + A6's shipyard wording, §3.10
   A5.1–A5.5, §16.1, §12.3 (the N28 sheet your row press opens).
4. `vajb-orbit/ui/station/shipyard_panel.gd` — by grep then range: the build
   view (`_fill_build_view` `:1629`, `BUILD_HULL_FORMAT` `:146`,
   `BUILD_MODULE_FORMAT` `:147`, `_build_action_row` `:1696` region, the mode
   plates `:277-286`), the hangar surfaces T-175 rides (the pane subtitle
   `:142`, the `PORT`/`STBD` labels — grep).
5. `vajb-orbit/game/shipyard.gd` (307 lines — read whole): `HULL_RECIPES`
   (`:28`), `hull_recipe` (`:104`), `buildable_hulls` (`:201`),
   `buildable_modules` (`:210`), `queue_job` (`:241`), `cancel_job` (`:270`),
   `collect` (`:285`), the KEY_ fields (`:95-99`).
6. The confirm seam contract (the S43 brief's disclosed reading, verbatim
   there; `contracts_panel.gd:426-435` + `station.gd:568-599`).
7. The AUCTION list idiom exemplar: `auction_panel.gd` (grep `_make_row`/
   `shelf`/column header band) — the house style P54 names.

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.8 P54** — "the build band (T-178's live band and
`BUILD_HULL_FORMAT`'s CR figures, `shipyard_panel.gd:146`) **retires**; the
build surface becomes the **AUCTION house style**: a build list of two
category sections wearing §5.10's shelf idiom — **`HULLS`** (10 §3.1's nine
recipes) and **`MODULES`** (10 §3.2's shape rule; its rows land with the
module-catalogue wave — the section ships with the caption `MODULE BUILDS LAND
WITH THE MODULE CATALOGUE`). Each HULLS row (P40's band + N45 trim; `Button` +
container children): the name + `<class> CLASS · <hull> · <slots>` meta; **the
materials bill as materials** — one run per material, `<n>× <name>` with the
family glyph 24 at its own cut, each run reading `<held>/<needed>` from
`cargo_qty` (read-only seam); the labour line `<labour> CR LABOUR`; a per-row
chip **`READY` / `MISSING <n>× <material>`** (label + frame, never colour
alone); the **`BUILD`** `ActionInline` rightmost. The row press opens the
**N28 sheet** (the full bill). The `BUILD` press routes through UI_SPEC §17's
shipyard door — the dialog body carries the bill. `BUILD_HULL_FORMAT`'s two CR
figures die with the band: the auction owns the buy price (its own list), the
build side carries materials + labour only. The queue's commit/refund law
(10 §3.3) is untouched."

**UI_SPEC §17 A6 (the shipyard worked example)** — "`ARE YOU SURE YOU WANT TO
BUILD CORVETTE FOR 60× TUNGSTEN ORE · 35× COBALT ORE · 4× WRECK ALLOY +
9 450 CR LABOUR?`"

## Measured facts (cite, do not re-derive)
- The build view today is one list of `StationButton` rows worded
  `BUILD_HULL_FORMAT`/`BUILD_MODULE_FORMAT` (`_fill_build_view`,
  `shipyard_panel.gd:1629-1660`) — the whole CR band retires.
- `Shipyard.queue_job(profile, kind, id)` commits materials + labour at queue
  time and returns bool (10 §3.3's law); the press path that exists today runs
  it directly — the confirm door fronts it.
- Material display names come from the catalogues
  (`game/mineral_catalog.gd` / `game/component_catalog.gd` name fields,
  upper-cased to the caption law — e.g. `TUNGSTEN ORE`, `WRECK ALLOY`), never
  hardcoded; `<held>` is `profile.cargo_qty(item_id)`.
- The queue/scrap/hangar views are untouched by this wave; the four mode
  plates stay (S41's F15 chips).
- T-175's SHIPYARD rider: the pane subtitle and the `PORT`/`STBD` labels
  render through `SectionHeader`/`StationCaption` — verify in your diff; if
  they already do (S41 landed the cures), report as already-shipped; if not,
  re-point them (the approved cure rides).
- The staged MODULES caption: `buildable_modules()`/`module_recipe()` DO
  carry real recipes (S27 landed them) — the pin still ships the staged
  caption this wave; report the discrepancy as a follow-up (the rows are one
  pass away at the owner's word; you do not over-deliver a pin).
- Gate baseline 1330/0 (2026-10-12).

## Task
Rebuild the BUILD view as the AUCTION-style two-shelf list per P54, wire the
BUILD door through the shell's confirm seam with A6's wording, retire the CR
band formats, and add the suite `tests/test_s46_shipyard_build.gd`.

## Acceptance list
1. The build view is two category sections in §5.10's shelf idiom: `HULLS`
   (nine recipe rows, 10 §3.1's) then `MODULES` (header + the staged caption
   `MODULE BUILDS LAND WITH THE MODULE CATALOGUE`, no rows).
2. Each HULLS row is a `Button` + container children (P40/N45 idiom) carrying:
   the name + `<class> CLASS · <hull> · <slots>` meta; one `<n>× <name>`
   run per material with the family glyph 24 at its own cut and `<held>/<needed>`
   from `cargo_qty`; the labour line `<labour> CR LABOUR` (the only CR
   figure); a per-row chip `READY` / `MISSING <n>× <material>` (label + frame;
   the first missing material in recipe order — disclosed bucket 1).
3. The row press opens the N28 sheet with the recipe's full bill (read-only)
   through the shipped `sheet_requested` seam.
4. The `BUILD` `ActionInline` sits rightmost; its press opens the confirm
   dialog through the shell seam: title `CONFIRM PURCHASE`, body
   `ARE YOU SURE YOU WANT TO BUILD <NAME> FOR <BILL> + <LABOUR> CR LABOUR?`
   (`<BILL>` the `60× TUNGSTEN ORE · 35× COBALT ORE · 4× WRECK ALLOY` run
   idiom, names from the catalogues); OK runs `queue_job` unchanged (which can
   still refuse); CANCEL returns focus; a refusal reports §5.6's/BUILD_REFUSED
   wording on the strip.
5. `BUILD_HULL_FORMAT` and `BUILD_MODULE_FORMAT` are gone (no CR build figures
   anywhere in the build view; the auction's own list is untouched).
6. The queue's commit/refund law is untouched: no change to
   `game/shipyard.gd`'s transaction functions (the file is read-only this
   wave); the queue/scrap views byte-stable.
7. T-175's SHIPYARD surfaces verified (or cured) per the measured facts.
8. New suite `tests/test_s46_shipyard_build.gd` pins items 1–6 (at least one
   row each); the report answers every item with a cite.

## Hard constraints
- **The 5-minute failsafe (the S43 process law):** every shell command you run must be
  bounded — run anything that can take longer than a minute as `timeout 280 <command>
  > /tmp/<log>.txt 2>&1; tail -n 40 /tmp/<log>.txt` and read the log; **never** wait on a
  background job, never use a background-run feature; poll the log file with short sleeps.
  If any single wait exceeds five minutes, stop, write the report with what is done, and
  say so.
- **Suite shaping (the S45 lesson):** one persistent panel mount, narrow reads, no
  `profile_changed` connection unless a row needs the rendered result.
- File set: `vajb-orbit/ui/station/shipyard_panel.gd`,
  `vajb-orbit/ui/station/shipyard_panel.tscn`,
  `vajb-orbit/tests/test_s46_shipyard_build.gd`. `game/shipyard.gd` is
  **read-only** (10 §3's economics are owner-locked adjacent; a signature
  change there is a reported stop, not an edit). Do not touch other panels,
  docs, the theme.
- No new hex; no new tokens; A5.1–A5.5 composition; the labour line is the
  only CR figure in the build view.
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S46-shipyard-build/S46-V0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the three files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/shipyard_panel.tscn,vajb-orbit/tests/test_s46_shipyard_build.gd" crush run "You are worker S46-V0. Read .agents/gen/slices/S46-shipyard-build/S46-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
