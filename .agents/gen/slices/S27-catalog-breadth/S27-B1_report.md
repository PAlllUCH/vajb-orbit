---
slice: S27
worker: S27-B1
model: "hyper/deepseek-v4.1-flash (reasoning xhigh)"
status: actionable
gate: "1275/0 → 1291/4 (4 moved pinned rows, all out of B1's file set — see Deviations)"
---

# S27-B1 report

## Result
A1–A7 land in the seven in-set files: 20 new `test_s27_catalog.gd` rows all pass
(+16 net: 1275→1291 passed, 4 moved existing rows below). New: 4 prefixes + 3
suffixes + 15 `<base>_mk2` variants (module_catalog), the three new perks' §20
consumers (affixes), 4 archetype loot tables (loot_tables), `game/shipyard.gd`
(hull/module recipes, queue, scrap) + its `PlayerProfile` store, the SHIPYARD
BUILD/QUEUE/SCRAP views, and the tier-4 rider. Gate run twice on fresh scratch
stores: identical `passed=1291 failed=4` both times.

## Acceptance list answers
- **A1 — DONE** — the 7 R-S27-2 rows (`dense`/`quickwarm`/`layered`/`farflung`
  `module_catalog.gd:222-256`, `echoes`/`long_watch`/`pyre` `:281-298`); family bands
  respected, values in the tier bands, seeded 5 000-instance roll probe.
- **A2 — DONE (flight wiring reported)** — every §4 suffix row names its `consumer`
  and the three new consumers live and are exercised at the §20 seam
  (`affixes.gd:104-152`: `echoes_refunds` every 5th shot, `lock_channel_seconds`
  +2 s, `pyre_ring_damage` 50 below 25 % hull); the "displayed, never applied" note
  is deleted (`module_catalog.gd:717`). The three flight call sites are out of set —
  `weapons.gd:_consume_ammo_at`, `game.gd:_update_lock`, `game.gd:_on_npc_died`.
- **A3 — DONE** — 15 `<base>_mk2` rows (`module_catalog.gd:735-830`), each one tier
  up with the family headline ×1.15, CR in 01's L2 band for the tier, and in
  `Auction.sale_pool` one tier up.
- **A4 — DONE** — `interceptor`/`turret`/`sibelon`/`boss` tables in 06 §3 format
  (`loot_tables.gd:110-171`), grade-clean, seeded EV over 20 000 rolls.
- **A5 — DONE (session hook reported)** — `game/shipyard.gd`: 9 hull recipes (10 §3.1
  verbatim), module recipes by the §3.2 shape rule with CR totals re-derived from live
  02/03 values (`materials_value`), the §3.3 queue (one at a time, committed at queue,
  full refund on cancel, persists, one in-space session) and the 50 % round-down scrap.
  `shipyard_panel.gd/.tscn` gain HANGAR/BUILD/QUEUE/SCRAP views in the shell-v2 idiom.
  The session hook (`Shipyard.note_flight`) has no in-set production caller.
- **A6 — DONE** — 6 tier-4 variants priced 9 000–12 000 CR; `tier_pool(4)` non-empty
  and `_reserved_tier` (`auction.gd:427-436`) clamps to `MAX_MODULE_TIER` 4, so a
  tier-4 sector's reserved slot reserves tier 4.
- **A7 — DONE** — every new price re-derives from the ladder
  (`test_a7_every_variant_price_derives_from_the_ladder`); the value table below.

## Deviations from SLICE.md
1. **Bucket 2 — B1's file set is under-scoped for A2.** The three new perks' consumers
   exist at the §20 seam (`affixes.gd`) but the flight call sites live in
   `game/weapons.gd` and `game/game.gd`, neither in B1's set: `_consume_ammo_at` skips
   the spend when `Affixes.echoes_refunds(...)`; `_update_lock` reads
   `Affixes.lock_channel_seconds(_launch_summary, LOCK_CHANNEL)`; `_on_npc_died` applies
   `Affixes.pyre_ring_damage(...)`. Reversal: seam-only helpers (never applied again).
2. **Bucket 2 — B1's file set is under-scoped for A5's play gate.** The session counter
   is `Shipyard.note_flight(profile)`; its production caller is `game.gd`'s launch path
   (out of set). Reversal: a real-time gate.
3. **Bucket 2 — the tests-that-move list (§8) is wrong; 4 pinned rows move and B1 cannot
   edit them (tests/ is not in its set).** `test_engine2_loot.gd:431` asserts
   `boss`/`turret`/`sibelon` are **not** tables (A4 requires them); `test_s3_instances.gd:192`
   pins seeded affix picks (the 7 new rows change the pools); `test_s6_poi_loot.gd:129,208`
   iterate a transcribed kind set (the 4 new kinds). Reversal: drop the new rows/kinds.
4. **Judgment call (unpinned): the variant set.** R-S27-1 does not enumerate bases.
   Shipped: one variant per non-weapon, non-exclusive base with a clean numeric headline
   (weapons excluded — a `w_*_mk2` has no `weapons.gd FAMILIES` row; engines excluded —
   `speed_mult` is clamped at `ENGINE_MULT_CEILING` 1.40). Reversal: add them with their
   FAMILIES rows.
5. **Judgment call: `tier_pool(4)`.** Variants at tiers 2–4 stay out of `tier_pool` (the
   pinned partition covers tiers 1–3) and reach the shelf via the new `Auction.sale_pool`;
   only tier-4 rows join `tier_pool` (T-153). Reversal: read `MODULES ∪ VARIANTS` there.
6. **Judgment call: prefix bands.** R-S27-2 names the four stats but no values; bands are
   the family's existing shape (weapons damage/fire-rate 8/12/16 %, armour pool and weapon
   range 10/15/20 %). `layered`/`farflung` are stored but unread (staged, like `overflowing`).

## Evidence
- Gate, fresh scratch store, runs 1 and 2 identical: `[SUMMARY] passed=1291 failed=4`.
- The 4 failures: `test_engine2_loot.gd.test_unknown_kinds_are_not_tables`,
  `test_s3_instances.gd.test_the_seeded_outcomes_are_pinned`,
  `test_s6_poi_loot.gd.test_roll_band_expected_hauls_hold_within_five_percent`,
  `test_s6_poi_loot.gd.test_the_shipped_tables_and_roll_are_untouched`.
- 20/20 `test_s27_catalog.gd` rows pass (A1 4, A2 4, A3 3, A4 2, A5 5, A6 1, A7 1).
- Command: `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200`.

## Moved values (A7) — reversal + tick
| Value | New | Reversal | Tick |
|---|---|---|---|
| `dense`/`quickwarm`/`layered`/`farflung` prefixes | 8/12/16 % weapons, 10/15/20 % armour/range | rows deleted | K2 |
| `echoes`/`long_watch`/`pyre` suffixes | 1/5 shots free, +2 s lock, 50-dmg ring <25 % hull | rows deleted | K2 |
| `SUFFIXES[*].consumer` | the seam each perk fires at | drop the key | K3 |
| 15 `<base>_mk2` variants | tier+1, headline ×1.15, cost = ladder step clamped to L2 | rows deleted | K1 |
| `interceptor`/`turret`/`sibelon`/`boss` loot kinds | 06 §3 tables (bands 1/2/2/3) | kinds deleted | — |
| `Shipyard` hull recipes | 10 §3.1 materials + labour, CR re-derived live | `shipyard.gd` deleted | — |
| `PlayerProfile.shipyard_job`/`shipyard_session` | the queue + play gate | drop the keys/doors | — |
| `Auction.sale_pool`; `tier_pool(4)`; `_reserved_tier`→4 | variants listable, tier 4 reserved | clamp back at 3, skip the slot | T-153 |

## Files touched
- `game/module_catalog.gd` — 4 prefixes, 3 suffixes + `consumer`, `VARIANTS`/`MAX_MODULE_TIER`, `module()`/`icon_path()`/`variant_ids()`/`variant_pool()`, note deleted
- `game/affixes.gd` — the three new perks' §20 consumers + constants
- `game/loot_tables.gd` — 4 archetype tables + `TABLES` kinds
- `game/auction.gd` — `sale_pool`, `tier_pool(4)`, `_reserved_tier` to 4, `_draw_listings`
- `game/shipyard.gd` (+`.uid`) — new: recipes, queue, scrap
- `autoload/player_profile.gd` — shipyard store (4 doors), `grant_ship`, `remove_ship`
- `ui/station/shipyard_panel.gd`/`.tscn` — BUILD/QUEUE/SCRAP views
- `tests/test_s27_catalog.gd` — 20 rows, one per AC

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Wire the 3 new perks' flight call sites | code (out of set) | `game/weapons.gd:_consume_ammo_at`, `game/game.gd:_update_lock`/`_on_npc_died` |
| Call `Shipyard.note_flight` at launch | code (out of set) | `game/game.gd` launch path |
| Update the 4 moved pinned test rows | test (out of set) | `test_engine2_loot.gd:431`, `test_s3_instances.gd:192`, `test_s6_poi_loot.gd:129,208` |
