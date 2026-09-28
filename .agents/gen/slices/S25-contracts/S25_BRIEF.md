# S25 — The contracts board (wave brief)

**Wave:** S25 (code lane, item 31 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S25-contracts/`
**Baseline:** the gate after S24's close (record it in the report);
`python3 staging/verify_wave.py snapshot --name s25_start` before the first dispatch.
**Owner go (2026-09-27):** pillar B ("new designed systems") ticked; 14 §2's
board is the design and it is fully pinned — this wave invents no reward number.

## 1. The law to read, in order
1. `slices/S25-contracts/SLICE.md` — scope, file sets.
2. `docs/gameplay/14_station_services.md` §2 + §6 (by range) — the pin;
   its **2026-09-27 P3 block** (R-S25-1: board size 6, Expedition staged).
3. `slices/D16-station-ui/D16-A1_report.md` (the panel spec) when it exists.
4. `docs/gameplay/12_factions.md` §4.1 (standing gates) by range.
5. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Contracts were measured as
> "5 designed / 0 built — the biggest 'there is not much to do' fix"; this wave
> is that fix.

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| `contract_registry.gd` does not exist ("not built yet") | `docs/gameplay/17_coder_handoff.md` §2 |
| `PlayerProfile` reserves the keys already | `autoload/player_profile.gd:1724 (contracts())`, `:2545-2548` |
| the 20-minute clock exists (`BAND_SECONDS := 1200`) | `autoload/world_clock.gd:18,25,33` |
| convoys already spawn per inhabited sector (density only) | `game/sector_registry.gd` population; `game/npc_registry.gd` convoy rows |
| the corridor ambush site is pinned ("the corridor is where pirates ambush") | `docs/gameplay/11_galactic_map.md` §2.2 |
| S24 exposes the seams this wave reads | `slices/S24-world-identity/S24-B1_report.md` §A5 |
| the station panel idiom (rows over plates) | `ui/station/auction_panel.gd` + UI_SPEC §3.10 A5 |

## 4. Pinned interface (verbatim) + rules
```gdscript
# autoload/player_profile.gd:1724 — the persistence seam (shape stands)
func contracts() -> Array:
# autoload/world_clock.gd:18,25,33 — the generation clock
const BAND_SECONDS := 1200
static func now() -> int:
static func bands_between(from_timestamp: int, to_timestamp: int) -> int:
# S24's seam (read, never redefine)
func contracts_visible(standing: int) -> bool:   # shape per S24's A5 report
```

Rules:
1. **14 §2's numbers are law** (reward shapes, escrow, the 100 CR cancel, max
   3, standing gates). The only new value is R-S25-1's board size (6) and the
   Expedition staging.
2. **Contracts are dictionaries in one registry** (14 §9: "Resource-style
   dictionaries like everything else"); generation is seeded and probe-able
   (fixed seed ⇒ same board).
3. **Escrow is real**: accepted goods leave the manifest into a reservation;
   cancel returns them and charges 100 CR; a completed delivery consumes the
   escrow exactly once (no double-pay — prove it).
4. **Escort is one convoy, one route** (14 §6 verbatim): the convoy's hull is
   the timer; losing it forfeits the payout and costs −5 standing; the ambush
   fires at the corridor midpoint.
5. **UI follows A5.2** (containers/anchors; chrome flat or per D16's spec);
   panels are additive — no existing panel's layout moves.

## 5. Spec extract (verbatim, cited)
`14_station_services.md` §2:
> "Data-driven job list; new jobs roll on the 20-minute station clock."
> "| **Haul** | "40× `ingot_titanium` to S4 outpost" | spot value ×1.25 + 300 CR, faction standing +2 |
| **Hunt** | "Destroy 5 pirates in S2" | 800 CR + loot as normal, +1 standing per kill extra |
| **Gather** | "20× `mineral_cobalt` ore (raw)" | ×1.4 ore value, +2 standing |
| **Escort** (§6) | "Protect convoy 7 to S4 gate" | 1 200 CR, +5 standing |"
> "**Faction-tied:** every contract belongs to a faction; rewards use that faction's demand biases so hauling to Meridian pays differently than to the Choir (12 §3)."
> "**No instant-fail timers in v1** except escort (its timer is the convoy's hull). Haul/gather contracts have no deadline; they occupy **cargo or standing slots** (max 3 active contracts) instead."
> "Materials delivered for a contract come from the hold as normal; the board pays *over* the exchange's buy price (that's the point) but locks the goods at accept-time (escrow: quantity reserved from the manifest, removable by cancelling for a 100 CR fee)."
> "Standing gates (12 §4.1): Shunned players see no contracts; Outlaws see none either. Redemption must precede employment."

`14_station_services.md` §6:
> "Spawn point: the accepting station. A **trade convoy** (1 hauler-class AI hull + 1–2 fighter escorts) flies a fixed route to a target sector's gate at freighter speed."
> "Win: convoy hull survives to the gate → payout at destination station."
> "Lose: convoy destroyed → no payout, −5 standing, and the pirates who did it keep the loot (which you can... recover. Aggressively)."
> "Pirates ambush at the corridor midpoint (11 §2.2) — the contract literally routes through the dangerous part."
> "Convoy hulls use the Hauler stats (08 §2) with 50 % of hold filled with visible cargo pods; a *pirate player* (13) can hunt convoys as income — same system, both directions."

`14_station_services.md` §9:
> "`contract_registry`: 5 types × parameterized tables; contracts are Resource-style dictionaries like everything else."

**2026-09-27 P3 block:** R-S25-1 — 6 rows per board, Expedition staged as a seam
until S26 (tick J1).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (registry + generation):** `contract_registry.gd` generates seeded boards
  of 6 rows on the 20-minute clock; Haul/Hunt/Gather/Escort roll with faction
  ties and sector-appropriate objectives; Expedition exists as a seam row that
  S26 flips live.
- **A2 (rewards):** each type pays its §2 row exactly (Haul spot×1.25+300 & +2
  standing; Hunt 800 + drops & +1/kill; Gather ×1.4 & +2; Escort 1 200 & +5),
  with the faction demand bias applied and Known's +5 % hook honored.
- **A3 (gates):** Shunned/Outlaw see an empty board; Champion sees one
  standing-order contract (12 §4.1's rows); max 3 active enforced.
- **A4 (escrow):** accept locks the goods off the manifest; cancel returns them
  for exactly 100 CR; delivery consumes the escrow exactly once (a double-
  completion probe pays once).
- **A5 (escort):** the convoy spawns at the accepting station per §6 (Hauler
  stats, 50 % visible pods, 1–2 fighters), flies the fixed route at freighter
  speed, eats the corridor-midpoint ambush, and pays/penalises exactly per the
  win/lose rows (−5 standing on loss; the pirates keep the loot).
- **A6 (persistence):** active contracts survive a dock/launch cycle and a game
  restart (the reserved keys); a dead escort contract cannot resurrect.
- **A7 (panel + summary):** the CONTRACTS panel lists type/objective/reward/
  faction with accept/cancel (100 CR shown) per D16's spec (fallback: the
  auction row idiom under A5.2); every new value tabled with reversal + tick id.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S25-B1 | coder (builder) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, .agents/gen/slices/S25-contracts/S25-B1_report.md` | A1–A7 + `S25-B1_report.md` |
| S25-R1 | reviewer | `vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/S25-R1_review.md` | `S25-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S25-F1 | fixer (only on HIGH/MED) | `vajb-orbit/game/, vajb-orbit/ui/, vajb-orbit/autoload/player_profile.gd, vajb-orbit/tests/, vajb-orbit/tools/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/` | `S25-F1_report.md` |

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s25_contracts.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_p1_market.gd`, `test_s5_commerce.gd` | A2's pay-over-exchange rule | unchanged (contracts pay *beside* the exchange) |
| `test_s6_travel.gd` | A5's convoy route | unchanged (convoy densities untouched) |
| `test_p2b_retirement.gd`, `test_p1_profile.gd` | A4/A6's persistence | unchanged (new keys, existing rows intact) |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only (14 §2 is the pin as landed). `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`.
- No art (owner 2026-09-27); the panel is theme chrome only. Bounded runs,
  scratch `XDG_DATA_HOME` (L229), no shell edits; Layer Cake.

## 10. Staged / deferred
- Expedition contracts (S26's arenas flip the seam), insurance interplay
  (S26), the "pirate player hunts convoys" loop beyond the AI-ambush (13's
  heat system already covers player piracy).

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| J1 | R-S25-1 | 6 rows per board; Expedition staged to S26 |

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s25_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/
   --tests --expect-reports .agents/gen/slices/S25-contracts/S25-B1_report.md
   .agents/gen/slices/S25-contracts/S25-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit.
