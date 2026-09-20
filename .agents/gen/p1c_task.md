# P1c task — PlayerProfile save migration v1 -> v2 (docs 17 §3, 01 §7, STATION_SPEC)

Worker: coder. Wave: P1 economy core. Deliverable: exactly one edited file:

`vajb-orbit/autoload/player_profile.gd`

Do not touch any other file. No MCP tools. Do not run the editor. Do not edit
`project.godot`, `addons/`, docs, or any other script.

## Read first

- `vajb-orbit/autoload/player_profile.gd` — the whole file. It must keep its
  entire existing public API and behaviour (STATION_SPEC.md §2 is frozen).
- `docs/gameplay/17_coder_handoff.md` — §3 only (persistence table + signal
  keys). This is the contract for the new state.
- `docs/design/STATION_SPEC.md` — §2 and §3 (existing API, save file, load
  outcomes). The new work extends §3; it must not contradict §2.
- `docs/gameplay/01_economy_core.md` — §5 `last_band`/market context only.

## What changes

### 1. Version

`const SAVE_VERSION := 2`. `_load_profile()` accepts **version 1 and
version 2** for reading (1 = migration: new keys come up at defaults, that is
normal, no warning; 2 = normal read). Any other version keeps today's
behaviour: `push_warning` + defaults. Writes always persist `save_version = 2`.
Keep the existing header contract comment from `STATION_SPEC` and append a
short P1 note: keys below added by gameplay doc 17 §3 (save v2) plus the
`vitals` extension approved for the 01 §6 repairs panel.

### 2. New persisted state (all keys under `[profile]`, all written by
`_write_profile`, all read by `_read_values`)

| Key | Type | Default | Notes |
|---|---|---|---|
| `modules` | Dictionary | `{}` | module_instance_id -> Dictionary (17 §3, data only for now) |
| `fits` | Dictionary | `{}` | ship_id -> Dictionary (data only for now) |
| `market` | Dictionary | shape below | 05 §2/§4 |
| `heat` | Dictionary | `{}` | faction_id -> int (data only for now) |
| `standing` | Dictionary | `{}` | faction_id -> int (data only for now) |
| `contracts` | Array | `[]` | max-3 active list (data only for now) |
| `vaults` | Dictionary | `{}` | station_id -> Dictionary (data only for now) |
| `insured` | bool | `false` | 14 §3 |
| `mercy_used` | bool | `false` | 14 §3 |
| `vitals` | Dictionary | `{}` | ship_id -> `{"hull": int, "shield": int}` (01 §6 repairs; approved extension) |

`market` normalised shape (all sub-keys always present after read or set):
`{"demand": {}, "stock": {}, "queue": {}, "trend": {}, "last_band": 0}`.
Dictionary keys inside the new state are plain `String` values at every
level; the existing `_read_qty` / `_keys_to_strings` helpers are unchanged
and still serve `cargo` / `ammo`.

Loading must be per-field tolerant in the existing style: a missing new key
falls back to its default, a wrong-typed new key is ignored with
`push_warning` and falls back to default (mirror `_read_int` / `_read_qty`).
Never let a v1 file produce a warning for the missing new keys.

### 3. Public accessors (new, additive)

Getters return deep copies (`duplicate(true)`) so callers cannot mutate live
state. Setters store a deep copy; a set with an equal value is a no-op (no
signal, no save). Signal rule from 17 §3: exactly `modules`, `fits` and
`standing` emit `profile_changed` with that key; every other new key persists
silently. The existing five keys keep their exact current behaviour.

- `func modules() -> Dictionary` / `func set_modules(value: Dictionary) -> void` -> emits `&"modules"`
- `func fits() -> Dictionary` / `func set_fits(value: Dictionary) -> void` -> emits `&"fits"`
- `func standing() -> Dictionary` / `func set_standing(value: Dictionary) -> void` -> emits `&"standing"`
- `func market() -> Dictionary` / `func set_market(value: Dictionary) -> void` (silent)
- `func heat() -> Dictionary` / `func set_heat(value: Dictionary) -> void` (silent)
- `func contracts() -> Array` / `func set_contracts(value: Array) -> void` (silent)
- `func vaults() -> Dictionary` / `func set_vaults(value: Dictionary) -> void` (silent)
- `func insured() -> bool` / `func set_insured(value: bool) -> void` (silent)
- `func mercy_used() -> bool` / `func set_mercy_used(value: bool) -> void` (silent)
- `func vitals_of(ship_id: StringName) -> Dictionary` — `{}` when unknown;
  otherwise `{"hull": int, "shield": int}` (copy).
- `func set_vitals(ship_id: StringName, hull: int, shield: int) -> void` —
  clamps both at 0, empty id is ignored (silent).

Internal: keep `_touch(key)` emitting exactly as today; add a private
`_mark_dirty()` used by the silent setters (dirty + debounce timer + write,
no signal). `_touch` must keep working for the existing five keys.

### 4. `reset_to_defaults()`

Also clears every new key to its default (market back to the empty shape,
vitals empty). Its emitted signal set stays exactly the current five keys
(contract in STATION_SPEC §2.7 is unchanged).

### 5. Test/support hooks (documented as such in the header)

- `var save_path: String = SAVE_FILE` — `_load_profile()` and
  `_write_profile()` use `save_path` instead of the `SAVE_FILE` constant.
  Default behaviour is byte-identical for production.
- `func reload() -> void` — re-reads the file through the current
  `save_path`: `_config = ConfigFile.new()` then `_load_profile()`.
- These exist for the P1 test suites and migration fixtures. No other
  behaviour may depend on them.

## Existing behaviour that must not regress

- `profile_changed` payloads and ordering for `credits`/`ammo`/`ships`/
  `upgrades`/`cargo`; `purchase_failed` reasons; `spend`/`add_credits`
  guards; clamping; the debounce timer; `flush()` on close; default values;
  no `class_name` line (autoload collision); typed GDScript and tabs.

## Parse + behaviour gate (required)

Create a probe scene `res://tools/_probe_p1c.tscn` + `_probe_p1c.gd` (off-tree
profile instances only — never point `save_path` at `user://profile.cfg`).
The probe must prove, with assertions and printed evidence:

1. Fresh defaults: credits 10000, `market()` shape complete, `vitals_of(&"ship_vanguard")` `{}`.
2. A hand-written **v1 fixture** at `user://p1c_probe_v1.cfg` (`save_version=1`,
   credits 1234, owned ships + cargo + ammo in today's format) loads after
   `reload()`: credits/owned/cargo preserved, every new key at default, no
   warning for new keys.
3. A **v2 round trip** at `user://p1c_probe_v2.cfg`: set non-trivial values on
   all ten new keys (including vitals), `save()`, build a second instance,
   `reload()`, assert deep equality for all of them.
4. Getter copies: mutating a returned dictionary does not change the profile.
5. Silent keys emit nothing; `set_modules` / `set_fits` / `set_standing` emit
   exactly one `profile_changed` with that key; an equal set emits nothing.
6. Delete both probe cfg files at the end; print `PROBE OK`; quit.

Run:

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1c.tscn --quit-after 300

Requirements: exit 0, stdout contains `PROBE OK`, no `SCRIPT ERROR`. Do NOT
use `--check-only --script`. Delete the probe files and any `.uid` sidecars
they got before you finish. **Never** let the probe touch
`user://profile.cfg`.

## Shell notes (this workspace)

- `grep`, `head`, `tail`, `wc` are absent; use PowerShell `Select-String` /
  `Get-Content` or `py -3.14`.
- The bash tool strips `$` before PowerShell sees it — write PowerShell with
  no `$`.
- `py -3.14` is the working Python; bare `python` is not.

## Report (required)

Write `.agents/gen/p1c_report.md`: what changed (line-range level), exact
commands with observed output, probe assertions with results, and every
deviation. Under 100 lines.
