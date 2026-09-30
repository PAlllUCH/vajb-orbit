---
slice: D15
reviewer: D15-R1
verdict: passed-with-followups
gate: "n/a (design only — no gate rows move)"
---

# D15-R1 review

Graded against D15_BRIEF §5's extract, §4's four rules and UI_SPEC §3.10 A5.2,
never against A1's own claims. Values re-derived from the pinned blocks, the
L-rows and the code consts.

## Acceptance list
- **A1 — pass** — 25/25 rows carry PROPOSED | reversal | tick | §text + cite
  (`D15-A1_report.md:22-48`); S22 §11's T-feel-1..6 + M4–M7, 09 §3.3's T1–T7,
  §22 T3 and L39/L103/L182/L57 all resolve (`S22_BRIEF.md:159-167`;
  `09_ship_slots_modules.md:686-690` carries M5/M6/M7 verbatim — M6's `—`
  reversal is that block's own cell). T-feel-7 takes the brief-rule-4-sanctioned
  "accepted deviation" (`D15_BRIEF.md:52-54`). F1's disclosure gap is rule 3,
  not a column miss.
- **A2 — pass** — the blocks cover exactly L48/L49/L55/L57/L59/L64 (AUDIO-1,
  AUDIO-3, T-feel-5, T-feel-7, FX-2a–c, FX-2d, FX-2e) plus A2's own chip-spark
  and §4.1 items (FX-1, AUDIO-2); blocks append-only, 37 insertions / 0
  deletions, both at EOF under dated headings (`git diff`); every row carries
  its reversal + tick id (FX-2e's `—` is the P3 blocks' no-reversal notation,
  `09_ship_slots_modules.md:689`). Quotes re-derived: §1.1's "4:1"/"6:1
  elongation" (`FX_SPEC.md:67`), §1.2 "over the muzzle" (`:77`), §1.5's 0→1.5× /
  0.3 s (`:129`), §1.6's "4-frame mini sheet" (`:139`), §6's 1.6–2.6 s cadence
  (`:270`), §4.1's five bullets incl. "N > 2", "steal the oldest", "dropped,
  not queued" (`AUDIO_SPEC.md:139-151`), the S-table's next free row S26 (`:118`).
- **A3 — pass** — all three elements specified under A5.2's four clauses and
  drawn in `staging/mockup/out/d15_feedback_composition.svg`: feed lands as four
  `Label`s in the right well's own container (A5.2(i), `UI_SPEC.md:395,413`'s
  well (316,60)–(696,348)); the marker's verb is the strike-X drawn inside its
  own full-rect child of the reticle (A5.2(iii), `hud.gd:1958-1969`'s shipped
  ARM 4.0 / SECONDS 0.25 / `accent_danger_bright`); the ram spark is one chip
  burst at the handler's contact point (`player_ship.gd:472-492`,
  `npc_ship.gd:538-548`, = L56's repro cites) with `sfx_impact_hull`/`_rock`
  (shipped, `audio_manager.gd:97`). Shipped assets only; no banded chrome, so
  clause (iv) is not engaged. No re-cut ships this round — T-feel-7's re-cut is
  the brief §10's own deferral and both re-cut mentions are reversal paths
  marked staged.
- **A4 — pass** — every named ruling is real and implemented by the named text:
  ruling 18 (`18_engine_spec.md:101`), ruling 23 (`:216`), §23 one-vector — the
  ramp chases the whole velocity (`CONTRACTS.md:1928-1931`, L182), A5.1/A5.2 and
  A5.4's "never colour alone" row (`UI_SPEC.md:627,640-645,676`) → panel 1's
  breach frame + the 0 figure, S2.6's "hits must read" (`LOW_BACKLOG.md:136`) →
  panels 2–3, the Tween house rule (`hud.gd:1958`) → panel 2. Both bucket-3
  calls reach the owner (AUDIO-3 = L49's own "Owner's call"; T-feel-1's fork =
  L25's "Owner tick: either bless orbiting or add a fuse/orbit radius to §13").
  Writes confined per the tree diff in Gate.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| D15-A1/F1 | MED | tick sheet + rulings block | T-feel-2·L103 moves an NPC flight number without rule 3's "says so", and the ruling line's "T-feel-1/1b are the only rows moving gameplay" is false on the sheet's own rows | fixer (flag the row, correct the claim) |
| D15-A1/F2 | MED | tick sheet T-feel-3 / §22 T3 / bucket-2 line | the two `docs/CONTRACTS.md` edits are assigned to "R1", who may not make them this wave | fixer (name the developer per close-out 1) |
| D15-A1/F3 | LOW | tick sheet evidence anchors | three inherited line anchors do not re-land | → ticketed as `L250` |
| D15-A1/F4 | LOW | FX_SPEC §8 FX-1 reversal | the staged chip-spark re-cut rides no staged/deferred list | → ticketed as `L251` |

Evidence, one line each:
- **F1** — `D15-A1_report.md:26` mirrors `_step_lateral_drag` into `npc_ship.gd`
  (L103: NPC skid settles ~2× slower) yet `:51` says only T-feel-1/1b move
  gameplay; the row names its §14 re-scope but never flags the flight-number
  move `D15_BRIEF.md:49-51` demands.
- **F2** — `D15-A1_report.md:28-29,56` say "R1 tightens §23.5's wording" / "R1
  strikes it in CONTRACTS §22"; `docs/CONTRACTS.md` is untouchable this wave
  (`D15_BRIEF.md:101-103`) and R1's file set is the review file (`:95`), while
  close-out 1 routes both edits to the developer at S22's open (`:116-117`).
- **F3** — `HIT_RADIUS` is `projectile.gd:70` and `SHOT_MASS` `weapons.gd:224`
  (not `projectile.gd:68,74`); the retune doc's "No other file reads this" is
  `ship_fit.gd:401` (not `:151`); the release ramp is `_step_release`/
  `_thrust_axis` (`player_ship.gd:771`, L182's own symbols — not `:873-884`).
  All three anchors ride `D15_BRIEF.md:28-31`'s table, so the rows stay sourced
  by symbol + §text; only the line numbers are stale.
- **F4** — `FX_SPEC.md:351` marks the 4-object master re-cut "(staged —
  generation budget)" but `D15_BRIEF.md:107-109` stages only the bolt/slug
  re-cut, the anti-flam assets pass and §13 columns, and `S22_BRIEF.md:155-157`
  carries L49's trim — nothing carries this one forward.

## Verified fixes
F1/F2 cured 2026-09-29 by the designer session (owner-ruled direct route, no
fixer dispatch): the T-feel-2 row flags its NPC flight-number move and the
rulings block names every gameplay-moving row (F1); the two CONTRACTS edits are
re-attributed to the developer at S22's open (F2). The two LOWs stay ticketed
(L250–L251), not fixed. A1's deliverables were never edited by this review.

## Gate
`n/a` — design-only wave, no gate rows move (`D15_BRIEF.md:98`: a row moving is
a defect). Tree diff `python3 staging/verify_wave.py verify --baseline
d15_start` → modified `docs/design/AUDIO_SPEC.md`, `docs/design/FX_SPEC.md` (37
insertions, 0 deletions), added `D15-A1_report.md` +
`staging/mockup/out/d15_feedback_composition.svg`, deleted none, `problems: []`
— nothing outside `docs/design/`, `staging/mockup/` and the slice folder moved
(`staging/compare/` predates the baseline snapshot). Negative control: the two
spec diffs contain no deletion lines.
