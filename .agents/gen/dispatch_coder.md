# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-10-08 (owner clear-out: live items only — the closed
S36 row and the Done section live verbatim in `_archive/dispatch_done_2026-10-08.md`,
the earlier done rows in `_archive/dispatch_coder_done_2026-10-07.md`, the wave
recaps in `MASTER_REPORT.md` §6). Execute **one item per order**, close out per
the brief's close-out section.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, `build_code_map.py`, WAVEBOARD, wave-boundary commit).

**`build_code_map.py` in the close-out (adopted 2026-10-08, S24's close-out).** A
wave that adds or renames files leaves `docs/CODE_MAP.md` stale; S24's new
`game/station_registry.gd` plus its two suites proved it (22 changed map lines).
The step is law from this wave on; reversal: drop it from this paragraph, the
AGENTS.md handoff template and the slice briefs' close-out sections. **Provenance,
recorded so the guard stays honest:** S24-F1 added it out of scope, through bash,
undisclosed; the developer session re-authored it here with its rationale and its
reversal, so the law changed by a ruling and not by an implementer.

**Model roster (owner, 2026-10-03, shell-v2 round):** code runs
`hyper/deepseek-v4.1-flash`, heavy design runs `xiaomi/mimo-v2.6-pro`, review
runs `hyper/glm-5.3-flash` — every run at the provider's max reasoning effort
(mimo's enum caps at `high`, measured 2026-10-03). Nothing heavier without
asking the owner first.

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 34 | S28 | Universal cost law | The economy's one law: the ×2.0/tier value ladder (`02`'s 2026-10-08 block), the value-relative refine fee (`04` §8), SC-scaled boss/contract payouts (`14`'s block), the battery/bloom caps (`01` L4). Five-piece: `slices/S28-economy-law/`; ticks M8–M14; two builders (C1 values+fee → C2 battery+bloom), R1, F1 on HIGH/MED. | **closed 2026-10-08** — gate 1202/0 ×2, verify clean vs `s28_start`; C1 +10 rows, C2 +6; R1 no HIGH, its one MED fixed in review, 2 LOW → T-154/T-155; CONTRACTS §25; ticks M8–M14 ratified green |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop, S28's tier-scaled payouts. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | **closed 2026-10-08** — gate 1226/0 ×2, verify clean vs `s25_start`; B1 +22 rows; R1 blocked on 2 HIGH (the loop had no production caller; a band-flaky escrow row) + 1 MED (Hunt's flat standing), F1 cured all three (+2 rows, negative control) → 1226/0; 2 LOW → T-156/T-157; **T-138/T-152/T-154 closed**; CONTRACTS §26; tick J1 shipped as PROPOSED |
| 35 | S38 | The board's clock and the hub's cold start | The owner's 2026-10-08 playtest finding: the hub entered from the main menu offers no contracts (the docked place is never filed on that path) and the board's 20-minute roll has no visible countdown. Five-piece: `slices/S38-hub-start-and-clock/`; ticks H1–H3; riders T-156/T-157. | **closed 2026-10-08** — gate 1226 → **1236/0** ×2 hermetic on fresh scratch stores, **zero** `SCRIPT ERROR` lines, verify clean vs `s38_start`; B1 +10 rows (H1 the cold-start place, H2/H3 the U22 countdown and the in-place re-roll), one MED (a stale test message) cured by F1, 2 LOW → T-158/T-159; **T-156/T-157 closed**; CONTRACTS **§27** + §10 v0.50/v0.51; ticks H1–H3 shipped as PROPOSED |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | **next** — S25's Expedition seam is the `staged` row `contract_registry` ships, waiting for its arena payout. **Brief re-cut 2026-10-08** — boss payouts re-cut to 6 000/12 000 (M10), the premium law re-cut to M14's 1.5 %-of-list, the panel law pinned to STATION_HUB §15.3/§15.4, cites re-measured. Dispatch from `slices/S26-endgame/S26_prompts.md` |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap), prices from 01's L2 bands. Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | queued · after 32 (`game/`); carries **T-153** (a tier-4 module row). **Brief re-cut 2026-10-08** — prices re-pointed to 01's L2 bands (nothing restates a price; recipe CR totals re-derive from the live values), T-153 folded in, cites re-measured |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

## Done

Items 1–44 closed (gate 437 → 1226/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md` and `MASTER_REPORT.md` §6.

## Handoff (live)

**Item 32 = S26 bosses, arenas, insurance and vaults — next** (its brief was
re-cut 2026-10-08 against the shipped game; dispatch from
`slices/S26-endgame/S26_prompts.md`). S38 closed ahead of it on 2026-10-08: both
hold `game/` and `ui/screens/station.gd`, and S26 needs a hub that is readable on
the menu path — which S38 delivered (the cold-start place, the roll countdown,
the in-place re-roll). Item 33 (S27) then runs. The owner's fresh design round
may regenerate the planning before any dispatch — check `dispatch_designer.md`
first.

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
