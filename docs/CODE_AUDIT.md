# CODE_AUDIT — full-code evaluation (2026-10-19)

Status: **executed the same day.** The 2026-10-19 sweep landed the P0 plan below
(shared panel base, test harness, lazy station panes, guardrails). The
"Before → after" columns are measured, not estimated; the remaining P1/P2 items
are what is still open.

Repeatable half: `python3 staging/code_audit.py` (inventory, duplicate functions,
duplicate 8-line blocks, class usage). Runtime numbers were taken in the live
editor on the Linux host, Godot 4.7.2-stable, Forward+, 1920×1080. The gate was
`python3 staging/gate.py --times 2`; it read **1433/0 ×2 byte-identical, zero
`SCRIPT ERROR`** on this tree.

## 0. Headline

- **171,864 GDScript lines**: 69,573 production (104 files) + 102,291 tests
  (233 files). 35 production scenes, 129 scenes total, 51 production
  `class_name`s, 6 project autoloads.
- **Duplication is down across the board.** Production: **102 → 89 duplicate
  clusters**, **1,526 → 995 redundant lines**. Tests: **255 → 238 clusters**,
  **4,560 → 3,376 redundant lines**.
- **The station's eager build is gone.** Boot: **2,058 → 1,029 ms**; nodes:
  **2,427 → 305**; static memory: **162.8 → 121.5 MB**. The first open of a pane
  pays its own build once; the rail's hover/focus prefetch warms it before the
  click.
- **Flight is unchanged and healthy**: 831 nodes, 184 draw calls, 1.2 ms
  physics.
- **Orphans are gone**: the last one, `ui/components/inspect_chip.gd`, is
  deleted (its geometry pin is cited in `UI_SPEC.md` directly). The 1,356-line
  `_mockup_station` scene/script is also deleted.
- **Record drift fixed**: `README.md` quoted `passed=524`; `CHANGELOG.md` now
  carries the 0.4 and 0.5 playtest entries.

## 1. Inventory and layers

| Layer | Files | Lines | Role |
|---|---:|---:|---|
| `autoload/` | 6 | 5,360 | singletons: Settings, Audio, Router, Dialog, Profile, Clock |
| `game/` | 40 | 29,685 | simulation, catalogs, economy, combat, flight |
| `ui/` | 40 | 30,121 | screens, station panels, HUD, components, theme helpers |
| `tools/` | 18 | 4,407 | standalone `--script` probes and generators |
| `tests/` | 233 | 102,291 | 121 gate suites + 109 probes + 3 harness files |
| **total** | **337** | **171,864** | `addons/` is vendored and excluded |

- Production scenes: **35**. Tests own 94 scenes (suites mount real scenes;
  probes have their own scene).
- Autoloads (one instance each, registered in `project.godot`):
  `SettingsManager`, `AudioManager`, `Router`, `DialogManager`,
  `PlayerProfile`, `WorldClock`; plus the editor-only `_mcp_game_helper`.
- The test suite is **60 % of all code**. It is not dead weight: the gate is
  1,433 rows. The stateless fixtures now live in `tests/support.gd`; the
  remaining duplicates are suite lifecycle/state, not copy-paste rules.

## 2. Class taxonomy and usage

Measured by `staging/code_audit.py`; "refs" counts production files only, so
test-only consumers are deliberately excluded. The complete per-file,
per-script user list (including class_name consumers) is `docs/CODE_MAP.md`
Section 4; this is the ranked summary.

| Domain | Classes / files | Shape |
|---|---|---|
| Autoload services | `PlayerProfile`, `SettingsManager`, `AudioManager`, `Router`, `DialogManager`, `WorldClock` | one node each, mutable state, cross-scene API |
| Data catalogs | `ModuleCatalog`, `ComponentCatalog`, `MineralCatalog`, `StationCatalog`, `CraftingCatalog`, `ContractRegistry`, `NpcRegistry`, `SectorRegistry`, `StationRegistry`, `LootTables`, `Affixes` | static const tables + read-only accessors; no nodes, no mutation |
| Simulation | `Game`, `PlayerShip`, `NpcShip`, `NpcBrain`, `Weapons`, `WeaponComponent`, `Projectile`, `Asteroid`, `AsteroidField`, `Pickup`, `Gate`, `Corridor`, `Poi`, `Sector` | scene-owned nodes; per-frame work is bounded and throttled |
| Stats / fit | `ShipFit`, `ShipStats`, `PlayerState`, `Damage`, `Repairs`, `Refinery`, `Shipyard`, `Exchange`, `Auction` | static resolvers + per-instance snapshots |
| UI shell | `Screen`, `UIPaths`, `Router` consumers, screen scripts | scene routing, theme, overlays |
| Station panels | `StationPanel` + 12 `*_panel.gd` files | one shared base; each panel is a `VBoxContainer` |
| HUD | `Hud`, `Hud` children (`Minimap`, `MapDeck`, `TargetReticle`, `CockpitCluster`, `ShipStatusScreen`, `SlotButton`) | one HUD scene, instrument children |
| Components / theme | `ChromeFamily`, `CockpitStyle`, `ArmoryStyle`, `CargoSummary`, `InspectSheet`, `Tooltip`, `MenuButton`, `ShipSlots` | shared look/behaviour helpers |

Most-referenced production classes:

| Class | Refs | Files | Class | Refs | Files |
|---|---:|---:|---|---:|---:|
| `ShipFit` | 196 | 26 | `StationCatalog` | 28 | 15 |
| `PlayerState` | 82 | 13 | `NpcShip` | 27 | 9 |
| `ShipStats` | 58 | 19 | `WeaponComponent` | 23 | 5 |
| `ModuleCatalog` | 58 | 15 | `Repairs` | 21 | 6 |
| `PlayerShip` | 57 | 11 | `Damage` | 20 | 7 |

Low-reference classes are small surfaces, not dead code: `CargoSummary` is
consumed through a `preload` alias in `cargo_overlay.gd` (so its `class_name`
token is never spelled), and `CockpitCluster` is constructed by `hud.gd:986`.
There are no unreferenced production scripts now: `CODE_MAP` reports zero
orphans after the `inspect_chip.gd` deletion (Section 6).

## 3. Data and persistence (the "databases")

There is no SQL/NoSQL database. Mutable state is a small set of files; the rest
is compile-time data.

| Store | Owner | Backing | Mutability / consumers |
|---|---|---|---|
| Player save | `autoload/player_profile.gd` | `user://profile.cfg`, `ConfigFile`, `save_version 7` | the only gameplay save; one debounced writer; migrations v1→v7 |
| Settings | `autoload/settings_manager.gd` | `user://settings.cfg`, `user://inputs.cfg` | writes on change; UI and input read |
| Economy log | `game/economy_log.gd` | `user://economy_log.txt` | append-only, never read at runtime |
| Dev tuning | `ui/dev/dev_tuning_menu.gd` / `game/ore_tuning.gd` | `user://dev_tuning.cfg` | dev-only overlay |
| Cockpit style | `ui/hud/cockpit_style.gd` | `res://ui/hud/cockpit_style_user.tres` or defaults | resource load, no runtime writer |
| Armory style | `ui/station/armory_style.gd` | `res://ui/station/armory_style_user.tres` or defaults | resource load, no runtime writer |
| World clock | `autoload/world_clock.gd` | system time + 20-minute bands | stateless; no timer per consumer |
| Auction shelf / exchange / contracts | `PlayerProfile` state + static resolvers | in-memory, persisted in the save | one owner, static read/transaction functions |

Compile-time catalogs (no persistence): `ModuleCatalog` (36 base + 15 variant
rows, 16 prefixes, 13 suffixes, 8 source tables), `ComponentCatalog` (20),
`MineralCatalog` (20), `StationCatalog` (9 ships, 8 ammo packs),
`CraftingCatalog`, `ContractRegistry` (4 live rows + seams), `NpcRegistry`
(9 population rows + 2 arena bosses), `SectorRegistry` (7 sectors),
`StationRegistry` (9 places), `LootTables`, `Affixes`, `ShipFit.HULLS` (11).

**Ownership rule that holds:** a registry is static and read-only; a panel
never owns state; all currency/cargo mutations go through `PlayerProfile`.
The audit found no second save path and no duplicate mutable store.

## 4. Duplication findings

Method: exact normalized function bodies (comments/blank lines stripped,
> 40 chars) and 8-line sliding windows. This measures copy-paste, not
similar-looking code.

### 4.1 Production

- **89 duplicate clusters, 995 redundant lines**, 304 duplicated 8-line blocks.
- Most copied helpers remaining: `_token` ×16, `_notification` ×9,
  `_make_label` ×7, `_profile` ×5, `_emit_sheet` ×5, `_on_scroll_started` ×4,
  `_active_id` ×4, `_check` ×4, `_service` ×3, `texture` ×2, `_exit_tree` ×2,
  `_make_tween` ×2.
- **What the sweep removed:** the 12 station panels no longer carry their own
  `_token` (except the armory's style override), `_format_int`, `_make_tween`,
  `_exit_tree`, `_pulse`, `_profile`, `_clear_list`, `_base_id`, `_active_hull`,
  `_vitals`, `_plate_texture`, `_strip_chip_box`, `_slot_glyph`, and
  `_load_texture`. They inherit `StationPanel` instead.
- **One slot table:** `ui/components/ship_slots.gd` now owns the eight slot
  glyph stems; the armory, fitting, shipyard and ship-status screen read it.
- **One hot-price rule:** `Auction.hot_price` delegates to
  `ModuleCatalog.hot_price`; the duplicate 20 % constant is gone.

Remaining families worth a later pass:

| Helper family | Copies | Where |
|---|---:|---|
| `_token` | 17 definitions | HUD, minimap, status screen, inspect sheet, menu/slot buttons, cargo overlay, screens |
| `_notification` | 10 definitions | station panes and screens; each has pane-specific extra work |
| `_make_label` | 8 definitions | three signature variants; not a safe mechanical merge |
| `_profile` | 6 definitions | `game.gd`, cargo overlay, status screen, weapons, NPC/player state |
| `_emit_sheet` | 6 definitions | station panes; tied to their own `_sheet_payload` and signal |
| `_service` | 4 definitions | the four node autoloads; a shared lookup is the next small win |
| `texture` / `_on_scroll_started` / `_active_id` / `_check` | 4 each | one or two screens each; local idioms |

### 4.2 Tests

- **238 duplicate clusters, 3,376 redundant lines** (was 255 / 4,560).
- Most copied now: `teardown` ×32, `suite_teardown` ×17, `_on_status` ×13,
  `_last_status` ×11, `_fresh` ×10, `suite_setup` ×9, `_open_game` ×8,
  `_last_danger` ×7, `_free_station` ×7, `_log_lines` ×6, `setup` ×6,
  `_host` ×6.
- **What the sweep removed:** the stateless helpers now live in
  `tests/support.gd`: `tree`, `near`, `delete_file`, `deep_eq`, `cell_text`,
  `profile`, `fixture_host`, `audio`. 113 test files were migrated in the first
  pass and 51 in the second; 224 helper definitions were removed.
- The remainder is suite-local state: each suite's `teardown` frees its own
  nodes, `_fresh` builds its own profile path, `_on_status` appends to its own
  array. A shared base fixture could reduce it, but that is a test-architecture
  change, not a mechanical dedupe; it is deferred.

### 4.3 What is *not* duplication

- The catalogs are intentionally separate (module/component/mineral/station/
  contract/NPC/sector). They have different keys and different owners; merging
  them would be a worse coupling, not a cleanup.
- `PlayerProfile`'s save keys and `CONTRACTS.md` pins are the yardstick. Do not
  collapse names that the docs treat as separate concepts.
- `NpcRegistry`'s 281 key occurrences across 11 archetypes are a data table.
  `tests/test_code_health.gd` now pins every required key, so a dropped key is
  a red row instead of a silent fallback.

## 5. Runtime and performance (measured)

### 5.1 Station — before and after the lazy-pane sweep

| Metric | Before | After |
|---|---:|---:|
| Boot to helper-ready | 2,058 ms | **1,029 ms** |
| Nodes / Controls | 2,427 / 2,414 | **305 / 295** |
| Objects | 7,821 | **2,536** |
| Static memory | 162.8 MB | **121.5 MB** |
| Draw calls / primitives | 103 / 1,896 | 103 / 1,896 |
| Idle process time | 6.55 ms | 6.92 ms |
| FPS | 165 | 165 |

Only OVERVIEW and the SERVICES deck chrome are built at boot. The six module
panes and the three service panes are built by `_panel_for` /
`_ensure_service_pane` on first use. The rail's `mouse_entered` / `focus_entered`
prefetch warms the pane before the click.

First-open cost, cold (includes one process frame; the number the player feels
once):

| Pane | Cold open |
|---|---:|
| Armory | 227 ms |
| Refinery | 93 ms |
| Exchange | 116 ms |
| Auction | 416 ms |
| Shipyard | 96 ms |
| Launch | 48 ms |

The Auction is the outlier because its shelf draws on entry. It is the one pane
worth prewarming further (e.g. a thread-loaded first shelf), but it no longer
costs every station boot.

### 5.2 Flight (unchanged)

| Metric | Value |
|---|---:|
| Boot to helper-ready | **3,056 ms** |
| Nodes / Controls | **831 / 581** |
| Objects | 3,530 |
| Static memory | **136.0 MB** |
| Draw calls / primitives | 184 / 7,486 |
| Physics process | **1.217 ms** |
| FPS | 164 |
| Live entities | 54 asteroids, 5 NPCs |

### 5.3 What the code already does well

- No `find_child` / `find_children` calls in production; only 3 `get_node`
  calls. Nodes are reached by `$` / `%` paths.
- No `load()` inside `_process`; 284 `preload` sites and resource-cached
  `load()` for textures/styles. No per-frame resource loading was found.
- HUD refresh is throttled (`game.gd:579`, `HUD_REFRESH_INTERVAL`), not run
  every physics tick.
- Group scans are event/targeting driven (`weapons.gd:1925`, `2402`), not a
  per-frame world sweep; the flare path is the only repeated scan and only
  while a flare lives.
- Six autoloads, one instance each; registries are static, not nodes.
- The station's only `_process` (`station.gd:1923`) is a no-op unless the
  departure sequence is running.

## 6. Dead, stale and risky

| Item | Evidence | State |
|---|---|---|
| `ui/components/inspect_chip.gd` | the only true orphan | **deleted 2026-10-19**; `UI_SPEC.md` now cites the §8 P1 / N37 pin directly |
| `ui/screens/_mockup_station.gd` + `.tscn` | 1,356-line throwaway; STATION_HUB §12.6 and CLEANUP_PLAN both planned deletion when the real screen landed | **deleted 2026-10-19** |
| `ui/station/fitting_panel.tscn` | not instantiated by production; tests mount it; `auction_panel.gd:52` preloads the script only | keep for tests; do not add production callers |
| `README.md:34` | quoted `passed=524` | fixed to the gate wrapper / 1433 |
| `CHANGELOG.md` | had 0.2, 0.3 and vote-site only; the records say 0.4 and 0.5 shipped | 0.4/0.5 entries added |
| `docs/CODE_MAP.md` orphan list | listed `ship_stats.gd`, `cockpit_cluster.gd` and every `tools/` script as orphans | fixed in `staging/build_code_map.py`: `class_name` consumers count, `tools/` is separate |
| God files | `armory_panel.gd` 4,493; `game.gd` 3,778; `player_profile.gd` 3,305; `hud.gd` 2,686; `weapons.gd` 2,664 | do not split speculatively; split only at the next feature that touches them |

## 7. Recommendations, ranked

### P0 — landed in the 2026-10-19 sweep

1. **`StationPanel` base.** One helper suite for the 12 station panes; the
   armory's `_token` override is the one documented exception.
2. **`tests/support.gd`.** Stateless fixtures centralized; the remaining test
   duplicates are suite-local lifecycle.
3. **Lazy station panes.** Boot/memory win above; rail hover/focus prefetch.
4. **Guardrails.** `tests/test_code_health.gd` pins the base-class rule, the
   no-re-declaration rule and the NPC required-key rule.

### P1 — next small consistency pass

5. A shared UI token/format kit for the remaining `_token` copies outside the
   station panels (HUD, screens, components). This is the largest remaining
   copy-paste family.
6. One weapon-family source: `PlayerState.WEAPONS` for the five, with the HUD
   adding its two extra ids explicitly.
7. One `_service` lookup for the four node autoloads.
8. One `_load_texture` already landed in `StationPanel`; the remaining
   `_on_scroll_started` / `_active_id` / `_check` families are one-per-screen
   idioms and can stay.
9. ~~Repoint the `UI_SPEC.md` `inspect_chip.gd` citation and delete the orphan.~~
   Done in the sweep.

### P2 — only when the owning feature moves

10. Split `armory_panel.gd` and `game.gd` along their existing comment banners;
    do not split for line count alone.
11. A shared test fixture base class for the suite lifecycle hooks, if the test
    suite keeps growing.
12. Keep the catalogs separate; add a table test when a new one lands (the NPC
    one is the template).

## 8. Changes made in this pass

- Added `ui/station/station_panel.gd` (the shared panel suite) and migrated 12
  `*_panel.gd` files to it; removed ~530 redundant production lines, plus the
  1,356-line dead mockup.
- Added `ui/components/ship_slots.gd`; removed the four duplicate slot tables
  and the three duplicate `_slot_glyph` bodies.
- Added `tests/support.gd`; migrated 113 + 51 test-file passes and removed 224
  helper definitions.
- Made station module/service panes lazy; added rail hover/focus prefetch;
  updated the tests that read the private pane arrays to use the public
  `pane_for` / `panes` / `service_panel` doors.
- Added `tests/test_code_health.gd` (3 rows) as the maintainability guardrail.
- Deleted `_mockup_station.gd` / `.tscn` / `.uid` (the dead approval mockup)
  and the last orphan, `ui/components/inspect_chip.gd`; `CODE_MAP` now reports
  zero orphans.
- Centralized `_load_texture` in `StationPanel`; `Auction.hot_price` now
  delegates to `ModuleCatalog.hot_price`.
- Added `staging/code_audit.py`; fixed `staging/build_code_map.py`'s
  `class_name`/`tools/` orphan logic and its section-index line ranges.
- Regenerated `docs/CODE_MAP.md` / `CODE_MAP.json`.
- Updated `README.md`, `AGENTS.md`, `CHANGELOG.md`, this document and the
  mockup notes in `STATION_HUB.md` / cleanup plans.
- Gate: **1433/0 ×2**; no gameplay behavior changed.

## 9. Reproduce

```bash
python3 staging/code_audit.py            # inventory + duplicates + class usage
python3 staging/build_code_map.py        # regenerate docs/CODE_MAP.md + .json
python3 staging/gate.py --times 2        # 1433/0 ×2, zero SCRIPT ERROR
```

Runtime numbers: open the editor with the project, then run
`res://ui/screens/station.tscn` and `res://game/game.tscn` as custom scenes and
read `Performance` / `Time.get_ticks_msec()` through the godot-ai `game_eval`
tool. The first-open costs came from switching to each module and waiting one
`process_frame`; the station before/after used the same probe.
