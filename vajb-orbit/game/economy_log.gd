class_name EconomyLog
extends RefCounted
## Append-only economy debug log (01 §7): one line per economy event, written by
## the transaction functions in the exchange, refinery, shipyard and station
## services. Never shown in the UI, never read back at runtime; it exists so a
## balancing session can be replayed line by line afterwards.
## Contract: docs/gameplay/01_economy_core.md §7, docs/gameplay/17_coder_handoff.md §5.

const DEFAULT_PATH := "user://economy_log.txt"

## Overridable so tools can round-trip against a scratch file.
static var log_path: String = DEFAULT_PATH


## Appends `timestamp, event, item, qty, credits_delta, balance`. Never fails a
## transaction: an unwritable log warns and returns.
static func append(event: String, item: StringName, qty: int, credits_delta: int, balance: int) -> void:
	var line := "%s, %s, %s, %d, %s, %d\n" % [
		Time.get_datetime_string_from_system(true),
		event,
		String(item),
		qty,
		_signed(credits_delta),
		balance,
	]
	var file := _open_for_append()
	if file == null:
		push_warning("EconomyLog: could not open %s (error %d)" % [log_path, FileAccess.get_open_error()])
		return
	file.seek(file.get_length())
	file.store_string(line)


## READ_WRITE appends, but on 4.7.2 it refuses a path that does not exist yet
## (ERR_FILE_CANT_OPEN), so the first line creates the file and reopens it.
static func _open_for_append() -> FileAccess:
	var file := FileAccess.open(log_path, FileAccess.READ_WRITE)
	if file != null or FileAccess.file_exists(log_path):
		return file
	var created := FileAccess.open(log_path, FileAccess.WRITE)
	if created == null:
		return null
	created.close()
	return FileAccess.open(log_path, FileAccess.READ_WRITE)


static func _signed(value: int) -> String:
	if value >= 0:
		return "+%d" % value
	return "-%d" % absi(value)
