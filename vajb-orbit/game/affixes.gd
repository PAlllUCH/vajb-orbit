class_name Affixes
extends RefCounted
## The affix bridge (CONTRACTS section 20, 15 sections 3/4): the profile's fitted
## module instances, summed per fit, in the shape `ShipFit.resolve`'s optional
## `affixes` parameter takes.
##
## `summary(profile, ship_id)` walks `resolved_fit`'s cells in
## `ShipFit.FIT_SLOT_KEYS` then cell order, reads each cell's record through
## `PlayerProfile.instance` (a fitted record survives at `count` 0, so it still
## answers -- CONTRACTS section 15), and returns
##
##     {prefix_id: summed_magnitude,        # 15 section 3's own signs, stored
##      &"suffixes": Array[StringName],     # one entry per perk, once
##      &"instances": Array[Dictionary]}    # one row per fitted instance
##
## The magnitude of a prefix is the sum of the values the records **store** -- a
## bare id is stored as `0.0` and stays inert, and `ModuleCatalog.prefix_value` is
## never consulted here (15 section 3's band is the roll's own reader; a consumer
## reads what was rolled). `frugal`/`lightened`/`spry` keep their negative signs,
## so a consumer that reads `(1 + sum)` gets cheaper/shorter for a negative band.
##
## `instances` is load-bearing, not a convenience: a rule written
## `own x (1 + sum(own))` (Vigilant, Wideband, Surefire, Tempered, Lightened) has
## to know *which* instance carries a prefix and what that instance's own catalogue
## contribution is, and a summed magnitude alone cannot express it. The measured
## counter-example (K0 F1): an `s_light` 200-pool Sturdy 0.10 beside an `s_heavy`
## 400-pool Sturdy 0.15 adds +80, not 0.25 x 600 = +150.
##
## Data only: statics over a profile, no state of its own, no catalogue arithmetic
## beyond one base id's own row. `{}` when the hull has no fit at all (an NPC hull,
## or an unknown id).

## The summary's own two non-prefix keys (CONTRACTS section 20). `ShipFit` reads
## them too; it keeps its own literals so the two global classes stay a one-way
## dependency (`game/affixes.gd` reads `ShipFit.FIT_SLOT_KEYS`).
const KEY_SUFFIXES: StringName = &"suffixes"
const KEY_INSTANCES: StringName = &"instances"

## One `instances` row's keys, verbatim from CONTRACTS section 20.
const KEY_SLOT: StringName = &"slot"
const KEY_INDEX: StringName = &"index"
const KEY_BASE_ID: StringName = &"base_id"
const KEY_PREFIXES: StringName = &"prefixes"
const KEY_ID: StringName = &"id"
const KEY_VALUE: StringName = &"value"

## The record's own key spellings (CONTRACTS section 15), read as plain strings so
## this file preloads nothing but the slot order.
const RECORD_BASE_ID := "base_id"
const RECORD_PREFIXES := "prefixes"
const RECORD_SUFFIXES := "suffixes"


## One hull's fitted instances, summed per prefix, with one row per fitted instance
## in `ShipFit.FIT_SLOT_KEYS` then cell order (CONTRACTS section 20). `profile` is
## anything that answers `resolved_fit` and `instance` -- the autoload or a
## throwaway copy. A hull outside the nine, or one whose fit does not resolve,
## answers `{}`.
static func summary(profile, ship_id: StringName) -> Dictionary:
	if profile == null:
		return {}
	var fit: Dictionary = profile.resolved_fit(ship_id)
	if fit.is_empty():
		return {}

	var totals: Dictionary = {}
	var flags: Array[StringName] = []
	var rows: Array[Dictionary] = []
	for slot: StringName in ShipFit.FIT_SLOT_KEYS:
		var cells: Array = _cells(fit, slot)
		for index: int in range(cells.size()):
			var entry := StringName(str(cells[index]))
			if entry == &"":
				continue
			var record: Dictionary = profile.instance(entry)
			if record.is_empty():
				continue
			rows.append(_row(slot, index, record, entry, totals, flags))

	var out: Dictionary = totals
	out[KEY_SUFFIXES] = flags
	out[KEY_INSTANCES] = rows
	return out


## Whether the summary carries `id` as one of its suffix flags (CONTRACTS
## section 20's once-per-perk rule: two instances of the same suffix are one flag).
## The parameter is `data`, not `summary` (K1's D5): a parameter named after this
## class's own `summary` function raises `SHADOWED_VARIABLE`. GDScript has no named
## arguments, so the name touches no caller.
static func has_suffix(data: Dictionary, id: StringName) -> bool:
	var flags: Variant = data.get(KEY_SUFFIXES, null)
	if flags == null:
		flags = data.get(String(KEY_SUFFIXES), null)
	if not flags is Array:
		return false
	for raw: Variant in flags as Array:
		if StringName(str(raw)) == id:
			return true
	return false


## --- S27 (15's 2026-09-27 P3 block, R-S27-2/3, ticks K2/K3) ------------------------
##
## The three new suffix perks' consumers, at the same CONTRACTS section 20 seam
## `has_suffix` reads. Each is a pure function over the summary + its own argument, so
## a caller (the ammo bank, the lock channel, the kill handler) reads the flag once and
## asks the perk what it does. The three shipped perks (Embers/Leeches/Cartograph) keep
## their own call sites; these are the new rows' named consumers.
const PERK_ECHOES: StringName = &"echoes"
const PERK_LONG_WATCH: StringName = &"long_watch"
const PERK_PYRE: StringName = &"pyre"

## 15 section 4, `of Echoes`: "every 5th shot costs no ammo".
const ECHOES_EVERY := 5
## 15 section 4, `of the Long Watch`: "+2 s lock hold".
const LONG_WATCH_SECONDS := 2.0
## 15 section 4, `of the Pyre`: "a kill below 25 % hull detonates a 50-damage ring".
const PYRE_HULL_THRESHOLD := 0.25
const PYRE_RING_DAMAGE := 50.0


## Whether the shot at `shot_index` (1-based, the instance's own release count) is the
## free one when the summary carries `of Echoes`: every `ECHOES_EVERY`-th release costs
## no ammo. False for a summary without the perk, so the caller's ordinary spend stands.
static func echoes_refunds(data: Dictionary, shot_index: int) -> bool:
	if shot_index <= 0 or not has_suffix(data, PERK_ECHOES):
		return false
	return shot_index % ECHOES_EVERY == 0


## The lock channel's duration with `of the Long Watch` applied: `base` plus
## `LONG_WATCH_SECONDS` when the summary carries the perk, `base` otherwise.
static func lock_channel_seconds(data: Dictionary, base: float) -> float:
	if not has_suffix(data, PERK_LONG_WATCH):
		return base
	return base + LONG_WATCH_SECONDS


## The Pyre's ring damage: `PYRE_RING_DAMAGE` when the summary carries `of the Pyre`,
## else 0.0. `hull_fraction` is the victim's hull share at the killing blow; a kill at
## or above `PYRE_HULL_THRESHOLD` is not a below-quarter-hull kill and pays no ring.
static func pyre_ring_damage(data: Dictionary, hull_fraction: float) -> float:
	if not has_suffix(data, PERK_PYRE):
		return 0.0
	if hull_fraction >= PYRE_HULL_THRESHOLD:
		return 0.0
	return PYRE_RING_DAMAGE


## One cell's `instances` row, accumulating its prefixes into `totals` and its
## suffixes into `flags` as it is built. `fallback` is the cell's own id, used as
## the base id when the record does not name one (a record keyed by its base).
static func _row(
	slot: StringName,
	index: int,
	record: Dictionary,
	fallback: StringName,
	totals: Dictionary,
	flags: Array[StringName]
) -> Dictionary:
	var base := StringName(str(record.get(RECORD_BASE_ID, fallback)))
	var prefixes: Array = []
	for raw: Variant in _rows(record.get(RECORD_PREFIXES, [])):
		var id := StringName(_row_id(raw))
		if id == &"":
			continue
		var value := _row_value(raw)
		prefixes.append({KEY_ID: id, KEY_VALUE: value})
		totals[id] = float(totals.get(id, 0.0)) + value
	var suffixes: Array[StringName] = []
	for raw: Variant in _rows(record.get(RECORD_SUFFIXES, [])):
		var id := StringName(_row_id(raw))
		if id == &"":
			continue
		suffixes.append(id)
		if not flags.has(id):
			flags.append(id)
	return {
		KEY_SLOT: slot,
		KEY_INDEX: index,
		KEY_BASE_ID: base,
		KEY_PREFIXES: prefixes,
		KEY_SUFFIXES: suffixes,
	}


## The non-empty cells one slot type holds, in layout-index order: an Array keeps
## its own order and its `""` holes, a scalar slot (POWER) is one cell, and a
## missing or unknown key is no cells.
static func _cells(fit: Dictionary, slot: StringName) -> Array:
	var raw: Variant = fit.get(slot, fit.get(String(slot), null))
	if raw is Array:
		return raw
	if raw is String or raw is StringName:
		return [raw] if String(raw) != "" else []
	return []


static func _rows(raw: Variant) -> Array:
	if raw is Array:
		return raw
	return []


## A stored affix row's id: the record keeps `{id, value}` dictionaries, and a
## hand-built fixture may keep a bare id, which reads as the id itself.
static func _row_id(raw: Variant) -> String:
	if raw is Dictionary:
		return str((raw as Dictionary).get(KEY_ID, (raw as Dictionary).get(String(KEY_ID), "")))
	return str(raw)


## A stored affix row's value, `0.0` for a bare id: the value is what the roll
## stored, never re-derived from the band.
static func _row_value(raw: Variant) -> float:
	if raw is Dictionary:
		return float((raw as Dictionary).get(KEY_VALUE, (raw as Dictionary).get(String(KEY_VALUE), 0.0)))
	return 0.0
