class_name WeaponComponent
extends Node2D
## The player's fitted weapons: the six families of ENGINE_SPEC section 4.1, the
## `fire_primary` trigger, ammo and Energy draw, the lock seam the seeker follows
## and the two countermeasures of section 4.6.
##
## Mounted by `PlayerShip` like the mining laser (a child node at the hull's
## origin) and handed the launch snapshot: `setup(stats, state)` then
## `set_fitted(weapon_ids)`. It reads the trigger itself (`fire_primary`, held) and
## aims at the cursor, so the hull only has to mount it; the HUD's weapon slots
## call `select_group`.
##
## The family table is this file's, transcribed from section 4.1 (family, aim,
## travel, shield rule, DPS) and section 13 (ranges, the cannon's burst cycle, the
## rocket and mine rows, the draw rates); `docs/CONTRACTS.md` sections 2/4/5/8.1 pin
## the seams it spends through (`PlayerState.try_spend_energy`, `set_ammo`,
## `Impact.recoil_impulse` via `PlayerShip.apply_recoil`) and the slice-2 brief's
## pinned interface item 2 pins the API below.
##
## What this file does not own, by the wave's file sets: the damage pipeline
## (`damage.gd`, W2), the lock channel and the reticle (`hud.gd`/the wiring, W5),
## the mining laser's own 5 E/s beam drain (mining_laser.gd is in no slice-2 set -
## reported), and the hit site's own visuals (the impact and death pass).
##
## Fire and travel feedback is this file's: `shot_fired` drives the muzzle flash
## (FX_SPEC section 1.2) and the family's cue (AUDIO_SPEC section 8 through the
## handoff's pools), and the instant families draw FX_SPEC section 1.6's
## engine-drawn shaft. Nothing here reads or writes a balance number.
##
## S4 (CONTRACTS section 16, 09 section 10): a **battery** is the identical weapons
## fitted across W cells, and one trigger pull discharges the whole battery. `fitted()`
## is one entry per barrel with duplicates kept, `battery_ids()` is the distinct id of
## each battery in first-barrel order - what `weapon_1..5` and the HUD's slots address -
## and `battery(base_id)` is one battery's barrel positions in `fitted()`. A pull arms
## the selected battery, its barrels draw a release offset in `[0, BATTERY_STRUM_MS]` ms
## and each released barrel spends its own round, applies its own recoil and emits
## `shot_fired`; a barrel the family refuses is dry and never holds the rest back.

## Raised when a shot actually leaves: one per released projectile (cannon,
## railgun, rocket, mine) and once per beam hold for the instant families, which
## deal their damage per frame rather than per shot.
signal shot_fired(weapon_id: StringName)
## Raised when a trigger pull could not shoot: an empty ammo pack or a short Energy
## pool (section 4.4). Once per pull, never per frame.
signal dry_fired(weapon_id: StringName)
## Section 4.6's chaff breaks the active lock. The lock's owner (W5's channel)
## listens here; this component clears its own lock target at the same moment.
signal locks_broken()
signal countermeasure_used(item_id: StringName)

const PlayerStateScript := preload("res://game/player_state.gd")
const ProjectileScript := preload("res://game/projectile.gd")
const ImpactScript := preload("res://game/impact.gd")
const FxScript := preload("res://game/fx.gd")

## ENGINE_SPEC section 4.1's family table with section 13's calibration rows. One
## row per family, keyed by the weapon id the fit and `PlayerState.WEAPONS` use.
##
## `dps` is the spec's damage-per-second-of-fire; an instant row is applied as
## `dps x delta` each frame while the beam is up (the only reading that makes a
## DPS figure exact without inventing a rate of fire), and a travelling row carries
## `dps x interval` per released shot - see `shot_damage`. `interval` is the spec's
## own for the rocket (1.2 s), the cannon's burst cycle sums to it for the cannon
## (0.35 + 0.25), and the railgun borrows it (reported: section 4.1 gives the
## railgun no cycle and no rate of fire).
##
## `edge` marks the mine, which section 4.1 calls "drop" rather than "held":
## one per trigger pull.
const FAMILIES: Dictionary = {
	&"laser": {
		&"module": &"w_laser",
		&"family": &"energy",
		&"range": 500.0,
		&"dps": 30.0,
		&"draw": 6.0,
		&"instant": true,
		&"bypass_shield": false,
	},
	&"plasma": {
		&"module": &"w_plasma",
		&"family": &"energy",
		&"range": 450.0,
		&"dps": 70.0,
		&"draw": 10.0,
		&"instant": true,
		&"bypass_shield": false,
		&"hull_bonus": 1.25,
	},
	&"cannon": {
		&"module": &"w_cannon",
		&"family": &"kinetic",
		&"kind": &"bolt",
		&"range": 600.0,
		&"dps": 45.0,
		&"speed": 1000.0,
		&"bypass_shield": true,
		&"burst_on": 0.35,
		&"burst_off": 0.25,
	},
	&"railgun": {
		&"module": &"w_railgun",
		&"family": &"kinetic",
		&"kind": &"slug",
		&"range": 800.0,
		&"dps": 60.0,
		&"speed": 1400.0,
		&"bypass_shield": true,
	},
	&"rocket": {
		&"module": &"w_rocket",
		&"family": &"missile",
		&"kind": &"rocket",
		&"range": 900.0,
		&"alpha": 180.0,
		&"speed": 900.0,
		&"turn_rate": 2.2,
		&"interval": 1.2,
		&"homing": true,
		&"bypass_shield": true,
	},
	&"mine": {
		&"module": &"w_mine",
		&"family": &"deployable",
		&"kind": &"mine",
		&"range": 0.0,
		&"alpha": 180.0,
		&"speed": 0.0,
		&"arm": 2.0,
		&"trigger": 60.0,
		&"bypass_shield": true,
		&"edge": true,
	},
}

## 09 section 3.1's note, pinned in CONTRACTS section 3: "the railgun shares the
## cannon pack in v1". `PlayerState.WEAPONS` carries the five v1 ids, so a railgun
## round spends the cannon's slot (reported: the railgun is the sixth family and
## has no slot of its own).
const SHARED_PACK: Dictionary = {&"railgun": &"cannon"}

## Section 4.3 / section 11: `weapon_1..5` selects a group and **Space**
## (`fire_primary`) fires it. Five groups is the input map's count.
const GROUPS_MAX := 5
const FIRE_ACTION: StringName = &"fire_primary"
const MODULE_PREFIX := "w_"

## S4 (09 section 10, CONTRACTS section 16 rule 4): a battery's barrels each draw a
## release offset uniformly in `[0, BATTERY_STRUM_MS]` ms so a volley reads as a salvo
## rather than one louder shot. This ceiling is the whole number; its reversal is 0
## (a perfectly simultaneous volley).
const BATTERY_STRUM_MS := 40

## Section 4.2 item 7's shooter term and section 6's chip rate. The chip rate is
## the spec's own (10 %, ruling 17); `SHOT_MASS` is section 13's missing row
## (reported): no projectile weight exists, so every shot carries one mass unit and
## the recoil term is a one-line tunable.
const SHOT_MASS := 1.0
const GUN_CHIP_RATE := 0.10

## The cadence a kinetic weapon with no burst cycle of its own borrows. Derived,
## not invented: the cannon's burst cycle (0.35 s on + 0.25 s off) is the only
## shot cadence section 13 states. `interval_of` gates it on the row's family, so a
## non-kinetic row that states no cadence (the mine) reads 0.0 instead.
const KINETIC_INTERVAL := 0.6

## Rocks are layer 1 (`Asteroid.COLLISION_LAYER`) and hulls layer 2
## (`player_ship.tscn`'s `HullBody`), which is what a shot may touch.
const ROCK_LAYER_MASK := 1
const HULL_LAYER_MASK := 2
const TARGET_MASK := ROCK_LAYER_MASK | HULL_LAYER_MASK

## Section 4.6 and section 13's "Lock & countermeasures" rows, verbatim.
const CHAFF_ITEM: StringName = &"cm_chaff"
const FLARE_ITEM: StringName = &"cm_flare"
const CHAFF_WINDOW := 3.0
const CHAFF_GHOSTS := 3
const FLARE_LURE := 450.0

## The ghost signatures W5's minimap reads: the node answers
## `blip_kind()` with UI_SPEC section 3.3's `&"ghost"`, which is spelled on the node
## itself because an inner class cannot see this script's constants.
const GHOST_GROUP: StringName = &"ghost_signature"
const GHOST_NODE_NAME: StringName = &"ChaffGhost"
const FLARE_NODE_NAME: StringName = &"CountermeasureFlare"

const PROJECTILE_GROUP: StringName = &"projectile"
const PROJECTILE_NODE_NAME: StringName = &"Projectile"
const PROFILE_SERVICE: StringName = &"PlayerProfile"
const AUDIO_SERVICE: StringName = &"AudioManager"

## --- Fire feedback: what a released shot looks and sounds like -------------
##
## One row per firing family: the cue the family's shot plays, plus the pool tier the
## cannon family fires at. AUDIO_SPEC section 8's S1 is the player's light and medium
## energy weapons (one cue, a four-take round-robin), S2 is the heavy cannon's three
## tiers by length (take 0 the cannon's own, take 1 the heavier railgun's, take 2 the
## long charge-up left to the pool), S3 is the rocket's launch + warhead pair. The
## mine is absent on purpose: section 8 states no deployable cue (reported).
const FIRE_CUES: Dictionary = {
	&"laser": {&"cue": &"sfx_weapon_laser"},
	&"plasma": {&"cue": &"sfx_weapon_laser"},
	&"cannon": {&"cue": &"sfx_weapon_cannon", &"take": 0},
	&"railgun": {&"cue": &"sfx_weapon_cannon", &"take": 1},
	&"rocket": {&"cue": &"sfx_weapon_rocket"},
}

## FX_SPEC section 1.2's muzzle flash: the four pre-cut frames at the spec's own
## 20 FPS (0.2 s, one-shot), the frame's own mouth sitting on the muzzle (the frames
## carry the barrel to the left of it, ~135 px in from the frame's left ink edge) and
## the flash reading about a hull's length.
const FLASH_FRAMES: Array[String] = [
	"res://assets/fx/fx_muzzle_flash_f1.png",
	"res://assets/fx/fx_muzzle_flash_f2.png",
	"res://assets/fx/fx_muzzle_flash_f3.png",
	"res://assets/fx/fx_muzzle_flash_f4.png",
]
const FLASH_FRAME_SIZE := Vector2(535.0, 487.0)
const FLASH_MUZZLE_PX := Vector2(135.0, 243.5)
const FLASH_WORLD := 44.0
const FLASH_FPS := 20.0

## FX_SPEC section 1.2 fixes the flash at "4 frames at 20 FPS = 0.2 s total, one-shot,
## no loop", so a held trigger cannot loop the animation itself: it replays that same
## one-shot - and the family's cue with it - once per this cycle
## (`_advance_fire_feedback`), which is the "they should loop" read the owner gave the
## fire feedback in his third round (2026-09-21). Derived from the row above, not
## invented: `FLASH_FRAMES.size() / FLASH_FPS`, and the suite checks the two agree.
const FLASH_SECONDS := 0.2

## FX_SPEC section 1.6 sanctions the engine-drawn beam ("the beam line itself is
## engine-drawn; no texture needed"), so the instant families draw theirs the way
## `mining_laser.gd` draws the mining shaft: a wide dim halo under a thin bright core.
## The tones come from the generated theme (no hex literals outside
## `tools/build_theme.gd`); a weapon is a danger state, so they are the ember pair.
const BEAM_NAMES: Array[StringName] = [&"Beam", &"BeamCore"]
const BEAM_HALO_WIDTH := 5.0
const BEAM_CORE_WIDTH := 2.0
const BEAM_HALO_ALPHA := 0.45
const BEAM_CORE_ALPHA := 0.95
const BEAM_HALO_TOKEN: StringName = &"accent_danger"
const BEAM_CORE_TOKEN: StringName = &"accent_danger_bright"
const THEME_PATH := "res://ui/theme/vajb_theme.tres"
const TOKENS_TYPE: StringName = &"Tokens"

## A beam lands on a hull every frame, so its hits read through the same two doors a
## landed projectile uses (`Projectile.play_impact` / `spawn_shield_ripple`): the cue for
## what took the hit and the shield's ring. The read is rate-gated per contact - one on
## the frame the contact starts and one every `BEAM_HIT_INTERVAL` after - because a cue
## per frame is a machine gun, not a beam.
##
## AUDIO_SPEC states no rate for a beam's hits, and the impact takes it plays run
## 0.117-0.364 s, so a quarter second is a sustained read rather than a stack (proposed).
const BEAM_HIT_INTERVAL := 0.25

## AUDIO_SPEC section 8's S8, "Mining chip hit": the transient a gun makes chipping a
## rock, and the cue FX_SPEC section 1.6 pairs with the chip-sparks burst. It is the
## same take `mining_laser.gd`'s own `CHIP_CUE` names - `_01` and not the 01-04
## round-robin, because `sfx_mining_chip_04` is a documented 21 s outlier (ASSET_AUDIT
## item 8) - and the suite keeps the two constants equal, so they cannot drift.
const CHIP_CUE: StringName = &"sfx_mining_chip_01"

## The held beam's bed. The library ships exactly one energy-emission loop (S6's shield
## hum and S7's mining bed are the same source, `staging/audio/build_audio.py`), and the
## mining bed is its only shipped looping take, so a held weapon beam rides that bed;
## a dedicated `sfx_weapon_beam_loop` is the ideal asset (proposed).
const BEAM_BED_CUE: StringName = &"sfx_mining_beam"

## FX_SPEC section 1.6's 2026-09-22 amendment (S2.6, the owner's sixth and seventh
## requests). Both are drawn-line/effect-position only: the damage still resolves at the
## surface point the ray found, and no damage number moves.
##
##   `BEAM_SINK` - the drawn shaft ends `BEAM_SINK` of the way from that point to the
##   struck body's centre (owner: "a laser beam should connect to more of the middle of
##   the object"), so the line reads as reaching into the object instead of stopping at
##   its rim. Reversal: `0.0` = the rim hit, exactly as shipped.
##
##   `HIT_FX_JITTER_MULT` - the contact FX spawn at a uniform random point in a disc of
##   `clamp(HIT_FX_JITTER_MULT x collision radius, MIN, MAX)` u around the resolved hit
##   (owner: "a beam's hit should spawn its impact FX somewhat randomly across the struck
##   surface instead of at one fixed point"). The radius is the target's own
##   (`Projectile.collision_radius`); the 48 u ceiling is inert for every shipped object
##   and the 8 u floor binds for a radius-less one. Reversal: `0.0` = the fixed contact
##   point, which `Projectile.scatter_in_disc` hands straight back.
const BEAM_SINK := 0.45
const HIT_FX_JITTER_MULT := 0.35
const HIT_FX_JITTER_MIN := 8.0
const HIT_FX_JITTER_MAX := 48.0

## Fire feedback draws over the hull that fired it (the hull's own sprite sits at the
## default 0 on the same canvas).
const FEEDBACK_Z := 2

## A hull's collider is its own `HullBody` (`RigidBody2D`), which carries no damage
## method, so a hit that lands on one has to be handed to the ship behind it. These
## are the groups a ship answers to: `game.gd:_hull_of` walks the same two for the
## lock pick, so the two resolvers cannot drift apart.
const SHIP_GROUPS: Array[StringName] = [&"player_ship", &"npc_ship"]

var _stats: ShipStats = null
var _state: PlayerState = null
var _fitted: Array[StringName] = []
var _group := 1

## The batteries of `_fitted`, rebuilt with it: the distinct ids in first-barrel order
## (CONTRACTS section 16 rule 2). `weapon_1..5` and every HUD slot address one entry.
var _batteries: Array[StringName] = []

var _firing := false
var _was_firing := false
var _external_trigger := false
var _dry_noted := false

## One cadence timer per barrel of `fitted()` (CONTRACTS section 16 rule 4: "the single
## `_shot_timer` becomes one timer per barrel"), so three cannons deliver three shots
## per burst window and a held trigger is a stream of salvos rather than one burst.
var _barrel_timers: Array[float] = []

## One release countdown per barrel: `>= 0.0` is the seconds left before that barrel
## releases this pull, `-1.0` is unarmed (nothing pending). Armed by `_arm_battery` on
## the pull's rising edge, spent by `_release_battery` a frame at a time.
var _armed: Array[float] = []

## One open flag per instant (beam) barrel: the barrel has released and, while the
## trigger is held, keeps paying its family's `draw x delta` and drawing every frame
## (CONTRACTS section 16 rule 6).
var _beam_open: Array[bool] = []

## The battery the last arm was for, so a group switched mid-hold arms the new one.
var _armed_weapon: StringName = &""
var _burst_phase := 0.0
var _beam_live := false

## The strum's own generator. Private, like `_fx_rng`, so the release offsets never
## perturb another generator's stream and a seeded run still measures what it says.
var _strum_rng := RandomNumberGenerator.new()

## The instant families' two engine-drawn lines (FX_SPEC section 1.6), built in code
## because the component itself is mounted in code.
var _beam_halo: Line2D = null
var _beam_core: Line2D = null

## The beam's own hit feedback: the target the rate guard is counting for and how long
## that contact has been held since it was last read (a fresh contact reads at once).
var _beam_contact: Object = null
var _beam_hit_clock := 0.0

## The contact FX's own generator (FX_SPEC section 1.6's scatter). Private, like the
## asteroid field's and the hull's arc sparks', so the effects never perturb the gameplay
## streams and a seeded run still measures what it says.
var _fx_rng := RandomNumberGenerator.new()

## The held beam's fire-feedback clock: how long it is since the muzzle flash and the
## family's cue last played. Cleared when the beam opens and when it goes out, so each
## hold starts from its own opening flash.
var _beam_feedback_clock := 0.0

## The lock the seeker follows (section 4.1/4.6). The channel that earns it is
## W5's; this is the seam it lands on.
var _lock_target: Node2D = null

## An explicit aim point (additive seam): a probe and a non-mouse aiming mode both
## need to fire at a chosen point, and the cursor is read only when unset.
var _has_aim_point := false
var _aim_override := Vector2.ZERO

var _chaff_remaining := 0.0
var _ghosts: Array[Node2D] = []
var _flare: Node2D = null
var _flare_age := 0.0
var _flare_rockets: Array[Node2D] = []

## Whether a target's damage method takes section 4.2 item 5's context, cached per
## target class: the answer belongs to the script, not to the hit.
var _ctx_arity: Dictionary = {}


## The launch handshake (pinned interface): the resolved snapshot and the live
## pools. Re-callable on a hull swap.
func setup(stats: ShipStats, state: PlayerState) -> void:
	_stats = stats
	_state = state
	_connect_feedback()


func _ready() -> void:
	_connect_feedback()


## The fire feedback hangs off this component's own `shot_fired`, so a released
## projectile, a beam's opening frame and the mine's drop all take one route.
## Connected from `setup` as well as `_ready`: a fixture that is never added to a tree
## still fires, and the second call is a no-op.
func _connect_feedback() -> void:
	if not shot_fired.is_connected(_on_shot_fired):
		shot_fired.connect(_on_shot_fired)


## The fitted weapon ids, **one entry per barrel in fit order** (`weapon_1` is index 0).
## Module ids are accepted as well as weapon ids - `w_laser` normalizes to `laser` -
## because the fit is a module list and the family table is keyed by weapon (09
## section 3.1's two names for the same thing). Unknown or family-less ids are dropped
## rather than kept as dead barrels; **duplicates are kept**, because N barrels keep N W
## mounts (09 section 10's 2026-09-22 ruling) and the battery is what groups them
## (CONTRACTS section 16 rules 1-2). The whole list is otherwise kept, because six
## families exist while the input map offers five `weapon_1..5` keys, so a fit can carry
## more weapons than there are selectable batteries (reported).
func set_fitted(ids: Array[StringName]) -> void:
	_fitted.clear()
	for value: StringName in ids:
		var id := weapon_id(value)
		if id == &"":
			continue
		_fitted.append(id)
	_sync_barrels()


## Rebuilds everything a fit change invalidates: the battery list `weapon_1..5` selects
## from, and the three per-barrel arrays the volley runs on.
func _sync_barrels() -> void:
	var batteries: Array[StringName] = []
	for id: StringName in _fitted:
		if not batteries.has(id):
			batteries.append(id)
	_batteries = batteries
	var timers: Array[float] = []
	var armed: Array[float] = []
	var open: Array[bool] = []
	for _position in _fitted.size():
		timers.append(0.0)
		armed.append(-1.0)
		open.append(false)
	_barrel_timers = timers
	_armed = armed
	_beam_open = open
	_armed_weapon = &""


## `weapon_1..5` (section 4.3): the input map's five keys are the group range, so a
## group outside it clamps. A group with no fitted battery selects nothing, and the
## trigger then falls silent rather than firing the previous group.
func select_group(group: int) -> void:
	_group = clampi(group, 1, GROUPS_MAX)


func selected_group() -> int:
	return _group


## The selected battery's weapon id, `&""` past the end of `battery_ids()`.
func selected_weapon() -> StringName:
	if _group < 1 or _group > _batteries.size():
		return &""
	return _batteries[_group - 1]


## The batteries this fit carries, in first-barrel order (CONTRACTS section 16 rule 2):
## the distinct weapon ids of `fitted()`, duplicated so a caller cannot write through.
## A battery - not a barrel - is what a `weapon_1..5` key and every HUD slot addresses,
## so on a fit of distinct families this list is element-for-element the `fitted()` this
## component shipped before S4 and every existing group, cadence and dry test reads the
## same.
func battery_ids() -> Array[StringName]:
	return _batteries.duplicate()


## This battery's **barrel positions in `fitted()`**, ascending - not W-cell indices
## (CONTRACTS section 16 rule 3): the component is handed a flat id list that has
## already dropped family-less modules, so the two index spaces diverge on the first
## `w_mining` cell. Normalised through `weapon_id`, so `&"w_laser"` and `&"laser"`
## answer the same list; a base with no firing family answers `[]` (its strip row
## exists, but there is no trigger behind it).
func battery(base_id: StringName) -> Array:
	var positions: Array = []
	var id := weapon_id(base_id)
	if id == &"":
		return positions
	for position in _fitted.size():
		if _fitted[position] == id:
			positions.append(position)
	return positions


## One entry per barrel, fit order, duplicates kept - what the volley walks.
func fitted() -> Array[StringName]:
	return _fitted.duplicate()


func is_fitted(weapon: StringName) -> bool:
	return _fitted.has(weapon)


## The trigger: held means fire the selected group. Called by `_physics_process`
## from the input map; `set_firing` is the explicit seam a probe or a caller that
## reads its own input uses, and `poll_input` hands it back.
func set_firing(active: bool) -> void:
	_external_trigger = true
	_firing = active


func poll_input() -> void:
	_external_trigger = false


func is_firing() -> bool:
	return _firing


## Why the selected group cannot shoot right now, in the closed vocabulary
## `&"none"` (nothing selected), `&"energy"` (the pool is empty, section 4.4) and
## `&"ammo"` (the pack is empty, section 4.3); `&""` means it can.
func dry_reason() -> StringName:
	var id := selected_weapon()
	if id == &"":
		return &"none"
	var row: Dictionary = FAMILIES[id]
	if float(row.get(&"draw", 0.0)) > 0.0:
		return &"energy" if _state == null or _state.energy <= 0.0 else &""
	if not _ammo_available(id):
		return &"ammo"
	return &""


## The lock seam the seeker follows (section 4.1 "the rocket is the first
## heat-seeker: its homing runs on the lock target"). The lock channel belongs to
## the HUD/wiring layer; it marks and it earns the lock, this component only reads
## it, and it is dropped when the target dies or leaves the scanner's range.
func set_lock_target(target: Node2D) -> void:
	_lock_target = target


func clear_lock_target() -> void:
	_lock_target = null


func lock_target() -> Node2D:
	return _lock_target


## The aim override (additive seam): a probe fires deterministically and a
## stick/keyboard aiming mode can replace the cursor.
func set_aim_point(point: Vector2) -> void:
	_has_aim_point = true
	_aim_override = point


func clear_aim_point() -> void:
	_has_aim_point = false


## Section 4.6's chaff half: while the ghosts live, a lock cannot re-acquire the
## real hull. The lock's owner asks this before it starts a channel.
func jamming() -> bool:
	return _chaff_remaining > 0.0


func ghosts() -> Array[Node2D]:
	var live: Array[Node2D] = []
	for ghost: Node2D in _ghosts:
		if ghost != null and is_instance_valid(ghost):
			live.append(ghost)
	return live


func flare() -> Node2D:
	return _flare if _flare != null and is_instance_valid(_flare) else null


## Section 4.6: one `cm_chaff` or `cm_flare` item is spent from the hold and its
## effect fires. `PlayerProfile` is the only cargo mutator (17 section 5 rule 2),
## so the spend is a guarded `remove_cargo`; a refused spend changes nothing and
## returns false.
func use_countermeasure(item_id: StringName) -> bool:
	if item_id != CHAFF_ITEM and item_id != FLARE_ITEM:
		return false
	if not _spend_item(item_id):
		return false
	if item_id == CHAFF_ITEM:
		_deploy_chaff()
	else:
		_deploy_flare()
	countermeasure_used.emit(item_id)
	return true


## --- The frame ------------------------------------------------------------


func _physics_process(delta: float) -> void:
	tick(delta)


## One frame of the trigger. `_physics_process` is exactly this call, so a probe or
## a test can step the weapons deterministically without a physics frame.
##
## The frame, in order (CONTRACTS section 16 rule 4): the barrels' own cadence timers
## run down, a pull's rising edge arms the selected battery, an unheld trigger disarms
## it, and then every armed barrel whose offset has elapsed and whose cadence is ready
## releases - a travelling one fires, an instant one opens.
func tick(delta: float) -> void:
	_sample_trigger()
	if delta > 0.0:
		_advance_barrel_timers(delta)
		if _firing:
			_burst_phase = fmod(_burst_phase + delta, KINETIC_INTERVAL)
		_advance_countermeasures(delta)
		_prune_lock()
	var edge := _firing and not _was_firing
	if edge:
		_dry_noted = false
		_beam_live = false
		_burst_phase = 0.0
		_arm_battery()
	if not _firing:
		_was_firing = false
		_beam_live = false
		_disarm_battery()
		_close_beams()
		_hide_beam()
		return
	_was_firing = true
	var id := selected_weapon()
	if id == &"":
		return
	## A group switched while the trigger is held arms the battery it switched to: the
	## pin's rising edge is where a pull arms, and a battery that was never armed would
	## otherwise fire nothing until the trigger was let go and pulled again.
	if id != _armed_weapon:
		_arm_battery()
	var row: Dictionary = FAMILIES[id]
	_release_battery(id, row, delta)
	if bool(row.get(&"instant", false)):
		_fire_beam_battery(id, row, delta)


## One frame of the barrels' own cadence. They run down whether or not the trigger is
## held, exactly as the single `_shot_timer` did, so a barrel's rate is its family's
## and not the pull's.
func _advance_barrel_timers(delta: float) -> void:
	for position in _barrel_timers.size():
		_barrel_timers[position] = maxf(_barrel_timers[position] - delta, 0.0)


## The pull's rising edge (CONTRACTS section 16 rule 4): every barrel of the selected
## battery draws a release offset uniformly in `[0, BATTERY_STRUM_MS]` ms, and the
## volley's clock is the battery's own earliest draw - so the lead barrel releases on
## the pull's own frame, which is the frame the pinned fire feedback (FX_SPEC section
## 1.2's flash, section 1.6's opening shaft) has always opened on, and a one-barrel
## battery is never held up by the draw. Every barrel behind the lead releases when its
## own offset has elapsed.
func _arm_battery() -> void:
	_disarm_battery()
	var weapon := selected_weapon()
	_armed_weapon = weapon
	if weapon == &"":
		return
	var positions := battery(weapon)
	var ceiling := float(BATTERY_STRUM_MS) / 1000.0
	var lead := INF
	for position: int in positions:
		var offset := _strum_rng.randf_range(0.0, ceiling)
		_armed[position] = offset
		lead = minf(lead, offset)
	if lead <= 0.0 or lead == INF:
		return
	for position: int in positions:
		_armed[position] -= lead


func _disarm_battery() -> void:
	for position in _armed.size():
		_armed[position] = -1.0
	_armed_weapon = &""


func _close_beams() -> void:
	for position in _beam_open.size():
		_beam_open[position] = false


## One frame of the pull: every armed barrel whose release offset has elapsed **and**
## whose own cadence timer is ready releases (CONTRACTS section 16 rule 4). A barrel
## whose cadence or burst window is not ready stays armed and retries next frame - the
## trigger is still held - so one barrel's cadence never silences the rest of the
## battery. An instant barrel opens; a travelling one fires through
## `_fire_projectile`, which is where a family's own refusal (an empty pack) makes
## that barrel dry.
func _release_battery(weapon: StringName, row: Dictionary, delta: float) -> void:
	var instant := bool(row.get(&"instant", false))
	var step := maxf(delta, 0.0)
	for position: int in battery(weapon):
		if _armed[position] < 0.0:
			continue
		_armed[position] -= step
		if _armed[position] > 0.0:
			continue
		if _barrel_timers[position] > 0.0:
			continue
		if not instant and not _burst_open(row):
			continue
		_armed[position] = -1.0
		if instant:
			_beam_open[position] = true
		else:
			_fire_projectile(position, weapon, row)


func _sample_trigger() -> void:
	if _external_trigger:
		return
	if not InputMap.has_action(FIRE_ACTION):
		_firing = false
		return
	_firing = Input.is_action_pressed(FIRE_ACTION)


## The cannon fires during its 0.35 s on-window and is silent for the 0.25 s off
## (section 4.1's burst cycle). A row without a cycle is always open.
func _burst_open(row: Dictionary) -> bool:
	var on := float(row.get(&"burst_on", 0.0))
	if on <= 0.0:
		return true
	return _burst_phase < on


## --- Firing ---------------------------------------------------------------


## Section 4.1's instant families: "energy shots resolve instantly at the cursor's
## ray point (circle hit test), capped at the weapon's range", for `dps x delta` of
## damage, paid for out of the Energy pool first (section 4.4): a pool that cannot
## pay the frame means no shot and dry-fire feedback.
##
## One frame of a **battery** (CONTRACTS section 16 rule 6): every open barrel pays its
## own `draw x delta`, a pool that cannot pay one makes only that barrel dry for the
## frame, and the ones before it keep drawing. The shaft itself is one drawing - one
## muzzle, one aim point, whatever the barrel count - and the frame's damage is the sum
## of the barrels that paid, so a three-laser battery burns three draws and deals three
## lasers' worth without drawing three shafts over each other.
func _fire_beam_battery(weapon: StringName, row: Dictionary, delta: float) -> void:
	var draw := float(row.get(&"draw", 0.0)) * maxf(delta, 0.0)
	var paid := 0
	for position: int in battery(weapon):
		if not _beam_open[position]:
			continue
		if not _spend_energy(draw):
			_dry(weapon)
			continue
		paid += 1
	if paid == 0:
		_beam_live = false
		_hide_beam()
		return
	var from := global_position
	var offset := _aim_point() - from
	var reach := minf(offset.length(), float(row.get(&"range", 0.0)))
	if reach <= 0.0:
		_hide_beam()
		return
	var to := from + offset.normalized() * reach
	## FX_SPEC section 1.6's engine-drawn beam. The target is resolved **before** the
	## shaft is drawn, so the shaft stops on the point the ray actually reached
	## (`target[&"point"]`) instead of running through it to the aim point; a miss still
	## draws the weapon's own reach, so an empty shot shows exactly as it did.
	## (The impact visual stays the hit site's business, not the beam's.)
	var target := _beam_target(from, to)
	var endpoint := to
	var collider: Variant = target.get(&"collider")
	if not target.is_empty():
		endpoint = target[&"point"]
	## Section 1.6's amendment: what is drawn stops `BEAM_SINK` short of the surface, on
	## its way to the struck body's centre. `endpoint` itself stays the surface point -
	## the damage, the cue and the rocket's blast all resolve where the ray landed.
	_draw_beam(_beam_drawn_end(endpoint, collider))
	_beam_started(weapon)
	_advance_fire_feedback(weapon, delta)
	if target.is_empty():
		return
	if bool(target[&"projectile"]):
		## Section 4.1: a rocket dies to any weapon hit, and the beam stops there. The
		## kill is a destruction like every other, so it takes the explosion and the blast
		## cue the projectile route gives it (reported: the beam's kill was silent beside
		## the projectile's).
		(collider as Node).call(&"fizzle")
		ProjectileScript.play_blast(self)
		ProjectileScript.spawn_explosion(_hit_fx_parent(collider), endpoint)
		return
	_apply_beam(weapon, row, collider, endpoint, delta, float(paid))


## A travelling family (section 4.1): a shot leaves at its own speed toward the
## cursor, spends one round from its pack, and pushes the hull back with section
## 4.2 item 7's term through the hull's own `apply_recoil` seam.
##
## Called once per **barrel** of the battery as that barrel releases (CONTRACTS section
## 16 rules 4-5), so a three-barrel volley spawns three shots, spends three rounds from
## the one family pack and pushes the hull three times. The release is the barrel's own
## edge: a barrel is armed only by a pull and disarmed when it fires, which is where the
## mine's "one per trigger pull" now lives. A barrel the pack refuses is dry and leaves
## the rest of the battery to fire.
func _fire_projectile(position: int, weapon: StringName, row: Dictionary) -> void:
	if not _ammo_available(weapon):
		_dry(weapon)
		return
	var speed := float(row.get(&"speed", 0.0))
	var direction := _aim_direction() if speed > 0.0 else Vector2.ZERO
	var shot := _spawn_shot(weapon, row, direction)
	if shot == null:
		return
	_consume_ammo(weapon)
	_barrel_timers[position] = interval_of(weapon)
	_apply_recoil(direction * speed)
	shot_fired.emit(weapon)


func _spawn_shot(weapon: StringName, row: Dictionary, direction: Vector2) -> Node2D:
	var parent := _world_parent()
	if parent == null:
		return null
	var shot := ProjectileScript.new() as Node2D
	if shot == null:
		return null
	shot.name = PROJECTILE_NODE_NAME
	shot.call(&"configure", {
		&"kind": StringName(row.get(&"kind", &"bolt")),
		&"speed": float(row.get(&"speed", 0.0)),
		&"damage": shot_damage(weapon),
		&"bypass_shield": bool(row.get(&"bypass_shield", false)),
		&"homing": bool(row.get(&"homing", false)),
		&"target": _seeker_target(weapon),
		&"turn_rate": float(row.get(&"turn_rate", 0.0)),
		&"source": _host(),
		&"direction": direction,
		&"range": float(row.get(&"range", 0.0)),
		&"arm": float(row.get(&"arm", 0.0)),
		&"trigger": float(row.get(&"trigger", 0.0)),
		&"mass": SHOT_MASS,
		&"chip": GUN_CHIP_RATE,
	})
	parent.add_child(shot)
	shot.global_position = global_position
	return shot


## The beam's business, once the shot has spent its Energy: a rock takes section
## 6's chip work (depletion only - the units `apply_work` reports are the mining
## laser's extraction and are discarded here, ruling 17) plus section 1.6's own
## contact read, and a hull takes `dps x delta` of damage under its family's shield
## rule.
##
## `barrels` is how many of the battery's barrels paid for this frame (CONTRACTS
## section 16 rule 6's per-barrel frame): the damage and the chip work are that many
## barrels' own `dps x delta`. The shaft and the contact feedback stay one read per
## frame - one muzzle, one aim point, one contact - so a battery of three lasers deals
## three lasers' worth without reading its target three times a frame.
func _apply_beam(
	weapon: StringName,
	row: Dictionary,
	collider: Variant,
	point: Vector2,
	delta: float,
	barrels: float = 1.0
) -> void:
	var amount := dps_of(weapon) * maxf(delta, 0.0) * maxf(barrels, 0.0)
	if amount <= 0.0:
		return
	var hull_body := collider as Node
	if hull_body != null and hull_body.is_in_group(ProjectileScript.ROCK_GROUP):
		if hull_body.has_method(&"apply_work"):
			hull_body.call(&"apply_work", amount * GUN_CHIP_RATE)
		## A gun chipping a rock reads the way the mining shaft does: S8's chip transient
		## and FX_SPEC section 1.6's chip-sparks burst at the contact, on the same
		## per-contact rate guard the hull read below uses (a chip per frame is a machine
		## gun, not a beam).
		if _beam_read_due(collider, delta):
			_play_chip_cue()
			ProjectileScript.spawn_chip_sparks(_hit_fx_parent(collider), _hit_fx_point(collider, point))
		return
	## The sink is resolved once and read for both the shield rule and the delivery:
	## a hull's collider is that hull's own `HullBody`, which cannot answer
	## `_shield_up`, so plasma's "+25 % once shields are down" would otherwise fire
	## against live shields on the body's silence.
	var target := _sink_for(collider)
	var bypass := bool(row.get(&"bypass_shield", false))
	## Whether this frame's damage is going into a shield: the same read the delivered
	## hit makes, so the cue, the ring and the damage can never disagree.
	var shielded := not bypass and _shield_up(target)
	## Section 4.1: plasma is "+25 % to hull once shields are down". Only a target
	## whose shield the weapon can read gets the bonus, so the family can never
	## out-damage its own row.
	var bonus := float(row.get(&"hull_bonus", 1.0))
	if bonus > 1.0 and not bypass and not _shield_up(target):
		amount *= bonus
	_beam_hit_feedback(target, shielded, point, delta)
	_deliver(
		target, amount, bypass, point, StringName(row.get(&"family", &"energy")), Vector2.ZERO
	)


## The beam's per-contact rate guard, shared by both reads it makes: true on the frame a
## contact starts and once every `BEAM_HIT_INTERVAL` after, false on the frames between.
## One guard for a hull's cue and a rock's chip, so a beam cannot read one contact at a
## different cadence than another. `_hide_beam` clears the contact, so a new hold on the
## same thing reads from its own first frame.
func _beam_read_due(target: Object, delta: float) -> bool:
	if target == null:
		_beam_contact = null
		_beam_hit_clock = 0.0
		return false
	if target != _beam_contact:
		_beam_contact = target
		_beam_hit_clock = BEAM_HIT_INTERVAL
	_beam_hit_clock += maxf(delta, 0.0)
	if _beam_hit_clock < BEAM_HIT_INTERVAL:
		return false
	_beam_hit_clock = 0.0
	return true


## The hit's other half for a beam: the cue for what is taking the damage and, once the
## shield absorbs it, section 1.5's ring and S6's bed - the same doors a landed
## projectile uses, so a beam's hits read exactly like a shot's.
##
## Rate-gated per contact through `_beam_read_due`, because the damage is per frame.
func _beam_hit_feedback(target: Object, shielded: bool, point: Vector2, delta: float) -> void:
	if not _beam_read_due(target, delta):
		return
	var kind := (
		ProjectileScript.IMPACT_KIND_SHIELD if shielded else ProjectileScript.IMPACT_KIND_HULL
	)
	ProjectileScript.play_impact(self, kind)
	if not shielded:
		return
	ProjectileScript.spawn_shield_ripple(_hit_fx_parent(target), _hit_fx_point(target, point))
	ProjectileScript.hold_shield(self)


## FX_SPEC section 1.6's amendment, the one seam this file's two contact-FX readers go
## through (the rock's chip sparks above and the hull's shield ring below): a uniform
## random point in the pinned `clamp(HIT_FX_JITTER_MULT x collision radius, MIN, MAX)` u
## disc around the resolved hit. The radius belongs to what was hit, so a rock scatters
## over its own 24/42/66 u body, a hull over its 30 u collider and a radius-less target
## over the 8 u floor. Only the effect's position moves.
func _hit_fx_point(target: Object, at: Vector2) -> Vector2:
	var radius := clampf(
		HIT_FX_JITTER_MULT * ProjectileScript.collision_radius(target),
		HIT_FX_JITTER_MIN,
		HIT_FX_JITTER_MAX
	)
	return ProjectileScript.scatter_in_disc(_fx_rng, at, radius)


## What the shaft is drawn to: the point the ray resolved, pulled `BEAM_SINK` of the way
## towards the struck body's centre (FX_SPEC section 1.6's amendment). A miss has no
## target and a beam's own reach is what was asked for, so the reach is handed back.
func _beam_drawn_end(hit_point: Vector2, target: Object) -> Vector2:
	var body := target as Node2D
	if body == null or not is_instance_valid(body):
		return hit_point
	return hit_point.lerp(body.global_position, BEAM_SINK)


## S8's chip transient, through the one-shot SFX route the mining laser's own
## `_play_chip` uses. A missing audio service is a no-op.
func _play_chip_cue() -> void:
	var audio := _audio()
	if audio == null or not audio.has_method(&"play_sfx"):
		return
	audio.call(&"play_sfx", CHIP_CUE)


## Once per beam hold: the weapon announces that it opened fire (the per-frame
## damage is not a shot, so it is not per-frame signal traffic). The feedback clock
## starts here too, so the hold's opening flash and the replays after it are one cycle
## apart.
func _beam_started(weapon: StringName) -> void:
	if _beam_live:
		return
	_beam_live = true
	_beam_feedback_clock = 0.0
	shot_fired.emit(weapon)


## A held trigger's fire feedback, on FX_SPEC section 1.2's own clock. The flash is a
## one-shot ("4 frames at 20 FPS = 0.2 s total, one-shot, no loop"), so a held beam cannot
## loop the animation: it replays the same one-shot - and the family's cue with it - once
## per flash cycle for as long as the beam is up, instead of one flash per release (the
## owner's third-round finding W4, "they should loop").
##
## `shot_fired` is deliberately NOT re-emitted: section 4.1's pinned signal stays one per
## hold, and only what the hold looks and sounds like repeats.
func _advance_fire_feedback(weapon: StringName, delta: float) -> void:
	_beam_feedback_clock += maxf(delta, 0.0)
	if _beam_feedback_clock < FLASH_SECONDS:
		return
	_beam_feedback_clock = fmod(_beam_feedback_clock, FLASH_SECONDS)
	_on_shot_fired(weapon)


func _dry(weapon: StringName) -> void:
	if _dry_noted:
		return
	_dry_noted = true
	dry_fired.emit(weapon)


## --- Fire and travel feedback --------------------------------------------


## One released shot's feedback, hung off `shot_fired` so every family takes the same
## route: the muzzle flash at the muzzle and the family's own fire cue. Cadence,
## damage, Energy and ammo are untouched - this only draws and sounds what the shot
## already did.
func _on_shot_fired(weapon: StringName) -> void:
	_spawn_muzzle_flash(_aim_direction())
	_play_fire_cue(weapon)


## FX_SPEC section 1.2's four-frame flash on the muzzle. The muzzle is this
## component's own origin - the point a shot leaves from and a beam launches from -
## and the frame is offset so the flash's mouth, not its middle, sits there. Freed by
## the animation itself (`Fx.play_once`).
func _spawn_muzzle_flash(direction: Vector2) -> void:
	var textures: Array = []
	for path: String in FLASH_FRAMES:
		if not ResourceLoader.exists(path):
			return
		textures.append(load(path))
	var frames := FxScript.texture_frames(textures, FLASH_FPS)
	if frames.get_frame_count(FxScript.ANIMATION) == 0:
		return
	var scale_factor := FxScript.scale_for(FLASH_FRAME_SIZE, FLASH_WORLD)
	var flash := FxScript.play_once(
		self,
		frames,
		-FLASH_MUZZLE_PX * scale_factor,
		direction.angle() - global_rotation,
		scale_factor,
		false
	)
	if flash != null:
		flash.z_index = FEEDBACK_Z


## The family's cue, through the audio service's pool route (the extra takes on disk
## are unreachable through a plain `play_sfx` - ASSET_WIRING_HANDOFF section 1.2). A
## family AUDIO_SPEC gives no cue plays none.
func _play_fire_cue(weapon: StringName) -> void:
	var cue := fire_cue_of(weapon)
	if cue == &"":
		return
	var audio := _audio()
	if audio == null or not audio.has_method(&"play_pool"):
		return
	audio.call(&"play_pool", cue, fire_take_of(weapon))


func _audio() -> Node:
	if not is_inside_tree():
		return null
	return get_tree().root.get_node_or_null(NodePath(AUDIO_SERVICE))


## The instant families' shaft: two lines from this muzzle to `to`, drawn in this
## component's own space (the convention `mining_laser.gd` uses). Built lazily, so a
## component that is never in a tree still has somewhere to draw.
func _draw_beam(to: Vector2) -> void:
	_sync_beam()
	if _beam_halo == null or _beam_core == null:
		return
	var local_end := to_local(to)
	var points := PackedVector2Array([Vector2.ZERO, local_end])
	_beam_halo.points = points
	_beam_core.points = points
	_beam_halo.visible = true
	_beam_core.visible = true
	## A held beam is an emission that lasts, so it rides a bed: S7's held-loop model
	## (`mining_laser.gd:_play_beam_loop`), through the manager's loop route.
	_play_beam_bed()


func _hide_beam() -> void:
	if _beam_halo != null and is_instance_valid(_beam_halo):
		_beam_halo.visible = false
	if _beam_core != null and is_instance_valid(_beam_core):
		_beam_core.visible = false
	## The beam is not held any more, so nothing is in contact, nothing is sounding and
	## the fire feedback's clock starts fresh on the next hold.
	_beam_contact = null
	_beam_hit_clock = 0.0
	_beam_feedback_clock = 0.0
	_stop_beam_bed()


## Leaving the tree (a hull swap, a death, a scene change) must not leave the bed
## sounding under a beam that no longer exists.
func _exit_tree() -> void:
	_stop_beam_bed()


## The held beam's bed, on the mining laser's model: a looping cue through
## `play_loop`, which is idempotent, so the per-frame call costs nothing once the bed is
## up. The library's one energy-emission loop is the mining bed's take (see
## `BEAM_BED_CUE`).
func _play_beam_bed() -> void:
	var audio := _audio()
	if audio == null or not audio.has_method(&"play_loop"):
		return
	audio.call(&"play_loop", BEAM_BED_CUE)


## The bed goes out with the beam. The manager's cue-scoped stop is preferred: the guarded
## route below (`mining_laser.gd:_stop_beam_loop`'s, kept for a service that has no
## `stop_bed`) can only name the foreground bed, and a held beam's bed is not the
## foreground one while an impact hum is up - measured, and the reason `stop_bed` exists.
func _stop_beam_bed() -> void:
	var audio := _audio()
	if audio == null:
		return
	if audio.has_method(&"stop_bed"):
		audio.call(&"stop_bed", BEAM_BED_CUE)
		return
	if not audio.has_method(&"current_loop") or not audio.has_method(&"stop_loop"):
		return
	if StringName(audio.call(&"current_loop")) != BEAM_BED_CUE:
		return
	audio.call(&"stop_loop")


## Where a hit's effect hangs: the world node the thing that was hit lives in, so the
## ring stays on the point that was hit instead of riding the ship that fired. A target
## with no parent falls back to the world node, the scene `_spawn_shot` uses.
func _hit_fx_parent(target: Object) -> Node:
	var node := target as Node
	if node != null and is_instance_valid(node) and node.get_parent() != null:
		return node.get_parent()
	return _world_parent()


func _sync_beam() -> void:
	if _beam_halo != null and is_instance_valid(_beam_halo):
		return
	var theme := load(THEME_PATH) as Theme
	_beam_halo = _make_beam(
		BEAM_NAMES[0], BEAM_HALO_WIDTH, BEAM_HALO_TOKEN, BEAM_HALO_ALPHA, theme
	)
	_beam_core = _make_beam(
		BEAM_NAMES[1], BEAM_CORE_WIDTH, BEAM_CORE_TOKEN, BEAM_CORE_ALPHA, theme
	)
	add_child(_beam_halo)
	add_child(_beam_core)


## One line of the shaft. Both tones come from the generated theme and are drawn
## additively (an ember weapon beam is light, not ink).
func _make_beam(
	node_name: StringName, width: float, token: StringName, alpha: float, theme: Theme
) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.width = width
	var color := Color.WHITE
	if theme != null:
		color = theme.get_color(token, TOKENS_TYPE)
	color.a = alpha
	line.default_color = color
	line.material = FxScript.additive_material()
	line.z_index = FEEDBACK_Z
	line.visible = false
	return line


## --- Aim and targeting ----------------------------------------------------


func _aim_direction() -> Vector2:
	var offset := _aim_point() - global_position
	if offset.is_zero_approx():
		return Vector2.RIGHT.rotated(_host_rotation())
	return offset.normalized()


func _aim_point() -> Vector2:
	if _has_aim_point:
		return _aim_override
	if not is_inside_tree():
		return global_position
	return get_global_mouse_position()


func _host_rotation() -> float:
	var host := _host()
	if host != null:
		return host.global_rotation
	return global_rotation


## The rocket's target at launch: the lock target while it is valid and inside the
## scanner's lock range (section 4.1 ruling 21: "lock range = the scanner's range").
## Without one, `configure` gets no target and the rocket dumb-fires at the cursor.
func _seeker_target(weapon: StringName) -> Node2D:
	if weapon != &"rocket":
		return null
	if _lock_target == null or not is_instance_valid(_lock_target):
		return null
	if _stats != null and _stats.lock_range > 0.0:
		if global_position.distance_to(_lock_target.global_position) > _stats.lock_range:
			return null
	return _lock_target


func _prune_lock() -> void:
	if _lock_target == null:
		return
	if not is_instance_valid(_lock_target):
		_lock_target = null
		return
	if _stats != null and _stats.lock_range > 0.0:
		if global_position.distance_to(_lock_target.global_position) > _stats.lock_range:
			_lock_target = null


## The nearest thing the beam reaches: the first body on the ray (a rock or a hull)
## or a destructible shot on the same segment, whichever is closer.
func _beam_target(from: Vector2, to: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var space := _space()
	if space != null:
		var query := PhysicsRayQueryParameters2D.create(from, to, TARGET_MASK, _exclusions())
		query.collide_with_areas = false
		query.collide_with_bodies = true
		var hit: Dictionary = space.intersect_ray(query)
		if not hit.is_empty():
			var point: Vector2 = hit.get("position", to)
			best = {
				&"point": point,
				&"collider": hit.get("collider"),
				&"distance": from.distance_to(point),
				&"projectile": false,
			}
	var shot := _rocket_on_segment(from, to)
	if shot.is_empty():
		return best
	if best.is_empty() or float(shot[&"distance"]) < float(best[&"distance"]):
		return shot
	return best


## A beam is instant and has no body of its own, so a rocket on the segment is
## found by distance to the segment rather than by an overlap event.
func _rocket_on_segment(from: Vector2, to: Vector2) -> Dictionary:
	var tree := get_tree()
	if tree == null:
		return {}
	var best: Dictionary = {}
	var best_distance := INF
	for node: Node in tree.get_nodes_in_group(PROJECTILE_GROUP):
		var shot := node as Node2D
		if shot == null or not is_instance_valid(shot):
			continue
		if not shot.has_method(&"is_destructible") or not bool(shot.call(&"is_destructible")):
			continue
		if _is_own_shot(shot):
			continue
		var closest := Geometry2D.get_closest_point_to_segment(shot.global_position, from, to)
		if shot.global_position.distance_to(closest) > float(shot.call(&"hit_radius")):
			continue
		var along := from.distance_to(closest)
		if along < best_distance:
			best_distance = along
			best = {
				&"point": closest,
				&"collider": shot,
				&"distance": along,
				&"projectile": true,
			}
	return best


func _is_own_shot(shot: Node2D) -> bool:
	if not shot.has_method(&"source"):
		return false
	var source: Variant = shot.call(&"source")
	return source != null and source == _host()


## Whether the target's shields are up (section 4.1's shield rules read it). A
## target that answers through a `shield_up()` method or a `shield` property is
## read directly; a hull that exposes its `state` resource is read through it. A
## target whose shields cannot be read is treated as shields-down only where that
## is the conservative answer (see `_apply_beam`: never a damage bonus).
func _shield_up(target: Object) -> bool:
	if target == null:
		return false
	if target.has_method(&"shield_up"):
		return bool(target.call(&"shield_up"))
	var direct: Variant = target.get(&"shield")
	if _is_number(direct):
		return float(direct) > 0.0
	var state: Variant = target.get(&"state")
	if state != null and state is Object:
		var pooled: Variant = (state as Object).get(&"shield")
		if _is_number(pooled):
			return float(pooled) > 0.0
	return false


## --- Damage delivery ------------------------------------------------------


## The pinned target seam (W2's pipeline calls the same method on the same
## targets): `take_damage(amount, bypass_shield, ctx)`, a two-argument
## `take_damage`, or `PlayerState.damage` as the resource-level fallback. `ctx` is
## section 4.2 item 5's combat context, populated on every hit.
func _deliver(
	target: Object,
	amount: float,
	bypass: bool,
	point: Vector2,
	family: StringName,
	impulse: Vector2
) -> void:
	if amount <= 0.0:
		return
	target = _sink_for(target)
	if target == null:
		return
	if target.has_method(&"take_damage"):
		if _takes_ctx(target, &"take_damage"):
			target.call(&"take_damage", amount, bypass, _ctx(target, point, family, impulse))
		else:
			target.call(&"take_damage", amount, bypass)
		return
	if target.has_method(&"damage"):
		if _takes_ctx(target, &"damage"):
			target.call(&"damage", amount, bypass, _ctx(target, point, family, impulse))
		else:
			target.call(&"damage", amount, bypass)


## The ship behind a physics collider, so a hit that lands on a hull's own body is
## still dealt to the hull (section 4.1: the shot's damage belongs to the ship; the
## collider is a `HullBody` with no damage method). The walk is `game.gd:_hull_of`'s:
## the target itself once it answers for damage, else its nearest ancestor in the
## ship groups. Anything else - a rock, a probe fixture, a resource - is returned
## unchanged, so every existing caller keeps its behaviour.
func _sink_for(target: Object) -> Object:
	if target == null:
		return null
	if target.has_method(&"take_damage") or target.has_method(&"damage"):
		return target
	var cursor := target as Node
	while cursor != null:
		for group: StringName in SHIP_GROUPS:
			if cursor.is_in_group(group):
				return cursor
		cursor = cursor.get_parent()
	return target


func _ctx(target: Object, point: Vector2, family: StringName, impulse: Vector2) -> Dictionary:
	return {
		&"direction": _impact_bearing(target, point),
		&"impulse": impulse,
		&"family": family,
	}


## Section 4.2 item 5: the impact bearing relative to the target's heading, which
## is the key slice 3's quadrants read.
func _impact_bearing(target: Object, point: Vector2) -> float:
	var node := target as Node2D
	if node == null:
		return 0.0
	return wrapf((point - node.global_position).angle() - node.global_rotation, -PI, PI)


## Whether a method takes the context: a property of the class, so the answer is
## cached per script rather than scanned per hit.
func _takes_ctx(target: Object, method: StringName) -> bool:
	var key: Variant = target.get_script()
	if key == null:
		key = target.get_class()
	if _ctx_arity.has(key):
		return bool(_ctx_arity[key])
	var count := 0
	for entry: Dictionary in target.get_method_list():
		if StringName(entry.get("name", "")) == method:
			count = (entry.get("args", []) as Array).size()
			break
	var takes := count >= 3
	_ctx_arity[key] = takes
	return takes


## --- Rounds, Energy, recoil ----------------------------------------------


## Section 4.4: an energy weapon pays `draw x delta` out of the pool before the
## frame's damage, through slice 0's spending gate (which also burns the fuel toll).
func _spend_energy(amount: float) -> bool:
	if _state == null:
		return false
	return _state.try_spend_energy(amount)


func _ammo_available(weapon: StringName) -> bool:
	if _state == null:
		return false
	var slot := ammo_slot(weapon)
	if slot < 0 or slot >= _state.ammo.size():
		return false
	return _state.ammo[slot] > 0


## Section 4.3: the round leaves the pack through `PlayerState.set_ammo`, which is
## the HUD's own channel (`weapon_changed`).
func _consume_ammo(weapon: StringName) -> void:
	if _state == null:
		return
	var slot := ammo_slot(weapon)
	if slot < 0 or slot >= _state.ammo.size():
		return
	_state.set_ammo(slot, _state.ammo[slot] - 1)


## Section 4.2 item 7: firing pushes the hull back with `projectile_mass x
## muzzle_velocity` opposite the muzzle. The arithmetic is slice 0's
## (`Impact.recoil_impulse`) and the hull's `apply_recoil` is the seam that applies
## it to the rigid body; an instant family parts with no mass and no muzzle, so it
## applies no recoil (reported).
func _apply_recoil(velocity: Vector2) -> void:
	var host := _host()
	if host == null or velocity.is_zero_approx():
		return
	if not host.has_method(&"apply_recoil"):
		return
	host.call(&"apply_recoil", velocity, SHOT_MASS)


## --- Countermeasures (section 4.6) ---------------------------------------


func _spend_item(item_id: StringName) -> bool:
	var profile := _profile()
	if profile == null or not profile.has_method(&"remove_cargo"):
		return false
	return bool(profile.call(&"remove_cargo", item_id, 1))


## "on use spawns 3 ghost signatures drifting from the ship for CHAFF_WINDOW
## (3.0 s). Active locks break immediately and cannot re-acquire the real hull
## while ghosts live."
##
## The ghosts drift on the hull's own velocity (section 4.6 pins no drift speed, so
## the hull's speed is the yardstick) plus an evenly spread outward copy of it, one
## per bearing; a hull sitting still leaves three signatures on its own position,
## which is exactly what a decoy of a stationary ship is.
func _deploy_chaff() -> void:
	_break_lock()
	_free_ghosts()
	_chaff_remaining = CHAFF_WINDOW
	var parent := _world_parent()
	if parent == null:
		return
	var velocity := _hull_velocity()
	for index in CHAFF_GHOSTS:
		var ghost := ChaffGhost.new()
		ghost.name = GHOST_NODE_NAME
		parent.add_child(ghost)
		ghost.global_position = global_position
		ghost.velocity = _ghost_velocity(velocity, index)
		ghost.add_to_group(GHOST_GROUP)
		_ghosts.append(ghost)


## "Active locks break immediately" (section 4.6). The signal is the lock owner's
## half; this component drops the seeker's target at the same moment.
func _break_lock() -> void:
	_lock_target = null
	locks_broken.emit()


## "any homing rocket inside FLARE_LURE (450 u) retargets the flare and detonates
## on it", and section 4.1: "a live flare overrides that target". Section 13 pins
## the lure radius and no burn time, so the decoy lives exactly as long as something
## is chasing it: the item's whole effect is the rockets it pulls off the hull, and
## a decoy nobody is chasing is freed (reported as the missing value).
func _deploy_flare() -> void:
	var parent := _world_parent()
	if parent == null:
		return
	if _flare != null and is_instance_valid(_flare):
		_flare.queue_free()
	_flare_rockets.clear()
	_flare = FlareDecoy.new()
	_flare.name = FLARE_NODE_NAME
	parent.add_child(_flare)
	_flare.global_position = global_position
	_flare_age = 0.0
	_lure_rockets()


func _advance_countermeasures(delta: float) -> void:
	if _chaff_remaining > 0.0:
		_chaff_remaining = maxf(_chaff_remaining - delta, 0.0)
		if _chaff_remaining <= 0.0:
			_free_ghosts()
	_flare_age += delta
	if _flare == null:
		return
	if not is_instance_valid(_flare):
		_flare = null
		_flare_rockets.clear()
		return
	_lure_rockets()
	var still_chasing: Array[Node2D] = []
	for shot: Node2D in _flare_rockets:
		if shot != null and is_instance_valid(shot):
			still_chasing.append(shot)
	_flare_rockets = still_chasing
	if _flare_rockets.is_empty() and _flare_age > 0.0:
		_flare.queue_free()
		_flare = null


func _lure_rockets() -> void:
	var tree := get_tree()
	if tree == null:
		return
	if _flare == null or not is_instance_valid(_flare):
		return
	for node: Node in tree.get_nodes_in_group(PROJECTILE_GROUP):
		var shot := node as Node2D
		if shot == null or not is_instance_valid(shot):
			continue
		if _flare_rockets.has(shot):
			continue
		if not shot.has_method(&"retarget") or not shot.has_method(&"family"):
			continue
		if StringName(shot.call(&"family")) != &"missile":
			continue
		if shot.global_position.distance_to(_flare.global_position) > FLARE_LURE:
			continue
		shot.call(&"retarget", _flare)
		_flare_rockets.append(shot)


func _ghost_velocity(hull_velocity: Vector2, index: int) -> Vector2:
	if hull_velocity.is_zero_approx():
		return Vector2.ZERO
	var bearing := hull_velocity.angle() + TAU * float(index) / float(CHAFF_GHOSTS)
	return hull_velocity + Vector2.RIGHT.rotated(bearing) * hull_velocity.length()


func _free_ghosts() -> void:
	for ghost: Node2D in _ghosts:
		if ghost != null and is_instance_valid(ghost):
			ghost.queue_free()
	_ghosts.clear()


## --- Host plumbing --------------------------------------------------------


## The hull this component is mounted on: the ancestor that owns the physics seams
## (`apply_recoil`, `impact_body`). Walked rather than cached so a hull swap needs
## no re-binding.
func _host() -> Node2D:
	var node := get_parent()
	while node != null:
		if node.has_method(&"apply_recoil"):
			return node as Node2D
		node = node.get_parent()
	return null


func _hull_velocity() -> Vector2:
	var host := _host()
	if host != null and host.has_method(&"velocity"):
		var value: Variant = host.call(&"velocity")
		if value is Vector2:
			return value
	return Vector2.ZERO


## Shots are world objects and outlive the trigger: they are parented to the
## running scene (the game root) rather than to the ship's transform, the same
## convention the pickups and the mining laser's shaft use.
func _world_parent() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	var scene := tree.current_scene
	if scene != null:
		return scene
	return tree.root


func _space() -> PhysicsDirectSpaceState2D:
	if not is_inside_tree():
		return null
	var world := get_world_2d()
	if world == null:
		return null
	return world.direct_space_state


## Everything on the host's own bodies is excluded from the aim query, so a shot
## cannot resolve on the hull that fired it.
func _exclusions() -> Array[RID]:
	var out: Array[RID] = []
	var host := _host()
	if host == null:
		return out
	var stack: Array[Node] = [host]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		var body := node as CollisionObject2D
		if body != null:
			var rid := body.get_rid()
			if not out.has(rid):
				out.append(rid)
		for child: Node in node.get_children():
			stack.append(child)
	return out


func _profile() -> Node:
	var loop := Engine.get_main_loop()
	if not loop is SceneTree:
		return null
	var root := (loop as SceneTree).root
	if root == null:
		return null
	return root.get_node_or_null(NodePath(PROFILE_SERVICE))


## --- The family table, read-only (the single owner stays this file) -------


static func row_of(id: StringName) -> Dictionary:
	var row: Variant = FAMILIES.get(id)
	if row is Dictionary:
		return row as Dictionary
	return {}


static func weapon_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for key: Variant in FAMILIES:
		out.append(StringName(key))
	return out


static func family_of(id: StringName) -> StringName:
	var row := row_of(id)
	return StringName(row.get(&"family", &""))


## The cue a family's released shot plays ("" for the one family AUDIO_SPEC states
## none for).
static func fire_cue_of(id: StringName) -> StringName:
	var row: Variant = FIRE_CUES.get(id)
	if row is Dictionary:
		return StringName((row as Dictionary).get(&"cue", &""))
	return &""


## The pool tier a family fires at; -1 leaves the choice to the pool's own mode.
static func fire_take_of(id: StringName) -> int:
	var row: Variant = FIRE_CUES.get(id)
	if row is Dictionary:
		return int((row as Dictionary).get(&"take", -1))
	return -1


static func range_of(id: StringName) -> float:
	return float(row_of(id).get(&"range", 0.0))


static func dps_of(id: StringName) -> float:
	return float(row_of(id).get(&"dps", 0.0))


## The seconds between one released shot and the next: the spec's own where it
## states one (the rocket's 1.2 s), the cannon's burst cycle where it states a
## cycle, and the burst cycle's length for the kinetics that state neither
## (section 4.1 blesses no rate of fire anywhere - reported).
##
## The fallback is family-aware (C2-F4): `KINETIC_INTERVAL` is the cannon's burst
## cycle, a *kinetic* row's own shape, so only a kinetic row may borrow it. A family
## that states no cadence and is not kinetic has none - the mine is `edge`, one per
## trigger pull, and reads 0.0 rather than a borrowed gun cadence. Its damage is the
## row's `alpha`, so `shot_damage` never reads this fallback.
static func interval_of(id: StringName) -> float:
	var row := row_of(id)
	if row.is_empty() or bool(row.get(&"instant", false)):
		return 0.0
	if row.has(&"interval"):
		return float(row[&"interval"])
	var on := float(row.get(&"burst_on", 0.0))
	var off := float(row.get(&"burst_off", 0.0))
	if on > 0.0 or off > 0.0:
		return on + off
	if family_of(id) == &"kinetic":
		return KINETIC_INTERVAL
	return 0.0


## The damage one released shot carries: section 4.1's `alpha` where the row
## states one (rocket 180, mine 180), else `DPS x interval`, so a stream of hits
## delivers exactly the spec's DPS. The instant families carry none (their damage
## is per second, not per shot).
static func shot_damage(id: StringName) -> float:
	var row := row_of(id)
	if row.is_empty() or bool(row.get(&"instant", false)):
		return 0.0
	if row.has(&"alpha"):
		return float(row[&"alpha"])
	return dps_of(id) * interval_of(id)


## The `PlayerState` ammo slot a weapon spends: its own id where the array has one,
## else the pack it shares (`SHARED_PACK`, section 4.3). -1 means no slot at all.
static func ammo_slot(id: StringName) -> int:
	var slot := PlayerStateScript.WEAPONS.find(id)
	if slot >= 0:
		return slot
	var pack: Variant = SHARED_PACK.get(id)
	if pack == null:
		return -1
	return PlayerStateScript.WEAPONS.find(StringName(pack))


## `w_laser` -> `laser`; anything already a weapon id passes through. Unknown ids
## answer `&""` so a typo cannot become a dead group.
static func weapon_id(value: StringName) -> StringName:
	var text := String(value)
	if text.begins_with(MODULE_PREFIX):
		text = text.substr(MODULE_PREFIX.length())
	var id := StringName(text)
	return id if FAMILIES.has(id) else &""


func _is_number(value: Variant) -> bool:
	return value is float or value is int


## --- Decoys ---------------------------------------------------------------


## A chaff ghost (section 4.6): a signature, not a hull - it is never a target, it
## only exists for the lock's re-acquisition rule and the minimap's `&"ghost"` blip.
## It drifts on the velocity the chaff gave it and is freed by the component's
## window, so the window and the blips cannot disagree.
class ChaffGhost extends Node2D:
	var velocity := Vector2.ZERO

	## UI_SPEC section 3.3's chaff blip kind, spelled here because an inner class
	## cannot see the outer class's constants.
	func blip_kind() -> StringName:
		return &"ghost"

	func _physics_process(delta: float) -> void:
		global_position += velocity * delta


## The flare decoy (section 4.6). It is a lure position, not a hazard: rockets
## retarget to it and detonate on it. It has no lifetime of its own because the
## spec pins none - the component frees it when it has pulled nothing.
class FlareDecoy extends Node2D:
	pass
