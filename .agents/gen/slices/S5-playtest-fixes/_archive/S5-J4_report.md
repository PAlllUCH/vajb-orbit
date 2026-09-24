---
slice: S5
worker: S5-J4
model: "deepseek/deepseek-v4-flash"
status: actionable    # one required test move outside the wave's declared list, one art contradiction (bucket 3), one deferred seam
gate: "566/0 (J3's close) -> 577/0, twice, on two scratch stores; live profile md5 unchanged"
---

# S5-J4 report — hardpoints & gunnery: the measured per-hull map, the FX rows, per-barrel tracking

## Result

`ShipFit.HARDPOINTS` now carries all nine player hulls — four thruster rows (`rear`,
`front`, `left`, `right`) and **one weapon mount per W cell** (29 mounts across the nine
hulls) — every number measured off the hull's own side render by
`tests/probe_s5_hardpoints.gd`, whose output is byte-identical to the shipped literal
(verified token by token below). `PlayerShip.thruster_anchors(mode)` resolves to the map
(rear by default, so every pre-S5 caller still reads thrust), `thruster_frame()` lights the
row the stick asks for through one stable emitter union, `PlayerShip.weapon_mount(i)` turns
mount *i*'s measured px into hull-local units at the sprite's own scene scale, and
`WeaponComponent` fires each barrel from that mount along its **own current facing** at its
family's new `track_dps`, with a beam connecting only inside `TRACK_TOLERANCE := 5.0 deg`.

Gate, this machine, twice on two fresh scratch stores (`XDG_DATA_HOME=/tmp/s5j4_scratch/xdg2`
and `.../xdg3`), live `user://` untouched (md5 `539de5b7af59c77b6bffc477413161da` identical
before and after every run):

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=577 failed=0        (both runs, identical; also a 600-frame game-scene smoke, 0 script errors)
```

Arithmetic: J3's close was **566/0**. The 577 = 566 **+ 11** — `test_s5_hardpoints.gd`'s own
eleven rows (a new suite). One existing row was re-pointed (below), leaving every other
suite's row count untouched.

## The measurement method (the deliverable's own provenance)

The render is the sprite the world draws for a hull, `res://assets/ships/ship_<stem>_side.png`
(the bow-right view `npc_registry` builds for NPCs and the station previews use), and the
probe is re-runnable and bounded:

```
XDG_DATA_HOME=/tmp/s5j4_scratch/xdg $GODOT_CONSOLE --headless --path "$VAJB_PROJ" --script res://tests/probe_s5_hardpoints.gd
```

Per hull, from the ink (`alpha > 16`), in **render px relative to the sprite's own centre**
(the point the scene's `Hull` sprite draws at; `+x` = bow, `+y` = starboard, Godot's own 2D
axes), so a consumer multiplies by the sprite's scene scale (`player_ship.tscn`: 0.0663):

1. `ink` box `[x0..x1] x [y0..y1]`, `L = x1 - x0 + 1`.
2. **rear** — flame-coloured 8-connected blobs of at least 60 px in the rear fifth of `L`;
   blobs whose y-centres are within 20 px are one nozzle (a plume split by the bell rim); the
   anchor is the blob's **mouth** (its max-x pixel, at the mean y of the pixels within 3 px of
   that column).
3. **front** — the bow band (the forward 4 percent of `L`): its two ink extremes.
4. **left / right** — the ink columns at 25 percent and 75 percent of `L`: each column's top
   edge (left) and bottom edge (right).
5. **weapon_mounts** — one per W cell in the hull's own row-major order: the cell's column
   fraction places the longitudinal station on the measured ink box, its row fraction the
   height, the nearest ink run is the cell's body section, and the mount sits at that height
   clamped 4 px clear of the section's edges (so no mount floats off the drawn hull).
   `facing` is the **silhouette's own tilt** at the station, measured on the top contour for a
   cell in the grid's upper half (bottom contour below) between 20 px behind and 20 px ahead,
   read as 0 (the hull's axis) when it exceeds 45 deg — a 40 px contour jump that steep is a
   step between structures, not a taper.

**The probe's literal is the shipped table.** Regenerated after the last edit and compared
token by token with `ShipFit.HARDPOINTS` (whitespace-normalised): identical.

The old `MOUNT_SPREAD` derivation (`ShipFit.mount_offset`, 09 section 8) is kept verbatim as
the fallback and is what a hull with no row still answers — section 11's named reversal.

## The measured table (09 section 11, the nine rows)

| `ship_fighter` | **2** `(-391.5, -71.2)` · `(-392.5, 37.3)` | **2** `(414.5, -38.5)` · `(414.5, 14.5)` | **2** `(-207.5, -174.5)` · `(207.5, -108.5)` | **2** `(-207.5, 92.5)` · `(207.5, 73.5)` | `W1` `(-103.5, -116.5)` `0.1`<br>`W2` `(103.5, -116.5)` `0.149` | `ship_fighter_side.png` · canvas 897x415 · ink 831x349 |
| `ship_vanguard` | **2** `(-371.0, -111.4)` · `(-369.0, 118.3)` | **2** `(443.0, -31.5)` · `(443.0, 22.5)` | **2** `(-222.0, -189.5)` · `(222.0, -95.5)` | **2** `(-222.0, 197.5)` · `(222.0, 137.5)` | `W1` `(-111.0, -168.5)` `-0.124`<br>`W2` `(111.0, -168.5)` `-0.503`<br>`W3` `(-111.0, 55.5)` `-0.173` | `ship_vanguard_side.png` · canvas 960x521 · ink 888x449 |
| `ship_miner` | **2** `(-439.5, -75.3)` · `(-440.5, 63.7)` | **2** `(453.5, -32.5)` · `(453.5, 102.5)` | **2** `(-227.5, -99.5)` · `(227.5, -64.5)` | **2** `(-227.5, 131.5)` · `(227.5, 127.5)` | `W1` `(-340.5, -106.2)` `-0.1`<br>`W2` `(340.5, -47.5)` `0.149` | `ship_miner_side.png` · canvas 981x355 · ink 909x283 |
| `ship_trader` | **2** `(-428.0, -72.1)` · `(-428.0, 71.1)` | **2** `(472.0, -57.5)` · `(472.0, 49.5)` | **2** `(-236.0, -147.5)` · `(237.0, -129.5)` | **2** `(-236.0, 148.5)` · `(237.0, 132.5)` | `W1` `(-118.0, -117.5)` `-0.025` | `ship_trader_side.png` · canvas 1022x389 · ink 946x313 |
| `ship_corvette` | **2** `(-456.0, -27.3)` · `(-457.0, 30.7)` | **2** `(480.0, -18.0)` · `(480.0, 17.0)` | **2** `(-240.0, -85.0)` · `(241.0, -54.0)` | **2** `(-240.0, 83.0)` · `(241.0, 56.0)` | `W1` `(-120.0, -63.9)` `0.359`<br>`W2` `(120.0, -63.9)` `-0.291`<br>`W3` `(-361.0, 20.6)` `0.173`<br>`W4` `(361.0, 43.5)` `0.221` | `ship_corvette_side.png` · canvas 1038x246 · ink 962x170 |
| `ship_freighter` | **2** `(-434.0, -71.1)` · `(-435.0, 41.3)` | **2** `(454.0, -57.0)` · `(454.0, 44.0)` | **2** `(-227.0, -134.0)` · `(228.0, -120.0)` | **2** `(-227.0, 133.0)` · `(228.0, 117.0)` | `W1` `(-114.0, -108.1)` `0.075` | `ship_freighter_side.png` · canvas 982x342 · ink 910x270 |
| `ship_gunship` | **3** `(-394.5, -163.8)` · `(-398.5, -125.9)` · `(-371.5, 83.0)` | **2** `(454.5, -53.0)` · `(454.5, 39.0)` | **2** `(-227.5, -267.0)` · `(227.5, -272.0)` | **2** `(-227.5, 265.0)` · `(227.5, 268.0)` | `W1` `(-341.5, -199.0)` `-0.1`<br>`W2` `(-113.5, -228.9)` `0.025`<br>`W3` `(113.5, -228.9)` `0.025`<br>`W4` `(341.5, -81.0)` `0.337`<br>`W5` `(-341.5, 113.7)` `0.1` | `ship_gunship_side.png` · canvas 983x644 · ink 911x572 |
| `ship_patrol` | **2** `(-398.5, -24.8)` · `(-400.5, 76.0)` | **2** `(465.5, 28.0)` · `(465.5, 46.0)` | **2** `(-233.5, -56.0)` · `(233.5, -12.0)` | **2** `(-233.5, 141.0)` · `(233.5, 94.0)` | `W1` `(-116.5, -124.1)` `0.0`<br>`W2` `(116.5, -27.0)` `0.197`<br>`W3` `(-116.5, -0.5)` `0.0`<br>`W4` `(116.5, -0.5)` `0.197` | `ship_patrol_side.png` · canvas 1007x384 · ink 933x310 |
| `ship_destroyer` | **4** `(-425.0, -85.8)` · `(-445.0, -52.7)` · `(-416.0, 52.7)` · `(-425.0, 83.3)` | **2** `(474.0, -30.5)` · `(474.0, 19.5)` | **2** `(-237.0, -113.5)` · `(238.0, -74.5)` | **2** `(-237.0, 117.5)` · `(238.0, 54.5)` | `W1` `(-190.0, -113.5)` `-0.075`<br>`W2` `(0.0, -98.5)` `0.268`<br>`W3` `(190.0, -82.5)` `-0.443`<br>`W4` `(-190.0, -23.2)` `-0.075`<br>`W5` `(190.0, -23.2)` `-0.443`<br>`W6` `(-380.0, 67.5)` `0.245`<br>`W7` `(-190.0, 67.5)` `0.0` | `ship_destroyer_side.png` · canvas 1028x349 · ink 950x273 |

Counts are the art's own: the Mule's render carries **two** lit nozzles against its three
engine cells, the Gunship three against two cells, the Destroyer four against three. That is
why section 8's one-anchor-per-engine-cell rule is superseded rather than kept beside the map
(see the test move below, and "Reported, not changed").

## AC5, measured — the nine rows resolve

`test_s5_hardpoints.gd` (all eleven rows green) reads the table back against the renders it
names and against the runtime seams:

- every one of the nine hulls has a row; all four thruster rows are non-empty; `weapon_mounts`
  has exactly `slot_capacity(hull, &"weapons")` entries; every value is inside its render's own
  canvas; an NPC hull (`ship_swarmer`) has no row and `hardpoints()` answers `{}`.
- **each W cell binds its own mount** — 29 cells, all distinct within a hull; the seven
  multi-mount hulls print `cells=N distinct=N` (Fighter 2, Vanguard 3, Miner 2, Corvette 4,
  Gunship 5, Patrol 4, Destroyer 7).
- a hull with no map keeps section 8 **edge for edge**: the single tail point at
  `-radius x 0.55`, every mode answering the same derived row, and an empty flag list.
- the FX seam resolves to the map at the sprite's scale for every mode, and the default mode is
  the rear row.
- the frame lights the row the stick asks for, measured on the Destroyer (rear 4, front 2,
  left 2, right 2): `thrust lit=4 of 10`, `brake/retro lit=2 of 10`, `strafe left lit=2 of 10`,
  `strafe right lit=2 of 10`; a coast at ratio 0.5 lights the rear row alone, a standstill
  lights nothing.
- the trail union is stable: `trail union=9 rear=3` on the Gunship (3 + 2 + 2 + 2), the same
  nine emitter nodes before and after a mode change, only the flags moving.

Before/after for the FX half, on the Mule (the hull the old test measured): **before**, three
derived anchors (one per engine cell, `MOUNT_SPREAD` geometry), the only rows the FX could
read; **after**, the render's two lit nozzle mouths at the sprite's scale, plus the front and
both side rows, each lit by its own stick.

## AC6, measured — gunnery

**Tracking (the owner's "weapons to not turn as fast ... different turn speeds").** A laser
(180 deg/s) and a rocket (60 deg/s) in the same rack, both settled on the aim first, then a
90 deg swing and half a second of frames:

```
[s5-hardpoints] 0.5 s after a 90 deg swing: laser moved 90.0 deg (error 0.0), rocket moved 30.0 deg (error 60.0)
```

— the ratio is exactly the table's 180/60 = 3; the fast barrel arrives, the slow one is 60 deg
short. The mine's row (`track_dps` 0) is measured holding its mount's own 0.7 rad facing while
a laser beside it arrives on the aim.

**A shot flies along its barrel's current facing, from its own mount.** A fixture hull with one
mount at `(12, -4)` px and a 0.4 rad rest facing, aimed a quarter turn away, releases on its
first frame:

```
[s5-hardpoints] shot at (12.0, -4.0) bearing 24.9 deg
```

— the spawn is the mount (not the hull's centre, not the aim) and the bearing is the mount's own
0.4 rad plus the single frame of tracking it earned (0.4 rad = 22.9 deg). The pin's owner tick
chose this over hold-fire-until-aligned; that alternative is one gate in `_fire_projectile`
(skip the release while `_beam_aligned(position)` is false), named here as the reversal.

**The beam connects only inside `TRACK_TOLERANCE := 5.0 deg`.**

```
[s5-hardpoints] beam tolerance: aligned frame 0.500 damage, -87.0 deg off made no entry, sweep back in 0.0 deg
```

— aligned, one frame delivers `dps x delta` (0.5 at 0.1 s); a quarter-turn aim change leaves the
barrel 87 deg off on the first frame, the shaft is still drawn **where the barrel points** and
the contact deals nothing; half a second of the laser's 180 deg/s brings it back inside the cone
and the damage resumes; a 3 deg error still connects (the cone's own edge).

**The reversal, measured.** With `TRACK_MULT := 0.0` the gate reads **573 passed / 4 failed**,
and the four red rows are exactly the four that assert the *shipped* tracking (the lag pair, the
shot-along-facing bearing, the tolerance cone, and the constant's own value) — **every other
suite in the gate stays green**, so instant aim reproduces the pre-S5 behaviour exactly.
Restored to `1.0`: 577/0.

## What shipped, file by file (all inside the J4 set)

| File | Change |
|---|---|
| `game/ship_fit.gd` | `HARDPOINTS` (the measured table); `hardpoints` / `is_mapped` / `thruster_points` / `weapon_mounts` / `weapon_mount`; `mount_offset`'s docstring now names itself the fallback |
| `game/player_ship.gd` | `thruster_anchors(mode)` resolves the map at the sprite's own scale, `_derived_anchors()` is the kept fallback, `thruster_frame()` (anchors + flags), `weapon_mount(i)`, `_hull_sprite_scale()`, and the frame passes the raw throttle and strafe |
| `game/projectile.gd` | `sync_thruster_trails(..., flags)` — an optional per-anchor fire list; an empty list is the pre-S5 shape |
| `game/weapons.gd` | `track_dps` in the family table plus `MODULE_TRACK_DPS[&"w_mining"]`, `TRACK_MULT`, `TRACK_TOLERANCE`, `track_dps_of`, the per-barrel `_facing` / `_base_facing` / `_mounts`, `_track_barrels`, `barrel_aim_angle`, `muzzle_position` / `muzzle_direction`, `_beam_aligned`, `barrel_facing` / `barrel_facings`, the shot spawn at the mount along the facing, and the beam's lead-barrel muzzle with its cone gate |
| `tests/probe_s5_hardpoints.gd` | **new**: the measurement probe (the table's only writer) |
| `tests/test_s5_hardpoints.gd` | **new**: AC5/AC6, eleven rows |
| `tests/test_p2a_launch_fit.gd` | one row re-pointed (below) |

`game/mining_laser.gd` is in the J4 file set and is **unchanged**: the mining shaft is
cursor-aimed (`mining_laser.gd` reads the cursor and its own 220 u range; it is not fired through
`WeaponComponent`), so the only map value that could apply is a mount *position* for the shaft's
origin — that needs a cell-ref for the `w_mining` cell, which J3's rack record carries but the
laser node does not. `w_mining`'s `track_dps` 150 ships as data (`MODULE_TRACK_DPS`) and is
documented in 09 section 3.1.

## Tests that move

- **`test_p2a_launch_fit.gd`** — `test_the_thruster_anchors_are_one_per_engine_cell` becomes
  `test_the_thruster_anchors_come_from_the_hulls_measured_map`: the Mule's anchors are its
  render's two measured nozzle mouths, asserted equal to
  `ShipFit.HARDPOINTS[&"ship_freighter"].thrusters.rear` times the sprite's scale, with an
  explicit assertion that the count is **not** the grid's E count (the doc's supersession, named
  inline), and the NPC-hull fallback assertions kept unchanged. **This is a move outside the wave
  brief's declared "tests that move" list, and I flag it as a bucket-2 disclosure:** the row
  asserted the exact rule 09 section 11 supersedes, so under the pin it *must* read the map;
  leaving it red would have made the wave's own gate fail. Its subject is unchanged (the anchor
  seam), and the assertions it lost are the superseded rule itself.
- New: `tests/test_s5_hardpoints.gd` (+11 rows), `tests/probe_s5_hardpoints.gd`.
- No other suite moved. `test_slice2_5_feel.gd`'s one-anchor and active-rule rows pass unchanged
  (its hull carries no map, so it exercises the fallback path verbatim).

## Docs amended (the deliverable the brief names)

- `docs/gameplay/09_ship_slots_modules.md` **section 11**: the placeholder row replaced by the
  nine measured rows plus the units/method paragraph (render px relative to the sprite centre, the
  probe as the derivation, the counts being the art's own).
- `docs/gameplay/09_ship_slots_modules.md` **section 3.1**: the `track_dps` column added to the
  WEAPONS table (180 / 120 / 60 / fixed / 75 / 100) with the reversal and the `w_mining` 150 note.
  No other docs text touched; `18_engine_spec.md` and `08_ship_slots_modules.md` are untouched.

## Reported, not changed (bucket 2 / 3)

1. **Bucket 3 (taste) — the art and the grid disagree on nozzle counts.** The Mule's render shows
   two lit nozzles while the grid grants three E cells; the Gunship and the Destroyer disagree the
   other way (three and four nozzles against two and three cells). The map records the art, which
   is what the pin asks for; whether the *art* should gain a nozzle or the *grid* should lose a cell
   is an owner/art call. The measured arrays are the source of the mismatch and can be re-derived at
   any time from the probe.
2. **Bucket 3 (taste) — the `track_dps` table is the pin's proposed set** (laser 180, mining 150,
   cannon 120, railgun 100, plasma 75, rocket 60, mine fixed). Shipped as proposed; the owner tick
   is still owed, and the one constant that retunes all of it is `WeaponScript.TRACK_MULT`
   (0 = instant aim).
3. **Bucket 2 (docs / pin) — the test move above.**
4. **Low, deferred — the mining shaft's origin.** Wiring `mining_laser.gd`'s shaft to the
   `w_mining` cell's measured mount needs that module's cell-ref (J3's records carry it); today it
   stays at the hull's origin, as it was.
5. **Low, reported — a weapon mount beyond the map.** All 29 W cells of the nine hulls are mapped,
   so the per-cell fallback (`Vector2.ZERO`, the pre-S5 muzzle) is unreachable in the shipped tree;
   it exists for a hull the probe cannot measure.
6. **Low, pre-existing, worth knowing next to this map — the flying hull's sprite is one texture.**
   `player_ship.tscn` draws `ship_vanguard_side.png` for every hull (measured: its `Hull` node has
   one `ExtResource` texture), so the px-to-units factor this wave reads is that one sprite's scene
   scale for all nine maps. The measured px are each hull's **own** render, which is what the pin
   asks for; a per-hull sprite swap (plus a per-hull collider radius) is the follow-up that would
   make the drawn hull and its map the same art. Named here so the scale's provenance is not read as
   an accident.

## Gate and hygiene

- Two scratch stores, identical counts (577/0), plus a 600-frame `game.tscn` smoke run with zero
  script errors; the live profile's md5 is identical before and after every run.
- The probe writes nothing and needs no profile (the scratch store is arm's-length hygiene); it
  quits after printing, and its work is bounded (nine renders).
- No background jobs; every command bounded; no shell file edits; this file and the two suites are
  the only new artifacts.

## Owner ticks owed after this wave (J4's share)

1. The `track_dps` taste table (09 section 3.1) — one value per family, shipped as proposed.
2. **Fire-along-facing (built) vs hold-fire-until-aligned** (the pin's alternative, CONTRACTS 17).
3. The Mule / Gunship / Destroyer art-vs-grid nozzle counts (finding 1 above).
