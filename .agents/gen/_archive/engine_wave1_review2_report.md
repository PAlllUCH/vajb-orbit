# Engine wave 1 — W8 re-review (review 2) report

Reviewer: W8. Scope: the files fixed by the W7 batch-1 pass (H1–H4, M1, M2 code
half) and the batch-2 pass (M3), the M4–M7 rulings as recorded in
`.agents/gen/engine_wave1_w7_report.md` §B5, and the W6 LOW findings as
regression checks. Method: **measure, never trust reports** — every number below
was re-derived from disk or by headless run on 2026-09-18.

**Result: all eight fixes verified fixed; no regression in the LOW set; two
observations recorded (neither is a code defect).** 40/40 probe checks, four
boot gates exit 0, P1 suite 53/53.

---

## 0. Gates run

```
# 1. W8 re-review probe (own harness, own geometry; scene run)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless \
  --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 1500 \
  res://tools/_probe_w8_rereview.tscn
-> exit 0, "=== w8 re-review probe: checks 40, failures 0 ==="
   (.agents/gen/engine_wave1_review2_probe.txt)

# 2-5. boot gates: game / menu / settings / station, each --quit-after 180
-> all exit 0. game/menu/settings: 159-byte clean logs (banner + godot_ai line).
   station: 408-byte log carrying the pre-existing 4 ObjectDB / 2 resource tail.
   (.agents/gen/engine_wave1_review2_boot_*.txt)

# 6. theme determinism check
... --headless --path <proj> --script res://tools/build_theme.gd --quit-after 120
-> exit 0; rebuild reproduced vajb_theme.tres at 25 771 B, md5
   F0BF1B434CB19EDD0FEE7001B17632B4 — W5's figures byte-for-byte
   (.agents/gen/engine_wave1_review2_theme_run.txt)

# 7. the P1 economy suite  (--quit-after 300 res://tests/headless_runner.tscn)
-> exit 0, "[SUMMARY] passed=53 failed=0"  (.agents/gen/engine_wave1_review2_tests.txt)
```

Every Godot run was bounded by `--quit-after`, ran in the foreground, and its
stdout was redirected to a log that was read afterwards; no command exceeded
60 s. The probe self-quit behind a 45 s watchdog and cleaned its own `user://`
scratch.

---

## 1. The eight fixes, re-measured

### H1 — profile cargo mirrors into PlayerState (game.gd) — FIXED

Source: `_sync_cargo()` sums `PlayerProfile.cargo_items()` and calls
`PlayerState.set_cargo_used(used)` only on change (`game.gd:464-476`); called
from `_refresh_hud()` (`game.gd:507`) and from `_on_profile_changed` keyed on
`PROFILE_CARGO_KEY = &"cargo"` (`game.gd:456-458`), connected in
`_connect_profile()` and disconnected in `_exit_tree()`. The profile signal
carries `key: StringName` and `add_cargo`/`remove_cargo` touch `KEY_CARGO`
(`player_profile.gd:29,216,229,395`), so a collection/sale/refinery job reaches
the HUD on the same call.

Measured live: boot `CARGO 0/40`; forced stale `set_cargo_used(0)` +
`_refresh_hud()` restored `profile=0 state=0 footer='CARGO 0/40'`; `add_cargo(3)`
mirrored `0 → 3` with no frame in between and the footer followed on the same
call; 3 of 40 cargo cells filled; a really-collected pickup moved the readout
and footer immediately (`3 → 5`); the hold-full state showed `CARGO 40/40` with
the `accent_danger` override set and cleared again when emptied.

### H2 — the ship collides with rocks (player_ship.tscn + player_ship.gd) — FIXED

Measured on the shipped scene: exactly one `CollisionObject2D` descendant, a
`CharacterBody2D` named `HullBody`, `collision_layer = 2`,
`collision_mask = 1` (`Asteroid.COLLISION_LAYER`), `motion_mode = 1`, carrying a
`CircleShape2D` radius **30.0**. The art derivation holds: the hull sprite is
905 px at scale 0.0663 = **60.0015 u** long, half = **30.0007** (measured with
Pillow on `ship_vanguard_side.png`), so the circle is the art half-length as
documented at `player_ship.gd:29-37`.

Independent collision geometry (rock at x = 300, W7 used 200): the ship, in the
tree, thrust 400 steps at 1/60, stopped at **x = 227.99988** against a contact
of `300 − 42.0 − 30.0 = 228.0` (the 0.0001 shortfall is `move_and_collide`'s
safe margin). 150 more thrust steps at the same heading moved it **0.0000** —
the stop is the rock, not a brake — and `_speed` was still **406.6** (max), so
momentum is untouched as disclosed. The body sits back at local **0.0** and the
ship owns its transform. Negative control: the same run with the ship not in the
tree passed through to **x = 2201.7263** — W6's pre-fix number, reproduced.
Spawn clearance over all seven rows, **two seeds each** (W7 used one): the
closest rock surface to any shipped spawn is **1112.76 u** against the 30 u
hull (W7 measured 1308.79 with their seed; both ~37× the hull radius, and the
geometry guarantees it — fields are placed at 1800 u from the sector centre,
the spawn 420 u out).

### H3 — `PlayerState.damage(amount, bypass_shield := false)` — FIXED

Measured: `damage` declares **2** arguments. With hull 500 / shield 100,
`damage(150)` left **hull 500 / shield 0** with exactly one `shield_changed`
and zero `hull_changed` (no carry-over); the next point came off the hull
(499); `damage(150, true)` left **hull 350 / shield 100**; a hit larger than the
shield (90 vs 40) did **not** spill into the hull; non-positive amounts are
no-ops; a lethal bypass hit still emitted `died`. All seven H3 checks pass.

### H4 — the reticle state is pushed from game.gd — FIXED

`_push_reticle_state()` (`game.gd:392-405`) reads the cached `_laser`, mirrors
`_reticle_state`, and is called from `_physics_process` every frame
(`game.gd:135`). Measured through the live scene's own pusher with a `w_mining`
fit mounted on the launch ship: reticle **PLAIN at rest → IN_RANGE** with the
beam active and a rock under the cursor (`has_target() = true`) →
**OUT_OF_RANGE** with the beam still active after the rock was freed →
**PLAIN** on release. (See observation 1: the launch fit itself has no laser,
so the two mining states are only reachable once the module is fitted.)

### M1 — one hold source for the pickup gate — FIXED

`pickup.gd:134-161`: `_hold_has_room(ship)` reads `_ship_hold(ship)`, which
returns `ship.cargo_max()` when the node exposes it and falls back to
`ShipFit.HULLS[profile.active_ship].cargo` otherwise; the station catalogue's
`cargo` column is no longer consulted (`station_catalog.gd` is not preloaded in
the file). All nine `ShipFit.HULLS` cargo values are non-zero (25/40/55/60/35/
120/50/60/80, measured), so the `capacity <= 0` refusal can never strand a hull.

Measured: the two tables still disagree on **5 of 9** hulls; the accessor hold
(40) equals `PlayerState.cargo_max` (40) and the boot footer; a stand-in without
the accessor resolves 40 for the Vanguard and **55** with the profile on
`ship_miner`; with the profile on `ship_miner` (no catalogue row) an ore pickup
on the ship **collected** (cargo 7 → 8); a full hold left an in-range pickup
(42.43 u away, inside `TRACTOR_RANGE` 120) unmoved and uncollected over 30
steps.

### M2 — `REBINDABLE_ACTIONS` 15 → 17 (code half) — FIXED, ruling honoured

Measured: `rebindable_actions()` returns **17** in `PROJECT_SETTINGS_PATCH.md`
§2 order with tail `[&"interact", &"warp"]`; `binding_text` returns `""` for
both (unbound); `InputMap.has_action` is **false** for both and
`ProjectSettings` has no `input/interact` key — the orchestrator's application
step is still outstanding, as the ruling expects. Every reader of the list is
`InputMap.has_action`-guarded (`settings_manager.gd:153,164,177,189,309,328`),
and the settings screen builds one row per action
(`settings.gd:176` `_build_rebind_rows`). The dock prompt still works with both
actions unapplied: hidden 900 u from the station, `F · DOCK` inside.

### M3 — the mining laser is gated on `w_mining` — FIXED, ruling honoured

Source: `MINING_MODULE := &"w_mining"` (`player_ship.gd:27`), the gate in
`_sync_mining_laser()`/`_has_mining_module()` (`:327-336`), the release path
(`:339-345`), the guard repeated in `_update_mining_laser()` (`:378-385`), and
`game.gd:229` passing `ShipFit.fitted_ids(ShipFit.STANDARD_FIT)`.

Measured with this reviewer's own geometry (stand-off 212 u, W7 used 200):
standard fit ids carry no `w_mining`; a fit carrying the module resolves with
it; without the module no laser mounts and holding `mine` for two full cycles
mines **nothing** (rock yield 5 → 5, 0 pickups); with the module the laser
mounts and mines **exactly one unit per cycle** (yield 5 → 4 → 3 across two
cycles, one pickup per cycle, both outside tractor range); the pinned
two-argument `setup(stats, state)` still runs (no laser, `hull_max = 1000.0`,
ship in the `player_ship` group); the module mounts on demand and a hull swap
back to the standard fit releases it (0 live laser nodes). On the live launch
scene: no laser node, `game._laser = null`, a rock 150 u away under `mine` for
two cycles produced no work, no pickup and a PLAIN reticle.

---

## 2. The rulings, verified rather than re-opened

- **M4 (keep sector 7 station-less) — honoured.** `sector_registry.gd` is
  byte-identical to W6's measured hash `C3F3AE450CEF4F03FAE0233EA4DB2077`, and
  `sector_7` still passes `_densities(6, 8, 0, 0, 0)` — the third parameter is
  `stations` (`sector_registry.gd:139-145`). `sector.gd` unchanged
  (`02BE97B023CED32ABA4D7023DA69B5B8`).
- **M5 (keep the WorldClock band respawn) — honoured.** `asteroid_field.gd`
  unchanged (`6A299942EDD699974F04D4AFD20C5DDD`); the stamp-then-roll behaviour
  (`last_respawn_time` set before the new rocks roll, `:98-112`) and the
  sector's band-driven `_respawn_cycle()` (`sector.gd:204-239`) are exactly as
  W3/W4 shipped them.
- **M6 (keep the always-visible cursor reticle) — honoured.**
  `target_reticle.gd` unchanged (`98FEA21048E6746F9B6D3ACA2DF7BDD5`).
- **M7 (doc-only) — honoured, still open.** `docs/gameplay/02_minerals.md:190`
  still reads "Asteroid combat … the mining laser is the only extraction tool
  in v1" (mtime 10:25, i.e. before the fix passes); the one-sentence
  transcription into 02 §9 is still owed to a doc pass.

---

## 3. Regression checks (the LOW set)

- **Scope:** a full mtime sweep of `vajb-orbit/` shows the wave's code footprint
  is still exactly the six batch-1 files (17:45–17:59) plus the two batch-2
  files (18:06–18:07). No `docs/`, `assets/` or `addons/` byte was written by
  any pass, and nothing moved after 18:07 except this review's own probe.
- **Frozen artefacts:** `project.godot` (6 417 B, `1E69D6C2…`), the HUD quartet
  (`hud.gd 0AE885AC…`, `hud.tscn 343D63F2…`, `minimap.gd 8EB85539…`,
  `target_reticle.gd 98FEA210…`), `mining_laser.gd|.tscn` (W3's, byte-identical)
  and `tools/build_theme.gd` all match the W6/W7 baselines. `vajb_theme.tres`
  rebuilds byte-identically from `build_theme.gd` (gate 6), which also proves
  the wave added **no theme item**.
- **L1 (invented constants):** the only new numbers are `radius = 30.0`
  (art-derived, re-verified above) and the id constant `MINING_MODULE`; neither
  re-tunes a §13 value. The six changed files are LF-only, tab-indented and
  contain no hex literal (measured).
- **L2/L3 (beam look, chip cue):** `mining_laser.gd` untouched — no drift.
- **L4 (additive API):** `setup`'s third parameter is defaulted and additive;
  the pinned `setup(stats, state)` call is measured working (M3 d); the frozen
  HUD API is untouched by hash.
- **L5/L6/L7/L8/L9:** untouched files, so no drift; `_fire`'s ammo decrement and
  the interim `SECTOR_NAME` label are unchanged (pre-existing, not this wave's
  scope).
- **L10 (process):** this pass archives its own probe log; the probe source was
  a throwaway and is deleted (see §5).

**Gates:** four boot scenes exit 0 with no new output; the P1 suite is 53/53.
The station gate reproduces the pre-existing 4 ObjectDB / 2 resource exit tail
(`station.tscn`), matching W7's batch-2 log; this run's menu gate was clean
(159 B) where W7's carried the tail, i.e. the leak is non-deterministic between
runs, not introduced here.

---

## 4. Observations (not defects, for the orchestrator/owner)

1. **The slice-1 reticle states and the mining loop are unreachable on the
   launch fit — the direct, disclosed consequence of the M3 ruling.** The
   launch always resolves `ShipFit.STANDARD_FIT` (`game.gd:190,229`), which
   carries no `w_mining`, so the shipped launch ship mounts no laser, `E` is
   inert, and `H4`'s IN_RANGE/OUT_OF_RANGE states are only reachable once the
   module is fitted (this review proved them by fitting it on the live ship).
   ENGINE_SPEC §14 says the fit stays the 09 §7 standard fit until P2's fitting
   UI lands, so this is the spec's own cost of the W-slot rule — but it means
   the mine → pickup → cargo chain, and with it H1's primary producer, has no
   shipped path in slice 1. Worth one line in the phase notes so nobody reads
   the dead `E` key as a bug.
2. **Filesystem mtimes are unreliable on this drive.** `game/game.tscn`,
   `game/economy_log.gd` and `ui/theme/grain.tres` carry 18:20 mtimes (inside
   this review's window) though nothing wrote them: their sizes/hashes are
   consistent with their pre-wave state (`game.tscn` still holds the wave-1
   starfield + camera, `economy_log.gd` still documents `static var log_path`
   as the pre-existing override the W6 probe already used, and the theme
   rebuild proved the theme path byte-stable). Hashes, not mtimes, are the
   identity test on this workspace — the W7 reports' hash-based claims all
   verified.

---

## 5. Probe hygiene

- One throwaway probe (`extends Node`, `quit()`-terminated, 45 s watchdog,
  scene run because `game.gd`'s autoload references cannot compile in a
  `--script` main loop), bounded by `--quit-after 1500`, stdout redirected to
  `.agents/gen/engine_wave1_review2_probe.txt`. Two earlier runs of the same
  probe (one with a parse error, one with two harness-side failures that the
  fix re-ran clean) are superseded by the final log.
- The probe repointed `PlayerProfile.save_path` and `EconomyLog.log_path` at
  scratch files, restored the manifest it perturbed, cleared the dirty flag and
  debounce before exit, and removed its scratch files (`user://` verified clean
  afterwards). `user://profile.cfg` and `user://economy_log.txt` were last
  written at 18:13, before any review run, and were not touched.
- The probe source and its `.uid` sidecar are deleted: `vajb-orbit/tools/`
  ends holding only `build_theme.gd` and `derive_icon_tints.gd` (+ their
  `.uid`s), re-verified after deletion.
