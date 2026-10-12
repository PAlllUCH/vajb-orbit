---
slice: S48
worker: S48-V0
role: coder
status: ready
tier: paid
---

# S48-V0 — the C-key Cargo overlay, both planes (UI_SPEC §18 A7–A9 + STATION_HUB §23.2)

## Context (read in this order, by range)
1. `docs/design/UI_SPEC.md` §18 (lines ~1921–1938, verbatim below) and §12.3
   (the N28 sheet idiom the surface wears), §12.2 (the stacking law), §3.10
   A5.1–A5.5, §16.1.
2. `docs/design/STATION_HUB.md` §23.2 (lines ~2122–2131, verbatim below).
3. `vajb-orbit/ui/screens/station.gd` — the input ladder (`_unhandled_input`
   `:403-455` — your C step joins it; note `ui_cancel`'s Router-overlay guard
   at `:413-415`), the overlay layers (`:215-222`), the N28 sheet's own build
   (grep `_on_panel_sheet` / the sheet build) — the idiom you reuse.
4. `vajb-orbit/game/game.gd` — `_update_cargo_input` (`:1696-1700`), the ESC
   ladder `_update_cancel_input` (`:1042-1060`), the HUD wiring (`_hud`), and
   the scene's layer seats (the HUD's CanvasLayer is layer 10 — §2.3).
5. The read seams: `vajb-orbit/autoload/player_profile.gd` — `cargo_items()`
   (`:650`), `cargo_qty()` (`:646`), `ammo_of()` (`:440`); the active hull's
   cargo capacity (08 §3 — the catalogue's `cargo` column; the OVERVIEW's
   `_active_ship`/`Catalog.ship` reads are the exemplar).
6. The tint laws: 02 §6 (the ore tiers), 03 §4.1 (the component grades).
7. The §5.2 dialog idiom (`docs/design/UI_SPEC.md:787-806`) and the flight
   HUD's `CargoBlock` (S39/T-170 — `ui/hud/hud.gd`, read-only reference).

## Spec extract (the pinned law, verbatim)

**UI_SPEC §18 A7** — "**the C key, both planes — one law.** `cargo_toggle`
(bound to C, `project.godot`) opens the overlay in **both** planes. **Station:**
the station shell handles the action from any pane and opens the overlay above
the pane, below the drawer/sheet overlays (§12.2's stacking). **Flight — the
overlay's seat:** the same surface (A8) over the flight HUD, on the layer-20
overlay `CanvasLayer` (§2.3's dialog layer — above the HUD's layer 10),
topmost: `ui_cancel` closes it as the one topmost step before the map-deck
step (P19's idiom; flight's own topmost-first poll, `game.gd:1040-1056`). The
HUD `CargoBlock` (S39/T-170) stays as it is. One at a time (§5.2's queue); it
opens over an open pane or the live HUD without pausing anything."

**A8** — "**the surface: the N28 sheet idiom, read-only — one surface, both
planes**: `DialogRoot` full-rect `MOUSE_FILTER_STOP` → dimmer `void_base` 60 %
→ `CenterContainer` → `PanelContainer` `panel_raised` → `MarginContainer` 16 →
`VBoxContainer` 12; width size-to-content in **420/720** (N28), height under
N32's 80 %-viewport scroll rule. Title row: **`CARGO — <n>/<cap> UNITS`** (cap
= the active hull's cargo, 08 §3). Close: ESC (one operation — P19's topmost
step station-side, the same one step in flight per A7), the scrim (N38), C
again; focus returns to the trigger (N39); open/close envelope N29 (≤ 0.2 s).
**No transactional control inside**."

**A9** — "**the contents rows, the owner's five groups** (each group a
`StationCaption` band, §12.3's row grammar; rows `Label` 13 with the family
glyph 24 at its own rect, A5.2(iii)): **AMMUNITION** — one row per weapon,
`<weapon name> · <rounds> ROUNDS` (`ammo_of`, §5.1's read); **ORE** — `<name> ·
<n>` per ore stack (`cargo_qty`, tier tint, 02 §6); **INGOTS** — same, ingot
ids; **COMPONENTS** — per component id (03 §3, grade tint, 03 §4.1); **FUEL
CELLS** — the `pow` family's rows (`comp_pow_1`…, 03 §3) drawn as their own
group so nothing double-counts. Empty group: a `NONE HELD` caption row. **Read-
only seams:** every number reads `cargo_items()` / `cargo_qty()` / `ammo_of()`
only — no price, no quote, no recomputation."

**STATION_HUB §23.2 (station side)** — "`cargo_toggle` (C, already bound in
`project.godot` for flight) is handled by the station shell from **any pane**,
opening the read-only overlay above the pane (above panes, below the
drawer/sheet stacking order — the §12.2 stack law); `ui_cancel` closes it as
P19's topmost step. The station's hold read seams stay as they are; the
overlay adds no transaction anywhere."

## Measured facts (cite, do not re-derive)
- The station's key ladder is `_unhandled_input` (`station.gd:403-455`); the
  C step joins it (an `is_action_pressed(&"cargo_toggle")` branch — the action
  is in the input map, `project.godot:73`). The `ui_cancel` branch's
  Router-overlay guard (`:413-415`) stands; the cargo overlay's ESC close is
  the shell's own step inside `_handle_cancel`'s ladder (the overlay's open
  state read first — P19's topmost-first).
- The flight poll `_update_cargo_input` (`game.gd:1696-1700`) drives the HUD's
  retired panel through `set_cargo_open` (the frozen setter, `hud.gd:2228-2235`)
  — the overlay's open state replaces that sink: the poll calls the overlay
  (C toggles), the flag mirror stays in step, the HUD panel stays hidden.
- The flight's overlay host is a layer-20 `CanvasLayer` the game scene owns
  (the HUD's own CanvasLayer is layer 10; §2.3's dialog layer is 20 — the
  station's confirm layer is the precedent, `station.gd:501-505`).
- The ESC ladder in flight is `_update_cancel_input` (`game.gd:1042-1060`) —
  the overlay's close is the one topmost step before the map-deck step.
- The five groups' item universes: ore ids (02 §3), ingot ids (02 §3's ingot
  family), component ids (03 §3) with `comp_pow_*` split out as FUEL CELLS,
  weapons (the battery's fitted weapons — `ammo_of`). The tints: 02 §6's tier
  tint for ore, 03 §4.1's grade tint for components.
- The family glyphs ship at `assets/icons/…` (`icon_cargo_ore.svg`,
  `icon_credits.svg`, the module/slot families — reuse the shipped files at
  their own cut; the catalogue rows carry each item's icon field).
- Gate baseline 1330/0 (2026-10-12).

## Task
Build the shared read-only cargo overlay (scene + script), wire it into both
planes' input ladders, and add the suite `tests/test_s48_cargo_overlay.gd`.

## Acceptance list
1. One overlay scene/script serves both planes: the N28 idiom's surface
   (DialogRoot full-rect MOUSE_FILTER_STOP → void_base 60 % dimmer →
   CenterContainer → `panel_raised` PanelContainer, size-to-content width
   420/720 → margin 16 → VBox 12), height under the 80 %-viewport scroll rule.
2. Title `CARGO — <n>/<cap> UNITS` where `<n>` is the summed hold and `<cap>`
   the active hull's cargo capacity (08 §3).
3. The five `StationCaption` groups (AMMUNITION / ORE / INGOTS / COMPONENTS /
   FUEL CELLS) with the rows A9 words — glyphs 24 at their own rect, the tier/
   grade tints, `NONE HELD` on an empty group; every figure reads
   `cargo_items()`/`cargo_qty()`/`ammo_of()` only.
4. No transactional control anywhere in the overlay (no buttons but the
   implicit close affordances).
5. Station: the shell handles `cargo_toggle` from any pane; the overlay opens
   above the pane, below the drawer/sheet overlays; C again, ESC, or the scrim
   closes it; focus returns to the trigger; the open/close envelope ≤ 0.2 s.
6. Flight: the overlay opens over the live HUD on the layer-20 `CanvasLayer`
   (above the HUD's layer 10) without pausing anything; C again, ESC (the one
   topmost step before the map-deck step), or the scrim closes it; the HUD
   `CargoBlock` stays untouched and visible; the retired HUD panel stays
   hidden; `_cargo_open`'s mirror stays in step.
7. New suite `tests/test_s48_cargo_overlay.gd` pins items 1–6 (at least one
   row each; the flight rows may drive the poll directly); the report answers
   every item with a cite.

## Hard constraints
- File set: `vajb-orbit/ui/dialogs/cargo_overlay.gd` (new),
  `vajb-orbit/ui/dialogs/cargo_overlay.tscn` (new),
  `vajb-orbit/ui/screens/station.gd`, `vajb-orbit/game/game.gd`,
  `vajb-orbit/tests/test_s48_cargo_overlay.gd`. Do not touch
  `ui/hud/hud.gd` (read-only), the profile (read-only seams), other panels,
  docs, the theme, `project.godot` (the binding is shipped).
- No new hex; no new tokens; A5.1–A5.5 composition; no priced row anywhere.
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S48-cargo-overlay/S48-V0_report.md` (≤120 lines,
  from `_templates/REPORT.md`).
- Deliverable: the five files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/dialogs/cargo_overlay.gd,vajb-orbit/ui/dialogs/cargo_overlay.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/game/game.gd,vajb-orbit/tests/test_s48_cargo_overlay.gd" crush run "You are worker S48-V0. Read .agents/gen/slices/S48-cargo-overlay/S48-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
