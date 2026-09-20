extends Node
## The one 20-minute station clock. Every periodic station system reads this
## script instead of owning a timer: exchange demand bands (05 §2), auction
## rotation (10), contract re-roll (14 §2), arena cooldowns (14 §5) and sector
## respawn bookkeeping (11) all consume the same bands. It is evaluated lazily,
## at station entry and at each transaction; there are no per-consumer Timers,
## ever. Contract: docs/gameplay/17_coder_handoff.md §4, docs/gameplay/14_station_services.md §9.
##
## Design: now() is system Unix time in whole seconds, so every consumer can
## persist a "last evaluated" stamp that survives a process restart; a band is
## any full 20-minute window between that stamp and now. The API is static so a
## caller can preload this script and use the same math without touching the
## autoload node, whose only job is to exist.
##
## No class_name: the autoload is named WorldClock, and Godot rejects a global
## class that hides an autoload singleton (parse error at registration).

const BAND_SECONDS := 1200

static var _override := -1


## Current clock reading: the override when one is set (tests, probes), else the
## system clock in whole seconds.
static func now() -> int:
	if has_override():
		return _override
	return int(Time.get_unix_time_from_system())


## Bands elapsed between two stamps. Zero unless both are real timestamps and
## the range is forward, so a fresh profile or a stale stamp never re-rolls.
static func bands_between(from_timestamp: int, to_timestamp: int) -> int:
	if from_timestamp <= 0 or to_timestamp <= 0:
		return 0
	if to_timestamp <= from_timestamp:
		return 0
	@warning_ignore("integer_division")
	return (to_timestamp - from_timestamp) / BAND_SECONDS


## Pins the clock to a fixed stamp. Tests and probes only.
static func set_override(timestamp: int) -> void:
	_override = timestamp


## Returns the clock to system time.
static func clear_override() -> void:
	_override = -1


static func has_override() -> bool:
	return _override > 0
