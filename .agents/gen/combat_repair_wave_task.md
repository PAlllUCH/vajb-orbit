# Wave Combat/collision repair — task brief

Law, in order: `AGENTS.md`, `docs/CONTRACTS.md` (v1.1, §4 collision pins, §8.2 the
slice-2 weapon pins), `docs/gameplay/18_engine_spec.md` (§2.1 rulings, §4.1/§4.2,
§6 cleaving, §13 numbers), this brief, `.agents/gen/WAVEBOARD.md`. Evidence:
`.agents/gen/owner_playtest_findings_20260921.md` (the owner's live report with the
measured lines). **No number is re-derived here; every figure below is quoted from
those sources or from the probes this wave will run.**

## Owner rulings this wave executes (2026-09-21)

1. **Weapon fire must damage asteroids.** Today `game/asteroid.gd` exposes
   `apply_work(amount)` (the mining cleave) and no `take_damage`/`damage`, so
   `game/weapons.gd:_deliver` returns silently and a shot at a rock does nothing.
   The rock gains the sink and weapon damage reaches it through the same cleave
   channel. The damage→work conversion is a **new unpinned value**: implement it as
   one named constant, state it as a proposal with its reversal path, and record it
   for the owner's tick in §13.
2. **The flight drag/inertia is retuned now.** The owner wants inertia without the
   "weird drag" (a press-and-release still carries the hull for about a second). The
   shipped pair is the flight model's own (`DRAG` 120 / `ACCELERATION` 420, §13-
   adjacent feel numbers, CONTRACTS §9.8 item 4 territory). The retune is measured:
   a decay curve before and after, old and new constants, and every §13 row it does
   **not** touch stated explicitly.

## What is already measured (do not re-litigate)

- The trigger works: in a live direct-scene run, `fire_primary` set
  `is_firing()` true and drained Energy 100.0 → 93.73 over ~1 s (the 6 E/s beam
  draw), `dry_reason()` empty, `fitted()` `["laser"]`.
- `game/impact.gd` gives a contact free below `COLLISION_MIN_DV` 40.0 u/s
  (`COLLISION_FACTOR` 2.0e-5) — §13's own row.
- `game/player_ship.gd:_on_hull_body_entered` charges the player's half through
  `Damage.ram` (which applies to `self`) and offers the peer's half through
  `apply_collision_damage`; `game/npc_ship.gd:338` implements it, `Asteroid` does not.
- `game/asteroid.gd:193-194` sets `collision_layer = 1`, `collision_mask = 0`.
- **The orchestrator's live ram probe was invalid** (the ship root's transform is
  owned by `HullBody`, so the teleport did not hold and no contact ever happened).
  Never cite it. CONTRACTS §9's trap list is law here: a live but *unfocused* game
  window is unreliable, and a `--script` run cannot exercise `Input` state. Probes
  are deterministic headless scenes, as `tests/probe_w5_lint.tscn` is.

## Dropped by the owner

- The reticle jump after launch and the "ship fires in the hangar" observation: the
  owner reports both resolved. No probe, no fix. `ui/screens/station.gd` contains no
  `WeaponComponent` and no fire handling, so the hangar shot had no weapon path.

## Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| **C1** | coder — ram probe | `vajb-orbit/tests/,vajb-orbit/tools/` | A deterministic headless ram probe: a hull driven into a rock with a fixed velocity step, measuring the rock's velocity and position delta, both sides' pool deltas, and whether `collision_mask = 0` makes the pair one-way (test the same ram with the mask corrected, in memory only, to separate the mask from the missing sink). Report the root cause with the raw numbers and name the file that must change. **Do not fix.** |
| **C2** | coder — weapon probe | `vajb-orbit/tests/,vajb-orbit/tools/` | A deterministic headless weapon probe: each of the five families fired at an NPC hull (damage landed, shield-first, `bypass_shield` for the kinetic/missile rows) and at a rock (the exact no-op path, with the sink name that is missing). Also cover the **real launch fit** (five weapons, 1 500 rounds) rather than a single laser, and record `dry_reason()` per family so an empty group is distinguishable from a broken one. **Do not fix.** |
| **C3** | coder — flight decay probe | `vajb-orbit/tests/,vajb-orbit/tools/` | A deterministic headless probe of the hull's velocity decay after a release: the curve (velocity and distance per 0.1 s) for the shipped `DRAG`/`ACCELERATION` pair, plus the afterburner case, and the numbers a retune must beat (time to 10 % and distance carried). Report the curve; **do not retune** — C5 does that with these numbers. |
| **T1** | coder — tooling | `staging/phase_f/apply_import_settings.py` | Add an `--only <pattern…>` scope so the tool touches only the named files/globs, keeping the current behaviour as the default. The graphics lane is blocked on this: unscoped, the tool rewrites 1080 of 1620 `.import` files. Prove it with a dry run that reports the counts for both modes. |
| **C5** | coder — fixer | `vajb-orbit/game/asteroid.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/impact.gd,vajb-orbit/tests/` | Only what C1–C3 prove broken, one pass: the rock's collision half (mask/pair) and its damage sink per ruling 1; the drag retune per ruling 2, with C3's curve as the before/after evidence; a test per fix. Every changed constant and the reversal path go in the report. |
| **C6** | coder — reviewer (**mandatory**) | `vajb-orbit/tests/,vajb-orbit/tools/` | Re-runs every C1–C3 probe byte-identically and re-measures C5's after-numbers; checks CONTRACTS §4/§8.2 for drift; verifies that no §13 row moved except the two recorded deviations; tiers HIGH/MED/LOW. LOW → `.agents/gen/LOW_BACKLOG.md`. |

Run order: **C1 · C2 · C3 · T1 in parallel**, then **C5**, then **C6**. A fixer pass
(C7) follows only if C6 leaves HIGH or MED.

## Hard rules

- `VAJB_WORKER_FILES` exactly as tabled; the PreToolUse hook denies writes outside it
  (and denies absolute paths on this host — use workspace-relative paths).
- Bounded Godot runs only (`--quit-after N`, stdout to a log the worker reads).
- Probe hygiene (L17): a probe that repoints `PlayerProfile.save_path` must
  stop/flush the 0.5 s debounce before restoring it.
- The gate is `godot --headless --path vajb-orbit res://tests/headless_runner.tscn
  --quit-after 1200`, measured at **passed=226 failed=0** before this wave. Grow the
  count; never shrink it, never edit a test to hide a failure.
- No assets, no theme, no `project.godot`, no `addons/**`, no `docs/**` (the doc
  ticks are a separate pass). `docs/gameplay/18_engine_spec.md` is owner-locked.
- A load failing only on a missing sprite/texture path is *environment-deferred*, not
  a finding.

## Close-out (orchestrator)

Gate re-run; `python3 staging/verify_wave.py verify --baseline combat_repair_start
--forbidden project.godot --expect-reports <the wave's reports> --tests`; WAVEBOARD
updated (this wave Done, the owner's rulings recorded, slice 2.5 unblocked);
wave-boundary commit; report to the owner with the retune's old/new numbers and the
damage→work constant awaiting their tick.
