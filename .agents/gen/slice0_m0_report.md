# Slice 0 — M0 report (doc check)

Worker: M0. Wave: engine slice 0 (physics & fuel). Date: 2026-09-21.
Brief: `.agents/gen/slice0_task.md` §M0 + Global rules; spec `docs/gameplay/18_engine_spec.md` §12 (items 7–13), §14 (slice 0), §16.
Scope: documentation only. Two files edited; four + two verified and left untouched.

---

## 1. Files changed (byte sizes, md5)

| File | Before | After | Δ |
|---|---|---|---|
| `docs/gameplay/01_economy_core.md` | 10 212 B · `d038c3d2bd00edc1afa13a5470ec01c3` | 10 677 B · `3089a3d44551b6e26b786a75e4f8db04` | +465 B, +7 lines |
| `docs/design/IMPLEMENTATION_PLAN.md` | 45 790 B · `e4d95d5708dc11f086233248ece33af3` | 47 085 B · `f6b2ff5ddd9e6f84975865a5c7fd93c0` | +1 295 B, +2 lines |

Verified, **not** modified (measured at verification time, §2):

| File | Bytes | md5 |
|---|---|---|
| `docs/gameplay/09_ship_slots_modules.md` | 13 562 | `95e3e1366b752e648f8a0ecbd317fd55` |
| `docs/gameplay/14_station_services.md` | 7 383 | `73f65557f1eb1015e8d23eeda0e54b09` |
| `docs/gameplay/06_loot_drops.md` | 6 486 | `13db7bdb277589da6e7ab01551119f32` |
| `docs/gameplay/11_galactic_map.md` | 7 281 | `407a2ad729f91dbe5f0e312af67bedfa` |
| `docs/gameplay/08_ship_classes.md` | 8 491 | `d0e46526edbb31cc2665801b27209a7d` |
| `docs/gameplay/02_minerals.md` | 10 664 | `632fa9bc092762296eeef74b032d3d81` |

Diff of the wave (only the two M0 files; the `staging/phase_f/*` entries were already dirty at session start and are another lane's):

```
$ git diff --stat
 docs/design/IMPLEMENTATION_PLAN.md |    2 +
 docs/gameplay/01_economy_core.md   |    7 +
 staging/phase_f/recut_quartet.py   |   44 +-          <- pre-existing, not mine
 staging/phase_f/recut_report.json  | 5934 ++++++...    <- pre-existing, not mine
 4 files changed, 5933 insertions(+), 54 deletions(-)
```

---

## 2. Commands and output

**Sizes/hashes** (`wc`/`grep`/`head`/`cat` are absent from this shell's PATH — tooling note §6):

```
$ py -3.14 -c "<len + md5 for the eight files>"
   13562  95e3e1366b752e648f8a0ecbd317fd55  docs/gameplay/09_ship_slots_modules.md
    7383  73f65557f1eb1015e8d23eeda0e54b09  docs/gameplay/14_station_services.md
    6486  13db7bdb277589da6e7ab01551119f32  docs/gameplay/06_loot_drops.md
    7281  407a2ad729f91dbe5f0e312af67bedfa  docs/gameplay/11_galactic_map.md
    8491  d0e46526edbb31cc2665801b27209a7d  docs/gameplay/08_ship_classes.md
   10664  632fa9bc092762296eeef74b032d3d81  docs/gameplay/02_minerals.md
   10212  d038c3d2bd00edc1afa13a5470ec01c3  docs/gameplay/01_economy_core.md
   45790  e4d95d5708dc11f086233248ece33af3  docs/design/IMPLEMENTATION_PLAN.md
```

**Universal test gate** (run twice; both identical):

```
$ "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path \
    "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn \
    --quit-after 1200 > .agents/gen/_slice0_m0_testgate.log 2>&1
exit=1
[FAIL] test_p1_catalogues.gd.test_mineral_icons_are_the_dedicated_glyphs:
       res://assets/icons/icon_mineral_iron_48.png is missing on disk
[SUMMARY] passed=52 failed=1          (runs 1 and 2, logs _slice0_m0_testgate{,2}.log)
```

Expected gate is `passed=53 failed=0`. See §5 — the single failure is an external,
concurrent asset-tree change, reproducible before and after the doc edits, and not
reachable by a `.md` write.

---

## 3. Verification of the applied 2026-09-20 amendment blocks (§12 items 7–12)

Verdicts are on content; form/placement notes are in §4.

| §12 item | Target | Evidence found | Verdict |
|---|---|---|---|
| 7a | `09` §3.1 weapon table gains a **power** column | `09:89–96` amendment block (rates 6/10/5 E/s, "kinetics … ammo as before, no Energy"); table `09:64–71` still has no `Power` column | content ✓ / form ✗ → **D1** |
| 7b | `09` §3.5 booster rows gain their fuel burns | `09:144` `b_afterburner` "burns BOOST_FUEL 3.0/s while active (2026-09-20)"; `09:145` `b_fold` "burns DASH_FUEL 25/burst, 0.8 s invulnerability (2026-09-20 rename)" | ✓ (matches §13, ruling 9) |
| 8 | `14` §2 services menu gains refuel + recharge rows | `14:20` row "Refuel / recharge … (2026-09-20: every station; CR rate per 18_engine_spec §13)" in §1's deck table; §2 (Contracts board) has no such rows | content ✓ / location ✗ → **D2**, dangling §13 pointer → **D3** |
| 9 | `06` countermeasures `cm_chaff`/`cm_flare` in the pirate tables | `06:50–51` fighter lines 5–6 at 0.15; `06:56–62` amendment block ("3 ghost signatures for 3 s", "within 450 u", other hull tables untouched; `cm_*` occur nowhere else in 06) | ✓ (matches §4.6 + §13) |
| 10 | `11` §1 hazard column: nebula rows; radar degradation transcribed | `11:34–40` nebula paragraph ("0–2 per sector as a registry row", "degrades radar and locks: passive tags inside refresh slowly and a lock channel cannot complete while its line crosses the cloud"); §1's table `11:17–25` has no hazard column | content ✓ / form ✗ → **D4** |
| 11 | `08` §2 speed anchor replaced by the §13 speed-table-v2 reference | `08:53–60` "flight-stat source is the handling column of 18_engine_spec §13 … and — 2026-09-20 — hull mass; the §13 speed table v2 replaces the ×450 anchor once the owner ticks its △ interpolations" | ✓ |
| 12 | `02_minerals.md` untouched | no `cleav`/`fragment`/`2026-09` match in `02`; the fragment rule lives in the spec (§13 "Fragment mineral: parent's mineral, re-rolled yield (02 §5 path)") | ✓ |

No invented constant was found in any of the applied blocks: every number traces to
the spec — weapon draw 6/10/5 E/s (§13), `BOOST_FUEL` 3.0/s, `DASH_FUEL` 25,
fold 400 u / 20 s / 0.8 s i-frames (ruling 9, §4.4), chaff 3 ghosts / 3.0 s and
flare 450 u (§4.6, §13 `CHAFF_WINDOW` / `FLARE_LURE`), nebula 0–2/sector (§8).

---

## 4. Discrepancies (reported only; no file was re-edited to "fix" a verified block)

- **D1 — LOW (form).** `09` §3.1: spec item 7 says the *table* gains a power column;
  the applied block says it in prose instead and keeps the small-integer `Draw`
  column as the fitting budget. Nothing is missing content-wise (the rates and the
  pack-fed split are named); only the column form of the transcription differs.
- **D2 — LOW (placement/row shape).** `14`: item 8 names §2; the row landed in §1's
  service-deck table, and as one combined `Refuel / recharge` row rather than two.
- **D3 — MED (dangling pointer, spec-side gap).** `14:20` cites "CR rate per
  `18_engine_spec` §13", but §13 carries no refuel rate row (a search for
  "fuel point" in the spec hits only §12 item 8 itself). The pinned interface in
  `slice0_task.md` §P7 also says "CR per fuel point per §13", so M3 needs a number
  the spec does not yet contain. Owner/M4 ruling needed: add the row to §13 or point
  the docs at another source.
- **D4 — LOW (form).** `11` §1: item 10 asks for a hazard *column*; §1's table has
  none, and the nebula amendment is a paragraph. The radar-degradation transcribe
  item 10 requires is present and matches §8.
- **D5 — LOW (naming basis).** Item 9 says the `cm_*` names "follow 03 components",
  but 03 has no countermeasure family and no `cm_*` id (its families are Salvage /
  Machinery / Electronics / Weapons / Power / Ore-Grade), and §12 does not list 03 as
  an amendment target. The ids are new vocabulary introduced by the 06 amendment.
- **D6 — LOW (availability ambiguity).** `14:20` says refuel/recharge at "every
  station", while §8's outpost subset enumerates what secondary stations offer and
  omits refuel/recharge. Neither §12 item 8 nor §4.4 states the outpost case.

---

## 5. External finding — the universal gate is red on an asset path, not on code

Both gate runs: `passed=52 failed=1`, the one failure being

```
[FAIL] test_p1_catalogues.gd.test_mineral_icons_are_the_dedicated_glyphs:
       res://assets/icons/icon_mineral_iron_48.png is missing on disk
```

Cause, measured during this session: `vajb-orbit/assets/icons/` is being reorganised
into per-family subdirectories by another lane *right now* — flat files gone,
`assets/icons/mineral/`, `status/`, `weapon/`, `hud/`, `service/`, `slot/`, … present
(1 350 PNGs in total, e.g. `assets/icons/mineral/icon_mineral_iron_48.png` = 3 678 B,
and the subdirectories' mtimes run from `2026-09-21 00:38:34` to `00:52:16`, i.e.
while this worker ran). `game/mineral_catalog.gd` and
`tests/test_p1_catalogues.gd:161` still reference the flat
`res://assets/icons/icon_mineral_<id>_48.png`. `assets/**` is outside M0's file set,
so nothing was touched; the failure is reproducible and pre-dates the doc edits (the
service/slot/status moves landed at 00:38, before the first command). M4 should
re-run the gate once the asset lane settles.

---

## 6. Deviations and tooling notes

- **Tooling:** this shell has no `wc`, `grep`, `head` or `cat` on PATH (each returns
  `executable file not found in $PATH`). Sizes/hashes were measured with `py -3.14`
  and content searched with the Grep/View tools. No semantic change to any command.
- **No file was re-edited** to resolve D1/D2/D4: the brief says verify, report
  discrepancies only. D3 and D6 are spec-side gaps that M0 cannot close in the doc it
  is checking.
- **Probes:** none written; M0 changed no code, so no `res://tools/_probe_s0m0_*.gd`
  exists and `vajb-orbit/tools/` still holds only `build_theme.gd` +
  `derive_icon_tints.gd`.
- Logs kept: `.agents/gen/_slice0_m0_testgate.log`,
  `.agents/gen/_slice0_m0_testgate2.log`.

---

## 7. Acceptance as measurements

| Requirement | Measurement |
|---|---|
| Verify `09`, `14`, `06`, `11` against §12 items 7–12 | 7 items checked against the spec text; all four files carry their 2026-09-20 block; md5s recorded in §1; 6 discrepancies reported, 0 files re-edited |
| Transcribe §12 item 13 into `01` §6, one paragraph, no new numbers | `01:180–185`, one paragraph, 6 lines, +465 B; every number in it (`&"fuel"`, save v3, ≥ 90 % exemption) already exists in the spec/01; inserted after `01:177–178` (the shield-alone exemption) and before `## 7` |
| Append the slice-0 line to `IMPLEMENTATION_PLAN` §9.9, no new numbers | `IMPLEMENTATION_PLAN.md:436`, one paragraph appended after §9.9's slice-1 closing line (§9.9 now ends the file); +1 295 B; all numbers are spec citations (§3.2, §6, §4.2 6–8, §12 item 8, save v3, §16 item 1) |
| Universal test gate | run twice: `[SUMMARY] passed=52 failed=1`; the single failure is the external asset-path item in §5 |
| Files touched vs worker set | exactly `docs/design/IMPLEMENTATION_PLAN.md` and `docs/gameplay/01_economy_core.md` (+ this report) — within M0's declared set |
