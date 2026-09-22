# P2-B proper — W2 report: the FITTING pane and the rail swap

**Role:** W2 (coder — the FITTING pane). **Files changed:** `vajb-orbit/ui/station/fitting_panel.gd` +
`fitting_panel.tscn` + `.gd.uid` (new), `vajb-orbit/ui/screens/station.gd`, the retired
`vajb-orbit/ui/station/upgrades_panel.gd` / `.gd.uid` / `.tscn` (deleted), and `vajb-orbit/tests/`
(`test_p2b_fitting_panel.gd` + `.uid`, `probe_w2_fitting.gd` + `.uid` + `.tscn`, `probe_w2_lint.gd` +
`.uid` + `.tscn`). **Nothing else touched:** no assets, no theme, no `project.godot` (`git diff --stat
vajb-orbit/project.godot` is empty), no `addons/`, no `docs/`. Everything below is measured on this host
(Godot 4.7.2.stable, Linux), with the command and the raw line it produced.

**Headline numbers.**

| Measure | Value |
|---|---|
| Gate before (sandboxed `user://`, this host) | `[SUMMARY] passed=402 failed=0`, exit 0 — reproduces W1's figure |
| Gate after (same command) | `[SUMMARY] passed=420 failed=0`, exit 0 |
| Growth | **+18** (one new suite, `test_p2b_fitting_panel`, 18 tests) |
| `SCRIPT ERROR` rows in the gate log | **5 → 1**: the four `station.gd` parse failures W1 reported (its §7 blocker) are cured; the survivor is the pre-existing freed-instance row (`tests/test_weapon_fx_f4.gd`, LOW L61) |
| Lint ledger, the four files this pass owns | **0 warning rows**; positive control `game/weapons.gd` **3**, negative control `autoload/world_clock.gd` **0** |
| Vanguard grid (08 §3.2 `.WW.`/`HSCB`/`HWU.`/`.EP.`) | 16 cells, **11 plates, 5 gap `Control`s**, `columns` 4, `h`/`v` separation **4**, cells **48 px**, glyphs **36 px** inset 6, caption `SLOT LAYOUT · 11 CELLS · 1 ENGINES` |
| FITTING grid vs the shipyard's, cell for cell | **16/16 same size, 16/16 same plate art** (the same theme `SlotButtonWeapon` textures), same glyph file, same separations, same caption |
| The focus ring on a cell | `StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1)` — the theme's shared `accent_danger_bright` ring |
| Focus walk, W1 selected | 11 cells (`SlotW00 … SlotP00`, row-major) → 2 rows → `RemoveButton`; `FittingScroll.focus_mode` **0**, so nothing else in the pane is a stop; `focus_primary()` lands on `SlotW00` |
| **One finding, outside W2's file set and the pin's rule 5** | on an account with **no stored fit** for the active hull the pane previews `legal=true, missing=[]` and offers `FIT`, while `fit_module_at` returns **false** (its candidate comes from the stored fit, which is missing engines + power). See §6. |

---

## 1. What landed (STATION_HUB §5.3, CONTRACTS §13 rule 5)

**The rail.** `ui/screens/station.gd`: `Module.UPGRADES` → `Module.FITTING` (index **4**, the retired
entry's position), `MODULE_LABELS[4] = "FITTING"`, `MODULE_FILES[4] = "fitting"`, and the icon
(`res://assets/icons/equip/icon_equip_generator_48.png`), the tint (`false`) and the bed
(`amb_station_noise_loop_01`, §11's "kept under the new label") are the retired entry's own, untouched.
`ui/station/upgrades_panel.gd` / `.gd.uid` / `.tscn` are deleted. W1's §7 blocker is cured with the same
retirement: `_owned_state_text`'s `Catalog.upgrade(id)` branch (W1's item 1 — the fallback `ALREADY OWNED`
now stands alone) and `_entry`'s upgrade step (item 2 — ammo → ship → module is the resolution order that
remains) are gone.

**The pane** — the §5.1 host-pane construct, two stacked sections and one footer strip that is always
visible:

| Part | What it reads | Rendered form |
|---|---|---|
| `PaneHeader` | the active hull (`PlayerProfile.active_ship` → `StationCatalog.ship`) | title `FITTING`, the retired UPGRADES pane's own icon, the shipyard's own tag string `ACTIVE HULL <NAME>` |
| `SLOT LAYOUT` | `ShipFit.grid_cells/grid_size/grid_counts(hull)` | the shipyard's recipe, cells **selectable** |
| `OWNED MODULES` | `PlayerProfile.modules()` aggregated through `base_module_id`, `module_count(id)`, `ModuleCatalog` | one 76 px row per owned id: 48 px icon, name, meta `SLOT <TYPE> · DRAW <n>`, `OWNED ×<n>`, ACTION |
| `PaneFooter` | `ShipFit.fit_legal(hull, fit)`, the selection, `fit_for` | the power meter, the selected cell's line, the per-cell `REMOVE` |

**Writes.** The pane calls exactly two profile writers, both composed, both requested:
`PlayerProfile.fit_module_at` (install *and* swap) and `clear_fit_slot` (remove). Every candidate is
judged with `ShipFit.fit_legal` first — the same function the profile re-checks on commit — so a refusal
writes nothing. `test_the_pane_writes_only_through_the_two_composed_calls` is the standing guard: it reads
the pane's source and asserts the two ids are the only profile calls in it (no `set_fit`, `set_fit_slot`,
`clear_fit`, `add_module`, `take_module`, `buy_module`, `spend`, `add_credits`, `install_upgrade`,
`buy_ship`, `buy_ammo`).

**The ACTION states** (measured on the live pane, `probe_w2_fitting.log:50-54`):

| Selection | ACTION on a weapons row | ACTION on the engines row | Footer line | REMOVE |
|---|---|---|---|---|
| nothing | `SELECT A CELL` (all rows) | `SELECT A CELL` | `SELECT A CELL` | disabled |
| `weapons 0` (holds a laser) | `SWAP` | `SELECT A CELL` | `W1 · LASER MKII · OWNED ×1` | offered |
| `weapons 1` (empty) | `FIT` | `SELECT A CELL` | `W2 · EMPTY · OWNED ×0` | disabled |
| `engines 0` (holds `e_std`) | `SELECT A CELL` | `SWAP` | `E1 · STANDARD DRIVE · OWNED ×0` | offered |
| `shields 0` | `SELECT A CELL` | `SELECT A CELL` | `S1 · LIGHT SHIELD · OWNED ×0` | offered |

**The meter**, in the pin's three forms (measured, `probe_w2_fitting.log:56-61`):

- idle: `PWR 3 / 8` with `fit_legal`'s own `{out 8, draw 3, spare 5, legal true}` for the delivered
  Vanguard fit;
- candidate: `PWR 3 / 8 · CANDIDATE 4 / 8` after reading the cannon row on an empty W2 (the cannon's
  draw 1 replaces nothing);
- over budget: `PWR 6 / 6 · CANDIDATE 8 / 6 — OVER BY 2` in the theme's `accent_danger`
  (`(0.7843, 0.2784, 0.1216)`, equal to `Tokens/accent_danger`), with the refusal beside it.

**The three pinned refusals** (all reachable, all measured): `8 / 6 PWR — OVER BY 2` (the candidate's own
`fit_legal` numbers through §5.1's over-by format), `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` (a press on
the E cell's REMOVE, danger colour), and `REFUSED · FIT ILLEGAL` (the catch-all — its reachable case is an
unfit account, §6). The footer is never blank: the meter always carries a line and the selection line
falls back to the pin's own `SELECT A CELL`.

## 2. The five judgement calls the pin left open

Each is one constant or one branch, with its reversal.

1. **Where the per-cell remove lives.** §5.3 names `clear_fit_slot` as the per-cell remove and pins the
   mandatory refusal, but names no control for it; §10's focus order ends with "the pane's own footer".
   The footer strip therefore carries a `REMOVE` `StationButton` (the OUTFITTING strip's own word and
   160 × 48 plate) that acts on the selected cell, and it is the footer's one focus stop. It is offered
   only when the selected cell holds a module, and a mandatory cell answers the pinned wording rather
   than being disabled (the pin's words are what explain it). **Reversal:** drop the control and its
   `_on_remove_pressed`; `clear_fit_slot` then has no door on this surface.
2. **The candidate's source.** The meter's candidate is the module the player is reading — the focused or
   hovered OWNED MODULES row (a press reads it too, so a refused press leaves the arithmetic that refused
   it on screen); with no row being read the candidate is the selected cell's own module, i.e. the
   pin's line renders as a no-change preview (`PWR 3 / 8 · CANDIDATE 3 / 8`). A row whose type is not the
   selected cell's type never becomes the candidate. **Reversal:** one branch in `_candidate_power`.
3. **The rows are keyed by base id.** `modules()` keys are aggregated through the profile's own
   `base_module_id` and summed, so one row per id (the pin's words) whether the inventory holds a base id
   (today) or an instance id (15 §6's next wave); an id the catalogue cannot name never becomes a row.
   **Reversal:** iterate `modules()` keys directly once affixes create instances.
4. **The grid is not rebuilt while the matrix has not moved.** The grid is a function of
   `ShipFit.grid_cells(hull)`, so a `&"fits"`/`&"modules"` refresh re-reads its selection marker without
   freeing its cells — which is what keeps a cell selected across the very transaction the player just
   made (measured: `selected_cell()` is `{weapons, W, 1}` after the install into W2). A hull switch
   (`&"ships"`) rebuilds it from the new matrix and clears the selection. **Reversal:** drop the
   `_grid_hull` guard in `_sync_grid` to rebuild per key.
5. **The one alias the catalogue forces.** `ModuleCatalog` spells an engine module's slot `engine`
   (09 §1's singular type name) while the fit's set key is `engines` (`ShipFit.FIT_SLOT_KEYS`) — the same
   pair `ShipFit._engine_slot` already bridges. `SLOT_KEY_ALIASES = {&"engine": &"engines"}` is that one
   table, so a thruster row can target an ENGINE cell and the ordering can walk `FIT_SLOT_KEYS` and
   nothing else. **Reversal:** delete the table once the catalogue spells the slot `engines`.

Also reused rather than re-invented: the OUTFITTING pane's C16 icon rule (three flat weapon glyphs read
as near-black, so `w_cannon`/`w_mine`/`w_plasma` draw the derived `icons/tint/` stencil at
`text_primary` × 0.72 — measured on the row list, `probe_w2_fitting.log:47`) and its `_resolved_fit`
resolution (`fit_for`, else `ShipFit.standard_fit` — the same resolution `game.gd:_launch_fit_for`
launches with, so the meter cannot promise a budget the launch would not fly).

## 3. The grid is the shipyard's recipe, measured cell for cell

The pane duplicates the recipe rather than lifting it into a helper (W2's file set holds no shared file
and the pin allows a byte-equivalent duplicate). Both grids were mounted side by side with the same hull
and the same theme and compared cell for cell (`probe_w2_fitting.log:23-39`):

```text
[W2-FITTING] hull=ship_vanguard matrix=(4, 4) cells=16 gaps=5 columns=4 plates=11
[W2-FITTING] grid separations h=4 v=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[W2-FITTING] shipyard cells=16 columns=4 h=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[W2-FITTING] recipe cell 01 same_size=true same_art=true mine=Button theirs=TextureButton art=res://assets/ui/ui_slot_weapon_normal.png
... (16/16 same_size=true same_art=true) ...
[W2-FITTING] focus stylebox on a FITTING cell: StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0)
```

The one difference the pin asks for is selectability, and it is the one difference the probe finds: a
slot cell is a `Button` carrying the theme's `SlotButtonWeapon` variation (`FOCUS_ALL`, `toggle_mode`,
not `disabled`), so it draws the same four plate textures out of the theme **and** the theme's shared
focus ring, where the shipyard's display is a `disabled` `TextureButton` with `focus_mode NONE`. The
pressed plate is the selection's second channel; a gap stays an empty 48 × 48 `Control` in both panes.

## 4. Tests (18, all new; the brief's file is `tests/test_p2b_fitting_panel.gd`)

The suite mounts the shipped scene with the shipped theme and drives it through the shell's own wiring
(a row's `pressed`, the profile's `profile_changed` → `refresh_profile`), borrowing the shipped autoload
with `save_path` repointed at a scratch file and handing every field back in `suite_teardown` (L17).

| Test | Subject |
|---|---|
| `test_the_rail_entry_is_fitting_and_the_upgrades_pane_is_gone` | the rail swap on the script's tables **and** on the assembled shell (the 5th entry `FittingEntry`, its label, the retired icon, the `Fitting` pane under `%HostMargin`, no `Upgrades` pane, both retired files gone) |
| `test_the_grid_renders_the_active_hulls_cells_with_gaps` | one child per matrix cell, `columns`, 48 px, gaps plate-less, plate names, `FOCUS_ALL`, the glyph per type, the 6 px inset, the caption's own counts |
| `test_the_grid_is_the_shipyards_own_recipe` | the two grids cell for cell: count, columns, separation, size, glyph file, the theme's plate art per state, the caption |
| `test_an_npc_hull_draws_no_cells` | no matrix → no cells, empty caption, the meter still reads |
| `test_the_owned_rows_are_the_inventory_in_pin_order` | `FIT_SLOT_KEYS` then catalogue order (re-derived in the test), title, meta, `OWNED ×<n>`, the non-catalogue/zero-count exclusion |
| `test_the_empty_state_is_one_disabled_pinned_row` | one disabled row carrying `NO MODULES OWNED · BUY THEM IN OUTFITTING`, no module rows |
| `test_the_action_states_are_fit_swap_and_select_a_cell` | `FIT` / `SWAP` / `SELECT A CELL` per selection, and that a `SELECT A CELL` press writes nothing and says so |
| `test_a_per_cell_install_lands_on_the_cell_it_was_given` | W2 takes the cannon, W1/W3 untouched, the inventory moves, the selection survives |
| `test_a_swap_returns_the_displaced_module` | W1 swaps, the displaced laser is back in the inventory, the other cells untouched |
| `test_a_mandatory_cell_refuses_with_the_pinned_wording` | the E cell's REMOVE refuses with the pinned wording (danger, in the shell's strip too), the fit untouched; the same cell then *swaps* to `e_ion`; a shield cell empties through the composed remove |
| `test_remove_is_offered_only_for_a_filled_cell` | the `REMOVE` gate |
| `test_the_meter_numbers_are_fit_legals_power_dictionary` | the idle meter equals `fit_legal`'s own `power` for the resolved fit, and follows a fit write |
| `test_an_over_budget_candidate_is_the_danger_form` | the candidate line, `— OVER BY <n>`, the danger colour = `Tokens/accent_danger`, the over-by refusal, nothing written, the module still owned |
| `test_the_footer_line_reads_the_selected_cell` | `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`, the idle word, the two pinned constants |
| `test_profile_changed_drives_the_refresh` | `&"modules"` grows a row, `&"fits"` moves the meter, `&"ships"` rebuilds the grid and the caption |
| `test_a_credit_change_does_not_rebuild_the_rows` | `&"credits"` is another pane's business (the row node survives) |
| `test_the_focus_order_is_cells_then_rows_then_footer` | the walk is cells → rows → footer, the scroll is not a stop, `focus_primary()` rings `SlotW00` |
| `test_the_pane_writes_only_through_the_two_composed_calls` | the write discipline (§1) |

No existing assertion was deleted: the retired UPGRADES surface's assertions left with W1's retirement
(`test_p1_profile.gd`), and W2's suite adds only new subjects.

## 5. Evidence

```text
# sandboxed user:// (a scratch XDG_DATA_HOME), before any edit:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=402 failed=0                                # exit 0, 5 SCRIPT ERROR rows

# after:
[SUMMARY] passed=420 failed=0                                # exit 0, 1 SCRIPT ERROR row
#   test_p2b_fitting_panel 18 · test_p2b_retirement 13 · test_p2b1_outfitting_panel 9 (unchanged elsewhere)

# the suite alone:
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_p2b_fitting_panel
[SUMMARY] passed=18 failed=0                                 # exit 0

# the pane measured in memory:
godot --headless --path vajb-orbit res://tests/probe_w2_fitting.tscn --quit-after 600
[W2-FITTING] done                                            # exit 0, 67 measurement lines

# the warning ledger:
godot --headless --debug --path vajb-orbit res://tests/probe_w2_lint.tscn --quit-after 600
[W2-LINT] debugger_active=true
fitting_panel.gd 0 · station.gd 0 · test_p2b_fitting_panel.gd 0 · probe_w2_fitting.gd 0
POSITIVE-CONTROL weapons.gd: 3 WARNING rows   NEGATIVE-CONTROL world_clock.gd: 0
```

Logs: `.agents/gen/p2b_proper_w2_gate_before.log`, `p2b_proper_w2_gate_after.log`,
`p2b_proper_w2_suite.log`, `p2b_proper_w2_probe.log`, `p2b_proper_w2_lint.log`.

### 5.1 The pane in the live station (godot-ai, the owner's own profile)

`scene_open(res://ui/screens/station.tscn)` → `project_run(mode="current")` → a click on the rail and on
cells, read with `editor_screenshot(source="game")` at 1152 px. Measured in the frames:

- the rail's fifth entry is **FITTING** with the retired generator icon, in the retired position;
- the pane's header reads `FITTING` / `ACTIVE HULL VANGUARD`, and the section caption
  `SLOT LAYOUT · 11 CELLS · 1 ENGINES` sits over a 4 × 4 grid whose 11 plates carry their slot glyphs
  and whose 5 gaps are empty cells; the clicked cell draws the **orange 1 px focus ring**;
- `OWNED MODULES` shows the account's own inventory (one `Laser MkII` row, `SLOT WEAPONS · DRAW 1`,
  `OWNED ×3`, `SWAP`) and the meter reads `PWR 5 / 8 · CANDIDATE 5 / 8` for the live fit;
- clicking a **U** cell turns the row's ACTION into `SELECT A CELL` and **disables** `REMOVE` (an empty
  cell has nothing to return);
- clicking the **E** cell and pressing `REMOVE` renders `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` in the
  pane's footer **and** in the shell's status strip (danger colour), with the cell still filled.

## 6. One finding, and it is the pin's, not W2's

**Measured on an account that holds no fit for the active hull** (a fresh profile; every hull's fit is
`fit_for`'s all-empty shape until something writes one — nothing in the shipped tree writes one except
the OUTFITTING pane's own `_seed_fit`):

```text
[W2-FITTING] unfit hull: pane preview legal=true missing=[] | stored candidate legal=false power={ &"out": 8, &"draw": 1, &"spare": 7, &"legal": true } | fit_module_at=false
[W2-FITTING] unfit hull: meter=PWR 3 / 8 · CANDIDATE 3 / 8 line=W2 · EMPTY · OWNED ×0 action=FIT
```

The pane previews the fit the launch flies (`fit_for` → `standard_fit`, `game.gd:_launch_fit_for`'s own
resolution) and offers `FIT`; `fit_module_at` composes its candidate from the **stored** fit
(`fit_for`, CONTRACTS §13), which for an unfit hull is missing engines + power, so it refuses and the
player sees `REFUSED · FIT ILLEGAL`. Playing the surface therefore needs an account whose active hull
already carries a stored fit — which today only OUTFITTING's own install path materialises. The
`REFUSED · FIT ILLEGAL` wording is not dead (this is its reachable case), but the first install on a
fresh account is.

W2 cannot cure it: the pin's rule 5 lists the calls the pane may make and `set_fit` is not among them
(that is exactly what "the pane never mutates directly" means), the file that would have to change is
`autoload/player_profile.gd` (W1's set, and `fit_module_at`'s candidate source is CONTRACTS §13 itself),
and the other candidate — the pane seeding the standard fit the way OUTFITTING's `_seed_fit` does — is
P2-B1's precedent but a pin change. **Two reversal paths, both outside W2's file set:** (a) let
`fit_module_at`/`clear_fit_slot` compose their candidate from `fit_for` **falling back to
`ShipFit.standard_fit`** when the stored fit holds no module — the same resolution
`game.gd:_launch_fit_for` and this pane already use, and the pane's preview then agrees with the commit;
or (b) pin the pane's own seed (`PlayerProfile.set_fit(hull, ShipFit.standard_fit(hull))` before the
first write, the OUTFITTING pane's `_seed_fit` shape). Either is a D0 + W1 change, so this report leaves
the number where the pin puts it and names the finding.

## 7. Notes for R1 / the fixer

- **Re-run byte-identically:** the four logs above, in order; `probe_w2_fitting` is read-only apart from
  borrowing the autoload the same way the suite does (it flushes and restores in `_return`, and deletes
  its scratch file).
- **Drift checks worth making:** `CONTRACTS.md` §13 rule 5 against the pane's source (the token guard in
  the suite is the cheap one); §5.3's five pinned strings against `PanelScript.REFUSAL_*`,
  `ACTION_SELECT`, `METER_*`, `SELECTION_FORMAT`; `station.gd`'s `MODULE_LABELS`/`MODULE_FILES` against
  the rail the shell builds; `ShipFit.FIT_SLOT_KEYS` against `test_p2b_fitting_panel`'s own re-derivation.
- **Two things outside W2's file set, left alone deliberately:** `ui/screens/station.tscn:298`'s
  leave-confirm body still says "…and upgrades are saved automatically" (the owner's copy pass, one
  word) and the Phase C mockups `ui/screens/_mockup_station.gd`/`.tscn` still carry their own local
  `UPGRADES` rows (§12.6 deletes them when the real screen lands). Neither is a live reference to the
  retired surface.
- **`ui/station/upgrades_panel.*` is deleted, not emptied** — `git status` shows three deletions and no
  dead branch anywhere in the pane (no `upgrade` token survives in `fitting_panel.gd` or `station.gd`).
- **The `_grid_hull` guard** (§2 item 4) is the one place the pane's refresh is narrower than §12.4's
  wording ("`&"fits"` and `&"modules"` **rebuild** FITTING's grid…"): the rendered grid cannot differ
  while the matrix has not moved, and rebuilding it would drop the player's selection on every install.
  If the reviewer reads §12.4 literally, the fix is to drop the guard and re-select by
  `(slot_key, index)` after the rebuild — one branch.
- **A hole W1 flagged and this pane does not close:** `fit_module_at` does not check that a module's own
  slot matches the cell's type (measured by W1, §8). The pane gates by type itself (`_row_target_cell`),
  so the surface cannot express a mismatched write — but the profile API still can, and the alias in §2
  item 5 is what lets a legitimate engine swap through.

## 8. Reversal paths

- **The rail:** restore `Module.UPGRADES`, `MODULE_LABELS[4] = "UPGRADES"`, `MODULE_FILES[4] =
  "upgrades"` and the two retired pane files (`git show HEAD:vajb-orbit/ui/station/upgrades_panel.gd`),
  and put back `_owned_state_text`'s upgrade branch and `_entry`'s `Catalog.upgrade(id)` step.
- **The pane:** delete `fitting_panel.gd`/`.tscn` (the rail then synthesises a placeholder for a missing
  scene, STATION_HUB §12.1) — no other file references it.
- **Each judgement call:** §2's five reversals, one branch or one constant each.
- **The strings:** every wording lives in one `const` at the top of the pane (or is the pin's own
  constant), so a copy change is one line; the empty-state and meter forms are the pin's.
