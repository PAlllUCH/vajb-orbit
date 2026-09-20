# P1r report — independent review of the P1 economy core

Reviewer pass. No file outside this report was created or edited; no MCP tool, no editor run.
Truth used: `docs/gameplay/01`–`05`, `17`, `docs/design/STATION_HUB.md` (§2, §3.1, §5.6–§5.9,
§12.3/§12.4), `STATION_SPEC.md`, `ICONS_SPEC.md` §8.6 (plus §8.1, cited by the code, and
`docs/gameplay/11` §1.1, which the catalogue cites as superseding 02 §5 — both verified).
Files read in full: the two catalogues, `exchange.gd`, `refinery.gd`, `repairs.gd`,
`economy_log.gd`, `world_clock.gd`, `player_profile.gd`, the three new panels (.gd + .tscn),
`station.gd`, `game.gd`, `station.tscn`, `tests/` (runner + 7 suites).

**Verdict: no blockers.** The numbers, the transaction law, the one-clock rule, the panel
contract and the persistence migration all hold. 17 findings, 1 major, rest minor/nits,
plus two end-to-end/reachability notes.

## Findings

| # | severity | file:line | problem | suggested fix |
|---|----------|-----------|---------|---------------|
| 1 | major | `game/game.gd:211-231`, `game/player_state.gd:14-15`, `game/repairs.gd:41-52` | `PlayerState` pools are the Vanguard's (1000/600) whatever the active hull; vitals are clamped to and written back from those maxima, so a non-Vanguard hull shows phantom damage and pays a fee at every dock | seed `hull_max`/`shield_max`/`cargo_max` from `StationCatalog.ship(active_ship)` in `game.gd` (STATION_SPEC §6 rule 5 already gives it that job); clamp the filed report to those maxima |
| 2 | minor | `game/mineral_catalog.gd:259-264`, `game/component_catalog.gd:192-196` | 7 hex literals in game code; IMPLEMENTATION_PLAN §7:340 = "No hex literals outside `tools/build_theme.gd`" (STATION_SPEC §1 repeats it). Palette now has two owners | move the tints to `Tokens/…` in `tools/build_theme.gd` and read them via `get_theme_color`, or record an explicit amendment (STATION_HUB's P1 amendment claims "no new theme items") |
| 3 | minor | `game/exchange.gd:235-249`, `260-284` | `sell`/`sell_all` snapshot `state`, then emit `profile_changed` (from `remove_cargo`/`add_credits`) mid-transaction; a panel refresh re-enters `Exchange.quote` → `evaluate_market` → `set_market`, and the outer call then writes its older snapshot back | guard the panel's `&"cargo"` refresh with a `_transaction`/`_rebuild_pending` pair (the refinery panel already does), or re-read the market after the emits |
| 4 | minor | `ui/station/repairs_panel.tscn:119` | footer states the fee rates as copy while `Repairs.HULL_CR_PER_POINTS`/`SHIELD_CR_PER_POINTS` own them (the refinery derives its footer from the module) | build the caption from the constants at runtime |
| 5 | minor | `game/exchange.gd:82-88`, `128` | `unit_gross` is dead in production (only a test calls it) and its comment promises a UI use no panel makes; 05 §2's "always shows the current price next to the baseline" is not met by §5.8's board (PRICE + DEMAND + TREND) | add a baseline cell, or drop `unit_gross` and amend 05 §2/§8 |
| 6 | minor | `game/exchange.gd:29-32`, `83`, `test_p1_pricing.gd:121-124` | 05 §2's raw-ore aside ("18 × 0.98 = 17") contradicts 05 §2's own `round()` formula and 05 §3's table (63.7 → 64); code implements round → 18 | code is right; fix the doc aside (it is the only 05 §3-family mismatch; see the derivation table below) |
| 7 | minor | `game/refinery.gd:13-16`, `100-105` | 04 §5 still says `remove_cargo(mineral_id, 4n)` and orders `spend` before `remove_cargo`; the module takes 3n and takes → pays → gives (01 §7 / 17 §5 order) | doc-only fix: 4n → 3n; state the law order so it is not re-litigated |
| 8 | minor | `game/exchange.gd:128`, `autoload/player_profile.gd:602` | 05 §8 names `exchange_price(id, is_ingot, is_component)` and market key `last_band_time`; shipped are `exchange_price(item_id, demand)` (kind inferred, demand required) and `last_band` (+ `queue`/`trend` buckets) | amend 05 §8 to the shipped shapes (renaming a persisted key needs a migration) |
| 9 | minor | `autoload/world_clock.gd:25-28` | `now()` is system Unix time, so bands accrue while the game is closed; 05 §2 says "every 20 minutes of real playtime" | amend 05 §2 to "real time", or switch to an accumulated playtime stamp when one exists |
| 10 | minor | `ui/screens/station.gd:242`, `430-434` | the rail's LOG OUT entry logs out directly; the `LeaveConfirm` overlay STATION_HUB §2/§5.5 requires is only reachable through the two-step `ui_cancel`. Inherited from `_mockup_station.gd:481`, so pre-P1 and outside the "rail extension" scope | `logout.pressed.connect(_open_leave_confirm)`; rename the direct handler for the dialog's button |
| 11 | minor | `ui/screens/_mockup_station.gd/.tscn` | the mockups still ship although the real screen landed (IMPLEMENTATION_PLAN §9.6, STATION_HUB §12.6 say delete them) | delete the mockup pair and its `.uid` |
| 12 | minor | `tests/test_p1_profile.gd:58-78` | `test_fresh_defaults_without_a_file` asserts the compile-time field defaults of an out-of-tree instance, so `_load_profile()`'s `ERR_FILE_NOT_FOUND` first-run branch and STATION_SPEC §2.8's defaults (owned ships `[ship_vanguard]`, 300 rounds × 5) are never asserted | call `reload()` on the fresh instance (as the migration test does) and assert the §2.8 set |
| 13 | nit | `autoload/world_clock.gd:38`, `game/refinery.gd:55` | deliberate `int/int` division trips Godot's `INTEGER_DIVISION` editor warning | `@warning_ignore("integer_division")` |
| 14 | nit | `ui/station/refinery_panel.gd:152-155` | `focus_primary()` calls `_refine_all_button.grab_focus()` without the `.disabled` check used one branch above | check `.disabled` and let the shell's rail fallback take over |
| 15 | nit | `ui/station/refinery_panel.gd:509-512` | the empty state replaces §5.7's unconditional footer with "BRING RAW ORE FROM THE BELT" (the amendment specifies an empty row, not a footer change) | keep the constant footer or amend §5.7 |

| # | severity | file:line | note (no defect in code) |
|---|----------|-----------|--------------------------|
| 16 | minor | `game/mineral_catalog.gd:26-27` | the catalogue is one data edit behind the art: ICONS_SPEC §8.1 says "Retire the 02 §6 fallback", and Phase F shipped `icon_mineral_<name>_{16,48}` / `icon_ingot_<name>_{16,48}` (20+20 verified on disk) while `icon_ore`/`icon_ingot` still point at the generic Phase B 48 px glyphs; 17 §2.1 also wants `_96` for new consumers. STATION_HUB §5.7/§5.8 and ICONS_SPEC §8.6 sanction the current tinted-stencil read, so this is an owner decision, not a bug (every referenced file exists) |
| 17 | minor | `game/*`, `autoload/*` | **reachability**: no production path puts ore in the hold (`add_cargo` is called only by `refinery.gd`, which consumes ore) and `game.gd`'s `mine` action still bumps the mock `cargo_used`, so REFINERY/EXCHANGE are only exercised with data from tests. 17 §1 assigns the mining flow to P3, so this is expected — but "P1 code-complete" is not "P1 playable end to end" |

## Derivation and transaction detail

**05 §3 table reproduced by hand from the shipped code** (`unit_net`, `exchange.gd:83` =
`roundi(baseline * demand * 0.98)`; baselines from `mineral_catalog.gd`):

| 05 §3 row | doc 1.0 / 0.6 / 1.6 | hand-derived | verdict |
|---|---|---|---|
| Iron 65 | 64 / 38 / 102 | 63.7 · 38.22 · 101.92 | match |
| Titanium 162 | 159 / 95 / 254 | 158.76 · 95.256 · 254.016 | match |
| Gold 395 | 387 / 232 / 619 | 387.1 · 232.26 · 619.36 | match |
| Krillum 2160 | 2117 / 1270 / 3387 | 2116.8 · 1270.08 · 3386.88 | match |
| Iron ore 18 (05 §2 aside) | 17 | 17.64 → 18 | **doc-internal conflict, finding 6** |

**05 §5 both worked examples** (`sale_quote`, `exchange.gd:103-106` = `roundi(baseline*demand*qty)`,
`commission_for` = `maxi(10, ceili(gross*0.02))`):
10 Gold ingots at demand 1.2 → gross 4740, fee 95, paid 4645 (doc: identical).
1 Torn Plating → `component_unit_price` (line 111) `roundi(12*0.9)` = 11, fee 10 (floor), paid 1 (doc: identical).
Also verified by hand: 05 §4 quotas 40/15/4 (`STOCK_QUOTA`, line 57), 05 §2 drift ±0.15 clamped
[0.6, 1.6] (`_drift_demand`, `370-377`), trade impact −0.01/unit floored at 0.6 (`_apply_trade`,
`357-358`), 01 §6 fee `(800/2)+(300/3)=500` (`repairs.gd:49-52`), 04 Iron case 3 ore + 15 CR → 1
ingot with 1–2 ore left untouched (`refinery.gd:44-47`, `82-116`), 11 §1.1 sector mixes
(`mineral_catalog.gd:266-274`, identical to the amendment), ICONS_SPEC §8.6 tints
(`259-264`, `192-196`), all 20 mineral and 18 component ids/values/units.

**Transaction law (17 §5) in all three modules.** `exchange.sell`/`sell_all`: evaluate → quote
(verify) → `remove_cargo` (take) → `add_credits` (pay, emits) → demand/stock/queue update →
`set_market` → one `SELL` line (+ a `QUEUE` line for surplus overflow) — exactly 05 §6.5's order;
a refusal returns before any mutation and writes no log line. `refinery.refine`/`refine_all`:
verify (mineral, count, ore, fee) → take → pay → give → one `REFINE` line, with an explicit
restore on the defensive failure paths; `refine_all` charges once, converts nothing if the total
fee is unpayable, and logs one combined line. `repairs.repair`: verify → pay → restore → log,
`REPAIR` with `+0` for the §6 free shield top-up. No negative balance is reachable
(`spend`/`_charge` guard, `add_credits` clamps at 0), no partial state survives a refusal
(asserted in the suites), and every event writes the six-field
`timestamp, event, item, qty, delta, balance` line (`economy_log.gd:17-25`).

## Looks correct (coverage)

- **Numbers:** 20 minerals × (ore, ingot, tier, units, id, icon) and 18 components × (value,
  family, grade, units, icon) match 02 §2/§3 and 03 §3/§4 cell for cell; tints match
  ICONS_SPEC §8.6; component icon families match 03 §3; grade means 19/47/113 hold.
- **One clock:** band math exists only in `world_clock.gd` (`BAND_SECONDS` 1200,
  `bands_between`); its only caller is `exchange.evaluate_market`, which runs on panel entry
  (`exchange_panel.gd:144`) and inside every quote/sale; no `Timer` anywhere for market/stock
  (the only two Timers in the reviewed tree are the spec'd save debounce and the launch arm).
  A stale/future/zero stamp never re-rolls.
- **No UI math:** every displayed price/fee/stock/quota is an `Exchange`/`Refinery`/`Repairs`/
  catalogue read; the only rate-shaped string in UI is finding 4 (spec copy). `QTY` is the
  sanctioned `Exchange`-free `cargo_qty` read.
- **Persistence:** the frozen `PlayerProfile` API is intact and un-regressed; the new
  `modules`/`fits`/`standing` emit, every other new key is silent (17 §3); getters return deep
  copies (`cargo_items`, `owned_ships`, `installed_upgrades`, `modules`, `fits`, `standing`,
  `market`, `heat`, `contracts`, `vaults`, `vitals_of`); v1 loads with per-key defaults, emits
  nothing, and leaves the file at `save_version` 1 until a real change; writes always persist
  v2; a wrong-typed or unparsable field degrades per field. The owner's live `profile.cfg` was
  inspected and shows the v2 shape with all §3 keys plus `vitals`.
- **Panel contract:** all three panels expose `status_requested` / `refresh_profile` /
  `focus_primary` (`disarm` on refinery and exchange, correctly optional elsewhere), emit no
  new signals, build rows to the measured grid (76 px, 12/8 inner margin, 130/110/160 in the
  refinery, §5.8's corrected 70/80/100 · 80/60/95 · 80/130/60 in the exchange), keep 340/360/560
  columns, 48 px steppers, 88 px primary actions, 220/500 widths from §12.3/§5.8, use only theme
  items that exist in `vajb_theme.tres`, bake no theme, add no Timer, and route every number
  through the modules. Refusal copy follows §5.6 (strip + cue + pulse, focus and selection kept).
- **Shell integration:** `Module` has exactly 7 members in §2's order and `MODULE_FILES` /
  `MODULE_LABELS` / `MODULE_ICONS` / `MODULE_TINTED` / `MODULE_BEDS` are all length 7 in that
  order; cycling wraps over the 7 modules and skips LOG OUT; `station.tscn` holds no pane nodes
  and correctly needed **no** edit from the panel wave (the shell loads panels by naming
  convention and degrades to a marked placeholder), so §12.1's "instances the four panels" is
  superseded — worth an amendment note.
- **`game.gd`:** vitals seeding is null/type-guarded, clamps to the in-space maxima, falls back
  to full pools with no record, and the dock report is filed before the unchanged
  `route_requested(loading, station)` emit. Finding 1 is the maxima source, not the wiring shape.
- **Tests:** the 17 §6 checklist items are all present and asserted with exact numbers, not
  `> 0` (05 §3 table, both 05 §5 examples, the 04 iron case, the full v2 round trip, the v1
  migration read that leaves the file at v1); suites redirect `save_path` and
  `EconomyLog.log_path` before the first mutation and never add a profile to the tree, so
  `user://profile.cfg` and `user://economy_log.txt` are untouched (verified: no
  `user://test_p1_*` leftovers exist, and no `economy_log.txt` has ever been written).

## Limits of this pass

- I did not run the editor or any Godot binary (per the brief), so the suite verdict is static
  plus the sibling's evidence log: `.agents/gen/p1l_run.txt` (`[SUMMARY] passed=51 failed=0`,
  written after the last suite edit). `test_p1_market.gd` changed **during** this review
  (12:34, added `_deep_eq`) and was re-read; the other three WIP suites were unchanged.
- Panel geometry is reviewed against §5.8/§12.3 constants and scene values, not pixels; P1i's
  1920×1080 measurements are taken on trust.
- No placeholder item remains outside `station.gd`'s offline path, and no `*_probe*` file
  survives in the project.
- The workspace is not a git repo, so "was `project.godot`/`addons/` touched" cannot be
  diffed; the current file was read instead — `WorldClock` and `PlayerProfile` autoloads
  present (required by 17 §2/§4), main scene and input map unchanged, no `addons/` edit found.
- Owner data note (from P1i's disclosure, confirmed in the file): the owner's
  `user://profile.cfg` already carries a stamped `market` section (last_band 1789727439, one
  band of drift, stock at quota). That is exactly what the game writes on a first station
  entry, so it needs no action — but a later "fresh profile" check must not treat it as pristine.
