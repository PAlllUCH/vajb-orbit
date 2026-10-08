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
| 34 | S28 | Universal cost law | The economy's one law: the ×2.0/tier value ladder (`02`'s 2026-10-08 block), the value-relative refine fee (`04` §8), SC-scaled boss/contract payouts (`14`'s block), the battery/bloom caps (`01` L4). Five-piece: `slices/S28-economy-law/`; ticks M8–M14; two builders (C1 values+fee → C2 battery+bloom), R1, F1 on HIGH/MED. | **next** — runs before 31 because S25/S26 pin the `14` §2/§7 payouts it amends (one re-cut of their extracts, not rework) |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | queued · after 34 — `contracts_visible`/`insurance_multiplier` ship as its seams. **Its brief predates shell v2 as S24's did: re-cut it before dispatch** (`UI_SPEC.md` §12–§15 + `STATION_HUB.md` §19–§21 + `STATION_HUB.md` §15.2's U3–U8 rows), **and its `14` §2 reward extract re-cuts against S28's block** |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | queued · after 31 (Expedition seam) |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap). Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | queued · after 32 (`game/`); carries **T-153** (a tier-4 module row) |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

## Done

Items 1–44 closed (gate 437 → 1186/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md` and `MASTER_REPORT.md` §6.

## Handoff (live)

**Item 34 = S28 universal cost law — next** (the five-piece landed 2026-10-08;
dispatch from `slices/S28-economy-law/S28_prompts.md`). It runs before item 31
because S25/S26's briefs pin the `14` §2/§7 payout numbers S28 amends — one
re-cut of those extracts, not rework of their code. Items 31–33 then run in
order; re-cut each brief the way S24's was before dispatch. The owner's fresh
design round may regenerate the planning before any dispatch — check
`dispatch_designer.md` first.

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
