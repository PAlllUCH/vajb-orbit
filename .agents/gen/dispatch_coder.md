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
| 36 | S39 | Flight feel, hostile fire and cargo | The owner's playtest #2, seven findings: enemies never shoot back (T-164); a 180° reversal takes two `accel_time`s (T-165); Shift buys no thrust so it cannot tighten a turn (T-166); no baseline boost for a module to stack on (T-167); a convoy cannot recover its route (T-168); weapon knockback throws hulls like ragdolls (T-169); cargo invisible in flight and at the station (T-170). Five-piece: `slices/S39-flight-feel/`. | **closed 2026-10-10** — gate **1258 → 1267/0** ×2 hermetic, verify clean vs `s39_start`; new suite `tests/test_s39_feel.gd` (9 rows, A1–A7); `test_s19_quadrants.gd` re-pinned `npc_ship.gd`/`npc_brain.gd`, `probe_rock_cleave_a2.gd` re-pinned to 0.15; CONTRACTS **§29** + §10 **v0.55**; **T-164–T-170 closed**; every new number PROPOSED with its reversal |
| 37 | S40 | The legibility pass | The owner's visibility review of the station decks (playtest #2 follow-up): the armory's installed-modules overview has no background (T-172); the OVERVIEW tiles' icons and texts are unreadable on theirs (T-173); "a review of visibility is needed and composition". The review itself is `slices/S40-legibility/S40_REVIEW.md` — ten decks rendered at 1920×1080, 607 labels measured for WCAG contrast against their own ink rect. Five-piece: `slices/S40-legibility/`. | **closed 2026-10-10** — gate **1267 → 1275/0** ×2 hermetic, verify clean vs `s40_start`; the measured below-AA share **241/607 (39.7 %) → 34/610 (5.6 %)**, below-3.0:1 **47 → 5**; new suite `tests/test_s40_legibility.gd` (8 rows, A1–A3); UI_SPEC **§16**; **T-171/T-172/T-173 closed**, **T-174/T-175/T-176 + T-177 filed**; the caption tone PROPOSED, awaiting the owner's ratify |
| 34 | S28 | Universal cost law | The economy's one law: the ×2.0/tier value ladder (`02`'s 2026-10-08 block), the value-relative refine fee (`04` §8), SC-scaled boss/contract payouts (`14`'s block), the battery/bloom caps (`01` L4). Five-piece: `slices/S28-economy-law/`; ticks M8–M14; two builders (C1 values+fee → C2 battery+bloom), R1, F1 on HIGH/MED. | **closed 2026-10-08** — gate 1202/0 ×2, verify clean vs `s28_start`; C1 +10 rows, C2 +6; R1 no HIGH, its one MED fixed in review, 2 LOW → T-154/T-155; CONTRACTS §25; ticks M8–M14 ratified green |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop, S28's tier-scaled payouts. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | **closed 2026-10-08** — gate 1226/0 ×2, verify clean vs `s25_start`; B1 +22 rows; R1 blocked on 2 HIGH (the loop had no production caller; a band-flaky escrow row) + 1 MED (Hunt's flat standing), F1 cured all three (+2 rows, negative control) → 1226/0; 2 LOW → T-156/T-157; **T-138/T-152/T-154 closed**; CONTRACTS §26; tick J1 shipped as PROPOSED |
| 35 | S38 | The board's clock and the hub's cold start | The owner's 2026-10-08 playtest finding: the hub entered from the main menu offers no contracts (the docked place is never filed on that path) and the board's 20-minute roll has no visible countdown. Five-piece: `slices/S38-hub-start-and-clock/`; ticks H1–H3; riders T-156/T-157. | **closed 2026-10-08** — gate 1226 → **1236/0** ×2 hermetic on fresh scratch stores, **zero** `SCRIPT ERROR` lines, verify clean vs `s38_start`; B1 +10 rows (H1 the cold-start place, H2/H3 the U22 countdown and the in-place re-roll), one MED (a stale test message) cured by F1, 2 LOW → T-158/T-159; **T-156/T-157 closed**; CONTRACTS **§27** + §10 v0.50/v0.51; ticks H1–H3 shipped as PROPOSED |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | **closed 2026-10-10** — gate **1237 → 1258/0** ×2 hermetic on fresh scratch stores (row sets byte-identical), verify clean vs `s26_start`, `build_code_map.py` re-run; B1 landed A1–A8 (+20 `test_s26_endgame.gd` rows), R1 left **1 HIGH + 4 MED**, F1 cured all five at their named sites moving no test row (reviewer's probe 80/1 → 81/0); the §8 list held exactly (+20 new, `test_s25_contracts.gd` +1 net — three seam rows re-cut by the orchestrator before the review); 2 LOW → **T-161/T-162/T-163**; CONTRACTS **§28** + §10 **v0.54**; ticks E1/E2 shipped as PROPOSED |
| 38 | S41 | The composition pass | The D23 design audit implemented: 16 findings (1 HIGH, 8 MED, 7 LOW) from a visual / UI designer's review of the ten station decks — the OVERVIEW's navigation rows below the fold, the armory's unroofed left sector, the battery list's mislabelled column, the refinery's undivided ore list, invisible disabled states, scrollbars that read on no deck, three action geographies, and **T-177**'s uid-less theme generator. Five-piece: `slices/S41-composition/`; source `slices/D23-panel-audit/D23-R1_audit.md`. | **closed 2026-10-11** — gate **1300 → 1330/0** ×2 hermetic on fresh scratch stores, verify clean vs `s41_start`, `build_code_map.py` re-run; **five builders** (B1–B4 parallel + B5 the completion pass the file-set stop forced), **R1** (glm-5.3-flash, code **and** visual) **passed-with-followups** — all 16 findings fixed at their named sites and visible on ten fresh renders; **T-177 closed** (the generator preserves the `.tres` uids; a regeneration is a byte no-op); one MED is an owner call (no fixer ran), 3 LOW → **T-180/T-181/T-182**; CONTRACTS **§9 S41 block** + §10 **v0.58**; new chrome values PROPOSED |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap), prices from 01's L2 bands. Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | **closed 2026-10-10** — gate **1275 → 1300/0** ×2 hermetic on fresh scratch stores, verify clean vs `s27_start`, `build_code_map.py` re-run; two builders (B1's set was under-scoped for A2/A5's flight call sites and four `tests/` pins — the brief §7/§8 amendments re-scoped it, B2 closed both), R1 (glm-5.3-flash) left **no HIGH** / 2 MED / 1 LOW, F1 cured both MEDs (a `stat`-level prefix dedupe; a `NpcShip.pre_hit_hull_fraction()` Pyre gate, its AC6 seal re-pinned); **T-153 closed**, F3 → **T-178**; CONTRACTS **§20 S27 block** + §9 + §10 **v0.56/v0.57**; ticks K1–K3 shipped PROPOSED |

## Parked (owner-gated — not queued; say the word and the five-piece lands)

## Done

Items 1–45 closed (gate 437 → 1330/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md` and `MASTER_REPORT.md` §6.

## Handoff (live)

**Queue empty — item 38 (S41) closed 2026-10-11.** P3's remaining work is the
owner's eye, not a wave: playtest build 2 and the tester template
(`docs/gameplay/19_testing_notes.md`) are the phase's exit criteria. The next code
work follows a fresh planning round — check `dispatch_designer.md` first. Four
owner ticks are open before touching the affected surfaces: **T-178** (the
shipyard build band post-S28), **T-179** (the Pyre ring's own-kill cascade),
**T-180** (the tooltip vs a pane's own header) and **T-181** (STATION_HUB §5.7's
refinery wording; next free ticket **T-183**), plus S41's PROPOSED chrome tokens
and the OVERVIEW hull-block tradeoff on TICKS. Lessons the last two waves taught:
a brief's `VAJB_WORKER_FILES` set must cover every file an acceptance item's own
text reaches (S27-B1 and S41's F8/F15 both stopped on this — the stop is correct,
but the fix is to scope the set, and a completion builder is the cheap repair);
a `tests/` pin a wave's own rows obsolete is the developer's bucket-2 re-cut, not
a builder's; a brief that contradicts a pinned doc is the **developer's** error,
not the worker's (S41's F14 brief named the wrong refinery action set — always
re-read the pin the finding touches); the four S19 sealed files (`damage.gd`,
`npc_ship.gd`, `npc_brain.gd`, `weapons.gd`) re-pin to the finished tree by the
S22 procedure when a wave edits one; and a parallel wave's per-worker gate line is
not the wave's gate — run the settled tree before believing a failure count.

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
