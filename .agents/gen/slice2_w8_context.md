# Slice 2, W8 — re-reviewer context for this pass (2026-09-21)

You are the re-reviewer of engine slice 2, after W7's fixes. Measure, never trust
reports. Read `.agents/gen/slice2_review_report.md` (W6's findings — the authority),
`.agents/gen/slice2_w7_report.md` (the fixer's claims), and
`.agents/gen/slice2_owner_rulings.md` (the four rulings of this wave). Then verify.

## 1. What must now measure green

| Finding | What W7 claims | How to falsify |
|---|---|---|
| **F1** HIGH — a shot's damage never reached a ship | `_sink_for(target)` in `weapons.gd:~707` and `projectile.gd:~521` resolves the sink through the collider's nearest ancestor in the `player_ship`/`npc_ship` groups | re-run W6's own probe (`.agents/gen/slice2_w6_probe_source.gd`, restore it to `res://tools/` as `_probe_w6_slice2.gd`). It read `ok=124 failed=2` before; W7 claims `ok=126 failed=0`. Its sections B (laser at 300 u must drain ~30 shield/s) and C (a bolt must charge the hull ~27) are the two that were red |
| **F2** MED — the ammo half of §4.3 was inert | `PlayerProfile.set_ammo(weapon_id, rounds)` added, mirroring `set_vitals` | fire, dock, read the filed pack back; `game.gd:_file_ammo_report`'s guard must now pass |
| **F4** MED — two §10 blip requirements unmet | `ui/hud/minimap.gd` gained a `ghost` kind with the time-based alpha (0.3–0.7 at 6 Hz) and a `swarmer` kind mapping to the hostile colour | read the map back; confirm the existing kinds' colours did not move and no new theme item or hex literal appeared |

**The universal gate must read the measured total with ZERO failures.** It was
**217/0** when the orchestrator last ran it (W7 added `test_engine2_fixes.gd`,
17 tests). Measure it yourself; the brief's 53 and the earlier 78/200 are stale.

## 2. The rulings of this wave — verify against them, not the brief

- **R5: `countermeasure_chaff` = Z and `countermeasure_flare` = X.** The
  orchestrator bound both through godot-ai (finding F5). Verify on disk in
  `project.godot` (keycodes 90 and 88) and that a real key event reaches the
  spend; also confirm the input map now holds **20 actions** and that
  `consume_fuel_cell` is still **R** (not §11's C) with `cargo_toggle` on C.
- **R6:** the mine's borrowed alpha 180 and the kinetics' borrowed 0.6 s cadence
  are **accepted** as the spec's numbers; the next spec pass records them. Do not
  flag them as invented constants.
- **R7/R8:** the UI chrome regression (`.agents/gen/ui_chrome_regression.md`) is
  routed to the graphics lane (re-cut the plates tight) and the backdrop work is
  sized for **4K** (a 2× cut owed for every large element). Both are open-owner /
  art-lane items, **not** slice-2 findings.
- The assets re-layout stays environment-deferred
  (`.agents/gen/asset_path_fallout.md`).

## 3. Still open, and deliberately not fixed

W6's F3 (the item-5 delivery seam has three owners — a refactor, no behaviour
change), F7 (W3's six spec holes), F8 (`cm_*` have no `03` §3 row), F9 (06's prose
hauls — **now closed** by a separate doc worker: the fighter reads 2.15 units /
28.375 CR / 11.83 % empty, freighter 2.30, corvette 1.50, maw 6.375 with a 1025 CR
floor and 1584.75 mean; verify those landed), F10 (a credit cache has no distinct
visual — needs art), F11 (a doc pointer — **now closed**: `11_galactic_map.md` §3
cites `18_engine_spec §13`). The LOW backlog is `.agents/gen/LOW_BACKLOG.md`
L19–L29, including L19's `hud.tscn` follow-up, which W6 ruled **acceptable**.

## 4. Your deliverables

- **`docs/CONTRACTS.md`** — you are the only writer in this wave. Update the
  changelog with this pass, and §1 to record the two countermeasure bindings as
  **applied** (Z/X), alongside `consume_fuel_cell` = R. Record the R5/R6 rulings
  so the next wave does not re-litigate them. Confirm §9 carries the measured
  total.
- **`.agents/gen/slice2_w8_report.md`** — a per-finding verification table
  (claim, method, measured, verdict), the final gate output, and a wave-close
  statement naming every item still open with its owner.

## 5. Rules

- Your file set is `docs/CONTRACTS.md` + `vajb-orbit/tools/` (write probes with
  the `write` tool; delete them with their `.uid` before the report, leaving
  `tools/` holding only `build_theme.gd` + `derive_icon_tints.gd`).
- Bounded headless runs only (`--quit-after`), stdout to a log you read, nothing
  left in the background.
- No invented numbers. A missing spec value is reported, never guessed.
