---
slice: S21
worker: S21-B2
model: deepseek/deepseek-flash (reasoning-effort max)
status: actionable
gate: "930/1 → 936/1 (+6 = this worker's six rows; the one failure is S19's byte-seal row, B1 disclosure (b) / B3's re-pin)"
resumed: post-crash resume — the edits were on disk, this report unwritten; two defects the draft carried were repaired on resume (Deviations (a))
---

# S21-B2 report — post-crash resume

## Result
A4a/A5/A6/A7/A8 landed; `tests/test_s21_stability.gd` 14 → 20 rows (`--suite=…` → `20/0`). The gate
reads `[SUMMARY] passed=936 failed=1` on a fresh scratch store **and** on a copy of the live account;
the live file was byte-identical before/after (md5 `f51190c8…f7010f`).

## Acceptance list answers
- **A4a — DONE.** The market advances only at the dock (`station.gd:189` `on_route` →
  `_normalise_market` `:199`), the AUCTION shelf only at pane switch (`auction_panel.gd:200`
  `_ready` draws read-only through `_draw_pane` `:244`; `enter_pane` `:234` rolls, reached from
  `focus_primary`), and the EXCHANGE pane's build-time `_evaluate()` moved to `focus_primary`
  (`exchange_panel.gd:164,204-207`). Row `test_s21_stability.gd:739` mounts the whole shell with a
  **stale** band and an **empty** shelf: `_dirty` false, both records unchanged, file md5 + mtime
  unchanged; then `on_route` normalises and the switch rolls the shelf. (A4b is B1's, green.)
- **A5 — DONE.** The four fixtures build their own fit **and** its packs/hold (dock
  `test_engine2_dock.gd:58-59,268`, fixes `test_engine2_fixes.gd:62-63,162`, wiring
  `test_engine2_wiring.gd:45-46,107`), each `_restore_fixture` handing back `_ammo`, `_cargo` and
  `_ammo_rem`; slot order reads the launched `_state.weapons` (dock `:254`, fixes `:569`, wiring
  `:325`), never `PlayerState.WEAPONS`. Gate count on scratch and on a live copy: identical
  (Evidence). Row `:803` measures the shipped launch ordering `[railgun, laser]`.
- **A6 — DONE.** Law (rule 2): **`module_count(id)` is the key-exact record read**
  (`player_profile.gd:576`, note `:562-580`); aggregates read `instances_of(base_id)` (profile
  `:702`, armory `:2128`, `auction.gd:843`) or sum the bag's keys (`fitting_panel.gd:632`
  `_bag_units`, STATION_HUB §5.3's unit count); `take_module` reads its own keyed record and can
  never spend an instance (`:610-618`). Row `:858`: instance-keyed bag → `module_count(w_laser)==0`
  vs 3 `instances_of`; stacked record → count 2 and **one** cell; the take is key-exact; FITTING's
  OWNED ×n counts units (1), the armory's row records (1). `_base_id` fallback: `_lost_entries`
  (`fitting_panel.gd:690`) lists the fit's unresolved ids, `_owned_counts` (`:652`) keys them at 0,
  `_owned_ids` (`:714`) renders them last — **one** row, id-titled, `OWNED ×0` (row `:915`).
- **A7 — DONE.** R-S21-1: `exchange.gd:120` `commission_for_item` pays `roundi(0.02 × gross)` for
  ammo with **no floor**, the one function the quote (`:413`), the transaction and `sell`'s
  quoted-gross re-derivation (`:314`) read; 2 CR gross pays 0 and nets 2, 60 CR pays 1. R-S21-2:
  `KEY_AMMO_REM` holds 0..9 (`player_profile.gd:97,379`); `load_ammo_from_hold` (`:400`) draws the
  bank first, opens units for `ceil(rest/10)`, banks the opened unit's unused rounds (295+1 unit →
  300, bank 5; a 3-round shortfall against a banked 6 keeps 3). LAUNCH: `_cell_ordnance`
  (`launch_panel.gd:672`) = pack + min(shortfall, bank + units×10) over `_fit_weapons` (`:627`), the
  cell list `game.gd:_launch_weapons` writes; row `:967` reads 240 for a twin-cannon fit with 12
  hold units, having drawn nothing.
- **A8 — DONE.** `ACTION_OWNED` (`auction_panel.gd:131`) + `_refresh_hull_row` (`:901,915`): an
  owned hull's row is disabled with `OWNED`; a direct `buy_hull` still refuses with
  `REFUSED · ALREADY OWNED`; an unowned row stays live `BUY` (row `:1066`).

## The accessor law (rule 2)
`module_count(id)` is a key-exact **record** read, never a base-id aggregate; `instances_of(base_id)`
is the aggregate read (one entry per in-bag record); only FITTING's `_bag_units` / `OWNED ×n` counts
*units* (STATION_HUB §5.3). Stated at `player_profile.gd:562-580,601-609`.

## Rows moved (with the reason)
| Suite | Row | Move | Why |
|---|---|---|---|
| gate | `test_s21_stability.gd` | 930/1 → 936/1 | the six rows: A4a 1, A5 1, A6 2, A7 1, A8 1 |
| `test_s5_ammo_cargo.gd` | `…ammo_sale…` `:483-489` | fee 10→1, paid 50→59, credits +50→+59 | R-S21-1 |
| `test_s5_ammo_cargo.gd` | `…hold_surface…` `:541,544` | 50→59, 46→55 | R-S21-1 |
| `test_s5_ammo_cargo.gd` | `…overshoot` `:370-376` | +1 bank assertion | R-S21-2 |
| `test_s5_ammo_cargo.gd` | `_seed_account` `:156` + capture/restore | stages `_ammo_rem` | R-S21-2 hygiene |
| `test_s5_commerce.gd` | `_assert_s3_rendering` `:493-497` | `BUY` → `OWNED` iff owned | R-S21-3 |
| other suites | — | **counts unchanged** | 930 + 6 = 936 |

## Deviations from SLICE.md
- **(a) Post-crash repairs.** (1) The bank dropped its unspent half when the shortfall was smaller
  than it (`player_profile.gd:414-424` now keeps `(bank − spent) + opened×10 − drawn`; the
  partial-bank assertion joined A7's row). (2) The three fixtures aliased the saved dicts
  (`var packs = _previous_ammo`), so `_restore_fixture` wrote the staged values back; now
  `.duplicate(true)` in all three.
- **(b) §7's region `ui/station/outfitting_panel.gd` does not exist.** L124's site (old `:1295`) is
  today's `ui/station/fitting_panel.gd:1451` `_base_id`, so A6 landed there; no pin moves.
- **(c) Two suites outside §8's candidate table moved pinned constants** (`test_s5_ammo_cargo.gd`,
  `test_s5_commerce.gd`): they assert the exchange's fee and the auction's ACTION cell, which
  R-S21-1/R-S21-3 rewrite. **Both keep their row counts**; reported for R1's judgment. Reversal:
  untick M2/M1 and restore the old constants.
- **(d) `ui/station/exchange_panel.gd` was edited though not in §7's region list** — A4a cannot hold
  otherwise: its build-time `_evaluate()` was one of the boot writes, so it moved to
  `focus_primary`; entry behaviour unchanged (it still evaluates on every pane entry).
- **(e) `FIXTURE_PACKS` 120/60 sit below both 300 ceilings** so each fixture's auto-load is a no-op
  read; no doc pins the pair.

## New consts (value + reversal)
| Value | Where | Reversal |
|---|---|---|
| `KEY_AMMO_REM = &"ammo_rem"` | `player_profile.gd:97` | delete it, `_ammo_rem`, `ammo_remainder`, `_set_ammo_remainder` and both file lines; draw whole units |
| `ACTION_OWNED = "OWNED"` | `auction_panel.gd:131` | delete it; render `ACTION_BUY` with `disabled = false` |
| `FIXTURE_PACKS`, `FIXTURE_FAMILIES` | dock `:58-59`, fixes `:62-63`, wiring `:45-46` | test-local; drop them and the staging |

No other new const (`COMMISSION`, `ROUNDS_PER_CARGO_UNIT` are pre-existing).

## Evidence
- Scratch gate — `XDG_DATA_HOME=/tmp/s21_b2_scratch $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=936 failed=1`; only
  `[FAIL]`: `test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical`
  (`res://game/npc_ship.gd` — B1 disclosure (b), B3's re-pin; reported, left).
- Live-copy gate — same command with `XDG_DATA_HOME=/tmp/s21_b2_live` (a copy of
  `app_userdata/Vajb Orbit`, profile md5 `f51190c829131de3138f1322cbf7010f`) →
  `[SUMMARY] passed=936 failed=1`, same failure; the live file's md5/mtime unchanged after.
- `-- --suite=test_s21_stability` → `20/0`; the ten §8 candidate suites together → `108/0`
  (`test_p2b1_outfitting_panel.gd` green).

## Files touched
`ui/screens/station.gd` (dock normalise), `ui/station/auction_panel.gd` (read-only build, OWNED
plate), `ui/station/exchange_panel.gd` (entry evaluation), `ui/station/fitting_panel.gd` (bag law,
lost-row fallback), `ui/station/launch_panel.gd` (remainder-aware strip), `autoload/player_profile.gd`
(remainder + load + law), `game/exchange.gd` (per-item commission), the three `tests/test_engine2_*.gd`
fixtures, `tests/test_s5_*.gd` (pin constants), `tests/test_s21_stability.gd` (six rows).
`game/damage.gd` untouched.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `probe_w3_services.gd` still prints `module_count` as "owned" (L115) | LOW | `tests/probe_w3_services.gd:208` |
| `_row_hint` still formats `action_word` for a hull row (unreachable while disabled) | LOW | `ui/station/auction_panel.gd:1049` |
| The two s5 suites' constants are the reversal sites if M1/M2 are unticked | LOW | `test_s5_ammo_cargo.gd:483,541` |
