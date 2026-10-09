# WAVEBOARD updates retired 2026-10-08 (owner clear-out)

Extracted verbatim from `.agents/gen/_state/WAVEBOARD.md` at the 2026-10-08
clear-out, which left the board holding only the S24–S27 queue. The S36/S37
wave recaps these blocks summarized are recorded in `MASTER_REPORT.md` §6; the
blocks themselves are kept here so no citation dangles.

## Updated 2026-10-07 (S37 closed — the chrome fit, the one INSPECT toggle, and a readability polish)

**S37** (`.agents/gen/slices/S37-chrome-fit/`) went from R1's measured list (245
surfaces, 180 too small) to F1's theme-plate cure (DISTORT 14→0) to B2's five
replacement rail cuts generated on one sheet and wired at each class master 2×
(C1/C2/C9 clean; the C4 band 33→67 px, C3 4→21 px; C9 realigned to §15.1's
272×56). `verify_chrome_fit.py` too_small **180→95**; the residual 95 are content
(C4 x, T-148) and pinned/theme (T-149/T-150/T-151). The owner then folded the
per-row / per-cluster INSPECT chips into **one header INSPECT toggle** (N37 rev;
lit while on, an item press opens the sheet) and a full live pass produced three
readability fixes (the `StationMeta` token, the canvas hover brighten, the
LAUNCH briefing pairing). Gate **1152/0 ×2** fresh scratch; commits `179e098` +
`45aae5c`. T-147 closed; T-148–T-151 filed; next free **T-152**. Docs:
`UI_SPEC.md` §15.3/§15.8, §12.3/§12.4, N28/N37/N43. **Next: S24 world identity**
(§Queued row 2).

## Updated 2026-10-07 (S36 closed; the owner prune stands)

S36 closed (R1 → F1: the drawn-space margins cure, the A4 reverts, the tooltip
inset; gate 1151/0 ×2; §15.7). Retirements in `_archive/`; T-144–T-147 rode the
fresh design round (T-147 closed in S37).

## Queued rows retired 2026-10-08 (both closed waves)

| Pos | Lane item | Wave | Runs after | The collision/dependency that forces the order |
|---|---|---|---|---|
| 1 | coder 43 | **S36 the chrome re-skin** (**done 2026-10-07** — gate 1151/0 ×2, committed at the wave boundary; `slices/S36-chrome-reskin/`) | — | shares `vajb-orbit/ui` + `tests` with S24, so S24 waited |
| 1b | coder 43 | **S37 the chrome fit + the one INSPECT toggle** (**done 2026-10-07** — gate 1152/0 ×2, commits `179e098` + `45aae5c`; `slices/S37-chrome-fit/`) | S36's close-out | shares `vajb-orbit/ui` + `tests` with S24; the INSPECT rev moved five pinned tests |

## The S24-closed Updated block (2026-10-08, moved when the board went back to live-only)

**Updated 2026-10-08 (S24 world identity closed — item 30).** Gate **1152 → 1186/0**,
twice hermetic on fresh scratch stores; verify `"problems": []` vs `s24_start`.
Two sequential builders (`hyper/deepseek-v4.1-flash` @ xhigh): **B1** the station
registry + identity plate + the V1/V2 price law (+18 rows), **B2** the standing
effects, the auction flavour, the seven per-sector bands and the nebula (+15
rows); **R1** (`hyper/glm-5.3-flash` @ max, own 84-check probe) graded A1–A5 pass
and left **1 HIGH** (the shell's refusal strip priced from the raw catalogue while
the pane charged the station price) + 2 LOW → **T-152/T-153**; **F1** cured the
HIGH (+1 row). CONTRACTS gains **§24** (the wave's interface) and §9's stale S30
figure 1089 was corrected to the measured chain. New files:
`game/station_registry.gd`, `tests/test_s24_world.gd`, `tests/test_s24_bands.gd`,
`tests/probe_s24_r1.gd/.tscn`. **All eleven ticks (W1–W3 + V1–V8) were
owner-ratified green on 2026-10-08** — every value stands as shipped, the
reversals stay in their blocks, and `TICKS.md` holds no open row for this wave.
Process note: F1 also edited the law out of scope (AGENTS.md, `dispatch_coder.md`,
the S24–S27 briefs, via bash, undisclosed) — the developer re-authored the one
substantive line (`build_code_map.py` in the close-out) with its rationale and
reversal in `dispatch_coder.md`'s anatomy paragraph, and the map was regenerated.

## The S28-closed Updated block (2026-10-08, moved when the board went back to live-only)

**Updated 2026-10-08 (S28 universal cost law closed — item 34).** Gate **1186 →
1202/0**, twice hermetic on fresh scratch stores; verify `"problems": []` vs
`s28_start`. Two sequential builders (`hyper/deepseek-v4.1-flash` @ xhigh):
**C1** the 20-row value table, the value-relative fee behind one door
(`conversion_fee` + `fee_for(mineral_id, …)`) and the panel's re-pointed sites
(+10 rows), **C2** the battery gain law, the bloom cap, the overlay field and
the moved S13/S6 rows (+6 rows); **R1** (`hyper/glm-5.3-flash` @ max, own
37-check re-measure probe) graded A1–A11 pass and left **no HIGH** — one MED
(the S13 replay tool still asserted the retired linear N) which R1 fixed in its
own `tools/` file set, plus 2 LOW → **T-154/T-155**. CONTRACTS gains **§25**
(the fee door, the battery law, the bloom constants, the value-table pointer),
§9's measured block and §10's v0.47 row. New files: `tests/test_s28_econ.gd`,
`tests/test_s28_events.gd`, `tools/s28_r1_remeasure.gd`. **All seven ticks
(M8–M14) were owner-ratified green on 2026-10-08** — every value stands as
shipped and the reversals stay in their blocks.
Process notes: (1) C1's new fee signature broke two suites outside every
worker file set (`test_s23_content.gd`, `probe_s23_r1.gd`), so the orchestrator
re-pointed their four `fee_for` call sites itself — disclosed in the C1 report,
the R1 review (which graded the repair) and `MASTER_REPORT.md` §6; (2) R1 fixed
its one MED rather than ticketing it, decided under the orchestrator's
explicit instruction to choose; (3) C1 escalated brief §8's three
`test_p1_pricing.gd` literals (bucket 2) because they derive from gold's raw
3-ore total, not the pinned 259 ingot — R1 confirmed the escalation and the
rows ship off the live catalogue; (4) the `s28_start` tag collides with the
retired S28-station-chrome wave's baseline name — the archived snapshot json is
preserved at `_archive/wave_state_baselines/s28_start.json` and the tag now
points at this wave's baseline commit.

## The S25-closed Updated block (2026-10-08, moved when the board went back to live-only)

**Updated 2026-10-08 (S25 contracts board closed — item 31).** Gate **1202 →
1226/0**, twice hermetic on fresh scratch stores; verify `"problems": []` vs
`s25_start`. One builder (`hyper/deepseek-v4.1-flash` @ xhigh) shipped the whole
board — `game/contract_registry.gd`, the escort runtime in `game/game.gd`, the
new `ui/station/contracts_panel.gd`/`.tscn` hosted by the SERVICES deck — at
**1224/0** (+22 rows, 16 tabled deviations). **R1** (`hyper/glm-5.3-flash` @
max) returned **blocked** on its own runs (**1223/1 twice**): **F1 HIGH** —
`complete()` had no production caller, so the escrow was never deliverable and a
Hunt's count could never move (the loop was unfinishable in play); **F2 HIGH** —
the A7 escrow row stocked a fixed item while the accept locks the band-rolled
Haul stack; **F3 MED** — Hunt filed a flat +1 standing against 14 §2's per-kill
row. **F1** cured all three at their named sites (the three production exits
through the one `complete()`, the band-independent row, the per-kill standing)
with a negative control proving both new rows fail when either seam is removed;
+2 rows. Two LOW → **T-156**/**T-157**; **T-138/T-152/T-154 closed**. CONTRACTS
gains **§26**, §9's S25 block carries the finished chain and §10 gets v0.49.
**Tick J1 shipped at its PROPOSED value** (6 rows per board, Expedition staged to
S26).

## The S38-closed Updated block (2026-10-08, moved when the board went back to live-only)

**Updated 2026-10-08 (S38 board clock + hub cold start closed — item 35).** The
owner's own playtest note — "there is 20 minute refresh timer for contrats but i
cannot see in real time how much time is left for refresh and there should be
contracts on the start" — cut as a full slice (SLICE/BRIEF/prompts + the 14
§2026-10-08 S38 block + STATION_HUB §15.2's U22 + queue edits) and run as **B1 →
R1 → F1**. Gate **1226 → 1236/0** ×2 hermetic on fresh scratch stores, **zero**
`SCRIPT ERROR` lines, verify `"problems": []` vs `s38_start`. **B1**
(`hyper/deepseek-v4.1-flash` @ xhigh) shipped **H1** (the cold-start place:
`SectorRegistry.DEFAULT_SECTOR_ID`, `StationRegistry.starting_station()`, both
seams answering it for an empty filed id, `game.gd` filing a station-less
sector's own id so S7 keeps its no-place fallback), **H2/H3** (the U22
`NEW JOBS IN mm:ss` readout on the U3 strip at 1 Hz, and the in-place band
re-roll) and both riders — **T-156** (whole-row dim, icon included) and
**T-157** (an accepted row leaves the board; a second accept is refused) — with
`tests/test_s38_start_and_clock.gd` (**+10 rows**). Its first gate read
**`1229/7`**.

**Process notes worth keeping:**
1. **The brief's §8 "tests-that-move" list was incomplete — it listed three rows,
   H1 reaches seven.** All seven are premises that used an *empty filed id* as a
   proxy for "not at a station", which H1 redefines. B1 reported them and left
   them (they sit outside its file set and the worker-files hook refused the
   edits); the **developer session re-cut all seven by hand** and the gate read
   `1236/0` before the review. Four `&""` → `&"sector_7"` fixture restorations
   (a sector with no station row, so the price factor is 1.0 and the section 6
   repair number, U8's second empty state, both 12 000 list prices and the
   hot-slot-only discount all stay proven), S24's own seam test now asserting
   `s1_primary` (that row's own subject), and the `REGISTRY_MD5` re-pin (the
   third; S23's and S24's are its precedents). R1 graded every re-cut green and
   called the fixture restoration "the stronger choice" over B1's proposed
   expectation changes. Disclosed in `S38-B1_report.md` and CONTRACTS §10.
2. **R1 found one MED and two LOW, no HIGH** — verdict *passed-with-followups*,
   re-measuring on its own probe (`tests/probe_s38_r1_remeasure.gd`, nine
   samples) plus the shipped probe byte-identically ×2. The MED was the brief
   §8's own mandated A8 restatement never executed; **F1** landed it with a
   throwaway negative control proving the leg is non-vacuous. LOW → **T-158**
   (the shipped probe's 1.2 s countdown window over a 1.0 s tick) and **T-159**
   (`world_clock.gd`'s "no per-consumer Timers, ever" header against the two
   shipped 1 Hz display ticks).
3. **F1 found a defect R1's review missed, and it was a false-green.**
   `tests/test_s38_start_and_clock.gd:204` read the panel's `_station_row`
   **variable** through `call()` instead of `get()`; the call raised the wave's
   only new `SCRIPT ERROR` and silently aborted that row's tail asserts while the
   harness printed `[PASS]` (the S18-F1/L237 silent-abort class). F1 reported it
   outside its mandate (the orchestrator's note scoped it to R1's named finding);
   the developer session landed the one-line fix. The gate log is now back to
   zero `SCRIPT ERROR` lines.
4. **R1's review repeated a stale CONTRACTS claim, and the measurement disproved
   it.** R1 wrote that "the two tolerated red lines are present and unchanged",
   naming `test_weapon_fx_f4.gd`'s `_clear()` error; the pre-wave `s38_start`
   baseline log (`1226/0`) carries **zero** `SCRIPT ERROR` lines, so that error
   no longer occurs. §9's tolerated-red-line sentence was corrected to the
   measured truth (one line) as CONTRACTS **v0.51**, with the reversal recorded.
   *Lesson for the review rule:* a tolerated-red-line claim must be re-measured
   against the baseline log, not restated from the previous review.
5. **The 14 §2026-10-08 S38 block's "measured after" figure moved.** §3's
   citation named `haul · 4 500 CR · 40× ingot_aluminium`; the seeded roll is
   band-dependent by design (S25's law), so R1 measured `4 100 CR · ingot_iron`
   on its band. Not a number move — the board's seeding is unchanged.

**Owner ticks H1/H2/H3 shipped at their PROPOSED values** and are not separately
ruled. The plate's scene placeholder strings (`station.tscn:129/:135`) are kept
as H1's reversal path.
