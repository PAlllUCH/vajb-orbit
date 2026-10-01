class_name AsteroidField
extends Node2D
## One asteroid field: 6-12 rocks in a cluster, the 02 §5 generation rolls, the
## 02 §8 respawn bookkeeping and (engine slice 0) the ruling-17 cleaving.
## Contract: ENGINE_SPEC.md §8 ("4-8 asteroid fields (6-12 rocks each) ... POIs and
## fields re-roll on the single 20-minute `WorldClock`"), §6 (tiered cleaving: a
## depleted Large spawns 2-3 Medium fragments, a Medium 2 Small, a Small bursts into
## 1-2 pickups of its mineral; fragments eject at `current_velocity × 1.2` ±15°;
## yield-0 rocks despawn bare; fragments belong to the same field count), §13; §15;
## docs/gameplay/02_minerals.md §5 (the rolls), §7 and §8 (depletion, respawn and the
## ×0.7 diminishing window); docs/gameplay/11_galactic_map.md §1.1 (the per-sector
## tier weights, which supersede 02 §5's abstract ranges); docs/gameplay/
## 17_coder_handoff.md §4 (one 20-minute accumulator, no per-consumer Timers);
## slice-0 brief §M2 and pinned interface item 5.
##
## **The owner's asteroid ruling (2026-09-21) amends the two cleaving rows quoted
## above** -- "asteroids breaking effects (they should somehow explode, random
## fragments from 2 to 5 moving in random directions)": the split is a random mix of
## fragments, the ejection direction is uniform over the full circle, and every
## depletion reads as a break (FX_SPEC §1.4's explosion at the rock's own centre,
## scaled to it, + S4's rock cue + §4.2 item 8's blast on the neighbours it can
## reach) -- including a yield-0 rock, which still cleaves into nothing. The tick for
## §6/§13/§15 is the owner's; the counts, the scale and the cue are the wave brief's
## table, never this file's own numbers.
##
## **S14 (2026-09-25, 02 §5.2) supersedes that split's shape:** four size classes
## (`XL > L > M > S`) and a child set rolled per kind from `OreTuning.split_mix`
## (rule 1), plus the spawn mix S 40 / M 32 / L 20 / XL 8 (rule 4). The 2026-09-21
## ruling's two other halves are untouched: the direction is still the full circle
## and a break is still the rock's death.
##
## **S22.5 (2026-09-30, 02 §5.3) adds the rock's own life and the chip splinter:**
## every rock this file builds (originals, cleave children and splinters) rolls its
## `toughness` off the field's seeded `rng` (A1) and a non-cracking gun chip on an
## L/XL rock rolls `splinter_chance` to shed one S-class splinter (A4), capped per
## rock by `splinter_interval`. The splinter is a field member born on the same
## ring/cone/kick carrier as a cleave child, so it lives, blocks and dies like any
## other debris; it carries `bore 0` and pays nothing, so Rule A still holds.
##
## Consumer contract — W4's `game/sector.gd` binds this script duck-typed, so the
## three names below are the frozen handoff:
##   * `setup(config)` with `{&"tier_weights": Dictionary, &"rocks": int,
##     &"seed": int}` (only `tier_weights` is required; a missing `rocks` rolls
##     6-12 here, and a zero `seed` randomizes),
##   * `is_depleted() -> bool`,
##   * `respawn(now := -1) -> bool`, called on each elapsed 20-minute band.
##
## The clock is read, never owned: no Timer lives here, and the 20-minute cadence
## is the band itself (ENGINE_SPEC §8, 17 §4), not a second schedule.
##
## **Slice 0's split of labour:** `asteroid.gd` owns the cleaving *rules* (the size
## class, the split table, the ejection arithmetic); this file owns the *spawning*
## and the break's *read* (the FX, the cue and the blast), because it holds the
## generation RNG, the field count and the pickups' world parent. Fragments are built
## by the same code path as the field's own rocks, so they are field members from
## birth: `rocks()`, `rock_count()` and `is_depleted()` see them, and a field with
## live fragments is not depleted (no respawn fires while a cleave is still being
## chewed through).

const AsteroidScript := preload("res://game/asteroid.gd")
const MineralCatalogScript := preload("res://game/mineral_catalog.gd")
const Clock := preload("res://autoload/world_clock.gd")

## The break's FX and cue come from the files that own them (FX_SPEC §1.4's explosion
## sheet through `projectile.gd`'s sheet helper, its S4 rock cue through the same
## `play_impact` door, and `impact.gd`'s shockwave helper for the blast). Reached by
## path, not by the global class name, for the same reason `asteroid.gd` reaches
## `ship_fit.gd` and `weapons.gd` that way: the global name only resolves once the
## editor has scanned the project.
const ProjectileScript := preload("res://game/projectile.gd")
const ImpactScript := preload("res://game/impact.gd")

## S13's one live balance surface (01 §5.6, 02 §5.1 Rule A). The shatter payout and
## the cleave handoff read their numbers here, so the F1 overlay can tune them live.
const OreTuningScript := preload("res://game/ore_tuning.gd")

## `Pickup` is loaded lazily, exactly as the mining laser loads it: this field must
## be able to build, roll and cleave a rock field whether or not the pickup leaf
## script compiles, and a `preload` would make one bad leaf path kill the whole
## field. A missing/failed pickup script costs the burst's cargo, never the field.
const PICKUP_SCRIPT := "res://game/pickup.gd"

## ENGINE_SPEC §8's rocks-per-field band, and the fallback count when a caller
## hands in no `rocks` value.
const FIELD_ROCKS_MIN := 6
const FIELD_ROCKS_MAX := 12

## Cluster radius, and the ring geometry inside it. No spec number exists for a
## field's footprint: 400 u is this file's one placement value, small against the
## 10 000 u arena (§13 `SECTOR_SIZE`) and wide enough that twelve rocks of the
## largest look (132 u across) do not interpenetrate. Jitter values are the same
## kind of placement constant. Reversal is one edit.
const FIELD_RADIUS := 400.0
const FIELD_INNER_FRACTION := 0.35
const FIELD_ANGLE_JITTER := 0.25

## 02 §8's diminishing window: an asteroid rolled while the field is inside the
## five minutes after its last respawn carries ×0.7 yield. 01 §5.5 names the
## multiplier's purpose ("mine the same rock forever" must not pay).
const DIMINISHING_WINDOW_SECONDS := 300
const DIMINISHING_YIELD_MULT := 0.7

## Ruling 17's fragment placement: fragments land on a spread ring around the dying
## rock, at the dying rock's own radius plus the fragment's, so a cleave never
## spawns two bodies inside one another. The ring's angular jitter is the same kind
## of placement constant as the cluster's (`FIELD_ANGLE_JITTER`); no spec number
## exists for a spawn ring and none is invented as a gameplay value.
const FRAGMENT_ANGLE_JITTER := 0.25

## 18 §13's Rock-rock contact row (S22.7, owner tick R3): a placed rock -- a field
## spawn or a cleave sibling -- may never land closer than the two collision radii
## plus this margin, so turning the rock-rock pair on cannot shove overlapping bodies
## apart at spawn or at a split. The margin is §13's own number; `PLACEMENT_RETRIES`
## is the pass's mechanics, not a gameplay value: how many re-rolls a blocked
## candidate gets on the field's seeded RNG before the widest-gap candidate wins
## (a saturated field must still place). Reversal: delete the pass and these two
## constants -- the pure ring rolls of record.
const PLACEMENT_MARGIN := 8.0
const PLACEMENT_RETRIES := 8

## CONTRACTS §14's "Fragment burst" (the owner's "when breaking asteroids they
## should move when exploding"): every fragment also carries this much speed along
## its own outward radial -- **the placement direction above**, rock centre to spawn
## point, so no second direction is invented. It is additive on top of §5's shape
## (`eject_velocity()` = the parent's velocity × 1.2, rolled over
## `FRAGMENT_EJECT_CONE_DEG`): a rock at rest ejects at 0.0 today and now bursts
## visibly, while a drifting rock keeps its inherited component exactly. The field
## owns it because the field is what rolls the spawn point; the rock keeps the
## shape's half. Reversal: `0.0` is today exactly (measured before the change: a
## resting rock's four fragments all read radial 0.000 u/s).
const FRAGMENT_OUTWARD_KICK := 150.0
##
## S22.7 (18 §13's Ejection row as amended): the fragment's WHOLE ejection vector
## (this kick plus the inherited `×1.2` shape) then scales by the per-child jitter
## roll × the mass weighting read off `Asteroid.FRAGMENT_SPEED_JITTER` /
## `FRAGMENT_MASS_SPEED_EXP`, so a split never leaves at one speed.

## 02 §7's floating pickup prop and the group `Pickup.setup` joins. The burst's ore
## is placed on the same ring as the fragments, for the same reason.
const PICKUP_GROUP: StringName = &"pickup"
const PICKUP_NAME: StringName = &"BurstPickup"

## 02 §8's per-field stamps, in WorldClock seconds (the same basis as the sector's
## 20-minute band, so the window survives a process restart).
var last_depleted_time: int = 0
var last_respawn_time: int = 0

## The generation RNG. A caller that wants reproducible rocks seeds it through
## `setup(config)`'s `&"seed"`; a probe may also read it back.
var rng := RandomNumberGenerator.new()

## S13_BRIEF §2 rule 3's float credit, per field and per cycle: a shatter's owed ore
## accumulates here and pays whole pickup units when it crosses 1.0, so a sub-unit
## reserve is neither lost nor ever paid as a fractional pickup. `setup()` and
## `respawn()` clear it with the rocks they clear (S13-R1's F1), so one cycle's
## leftover credit can never pay against the next cycle's rocks.
var _ore_credit := 0.0

var _tier_weights: Dictionary = {}
var _rocks: Array[Node2D] = []
var _rocks_per_cycle := FIELD_ROCKS_MIN
var _built := false
## Fragment names come from one counter, so a cleave's children can never collide
## with a rock's name or with an earlier cleave's.
var _spawned := 0
## The lazily loaded pickup leaf and its one-shot warning latch.
var _pickup: GDScript = null
var _pickup_warned := false


## Builds the field. `config` is W4's payload: `&"tier_weights"` (11 §1.1's weights
## for the sector, passed straight from `SectorRegistry`), `&"rocks"` (the sector's
## 6-12 roll) and `&"seed"`. A virgin field rolls at full yield: the ×0.7 window
## belongs to respawns only (02 §8, 01 §5.5).
func setup(config: Dictionary = {}) -> void:
	_tier_weights = _integer_keys(config.get(&"tier_weights", {}))
	rng = RandomNumberGenerator.new()
	var seed_value := int(config.get(&"seed", 0))
	if seed_value != 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	var count := int(config.get(&"rocks", 0))
	if count <= 0:
		count = rng.randi_range(FIELD_ROCKS_MIN, FIELD_ROCKS_MAX)
	_rocks_per_cycle = clampi(count, FIELD_ROCKS_MIN, FIELD_ROCKS_MAX)
	_clear_rocks()
	_ore_credit = 0.0
	_roll_rocks(_rocks_per_cycle)
	_built = true


## True once every rock has cracked (02 §8: a fully depleted field is the one that
## respawns). A sector may call `respawn()` unconditionally: this is its guard.
func is_depleted() -> bool:
	if not _built:
		return false
	return rocks().is_empty()


## Re-rolls the field: fresh minerals and yields under 02 §5's rules for the same
## rock count (02 §8's "a respawned field is a fresh roll"). Stamps
## `last_respawn_time` first, so the new rocks roll inside the ×0.7 window.
##
## Returns false when the field still has rocks. `now` defaults to the WorldClock
## and exists so probes and review sheets can drive the window without waiting; it
## is the one reading that stamps `last_respawn_time` **and** the one the cycle's
## yield roll is taken against (L73), so a caller that stamps a cycle rolls the
## ×0.7 band it just opened instead of whatever the wall clock says.
func respawn(now: int = -1) -> bool:
	if not is_depleted():
		return false
	var stamp := now if now >= 0 else Clock.now()
	last_respawn_time = stamp
	_clear_rocks()
	_ore_credit = 0.0
	_roll_rocks(_rocks_per_cycle, stamp)
	return true


## 02 §8's window as a query: true while the field sits inside the five minutes
## after its last respawn.
func diminishing_active(now: int = -1) -> bool:
	if last_respawn_time <= 0:
		return false
	return (now if now >= 0 else Clock.now()) - last_respawn_time < DIMINISHING_WINDOW_SECONDS


## The live rocks, in spawn order. Cracking frees a rock, so freed entries are
## pruned here; `Sector` never calls this (it blips one per field, 11 §3).
func rocks() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for rock: Node2D in _rocks:
		if is_instance_valid(rock):
			out.append(rock)
	return out


func rock_count() -> int:
	return rocks().size()


## The rock count this field rolls per cycle (W4's roll, held across respawns).
func rocks_per_cycle() -> int:
	return _rocks_per_cycle


func tier_weights() -> Dictionary:
	return _tier_weights.duplicate()


## `now` is the caller's own stamp when it has one (`respawn`'s, L73) and the
## WorldClock otherwise; it reaches `_rolled_yield` so the cycle's window and the
## cycle's yields are read off one clock.
func _roll_rocks(count: int, now: int = -1) -> void:
	if _tier_weights.is_empty():
		## Defensive only: a field with no weights cannot roll a tier. W4 always
		## hands in `SectorRegistry`'s table, which is 11 §1.1.
		push_warning("AsteroidField: empty tier weights, field left bare")
		return
	for index in count:
		var tier := _roll_tier()
		var mineral: Dictionary = MineralCatalogScript.roll_mineral(tier, rng)
		var mineral_id := StringName(mineral.get(&"id", &""))
		if mineral_id == &"":
			push_warning("AsteroidField: unknown tier %d, rock %d skipped" % [tier, index])
			continue
		_spawn_rock(index, mineral_id, tier, _rolled_yield(tier, now))


## 02 §5's yield roll (`base × variance`) with 02 §8's ×0.7 window applied, exactly
## as the field roll has always applied it. One helper, so a rock the field rolls and
## a fragment a cleave rolls cannot drift apart. `now` is the caller's stamp when it
## has one (`respawn`'s, L73) and the WorldClock otherwise.
func _rolled_yield(tier: int, now: int = -1) -> int:
	var units := MineralCatalogScript.roll_yield(tier, rng)
	var multiplier := _yield_multiplier(now)
	if multiplier < 1.0:
		units = maxi(1, roundi(float(units) * multiplier))
	return units


func _spawn_rock(index: int, mineral_id: StringName, tier: int, bore: int) -> void:
	## S13: `_rolled_yield` returns the rock's own original yield, which `setup`
	## splits. The extractable half is what extraction realises; the reserve is the
	## rest, read back at the shatter. `bore` is passed so `_bore_ore` is the exact
	## roll rather than a value reconstructed from a rounded extractable.
	##
	## S14 (02 §5.2, S14_BRIEF §2 rule 4): the size class is now a roll of its own,
	## taken here from `OreTuning.spawn_size_weights` (S 40 / M 32 / L 20 / XL 8)
	## instead of leaving `SIZE_ANY` to draw uniformly over every look row. The look
	## inside that class stays `Asteroid._roll_look`'s uniform three-silhouette pick,
	## so the sprite can no longer decide the class.
	var rock := _new_rock(
		"Rock%d" % (index + 1), mineral_id, tier,
		AsteroidScript.extractable_units(bore), _roll_size(), false, float(bore)
	)
	## §13's minimum-separation pass (S22.7 R3): the candidate rolls against every
	## rock the cycle has already placed -- field-local positions on both sides.
	var avoid: Array[Dictionary] = []
	for placed: Node2D in rocks():
		if placed != rock:
			avoid.append({
				&"pos": placed.position,
				&"radius": float(placed.call(&"world_radius")),
			})
	rock.position = _rock_position(
		index, float(rock.call(&"world_radius")), avoid
	)


## S14 (02 §5.2, S14_BRIEF §2 rule 4): the size class a spawned rock rolls, read
## live from `OreTuning.spawn_size_weights` on the field's own seeded `rng`. Keys are
## the `Asteroid.SIZE_*` classes; the weights are accumulated in ascending class
## order (S, M, L, XL), so the table reads as its own 40/32/20/8 row no matter what
## order a config wrote its keys in. `_roll_tier`'s arithmetic, one table over.
func _roll_size() -> int:
	var weights := _integer_keys(OreTuningScript.spawn_size_weights)
	var total := 0
	for weight: Variant in weights.values():
		total += int(weight)
	if total <= 0:
		## Defensive only (the S14 twin of `_roll_tier`'s empty-table guard): the
		## smallest class is the answer that cannot make a rock unbreakable.
		return AsteroidScript.SIZE_SMALL
	var roll := rng.randi_range(1, total)
	var accumulated := 0
	var classes: Array = weights.keys()
	classes.sort()
	for size_class: Variant in classes:
		accumulated += int(weights[size_class])
		if roll <= accumulated:
			return int(size_class)
	return AsteroidScript.SIZE_SMALL


## The one construction path for every rock in the field, originals and fragments
## alike: named, parented, initialised and connected before it is measured, with its
## S22.5 toughness rolled on the way in (02 §5.3 A1). The connect carries the rock
## itself (`bind`), because the `cracked` signal is the
## pinned bare signature and the field is what needs to know which rock died. The
## counter increments last, so a caller that names its child from `_spawned + 1`
## gets a unique name every time.
func _new_rock(
	node_name: String,
	mineral_id: StringName,
	tier: int,
	units: int,
	size_class: int,
	defer_shape: bool = false,
	bore: float = -1.0
) -> RigidBody2D:
	var rock := AsteroidScript.new() as RigidBody2D
	rock.name = node_name
	add_child(rock)
	## S22.5 (02 §5.3 A1): the roll comes off the field's own seeded RNG, so two
	## fields built with one seed carry identical toughnesses and a suite can
	## reproduce any reading without guessing.
	var toughness := rng.randf_range(
		OreTuningScript.toughness_min, OreTuningScript.toughness_max
	)
	rock.call(&"setup", mineral_id, tier, units, size_class, defer_shape, bore, toughness)
	rock.connect(&"cracked", _on_rock_cracked.bind(rock))
	## S22.5 (02 §5.3 A4): a non-cracking gun chip asks the field for its roll.
	rock.connect(&"gun_chipped", _on_gun_chipped.bind(rock))
	_rocks.append(rock)
	_spawned += 1
	return rock


## Ruling 17, on the way out: a depleted rock reads as a break (the owner's
## 2026-09-21 asteroid ruling -- it "should somehow explode") and then cleaves into
## fragments, or, at the small end, bursts into pickups, before it is freed. The
## `cracked` emission is synchronous inside `apply_work`, so the rock is still valid
## here and its velocity and radius are still readable -- which is what `× 1.2` and
## the explosion's own scale are measured against.
func _on_rock_cracked(rock: Node2D) -> void:
	_rocks.erase(rock)
	_break_read(rock)
	_cleave(rock)
	if _rocks.is_empty():
		last_depleted_time = Clock.now()


## Ruling 17's "a yield-0 rock still cracks and despawns bare" read the *cleaving*
## half; the owner's 2026-09-21 ruling makes the break read the rock's **death**, not
## an ore event, so every path through here reads the same way -- a Large that
## cleaves, a Small that bursts pickups, and a rock that rolled no ore at all. It
## runs *before* `_cleave`, so the read belongs to the rock and not to its children:
## the fragments are born after the blast and are not shoved by their parent's death.
##
## Three pieces, all of them existing owners' work:
##   1. FX_SPEC §1.4's five-frame explosion at the rock's own centre, sized to the
##      rock (`Projectile.spawn_rock_break` -- §7.3's one-shot wiring: the sheet
##      plays once and frees itself);
##   2. S4's rock cue, through the same `play_impact` door a bolt's rock hit uses and
##      the pool row `AudioManager.CUE_POOLS` now carries (L53: the four takes were
##      on disk with no row);
##   3. §4.2 item 8's blast on the bodies the break is nearest.
func _break_read(rock: Node2D) -> void:
	var centre: Vector2 = rock.global_position
	var diameter := 2.0 * maxf(float(rock.call(&"world_radius")), 0.0)
	ProjectileScript.spawn_rock_break(_world_parent(), centre, diameter)
	ProjectileScript.play_impact(self, ProjectileScript.IMPACT_KIND_ROCK)
	_push_neighbours(centre)


## §4.2 item 8's outward impulse over `EXPLOSION_WINDOW`, on the bodies this break
## can actually reach: the rocks still standing in this field (a rock that breaks
## nudges its neighbours) and the hulls the tree exposes, walked to their physics body
## through `impact_body` exactly as `game.gd`'s wreck blast walks to the player's. The
## push itself is `Impact.apply_shockwave`; `I(d) = P0 / (1 + d^2)` is its own range,
## so the gate is the same floor `projectile.gd`'s own blast query stops at
## (`MIN_SHOCKWAVE_IMPULSE`, about 63 u) and no radius is invented here. A body past
## that floor is left alone rather than handed a blast it cannot feel.
func _push_neighbours(centre: Vector2) -> void:
	for body: Variant in _blast_targets():
		var rigid := body as RigidBody2D
		if rigid == null:
			continue
		var distance: float = rigid.global_position.distance_to(centre)
		if ImpactScript.explosion_impulse(distance) < ProjectileScript.MIN_SHOCKWAVE_IMPULSE:
			continue
		ImpactScript.apply_shockwave(centre, rigid, ImpactScript.EXPLOSION_WINDOW)


## The bodies a break is offered to: this field's live rocks, plus every hull in the
## tree's two hull groups, resolved through `impact_body` when the ship exposes one
## (both shipped hulls do). Rocks are the near ones by construction -- the field's own
## 400 u cluster -- and the ships are filtered by the impulse floor above, so a sector
## whose hulls are thousands of units away pays two group lookups and nothing else.
func _blast_targets() -> Array:
	var out := []
	for rock: Node2D in rocks():
		out.append(rock)
	if not is_inside_tree():
		return out
	var tree := get_tree()
	if tree == null:
		return out
	for group: StringName in [ProjectileScript.PLAYER_GROUP, ProjectileScript.NPC_GROUP]:
		for node: Node in tree.get_nodes_in_group(group):
			var body: Variant = node
			if node.has_method(&"impact_body"):
				body = node.call(&"impact_body")
			if body is RigidBody2D:
				out.append(body)
	return out


## §13's "Fragment split", as amended by the owner's **S14 debris ruling**
## (2026-09-25, 02 §5.2): the child set is rolled per size kind and independently --
## `XL -> L 1-3, M 2-4, S 2-5`; `L -> M 1-3, S 2-4`; `M -> S 1-3`; `S -> none` --
## from `OreTuning.split_mix`, so an XL reads as debris rather than one ring of one
## kind. Every child is strictly smaller than its parent, so the cascade terminates
## at the Small end, whose cleave *is* the pickup burst. A yield-0 **original**
## carries nothing to break and cleaves into nothing (§6/§15, ruling 17); S16
## (02 §5.2 ter) marks every fragment this cleave builds, so debris re-splits per
## its own size class whatever its bore.
##
## S13 attributes the shatter (S13_BRIEF §2 rule 3). A **mining** shatter pays the
## full reserve: a Small as pickups, an M/L/XL by handing its children the reserve as
## their own extractable, split across the **whole mixed child set** and with **no
## fresh roll** - each child's `_bore_ore` is its whole-unit share, so the family
## realises the root's `_bore_ore` and a field mints nothing, however the dice fall.
## A **gun** shatter pays at most `gun_burst_share x _bore_ore` as pickups and the
## excess reserve burns; an M/L/XL still leaves physical fragments, but they carry no
## ore (the reserve is spent).
func _cleave(rock: Node2D) -> void:
	if not bool(rock.call(&"cleaves")):
		return
	var size_class: int = int(rock.call(&"size_class"))
	var from_mining := bool(rock.call(&"shatter_from_mining"))
	var reserve := float(rock.call(&"reserve_units"))
	var owed := reserve
	if not from_mining:
		owed = minf(reserve, OreTuningScript.gun_burst_share * float(rock.call(&"bore_ore")))
	if size_class == AsteroidScript.SIZE_SMALL:
		_pay_burst(rock, owed)
		return
	if not from_mining:
		## The gun's capped payout lands here; its fragments below are debris.
		_pay_burst(rock, owed)
	var children := _roll_children(size_class)
	if children.is_empty():
		return
	var count := children.size()
	## S13 (02 §5.1 Rule A) as S14 re-pins it: the reserve is split across the whole
	## rolled child set, and a child's size never weights its share.
	var shares: Array = []
	if from_mining:
		shares = _unit_shares(roundi(reserve), count)
	var velocity: Vector2 = rock.call(&"eject_velocity")
	var origin: Vector2 = rock.global_position
	var ring := maxf(float(rock.call(&"world_radius")), 0.0)
	var mineral_id := StringName(rock.get(&"mineral_id"))
	var tier := int(rock.get(&"tier"))
	var siblings: Array[Node2D] = []
	for index in count:
		var units: int = int(shares[index]) if from_mining else 0
		var fragment := _new_rock(
			"Fragment%d" % (_spawned + 1),
			mineral_id,
			tier,
			units,
			int(children[index]),
			true,
			float(units)
		)
		## S16 (02 §5.2 ter): every rock this cleave builds is debris, so it
		## re-splits per its own size class whatever its bore. Only debris is
		## marked (here and in `_spawn_splinter`): an original stays unmarked
		## and keeps ruling 17's yield-0 law.
		fragment.call(&"mark_cleave_child")
		var angle := TAU * float(index) / float(count)
		angle += rng.randf_range(-FRAGMENT_ANGLE_JITTER, FRAGMENT_ANGLE_JITTER)
		_deploy_debris(fragment, origin, ring, angle, velocity, siblings)
		siblings.append(fragment)


## The one placement and ejection arithmetic every debris body rides: a `_cleave`
## child and an S22.5 splinter alike (02 §5.3 A4's "same cone/carrier"). `angle` is
## the caller's placement radial (the cleave's ring slot plus its jitter, or the
## splinter's own roll) and `velocity` is the shape's inherited half
## (`Asteroid.eject_velocity()`, the parent's velocity x 1.2). The cone roll stays
## here, on the field's own seeded RNG, exactly where the shipped block took it, so
## the cleave's draw order is unchanged.
##
## S22.6 (18 §13's Rock drift damping row): every body placed here also takes
## `Asteroid.apply_fragment_damp()` -- `FRAGMENT_LINEAR_DAMP` 0.25, replacing its own
## body damp -- because this is the one point both debris paths pass through. It is
## the last write to the body, so the parent's `LINEAR_DAMP` is gone before the child
## is ever measured.
##
## S22.7 (18 §13's Rock-rock contact row, tick R3): `siblings` -- the cleave's
## already-placed children -- hold their rolled slots while a blocked candidate
## re-rolls its angle along the ring system (bounded by `PLACEMENT_RETRIES`), and a
## candidate that no angle clears slides out along its own placement ray to the exact
## distance that clears every sibling by the margin. The slide is the pass's
## load-bearing half: at the pinned per-kind ring distances an XL's fullest mixed
## brood (3L + 4M + 5S) needs ~450 deg of angular clearance around one centre, so no
## angle-only search can hold the invariant -- the own-ray slide can, for every
## brood. A splinter has no siblings and never enters the pass.
##
## S22.7 (18 §13's Ejection row as amended, ticks S1+S2): the child's WHOLE ejection
## vector -- the inherited `×1.2` part and the outward kick together -- then scales
## by a per-child jitter roll times the mass weighting
## `pow(ROCK_MASS_M / child_mass, FRAGMENT_MASS_SPEED_EXP)`, so splinters fly and
## boulders lumber. Reversal: drop the scale (and the sibling pass).
func _deploy_debris(
	child: Node2D, origin: Vector2, ring: float, angle: float, velocity: Vector2,
	siblings: Array[Node2D] = []
) -> void:
	child.call(&"apply_fragment_damp")
	var distance := ring + float(child.call(&"world_radius"))
	if not siblings.is_empty():
		var avoid: Array[Dictionary] = []
		for sibling: Node2D in siblings:
			avoid.append({
				&"pos": sibling.global_position,
				&"radius": float(sibling.call(&"world_radius")),
			})
		var placement := _sibling_placement(
			origin, distance, float(child.call(&"world_radius")), angle, avoid
		)
		angle = placement.x
		distance = placement.y
	var outward := Vector2.RIGHT.rotated(angle)
	## One direction, two uses: this is the placement radial, and §14's kick rides
	## the same vector, so a fragment always leaves along the ray it was born on.
	child.global_position = origin + outward * distance
	var weight := pow(
		AsteroidScript.ROCK_MASS_M / (child as RigidBody2D).mass,
		AsteroidScript.FRAGMENT_MASS_SPEED_EXP
	)
	var scale := weight * rng.randf_range(
		AsteroidScript.FRAGMENT_SPEED_JITTER.x, AsteroidScript.FRAGMENT_SPEED_JITTER.y
	)
	child.linear_velocity = (
		velocity.rotated(
			deg_to_rad(
				rng.randf_range(
					-AsteroidScript.FRAGMENT_EJECT_CONE_DEG,
					AsteroidScript.FRAGMENT_EJECT_CONE_DEG
				)
			)
		) + outward * FRAGMENT_OUTWARD_KICK
	) * scale


## The debris ring's half of the placement pass. The first candidate is the caller's
## slot at the parent-clearance distance; while it is blocked, candidates re-roll
## their angle on the field's seeded RNG (bounded, like `_rock_position`), each taken
## at its own exact clear distance along its ray. The winner is the first candidate
## that is clear at the floor, else the one needing the least outward slide. Returns
## `(angle, distance)`.
func _sibling_placement(
	origin: Vector2, floor_distance: float, radius: float, angle: float, avoid: Array[Dictionary]
) -> Vector2:
	var best_angle := angle
	var best_distance := _clear_distance(origin, floor_distance, radius, angle, avoid)
	for attempt in PLACEMENT_RETRIES:
		if is_equal_approx(best_distance, floor_distance):
			break
		var candidate := rng.randf_range(0.0, TAU)
		var needed := _clear_distance(origin, floor_distance, radius, candidate, avoid)
		if is_equal_approx(needed, floor_distance):
			return Vector2(candidate, floor_distance)
		if needed < best_distance:
			best_distance = needed
			best_angle = candidate
	return Vector2(best_angle, best_distance)


## The least distance along the `angle` ray from `origin` that a body of `radius`
## needs to clear every placed entry by `PLACEMENT_MARGIN` -- the floor distance when
## the pure ring slot already does, else the binding entry's exact quadratic root
## (`d = d_j·cosΔ + sqrt(need² − d_j²·sin²Δ)`, the ray's outward exit from that
## entry's exclusion disc). Exact arithmetic, no RNG, so a slide is reproducible.
func _clear_distance(
	origin: Vector2, floor_distance: float, radius: float, angle: float, avoid: Array[Dictionary]
) -> float:
	var distance := floor_distance
	var ray := Vector2.RIGHT.rotated(angle)
	for entry: Dictionary in avoid:
		var offset: Vector2 = entry[&"pos"] - origin
		var need := radius + float(entry[&"radius"]) + PLACEMENT_MARGIN
		var across := absf(offset.cross(ray))
		if across >= need:
			continue
		distance = maxf(
			distance,
				offset.dot(ray) + sqrt(need * need - across * across)
		)
	return distance


## S22.5 (02 §5.3 A4): a gun hit that did not crack an L/XL rock rolls
## `OreTuning.splinter_chance` to shed one splinter, capped at one per rock per
## `OreTuning.splinter_interval` seconds. The cap is asked first, so a hit inside the
## window consumes no roll; every roll is the field's own seeded RNG. S/M rocks shed
## none and a cracking hit never reaches here (its break is `cracked`).
func _on_gun_chipped(rock: Node2D) -> void:
	var kind: int = int(rock.call(&"size_class"))
	if kind != AsteroidScript.SIZE_LARGE and kind != AsteroidScript.SIZE_XL:
		return
	var now_ms := Time.get_ticks_msec()
	if not bool(rock.call(&"splinter_ready", now_ms)):
		return
	if rng.randf() >= OreTuningScript.splinter_chance:
		return
	rock.call(&"mark_splinter_shed", now_ms)
	_spawn_splinter(rock)


## S22.5 (02 §5.3 A4): the splinter itself, a real S-class body rather than a
## particle. Born `bore 0` (Rule A: it pays nothing at any shatter) with A3's S budget
## by class, marked as debris like a `_cleave` child, and placed on the same
## ring/cone/kick carrier. Its S class is why it never splits further: the §5.2 bis
## table gives S no children, so its own crack is the bare break.
func _spawn_splinter(rock: Node2D) -> void:
	var splinter := _new_rock(
		"Splinter%d" % (_spawned + 1),
		StringName(rock.get(&"mineral_id")),
		int(rock.get(&"tier")),
		0,
		AsteroidScript.SIZE_SMALL,
		true,
		0.0
	)
	splinter.call(&"mark_cleave_child")
	var origin: Vector2 = rock.global_position
	var ring := maxf(float(rock.call(&"world_radius")), 0.0)
	var velocity: Vector2 = rock.call(&"eject_velocity")
	var angle := rng.randf_range(0.0, TAU)
	_deploy_debris(splinter, origin, ring, angle, velocity)


## S14's child roll (02 §5.2, S14_BRIEF §2 rule 1): for each `(child_kind, range)`
## of `OreTuning.split_mix[parent_kind]`, in the table's own order, roll `count` on
## the **field's seeded `rng`** and append that many of the kind. The flat list is
## the whole child set - the ring placement and the reserve split both work across
## it, so a mixed set is one debris spread and not one ring per kind. An empty list
## means the table gives this parent no children (a Small), and a row whose value is
## not a count range is skipped rather than allowed to roll nothing.
func _roll_children(parent_kind: int) -> Array[int]:
	var out: Array[int] = []
	var mix: Dictionary = OreTuningScript.split_mix.get(parent_kind, {})
	for child_kind: Variant in mix.keys():
		var span: Variant = mix[child_kind]
		if not span is Vector2i:
			continue
		var pair: Vector2i = span
		if pair.x < 0 or pair.y < pair.x:
			continue
		for _roll in rng.randi_range(pair.x, pair.y):
			out.append(int(child_kind))
	return out


## S13's shatter payout (S13_BRIEF §2 rule 3): a shatter's owed ore accumulates in
## the field's float credit and pays whole pickups - never a fractional pickup -
## bounded per burst by `OreTuning.pickup_burst`. The pickups are the same floating
## cargo a mining cycle spawns (02 §7), parented to the world rather than the field
## so a respawn cannot free the player's ore.
func _pay_burst(rock: Node2D, owed: float) -> void:
	if owed <= 0.0:
		return
	_ore_credit += owed
	var script := _pickup_script()
	if script == null:
		return
	var item := MineralCatalogScript.ore_id(StringName(rock.get(&"mineral_id")))
	if item == &"":
		return
	## Whole units only: floor the credit (a hair of slack so an exact 1.0 crosses),
	## then cap this burst by the tuned `pickup_burst` roll.
	var credit := floori(_ore_credit + 0.000001)
	var burst := rng.randi_range(OreTuningScript.pickup_burst.x, OreTuningScript.pickup_burst.y)
	var count := mini(maxi(credit, 0), maxi(burst, 0))
	if count <= 0:
		return
	_ore_credit -= float(count)
	var origin: Vector2 = rock.global_position
	var ring := maxf(float(rock.call(&"world_radius")), 0.0)
	var parent := _world_parent()
	for index in count:
		var pickup := script.new() as Node2D
		pickup.name = PICKUP_NAME
		parent.add_child(pickup)
		var angle := TAU * float(index) / float(count)
		angle += rng.randf_range(-FRAGMENT_ANGLE_JITTER, FRAGMENT_ANGLE_JITTER)
		pickup.global_position = origin + Vector2.RIGHT.rotated(angle) * ring
		pickup.call(&"setup", item, 1, false)


## Splits a whole-unit reserve across `count` children as evenly as an integer
## allows; the remainder lands on the first children, so the sum is exact and no
## child is handed more than its own share by more than the rounding the reserve
## itself already carries.
func _unit_shares(total: int, count: int) -> Array[int]:
	var out: Array[int] = []
	if count <= 0:
		return out
	var whole := maxi(total, 0)
	var base := whole / count
	var remainder := whole % count
	for index in count:
		out.append(base + (1 if index < remainder else 0))
	return out


## The pickup leaf, loaded once and remembered. A script that fails to compile
## (a stale asset path in it, as the naming re-layout left behind) is reported once
## per field, not once per burst: the rock field keeps working either way.
## `can_instantiate()` is the real gate — a script that failed to compile still
## loads as a `GDScript` object and only fails at `new()`.
func _pickup_script() -> GDScript:
	if _pickup != null:
		return _pickup
	if not ResourceLoader.exists(PICKUP_SCRIPT):
		_report_missing_pickup("does not exist")
		return null
	var script := load(PICKUP_SCRIPT) as GDScript
	if script == null or not script.can_instantiate():
		_report_missing_pickup("failed to compile")
		return null
	_pickup = script
	return _pickup


func _report_missing_pickup(reason: String) -> void:
	if _pickup_warned:
		return
	_pickup_warned = true
	push_warning(
		"AsteroidField: %s %s; a small rock's pickup burst spawns nothing"
		% [PICKUP_SCRIPT, reason]
	)


## The break read's FX parent and the pickups' parent: `current_scene` is the running
## scene (the same parent the mining laser's pickups use), and the tree root is the
## fallback for a field outside a scene. A field that is not in a tree at all (a probe,
## or `tests/test_engine2_cleaving.gd`'s detached fixture) parents to itself, which is
## the only answer that keeps its effects and its ore together - and it is why this
## checks `is_inside_tree()` rather than asking `get_tree()`, which the engine reports
## as an error on a node that has no tree.
func _world_parent() -> Node:
	if not is_inside_tree():
		return self
	var tree := get_tree()
	if tree == null:
		return self
	return tree.current_scene if tree.current_scene != null else tree.root


func _clear_rocks() -> void:
	for rock: Node2D in _rocks:
		if is_instance_valid(rock):
			rock.queue_free()
	_rocks.clear()


## The ×0.7 window, evaluated at roll time against `last_respawn_time` — the
## literal 02 §8 implementation note. A virgin field (no stamp) rolls at full
## yield; every respawn stamps first, so a respawned field's rocks roll at ×0.7.
## `now` is the caller's own stamp when the whole cycle hangs off one (`respawn`'s,
## L73) and the WorldClock otherwise, which is every other caller.
## See the W3 report for the reading of 02 §8's note and its reversal path.
func _yield_multiplier(now: int = -1) -> float:
	if last_respawn_time <= 0:
		return 1.0
	if (now if now >= 0 else Clock.now()) - last_respawn_time >= DIMINISHING_WINDOW_SECONDS:
		return 1.0
	return DIMINISHING_YIELD_MULT


## 11 §1.1's weights, rolled exactly as `MineralCatalog.roll_tier` rolls its
## per-sector table (same tier order 1-4, same accumulate), because this field is
## handed the weights rather than a sector number.
func _roll_tier() -> int:
	var total := 0
	for weight: Variant in _tier_weights.values():
		total += int(weight)
	if total <= 0:
		return 0
	var roll := rng.randi_range(1, total)
	var accumulated := 0
	for tier: int in [1, 2, 3, 4]:
		if not _tier_weights.has(tier):
			continue
		accumulated += int(_tier_weights[tier])
		if roll <= accumulated:
			return tier
	return 0


## An even angular spread at a jittered radius, guarded by §13's minimum-separation
## pass (S22.7 R3): a candidate that lands inside an already-placed rock's clearance
## (`r_i + r_j + PLACEMENT_MARGIN`) is re-rolled on the field's own seeded RNG --
## bounded by `PLACEMENT_RETRIES`, so a saturated field still places -- and the
## widest-gap candidate wins when every roll is blocked. The first roll is the pure
## ring roll of record; `radius` is the arriving rock's collision radius and `avoid`
## carries what is already standing (field-local positions, like the return value).
func _rock_position(index: int, radius: float, avoid: Array[Dictionary]) -> Vector2:
	var best := Vector2.ZERO
	var best_gap := -INF
	for attempt in PLACEMENT_RETRIES + 1:
		var angle := TAU * float(index) / float(maxi(_rocks_per_cycle, 1))
		angle += rng.randf_range(-FIELD_ANGLE_JITTER, FIELD_ANGLE_JITTER)
		var ring := rng.randf_range(FIELD_RADIUS * FIELD_INNER_FRACTION, FIELD_RADIUS)
		var candidate := Vector2.RIGHT.rotated(angle) * ring
		var gap := _placement_gap(candidate, radius, avoid)
		if gap >= PLACEMENT_MARGIN:
			return candidate
		if gap > best_gap:
			best_gap = gap
			best = candidate
	return best


## The smallest gap a body of `radius` at `candidate` keeps to the placed entries --
## the number the pass's margin is judged against (negative: the bodies overlap).
func _placement_gap(
	candidate: Vector2, radius: float, avoid: Array[Dictionary]
) -> float:
	var gap := INF
	for entry: Dictionary in avoid:
		gap = minf(
			gap,
			candidate.distance_to(entry[&"pos"]) - radius - float(entry[&"radius"])
		)
	return gap


## Weight tables are int-keyed in `MineralCatalog.SECTOR_TIER_MIX`; a string-keyed
## config (a hand-written or JSON-shaped payload) is normalised rather than
## silently rolling tier 0.
func _integer_keys(source: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for key: Variant in source.keys():
		out[int(key)] = int(source[key])
	return out
