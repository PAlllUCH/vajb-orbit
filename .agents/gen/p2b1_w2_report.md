# P2-B1 — W2 report: the OUTFITTING panel (the MODULES section and the FITTED WEAPONS strip)

**Worker:** W2 (coder — the panel). **Wave:** P2-B1 — the weapon fit surface.
**Brief (law):** `.agents/gen/p2b1_weapon_fit_wave_task.md` §3 (the pin) + §4 row W2 + §5 + §6.
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/ui/station/outfitting_panel.gd`,
`vajb-orbit/ui/station/outfitting_panel.tscn`, `vajb-orbit/tests/`. Two shipped files changed,
one suite and one probe created; **no** `assets/**`, no theme, no `project.godot`, no
`addons/**`, no `docs/**`.
**Status:** complete. The gate is green and grown (**380 → 387**, `failed=0`, exit 0); the
surface is the pin's six rows, four states and four actions, both refusal wordings render
byte-exactly in the panel's own footer strip, every fit write goes through the profile's APIs
behind `ShipFit.fit_legal`, and no number was invented.

---

## 1. Files changed

| File | Change |
|---|---|
| `vajb-orbit/ui/station/outfitting_panel.gd` | **+727 / −60** (558 → 1 225 lines): the MODULES section, the FITTED WEAPONS strip, the four actions, the two refusals, and the header-fit pass generalised from one column header to two. The ammo construct's behaviour is untouched (the deletions are the replaced doc header, the replaced `_fit_header`/`_connect_layout`/`_apply_tokens` blocks and three widened signatures — §11). |
| `vajb-orbit/ui/station/outfitting_panel.tscn` | **+58 / −8** (75 → 125 lines): the scroll now holds an `OutfittingBody` with the strip, the `MODULES` caption and header, the module rows, then the ammo header and rows in that order; the two captions are `SectionHeader` labels. |
| `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` | **new**, 630 lines, 7 tests: the row set against 09 §3.1 parsed out of the document, the strip against the hull's own W cells, the buy→install→swap→remove round trip, the power-overload refusal, the full-cells refusal, the mandatory set, and the signal-driven refresh. |
| `vajb-orbit/tests/probe_p2b1_panel_fit.gd` + `.tscn` | **new**, 281 lines: the re-runnable evidence probe (54 `[probe]` lines) — mount the shipped pane, drive the whole surface, print every number below. |
| `.agents/gen/p2b1_w2_report.md`, `p2b1_w2_gate.txt`, `p2b1_w2_probe.txt`, `p2b1_w2_suite.txt` | this report and its raw captures. |

`git status --short` lists my three code/test files and my probe scene plus these four captures;
the four modified `docs/**` files are **D0's** and the two `player_profile.gd` /
`test_p1_profile.gd` changes are **W1's**, untouched by this pass.

## 2. What the pane now is

Render order, top to bottom, one `ScrollContainer` (STATION_HUB §5.1's amendment):

```text
FittedCaption   "FITTED WEAPONS"                      (SectionHeader)
FittedStrip     one line per W cell of the active hull: "W1 LASER MKII" | "W2 — EMPTY"
                                                        + REMOVE on the fitted lines only
ModulesCaption  "MODULES"                             (SectionHeader)
ModulesHeader   MODULE | EFFECT | PRICE | STATUS | ACTION
ModuleRows      09 §3.1's six rows (48 px icon, name, "W SLOT · DRAW n", effect, price,
                status, action)
OutfittingHeader  PACK | HELD / MAX | PRICE | STATUS   (unchanged ammo construct)
OutfittingRows   the five ammo packs (unchanged)
```

The pane's contract with the shell is unchanged (`status_requested` up,
`refresh_profile(key)` down, `focus_primary()`), plus three read-backs a probe can use:
`module_row_ids()`, `module_action(id)`, `fit_index_of(id)`, and the four action entry points
`buy_module` / `install_module` / `swap_module` / `remove_module`.

**The panel never mutates state itself** (CONTRACTS §12 rule 2, STATION_HUB §12.4). Every
profile touch is a public API call — `can_afford`, `credits`, `module_count`, `fit_for`,
`base_module_id`, `active_ship`, `buy_module`, `take_module`, `add_module`, `set_fit_slot`,
and `set_fit` for the seed (§5) — and `grep -n "profile\.set\|_profile\.set"` over the panel
is empty. Reads are `ShipFit` (`grid_cells`, `slot_capacity`, `standard_fit`, `fit_legal`,
`HULLS`, `FIT_SLOT_KEYS`) and `ModuleCatalog` (`module`, `slot_of`).

## 3. The row set — 09 §3.1's six, in its own order

The brief's §3 bullet 1 says *six* weapon rows and then lists **seven** ids (D0 finding 1).
This pass renders **09 §3.1's table: six rows**, because that reading satisfies the bullet's
own prose — *six* rows, *in 09 §3.1's table order*, each showing *the 09 §3.1 effect text* —
while the seven-id reading breaks all three (09 §3.1 has no `w_mining` row and therefore no
effect prose for it). The owner's own dispatch repeated "six weapon rows in 09 section 3.1's
order", and D0's §2 rail edit already records the pane's payload as "6 weapon modules + 5 ammo
packs".

Measured (probe line 4 and the doc parse in `test_module_rows_are_09_3_1s_table_in_order`):

```text
[probe] MODULES rows=6 w_laser=900/draw1 w_cannon=1200/draw1 w_rocket=2400/draw2
        w_mine=1800/draw1 w_plasma=4800/draw3 w_railgun=5200/draw3
[probe] catalogue weapon ids=7 (the row set is 09 section 3.1's table)
```

`ModuleCatalog` ships **seven** weapon-slot ids; `w_mining` (600, draw 1, 09 §4 item 7) is the
one this surface does not sell. The suite parses 09 §3.1's table out of
`docs/gameplay/09_ship_slots_modules.md` (id, draw, cost, effect prose — costs with the
document's thousands space) and compares it with the catalogue **and** with the rendered cells,
so the six and their numbers cannot drift from the pin.

**Reversal / open reading for R1 and the owner (one line each).** `MODULE_ROWS` in the panel
is the only list; adding a seventh row is `&"w_mining"` in it plus one transcribed string in
`EFFECT_TEXT` (09 §3.1's own note reads *"The mining laser (`w_mining`, §4 item 5) is family
tool with shield rule rocks only"*), and `buy_module` (W1's seam) already sells any catalogue
id, so no other change is owed. Until then the mining laser has no door on this surface, which
is the one functional consequence of the six-row reading and the reason it is flagged here
rather than decided silently.

## 4. The state machine

STATUS is the pin's, in its order (measured on the shipped pane):

| State | Rendered | Condition |
|---|---|---|
| fitted | `FITTED (Wk)` | the active hull's W cell *k* holds this module (k = the layout index + 1) |
| owned | `OWNED ×n` | not fitted and `module_count(id) = n > 0` |
| for sale | `FOR SALE` | not owned and `can_afford(cost)` |
| locked | `LOCKED` | not owned and unaffordable (the price cell also takes `accent_danger`) |

ACTION is the pin's chain, one state per row, chosen by (empty W cell exists, fitted index,
inventory count):

| ACTION | Condition | Effect |
|---|---|---|
| `BUY` | a cell is empty and the account holds none, or no cell is empty and it holds none | `PlayerProfile.buy_module(id, catalogue cost)` |
| `INSTALL` | a cell is empty and the account holds one | `set_fit_slot(hull, weapons, first empty cell, id)` + `take_module(id, 1)` |
| `SWAP` | no cell is empty, the module is not fitted and the account holds one | the same write into **W1** (index 0) + `take_module(id, 1)` + `add_module(displaced, 1)` |
| `REMOVE` | no cell is empty and the module *is* fitted | `set_fit_slot(hull, weapons, index, "")` + `add_module(base_module_id(cell), 1)` |

Three readings this pass had to fix, each with its reversal:

1. **A fitted module is not pinned to REMOVE.** 09 §4 item 4 lets a weapon repeat ("armour,
   shields, weapons and utility modules may repeat"), so while a W cell is empty a fitted
   module's row offers `INSTALL` (a second copy) or `BUY` (a spare), and `REMOVE` is the
   *full-grid* state — the last state of the pin's chain, where taking the module off is the
   only thing left to do. Reversal: return `REMOVE` for any fitted module (one line in
   `module_action`), which makes a two-cannon fit impossible to build from this surface.
2. **SWAP targets W1.** The pin fixes INSTALL to the first empty cell and gives SWAP no cell;
   owner tick 3 defers the per-slot picker to P2-B proper, so SWAP takes the same first cell
   (`SWAP_INDEX := 0`) rather than inventing a second rule. Reversal: pass another index —
   `swap_module(id, index)` already takes one.
3. **A fit refusal is 09 §2's overload line, and there is a third, unreachable guard.**
   `_refuse_fit` renders the overload whenever the candidate's power budget is the failing
   part, else `REFUSED · FIT ILLEGAL` (a fit that arrived already over capacity, or missing a
   mandatory key, which no W-cell write can produce: a cell is written in place, the mandatory
   set is untouched, and 09 §4 item 4 guards engines and computers, not weapons). Reversal:
   drop the guard branch and always render the overload.

## 5. The write path: seed, then the cell

`PlayerProfile.set_fit_slot` writes one cell of the hull's **stored** fit, and a hull the
account holds no fit for is normalised from nothing. Measured on a throwaway profile (probe
lines 1–3), because it is the whole reason the seed exists:

```text
[probe] bare set_fit_slot(weapons, 1, w_cannon) on a hull with no fit:
[probe]   engines=[""] power= weapons=["", "w_cannon", ""]
[probe]   fit_legal: legal=false missing=[&"engines", &"power"]
```

A bare write would therefore leave a fresh account's Vanguard holding one cannon and **no
mandatory set** — an unlaunchable fit. So every install, swap and remove calls `_seed_fit`
first, which writes `ShipFit.standard_fit(hull)` when the account holds no fit for that hull.
That seed is not a new rule: it is exactly the fit `game.gd:_launch_fit_for` already flies in
that case, so the pane and the launch agree, and the seed is a no-op once a fit exists
(measured: after the round trip `engines=["e_std"] power=p_std missing=[]`).

Order inside each action follows 17 §5: verify (`ShipFit.fit_legal` on the candidate, plus the
inventory count) → take → write → give back (the displaced module) → emit → (no log line: a
swap is free, 09 §4 item 8, and only `buy_module` writes one, W1's seam). A write that fails
after the take hands the module straight back, so nothing is lost in either direction.

## 6. The two refusal wordings, measured

Both render in the pane's own footer strip through `status_requested(message, true)` — never a
dialog — with the denied cue, and neither writes anything:

```text
[probe] overload refusal=10 / 8 PWR — OVER BY 2 danger=true
[probe] full-cells refusal=W SLOTS FULL — SWAP OR REMOVE FIRST danger=true
```

- The overload is `"%d / %d PWR — OVER BY %d"` over the **candidate** fit's arithmetic: two
  plasma coils and a rocket pod plus the light shield draw 10 against the Vanguard's 8 + `p_std`
  0, hence `10 / 8 PWR — OVER BY 2`. The suite additionally proves the format is 09 §2's own by
  parsing that section's example (`13 / 11 PWR — OVER BY 2`) out of the document and applying
  the pane's format to (13, 11, 2) — byte-equal.
- The full-cells line is STATION_HUB §5.1's, parsed out of the document by the suite and
  compared with the rendered message: `W SLOTS FULL — SWAP OR REMOVE FIRST`. It is reachable
  from `install_module` (no empty W cell), while the same state's *row* offers `SWAP` — the
  pin's own two sentences, both measured.
- Nothing auto-removes: after the refused install the cell is still empty, the module is still
  in the inventory and the balance is untouched (probe: `W3 — EMPTY`, `w_plasma:1`, `credits=0`).

## 7. The round trip (raw, from `probe_p2b1_panel_fit.gd`)

Every figure is `.agents/gen/p2b1_w2_probe.txt`, re-runnable with

```text
godot --headless --path vajb-orbit res://tests/probe_p2b1_panel_fit.tscn
```

The probe borrows the shipped autoload exactly as `test_p2a_launch_fit.gd` does (scratch
`save_path`, snapshot, flush on the scratch path, restore, delete) and wires the shell's own
`profile_changed → refresh_profile`.

```text
[probe] FITTED WEAPONS (start): [W1 LASER MKII | W2 — EMPTY | W3 — EMPTY]
[probe]   W1 remove visible=true
[probe]   W2 remove visible=false
[probe]   W3 remove visible=false
[probe] start: credits=10000 inv=[]
[probe] buy_module(w_cannon, 1200) = true
[probe] press w_cannon row (action=INSTALL)
[probe] after BUY + INSTALL w_cannon: credits=8800 inv=[]      strip=[W1 LASER MKII | W2 CANNON MKI | W3 — EMPTY]
[probe] buy_module(w_rocket, 2400) = true
[probe] press w_rocket row (action=INSTALL)
[probe] after BUY + INSTALL w_rocket (every W cell full): credits=6400 inv=[]   strip=[W1 LASER MKII | W2 CANNON MKI | W3 ROCKET POD]
[probe] buy_module(w_mine, 1800) = true
[probe] press w_mine row (action=SWAP)
[probe] after BUY + SWAP w_mine into W1: credits=4600 inv=[w_laser:1]   strip=[W1 MINE LAYER | W2 CANNON MKI | W3 ROCKET POD]
[probe] press strip REMOVE on W1
[probe] after strip REMOVE of W1: credits=4600 inv=[w_laser:1 w_mine:1]  strip=[W1 — EMPTY | W2 CANNON MKI | W3 ROCKET POD]
[probe] press strip REMOVE on W2
[probe] after strip REMOVE of W2: credits=4600 inv=[w_laser:1 w_cannon:1 w_mine:1]  strip=[W1 — EMPTY | W2 — EMPTY | W3 ROCKET POD]
```

| Claim (brief §3 / §1) | Measured |
|---|---|
| the pane sells 09 §3.1's costs | 1 200 / 2 400 / 1 800 charged; balance 10 000 → 8 800 → 6 400 → 4 600 |
| INSTALL fills the **first empty** W cell | the cannon lands in W2 (W1 holds the standard fit's laser) |
| SWAP displaces, never destroys (09 §4.8) | `w_laser:1` appears in the inventory and the mine leaves it |
| REMOVE returns to the inventory | the mine and the cannon both come back (`inv=[w_laser:1 w_cannon:1 w_mine:1]`) |
| the strip reads the fit live | every step's strip line follows the write, and REMOVE follows the fitted cell only |
| the mandatory set is untouched | `engines=["e_std"] power=p_std`, `fit_legal(...).missing=[]` after the whole probe |

## 8. Tests added and the gate

`tests/test_p2b1_outfitting_panel.gd`, seven tests, one per state change the brief names:

| Test | Asserts |
|---|---|
| `test_module_rows_are_09_3_1s_table_in_order` | 09 §3.1's table parsed out of the document carries six rows; the pane renders one per row in that order, with the catalogue's name, the document's draw/cost/effect, the `W SLOT · DRAW n` meta, the grouped PRICE, `FITTED (W1)` for the standard fit's laser and `FOR SALE`/`BUY` for the rest |
| `test_fitted_strip_reads_the_active_hulls_w_cells` | three lines for the Vanguard's three W cells, `W1 LASER MKII` / `W2 — EMPTY` / `W3 — EMPTY`, REMOVE on the fitted line only; a hull switch (buy + activate the Lancer) moves the strip to two lines, both fitted |
| `test_buy_install_swap_remove_round_trip` | the four actions across the three cells with credits, inventory, fit, strip, STATUS and ACTION checked at each step, including a second cannon (09 §4 item 4's repeat rule), the SWAP's displaced laser, and both REMOVE paths (the row's and the strip's) |
| `test_power_overload_refusal_shows_the_over_by_line` | `9 / 8 PWR — OVER BY 1` for its own candidate, `danger=true`, nothing written, nothing charged, the module still held; the pane's format reproduces 09 §2's `13 / 11 PWR — OVER BY 2` |
| `test_full_cells_refusal_line` | the row offers `SWAP` while `install_module` refuses with STATION_HUB §5.1's own parsed line, `danger=true`, nothing written; the SWAP then succeeds and hands the laser back |
| `test_mandatory_set_is_untouchable` | all six rows are `weapons` modules, no engine/reactor row, an engine id and a reactor id cannot be installed or swapped in (nothing written, no footer line), the strip carries W cells only, and the round trip leaves `engines=["e_std"]`, `power="p_std"`, `missing=[]`, `overflow={}` |
| `test_profile_changed_drives_the_refresh` | with the shell's wiring the pane's rows and strip move on an external `buy_module` / `add_module` / `set_fit_slot` / `spend`; unwired, the same key leaves the pane stale — the refresh is the signal, not a read-through |

Gate (brief §6), baseline measured before this pass: `[SUMMARY] passed=380 failed=0`.

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
...
[SUMMARY] passed=387 failed=0
```

exit 0; 387 `[PASS]`, 0 `[FAIL]`; raw captures `.agents/gen/p2b1_w2_gate.txt` and
`.agents/gen/p2b1_w2_suite.txt` (the suite alone: `passed=7 failed=0`). No existing test's
assertions changed and no suite outside the new one moved (380 + 7 = 387).

## 9. The header fit (a Fix Wave 1 W2.2 consequence this wave had to resolve)

Both column headers now sit inside the scrolling body, directly above their own rows, so their
insets are the scene's own 12 px (`HeaderMargin` / `ModulesMargin` versus the rows' `RowInner`)
and `_fit_section` no longer measures or writes them — it still fits each header's **column
widths** from its own rows' cells, which was the other half of W2.2. Measuring the margins is
not merely unnecessary now, it does not converge: with a measured trailing margin the panel's
own minimum width grows by the margin it just wrote (measured while diagnosing: `size.x` 927 →
939 → 951 → 963 px per pass, and the deferred re-fit queue flooded until Godot aborted in
`Container::_sort_children` with "Message queue out of memory"). The scene's constants are the
fixed point, and the ammo header's alignment is preserved: both the header's MarginContainer
and the rows' `RowInner` carry the same 12 px inset by construction.

## 10. Rendered check (live, not headless)

`project_run(mode="custom", scene="res://ui/screens/station.tscn")` then
`editor_screenshot(source="game", max_resolution=1152)`: the pane renders as specified — the
`FITTED WEAPONS` caption with `W1 LASER MKII` (its REMOVE plate carrying the focus ring, since
`focus_primary` reaches the strip first), `W2 — EMPTY`, `W3 — EMPTY`; the `MODULES` caption with
the `MODULE | EFFECT | PRICE | STATUS | ACTION` header; the six rows with their icons, meta,
effect prose, prices, `FITTED (W1)` / `FOR SALE` statuses and `BUY` actions, the 4 800 plasma
price in `accent_danger` with `LOCKED` against the account's 2 933 CR; the ammo header and rows
below; the footer line unchanged. The screenshot is inline-only (the MCP tool has no output
path), so R1 re-takes it with the same two calls. The dynamic states (fitted, swapped,
refused) are measured headlessly in §7/§8 rather than by mutating the owner's live save.

## 11. Findings for R1 and the owner (transcribed, not resolved)

1. **The row set reading (§3)** — six rows, `w_mining` not sold. The owner's call; one line
   either way.
2. **The ACTION precedence (§4 item 1)** — a fitted module with an empty cell offers
   INSTALL/BUY (09 §4 item 4), so REMOVE is the full-grid state; the strip's REMOVE is
   available in every state.
3. **The seed write (§5)** — the panel calls `set_fit` once per hull the account holds no fit
   for. CONTRACTS §12 rule 2 names `set_fit_slot`/`clear_fit`; the seed is neither, because
   neither can materialise a whole fit, and the alternative (a bare `set_fit_slot`) produces an
   unlaunchable hull, measured above. `clear_fit` is deliberately unused: it drops the hull's
   whole fit (the launch would then fall back to the standard fit) and cannot empty one cell.
4. **`REFUSED · FIT ILLEGAL`** — a third wording, unreachable from this surface's own writes
   (§4 item 3). Not one of the pin's two.
5. **Three new cosmetic strings** beyond the pin's two refusals, in the ammo rows' own style:
   `PURCHASED · <NAME> · <n> CREDITS`, `INSTALLED · <NAME> · W<k>`,
   `SWAPPED · <NAME> · <NAME> BACK IN INVENTORY`, `REMOVED · <NAME> · BACK IN INVENTORY` and
   the focus hint `ENTER <ACTION> · <NAME> · <n> CREDITS`. No number in any of them.
6. **LOW — stale pane copy (not mine to change, `docs/**` is D0's).** The subtitle still reads
   `AMMUNITION AND CONSUMABLES · 5 PACKS IN THE CATALOGUE` and the panel tag still lists only the
   five ammo ids, while the pane now also sells six weapon modules. STATION_HUB §5.1's amendment
   does not name either string; D0's §2 rail edit already describes the payload as "6 weapon
   modules + 5 ammo packs".
7. **LOW — the ammo footer is ammo-specific.** `%PaneFooter` still reads
   `HOLD CAPACITY IS ADVISORY · A PURCHASE IS NEVER CLAMPED` under the module rows too. It is
   accurate for the ammo group it was written for; the module section has no footer of its own
   in the pin.
8. **Observation, not this wave's code: the owner's `user://profile.cfg` was rewritten once
   during this session, by the game's own market-band evaluation on docking** (05 §2,
   `game/exchange.gd:evaluate_market` → `set_market` → the debounced save), not by the pane or
   its tests. Measured: the gate run and the probe run each leave the file **byte-identical**
   (`md5sum -c` OK, twice), and a second station run after the band rolled left it untouched too
   (mtime unchanged). The pane writes nothing on mount: it reads only, and its own writes are
   the four row actions. Recorded because a station visit can therefore rewrite the save, which
   is worth an owner's eye independently of this wave.
9. **`ShipFit.grid_cells` is read for the strip's cells and `slot_capacity` (= `grid_counts`) is
   no longer used by the panel**: `_weapon_cells` walks `grid_cells`, keeps the W cells, and
   reads the fit at each cell's own layout index — the pin's own sentence, and 09 §8 item 1's
   count consumer is still `grid_counts` for every other reader.

## 12. Commands run (all raw output in this report or re-runnable)

| Command | Purpose | Result |
|---|---|---|
| `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | the wave gate, before and after | 380 → **387** passed, 0 failed, exit 0 |
| `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200 -- --suite=test_p2b1_outfitting_panel` | the new suite alone | 7 passed, 0 failed |
| `godot --headless --path vajb-orbit res://tests/probe_p2b1_panel_fit.tscn` | the evidence probe | 54 `[probe]` lines, no error, exits itself |
| `md5sum -c` on `user://profile.cfg` before/after the gate and the probe | probe hygiene L17 | OK, twice (the owner's save is byte-identical) |
| `project_run(custom, res://ui/screens/station.tscn)` + `editor_screenshot(game, 1152)` | the rendered check (§10) | the pane as specified; no error in the game log |
| `git diff --numstat` / `git status --short` | scope proof | 2 shipped files + 3 new test files, all under `vajb-orbit/ui/station/` and `vajb-orbit/tests/`; no `assets`, theme, `project.godot`, `addons` or `docs` |
