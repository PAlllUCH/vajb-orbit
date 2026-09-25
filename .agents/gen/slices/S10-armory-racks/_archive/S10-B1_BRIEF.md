---
slice: S10
worker: S10-B1
role: coder
status: ready
tier: deepseek-direct        # owner's route ruling; high reasoning
---

# S10-B1 — ARMORY: make the fitted rack hittable, the drum honest, selection real

## Context (read in this order)

1. `slices/S10-armory-racks/SLICE.md` — §In scope + your row in Worker file sets
2. `slices/S10-armory-racks/S10-A0_report.md` **end to end** — this brief is written
   from it; every `file:line` below is A0's measurement, re-derive your own
3. `docs/design/STATION_HUB.md` **§5.11** (the ARMORY pin + D7's surface-only
   restyle note), **§5.1**
4. `docs/gameplay/09_ship_slots_modules.md` **§11**
5. `docs/CONTRACTS.md` **§17** (the rack transactions), **§16** (composed
   `fit_into_rack`, rule 9's refusal wording), **§9** (the gate)
6. `docs/design/UI_SPEC.md` **§3.9/§3.10** (the console language D7 applied)

## Task (four fixes, all measured broken by A0 through real input)

1. **Restore the barrel chip's two hit targets — this is the owner's "can't drag
   equipped weapons" and "can't remove".** D7 (`faa24ad`) changed
   `armory_panel.gd:1558` `name_button.custom_minimum_size` from
   `Vector2(COL_ACTION, 0.0)` to `Vector2.ZERO` and added `_position_slots`
   (`:1617-1636`, connected at `:1589-1592`); the `Name` plate and the `✕`
   (`Close`, `:1570 custom_minimum_size = ZERO`) now measure `(0,44)`, so a real
   press on a fitted barrel never starts a drag and never removes it. Pre-D7 the
   same real press/move/release committed `MOVED · CANNON MKI · B3`. Restore
   hittable geometry (the pre-D7 `COL_ACTION` width via the existing const, or put
   `_get_drag_data`/the remove on the chip itself) so a **real** drag and a real
   `✕` click work on every fitted cell, on every rack. Keep the D7 look: the
   plate is transparent ink today (`:1561`) and must stay visually unchanged.
2. **Make the SALVO drum honest for instance-keyed cells.** `_rack_cycle`
   (`:1651-1661`) calls `WeaponComponent.weapon_id` on the **raw** fit entry;
   `weapon_id("mod_0002") = ""` (`game/weapons.gd:2431-2436` strips only a `w_`
   prefix) so a rolled/bought battery reads blanks (`salvo = ---`). Resolve each
   cell to its base id first (the catalogue/instance resolution the pane already
   uses elsewhere) and then ask for the cycle. No pin text moves; a base-keyed
   fit must read exactly as it does today.
3. **Wire rack selection to real input.** `set_selected_rack` (`:663`) has one
   caller in the project (`:1583`, a barrel chip's `Name` focus) and the pane
   declares no input handler; a bay click and the drawn `(1)..(7)` hints
   (`RACK_KEY`, `:132`) do nothing. Add a pane-local seam (`_gui_input` /
   `_unhandled_input`) that selects the bay on a click and on `weapon_1..7`, so
   the §3.2 ember frame follows the player. **Presentation only** — write nothing
   to the profile (the frame is not state today, `:662`); what selection should
   *mean* is an owner tick, not your call.
4. **Tests.** Move exactly the rows the fix changes in
   `tests/test_d7_armory.gd` (A0 names the chip/`Name`/`Close` geometry rows and
   the `salvo_readout` rows: `:423/444-455`, `:468-518`, `:674-689`) and add
   `tests/test_s10_armory_input.gd` driving **real** input
   (`Input.parse_input_event`) with a probe-owned drag canary first — a suite that
   calls `can_drop`/`drop` directly is **not** evidence (S8's L170). Cover: a real
   barrel drag commits the move/swap, a real `✕` click removes, an
   instance-keyed rack yields a cycle figure, a bay click and `1..7` move the
   selection.

## Deliberately NOT in this dispatch (do not build)

- **Refusal feedback on a refused hover** (A0 Q2d: `can_drop = false` means the
  Viewport never calls `_drop_data`, so the pinned `W SLOTS FULL — SWAP OR REMOVE
  FIRST` never renders through the UI). When the wording appears is a pinned
  reading (STATION_HUB §5.1/**§5.11**, CONTRACTS §16 rule 9) → staged as an
  **owner tick**, not coded here.
- **A per-battery ammo preview and battery stats** — A0 proved nothing pins them
  (§5.11 / 09 §11 / UI_SPEC §3.10 pin the bay plate + SALVO drum only) → owner
  tick (spec addition).
- The trailing-rack reading (S8's H2 owner tick) and the seven-racks-on-a-3-W-hull
  question.
- FITTING drag code (S8's O1/O2 owner call), any balance number, any `.tscn`
  node structure change, `docs/`, `assets/`.

## Hard constraints

- File set: `vajb-orbit/ui/station/armory_panel.gd`, `vajb-orbit/tests/`
  (dispatch sets `VAJB_WORKER_FILES` to exactly this). If a fix genuinely needs
  `armory_panel.tscn` or `armory_style.gd`, **stop and report** rather than
  write outside the set.
- No new number: reuse the existing style tokens (`COL_ACTION`, the bay/cell
  rects) — inventing a size is a pin change.
- Shell edits are forbidden (the hook gap) — edit tools only.
- Every probe on a **scratch store** (`XDG_DATA_HOME=$(mktemp -d)`, repoint
  `save_path` before any `PlayerProfile` boot); record the live `profile.cfg` /
  `economy_log.txt` md5 pair before and after.
- Every run bounded (`--quit-after`, self-quitting probes); never leave a command
  in the background.
- Do not run the editor bridge or a paid API; no network.

## Output contract

- Report `slices/S10-armory-racks/S10-B1_report.md` (from `_templates/REPORT.md`,
  ≤120 lines): per fix, the seam, the before/after real-input measurement, the
  moved test rows, and any deviation with its bucket.
- Gate: run the universal test gate twice on scratch stores; record both
  `[SUMMARY]` lines (expect `770/0` plus your suite's rows).

## Model guidance

Tier `deepseek-direct` (owner's ruling): `deepseek/deepseek-flash`,
`--reasoning-effort high`. Split rather than escalate.

## Paste block

```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/armory_panel.gd,vajb-orbit/tests/" crush run "<see S10_prompts.md's S10-B1 block>" -m deepseek/deepseek-flash --reasoning-effort high --cwd "$VAJB_WORKSPACE"
```
