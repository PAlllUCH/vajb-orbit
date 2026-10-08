---
slice: S24
reviewer: S24-R1
verdict: blocked (HIGH remains)
gate: "1152/0 (baseline) → 1185/0 twice, fresh scratch stores, byte-identical"
---

# S24-R1 review

Both reports were treated as claims only; every number below was re-measured by this
review on fresh scratch stores (`tests/probe_s24_r1.tscn`, self-quitting, own seed
424242, own expected values typed from `14`'s 2026-09-27 table, `12` §4.1/§5, `13` §4
and `11`'s V8 block — never from the builders' constants), plus a count-vs-HEAD sweep
and the md5 checks. The gate is green and no unlisted gate row moved.

## Acceptance list

- A1 — pass — nine rows verbatim (names, characters, sector, kind, faction; no S7
  row), the §1/§8 matrix right at every kind (probe `A1 row *`/`A1 concord…`/`A1 choir…`/`A1 outposts…`); the
  plate reads the row's name + character at s1/s3/s5 with the two plate placeholders
  gone (`A1 plate *`); the seam resolves the outpost by its own row and falls back
  normally (`A1 outpost resolves…`); the dock files the station beside the faction
  (`A3 the dock files…`); vault read + U2 state covered by B1's suites 5/7/8.
- A2 — pass — repair fee 692 → 761 / 657 / 623, each exactly `roundi(base ×
  1.10/0.95/0.90)`, and the no-station §6 figure unchanged; module list ±10 %; the
  additive stack reads 3900 = 0.75 × 5200 at the registry **and at the mounted
  armory's own `_module_price`** (0.765 explicitly rejected); commission 27 vs 36 at
  1 800 gross, the 10 CR floor and the ammo exemption (6/8) at both rates; the
  exchange's gross/unit/fee identical at Shunned and Champion (`A2 *`, all ok).
- A3 — pass — `contracts_visible` false at −11/−100, true at −10; insurance 0.8 at
  71, 1.0 at 70 and 0; Known's pair 123/256 seeded shelves at Known, 0/256 at
  Neutral, both hot rows priced `hot_price(station list)` last; Trusted's reserved
  slot reads the sector band (tier 2 ×24, shelf 6 + 20 held) and Neutral draws tiers
  {1,2,3}; V6 bias 0.1806 vs 0.1042 station-less; the two axes hold (dock −51
  refuses / −50 opens; clean-heat Outlaw sold the ticket; outlaw heat refuses the
  gate) (`A3 *`, all ok).
- A4 — pass — the seven bands are R-S24-2 verbatim in the row's own fill order, the
  columns still sum to 13 §4's densities, S6's pirate takes the remainder (2,4) with
  the swarmer at (1,1), no sibelon in S7, no band names a hunter and the heat path
  still answers a wing (`A4 *`, all ok).
- A5 — pass — 64 seeded rolls stay inside 0–2/radius 900/clearance 1500..4100 and
  the stream decides the roll; one node per rolled row on its centre in the Void
  Haze wash at 15 %; inside: lock ×0.5, POI channel 150 u, the pushed minimap radius
  ×0.5 with the zoom state untouched, hull tinted; outside: lock/300 u/radius exact
  and the tint gone (`A5 *`, all ok).
- A6 — pass with F1 — both reports document their half's interface, table every new
  value with a reversal + tick, and name the S25/S26 call shapes; one price read
  site still sits outside the law (F1).

## The S17 re-pin (orchestrator-applied) and drift checks

- `REGISTRY_MD5` in `tests/test_s17_gate_edges.gd:56` = `3661a0d21ad2de97811e40460c597f2a`
  = the file's md5; `GATE_MD5` = `c13574f6af658c1fcd4728c34901caf3` = `gate.gd`'s
  md5; `gate.gd` is not in the wave's diff and `sector_registry.gd`'s diff is only
  the wave's two row keys, constants and accessors — nothing else drifted.
- Count-vs-HEAD sweep: 1152 → 1185 is exactly the two new suites (+18/+15); **no
  other suite's row count moved** (the brief §8 candidates stayed put).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `ui/screens/station.gd:1308,1328-1329,1339-1343` (S24-B1) | The shell's refusal copy still prices from the raw catalogue: `_refusal_text(REASON_INSUFFICIENT, id)` renders "%s NEEDED" from `_entry_cost` → `_entry(id).get(&"cost")` (`Catalog.ammo_pack`/`Catalog.ship`/`ModuleCatalog.module`), while the pane that triggered `purchase_failed` (`player_profile.gd:2072` emits the base id) charged the registry's station price — at any non-Neutral band the strip's figure disagrees with the price the player just saw (a read site still calling the catalogue directly). | F1: route `_entry_cost` through `StationRegistry.apply_price` when a place is docked (display-only; the charge is already correct). |
| F2 | LOW | `ui/station/launch_panel.gd:53` (S24-B1's file, pre-existing) | The undock destination still reads the mockup-era `OPEN SPACE · HELIOS DRIFT` — a sector name the map doesn't carry (11 §1) — instead of the docked sector's own name; surfaced by A1's placeholder sweep, outside the brief's two named plate strings, untouched this wave. | → ticketed as T-152, not fixed here |
| F3 | LOW | `game/auction.gd:421` (S24-B2, the M2 mechanism's cost) | The reserved slot's tier clamp hides a tier-4 sector's band: S6/S7 reserve their slot at tier 3 because `tier_pool(4)` is empty — the shelf size is preserved, but the slot no longer reads the sector's own band there. | → ticketed as T-153 (a tier-4 catalogue row rides with S27), not fixed here |

## The two mechanism choices, graded

- **M1 — V4's second hot row derived from the shelf's own md5 digest, not stored
  (`auction.gd:257`): pass.** §15's four-member `auction` pin and
  `AUCTION_KEYS` hold (`M1 the shelf keeps…`), the derivation is deterministic per
  shelf (`M1 … deterministic`), and the parity is a fair coin over the seeded
  stream — my 123/256 at Known against B2's 36/64, 0/256 at Neutral. The stored-key
  reversal is pinned in CONTRACTS §24.
- **M2 — V5's reserved slot clamped into the catalogue's 1–3 (`auction.gd:421`):
  pass as shipped.** `sector_tier(sector_6)` = 4 and `tier_pool(4)` is empty, so the
  alternatives were a dropped 20th row (breaks the pinned 6 + 20) or an added 21st
  row (a §2.1 shelf-size amendment); the clamp is the only in-pin reading. The band
  fidelity it costs is F3/LOW.

## CONTRACTS updates (this pass)

- New **§24** pins the wave's interface: the registry accessors + the nine-row
  matrix, the profile seam, the two sector row keys, the pinned price order, the
  hot-pair/reserved-slot/bias mechanics with their reversals, and the three cloud
  readings at the push.
- **§9**'s measured block corrected: it still read S30's `1089` (2026-10-04) while
  the wave's own baseline measured **1152** — the S31–S37 growth sat between the two
  with no §10 row to bridge them. §9 now reads 1185 with the chain recorded; **§10**
  gains the v0.46 row (the next free row at write time).

## Gate

- Baseline: `[SUMMARY] passed=1152 failed=0` (the re-cut's own 2026-10-08 run).
- This review, twice on fresh scratch stores, byte-identical, exit 0:
  `[SUMMARY] passed=1185 failed=0` / `[SUMMARY] passed=1185 failed=0`.
- Reviewer probe: `probe_s24_r1` → `[S24R1] done pass=84 fail=0`, exit 0.
- Negative controls inside the probe: the additive stack rejects the multiplicative
  0.765 reading, and Neutral draws 0 second hot rows in 256 shelves.
