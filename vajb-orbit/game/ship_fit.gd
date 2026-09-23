class_name ShipFit
extends RefCounted
## Hull + fit -> `ShipStats`, in the 09 section 5 resolution order.
## Sources, one each: 08 section 2 (hull base: structure, shield, cargo, hardpoints,
## power out), ENGINE_SPEC section 13 (per-class handling column, speed scale,
## tractor values), 09 section 3 (module effects and power draws), 09 section 7
## (`STANDARD_FIT`), ENGINE_SPEC section 4.2 / 09 section 3.2 (base shield regen),
## ENGINE_SPEC section 4.1 (lock range = the scanner's range).
## Reduced form (ENGINE_SPEC section 9): v1 resolves the 09 section 7 standard fit;
## the fitting UI and full catalogue are P2 — the `resolve` interface does not change.
## Data, not logic: no nodes, no autoload, no catalogue reads outside these tables.
##
## **Slot frames (2026-09-21, CONTRACTS section 11 = 08 section 3).** `SLOT_GRIDS`
## is 08 section 3.2's hull-plan matrix per hull with its cosmetic spaces removed,
## and every per-type count (`grid_counts`, `slot_capacity`, `HULLS[hull].weapons`)
## is derived from it, so a count and a layout cannot disagree. The engine is a set,
## not a slot: `engines` is an array with one entry per E cell, all of them
## mandatory (09 section 4.1), and `resolve` applies the set's summed deltas once
## and clamps the summed speed multiplier to `ENGINE_MULT_CEILING` (09 section 3.7).
## The module catalogue moved to `game/module_catalog.gd`; the `MODULES` const below
## is its alias, so `ShipFit.MODULES[id][&"effects"]` still indexes one literal.
##
## Interpretation the docs leave open (all reported in the W1 report):
## * Plating multiplies the handling *times* (accel, coast, turn spin-up) by
##   1 + |speed penalty| (ENGINE_SPEC section 3.2); `turn_rate` is a rate, so it
##   moves only with the engine's `turn_mult`.
## * Pools clamp at 3x their own hull base (09 section 5 step 4).
## * Regen is base + the best single shield module value ("best value", 09 section 5).
## * The booster-on-activation speed multiplier is not baked into the snapshot
##   (it depends on whether the booster is firing); `boosters` carries the ids.
## * `hull_mass` is the ENGINE_SPEC section 13 class column (which gains the
##   mass row v2 of that table describes) times any plating `mass_add`; the two
##   power pools are the section 13 flat base (100 / 200 / 5 per second), not a
##   class column.

const MAX_SPEED_SCALE := 450.0
const SPEED_FLOOR_RATIO := 0.4
const POOL_CEILING_MULT := 3.0
const BASE_SHIELD_REGEN := 2.0
const BASE_SCAN_RANGE := 900.0
const BASE_TRACTOR_RANGE := 120.0
const BASE_TRACTOR_SPEED := 90.0
const BASE_TRACTOR_STREAMS := 1

## ENGINE_SPEC section 13 "Energy & fuel (rulings 10-14)", verbatim: the two pools
## are a flat base, not a class column -- `energy_max` 100 / `fuel_max` 200 with
## `energy_regen` 5/s (the doc's `recharge_rate`). Modules move them in a later
## pass (09 section 3), which is why they are resolved here rather than read off a
## hull row. `POOL_CEILING_MULT` (09 section 5 step 4) applies to each pool against
## its own base, exactly as it does for hull and shield.
const BASE_ENERGY_MAX := 100.0
const BASE_FUEL_MAX := 200.0
const BASE_ENERGY_REGEN := 5.0

## The pre-amendment pair. `LIST_SLOT_KEYS` is still `fitted_ids`' list order;
## `SINGLE_SLOT_KEYS` is superseded -- the engine is a set now, so `fitted_ids`
## reads `engines` itself and takes `power` after it (rule 3 of CONTRACTS section
## 11). It stays published for the pre-wave surface; nothing in this file reads it.
const SINGLE_SLOT_KEYS: Array[StringName] = [&"engine", &"power"]
const LIST_SLOT_KEYS: Array[StringName] = [
	&"weapons",
	&"shields",
	&"armour",
	&"computers",
	&"boosters",
	&"utility",
]

## 08 section 3.2's nine hull-plan matrices: one row per line, the cosmetic spaces
## of the document's block removed (the Cutter's rows are `.WW.`, `HSCB`, `HWU.`,
## `.EP.`). A letter is 09 section 1's slot type, `.` is a gap -- the hull's own
## silhouette, not a slot. Rows are equal length per hull. The nine keys are the
## player hulls `HULLS` carries; an NPC hull has no grid (rule 6 below).
## `tests/test_ship_grids.gd` parses that fenced block out of
## `docs/gameplay/08_ship_classes.md` and compares it with this table hull by hull
## and row by row, so the document and the data cannot drift apart.
const SLOT_GRIDS: Dictionary = {
	&"ship_fighter": [".WW.", "HSCB", ".EP."],
	&"ship_vanguard": [".WW.", "HSCB", "HWU.", ".EP."],
	&"ship_miner": ["W..W", "CHHS", "UUU.", "EEP."],
	&"ship_trader": [".W..", "SCCH", "HUUU", "EEBP"],
	&"ship_corvette": [".WW.", "HSSH", "WCBW", ".EPU"],
	&"ship_freighter": [".W..", "HHHS", "UUUU", "CU..", "EEEP"],
	&"ship_gunship": ["WWWW", ".SS.", "HCH.", "WU..", "EEP."],
	&"ship_patrol": [".WW.", "HSSH", "CWWC", "HBUU", ".EEP"],
	&"ship_destroyer": [".WWW.", "HSSSH", "CWCW.", "H.BH.", "WWUU.", "EEEP."],
}

## 08 section 3.2's letters to 09 section 1's slot-type keys. `.` is a gap.
const SLOT_TOKEN_KEYS: Dictionary = {
	"E": &"engines",
	"P": &"power",
	"W": &"weapons",
	"S": &"shields",
	"H": &"armour",
	"C": &"computers",
	"B": &"boosters",
	"U": &"utility",
}

## The fitting order: every count, capacity and display walks these eight keys, so
## the panel and the HUD agree without restating a list. `fitted_ids` keeps its own
## resolution order instead (weapons first) -- rule 3 of CONTRACTS section 11.
const FIT_SLOT_KEYS: Array[StringName] = [
	&"engines",
	&"weapons",
	&"shields",
	&"armour",
	&"computers",
	&"boosters",
	&"utility",
	&"power",
]

## 09 section 4.1: a fit without every ENGINE cell filled (08 section 3.1) and
## exactly one POWER module cannot launch.
const MANDATORY_SLOT_KEYS: Array[StringName] = [&"engines", &"power"]

## 09 section 3.7: the summed speed multiplier's ceiling. The best legal set on a
## three-cell hull (`e_std` + `e_ion` + `e_vector`) is exactly 1.40.
const ENGINE_MULT_CEILING := 1.40

## 09 section 8: the fraction of the hull's half-extents the layout grid covers.
## One pair for all nine hulls; `mount_offset` scales a cell's normalised position
## by it, so no per-hull anchor table exists to drift from the matrices.
const MOUNT_SPREAD := Vector2(0.34, 0.22)

## Per-hull hardpoints (09 section 11, wave S5, CONTRACTS section 17) -- the measured map
## that supersedes 09 section 8's no-table rule. Generated, never hand-edited: the values
## are the output of `tests/probe_s5_hardpoints.gd`, which measures each hull's own side
## render (`res://assets/ships/ship_<stem>_side.png`, the bow-right view the world draws
## for a hull) and prints this literal; the probe's header states the method in full and
## 09 section 11's table records the same rows with their provenance.
##
##   XDG_DATA_HOME=/tmp/s5j4_scratch/xdg $GODOT_CONSOLE --headless --path vajb-orbit \
##     --script res://tests/probe_s5_hardpoints.gd
##
## Units: **render px relative to the sprite's own centre** (the point the scene's `Hull`
## sprite draws at; x right = bow, y down = the hull's starboard, matching Godot's own 2D
## axes), so a consumer scales by the sprite's own scene scale (`player_ship.tscn` draws
## it at 0.0663, the figure `asteroid.gd` cites for the same art). A hull the probe cannot
## measure has no row here, and `hardpoints` answers `{}` for it -- that hull falls back to
## 09 section 8's derivation (the reversal named in section 11).
##
## `thrusters` are the flight-FX anchors: `rear` is the lit nozzle mouths (thrust),
## `front` the bow band's two ink extremes (brake/retro), `left`/`right` the flank
## stations at 25 % and 75 % of the hull's length (strafe). `weapon_mounts` is one entry
## per W cell in the hull's own row-major cell order (09 section 4 item 5), so W cell `i`
## binds `weapon_mounts[i]`; `pos` is where the shot leaves from and `facing` the barrel's
## rest direction in radians relative to the hull's axis, which tracking sweeps from.
const HARDPOINTS: Dictionary = {
	&"ship_fighter": {
		&"thrusters": {
			&"rear": [Vector2(-391.5, -71.2), Vector2(-392.5, 37.3)],
			&"front": [Vector2(414.5, -38.5), Vector2(414.5, 14.5)],
			&"left": [Vector2(-207.5, -174.5), Vector2(207.5, -108.5)],
			&"right": [Vector2(-207.5, 92.5), Vector2(207.5, 73.5)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-103.5, -116.5), &"facing": 0.100},
			{&"pos": Vector2(103.5, -116.5), &"facing": 0.149},
		],
	},
	&"ship_vanguard": {
		&"thrusters": {
			&"rear": [Vector2(-371.0, -111.4), Vector2(-369.0, 118.3)],
			&"front": [Vector2(443.0, -31.5), Vector2(443.0, 22.5)],
			&"left": [Vector2(-222.0, -189.5), Vector2(222.0, -95.5)],
			&"right": [Vector2(-222.0, 197.5), Vector2(222.0, 137.5)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-111.0, -168.5), &"facing": -0.124},
			{&"pos": Vector2(111.0, -168.5), &"facing": -0.503},
			{&"pos": Vector2(-111.0, 55.5), &"facing": -0.173},
		],
	},
	&"ship_miner": {
		&"thrusters": {
			&"rear": [Vector2(-439.5, -75.3), Vector2(-440.5, 63.7)],
			&"front": [Vector2(453.5, -32.5), Vector2(453.5, 102.5)],
			&"left": [Vector2(-227.5, -99.5), Vector2(227.5, -64.5)],
			&"right": [Vector2(-227.5, 131.5), Vector2(227.5, 127.5)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-340.5, -106.2), &"facing": -0.100},
			{&"pos": Vector2(340.5, -47.5), &"facing": 0.149},
		],
	},
	&"ship_trader": {
		&"thrusters": {
			&"rear": [Vector2(-428.0, -72.1), Vector2(-428.0, 71.1)],
			&"front": [Vector2(472.0, -57.5), Vector2(472.0, 49.5)],
			&"left": [Vector2(-236.0, -147.5), Vector2(237.0, -129.5)],
			&"right": [Vector2(-236.0, 148.5), Vector2(237.0, 132.5)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-118.0, -117.5), &"facing": -0.025},
		],
	},
	&"ship_corvette": {
		&"thrusters": {
			&"rear": [Vector2(-456.0, -27.3), Vector2(-457.0, 30.7)],
			&"front": [Vector2(480.0, -18.0), Vector2(480.0, 17.0)],
			&"left": [Vector2(-240.0, -85.0), Vector2(241.0, -54.0)],
			&"right": [Vector2(-240.0, 83.0), Vector2(241.0, 56.0)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-120.0, -63.9), &"facing": 0.359},
			{&"pos": Vector2(120.0, -63.9), &"facing": -0.291},
			{&"pos": Vector2(-361.0, 20.6), &"facing": 0.173},
			{&"pos": Vector2(361.0, 43.5), &"facing": 0.221},
		],
	},
	&"ship_freighter": {
		&"thrusters": {
			&"rear": [Vector2(-434.0, -71.1), Vector2(-435.0, 41.3)],
			&"front": [Vector2(454.0, -57.0), Vector2(454.0, 44.0)],
			&"left": [Vector2(-227.0, -134.0), Vector2(228.0, -120.0)],
			&"right": [Vector2(-227.0, 133.0), Vector2(228.0, 117.0)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-114.0, -108.1), &"facing": 0.075},
		],
	},
	&"ship_gunship": {
		&"thrusters": {
			&"rear": [Vector2(-394.5, -163.8), Vector2(-398.5, -125.9), Vector2(-371.5, 83.0)],
			&"front": [Vector2(454.5, -53.0), Vector2(454.5, 39.0)],
			&"left": [Vector2(-227.5, -267.0), Vector2(227.5, -272.0)],
			&"right": [Vector2(-227.5, 265.0), Vector2(227.5, 268.0)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-341.5, -199.0), &"facing": -0.100},
			{&"pos": Vector2(-113.5, -228.9), &"facing": 0.025},
			{&"pos": Vector2(113.5, -228.9), &"facing": 0.025},
			{&"pos": Vector2(341.5, -81.0), &"facing": 0.337},
			{&"pos": Vector2(-341.5, 113.7), &"facing": 0.100},
		],
	},
	&"ship_patrol": {
		&"thrusters": {
			&"rear": [Vector2(-398.5, -24.8), Vector2(-400.5, 76.0)],
			&"front": [Vector2(465.5, 28.0), Vector2(465.5, 46.0)],
			&"left": [Vector2(-233.5, -56.0), Vector2(233.5, -12.0)],
			&"right": [Vector2(-233.5, 141.0), Vector2(233.5, 94.0)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-116.5, -124.1), &"facing": 0.000},
			{&"pos": Vector2(116.5, -27.0), &"facing": 0.197},
			{&"pos": Vector2(-116.5, -0.5), &"facing": 0.000},
			{&"pos": Vector2(116.5, -0.5), &"facing": 0.197},
		],
	},
	&"ship_destroyer": {
		&"thrusters": {
			&"rear": [Vector2(-425.0, -85.8), Vector2(-445.0, -52.7), Vector2(-416.0, 52.7), Vector2(-425.0, 83.3)],
			&"front": [Vector2(474.0, -30.5), Vector2(474.0, 19.5)],
			&"left": [Vector2(-237.0, -113.5), Vector2(238.0, -74.5)],
			&"right": [Vector2(-237.0, 117.5), Vector2(238.0, 54.5)],
		},
		&"weapon_mounts": [
			{&"pos": Vector2(-190.0, -113.5), &"facing": -0.075},
			{&"pos": Vector2(0.0, -98.5), &"facing": 0.268},
			{&"pos": Vector2(190.0, -82.5), &"facing": -0.443},
			{&"pos": Vector2(-190.0, -23.2), &"facing": -0.075},
			{&"pos": Vector2(190.0, -23.2), &"facing": -0.443},
			{&"pos": Vector2(-380.0, 67.5), &"facing": 0.245},
			{&"pos": Vector2(-190.0, 67.5), &"facing": 0.000},
		],
	},
}

## 09 section 4 item 4: a repeated module id is refused for the types whose effects
## stack from the same module. `e_std` is the one exception 09 section 3.7 names by
## hand (`e_std` + `e_std` is legal: both are the reference engine).
const DUPLICATE_GUARD_KEYS: Array[StringName] = [&"engines", &"computers"]
const REFERENCE_ENGINE_ID: StringName = &"e_std"

## 08 section 2's hull rows, one per class. `weapons` is that table's Weapons
## column, which 08 section 3 derives from the hull's 08 section 3.2 matrix: it
## equals `grid_counts(hull)[&"weapons"]` (and so `slot_capacity(hull, &"weapons")`)
## for all nine hulls, because the HUD, the shipyard strip and `hardpoints` all
## read it. The three rows the 2026-09-21 amendment moved are marked in 08 section 3.
const HULLS: Dictionary = {
	&"ship_fighter": {
		&"name": "Lancer",
		&"ship_class": "Fighter",
		&"hull": 700.0,
		&"shield": 400.0,
		&"cargo": 25,
		&"weapons": 2,
		&"power_out": 6,
	},
	&"ship_vanguard": {
		&"name": "Vanguard",
		&"ship_class": "Cutter",
		&"hull": 1000.0,
		&"shield": 600.0,
		&"cargo": 40,
		&"weapons": 3,
		&"power_out": 8,
	},
	&"ship_miner": {
		&"name": "Delver",
		&"ship_class": "Miner",
		&"hull": 1100.0,
		&"shield": 500.0,
		&"cargo": 55,
		&"weapons": 2,
		&"power_out": 10,
	},
	&"ship_trader": {
		&"name": "Courier",
		&"ship_class": "Trader",
		&"hull": 950.0,
		&"shield": 550.0,
		&"cargo": 60,
		&"weapons": 1,
		&"power_out": 8,
	},
	&"ship_corvette": {
		&"name": "Spearhead",
		&"ship_class": "Corvette",
		&"hull": 1300.0,
		&"shield": 700.0,
		&"cargo": 35,
		&"weapons": 4,
		&"power_out": 9,
	},
	&"ship_freighter": {
		&"name": "Mule",
		&"ship_class": "Hauler",
		&"hull": 1600.0,
		&"shield": 500.0,
		&"cargo": 120,
		&"weapons": 1,
		&"power_out": 9,
	},
	&"ship_gunship": {
		&"name": "Bulwark",
		&"ship_class": "Gunship",
		&"hull": 1400.0,
		&"shield": 650.0,
		&"cargo": 50,
		&"weapons": 5,
		&"power_out": 11,
	},
	&"ship_patrol": {
		&"name": "Warden",
		&"ship_class": "Frigate",
		&"hull": 1800.0,
		&"shield": 800.0,
		&"cargo": 60,
		&"weapons": 4,
		&"power_out": 12,
	},
	&"ship_destroyer": {
		&"name": "Obliterator",
		&"ship_class": "Destroyer",
		&"hull": 2200.0,
		&"shield": 900.0,
		&"cargo": 80,
		&"weapons": 7,
		&"power_out": 15,
	},
}

## ENGINE_SPEC section 13 handling column; max speed is 08 section 2's base-speed
## percentage x `MAX_SPEED_SCALE`.
##
## **The `coast_time` column was retuned (owner ruling, 2026-09-21): all nine rows are
## scaled x 0.50.** The owner's "weird drag - I release and it still goes forward for a
## second" is this column: `coast_time` is the only free number in the release path, and
## it sets both the release brake (`max_speed / coast_time`) and the body's damp
## (`1 / coast_time`), so halving it halves the carry and the lateral settle together and
## leaves every other section 13 row where it was. Measured by the C3 flight-decay probe
## on the shipped launch (the launch fit's `h_plate_light` multiplies the row by 1.05, so
## the Vanguard's resolved coast time is 1.05 s): time to 10 % of the release speed
## 1.890 s -> 0.945 s, carried distance 430.32 u -> 216.85 u, and the two accelerate legs
## are unchanged. **The rows below still carry that x 0.50, and `COAST_TIME_MULT` below is
## the reverse of it** (owner ruling 2026-09-22: "ship loses speed way too fast" - x 2.0
## lands the resolved column back on section 13's own); the older reversal sentence
## (multiply the nine rows by 2.0) is superseded by the constant, so the revert is one
## number and not a nine-row edit. No other file reads this column by hand.
##
## **The `turn_rate` column is retuned (owner ruling, 2026-09-21, third round): all
## nine rows are scaled x 0.50.** "i dont like how fast ship turn" is this column,
## and the ruling makes it the only handling number of the flight-feel wave (the
## wave's other two behaviours, the cursor steering and the strafe, derive from these
## rows and invent no number of their own): the Vanguard's 3.0 rad/s - 172 deg/s - is
## 1.5 rad/s - 86 deg/s. `turn_spinup` and every other column are untouched, so the
## nose still spins up to the rate over its class spin-up and the autopilot and the
## cursor steering both reach their bearing at half the old rate. Nothing else reads
## this column by hand: it reaches every hull through `ShipStats`, so the nine NPC
## hulls turn at the retuned rate for the same reason the retuned `coast_time` halves
## every NPC's carry. **Reversal: multiply the nine rows below by 2.0 and re-run
## `tests/probe_g1_flight_feel.tscn`;** the turn curve's before/after table is in
## `.agents/gen/flight_beam_g1_report.md`.
const HANDLING: Dictionary = {
	&"ship_fighter": {
		&"max_speed": 450.0,
		&"accel_time": 2.0,
		&"coast_time": 0.8,
		&"turn_rate": 1.7,
		&"turn_spinup": 0.4,
		&"hull_mass": 80.0,
	},
	&"ship_vanguard": {
		&"max_speed": 428.0,
		&"accel_time": 2.4,
		&"coast_time": 1.0,
		&"turn_rate": 1.5,
		&"turn_spinup": 0.5,
		&"hull_mass": 110.0,
	},
	&"ship_miner": {
		&"max_speed": 338.0,
		&"accel_time": 4.0,
		&"coast_time": 1.7,
		&"turn_rate": 1.0,
		&"turn_spinup": 1.0,
		&"hull_mass": 140.0,
	},
	&"ship_trader": {
		&"max_speed": 383.0,
		&"accel_time": 3.0,
		&"coast_time": 1.3,
		&"turn_rate": 1.2,
		&"turn_spinup": 0.7,
		&"hull_mass": 160.0,
	},
	&"ship_corvette": {
		&"max_speed": 495.0,
		&"accel_time": 2.2,
		&"coast_time": 0.9,
		&"turn_rate": 1.6,
		&"turn_spinup": 0.45,
		&"hull_mass": 90.0,
	},
	&"ship_freighter": {
		&"max_speed": 293.0,
		&"accel_time": 6.0,
		&"coast_time": 2.6,
		&"turn_rate": 0.75,
		&"turn_spinup": 1.4,
		&"hull_mass": 260.0,
	},
	&"ship_gunship": {
		&"max_speed": 360.0,
		&"accel_time": 4.4,
		&"coast_time": 1.9,
		&"turn_rate": 0.95,
		&"turn_spinup": 1.0,
		&"hull_mass": 190.0,
	},
	&"ship_patrol": {
		&"max_speed": 383.0,
		&"accel_time": 4.0,
		&"coast_time": 1.7,
		&"turn_rate": 1.05,
		&"turn_spinup": 0.9,
		&"hull_mass": 220.0,
	},
	&"ship_destroyer": {
		&"max_speed": 315.0,
		&"accel_time": 6.4,
		&"coast_time": 2.8,
		&"turn_rate": 0.8,
		&"turn_spinup": 1.2,
		&"hull_mass": 300.0,
	},
}

## CONTRACTS section 14 (owner rulings 2026-09-22): the HANDLING derivation gains the
## multiplier pattern. The rows above stay the shipped literals -- the table the module
## costs were balanced against -- and these three constants are what `resolve()` applies to
## them, so each ruling is one number to flip rather than a nine-row edit.
##
## - `ACCEL_TIME_MULT` **2.0** on `accel_time`: a hull takes about twice as long to reach
##   its top speed. The owner: "the acceleration is too fast for ship, it shouldn't reach
##   top speed that quickly". Measured by `tests/probe_s2_6_flight.tscn` on the launched
##   Vanguard: t_90 2.283 -> 4.567 s, the accelerate leg doubling per class and every hull's
##   ceiling unmoved (`max_speed` never moves). **Reversal: 1.0.**
## - `COAST_TIME_MULT` **2.0** on **today's** `coast_time` rows, which is exactly section
##   13's own column: the documented revert of the combat wave's x 0.50 drag retune. The
##   owner: "ship loses speed way too fast". Measured on the same launch: time to 10 % of
##   the release speed 0.945 -> 1.890 s, carried distance 214.59 -> ~429 u. It reaches every
##   NPC hull through `ShipStats` (NPCs carry further, as they did before the retune).
##   **Reversal: 1.0.**
## - `LATERAL_DAMP_MULT` **1.0** of today: the sideways decay keeps today's time constant
##   while the forward carry grows, because in this model the lateral damp *is* the outward
##   skid in a turn (the owner: "inertia works weird, like ship slides in one side").
##   `PlayerShip._lateral_damp` reads it and turns it into the explicit lateral drag; 0.0
##   removes that drag, so the sideways decay rides the forward revert instead. **Reversal:
##   0.0.** (The resolved snapshot's `coast_time` is the *forward* one, so this constant is
##   read from `player_ship.gd` rather than through `ShipStats` -- section 2's field list is
##   frozen and carries no lateral field.)
const ACCEL_TIME_MULT := 2.0
const COAST_TIME_MULT := 2.0
const LATERAL_DAMP_MULT := 1.0

## 09 section 3's module catalogue lives in `game/module_catalog.gd` -- the one
## literal, carrying `name`, `tier`, `cost` and `icon` alongside the `slot`,
## `draw` and `effects` a `ShipStats` snapshot needs. This const is its alias,
## so every caller and test that indexes `ShipFit.MODULES[id][&"effects"]`
## keeps working and only one literal exists (CONTRACTS section 11).
const MODULES: Dictionary = ModuleCatalog.MODULES

## 09 section 9: one fit per hull, built from 09 section 7 -- the mandatory set
## (one `e_std` per ENGINE cell, one `p_std`, 09 section 4.1) for every hull, plus
## the Lancer's and the Vanguard's full starter fits. It is the fallback a launch
## uses when the profile holds no fit for the active hull (10 section 2.3), and the
## fit the auction delivers with those two hulls. Array keys carry one entry per
## cell of that type in 08 section 3.2's row-major order (09 section 4 item 5);
## a missing key means the hull carries none of that type.
const STANDARD_FITS: Dictionary = {
	&"ship_fighter": {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser", &"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	},
	&"ship_vanguard": {
		&"engines": [&"e_std"],
		&"power": &"p_std",
		&"weapons": [&"w_laser"],
		&"shields": [&"s_light"],
		&"armour": [&"h_plate_light"],
	},
	&"ship_miner": {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
	},
	&"ship_trader": {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
	},
	&"ship_corvette": {
		&"engines": [&"e_std"],
		&"power": &"p_std",
	},
	&"ship_freighter": {
		&"engines": [&"e_std", &"e_std", &"e_std"],
		&"power": &"p_std",
	},
	&"ship_gunship": {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
	},
	&"ship_patrol": {
		&"engines": [&"e_std", &"e_std"],
		&"power": &"p_std",
	},
	&"ship_destroyer": {
		&"engines": [&"e_std", &"e_std", &"e_std"],
		&"power": &"p_std",
	},
}

## 09 section 9: "`STANDARD_FIT` (the Vanguard row) stays as the one alias existing
## callers and tests already use". It is the same dictionary as
## `STANDARD_FITS[&"ship_vanguard"]`, so there is one literal and no drift; a
## one-engine Vanguard fit resolves to exactly the pre-amendment figures (09
## section 3.7 consequence 2).
const STANDARD_FIT: Dictionary = STANDARD_FITS[&"ship_vanguard"]


## Resolve `hull_id` + `fit` into the engine's stats snapshot (09 section 5 order).
## Unknown hulls push an error and return null; an unknown module id pushes a
## warning and is ignored, so a fit referencing a not-yet-implemented module
## still resolves the rest.
static func resolve(hull_id: StringName, fit: Dictionary) -> ShipStats:
	var hull: Dictionary = HULLS.get(hull_id, {})
	var handling: Dictionary = HANDLING.get(hull_id, {})
	if hull.is_empty() or handling.is_empty():
		push_error("ShipFit.resolve: unknown hull id '%s'" % hull_id)
		return null

	var stats := ShipStats.new()
	# 1. Hull base (08 section 2 + ENGINE_SPEC section 13 handling column, which
	# now carries `hull_mass` too). The two times are the row times the ruling
	# multipliers (CONTRACTS section 14: the accelerate leg x 2.0, the release back
	# on section 13's own column), so the literals above stay the shipped table and
	# a reversal is one constant. `max_speed` takes no multiplier and never moves.
	stats.hull_max = float(hull[&"hull"])
	stats.shield_max = float(hull[&"shield"])
	stats.cargo_max = int(hull[&"cargo"])
	stats.max_speed = float(handling[&"max_speed"])
	stats.accel_time = float(handling[&"accel_time"]) * ACCEL_TIME_MULT
	stats.coast_time = float(handling[&"coast_time"]) * COAST_TIME_MULT
	stats.turn_rate = float(handling[&"turn_rate"])
	stats.turn_spinup = float(handling[&"turn_spinup"])
	stats.hull_mass = float(handling[&"hull_mass"])
	stats.shield_regen = BASE_SHIELD_REGEN
	stats.damage_mult = 1.0
	stats.scan_range = BASE_SCAN_RANGE
	stats.tractor_range = BASE_TRACTOR_RANGE
	stats.tractor_speed = BASE_TRACTOR_SPEED
	stats.tractor_streams = BASE_TRACTOR_STREAMS
	stats.energy_max = BASE_ENERGY_MAX
	stats.energy_regen = BASE_ENERGY_REGEN
	stats.fuel_max = BASE_FUEL_MAX

	var ids := fitted_ids(fit)
	_warn_unknown(ids)
	_apply_flat(stats, ids)
	_apply_speed(stats, ids)
	_apply_computers(stats, ids)
	_apply_shields(stats, ids)
	_apply_utility(stats, ids)
	_apply_boosters(stats, ids)
	_clamp(stats, hull, handling)
	stats.lock_range = stats.scan_range
	return stats


## Module ids of a fit in resolution order: the list slots in `LIST_SLOT_KEYS`
## order (weapons first -- rule 3 of CONTRACTS section 11, so the weapon group's own
## order does not move), then the engine set, then power. Accepts StringName or
## String keys and StringName or String values, so a fit loaded from JSON resolves
## unchanged. The engine key is read as the set's `engines` array (09 section 4 item
## 5) and tolerates the legacy singular `engine` -- one id or an `Array` -- so the
## pre-amendment `STANDARD_FIT` shape and every existing fixture still resolve;
## when both keys are present, `engines` wins.
static func fitted_ids(fit: Dictionary) -> Array[StringName]:
	var ids: Array[StringName] = []
	for key: StringName in LIST_SLOT_KEYS:
		ids.append_array(_list_slot(fit, key))
	ids.append_array(_engine_slot(fit))
	var power := _single_slot(fit, &"power")
	if power != &"":
		ids.append(power)
	return ids


## 09 section 2 budget: sum of non-ENGINE draws against the hull's 08 section 2
## power out plus the fitted power module. The fitting panel (P2-B) owns the UI and
## the illegal-fit refusal; `fit_legal` wraps this arithmetic with the mandatory-set
## and duplicate rules, and this stays the bare arithmetic callers already use.
static func power_budget(hull_id: StringName, fit: Dictionary) -> Dictionary:
	var hull: Dictionary = HULLS.get(hull_id, {})
	if hull.is_empty():
		push_error("ShipFit.power_budget: unknown hull id '%s'" % hull_id)
		return {&"out": 0, &"draw": 0, &"spare": 0, &"legal": false}
	return _power_arithmetic(hull, fit)


static func _power_arithmetic(hull: Dictionary, fit: Dictionary) -> Dictionary:
	var out := int(hull[&"power_out"])
	var draw := 0
	var ids := fitted_ids(fit)
	_warn_unknown(ids)
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty():
			continue
		if row[&"slot"] == &"engine":
			continue
		draw += int(row[&"draw"])
		out += int(_effect(row, &"power_add", 0.0))
	return {&"out": out, &"draw": draw, &"spare": out - draw, &"legal": draw <= out}


## 08 section 3.2's rows for this hull, gaps included, top row first. `[]` for a
## hull with no grid (an NPC hull), and never a warning or an error.
static func grid_rows(hull_id: StringName) -> Array:
	var rows: Variant = SLOT_GRIDS.get(hull_id, [])
	if rows is Array:
		return (rows as Array).duplicate()
	return []


## The matrix's (columns, rows). Every row of one hull is the same length (08
## section 3.2). `Vector2i.ZERO` for a hull with no grid.
static func grid_size(hull_id: StringName) -> Vector2i:
	var rows := grid_rows(hull_id)
	if rows.is_empty():
		return Vector2i.ZERO
	return Vector2i(String(rows[0]).length(), rows.size())


## One entry per matrix cell, row-major from the top-left, gaps included:
##   {type: StringName ("" for a gap), token: String, index: int (-1 for a gap),
##    col: int, row: int, gap: bool}
## `index` is 09 section 4 item 5's layout index: the cells of one type are numbered
## row-major within that type, so `engines[0]` is the topmost, leftmost E cell and
## the fit arrays, the layout display and the saved profile all share it. `[]` for a
## hull with no grid.
static func grid_cells(hull_id: StringName) -> Array:
	var cells: Array = []
	var rows := grid_rows(hull_id)
	if rows.is_empty():
		return cells
	var counters: Dictionary = {}
	var row_index := 0
	for row_value: Variant in rows:
		var row := String(row_value)
		for col: int in row.length():
			var token := row.substr(col, 1)
			var slot: StringName = &""
			var index := -1
			if SLOT_TOKEN_KEYS.has(token):
				slot = SLOT_TOKEN_KEYS[token]
				index = int(counters.get(slot, 0))
				counters[slot] = index + 1
			cells.append({
				&"type": slot,
				&"token": token,
				&"index": index,
				&"col": col,
				&"row": row_index,
				&"gap": slot == &"",
			})
		row_index += 1
	return cells


## 08 section 3's derived per-type counts. All eight `FIT_SLOT_KEYS` are present,
## 0 for a type the hull does not carry; a hull with no grid returns the eight keys
## at 0. Every count is read off `SLOT_GRIDS`, never kept beside it, so a count and
## a layout cannot disagree.
static func grid_counts(hull_id: StringName) -> Dictionary:
	var counts: Dictionary = {}
	for key: StringName in FIT_SLOT_KEYS:
		counts[key] = 0
	for cell: Dictionary in grid_cells(hull_id):
		if bool(cell[&"gap"]):
			continue
		var key: StringName = cell[&"type"]
		counts[key] = int(counts.get(key, 0)) + 1
	return counts


## How many cells of `slot_key` this hull carries: its `grid_counts` entry, 0 for a
## type the hull does not have and 0 for any hull with no grid.
static func slot_capacity(hull_id: StringName, slot_key: StringName) -> int:
	var capacity: Variant = grid_counts(hull_id).get(slot_key, 0)
	return int(capacity)


## 09 section 9's fit for this hull, as a fresh copy a caller may edit (the launch
## fallback and the auction both hand it onward). `{}` for a hull with no standard
## fit, which is every hull with no grid and any id that is not a player hull.
static func standard_fit(hull_id: StringName) -> Dictionary:
	var row: Variant = STANDARD_FITS.get(hull_id, {})
	if row is Dictionary:
		return (row as Dictionary).duplicate(true)
	return {}


## Whether a fit may launch on this hull, as data rather than a refusal
## (09 section 4). Return shape, verbatim from CONTRACTS section 11:
##   {legal: bool,
##    overflow: {slot_key: int},        # cells fitted beyond the hull's capacity
##    missing: Array[StringName],       # mandatory keys not fully filled (4.1)
##    duplicates: Array[StringName],    # keys holding a repeated module id (4.4)
##    power: {out, draw, spare, legal}} # 09 section 2's arithmetic
##
## `duplicates` names the offending *slot keys* (`[&"engines"]`, `[&"computers"]`),
## the same currency as `missing`, so a panel can mark the cells it must clear. The
## guard keys and 09 section 3.7's one exception are `DUPLICATE_GUARD_KEYS` and
## `REFERENCE_ENGINE_ID`. A hull with no grid fits nothing and answers
## `legal: false` with no error (rule 6 of CONTRACTS section 11); an unknown module
## id still warns, exactly as `resolve` does.
static func fit_legal(hull_id: StringName, fit: Dictionary) -> Dictionary:
	var counts := grid_counts(hull_id)
	var fitted := _fitted_counts(fit)
	var overflow: Dictionary = {}
	for key: StringName in FIT_SLOT_KEYS:
		var extra := int(fitted.get(key, 0)) - int(counts.get(key, 0))
		if extra > 0:
			overflow[key] = extra
	var missing: Array[StringName] = []
	for key: StringName in MANDATORY_SLOT_KEYS:
		if int(fitted.get(key, 0)) < int(counts.get(key, 0)):
			missing.append(key)
	var duplicates: Array[StringName] = []
	for key: StringName in DUPLICATE_GUARD_KEYS:
		if _has_duplicate(fit, key):
			duplicates.append(key)
	var power := {&"out": 0, &"draw": 0, &"spare": 0, &"legal": false}
	var hull: Dictionary = HULLS.get(hull_id, {})
	if not hull.is_empty():
		power = _power_arithmetic(hull, fit)
	return {
		&"legal": (
			SLOT_GRIDS.has(hull_id)
			and overflow.is_empty()
			and missing.is_empty()
			and duplicates.is_empty()
			and bool(power[&"legal"])
		),
		&"overflow": overflow,
		&"missing": missing,
		&"duplicates": duplicates,
		&"power": power,
	}


## The anchor of cell `index` of `slot_key`, in the hull's own frame:
## `((col + 0.5) / cols - 0.5, (row + 0.5) / rows - 0.5)` scaled by `MOUNT_SPREAD`
## (09 section 8). **Superseded by `HARDPOINTS` (09 section 11, CONTRACTS section 17):
## this derivation is the fallback a hull without a measured map keeps.** A hull with a
## row in `HARDPOINTS` reads its measured anchors instead; an NPC hull (no grid, no row)
## still answers `Vector2.ZERO`. Reversal of the supersession: drop `HARDPOINTS` and
## resume this rule for every hull.
## Consumption in flight is the feel lane's; this is the data and the API only.
static func mount_offset(hull_id: StringName, slot_key: StringName, index: int) -> Vector2:
	if index < 0:
		return Vector2.ZERO
	var size := grid_size(hull_id)
	if size == Vector2i.ZERO:
		return Vector2.ZERO
	for cell: Dictionary in grid_cells(hull_id):
		if bool(cell[&"gap"]) or cell[&"type"] != slot_key:
			continue
		if int(cell[&"index"]) != index:
			continue
		var x := (float(int(cell[&"col"])) + 0.5) / float(size.x) - 0.5
		var y := (float(int(cell[&"row"])) + 0.5) / float(size.y) - 0.5
		return Vector2(x, y) * MOUNT_SPREAD
	return Vector2.ZERO


## This hull's measured hardpoint map (09 section 11), or `{}` for a hull with none --
## an NPC hull, an unknown id, or a player hull the probe could not measure. Read-only:
## the table is data, the probe is the only writer.
static func hardpoints(hull_id: StringName) -> Dictionary:
	var row: Variant = HARDPOINTS.get(hull_id, {})
	if row is Dictionary:
		return row
	return {}


## Whether this hull carries a measured map at all: the one test the fallback turns on.
static func is_mapped(hull_id: StringName) -> bool:
	return HARDPOINTS.has(hull_id)


## The hull-local px anchors of one thruster mode (09 section 11): `&"rear"` (thrust),
## `&"front"` (brake / retro), `&"left"` / `&"right"` (strafe). `[]` for a hull with no
## map or no such row -- the caller then falls back to 09 section 8's derivation.
static func thruster_points(hull_id: StringName, mode: StringName) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var thrusters: Variant = hardpoints(hull_id).get(&"thrusters", {})
	if not thrusters is Dictionary:
		return out
	var row: Variant = (thrusters as Dictionary).get(mode, [])
	if not row is Array:
		return out
	for value: Variant in (row as Array):
		if value is Vector2:
			out.append(value)
	return out


## The hull's measured weapon mounts (09 section 11) as fresh dictionaries, in W-cell
## order: `{pos: Vector2, facing: float}` in hull-local px, `facing` in radians relative
## to the hull's axis. W cell `i` binds entry `i`; `[]` for a hull with no map.
static func weapon_mounts(hull_id: StringName) -> Array:
	var out: Array = []
	var row: Variant = hardpoints(hull_id).get(&"weapon_mounts", [])
	if not row is Array:
		return out
	for value: Variant in (row as Array):
		if value is Dictionary:
			out.append((value as Dictionary).duplicate())
	return out


## One hull's measured mount for W cell `index`, `{}` when the hull has no map or the
## cell has none (the caller then fires from the pre-S5 muzzle, the hull's own origin).
static func weapon_mount(hull_id: StringName, index: int) -> Dictionary:
	if index < 0:
		return {}
	var mounts := weapon_mounts(hull_id)
	if index >= mounts.size():
		return {}
	return mounts[index]


## How many non-empty entries each type of a fit carries, all eight
## `FIT_SLOT_KEYS` present. The engine key is read through `_engine_slot`, so a
## legacy singular `engine` counts as a one-cell set.
static func _fitted_counts(fit: Dictionary) -> Dictionary:
	var counts: Dictionary = {}
	for key: StringName in FIT_SLOT_KEYS:
		if key == &"engines":
			counts[key] = _engine_slot(fit).size()
		elif key == &"power":
			counts[key] = 1 if _single_slot(fit, key) != &"" else 0
		else:
			counts[key] = _list_slot(fit, key).size()
	return counts


## 09 section 4 item 4: a repeated module id is refused for `DUPLICATE_GUARD_KEYS`,
## with 09 section 3.7's one exception -- the reference engine may repeat, because
## a hull that arrives with `e_std` per cell must stay launchable.
static func _has_duplicate(fit: Dictionary, key: StringName) -> bool:
	var ids: Array[StringName] = []
	if key == &"engines":
		ids = _engine_slot(fit)
	else:
		ids = _list_slot(fit, key)
	var seen: Array[StringName] = []
	for id: StringName in ids:
		if id == &"" or (key == &"engines" and id == REFERENCE_ENGINE_ID):
			continue
		if seen.has(id):
			return true
		seen.append(id)
	return false


static func _apply_flat(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 5 step 2: flat module effects (plates, shield pools, cargo units).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty():
			continue
		stats.hull_max += _effect(row, &"hull_add", 0.0)
		stats.shield_max += _effect(row, &"shield_add", 0.0)
		stats.cargo_max += int(_effect(row, &"cargo_add", 0.0))


static func _apply_speed(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 5 step 3 order: armour, then engine. Plating pays twice — its
	# 09 section 3.3 speed cost and the handling-time multiplier of ENGINE_SPEC
	# section 3.2 ("slow *and* ponderous").
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"armour":
			continue
		var penalty := _effect(row, &"speed_penalty", 0.0)
		stats.max_speed *= 1.0 + penalty
		var mass := 1.0 + absf(penalty)
		stats.accel_time *= mass
		stats.coast_time *= mass
		stats.turn_spinup *= mass
		# ENGINE_SPEC section 3.2 "Mass sources: hull class + armour plating": a
		# plating module's own `mass_add` (09 section 3.3, only `h_composite`
		# carries one today) is the collision/inertia mass the class column does
		# not know about. The handling-time multiplier above is the feel; this is
		# the number the collision formula and the rigid body read.
		stats.hull_mass *= 1.0 + _effect(row, &"mass_add", 0.0)
	# 09 section 3.7 as amended 2026-09-21: the engine set's deltas are **summed,
	# never multiplied**, and the summed speed multiplier is clamped to
	# `ENGINE_MULT_CEILING`; the turn multiplier carries no ceiling. Applied once,
	# after armour and before booster-on-activation. A single engine resolves to
	# exactly the figure the old multiplication gave, because `m - 1` is `m` there
	# (`e_vector` alone is 1.25 either way), and a fit with no engine multiplies by
	# 1.0 exactly as the old empty loop did.
	var speed_mult := 1.0
	var turn_mult := 1.0
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"engine":
			continue
		speed_mult += _effect(row, &"speed_mult", 1.0) - 1.0
		turn_mult += _effect(row, &"turn_mult", 1.0) - 1.0
	stats.max_speed *= minf(speed_mult, ENGINE_MULT_CEILING)
	stats.turn_rate *= turn_mult


static func _apply_computers(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.4: damage computers stack additively, scanner range takes the
	# best single value.
	var damage_add := 0.0
	var scanner_add := 0.0
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"computers":
			continue
		damage_add += _effect(row, &"damage_add", 0.0)
		scanner_add = maxf(scanner_add, _effect(row, &"scanner_add", 0.0))
	stats.damage_mult = 1.0 + damage_add
	stats.scan_range *= 1.0 + scanner_add


static func _apply_shields(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.2 + ENGINE_SPEC section 4.2: the 2/s base plus the best single
	# module value.
	var regen_add := 0.0
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"shields":
			continue
		regen_add = maxf(regen_add, _effect(row, &"regen_add", 0.0))
	stats.shield_regen = BASE_SHIELD_REGEN + regen_add


static func _apply_utility(stats: ShipStats, ids: Array[StringName]) -> void:
	# 09 section 3.6 tractor gear (pickup behaviour is the pickup's own contract).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"utility":
			continue
		stats.tractor_range *= _effect(row, &"tractor_range_mult", 1.0)
		stats.tractor_speed *= _effect(row, &"tractor_speed_mult", 1.0)
		stats.tractor_streams += int(_effect(row, &"tractor_streams_add", 0.0))


static func _apply_boosters(stats: ShipStats, ids: Array[StringName]) -> void:
	# Ids only: the activation multiplier is not a static stat (see the file doc).
	for id: StringName in ids:
		var row := _row(id)
		if row.is_empty() or row[&"slot"] != &"boosters":
			continue
		stats.boosters.append(id)


static func _clamp(stats: ShipStats, hull: Dictionary, handling: Dictionary) -> void:
	# 09 section 5 step 4: speed never below 40 % of the hull's base, and no pool
	# above 3x its own base. The slice-0 pools join the rule against their own
	# ENGINE_SPEC section 13 base (nothing moves them yet; a module that does will
	# not be able to exceed the ceiling).
	stats.max_speed = maxf(
		stats.max_speed, float(handling[&"max_speed"]) * SPEED_FLOOR_RATIO
	)
	stats.hull_max = minf(stats.hull_max, float(hull[&"hull"]) * POOL_CEILING_MULT)
	stats.shield_max = minf(
		stats.shield_max, float(hull[&"shield"]) * POOL_CEILING_MULT
	)
	stats.energy_max = minf(stats.energy_max, BASE_ENERGY_MAX * POOL_CEILING_MULT)
	stats.fuel_max = minf(stats.fuel_max, BASE_FUEL_MAX * POOL_CEILING_MULT)


## One module row (09 section 3), read through `game/module_catalog.gd` so the slot
## type, the power draw and the stat effects have exactly one literal.
static func _row(id: StringName) -> Dictionary:
	return ModuleCatalog.module(id)


## One warning per unknown id, not one per resolution pass.
static func _warn_unknown(ids: Array[StringName]) -> void:
	for id: StringName in ids:
		if not ModuleCatalog.MODULES.has(id):
			push_warning("ShipFit: unknown module id '%s' (ignored)" % id)


static func _effect(row: Dictionary, key: StringName, fallback: float) -> float:
	var effects: Dictionary = row.get(&"effects", {})
	return float(effects.get(key, fallback))


static func _list_slot(fit: Dictionary, key: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []
	var raw: Variant = fit.get(key, fit.get(String(key)))
	if raw is Array:
		for entry: Variant in raw as Array:
			var id := StringName(entry)
			if id != &"":
				ids.append(id)
	elif raw is StringName or raw is String:
		if String(raw) != "":
			ids.append(StringName(raw))
	return ids


## The engine set: `engines` when the fit carries that key (even an empty array),
## the legacy singular `engine` otherwise. Both spellings accept an Array or one id.
static func _engine_slot(fit: Dictionary) -> Array[StringName]:
	if _has_slot_key(fit, &"engines"):
		return _list_slot(fit, &"engines")
	return _list_slot(fit, &"engine")


## A fit's key may be spelled String or StringName (a loaded `ConfigFile` gives
## String); both are read.
static func _has_slot_key(fit: Dictionary, key: StringName) -> bool:
	return fit.has(key) or fit.has(String(key))


## A single-valued slot (`power`) as one id. An `Array` is accepted too, taking its
## first non-empty entry, because a caller may hand over a loosened fit (a
## normalised cell array for a one-cell type, or the legacy `engine` spelling grown
## to an array); the pinned one-id spelling is unchanged.
static func _single_slot(fit: Dictionary, key: StringName) -> StringName:
	for spelling: Variant in [key, String(key)]:
		if not fit.has(spelling):
			continue
		var raw: Variant = fit[spelling]
		if raw is Array:
			for entry: Variant in raw as Array:
				if String(entry) != "":
					return StringName(entry)
			return &""
		if raw is StringName or raw is String:
			return StringName(raw)
		return &""
	return &""
