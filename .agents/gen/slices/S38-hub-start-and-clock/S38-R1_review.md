---
slice: S38
reviewer: S38-R1
verdict: passed-with-followups
gate: "1226/0 → 1236/0 ×2 hermetic on fresh scratch stores (B1's first read 1229/7, re-cut per brief §8's extended table)"
---

> **Use when:** a review wave runs. Copy to the slice folder as
> `<ReviewerID>_review.md`. Grade the brief's acceptance list first, then diff
> findings against `docs/CONTRACTS.md`, never against the brief. Tiering per
> WAVEBOARD: HIGH blocks, MED gets one fixer pass, LOW moves to LOW_BACKLOG as
> `T-###`.
>
> **Hard cap: 150 lines.** One row per finding, one line of evidence each (the
> probe output or the `file:line`), no pasted source and no pasted logs. Read
> `docs/CONTRACTS.md` by section — its index gives the line range; never in
> full.

# S38-R1 review

Graded against brief §5's extracts (14's 2026-10-08 S38 block, STATION_HUB
§15.2's U22) and the S38 block as landed — never against B1's report. All three
deciding measurements re-taken on fresh scratch stores: the shipped probe run
byte-identically ×2, plus R1's own `tests/probe_s38_r1_remeasure.gd` (9 samples
at 0.35 s, fresh-mount plate reads, the riders, the pin block).

## Acceptance list

- **A1 — pass.** Cold start (`filed=''`): both seams answer `s1_primary`; the
  panel reads 6 rows, no U8 empty state, `station_row=s1_primary`; the plate
  reads the row's own pair `["Halcyon Anchorage", "forge-grey bastion, the full
  menu"]`, not `ORBITAL DRYDOCK KEPLER-9` / `HELIOS DRIFT`
  (`[S38R] cold` lines; `[S38P] start plate=` on both shipped-probe runs). The
  first row's goods/reward differ from §3's citation (`haul · 4100 CR · 40×
  ingot_iron` here vs `4 500 CR · 40× ingot_aluminium`) — the seeded roll is
  band-dependent by design (S25's law), not a number move.
- **A2 — pass.** `[S38R] tick#0..8`: displayed text tracked
  `BAND_SECONDS − now % BAND_SECONDS` at every sample (expected==live, lag ≤ 1
  tick), 4 distinct texts over ~3 s, timer `wait=1.0 one_shot=false
  running=true`. Shipped probe run 2: `15:30 → 15:29 moved=true`. Run 1 read
  `moved=false` with the readout measurably live — probe-window slack, F2.
- **A3 — pass.** Driven boundary (override to the exact edge, one `_tick`):
  `band 1492943->1492944 expected=1492944`, rows ==
  `ContractRegistry.board(starting_station(), 0)` (band+1's own ids
  `c_s1_primary_1492944_*`), `changed=true`, readout restarted `20:00`,
  `same_panel=true` — no scene change, no player action.
- **A4 — pass.** `sector_7` filed → place `{}`, id seam `sector_7` (the
  sentinel, not empty) and a **fresh-mount** plate = the scene's placeholder
  pair (the fallback intact; a reused screen keeps the last written identity, so
  the fresh mount is the honest reading). Null profile `{}`; unparseable
  `nonsense` → place `{}`, id seam returns the filed id — both unchanged.
- **A5 — pass.** T-156: one dimmed inner box, `modulate == text_dim`, the type
  icon descends under it (alpha 1.00 — the dim is the colour multiply); the
  suite's negative control holds (live rows `Color.WHITE`, not in the dimmed
  set). T-157: accept → rows `6->5`, id gone from the drawn rows, second
  `accept(id)` → `ok=false`, `active=1` — the second attempt cannot happen, in
  the suite and in R1's probe.
- **A6 — pass.** Gate `[SUMMARY] passed=1236 failed=0` exit 0, twice, fresh
  scratch stores; growth is exactly `test_s38_start_and_clock.gd` +10 (per-suite
  `func test_` counts diffed against the pre-wave tree move no other row). The
  seven re-cuts graded below; probe lines recorded; §26's pin block re-read
  byte-identical off the live tables (board 6, max 3, fee 100, round 100, SC
  1100/1500/3000/6000, flats 800/1200/300, Known 11/+5 %, gate floor −11,
  `BAND_SECONDS` 1200).

**The seven re-cuts (graded inside A1/A6).** All seven preserve their row's
intent; none hides a defect. The four `&""` → `&"sector_7"` sites
(`test_s24_world.gd:512`, `test_s25_contracts.gd:1174`, `test_s29_station_panels.gd:87`
with `_docked_station` saved/restored, `test_s3_auction.gd:431`) restore the
exact "not at a station" fixture (no station row → factor 1.0), so 14 §6's 692,
U8's second state verbatim, both 12 000 list prices and the hot-slot-only
discount all stay proven; S24's seam test now asserts `s1_primary` from both
seams, which is that row's own subject under H1; the `REGISTRY_MD5` re-pin
matches the shipped file byte-for-byte (`md5sum game/sector_registry.gd` =
`71e7d4f488b510d70e09f6f65540b840`, third re-pin, S23/S24 precedent). The
developer's re-cuts chose fixture restoration over B1's proposed expectation
changes (10 200) — the stronger choice; B1's code is untouched by the addendum.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | `tests/test_s25_contracts.gd:1204-1212` | §8's own verdict for `test_a8_the_launch_line_names_the_docked_sector`'s last leg — "outcome unchanged … but its wording is stale — restate" — was never executed: the message still says "a profile with no place still names no dead sector" while H1 makes that filed id the cold start at Halcyon (the leg still passes: `OPEN SPACE · HALCYON REACH` carries no `HELIOS`). One wording line + its comment; outcome untouched. | F1 |
| F2 | LOW | `tests/probe_s38_start_board.gd:30,144-146` | The countdown proof waits 1.2 s over a 1.0 s tick — 0.2 s of slack, so one ≥0.2 s frame flips the read to `moved=false` (R1's run 1 did exactly that while R1's nine-sample probe showed the readout live). Widen `TICK_WAIT` (≥2.2 s) or take three reads. Harness only; the game readout is fine. | → ticketed as `T-158`, not fixed here |
| F3 | LOW | `autoload/world_clock.gd:6` | The header still claims "there are no per-consumer Timers, ever" while two consumers now own 1 Hz display-tick timers (`refinery_panel.gd:250`, `contracts_panel.gd`'s `_make_tick_timer`); scope the sentence to band evaluation (comment-only — 14's S38 block pins the tick idiom, so the spec is not in tension, only the header). | → ticketed as `T-159`, not fixed here |

No HIGH, no other MED. The gate-row diff against §8 is exact: the three
originally listed rows plus the four added ones, nothing else moved (counts and
PASS set); §8's "unchanged" rows are unchanged (`test_s24_world.gd`'s
null-profile and unparseable legs pre-existed and stand).

## Riders' disposition

- **T-156 — closed in code** (S38-B1): whole-row dim via the inner box's one
  `modulate` (`contracts_panel.gd` `_dim_rows` + `_apply_tokens`), re-measured
  by suite row and by R1's probe.
- **T-157 — closed in code** (S38-B1): `_without_active` filters accepted ids at
  `_refresh`; the panel's `accept` door refuses a second attempt
  (`REASON_UNKNOWN`); re-measured by suite row and by R1's probe.
- LOW_BACKLOG's next free id at write time: **T-158** (F2), **T-159** (F3); the
  next free ticket after them is **T-160**.

## Verified fixes

None yet — F1 goes to the fixer pass (one wording line); F2/F3 are ticketed.

## Gate

`[SUMMARY] passed=1236 failed=0` ×2 on fresh scratch stores, exit 0 both times
(R1's own runs; the two lines agree). The two tolerated red lines are present
and unchanged (`test_weapon_fx_f4.gd`'s `_clear()` SCRIPT ERROR, the
`Parameter "data.tree" is null.` warning). Negative controls: the shipped
probe's `board_of_empty_row=0` (the registry itself still answers 0 for an empty
row) and `band next_roll_differs=true`; the suite's live-row undimmed control.
`staging/verify_wave.py verify --baseline s38_start --forbidden
vajb-orbit/project.godot vajb-orbit/addons/ --tests`: `"problems": []`, the
added files are exactly the wave's four (B1 report, the suite, B1's probe,
R1's probe). CONTRACTS §9's S38 block, §10's v0.50 row and new **§27** (the
wave's pinned interface) written; the index regenerated (29 sections).
