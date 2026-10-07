# S35_BRIEF — owner fix round: one sell selector (MAX/0), preview clear, one shared menu

## §0 Owner note verbatim (2026-10-05)

"spawn fixer: in exchange there are two separate "units number" selector
instead of sell or even better (MAX and 0) button, in armory clicking a socket
shows what can be fit, clicking somewhere else should disable the preview, i
want the menu in fit cells and battery config on the right to be exactly the
same menu. while coder works do the T-131, T-134 (coder as mentioned above)
T-135 and chrome generation. go" — and "for coding run deepseek on x-high".

## §1 Law to read in order

1. This brief (the interface blocks, the acceptance list).
2. `docs/design/UI_SPEC.md` §14 (N48/N49 + the 2026-10-05 N49 amendment) +
   §13.1 (N42–N47) + §11.1 (A5.5/N24) + §3.10 A5.
3. `docs/design/STATION_HUB.md` §21.1 (P38–P41 + the 2026-10-05 P38/P39
   amendment) + §20.1 (P32–P35 as amended).
4. `slices/S33-shell-v3/S33-B1_report.md` + `S33-F1_report.md` (the current
   shapes: the two-state list, the EQ container, the trade stack, `FIT`/
   `FITTED`/`STORED` semantics).

## §2 Measured facts (file:line)

- Exchange trade stack (S33): `StepperRow` (the now-display-only unit-number
  selector) → `SellUnitsRow` → `InspectCluster` → `PaneFoot`;
  `exchange_panel.gd` `SELL_WORD` :122-ish, `SELL_QUANTITY_FORMAT` :123,
  `%SellButton`/`%SellAllButton`, `_sell_units` bounds 1..row units, the SELL
  delta rows in `test_s5_ammo_cargo.gd`.
- ARMORY (S33/F1): the right list `_equip_rows` browse/selected branches
  (`armory_panel.gd:4105-4123`, `_fitted_bases`), `_select` :3255-3275 and
  `clear_selection` :3295-3309 (hint refresh added by S33-F1/F2), the EQ
  container `_build_eq` :3900-4090, `%BrowserBand`/`%EqBand` + tabs.
- Doors: `fit_module_at`, `clear_fit_slot`, `move_rack_cell`, `install_weapon`
  (S33-R1's door audit).

## §3 Pinned interface (the three fixes)

```
EXCHANGE trade column (the N49-amended stack, top-down)
SellUnitsRow   "SELL UNITS" stepper (min 0, max = selected row's units)
               + two P2 ActionInline quick buttons: "MAX" (fills max),
               "0" (empties; SELL then disabled)
InspectCluster the N43 cluster (unchanged)
PaneFoot       SELL / SELL ALL RAW (unchanged)
# the S33 duplicate unit-number selector dies
```

```
ARMORY
- P38a: a press outside every socket and row CLEARS the selection + preview:
  right menu back to browse, CELL INFO cleared, the hint follows (P40).
- P39a: both modes' right sector render ONE shared menu component
  (identical categories, rows, band, trim); modes differ only in the row
  actions + the FIT CELLS socket filter (select-to-fit / drag-to-fit / BUY
  vs drag-to-rack). The S33 EQ container merges into this menu.
```

Rules: the quick buttons are `ActionInline` chips per UI_SPEC §8 P2; MAX/0
act on the same `_sell_units` value a SELL press moves; click-away clearing is
pointer-press routing on empty chrome only (a press on any control keeps its
own behavior); the shared menu is one scene/script builder, not two lookalikes.

## §4 Spec extract (verbatim) + acceptance list

N49-amended (UI_SPEC §14): "the trade column carries one quantity control —
the SELL UNITS selector with MAX and 0 quick-set buttons beside it (stepper
min 0, max = the selected row's units; SELL disabled at 0 or with no
selection) … The S33 duplicate unit-number selector dies."
P38a (STATION_HUB §21.1): "a press outside every socket and row clears the
selection and the preview (the right menu returns to browse, CELL INFO
clears, the hint follows P40)."
P39a: "both modes' right sector render one shared menu component: identical
categories, rows, band and trim in FIT CELLS and BATTERY CONFIG … the modes
differ only in the row actions and the FIT CELLS socket filter."

Acceptance (the report answers each):
1. One quantity control in the trade column; MAX fills the row's units, 0
   empties and disables SELL (probe both); bounds 0..row units.
2. SELL moves exactly the selector value (profile delta probe) and is
   disabled at 0 and without a selection; no second units-number selector
   exists anywhere in the exchange (grep + scene probe).
3. Click-away: select a socket → press empty chrome → selection + preview
   cleared (CELL INFO cleared, list back to browse, hint idle) (probe).
4. The right menu is ONE shared component in both modes (same builder/scene
   subtree + identical category set both modes; grep proves a single
   builder).
5. Mode behavior intact: FIT CELLS' socket filter + fit/drag/BUY actions and
   BATTERY CONFIG's drag-to-rack persist through the profile doors (probe).
6. Gate green ×2 + every moved test row disclosed.

## §5 Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S35-B1 | builder — `hyper/deepseek-v4.1-flash` @ xhigh | `vajb-orbit/ui/,vajb-orbit/tests/` | code + tests → `S35-B1_report.md` |
| S35-R1 | reviewer — `hyper/glm-5.3-flash` @ max | `vajb-orbit/tests/,.agents/gen/slices/S35-owner-fixes/` | `S35-R1_review.md` |
| S35-F1 | fixer — as B1 (**only if HIGH/MED**) | `vajb-orbit/ui/,vajb-orbit/tests/` | `S35-F1_report.md` |

## §6 Run order
B1 → R1 → (F1). Runs parallel with **D21-G1** (the chrome generation driver,
`hyper/glm-5.3-flash` @ max — the owner's image-generation lane assignment);
disjoint file sets (`vajb-orbit/ui`+`tests` vs `asset-library/`+the D21 slice).

## §7 Tests that move
`test_s5_ammo_cargo.gd` (the N49 rows restate: bounds 0.., MAX/0, disable),
`test_s32_armory_modes.gd` (the EQ-container rows + the two-state rows
restate as shared-menu rows; P38 semantics + the hint rows stay),
`test_d7_armory.gd` (EQ-container geometry rows). Every moved row disclosed
(old → new → why). New rows: MAX/0 behavior + disable at 0, no second
selector (grep), click-away clearing (probe), one shared menu (identical
categories both modes + single builder), mode actions intact.

## §8 Hard rules
File set `vajb-orbit/ui/,vajb-orbit/tests/` only. This brief is law: a pinned
number you believe wrong gets reported and left at the closest value — never
silently changed. Profile writes through the existing doors only. A5.5/N24.

## §9 Staged / deferred
The chrome family art (D21-G1 generates behind the owner's review sheet; the
S36 wave re-skins). T-128/T-129/T-114 ride untouched.

## §11 Tick sheet
None — T-134 is resolved by this wave at the owner's own words (§0).

## §12 Close-out
Gate ×2 fresh scratch → `verify_wave.py verify --baseline s35_start` →
`staging/build_code_map.py` → TICKS refresh → WAVEBOARD row +
`MASTER_REPORT.md` §6 → wave commit.
