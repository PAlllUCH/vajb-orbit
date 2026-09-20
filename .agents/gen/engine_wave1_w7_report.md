# Engine wave 1 — W7 fix report

Worker: **W7** (fix cycle 1). Status: **done; all six assigned findings fixed and
measured clean** (fix probe 29 checks / 0 failures, four boot gates exit 0 with no
new output, P1 suite 53/53). Contract: `ENGINE_SPEC.md` (§4.2 item 1, §6, §7, §9, §10,
§12 item 5, §13, §14), `.agents/gen/engine_wave1_task.md` global rules + §W7, and the
findings in `.agents/gen/engine_wave1_review_report.md` §4/§7 as re-read against
`.agents/gen/engine_wave1_w5_report.md` §7 (the paste-ready reticle hunk).

Assigned: **H1, H2, H3, H4, M1, M2 (code half only)**. **M3–M7 were not touched** (owner
rulings pending) — verified by `git`-less mtime/hash scan: no byte of
`player_ship.gd`'s laser mount gate, `sector_registry.gd`, `sector.gd`,
`asteroid_field.gd`, `target_reticle.gd` or `docs/` was written by this pass.

Nothing was redesigned: every change is inside `ENGINE_SPEC.md` and the pinned
interfaces. No new constant carries a gameplay value; the one new geometry number
(the ship's collision radius) is derived from shipped art and documented with its
reversal path. The HUD API stays frozen, no theme item was added, and no hex literal
was introduced.

---

## 0. Gates run (exact commands and results)

```
# 1. fix probe (scene run; source archived, see §5)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_w7_seams.tscn
-> exit 0, "=== w7 fix probe: checks 29, failures 0 ==="   (.agents/gen/engine_wave1_w7_probe.txt)

# 2. flight-scene boot gate
... --headless --path <proj> --quit-after 180 res://game/game.tscn
-> exit 0, 159-byte log = banner + helper line, no ERROR/WARNING  (…_w7_boot_game.txt)

# 3. menu gate
... --headless --path <proj> --quit-after 180 res://ui/screens/main_menu.tscn
-> exit 0, 408-byte log (the pre-existing 4 ObjectDB/2 resource leak tail)  (…_w7_boot_menu.txt)

# 4. settings gate (the Controls tab builds one row per REBINDABLE_ACTIONS entry)
... --headless --path <proj> --quit-after 180 res://ui/screens/settings.tscn
-> exit 0, 159-byte log, no output beyond the banner  (…_w7_boot_settings.txt)

# 5. station gate
... --headless --path <proj> --quit-after 180 res://ui/screens/station.tscn
-> exit 0, 408-byte log (same pre-existing tail)  (…_w7_boot_station.txt)

# 6. the P1 economy suite
... --headless --path <proj> res://tests/headless_runner.tscn
-> exit 0, "[SUMMARY] passed=53 failed=0"  (…_w7_tests.txt)
```

Probe source archived at `.agents/gen/engine_wave1_w7_probe_source.gd` +
`…_source.tscn`; copy both to `res://tools/_probe_w7_seams.gd|.tscn` to re-run gate 1.
The throwaway copies and their `.uid` were deleted afterwards: `vajb-orbit/tools/` holds
only `build_theme.gd` and `derive_icon_tints.gd` (+ their `.uid`).

Editor LSP also returns **no diagnostics** for `game/game.gd`, `game/pickup.gd`,
`game/player_ship.gd`, `game/player_state.gd`, `autoload/settings_manager.gd` (editor
open with the project; the language server is live). Per W6 §6 that silence is not proof
on its own, which is why the gates above are scene runs.

---

## 1. Files changed (before → after) and scope proof

All six files are LF-only, tab-indented (0 lines indented with four spaces), with no hex
literal. Sizes and hashes measured with `py -3.14` (the interpreter AGENTS.md mandates).

| File | Bytes | Lines | md5 after |
|---|---:|---:|---|
| `vajb-orbit/game/player_state.gd` (H3) | 1 984 → **2 571** | 70 → **79** | `186BECEA20573967EC6BE50743C66095` |
| `vajb-orbit/autoload/settings_manager.gd` (M2) | 12 566 → **12 901** | 423 → **432** | `899E39F25E8845995CCF109236E37676` |
| `vajb-orbit/game/player_ship.tscn` (H2) | 432 → **725** | 12 → **22** | `EA4B48F35691B4B2803E6249E0E0B528` |
| `vajb-orbit/game/player_ship.gd` (H2, M1) | 11 216 → **13 356** | 331 → **370** | `92BA1FEC16FD955097DD238D034E5DE5` |
| `vajb-orbit/game/pickup.gd` (M1) | 6 775 → **7 734** | 167 → **184** | `4BEA026109FCF8FA7F3BF2E75E64E227` |
| `vajb-orbit/game/game.gd` (H1, H4) | 16 208 → **19 462** | 508 → **587** | `11717BDEFD418678A069C3BFF4D6DE55` |

Before-hashes for the same six: `59D1122081947F84D62C80021F3F1863`,
`F5FF335E8C959BC475C7853BE5791222`, `B8532F34D6BE08BF8E00740BCAAE5795`,
`6EA28365A486B916280E33CDBD0DAA53`, `91594EA0A15010821F24BE489FD189EC`,
`03144938FA5FDB92D30CBD5AA6DB8914` (the last two are the values W3 and W2 reported).

**Untouched, re-measured after the pass.** `ui/theme/vajb_theme.tres` 25 771 B, md5
`F0BF1B434CB19EDD0FEE7001B17632B4`, mtime **15:16:36** — W5's figure exactly, so this
pass cannot have added a theme item. `project.godot` 6 417 B, md5
`1E69D6C2F84C9FAF26F631FDBD202A7B` (M2's `interact`/`warp` are **not** applied: that is
the orchestrator's step). The HUD quartet (`hud.gd` `0AE885AC…`, `hud.tscn`
`343D63F2…`, `minimap.gd` `8EB85539…`, `target_reticle.gd` `98FEA210…`) is byte-identical
to W5's report, so the frozen `Hud` API and the reticle are untouched: H4 is a caller,
not a HUD edit. `tools/build_theme.gd` md5 `3962995AA4E7C48E02B647A4B5DA630D`.

**Scope proof** (mtime scan of everything under `vajb-orbit/`, `.godot/` excluded, 40
minute window). Exactly the six files above, nothing else — no `docs/`, `assets/`,
`addons/` or probe residue:

```
17:45:57 game/player_state.gd
17:46:01 autoload/settings_manager.gd
17:46:48 game/player_ship.tscn
17:48:03 game/game.gd
17:59:30 game/player_ship.gd
17:59:34 game/pickup.gd
```

---

## 2. The six fixes

### H1 — the profile's manifest is mirrored into `PlayerState` (`game.gd`)

`PlayerProfile` stays the only cargo owner (17 §5 rule 2) and `PlayerState` stays the
only channel the HUD reads (§3.9); the missing wire between them now exists in three
places:

- `game.gd:461-473` `_sync_cargo()` sums `PlayerProfile.cargo_items()` and calls
  `PlayerState.set_cargo_used(used)` when the value differs (so the signal is not
  spammed).
- `game.gd:504` calls it from `_refresh_hud()`, i.e. on the existing 0.1 s
  `HUD_REFRESH_INTERVAL` tick and on every other HUD refresh.
- `game.gd:436-455` connects `PlayerProfile.profile_changed` (key `&"cargo"`,
  `PROFILE_CARGO_KEY` at `game.gd:31`) to `_on_profile_changed` → `_sync_cargo()`, so a
  **collection, sale or refinery job** moves the readout on the same call, with no frame
  in between. `_exit_tree` (`game.gd:123-126`) disconnects it again.

Measured in the live scene: the readout tracks the profile at boot (`CARGO 38/40` with
38 units), with `PlayerState` forced stale a single `_refresh_hud()` restores it
(`profile=34 state=34`), a direct `add_cargo` shows up with no frame in between
(`34 → 37`, footer `CARGO 37/40`), the cargo cells fill to the same count (37 of 40), a
collected pickup does the same (`35 → 37`, footer `CARGO 37/40`), and the hold-full
state is live: at fill 40 the footer reads `CARGO 40/40` with the `accent_danger`
override set, and emptying it clears the override. W6's measurement was `CARGO 0/40`
for every frame.

### H2 — the player ship collides with rocks (ENGINE_SPEC §6)

`game/player_ship.tscn` gains one node and one shape:

```
[sub_resource type="CircleShape2D" id="CircleShape2D_hull"]
radius = 30.0

[node name="HullBody" type="CharacterBody2D" parent="."]
collision_layer = 2
collision_mask = 1
motion_mode = 1

[node name="Shape" type="CollisionShape2D" parent="HullBody"]
shape = SubResource("CircleShape2D_hull")
```

The ship occupies its own layer (2) and masks only the rock layer
(`Asteroid.COLLISION_LAYER` = 1, whose comment already anticipated exactly this: "a ship
that collides with rocks is the moving body masking it (the ship's own layer is W2's
choice)"). `player_ship.gd:21-29` carries the derivation and the reversal path;
`player_ship.gd:76` resolves the body once in `_ready`; `player_ship.gd:236-253` runs the
step through it:

```gdscript
func _advance(delta: float) -> void:
	var motion := Vector2.RIGHT.rotated(_heading) * _speed * delta
	if _body == null or not is_inside_tree():
		position += motion
		return
	var travelled := motion
	var collision := _body.move_and_collide(motion)
	if collision != null:
		travelled -= collision.get_remainder()
	position += travelled
	_body.position = Vector2.ZERO
```

The ship keeps owning its transform (the body sits at local zero and is re-zeroed each
step); `move_and_collide` owns the collision test. **Momentum is deliberately untouched**
(no invented brake or bounce rule): a blocked step costs the distance only, so turning
away and thrusting leaves the rock. The fallback branch keeps every pre-fix behaviour
that does not have a body in the space (a ship outside the tree, a scene without the
node), which is what makes the negative control below meaningful.

Measured: 1 collision body, layer 2 / mask 1, radius 30.0. Thrust from (0, 0) for 400
manual steps at 1/60 against a 66 u-radius rock at x = 200 stopped the ship at
x = **103.9999** (contact = 200 − 66.0 − 30.0 = 104.0): it stops *at* the surface (the
sub-milliunit shortfall is Godot's `move_and_collide` safe margin). W6 measured the same
run ending at x = **2201.7** with no body; the W7 probe reproduces that exact number as
its negative control (a ship not in the tree), so the stop is the body and not the
harness. In the live scene every layer-1 physics body is an asteroid (63 bodies, 0
others; the 1 layer-1 *area* is the sector's `DockZone`, which cannot block motion), so
the mask can only ever see rocks.

The one behavioural risk of making rocks solid is a spawn *inside* a rock, which would
wedge the ship. Measured across all seven registry rows (fresh populate, 39-73 rocks
per sector, spawn `(0, 420)` in every row): the closest rock **surface** to any shipped
spawn is **1308.79 u**, against the 30.0 u hull radius.

### H3 — `PlayerState.damage(amount, bypass_shield := false)` (ENGINE_SPEC §4.2 item 1, §12 item 5)

`player_state.gd:48-60`:

```gdscript
func damage(amount: float, bypass_shield: bool = false) -> void:
	if amount <= 0.0:
		return
	if not bypass_shield and shield > 0.0:
		set_shield(shield - amount)
		return
	set_hull(hull - amount)
```

A live shield takes the hit, absorbing up to its current value with **no carry-over**
(§4.1: "no hull damage while shield > 0"); `bypass_shield` is the kinetic/missile/
deployable rule and lands on the hull. `set_shield`/`set_hull` keep their signals, so
the HUD channel and `PlayerShip.damage_taken` (which is how the warp channel breaks) are
unchanged.

Measured: `damage()` has 2 arguments; `hull 500 / shield 100`, `damage(150)` →
`hull 500, shield 0` with exactly one `shield_changed` and zero `hull_changed` events;
`damage(50)` then takes the hull to 450; `damage(150, true)` leaves the shield at 100 and
the hull at 350; `damage(40)` leaves `shield 60 / hull 500`; non-positive amounts are
still no-ops.

### H4 — the mining reticle state is pushed from `game.gd`

`game.gd:95` caches the shaft (`_laser`) once in `_spawn_ship` (`game.gd:228-231`),
`game.gd:382-402` is W5 §7's hunk with the cached node and a value mirror, and
`game.gd:135` calls it every physics frame:

```gdscript
func _push_reticle_state() -> void:
	if _hud == null or not _hud.has_method(&"set_reticle_state"):
		return
	var state: int = TargetReticle.State.PLAIN
	if _laser != null and bool(_laser.call(&"is_active")):
		state = (
			TargetReticle.State.IN_RANGE
			if bool(_laser.call(&"has_target"))
			else TargetReticle.State.OUT_OF_RANGE
		)
	if state == _reticle_state:
		return
	_reticle_state = state
	_hud.call(&"set_reticle_state", state)
```

Measured in the live scene with a rock 100 u along the cursor ray: reticle at rest
`PLAIN`; beam active + `has_target()` true → **`IN_RANGE`**; beam still active with the
rock removed → **`OUT_OF_RANGE`**; trigger released → **`PLAIN`**. W6 measured `state=0`
in the same situation, so both meaningful slice-1 states are now reachable.

### M1 — one hold source for the pickup gate

`PlayerShip.cargo_max()` (`player_ship.gd:124-133`) returns the live hold
(`PlayerState.cargo_max`, which `game.gd:_apply_ship_maxima` seeds from the `ShipFit`
snapshot per §9; the `_stats` value is the pre-`setup` fallback). `pickup.gd:134-161`:
the gate reads that accessor, `_hold_has_room(ship)` is passed the ship it already
looked up, and the unused `station_catalog.gd` preload is gone. A group member that does
not expose the accessor (a probe's stand-in) falls back to `ShipFit.HULLS` for the
profile's active hull, the same table the accessor is seeded from; the station
catalogue's `cargo` column is never consulted again.

Measured: `ShipFit` and `StationCatalog` disagree on **5 of 9** hulls. With the profile
on `ship_miner` (no catalogue row; `ShipFit` hold 55) an ore pickup placed on the live
ship is **collected** (cargo 36 → 37). A stand-in without the accessor resolves hold 40
and, with the profile on `ship_miner`, hold **55**. With the hold filled to 40, an ore
pickup 42.43 u away (inside `TRACTOR_RANGE` 120) neither moves nor collects. W6 measured
the miner case as not collected (35 → 35).

### M2 — `SettingsManager.REBINDABLE_ACTIONS` 15 → 17 (code half only)

`settings_manager.gd:28-51` appends `&"interact"` and `&"warp"` after `&"target_next"`,
exactly the order `docs/design/PROJECT_SETTINGS_PATCH.md` §2 assigns (orders 16/17). The
doc comment records that the list leads the input map and every reader is
`InputMap.has_action`-guarded (`_capture_default_events`, `_load_inputs`,
`reset_all_inputs`, `save_inputs`, `binding_text`, `set_binding`, all unchanged), and
`game.gd`'s `interact`/`warp` reads keep their guards (the fix adds no read).

Measured: `rebindable_actions()` = **17**, tail `[&"interact", &"warp"]`, all 17 in patch
order; `binding_text(&"interact", 0)` = `""` (the Controls tab renders the two new rows
as UNBOUND, `ui/screens/settings.gd` builds them dynamically and labels them
`INTERACT`/`WARP`); `InputMap.has_action(&"interact")` / `(&"warp")` are still **false**
and `project.godot` is untouched, i.e. this is the code half only. The settings screen
boots clean with the 17-row Controls tab, and the live flight scene still shows
`F · DOCK` inside the dock zone and hides it outside with both actions unapplied, so the
guarded paths are intact.

---

## 3. Acceptance evidence per finding

| Finding | Measured | Where |
|---|---|---|
| H1 | `CARGO 38/40` at boot → `CARGO 40/40` at fill → `CARGO 0/40` emptied; the readout tracks the profile at boot, on `add_cargo`, on a collected pickup; cells filled = `cargo_used` | probe log lines 31-39, 47-50 |
| H2 | 1 body, layer 2, mask 1, radius 30.0; thrust run stops at x = 104.0 (contact 104.0); the same run without the body reaches x = 2201.73; every layer-1 body is an asteroid (63, 0 others); closest rock surface to a spawn 1308.79 u | probe log lines 13-19, 20-29, 51-53 |
| H3 | args = 2; `150 → shield 0 / hull 500` (1 shield event, 0 hull events); `50 → hull 450`; `150 bypass → shield 100 / hull 350`; `40 → shield 60 / hull 500` | probe log lines 4-11 |
| H4 | reticle 0 at rest → **1** with beam + target → **2** with beam, no target → **0** on release | probe log lines 54-59 |
| M1 | 5 of 9 hulls differ between the tables; `ship_miner` (catalogue row missing) collects; stand-in fallback 40 / 55; full hold (42.43 u away) blocks | probe log lines 41-48 |
| M2 | 17 actions in patch order, tail `[interact, warp]`, unbound text, `InputMap` still false, settings gate clean | probe log lines 65-67, gate 4 |
| No regression | four boot gates exit 0 with no new output; P1 suite 53/53 | §0 |

---

## 4. Deviations, interpretations and open points

1. **The ship's collision radius is art-derived, not spec'd (LOW, disclosed).** No doc
   pins a hull radius. 30.0 is the half-length the shipped `ship_vanguard_side.png`
   (905 px at the scene's 0.0663 = 60.0 u) implies, the same basis `asteroid.gd`'s
   `LOOK_WIDTHS` reads. A circle is rotation-invariant and the hull's long axis
   dominates; the disclosed consequence is that a *side-on* stop leaves about 17 u of
   visual gap (the nose, which is what players notice, stops exactly at the surface).
   Reversal: one node in `player_ship.tscn`.
2. **Impact response is "solid, no damage" (interpretation).** §6 says rocks are solid
   and says nothing about impact damage, sliding, or speed loss, so the fix neither
   invents damage nor zeroes `_speed`: the step is simply truncated at the rock, and a
   ship pinning itself nose-first stays pinned until it turns. A slide (two
   `move_and_collide` calls, or `move_and_slide`) would fit the same spec and is a
   deliberate follow-up, not part of this finding.
3. **Layer choice has one forward consequence (LOW).** The ship is layer 2 / mask 1, so
   the sector's `DockZone` Area2D (default layer 1 / mask 1) would not detect the ship by
   physics overlap. Nothing depends on it today: `Sector.dock_zone_contains` is a
   geometric test by design (`sector.gd` documents "the player ship is a plain Node2D
   this slice"), and the prompt measurement proves docking still works. If a later wave
   moves docking to Area2D signals, the zone must gain layer 2 (one property).
4. **M1's accessor is the primary reader, `ShipFit.HULLS` the fallback.** Both read one
   table; the catalogue is never consulted. W6's brief said "+ `PlayerShip` accessor",
   and the fallback keeps the established probe idiom (a bare `Node2D` in the
   `player_ship` group) working, which is what the wave's own pickup harness uses.
5. **The reticle push runs every physics frame, mirrored.** W5 §7 allowed
   `_refresh_hud()`; at 0.1 s the cursor reticle would lag the trigger visibly, and the
   read is two guarded calls on a cached node, so the per-frame placement was chosen.
   The mirror keeps the HUD from being addressed with an unchanged value.
6. **H1 mirrors `used` only.** `cargo_max` is still seeded once at launch from `ShipFit`
   (§9); nothing in slice 1 changes the hold mid-flight. A mid-flight fit change would
   need a second mirror, which is slice 4's fitting layer.
7. **Unrelated, not fixed (report only).** The editor (open with the project, and with
   the flight scene **playing**) reports pre-existing warnings this pass did not cause
   and did not touch: a parse error in `ui/station/exchange_panel.gd`
   (`_icon_tint()`) and `settings_manager.gd`'s event-cast `INT_AS_ENUM_WITHOUT_CAST`
   warnings plus a local `name` shadowing `Node.name` (P1/Controls-tab territory). The
   wave's own items M3–M7 are untouched and still await owner rulings, as does the
   orchestrator's `project.godot` application of `interact`/`warp`.
8. **W6's probe harness rule gained a corollary (process, LOW).** The W6 probe's
   collision seam drove `_physics_process` on a ship that was never added to the tree, so
   its body could not have been in the physics space even after this fix. The W7 probe
   adds the ship with `set_physics_process(false)` (so the manual stepping stays
   deterministic per W6 §6) and awaits one physics frame, then drives it: that is the
   shape a re-review must use for any collision measurement.

---

## 5. Probe hygiene and owner data

- One throwaway probe (`extends Node`, `quit()`-terminated, 90 s watchdog, scene run
  because `game.gd`'s `Router` autoload cannot compile in a `--script` main loop),
  archived and deleted with its `.uid`; `tools/` ends holding only `build_theme.gd` and
  `derive_icon_tints.gd`.
- **The W6 probe left debris that this pass removed.** `user://_w6_probe_profile.cfg`
  was still on disk: its cleanup called `DirAccess.remove_absolute("user://…")`, which
  does not resolve, and the profile's exit flush recreated the file after the cleanup
  anyway (the scratch profile is written at `NOTIFICATION_EXIT_TREE`, i.e. after the
  probe's own deletion). The W7 probe fixes both halves:
  `ProjectSettings.globalize_path()` for the path, and clearing the profile's dirty flag
  plus its debounce timer before deleting. Verified: `_w6_probe_profile.cfg` and
  `_w7_probe_profile.cfg` are gone and a re-run leaves none behind.
- **Owner data untouched by the probe.** `user://profile.cfg` (md5
  `5387980C4CEC80EE4DCB43416911198F`) and `user://economy_log.txt` (md5
  `4DD97C470E1548841976FE9ADBCDF4C6`) had the same size, mtime and hash either side of the
  probe runs, because the probe repoints `PlayerProfile.save_path` and
  `economy_log.log_path` at scratch files and restores the manifest it perturbed
  (measured: "profile cargo restored: 38 units in 5 stacks"). Those hashes describe that
  measurement window only: the concurrently playing editor game rewrites both files
  afterwards, so a re-review must re-take its own before/after pair around the probe run
  rather than compare against them.
- **Environment note for the reviewer.** While this pass ran, the editor had
  `res://game/game.tscn` **playing** (`editor_manage(op="state")` →
  `is_playing: true`, game live), and that session is mining continuously: the MINE lines
  arriving in `user://economy_log.txt` every ~1 s and the profile writes during the same
  minutes come from it, not from these gates. It also means the owner's live manifest
  changes between runs (it held 38 units at the last probe), which the probe now tolerates
  by freeing headroom before any collection assertion.
- The probe's evidence is fully re-runnable from the two archived files; gate 1 prints
  `checks 29, failures 0`.

---

## 6. Handoff to W8 (re-review)

Re-measure, do not trust this report: the six md5s (§1), the theme/`project.godot`/HUD
hashes, the four gates, the P1 suite, and gate 1 after copying the archived probe back
into `res://tools/` (delete it again afterwards). The specific claims to attack:

1. H1 — force `PlayerState.cargo_used` stale, call `_refresh_hud()`, then collect a
   pickup and read the footer *before* any frame passes.
2. H2 — repeat the thrust run **with the ship in the tree** (W6's own seam-3 probe added
   only the rock, which is why it could not see a body), check the stop lands on
   `200 − rock_radius − 30`, and re-measure the spawn clearance over all seven rows.
3. H3 — the four cases in §2/§3 plus the signal counts.
4. H4 — the three reticle states, in the live scene, with the beam held active across the
   rock's removal.
5. M1 — the `ship_miner` collection and the full-hold drift, both keyed on the ship's own
   hold rather than the catalogue row.
6. M2 — `rebindable_actions().size() == 17` while `project.godot` still lacks both
   actions (the orchestrator applies them; the guards are what keeps the game running
   until then).

Still open for the orchestrator/owner, unchanged by this pass: the `project.godot`
application of `interact`/`warp`, and the M3–M7 rulings (mining-laser mount gate,
sector 7's station, field respawn semantics, `clear_target`'s frozen behaviour, the
02 §9 asteroid-combat sentence).

---
---

# Batch 2 — the M3 W-slot gate, plus the M4–M7 owner rulings (appended 2026-09-18)

Batch 2 is a second, single-finding pass over the same wave, run after the owner ruled on
W6's M3–M7. It fixes **M3 only** and records the other three rulings in place of code.
Scope was fixed by the ruling: keep the pinned `PlayerShip` API and scene shape, keep W3's
`MiningLaser` script untouched, touch nothing that M4/M5/M6 describe, and change no doc. No
doc change was needed in the other direction either: 09 §4.5 and ENGINE_SPEC §4.3/§6 already
require the W slot, so this pass made the code conform to the docs rather than the reverse.

**M3 (fixed).** The mining laser is mounted, and `E` mines, only when the resolved fit
carries `w_mining` — 09 §4.5's W-slot module, per ENGINE_SPEC §4.3 ("`E` … fires the
mining laser whenever it is fitted") and §6 ("Mining laser (`w_mining`, W slot, 09 §4.5)").
The standard fit carries no `w_mining`, so **the launch ship mines nothing until that
module is fitted**; one W slot is the price of the ability (the Delver/Fighter trade-off).

**M4, M5, M6 (ruled keep-as-is, no code touched).** Owner rulings, recorded here instead of
in code, see §B5.

**M7 (doc-only, not done this pass).** See §B5.

---

## B1. Gates run (exact commands)

```
# 1. M3 gate probe (scene run; source archived, see §B6)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 1800 \
  res://tools/_probe_m3_gate.tscn > .agents/gen/engine_wave1_w7_m3_probe.txt 2>&1
-> exit 0, "=== m3 gate probe: checks 6, failures 0 ==="    (run twice, byte-identical result)

# 2. flight-scene boot gate (the launch ship, standard fit)
... --headless --path <proj> --quit-after 180 res://game/game.tscn
-> exit 0, 159-byte log = banner + helper line, no ERROR/WARNING
   (.agents/gen/engine_wave1_w7_b2_boot_game.txt)

# 3. menu gate      ... --quit-after 180 res://ui/screens/main_menu.tscn
# 4. settings gate  ... --quit-after 180 res://ui/screens/settings.tscn
# 5. station gate   ... --quit-after 180 res://ui/screens/station.tscn
-> exit 0 each; menu/station carry the pre-existing 4 ObjectDB + 2 resource tail,
   settings = the 159-byte clean log   (…_b2_boot_menu|settings|station.txt)

# 6. the P1 economy suite
... --headless --path <proj> --quit-after 3000 res://tests/headless_runner.tscn
-> exit 0, "[SUMMARY] passed=53 failed=0"   (…_b2_tests.txt)
```

Every Godot run is bounded by `--quit-after` and the probe self-quits behind a 90 s
watchdog; all stdout is redirected to a log that was read afterwards. Nothing ran in the
background and no command exceeded 60 s.

---

## B2. Files changed (before → after) and scope proof

| File | Bytes | Lines | md5 after |
|---|---:|---:|---|
| `vajb-orbit/game/player_ship.gd` | 13 356 → **15 166** | 370 → **413** | `036A49444B28D0C34423AE2D832ABC06` |
| `vajb-orbit/game/game.gd` | 19 462 → **19 715** | 587 → **590** | `BDD96126548758C27DBC154D5091D625` |

Before-hashes are §1's after-hashes: `92BA1FEC16FD955097DD238D034E5DE5` (player_ship.gd)
and `11717BDEFD418678A069C3BFF4D6DE55` (game.gd). Both files are LF-only, tab-indented
(0 lines indented with four spaces), end with a newline and contain no hex literal (measured
with `py -3.14`, the interpreter AGENTS.md mandates).

**Untouched, re-measured after this pass** (the ruling's "keep" list, plus the wave's frozen
artefacts):

| File | Bytes | md5 (measured) | Note |
|---|---:|---|---|
| `game/mining_laser.gd` | 8 428 | `792305ECD1AB50CBEEDC78D483AFD6FF` | **W3's script, byte-identical** (W6's §1 value) |
| `game/mining_laser.tscn` | 333 | `AE7437E276EEC22A543DC2813DE695A5` | W3's scene, byte-identical |
| `game/player_ship.tscn` | 725 | `EA4B48F35691B4B2803E6249E0E0B528` | the H2 shape survives; no node added or removed |
| `game/sector_registry.gd` | 5 815 | `C3F3AE450CEF4F03FAE0233EA4DB2077` | M4 territory, untouched |
| `game/sector.gd` | 12 438 | `02BE97B023CED32ABA4D7023DA69B5B8` | M5 territory, untouched |
| `game/asteroid_field.gd` | 8 686 | `6A299942EDD699974F04D4AFD20C5DDD` | M5 territory, untouched |
| `ui/hud/target_reticle.gd` | 6 553 | `98FEA21048E6746F9B6D3ACA2DF7BDD5` | M6 territory, untouched |
| `project.godot` | 6 417 | `1E69D6C2F84C9FAF26F631FDBD202A7B` | no wave-1 edit, no input action added |
| `ui/theme/vajb_theme.tres` | 25 771 | `F0BF1B434CB19EDD0FEE7001B17632B4` | no theme item added |
| `tools/build_theme.gd` | 23 761 | `3962995AA4E7C48E02B647A4B5DA630D` | untouched |

**Scope proof** (mtime scan of everything under `vajb-orbit/`, `.godot/` excluded, 45-minute
window). Exactly the two files above fall inside this pass's window; the four earlier stamps
are the W7 fix pass, and no `docs/`, `assets/`, `addons/` or probe file was written:

```
17:45:57 game/player_state.gd          (W7 pass)
17:46:01 autoload/settings_manager.gd  (W7 pass)
17:46:48 game/player_ship.tscn         (W7 pass)
17:59:34 game/pickup.gd                (W7 pass)
18:06:56 game/game.gd                  (batch 2)
18:07:05 game/player_ship.gd           (batch 2)
```

---

## B3. The M3 fix

### B3.1 The gate reads the resolved fit, and the fit arrives through `setup`

`player_ship.gd`:

- `MINING_MODULE := &"w_mining"` (`:27`), the module 09 §4.5 and ENGINE_SPEC §6 name.
- `var _fit_ids: Array[StringName] = []` (`:65`) — the launched fit's module ids.
- `setup(stats, state) -> setup(stats, state, fit_ids: Array[StringName] = [])` (`:97`),
  storing `fit_ids.duplicate()` and calling `_sync_mining_laser()` (`:101-102`).
- `_sync_mining_laser()` (`:327`) — mount **or** release, so a hull swap to a fit without
  the module takes the node away again; `_has_mining_module()` (`:335`) is the single test;
  `_release_mining_laser()` (`:339`) detaches, frees and clears the cached node and the
  trigger flag; `_mount_mining_laser()` (`:350`) now ignores a node already queued for
  deletion so a release-then-remount in one frame cannot adopt a dying child.
- `_update_mining_laser()` (`:378`) repeats the gate, so a laser node authored into the
  scene can never be fired by a fit that does not carry `w_mining`.
- `_ready()` (`:83`) calls `_sync_mining_laser()` instead of mounting unconditionally: with
  no fit supplied yet it mounts nothing, which is the safe default.

`game.gd` (`:229`) passes the launched fit's ids at the one launch site:

```gdscript
	_ship.setup(_stats, _state, ShipFit.fitted_ids(ShipFit.STANDARD_FIT))
```

`ShipFit.fitted_ids()` is W1's existing helper (L4's additive API), so the ids come from the
same fit `_resolve_stats()` resolves — no second source, no duplicated module list, and the
v1 standard fit's ids are `[w_laser, s_light, h_plate_light, e_std, p_std]` (measured).

### B3.2 Why a third `setup` parameter and not a new `ShipStats` field

The ruling kept the `PlayerShip` API pinned, and `ShipStats`' 16-field list is pinned twice
over (ENGINE_SPEC §9, brief pin 1) with W6 re-verifying it in §2 of the review. The third
parameter is **additive and defaulted**: `setup(stats, state)` — the pinned shape, and every
existing call site, including the wave's own archived probes — still compiles and runs, and
the empty default means "no W slot spent, no laser". Nothing pinned was renamed, removed or
reordered, `ShipStats` is byte-identical, and `game.gd` is the only caller that supplies the
fit. The one behaviour a 2-argument caller gets (a ship with no mining laser) is the ruling's
own outcome for the standard fit, not a regression.

### B3.3 What the W-slot cost now means

`w_mining` resolves to no stats at all (`ShipFit.MODULES[&"w_mining"]` has `effects: {}`), so
before this pass the module was decorative: the laser was mounted for every fit because no
stat carried the difference. The gate now sits on the fit's module **ids**, which is the same
channel `boosters` already uses, and the cost is real: a hull that wants to mine must spend a
W slot (and the §4.4 power draw) on the tool, and a launched standard-fit ship cannot mine a
single unit.

---

## B4. Acceptance evidence (six checks, all measured)

Probe log: `.agents/gen/engine_wave1_w7_m3_probe.txt`. Two identical runs: `checks 6,
failures 0`.

| # | Check | Measured (log line) |
|---|---|---|
| a1 | the standard fit carries no `w_mining` | ids `[w_laser, s_light, h_plate_light, e_std, p_std]` (5) |
| a2 | a fit with `w_mining` resolves with the module in its ids | ids `[w_mining, s_light, h_plate_light, e_std, p_std]`, `resolve()` non-null (7) |
| c | **without `w_mining`: no laser mounts, `E` mines nothing** | `laser=<Object#null>`; rock yield **3 → 3**; pickups **0**; ship 200.0 u from the rock under the cursor (10) |
| b | **with `w_mining`: the laser mounts and one cycle mines one unit** | `laser=MiningLaser:<Node2D#…>`; rock yield **3 → 2**; pickups **1**; same 200.0 u geometry (13) |
| d | the pinned two-argument `setup(stats, state)` call still runs | laser absent, `hull_max=1000.0`, ship in the `player_ship` group (16) |
| e | the launch ship: standard fit, no laser, `E` inert, reticle plain | live `game.tscn`: `_ship` present, `game._laser=<Object#null>`, no laser node, `reticle_state=0` (PLAIN) with `mine` held for 100 frames, pickups **0**, hold 40 / hull 1250 (19) |

The two mining cases are the same harness, the same rock and the same 200.0 u stand-off
(cursor at the world origin, ship at `(-200, 0)`, rock at `(0, 0)`), so the negative control
is proven to measure the gate and not a broken measurement: the only difference is the fit.
The 200 u stand-off sits inside `MINE_LASER_RANGE` (220) and outside the pickup
`TRACTOR_RANGE` (120), so the positive case spawns its pickup and never collects it — the
probe's own profile writes are impossible by construction.

The launch ship boots clean (gate 2: exit 0, no ERROR/WARNING) and the P1 suite stays 53/53,
so the gate costs nothing outside mining: the ship, the collision body (H2), the reticle push
(H4, which already tolerated `_laser == null` and now has a permanent `null` on the launch
fit) and the pickup hold seam (M1) all behave as W7 measured.

---

## B5. Owner rulings recorded (no code, per the ruling)

1. **M4 — sector 7 spawns no station: keep as-is.** The Maw's `stations = 0`
   (`sector_registry.gd:113`) stays; §7's "warp reports unavailable (no station in the
   sector)" is the reading that governs, and W4's disclosed choice stands. No file touched
   (`sector_registry.gd` md5 `C3F3AE450CEF4F03FAE0233EA4DB2077`, `sector.gd`
   `02BE97B023CED32ABA4D7023DA69B5B8`, both re-measured unchanged).
2. **M5 — field respawn semantics: keep the `WorldClock` band.** Respawn stays on the
   20-minute `WorldClock` band with the `asteroid_field.gd` stamp-and-roll behaviour, i.e.
   02 §8's prose is not implemented literally; both halves remain as W3/W4 disclosed them.
   No file touched (`asteroid_field.gd` md5 `6A299942EDD699974F04D4AFD20C5DDD`).
3. **M6 — the cursor reticle stays always visible: keep as-is.** `TargetReticle.clear_target`
   keeps dropping only the lock brackets and micro-bar; the frozen §3.10 behaviour of the
   method is the accepted reading of §9.9's cursor reticle. No file touched
   (`target_reticle.gd` md5 `98FEA21048E6746F9B6D3ACA2DF7BDD5`).
4. **M7 — doc-only, and still open.** `docs/gameplay/02_minerals.md:190` still reads
   "Asteroid combat (shooting rocks to break them faster) — the mining laser is the only
   extraction tool in v1", while ENGINE_SPEC §2 decision 6, §6 and §13 ship gun work at
   10 %. Nothing was transcribed this pass: the wave's global rules freeze `docs/` after W0,
   and the ruling reads "record … instead of changing code", so the sentence stays wrong on
   disk and is flagged here for a doc pass (one sentence, into 02 §9).

---

## B6. Probe hygiene and owner data

- One throwaway probe (`extends Node`, `quit()`-terminated, 90 s watchdog, scene run because
  `game.gd`'s `Router` autoload cannot compile in a `--script` main loop), archived at
  `.agents/gen/engine_wave1_w7_m3_probe_source.gd|.tscn` and deleted from `res://tools/`
  with its `.uid` sidecar (none was created: the probe never went through an editor
  import). `tools/` was verified to end holding only `build_theme.gd` and
  `derive_icon_tints.gd` (+ their `.uid`).
- No scratch file survives: the probe repoints `PlayerProfile.save_path` and
  `economy_log.log_path` at `user://_probe_m3_profile.cfg` / `user://_probe_m3_log.txt`,
  clears the profile's dirty flag and debounce timer before exiting, and
  `user://` was listed afterwards: neither name exists. The probe's two mining cases spawn
  one pickup, which is deliberately outside tractor range and is freed by the probe.
- **Owner data untouched by this pass.** `user://profile.cfg` (md5
  `FDF15C59257C8F29460134DF6164FCC2`) and `user://economy_log.txt` (9 102 B) had the same
  mtime and hash either side of every batch-2 run, measured before and after. One caveat for
  a re-review: the **station boot gate** crossed a 20-minute market-band boundary at
  18:09:11 (the profile's `last_band` reads exactly that) and persisted the rolled prices at
  18:09:14 — pre-existing station/market behaviour that has nothing to do with this change
  (station code never instantiates `PlayerShip`), and a re-run inside the same band writes
  nothing. A re-review must therefore take its own before/after pair rather than compare
  against the hashes above.
- The editor was open with the project (`current_scene = res://game/game.tscn`,
  `play_state = stopped` at the session check) and was not driven by this pass; no editor or
  MCP write was attempted against it.

## B7. Handoff

Re-measure, do not trust this report. Copy the archived probe back into `res://tools/` as
`_probe_m3_gate.gd|.tscn`, run gate 1, delete it again, and re-take the six file hashes in
§B2. The specific claims to attack:

1. **The negative control is real mining geometry.** The rock sits on the beam's own cursor
   ray 200.0 u out, inside the 220 u range, and the positive control mines exactly one unit
   from the same placement. If the negative case ever stops mining for a *harness* reason,
   the positive case fails first.
2. **One unit per cycle, not per frame.** 100 frames (1.67 s) yields exactly one unit
   (yield 3 → 2) and one pickup: a second cycle would appear at 2.4 s.
3. **The pinned call shape.** `setup(stats, state)` still runs and mounts nothing; the
   third parameter is additive.
4. **The launch path.** `game.tscn` with the standard fit mounts no laser, `game.gd._laser`
   is `null`, the reticle stays `PLAIN` with `mine` held, and `E` produces no pickup and no
   rock work.
5. **Nothing else moved.** `mining_laser.gd|.tscn`, `player_ship.tscn`, `sector_registry.gd`,
   `sector.gd`, `asteroid_field.gd`, `target_reticle.gd`, `project.godot` and the theme are
   byte-identical to §B2's hashes.
