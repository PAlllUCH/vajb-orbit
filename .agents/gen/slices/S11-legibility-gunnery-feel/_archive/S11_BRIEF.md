---
slice: S11
wave: S11
brief: .agents/gen/slices/S11-legibility-gunnery-feel/S11_BRIEF.md
prompts: .agents/gen/slices/S11-legibility-gunnery-feel/S11_prompts.md
pin: docs/CONTRACTS.md §23 (v0.22, docs-first)
status: ready
gate_baseline: "775/0 (S10 close, 396b8f3) — read the live count at dispatch, never trust this line"
---

# S11_BRIEF — station legibility, space gunnery, one-vector inertia

## The law to read, in order

1. `docs/CONTRACTS.md` **§23** — this wave's pin, and the only place the numbers live.
   Read it end to end before touching a file. §22 and §14 are its amendments.
2. `docs/CONTRACTS.md` **§9** (the gate: how to run it, what green means) and **§7** (the
   HUD's frozen API — the credits block is an addition to it, never a change).
3. `slices/S11-legibility-gunnery-feel/SLICE.md` — scope, worker sets, acceptance criteria.
4. `docs/design/UI_SPEC.md` + `docs/design/STATION_HUB.md` §5.1/§5.11 (the station's block
   language; the ARMORY's contract), `docs/design/STYLE_BIBLE.md` (the palette).
5. `AGENTS.md` — the gate command, the worker rules (bound every Godot run, never leave a
   background command, never write the live profile).

## The owner's request, verbatim (2026-09-24)

> "I want a panel in the space station where i buy ships etc to always show full item
> description that is hovered on maybe on the bottom left where there are currect infos but
> they only update on press. we might need to make them bigger. or move it to the top next
> to credits. i also want the current credits in the space scene. spawn deepseek api
> deepseek flash reviewer on max reasoning to do review of readibility in the pararell, the
> armory meny in particular (it looks pretty bad) if its graphics lane make sure its well
> known. cannon and railgun, every kinetic weapon should have near infinite range, i dont
> see a reason why they should dissapear in space, same for lasers. also take a look at the
> flight and inertia. when flying forward and to the side when i stop first ship stops then
> glides to the side, like each vector of inertia is independent which doesnt feel good.
> prepare a plan to fix it, report when fixed"

Answered the same day: **"go ahead with all"** — every recommendation taken, plus the
`deepseek/deepseek-flash` `max` readability audit (that one is slice **D12**, already
dispatched, not this wave).

## What is already measured (do not re-measure, re-derive only what you touch)

| fact | value | where measured |
|---|---|---|
| the station's footer is one caption line, written by hover **and** press | 13 px, `Tokens/text_dim`, `StationCaption` | `ui/screens/station.tscn:226-241`, `ui/screens/station.gd:531-538` |
| panes publish only terse hover hints; no pane has a description surface | `STATUS_HINT % [name, cost]` | `ui/station/armory_panel.gd:1428`, `status_requested` in all eight panes |
| `&"description"` exists on ships (18), components (18), minerals (20) — and on **none** of `MODULES` | read in one place only | `game/station_catalog.gd:96`, `game/component_catalog.gd:17`, `ui/station/shipyard_panel.gd:919` |
| credits live only in the profile autoload; the HUD has no credit readout | `profile_changed(key)` signal exists | `autoload/player_profile.gd:53,282`; zero hits in `ui/hud/**` |
| family ranges today | laser 500, plasma 450, cannon 600, railgun 800, rocket 900, mine 0 | `game/weapons.gd:81-160` |
| a shot fizzles at `max_range` (0 = no limit); a beam is capped by `reach` | | `game/projectile.gd:441,503,635`; `game/weapons.gd:1108,1123` |
| the sector is 10 000 × 10 000 (diagonal ≈14 142 u) | why 30 000 u is "near infinite" | `game/sector_registry.gd:32` |
| the released hull decays on two time constants + an explicit cross-axis drag | the owner's complaint in numbers | `game/player_ship.gd:1068-1090`, `:864-880`, `:851` |
| handling multipliers | `ACCEL_TIME_MULT 2.0`, `COAST_TIME_MULT 2.0`, `LATERAL_DAMP_MULT 1.0` | `game/ship_fit.gd:514-516` |

## Pinned interfaces (verbatim; every ambiguity is fixed here or in §23)

```gdscript
## ui/station/*_panel.gd — declared on all eight panes
## Emitted when the pointer lands on or leaves a row the player can buy, fit or sell.
## `title` is the row's identity line, `body` its catalogue description (empty when the
## row carries none), `danger` colours the title. `title == ""` clears the shell's block.
signal inspect_requested(title: String, body: String, danger: bool)
```

```gdscript
## game/station_catalog.gd — static additions, the single homes for both rules
## The body text for one catalogue id: base-id resolved (a `mod_*` instance resolves
## through its base), read from MODULES / SHIPS / the ammo and service rows' own
## `description` key, `""` when the row carries none (never invented text), with a
## `mod_*` instance's affix perks appended, joined by " · ".
static func describe(id: StringName) -> String

## The station's own digit grouping, one copy: `1200` -> `1 200`.
static func group_int(value: int) -> String
```

```gdscript
## ui/screens/station.tscn — the inspector block, immediately above the status strip
## Inspector (PanelContainer, PanelRaised)
##   InspectorMargin (MarginContainer)
##     InspectorBox (VBoxContainer)
##       InspectorTitle (Label, StationPanelTitle, one line, clipped)
##       InspectorBody  (Label, SectionHeader, font_color override = Tokens/text_primary,
##                       autowrap_mode AUTOWRAP_WORD_SMART, max_lines_visible 2)
const INSPECTOR_BODY_MAX_LINES := 2
```

```gdscript
## game/weapons.gd — beside FAMILIES
## The owner's 2026-09-24 ruling: a kinetic slug and a beam do not stop in the dark.
## 30 000 u is past a sector's own 14 142 u diagonal (`sector_registry.gd:32`) and the
## fizzle stays finite, so a shot still despawns (CONTRACTS section 23.4).
const NEAR_INFINITE_RANGE := 30000.0
```

```gdscript
## game/ship_fit.gd — the handling multipliers (CONTRACTS section 23.5)
const ACCEL_TIME_MULT := 2.0          ## unchanged
const COAST_TIME_MULT := 2.5          ## T1: was 2.0
const LATERAL_DAMP_MULT := 1.0        ## RETIRED IN PLACE: unread after 23.5
const ANGULAR_DAMP_MULT := 0.5        ## new, T2: factor on 1 / turn_spinup
```

Rules that fix the rest:

- **Status vs inspector.** `status_requested` keeps its meaning and its wording (transient
  action feedback, danger colour). The inspector is additive and hover-driven. A press may
  write both; a hover writes only the inspector. Never delete or reword a status string.
- **Which panes emit.** `armory`, `shipyard`, `exchange`, `auction`, `refinery`, `fitting`
  emit on hover-in, on hover-out (cleared) and on selection. `repairs` and `launch` declare
  the signal and never emit — their rows are not catalogue items.
- **What the title is.** The row's own name plus its price where the row has one, in the
  pane's existing wording style; never a new format string if the pane already prints one.
- **No invented copy.** §23.2's table is the only source for the 35 module descriptions.
  Transcribe it; do not improve it; if a row looks wrong, report it and leave it.
- **The HUD never writes the profile.** Read by the service name, guard with `has_method`,
  connect `profile_changed`, update on `&"credits"` only.
- **Do not touch** `docs/**` (R1 owns the §9/§10 rows), `game/sector.gd`,
  `game/station_scene.gd`, `assets/**`, `staging/**`, `asset-library/**`, or anything under
  `slices/D11-station-scene/`. Do not reformat, re-wrap or "improve" a file you touch.
- **Never** `git add -A`, never commit, never run a tool that writes the live profile
  (`XDG_DATA_HOME=$(mktemp -d)` for every gate and probe).

## Workers

| ID | role | VAJB_WORKER_FILES | deliverable |
|---|---|---|---|
| S11-B1 | coder | `vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/repairs_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/ui/screens/station.gd,vajb-orbit/ui/screens/station.tscn,vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/test_s11_inspector.gd` | the inspector block + the six emitters + `describe`/`group_int` + its suite |
| S11-B2 | coder | `vajb-orbit/game/module_catalog.gd,vajb-orbit/ui/hud/hud.gd,vajb-orbit/ui/hud/hud.tscn,vajb-orbit/tests/test_s11_inspector.gd` | the 35 descriptions (data) + the HUD credits block + the credits half of the suite |
| S11-B3 | coder | `vajb-orbit/game/weapons.gd,vajb-orbit/tests/` | `NEAR_INFINITE_RANGE` + the range rows that move |
| S11-B4 | coder | `vajb-orbit/game/ship_fit.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/tests/test_s2_6_flight.gd,vajb-orbit/tests/test_flight_feel_g1.gd,vajb-orbit/tests/test_engine_c3_flight_decay.gd,vajb-orbit/tests/test_s11_flight_stop.gd` | one-vector decay + T1/T2 + the 5° acceptance suite |
| S11-R1 | reviewer | `vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/_state/LOW_BACKLOG.md,.agents/gen/slices/S11-legibility-gunnery-feel/` | `S11-R1_review.md`, §9/§10 rows, LOW rows |

## Run order

1. **B1 ∥ B3 ∥ B4** — disjoint file sets, three background workers.
2. **B2** — after B1 lands (`group_int` must exist); B2 also owns the two HUD files.
3. **R1** — after all four; it re-measures, never fixes.
4. **F1** — only if R1 leaves HIGH or MED.

## Tests that move

- **New:** `tests/test_s11_inspector.gd` (B1: the signal, the block, `describe`, and B2's
  credits half), `tests/test_s11_flight_stop.gd` (B4: the 5° acceptance).
- **Re-derived:** any row pinning a family `range` / `range_of` (B3);
  `test_s2_6_flight.gd`, `test_flight_feel_g1.gd`, `test_engine_c3_flight_decay.gd` and the
  probes `probe_s2_6_flight`, `probe_g1_flight_feel`, `probe_c3_flight_decay` (B4). Re-derive
  to the ticked constants; **never weaken a bound**.
- **Untouched:** every other suite. If one fails, it is a finding, not a license to edit it.

## Hard rules

- Docs first, code second, tests third — this brief plus §23 is the last docs write before
  the builders; only R1 writes `docs/CONTRACTS.md` after that.
- One worker, one file set. A need outside your set is a **report**, not an edit (the S8-Q3
  precedent: a new worker or a continuation, never a widened grant).
- Bound every Godot run (`--quit-after`), never leave a command in the background, redirect
  probe output to a log you read.
- The gate is `XDG_DATA_HOME=$(mktemp -d) timeout 900 "$GODOT_CONSOLE" --headless --path
  "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200`; green is
  `[SUMMARY] passed=775+new failed=0`. Record the exact line in your report.
- Report ≤120 lines, no pasted source, no transcripts, `file:line` for every claim.

## Staged / deferred

- **T3 `STRAFE_RATE_MULT`** — held (§22's row contradicts itself). Notice with the owner.
- The panes' **existing** type sizes and the `text_dim` caption colour — a graphics-lane
  matter (D12-A0's audit). S11 must not "fix" them in passing.
- The inspector's multi-line body beyond two lines, and any scrolling description — not this
  wave.
- Item 17 (jump gates to sector edges) and slice 4's remainder — untouched.

## Owner ticks this wave owes you

1. The inspector's **placement and size** as shipped (bottom-left, `StationPanelTitle` +
   `SectionHeader`-at-`text_primary`, two wrapped lines) — or the header-next-to-credits
   variant instead.
2. The **35 descriptions' wording** (§23.2) — you own the copy.
3. The **30 000 u** ceiling, and the IN/OUT OF RANGE readout left as it is.
4. The **one-vector decay** feel (a single stop along the release line) plus T1 2.5 / T2 0.5.
5. The credits block's position (top-left column, below fuel).

## Close-out (per the queue's wave anatomy)

1. Gate ×2 on fresh scratch stores; live profile md5 before and after (the owner plays — a
   moved profile is attributed, not drift).
2. `python3 staging/verify_wave.py verify --baseline s11_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md docs/design/UI_SPEC.md
   docs/design/STATION_HUB.md --tests --expect-reports
   .agents/gen/slices/S11-legibility-gunnery-feel/S11-B1_report.md … S11-R1_review.md`
   → exit 0, `problems: []`.
3. R1's §9/§10 row (sequenced after any D11 row), LOW rows at the next free ids,
   `WAVEBOARD.md` (§Queued → §Closed, live gate count), `MASTER_REPORT.md` §6 recap.
4. Wave-boundary commit with explicit paths (never `git add -A` — D11 and the D12 lane are
   live).
