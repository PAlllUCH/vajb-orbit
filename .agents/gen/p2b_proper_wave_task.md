# P2-B proper — the fitting panel (wave brief)

**Owner order (2026-09-22):** *"lets start with p2-b"* — followed by the scope confirmation's
three ticks: **affixes (doc 15) are the NEXT wave, not this one**; the six legacy `UPGRADES`
rows **retire now** with their effects migrated into the module catalogue; the owner's four
station requests **all ride along** (shipyard hover info, an owned-items inventory, the
shipyard's own slot-grid layout in the fitting surface, and REFUEL/RECHARGE buttons).

This wave builds the fitting surface proper and nothing else.

---

## 1. What exists, and what is missing

**Measured at the P2-B1 close-out (gate 389, commit `1f794cc`):**

- OUTFITTING sells the seven weapon modules (`outfitting_panel.gd:95-121`) and its rows
  install into the **first empty W cell** (no per-slot choice).
- `ShipFit.fit_legal` (`game/ship_fit.gd`) already refuses capacity, duplicate and
  power-budget violations; `PlayerProfile.set_fit_slot` already writes any cell of any type.
- The FITTED WEAPONS strip shows **W cells only**.
- The shipyard shows the hull's own layout grid as a **display**
  (`shipyard_panel.gd:352-397`: `SlotButtonWeapon` plates, 48 px, gaps as empty Controls).
- `Repairs.refuel` / `Repairs.recharge` (`game/repairs.gd:120`, `:150`) are free and instant
  at every station and **no panel calls them** (measured).

**What is missing is the fitting surface proper:** pick any cell of any of the eight types,
install / swap / remove per cell, see the power budget before committing, and see what you
own — plus the retirement of the pre-module `UPGRADES` rows and the owner's four requests.

**Measured fact that decides the flag day's cost:** nothing in flight reads
`has_upgrade` — grep finds it only in `player_profile.gd` itself, `upgrades_panel.gd` and the
tests. The six legacy upgrade rows therefore buy **no gameplay effect today**, and 09's own
lineage notes already name each one's successor module (§2's table below).

---

## 2. What is measured (do not re-discover)

- **`ShipFit` pin (CONTRACTS §11):** `grid_rows/grid_size/grid_cells/grid_counts/
  slot_capacity/fit_legal/standard_fit/mount_offset`, `SLOT_GRIDS`, `SLOT_TOKEN_KEYS`,
  `FIT_SLOT_KEYS` = `[engines, weapons, shields, armour, computers, boosters, utility, power]`,
  `MANDATORY_SLOT_KEYS` = `[engines, power]`, `ENGINE_MULT_CEILING` 1.40. `grid_cells` is
  row-major with gaps included: `{type, token, index, col, row, gap}`.
- **`PlayerProfile` (save v4):** `SAVE_VERSION := 4` (`player_profile.gd:37`),
  `MIN_READABLE_VERSION := 1` (`:38`); `fit_for` (all-empty shape for an unfit hull),
  `set_fit`, `set_fit_slot` (refuses an unknown hull / unknown slot key / out-of-range index;
  `""` empties a cell; module ids are deliberately unvalidated because a fit may store a
  15 §6 instance id), `clear_fit`; `modules()`, `module_count`, `add_module`, `take_module`,
  `buy_module`; `profile_changed(&"fits")` / `&"modules"`; economy events are
  `player_profile.gd:79`'s `EVENT_*` string constants (`EVENT_BUY_MODULE := "BUY_MODULE"`).
- **The legacy UPGRADES:** `game/station_catalog.gd:167-217` (six rows, `upgrade(id)`,
  `upgrade_ids()`), `ui/station/upgrades_panel.gd`/`.tscn`, the rail's
  `Module.UPGRADES` (`ui/screens/station.gd:51`) and its label (`:67`).
  `install_upgrade` (`player_profile.gd:248`) charges credits and records a permanent flag.
- **The shipyard's grid recipe** to reuse: `shipyard_panel.gd:352-397` (`_set_layout_grid`,
  `_make_slot_cell`, `_make_gap_cell`, `PLATE_SIZE` 48, caption
  `HARDPOINT_CAPTION` = `SLOT LAYOUT · %d CELLS · %d ENGINES`).
- **The pane construct to reuse** (STATION_HUB §5.1): caption + one row grid + footer strip
  (`status_requested`), `CELL_SEPARATION` 2, 76 px row pitch, 48 px module icons.
- **`Repairs` service shape:** `refuel` → `{ok, ship_id, fee, fuel_max}`, refuses a full tank
  (`REASON_FUEL_FULL`) and an unfiled ship; `recharge` → `{ok, ship_id, fee, energy_max}`,
  no full case. Both at `FREE_FEE` 0.
- **The legacy effect→module mapping is 09's own, already written:**
  `upgrade_generator` → `p_mk2` (09 §3.8 "the old Reactor Mk2, rebased"),
  `upgrade_shield` → `s_heavy` (09 §3.2 lineage), `upgrade_engine` → `e_ion`
  (09 §3.7 "the old Ion Drive, 3 800 CR, rebased"), `upgrade_module` → `c_scanner`
  (09 §3.4, +25 % scanner range), `upgrade_extra` → `u_cargo` (09 §3.6 lineage),
  `upgrade_drone` → `u_drones` (09 §3.6, "repair drone bay").

---

## 3. The pinned interface (CONTRACTS §13 — D0 lands it verbatim)

### 3.1 The profile pin (additive beyond §12)

```gdscript
## autoload/player_profile.gd — additive beyond §12's pin.
const SAVE_VERSION := 5              # was 4; a v4 file still reads (MIN_READABLE_VERSION 1)
const FIT_MANDATORY_KEYS: Array[StringName] = [&"engines", &"power"]   # 09 §4.1
const LEGACY_UPGRADE_MODULES: Dictionary = {          # the six-row retirement table, 09's own
    &"upgrade_generator": &"p_mk2",   &"upgrade_shield": &"s_heavy",
    &"upgrade_engine":    &"e_ion",   &"upgrade_module": &"c_scanner",
    &"upgrade_extra":     &"u_cargo", &"upgrade_drone":  &"u_drones",
}
const EVENT_FIT_MODULE := "FIT_MODULE"   # the fitting transaction's own log id

func fit_module_at(ship_id: StringName, slot_key: StringName, index: int,
                   module_id: StringName) -> bool
    # The composed install. Refuses (false, no write) when: the hull is not one of
    # the nine; the slot key is not in FitData.FIT_SLOT_KEYS; the index is outside
    # 0 .. slot_capacity-1; module_count(module_id) == 0; or the candidate fit fails
    # ShipFit.fit_legal — the candidate being fit_for(ship_id) with that one cell
    # set to module_id. On success, in this order: the displaced module (when the
    # cell was non-empty) returns with add_module; take_module(module_id, 1);
    # set_fit_slot(ship_id, slot_key, index, module_id); one Log.append(EVENT_FIT_MODULE,
    # module_id, 1, 0, credits) line; profile_changed(&"fits") and (&"modules").
func clear_fit_slot(ship_id: StringName, slot_key: StringName, index: int) -> bool
    # The composed remove. Same guards, plus: a key in FIT_MANDATORY_KEYS is always
    # refused (09 §4.1's mandatory set is never empty). The cell's module returns to
    # the inventory with add_module; the cell is written &""; one log line
    # (EVENT_FIT_MODULE with a negative qty is not used — use the module id, qty 1,
    # delta 0 and let the caller's footer carry the words); emits both keys.
func retire_legacy_upgrades() -> int
    # The v5 migration step, idempotent. For every id in the `upgrades` record whose
    # value is true: add_module(LEGACY_UPGRADE_MODULES[id], 1) and drop the record.
    # Returns how many were migrated (0 on a v5 file). Called from the load path when
    # the file's save_version < 5, after the record is read.
```

**Rules the pin fixes, so no worker has to choose:**

1. **The migration is a one-way door.** A v4 file with all six upgrades installed loads as
   six inventory modules (one each) and no upgrade records; a v5 file has no `upgrades`
   record at all. `has_upgrade` / `installed_upgrades` / `install_upgrade` and the
   `upgrades` key are **removed** from the profile; a v1–v3 file still loads (it never had
   the key). Fixture: the wave's own test builds a v4 file with all six set and asserts the
   six modules afterwards and `retire_legacy_upgrades() == 0` on the second call.
2. **`fit_module_at` never half-writes.** Every refusal precedes every write; the
   displacement happens before the take, so a swap can never lose the displaced module.
3. **`clear_fit` stays as it is** (whole-fit reset, used by the seed and tests);
   `clear_fit_slot` is the pane's per-cell remove.
4. **The pane never mutates directly** (STATION_HUB §12.4): panels request, the profile
   mutates. The pane may only call the two composed APIs, `fit_for`, `module_count`,
   `modules`, `ShipFit.*` and `Repairs.*`.
5. **Legality is previewed, not enforced twice.** The pane calls `ShipFit.fit_legal` on the
   candidate fit to colour the power meter and to gate the ACTION; the profile re-checks on
   commit. Both read the same function.

### 3.2 The FITTING pane (STATION_HUB §5.3, replacing UPGRADES)

- **Rail:** `Module.UPGRADES` becomes `Module.FITTING`; the label becomes `FITTING`; the
  entry keeps the retired entry's rail position, its icon path and its tint. The retired
  `ui/station/upgrades_panel.gd` and `.tscn` are deleted; nothing else in the rail moves.
- **Anatomy** — the §5.1 host-pane construct, two stacked sections:
  - **SLOT LAYOUT** — the active hull's grid, **the shipyard's own recipe** (`ShipFit.grid_cells`,
    `SlotButtonWeapon` 48 px plates, gaps as empty `Control`s, the type's slot glyph, the
    caption `SLOT LAYOUT · <n> CELLS · <m> ENGINES`). Unlike the shipyard's display, these
    cells are **selectable**: one selected at a time, `FOCUS_ALL`, the selected cell carrying
    the theme's focus ring; a cell's identity is its `slot_key` + `index` (09 §4.5's layout
    index). The recipe is shared with the shipyard (lift it into a helper both panes call, or
    duplicate it byte-equivalently) — the reviewer checks both grids render identically.
  - **OWNED MODULES** — one row per owned module **id** (aggregated by id), ordered by
    `ShipFit.FIT_SLOT_KEYS` then catalogue order: 48 px module icon, name, the meta
    `SLOT <TYPE> · DRAW <n>`, `OWNED ×<n>`, and ACTION.
- **ACTION per state:** `FIT` when a cell of the module's own type is selected and the
  module is legal there (calls `fit_module_at`); `SWAP` when that cell already holds another
  module (same call — the displaced one returns to the inventory); `SELECT A CELL`
  (disabled) when no cell is selected or the module's type has no selected cell.
- **The power meter** (footer strip, always visible): idle `PWR <Σ draws> / <out + power module>`;
  with a cell selected, the candidate's own line `PWR <Σ> / <out> · CANDIDATE <Σ'> / <out>`;
  when the candidate is over budget the same line renders in the danger colour and ends
  `— OVER BY <n>`. The numbers are `fit_legal`'s own `power` dictionary.
- **Hover / selection info (owner request 1):** the selected cell's line reads
  `<TYPE><n> · <MODULE NAME or EMPTY> · OWNED ×<n>`; the shipyard's plates gain the same line
  on hover (`shipyard_panel.gd`), reading the selected hull's `fit_for` entry.
- **Refusals** (footer strip, never a dialog): `13 / 11 PWR — OVER BY 2` (09 §2's own
  format, already pinned), `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` (new this pass),
  and `REFUSED · FIT ILLEGAL` as the catch-all for a fit illegal for any other reason
  (L77's guard, now named here as the third pinned refusal). The footer is never blank.
- **Focus order:** the SLOT LAYOUT cells first (row-major), then the OWNED MODULES rows,
  then the pane's own footer, then the rail (STATION_HUB §10).
- **Empty states:** an account that owns no modules shows one disabled row
  `NO MODULES OWNED · BUY THEM IN OUTFITTING`; a hull with every cell filled and nothing
  selected shows the meter and the grid, no refusal.

### 3.3 LAUNCH's service rows (owner request 4)

- §5.4's DECK CONTROL gains `REFUEL` and `RECHARGE` actions for the active hull, calling
  `Repairs.refuel(profile, active_ship)` / `Repairs.recharge(profile, active_ship)` and
  rendering the service's own result in the pane's status line (`fuel_max` / `energy_max`
  on success; the service's refusal reason otherwise). Free and instant — **no price column,
  no credits move** (14 §1's rate; `FREE_FEE` is 0).
- Already-full and no-damage-report states are the service's refusals, rendered, never
  hidden — the button stays pressable and the footer says why.

---

## 4. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **D0** | docs | `docs/` | `STATION_HUB.md` §5.3 becomes **FITTING** verbatim from §3.2 (UPGRADES' retirement recorded with its reversal), §5.4 gains §3.3's rows, §5.2 gains the hover line, §7.1's art map notes the FITTING rail entry reusing the retired icon; `09_ship_slots_modules.md` §4 gains the per-slot/mandatory-swap rules and §7 the retirement note; `10_ship_acquisition.md` §6's interim note names FITTING as the install surface; `15_module_affixes.md` gains the dated note that affixes are the next wave; `CONTRACTS.md` gains **§13** verbatim from §3 plus the v0.5 changelog line (and §9's expected gate figure moves when R1 measures it). No code, no number beyond the transcription. |
| **W1** | coder — profile & retirement | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/station_catalog.gd,vajb-orbit/tests/` | §3.1 exactly: `SAVE_VERSION` 5, `LEGACY_UPGRADE_MODULES`, `FIT_MANDATORY_KEYS`, `EVENT_FIT_MODULE`, `fit_module_at`, `clear_fit_slot`, `retire_legacy_upgrades`; the six legacy rows, `upgrade()`, `upgrade_ids()`, `has_upgrade`, `installed_upgrades`, `install_upgrade` and the `upgrades` key go; tests: the v4 fixture migration (all six → six modules, idempotent), the composed install/swap/remove round trip, the mandatory refusal, the not-owned refusal, the power refusal. |
| **W2** | coder — the FITTING pane | `vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/fitting_panel.tscn,vajb-orbit/ui/station/upgrades_panel.gd,vajb-orbit/ui/station/upgrades_panel.tscn,vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/` | §3.2: the pane, the rail swap (`Module.FITTING`), the deleted UPGRADES pane, the power meter, the refusals, the focus order, the empty state; tests: the grid renders the active hull's cells (gaps included), a per-cell install targets **that** cell, the swap returns the displaced module, the mandatory cell refuses with the pinned wording, the meter's numbers equal `fit_legal`'s. |
| **W3** | coder — shipyard hover & LAUNCH services | `vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/ui/station/launch_panel.gd,vajb-orbit/tests/` | §3.2's hover line on the shipyard's plates (owner request 1) and §3.3's REFUEL/RECHARGE rows (owner request 4); tests: the hover line's text for a fitted cell, an empty cell and an unknown hull; refuel/recharge success and the full-tank refusal rendered. |
| **R1** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Verify, never trust: re-run W1/W2/W3's probes byte-identically; re-measure the migration (build the v4 fixture yourself), the composed round trip, the mandatory refusal, the meter's arithmetic against `fit_legal`, the rail swap, the two service calls, and the shipyard hover; confirm the six legacy rows are gone from the catalogue and the panel; grep CONTRACTS §11/§12/§13 for drift; confirm no §13/§8 value moved and no weapon/engine/power number changed; tier HIGH/MED/LOW with the exact command and raw output; LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **F1** | coder — fixer | per-finding sets from R1's report | Only R1's HIGH/MED, one pass, each re-measured before and after with R1's own command. |

**Run order:** **D0 → W1 → W2 → W3 → R1 → F1** (F1 only if R1 leaves HIGH or MED). W2 and W3
are disjoint (no shared file) and may run in either order, but not at the same time as each
other; W1 must land before W2 (W2 consumes `fit_module_at`).

---

## 5. Tests that move (named, sanctioned)

- `tests/test_p1_profile.gd` — the six `upgrade` references move to W1's retirement tests;
  the suite may gain the migration assertions. **No existing assertion is deleted without its
  subject moving** — the upgrades surface is retiring, so its assertions retire with it, and
  the brief says so here.
- New: `test_p2b_retirement.gd` (W1), `test_p2b_fitting_panel.gd` (W2), `test_p2b_services.gd`
  (W3, may also live as additions to existing suites).
- The gate grows from **389**; R1 measures the final count, and the close-out writes it into
  CONTRACTS §9 and the WAVEBOARD.

---

## 6. Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; bounded Godot runs only (`--quit-after` on every
  runner, and every probe self-quits with its own hard bound — set-by-set: a probe that can
  loop must carry an iteration cap, see LOW L82's lesson); L17 probe hygiene.
- No `assets/**`, no theme, no `project.godot`, no `addons/**`; `docs/**` belongs to D0 only.
- **No invented number and no invented wording** — every cost, draw, capacity and refusal is
  09's, 12's, the pin's own, or explicitly pinned in §3 above.
- Only `PlayerProfile` mutates credits/cargo/modules/fits; panels only request.
- Delete the retired surface completely: no dead `upgrade` branches left behind, no
  commented-out rows, no unused constants.

---

## 7. Owner ticks (block nothing)

1. **FITTING takes the UPGRADES rail entry** (label `FITTING`, the retired entry's icon and
   position; no new art). Reversal: restore the label, the entry and the pane files.
2. **The six-row retirement table** (§3.1's `LEGACY_UPGRADE_MODULES`) — each successor is
   09's own lineage wording, and installed legacy upgrades convert to one inventory module
   each at save v5. Reversal: the mapping constant plus the catalogue rows.
3. **The pinned strings** — the power meter's `PWR <Σ> / <out>` and its `· CANDIDATE … —
   OVER BY <n>` form, `MANDATORY CELL — SWAP ONLY, NEVER EMPTY`, and `REFUSED · FIT ILLEGAL`
   as the catch-all.
4. **The four owner requests** land as §3.2's hover/selection line, the OWNED MODULES
   section, the shipyard-recipe grid, and §3.3's REFUEL/RECHARGE rows.
5. **Affixes (doc 15) are the next wave** — this wave's inventory aggregates by id and does
   not create instances. Reversal: none owed; the instance shape is 15's own.

---

## 8. Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline <tag> --forbidden
project.godot --expect-reports <the wave's reports> --tests`; WAVEBOARD updated (this wave
Done, the **AUCTION** and **affixes** queued behind it, the owner's remaining requests
re-checked against §7); CONTRACTS §9's figure and §13's changelog merged; wave-boundary
commit; report to the owner with the measured gate count, W1/W2/W3's numbers, R1's findings
by tier, and the ticks above.
