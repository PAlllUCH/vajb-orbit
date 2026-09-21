# Wave P2-B1 — the weapon fit surface (weapons gating) — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (§8 economy seams, §11 — P2-A's
pin this wave consumes), `docs/gameplay/09_ship_slots_modules.md` §1/§2/§3.1/§4/§5/§7/§9,
`docs/gameplay/10_ship_acquisition.md` §2/§5/§6, `docs/gameplay/08_ship_classes.md` §3,
`docs/gameplay/17_coder_handoff.md` §5 (transaction law), then this brief, then
`.agents/gen/WAVEBOARD.md`. **Runs after wave P2-A (item 4)** — its APIs are this
wave's floor. The gate before this wave is whatever P2-A closed at (measure it).

## 1. The owner ruling this wave executes (2026-09-21, verbatim)

*"add weapons gating. only starting laser should be usable/equipped, others have
to be added to ship/laser has to be swapped for something else"*

**What already exists** (measured): only a *fitted* weapon mounts and fires —
`game.gd` resolves the active hull's own fit and `weapons.gd` mounts its weapon
ids, so the standard fit's single `w_laser` is the only gun (slice 2.5's probes
measured `launched_fit=[w_laser]` throughout). The HUD shows the hull's W cells.
**What is missing is the acquire-and-install loop**: the player cannot obtain
another weapon module or put it into a W slot, so the gate is real but has no
door.

This wave builds that door, and nothing else:

- **BUY** — the six weapon modules of 09 §3.1 are purchasable into the profile's
  module inventory: `w_cannon` 1 200, `w_mining` 600, `w_rocket` 2 400,
  `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200 (09 §3.1's costs, frozen).
  The interim shop surface is **OUTFITTING**, per 10 §5's precedent (legacy rows
  stay purchasable there until the fitting phase ships); the AUCTION module is
  10 §2's proper home and stays future.
- **INSTALL / SWAP / REMOVE** — the active hull's W slots (count from
  `ShipFit.grid_counts(active_hull)[&"weapons"]`, cells in §9's standard-fit
  order): INSTALL fills the **first empty W cell**; with none empty the action is
  SWAP — the displaced module returns to the inventory, never destroyed (09 §4.8).
  REMOVE empties a named cell back into the inventory. **The mandatory set is
  untouchable from this surface** — engines and the reactor have no rows here.
- **Legality** — every install/swap runs `ShipFit.fit_legal(hull_id, fit)` (P2-A
  W1): capacity, the no-duplicate rule for computers/engines, and the power
  budget (`Σ draws ≤ power_out + power module`). An illegal fit is **refused with
  the overload shown** — 09 §2's own wording, `13 / 11 PWR — OVER BY 2` — nothing
  auto-removes.
- **Flight side changes nothing**: the launch already resolves the hull's fit, so
  a swapped laser mounts as a cannon on the next launch and the trigger honours
  it. In-space refitting does not exist in v1 (09 §4.8).

## 2. What is measured (do not re-discover)

- **P2-A (item 4) lands the APIs this wave consumes** — read its reports in
  `.agents/gen/p2a_*.md`: `ShipFit.grid_counts/grid_cells/fit_legal/standard_fit`,
  `ModuleCatalog.module()/icon_path()/slot_of()`, and `PlayerProfile.fit_for /
  set_fit_slot / clear_fit / module_count / add_module / take_module` with
  `profile_changed(&"fits")` / `&"modules")` and save v4. **If any of those is
  missing when this wave starts, stop and report** — do not re-implement them.
- The panel to amend is `ui/station/outfitting_panel.gd`/`.tscn` (ammo rows today,
  `STATION_HUB.md` §5.1's construct: 40 px icon, title, meta, EFFECT, PRICE,
  STATUS; `CELL_SEPARATION` 2; the row grid is the D0 text's law).
- `PlayerProfile` transaction law (17 §5): verify → charge/take → pay/give →
  emit → log, integers only, every economy event writes an
  `economy_log` line. `EconomyLogScript.append(event, id, qty, delta, credits)`
  is the shipped logger.
- Module icons all ship (`assets/icons/module/icon_module_<id>_48.png`, weapon
  families use `assets/icons/weapon/icon_weapon_<family>_48.png` — P2-A's icon
  rule). No art is owed.

## 3. The pinned interface (CONTRACTS §12, D0 lands it verbatim)

```gdscript
## autoload/player_profile.gd — additive beyond P2-A's §11 pin.
func buy_module(module_id: StringName, cost: int) -> bool
    # 17 §5: refuse when unknown/insufficient (purchase_failed), else spend(cost),
    # add_module(module_id, 1), profile_changed(&"modules"), one EconomyLog line
```

Consumer rules (STATION_HUB §5.1 amendment, D0 lands verbatim; the numbers are
09 §3.1's):

- The pane gains a `MODULES` caption and six weapon rows above the ammo packs,
  one per module in 09 §3.1's table order (`w_laser` 900 first, then `w_cannon`
  1 200, `w_rocket` 2 400, `w_mine` 1 800, `w_plasma` 4 800, `w_railgun` 5 200,
  `w_mining` 600), each row: 48 px module icon, name, `W SLOT · DRAW n` meta, the
  09 §3.1 effect text, PRICE, STATUS, ACTION.
- STATUS: `FITTED (Wk)` when installed on the active hull, `OWNED ×n` in the
  inventory, `FOR SALE` when affordable, `LOCKED` otherwise.
- ACTION per state: `BUY` (buy_module) → `INSTALL` (first empty W cell; none
  empty → the row offers SWAP, the displaced module returns to inventory) →
  `SWAP` → `REMOVE`.
- Above the rows, a **FITTED WEAPONS** strip: one line per W cell of the active
  hull — `W1 LASER MKII` / `W2 — EMPTY` — each fitted line carrying REMOVE; the
  strip reads `ShipFit.grid_cells` + `PlayerProfile.fit_for` and never mutates
  directly (panels request, the profile mutates — STATION_HUB §12.4).
- Refusals render in the footer strip the panel already owns
  (`status_requested`), never a dialog.
- Focus order: the fitted strip first, then the module rows, then the ammo rows
  (Tab order, STATION_HUB §10).

## 4. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **D0** | docs | `docs/` | `docs/design/STATION_HUB.md` §5.1 gains the MODULES section + the fitted strip **verbatim** from §3 (rows, states, refusals, focus), and §7's art map gains the module icon paths; `docs/gameplay/10_ship_acquisition.md` §6 gains the dated interim note (OUTFITTING sells the six weapon modules until the AUCTION module exists; the surface retires into it then); `docs/gameplay/09_ship_slots_modules.md` §4.8 gains the same pointer; `docs/CONTRACTS.md` gains **§12** verbatim from §3 plus a §10 changelog line. No code, no numbers beyond the transcription. |
| **W1** | coder — the purchase seam | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `buy_module` exactly as §3 pins it (refusals reuse `purchase_failed`'s reasons; the log line is `EVENT_BUY_MODULE` or the nearest shipped event id), plus tests: a successful buy round-trips inventory + credits + signal + log line, and the insufficient/unknown refusals. |
| **W2** | coder — the panel | `vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/tests/` | The MODULES section + the fitted strip, reading `ModuleCatalog` / `ShipFit` / `PlayerProfile` and writing only through the profile's APIs; every refusal of §3 rendered; `refresh_profile` reacts to `&"fits"` and `&"modules"`. Tests: buy→install→swap→remove round-trip on the Vanguard's 3 W cells, the power-overload refusal with the exact wording, the full-cells refusal, the mandatory set untouched, and `profile_changed` driving the refresh. |
| **R1** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-run W2's probe byte-identically; re-measure the round-trip and the refusals; check every row against 09 §3.1's costs/draws and §4's rules; grep CONTRACTS §8/§11/§12 for drift; confirm no §13 row and no weapon damage/cadence/range value moved; tier HIGH/MED/LOW with raw output. LOW → `.agents/gen/LOW_BACKLOG.md`. |
| **F1** | coder — fixer | per-finding sets from R1's report | Only R1's HIGH/MED, one pass, each re-measured before and after with R1's own command. |

Run order: **D0 → W1 → W2 → R1 → F1** (only if R1 leaves HIGH or MED).

## 5. Tests that move (named, sanctioned)

- `tests/test_p1_profile.gd` may gain assertions (it owns the profile); **no
  existing test's assertions change** — additions only. The gate grows.

## 6. Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; bounded Godot runs only; L17 probe
  hygiene; the gate `godot --headless --path vajb-orbit
  res://tests/headless_runner.tscn --quit-after 1200`.
- No `assets/**`, no theme, no `project.godot`, no `addons/**`; `docs/**` belongs
  to D0 only. **No invented number** — every cost, draw and wording is 09 §3.1's
  or §3's transcription.
- Only `PlayerProfile` mutates credits/cargo/modules/fits; panels only request.

## 7. Owner ticks (block nothing)

1. **OUTFITTING as the interim shop** — the six weapon modules sell there until
   the AUCTION module exists (10 §2's design), then the rows move; 10 §5's
   precedent, recorded by D0.
2. **The refusal wordings** (`13 / 11 PWR — OVER BY 2`, `W SLOTS FULL — SWAP OR
   REMOVE FIRST`) — 09 §2's format plus two new lines; cosmetic, D0's.
3. **INSTALL targets the first empty W cell** (no slot picker in this wave) —
   the full fitting panel with per-slot choice and the affix inventory is
   **P2-B proper**, briefed after P2-A's review.

## 8. Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline p2b1_start
--forbidden project.godot --expect-reports <the wave's reports> --tests`;
WAVEBOARD updated (this wave Done, **P2-B proper** queued behind it); wave-boundary
commit; report to the owner with the measured gate count, the round-trip numbers,
R1's findings by tier, and the ticks above.
