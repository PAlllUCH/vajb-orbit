# W7 pass — the owner's `user://profile.cfg` (measured, 2026-09-21)

Why this file exists: a gate run rewrote the owner's live profile during this pass
(723 -> 1636 bytes) and the discipline in force says every such change must be attributed
and measured, not hand-waved. Nothing in the W7 fix set writes it; the evidence below is the
attribution. It is **not** one of the reviewer's findings and W7 did not change any file for
it (the writer is `test_engine2_pools.gd`, another worker's suite).

Path measured (Godot 4.7.2 `user://` for this project):
`C:\Users\Kamil\AppData\Roaming\Godot\app_userdata\Vajb Orbit\profile.cfg`

## The observations, in order

| When | Size | md5 | mtime | What ran in between |
|---|---|---|---|---|
| 09:08 | 723 | `dd628234b36e6f3611ba7cdeeba37dec` | - | baseline, recorded twice around a scoped `test_engine2_fixes` run: **unchanged** |
| 09:12:50 | 1636 | `e2ade7725d017db153e7ff2ca8403609` | 09:11:51 | the window held the W6 probe run, the full gate and the five boot gates |
| 09:13:17 | 1635 | `ec0a09b501ab0d063242ec1d83e96d62` | 09:13:17 | a second full gate run |
| 09:17:25 | 1635 | `ec0a09b501ab0d063242ec1d83e96d62` | 09:17:25 | a scoped `test_engine2_pools` run |
| 09:18:34 | 1635 | `ec0a09b501ab0d063242ec1d83e96d62` | 09:17:25 (unchanged) | the recorded final full gate |

The 723 -> 1636 growth is a **normalisation write**, not new data: the file it replaced
carried empty/short dictionary blocks, and the write persisted the in-memory state
(`_read_values` -> `_normalise_market` fills `market` demand/stock/queue/trend from the
defaults). Content read back: `save_version=3`, `credits=10000`,
`owned_ships=["ship_vanguard"]`, `vitals={}`, `cargo={}`, `upgrades=[]`, all five packs 300 -
i.e. the same state the small file described, serialised in full.

## Who writes it: a per-suite bisect (mtime is the write detector, since a converged
## rewrite leaves the bytes identical)

Each suite was run alone (`--suite=<name>`) and `st_mtime_ns` compared before and after:

- **`test_engine2_pools` — WROTE** (mtime moved; bytes 1635 -> 1635, identical content).
- clean (mtime and md5 both unchanged): `test_p1_catalogues`, `test_p1_clock_log`,
  `test_p1_market`, `test_p1_pricing`, `test_p1_profile`, `test_p1_refinery`,
  `test_p1_repairs`, `test_engine2_cleaving`, `test_engine2_damage`, **`test_engine2_fixes`
  (this pass's own suite)**, `test_engine2_hud`, `test_engine2_loot`, `test_engine2_npc`,
  `test_engine2_weapons`, `test_engine2_wiring`.
- clean: all five boot gates run one at a time (`game`, `boot`, `main_menu`, `settings`,
  `station`, `--quit-after 300`).

## Mechanism (read from the shipped suite)

`vajb-orbit/tests/test_engine2_pools.gd` is the one suite that borrows the **real autoload**
(`_service()` = `/root/PlayerProfile`) instead of a throwaway instance:

- `setup()` line 45: `_profile.save_path = SCRATCH_PROFILE`
- `teardown()` lines 50-57: restores the cargo it spent (`add_cargo`/`remove_cargo` ->
  `_touch` -> `_dirty = true`) and then `_profile.save_path = Profile.SAVE_FILE` **while the
  store is still dirty and its 0.5 s debounce timer is still pending**.

The pending write therefore lands on the owner's real path - at the debounce (if a frame
elapses inside the window) or in the exit flush (`PlayerProfile._notification(EXIT_TREE)` ->
`flush()` -> `_write_profile()`), whichever comes first. That is why the bisect catches it
sometimes and not others: it is a race between the debounce and the runner's teardown, and the
final full gate happened not to lose it.

One-line cure for whoever owns that suite (W7 did **not** apply it, to keep this pass to its
three findings): `_profile.call(&"flush")` immediately before line 57, so the debounce and the
dirty flag are settled while the scratch path is still in place.

## Why W7's own suite cannot do this

`test_engine2_fixes.test_the_dock_report_settles_a_fired_pack` borrows the same autoload, but
in the safe order, and the order is the point: snapshot the store -> point `save_path` at the
scratch -> run the filing -> write the snapshot back -> `flush()` (dirty cleared, timer
stopped, on the **scratch** path) -> restore `save_path`. Measured: `profile.cfg` byte- and
mtime-identical across two scoped runs of that suite, and across the final full gate.
