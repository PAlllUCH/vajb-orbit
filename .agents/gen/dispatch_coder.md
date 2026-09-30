# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-09-25 (owner ask: "too much shit to keep track of
it" — the queue carries only live items; closed work lives in
`MASTER_REPORT.md` §6 and git). Execute **one item per order**, close out per
the brief's close-out section. Model for every worker:
`deepseek/deepseek-flash` (owner ruling 2026-09-24) on
`--reasoning-effort max`. The owner pastes only the handoff block at the
bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, WAVEBOARD, wave-boundary commit).

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 27 | S21 | Stability & playtest fixes | Death state, wreck window across transitions, ship-vs-ship crash damage, profile/hermeticity hygiene, bag reads, money edges, world-sim fixes (L18/L22/L23/L24/L73/L90/L93/L110/L114/L122/L124/L130/L131/L136/L150/L152/L153/L154/L176/L215/L237/L243). Five-piece: `slices/S21-stability-fixes/`; pins R-S21-1..3 (01/10's 2026-09-27 P3 blocks, ticks M1–M3). **Split into three builders (B1/B2/B3, owner-ruled 2026-09-28)** — disjoint regions, sequential, review grades A1–A11 across all three. | **done 2026-09-29** (gate 917 → **941/0**, 1 HIGH bucket-2 list landed by F1 / 0 MED left / 3 LOW) |
| 28 | S22 | Feel, juice & balance | Hit/ram feedback, muzzle at nose, quadrant HUD feed, anti-flam + mine cue, laser_04 drop, the feel tick rows and the S19 balance rows (L28/L56/L51/L241/L54/L48/L49/L25/L39/L103/L168/L244/L242/L70; L52/L65/L55 and the FX pins were verify-only — already shipped at the ticked values). Five-piece: `slices/S22-feel-and-juice/`; pins R-S22-1..4 (01/09 P3 blocks, ticks M4–M7) + D15's ticked sheet. **Split into three builders (B1/B2/B3, owner-ruled 2026-09-30)** — sequential, review graded A1–A14 across all three. | **done 2026-09-30** (gate 941 → **971/0**, 1 HIGH bucket-2 list closed by the developer / 0 MED / 2 LOW) |
| 28.5 | S22.5 | Asteroid toughness & chip splinters | The owner's 2026-09-30 ask: a per-rock randomised toughness, size carrying toughness (S 1.5 · M 2.5 · L 4.0 · XL 6.0 on the gun door only), a real work budget for gun-born debris instead of its instant crack, and 25 %-per-hit splinters shed by an L/XL under fire. Five-piece: `slices/S22.5-asteroid-toughness/`; pins **02 §5.3's A1–A5** (owner-ticked 2026-09-30). One builder (small region: `asteroid.gd`/`asteroid_field.gd`/`ore_tuning.gd` + tests). | **done 2026-09-30** (gate 971 → **983/0**, 0 HIGH / 0 MED / 1 LOW L255 closed by the developer) |
| 29 | S23 | Content activation | `w_proton`/`w_flak` families, the three dead module effects, 7 stock fits, sibelon seam, interceptor/turret-platform hulls, per-hull sprites + liveries (L137), loot rows (L48-class closed). Five-piece: `slices/S23-content-activation/`; pins R-S23-1..6 (09/08 P3 blocks, ticks C1–C6). | queued · after 28.5 (`game/`) |
| 30 | S24 | World identity | Named stations + per-faction menus/flavours, standing band effects, per-sector hostile bands, nebula clouds (L-band-split). Five-piece: `slices/S24-world-identity/`; pins R-S24-1..3 (14/13/11 P3 blocks, ticks W1–W3). | queued · after 17 (D16's spec) + 29 |
| 31 | S25 | Contracts board | `contract_registry` + the board panel: Haul/Hunt/Gather/Escort, escrow + 100 CR cancel, standing gates, the escort convoy loop. Five-piece: `slices/S25-contracts/`; pin R-S25-1 (14 P3 block, tick J1). | queued · after 30 (`ui/station/` + profile) |
| 32 | S26 | Bosses, arenas, insurance, vaults | The Boneyard + The Pyre arena runs, the Maw roaming S7 with 06 §3.4's table, death persistence, insurance + mercy clause, vaults + `u_vault`. Five-piece: `slices/S26-endgame/`; pin R-S26-1 (08 P3 block, ticks E1/E2). | queued · after 31 (Expedition seam) |
| 33 | S27 | Catalog breadth & shipyard | +7 affix rows with perks live, tier variants, per-archetype loot, the 10 §3 shipyard (recipes/queue/scrap). Five-piece: `slices/S27-catalog-breadth/`; pins R-S27-1..3 (09/15 P3 blocks, ticks K1–K3). | queued · after 32 (`game/`) |

## Parked (owner-gated — not queued; say the word and the five-piece lands)


## Done

Items 1–28.5 closed (gate 437 → **983/0** through the waves); detail, reviews,
incidents and LOW rows in `.agents/gen/MASTER_REPORT.md` §6 and the archived
session reports.

- **Item 28 = S22 feel, juice & balance** (2026-09-30, gate 941 → **971/0**
  twice hermetic, 1 HIGH / 0 MED / 2 LOW **L252–L254**). Three sequential
  builders (owner-ruled 2026-09-30): B1 the feedback seams (A1–A4/A8/A12/A13),
  B2 the HUD feed and the audio pass (A5–A7/A14, incl. a CC0 mine cue sourced
  through `assetmcp`), B3 the flight and balance rows (A9–A11) plus the S19
  byte-seal re-pin (`npc_ship.gd 12ab0ae2…`, `weapons.gd 6f95a9c2…`). New
  suites `test_s22_feedback.gd` (11) / `test_s22_audio.gd` (7) /
  `test_s22_balance.gd` (12) = 30 rows. Its one HIGH was bucket 2 (brief §8's
  `test_s19_quadrants.gd` line missing R-S22-1's third moved row, L252) and it
  was **discharged by the developer at close** — the artefact was the brief
  itself, so no F1 ran; the two LOWs are the fuze's no-distance-gate delivery
  (owner confirm, L253) and the anti-flam docstring's overclaim (L254).

- **Item 28.5 = S22.5 asteroid toughness & chip splinters** (2026-09-30, gate
  971 → **983/0** twice hermetic, 0 HIGH / 0 MED / 1 LOW **L255** closed by the
  developer). The owner's same-day ask, docs-first in `02_minerals.md` §5.3
  (A1–A5, ticked): every rock rolls its own **0.80–1.60** toughness, size
  multiplies it as a **gun-door divisor** (S 1.5 · M 2.5 · L 4.0 · XL 6.0) so
  mining keeps its pinned 1.2 s/unit pace, oreless debris cracks on a **work
  budget** (S 2.0 · M 3.0 · L 4.5) instead of the first point of damage, and a
  **non-cracking gun hit on an L/XL sheds a real S-class splinter** at 25 %,
  capped at 1 per 0.5 s. One builder, `test_s22_5_asteroids.gd` (11 rows), the
  dev-menu Save/Load row (+1) = 971 → 983; every must-not-move suite row-identical
  (the four-times table: **S 3.61 s · M 6.00 s · L 9.61 s · XL 14.41 s** of
  `w_laser` at the mean roll, vs ≈2.0 s for every class before). Its one LOW was
  the developer's own close-out command (the §5.3 clarifying sentence landed after
  the snapshot), closed by dropping that path from `--forbidden` with the
  exception recorded.

- **Item 27 = S21 stability & playtest fixes** (2026-09-29, gate 917 → **941/0**
  twice hermetic, 1 HIGH / 1 MED / 3 LOW **L246–L249**). Three sequential
  builders (owner-ruled 2026-09-29): B1 the hull and flight scene, B2 the account
  and station, B3 the world bodies, pane copy and harness plus two owner-ruled
  pin moves (the S19 byte-seal re-pinned to the finished tree's `a694170c…`, and
  A3's reach widened to NPC-vs-NPC with `LOS_MASK` split out and the two moved
  rows re-pinned). New suite `test_s21_stability.gd` (23 rows). Its one HIGH was
  bucket 2 (brief §8's tests-that-move list missing the two `test_s5_*` suites,
  L246) — **S21-F1** landed it as the list amendment on the S19 precedent, and
  cured the MED (S20's own silent-abort row at `test_s20_chrome_unify.gd:276`)
  with the flip restored. **22 backlog rows closed** (L18/L22/L23/L24/L73/L90/
  L93/L110/L114/L122/L124/L130/L131/L136/L150/L152/L153/L154/L176/L215/L237/
  L243) with their reversals. Incident: the first F1 wedged 28 minutes on an
  unbounded Godot `--script` run and needed a `python3 os.kill` SIGKILL (the
  shell's `kill` did not reach it); re-dispatched bounded.

- **Item 26 = S19 directional armour & breach malfunctions** (2026-09-26,
  gate 895 → **914/0** twice hermetic, 1 HIGH / 0 MED / 5 LOW **L240–L245**).
  Four `hull_max/4` pools route by `ctx.direction` with the sum invariant, the
  rear 160° arc's ×1.6 lands before the shield-first absorb, an emptied pool
  runs its breach malfunction (RCS drift / flicker / turn clip, derived state),
  repairs and both readouts carry the four quadrants. Its one HIGH was bucket 2
  (the astern shielded row the pin moves, off the brief's §3 list): **S19-F1**
  ran, moved the row onto P3's own `STERN_DAMAGE_MULT` and wrote the §3 list
  amendment (L240 closed), the first fixer to take a bucket-2 list item,
  disclosed as a deviation. Ran only after S20's close-out per the
  file-collision law (its first, concurrent B1 was stopped before it wrote
  anything; the baseline was re-taken on the post-S20 tree). Owner ticks
  **T1–T7** in 09 §3.3's amendment stay open (balance deferred).
- **Item 25 = S20 ARMORY chrome unification & the hover reflow fix**
  (2026-09-26, gate 887 → **895/0** twice hermetic, 2 HIGH / **1 MED** /
  4 LOW **L234–L239**). The pane wears the §5.3 chrome family with the D13
  layout frozen, the shell inspector holds a constant height, `OVER CAP`
  measures 4.855:1 (**L227 closed**). Its one MED (the pane scene still
  carrying the retired master's ext_resource) was the fixer's only in-scope
  item, so **S20-F1** ran and dropped it; its two HIGHs are bucket-2 pin-list
  items — **L238–L239**, the developer session's list edit, no code revert.
  Owner ticks recorded in `UI_SPEC.md` §3.10 A4: T1–T4 as briefed, T5 = keep,
  **T6 open** (the bay chip's `▲ OVER CAP` vs `▲ AT CAP` wording).
- **Item 24 = S18 armory rework** (2026-09-26, gate 877 → 886/0, 0 HIGH /
  1 MED / 5 LOW L223–L229, no fixer — its one MED was UI_SPEC §3.10 A3's cell
  `117×50 → 117×52`, docs text, the developer session's owed fix, landed in
  `d323cb7`). The owner's same-day live bug report (text behind backgrounds)
  was fixed post-close-out — the chrome layer under the content, the drop cues
  in their own grid slots (L232–L233 closed, two guards) — taking the gate
  886 → 887/0.

## Handoff (live)

**Item 29 = S23 content activation — next** (paste the block at the bottom of
`.agents/gen/slices/S23-content-activation/S23_prompts.md`; the later items'
handoff blocks live in their own `<WaveID>_prompts.md`).

The whole queue is phase **P3** (`phases/P3-content-feel-push/PHASE.md`);
order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
