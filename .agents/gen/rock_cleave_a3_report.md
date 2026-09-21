# A3 — rock cleave: the fixer pass

Wave `rock_cleave` (brief `.agents/gen/rock_cleave_wave_task.md`; the law read in the order
the brief fixes: `AGENTS.md`, `docs/CONTRACTS.md` §5/§9, `18_engine_spec.md` §6/§13,
`02_minerals.md` §5/§8, `FX_SPEC.md` §1.4/§7.3, the brief, `WAVEBOARD.md`). Worker **A3**,
fixer. Date 2026-09-22, host Linux (`/home/kamil-paluszkiewicz/VajbOrbit`), engine
`4.7.2.stable.official.ed1daf0bf`.

Authority for every finding: `.agents/gen/rock_cleave_a2_report.md` (read in full, 353
lines). A1's work under it: `.agents/gen/rock_cleave_a1_report.md`.

---

## 0. Verdict

**One finding was assigned, it was the wave's only MED, and it is fixed. Nothing else was
touched.**

| A2's tier | Finding | A3's action |
|---|---|---|
| HIGH | none — A2 left **0 HIGH** | nothing to fix |
| **MED** | `docs/CONTRACTS.md` §5's cleaving sentence still states the retired rows and the retired cone (A2 §6) | **fixed**: §5's second sentence rewritten to the shipped behaviour, plus the `v1.4` §10 changelog entry A2 authored |
| LOW | L72–L75 | **not touched** (not assigned; they ride to `LOW_BACKLOG.md` as A2 left them) |

The MED's own file is the whole of my declared set, and it is the only file outside
`.agents/` I wrote. `git status --porcelain` after the last measurement: the six files A1
modified, the four A1/A2 added under `tests/` and `tools/`, `docs/CONTRACTS.md` (mine,
`+40/−7`), and my `.agents/` evidence. No `vajb-orbit/` file, no asset, no theme, no
`project.godot`, no `addons/**`, no other doc.

```bash
$ git diff --stat -- docs/CONTRACTS.md
 docs/CONTRACTS.md | 47 ++++++++++++++++++++++++++++++++++++++++++++-------
 1 file changed, 40 insertions(+), 7 deletions(-)
```

### The one instruction conflict, resolved explicitly

My dispatch prompt carries the generic clause *"Do not touch assets, the theme,
`project.godot`, `addons` or docs"* (the identical clause is in A1's and A2's prompts —
`.agents/gen/rock_cleave_wave_prompts.md:13`), while the orchestrator's machine-enforced
declaration for this pass is

```text
VAJB_WORKER_FILES=docs/CONTRACTS.md
```

and `.crush/hooks/enforce_worker_files.py` denies every `edit`/`write`/`multiedit` outside
that set (it denied my first write, to an `.agents/` script, on the Windows-only prefix
bug A2 filed as **L75**). The per-finding set is the specific instruction and it names the
MED's own file; A2 §6 anticipated exactly this shape ("`docs/CONTRACTS.md` as A3's whole
`VAJB_WORKER_FILES` is the other valid shape") and CONTRACTS' own preamble assigns the
doc's review-wave amendments to the fixer route. So the "no docs" clause is the brief's
boilerplate for a *code* fixer, and the assignment wins. I resolved it by fixing only the
MED, in only that file.

---

## 1. The MED, before and after, with A2's own command

A2's reproducing command (§6), run verbatim:

```bash
git grep -n "±15° cone" docs/CONTRACTS.md
```

| | Output | exit |
|---|---|---|
| **before** (HEAD `8d189bf`, md5 `a0332d330ecf23a2257411971ad46652`) | `docs/CONTRACTS.md:267:`× 1.2` inside a ±15° cone, fragment mineral **and tier** inherited from the parent` | 0 |
| **after** (working tree, md5 `020a23eb49759748a7cc017b8d651429`) | *(no match)* | 1 |

Widened to the retired rows, same shape:

```bash
git grep -n "L (2,3)\|M (2,2)" docs/CONTRACTS.md
```

| | Output | exit |
|---|---|---|
| **before** | `docs/CONTRACTS.md:266:`FRAGMENT_SPLIT` L (2,3) → M, M (2,2) → S, `PICKUP_BURST` (1,2) for an S, ejection` | 0 |
| **after** | *(no match)* | 1 |

Counts of the three retired statements and of the six facts the paragraph now has to carry
(the same nine lines in both logs):

| grep -cF | before | after |
|---|---|---|
| `L (2,3)` | 1 | **0** |
| `M (2,2)` | 1 | **0** |
| `±15° cone` | 1 | **0** |
| `FRAGMENT_EJECT_CONE_DEG` | 0 | **1** |
| `MIN_SHOCKWAVE_IMPULSE` | 0 | **2** |
| `sfx_impact_rock` | 0 | **2** |
| `clamp(1.2 × diameter, 96, 224)` | 0 | **2** |
| `uniform 2–5` | 0 | **1** |
| `360` | 0 | **2** |

The two retired numbers do still appear **once**, as the reversal path, which is what a
contract owes its readers: `docs/CONTRACTS.md:268` — `the reversals are those two
constants themselves: restore the fixed `(2,3)`/`(2,2)` rows, or set the cone to `15.0``.
They are named as the way back, never as the behaviour. The guard (§2) asserts that: every
`(2,3)`/`(2,2)` mention must sit on a line carrying `restore`.

Raw logs, both complete: `.agents/gen/rock_cleave_a3_med_before.txt`,
`.agents/gen/rock_cleave_a3_med_after.txt`. The full delta:
`.agents/gen/rock_cleave_a3_diff.txt`.

### The new §5 text, as it now stands (docs/CONTRACTS.md:265-280)

```text
class is a look *and* the cleaving class: `FRAGMENT_SPLIT` is a **uniform 2–5 on both
cleaving tiers** (`(2,5)` L → M and M → S), `PICKUP_BURST` `(1,2)` for an S, and
ejection `× 1.2` in a **uniform 360°** direction (`FRAGMENT_EJECT_CONE_DEG` 360.0 —
the reversals are those two constants themselves: restore the fixed `(2,3)`/`(2,2)`
rows, or set the cone to `15.0`), fragment mineral **and tier** inherited from the
parent with the yield re-rolled through the 02 §5 path (the §13 row and §12 item 12
are law; §6's "re-rolled tier" parenthetical is not representable, since a mineral
fixes its tier). Every depletion — a cleave, a Small's burst or a yield-0 crack —
also reads as the rock's **death**, not an ore event: FX_SPEC §1.4's explosion at the
rock's own centre scaled `clamp(1.2 × diameter, 96, 224) u` through
`Projectile.spawn_rock_break` (§7.3's one-shot wiring), S4's rock cue through the
four-take `sfx_impact_rock` row `CUE_POOLS` now carries, and
`Impact.apply_shockwave` on the bodies inside `I(d) ≥ MIN_SHOCKWAVE_IMPULSE` (about
63 u — §13's own floor, so no radius is invented here). `AsteroidField` does the
spawning on `cracked`, so fragments are field members from birth and count toward
`rocks()`/`is_depleted()`.
```

A2's authored replacement was applied as written; five points where I was more specific
than A2's draft, each traceable to A2's own measurements or to the shipped code, none
inventing a number:

1. **The cue is named.** A2's draft said "S4's rock cue through the new four-take
   `CUE_POOLS` row"; the paragraph names the row, `sfx_impact_rock` — the interface fact
   a contract exists to pin, and what ties the doc to
   `autoload/audio_manager.gd:134`'s row (A2 §3 measured the row's four takes).
2. **The cone's shipped value is stated.** A2's draft named `FRAGMENT_EJECT_CONE_DEG` and
   its restore values; the paragraph states `360.0` too, because the value is the
   contract. `15.0` remains as the cone's reversal.
3. **The retired cone is not restated as a glyph.** The retired statement is described by
   the constant that restores it (`15.0`), so `±15° cone` no longer appears anywhere in
   the file — which is what lets the guard assert the retired claim is gone rather than
   merely re-worded.
4. **The explosion's owner and the blast's floor are named** —
   `Projectile.spawn_rock_break` (§7.3's one-shot wiring) and "about 63 u — §13's own
   floor, so no radius is invented here", both A2 §3's own numbers (`reach=63.2376`,
   `I(d) ≥ MIN_SHOCKWAVE_IMPULSE`).
5. **"not an ore event"** is A2 §6's own phrasing of the ruling's intent, and it is what
   makes the yield-0 clause read as deliberate rather than as a leak.

The `v1.4` §10 entry is appended after the P2-A entry (the changelog's own order — `v0.2`
already sits after `v1.3`), and it records the wave's gate as measured (`378`, pre-wave
`372`, the growth A1's), the owner tick still owed at §6/§13/**§15**, and the guard.

---

## 2. The guard that stands in for a test, and why the gate cannot grow here

My instructions say *"add or update a test per fix"* and *"grow its count"*. **This pass
cannot do that, and I did not fake it.** The gate discovers `vajb-orbit/tests/test_*.gd`
(`tests/headless_runner.gd`), my declared set is `docs/CONTRACTS.md` alone, and the hook
denies any write under `vajb-orbit/tests/` — so a docs-only fix has no gate surface. The
count does not move: **378 before, 378 after**, and §3 says why that is the correct
outcome for this finding, not a shortfall.

What I did instead is the honest equivalent: a re-runnable guard that turns the fix into a
red→green check and pins the doc to the code, so the same drift cannot come back silently.

```bash
bash .agents/gen/rock_cleave_a3_check.sh
```

| | Result |
|---|---|
| **before** (pre-fix tree) | `== FAIL: 11 checks, 8 failures ==`, exit 1 — `.agents/gen/rock_cleave_a3_check_before.txt` |
| **after** (final tree) | `== PASS: 12 checks, 0 failures ==`, exit 0 — `.agents/gen/rock_cleave_a3_check_after.txt` |

It is 12 assertions in seven groups, and every value it compares is read out of the file
that owns it rather than typed twice:

1. the three retired statements are absent from the doc (A2's command, widened);
2. any `(2,3)`/`(2,2)` mention sits on a line carrying `restore` (the reversal only);
3. `FRAGMENT_SPLIT` is one row on both cleaving tiers and the doc names that pair —
   `asteroid.gd:107-111`;
4. the doc's `× 1.2` is `FRAGMENT_EJECT_MULT` and its `360` is
   `FRAGMENT_EJECT_CONE_DEG` — `asteroid.gd:116,124`;
5. the doc's `(1,2)` is `PICKUP_BURST` — `asteroid.gd:112`;
6. the doc's `clamp(1.2 × diameter, 96, 224)` equals
   `ROCK_BREAK_WORLD_SCALE`/`_MIN`/`_MAX` — `projectile.gd:428-430`;
7. the doc's four-take `sfx_impact_rock` row is the row `audio_manager.gd:134` carries
   (four takes counted), and the doc's `Impact.apply_shockwave` +
   `MIN_SHOCKWAVE_IMPULSE` are the helper `projectile.gd:416` declares and
   `asteroid_field.gd:303` calls.

Check 4's second half passed **before** the fix as well (the doc already said `× 1.2`); the
other eight failures were all the doc's. The guard lives under `.agents/gen/` because that
is the only path this pass may write besides the doc itself — A2 could keep its tooling in
`vajb-orbit/tools/` because that was in A2's set.

**The one-line follow-up, if the orchestrator wants the gate itself to carry it:**
`vajb-orbit/tests/test_contracts_cleaving.gd` reading the same seven facts out of
`docs/CONTRACTS.md` and the owners, dispatched with a file set that includes
`vajb-orbit/tests/`. I did not write it: `tests/` is outside my declared set, and writing
it through a path the hook does not match would be circumventing the guard rather than
working inside it.

---

## 3. The gate, before and after, measured by me

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
```

| Run | Summary | Exit | `[FAIL]` | Log |
|---|---|---|---|---|
| **before** the fix | **`[SUMMARY] passed=378 failed=0`** | 0 | 0 | `.agents/gen/rock_cleave_a3_gate_before.txt` |
| **after** the fix | **`[SUMMARY] passed=378 failed=0`** | 0 | 0 | `.agents/gen/rock_cleave_a3_gate_after.txt` |

**The two logs are byte-identical** (`md5 4af158777350b2c9a22ff589b9eb6288`, `diff -q`
silent), which is the strongest available statement that a docs-only fix moved nothing.
A2's `378` and its `+6` over the pre-wave `372` are reproduced, not carried over, and A2's
four known non-`[PASS]` lines are at the same positions (`:6` the `weapons.gd:1330`
detached-bow error, `:228` the `EconomyLog` fixture warning, `:416` the
`tests/test_weapon_fx_f4.gd:176` `SCRIPT ERROR` of L61, `:427` the leak counter).

Per-suite tally of the after run (identical in the before run, since the logs match):

```text
combat_repair_c5 7 · engine2_cleaving 15 · engine2_damage 20 · engine2_dock 2 ·
engine2_fixes 17 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 · engine2_pools 16 ·
engine2_weapons 29 · engine2_wiring 13 · engine_c3_flight_decay 3 · flight_beam_g2 5 ·
flight_feel_g1 12 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 ·
p1_profile 9 · p1_refinery 6 · p1_repairs 5 · p2a_launch_fit 12 · p2a_lint_shadow 2 ·
p2a_profile_fits 11 · p2a_ship_roster 4 · ship_grids 27 · slice2_5_feel 17 ·
ui_slot_layout 12 · weapon_fx_f1 22 · weapon_fx_f2 13 · weapon_fx_f4 6   = 378
```

`engine2_cleaving 15` confirms A2's `9 → 15`; **no other suite's count moved**, which is
the brief's §4 test contract honoured by A1 and untouched by me.

---

## 4. Scope, verified

- **Written outside `.agents/`:** `docs/CONTRACTS.md` only — `+40/−7`, md5
  `a0332d330ecf23a2257411971ad46652` → `020a23eb49759748a7cc017b8d651429`. `git status
  --porcelain` names no other file of mine, and `git diff --stat -- vajb-orbit/` is A1's
  six files (`audio_manager.gd +20`, `asteroid.gd +38`, `asteroid_field.gd +128`,
  `projectile.gd +39`, `test_engine2_cleaving.gd`, `test_weapon_fx_f2.gd`) exactly as A2
  measured them.
- **Not touched:** `vajb-orbit/assets/**`, the theme, `project.godot`, `addons/**`, every
  other doc (in particular `18_engine_spec.md`, owner-locked), and A2's four LOWs
  (L72–L75 stay as A2 filed them).
- **The before/after A/B left the tree where it found it:** the pre-fix state was produced
  by `git checkout -- docs/CONTRACTS.md`, whose md5 reproduced the pre-fix figure recorded
  before any edit, and the fixed file was restored byte-identically from a copy
  (`md5 020a23eb…` verified after every subsequent reflow). No `git stash` was used, so no
  other wave file was ever at risk.
- **Evidence files this pass produced** (all under `.agents/`, hook-exempt):

```text
.agents/gen/rock_cleave_a3_report.md          this report
.agents/gen/rock_cleave_a3_check.sh           the re-runnable guard (12 checks)
.agents/gen/rock_cleave_a3_check_before.txt   the guard, red on the pre-fix tree (8 failures)
.agents/gen/rock_cleave_a3_check_after.txt    the guard, green on the final tree
.agents/gen/rock_cleave_a3_med_before.txt     A2's command + the paragraph, pre-fix
.agents/gen/rock_cleave_a3_med_after.txt      A2's command + the paragraph, post-fix
.agents/gen/rock_cleave_a3_gate_before.txt    the gate before
.agents/gen/rock_cleave_a3_gate_after.txt     the gate after (byte-identical)
.agents/gen/rock_cleave_a3_diff.txt           the whole docs/CONTRACTS.md delta
```

---

## 5. What I deliberately did not fix, and what the close-out still owes

- **§9's `Expected:` line (`docs/CONTRACTS.md:743`) still reads `passed=294`.** The measured
  gate is `378` (A2's `372` pre-wave), so that line has been stale since the P2-A and
  rock-cleave waves. **A2 did not tier it, and its replacement text for this MED does not
  name it, so it is outside the finding I was assigned** — I left it rather than widen a
  one-pass fixer into an unassigned doc rewrite. It is a one-line close-out edit for the
  orchestrator (the convention the v1.2/v1.3 entries followed: "the count to read is the
  measured one with zero failures, never a stale total"), and my `v1.4` entry records the
  measured `378`/`372` in the meantime.
- **The owner tick is unchanged and still owed** — `18_engine_spec.md` §6 (lines 283-290),
  §13 (493-497) and **§15** (619-621) still carry the retired rows and the retired cone.
  §15 matters most: it is the headless-assertable checklist and it now contradicts the
  shipped suite. Reproduce: `git grep -n "±15° cone\|2–3 Medium"
  docs/gameplay/18_engine_spec.md`. The file is owner-locked; my entry names it.
- **L74's gap stands**: `test_the_fragment_count_varies_inside_the_amended_bounds` would
  also pass on the retired rows. It is a LOW and unassigned; it needs `tests/`, which this
  pass cannot write.

## 6. Limits, stated plainly

1. This is a headless host and this pass is documentation: I read the shipped constants and
   proved the doc equals them, and I ran the gate. I did not watch a frame or hear a cue,
   and nothing here is new evidence about the rock-cleave behaviour itself — that is A1's
   probe and A2's re-measurement, both unchanged by this pass.
2. The guard reads text and constants, not intent: a future paragraph that stated a wrong
   number in prose the seven patterns do not cover would pass it. It is a drift detector for
   the seven facts §5 pins, which is exactly what A2's MED was.
3. The hook's Linux-path denial (L75) blocked my first write; I reported it as A2 did rather
   than editing the hook, which is outside every worker's set.
