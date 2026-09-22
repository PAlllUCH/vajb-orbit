# P2-B proper — F1 fixer report (2026-09-22)

**Role:** F1, the single fixer pass of wave P2-B proper. I fixed exactly the two MED findings
R1 left (`.agents/gen/p2b_proper_r1_report.md` §7, MED-1 and MED-2) and nothing else: no LOW,
no HIGH existed. R1's own commands re-measure both below; the evidence bundle is
`.agents/gen/p2b_proper_f1_evidence.txt`.

**Files I changed** (my declared set: `vajb-orbit/autoload/player_profile.gd`,
`vajb-orbit/ui/station/fitting_panel.gd`, `vajb-orbit/ui/station/shipyard_panel.gd`,
`vajb-orbit/tests/`):

| File | Change |
|---|---|
| `vajb-orbit/autoload/player_profile.gd` | `resolved_fit` added; `fit_module_at` and `clear_fit_slot` compose their candidate from it; `_with_cell` composes a type the fit does not carry yet; `_holds_a_module` added |
| `vajb-orbit/ui/station/fitting_panel.gd` | `_resolved_fit` calls the profile's accessor; `_clear_notice()` added and called on both success paths |
| `vajb-orbit/ui/station/shipyard_panel.gd` | `hover_line` reads `resolved_fit` for a hull the account owns |
| `vajb-orbit/tests/test_p2b_retirement.gd` | 3 tests added |
| `vajb-orbit/tests/test_p2b_fitting_panel.gd` | 2 tests added |
| `vajb-orbit/tests/test_p2b_services.gd` | 1 test added (+ `_fit_cell` reader) |
| `vajb-orbit/tests/probe_f1_residual.gd`/`.tscn` | the one throwaway probe I wrote, kept as the residual's evidence (§6); drop it at the close-out if unwanted |

**Not touched:** `assets/**`, the theme, `project.godot`, `addons/**`, `docs/**`, and no frozen
game file (`game/ship_fit.gd`, `game/module_catalog.gd`, `game/player_state.gd`, `game/game.gd`,
`game/repairs.gd`, `08_ship_classes.md` all clean in `git status`). The owner's
`user://profile.cfg` was never written: `md5 9a04bea68fbe90c4d017e66245ceee7e` before and after
every run.

**The gate I measured myself:** `[SUMMARY] passed=437 failed=0`, exit 0, sandboxed
`XDG_DATA_HOME`, `[PASS]` lines = 437. That is R1's 431 plus the six tests this pass adds; the
only `SCRIPT ERROR` line in the log is the pre-existing `test_weapon_fx_f4.gd` freed instance.
Before my change the same command read `passed=431 failed=0`.

---

## MED-1 — the pane previewed one fit and the profile committed against another

**Cure taken (R1's option (a), profile-side, as the orchestrator decided):** the profile composes
its candidate from the fit the launch would fly, and the pane and the shipyard read that same
accessor.

`autoload/player_profile.gd`:

```gdscript
## The fit this hull would launch with, in `fit_for`'s own shape: the account's
## stored fit when it holds any module at all, and 09 section 9's
## `ShipFit.standard_fit` otherwise. That is the launch's own fallback - the
## launch resolves the hull's stored fit and hands the empty one to
## `ShipFit.standard_fit` (`game.gd:_launch_fit_for`) ...
func resolved_fit(ship_id: StringName) -> Dictionary:
	var stored := fit_for(ship_id)
	if _holds_a_module(stored):
		return stored
	return FitData.standard_fit(ship_id)
```

and in `fit_module_at` / `clear_fit_slot`:

```gdscript
	var base := resolved_fit(ship_id)
	var candidate := _with_cell(base, slot_key, index, module_id)   # clear_fit_slot: &"")
```

`_with_cell` gained the one thing a launch-fallback fit needs: 09 §9's `ShipFit.standard_fit`
names only the types the hull is delivered with, so a cell of a type it leaves out (the
Vanguard's U cell, the Fighter's C or B cell) is **composed** at its layout index instead of
read (`candidate.get(slot_key, candidate.get(String(slot_key), []))` + pad) - without that the
cure is unreachable exactly where R1 measured it.

**Two decisions inside the cure, both pinned by the finding's own text:**

1. **The write is the candidate, not the one cell.** The candidate is the launch's fit with the
   one cell set, and the transaction persists it whole with `set_fit`. Composing the candidate
   alone would have made the *first* install on a bare hull write a one-module fit that flies
   `missing: [engines, power]` - R1's own MED-1 refusal shape, moved one step later - and every
   install after it would then be refused. Wherever the stored fit already holds a module the
   two writes are the same write (`set_fit` of the resolved fit + one cell normalises exactly as
   `set_fit_slot` does from the stored entry), which is why every existing profile test and
   R1's own profile probe are unchanged.
2. **`clear_fit_slot` keeps its module read on the stored fit** (`fit_for`). The candidate is
   the launch's fit - as instructed - but the module that goes *back to the inventory* is read
   from the account's own fit, because only that fit holds a module the account actually has.
   Reading the launch's fit there would hand over a delivered module the account never owned.
   This leaves one residual, measured and reported in §6 rather than fixed.

**The pane** (`ui/station/fitting_panel.gd`) no longer duplicates the resolution:

```gdscript
func _resolved_fit(profile: ProfileScript, hull: StringName) -> Dictionary:
	if profile == null:
		return ShipFit.standard_fit(hull)
	var fit: Dictionary = profile.call(&"resolved_fit", hull)
	return fit
```

and the pane's own dead `_holds_a_module` copy is deleted (nothing else used it).

**The shipyard** (`ui/station/shipyard_panel.gd`) reads the launch's fit for a hull the account
owns, and keeps `fit_for` for one it does not:

```gdscript
		var read := &"fit_for"
		if _owned_ids(profile).has(_selected_id):
			read = &"resolved_fit"
		module_id = _fit_cell_module(profile.call(read, _selected_id), slot_key, index)
```

### Re-measured with R1's own command

```text
$ XDG_DATA_HOME=/tmp/r1_probe_sb godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600 | rg 'unfit hull'

# BEFORE - byte-identical to R1 §7 MED-1:
[R1-PANES] unfit hull: stored fit holds a module=false action=SWAP meter=PWR 4 / 6 · CANDIDATE 4 / 6
[R1-PANES] unfit hull: install through the pane=false footer=REFUSED · FIT ILLEGAL
[R1-PANES] unfit hull: the stored candidate fit_legal={ &"legal": false, &"overflow": {  }, &"missing": [&"engines", &"power"], &"duplicates": [], &"power": { &"out": 6, &"draw": 0, &"spare": 6, &"legal": true } }

# AFTER - the install succeeds and the footer no longer reads REFUSED:
[R1-PANES] unfit hull: stored fit holds a module=false action=SWAP meter=PWR 4 / 6 · CANDIDATE 4 / 6
[R1-PANES] unfit hull: install through the pane=true footer=SELECT A CELL
[R1-PANES] unfit hull: the stored candidate fit_legal={ &"legal": true, &"overflow": {  }, &"missing": [], &"duplicates": [], &"power": { &"out": 6, &"draw": 4, &"spare": 2, &"legal": true } }
```

The stored fit the probe reads back is now launchable (`legal true`, `missing []`, the delivered
power line `4 / 6`), which is the half of the cure the instruction's test asks for.

The rest of R1's probe is unchanged but for the token-scan line numbers my added comment lines
moved (`diff` in the evidence bundle §2); it reproduces byte-identically on two scratch roots.

**`probe_w2_fitting.gd` had to move, and it is the finding:** W2's own `_probe_seeding_hole`
prints the unfit-hull read-back, so after the cure `fit_module_at=false → true` and the pane it
then re-reads shows the install (`PWR 4 / 8`, `W2 · CANNON MKI`, action `SWAP`) instead of the
untouched state. The other five of the six wave probes are byte-identical to R1's logs.

**R1's panes probe does not exercise the shipyard half** (its last hover case re-seeds the
Fighter as owned but leaves the *selected* hull on the Vanguard, which is no longer owned - so
that line stays `W1 · EMPTY · OWNED ×0` on the unowned branch). The new suite test below
measures the owned-hull path instead.

### Tests added

| Suite | Test | What it asserts |
|---|---|---|
| `test_p2b_retirement.gd` | `test_resolved_fit_is_the_launchs_own_fallback` | a bare hull and an all-empty stored fit both resolve to 09 §9's delivered fit; a stored fit that holds a module is the one; an NPC hull still resolves to `{}` |
| `test_p2b_retirement.gd` | `test_the_first_install_on_a_bare_hull_keeps_the_launchs_fit` | the composed install on a fitless Fighter succeeds, `fit_legal` is `legal` with `missing []`, the delivered engine/reactor/shield/plate stand, the named cell took the cannon, the delivered laser it replaced was **not** banked, and `resolved_fit == fit_for` afterwards |
| `test_p2b_retirement.gd` | `test_a_stored_fit_is_written_cell_by_cell_as_before` | for a hull that holds a fit, every slot key except the named cell is exactly what the stored fit held (the "shipped-fit hulls unchanged" half) |
| `test_p2b_fitting_panel.gd` | `test_an_unfit_hulls_first_install_through_the_pane_succeeds` | on a fitless Fighter the pane's selection line reads the **delivered** laser (not EMPTY), the cannon's row offers `SWAP`, the press succeeds, the footer is not the catch-all refusal, the fit left behind is launchable, and `resolved_fit == fit_for` |
| `test_p2b_services.gd` | `test_the_hover_line_reads_the_launchs_fit_for_an_owned_hull` | an owned hull with no stored fit reads the launch's fit in every non-gap cell (expected lines derived from `ShipFit.standard_fit` and `module_count`, never a literal this suite invents) |

`test_p2b_services.gd` gained a `_fit_cell` reader so the expectation comes from the delivered
fit itself.

### Follow-ups I could not land (docs are not mine)

The wave brief keeps `docs/**` for D0 and this pass is instructed not to touch docs, so §13
needs four one-line merges at the close-out - each is the fix's own text, nothing more:

1. **§13's `fit_module_at` comment** - "the candidate being `fit_for(ship_id)` with that one cell
   set to `module_id`" becomes `resolved_fit(ship_id)` (the launch's own fallback), and the
   success write is the candidate written whole; the same sentence in 09 §4 item 9 if it spells
   out the stored-fit candidate.
2. **§13's `clear_fit_slot` comment** - the candidate is `resolved_fit(ship_id)` with the cell
   set to `&""`, while the module returned to the inventory is still the stored fit's.
3. **§13 rule 5's allowed-call list** - the pane now reads `PlayerProfile.resolved_fit` (a
   read-only accessor) in place of its own copy of the fallback. This is the one sentence R1's
   MED-1 said the cure would need.
4. **§9's gate figure** - `431` → the measured `437` (and the six tests above are this wave's).

---

## MED-2 — a refusal's line outlived the successful action that followed it

**Cure:** the two success paths drop the latched line and repaint the footer; `_notice` keeps
latching, so the refusal still belongs to the press that made it.

`ui/station/fitting_panel.gd`:

```gdscript
func _clear_notice() -> void:
	_line_override = ""
	_line_danger = false
	_refresh_footer()
	status_requested.emit(_line.text, false)
```

called after the profile write succeeds in both `install_module` and `remove_selected`.

**One step beyond R1's parenthetical, and why:** R1's symptom names both surfaces ("the footer
**and the shell strip** keep saying …"), and `_notice` is what writes the strip; clearing only
the pane's own override would leave the refusal in the shell's StatusLabel, i.e. still on
screen. The republish uses the pane's own pinned line - no wording is invented, and the pane
already publishes its own line into the strip for the `SELECT A CELL` notice. It is one line;
the reversal (R1's own) is to drop the `status_requested.emit` and let the strip keep the last
notice the way it did before.

### Re-measured with R1's own command

```text
$ XDG_DATA_HOME=/tmp/r1_probe_sb godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600 | rg 'refused REMOVE|then a legal swap|footer now'

# BEFORE - byte-identical to R1 §7 MED-2:
[R1-PANES] refused REMOVE=false footer=MANDATORY CELL — SWAP ONLY, NEVER EMPTY
[R1-PANES] then a legal swap on the same cell: ok=true engines=["e_ion"]
[R1-PANES] footer now=MANDATORY CELL — SWAP ONLY, NEVER EMPTY (still the refusal=true) meter=PWR 3 / 8 · CANDIDATE 3 / 8

# AFTER - the footer stops reading the refusal:
[R1-PANES] refused REMOVE=false footer=MANDATORY CELL — SWAP ONLY, NEVER EMPTY
[R1-PANES] then a legal swap on the same cell: ok=true engines=["e_ion"]
[R1-PANES] footer now=E1 · ION DRIVE · OWNED ×0 (still the refusal=false) meter=PWR 3 / 8 · CANDIDATE 3 / 8
```

`after clear_selection footer=SELECT A CELL` still prints unchanged under it, and the
over-budget section's `footer`/`strip` pair is unchanged.

### Test added

`test_p2b_fitting_panel.gd::test_a_successful_swap_does_not_leave_the_refusals_line` - a refused
REMOVE on the mandatory E cell (with its pinned wording asserted on the footer **and** on the
strip), then `install_module(ION)` on the same cell with **no re-selection in between** (which
is what W2's suite did and R1's §7 said it does not cover): the swap lands, the footer equals the
selection line and no longer the refusal, the shell's strip carries that same line, and neither
is in the danger state.

---

## 3. Everything else I re-measured

| Measurement | Command | Result |
|---|---|---|
| The gate, before → after | `XDG_DATA_HOME=<scratch> godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | `passed=431 failed=0` → `passed=437 failed=0`, exit 0 both; `[PASS]` lines 431 → 437 |
| The three P2-B suites, alone | the same with `-- --suite=test_p2b_retirement --suite=test_p2b_fitting_panel --suite=test_p2b_services` | `42 → 48`, `failed=0` |
| W1/W3's four probes + the two lint probes | their own commands, `--quit-after 600` | **byte-identical** to R1's logs (6 / 36 / 20 / 14 / 14 marker lines) |
| W2's probe | its own command | two lines moved: W2's own unfit-hull read-back = MED-1 (§above) |
| R1's v5 migration probe | its own command | **byte-identical** to R1's evidence |
| R1's profile probe | its own command | identical but for the economy log's own wall-clock field |
| R1's panes probe, twice, two scratch roots | its own command | reproducible byte-for-byte |
| The station screen boots bounded | `res://ui/screens/station.tscn --quit-after 400` | exit 0, no `SCRIPT ERROR` (exit-time leak lines only, R1's LOW-7) |
| The pin audits | `python3 vajb-orbit/tools/r1_p2b1_signature_audit.py`, `…format_law.py` | 27 signatures / 0 drift, 21 checks / 0 failures |
| The owner's profile | `md5sum ~/.local/share/godot/app_userdata/"Vajb Orbit"/profile.cfg` | `9a04bea68fbe90c4d017e66245ceee7e` unchanged |

## 4. What I did not do

- No LOW was fixed: not L85-L92, and not the `_fit_cell_module`/LOW-2 family.
- No doc, asset, theme, `project.godot` or addon was touched (§the four §13 follow-ups above).
- I did not re-run the gate against a live-profile copy; R1's three data-dependent failures
  (LOW-6) are untouched by a fit path this pass did not move, and the same sandbox rule applies.

## 5. One boundary worth stating

`fit_module_at` now writes the **whole** candidate, so the write is no longer literally one
`set_fit_slot` call. CONTRACTS §13's text names `set_fit_slot` in the success order; the net
stored fit is the same in every case where the stored fit is the launch's fit (proved by R1's
profile probe and every existing profile test being byte-identical), and different only on the
bare-hull path this finding is about. §13's merge at the close-out should say the candidate is
written whole.

## 6. Residual (measured, not fixed) - for the orchestrator's backlog decision

On a hull with **no stored fit**, `clear_fit_slot` still refuses a *delivered* cell while the
pane offers REMOVE, because the module read is the stored fit's (decision 2 above):

```text
$ XDG_DATA_HOME=/tmp/f1_res godot --headless --path vajb-orbit res://tests/probe_f1_residual.tscn --quit-after 600   # exit 0
[F1-RESIDUAL] launch fit shields=[&"s_light"] | stored fit shields=[""]
[F1-RESIDUAL] the pane offers REMOVE=true, answers=false, footer=REFUSED · FIT ILLEGAL
[F1-RESIDUAL] the profile's own clear_fit_slot answers=false
```

The same code path before and after this pass (the pane's fallback and `clear_fit_slot`'s
`fit_for` read are both unchanged), so it is pre-existing, unreported by R1, and outside the two
assigned findings. Curing it means letting a delivered module go back to the inventory - a real
economy change (the shipped OUTFITTING surface already banks the delivered fit once its own
`_seed_fit` has materialised it), which is a decision above this pass's mandate. It is reachable
only before the hull's first install; after one cell is written the stored fit holds the
delivery and REMOVE works normally.

## 7. Reversals

- **MED-1:** drop `resolved_fit` and restore `fit_for(ship_id)` in the two candidate lines
  (`_with_cell(fit_for(ship_id), …)`) and `set_fit_slot` in `fit_module_at`; restore the pane's
  own `_holds_a_module` copy and the shipyard's single `fit_for` read. The pin's present text.
- **MED-2:** delete the `_clear_notice()` calls (or the whole helper) and let the override latch
  again.
- **The strip republish:** delete the `status_requested.emit(_line.text, false)` line.
- **The probe:** delete `vajb-orbit/tests/probe_f1_residual.gd`/`.tscn` (its output is quoted
  above and in the evidence bundle).
