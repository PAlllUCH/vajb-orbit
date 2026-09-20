# Engine wave 1 — W0 report (doc transcription from ENGINE_SPEC §12)

Worker: W0 (docs only). Status: **done**. Deliverables: exactly the five named docs, nothing else
touched. Brief: `.agents/gen/engine_wave1_task.md` §W0, global rules §"Global rules".

Every sentence added below is transcribed from `ENGINE_SPEC.md` (workspace root). No number, no
threshold and no design decision originates in this worker; where a number appears in a doc it was
copied from the spec, and where the spec makes §13 the single source the doc points at §13 instead
of restating it.

## 1. Files changed (measured before → after)

Measured with `py -3.14` (`os.stat`-equivalent via `open(p,'rb').read()`); CRLF count is included
because these docs are LF-only and must stay so.

| File | Bytes | Lines (LF) | CRLF | md5 after |
|---|---:|---:|---:|---|
| `docs/design/IMPLEMENTATION_PLAN.md` | 39 500 → 45 561 (+6 061) | 397 → 434 (+37) | 0 | `EAD9705CE928B5DDF98873F8F29278F1` |
| `docs/gameplay/08_ship_classes.md` | 7 922 → 8 321 (+399) | 136 → 143 (+7) | 0 | `1D79F6588AA51562519AA6CCC520564F` |
| `docs/gameplay/09_ship_slots_modules.md` | 11 824 → 12 826 (+1 002) | 234 → 248 (+14) | 0 | `6C8B61430D1FBB4DA63FBE53E09B6D18` |
| `docs/gameplay/11_galactic_map.md` | 6 351 → 6 758 (+407) | 133 → 140 (+7) | 0 | `F0F6500BD34633BB697AC13EAE128ABF` |
| `docs/design/PROJECT_SETTINGS_PATCH.md` | 10 404 → 11 126 (+722) | 190 → 194 (+4) | 0 | `B7353ED84B3F3932CCB23DF9727F694B` |

Total: +8 591 bytes, +69 lines, five files, LF preserved, no file created or deleted.

## 2. What was transcribed, per file, with its spec citation

| Change | Spec source |
|---|---|
| `IMPLEMENTATION_PLAN.md` new **§9.9 Engine wave amendments** (decisions 1–7 verbatim; §3.7, §3.9, §3.10 amendments; retirements; companion-doc list; §13 as the number source) | §12 item 4, §2, §3.1, §4.2, §10, §11 |
| `IMPLEMENTATION_PLAN.md` §3.7: `interact` (F) and `warp` (H) appended to the rebinding list (17), ESC keeps its binding and changes in-game meaning, `InputMap.has_action` guards | §11 |
| `IMPLEMENTATION_PLAN.md` §3.9: `func damage(amount: float, bypass_shield := false) -> void` + no-carry-over/otherwise-hull note, HUD signals unchanged | §12 item 5, §4.2 |
| `IMPLEMENTATION_PLAN.md` §3.10: `set_prompt(text: String)`, `set_warp_channel(progress: float)`, `&"friendly"` blip kind, `set_target_info` range state, reticle states + hit markers | §10, §12 item 4 |
| `08_ship_classes.md` §2: flight handling is sourced from the handling column of `ENGINE_SPEC.md` §13; 08 references it, `Base speed` stays the progression column (§13 max speed = base % × 450 u/s) | §12 item 1, §13 |
| `09_ship_slots_modules.md` §3.1: `Family` + `Shield rule` columns on all six weapon rows; note giving the family enum and `w_mining` = tool / rocks only; railgun's "ignores 50 % of armour" retired with the spec's reason | §4.1, §12 item 2 |
| `09_ship_slots_modules.md` §3.2: base shield regen 2/s with no shield module; module regen adds to it; regen resumes 4 s after the last incoming damage | §4.2, §12 item 3 |
| `11_galactic_map.md` §1: one arena size (`SECTOR_SIZE`, §13) and the same layout budget for every sector; differentiation by backdrop/owner/tier mix/enemy mix/hazards, never size; §1.1 tier table stays authoritative | §2 decision 4, §8, §12 item 6 |
| `PROJECT_SETTINGS_PATCH.md` §2: `interact` = F (order 16), `warp` = H (order 17), `input_action_count` 15 → 17, two new notes; §6 verify text 15 → 17 | §11 (+ brief §W0 item 5) |

## 3. Commands run, with output

Docs-only task, so no Godot process was started: per the brief the editor was left alone, no
headless `--editor` reimport was run, and no scene run was needed (no code changed). Verification
was done with file-level measurements under `py -3.14` (the interpreter AGENTS.md mandates; the
PATH `python` is Inkscape's and has no CA roots).

1. Before-edit baseline:

```
powershell -NoProfile -Command "... Get-FileHash -Algorithm MD5 ... (Get-Item $p).Length ..."
docs/design/IMPLEMENTATION_PLAN.md bytes=39500 md5=620E10E34AE1828A1385780E13C386AE
docs/gameplay/08_ship_classes.md bytes=7922 md5=532520037F3DAFF268D80198AD1883F7
docs/gameplay/09_ship_slots_modules.md bytes=11824 md5=9A4EC61C2E299395781E0098A05B7F0F
docs/gameplay/11_galactic_map.md bytes=6351 md5=9ECC25BDFDADC0E99BFD46410194E516
docs/design/PROJECT_SETTINGS_PATCH.md bytes=10404 md5=FC741F35F780C8FE8653E10CCC6CB364
```

Line-ending baseline (byte scan): `IMPLEMENTATION_PLAN LF=397 CRLF=0 · 08 LF=136 CRLF=0 ·
09 LF=234 CRLF=0 · 11 LF=133 CRLF=0 · PATCH LF=190 CRLF=0` (so every added line is LF, confirmed
again after editing).

2. JSON validity of every fenced block in the patch doc (the only machine-applied doc):

```
py -3.14 -c 'import json,re; ...'
JSON OK blocks= 6
actions= [17]
count field= [17]
tail= {'verify': [... 'exactly the 17 user actions above, in order, one key event each' ...]}
```

All six `json` blocks parse; the actions list is 17 rows and `input_action_count` agrees with it.

3. Structural shape of the edited docs:

```
IMPLEMENTATION_PLAN bytes= 45561 lines= 435  fences= 10 even  table col-count groups= {3: 34, 4: 19, 5: 7}
08 bytes= 8321  lines= 144  fences= 0 even   table col-count groups= {11: 11, 10: 11, 4: 24}
09 bytes= 12826 lines= 249  fences= 0 even   table col-count groups= {5: 10, 3: 8, 8: 8, 6: 39, 4: 11}
11 bytes= 6758  lines= 141  fences= 0 even   table col-count groups= {6: 18, 4: 10}
PATCH bytes= 11126 lines= 195 fences= 12 even table col-count groups= {}
```

The new 8-pipe group in 09 is exactly the rebuilt §3.1 table (7 columns: header + separator + 6
rows = 8 rows). Every other group is unchanged in kind, so no table lost or gained a stray cell.

4. Transcription check — weapon families and shield rules, 09 §3.1 versus ENGINE_SPEC §4.1:

```
spec rows 7  09 rows 6
w_laser    same=True
w_cannon   same=False   (only difference: spec bolds "**bypasses shields**"; cell text identical)
w_rocket   same=True
w_mine     same=True
w_plasma   same=True
w_railgun  same=True
MISMATCHES: ['w_cannon']
spec w_mining: ('tool', 'rocks only')
```

6 of 6 rows are byte-identical to the spec once the spec's own markdown bold markers are removed
(normalised so the cell matches the plain style of the other eleven cells in that table). The
`w_mining` = tool / "rocks only" fact quoted in the new note is the spec's seventh §4.1 row.

5. Cross-check that the §13 handling table is the arithmetic of 08 §2's percentages:

```
Fighter    pct=100% x450=  450.0 -> spec 450  OK
Cutter     pct= 95% x450=  427.5 -> spec 428  OK
Miner      pct= 75% x450=  337.5 -> spec 338  OK
Trader     pct= 85% x450=  382.5 -> spec 383  OK
Corvette   pct=110% x450=  495.0 -> spec 495  OK
Hauler     pct= 65% x450=  292.5 -> spec 293  OK
Gunship    pct= 80% x450=  360.0 -> spec 360  OK
Frigate    pct= 85% x450=  382.5 -> spec 383  OK
Destroyer  pct= 70% x450=  315.0 -> spec 315  OK
ALL MATCH
```

9/9 classes: §13's max speed equals 08 §2's base-speed percentage × 450 u/s (rounded to the
nearest integer, worst error 0.5 u/s). This is the measurement behind the sentence added to 08 §2;
it also confirms neither doc needs a value changed.

6. Scope proof — files written during this task (mtime scan of the whole workspace, 2 h window):

```
16:11:39 docs/design/IMPLEMENTATION_PLAN.md
16:11:15 docs/design/PROJECT_SETTINGS_PATCH.md
16:11:05 docs/gameplay/11_galactic_map.md
16:11:02 docs/gameplay/09_ship_slots_modules.md
16:10:54 docs/gameplay/08_ship_classes.md
```

Those five are the only files this worker wrote (the other recent entries in that listing, e.g.
`ENGINE_SPEC.md` 15:46, `vajb-orbit/**` 14:xx–15:xx, precede this task). Nothing under
`vajb-orbit/`, `project.godot`, `assets/`, `addons/` or `staging/` was touched; no probe file was
created, so nothing needed deleting. `vajb-orbit/tools/` still holds only `build_theme.gd` (+`.uid`)
and `derive_icon_tints.gd` (+`.uid`), as the brief requires.

## 4. Deviations and open points

1. **08 §2 has a reference, not a duplicated numeric column (interpretation, needs no reversal
   unless the owner wants the numbers restated).** ENGINE_SPEC §12 item 1 says the hull table
   "gains a handling column (§13 table is the source; 08 references it)"; the brief's §W0 item 2
   narrows it to "note that the handling column of `ENGINE_SPEC.md` §13 is the flight-stat source
   for engine purposes". Because the same item names §13 *the source* and 08 *the referrer*,
   putting the nine rows of handling numbers into 08 would create a second copy of a table the
   spec declares single-source, so 08 §2 now names §13's handling column, lists its five columns
   and the 450 u/s scale relation, and states that §13 is the single source. Reversal path: copy
   the nine §13 rows into the 08 hull table as a `Handling` block (or per-cell columns) — the
   values are on the spec's §13 table, so it is a pure transcription either way.
2. **Two order numbers and one count were derived, not quoted.** The patch doc's §2 JSON requires
   `order` per row and `input_action_count`, so appending two actions produced `order: 16/17` and
   `input_action_count: 17` (with the §6 verify line and the §2 prose updated to match, so the doc
   stays internally consistent and appliable). No behavioural decision rides on them; the binding
   values (`F`, `H`) and the actions' purpose are the spec's.
3. **`SettingsManager.REBINDABLE_ACTIONS` is a hardcoded 15-entry const and will not follow the
   patch.** `vajb-orbit/autoload/settings_manager.gd:29–45` lists the fifteen Phase C actions
   literally, and `rebindable_actions()` (`:142`) serves that const. After the orchestrator applies
   `interact`/`warp`, the settings CONTROLS tab still shows fifteen rows unless a code owner
   extends the const. This is a code edit, outside W0's docs-only remit (and `autoload/` is not in
   any slice-1 file list), so it is reported rather than done. §3.7's amended text now states the
   contract expectation of 17, so the gap is visible to the W6 review.
4. **ENGINE_SPEC §12 item 5's `game/player_state.gd` change is recorded, not made.** §3.9 of the
   plan now carries the `damage(amount, bypass_shield := false)` signature and its §4.2 semantics;
   the GDScript edit belongs to a slice-1 code owner (the brief's §W1–§W4 file lists), not to W0.
5. **§9.9 deliberately carries no numbers.** The spec makes §13 the single, playtest-tunable
   source; §9.9 therefore names the values' home (§13: speed scale, per-class handling, weapon
   ranges, aggro radii, `AGGRO_COOLDOWN`, `WARP_CHANNEL`, `SECTOR_SIZE`, pickup lifetime/tractor,
   `MINE_CYCLE`) and the interface's home (§9) instead of copying them. If the contract is expected
   to restate them, that is a one-edit change.
6. **`docs/design/PHASE_C_STATUS.md:63` still reads "15 actions".** Left alone: it is a historical
   Phase C record ("photographed" evidence) and is not in this wave's file list.
7. **Not mine, but visible in the scope scan:** `CLEANUP_PLAN.md` at the workspace root was created
   at 16:11:41 (seconds after my last edit) by another actor; it opens with "Nothing here executes
   while a worker wave is in flight". Untouched by this worker, flagged only so the mtime picture
   is unambiguous.
8. **No Godot verification was run, by design.** Docs-only change; the brief forbids launching the
   editor or a headless `--editor` reimport, and no `.gd`/`.tscn` byte changed, so the parse/boot
   gates in `IMPLEMENTATION_PLAN.md` §6 have nothing to exercise here. Evidence above is
   file-level and structural.

## 5. State handed to W1–W4

The docs are frozen for this wave as of this report. Code must code against: `interact` = F and
`warp` = H behind `InputMap.has_action` guards (point 3 above is the reason), ESC = cancel
order + lock, docking = dock-zone `F` prompt, HUD `set_prompt` / `set_warp_channel` /
`&"friendly"` blips / reticle states, and `PlayerState.damage(amount, bypass_shield := false)`.
