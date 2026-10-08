# S26 — Endgame: bosses, arenas, insurance, vaults (wave brief)

**Wave:** S26 (code lane, item 32 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S26-endgame/`
**Baseline:** the gate after S25's close (record it in the report);
`python3 staging/verify_wave.py snapshot --name s26_start` before the first dispatch.
**Owner go (2026-09-27):** pillars B + A; the boss sprites ship unused
(`ASSET_CATALOG.md:48-54`) and 14 §5/§3/§4 are fully pinned. **No new AI art.**
**Re-cut 2026-10-08** against the shipped tree (post-S24 + S28): the boss
payouts re-cut against S28's block (6 000 / 12 000, M10), the premium law
re-cut against M14, the panel law re-pointed to STATION_HUB §15.3/§15.4, every
cite re-measured. The S25 seam cite is prospective — re-verify its shipped
shape at dispatch (S25 runs first).

## 1. The law to read, in order
1. `slices/S26-endgame/SLICE.md` — scope, file sets.
2. `docs/gameplay/14_station_services.md` §5 + §3 + §4 (by range) — the pin;
   its **2026-10-08 S28 block** (the boss payouts 6 000/12 000, M10; the
   premium law, M14); `06_loot_drops.md` §3.4 (the Maw table);
   `08_ship_classes.md` **2026-09-27 P3 block** (R-S26-1, tick E1).
3. `docs/design/STATION_HUB.md` §15.3 (the INSURANCE panel spec) and §15.4
   (the VAULTS panel spec) — the deck law; §5.2 (the confirm dialog).
4. `docs/design/UI_SPEC.md` §12–§15 and `docs/design/STATION_HUB.md` §19–§21
   (by range) — shell v2. The panels join the deck; no layout regresses.
5. `slices/S25-contracts/S25-B1_report.md` — the Expedition seam (how to flip
   it live). **If S25 has not closed yet, its brief §6 A1 is the seam's contract;
   re-verify the shipped shape at dispatch.**
6. `docs/CODE_MAP.md` — what lies where (by range).
7. The §5 spec extract.

## 2. The owner's request (verbatim)
> "right now the fundamentals are there, it needs a bit of playtesting and a lot
> of new content as right now there isnt much … i want to focus on content,
> bugfixes, playability and feel" (2026-09-27). Bosses measured as "3 designed
> / 0 live (6 boss sprites sitting in the library)"; death defects L23/L24 were
> in the bugfix pillar this wave completes.

## 3. What is already measured (file:line, re-measured 2026-10-08)
| Fact | Site |
|---|---|
| the boss row is `SEAM_SLICE_4` ("code the seam, ship nothing") | `game/npc_registry.gd:184` (const), zero-density seam rows at `:451` and `:510` |
| `MAW_LINES` exists but "the row rolls no 06 table" | `game/loot_tables.gd:90`; the maw band row at `:109` |
| insurance/mercy are "slice 4" comments | `game/game.gd:2881`, `:3055` |
| `_respawn_docked` defers the sector record/payout | `game/game.gd:3056` (call at `:2906`) |
| `PlayerProfile` reserves `vaults`/`insured`/`mercy_used` | `autoload/player_profile.gd:1926 vaults()`, `:1938 insured()`, `:1949 mercy_used()` (no-arg) |
| the `u_vault` row's "+20 units all vaults" has no consumer | `game/module_catalog.gd:547`; 15 §5 |
| the boss renders ship (boneyard/pyre/maw + 3 staged) | `docs/design/ASSET_CATALOG.md:48-54` |
| the insurance premium law (M14, ratified) | 14's 2026-10-08 S28 block (§5 below) |
| S25's Expedition seam is the row this wave flips | `slices/S25-contracts/S25_BRIEF.md` §6 A1 (prospective; S25-B1's report at dispatch) |

## 4. Pinned interface (verbatim) + rules
```gdscript
# game/npc_registry.gd:184 — the seam this wave releases
const SEAM_SLICE_4: StringName = &"slice_4"
# zero-density seam rows at :451 and :510 (KEY_SPAWN: SPAWN_SEAM)
# game/loot_tables.gd:90 — the table that finally has a feeder
const MAW_LINES: Array[Dictionary] = [
# autoload/player_profile.gd — the seams that go live (re-measured 2026-10-08)
func vaults() -> Dictionary:   # :1926
func insured() -> bool:        # :1938
func mercy_used() -> bool:     # :1949
# S24's seam (read, never redefine) — game/station_registry.gd:423
static func insurance_multiplier(standing: int) -> float:
```

Rules:
1. **14 §3/§4/§5 and 06 §3.4 are law, re-priced by S28's block** (§5 below):
   arena flow, the Maw table, vaults; the boss payouts are **6 000 / 12 000**
   (M10); the premium is **1.5 % of list per class (135–1 080)** (M14). The only
   new values are R-S26-1's hull rows and the E2 roam rows.
2. **An arena is a place** (14 §5): a marked, barricaded ring with nav pylons,
   visible from any distance — built from existing scene parts and sprites, no
   art.
3. **Insurance pays once per launch** (the one-death rule): the payout flow is
   §3's verbatim, the mercy clause fires once per profile ever.
4. **Vaults are furniture** (14 §4): contents persist per station, never count
   against launch cargo; `u_vault` extends every vault by +20 (15 §5).
5. **Kill credit is the last hit by the player** (14 §5); escorts and drones
   cannot complete a boss contract.
6. **The panels follow STATION_HUB §15.3/§15.4**: the INSURANCE and VAULTS
   panels wire into the SERVICES deck beside S25's contracts strip; shell v2
   idioms (UI_SPEC §12–§15); no existing panel's layout moves.

## 5. Spec extract (verbatim, cited)
`14_station_services.md` §5:
> "Each arena is a **physical place**: a marked, barricaded zone in its sector (S3: "The Boneyard" — Meridian arena; S6: "The Pyre" — Choir arena), visible from any distance as a lit ring of nav pylons. No hidden bosses."
> "**Contracts, not buttons:** the arena run is a contract type (§2) taken at the faction's expedition desk: accept → arena opens (a 60 s window to fly there) → boss fight → payout on return-to-station, win or lose."
> "Two bosses: **Boneyard Behemoth** (S3, gunship-tier fit, 15 k CR + magic module roll) and **The Pyre Hierophant** (S6, frigate-tier fit, 40 k CR + guaranteed rare-module roll, 15 §5). The Maw (S7) remains the roaming endgame boss with its 06 §3.4 table — three difficulty beats, all visible from across the sector."
> "Arena cooldown: one run per boss per 20-minute clock (per profile)."
> "Kill credit requires **you** landing the last hit — escorts and drones don't steal your glory."

**2026-10-08 S28 block** (the re-cut; M10/M14 owner-ratified green):
> "**§7's arena bosses.** 15 000 and 40 000 CR are flat numbers from the
> pre-S28 economy: the Pyre's 40 000 read ≈36 sessions of §5.3's own pace. They
> re-price as ≈2 × SC of the arena's sector tier:
> - **Boneyard Behemoth: 6 000 CR** + the magic module roll (was 15 000).
> - **The Pyre Hierophant: 12 000 CR** + the guaranteed rare (was 40 000).
>   Reversal: the flat numbers (**M10**). These land with S26 — its brief's
>   R-S26-1 extract re-cuts against this block before dispatch."
> "**§3's insurance premiums stay** the per-class flats (200–700); **M14** holds
> the optional 1.5 %-of-list re-derivation (135–1 080) for S26's implementation."

(M14 is owner-ratified green: this wave implements the 1.5 %-of-list premium —
135–1 080 per class, charged at launch — in place of the §3 flats. Reversal:
keep the flats. §3's base table stays quoted as the superseded law.)

`14_station_services.md` §3:
> "**Premium:** flat per class, charged at launch, covers **one** hull loss (ship + installed modules at full value): | Fighter | 200 | | Cutter | 250 | | Delver / Trader / Corvette | 300 | | Hauler / Gunship | 400 | | Frigate | 500 | | Destroyer | 700 |"
> "**One-death rule:** the payout covers one loss; the policy does not renew mid-flight."
> "**Payout flow:** on death you respawn docked at the last station visited in a *base* hull of your class tier's cheapest ship, minus anything uninsured. Insurance pays the hull+fit back into your dock. (The starter Lancer is never fully losable: if you have no other hull, the Concord reissues a bare Fighter — mercy clause, once per profile.)"

`14_station_services.md` §4:
> "Stations rent hold space: **one vault per station, 20 units base, +20 per upgrade tier** (tiers 1–3: 500 / 1 200 / 2 400 CR one-off per station)."
> "**Meridian's `u_vault` tech (15 §2):** their stations rent 40-unit vaults and the rental tiers cost 25 % more (they know what a vault is worth)."
> "The vault holds any cargo type (ore, ingots, components); deposits and withdrawals are free; **contents persist per-station** … Vault contents do **not** count against cargo on launch."

`06_loot_drops.md` §3.4 (the Maw table):
> "| 1 | `comp_scrap_3` (Dreadnought Slag) | 1.00 | 3–5 | … | 6 | Credit cache (§5, large) | 1.00 | 800–1 200 CR |"
> "Expected haul per Maw: ≈ 6.375 items. Guaranteed minimum: line 1 + line 6 always pay. A Maw kill is a progression event: **a guaranteed floor of 1025 CR, a mean of 1584.75 CR**, plus the only Voidshard source in v1."

`18_engine_spec.md` §2 + §7 (death):
> "**Death: cargo drops.** Cargo spawns as pickups at the wreck with a 5-minute recovery window; hull/fit follow 14 §3 insurance."
> "respawn docked at the last station visited, insurance decides what comes back, mercy clause once per profile, heat persists."

**2026-09-27 P3 block (08 §4):** R-S26-1 — Boneyard = `ship_boss_boneyard` at
gunship-tier vitals ×2.5, 5 W; Pyre = `ship_boss_pyre` at frigate-tier ×2.5,
4 W; The Maw = `ship_boss_maw` hull 12 000 / shield 6 000, 7 W (tick E1).

## 6. Acceptance list (numbered; the report answers each with a cite)
- **A1 (arenas are places):** The Boneyard (S3) and The Pyre (S6) exist as
  lit, barricaded ring zones with nav pylons, visible at distance; entering one
  without an active run does nothing but mark the place.
- **A2 (arena contract loop):** the Expedition contract at the faction desk
  (S25's seam row flipped live — the §15.2 U7 staged row un-greys) opens the
  arena (60 s entry window), the boss fight runs, and payout lands at
  return-to-station win or lose; the cooldown is one run per boss per
  20-minute clock per profile; kill credit is the player's last hit only.
- **A3 (bosses live):** Boneyard (gunship-tier ×2.5, 5 W) and Pyre
  (frigate-tier ×2.5, 4 W) fight at R-S26-1's rows and pay **6 000 + magic
  roll / 12 000 + guaranteed rare** per S28's block (M10; 15 §5's rarity
  rules); The Maw roams S7 at the E2 rows and rolls 06 §3.4 exactly (20k
  seeded rolls: EV within the suite's bound; the floor 1 025 CR row proven).
- **A4 (death persists, 18 §2/§7):** the wreck and its cargo window survive
  the death→respawn route (a probe collects from a pre-death wreck after
  respawn); the player respawns docked at the last station visited.
- **A5 (insurance):** the premium is **1.5 % of the hull's list per class
  (135–1 080 band, M14)**, charged at launch, covers exactly one loss, and the
  payout flow is §3's verbatim (base hull of the tier's cheapest, hull+fit
  paid into the dock); Champion ×0.8 via `insurance_multiplier` (S24's seam);
  Choir stations sell none; the mercy clause reissues a bare Fighter exactly
  once per profile (a second total loss does not).
- **A6 (vaults):** one vault per station (20 units; tiers 500/1 200/2 400;
  Meridian 40-unit at +25 % tier prices), free deposits/withdrawals, contents
  persistent per station and excluded from launch cargo; `u_vault` adds +20 to
  every vault (15 §5's row).
- **A7 (deck + panels):** the INSURANCE and VAULTS panels per STATION_HUB
  §15.3/§15.4 wire into the SERVICES deck beside S25's contracts strip;
  shell-v2 idioms; every new value tabled with reversal + tick id (E1/E2 rows
  named); no gate row outside §8's list moved.
- **A8 (summary):** every moved value tabled with reversal + tick id; the
  boss-payout re-pricing cites M10, the premium cites M14.

## 7. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S26-B1 | coder (builder) | `vajb-orbit/game/npc_registry.gd, vajb-orbit/game/loot_tables.gd, vajb-orbit/game/game.gd, vajb-orbit/game/contract_registry.gd, vajb-orbit/game/module_catalog.gd, vajb-orbit/autoload/player_profile.gd, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/insurance_panel.gd, vajb-orbit/ui/station/insurance_panel.gd.uid, vajb-orbit/ui/station/insurance_panel.tscn, vajb-orbit/ui/station/vaults_panel.gd, vajb-orbit/ui/station/vaults_panel.gd.uid, vajb-orbit/ui/station/vaults_panel.tscn, vajb-orbit/tests/test_s26_endgame.gd, .agents/gen/slices/S26-endgame/S26-B1_report.md` | A1–A8 + `S26-B1_report.md` |
| S26-R1 | reviewer | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/S26-R1_review.md` | `S26-R1_review.md` + CONTRACTS §9/§10 + LOW rows |
| S26-F1 | fixer (only on HIGH/MED) | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S26-endgame/` | `S26-F1_report.md` |

Read-only throughout: `game/station_registry.gd`, `game/exchange.gd`,
`game/sector_registry.gd`, `game/mineral_catalog.gd`,
`autoload/world_clock.gd`, `docs/`.

## 8. Run order + the tests that move
**B1 → R1 → F1 only on HIGH/MED.** Expected gate growth: **+
`test_s26_endgame.gd` rows (one per AC)** only. Candidates:

| Suite | Why | Verdict |
|---|---|---|
| `test_s25_contracts.gd` | A2 flips the Expedition seam | one listed row may appear (the seam test); note it here if so |
| `test_engine2_loot.gd`, `test_s6_poi_loot.gd` | A3's Maw table feed | unchanged counts (EV bound preserved) |
| `test_p2b_retirement.gd`, `test_engine2_fixes.gd` | A4/A5's death flow | unchanged (death rows read the same signals) |
| `test_p2b_services.gd` | A6's vaults | unchanged (new service rows) |
| `test_s28_econ.gd`, `test_s24_world.gd` | S28's law, S24's seams (read-only) | unchanged |

Any other count moving is a bucket-2 pause: report it, leave it, stop.

## 9. Hard rules
- Docs read-only. `--forbidden` at verify: `docs/`,
  `vajb-orbit/project.godot`, `vajb-orbit/addons/`.
- No art (owner 2026-09-27): boss and arena visuals use the shipped renders
  and existing scene parts. Bounded runs, scratch `XDG_DATA_HOME` (L229), no
  shell edits; Layer Cake. The M10/M14 figures come from S28's block verbatim —
  never re-derived.

## 10. Staged / deferred
- The leviathan/spire/thorn bosses (art only, no design rows — needs a doc
  amendment the owner ticks first); crafting (07 is "NOT for coding");
  buy-side exchange; the wreck's cross-*session* persistence (18 pins only the
  in-run window).

## 11. Owner tick list (unticked ⇒ the PROPOSED value ships)
| Tick | Row | PROPOSED |
|---|---|---|
| E1 | R-S26-1 | the three boss hull rows as written (08 P3 block) |
| E2 | Maw roam rows (the developer lands them in 14 §5's next block at tick) | respawn on the 20-min clock after death; roams S7's field band at 0.5× freighter speed; aggro within 600 u |

(M10's boss payouts and M14's premium are owner-ratified green — not re-ticked
here; the M14 reading carries its reversal in §5.)

## 12. Close-out (the orchestrator)
1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s26_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/addons/
   --tests --expect-reports .agents/gen/slices/S26-endgame/S26-B1_report.md
   .agents/gen/slices/S26-endgame/S26-R1_review.md`
3. `python3 staging/build_code_map.py` — the map must describe the shipped tree
   (deterministic; a no-change re-run diffs nothing).
4. WAVEBOARD + `dispatch_coder.md` one-liners; `MASTER_REPORT.md` §6 recap;
   wave-boundary commit.
