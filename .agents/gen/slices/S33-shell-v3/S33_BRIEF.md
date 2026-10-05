# S33_BRIEF — shell v3: ARMORY two sectors + the exchange sell cluster

## §0 Owner notes verbatim (2026-10-05 round)

- Note 2 (armory, final wording — the 2-sector version supersedes the earlier
  3-sector sketch): "in armory the "fits here" is way too wide and clunks the
  screen. I want the screen to split into 2 sectors. left with overwiev we
  have not, right with current equipment where when i select a slot it shows
  all possibilities, otherwise i can just browse all the things i have for the
  ship." — "overwiev we have not" is read as "the overview we have now"
  (tick **T-132**).
- Note 3 (battery config): "make the "battery config" same as above. two
  splits. left one for drag and drop battery guns, right for ammo fuel rods
  etc, just keep the EQ there. a small container for all EQ should be pretty
  easy to do. same categories as before."
- Note 4 (exchange): "in exchange i need a "sell" button instead of "sell 1
  unit", sell units should be beneths unit number selector"
- Note 1 (OVERVIEW button backgrounds) is out of scope here — moved to the
  chrome-family wave D21 (UI_SPEC §14's closing note supersedes N50/N51).

## §1 Law to read in order

1. This brief (the interface blocks, the acceptance list).
2. `docs/design/STATION_HUB.md` §21.1 (P38–P41) + §21.2 (supersession map) +
   §20.1 (P32–P35 as amended) + §19 (the pane skeleton + §19.4 idiom).
3. `docs/design/UI_SPEC.md` §14.1 (N48/N49) + §13.1 (N42–N47) + §11.1
   (A5.5/N24) + §3.10 Amendment 5 (containers, never coordinates).
4. `docs/gameplay/09_ship_slots_modules.md` §10–§12 (battery law: W-cell
   racks, 5×4 hardcap, `battery_cycle` = slowest member's cooldown).
5. `slices/D20-station-playtest/D20_synthesis.md` §3 (door grounding).

## §2 Measured facts (file:line)

- ARMORY: `armory_panel.gd` `set_mode`/`_apply_mode` :982-1006,
  `_refresh_cell_info` :2050, `_cell_legality` :2088 (refusal strings :86-90),
  `_fits_here_rows` :2449, `cell_drop` :3880, `_browser_ids` :3961;
  `armory_style.gd` :216-300 (the S32-R1 full-width console + racks).
- EXCHANGE: `exchange_panel.gd` :51 `SELL_HEIGHT := 56.0`, :122-123
  `SELL_WORD`/`SELL_QUANTITY_FORMAT`, :126 `CONFIRM_FORMAT`, :164-165
  `%SellButton`/`%SellAllButton`, :629 the N43 INSPECT cluster, :661-662 the
  armed-wording read (`SELL n UNIT(S)` when armed, else `SELL`).
- Doors: `fit_battery`/`clear_battery`/`battery_groups`/`set_battery_groups`
  at `player_profile.gd:1178-1353`. Battery hardcap 5 racks × 4 cells.
- S32-F1 re-anchored 13 geometry rows (disclosed in `S32-F1_report.md`).

## §3 Pinned interface (shapes + the rules that fix ambiguity)

```
FIT CELLS / BATTERY CONFIG (each mode)
ModeHost (HBox; equal sectors, gutter per A5 tokens)
├─ LeftSector (width == RightSector)
│  ├─ FIT CELLS: CellGrid (23 cells + 3 engines, shipped) + CellInfo block
│  └─ BATTERY CONFIG: the B1–B5 rack editor (full-height)
└─ RightSector (width == LeftSector)
   ├─ FIT CELLS: FamilyTabs + one ColumnHeaderBand + EquipList (two states)
   └─ BATTERY CONFIG: CategoryTabs + the EQ container (count rows)
```

```
EXCHANGE trade column (top-down)
UnitSelector        buy quantity, as shipped
SellUnitsSelector   "SELL UNITS" — beneath UnitSelector; same stepper family;
                    min 1, max = selected hold row's units; disabled+text_dim
                    without a selection
InspectCluster      N43's cluster (unchanged)
SellButton          always "SELL" (360×56 ActionPrimary)
SellAllButton       "SELL ALL RAW" (unchanged)
```

Rules: sector equality is measured (probe both widths); lists are full-width
of their sector; the drag contract stands (drag from the list, right-click
pulls); profile writes go through the existing doors only; `CONFIRM_FORMAT`
keeps its counted wording.

## §4 Spec extract (verbatim) + acceptance list

P38 (STATION_HUB §21.1): "FIT CELLS is two equal sectors … LEFT = the shipped
cell grid + the CELL INFO block … RIGHT = one equipment list in two states: no
cell selected → browse everything the profile owns that the active hull can
use (rows tagged FIT / STORED; the family tabs stand); a cell selected → all
possibilities for that cell — owned-that-fits first (select-to-fit,
drag-to-fit), buyable-that-fits after (BUY + INSPECT) — rows tagged OWNED /
BUYABLE, legality line per row. FITS HERE and BUYABLE THAT FITS as separate
wide blocks die."
P39: "BATTERY CONFIG is two equal sectors. LEFT = the B1–B5 rack editor
full-height … RIGHT = the EQ container — one compact list of the non-weapon
equipment under the same category tabs as before (AMMUNITION · PWR/FUEL RODS ·
the other browser families present on the ship), count rows, INSPECT + BUY
top-ups where the old band offered them."
P40: "every list wears one AUCTION-idiom column-header band and the N45 trim
law (160 px ellipsis titles); every row control lands inside 1920×1080; the
mode hint line updates per mode + selection."
N48 (UI_SPEC §14.1): "the EXCHANGE trade column's commit button is always
worded SELL … the armed quantity wording retires. The confirm dialog keeps its
counted wording."
N49: "the trade column stacks top-down: the unit-number selector → SELL UNITS
selector directly beneath it … → the N43 INSPECT cluster → SELL / SELL ALL
RAW. SELL sells exactly the SELL UNITS value of the selected row."

Acceptance (the report answers each):
1. P38 layout: FIT CELLS two equal sectors; left = grid + CELL INFO unchanged (measured widths).
2. P38 semantics: the right list's two states exactly (no selection → owned-for-ship browse, FIT/STORED tags; selected → owned-that-fits then buyable-that-fits, OWNED/BUYABLE tags + legality + fit/BUY/INSPECT).
3. P39: BATTERY CONFIG two equal sectors — left racks full-height (drag persists via `set_battery_groups`, probe the profile), right = EQ container with the same category tabs + counts + INSPECT/BUY.
4. No `FITS HERE`/`BUYABLE THAT FITS` wide block and no P36 foot band remain (grep + scene probe).
5. N48: the commit button reads `SELL` in every state; the confirm dialog keeps counts.
6. N49: the stack order is exact; SELL UNITS bounds are min 1 / selected-row units and it disables without a selection; a SELL press moves exactly that value (profile delta probe).
7. P40 + gate: bands + 160 px trim on every list, containment at 1920×1080 (measured rects), gate green ×2, every moved test row disclosed.

## §5 Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S33-B1 | builder — `hyper/deepseek-v4.1-flash` @ xhigh | `vajb-orbit/ui/,vajb-orbit/tests/` | code + tests → `S33-B1_report.md` |
| S33-R1 | reviewer — `hyper/glm-5.3-flash` @ max | `vajb-orbit/tests/,.agents/gen/slices/S33-shell-v3/` | `S33-R1_review.md` |
| S33-F1 | fixer — as B1 (**only if HIGH/MED**) | `vajb-orbit/ui/,vajb-orbit/tests/` | `S33-F1_report.md` |

## §6 Run order
B1 → R1 → (F1). S33 runs **beside D21** (disjoint: code vs docs), strictly
**before S34** (both land rows in `vajb-orbit/tests/`; the whole-tree verify
baselines must not see each other's diffs).

## §7 Tests that move

`test_s32_armory_modes.gd` (the FITS HERE / BUYABLE lane + foot-band rows
restate as the two-state list + EQ container rows), `test_s5_batteries_v2.gd`
(rack rows re-anchor to the left sector), `test_s5_ammo_cargo.gd` +
`test_s11_inspector.gd` (sell / INSPECT rows), `test_s20_chrome_unify.gd` +
`test_s30_shell.gd` (census rows), the d7/s15/s18/s10 geometry rows (re-anchor
again). Every moved row disclosed (old → new → why). New rows: sector equality
per mode; the right list's two states incl. tags/legality; EQ container
categories + counts; SELL wording; SELL UNITS bounds + disable; SELL's profile
delta; stack order; containment.

## §8 Hard rules
File set `vajb-orbit/ui/,vajb-orbit/tests/` only (never docs/, game/,
autoload/, addons/). This brief is law: a pinned number you believe wrong gets
reported and left at the closest value — never silently changed. Profile
writes through the existing doors only. A5.5/N24: hover/focus/selection mutate
colour, modulate and `_draw` only.

## §9 Staged / deferred
The D21/S35 chrome family (panels keep today's plates in this wave); T-128
(pointer-guard port), T-129 (`_summary_hint` coordinates), T-114 (dead
`_row_hint` helpers — cure any you touch).

## §11 Tick sheet
| Tick | The call | Default if silent |
|---|---|---|
| **T-132** | note-2 reading: "left with overwiev we have not" = the overview we have now stays left | the pinned reading (P38) |

## §12 Close-out
Gate ×2 fresh scratch → `verify_wave.py verify --baseline s33_start` →
`staging/build_code_map.py` → TICKS (**T-130 closes** — P38 defines the
no-selection semantics; T-132 leaves when decided or defaults) → WAVEBOARD
row + `MASTER_REPORT.md` §6 → wave commit.
