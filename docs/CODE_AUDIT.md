# CODE_AUDIT — full-code evaluation (2026-10-19)

Status: **executed the same day.** The 2026-10-19 sweep landed the P0 plan below
(shared panel base, test harness, lazy station panes, guardrails) and the P1
consistency pass (UI token kit, weapon-family source, one `_service` lookup).
The "Before → after" columns are measured, not estimated; the remaining P2
items are what is still open.

Repeatable half: `python3 staging/code_audit.py` (inventory, duplicate functions,
duplicate 8-line blocks, class usage). Runtime numbers were taken in the live
editor on the Linux host, Godot 4.7.2-stable, Forward+, 1920×1080. The gate was
`python3 staging/gate.py --times 2`; it read **1436/0 ×2 byte-identical, zero
`SCRIPT ERROR`** on this tree.

## 0. Headline

- **171,934 GDScript lines**: 69,568 production (108 files) + 102,366 tests
  (233 files). 35 production scenes, 129 scenes total, 53 production
  `class_name`s, 6 project autoloads. The split's two extra files are the
  armory/game declaration halves.
- **Duplication is down across the board.** Production: **102 → 88 duplicate
  clusters**, **1,526 → 942 redundant lines**. Tests: **255 → 238 clusters**,
  **4,560 → 3,376 redundant lines**. The 18 `_token`\* entries left in the raw
  count are one-line delegations to `UiTokens.colour`, not copied logic.
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

- **88 duplicate clusters, 942 redundant lines**, 299 duplicated 8-line blocks.
- Most copied helpers remaining: `_notification` ×9, `_make_label` ×7,
  `_profile` ×5, `_emit_sheet` ×5, `_on_scroll_started` ×4, `_active_id` ×4,
  `_check` ×4, `texture` ×2, `_exit_tree` ×2, `_make_tween` ×2. The raw count
  also lists `_token` ×18, but every one is now the same one-line delegation to
  `UiTokens.colour` (the wrappers stay so the call sites and the tests' `call()`
  reads keep their names).
- **What the sweep removed:** the 12 station panels no longer carry their own
  `_token` (except the armory's style override), `_format_int`, `_make_tween`,
  `_exit_tree`, `_pulse`, `_profile`, `_clear_list`, `_base_id`, `_active_hull`,
  `_vitals`, `_plate_texture`, `_strip_chip_box`, `_slot_glyph`, and
  `_load_texture`. They inherit `StationPanel` instead.
- **One slot table:** `ui/components/ship_slots.gd` now owns the eight slot
  glyph stems; the armory, fitting, shipyard and ship-status screen read it.
- **One hot-price rule:** `Auction.hot_price` delegates to
  `ModuleCatalog.hot_price`; the duplicate 20 % constant is gone.
- **The shipyard's `_format_int` check:** its removed copy returned
  `StationCatalog.group_int`, which is byte-identical to the base algorithm
  (`1 234 567`, space-grouped), so the inheritance changed no visible figure.

Remaining families worth a later pass:

| Helper family | Copies | Where |
|---|---:|---|
| `_notification` | 10 definitions | station panes and screens; each has pane-specific extra work |
| `_make_label` | 8 definitions | three signature variants; not a safe mechanical merge |
| `_profile` | 6 definitions | `game.gd`, cargo overlay, status screen, weapons, NPC/player state |
| `_emit_sheet` | 6 definitions | station panes; tied to their own `_sheet_payload` and signal |
| `texture` / `_on_scroll_started` / `_active_id` / `_check` | 4 each | one or two screens each; local idioms |

- **One token read, one grouping rule (P1).** `ui/components/ui_tokens.gd` owns
  `colour(control, token, fallback)` and `format_int` (which delegates to the
  CONTRACTS §23.1 rule, `StationCatalog.group_int`). Every `_token` outside the
  kit delegates to it; the station base, the HUD, the cargo overlay and the
  station shell share the formatter.
- **One weapon-family source (P1).** `PlayerState.WEAPONS` owns the five v1 ids;
  the HUD's `WEAPON_IDS` is that const plus `WEAPON_ID_EXTRAS`
  (`railgun`, `mining`).
- **One service lookup (P1).** `autoload/service_lookup.gd` holds the root
  lookup; the four node autoloads' `_service` doors delegate to it.

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

The Auction is the outlier because its shelf draws on entry. Re-measured after
the P1 pass through `game_eval`: the pane's build is **136 ms** on rail hover,
and the selection then costs **29 ms**; a direct selection with no prefetch is
**156 ms**. The hover/focus prefetch already absorbs the build, and the
remaining 29 ms is the shelf advance `enter_pane()` must do on entry (it writes
the rotation), so no further prewarm was added.

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
| `README.md:34` | quoted `passed=524` | fixed to the gate wrapper / 1436 |
| `CHANGELOG.md` | had 0.2, 0.3 and vote-site only; the records say 0.4 and 0.5 shipped | 0.4/0.5 entries added |
| `docs/CODE_MAP.md` orphan list | listed `ship_stats.gd`, `cockpit_cluster.gd` and every `tools/` script as orphans | fixed in `staging/build_code_map.py`: `class_name` consumers count, `tools/` is separate |
| God files | `armory_panel.gd` 3,401 + `armory_panel_base.gd` 1,118; `game.gd` 1,234 + `game_base.gd` 2,560; `player_profile.gd` 3,305; `hud.gd` 2,686; `weapons.gd` 2,664 | the first pair split 2026-10-19 at its declaration/behavior seam; the rest split only at the next feature that touches them |

## 7. Recommendations, ranked

### P0 — landed in the 2026-10-19 sweep

1. **`StationPanel` base.** One helper suite for the 12 station panes; the
   armory's `_token` override is the one documented exception.
2. **`tests/support.gd`.** Stateless fixtures centralized; the remaining test
   duplicates are suite-local lifecycle.
3. **Lazy station panes.** Boot/memory win above; rail hover/focus prefetch.
4. **Guardrails.** `tests/test_code_health.gd` pins the base-class rule, the
   no-re-declaration rule and the NPC required-key rule.

### P1 — landed in the same 2026-10-19 pass

5. **Done.** `ui/components/ui_tokens.gd` owns the token read and the integer
   grouping; every `_token` outside the kit is a one-line delegation, the
   station base, HUD, cargo overlay and station shell share `format_int`, and
   `tests/test_code_health.gd` gained the delegation guardrail.
6. **Done.** `Hud.WEAPON_IDS` is `PlayerState.WEAPONS + WEAPON_ID_EXTRAS`, and
   the guardrail asserts the join.
7. **Done.** `autoload/service_lookup.gd` holds the root lookup; the four node
   autoloads delegate, and the guardrail asserts all four.
8. One `_load_texture` already landed in `StationPanel`; the remaining
   `_on_scroll_started` / `_active_id` / `_check` families are one-per-screen
   idioms and can stay.
9. ~~Repoint the `UI_SPEC.md` `inspect_chip.gd` citation and delete the orphan.~~
   Done in the sweep.

### P2 — the first split landed 2026-10-19

10. **Done.** Both god files split along their own seams, using path-based
    script inheritance as the partial-class mechanism:
    - `ui/station/armory_panel.gd` (behavior: 4,493 → **3,401**) extends
      `armory_panel_base.gd` (**1,118**: constants, the 11 widget classes,
      `@onready` nodes, state, token/caption helpers). The scene still attaches
      `armory_panel.gd`.
    - `game/game.gd` (entry + population/combat: 3,778 → **1,234**) extends
      `game_base.gd` (**2,560**: constants, state, launch/HUD/travel/dock core).
      The scene still attaches `game.gd`.
    The base can only call its own functions; the child may call the base. The
    two child-only handlers the base needs as callables (`_on_player_hit`; the
    armory's `_style_bay` family) were moved into the base or wired from the
    child, so neither script has an unresolved self-reference.
    **Gotcha:** `get_script_constant_map()` does not return inherited constants;
    a test that pins a constant reads it off the base or through
    `ChildScript.CONST` (which does inherit). The two source-text pins that read
    the child (`test_s13_devmenu`, `test_s5_batteries_v2`) now read both files /
    the base.
11. A shared test fixture base class for the suite lifecycle hooks stays
    deferred: the remaining duplicates are suite-local state (`teardown` frees
    its own nodes, `_fresh` seeds its own store), so a base class would add
    order-coupled hooks rather than remove logic. Revisit only if a new suite
    repeats a full lifecycle verbatim.
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
- Added `tests/test_code_health.gd` (6 rows) as the maintainability guardrail
  (base class, no re-declared helper, NPC keys, token delegation, weapon-family
  source, service lookup).
- Added `ui/components/ui_tokens.gd` and `autoload/service_lookup.gd`; the 18
  remaining `_token` helpers delegate, the HUD derives its rack ids from
  `PlayerState.WEAPONS`, and the four autoloads share one lookup.
- Split `armory_panel.gd` and `game.gd` into a declaration/core base plus a
  behavior/child script (P2 item 10); the scenes keep their original script
  paths. No gameplay code moved between owners except `_on_player_hit` (base)
  and the entry hooks (child).
- Added `staging/pre_push.py` + `staging/install_hooks.py`: the pre-push hook
  runs the audit and `gate.py --times 2` and refuses a failing push;
  `VAJB_SKIP_GATE=1` is the incident escape hatch.
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
- Gate: **1436/0 ×2**; no gameplay behavior changed.

## 9. Reproduce

```bash
python3 staging/code_audit.py            # inventory + duplicates + class usage
python3 staging/build_code_map.py        # regenerate docs/CODE_MAP.md + .json
python3 staging/gate.py --times 2        # 1436/0 ×2, zero SCRIPT ERROR
```

Runtime numbers: open the editor with the project, then run
`res://ui/screens/station.tscn` and `res://game/game.tscn` as custom scenes and
read `Performance` / `Time.get_ticks_msec()` through the godot-ai `game_eval`
tool. The first-open costs came from switching to each module and waiting one
`process_frame`; the station before/after used the same probe.
