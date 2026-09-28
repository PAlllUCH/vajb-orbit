# S24 — World identity (wave brief)

**Wave:** S24 (code lane, item 30 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S24-world-identity/`
**Baseline:** the gate after S23's close (record it in the report);
`python3 staging/verify_wave.py snapshot --name s24_start` before the first dispatch.
**Owner go (2026-09-27):** pillar D ("world identity") ticked — "station
differentiation — all 9 stations are currently content-identical" is the
measured defect this wave removes. **No new AI art** (owner).

## 1. The law to read, in order
1. `slices/S24-world-identity/SLICE.md` — scope, file sets.
2. The **2026-09-27 P3 blocks** in `14_station_services.md` (R-S24-1 names),
   `13_heat_bounty.md` (R-S24-2 bands), `11_galactic_map.md` (R-S24-3 nebula) —
   the pin; `12_factions.md` §2–§5 by range.
3. `slices/D16-station-ui/D16-A1_report.md` if it exists (the identity
   treatment); else AGENTS.md's UI composition rule (containers/anchors only).
4. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Pillar D as ticked: "Per-station
> stock/services/identity, more POI kinds, nebula clouds. Makes sectors feel
> distinct."

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| `station_catalog.gd` is three flat global arrays — no `station_id` anywhere | `game/station_catalog.gd:25,31-233` |
| all stations offer the same 3 services (`availability: all`) | `station_catalog.gd:206-233` |
| the service matrix and outposts' subset are already pinned | 14 §1/§8 |
| per-owner definitions are pinned but unused (menu multipliers, patrol, demand, shelf bias) | 12 §2 |
| demand flavours + Meridian 1.5 % commission are pinned | 12 §3 |
| standing bands + effects are pinned; `PlayerProfile.standing()` exists | 12 §4.1; `autoload/player_profile.gd:1634,1679` |
| two-axis enforcement is pinned and working (dock reads standing, gate reads heat) | 13 §7 |
| `HOSTILE_FILL` is one global `[pirate, swarmer]` ("band split stated by no doc") | `game/npc_registry.gd:89` |
| per-sector pirate densities are pinned | 13 §4 |
| nebula clouds: ruling 25 pins the effect, §1 pins 0–2 per sector | 18 §2.1 r25, 11 §1 |
| population consts ready for clouds | `game/sector_registry.gd:40-50` |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/station_catalog.gd — the table shapes a station entity must serve
const AMMO_PACKS: Array[Dictionary] = [   # :31-85
const SHIPS: Array[Dictionary] = [        # :86-196
const SERVICES: Array[Dictionary] = [     # :206-233
# autoload/player_profile.gd — the band seams the effects hook
func standing() -> Dictionary:            # :1634
func standing_of(faction: StringName) -> int:  # :1679
# game/npc_registry.gd:89 — what becomes per-sector
const HOSTILE_FILL: Array[StringName] = [&"pirate", &"swarmer"]
```

Rules:
1. **Data, not rebuild**: the station entity is a registry row + readers (the
  same shape `sector_registry.gd:83-141` uses); existing panels read the
  current station through one accessor. Panel layout does not move (A5.2's
  containers law; D16's treatment is design law when it exists).
2. **Only the P3-block values are new** (R-S24-1/2/3; ticks W1–W3 default
  PROPOSED). Everything else is 12/13/14's pinned tables applied at last.
3. **Two axes stay two axes** (13 §7): dock refusal reads standing, gate refusal
  reads heat — this wave changes neither, only proves both in tests.
4. **Contract visibility is a seam, not a panel** (S25 consumes it): one
  predicate `contracts_visible(standing)` per 12 §4.1, tested here.
5. **Nebula is feedback + range math only** (ruling 25): inside a cloud,
  radar/lock ranges halve and the hull tints; nothing else changes.

## 5. Spec extract (verbatim, cited)
`14_station_services.md` §1:
> "One station per faction is the "capital" offering the full menu; outposts offer a subset (§8)."

`14_station_services.md` §8:
> "Secondary stations (S2 outpost, S4 outpost, S5 shrine) offer: contracts (their faction's), bounty payment, and vault tier 1. No insurance (fly to a capital), no arenas."

`12_factions.md` §2:
> "Per-sector, the owner defines: 1. **Station services menu** (14 §2): which services are offered and at what multiplier. 2. **Patrol behaviour** (13 §3): how aggressively heat is enforced. 3. **Exchange demand flavour** (§3 below): what the local economy wants. 4. **Auction shelf bias** (§4): which modules the rotation favours."

`12_factions.md` §3:
> "| Concord | +0.15 on T1–T2 ingots, −0.10 on components | sell your common ore here, sell your salvage elsewhere |
| Meridian | +0.20 on components, +0.10 on T3 ore, commission 1.5 % (vs 2 %) | the merchant's harbour: salvage and mid-tier pay best |
| Choir | +0.25 on T3–T4 ingots and exotic components, −0.15 on T1–T2 | exotics fetch glory; common ore is an insult |"

`12_factions.md` §4.1 (the band table):
> "| −100…−51 | Outlaw | denied docking in faction space (13 §5), hunters |
| −50…−11 | Shunned | station prices +10 %, no contracts offered |
| −10…+10 | Neutral | baseline |
| +11…+40 | Known | contracts pay +5 %, auction hot slot chance ×1.5 |
| +41…+70 | Trusted | station prices −5 %, one extra auction slot reserved for your tier band |
| +71…+100 | Champion | prices −10 %, insurance premium ×0.8 (14 §3), one standing-order contract always available |"

`12_factions.md` §5:
> "The −15 % discounts stack with standing bands (Champion of the Choir buys a proton missile launcher 25 % under list — this is the intended reward loop for faction loyalty)."

`13_heat_bounty.md` §4:
> "Per-sector NPC counts (the density shape's numbers live in 18_engine_spec §13): S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8, patrols only in owned space, one convoy per inhabited sector."

`18_engine_spec.md` §2.1 ruling 25:
> "25 | **Nebulae, full effect.** Gas clouds tint hulls and degrade radar/lock while inside — environmental cover (§8)."

**2026-09-27 P3 blocks:** R-S24-1 (the nine names + character, tick W3),
R-S24-2 (per-sector hostile bands, tick W1), R-S24-3 (nebula effects
×0.5/×0.5/tint 15 %, tick W2) — implement as written.

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (stations are places, R-S24-1):** all nine docking places carry their
  name and character string, their faction's §1 service matrix (outposts §8's
  subset), and their owner's multipliers — measured: Meridian commission
  1.5 % vs 2 % elsewhere, Choir's insurance absent, an outpost showing exactly
  §8's three services.
- **A2 (standing effects, 12 §4.1):** each band's row is live and probed —
  dock refusal ≤ −51 (while a clean-heat Outlaw still buys a gate ticket,
  two-axis intact), Shunned +10 % and no contracts (the seam returns false),
  Known's ×1.5 hot-slot and +5 % contract pay (the pay hook for S25), Trusted's
  −5 % and reserved slot, Champion's −10 % and the ×0.8 insurance hook (a
  readable seam for S26); 12 §5's −15 % discounts apply and stack per §5.
- **A3 (hostile bands, R-S24-2):** each sector rolls its own band (S1–S2
  `[pirate]` … S7 with hunter pressure), densities stay 13 §4's, hunters stay
  heat-driven map-wide.
- **A4 (nebula, R-S24-3):** 0–2 clouds per sector; inside one, radar and
  lock-acquire ranges read ×0.5 and hulls carry the 15 % tint (probe both
  range values); outside, everything reads 1.0.
- **A5 (summary):** the station accessor's contract (name/faction/services/
  multipliers) documented in the report with the seams S25/S26 will read
  (`contracts_visible`, the insurance hook, the shelf bias hook); every new
  value tabled with reversal + tick id.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S24-B1 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, .agents/gen/slices/S24-world-identity/S24-B1_report.md` | A1–A5 + `S24-B1_report.md` |
| S24-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/S24-R1_review.md` | `S24-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S24-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S24-world-identity/` | `S24-F1_report.md` |

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s24_world.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_p1_market.gd`, `test_s5_commerce.gd` | A1's commission/bias flavours | unchanged outside Meridian stations (the 1.5 % row is the P3 pin) |
| `test_engine2_npc.gd`, `test_s6_travel.gd` | A3's bands | unchanged (same archetypes, distributed per band) |
| `test_d11_station.gd`, `test_d7_status.gd` | A1's identity strings | unchanged (rows are additive) |
| `test_engine2_dock.gd` | A2's dock refusal | unchanged |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only. `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`, `vajb-orbit/autoload/`.
- No art of any kind (owner 2026-09-27); identity = names + existing chrome.
- Bounded runs, scratch `XDG_DATA_HOME` (L229), no shell edits; Layer Cake.

## 10. Staged / deferred
- Contracts/insurance/vault panels (S25/S26 consume this wave's seams);
  S12's ore rows and slice 2.5's calls stay parked; per-station POI flavour and
  S7's lawless economy are future content.

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| W1 | R-S24-2 | the per-sector hostile bands as written |
| W2 | R-S24-3 | radar/lock ×0.5, tint 15 % |
| W3 | R-S24-1 | the nine names + character lines as written (rename per row) |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s24_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/ vajb-orbit/autoload/
   --tests --expect-reports .agents/gen/slices/S24-world-identity/S24-B1_report.md
   .agents/gen/slices/S24-world-identity/S24-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit.
