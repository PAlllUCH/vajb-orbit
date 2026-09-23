---
slice: S4
worker: S4-H4
model: deepseek-v4-flash
status: informational   # both findings fixed; one §16 wording item is owed to the developer session
gate: "521/0 → 524/0 (twice, exit 0, live stores byte-identical)"
---

# S4-H4 report — the S4 fixer pass

Fixer of wave S4. **F1 (HIGH) and F2 (MED) are fixed; nothing else was touched** (no LOW, no
refactor, no balance value, no frozen file). `VAJB_WORKER_FILES` =
`vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,`
`vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/weapons.gd,vajb-orbit/tests/,docs/CONTRACTS.md`.

Law read before working: `AGENTS.md`, `docs/gameplay/09_ship_slots_modules.md` §10 + §4,
`docs/design/STATION_HUB.md` §5.1, `docs/CONTRACTS.md` §16 v0.8.0/§13/§8.2/§9, the brief, and the
review's F1/F2 at their named `file:line` — never the brief's summary in place of a pin.

## Result

- **F1 fixed**: a held trigger is a stream of salvos again. One pull held 3.0 s on a three-cannon
  battery fires **15 shots (five three-barrel salvos, ~0.6 s apart)** where the review measured
  **3 shots and then ~2 976 frames with none**; the mine keeps **1** release per pull.
- **F2 fixed**: a bulk action that refuses leaves the hull holding **no** stored fit when it held
  none — measured `fits()` `[] → []` on the review's own case (fresh Lancer, one laser instance,
  `SWAP ALL` refused with the catch-all) where the review measured `[] → [ship_fighter]`.
- **Gate: `521/0 → 524/0`**, run twice on the final tree, `exit 0` both times, 524 tests over 44
  suites, one `SCRIPT ERROR` (L61's pre-existing `tests/test_weapon_fx_f4.gd:178` line), live
  `user://` pair byte-identical before and after every run and every probe.
- Three new tests (**+3**), two of which bite: on the pre-fix sources the two new suites read
  `passed=58 failed=2` and the F1 print reads exactly the review's defect line (`3 shots = 5
  windows x 3 barrels`).

## Finding-by-finding disposition

### F1 (HIGH) — a sustained trigger fires one salvo and then nothing — **FIXED**

**Root cause (the review's, confirmed by reading and by re-running its probe on the pre-fix
tree).** `tick` reached `_arm_battery` only on the pull's rising edge (`game/weapons.gd:612`
pre-fix) or on a mid-hold group switch (`:627`), and `_armed_weapon` was cleared only by
`_disarm_battery` (release, `:616`) or at the top of an arm (`:651`). So while the trigger was
held `id == _armed_weapon`, no re-arm happened, every `_armed[position]` was already `-1.0`
(`_release_battery`'s first guard skipped every barrel, `:691-692`), and the per-barrel cadence
timers — the whole reason rule 4 replaced the single `_shot_timer` — gated nothing after the first
salvo. Re-measured on the pre-fix sources with the review's own probe: `held 3.0 s from one pull:
shots=3`.

**Fix** (`vajb-orbit/game/weapons.gd`):

- `tick` now arms the battery again on the frame its whole salvo has released, for as long as the
  trigger is held: `if not instant and not bool(row.get(&"edge", false)) and _salvo_spent(id):
  _arm_battery()`. Each barrel therefore fires again as soon as its **own cadence timer** allows —
  one timer per barrel is now what gates the stream, and the salvo's stagger survives across
  salvos because each barrel's timer was set on its own release frame.
- New private `_salvo_spent(weapon) -> bool`: true when no barrel of the battery is still armed. A
  barrel held armed by its own cadence (rule 4's as-built (d)) keeps the salvo unspent, so the
  battery does not re-arm on top of a pending release.
- **Two carve-outs, both measured, both needed to keep shipped behaviour**:
  - a travelling **`edge`** row (the mine, 09 §3.1's "drop", `interval_of` 0.0) keeps one release
    per pull — this is the pre-S4 guard `_fire_projectile` read from the same flag
    (`f3b0d24:vajb-orbit/game/weapons.gd:601-603`). Without the carve-out a held pull would drop a
    mine a frame.
  - a **beam battery** is not re-armed: its barrels open once and keep drawing while the trigger is
    held, so there is no salvo to repeat.
- Comments moved with the code: `tick`'s frame order, `_fire_projectile`'s "the mine's one per
  trigger pull now lives in `tick`'s `edge` read", and `_advance_barrel_timers`' "a barrel's rate
  is its family's and not the pull's" is true again.

**Measurements (the review's probe D re-run on the fixed tree, four stages).** Full log in
`_fix_probes/probe_h4_stream.log.txt`; the probe is re-runnable at
`vajb-orbit/tests/probe_s4h4_stream.gd` (a `--script` `SceneTree` probe, so it is run under a
scratch `XDG_DATA_HOME`, T-93):

```text
[h4d] cannon interval_of=0.600 burst_on=0.350 burst_off=0.250
[h4d] held 3.0 s from one pull: shots=15 releases-at-frame=[1, 6, 14, 609, 614, 619, 1227, 1228, 1839, 1846, 1860, 2452, 2463, 2469]
[h4d] held another 3.0 s after a re-pull: shots=15 releases-at-frame=[3056, 3079, 3091, ...]
[h4d] 25 pulses of 100 ms on / 100 ms off: shots=24 (pack left 146) shots-per-pulse=0.96
[h4d] mine held 3.0 s: shots=1 (ammo left 9)
```

Stage 1 is the finding: 15 = five salvos × three barrels, ~0.6 s apart, against the review's
`3 shots` for the same stage. Stage 4 is the carve-out proven live.

**Regression test** (`tests/test_engine2_weapons.gd`):
`test_a_held_pull_streams_a_salvo_per_barrel_cadence` — three cannons, 60 Hz frames, exactly five
cadence windows, asserting the total **and** that every window carries its own three-barrel salvo
(a silent window is the defect, however the strum offsets fall). Stable across five runs
(`15 shots`, releases inside their windows: `[0,0,0, 36,37,38, 72,73,75, 108,109,112, 145,146,149]`
and four more span sets). `test_a_held_pull_keeps_the_mine_to_one_release` guards the `edge`
carve-out (1 shot for a 3.0 s hold, 2 after a second pull, ammo 10 → 9 → 8). **The stream test
bites**: with the fix stashed it prints the review's own defect line and fails
(`passed=58 failed=2` over the two touched suites).

### F2 (MED) — a refused bulk action leaves a stored fit on a hull that had none — **FIXED**

**Root cause (the review's, confirmed).** The pane's `_seed_fit` ran *before* `_batch_refusal`
*and* before the profile call in all three batch actions, so a refusal wrote the hull's standard
fit into `_fits`; the batch's own rollback restores to the state the batch started from — the
seeded one — and so cannot undo it.

**Fix** (`vajb-orbit/ui/station/outfitting_panel.gd`):

- The **preview runs first and the seed second** in `fit_all_battery`, `swap_all_battery` and
  `remove_all_battery`; `remove_module` (no preview exists there) keeps the seed where the clear
  transaction needs it.
- A seed a refusal made pointless is **dropped again**: `_seed_fit` now answers whether it wrote,
  and the new `_unseed_fit(profile, hull, seeded)` calls `PlayerProfile.clear_fit` when it did, on
  both refusal paths (the preview's and the transaction's). A refused action therefore writes
  nothing at all, which is what rule 7/8's "writing nothing" is measured on.

**The review's alternative cure was measured and is wrong, so it was not taken.** F2 said
"`_seed_fit` is redundant for all four of its callers, because `fit_module_at` / `clear_fit_slot` /
`fit_battery` / `clear_battery` each compose their write from `resolved_fit`". That holds for the
**compose** half and not for the **read** half: the clear transactions read the module they hand
back out of the hull's *stored* fit (`clear_fit_slot`, `autoload/player_profile.gd:911-913` —
deliberately, so a delivered module the account has not got is never banked), and `clear_battery`
lists its cells from `fit_for` (`:989-995`). On a hull that has never been written, a REMOVE of the
modules the strip is showing it therefore answers `false`. Dropping the seed would have turned a
fresh hull's `REMOVE ALL` — and `FIT ALL`'s bank of the displaced delivered module — into a
refusal, which `tests/test_p2b1_outfitting_panel.gd:679-699` pins as working (`a fresh account
stores no fit for the hull` → REMOVE ALL empties the cell, banks the module, keeps the mandatory
set). So: **keep the seed, fix only the refusal path.** Evidence: the whole pre-existing battery and
panel surface stayed green through both scoped runs and both full gates.

**Regression test** (`tests/test_s4_batteries.gd`): `test_a_refused_bulk_action_leaves_no_stored_fit`
— the review's own case, driven through the strip's plate (`_press_bulk`): a fresh Lancer
(`fits()` empty), one laser instance, `SWAP ALL` on its two-barrel battery → catch-all in the
danger colour, `fits()` still empty, bag untouched; then the seed the fix *keeps* is pinned by
`FIT ALL` (`min(owned, cells)` = one cell) leaving a stored fit holding that instance. **It bites**:
with the fix stashed it fails on `and the refusal left the hull holding no stored fit`.

## Documents updated

- `docs/CONTRACTS.md` **§9** — the expected gate figure is now the fixed reading
  (**`passed=524 failed=0`**, twice, by this pass, live pair byte-identical), the growth chain is
  `493 → 508 → 521 → 524` with the two per-suite counts H4 moved, and the "verdict is **blocked**"
  sentence now reads as the cleared record: the review was blocked on F1, **H4's fix clears it**,
  and the fix's own reading is §10's v0.8.2. H3's five-run `521` reading is kept beside it as the
  superseded measurement rather than deleted.
- `docs/CONTRACTS.md` **§10** — new **v0.8.2** entry recording the fix: both findings, the root
  causes, what the fix is (including the two F1 carve-outs), the measurements, the F2 cure's
  departure from the review's stated one **with the reason**, the bite checks, the new tests, the
  probe's location and the scratch-store route. **H3's v0.8.1 entry is untouched** — it stays the
  record of what the review measured.
- **`docs/CONTRACTS.md` §16 is untouched** (rules and as-built bullets alike) — see Follow-ups.

## Evidence

**Gate, twice on the final tree** (`source ~/.profile && godot --headless --path vajb-orbit
res://tests/headless_runner.tscn --quit-after 1200`):

```text
run1 exit=0   [SUMMARY] passed=524 failed=0
run2 exit=0   [SUMMARY] passed=524 failed=0
```

524 PASS lines, **44 suites**, one `SCRIPT ERROR` (the pre-existing L61 line at
`tests/test_weapon_fx_f4.gd:178`), zero `[FAIL]` in either run. Live stores md5-read before the
first run and after the last, and again after the probe:
`profile.cfg 3e6ee8d7e7145c4e37bbd8dc90f62f9b`, `economy_log.txt
eef2929404d1b3b2a4f30565e7b183b2` — the wave-start record, both unchanged.

**The bite checks** (`git stash push -- vajb-orbit/game/weapons.gd
vajb-orbit/ui/station/outfitting_panel.gd`, run the two touched suites, `git stash pop` — restored
and re-verified):

```text
[s4-weapons] held pull: 3 shots = 5 windows x 3 barrels, releases at [0, 0, 1] frames
[FAIL] test_engine2_weapons.gd.test_a_held_pull_streams_a_salvo_per_barrel_cadence
[FAIL] test_s4_batteries.gd.test_a_refused_bulk_action_leaves_no_stored_fit: and the refusal
        left the hull holding no stored fit
[SUMMARY] passed=58 failed=2
```

The F1 line is element-for-element the review's F1 measurement (one 3.0 s pull → 3 shots). The
mine test passes pre-fix as well, as it must: it is a guard for the carve-out this fix introduces,
not a reproducer of the defect.

**The other S4 evidence lines re-run byte-identically** — `mixed fit rows=["battery w_laser [0, 2],
"battery w_cannon [1]"]`, `overload line=11 / 8 PWR — OVER BY 3`, `fixed strip: 7 rows, 253 nodes
(36 per row)`; the strum's own and the held pull's are the two that vary run to run (both quoted in
§9).

**`verify_wave.py verify --baseline s4_start --forbidden vajb-orbit/project.godot
docs/gameplay/18_engine_spec.md`** → **`"problems": []`**. Its `modified` list is exactly the S4
set plus this pass's `docs/CONTRACTS.md`; its `added` list is the three builder reports, the
review, the review's ten probe archives, this pass's `_fix_probes/` pair, `probe_s4h4_stream.gd`
and `tests/test_s4_batteries.gd` (plus the engine-generated `test_s4_batteries.gd.uid` sidecar that
came with H1's suite; H1's `test_s4_batteries.gd` itself is in the `added` list for the same reason
— both landed after the `s4_start` baseline). **No forbidden file appears in either list**, and no
price, damage, cadence, ammo or fit-shape file is in them (`game/station_catalog.gd`,
`game/module_catalog.gd`, `game/player_state.gd`, `game/ship_fit.gd` absent).

**In-scope suites after the fix** (one scoped run over the five suites this wave's files appear in):
`test_s4_batteries` 16/0, `test_engine2_weapons` 44/0, `test_p2b1_outfitting_panel` 11/0,
`test_engine2_wiring` 13/0, `test_p2b_fitting_panel` 27/0 — **`passed=111 failed=0`** (108 pre-H4
tests + the three this pass added).

## Files touched

- `vajb-orbit/game/weapons.gd` — F1: `tick`'s re-arm of a spent, still-held battery, the new
  `_salvo_spent`, the `edge`/beam carve-outs, three comments brought back in line.
- `vajb-orbit/ui/station/outfitting_panel.gd` — F2: preview before seed in the three bulk actions,
  `_seed_fit` answers whether it wrote, new `_unseed_fit`, the refusal paths drop the seed;
  `remove_module` keeps its seed with the same rollback.
- `vajb-orbit/tests/test_engine2_weapons.gd` — the two F1 regression tests (additions only).
- `vajb-orbit/tests/test_s4_batteries.gd` — the F2 regression test, the `FIT_HULL` const and the
  `_fits()` read-back helper (additions only).
- `vajb-orbit/tests/probe_s4h4_stream.gd` — the re-runnable four-stage probe; identical text
  archived at `.agents/gen/slices/S4-weapon-batteries/_fix_probes/probe_h4_stream.gd.txt` with its
  log beside it (both `diff`-verified against the originals).
- `docs/CONTRACTS.md` — §9's figure and blocked sentence, §10's v0.8.2 entry.
- `.agents/gen/slices/S4-weapon-batteries/S4-H4_report.md` — this report.

## Deviations from the brief / the review

1. **F2's cure differs from the review's proposed one** (keep the seed, fix the refusal path, rather
   than dropping the call), because the review's redundancy claim is half-true: the clear
   transactions need a **stored** fit to find the module they hand back, and dropping the seed
   breaks a pinned behaviour (`test_p2b1_outfitting_panel.gd:679`). Measured, argued and recorded in
   §10's v0.8.2. Reversal: drop all four `_seed_fit` calls and let a fresh hull's REMOVE ALL refuse.
2. **One test beyond the two the brief asked for**: the mine's one-release-per-pull. The F1 fix
   introduces the `edge` carve-out, so leaving it unasserted would let a later pass delete the guard
   and put a minefield behind a held trigger. Reversal: drop the test, keep the guard.
3. **A new probe file inside `vajb-orbit/tests/`** (`probe_s4h4_stream.gd`, not a `test_*`, so the
   gate ignores it). Both builders kept their probes there and the orchestrator's close-out can
   re-run it; the source and log are also archived as text in the slice folder, so the evidence does
   not depend on the file surviving. Note it adds a tenth entry to the L125 pile (probes that read a
   surface S4 moved — this one reads the fire seam, which S4 owns).
4. Hard rules honoured: **no shell-based file edits** (every edit went through the file tools), every
   probe ran under a scratch `XDG_DATA_HOME` (`/tmp/h4_scratch/xdg`) with the live stores md5-read
   around it, nothing ran unbounded, and nothing was committed.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| **§16 rule 4's as-built bullet (c) is now stale in its wording, and the re-arm trigger is unpinned.** The fix leaves §16 untouched (the developer session owns it), so the two items below are reported here instead. | docs (bucket 2 — escalates to the developer/designer session) | `docs/CONTRACTS.md` §16 rule 4 |
| (c) says a refused travelling barrel is "**disarmed for that pull** — one `dry_fired` per volley, not one per held frame", with the reversal "leave the barrel armed and retry next frame, as the pre-wave single timer did". Built now: the barrel is disarmed for its **salvo** and re-armed by the next arm, so while the pack stays empty it retries every frame — the bullet's own **reversal**, not its text — while `dry_fired` still reads **once per pull** (`_dry_noted` is reset on the rising edge only; `test_a_dry_barrel_does_not_hold_the_battery_back` still passes). Either the bullet's text moves or the reversal is retired. Reversal for a future pass: nothing in code — this is a wording call. | | `game/weapons.gd` `tick`/`_salvo_spent`, `_dry` |
| Rule 4 pins `fitted()`, the arm, the offsets and the cadence gate, but not **when a held battery re-arms**. This fix chose: *on the frame the whole salvo has released, while the trigger is held, for a travelling non-`edge` battery; never for a beam battery; the mine keeps one release per pull*. Bullets (a), (b), (d) and (e) stay true (and (d)'s arm-retry machinery is now load-bearing rather than dead). The developer session may want that sentence in §16; the reversal is today's pre-fix behaviour (= F1). | | `docs/CONTRACTS.md` §16 rule 4, `game/weapons.gd:600-660` |
| The review's F2 prose ("`_seed_fit` is redundant for all four of its callers") is corrected by measurement in §10's v0.8.2. No ticket needed; flagging it so a later reader does not re-derive it from the review alone. | record | `S4-H3_review.md` F2 vs `docs/CONTRACTS.md` §10 v0.8.2 |
| F3–F9 (LOW) are untouched, as instructed; L123–L129 stay the orchestrator's rows. | — | `_state/LOW_BACKLOG.md` |
