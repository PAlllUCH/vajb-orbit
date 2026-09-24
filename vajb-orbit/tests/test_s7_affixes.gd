@tool
extends McpTestSuite
## Suite s7_affixes: the affix bridge and the ship-stat half of the affix
## application (CONTRACTS section 20; 15 sections 3/4; 09 section 5).
##
## Two surfaces, one suite. `Affixes.summary` (spelled `PlayerProfile.affix_summary`
## by the launch) walks a hull's `resolved_fit` cells, reads each fitted instance's
## record (a `count`-0 record still answers, CONTRACTS section 15) and returns the
## per-prefix aggregate **plus one row per fitted instance** -- the rows are what
## make the per-instance rules expressible at all (K0 F1). `ShipFit.resolve` then
## takes that summary as its optional third argument and applies it before
## `_clamp`, so an empty summary (or no third argument) reproduces every pre-S7
## figure byte for byte.
##
## Everything below is worked off the shipped catalogue rows, so a band or a cost
## change moves the expectation with it. The one hand-built summary is the
## over-capacity fixture that reaches 09 section 5's pool ceilings -- no legal fit
## can, which is itself the point of those ceilings.
##
## Profiles are throwaway instances of the autoload script whose `save_path` is
## repointed at a scratch file before the first mutation (the `test_s3_instances`
## harness): no instance enters the tree, so the debounced save Timer does not
## exist and every mutation writes through immediately.

const Profile := preload("res://autoload/player_profile.gd")
const ModuleData := preload("res://game/module_catalog.gd")
const FitData := preload("res://game/ship_fit.gd")

const PROFILE_PATH := "user://test_s7_affixes.cfg"

## 08 section 3.2's hulls this suite fits: the Cutter (1 S cell) for the single
## instance rows, the Spearhead (2 S cells) for Sturdy/Vigilant, the Warden (2 C
## cells) for Wideband/Surefire, the Obliterator (3 E cells, 3 S cells) for
## Tempered's ceiling and the pool clamp, and the Lancer for Spry.
const VANGUARD: StringName = &"ship_vanguard"
const FIGHTER: StringName = &"ship_fighter"
const CORVETTE: StringName = &"ship_corvette"
const PATROL: StringName = &"ship_patrol"
const DESTROYER: StringName = &"ship_destroyer"

## 09 section 3's modules this suite fits.
const LASER: StringName = &"w_laser"
const LIGHT_SHIELD: StringName = &"s_light"
const HEAVY_SHIELD: StringName = &"s_heavy"
const ION_SHIELD: StringName = &"s_ion"
const LIGHT_PLATE: StringName = &"h_plate_light"
const HEAVY_PLATE: StringName = &"h_plate_heavy"
const COMPOSITE: StringName = &"h_composite"
const TARGETING: StringName = &"c_target"
const SCANNER: StringName = &"c_scanner"
const NEXUS: StringName = &"c_nexus"
const AFTERBURNER: StringName = &"b_afterburner"
const CARGO: StringName = &"u_cargo"
const HOLDS: StringName = &"u_holds"
const STD_ENGINE: StringName = &"e_std"
const ION_ENGINE: StringName = &"e_ion"
const VECTOR_ENGINE: StringName = &"e_vector"
const STD_REACTOR: StringName = &"p_std"
const MK2_REACTOR: StringName = &"p_mk2"

## The Vanguard's standard fit resolved with no affix at all: the pre-S7 fixture
## this suite re-asserts as the proof that `{}` and no third argument are
## byte-identical (CONTRACTS section 20). Every value is derived here, not copied
## from another suite: hull 1000 / shield 600 / cargo 40, `s_light` +200 shield and
## +4/s regen, `h_plate_light` +250 hull at a -0.05 speed penalty (x0.95 speed,
## x1.05 on the three handling times), `w_laser` and `e_std`/`p_std` with no
## effects, and the section 14 handling multipliers (accel x2.0, coast x2.0).
const PRE_S7_VANGUARD: Dictionary = {
	"max_speed": 406.6,
	"accel_time": 5.04,
	"coast_time": 2.1,
	"turn_rate": 1.5,
	"turn_spinup": 0.525,
	"hull_mass": 110.0,
	"hull_max": 1250.0,
	"shield_max": 800.0,
	"shield_regen": 6.0,
	"damage_mult": 1.0,
	"lock_range": 900.0,
	"scan_range": 900.0,
	"tractor_range": 120.0,
	"tractor_speed": 90.0,
	"tractor_streams": 1,
	"cargo_max": 40,
	"energy_max": 100.0,
	"energy_regen": 5.0,
	"fuel_max": 200.0,
	"boosters": [],
	"booster_cooldown_mult": 1.0,
}

var _profile: Node = null
var _profiles: Array[Node] = []


func suite_name() -> String:
	return "s7_affixes"


func setup() -> void:
	_delete_file(PROFILE_PATH)
	_profile = _fresh()


func teardown() -> void:
	for profile: Node in _profiles:
		if is_instance_valid(profile):
			profile.free()
	_profiles.clear()


func suite_teardown() -> void:
	_delete_file(PROFILE_PATH)


## ---------------------------------------------------------------------------
## The summary: the aggregate, the flags, and the instance rows (AC1)
## ---------------------------------------------------------------------------


func test_the_summary_sums_the_stored_signs_and_lists_one_row_per_instance() -> void:
	var engine := _fitted(ION_ENGINE, [{"id": "tempered", "value": 0.12}])
	var laser := _fitted(LASER, [{"id": "keen", "value": 0.08}], ["leeches"])
	var shield := _fitted(LIGHT_SHIELD, [{"id": "sturdy", "value": 0.15}], ["whale"])
	var plate := _fitted(LIGHT_PLATE, [{"id": "lightened", "value": -0.06}], ["whale"])
	var reactor := _fitted(MK2_REACTOR, [{"id": "overflowing", "value": 2.0}])
	_profile.set_fit(VANGUARD, {
		&"engines": [engine],
		&"power": reactor,
		&"weapons": [laser],
		&"shields": [shield],
		&"armour": [plate],
	})

	var summary: Dictionary = _profile.affix_summary(VANGUARD)
	assert_eq(float(summary[&"tempered"]), 0.12, "Tempered's magnitude is the stored one")
	assert_eq(float(summary[&"keen"]), 0.08, "Keen's too")
	assert_eq(float(summary[&"sturdy"]), 0.15, "Sturdy's too")
	assert_eq(
		float(summary[&"lightened"]),
		-0.06,
		"and the negative bands keep their stored sign (15 section 3)"
	)
	assert_eq(float(summary[&"overflowing"]), 2.0, "a staged prefix still aggregates (staging is a consumer's call)")

	assert_eq(
		_names(summary[&"suffixes"]),
		_names([&"leeches", &"whale"]),
		"one suffix flag per perk, in first-seen order, and a repeat is one flag"
	)
	assert_true(Affixes.has_suffix(summary, &"whale"), "has_suffix reads the flag list")
	assert_true(Affixes.has_suffix(summary, &"leeches"), "for every carried perk")
	assert_false(Affixes.has_suffix(summary, &"embers"), "and answers false for one it does not carry")
	assert_false(Affixes.has_suffix({}, &"whale"), "an empty summary carries nothing")

	var rows: Array = summary[&"instances"]
	assert_eq(rows.size(), 5, "one row per fitted instance, and the delivered base ids make none")
	## FIT_SLOT_KEYS order: engines, weapons, shields, armour, ..., power.
	_assert_row(rows[0], &"engines", 0, ION_ENGINE, 1)
	_assert_row(rows[1], &"weapons", 0, LASER, 1)
	_assert_row(rows[2], &"shields", 0, LIGHT_SHIELD, 1)
	_assert_row(rows[3], &"armour", 0, LIGHT_PLATE, 1)
	_assert_row(rows[4], &"power", 0, MK2_REACTOR, 1)
	assert_eq(String(rows[2][&"prefixes"][0][&"id"]), "sturdy", "a row keeps its own prefix id")
	assert_eq(float(rows[2][&"prefixes"][0][&"value"]), 0.15, "and its own stored value")
	assert_eq(_names(rows[2][&"suffixes"]), _names([&"whale"]), "and its own suffix ids")
	assert_true(
		_names(rows[0][&"suffixes"]).is_empty(), "an instance with no suffix keeps an empty list"
	)


func test_the_summary_is_empty_for_a_hull_with_no_fit() -> void:
	assert_eq(Affixes.summary(null, VANGUARD), {}, "no profile, no summary")
	assert_eq(Affixes.summary(_profile, &"ship_not_a_hull"), {}, "and no fit for the hull, none either")
	## A hull whose account holds nothing still resolves the standard fit, so its
	## summary is a real (empty) summary rather than `{}`: no prefix, no flag, no row.
	var summary: Dictionary = _profile.affix_summary(VANGUARD)
	assert_false(summary.is_empty(), "the standard fit is a fit")
	assert_true(_names(summary[&"suffixes"]).is_empty(), "with no suffix flag")
	assert_eq((summary[&"instances"] as Array).size(), 0, "and no instance row")


func test_a_stored_zero_stays_inert_and_is_never_re_read_from_the_band() -> void:
	## A bare prefix id (a hand-built fixture, `test_s3_instances`' own shape) is
	## stored as `value: 0.0`; the summary must keep that 0.0 and the resolver must
	## not substitute the tier band (CONTRACTS section 20 / K0 F16). `wideband` at
	## `c_scanner`'s tier 1 would read 0.15 if it were re-derived.
	var scanner := _fitted(SCANNER, ["wideband"])
	_profile.set_fit(FIGHTER, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"computers": [scanner]})
	var summary: Dictionary = _profile.affix_summary(FIGHTER)
	assert_eq(float(summary[&"wideband"]), 0.0, "the stored 0.0 is the value")
	var stats := _resolve(FIGHTER)
	assert_close(
		stats.scan_range, 900.0 * 1.25, "the module's own scanner, with the stored 0.0 inert"
	)
	assert_ne(
		stats.scan_range,
		900.0 * (1.0 + 0.25 * 1.15),
		"and not the tier band's reading (%s)" % [ModuleData.prefix_value(&"wideband", 1)]
	)


## ---------------------------------------------------------------------------
## The empty-argument proof (AC1)
## ---------------------------------------------------------------------------


func test_resolve_without_a_summary_is_the_pre_s7_fixture() -> void:
	var plain: ShipStats = FitData.resolve(VANGUARD, FitData.STANDARD_FIT)
	var empty: ShipStats = FitData.resolve(VANGUARD, FitData.STANDARD_FIT, {})
	var bridged: ShipStats = FitData.resolve(
		VANGUARD, FitData.STANDARD_FIT, _profile.affix_summary(VANGUARD)
	)
	assert_true(plain != null, "the standard fit resolves")
	assert_true(
		_deep_eq(_snapshot(empty), _snapshot(plain)),
		"`{}` is byte-identical to the two-argument call"
	)
	assert_true(
		_deep_eq(_snapshot(bridged), _snapshot(plain)),
		"and so is the empty summary a base-id fit builds"
	)
	assert_true(
		_deep_eq(_snapshot(plain), PRE_S7_VANGUARD),
		"the full pre-S7 fixture holds: %s" % [_snapshot(plain)]
	)
	assert_eq(plain.damage_mult, 1.0, "no computer, no damage multiplier")
	assert_eq(plain.booster_cooldown_mult, 1.0, "no booster affix, no cooldown multiplier")


## ---------------------------------------------------------------------------
## Sturdy, Vigilant, Wideband, Surefire (AC2)
## ---------------------------------------------------------------------------


func test_sturdy_scales_its_own_instance_pool_not_the_summed_magnitude() -> void:
	## The K0 F1 counter-example, worked off shipped data: the Spearhead's 700
	## shield pool plus an `s_light` 200 Sturdy 0.15 and an `s_heavy` 400 Sturdy
	## 0.10 adds 30 + 40 = 70, not 0.25 x 600 = 150.
	var light := _fitted(LIGHT_SHIELD, [{"id": "sturdy", "value": 0.15}])
	var heavy := _fitted(HEAVY_SHIELD, [{"id": "sturdy", "value": 0.10}])
	_profile.set_fit(CORVETTE, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"shields": [light, heavy]
	})
	var stats := _resolve(CORVETTE)
	assert_close(stats.shield_max, 700.0 + 200.0 + 400.0 + 70.0, "the per-instance Sturdy sum")
	assert_ne(
		stats.shield_max,
		700.0 + 200.0 + 400.0 + 150.0,
		"not the summed-magnitude reading, which would double-count the pools"
	)


func test_sturdy_at_its_band_maximum_is_still_bounded_by_the_pool_ceiling() -> void:
	## The over-capacity fixture: no legal fit reaches 09 section 5's 3x shield
	## ceiling (the best three-cell hull carries 900 + 3 x 350 x 1.20 = 2160), so the
	## clamp is proved on six max-band `s_ion` instances -- 900 + 6 x 350 x 1.20 =
	## 3420 before `_clamp`, exactly 2700 after it. This is the assertion that the
	## affixes land **before** the clamp.
	var rows: Array = []
	var cells: Array = []
	for index: int in range(6):
		cells.append(ION_SHIELD)
		rows.append(_hand_row(&"shields", index, ION_SHIELD, [{"id": "sturdy", "value": 0.20}]))
	var stats: ShipStats = FitData.resolve(
		DESTROYER,
		{&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"shields": cells},
		_hand_summary(rows, [])
	)
	assert_close(stats.shield_max, 900.0 * 3.0, "the 3x ceiling, applied after the affix")


func test_vigilant_keeps_the_best_instance_and_scales_each_by_the_aggregate() -> void:
	## Best instance first: an `s_ion` 9/s plain beats an `s_light` 4/s Vigilant 0.35
	## (4 x 1.35 = 5.4), so the pool regenerates at 2 + 9.
	var ion := _fitted(ION_SHIELD, [])
	var light := _fitted(LIGHT_SHIELD, [{"id": "vigilant", "value": 0.35}])
	_profile.set_fit(CORVETTE, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"shields": [ion, light]
	})
	assert_close(_resolve(CORVETTE).shield_regen, 2.0 + 9.0, "the best instance wins")

	## Two carrying instances: each own becomes `own x (1 + sum(vigilant))` with
	## sum = 0.25 + 0.15 = 0.40, so 9 x 1.40 = 12.6 beats 4 x 1.40 = 5.6.
	var ion_b := _fitted(ION_SHIELD, [{"id": "vigilant", "value": 0.25}])
	var light_b := _fitted(LIGHT_SHIELD, [{"id": "vigilant", "value": 0.15}])
	_profile.set_fit(CORVETTE, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"shields": [ion_b, light_b]
	})
	assert_close(_resolve(CORVETTE).shield_regen, 2.0 + 9.0 * 1.40, "the aggregate scales both")


func test_wideband_takes_the_best_instance_and_scales_it_by_the_aggregate() -> void:
	## The Warden's two computer cells: a plain `c_nexus` (scanner 0.25) beside a
	## `c_scanner` (0.25) Wideband 0.25 -> 0.3125, so 900 x 1.3125. `lock_range`
	## follows `scan_range` untouched.
	var nexus := _fitted(NEXUS, [])
	var scanner := _fitted(SCANNER, [{"id": "wideband", "value": 0.25}])
	_profile.set_fit(PATROL, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"computers": [nexus, scanner]
	})
	var stats := _resolve(PATROL)
	assert_close(stats.scan_range, 900.0 * (1.0 + 0.25 * 1.25), "the adjusted best scanner")
	assert_close(stats.lock_range, stats.scan_range, "and the lock range follows it")

	## Both carrying: sum = 0.25 + 0.15 = 0.40 -> each 0.25 x 1.40 = 0.35.
	var nexus_b := _fitted(NEXUS, [{"id": "wideband", "value": 0.25}])
	var scanner_b := _fitted(SCANNER, [{"id": "wideband", "value": 0.15}])
	_profile.set_fit(PATROL, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"computers": [nexus_b, scanner_b]
	})
	assert_close(_resolve(PATROL).scan_range, 900.0 * 1.35, "the aggregate scales the best")


func test_surefire_scales_each_computer_and_the_computers_still_sum() -> void:
	## `c_target` 0.15 Surefire 0.05 -> 0.1575 beside a plain `c_nexus` 0.15 ->
	## damage_mult 1 + 0.3075.
	var target := _fitted(TARGETING, [{"id": "surefire", "value": 0.05}])
	var nexus := _fitted(NEXUS, [])
	_profile.set_fit(PATROL, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"computers": [target, nexus]
	})
	assert_close(_resolve(PATROL).damage_mult, 1.0 + 0.15 * 1.05 + 0.15, "summed, each own scaled")

	## Both carrying: sum = 0.05 + 0.08 = 0.13 -> each 0.15 x 1.13 = 0.1695.
	var target_b := _fitted(TARGETING, [{"id": "surefire", "value": 0.05}])
	var nexus_b := _fitted(NEXUS, [{"id": "surefire", "value": 0.08}])
	_profile.set_fit(PATROL, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"computers": [target_b, nexus_b]
	})
	assert_close(_resolve(PATROL).damage_mult, 1.0 + 2.0 * 0.15 * 1.13, "the aggregate scales both")


## ---------------------------------------------------------------------------
## Tempered, Lightened, Deep-hold, Spry, Whale (AC2, AC5)
## ---------------------------------------------------------------------------


func test_tempered_joins_the_summed_engine_delta_under_the_ceiling() -> void:
	## An `e_ion` (1.15) Tempered 0.12 -> (0.15) x 1.12 = 0.168, beside two `e_std`
	## (delta 0): speed_mult 1.168 on the Obliterator's 315.
	var ion := _fitted(ION_ENGINE, [{"id": "tempered", "value": 0.12}])
	_profile.set_fit(DESTROYER, {
		&"engines": [ion, STD_ENGINE, STD_ENGINE], &"power": STD_REACTOR
	})
	assert_close(_resolve(DESTROYER).max_speed, 315.0 * 1.168, "the tempered delta in the sum")

	## Band maximum on the best legal set: three `e_vector` (1.25) at Tempered 0.12
	## -> 3 x 0.25 x 1.12 = 0.84 -> 1.84, clamped to `ENGINE_MULT_CEILING` 1.40.
	var vectors: Array = []
	for index: int in range(3):
		vectors.append(_fitted(VECTOR_ENGINE, [{"id": "tempered", "value": 0.12}]))
	_profile.set_fit(DESTROYER, {&"engines": vectors, &"power": STD_REACTOR})
	assert_close(_resolve(DESTROYER).max_speed, 315.0 * 1.40, "the 1.40 ceiling, applied after the sum")


func test_lightened_flips_its_own_plate_and_never_crosses_into_a_bonus() -> void:
	## `h_plate_light`'s own -0.05 penalty plus abs(-0.08) = +0.03 would be a bonus,
	## so the effective penalty clamps at 0: the hull resolves exactly unplated.
	var plate := _fitted(LIGHT_PLATE, [{"id": "lightened", "value": -0.08}])
	_profile.set_fit(VANGUARD, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"armour": [plate]})
	var stats := _resolve(VANGUARD)
	assert_close(stats.max_speed, 428.0, "the clamped penalty adds no speed")
	assert_close(stats.accel_time, 2.4 * 2.0, "and the mass term follows it (1 + |0|)")
	assert_close(stats.coast_time, 1.0 * 2.0, "coast too")
	assert_close(stats.turn_spinup, 0.5, "and the spin-up")
	assert_close(stats.hull_mass, 110.0, "hull_mass carries the plate's own mass_add only")

	## Inside the band: -0.04 leaves -0.01, and the speed **and** mass terms follow.
	var plate_b := _fitted(LIGHT_PLATE, [{"id": "lightened", "value": -0.04}])
	_profile.set_fit(VANGUARD, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"armour": [plate_b]})
	var stats_b := _resolve(VANGUARD)
	assert_close(stats_b.max_speed, 428.0 * 0.99, "a -0.01 effective penalty")
	assert_close(stats_b.accel_time, 2.4 * 2.0 * 1.01, "with the handling mass at 1.01")
	assert_close(stats_b.coast_time, 1.0 * 2.0 * 1.01, "on every handling time")
	assert_close(stats_b.turn_spinup, 0.5 * 1.01, "including the spin-up")

	## Two plates, one carrying: the aggregate scales only the carrying instance.
	var light := _fitted(LIGHT_PLATE, [{"id": "lightened", "value": -0.04}])
	var heavy := _fitted(HEAVY_PLATE, [{"id": "lightened", "value": -0.06}])
	_profile.set_fit(VANGUARD, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"armour": [light, heavy]
	})
	## sum = -0.10 -> light -0.05 + 0.10 = +0.05 clamps to 0, heavy -0.12 + 0.10 = -0.02.
	assert_close(_resolve(VANGUARD).max_speed, 428.0 * 1.0 * 0.98, "each plate's own penalty")


func test_deep_hold_adds_its_units_on_top_of_the_instance_cargo() -> void:
	## The Warden's 60 hold plus `u_cargo` 15 Deep-hold 8 and `u_holds` 40 Deep-hold
	## 12: the affix adds its own units to its own instance's contribution.
	var cargo := _fitted(CARGO, [{"id": "deep_hold", "value": 8.0}])
	var holds := _fitted(HOLDS, [{"id": "deep_hold", "value": 12.0}])
	_profile.set_fit(PATROL, {
		&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"utility": [cargo, holds]
	})
	assert_eq(_resolve(PATROL).cargo_max, 60 + 15 + 40 + 8 + 12, "sum(value) on top of the rows")


func test_spry_sets_the_ship_level_cooldown_multiplier() -> void:
	## The Lancer's afterburner (catalogue cooldown 8.0) at Spry -0.15 -> 0.85, so
	## the consumer's 8.0 x 0.85 is 6.8 (K2 wires that line).
	var booster := _fitted(AFTERBURNER, [{"id": "spry", "value": -0.15}])
	_profile.set_fit(FIGHTER, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"boosters": [booster]})
	var stats := _resolve(FIGHTER)
	assert_close(stats.booster_cooldown_mult, 0.85, "1 + sum(spry) over the fitted booster")
	assert_eq(_names(stats.boosters), _names([AFTERBURNER]), "and the id list is untouched")

	## No Spry: the field keeps its 1.0 default.
	var plain := _fitted(AFTERBURNER, [])
	_profile.set_fit(FIGHTER, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"boosters": [plain]})
	assert_close(_resolve(FIGHTER).booster_cooldown_mult, 1.0, "an unaffixed booster is 1.0")


func test_whale_adds_its_flat_hull_before_the_pool_ceiling() -> void:
	var plate := _fitted(LIGHT_PLATE, [], ["whale"])
	_profile.set_fit(VANGUARD, {&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"armour": [plate]})
	assert_close(_resolve(VANGUARD).hull_max, 1000.0 + 250.0 + 50.0, "+50 on top of the plate")

	## The same flat term is bounded by the 3x hull ceiling on the over-capacity
	## fixture: 2200 + 5 x 1000 + 50 = 7250 before `_clamp`, exactly 6600 after.
	var rows: Array = []
	var cells: Array = []
	for index: int in range(5):
		cells.append(COMPOSITE)
		rows.append(_hand_row(&"armour", index, COMPOSITE, []))
	var stats: ShipStats = FitData.resolve(
		DESTROYER,
		{&"engines": [STD_ENGINE], &"power": STD_REACTOR, &"armour": cells},
		_hand_summary(rows, [&"whale"])
	)
	assert_close(stats.hull_max, 2200.0 * 3.0, "the 3x hull ceiling, applied after the flat step")


## ---------------------------------------------------------------------------
## Staged: Overflowing applies nothing (AC7)
## ---------------------------------------------------------------------------


func test_a_fitted_overflowing_instance_changes_nothing() -> void:
	## The budget is frozen (15 section 6: "affixes bend the good stats, never the
	## budget"), so Overflowing is staged: the record carries it, the summary
	## aggregates it, and `resolve` reads none of it.
	var plain := _fitted(MK2_REACTOR, [])
	_profile.set_fit(VANGUARD, {&"engines": [STD_ENGINE], &"power": plain})
	var before := _resolve(VANGUARD)
	var staged := _fitted(MK2_REACTOR, [{"id": "overflowing", "value": 2.0}])
	_profile.set_fit(VANGUARD, {&"engines": [STD_ENGINE], &"power": staged})
	var summary: Dictionary = _profile.affix_summary(VANGUARD)
	assert_eq(float(summary[&"overflowing"]), 2.0, "the summary does carry the staged prefix")
	var after := _resolve(VANGUARD)
	assert_true(
		_deep_eq(_snapshot(after), _snapshot(before)),
		"and the resolved snapshot is byte-identical with it fitted"
	)
	assert_close(after.energy_max, 100.0, "the reactor's own pool is untouched")
	assert_eq(
		int(FitData.power_budget(VANGUARD, _profile.base_fit(_profile.resolved_fit(VANGUARD)))[&"out"]),
		10,
		"and the budget reads the reactor's own power_add (8 + 2), never the affix"
	)


## ---------------------------------------------------------------------------
## Helpers
## ---------------------------------------------------------------------------


func _fresh():
	var profile := Profile.new()
	profile.save_path = PROFILE_PATH
	_profiles.append(profile)
	return profile


func _delete_file(path: String) -> void:
	var directory := DirAccess.open(path.get_base_dir())
	if directory != null:
		directory.remove(path.get_file())


## One instance of `base_id` carrying `prefixes`/`suffixes`, taken out of the bag
## (CONTRACTS section 15: fitting is `count` 1 -> 0, and the record survives).
func _fitted(base_id: StringName, prefixes: Array = [], suffixes: Array = []) -> StringName:
	var id: StringName = _profile.add_instance(base_id, &"rare", prefixes, suffixes)
	_profile.take_instance(id)
	return id


## The launch's own path: the raw fit through `base_fit` (base ids) plus the
## profile's summary, exactly as `game.gd`'s handshake composes them.
func _resolve(ship_id: StringName) -> ShipStats:
	var fit: Dictionary = _profile.base_fit(_profile.resolved_fit(ship_id))
	return FitData.resolve(ship_id, fit, _profile.affix_summary(ship_id))


## The over-capacity fixture's summary: the same contract `Affixes.summary`
## returns, built by hand because `set_fit` cuts a fit at the hull's own capacity
## and no legal fit reaches the pool ceilings.
func _hand_summary(rows: Array, flags: Array) -> Dictionary:
	var totals: Dictionary = {}
	for raw: Variant in rows:
		var row: Dictionary = raw
		for entry: Variant in row[&"prefixes"]:
			var prefix: Dictionary = entry
			var id := StringName(str(prefix[&"id"]))
			totals[id] = float(totals.get(id, 0.0)) + float(prefix[&"value"])
	totals[&"suffixes"] = flags
	totals[&"instances"] = rows
	return totals


func _hand_row(slot: StringName, index: int, base_id: StringName, prefixes: Array) -> Dictionary:
	return {
		&"slot": slot,
		&"index": index,
		&"base_id": base_id,
		&"prefixes": prefixes,
		&"suffixes": [],
	}


## Every field of one resolved snapshot, so an A/B comparison cannot miss one.
func _snapshot(stats: ShipStats) -> Dictionary:
	return {
		"max_speed": stats.max_speed,
		"accel_time": stats.accel_time,
		"coast_time": stats.coast_time,
		"turn_rate": stats.turn_rate,
		"turn_spinup": stats.turn_spinup,
		"hull_mass": stats.hull_mass,
		"hull_max": stats.hull_max,
		"shield_max": stats.shield_max,
		"shield_regen": stats.shield_regen,
		"damage_mult": stats.damage_mult,
		"lock_range": stats.lock_range,
		"scan_range": stats.scan_range,
		"tractor_range": stats.tractor_range,
		"tractor_speed": stats.tractor_speed,
		"tractor_streams": stats.tractor_streams,
		"cargo_max": stats.cargo_max,
		"energy_max": stats.energy_max,
		"energy_regen": stats.energy_regen,
		"fuel_max": stats.fuel_max,
		"boosters": stats.boosters,
		"booster_cooldown_mult": stats.booster_cooldown_mult,
	}


## One `instances` row's four identity fields, plus its prefix count.
func _assert_row(
	row: Dictionary, slot: StringName, index: int, base_id: StringName, prefixes: int
) -> void:
	assert_eq(String(row[&"slot"]), String(slot), "the row names its slot")
	assert_eq(int(row[&"index"]), index, "and its cell index")
	assert_eq(String(row[&"base_id"]), String(base_id), "and the base id it was fitted as")
	assert_eq((row[&"prefixes"] as Array).size(), prefixes, "and its own prefix rows")


func _names(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if raw is Array:
		for entry: Variant in raw as Array:
			out.append(String(entry))
	return out


func assert_close(actual: float, expected: float, msg: String) -> void:
	assert_true(
		is_equal_approx(actual, expected), "%s (got %.6f, want %.6f)" % [msg, actual, expected]
	)


## Structural equality with a float tolerance, exactly as `test_s3_instances` reads
## a nested record: `==` on nested dictionaries and typed arrays is not dependable.
func _deep_eq(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		var left: Dictionary = a
		var right: Dictionary = b
		if left.size() != right.size():
			return false
		for key: Variant in left.keys():
			if not right.has(key):
				return false
			if not _deep_eq(left[key], right[key]):
				return false
		return true
	if a is Array and b is Array:
		var left_array: Array = a
		var right_array: Array = b
		if left_array.size() != right_array.size():
			return false
		for index: int in range(left_array.size()):
			if not _deep_eq(left_array[index], right_array[index]):
				return false
		return true
	if (a is float) or (b is float):
		return is_equal_approx(float(a), float(b))
	return a == b
