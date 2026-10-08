# S24 — World identity (wave brief)

**Wave:** S24 (code lane, item 30 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S24-world-identity/`
**Baseline:** `[SUMMARY] passed=1152 failed=0`, exit 0 (measured 2026-10-08 on a
fresh scratch store, this re-cut's own run); `python3 staging/verify_wave.py
snapshot --name s24_start` before the first dispatch.
**Owner go (2026-09-27):** pillar D ("world identity") ticked — "station
differentiation — all 9 stations are currently content-identical" is the measured
defect this wave removes. **No new AI art** (owner).
**Re-cut (2026-10-08, developer):** the brief predates shell v2 (S30), the
2026-10-05/06 rounds and S31–S37. What changed: the fact table and every cite
re-measured against the shipped tree; the identity plate and the SERVICES slot
re-pointed at what actually ships; the mechanism §4.1/§5 never stated pinned as
**V1–V7** (`12_factions.md`'s 2026-10-08 block) and the cloud rows as **V8**
(`11_galactic_map.md`'s); the wave split into **two sequential builders**
(A1–A2 → A3–A5) because one worker cannot land nine subsystems in one pass.

## 1. The law to read, in order
1. `slices/S24-world-identity/SLICE.md` — scope, file sets, the two-builder order.
2. `14_station_services.md` **§1/§8** + its **2026-09-27 P3 block** (R-S24-1, the
   nine names) + its **2026-10-08 block** (the nine rows, the docked-station seam,
   the plate landing).
3. `12_factions.md` **§2–§5** + its **2026-10-08 block** (V1–V7 — the price law,
   the additive stack, `contracts_visible`, the hot pair, the reserved slot, the
   shelf bias, the insurance seam).
4. `13_heat_bounty.md` **§4/§7** + its **2026-09-27 P3 block** (R-S24-2) + its
   **2026-10-08 block** (the band moves to the sector row).
5. `11_galactic_map.md` **§1/§3** + its **2026-09-27 P3 block** (R-S24-3) + its
   **2026-10-08 block** (V8 — the cloud rows, the three readings).
6. `STATION_HUB.md` **§15.5** (+ its 2026-10-08 landing note), **§19.1/§19.4**
   (OVERVIEW block 4 + the SERVICES pane) and `UI_SPEC.md` **§12.4** (the header
   plate row) — composition is A5.1–A5.5: containers/anchors only.
7. §5's spec extract, then §4's rules.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Pillar D as ticked: "Per-station
> stock/services/identity, more POI kinds, nebula clouds. Makes sectors feel
> distinct."

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the header's name plate ships, with U17's glyph + ramp border already applied | `ui/screens/station.tscn:94-134`; `ui/screens/station.gd:_apply_identity()` |
| its two labels are **static placeholder strings** at every station ("ORBITAL DRYDOCK KEPLER-9" / "DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW") | `ui/screens/station.tscn:129,135` |
| the shell rail is 6 entries; SERVICES is slot 7, a **placeholder pane** (P26's deep-link target, outside the cycle) | `ui/screens/station.gd:65,72,873` |
| `_docked_faction()`'s second branch calls a method that exists nowhere (`has_method(&"n")`) — dead, and S30's own artifact | `ui/screens/station.gd:_docked_faction()` |
| only one station spawns per sector; the outpost counts never spawn a node | `game/sector.gd:151,535` |
| `station_catalog.gd` is three flat global arrays (ammo `:31`, ships `:105`, services `:225`); every service row is `availability: &"all"` | `game/station_catalog.gd` |
| the docked **faction** is the sector owner, filed at dock; no station id exists | `game/game.gd:1335-1339`; `autoload/player_profile.gd:1885-1892` |
| standing storage, the dock refusal (≤ −51) and the gate's two axes are live | `autoload/player_profile.gd:1805,1850`; `game/game.gd:210,1009-1019` |
| the exchange commission is station-blind: one `COMMISSION := 0.02`, a 10 CR floor, the ammo exemption | `game/exchange.gd:51,107,120` |
| the repair fee is the one station-service price function | `game/repairs.gd:66` |
| the module price helpers are `list_price` / `hot_price` (the hot discount is the auction's only one) | `game/module_catalog.gd:689,710` |
| the shelf is 6 hulls + **20** modules, one hot row per restock | `game/auction.gd:55-56,203,300` |
| `HOSTILE_FILL` is three entries and its own doc names S24's W1 as the supersession | `game/npc_registry.gd:89-93,464-466` |
| per-sector pirate densities already live on the sector rows | `game/sector_registry.gd:110-140,238-245` |
| **no nebula exists anywhere** in `vajb-orbit/**/*.gd` | (measured: no `nebula`/`cloud` match) |
| the three live ×0.5 sites: the lock range, the POI scan range, the minimap radius | `game/game.gd:1594`; `game/poi.gd:367-368`; `game/game.gd:342,2209` |
| OVERVIEW block 4's three service rows + readouts; the vault read carries its own PROPOSED reversal ("no station registry exists this wave") | `ui/station/overview_panel.gd:42-45,324,515-545` |
| the vaults store is `station_id -> {tier, contents}` and no station id has ever been written | `14 §9`; `ui/station/overview_panel.gd:_vault_units` |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/station_registry.gd — NEW (the nine places; 14's 2026-10-08 block)
static func station(station_id: StringName) -> Dictionary
static func docked_station(profile: Node) -> Dictionary
static func primary_for(sector_id: StringName) -> Dictionary
static func price_factor(station: Dictionary, standing: int, base_id: StringName = &"") -> float   # V1+V2
static func apply_price(price: int, station: Dictionary, standing: int, base_id: StringName = &"") -> int
static func contracts_visible(standing: int) -> bool          # V3
static func insurance_multiplier(standing: int) -> float      # V7
static func shelf_bias(station: Dictionary, base_id: StringName) -> float   # V6
# autoload/player_profile.gd — the seam beside docked_faction (transient, no save key)
func docked_station() -> StringName                           # :1885's twin
func set_docked_station(station_id: StringName) -> void
# game/game.gd:1335-1339 — the dock filing gains the station beside the faction
# game/npc_registry.gd:93 — retires as the band source (13's 2026-10-08 block)
const HOSTILE_FILL: Array[StringName] = [&"pirate", &"swarmer", &"sibelon"]
# game/sector_registry.gd — the row keys S24 adds
#   &"hostile_band": Array[StringName]        &"clouds": Array[Dictionary]
```

Rules:
1. **Data, not rebuild.** The station entity is a registry row + readers (the
   shape `sector_registry.gd:83-141` uses); panels read the docked station through
   `StationRegistry.docked_station(profile)`. **No layout moves**: A5.1–A5.5 bind
   every line (containers + anchors + `custom_minimum_size` + size flags, never
   coordinates; hover/focus/selection mutate colour/`modulate`/`_draw` only).
2. **Only the pinned values are new**: R-S24-1/2/3 (ticks W1–W3) and V1–V8
   (PROPOSED). Everything else is 12/13/14/11's existing tables applied at last.
   A number this brief does not carry is **reported, never invented**.
3. **Two axes stay two axes** (13 §7): dock refusal reads standing, gate refusal
   reads heat — this wave changes neither, only proves both in tests.
4. **The seams are seams, not panels.** `contracts_visible` (V3) and
   `insurance_multiplier` (V7) ship as predicates with tests; S25/S26 own the
   boards and premiums that call them.
5. **Nebula is feedback + range math only** (ruling 25, R-S24-3): inside a cloud
   the three ranges read ×0.5 and the hull tints 15 %; no stat, no damage, no AI
   change.
6. **Resolution never crashes.** `docked_station(profile)` falls back to the
   sector's primary row, then to an empty dictionary; the shipped placeholder
   strings in `station.tscn` are the last resort. A null profile or an unknown id
   is a normal path, not an error.
7. **The price law has one owner.** `price_factor`/`apply_price` live in the
   registry; a read site calls them and keeps the catalogue's own number as the
   input. The order is fixed: **catalogue list → (1 + band_delta − tech_discount)
   → the hot row's −20 % last** (`ModuleCatalog.hot_price`'s "never stacked with
   anything" stays about the auction's own discounts). `band_delta` is +0.10 /
   0 / −0.05 / −0.10 (V1); `tech_discount` is 0.15 for the station faction's own
   families and 0 otherwise (12 §5), **added** to the band, not multiplied (V2).
8. **The dead branch goes.** `_docked_faction()`'s `has_method(&"n")` fallback is
   deleted (S30's artifact; no such method exists anywhere in the project).
   Reversal: restore the two lines.

## 5. Spec extract (verbatim, cited)
`14_station_services.md` §1:
> "One station per faction is the "capital" offering the full menu; outposts offer a subset (§8)."

`14_station_services.md` §8:
> "Secondary stations (S2 outpost, S4 outpost, S5 shrine) offer: contracts (their faction's), bounty payment, and vault tier 1. No insurance (fly to a capital), no arenas."

`12_factions.md` §2:
> "Per-sector, the owner defines: 1. **Station services menu** (14 §2): which services are offered and at what multiplier. 2. **Patrol behaviour** (13 §3): how aggressively heat is enforced. 3. **Exchange demand flavour** (§3 below): what the local economy wants. 4. **Auction shelf bias** (§4): which modules the rotation favours."

`12_factions.md` §3:
> "| Meridian | +0.20 on components, +0.10 on T3 ore, commission 1.5 % (vs 2 %) | the merchant's harbour: salvage and mid-tier pay best |"

`12_factions.md` §4.1 (the band table):
> "| −50…−11 | Shunned | station prices +10 %, no contracts offered |
> | +11…+40 | Known | contracts pay +5 %, auction hot slot chance ×1.5 |
> | +41…+70 | Trusted | station prices −5 %, one extra auction slot reserved for your tier band |
> | +71…+100 | Champion | prices −10 %, insurance premium ×0.8 (14 §3), one standing-order contract always available |"

`12_factions.md` §5:
> "The −15 % discounts stack with standing bands (Champion of the Choir buys a proton missile launcher 25 % under list — this is the intended reward loop for faction loyalty)."

`13_heat_bounty.md` §4:
> "Per-sector NPC counts (the density shape's numbers live in 18_engine_spec §13): S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8, patrols only in owned space, one convoy per inhabited sector."

`11_galactic_map.md` §1:
> "The hazard set gains the nebula gas cloud: 0–2 per sector as a registry row, a desaturated blue-grey/teal wash (STYLE_BIBLE §7.2 — no new palette) that tints hulls inside and **degrades radar and locks**"

`18_engine_spec.md` §2.1 ruling 25:
> "25 | **Nebulae, full effect.** Gas clouds tint hulls and degrade radar/lock while inside — environmental cover (§8)."

**2026-09-27 P3 blocks:** R-S24-1 (the nine names + character, tick W3), R-S24-2
(per-sector hostile bands, tick W1), R-S24-3 (radar/lock ×0.5, tint 15 %, tick
W2) — implement as written. **2026-10-08 blocks:** V1–V7 (12), V8 (11), the nine
rows + the seam + the plate landing (14), the band on the row (13) — implement as
written; each carries its own reversal.

## 6. Acceptance list (numbered; each report answers its half with a cite)
- **A1 (stations are places, R-S24-1 — B1):** `StationRegistry` carries all nine
  rows with their W3 name + character, sector, kind, faction and the §1/§8 service
  matrix (Concord primaries: no arena; Choir primaries: no insurance; the three
  outposts: §8's three); the docked place resolves from the profile seam; the
  shell header's two labels read the row (measured: entering the station screen at
  S3 shows `Spanport Meridian` + "the merchant's harbour, best contract rates" and
  no placeholder text anywhere); OVERVIEW block 4's rows show the unavailable
  state (U2's disabled plate + the §1/§8 reason) and the vault read resolves the
  docked station's own record.
- **A2 (the station's prices, V1/V2 — B1):** the band multiplier is live on the
  repair fee, the ammo pack cost, the hull list price and the module list price
  (probe Shunned +10 %, Trusted −5 %, Champion −10 % against the Neutral figure);
  the Meridian commission reads 1.5 % at a Meridian station and 2 % elsewhere (the
  10 CR floor and the ammo exemption unchanged); 12 §5's −15 % applies at the
  owner's own stations and stacks **additively** (Champion at a Choir station on a
  Choir family reads 0.75 × list); the exchange's own quotes take no band
  multiplier; `shelf_bias` returns 2.0 for the owner's families and 1.0 elsewhere.
- **A3 (standing effects + the auction flavour, V3–V7 — B2):** each band's row is
  live and probed — `contracts_visible` true at Neutral and above, false at
  Shunned/Outlaw (the S25 seam); Known's hot pair (one guaranteed hot row + a 50 %
  second, both at `hot_price`, the roll seeded); Trusted's reserved slot (the
  shelf's first rolled module slot comes off the docked sector's tier band, the
  shelf still 6 + 20); the owner's tech families ×2 in the rolled draw (V6); the
  Champion insurance seam reads 0.8 and 1.0 elsewhere; the −51 dock refusal and
  the clean-heat Outlaw's gate ticket both still hold (two axes intact).
- **A4 (hostile bands, R-S24-2 — B2):** each sector's row carries its own band
  (S1–S2 `[pirate]` … S5–S6 `[swarmer, sibelon, pirate]` … S7 `[pirate, swarmer]`),
  the fill order is the row's order, densities stay 13 §4's, hunters stay
  heat-driven map-wide and `HOSTILE_FILL` no longer sources a band.
- **A5 (nebula, R-S24-3 — B2):** 0–2 cloud rows per sector on the sector's seeded
  RNG, centres ≥ 1500 u from the arena centre, radius 900 u; inside one the lock
  range, the POI scan range and the minimap radius all read ×0.5 and the hull
  carries the 15 % wash tint; outside, all three read the shipped value exactly
  (probe both directions).
- **A6 (summary — both):** each report documents its own half's interface
  (registry accessors, the profile seam, the sector row keys, the price order) and
  tables every new value with its reversal + tick; the seams S25/S26 read
  (`contracts_visible`, `insurance_multiplier`, the vault record) are named with
  their call shape.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S24-B1 | coder (builder 1) | `vajb-orbit/game/station_registry.gd, vajb-orbit/game/station_catalog.gd, vajb-orbit/game/repairs.gd, vajb-orbit/game/exchange.gd, vajb-orbit/game/game.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/overview_panel.gd, vajb-orbit/ui/station/launch_panel.gd, vajb-orbit/ui/station/armory_panel.gd, vajb-orbit/ui/station/fitting_panel.gd, vajb-orbit/tests/test_s24_world.gd, .agents/gen/slices/S24-world-identity/S24-B1_report.md` | A1 + A2 + `test_s24_world.gd` + `S24-B1_report.md` |
| S24-B2 | coder (builder 2, after B1) | `vajb-orbit/game/sector_registry.gd, vajb-orbit/game/sector.gd, vajb-orbit/game/npc_registry.gd, vajb-orbit/game/auction.gd, vajb-orbit/game/game.gd, vajb-orbit/ui/station/auction_panel.gd, vajb-orbit/tests/test_s24_bands.gd, .agents/gen/slices/S24-world-identity/S24-B2_report.md` | A3 + A4 + A5 + `test_s24_bands.gd` + `S24-B2_report.md` |
| S24-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/S24-R1_review.md` | `S24-R1_review.md` + CONTRACTS §24 + §9/§10 + LOW rows |
| S24-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/` | `S24-F1_report.md` |

## 8. Run order + the tests that move
**B1 → B2 → R1 → F1 only on HIGH/MED.** B1 and B2 are sequential by law (both
hold `game/game.gd`); B2 re-reads the file before editing. Expected gate growth:
`test_s24_world.gd` (B1) + `test_s24_bands.gd` (B2) rows only. Candidates that
may move, and why:

| Suite | Why | Verdict |
|---|---|---|
| `test_s3_auction.gd`, `test_s5_commerce.gd` | the shelf's hot rows (V4/V5) and the listing counts | counts and hot-row asserts may move **only** where V4/V5 says so; the shelf stays 6 + 20 |
| `test_p1_market.gd`, `test_s5_*` | the commission's station-awareness (V1) | unchanged outside Meridian stations |
| `test_engine2_npc.gd`, `test_s6_travel.gd` | the per-sector band (A4) | unchanged (same archetypes, distributed per band) |
| `test_d11_station.gd`, `test_d7_status.gd`, `test_s30_shell.gd` | the plate's text (A1) | may move only where an assert reads the placeholder string |
| `test_engine2_dock.gd`, `test_s11_inspector.gd` | the dock refusal, the hover chain | unchanged |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- **Docs are read-only for B1/B2** (the 2026-10-08 blocks are the yardstick); only
  R1/F1 write `docs/CONTRACTS.md`. `--forbidden` at verify:
  `vajb-orbit/project.godot vajb-orbit/addons/ docs/gameplay/ docs/design/`
  (plus every `vajb-orbit/autoload/*.gd` except `player_profile.gd`).
- **No art of any kind** (owner 2026-09-27); identity = names + existing chrome.
- **No new Tokens or hues** (N29, 12 §4.1's "a faction colour is out of contract").
- Bounded runs, scratch `XDG_DATA_HOME`, no shell edits, Layer Cake (signals up,
  calls down), no comments the code does not need.
- The gate runs twice per builder on fresh scratch stores; both `[SUMMARY]` lines
  go in the report.

## 10. Staged / deferred
- Outpost **nodes** (the three rows are data + tests; the POI-flavour item), the
  contracts/insurance/vault **panels** (S25/S26), per-station emblem art (D16
  §10), S12's ore rows and slice 2.5's calls (parked), S7's lawless economy.

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| W1 | R-S24-2 | the per-sector hostile bands as written |
| W2 | R-S24-3 | radar/lock ×0.5, tint 15 % |
| W3 | R-S24-1 | the nine names + character lines as written (rename per row) |
| V1 | the band's price set (12) | the station's goods/services; the exchange untouched |
| V2 | the §5 stack (12) | additive (Champion of the Choir = −25 %) |
| V3 | `contracts_visible` (12) | `standing > −11` |
| V4 | Known's hot pair (12) | one guaranteed hot row + a 50 % second |
| V5 | Trusted's reserved slot (12) | the first rolled module slot, tier-banded, shelf size unchanged |
| V6 | the shelf bias (12) | the owner's tech families ×2 |
| V7 | the insurance seam (12) | 0.8 at Champion, 1.0 elsewhere |
| V8 | the cloud rows (11) | 0–2 per sector, radius 900 u, centres ≥ 1500 u from the arena centre |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s24_start --forbidden
   vajb-orbit/project.godot vajb-orbit/addons/ docs/gameplay/ docs/design/
   --tests --expect-reports .agents/gen/slices/S24-world-identity/S24-B1_report.md
   .agents/gen/slices/S24-world-identity/S24-B2_report.md
   .agents/gen/slices/S24-world-identity/S24-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   `TICKS.md` refreshed; wave-boundary commit.
