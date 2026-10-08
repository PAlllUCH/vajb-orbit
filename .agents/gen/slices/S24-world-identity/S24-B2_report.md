---
slice: S24
worker: S24-B2
model: deepseek-v4.1-flash (hyper)
status: actionable
gate: "1170/0 → 1184/1 (twice, fresh scratch stores; the one failure is the stale S17 md5 pin on sector_registry.gd — bucket 2, left, see Deviations 6)"
---

# S24-B2 report

## Result
A3, A4 and A5 are live: the standing bands gate contracts, the auction and the insurance
seam; the shelf rolls V4's hot pair, V5's reserved slot and V6's owner bias off the station's
own row; every auction price goes through the registry's price law; each sector row carries
R-S24-2's band as its fill order; and the nebula clouds roll, draw and halve the three
readings. `test_s24_bands.gd` adds 15 rows (`--suite=test_s24_bands` → `passed=15 failed=0`);
the full gate moves 1170 → 1184 passed with **one** failure, the S17 `REGISTRY_MD5` pin that
my lawful edit to `sector_registry.gd` necessarily invalidates.

## Acceptance list answers
1. **A3 `contracts_visible`** — true at Neutral/Known/Trusted/Champion, false at Shunned and Outlaw — `station_registry.gd:417`; probe `test_s24_bands.gd:312`.
2. **A3 Known's hot pair** — one guaranteed row + a 50 % second at Known and above, one row at Neutral; measured **36 of 64** seeded shelves carry two — `auction.gd:235,257`; probe `:343`.
3. **A3 both hot rows at `hot_price`** — every hot row on both lists reads `hot_price(station list)`, plain rows the station's own list — `auction.gd:671,944`; probe `:378`.
4. **A3 Trusted's reserved slot** — the first rolled module slot takes the docked sector's tier band (S3 → tier 2 on all 24 seeded shelves), the shelf stays 6 + 20, and at Neutral the ordinary draw reaches tiers {1, 2, 3} again — `auction.gd:381,421`; probe `:420`.
5. **A3 V6 the owner's families ×2** — measured at Cinder Gate: the Choir's own families are **0.2139** of the rolled draw vs **0.0931** station-less, the Concord's fall 0.2181 → 0.1792 — `auction.gd:433`; probe `:454`.
6. **A3 the Champion insurance seam** — 0.8 at Champion and at the floor 71, 1.0 at 70 and below — `station_registry.gd:423`; probe `:325`.
7. **A3 the two axes still hold** — standing −51 refuses the dock, −50 does not, a clean-heat Outlaw at a gate is sold the jump ticket, an Outlaw-heat hull is refused — `game.gd:1014,1033`; probe `:537`.
8. **A3 the auction's price law (B1's gap closed)** — the hull list, `buy_hull`, the module list and `buy_listing` all read `StationCatalog.ship_price` / `StationRegistry.apply_price` (band, then the owner's tech step, then the hot row's −20 % last); a Champion of the Choir on a Choir family reads 0.75 × list — `auction.gd:671,895,944,962,979`; probe `:479`.
9. **A4 the bands are row data** — the seven rows carry R-S24-2 verbatim, in fill order (S1–S2 `[pirate]`, S3–S4 `[pirate, swarmer]`, S5–S6 `[swarmer, sibelon, pirate]`, S7 `[pirate, swarmer]`) — `sector_registry.gd:79-81,126-186`; probe `:577`.
10. **A4 the fill order + the retired source** — the columns sum to 13 §4's densities, a filler outside its row's band is absent, the row's last filler takes the rest (S6: pirate 2-4, swarmer 1-1, sibelon 1-1), and `HOSTILE_FILL` no longer sources a band (`npc_registry.gd:93` retires, `:523` reads the row); probe `:591`.
11. **A4 hunters stay heat-driven map-wide** — no band names one, no population spawns one, the heat path still answers a 2-3 wing — probe `:633`.
12. **A5 V8's roll** — 0–2 rows on the sector's own seeded stream, radius 900, centres ≥ 1500 u from the arena centre and inside the arena; 0, 1 and 2 all occur over 64 rolls — `sector_registry.gd:300`; probe `:659`.
13. **A5 the cloud node** — one node per rolled row, on its own centre, drawing the Void Haze `#1A2230` wash at 15 % alpha (sector 1, seed 1 → 1 cloud) — `sector.gd:116,521`; probe `:684`.
14. **A5 the three readings ×0.5 inside** — lock `×0.5`, the POI channel 150 u, the minimap push `×0.5`, the hull carrying the 15 % tint, `_minimap_radius` (the player's zoom) untouched, wheel included — `game.gd:1241,1258,1277,1291,1691`; probe `:712`.
15. **A5 the shipped values exactly outside** — lock == the fit's own, POI == 300.0, minimap == the zoom exactly, tint `Color.WHITE`, leaving the cloud restores the exact radius — same cites; probe `:762`.
16. **A6 the interface** — `hot_ids`/`second_hot_id` (`auction.gd:235,257`), `SectorRegistry.hostile_band`/`clouds`/`set_clouds`/`roll_clouds`/`in_cloud` (`sector_registry.gd:264,276,290,300,325`), `Sector.clouds`/`cloud_nodes` (`sector.gd:332,342`), the price order (`auction.gd:979`), the S25/S26 seams `contracts_visible` (`station_registry.gd:417`) and `insurance_multiplier` (`:423`).

## Deviations from SLICE.md
1. **V4's second hot row is derived from the shelf's own content, not stored.** CONTRACTS §15 pins `auction` at four members, `PlayerProfile.AUCTION_KEYS` is four (`player_profile.gd:188`) and `test_s3_auction.gd:574` asserts `state.keys().size() == 4`; `player_profile.gd` is outside B2's set, so a fifth key is a pin change this wave may not make. The 50 % roll is the md5 parity of the shelf's own id digest — the shelf the restock's seeded RNG drew — so a seeded restock answers the same pair every time (`String.hash`'s FNV parity measured invariant over a run, rejected). Reversal: one stored key plus `AUCTION_KEYS`' fifth entry.
2. **The reserved slot's tier is clamped into the catalogue's 1–3.** V5 sends it to `SectorRegistry.sector_tier`, which reaches 4 in S6–S7, and no tier-4 module row exists; `clampi` keeps the slot minted, because a dropped slot would break the pinned 6 + 20. Reversal: a tier-4 catalogue row, or no reservation at tier 4.
3. **The cloud roll runs last in `populate`**, so the stream every other population roll reads is byte-identical to pre-S24 (a seeded probe's fields, wrecks, anomalies and hulls do not move). The brief places the roll but not its position. Reversal: move it before the fields.
4. **The roll's outer bound is derived**: 11's block fixes only the 1500 u inner clearance, so a centre sits at most `SECTOR_SIZE/2 − CLOUD_RADIUS` = 4100 u out and a drawn disc never crosses the arena edge. Reversal: drop the bound, or 4500.0.
5. **V6's bias is the rolled draw's, not the stock ten's** — the stock ten are 10 §2.1's fixed tier-I rows ("always something to mount"). Reversal: hand the station row to the stock loop.
6. **`test_s17_gate_edges.gd:52`'s `REGISTRY_MD5` is stale — bucket 2, reported and left.** The brief's §8 "tests that move" table does not list this pin and `tests/` is outside B2's `VAJB_WORKER_FILES`, so the re-pin is R1's (or F1's), the S23 procedure the pin's own comment names: set it to `3661a0d21ad2de97811e40460c597f2a` and disclose it in `S24-R1_review.md`. `gate.gd` is untouched (`c13574f6af658c1fcd4728c34901caf3`).
7. **`ui/station/auction_panel.gd` needed no edit**: it renders the readers' own `price`/`was`/`hot` (`auction_panel.gd:692,738`), so the price law and the second hot row reach the pane through `listing_rows`/`hull_rows`.
8. **V5's reversal route**: an added 21st row is a `10 §2.1` shelf-size amendment, so the forced draw is the only in-pin reading.

## New values (reversal · tick)
| Value | Where | Tick | Reversal |
|---|---|---|---|
| `KNOWN_STANDING` 11 (V4's gate) | `auction.gd:102` | V4 | one constant |
| V4's second row: 50 % by md5 parity, content-derived | `auction.gd:257` | V4 | one stored key + `AUCTION_KEYS` |
| V5's reserved slot, tier `clampi(sector_tier, 1, 3)` | `auction.gd:381,421` | V5 | added 21st row, or no clamp |
| V6's bias on the rolled ten only | `auction.gd:433` | V6 | extend it to the stock ten |
| the seven `hostile_band` rows (verbatim R-S24-2) | `sector_registry.gd:79-81,126-186` | W1 | one row edit |
| `clouds` row key (empty until `populate`) | `sector_registry.gd:127` | V8 | drop the key |
| `CLOUDS_MIN/MAX` 0/2 · `CLOUD_RADIUS` 900.0 · `CLOUD_CLEARANCE` 1500.0 | `sector_registry.gd:90-93` | V8 | one constant each · 600.0 · 1000.0 |
| the roll's outer bound 4100.0 (derived) | `sector_registry.gd:333` | V8 | no bound, or 4500.0 |
| `CLOUD_WASH` `#1A2230` · alpha 0.15 | `sector_registry.gd:98-99` | V8 / W2 | Deep Void Blue `#111823` |
| `CLOUD_RANGE_FACTOR` 0.5 | `sector_registry.gd:104` | W2 | 1.0 (cosmetic tint only) |
| the cloud node's own draw (radius + wash) | `sector.gd:116` | V8 | one node per cloud removed |

## Evidence
- Gate, twice on fresh stores, identical: `XDG_DATA_HOME=$(mktemp -d) $GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 2400` → `[SUMMARY] passed=1184 failed=1` both runs, the one line `[FAIL] test_s17_gate_edges.gd.test_ac6_the_two_forbidden_files_are_byte_identical: sector_registry.gd is byte-identical`. 1184 + 1 = 1185 = B1's 1170 + this suite's 15, so nothing else moved; no `[SKIP]`.
- `-- --suite=test_s24_bands` → `[SUMMARY] passed=15 failed=0`.
- Measured figures (temporary prints, removed): Known's pair **36/64**; the Choir bias **0.2139 vs 0.0931**; the neutral reserved-slot tiers **{1, 2, 3}**; sector 1's first cloud seed **1 → 1 cloud**.

## Files touched
- `game/auction.gd` — V4's pair, V5's reserved slot, V6's bias, the price law on both lists.
- `game/sector_registry.gd` — the two row keys, the band/wash/range constants, the roll.
- `game/npc_registry.gd` — `_hostile_column` reads the row; `HOSTILE_FILL` retires as source.
- `game/sector.gd` — the `Cloud` node, `_spawn_clouds`, `clouds()`/`cloud_nodes()`.
- `game/game.gd` — the three readings, the tint, the push seam (`_update_clouds`).
- `tests/test_s24_bands.gd` — **new**: 15 rows, one per probe.
- `ui/station/auction_panel.gd` — **not touched** (deviation 7).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| re-pin `REGISTRY_MD5` (bucket 2; R1/F1 hold `tests/`) | HIGH (gate red) | `tests/test_s17_gate_edges.gd:52` |
| V4's second row is derived, not stored (a fifth shelf key is a CONTRACTS §15 pin change) | LOW (pin) | `game/auction.gd:257` |
| the reserved slot's tier clamp hides a tier-4 sector's band | LOW | `game/auction.gd:421` |
