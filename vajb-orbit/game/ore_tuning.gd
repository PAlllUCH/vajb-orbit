extends RefCounted
## The one live balance surface (S13, owner-ticked 2026-09-25): every ore constant
## the game's live arithmetic reads, in one plain object the F1 dev overlay can
## tune at runtime.
##
## Contract: docs/gameplay/01_economy_core.md §5.6 (the rock income invariant and
## its two owner ticks) and docs/gameplay/02_minerals.md §5.1 Rule A (the reserve
## variant), ruled 2026-09-25; S13_BRIEF.md §2 is the pinned interface.
##
## Defaults are the owner files' declared constants, and those constants stay
## declared (they are the declared defaults the committed probes and tests read;
## `test_s13_caps.gd` asserts every default below equals its const, AC6). Live
## arithmetic reads `OreTuning.<field>`; the consts are documentation plus the
## anti-drift yardstick.
##
## Reached by preload path only, never the global class table (D11-C1's lesson:
## the global name resolves only after the editor has scanned the project, so a
## headless run of a script that used it would not see it). Nothing in `game/` is
## preloaded here - a static-var script with no dependencies cannot close a cycle.

## 01 §5.6's cap: a gun-attributed shatter realises at most this share of the
## rock's own original yield. Default = the owner's 0.10 tick. Reversal: 1.0
## restores the pre-2026-09-25 behaviour.
static var gun_burst_share: float = 0.10

## 02 §5.1 Rule A's reserve variant: the share of a rock's own original yield set
## aside at setup for its fragments. Default = the owner's 0.25 tick.
## Reversal: 0.0 (fragments are physical debris and carry no ore).
static var fragment_core_share: float = 0.25

## The gun chip rate (weapons.gd:216's declared default). 18_engine_spec §6's
## 10 %: a gun's work on a rock is 10 % of its DPS-equivalent rate.
static var gun_chip_rate: float = 0.10

## `mining_laser.gd`'s cycle: one extraction cycle's seconds.
static var mine_cycle: float = 1.2

## `asteroid.gd`'s work-per-unit: how much extraction work realises one ore unit.
static var work_per_unit: float = 1.0

## `mineral_catalog.gd`'s per-tier base yield (02 §5).
static var tier_base_yield: Dictionary = {1: 6, 2: 5, 3: 4, 4: 3}

## 02 §5's yield variance band.
static var yield_variance_min: float = 0.5
static var yield_variance_max: float = 1.5

## `asteroid.gd`'s burst bounds (x..y pickups per burst). S13_BRIEF §2 rule 3
## supersedes it as the payout's size - the field's float credit pays whole units
## when it crosses 1.0, so a shatter pays `floor(credit)` and no live arithmetic
## reads this pair. It is carried so the F1 overlay covers every ore constant
## (rule 6) and so `test_s13_caps.gd` can assert its default equals the const.
static var pickup_burst: Vector2i = Vector2i(1, 2)

## S14 / 02 §5.2's debris split table, the pinned interface of S14_BRIEF §2 rule 1.
## Keys are the **integer size classes** (`asteroid.gd`'s `SIZE_*`: XL 3, L 2, M 1,
## S 0 - `test_s14_splits.gd` asserts the two agree) and each value maps a child
## kind to the inclusive `Vector2i` range its count is rolled from on the field's
## own seeded RNG at a shatter: `XL -> L 1-3, M 2-4, S 2-5`; `L -> M 1-3, S 2-4`;
## `M -> S 1-3`; `S -> none`. Every child key is strictly below its parent, so a
## family can never grow a class and the cascade terminates at S.
##
## The pinned table is the default; `AsteroidField._cleave` reads it live, and the
## F1 overlay carries it through Save/Load (rule 5). Reversal: the retired
## single-kind rule, `{2: {1: Vector2i(2, 5)}, 1: {0: Vector2i(2, 5)}}` (02 §5.2's
## reversal line), which restores `FRAGMENT_SPLIT`'s shipped 2026-09-21 shape.
static var split_mix: Dictionary = {
	3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
	2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
	1: {0: Vector2i(1, 3)},
	0: {},
}

## S14 / 02 §5.2's spawn mix (proposed, owner-tickable): the weight each size class
## carries when the **field** rolls a rock's size (S14_BRIEF §2 rule 4). Weights are
## whole-number shares, not percentages: `AsteroidField._roll_size` accumulates them
## and rolls 1..sum, so the table stays a weight table the overlay can retune.
## `test_s14_splits.gd` measures 1000 seeded rolls against 40/32/20/8 within 3
## percentage points. Reversal: `{0: 1, 1: 1, 2: 1, 3: 1}`, the retired uniform roll.
static var spawn_size_weights: Dictionary = {0: 40, 1: 32, 2: 20, 3: 8}


## S22.5 / 02 §5.3 A1: the per-rock toughness roll's band. Every spawned rock rolls
## uniform in [min, max] on the field's own seeded RNG, keeps it for life and reads it
## back through `Asteroid.toughness()`; the gun door divides by it (A2). Reversal:
## `1.0` / `1.0` (no roll - every rock reads the pre-S22.5 gun door exactly).
static var toughness_min: float = 0.80
static var toughness_max: float = 1.60

## S22.5 / 02 §5.3 A2: `SIZE_TOUGHNESS_MULT`, keyed by `asteroid.gd`'s integer size
## classes (S 0, M 1, L 2, XL 3). `Asteroid.apply_gun_work` divides its amount by this
## times the rock's own `toughness`, so a bigger rock takes longer to crack under fire
## and S no longer reads as XL; the **mining** door never reads it (A5). Reversal: all
## `1.0` (the pre-S22.5 door).
static var size_toughness_mult: Dictionary = {0: 1.5, 1: 2.5, 2: 4.0, 3: 6.0}

## S22.5 / 02 §5.3 A3: `FRAGMENT_WORK`, the work units a rock with **no ore** needs
## before it cracks, keyed by the rock's own size class. XL is absent by the §5.2 bis
## table: a child is always strictly smaller than its parent, so no gun-born XL exists.
## Reversal: `0.0` for every class (today's instant crack).
static var fragment_work: Dictionary = {0: 2.0, 1: 3.0, 2: 4.5}

## S22.5 / 02 §5.3 A4: the chance a gun hit that did **not** crack an L/XL rock sheds
## one splinter, and the per-rock interval (seconds) that caps it at one shed per
## window. Both are read live by `AsteroidField`. Reversal: `0.0` (no splinters),
## `0.0` (cap removed).
static var splinter_chance: float = 0.25
static var splinter_interval: float = 0.5


## Every field back to its owner-file default. The dev overlay's Reset button is
## this call plus the removal of `user://dev_tuning.cfg`.
static func reset_to_defaults() -> void:
	gun_burst_share = 0.10
	fragment_core_share = 0.25
	gun_chip_rate = 0.10
	mine_cycle = 1.2
	work_per_unit = 1.0
	tier_base_yield = {1: 6, 2: 5, 3: 4, 4: 3}
	yield_variance_min = 0.5
	yield_variance_max = 1.5
	pickup_burst = Vector2i(1, 2)
	## The two S14 tables, written out exactly as their declarations above (the S13
	## pattern: the declared default is the yardstick, and the anti-drift test reads
	## it back through `to_dict`).
	split_mix = {
		3: {2: Vector2i(1, 3), 1: Vector2i(2, 4), 0: Vector2i(2, 5)},
		2: {1: Vector2i(1, 3), 0: Vector2i(2, 4)},
		1: {0: Vector2i(1, 3)},
		0: {},
	}
	spawn_size_weights = {0: 40, 1: 32, 2: 20, 3: 8}
	## The S22.5 pair of tables and the three A1/A4 scalars, written out exactly as
	## their declarations above (the same anti-drift pattern the S14 tables follow).
	toughness_min = 0.80
	toughness_max = 1.60
	size_toughness_mult = {0: 1.5, 1: 2.5, 2: 4.0, 3: 6.0}
	fragment_work = {0: 2.0, 1: 3.0, 2: 4.5}
	splinter_chance = 0.25
	splinter_interval = 0.5


## A serialisable snapshot of every field, for `user://dev_tuning.cfg` (the
## overlay's Save) and for tests. The dictionary is a copy, so a writer cannot
## mutate the live table through it.
static func to_dict() -> Dictionary:
	return {
		&"gun_burst_share": gun_burst_share,
		&"fragment_core_share": fragment_core_share,
		&"gun_chip_rate": gun_chip_rate,
		&"mine_cycle": mine_cycle,
		&"work_per_unit": work_per_unit,
		&"tier_base_yield": tier_base_yield.duplicate(),
		&"yield_variance_min": yield_variance_min,
		&"yield_variance_max": yield_variance_max,
		&"pickup_burst": pickup_burst,
		&"split_mix": split_mix.duplicate(true),
		&"spawn_size_weights": spawn_size_weights.duplicate(),
		&"toughness_min": toughness_min,
		&"toughness_max": toughness_max,
		&"size_toughness_mult": size_toughness_mult.duplicate(),
		&"fragment_work": fragment_work.duplicate(),
		&"splinter_chance": splinter_chance,
		&"splinter_interval": splinter_interval,
	}


## Applies a snapshot (the overlay's Load). Unknown keys are ignored; a known key
## with an unusable value is left at its current value, so a corrupt config can
## never put the balance into an unplayable state.
static func from_dict(d: Dictionary) -> void:
	if d.has(&"gun_burst_share"):
		gun_burst_share = clampf(_number(d[&"gun_burst_share"], gun_burst_share), 0.0, 1.0)
	if d.has(&"fragment_core_share"):
		fragment_core_share = clampf(
			_number(d[&"fragment_core_share"], fragment_core_share), 0.0, 1.0
		)
	if d.has(&"gun_chip_rate"):
		gun_chip_rate = clampf(_number(d[&"gun_chip_rate"], gun_chip_rate), 0.0, 1.0)
	if d.has(&"mine_cycle"):
		mine_cycle = maxf(_number(d[&"mine_cycle"], mine_cycle), 0.01)
	if d.has(&"work_per_unit"):
		work_per_unit = maxf(_number(d[&"work_per_unit"], work_per_unit), 0.0001)
	if d.has(&"tier_base_yield"):
		var table: Variant = d[&"tier_base_yield"]
		if table is Dictionary and not (table as Dictionary).is_empty():
			var out: Dictionary = {}
			for key: Variant in (table as Dictionary).keys():
				out[int(key)] = maxi(int((table as Dictionary)[key]), 0)
			tier_base_yield = out
	if d.has(&"yield_variance_min"):
		yield_variance_min = maxf(_number(d[&"yield_variance_min"], yield_variance_min), 0.0)
	if d.has(&"yield_variance_max"):
		yield_variance_max = maxf(_number(d[&"yield_variance_max"], yield_variance_max), 0.0)
	if d.has(&"pickup_burst"):
		var burst: Variant = d[&"pickup_burst"]
		if burst is Vector2i:
			pickup_burst = burst
		elif burst is Vector2:
			var v: Vector2 = burst
			pickup_burst = Vector2i(int(v.x), int(v.y))
		elif burst is Array and (burst as Array).size() >= 2:
			pickup_burst = Vector2i(int((burst as Array)[0]), int((burst as Array)[1]))
	if d.has(&"split_mix"):
		var mix: Variant = d[&"split_mix"]
		if mix is Dictionary and not (mix as Dictionary).is_empty():
			var out: Dictionary = {}
			for parent: Variant in (mix as Dictionary).keys():
				var row: Variant = (mix as Dictionary)[parent]
				if not row is Dictionary:
					continue
				var kinds: Dictionary = {}
				for child: Variant in (row as Dictionary).keys():
					var pair := _span((row as Dictionary)[child])
					if pair.x >= 0 and pair.y >= pair.x:
						kinds[int(child)] = pair
				out[int(parent)] = kinds
			split_mix = out
	if d.has(&"spawn_size_weights"):
		var weights: Variant = d[&"spawn_size_weights"]
		if weights is Dictionary and not (weights as Dictionary).is_empty():
			var counts: Dictionary = {}
			for key: Variant in (weights as Dictionary).keys():
				counts[int(key)] = maxi(int(_number((weights as Dictionary)[key], 0.0)), 0)
			spawn_size_weights = counts
	if d.has(&"toughness_min"):
		toughness_min = maxf(_number(d[&"toughness_min"], toughness_min), 0.0)
	if d.has(&"toughness_max"):
		toughness_max = maxf(_number(d[&"toughness_max"], toughness_max), 0.0)
	if d.has(&"size_toughness_mult"):
		size_toughness_mult = _class_floats(d[&"size_toughness_mult"], size_toughness_mult)
	if d.has(&"fragment_work"):
		fragment_work = _class_floats(d[&"fragment_work"], fragment_work)
	if d.has(&"splinter_chance"):
		splinter_chance = clampf(_number(d[&"splinter_chance"], splinter_chance), 0.0, 1.0)
	if d.has(&"splinter_interval"):
		splinter_interval = maxf(_number(d[&"splinter_interval"], splinter_interval), 0.0)


## A count range from whatever shape a config carried it in: a `Vector2i`, a
## `Vector2`, or a two-element array (`[x, y]`). A `Vector2i.ZERO` is the answer for
## anything else, which `from_dict` then rejects for an inverted range, so an
## unusable row is dropped rather than allowed to make a shatter roll nothing.
## A size-class-keyed table of numbers (A2's multiplier, A3's work budget) from
## whatever shape a config carried it in: keys are normalised to the integer class and
## values to non-negative floats, so a hand-edited row lands usable. An empty or
## unreadable payload leaves `current` alone rather than emptying the table.
static func _class_floats(value: Variant, current: Dictionary) -> Dictionary:
	if not value is Dictionary or (value as Dictionary).is_empty():
		return current
	var out: Dictionary = {}
	for key: Variant in (value as Dictionary).keys():
		out[int(key)] = maxf(_number((value as Dictionary)[key], 0.0), 0.0)
	return out if not out.is_empty() else current


static func _span(value: Variant) -> Vector2i:
	if value is Vector2i:
		return value
	if value is Vector2:
		var v: Vector2 = value
		return Vector2i(int(v.x), int(v.y))
	if value is Array and (value as Array).size() >= 2:
		return Vector2i(int((value as Array)[0]), int((value as Array)[1]))
	return Vector2i.ZERO


## A missing/ill-typed value leaves the current one, which is what makes
## `from_dict` forgiving of a hand-edited config.
static func _number(value: Variant, fallback: float) -> float:
	if value is float or value is int:
		return float(value)
	return fallback
