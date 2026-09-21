# P1r2 report — independent re-review of the P1 fix wave

Verifier pass. Nothing in the project was edited: this report is the only file written. No MCP tool,
no editor. Truth: `.agents/gen/p1fix_task.md`, `.agents/gen/p1fix_report.md`, `.agents/gen/p1r_report.md`,
the shipped files, `docs/gameplay/01`–`05`/`17`, `docs/design/STATION_HUB.md` §5.8/§5.9,
`ICONS_SPEC.md` §8.1/§8.6/§9.6, and my own runs of the gate and the two boots (below).

**Verdict: all eight fixes are present and behave as the task specified. No fix regressed a reviewed
behaviour. Four new issues, all minor/cosmetic or test-coverage gaps (N1–N5 below), plus one process
observation (files outside the task's allowed list carry wave-time mtimes, P1).**

| Fix | Verdict | Evidence |
|---|---|---|
| F1 ship maxima | **confirmed** | `game/game.gd:16` preload, `:97` call before `_state.setup()` `:98`, `:217-232`; clamping below |
| F2 exchange re-entrancy | **confirmed** | `game/exchange.gd:242-258`, `:269-297`; real regression test `tests/test_p1_market.gd:230-269` |
| F3 repairs footer | **confirmed** | `ui/station/repairs_panel.gd:57,210-215,72`; `_footer` owned `repairs_panel.tscn:115-116` |
| F4 board baseline meta | **confirmed** (N4) | `ui/station/exchange_panel.gd:109,326-328,361-366`; `game/exchange.gd:86-89` |
| F5 focus guards | **confirmed** | `refinery_panel.gd:151-163`, `exchange_panel.gd:189-198`, `repairs_panel.gd:112-117` |
| F6 `warning_ignore` | **confirmed** | `world_clock.gd:38-39`, `refinery.gd:55-56`; the only two int/int sites in first-party code |
| F7 profile test gap | **confirmed** | `tests/test_p1_profile.gd:59-94` against `player_profile.gd:435-440` |
| F8 Phase F icons | **confirmed** (N1–N3) | 40/40 paths on disk + catalogue, 2 panels, `test_p1_catalogues.gd:152-172` |

## Gate and boots (re-run by me)

- `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn --quit-after 1200`
  → `[SUMMARY] passed=53 failed=0`, exit 0, no `SCRIPT ERROR`, no `INTEGER_DIVISION` warning. The only stderr
  noise is the deliberate `EconomyLog: could not open user://p1l_missing_dir_do_not_create/...` warning from
  `test_p1_clock_log.gd:test_unwritable_log_path_is_survivable`. Reproduced the report's claim exactly.
- Per-suite counts 11/4/13/5/9/6/5 = 53. `.agents/gen/p1l_run.txt` (12:35) has 51 = 10/4/12/5/9/6/5, i.e. the
  wave added exactly two tests: `test_mineral_icons_are_the_dedicated_glyphs` (F8) and
  `test_reentrant_quote_during_a_sale_keeps_the_fresh_market` (F2). No other test appeared or disappeared.
- `res://ui/screens/station.tscn --quit-after 300` → exit 0, no `SCRIPT ERROR`; the known pre-existing
  `4 ObjectDB instances were leaked` / `2 resources still in use` pair only (`.agents/gen/leak_verbose.log`
  does name `amb_station_room_01.ogg`, 8 mentions). `res://game/game.tscn --quit-after 300` → exit 0, clean.
  Both boots resolve the new icon paths (the station boot loads the hold rows, the 20 ingot board glyphs,
  the 18 component stencils and the REPAIRS footer; the game boot preloads the HUD's six `tint/` cargo stencils).

## Per-fix verification detail

**F1.** `ShipCatalog` is preloaded by path (`game.gd:14-16`) so the read never depends on the class table;
`_apply_ship_maxima()` runs before `setup()`, so the seeded maxima are the ones `setup()` publishes and the
HUD binds to. `StationCatalog.ship()` returns `{}` for an unknown id (`station_catalog.gd:168-169,188-192`),
which keeps the `PlayerState` defaults (`player_state.gd:14-16` = the Vanguard's 1000/600/40). Each value is
applied only when positive (`game.gd:227-231`), no warning path exists, and `_seed_vitals` (`:237-248`) clamps
with `minf(...)` against the real maxima before `set_hull`/`set_shield` clamp again (`player_state.gd:42,55`),
so an over-max record lands on the maximum and an under-max record is preserved. `_file_damage_report`
(`:253-257`) files the already-clamped values. Residual (pre-existing, matches the report's note 1): maxima now
have two readers, `game.gd` and `Repairs.fee` (`repairs.gd:38-52`), and both ignore the installed
`upgrade_shield` / `upgrade_extra` modifiers (`station_catalog.gd:122,149`); they agree with each other, so no
phantom fee, but the +20 % shield upgrade stays inert in both places and any future hull modifier must be
applied twice.

**F2.** `sell` re-reads `profile.market()` at `exchange.gd:254` immediately before `_apply_trade`/`set_market`
and the deltas land on that copy; `sell_all` does the same per line (`:292-294`) and the next line quotes
against the fresh copy. Emit order is untouched: evaluate → quote/verify → `remove_cargo` → `add_credits` →
market write → log (01 §7 / 05 §6.5), and pricing still uses the quote-time values. The re-read is sound
because `market()` returns `duplicate(true)` and `set_market` is silent (`player_profile.gd:269-278`). The new
test (`test_p1_market.gd:230-269`, fixture `:397-407`) is a genuine guard: with the re-read removed the sale
writes back the pre-sale copy, so the "stamp survives" assertion (`:257-261`) and the "drifted book survives"
one (`:262-267`) both fail, exactly as the report's 12/13 experiment claims; payout, credits and cargo are
also pinned to the quote. Residual (N5): the written deltas are still computed from quote-time values, so a
re-entrant restock of the sold component's stock/queue, or the sold mineral's own drift, is overwritten.

**F3.** `FOOTER_FORMAT` (`repairs_panel.gd:57`) is a format built at `:210-215` from
`RepairsService.HULL_CR_PER_POINTS` / `SHIELD_CR_PER_POINTS` (`repairs.gd:21-22` = 2 / 3), and `%PaneFooter`
resolves (owned node, `repairs_panel.tscn:115-116`). The scene literal (`repairs_panel.tscn:119`) is
byte-equal to the string the runtime builds, and STATION_HUB §5.9 fixes that same string, so the pre-`_ready`
default cannot contradict the constants. The .tscn copy remains a second owner of the text (disclosed).

**F4.** The mineral board row keeps its meta label in the payload (`exchange_panel.gd:326-328`) and refreshes
it to `BOARD_META_FORMAT` (`:109`) = `<ingot baseline> CR · <demand>x` from `Exchange.baseline_of` on the
row's ingot id and `Exchange.demand_of` (`:361-366`); `PRICE` stays `exchange_price` → `unit_net`. `unit_gross`
now carries the 05 §2 "gross helper of the pricing family, kept for the pricing family and the suite"
comment (`exchange.gd:86-89`) and is still called only by `test_p1_pricing.gd:78`. See N4.

**F5.** All three panels gate `grab_focus()` on `.disabled`: refinery rows/REFINE/REFINE ALL
(`refinery_panel.gd:154-163`), exchange hold rows/SELL ALL (`exchange_panel.gd:192-198`), repairs' only
button (`repairs_panel.gd:116-117`). The fallback the comments name is real: `station.gd:401-410` calls
`focus_primary()` and hands the ring to the rail entry when the focus owner is not inside the panel. In the
empty states every candidate is disabled (exchange `:533-537`, refinery `:478-482`), so no disabled control
can take the ring.

**F6.** Exactly two annotations exist in the tree, each on the line directly above the returning statement
(`world_clock.gd:38-39`, `refinery.gd:55-56`), and a scan of every first-party `.gd` (addons excluded) finds
exactly two integer divisions: those two (`repairs.gd:50-51` divides floats). The gate prints no
`INTEGER_DIVISION` warning, and an invalid annotation target would be a parse error, so placement is proven by
the run. Residual: adjacency is load-bearing, as disclosed.

**F7.** The test now calls `reload()` on a fresh instance with no file on disk (`test_p1_profile.gd:65`),
which is the `ERR_FILE_NOT_FOUND → _apply_defaults()` first-run branch (`player_profile.gd:435-440`), and
asserts 10000 CR plus "a fresh instance writes nothing" (`:66-69`), one owned `ship_vanguard` as both owned
and active (`:71-74`), empty upgrades/cargo (`:75-76`), 300 rounds for each of `AMMO_MAX`'s five weapons
(`:77-79`), the four market buckets and `last_band 0` (`:81-85`) and the remaining P1 keys at their defaults
(`:86-94`) — the STATION_SPEC §2.8 set the brief asked for. No file is left behind (verified).

**F8.** Every catalogue row points at its dedicated glyph (`mineral_catalog.gd:31-260`) and the header records
ICONS_SPEC §8.1's "Retire the 02 §6 fallback" with `TIER_TINTS` kept as the fallback (`:5-11`, `:264-269`);
ICONS_SPEC §8.1's follow-on clause ("then it covers ore/container only where a glyph is absent") and §8.6's
scope match what the code does. All 40 referenced files exist on disk (20 ore + 20 ingot, `krilium`
included); no generic 02 §6 ore/ingot name survives anywhere in the project, and no code path references
`tint/icon_mineral_*` or `tint/icon_ingot_*`. Both panels test the file-name prefix *before* any `tint/`
substitution (`exchange_panel.gd:844-874`, `refinery_panel.gd:393-416`), so dedicated art loads as itself and
is inked `WHITE` at alpha 0.72 while only a `tint/` stencil takes the tier tint; the board publishes the ingot
glyph (`:276`) and hold rows the row's own form (`:836-841`). I replayed both rules read-only over all 58
paths: 40/40 dedicated → untinted, 18/18 components → their existing `tint/` stencil + `GRADE_TINTS`
(unchanged, as the brief requires). `test_p1_catalogues.gd:152-172` asserts both path shapes and
`ResourceLoader.exists` for all 40 (`checked == 40` at `:172`) and passed in my gate run.

## New issues the fix wave introduced

| # | severity | where | issue |
|---|---|---|---|
| N1 | minor | `mineral_catalog.gd:9-11`, `refinery_panel.gd:393-397,388`, `exchange_panel.gd:65-69` | **The declared "absent dedicated glyph" fallback cannot trigger.** The prefix test short-circuits before any existence check, so a missing `icon_mineral_*` file is (a) never substituted with a `tint/` stencil and (b) handed straight to `load()` in the refinery, which has no `ResourceLoader.exists` guard (`:388`) → an engine error and a row with no icon; the exchange silently draws no icon (`:806-819` does check). Only a catalogue entry carrying a *non*-dedicated name reaches the tinted-stencil branch, so the comments in all three files describe a fallback that does not exist for the case they name. |
| N2 | nit | `tools/derive_icon_tints.gd`, `assets/icons/tint/` | The dedicated families' stencils (40 at `_48` — 20 `icon_mineral_*` + 20 `icon_ingot_*`, plus their 16/96/192 siblings) are now unreachable render assets: nothing loads them, and the tint pass regenerates them every run (they are part of §9.6's 556). |
| N3 | minor | `tests/` | The F8 branch has **no permanent test**. There is no panel suite, so the prefix/untinted rule and the fallback are evidenced only by the wave's deleted probe; a future change that tints every glyph, or inverts the prefix guard, passes the gate. The catalogue test asserts data paths, not panel behaviour. |
| N4 | nit | `ui/station/exchange_panel.gd:361-366` | The board row now prints the demand twice (`65 CR · 1.0x` meta beside the `INDEX` cell `1.0x`) and the mineral row lost its kind caption — `META_INGOT` is assigned at `:275` and overwritten by the first `_refresh_board()`, while component rows still read `SURPLUS`, so the two row families read differently. §5.8 specifies no meta for board rows, so this is an owner call: dropping the `INDEX` cell needs a §5.8 amendment. Disclosed by the report as its re-review item 3. |
| N5 | nit | `game/exchange.gd:254-256,292-294,364-371` | The deltas applied to the fresh copy are still quote-time-derived, so a re-entrant restock of the sold component's stock/queue is overwritten and the sold mineral's own drift is replaced by quote−impact. Deliberate per the task and pre-existing in class, but it is asymmetric with the "newer snapshot survives" law the fix now states, and no test pins the component arm. |

## Process and environment observations (no defect, worth the owner's eye)

- **P1 — files outside the task's allowed list carry wave-time mtimes.** Modified in the wave window
  (13:15–13:28): the 8 named sources + `test_p1_catalogues.gd` (13:24:11), `test_p1_market.gd` (13:27:37),
  `test_p1_profile.gd` (13:27:45) — and also `project.godot` (13:15:50), `tests/test_p1_repairs.gd`
  (13:27:47) and `tests/test_p1_clock_log.gd` (13:27:48). The last two are outside F1–F8, their test-name
  sets are identical to the 12:35 `p1l_run.txt`, and neither contains anything F1–F8-related, so no
  substantive out-of-scope change is visible; the two named suites were touched *after*
  `p1fix_report.md` (13:26:27) was written. A live editor session is demonstrable during the wave
  (`.godot/imported` writes 13:17–13:19, `.godot/editor/editor_layout.cfg` and `script_editor_cache.cfg`
  13:21:36), which is the likeliest writer of `project.godot`; `project.godot`'s content today matches the
  documented configuration (main scene `boot.tscn`, the 7 autoloads incl. `WorldClock`/`PlayerProfile`,
  `editor_plugins` = godot_ai, the input map, Forward+/Jolt/D3D12) and contains nothing new. The workspace
  has no VCS, so no diff is possible and I cannot attribute the writer — reporting the timestamps only.
- **P2 — the owner's `user://profile.cfg`.** It is v2 and intact; my *first* station boot rewrote it
  (mtime 13:28:38, station-entry market evaluation as documented), after which it is byte-identical
  (sha256 `a5b435f4…`) across three further station boots and one game boot, with `last_band` unchanged at
  1789730287 (13:18:07; 0 bands elapsed). Note the file today holds `credits=200600`, two installed upgrades
  and a non-empty cargo, which does not match the fix report's "(credits 600)" — a later "fresh profile"
  check must not treat it as pristine, and the owner may want to confirm that balance.
- No suite artefacts survive: no `user://test_p1_*` file, no `economy_log.txt`, no probe file in the project.
- I did not create a probe: the panel-level F8/F4 behaviour is verified by reading the code and by replaying
  its exact rules read-only over the catalogue paths, not by running a scene. The boot runs are the limit of
  the runtime evidence for panel state (they prove the paths load and nothing errors, not the modulate colour).
