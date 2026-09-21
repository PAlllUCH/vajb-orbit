# Slice 0 — M0b report (owner ruling: refuel and recharge are free)

Worker: M0b. Wave: engine slice 0 (physics & fuel). Date: 2026-09-21.
Brief: worker prompt M0b (owner ruling dated 2026-09-21), driven by M0 discrepancy **D3**
(`.agents/gen/slice0_m0_report.md` §4).
Scope: documentation only. **Two edits in two files**, no new numbers, no new gameplay values.
Read before editing: `AGENTS.md`, `.agents/gen/slice0_task.md` (Global rules),
`docs/gameplay/18_engine_spec.md` §4.4 + §13, `docs/gameplay/14_station_services.md`,
`docs/gameplay/01_economy_core.md` §6, `.agents/gen/slice0_m0_report.md`.
Declared worker set: `VAJB_WORKER_FILES="docs/gameplay/14_station_services.md,docs/design/IMPLEMENTATION_PLAN.md"`
(verified in-session; matches the two files touched).

---

## 1. Files changed (byte sizes, md5)

| File | Before | After | Δ |
|---|---|---|---|
| `docs/gameplay/14_station_services.md` | 7 383 B · `73f65557f1eb1015e8d23eeda0e54b09` | 7 408 B · `f8e1c12ec4b478f629c3b54bd17b42e0` | **+25 B**, ±0 lines (one row rewritten in place) |
| `docs/design/IMPLEMENTATION_PLAN.md` | 47 085 B · `f6b2ff5ddd9e6f84975865a5c7fd93c0` | 47 607 B · `7be8ae201f44fe093be06d7cd6a23628` | **+522 B**, +2 lines (blank + one paragraph; 437 → 439 lines) |

Verified and **deliberately untouched** (measured before *and* after; md5 identical):

| File | Bytes | md5 (before = after) |
|---|---|---|
| `docs/gameplay/18_engine_spec.md` (owner-locked) | 41 156 | `ec51bba31150ad048eaff681ddb89b93` |
| `docs/gameplay/01_economy_core.md` (M0's file; carries M0's uncommitted edit) | 10 677 | `3089a3d44551b6e26b786a75e4f8db04` |

Line endings preserved: both edited files report `0` CR bytes after the edit (LF in, LF out;
git's "LF will be replaced by CRLF" warning is the repo-wide autocrlf note, not a change I made).
`vajb-orbit/tools/` still holds only `build_theme.gd`, `derive_icon_tints.gd` (+ `.uid`,
`desktop.ini`) from me — the `_probe_s0m2_*.gd` files present there are **M2's**, not this worker's.

---

## 2. Edit 1 — `docs/gameplay/14_station_services.md` §1 (line 20)

**Before** (exact, 100 B):

```
| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; CR rate per 18_engine_spec §13) |
```

**After** (exact, 125 B):

```
| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; free and instant, no CR charged; owner ruling 2026-09-21) |
```

What changed and what did not:

- **Struck:** `CR rate per 18_engine_spec §13` — the dangling pointer to a §13 row that does not exist (§13's
  "Energy & fuel (rulings 10–14)" table carries `energy_max`/`fuel_max`, `energy_regen`, `FUEL_PER_ENERGY`,
  `BOOST_FUEL`, `DASH_FUEL`, `FUEL_CELL_UNITS`, emergency mode and weapon draw — **no refuel CR rate**).
- **Replaced with:** `free and instant, no CR charged; owner ruling 2026-09-21` — the row now reads as a free
  instant service and cites no rate.
- **Unchanged:** the row label `Refuel / recharge`, all three faction ticks, the `2026-09-20: every station`
  amendment stamp, and the row's position/column count. No cell was added, removed or reordered; no other row
  in the table was touched (matching M0's D2 note that item 8 landed as one combined row rather than two — this
  worker did **not** re-shape it, per the "keep the rest of the existing row wording as close to unchanged as
  possible" instruction).

---

## 3. Edit 2 — `docs/design/IMPLEMENTATION_PLAN.md` §9.9 (appended after line 436)

One short paragraph appended at the end of §9.9 (which ends the file), separated by one blank line and followed
by the file's existing single trailing newline. **Before:** §9.9 ended with the slice-0 line ("…Speed table v2
bakes in only after the owner's tick (§16 item 1)."). **After,** the file ends:

```
**Owner ruling 2026-09-21 — refuel and recharge are free station services.** Both charge no CR: refuel and recharge are free and instant, and the spec carries no refuel CR rate, so no worker may invent one. This supersedes the pinned-interface wording that sourced a rate per fuel point from `18_engine_spec` §13 (that pointer survives only in the owner-locked spec's §4.4 ruling 13 and §12 item 8; `14_station_services.md` §1 no longer repeats it) and closes M0 discrepancy D3 (`.agents/gen/slice0_m0_report.md`).
```

Contents required by the brief, mapped one-to-one:

| Required by the brief | Sentence carrying it |
|---|---|
| refuel and recharge are free station services | "**Owner ruling 2026-09-21 — refuel and recharge are free station services.** Both charge no CR: refuel and recharge are free and instant…" |
| the refuel CR rate is not a spec number | "…the spec carries no refuel CR rate…" |
| no worker may invent one | "…so no worker may invent one." |
| supersedes the pinned-interface wording that said the rate comes from §13 | "This supersedes the pinned-interface wording that sourced a rate per fuel point from `18_engine_spec` §13 …" |
| closes M0 discrepancy D3 | "…and closes M0 discrepancy D3 (`.agents/gen/slice0_m0_report.md`)." |

**No new number is introduced by either edit.** The only digits added anywhere are dates (`2026-09-21`) and
document-cross-reference numerals (`§13`, `§4.4`, `§12 item 8`, `§1`, `D3`), all of which already existed.

---

## 4. Exact commands and output

**Baseline measurements** (this shell has no `wc`/`grep`/`head`/`cat`/`sleep` on PATH — measured with `py -3.14`,
searched with the Grep tool, waited with `time.sleep`; see §7):

```
$ py -3.14 -c "<len + md5 for four files>"
7383  73f65557f1eb1015e8d23eeda0e54b09  docs/gameplay/14_station_services.md
47085 f6b2ff5ddd9e6f84975865a5c7fd93c0  docs/design/IMPLEMENTATION_PLAN.md
41156 ec51bba31150ad048eaff681ddb89b93  docs/gameplay/18_engine_spec.md
10677 3089a3d44551b6e26b786a75e4f8db04  docs/gameplay/01_economy_core.md
```

**After the two edits** (same command):

```
7408  f8e1c12ec4b478f629c3b54bd17b42e0  docs/gameplay/14_station_services.md
47607 7be8ae201f44fe093be06d7cd6a23628  docs/design/IMPLEMENTATION_PLAN.md
41156 ec51bba31150ad048eaff681ddb89b93  docs/gameplay/18_engine_spec.md   <- unchanged
10677 3089a3d44551b6e26b786a75e4f8db04  docs/gameplay/01_economy_core.md  <- unchanged
```

**Arithmetic checks** (the deltas are exactly the edit, nothing else):

```
old line bytes 100 chars 93
new line bytes 125 chars 119        -> 125 - 100 = +25  == 7408 - 7383   ✓
paragraph chars 514 bytes 520       -> 520 + 2 newlines = +522 == 47607 - 47085  ✓
CRLF count 14: 0      CRLF count plan: 0
spec md5 recheck: ec51bba31150ad048eaff681ddb89b93
```

**Diff** (`git diff -- docs/`, trimmed to this worker's hunks; the `01_economy_core.md` entry is M0's
uncommitted edit and `staging/*` is another lane's — neither is mine):

```
$ git diff --stat -- docs/
 docs/design/IMPLEMENTATION_PLAN.md   | 4 ++++
 docs/gameplay/01_economy_core.md     | 7 +++++++      <- M0, not this worker
 docs/gameplay/14_station_services.md | 2 +-
 3 files changed, 12 insertions(+), 1 deletion(-)

$ git diff -- docs/gameplay/14_station_services.md
-| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; CR rate per 18_engine_spec §13) |
+| Refuel / recharge | ✔ | ✔ | ✔ (2026-09-20: every station; free and instant, no CR charged; owner ruling 2026-09-21) |

$ git diff -- docs/design/IMPLEMENTATION_PLAN.md      (this worker's hunk only)
+<blank>
+**Owner ruling 2026-09-21 — refuel and recharge are free station services.** Both charge no CR: …
```

**Residual-pointer search after the edits** (`Grep`, pattern
`CR rate per 18_engine_spec|rate per fuel point|fuel point, §13|rate in §13` over `docs/`):

```
docs/gameplay/18_engine_spec.md:211   for CR (rate in §13, 14 amendment); **recharge** tops the Energy pool
docs/gameplay/18_engine_spec.md:412    fuel point, §13) and **recharge** (instant Energy top-up) rows.
docs/design/IMPLEMENTATION_PLAN.md:438  <this worker's ruling paragraph, which cites them on purpose>
```

The station docs and the plan are clean; the two surviving pointers are **inside the owner-locked spec**, which
this worker must not edit (§6 deviation D-A).

**Universal test gate**, run twice, bounded, stdout to a log (Global rules command):

```
$ "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path \
    "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn \
    --quit-after 1200 > .agents/gen/_slice0_m0b_testgate.log 2>&1        # run 1
  (same, > .agents/gen/_slice0_m0b_testgate2.log)                        # run 2

[FAIL] test_p1_catalogues.gd.test_mineral_icons_are_the_dedicated_glyphs: res://assets/icons/icon_mineral_iron_48.png is missing on disk
[SUMMARY] passed=52 failed=1        (identical in both runs; 65 log lines each, no SCRIPT ERROR)
```

`[PASS]` rows confirm the suite boots and the P1 repairs/profile/refinery tests all pass. The single failure is
the same external asset-tree item M0 measured and is **not** reachable by a `.md` write (evidence in §5).

---

## 5. External finding (unchanged from M0's §5, re-measured) — the gate is red on an asset path

Re-measured this session while the other lane is still writing:

```
flat 48 png count: 0            (vajb-orbit/assets/icons/icon_mineral_*_48.png)
mineral/ 48 png count: 20       (vajb-orbit/assets/icons/mineral/icon_mineral_*_48.png)
subdir file exists: True 3678   (assets/icons/mineral/icon_mineral_iron_48.png)
```

`assets/icons/` now holds 14 family subdirectories (`alt`, `booster`, `cargo`, `contract`, `equip`, `hud`,
`ingot`, `insignia`, `map`, `mineral`, `module`, `service`, `slot`, `status`, `weapon`) whose mtimes were still
advancing during this worker's run (`00:52:03` … `00:56:28`), and one in-flight temp file
(`hud/icon_hull_48.png.import22221356140.tmp`) is present. `game/mineral_catalog.gd` and
`tests/test_p1_catalogues.gd:161` still reference the flat `res://assets/icons/icon_mineral_<id>_48.png`.
`assets/**` is outside this worker's file set and was not touched. M4 should re-run the gate once that lane
settles; the expected green is `passed=53 failed=0`.

---

## 6. Deviations

- **D-A (report-only, no edit):** the superseded wording also lives **inside the owner-locked
  `docs/gameplay/18_engine_spec.md`** — §2.1 ruling 13 ("Stations sell fuel for CR (14 amendment)"),
  §4.4 ("the station's **refuel** service buys missing fuel for CR (rate in §13, 14 amendment)"), and §12 item
  8 ("**refuel** (CR per fuel point, §13)"). The brief forbids editing that file, so they were left verbatim.
  The ruling paragraph in §9.9 names them explicitly so the next reader is not misled by them; whoever holds
  the spec's owner lock should strike them in the same pass that ticks speed table v2.
- **D-B (report-only, no edit):** `.agents/gen/slice0_task.md` §Pinned interfaces item 7 still says
  "CR per fuel point per §13" and its §Acceptance M3 row still says "fee math per §13". That file is the wave
  brief, not in this worker's set, so it was not touched; M3 should treat the §9.9 ruling paragraph as law
  (`refuel`/`recharge` keep `repair()`'s return shape with no fee) and M4's CONTRACTS update should supersede
  the brief wording.
- **D-C (out of scope, pre-existing):** `14_station_services.md` §1 keeps M0's D2 shape — one combined
  `Refuel / recharge` row rather than the two rows §12 item 8 asked for. The brief said to keep the existing row
  wording as close to unchanged as possible, so the row was rewritten in place, not split.
- **D-D (scope judgement):** "the refuel and recharge rows" in the brief is one row in the actual document
  (§3/D-C). The ruling now covers both services in that single row, so both read as free and instant; nothing
  was lost by not splitting.
- **No probe was written** and none is needed: this worker changed no code, so no
  `res://tools/_probe_s0m0b_*.gd` exists.
- **Tooling:** this shell has no `wc`, `grep`, `head`, `cat`, `ls`(flag-supported) or `sleep` on PATH (each
  returns `executable file not found in $PATH`); sizes/hashes/diff arithmetic were computed with `py -3.14`,
  waiting was done with `time.sleep`, and content was searched with the Grep tool. No semantic change to any
  command. Logs kept: `.agents/gen/_slice0_m0b_testgate.log`, `.agents/gen/_slice0_m0b_testgate2.log`.

---

## 7. Acceptance as measurements

| Requirement | Measurement |
|---|---|
| Strike the dangling §13 pointer for a refuel CR rate in `14` | line 20 rewritten: `CR rate per 18_engine_spec §13` absent; grep for `CR rate per 18_engine_spec` over `docs/` returns only the §9.9 ruling paragraph that cites it deliberately. Row labelled as **free and instant, no CR charged** |
| Keep the rest of the row wording as close to unchanged as possible | row label, all three `✔` ticks, `2026-09-20: every station` and the column count all identical; +25 B total, ±0 lines; no other row or section touched (`git diff` = 1 changed line in the file) |
| Both refuel and recharge read as free instant services, citing no rate | the single combined row states `free and instant, no CR charged` and cites no document for a price |
| Append one short paragraph to `IMPLEMENTATION_PLAN` §9.9 recording the ruling | appended after line 436 as the file's last paragraph: +2 lines, +522 B, 437 → 439 lines, md5 `f6b2ff…` → `7be8ae…`; all five required contents present (§3 table) |
| No new numbers / no new gameplay values | the only digits added are the date `2026-09-21` and document cross-references; zero calibration values appear in either diff |
| `18_engine_spec.md` not edited | md5 `ec51bba31150ad048eaff681ddb89b93` identical before and after |
| No other file touched | `git status --porcelain` shows `docs/design/IMPLEMENTATION_PLAN.md` and `docs/gameplay/14_station_services.md` from this worker (plus M0's `docs/gameplay/01_economy_core.md`, another lane's `staging/phase_f/*`, and the external `assets/icons/**` churn) |
| Universal test gate | run twice: `[SUMMARY] passed=52 failed=1`, both runs; the one failure is the external asset-path item in §5, reproducible before and after the doc edits |
| Report | this file, `.agents/gen/slice0_m0b_report.md` |
