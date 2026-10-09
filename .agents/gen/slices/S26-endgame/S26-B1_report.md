---
slice: S26
worker: S26-B1
model: "deepseek/deepseek-v4.1-flash (reasoning xhigh)"
status: actionable
gate: "1237/0 → 1254/3 (the 3 are S25's seam rows; see Deviations D1)"
---

# S26-B1 report — the endgame (A1–A8)

## Result
The endgame ships: two physical arenas with their contract run, three released bosses at
R-S26-1's fits paying M10's 6 000/12 000, the Maw roaming S7 rolling 06 §3.4 exactly, death
that persists and pays through insurance (M14), per-station vaults, and the INSURANCE/VAULTS
panels in the SERVICES deck. New suite `test_s26_endgame.gd` = **20 rows, all passing**; the
only red rows are three of `test_s25_contracts.gd`'s seam assertions (D1).

## Acceptance list answers
- **A1 — DONE** — `NpcRegistry.ARENAS` places The Boneyard (S3, `boneyard`) and The Pyre (S6,
  `pyre`), and `game.gd:_build_arena_zone` builds the lit ring from the shipped
  `env_arena_nav_pylon`/`env_arena_barricade` renders (8 pylons + 8 barricades, r 1200) as a
  child of the sector; an entry with no open run spawns nothing — `npc_registry.gd:216-260`,
  `game.gd:_build_arena_zone`; `test_a1_*` (2 rows).
- **A2 — DONE** — the Expedition row is live at an arena station (`staged=false`, `boss`
  named) and stays the greyed seam elsewhere; `accept` opens a 60 s window and refuses a boss
  on its 20-minute clock; the scene spawns the boss on ring entry; the run settles at
  return-to-station, paying only on the player's last hit — `contract_registry.gd:_expedition_row,
  accept, arena_entry_open, arena_credit_kill, arena_settle, arena_settle_all`,
  `game.gd:_on_player_hit, _settle_arena_runs`; `test_a2_*` (4 rows).
- **A3 — DONE** — `NpcRegistry.boss_stats` scales the gunship (Boneyard ×2.5, 5 W) and the
  frigate (Pyre ×2.5, 4 W) and pins the Maw at 12 000/6 000, 7 W, 0.5× freighter speed;
  payouts are 6 000/12 000 with magic/rare module floors; the Maw rolls `MAW_LINES` over 20 000
  seeded rolls with EV 1584.75 (±5 %) and the 1 025 CR floor — `npc_registry.gd:BOSS_HULLS,
  boss_stats, boss_weapons`, `contract_registry.gd:EXPEDITION_PAYOUTS, ARENA_REWARD_FLOOR`,
  `loot_tables.gd:90 MAW_LINES`; `test_a3_*` (3 rows).
- **A4 — DONE** — the wreck ledger (`GameScript._wreck_drops`, a static) outlives the scene the
  death happened in, so a rebuilt scene re-materialises the pre-death pickup, and
  `_respawn_docked` routes `DESTINATION_STATION` — `game.gd:_drop_cargo_at_wreck,
  _materialise_wreck_drops, _respawn_docked`; `test_a4_the_wreck_window_survives_the_respawn_route`.
- **A5 — DONE** — the premium is M14's 1.5 % of the §3 class row's cheapest hull list
  (135–1 080), charged at launch, one loss, Champion ×0.8 through S24's seam; the payout
  credits hull+fit and replaces into the tier's cheapest base hull; Choir sells none; the
  mercy clause reissues a bare Fighter once — `player_profile.gd:insurance_premium,
  insurance_charge, insurance_payout`, `game.gd:_charge_insurance, _apply_insurance_payout`;
  `test_a5_*` (4 rows).
- **A6 — DONE** — one vault per station in the shipped `{tier, contents}` record, 20 base
  (+20/tier, Meridian 40 at ×1.25 tiers), free deposit/withdraw, persistent and outside
  `cargo_items()`, and `u_vault` adds +20 — `player_profile.gd:vault_capacity, vault_rent,
  vault_deposit, vault_withdraw, owns_u_vault`; `test_a6_*` (3 rows).
- **A7 — DONE** — `insurance_panel.tscn/.gd` and `vaults_panel.tscn/.gd` mount real (not the
  D11 placeholder) in the SERVICES deck beside S25's strip, carrying §15.3/§15.4's surfaces;
  every pane still expands and the strip still holds three — `test_a7_*` (2 rows).
- **A8 — DONE** — every moved value is tabled below with its reversal and tick; the payouts
  cite M10, the premium cites M14 — `test_a8_the_moved_values_are_the_documented_ones`.

## Deviations from the brief / SLICE.md (every one reversible)
| # | Deviation | Why | Reversal | Tick |
|---|---|---|---|---|
| D1 | Flipping the seam live makes **3 of `test_s25_contracts.gd`'s rows fail** (`:239`, `:464-477`, `:1146+` — all assert the Expedition row is staged at `s3_primary`) | A2 is explicit that the U7 row un-greys; s3_primary is the Meridian arena's desk. **Not editable in B1's set** (the worker-file hook denies `tests/`); R1 owns `vajb-orbit/tests/` | leave the row staged (breaks A2) | — |
| D2 | The bosses are spawned by `game.gd` (`_spawn_arena_boss`/`_spawn_maw`), not the sector band | `ship_fit.gd` (read-only) carries no boss class row, and `sector.gd` (read-only) cannot apply ×2.5; `boss_stats` is the one derivation | add boss class rows to `ship_fit.gd` and let the band spawn them | — |
| D3 | The two arena bosses are **synthesised** in `archetype()` from `BOSS_HULLS`, not added to `NPCS` | keeps `NPCS` at the shipped nine, so `test_engine2_npc.gd:54`'s nine-row assertion holds | add them to `NPCS` (and move that assertion) | — |
| D4 | A2's "payout on return-to-station, win or lose" read as: the run **closes** at return either way; the **payout requires the player's last hit** | the kill-credit rule is otherwise meaningless | pay on return regardless of credit | — |
| D5 | The premium is keyed on the **§3 class row's cheapest hull** (the six rows), not the active hull's own list | §15.3's premium table is six rows and the payout tier is the same row; a Corvette pays 240, not 405 | the active hull's own list | M14 |
| D6 | The mercy clause is the **shipless rescue** (fleet empty after the loss); the payout flow's replacement applies when another hull remains | §3's two clauses cannot both fire on one loss | grant the tier's cheapest instead of mercy | — |
| D7 | Vaults use the **shipped `{tier, contents}` record** (S24's `overview_panel.gd:574` reads it); the tier lives there, not in a new key | S24 is read-only and its test pins the shape | a separate `vault_rents` key | — |
| D8 | `overview_panel.gd:74`'s `VAULT_BASE_CAPACITY := 40` disagrees with §4's 20 base, so the OVERVIEW row and the VAULTS panel differ at tier 0 | S24's own PROPOSED reading (its comment admits the reversal); S24 is read-only | read the record's tier into the denominator | — |
| D9 | New PROPOSED values: ring centre `(0,-2600)` r 1200, pylon/barricade draw 180/220 u, Maw spawn `(0,-4200)`, arena reward pool = the priced non-exclusive catalogue | no doc places them | the sector origin / the full catalogue | — |

## A8 — every moved value, its reversal and tick
| Value | Was | Now | Source | Reversal | Tick |
|---|---|---|---|---|---|
| Boneyard Behemoth payout | 15 000 CR (14 §5) | **6 000 CR** | 14's S28 block; 01 §L3 | 15 000 | M10 |
| Pyre Hierophant payout | 40 000 CR | **12 000 CR** | 14's S28 block | 40 000 | M10 |
| Insurance premium | §3 flats 200–700 | **1.5 % of the class row's list, 135–1 080** | 14's S28 block; 01 §L4 | the flats | M14 |
| Boneyard hull | none | gunship ×2.5 (3 500/1 625), 5 W | 08's P3 block | per-row edit | E1 |
| Pyre hull | none | frigate ×2.5 (4 500/2 000), 4 W | 08's P3 block | per-row edit | E1 |
| Maw hull | 12 000/6 000, 7 W | same (released) | 08's P3 block | per-row edit | E1 |
| Maw roam | seam | S7, aggro 600 u, 0.5× freighter speed | 14 §5 | staged | E2 |
| Arena ring / window / clock | none | r 1200 ring, 60 s entry, 1 200 s cooldown | 14 §5 | — | — |
| Vault capacity / tiers | none | 20 base, 500/1 200/2 400, Meridian 40 at ×1.25 | 14 §4 | — | — |
| `u_vault` | no consumer | +20 units every vault | 15 §5 | — | — |

## Evidence
- Gate twice, fresh scratch stores, identical:
  `XDG_DATA_HOME=/tmp/s26_f1 godot --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 2400` → `[SUMMARY] passed=1254 failed=3`;
  the same with `/tmp/s26_f2` → the identical line. Baseline on `/tmp/s26_base_store` →
  `passed=1237 failed=0`.
- Row-level: the 20 `[PASS] test_s26_endgame.gd.*` lines are all A1–A8; the 3 `[FAIL]` lines
  are all `test_s25_contracts.gd`'s seam rows (D1). No other suite moved (`test_engine2_npc`,
  `test_s24_world`, `test_s6_poi_loot`, `test_engine2_loot`, `test_s28_econ` unchanged).
- A3's table: `test_a3_the_maw_rolls_06_3_4` rolls `MAW_LINES` 20 000× seeded and asserts the
  EV within 5 % of 1 584.75 and the floor exactly 1 025 (3×`comp_scrap_3`@75 + 800).
- A5's once-only: `test_a5_the_mercy_clause_fires_once` — first loss `mercy=true`, second
  `mercy=false`; `test_a5_charge_and_payout_flow` proves the purse moves by exactly the
  premium and the credit is the hull+fit value.

## Files touched
- `game/npc_registry.gd` — `BOSS_HULLS`, `boss_stats/boss_weapons/boss_sprite`, `ARENAS`,
  `arena_zone/arena_boss/has_arena`, the released Maw row, the synthesised arena-boss rows.
- `game/loot_tables.gd` — no change (its `MAW_LINES` finally has a feeder).
- `game/contract_registry.gd` — the live Expedition row, `arena_*` (window, cooldown, credit,
  settle, reward roll), `EXPEDITION_PAYOUTS`/`ARENA_REWARD_FLOOR`.
- `game/module_catalog.gd` — `roll_rarity`'s floor + `arena_pool()`.
- `autoload/player_profile.gd` — arena-run clock, vault record/tiers, the M14 premium, charge
  and payout; new save keys `arena_runs` (vaults reuse the shipped key).
- `game/game.gd` — the arena ring, boss spawn, Maw roam, kill credit, insurance charge/payout,
  arena settle at dock/respawn.
- `ui/screens/station.gd` — unchanged (the strip already mounts `insurance`/`vaults`).
- `ui/station/insurance_panel.{gd,tscn,gd.uid}` + `vaults_panel.{gd,tscn,gd.uid}` (new).
- `tests/test_s26_endgame.gd` (new) — 20 rows, A1–A8.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| `test_s25_contracts.gd`'s 3 seam rows (D1): point them at the S26 reading, or move the staged-row assertions to a non-arena station | [TEST] | `tests/test_s25_contracts.gd:239,464-477,1146+` (R1's set) |
| `overview_panel.gd`'s `VAULT_BASE_CAPACITY` 40 vs §4's 20 base (D8) | [DOC/CODE] | `ui/station/overview_panel.gd:74` |
| The arena props (`env_arena_nav_pylon`/`env_arena_barricade`) are shipped but absent from the generated `ASSET_CATALOG.md` | [DOC] | `docs/design/ASSET_CATALOG.md` |
