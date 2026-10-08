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
lane, WAVEBOARD, wave-boundary commit).

**Model roster (owner, 2026-10-03, shell-v2 round):** code runs
`hyper/deepseek-v4.1-flash`, heavy design runs `xiaomi/mimo-v2.6-pro`, review
runs `hyper/glm-5.3-flash` — every run at the provider's max reasoning effort
(mimo's enum caps at `high`, measured 2026-10-03). Nothing heavier without
asking the owner first.

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 30 | S24 | World identity | Named stations + per-faction menus/flavours, standing band effects, per-sector hostile bands, nebula clouds (L-band-split). Five-piece: `slices/S24-world-identity/`; pins R-S24-1..3 (14/13/11 P3 blocks, ticks W1–W3) + the new mechanism pins V1–V8 (12/14/13/11's 2026-10-08 blocks). | **next — brief re-cut 2026-10-08** against the shipped shell (S30–S37) and re-measured: baseline 1152/0, **two sequential builders** (B1 = the station entity/identity/prices A1–A2, B2 = bands/standing/auction/nebula A3–A5) then R1, then F1 only on HIGH/MED. Dispatch from `S24_prompts.md` |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | queued · after 30 (`ui/station/` + profile) |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | queued · after 31 (Expedition seam) |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap). Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | queued · after 32 (`game/`) |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

## Done

Items 1–43 closed (gate 437 → 1152/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md` and `MASTER_REPORT.md` §6.

## Handoff (live)

**Item 30 = S24 world identity — next, re-cut 2026-10-08** (two sequential
builders B1 → B2, then R1; dispatch lines in `S24_prompts.md`, models per the
roster). Items 31–33 then run in order. The owner's fresh design round may
regenerate S24–S27's planning before any dispatch — check `dispatch_designer.md`
first.

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
