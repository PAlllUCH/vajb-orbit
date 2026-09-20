# P1c report — PlayerProfile save v1 -> v2 migration

Deliverable: `vajb-orbit/autoload/player_profile.gd` (the only edited file).
Probe files `_probe_p1c.gd` / `_probe_p1c.tscn` were created, run and deleted;
no `.uid` sidecars were produced; `user://profile.cfg` was never written.

## What changed (file is 678 lines)

| Lines | Change |
|---|---|
| 1-12 | Header: STATION_SPEC contract comment kept, P1 note appended (17 §3 keys + `vitals` from 01 §6, test hooks). |
| 21-22 | `SAVE_VERSION := 2`; new `MIN_READABLE_VERSION := 1`. |
| 31-37 | New signal keys `KEY_MODULES`/`KEY_FITS`/`KEY_STANDING`; `MARKET_KEYS`. |
| 56-58 | `var save_path: String = SAVE_FILE` (test/support hook, documented as such). |
| 73-82 | New state: `_modules`, `_fits`, `_market` (inline normalised shape), `_heat`, `_standing`, `_contracts`, `_vaults`, `_insured`, `_mercy_used`, `_vitals`. |
| 233-359 | Ten new accessor pairs: `modules`/`set_modules`, `fits`/`set_fits`, `standing`/`set_standing` (each `_touch`es its key), `market`/`set_market`, `heat`, `contracts`, `vaults`, `insured`, `mercy_used` (each `_mark_dirty()`), `vitals_of` + `set_vitals` (clamp at 0, empty id ignored). Getters return `duplicate(true)`. |
| 375-377 | `reload()`: `_config = ConfigFile.new(); _load_profile()`. |
| 399-405 | `_mark_dirty()`: dirty + debounce timer + write, no signal. `_touch` untouched (389-397). |
| 435-458 | `_load_profile()`: reads via `save_path`; accepts `version 1..SAVE_VERSION`; outside that range keeps today's warning + defaults. Writes always persist `save_version = 2` (643). |
| 460-480 | `_apply_defaults()` also clears every new key (market back to the empty shape). |
| 482-508 | `_read_values()` reads all ten new keys last; existing five untouched. |
| 546-599 | `_read_plain_dict`, `_read_plain_array`, `_read_bool`, `_read_vitals`, `_vital_number` (per-field tolerant; missing key = silent default). |
| 601-638 | `_market_default`, `_normalise_market` (all five sub-keys always present), `_to_plain` (deep copy + String keys at every level). |
| 640-665 | `_write_profile()` writes the ten new keys and saves through `save_path`. |

`reset_to_defaults()` (380-387) is unchanged: it still emits exactly the five
existing keys, and `_apply_defaults` now clears the new state underneath it.

## Commands and observed output

    "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tools/_probe_p1c.tscn --quit-after 300

Run 1 (pre-fix): `EXIT=0`, 54 PASS / 0 FAIL, `PROBE OK`, but eight blocks of
`ERROR: Couldn't find the given section "profile" and key "modules", and no default was given.`
(`get_value` treats a `null` default as "no default supplied" *and* errors).
Fix: `_read_plain_dict` / `_read_plain_array` now pre-check
`_config.has_section_key(SECTION, key)` and pass a real `{}` / `[]` default.

Run 2 (final):
- `EXIT=0`, `[P1c] all 61 checks passed`, `PROBE OK`
- `ERROR` lines: 0, `SCRIPT ERROR` lines: 0
- `WARNING` lines: 5, all *after* the step-7 marker (marker = log line 62,
  warnings = lines 64/73/82/91/100) and all from the deliberate wrong-type
  fixture. Lines 1-62, i.e. the whole fresh-defaults / v1-migration / v2
  round-trip / copy / signal sequence, are warning-free.
- Production `user://profile.cfg` (on disk: `save_version=1`) was loaded by the
  autoload in both runs with no warning; its mtime stayed `2026-09-18 11:00:08`
  across runs at 11:18-11:20, so it was read and never rewritten.
- `user://` contained no `p1c` file after the run; `tools/` holds no probe
  files and no probe `.uid` sidecar.

## Probe assertions (61 checks, all passed)

1. Fresh defaults (absent file): credits 10000; `market()` has exactly 5 keys,
   `demand`/`stock`/`queue`/`trend` empty dictionaries, `last_band == 0`;
   `vitals_of(&"ship_vanguard") == {}`; modules/fits/heat/standing/contracts/
   vaults empty; `insured`/`mercy_used` false; no file created.
2. Hand-written v1 fixture (`save_version=1`, credits 1234, ships, cargo, ammo):
   loads through `reload()`; credits, owned ships (`ship_vanguard`,
   `ship_lancer`), active ship, upgrades, `cargo_qty(&"ore_iron") == 7`,
   `ammo_of(&"laser") == 55` preserved; every new key at its default; the file
   on disk still reads `save_version == 1` (no boot overwrite).
3. v2 round trip: non-trivial values on all ten new keys, `save()`, second
   instance, `reload()`; deep equality for all ten; file stores
   `save_version = 2`; every dictionary key is a plain `String` at every level.
4. Getter copies: mutating a returned `modules()` / nested `market()` /
   `vitals_of()` / nested `contracts()` copy leaves the profile unchanged.
5. Signals: `set_heat`, `set_market`, `set_contracts`, `set_vaults`,
   `set_insured`, `set_mercy_used`, `set_vitals` (and `set_vitals(&"", ...)`)
   emit nothing; `set_modules` / `set_fits` / `set_standing` emit exactly one
   `profile_changed` with their key; an equal set emits nothing;
   `add_credits` / `add_cargo` still emit `credits` / `cargo`.
6. Both probe cfg files (plus the step-7 fixture) deleted, `PROBE OK`, quit 0.
7. (Extra) Wrongly typed new keys (`modules`/`market`/`vitals` = non-dict,
   `contracts` = int, `insured` = string) fall back to their defaults with one
   `push_warning` each; `credits` still reads 4321 from the same v2 file.

## Deviations

1. Steps 1-6 are as specified; step 7 (wrong-type fallback) is an addition, kept
   last so the v1 no-warning evidence stays separable, with its own throwaway
   fixture `user://p1c_probe_bad.cfg` (also deleted).
2. `has_section_key` pre-checks in the two new container readers, as described
   above. Behaviour is per-spec; only the mechanism differs.
3. Probe steps 4 and 5 deliberately reuse the v2 file left by step 3 (documented
   inside the probe) instead of writing more fixtures.
4. `market` is initialised inline to the normalised shape so `market()` is
   complete even before a read, not just after `_apply_defaults`.
5. Assertions beyond the six proofs: `save_version == 2` on disk and the
   String-key check at every level.
6. The run log was kept only while extracting the evidence above and then
   deleted; no other file was created or modified.
