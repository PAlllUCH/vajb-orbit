---
slice: S4
reviewer: S4-H3
verdict: blocked        # F1 is HIGH: a held trigger fires one volley, not a stream of salvos
gate: "493/0 (S3 close-out) → 521/0 (measured five times by this pass; identical)"
---

# S4-H3 review — weapon batteries

Diffed against **`docs/CONTRACTS.md` §16 v0.8.0 rules 1–10, §13, `docs/design/STATION_HUB.md`
§5.1's 2026-09-23 amendment and `docs/gameplay/09_ship_slots_modules.md` §10** — never against
the brief. Every number below was re-measured in this pass; the builder reports were read as
claims and checked, not as evidence. **Nothing was fixed** (L82; `VAJB_WORKER_FILES` =
`vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md`).

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | **HIGH** | `vajb-orbit/game/weapons.gd:607-632`, `:635-637`, `:650-666`, `:691-692` | **A sustained pull fires one salvo and then nothing** for every travelling family. §16 rule 4's own sentence — "three cannons deliver three shots per burst window instead of one **and a sustained pull is a stream of salvos, not one burst**" — and the file's own comment at `:635-637` ("a barrel's rate is its family's and not the pull's") are both false as built. `_arm_battery` is reached only on the pull's rising edge (`:612`) or on a mid-hold group switch (`:627`), and `_armed_weapon` (`:653`) is only cleared by `_disarm_battery` (`:672`, called from `:616` on release and `:651` at the top of an arm). So while the trigger is held `id == _armed_weapon`, no re-arm happens, every `_armed[position]` is already `-1.0` (`:700`), and `_release_battery`'s first guard (`:691-692`) skips every barrel. The per-barrel cadence timers therefore gate nothing after the first volley — and `_barrel_timers` is the whole reason rule 4 replaced the single `_shot_timer` (pre-S4 `_fire_projectile(id, row, edge)` ran on **every** firing frame, gated inside by `_shot_timer`/`_burst_open`: `git show f3b0d24:vajb-orbit/game/weapons.gd` → `:527`, `:601-617`). Measured, probe D: one pull held 3.0 s → **3 shots, releases at frames 1/10/24 ms, then 2 976 frames with zero**; a release + re-pull → 3 more; 25 × (100 ms on / 100 ms off) → **23 shots**, i.e. ~0.9 per pulse, because a re-pull can only release barrels whose 0.6 s timer has since expired. §16 rule 4's as-built bullet (d) ("a closed burst window or an unready cadence timer keeps the barrel armed") only ever arises on a frame longer than `burst_on` (0.35 s), so the arm-retry machinery is otherwise dead. | S4-H4 |
| F2 | MED | `vajb-orbit/ui/station/outfitting_panel.gd:1089` (`fit_all_battery`), `:1112` (`swap_all_battery`), `:1134` (`remove_all_battery`); `vajb-orbit/autoload/player_profile.gd:947-975`, `:983-1010` | **A refused bulk action leaves a stored fit on a hull that had none.** The pane's `_seed_fit` (`:1242`) runs *before* `_batch_refusal` (`:1164`) and before the profile call, so a refusal writes the hull's standard fit into `_fits` and the batch's own rollback (which restores to the seeded state, correctly) cannot undo it. Measured, probe C: fresh `ship_fighter`, `fits()` = `[]`, one laser instance in the bag, `SWAP ALL` on its 2-barrel battery → footer `REFUSED · FIT ILLEGAL` **and `fits()` = `["ship_fighter"]`**. This is the same class H1 deviation 6 was written to avoid ("a hull that held no stored fit is returned to that state … `fit_for` hides the difference but `fits()` and the save file would not") — one layer out, on the refusal path the pin's §16 rules 7/8 describe as "writing nothing". No gameplay effect (`resolved_fit` already answered `standard_fit`), so it is not a HIGH; the cure is small: `_seed_fit` is **redundant for all four of its callers**, because `fit_module_at` / `clear_fit_slot` / `fit_battery` / `clear_battery` each compose their write from `resolved_fit` and so already carry 09 §7's mandatory set. Drop the call, or move it below the refusal preview. No test asserts the seeding's persistence (`grep -n "_seed_fit" vajb-orbit/tests/` → comments only). | S4-H4 |
| F3 | LOW | `docs/CONTRACTS.md` §16 rule 6's as-built bullet; `vajb-orbit/game/weapons.gd:739-750` (`_fire_beam_battery`) | **Rule 6's "a 1.200 pool pays two barrels" is a float knife-edge.** The draw is `row.draw * delta` = `6.0 * 0.1` = `0.60000000000000009`, so a pool set to exactly `1.200` pays **one** barrel (`1.200 - 0.60000000000000009` = `0.5999999999999999` < the next draw) and reads the rest dry once; only a pool set to `cost * 2.0` — the same float the comparison uses, which is what `test_engine2_weapons.gd:437` does — pays two. Measured, probe C: pool `1.200000` (= `cost * 2.0`) → spent `1.200000`, dry reads 1; pool exactly `1.200` → spent `0.600000`, dry reads 1. The observable (one dry read per pull, `_dry_noted`) is identical either way, so this is a doc-precision row: name the test's own `cost * 2.0` form in §16 rule 6, or let the sentence say "a pool that covers two draws". | → L123 |
| F4 | LOW | `vajb-orbit/ui/station/outfitting_panel.gd:1295` (`_base_id`) with `:823` (`_battery_groups`), `:1301` (`_module_name`); `vajb-orbit/autoload/player_profile.gd:362-374` (`base_module_id`) | **A fitted cell whose bag record is gone is grouped by its instance id**, so the strip draws one row per barrel reading `1× MOD_0021 · W1 · OWNED ×0` instead of one battery — measured, probe C, with `_modules` emptied under three fitted instances. `base_module_id` returns the entry unchanged when the record is missing, which is deliberate for a base-keyed fit, but an **instance** id then cannot resolve to its base. Unreachable in production today (a fitted instance keeps its record at `count` 0, and `instances_of` is the only lister), so it is a robustness row, not a live defect: `take_module` on a fitted instance is the one call that would open it. | → L124 |
| F5 | LOW | `vajb-orbit/tests/probe_p2b1_panel_fit.gd:209-219, 244` plus the eight others H1 listed (`probe_r1_p2b1_edge{,2,3}.gd`, `probe_r1_p2b1_fit.gd`, `probe_r1_p2b1_layout.gd`, `probe_r1_p2b1_persist.gd`, `probe_r1_p2b1_review.gd`, `probe_w5_layout.gd`) | **Nine historical probes read the pre-S4 strip shape and now fail silently.** Measured on `probe_p2b1_panel_fit.tscn` (scratch `XDG_DATA_HOME`): every strip child is a `VBoxContainer` but the probe casts `as HBoxContainer` (`:209`, `:216`, `:244`), so the reads return `null`/`[]` — `[probe] FITTED WEAPONS (start): []` on a hull with a fitted laser — and the probe additionally dies on the retired MODULES surface (`%ModuleRows` not found, `module_row_ids`/`buy_module`/`module_action` all `Nonexistent function`; S3's retirement, not S4's). They are outside the gate (`test_*` only), so nothing is red; H1's follow-up is confirmed by measurement, not by reading. | → L125 |
| F6 | LOW | `.agents/gen/_state/LOW_BACKLOG.md:201` (L78), `:145` (L61); `S4-H1_report.md:138`, `S4-H2_report.md:133-139` | **Three citation drifts.** (a) L78's `Where` column points at `outfitting_panel.gd:873-882` (`module_action`), which does not exist in the file (`grep -n "func module_action"` → nothing; the file is 1353 lines and `:873` is inside `_bag_count`), and its MODULES-row half retired in S3 — only the strip's REMOVE-reachability half survives, now through the expander's single-cell lines (verified by this pass's expander probe: `W1/W2/W3 LASER MKII`, each with an enabled REMOVE). (b) L61's line reference has shifted `:175-176` → **`:178`** (`guns.call(&"_hide_beam")`, the freed object is `guns`; the `_clear()` that freed it is at `:470-480`). (c) H2's report says the freed object is the `hull`; the runtime line is the `guns` call, so L61's diagnosis stays the correct one. | → L126 |
| F7 | LOW | `vajb-orbit/tests/test_engine2_weapons.gd:503-537` | **The strum test is a bound, not a spread.** H2's own follow-up, confirmed by reading the assertion: `fired_at[0] == 1` and `fired_at[2] <= 40` pass on `[1, 1, 1]`, so nothing pins that a spread exists. Intended (the pin's reversal is strum 0), but a future reviewer re-measuring "the strum" has no in-tree assertion to lean on — this pass's four runs read spreads of 5, 19, 27 and 27 ms, and H2's five quoted spans are 14, 11, 37, 25 and 9 ms. Adding one assertion ("over N pulls at least two distinct release frames") would make the mechanism, not just its ceiling, pinned. | → L127 |
| F8 | LOW | `vajb-orbit/tests/test_s4_batteries.gd:566-590` | **Recorded, not a defect:** the pin (§16 rule 9) says the mandatory wording is carried "for the set's completeness" and "**no test may assert it through a battery**". Verified: no test renders it through a battery — the S4 assertion is a constant byte-equality against `fitting_panel.gd`'s own (`:573-575`), and the only *rendered* assertions live in `test_p2b_fitting_panel.gd` (`:854, 882, 1019`), which drives the FITTING pane. The letter holds; the row exists so the next reader does not re-litigate the constant's presence in the suite. | → L128 |
| F9 | LOW | `vajb-orbit/game/game.gd:1358-1359`; `vajb-orbit/game/weapons.gd:441-443` (`GROUPS_MAX`); `docs/CONTRACTS.md` §16 rule 2 | **The two index spaces, recorded so they stay findable.** (a) Six families exist and `weapon_1..5` offers five keys, so a fit of six distinct families leaves the sixth battery unselectable — pre-existing, and the code already says "reported" (`weapons.gd:404-406`). (b) The HUD's W-slot buttons map a **cell** index to a group (`select_group(slot + 1)`), so on a hull whose W row holds fewer batteries than cells a trailing slot selects nothing and a battery need not sit at its own cell's slot — measured in the component (3 lasers → group 1 = `laser`, groups 2 and 3 = `&""`), and §16 rule 2 already records it as measured-not-changed. Both are pinned as *not* this wave's to move; the row keeps them in the backlog rather than in a report. | → L129 |

## What was verified (and how)

Every line below is this pass's own measurement; the probe sources and their full logs are
archived as text in `.agents/gen/slices/S4-weapon-batteries/_review_probes/` (none is a
`res://` scene, so none can boot the profile by accident — the L121 convention S3 set).

**Gate — run five times, identical.** `source ~/.profile && godot --headless --path vajb-orbit
res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=521 failed=0` (two plain
runs, one per-suite-counting run, and both `verify_wave.py --tests` runs), **521 over 44 suites**,
exit 0.
The pre-existing `SCRIPT ERROR … previously freed instance` at `tests/test_weapon_fx_f4.gd:178`
is the only error line and is L61's (see F6b). Per-suite counts that S4 moved:
`test_s4_batteries 15` (new), `test_engine2_weapons 42` (29 → 42), `test_p2b1_outfitting_panel 11`
(unchanged, its per-cell tests re-read as battery rows), `test_engine2_wiring 13` (unchanged, its
`fitted()` assertion rewritten per-barrel with a bite check). Nothing else moved: the other 40
suites are unchanged in count (`test_p2b_fitting_panel 27`, `test_s3_*` 25, and the rest).

**The builders' probes re-run byte-identically.** The S4 evidence is printed by the suites
themselves, so a re-run is the re-run: `[s4-batteries] mixed fit rows=["battery w_laser [0, 2]",
"battery w_cannon [1]"]` (byte-identical to H1's), `[s4-batteries] overload line=11 / 8 PWR — OVER
BY 3` (byte-identical, Vanguard railgun battery), `[s4-batteries] fixed strip: 7 rows, 253 nodes
(36 per row)` (byte-identical). The one line that must vary is the volley's strum
(`[s4-weapons] volley: releases at […]; ceiling 40, pack 30 -> 27`) — the offsets are drawn from
`_strum_rng` per pull; measured spans `[1, 17, 17]`, `[1, 28, 28]`, `[1, 4, 6]` ms in this pass
against H2's `[1, 9, 15]` / `[1, 3, 12]`, all inside the pinned 40 ms ceiling, all 3 shots, all
27 rounds left.

**§16 rule 1 — `fitted()` is per barrel, duplicates kept.** Probe A: `[w_laser, w_laser, w_laser]`
→ `fitted() = [laser, laser, laser]` (3 entries); `[cannon, w_laser, cannon]` → `[cannon, laser,
cannon]` (fit order); `[w_mining, w_laser, w_nothing, w_laser]` → `[laser, laser]` (the tool and
the typo still drop). Return type is `Array[StringName]`, which §16's prose sanctions.

**§16 rule 2 — groups address batteries.** `[w_laser, w_cannon, w_laser, cannon, w_rocket]` →
`battery_ids() = [laser, cannon, rocket]` (first-barrel order, never catalogue order); 3 lasers →
group 1 `laser`, group 2 `&""`, group 3 `&""`, `dry_reason` `none`; `[w_cannon, w_laser, w_cannon]`
→ group 2 `laser`.

**§16 rule 3 — `battery()` answers barrel positions, and the divergence is real.**
`[w_laser, w_mining, w_cannon, w_laser]` → `battery(&"w_laser") = [0, 2]`, `battery(&"laser") =
[0, 2]`, `battery(&"w_cannon") = [1]`, `battery(&"w_mining") = []`, `battery(&"w_nothing") = []`.
The pin's own case, end to end: `ShipFit.fitted_ids({weapons: ["w_mining", "w_laser", ""]}) =
[w_mining, w_laser]` (what `player_ship.gd:_bind_weapons` hands over) → the component reads
`fitted() = [laser]` and `battery(&"w_laser") = [0]` **while that laser is W-cell index 1**. The
strip never asks the component: its labels come from `_weapon_cells` (`outfitting_panel.gd:1273`),
measured as `W1·W3` for cells `[0, 2]`.

**§16 rules 7–8 — the batch, byte-compared.** Probe B (clean isolation, no helper writes in
between): `ship_corvette`, no stored fit, 4 railgun instances, `fit_battery(corvette, w_railgun,
[0,1,2,3])` → `false` with **3 `FIT_MODULE` log lines committed** (so writes landed before the
refusal) and `fits()` `[] → []` — the `clear_fit` branch of `_restore_fit_and_bag` returns the
hull to the absent state; all four instances back at `count` 1. Probe A: Vanguard + standard fit +
3 railgun instances → `fit_battery` `false`, **2 log lines committed**, `fit_for` and `modules()`
**byte-identical** to their `var_to_str` snapshots, no instance stranded below `count` 1. Guards:
`clear_battery` for a base the hull does not hold → `false`, fit byte-identical; the Vanguard's
`_legality` sweep shows cells 0/1 write and cell 2 refuses, which is why the rollback is
exercised rather than assumed.

**§16 rule 4 — the volley's arithmetic (the stream is F1).** Probe C: 3 cannons, pack 30, one
pull → **3 shots, pack 27** (one round per barrel out of the family's one pack), each shot
carrying `shot_damage(cannon)` = **27.0**, releases inside the ceiling with a measured spread of
5–27 ms and the lead on the pull's own frame. Per-barrel cadence is real across pulls (probe D:
23 shots over 25 × 200 ms pulses) but never produces a stream within one hold (F1). Dry barrel:
pack of 1 with three cannons → 1 shot and **one** `dry_fired` for the whole pull (`_dry_noted`
reset on the edge, `_dry` guarded), nothing else spawned.

**§16 rule 6 — the energy families.** Probe C: 3 lasers at `delta` 0.1 → **1.800 Energy** spent
(one barrel `0.600`) and **9.000** damage delivered in **one** `_deliver` (`hits = 1`), so the
shaft and the contact read stay one per frame while the damage and the chip work sum over the
paid barrels. A pool that cannot pay one barrel leaves the earlier ones drawing and reads dry
once (measured; see F3 for the float nuance).

**§16 rule 9 — the refusal copy renders, with the pin's own numbers.**
`REFUSAL_OVERLOAD`/`MANDATORY`/`FIT_ILLEGAL` measured **byte-equal** to `fitting_panel.gd:147-149`.
`13 / 11 PWR — OVER BY 2` — the doc's own literal — **renders**, and it renders through a battery:
probe C's hull/power sweep over all nine hulls shows `13/11/2` is reachable on **one** hull
(`ship_gunship`: `12/11/1, 13/11/2, 14/11/3, 15/11/4`; the Vanguard can only reach `9/8/1 …
12/8/4`, which is why H1 measured `11 / 8 PWR — OVER BY 3`), so a Bulwark with 3 railguns + 2
rockets pressed on the railgun battery's `FIT ALL` renders `status='13 / 11 PWR — OVER BY 2'
danger=true` with the fit `["w_railgun"×3, "w_rocket"×2]` and the bag (12/8) untouched.
`REFUSED · FIT ILLEGAL` renders on a Vanguard with 3 laser barrels and 2 bag instances via
`SWAP ALL`, fit and bag unchanged. `FitData.MANDATORY_SLOT_KEYS == [&"engines", &"power"]`
measured; no test asserts the mandatory wording through a battery (F8).

**§16 rule 10 — the fixed node set, and the strip's own readings.** 7 pre-built rows
(`_max_weapon_cells()` from `ShipFit`, measured 7 — the widest hull's W row), **253 nodes, 36 per
row**, unchanged across a re-grouping write and (H1's test) a hull switch; every row rewritten by
text/visibility/`disabled`. Rows measured on the Bulwark: `3× RAILGUN · W1·W2·W3 · OWNED ×12`,
`2× ROCKET POD · W4·W5 · OWNED ×8`; on the Vanguard with W2 empty: `2× LASER MKII · W1·W3 · OWNED
×6` then `W2 — EMPTY`. Disabled states (§5.1): a battery with **0** bag instances →
`FitAll disabled=true`, `SwapAll disabled=true`, `RemoveAll disabled=false` (never), and the row
still reads `OWNED ×0`; `OWNED ×<n>` is `instances_of(base_id).size()`, i.e. the number of cells
one batch can pair, not a sum of unit counts. Focus order measured
`["Expander", "Text", "FitAll", "RemoveAll", "SwapAll"]`; empty lines carry every control node
(the fixed set) but **all hidden and disabled**, with their `Cells` box closed, so they are
read-only and unfocusable. **AC3 / L78's surviving half:** on a full 3-barrel battery the expander
reveals `W1/W2/W3 LASER MKII`, each with a **visible, enabled** REMOVE; pressing the **third** one
emptied exactly W3 (`["w_laser", "w_laser", ""]`, one instance returned, `status='REMOVED · LASER
MKII · BACK IN INVENTORY'`); on a gapped battery (`[0, 2]`) the lines read `W1`/`W3` and pressing
the first emptied W1 while W3 stayed — so removal is reachable in every state and each line is
bound to its own cell, and the expander survives the write it makes. 7 lines are pre-built per
row, of which only the battery's own are shown.

**No frozen value moved.** `verify_wave.py verify --baseline s4_start --forbidden
vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests` → **`"problems": []`, exit 0**,
run twice (once before this review's own writes and once after them). Its `modified` list is
exactly **six** code/test files (all under the builders' sets: `autoload/player_profile.gd`,
`game/weapons.gd`, `tests/test_engine2_weapons.gd`, `tests/test_engine2_wiring.gd`,
`tests/test_p2b1_outfitting_panel.gd`, `ui/station/outfitting_panel.gd`), the three `docs/` files
the developer session amended (`CONTRACTS.md`, `STATION_HUB.md`, `09_ship_slots_modules.md`), the
four `.agents/gen/` slice/state files (`S4_BRIEF.md`, `S4_prompts.md`, `SLICE.md`, `WAVEBOARD.md`)
and this pass's own `CONTRACTS.md`/`LOW_BACKLOG.md` writes; its `added` list is the three builder
reports, this review and the five archived probes. No forbidden file (frozen `project.godot`, the
owner-locked engine spec) appears in either list. No price, damage, cadence or ammo value
moved: `game/station_catalog.gd`, `game/module_catalog.gd`, `game/player_state.gd` and
`game/ship_fit.gd` are absent from every S4 diff, `game/weapons.gd`'s 27 deletions are the single
`_shot_timer` being replaced (its `FAMILIES` table is untouched — the only added number is
`BATTERY_STRUM_MS := 40`), `autoload/player_profile.gd` is **104 insertions and 0 deletions**, and
`outfitting_panel.gd`'s 66 deletions are all the old per-cell strip code. No fit shape change: the
written fit is still `_normalise_fit`'s array shape, and every strip write goes through
`fit_battery`/`clear_battery`/`clear_fit_slot`.

**The scratch-store rule (T-93) — honoured, with a third route.** No probe in this pass used the
live store. `headless_runner.tscn` sandboxes itself (`_seed_scratch_store`, `:47-66`) for the gate;
my **five** probes ran under a **scratch `XDG_DATA_HOME`** (`/tmp/h3_scratch/xdg`, plus `/tmp/h3e/xdg`), so `user://`
resolves outside the account by construction — a `--script` `SceneTree` probe *does* boot the
`PlayerProfile` autoload (measured: `profile=present`, fresh defaults), which is why the wrapper
is not optional — and two of them additionally repointed `save_path`/`EconomyLog.log_path` at
scratch files. The historical `probe_p2b1_panel_fit.tscn` was likewise run under the scratch
`XDG_DATA_HOME`. The live stores were md5-read **before and after every probe and every gate run**:
`profile.cfg` **`3e6ee8d7e7145c4e37bbd8dc90f62f9b`** and `economy_log.txt`
**`eef2929404d1b3b2a4f30565e7b183b2`**, both the wave-start record and both unchanged at the end
of this pass.

## Verdict

**Blocked — F1 is HIGH.** The wave's headline works (one trigger fires the whole battery as a
staggered salvo, one round per barrel, per-barrel damage, all inside 40 ms) and rules 1–3, 5,
6 and 9–10 hold as built; the FITTING pane, the fit shape, the prices and the stats did not move.
What does not hold is rule 4's own second half: a held trigger fires **one** salvo and then goes
silent for every travelling family, which both contradicts the pin and removes a shipped
behaviour (the pre-S4 stream). F2 is a MED on the refusal path and rides the same fixer pass.
Tiering is per WAVEBOARD: H4 fixes F1 and F2, H3 re-verifies, F3–F9 become LOW rows (L123–L129)
and are not fixed here.
