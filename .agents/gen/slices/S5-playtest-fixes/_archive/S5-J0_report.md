---
slice: S5
worker: S5-J0
model: "deepseek/deepseek-v4-flash"
status: actionable
gate: "not run (docs drift check; baseline is S4's 524/0)"
---

# S5-J0 report — the pinned set vs the tree (post-D2/S3/S4)

## Result

The pinned set is **coherent on every number the wave touches** — save v6, `GROUPS_MAX` 5,
`BATTERY_STRUM_MS` 40, the 6+10 auction draw, the S4 strip, `HARDPOINTS` absent,
`weapon_6/7` absent — and **every `res://assets/...` reference in `.gd`/`.tscn` resolves**
(193 unique refs, 0 missing). What it does **not** survive is that the wave's pin set
contradicts itself in ten places and that three of the changes the pin requires cannot be
reached from the `VAJB_WORKER_FILES` sets that owe them. All ten are bucket 2 (docs or pin
text) except where stated; J0 fixed nothing and invented no number.

No gate run is owed by J0 (`VAJB_WORKER_FILES` holds no game source); the baseline it must
not disturb is CONTRACTS §9's measured **`passed=524 failed=0`**.

## F0 — HARNESS: the file-set hook denies every absolute Linux path (bucket 2, blocks all six workers)

`.crush/hooks/enforce_worker_files.py:_norm` relativises only the **Windows** root
(`g:/mój dysk/projekty/vajb orbit/`), so a Linux absolute target stays absolute and matches
no allowlist entry. Measured on this host:

```bash
env VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" python3 \
  .crush/hooks/enforce_worker_files.py <<< \
  '{"tool_input":{"file_path":"/home/<user>/VajbOrbit/.agents/gen/slices/S5-playtest-fixes/S5-J0_report.md"}}'
# {"decision": "deny", "reason": "outside this worker's declared file set. Allowed:
#  docs/, vajb-orbit/tests/, vajb-orbit/tools/..."}

env VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" python3 \
  .crush/hooks/enforce_worker_files.py <<< \
  '{"tool_input":{"file_path":".agents/gen/slices/S5-playtest-fixes/S5-J0_report.md"}}'
# (no output = allow)
```

Three consequences, all measured:

1. **Every `write`/`edit` from a worker session on this host is denied**, whatever the set
   says — including writes the set *does* allow (`docs/…`, `vajb-orbit/tests/…`). The
   allowlist is unreachable, not narrow.
2. **The cure is the caller's**: a workspace-relative `file_path` passes (`.agents/` is
   explicitly allowed by the hook, `enforce_worker_files.py:41-42`, "reports, waveboard
   notes, wave-state"). This report was written that way. L92a's own `Where` column already
   names `_norm` and prescribes exactly this cure: "Resolve the target against the workspace
   root before comparing (L75's own cure)" — it is still unimplemented, so every worker on
   the Linux host will hit this before it can write anything.
3. **The brief's file sets are otherwise fine for this**: no J0–F1 report path is outside its
   worker's set once paths are relative, because `.agents/` is exempt. My first reading —
   that the sets exclude the report path — was wrong; the sets allow it, the path
   normalisation is what denied it. Corrected here rather than left as a false finding.

Follow-up for the harness owner: put the Linux root in `_norm` (or `os.path.relpath` against
the workspace) so the comparison works on both hosts; until then every dispatch must state
"workspace-relative paths only" as a hard rule, which the brief already does for
`VAJB_WORKER_FILES` (brief:113) but not for the tools themselves.

## Contradictions inside the pin set (bucket 2 — the developer session owns the text)

### F1 — CONTRACTS §16 rule 3 and §17 pin opposite shapes for `battery()`

- §16 rule 3 (`docs/CONTRACTS.md:1556-1565`): "**`battery(base_id)` returns barrel positions
  in `fitted()` — not cell indices** — ascending, normalised through `weapon_id`".
- §17 (`docs/CONTRACTS.md:1695-1700`) stores `batteries: {ship_id: Array[Array[cell_ref]]}`,
  and the brief's ambiguity rule (brief:60-61) reads "`battery()` answers **cell refs**".
- The tree implements the §16 shape: `game/weapons.gd:472-482` walks `_fitted` and returns
  positions; `:462-469` `battery_ids()` is the distinct ids of `fitted()`.
- §17 restates **neither** `battery()`, `battery_ids()` nor `select_group`'s meaning, so §16
  rules 2/3 stay the only written pin and say the opposite of the wave's intent. J3 (the
  component) and J4 (the mount binding) read different sections and would build differently.
- Cure: §16 rules 2/3 gain an explicit supersession pointer to §17, or §17 restates the four
  signatures. Precedent for the former: §5.10's "must not diverge" note
  (`docs/design/STATION_HUB.md:868-873`).

### F2 — `GROUPS_MAX` 7 + composed groups break a seam whose callers are outside J3's set

- `game/weapons.gd:441-443` `select_group(g)` selects `_batteries[g - 1]`; the comment above
  it (`:436-440`) says "`weapon_1..5`: the input map's five keys are the group range".
- `game/game.gd:1358-1359` maps a **cell** index to a group:
  `_guns.call(&"select_group", slot + 1)`. With player-composed groups the ordinal no longer
  equals the cell, so the HUD's W-slot buttons select the wrong battery.
  `game/game.gd` is in J1's and J2's sets, **not J3's** (SLICE.md:51-53).
- `game/game.gd:71-77` `WEAPON_ACTIONS` holds **five** entries; `ui/hud/hud.gd:47-51`
  `WEAPON_IDS` holds **five** icons. Neither file is in J3's set. §17 pins only the
  `project.godot` rows as orchestrator-applied (`docs/CONTRACTS.md:1700`) and names neither
  consumer, so "racks B1..B7 bound to `weapon_1..7`" is half-wired.
- L129 already records the two index spaces (`_state/LOW_BACKLOG.md:317`) and prescribes
  "grow `GROUPS_MAX` and the input map **together**"; §17 grew one of the three.

### F3 — the rename has no home: the label is a literal in a foreign file, and the theme has none

- `ui/screens/station.gd:68-77` `MODULE_LABELS: Array[String]` carries the literal
  `"OUTFITTING"`, and `:58-67` `MODULE_FILES[0] = "outfitting"` is the pane's load path
  (`:284-285` `PANEL_DIR + MODULE_FILES[index] + PANEL_SUFFIX`). Renaming the pane files to
  `armory_panel.tscn` (J3's set, SLICE.md:53) turns the rail entry into `_make_placeholder`
  (`:306-327`) unless `MODULE_FILES[0]` changes too.
- `ui/theme/vajb_theme.tres` (576 lines) holds **no label-text constants** — its token keys
  are `Tokens/colors/*` only, plus fonts and styleboxes. `grep -rn "ARMORY"` across the tree
  returns **0 hits**. So the brief's hard rule "the one `ARMORY` label constant excepted,
  **through the theme only**" (brief:108-109) has no mechanism to route through.
- Both literals live in `ui/screens/station.gd`, which is **J1's** file, while the rename is
  **J3's** deliverable and J1's prompt (prompts:26) never mentions the rail.
- Cure: put the label in a file J3 owns, or add the two edits to J1's acceptance, or drop
  "through the theme only" (no theme home exists).

### F4 — J2 cannot implement the pinned EXCHANGE sell rule: the pricing surface is in nobody's set

- `game/exchange.gd:144-149` `is_sellable` = ore ∨ ingot ∨ component; `:118-130`
  `baseline_of` has no other branch; `:132-142` `exchange_price` returns 0 for an unknown id.
- `docs/design/STATION_HUB.md:734` pins that "Every displayed price comes from `Exchange`
  (the one pricing function, 05 §8); the panel never recomputes a price from a baseline",
  and `:757` names `Exchange.exchange_price(id, demand)` as the `UNIT` cell's source.
- §17 (`docs/CONTRACTS.md:1692`) and §5.11 (`STATION_HUB.md:922-923`) require EXCHANGE to
  sell `ammo_*` units at **60 % of list**. That is a new price family inside
  `game/exchange.gd` — **not** in J2's set (`game/module_catalog.gd`, `game/game.gd`,
  `autoload/player_profile.gd`, `ui/station/exchange_panel.{gd,tscn}`, `tests/`; SLICE.md:52),
  and `exchange_panel.gd` computing it would break the rule above.
- Also unpinned: 60 % of *list* vs the shipped minerals' route (`game/exchange.gd:56`
  `SURPLUS_DISCOUNT := 0.9`, `:82` `unit_net`, `:112-114` `component_unit_price`) — the ammo
  rows would be a third pricing shape on the same pane and §17 does not say which of the two
  existing forms they follow.

### F5 — the ammo rows' home: §5.11 says they leave the pane, §6.1/§17 say they deliver to cargo

- `docs/design/STATION_HUB.md:918-919` (§5.11, OUTFITTING → ARMORY): "**Ammunition rows leave
  this pane** (they move to cargo — 10 §6.1)".
- `docs/gameplay/10_ship_acquisition.md:256` (§6.1): "OUTFITTING/ARMORY's ammo rows **deliver
  to cargo** (units = rounds / 10), not to packs"; §17 agrees
  (`docs/CONTRACTS.md:1690-1691`).
- The rows are `ui/station/outfitting_panel.gd:588-593` (`buy_ammo`) — J3's file — while J2
  owns the destination change. If the rows leave and nothing else gains a buy row, ammo
  becomes unpurchasable: EXCHANGE only sells (`STATION_HUB.md:779` footer "THE STATION BUYS ·
  IT NEVER SELLS IN V1"; `exchange_panel.gd:178` "The exchange is not a buy shop").
- §5.11 never says which pane buys if the rows do leave.

### F6 — §5.11's shipyard row needs a class icon §5.10 measured as not shipping

- `STATION_HUB.md:899` (§5.11): "one row per owned ship (**48 px class icon**, name, class,
  `ACTIVE` badge)", repeated in J1's prompt (prompts:26).
- `STATION_HUB.md:830-832` (§5.10, same file, live): "**No class icon ships** (measured:
  `station_catalog.gd`'s nine rows carry `preview` only and there is no
  `assets/icons/ship/`)". Verified: `assets/icons/ship/` does not exist.

### F7 — §5.2's live paragraph still pins the exact behaviour the owner wants removed

- `STATION_HUB.md:521` action row: `IN SERVICE` (disabled) / `SET ACTIVE` / `BUY`;
  `:523-526`: "`ui_accept` on a ship row, or `ShipAction`, calls `set_active_ship(id)` when
  owned and `buy_ship(id, cost)` when not"; `:514` `STATUS` column `FOR SALE`/`LOCKED`.
- The tree implements it exactly: `ui/station/shipyard_panel.gd:927-933` `_on_row_pressed` →
  `_act(...)`, `:952-958` `set_active_ship` / `buy_ship`; constants at `:123-125`; `SUBTITLE`
  at `:91` still reads `"BUY AND SWITCH HULLS · …"`.
- §5.11 (`:897-903`) retires the buy rows and makes `SET ACTIVE` the sole commit but does
  **not** mark §5.2 `:508-526` superseded and carries no pointer from §5.2 to §5.11 — the
  two-way divergence §5.10's own amendment warned about (`:868-873`). J1's brief asks it to
  break a paragraph the pin still states as law.
- The *preview* half is already right in spirit: `:914-924` `_on_row_focused` writes nothing.
  The write is on **press**, not focus.

### F8 — the railgun ammo family has no numbers anywhere (bucket 3 — owner/designer number)

- `docs/CONTRACTS.md:1688-1689` (§17) and `10_ship_acquisition.md:253-255` (§6.1) name
  `&"ammo_railgun"`; J2's prompt repeats it (prompts:32).
- `autoload/player_profile.gd:158-165` `AMMO_MAX` holds **five** families — no `railgun`.
  `game/station_catalog.gd:14-51` `AMMO_PACKS` holds **five** packs — no railgun `rounds`,
  `cost` or `name`.
- `autoload/player_profile.gd:250-252` `buy_ammo` refuses any id outside `AMMO_MAX`, and
  `set_ammo` (`:265-268`) silently drops one, so a railgun pack cannot be seeded either.
- `docs/gameplay/09_ship_slots_modules.md:98-102` left this open on purpose: "the railgun is
  new and shares the cannon's ammo family in v1 **or gets its own pack in the ammo amendment —
  coder's choice, documented in the ammo table when implemented**". §17 chose "its own pack"
  and supplied no rounds, no cost and no `ammo_max`. Reported, not invented: the wave needs
  one owner number set — or §17 reverts to 09 §3.1's "shares the cannon's family", which
  needs no new number.

### F9 — the `DRIVES` tab keyed on the family name matches no module row (bucket 1, one-line pin advised)

- §17 (`docs/CONTRACTS.md:1682-1683`) lists `DRIVES` and explains "`DRIVES` labels the
  `engines` family"; §5.11 (`STATION_HUB.md:906-907`) repeats it.
- In `ModuleCatalog.MODULES` (from `game/module_catalog.gd:252`) the three drive rows carry
  `&"slot": &"engine"` — **singular** (`:523`, `:532`, `:541`), matching
  `ShipFit.SINGLE_SLOT_KEYS` (`game/ship_fit.gd:59`). The only `&"slot": &"engines"` in the
  file is the `tempered` **prefix** row (`:170-176`), not a module.
- An exact-key filter therefore renders `DRIVES` empty and makes the three drives unreachable
  through the tab. An implementer may pick the display key (bucket 1), but the pin's family
  *name* differing from the catalogue's slot *key* is what makes the empty tab the literal
  reading.
- The other eight tabs match catalogue keys exactly: `weapons` 12, `shields` 5, `armour` 4,
  `power` 4, `computers` 7, `boosters` 3, `utility` 8 module rows, plus `HULLS` (6 hull rows)
  and `ALL`.

### F10 — the `ammo_*` cargo namespace vs the family namespace is unstated

- §17's cargo ids carry a prefix the engine uses nowhere: `&"ammo_laser"` …
  (`docs/CONTRACTS.md:1688-1689`), while the families are bare ids — `laser`, `cannon`,
  `rocket`, `mine`, `plasma` in `game/station_catalog.gd:17,25,33,41,49`,
  `autoload/player_profile.gd:159-165` and `PlayerState.WEAPONS`.
- §17 says the pack "auto-fills from cargo of its family" (`docs/CONTRACTS.md:1690-1691`) but
  never states the mapping. `ammo_of`/`ammo_max`/`set_ammo` stay keyed by the family id
  (`player_profile.gd:242-248`), so a build keying cargo by family id satisfies the behaviour
  and violates the pinned id string, while a build using the pinned string needs the mapping
  written down.
- The same paragraph's carve-out "existing stacks keep working on `R`" reads
  `FUEL_CELL_ITEM = &"fuel_cell"` (`game/player_state.gd:63`) — the un-prefixed form, one line
  apart in the same pin. Related, and also unpinned: nothing in the tree **sells** a
  `fuel_cell` today (no `fuel_cell` row in `game/station_catalog.gd`, `game/mineral_catalog.gd`
  or `game/component_catalog.gd`; `game/exchange.gd:144-149` would not price it), so §17's
  "delisted everywhere" and its reversal "the row returns" describe a sale surface that does
  not exist at any `file:line`. The only fuel-cell-named cargo is the loot component
  `comp_pow_1` (`game/component_catalog.gd:131-140`), a different id.

## Stale lines inside the pin set (bucket 2 — docs text; the code is correct)

### F11 — CONTRACTS §16's measured citations no longer resolve (L126's class, four more)

| §16 cites | line today reads | the code it means is at |
|---|---|---|
| `game/weapons.gd:369`, "the `_fitted.has(id)` guard" (`CONTRACTS.md:1540`) | `var _flare_age := 0.0` | guard removed; `is_fitted()` `game/weapons.gd:508-509`; the dedupe is `_sync_barrels` `:422` |
| `game/weapons.gd:520`, "`tick` fires one weapon" (`:1515`) | `return &""` | `func tick` `game/weapons.gd:600` |
| `game/weapons.gd:1519-1526`, "`ammo_slot` resolves the family's index" (`:1612-1613`) | `func _deploy_flare()` | `func ammo_slot` `game/weapons.gd:1753` |
| `ui/station/outfitting_panel.gd:147-148`, the emit-inside-handler site (rule 10, `:1672`) | the "Audit anomaly C16" comment | `_build_strip` `:660-673`, `_max_weapon_cells()` `:787` |

Re-verified **correct**, so the reviewer need not re-check them: `fitting_panel.gd:147-149`
(rule 9), `game/ship_fit.gd:117` (rule 9 / §13 rule 1), `game/ship_fit.gd:481-491` (rule 1;
the doc says 481-489 and `return ids` is `:491`), `game/player_state.gd:84-89` (rule 5),
`game/game.gd:1247-1249` (rule 5), `game/game.gd:1358-1359` (rule 2, textually),
`game/player_ship.gd:1205-1206` (rule 3), `game/weapons.gd:441-443` (rule 2),
`game/weapons.gd:404-406` (L129's "reported"), `game/weapons.gd:143` (`GROUPS_MAX := 5`).

### F12 — 09 §10's pre-build citation points at the buy path

`docs/gameplay/09_ship_slots_modules.md:494-495` cites `ui/station/outfitting_panel.gd:591-596`
for "pre-builds `_max_weapon_cells()` rows". Today `:588-593` is the `buy_ammo` call; the
pre-build is `:660-673` and `_max_weapon_cells()` is `:787` (same correction as F11's last row).

### F13 — 09 §8's supersession is stated nowhere in §8

`docs/gameplay/09_ship_slots_modules.md:413-420` still reads "**No per-hull anchor table
exists**, so art changes and layout edits cannot desynchronise the geometry" and "Consumption
in flight is **staged** … belongs to the feel wave". §11 (`:527-534`) supersedes exactly that
rule with `HARDPOINTS`, and SLICE.md:62 records the supersession — but §8 carries no pointer
to §11, so two live sections contradict each other. §8 item 3 also carries the pre-D2 icon
shape (`:409-411`).

### F14 — the station's art map and node tree describe the raster families D2 deleted

`docs/design/STATION_HUB.md:949` claims "Every path below exists on disk and appears in
`ASSET_AUDIT.md` section E.2 or F.1". Measured missing today, row by row:

| §7.1/§7.2 line | path | the tree has |
|---|---|---|
| `:961` | `assets/icons/icon_map_node_station_48.png` | `assets/icons/map/icon_map_node_station.png` |
| `:962` | `assets/icons/tint/icon_credits_48.png` | no tint stencil for `icon_credits` at all |
| `:963` | `assets/icons/tint/icon_logout_48.png` | no tint stencil; `assets/icons/hud/icon_logout.svg` |
| `:964` | `assets/icons/icon_equip_module_48.png` | `assets/icons/equip/icon_equip_module.png` |
| `:965-967` | `tint/icon_hull_48.png`, `icon_equip_generator_48.png`, `icon_map_route_48.png` | `hud/icon_hull.svg`, `equip/icon_equip_generator.png`, `map/icon_map_route.png` |
| `:968` | `tint/icon_weapon_{cannon,mine,plasma}_48.png` | `weapon/icon_weapon_*.svg`, no stencil |
| `:969` | `icon_ammo_laser_48.png`, `icon_ammo_rocket_48.png` | `weapon/icon_ammo_*.png` (raster, kept) |
| `:970` | `module/icon_module_<id>_48.png` | `module/icon_module_<id>.svg` |
| `:971,972` | five UPGRADES `_48` icons, three `tint/icon_cargo_*_48.png` | absent / `.svg` |

The same stale shape is in §4's node tree (`:255`, `:264`, `:281`, `:292`, `:319`) and §5.2's
grid row (`:520`, `assets/icons/slot/icon_slot_<type>_48.png`); `docs/gameplay/
09_ship_slots_modules.md:409-411` repeats it. The tree is **135 SVG + 164 raster masters**
with no size variants (`.agents/gen/slices/D2-icon-unification/D2_SPLIT.md:1-30`;
`asset_path_fallout.md`: "379 asset references … 0 unresolvable").

**The deferral is spent.** `docs/CONTRACTS.md:1747-1750` records that "a failure that is only
a missing or moved asset path is environment-deferred until the designer ships, is not a code
finding". D2 closed 2026-09-22 (`.agents/gen/_state/WAVEBOARD.md:180-188`), so these are plain
stale doc lines and the code side is clean. `docs/CONTRACTS.md:1065-1075` (§11) does carry
D2's amendment for the module-icon rule, which is why the pin set disagrees with itself.
`docs/design/ASSET_NAMING_SPEC.md:96-101,163-164` is also pre-D2 ("`_16`, `_48`, `_96`, `_192`
and `@2x` are produced by appending to a master name"; "96 icon refs … rewritten") — adjacent
to the pin set rather than in it, flagged for the developer.

## LOW observations (code side; no pin changed)

- **F15 — the flat-glyph tint fallback is unreachable after D2.** `ui/station/auction_panel.gd:
  640-651` `_icon_source` returns early for any `.svg`, and all three `FLAT_GLYPH_ICONS`
  (`:633-637`) are `.svg` now, so the `TINT_DIR` branch is dead code. Same shape at
  `ui/station/outfitting_panel.gd:148-155` and `ui/station/fitting_panel.gd:92-99`. The
  stencil set (540 files = 135 names × 4 sizes) covers the **raster** families only — there is
  no `tint/icon_credits_*`, `tint/icon_hull_*` or `tint/icon_weapon_cannon_*`. J1 owns the
  auction file; the other two are outside this wave. Bucket 1.
- **F16 — L124's second citation drifted.** `_base_id` is at `ui/station/outfitting_panel.gd:
  1323` (file is 1381 lines), not `:1295`; `_battery_groups` at `:823` still holds.
  `_state/LOW_BACKLOG.md:312`. Bucket 2 (backlog text).
- **F17 — the HUD has no railgun or mining icon.** `ui/hud/hud.gd:47-51` `WEAPON_IDS` holds
  five entries (`laser, cannon, rocket, mine, plasma`); the railgun is auctionable today
  (`game/module_catalog.gd:298-306`, its base row; `w_mining` `:307`) and this wave makes its
  ammo reachable. No worker set carries `ui/hud/hud.gd`. Pre-existing; not owed by S5.

## Verified consistent — do not re-litigate

- Save is **v6** (`autoload/player_profile.gd:59`), `MIN_READABLE_VERSION` 1 (`:60`); §17's
  `SAVE_VERSION := 7` is an addition, and §13's block already self-notes that its `5` is not
  the digit to build against (`docs/CONTRACTS.md:1235-1238`).
- OUTFITTING still holds the S4 strip: `ui/station/outfitting_panel.gd:660-673` fixed node
  set, `:787` `_max_weapon_cells()`; the widest hull's W row is **7** (`game/ship_fit.gd:218`),
  so `GROUPS_MAX := 7` has a home for all seven racks.
- `GROUPS_MAX := 5` at `game/weapons.gd:143`; `BATTERY_STRUM_MS := 40`; `fitted()` keeps
  duplicates (`:484-486`); §16 rule 1's guard is genuinely removed (F11's first row).
- The auction draw is 6 hulls + 10 modules (`game/auction.gd:52-53`); listing rows already
  carry a `slot` key (`:452`), so J1's tabs are display-only over an existing field, and
  `HULL_SLOTS`/`MODULE_SLOTS`/`HOT_DISCOUNT_PERCENT`/`TIER_WEIGHTS` are untouched by the wave.
- `ShipFit.HARDPOINTS` exists nowhere (J4's deliverable); `thruster_anchors()` exists and
  derives from `MOUNT_SPREAD` (`game/player_ship.gd:392-413`, `game/ship_fit.gd:126`) — J4's
  named fallback is real.
- 09 §3.1 has **no** `track_dps` column yet (columns are Module/Tier/Draw/Family/Shield
  rule/Effect/Cost, `:83-90`); the seven proposed values live in §11's prose (`:540-546`) and
  match §17 (`docs/CONTRACTS.md:1713-1715`) value for value. §11's nine-row table is the
  placeholder (`:536-538`).
- `weapon_6`/`weapon_7` are absent: `project.godot:78-101` holds `weapon_1..5` on keycodes
  49-53.
- Weapons may repeat (`game/ship_fit.gd:131` `DUPLICATE_GUARD_KEYS = [engines, computers]`,
  matching 09 §4 item 4 at `:247-251`), so a mixed battery needs no rule change.
- Every named new test name is free and every named existing suite exists
  (`tests/test_s4_batteries.gd`, `test_engine2_weapons.gd`, `test_p2b1_outfitting_panel.gd`,
  `test_p2a_ship_roster.gd`, `test_p2a_launch_fit.gd`, `test_s3_auction.gd`,
  `test_p1_catalogues.gd`).
- The ACs the worker table references are defined in `SLICE.md:31-45` (AC1–AC7); the brief
  cites them without restating them, so J1–J4 must read SLICE.md too. SLICE.md:45's AC7 ("gate
  holds green") is not in the brief's tests-that-move list, and the brief's expected range
  (`524 → ~565`) is a forecast, not a pin — CONTRACTS §9's measured number is 524
  (`docs/CONTRACTS.md:802-806`).
- Every `res://assets/...` reference in `.gd`/`.tscn` resolves (193 unique, 0 missing; D2's own
  audit says the same at 379 refs once templates and directories are counted).

## Not this wave

- **Owner finding 5** (painted-only rail icons): `ui/screens/station.gd:78-88` `MODULE_ICONS`
  mixes four raster `.png` (`equip_module`, `equip_generator`, `status_repairing`,
  `map_route`) with four `.svg`, and `MODULE_TINTED: Array[bool] = [false, true, true, true,
  true, false, false, false]` tints five. Designer lane per SLICE.md:28
  (`dispatch_designer.md`); recorded so the drift is not lost.
- The shipyard build queue (10 §3), countermeasure packs in cargo, and the FITTING pane's
  per-cell surface are staged per brief:120-121 and SLICE.md:25-29.

## Deviations from SLICE.md

None in content. One process note, not a deviation: the first two `write` attempts to this
path were denied because the tool was handed a Linux **absolute** path, which
`enforce_worker_files.py:_norm` cannot relativise (F0). The report was written with a
workspace-relative path, which the hook allows; no shell write was used at any point
(brief:112-113, L100). No game source, doc, test or tool was modified.

## Evidence

```bash
# the pin set, read in the brief's order
sed -n '1678,1720p' docs/CONTRACTS.md                          # §17
sed -n '1509,1680p' docs/CONTRACTS.md                          # §16 (v0.8.0, rewritten 2026-09-23)
sed -n '1228,1350p' docs/CONTRACTS.md                          # §13
sed -n '892,924p'   docs/design/STATION_HUB.md                 # §5.11 (also §5.2 :506-552,
                                                               # §5.8 :731-779, §5.10 :805-891,
                                                               # §7.1 :951-997, §4 :242-368)
sed -n '247,263p'   docs/gameplay/10_ship_acquisition.md        # §6.1
sed -n '506,547p'   docs/gameplay/09_ship_slots_modules.md      # §11 (§3.1 :81-116, §8 :398-421)

# the tree
grep -n "SAVE_VERSION\|MIN_READABLE" autoload/player_profile.gd  # :59 v6, :60 MIN 1
grep -n "const GROUPS_MAX" game/weapons.gd                       # :143 -> 5
grep -n "func select_group\|func battery\|func battery_ids\|func fitted" game/weapons.gd
grep -n "select_group" game/game.gd                              # :1359 slot + 1
grep -n "weapon_" project.godot                                  # 78-101 = 1..5 only
grep -oE '&"slot": &"[a-z]+"' game/module_catalog.gd | sort | uniq -c   # engine x3; engines x1 = a PREFIX
ls assets/icons/ship                                             # No such file or directory
for f in <the 17 §7.1 paths>; do [ -e "$f" ] || echo "MISS $f"; done    # every _48 path MISS
rg --no-filename -o 'res://assets/[A-Za-z0-9_./-]+\.(png|svg|ogg|wav|ttf|tres|gdshader)' ...
                                                                 # 193 refs, 0 missing
# F0, the hook's path normalisation
env VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" python3 \
  .crush/hooks/enforce_worker_files.py <<< '<absolute path>'      # deny
env VAJB_WORKER_FILES="docs/,vajb-orbit/tests/,vajb-orbit/tools/" python3 \
  .crush/hooks/enforce_worker_files.py <<< '<relative path>'      # allow
```

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| `_norm` cannot relativise a Linux absolute path, so every worker write on this host is denied regardless of its set | HARNESS | `.crush/hooks/enforce_worker_files.py:20-31,41-46` |
| §16 rules 2/3 vs §17 on `battery()`/`battery_ids()`/`select_group` | DOC | `docs/CONTRACTS.md:1545-1565`, `:1694-1703` |
| `select_group(slot + 1)`, `WEAPON_ACTIONS`, `WEAPON_IDS` outside every set that grows `GROUPS_MAX` | SPEC + HARNESS | `game/game.gd:71-77,1358-1359`, `ui/hud/hud.gd:47-51` |
| `ARMORY` label has no theme home; the literal is in J1's file, the rename is J3's | DOC | `ui/screens/station.gd:58-77`, `ui/theme/vajb_theme.tres` |
| the 60 %-of-list ammo price needs `game/exchange.gd`, in no worker's set | SPEC + HARNESS | `game/exchange.gd:118-149`, SLICE.md:52 |
| do the ammo rows stay in ARMORY (delivering to cargo) or leave it? | DOC | `STATION_HUB.md:918-919` vs `10_ship_acquisition.md:256` |
| the shipyard's class icon §5.11 asks for does not ship | DOC | `STATION_HUB.md:899` vs `:830-832` |
| §5.2 :508-526 is not marked superseded by §5.11 | DOC | `STATION_HUB.md:521-526`, `:897-903` |
| the railgun's pack rounds/cost/`ammo_max` (or revert to the cannon's family) | owner number | `player_profile.gd:158-165`, `station_catalog.gd:14-51`, `09_ship_slots_modules.md:98-102` |
| `DRIVES` needs `engine` (the catalogue key), not `engines` (the family name) | SPEC | `CONTRACTS.md:1682`, `module_catalog.gd:523,532,541`, `ship_fit.gd:59` |
| the `ammo_*` cargo id ↔ family id mapping; and the fuel-cell delist has no sale surface to remove | DOC | `CONTRACTS.md:1688-1691`, `game/exchange.gd:144-149` |
| §16's four stale citations (L126's class) | DOC | `CONTRACTS.md:1515,1540,1612,1672` |
| 09 §10's pre-build citation | DOC | `09_ship_slots_modules.md:494-495` |
| 09 §8 vs §11 (no pointer between them); §8's pre-D2 icon shape | DOC | `09_ship_slots_modules.md:409-420` vs `:527-534` |
| STATION_HUB §4/§5.2/§7.1/§7.2 pre-D2 raster paths; ASSET_NAMING_SPEC pre-D2 | DOC | `STATION_HUB.md:255,264,281,292,319,520,949-972`; `ASSET_NAMING_SPEC.md:96-101,163-164` |
| dead tint fallback in three panes | CODE (LOW) | `auction_panel.gd:640-651`, `outfitting_panel.gd:148-155`, `fitting_panel.gd:92-99` |
| L124's `_base_id` citation | DOC (LOW) | `_state/LOW_BACKLOG.md:312` → `outfitting_panel.gd:1323` |
| HUD has no railgun/mining icon | CODE (LOW) | `ui/hud/hud.gd:47-51` |
