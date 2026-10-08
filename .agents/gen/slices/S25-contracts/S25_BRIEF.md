# S25 — The contracts board (wave brief)

**Wave:** S25 (code lane, item 31 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S25-contracts/`
**Baseline:** the gate after S28's close — **1202/0** (record it in the report);
`python3 staging/verify_wave.py snapshot --name s25_start` before the first dispatch.
**Owner go (2026-09-27):** pillar B ("new designed systems") ticked; 14 §2's
board is the design and it is fully pinned — this wave invents no reward number.
**Re-cut 2026-10-08** against the shipped tree (S24 world identity + S28 economy
law + the S30–S37 shell): every cite re-measured, the reward extract re-cut
against S28's scaling block, the panel law re-pointed to STATION_HUB §15.2.

## 1. The law to read, in order
1. `slices/S25-contracts/SLICE.md` — scope, file sets.
2. `docs/gameplay/14_station_services.md` §2 + §6 (by range) — the pin; its
   **2026-09-27 P3 block** (R-S25-1: board size 6, Expedition staged) and its
   **2026-10-08 S28 block** (the payout scaling — every flat reward scales
   ×SC(t)/SC(1) by the target sector's tier).
3. `docs/design/STATION_HUB.md` §15.2 — the CONTRACTS panel spec (D16-A1's
   landed law; its **U3–U8** rows grade the deck) and §5.2 (the confirm dialog).
4. `docs/design/UI_SPEC.md` §12–§15 and `docs/design/STATION_HUB.md` §19–§21
   (by range) — shell v2: the TERMINAL drawer, the popup pair, the shell bands,
   the chrome family. The panel joins this shell; no existing layout regresses.
5. `docs/gameplay/12_factions.md` §3 (demand biases), §4.1 (gates/pay bands)
   and its **2026-10-08 S24 block** (V3's `contracts_visible` predicate).
6. `docs/CODE_MAP.md` — what lies where (by range).
7. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Contracts were measured as
> "5 designed / 0 built — the biggest 'there is not much to do' fix"; this wave
> is that fix.

## 3. What is already measured (file:line, re-measured 2026-10-08)
| Fact | Site |
|---|---|
| `contract_registry.gd` does not exist ("not built yet") | `vajb-orbit/game/` has no such file |
| `PlayerProfile.contracts()` reads/writes the persisted array | `autoload/player_profile.gd:2195` (`_read_plain_array("contracts")`), `:2801` (save) |
| the 20-minute clock exists (`BAND_SECONDS := 1200`) | `autoload/world_clock.gd:18`, `:25 now()`, `:33 bands_between()` |
| the standing gates ship as one predicate | `game/station_registry.gd:417 contracts_visible(standing)` (V3: `standing > −11`), `:423 insurance_multiplier(standing)` |
| the sector tier the scaling reads | `game/sector_registry.gd` (11 §1's seven sectors, `tier_weights`); `game/mineral_catalog.gd:279 SECTOR_TIER_MIX` |
| the exchange price the Haul spot reads | `game/exchange.gd:155 sale_quote()`, `:187 exchange_price()` |
| convoys already spawn per inhabited sector (density only) | `game/npc_registry.gd` convoy rows |
| the corridor ambush site is pinned ("the corridor is where pirates ambush") | `docs/gameplay/11_galactic_map.md` §2.2 |
| the SERVICES deck placeholder the board replaces (T-138) | `ui/screens/station.gd:940` (`MODULE OFFLINE`) |
| the launch flavour line T-152 re-points | `ui/station/launch_panel.gd:53` (`OPEN SPACE · HELIOS DRIFT`) |
| the stale fee example T-154 corrects (comment-only) | `game/refinery.gd:129-130` |
| the station panel row idiom | `ui/station/auction_panel.gd` + STATION_HUB §15.2's row anatomy |
| the board's type icons ship | `icon_contract_*` rows in `docs/design/ASSET_CATALOG.md` |

## 4. Pinned interface (verbatim) + rules
```gdscript
# autoload/player_profile.gd:1914 — the persistence seam (shape stands)
func contracts() -> Array:
# autoload/world_clock.gd:18,25,33 — the generation clock
const BAND_SECONDS := 1200
static func now() -> int:
static func bands_between(from_timestamp: int, to_timestamp: int) -> int:
# S24's seams (read, never redefine) — game/station_registry.gd:417, :423
static func contracts_visible(standing: int) -> bool:    # V3: standing > -11
static func insurance_multiplier(standing: int) -> float:
# the exchange the Haul spot reads (read-only) — game/exchange.gd:155, :187
static func sale_quote(...):
static func exchange_price(item_id: StringName, demand: float) -> int:
```

Rules:
1. **14 §2's numbers are law, scaled by S28's block** (§5 below): reward shapes,
   escrow, the 100 CR cancel, max 3, standing gates. The only new value is
   R-S25-1's board size (6) and the Expedition staging.
2. **S28's scaling law (M11, owner-ratified green): every flat reward scales
   ×SC(t)/SC(1)** by the *target* sector's tier (11 §1.1; SC(t) = 1 100 / 1 500 /
   3 000 / 6 000 per 01's 2026-10-08 block), rounded to 100 CR. Tabled there:
   Hunt **800 / 1 100 / 2 200 / 4 400**; Escort **1 200 / 1 600 / 3 300 /
   6 500**. Haul's +300 CR flat scales by the same law (derived from M11's
   "each sector's flat rewards scale": 300/1 100 × SC(t), rounded —
   **300 / 400 / 800 / 1 600**); its spot×1.25 and Gather's ×1.4 already scale
   with the goods. Reversal: Haul's flat stays 300 at every tier.
3. **Contracts are dictionaries in one registry** (14 §9: "Resource-style
   dictionaries like everything else"); generation is seeded and probe-able
   (fixed seed ⇒ same board).
4. **Escrow is real**: accepted goods leave the manifest into a reservation;
   cancel returns them and charges 100 CR; a completed delivery consumes the
   escrow exactly once (no double-pay — prove it).
5. **Escort is one convoy, one route** (14 §6 verbatim): the convoy's hull is
   the timer; losing it forfeits the payout and costs −5 standing; the ambush
   fires at the corridor midpoint.
6. **The deck follows STATION_HUB §15.2** (U3–U8): the board replaces
   `station.gd:940`'s `MODULE OFFLINE` placeholder (T-138); the panel joins
   shell v2 (UI_SPEC §12–§15) — containers and anchors, chrome from the family;
   no existing panel's layout moves.

## 5. Spec extract (verbatim, cited)
`14_station_services.md` §2:
> "Data-driven job list; new jobs roll on the 20-minute station clock."
> "| **Haul** | "40× `ingot_titanium` to S4 outpost" | spot value ×1.25 + 300 CR, faction standing +2 |
|| **Hunt** | "Destroy 5 pirates in S2" | 800 CR + loot as normal, +1 standing per kill extra |
|| **Gather** | "20× `mineral_cobalt` ore (raw)" | ×1.4 ore value, +2 standing |
|| **Escort** (§6) | "Protect convoy 7 to S4 gate" | 1 200 CR, +5 standing |"
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

**2026-10-08 S28 block** (payout scaling; M11 owner-ratified green):
> "**§2's flat contract rewards.** Hunt 800 / Escort 1 200 are the T1 values; a
> board that pays them in S7 is furniture. Each sector's flat rewards scale
> **×SC(t)/SC(1)** by 11 §1's sector tier — Hunt **800 / 1 100 / 2 200 / 4 400**,
> Escort **1 200 / 1 600 / 3 300 / 6 500**, rounded to 100 CR (Haul's spot×1.25
> and Gather's ×1.4 already scale with the goods). Reversal: flat bases at every
> sector (**M11**). These land with S25 — R-S25-1's extract re-cuts likewise."

`01_economy_core.md`, 2026-10-08 S28 block (the scale):
> "**SC(t) — the Session Credit** (one good 10-minute session in tier-t space,
> 40-cargo hull, net of sinks; ±25 % is the probe's band):" t1 **1 100**, t2
> **1 500**, t3 **3 000**, t4 **6 000**.

`12_factions.md` §4.1 (the rows this wave reads; §4.1 stands as amended):
> "−50…−11 | Shunned | station prices +10 %, no contracts offered"
> "+11…+40 | Known | contracts pay +5 %, auction hot slot chance ×1.5"
> "+71…+100 | Champion | prices −10 %, insurance premium ×0.8 (14 §3), one standing-order contract always available"

`docs/design/STATION_HUB.md` §15.2 — the deck law (read in full before writing
the panel; its U3–U8 rows grade A7): the header strip with the escrow note
(**U3**), the board row anatomy — `icon_contract_<type>.svg` 24×24 + type name,
objective verbatim, reward right-aligned, faction glyph — on the A5.4-4 flat
Tokens idiom, the ACCEPT pressable, the max-3 state with the `MAX 3 ACTIVE` chip
(**U6**), the Expedition staged row (**U7**), the active-contract card with the
escrow readout (**U5**), `CANCEL · 100 CR FEE` + the §5.2 confirm dialog
(**U4**), and the two empty states (**U8**).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (registry + generation):** `contract_registry.gd` generates seeded boards
  of 6 rows on the 20-minute clock; Haul/Hunt/Gather/Escort roll with faction
  ties and sector-appropriate objectives; Expedition exists as a seam row that
  S26 flips live.
- **A2 (rewards):** each type pays its §2 row at the *target* sector's tier per
  the S28 table — Hunt 800 / 1 100 / 2 200 / 4 400; Escort 1 200 / 1 600 /
  3 300 / 6 500; Haul's flat 300 / 400 / 800 / 1 600 + spot×1.25; Gather ×1.4 —
  with the faction demand bias applied, Known's +5 % hook honored, and the
  round-to-100-CR rule proven by probe.
- **A3 (gates):** Shunned/Outlaw see the §15.2 U8 empty state; Champion sees one
  standing-order contract (12 §4.1's row); max 3 active enforced with the U6
  counter and chip.
- **A4 (escrow):** accept locks the goods off the manifest; cancel returns them
  for exactly 100 CR; delivery consumes the escrow exactly once (a double-
  completion probe pays once).
- **A5 (escort):** the convoy spawns at the accepting station per §6 (Hauler
  stats, 50 % visible pods, 1–2 fighters), flies the fixed route at freighter
  speed, eats the corridor-midpoint ambush, and pays/penalises exactly per the
  win/lose rows (−5 standing on loss; the pirates keep the loot).
- **A6 (persistence):** active contracts survive a dock/launch cycle and a game
  restart (the reserved keys); a dead escort contract cannot resurrect.
- **A7 (deck + panel):** the CONTRACTS panel per STATION_HUB §15.2 (U3–U8) in
  `ui/station/contracts_panel.gd`, wired into the SERVICES deck in place of
  `station.gd:940`'s `MODULE OFFLINE` placeholder (T-138); both U8 empty states
  verbatim; every new value tabled with reversal + tick id.
- **A8 (riders):** `launch_panel.gd:53` reads the docked sector's own name
  instead of the mockup-era `HELIOS DRIFT` (T-152); `refinery.gd:129-130`'s
  stale fee example corrected to the live derivation, comment-only, no
  behaviour change (T-154).

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S25-B1 | coder (builder) | `vajb-orbit/game/contract_registry.gd, vajb-orbit/game/contract_registry.gd.uid, vajb-orbit/game/game.gd, vajb-orbit/game/npc_registry.gd, vajb-orbit/game/refinery.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/station/contracts_panel.gd, vajb-orbit/ui/station/contracts_panel.gd.uid, vajb-orbit/ui/station/contracts_panel.tscn, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/launch_panel.gd, vajb-orbit/tests/test_s25_contracts.gd, .agents/gen/slices/S25-contracts/S25-B1_report.md` | A1–A8 + `S25-B1_report.md` |
| S25-R1 | reviewer | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/S25-R1_review.md` | `S25-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S25-F1 | fixer (only on HIGH/MED) | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S25-contracts/` | `S25-F1_report.md` |

Read-only throughout (never in a worker's file set): `game/exchange.gd`,
`game/sector_registry.gd`, `game/station_registry.gd`, `game/mineral_catalog.gd`,
`autoload/world_clock.gd`, `docs/`.

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s25_contracts.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_p1_market.gd`, `test_s5_commerce.gd` | A2's pay-over-exchange rule | unchanged (contracts pay *beside* the exchange) |
| `test_s6_travel.gd` | A5's convoy route | unchanged (convoy densities untouched) |
| `test_p2b_retirement.gd`, `test_p1_profile.gd` | A4/A6's persistence | unchanged (new keys, existing rows intact) |
| `test_s24_world.gd`, `test_s24_bands.gd` | S24's seams this wave reads | unchanged (read-only) |
| `test_s28_econ.gd`, `test_s28_events.gd` | S28's value table and fee law | unchanged (read-only) |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only (14 §2 + the S28 block are the pin as landed). `--forbidden`
  at verify: `docs/`, `vajb-orbit/project.godot`, `vajb-orbit/addons/`.
- No art (owner 2026-09-27): the `icon_contract_*` icons ship; the panel is
  theme chrome only. Bounded runs, scratch `XDG_DATA_HOME` (L229), no shell
  edits; Layer Cake. The SC(t) table comes from 01's block verbatim — never
  re-derived.

## 10. Staged / deferred
- Expedition contracts (S26's arenas flip the seam), insurance interplay
  (S26; §3's premiums stay per-class 200–700, M14 holds the optional
  1.5 %-of-list re-derivation for S26), the "pirate player hunts convoys" loop
  beyond the AI-ambush (13's heat system already covers player piracy).

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| J1 | R-S25-1 | 6 rows per board; Expedition staged to S26 |

(M11's scaling is owner-ratified green — not re-ticked here. Haul's derived
flat table carries M11's reversal; the alternative "flat stays 300" is its
reversal path.)

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s25_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/
   --tests --expect-reports .agents/gen/slices/S25-contracts/S25-B1_report.md
   .agents/gen/slices/S25-contracts/S25-R1_review.md`
3. `python3 staging/build_code_map.py` — the map must describe the shipped tree
   (deterministic; a no-change re-run diffs nothing).
4. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit.
