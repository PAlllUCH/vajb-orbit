extends SceneTree
## S13-R1's AC3 replay: the N-battery scaling measured through the same seam
## `test_s13_mining_batteries.gd` uses (`MiningLaser.extract_cycle`), but printed
## so the reviewer holds the numbers instead of the builder's word.
##
##   XDG_DATA_HOME=/tmp/s13_r1 "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" \
##     --script res://tools/r1_s13_ac3_replay.gd
##
## Banks 1/2/3 over 30 cycles against one 90-unit rock: per_cycle == bank, and the
## delivered total never exceeds the rock's own extractable (no double-pay).

const AsteroidScript := preload("res://game/asteroid.gd")
const MiningLaserScript := preload("res://game/mining_laser.gd")
const OreTuningScript := preload("res://game/ore_tuning.gd")

const TAG := "[S13R1]"
const ROCK_UNITS := 90
const CYCLES := 30

var _failures: Array[String] = []
var _baseline := 0.0


func _init() -> void:
	OreTuningScript.reset_to_defaults()
	print("%s mine_cycle=%.4f work_per_unit=%.4f" % [
		TAG, OreTuningScript.mine_cycle, OreTuningScript.work_per_unit,
	])
	for bank: int in [1, 2, 3]:
		_measure(bank)
	print("%s done failures=%d" % [TAG, _failures.size()])
	quit(1 if not _failures.is_empty() else 0)


func _measure(bank: int) -> void:
	var laser := MiningLaserScript.new() as Node2D
	laser.call(&"set_battery", bank)
	var rock := AsteroidScript.new() as RigidBody2D
	rock.call(&"setup", &"iron", 1, ROCK_UNITS)
	var delivered := 0
	for _cycle: int in CYCLES:
		delivered += int(laser.call(&"extract_cycle", rock, Vector2.ZERO))
	var per_cycle := float(delivered) / float(CYCLES)
	var rate := per_cycle / OreTuningScript.mine_cycle
	var ratio := 0.0 if _baseline <= 0.0 else rate / _baseline
	if bank == 1:
		_baseline = rate
	var removed := ROCK_UNITS - int(rock.get(&"yield_units"))
	print("%s bank=%d battery=%d per_cycle=%.4f rate=%.4f ratio_vs_1x=%.4f removed=%d delivered=%d"
		% [TAG, bank, int(laser.call(&"battery")), per_cycle, rate, ratio, removed, delivered])
	_check("bank%d_battery" % bank, int(laser.call(&"battery")) == bank,
		"bank %d holds %d" % [bank, bank])
	_check("bank%d_scaling" % bank,
		absf(per_cycle - float(bank)) <= 0.20 * float(bank),
		"bank %d realises %.4f units/cycle (within 20 %% of %d)" % [bank, per_cycle, bank])
	_check("bank%d_no_double_pay" % bank, removed == delivered and delivered <= ROCK_UNITS,
		"rock lost %d, cycles paid %d, budget %d" % [removed, delivered, ROCK_UNITS])
	laser.free()
	rock.free()


func _check(name: String, ok: bool, detail: String) -> void:
	if ok:
		print("%s ok   %s - %s" % [TAG, name, detail])
	else:
		print("%s FAIL %s - %s" % [TAG, name, detail])
		_failures.append(name)
