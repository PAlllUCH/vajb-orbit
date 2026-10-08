---
slice: S24
worker: S24-B1
model: deepseek-v4.1-flash (hyper)
status: actionable
gate: "1152/0 → 1170/0 (twice, fresh scratch stores)"
---

# S24-B1 report

## Result
The nine docking places are rows in `game/station_registry.gd` (W3 name + character line,
sector, kind, faction, the section 1/8 matrix); the docked place resolves from the new
`PlayerProfile.docked_station` seam filed by `game.gd` beside the faction; the shell plate's
two labels read the row, the dead `has_method(&"n")` branch is gone, OVERVIEW block 4 shows
U2's unavailable state and the vault read resolves the place's own record. The V1/V2 price law
has one owner live on the repair fee, the ammo pack, the hull list and the module list, with
the Meridian commission station-aware and the exchange's quotes band-free (`passed=1170 failed=0`
twice on fresh scratch stores; `test_s24_world.gd` adds 18 rows).

## Acceptance list answers
1. **A1 registry + matrix** — nine rows, verbatim W3 pair, per-row sector/kind/faction; every
   row contracts/refuel/recharge/vaults/bounty, Concord primaries no arena, Choir primaries no
   insurance, Meridian primaries the full menu, the three outposts §8's three + the free pair
   at vault tier 1 — `game/station_registry.gd:98-265`; probes `:test_the_registry_carries_the_nine_places`,
   `:test_the_service_matrix_is_section_1_and_8s`.
2. **A1 the place resolves from the seam** — `docked_station_id`/`docked_station` (row → the
   id's own sector primary → `{}`), filed by `game.gd:_file_docked_station` beside the faction —
   `game/game.gd:1346-1353`, `autoload/player_profile.gd:1900-1911`; probe `:test_the_dock_files_the_station_beside_the_faction`.
3. **A1 the plate reads the row** — `_apply_identity` fills `StationName`/`StationLocation` from
   `name`/`character` and pushes the pair to OVERVIEW — `ui/screens/station.gd:797-827`; probe
   `:test_the_shell_plate_reads_the_row` (S3 reads `Spanport Meridian` + the character line, no placeholder).
4. **A1 dead branch** — deleted in both `_docked_faction` twins — `ui/screens/station.gd:624-631`,
   `ui/station/overview_panel.gd:660-666`; probe `:test_the_dead_faction_fallback_is_gone`.
5. **A1 OVERVIEW unavailable state** — row `disabled` + the U2 reason caption in `text_dim`
   inside the pinned row box — `ui/station/overview_panel.gd:541-568`; probes
   `:test_the_overview_marks_an_unavailable_service`, `:test_the_overview_state_change_moves_no_box`.
6. **A1 the vault record** — the docked station's own record, never the sum —
   `ui/station/overview_panel.gd:571-590`; probe `:test_the_vault_read_resolves_the_docked_station`.
7. **A2 band on the repair fee** — 692 → 761 / 657 / 623 (Shunned / Trusted / Champion) —
   `game/repairs.gd:66-113`; probe `:test_the_band_multiplier_moves_the_repair_fee`.
8. **A2 band on the pack and the hull list** — `StationCatalog.ammo_pack_price` (120 → 132 / 114 /
   108) and `ship_price` (9 000 → 9 900 / 8 550 / 8 100) — `game/station_catalog.gd:265-282`; probes
   `:test_the_band_multiplier_moves_the_ammo_pack_cost`, `:test_the_band_multiplier_moves_the_hull_list_price`.
9. **A2 additive tech discount** — Champion of the Choir on `w_proton` = 0.75 × 5 200 = 3 900,
   and the armory pane's own `_module_price` reads it — `ui/station/armory_panel.gd:3054-3065`;
   probe `:test_the_module_price_stacks_the_tech_discount_additively`.
10. **A2 Meridian commission** — 1.5 % at a Meridian station, 2 % elsewhere, floor and ammo
    exemption unchanged, read by the profile-threaded quote — `game/exchange.gd:116-158`; probe
    `:test_the_meridian_commission_reads_1_5_percent`.
11. **A2 exchange band-free** — gross/unit/fee identical across bands; probe
    `:test_the_exchange_quotes_take_no_band_multiplier`.
12. **A2 shelf bias** — 2.0 for the owner's own families, 1.0 otherwise (Concord armour +
    engines, Meridian computers + boosters + storage, Choir shields + plasma + proton) —
    `game/station_registry.gd:429-431`; probe `:test_shelf_bias_returns_two_for_the_owners_families`.
13. **A6 interface + seams** — the registry accessors, the profile seam, the price order (list →
    1 + band − tech → the hot row's −20 % last) and the seams S25/S26 read ship with probes:
    `contracts_visible` (`:417`), `insurance_multiplier` (`:423`), the vault record — `:test_contracts_visible_and_the_insurance_seam`.

## New values (reversal · tick)
| Value | Where | Tick | Reversal |
|---|---|---|---|
| the nine rows (id/name/character/sector/kind/faction) | `station_registry.gd:98-265` | W3 | rename or delete a row |
| the service matrix (7 booleans/row) | the rows | §1/§8, no tick | edit the row |
| `vault_tiers` 1 (outpost) / 3 (primary) | the rows | derived §8 + §4 | drop the key; hide tiers 2/3 by kind |
| the two reason captions (verbatim) | `:95-96` | U2 | captions drop, rows hidden |
| band deltas +0.10 / 0 / −0.05 / −0.10 | `:61-66` | V1 (PROPOSED) | one constant each |
| `TECH_DISCOUNT` 0.15, additive | `:56` | V2 (PROPOSED) | 0.0, or multiplicative |
| `SHELF_BIAS_OWN/OTHER` 2.0/1.0 and `TECH_FAMILIES` (3 owners × 2–3 families) | `:39-43,77-78` | V6 (PROPOSED) | uniform: 1.0 for every family |
| `CONTRACTS_FLOOR` −11 | `:69,417` | V3 (PROPOSED) | `standing >= 0` |
| `INSURANCE_CHAMPION` 0.8 | `:72,423` | V7 (PROPOSED) | return 1.0 |
| `COMMISSION_MERIDIAN` 0.015 | `exchange.gd:63` | 12 §3 / 14 §3 | one constant |
| `_docked_station` seam (no save key, no version bump) | `player_profile.gd:289-293` | 14's 2026-10-08 block | derive the place from the sector's primary |
| `VAULT_BASE_CAPACITY` 40 (unchanged) | `overview_panel.gd:70-74` | U14 | read the record's tier into the denominator |

## Deviations from SLICE.md
1. **`refuel`/`recharge` are true at every row, outposts included.** §8 lists three services for
   an outpost but does not revoke §1's own refuel row ("every station; free and instant", owner
   2026-09-20/21), and `Repairs.refuel` gates on the catalogue's `availability: all`. Reversal:
   set both false at the three outpost rows.
2. **`vault_tiers` is derived, not stated**: §8 caps an outpost at "vault tier 1" and §4's range
   is tiers 1–3, so a primary carries 3. No other number was invented (reversal above).
3. **The hull list price has one reader and no shipped caller.** `StationCatalog.ship_price` is
   the wave's figure (SLICE.md's own line), but the auction's two reads (`game/auction.gd:500-512`
   `hull_rows`, `:757` `buy_hull`) still take `SHIPS.cost` directly and `auction.gd` is B2's file.
   Wired at the catalogue and probed; the call sites are reported, not guessed.
4. **`fitting_panel.gd` carries no price read** (measured: no `price`/`cost`/`CR` match), so the
   merged ARMORY pane is the module-price site; no edit was needed there.
5. **The same dead branch sat in `overview_panel.gd:_docked_faction`** (the twin helper) and is
   deleted there too; the row's own faction answers when the profile names none.
6. **`set_identity` moved from `_build_panels` into `_apply_identity`**, so OVERVIEW receives the
   row's text and the header stays the one source of truth.
7. **Measured A5.5 note:** the caption swap grows the readout label's own min width (84 → 284 px)
   inside the pinned 76-tall row; the row box, the chip and the caption's line box do not move.
8. **`station_registry.gd.uid` does not exist yet** — Godot mints it on the editor's next scan.

## Evidence
- Gate, twice on fresh stores: `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 2400` → `[SUMMARY] passed=1170 failed=0`, exit 0.
- `-- --suite=test_s24_world` → `[SUMMARY] passed=18 failed=0` (the +18 delta is this suite alone).
- Pre-existing, not a regression: the 4-instance `ObjectDB` leak + `amb_station_room_01.ogg` at exit
  is what `--suite=test_s30_shell` (also a station mount) prints today.

## Files touched
- `game/station_registry.gd` — **new**: the nine rows, the matrix, the price law, the two seams.
- `game/station_catalog.gd` — `ammo_pack_price` / `ship_price`, the two station-aware readers.
- `game/repairs.gd` — `fee` through the registry's factor (`_station_price`/`_standing`).
- `game/exchange.gd` — `commission_rate`, threaded through quote/sell/sell_all/_flush_queue.
- `game/game.gd` — `_file_docked_station` beside `_file_docked_faction`.
- `autoload/player_profile.gd` — the transient `docked_station`/`set_docked_station` seam.
- `ui/screens/station.gd` — the plate's two labels, the overview push, the dead branch gone.
- `ui/station/overview_panel.gd` — the availability state, the vault record read, the dead branch gone.
- `ui/station/armory_panel.gd` — `_module_price` + the pack cards' station price.
- `tests/test_s24_world.gd` — **new**: 18 rows.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| the auction's hull rows and `buy_hull` read `SHIPS.cost` directly, not `StationCatalog.ship_price` | LOW (V1 consumer) | `game/auction.gd:500-512,757` |
| outpost **nodes** (the three rows are data + tests only) | staged by the brief | `game/sector.gd:_spawn_station` |
