# Engine slice 0 — worker M3 (Station services, persistence, HUD pools). Report

Date 2026-09-21. Status: **complete, all three probes green, universal gate
accounted for line by line.**

Pinned interfaces implemented: task brief items **6 (HUD seam)**, **7 (station
services)**, **8 (persistence)**. Owner addendum of 2026-09-21 applied: refuel and
recharge are **free** (`fee 0`), no CR rate invented anywhere.

---

## 1. Files changed (my five only)

| File | Bytes | Diff |
|---|---:|---|
| `vajb-orbit/game/repairs.gd` | 9919 | +113 |
| `vajb-orbit/game/station_catalog.gd` | 6904 | +67 |
| `vajb-orbit/autoload/player_profile.gd` | 20576 | +64 |
| `vajb-orbit/ui/hud/hud.gd` | 31649 | +254 |
| `vajb-orbit/game/game.gd` | 21652 | +53 |

Nothing else was written: `git status` shows the other modified files belong to
M1/M2, the graphics lane and the wave's doc pass. No `assets/**`, no
`project.godot`, no theme, no `docs/**`, no test file.

## 2. What each seam now is

**`station_catalog.gd`** — `SERVICE_REFUEL`/`SERVICE_RECHARGE` ids plus a
`SERVICES` row table (`id`, `name`, `availability: &"all"`, `free`, `instant`,
`description`), read through `service(id)` / `service_ids()`, in the
`AMMO_PACKS`/`SHIPS`/`UPGRADES` shape. Transcribed from `14 §1`'s amended row
("every station; free and instant, no CR charged") and `18 §12` item 8. **No
price field exists in the rows** (probe `catalog c`) and no icon path was added,
because a path here would be a fresh unresolvable reference while the art tree is
being re-laid.

**`repairs.gd`** — `refuel(profile, ship_id) -> Dictionary` and
`recharge(profile, ship_id) -> Dictionary`, both all-or-nothing like `repair()`,
both reporting `fee: 0` from the single `FREE_FEE := 0` const (owner ruling; no
rate invented). `refuel` fills the tank to the hull's `fuel_max` and files it in
the same vitals record the damage report lives in, refusing a full tank
(`fuel_full`), an unfiled ship and an unbuildable hull (`no_damage_report`), and
a service the catalogue does not offer (`no_service`). The tank figure comes from
`ShipFit.resolve(hull, STANDARD_FIT).fuel_max` — the `18 §9/§13` single owner of
the pool numbers, and the same fit `game.gd` launches with, so the station fills
exactly the tank the launch seeds. `recharge` reports `energy_max` from the same
source and **persists nothing**, because `18 §12` item 13 keeps Energy out of the
record ("Energy recomputes at launch") — see the deviation in §5. Both log
through `economy_log` (`REFUEL`/`RECHARGE`, `+0` credits delta, live balance).
`fee`/`is_repairable`/`repair` are untouched.

**`player_profile.gd`** — save **v3** (`SAVE_VERSION := 3`, `MIN_READABLE_VERSION`
stays 1, so v1/v2 files still load). `set_vitals(ship_id, hull, shield, fuel :=
FUEL_UNFILED)` writes the tank beside hull and shield; `fuel` is **optional and
sticky** — a caller that passes none (the REPAIRS restore, every P1 caller) keeps
the filed tank instead of dropping the key, which is what keeps the P1 round-trip
tests exact. `vitals_of` returns the record as filed (`fuel` present only once a
dock has filed one, so a migrated report reads as "nothing filed" rather than an
empty tank — a v2 profile never boots into Emergency Flight Mode). A tank reading
that actually moved emits the new `profile_changed` key `&"fuel"`; hull/shield
writes stay silent (`17 §3`).

**`hud.gd`** — `set_pool(kind, value, maximum)` (`kind ∈ &"energy" | &"fuel"`) and
`set_emergency(active)`, plus the two blocks `UI_SPEC §3.1b` specifies: a header
row (title, spacer, current/max readout) over a 260×14 `ProgressBar`, appended
below `ShieldBlock`, and the `EMERGENCY FLIGHT` banner as the first child of the
column (above the blocks). Energy fill `metal_light`, Fuel fill `metal_mid` turning
`accent_danger` at ≤ 15 % (fill **and** readout), Energy fill `accent_danger` while
the mode lasts, banner in `accent_danger_bright`. Every colour is a `Tokens` role
composed into a `StyleBoxFlat` exactly the way the existing hull danger fill is —
no new theme item, no font-size override, no hex literal. The HUD also binds
`energy_changed`/`fuel_changed` (the hull/shield pattern) and reads
`emergency_mode` from `PlayerState` rather than re-deriving it. Blocks are built in
code because `hud.tscn` is outside this worker's file set (§5). `set_speedometer`
and `set_lock_progress` are slice-2 W5 scope and were **not** touched or
documented.

**`game.gd`** — `_apply_ship_maxima()` now also takes `energy_max`,
`energy_regen`, `fuel_max` from the launch snapshot (`18 §9`); `_seed_vitals()`
applies a **filed** tank (Fuel persists) while Energy is left to `setup()`'s
recompute; `_file_damage_report()` files hull, shield **and** fuel on dock;
`_push_pools()` pushes both pools and the emergency flag into the HUD from
`PlayerState` at the existing 0.1 s HUD cadence, behind `has_method` guards like
the prompt strip and the warp bar.

## 3. Acceptance, as measured

Probe sources are archived next to this report (`slice0_m3_station.{gd,tscn}`,
`slice0_m3_hud.{gd,tscn}`, `slice0_m3_game.{gd,tscn}`); copy one back into
`vajb-orbit/tools/` as `_probe_s0m3_<name>.gd` to re-measure. `tools/` is back to
`build_theme.gd` + `derive_icon_tints.gd` and no `.uid` was left behind.

```
"…_console.exe" --headless --path <proj> res://tools/_probe_s0m3_station.tscn --quit-after 1200
"…_console.exe" --headless --path <proj> res://tools/_probe_s0m3_hud.tscn     --quit-after 1200
"…_console.exe" --headless --path <proj> res://tools/_probe_s0m3_game.tscn    --quit-after 1200
```

| Probe | Result | Log |
|---|---|---|
| A — catalogue rows, refuel/recharge, `profile_changed fuel`, save v3 | `[SUMMARY] ok=26 failed=0`, exit 0 | `slice0_m3_probe_station.txt` |
| B — the two bars, the 15 % line, the banner, the PlayerState channel | `[SUMMARY] ok=23 failed=0`, exit 0 | `slice0_m3_probe_hud.txt` |
| C — launch seeding, pool push, dock filing on the shipped `game.gd` | `[SUMMARY] ok=14 failed=0`, exit 0 | `slice0_m3_probe_game.txt` |

Headline measurements (full lines in the logs):

- `refuel` on a filed `{hull 200, shield 300, fuel 55}` Vanguard returns
  `{ok: true, ship_id: ship_vanguard, fee: 0, fuel_max: 200}`; the record becomes
  `{hull 200, shield 300, fuel 200}` and credits do not move (`2969 -> 2969`).
  `fuel_max 200` == `ShipFit.resolve(vanguard, STANDARD_FIT).fuel_max` == the
  `§13` base. A second call refuses `fuel_full`.
- economy log: `…, REFUEL, ship_vanguard, 145, +0, 2969` and
  `…, RECHARGE, ship_vanguard, 0, +0, 2969`.
- `recharge` returns `{ok: true, fee: 0, energy_max: 100}` and files no energy key.
- `profile_changed`: a moved tank fires exactly once with `&"fuel"`; a
  repairs-style 3-arg write is silent and keeps `fuel 42`; filing `fuel 0` fires.
- save: scratch file reads back `save_version=3` and
  `{hull 200, shield 300, fuel 42}`; a v2 fixture (vitals without fuel) loads,
  keeps its own credits, and reads back with **no** fuel key, then refuels to 200
  without moving `hull 812`.
- HUD: block order `[EmergencyBanner, HullBlock, ShieldBlock, EnergyBlock,
  FuelBlock]`; both bars 260×14, `show_percentage = false`, every new node
  `MOUSE_FILTER_IGNORE`; Energy `metal_light`, Fuel `metal_mid`; at exactly 15 %
  the fuel fill **and** readout are `accent_danger` and above it both return; the
  Energy readout never takes a danger colour; `set_emergency(true)` shows the
  banner in `accent_danger_bright` and turns the Energy fill `accent_danger`,
  `false` restores; `PlayerState.set_fuel(0)` raises the banner through the
  signal alone; an unknown `kind` is ignored.
- `game.gd` (probe C, shipped source with one stubbed preload, see §5): pools take
  `100/200` from the snapshot; the filed tank seeds `fuel = 80` on a `80` report
  while `energy = 100/100` recomputes; the HUD's Fuel bar reads `80/200`; the
  game's own push moves both readouts (`35/100 | 20/200`) and raises/hides the
  banner; docking files `{hull 700, shield 400, fuel 64}` and that lands in the v3
  save file.

Universal gate (`res://tests/headless_runner.tscn --quit-after 1200`):

| Run | Result | Exit | Log |
|---|---|---|---|
| before my changes | `[SUMMARY] passed=78 failed=0` | 0 | `slice0_m3_testgate_before.txt` |
| after my changes | `[SUMMARY] passed=77 failed=1` | 1 | `slice0_m3_testgate.txt` |

The single failure is **`test_p1_profile.gd.test_v2_round_trip_for_every_key`
("writes always persist v2", `tests/test_p1_profile.gd:204`)** — the stale P1
assertion that a write persists `save_version 2`. It is the direct consequence of
the mandated v3 bump and it is in a file outside my set; see §5 item 2. No other
test moved; the count is unchanged (78).

Boot gates (all exit 0, before and after identical):

| Scene | Errors | Log |
|---|---|---|
| `res://game/game.tscn` | `assets/env/env_station.png` preload (sector.gd) + `env_stars_layer{1,2,3}.png` ext_resources | `slice0_m3_boot_game[_before].txt` |
| `res://ui/screens/main_menu.tscn` | `assets/env/env_menu_bg.png` | `slice0_m3_boot_menu[_before].txt` |
| `res://ui/screens/settings.tscn` | none | `slice0_m3_boot_settings[_before].txt` |
| `res://ui/screens/station.tscn` | none | `slice0_m3_boot_station[_before].txt` |

Hygiene: the probes repoint `PlayerProfile.save_path` and `EconomyLog.log_path` at
`user://` scratch files before writing anything and restore them afterwards. The
player's real `profile.cfg` md5
(`c1ef5ddb47528a08a71fb75adeb33733`) is unchanged by every probe re-run, and all
scratch files were removed.

## 4. Owner addendum — compliance

1. **Free services.** `refuel`/`recharge` return `fee: 0`; the const is
   `FREE_FEE := 0`; nothing in `station_catalog.gd`, `repairs.gd`, the HUD or the
   report carries a CR-per-fuel-point number or any other invented rate. No
   service lowers credits (probe `A/refuel c`).
2. **Assets.** No asset path was touched, no file outside my five was edited; the
   stale strings in `hud.gd` (the 11 `assets/icons/tint/…` preloads) and in
   `game.tscn`/`sector.gd` are exactly as found. New references were deliberately
   not introduced (the service rows carry no icon).
3. **Gate arithmetic.** The expected `52/1` did not reproduce: the measured
   pre-change baseline was `78/0` (M2's suites had landed and
   `test_p1_catalogues` passes now that `mineral_catalog.gd` was re-pathed). The
   asset-path failures in this environment are exactly the `game.tscn`,
   `main_menu.tscn` and `sector.gd` ones above, unchanged by my work; every check
   that does not depend on moved art passes, with the one version-assertion
   exception of §5 item 2.

## 5. Deviations, judgement calls and environment-deferred items

1. **`recharge` persists nothing (the one real judgement call).** `18 §12` item 13
   keeps Energy out of the vitals record ("Energy recomputes at launch"), so there
   is no field for an instant Energy top-up to write. Rather than invent an
   `energy` key that the launch would ignore, `recharge` returns the free-rate
   report plus `energy_max` and lets `PlayerState.setup()` do the filling it
   already does (`launch b` proves the pool is full at launch). The service is the
   panel's row and the contract's report of that behaviour. If M4 rules that the
   station must persist a buffer, the change is a `vitals` key plus a
   `_seed_vitals` branch — flagged, not guessed.
2. **Save v3 breaks one P1 assertion (wave-owned follow-up, not mine to fix).**
   `tests/test_p1_profile.gd:204` asserts `save_version == 2` with the message
   "writes always persist v2". The mandated bump makes that assertion false. The
   fix is one line in that test file (expect `3` and update the message); the file
   is outside my declared set and the enforcement hook denies it, so I left it and
   report it. Until it is patched the universal gate reads `passed=77 failed=1`.
3. **The REPAIRS panel does not yet list the two services.** `14 §2`/`12 §8` put
   `refuel` and `recharge` rows in the services menu, and the brief asked the
   existing panel to show them. `ui/station/repairs_panel.gd` and its `.tscn` are
   **not** in M3's file set, so the panel could not be touched; what landed is the
   data (`StationCatalog.SERVICES` + `service()`/`service_ids()`) and the two
   service functions the panel will call — the same shape `repairs_panel.gd`
   already uses for `RepairsService.fee`. Follow-up for the station/UI lane: add
   the two rows to `REPORT_ROWS` or a small service strip and wire the buttons to
   `Repairs.refuel` / `Repairs.recharge` (no new panel, no new theme tokens).
4. **The HUD blocks are built in code, not in `hud.tscn`.** `ui/hud/hud.tscn` is
   not in my set either, and §3.1b asks for two more blocks in the TopLeft column.
   `hud.gd:_build_pool_blocks()` therefore mirrors the scene's `HullBlock` pattern
   node for node (measured identical in shape and styling, probe B) and is
   idempotent in effect. Moving the blocks into the scene later retires that
   builder; until then nothing else may add an `EnergyBlock`/`FuelBlock` under
   `CanvasLayer/TopLeft/Blocks`.
5. **`game.gd`'s runtime is measured through a stub copy (environment-deferred).**
   `game.gd` cannot load while `sector.gd`'s `env_station.png` preload is stale
   (the graphics lane's re-path), and `game.tscn` cannot load while its three star
   textures are stale, so no plain boot gate exercises the file. Probe C runs the
   **shipped source** with exactly one substitution — the unresolvable
   `const SectorScript := preload("res://game/sector.gd")` becomes an inline
   `SectorScript` stub with the same four method signatures, printed by the probe
   — on a hand-built `Node2D "Game" + Camera2D` that matches `game.tscn`'s node
   shape. That is the strongest measurement available today; re-run the probe
   unpatched once the re-path lands.
6. **Side observation, not probe data.** The `station.tscn` boot gate persisted
   the dev profile's normalised market band on first run (mtime 01:53, now
   `save_version=3`). Content verified: the real balance/keys, no probe values, no
   fuel entry. Flagging it because it is the only real-file write seen in this
   session and it was not mine.

## 6. Left to M4/M5

- Ruling on §5 item 1 (`recharge` persistence) and patching §5 item 2 (the v2
  assertion) so the gate returns to `0` failures.
- Deciding whether `StationCatalog.SERVICES` should also carry the eventual panel
  labels/icons once the art re-path lands (§5 item 3, §5 item 4 are the wiring).
- CONTRACTS.md §7/§8 belong to M4: the addition here is `Hud.set_pool` /
  `Hud.set_emergency` (§3.1b), `Repairs.refuel` / `Repairs.recharge` (free),
  `PlayerProfile.set_vitals(…, fuel)` + `profile_changed &"fuel"` + save v3, and
  `game.gd:_push_pools()`.
