# F4 report — the one-pass fix of the weapon FX & audio review findings (2026-09-21)

Fixer: **F4**. Authority for every finding below is `.agents/gen/weapon_fx_f3_report.md`
(one HIGH, three MED), measured by F3 and re-measured here; the wave's rules are
`.agents/gen/weapon_fx_wave_task.md`.

File set used: `vajb-orbit/game/weapons.gd`, `vajb-orbit/autoload/audio_manager.gd`,
`vajb-orbit/tests/` (the fixer's own declared set). Written:

| Path | What it now holds |
|---|---|
| `vajb-orbit/game/weapons.gd` | the beam's hit read (H1) and the held beam's bed (H1), the beam-killed rocket's blast (M3) |
| `vajb-orbit/autoload/audio_manager.gd` | the pool's own-voice rule (M1), the per-bed loop voices with priority/lease/cue-scoped stop (M2) |
| `vajb-orbit/tests/test_weapon_fx_f4.gd` | six tests, one per fix plus the two seams the fixes created |
| `vajb-orbit/tests/probe_f4_weapon_fx.gd` + `.tscn` | the raw-measurement probe (34 `[F4]` lines, `failures=0`) |
| `.agents/gen/weapon_fx_f4_probe.txt` | that probe's output |
| `.agents/gen/weapon_fx_f4_f3probe_before.txt` / `_after.txt` | **F3's own probe**, run before and after this pass with F3's own command |
| `.agents/gen/weapon_fx_f4_gate_before.txt` / `_after.txt` | the gate, before (271) and after (277) |

No production file outside the two above was touched; no asset, theme, `project.godot`,
addon or doc file was touched (`git status` confirms).

Law read in this order: `.agents/gen/weapon_fx_wave_task.md`, F3's report and probe,
`docs/design/AUDIO_SPEC.md` §4.1/§4.2/§8 (the variant rules, the loop layers, the shipped
cue table, plus `staging/audio/build_audio.py` for the two beds' shared source),
`docs/design/FX_SPEC.md` §0/§1.4/§1.5/§1.6, `docs/design/ASSET_WIRING_HANDOFF.md` §1.1/§1.2,
`vajb-orbit/game/mining_laser.gd` (the held-loop model H1 asks for) and
`vajb-orbit/game/projectile.gd`'s hit-feedback section.

## 0. Verdict: all four findings closed, each with a measured before and after

| # | Finding | Fix, in one line | Before → after (F3's own probe, its own command) |
|---|---|---|---|
| **H1** | the instant families' hit site has no feedback; a held beam is nearly silent | `weapons.gd`: the hull branch of `_apply_beam` reads the hit through the projectile's own doors behind a per-contact rate guard; the held beam rides a bed on the mining laser's model | `beam_hit … fx_spawned=0 cues=play_pool(sfx_weapon_laser)` → `fx_spawned=1 cues=play_loop(sfx_mining_beam),play_pool(sfx_weapon_laser),play_pool(sfx_impact_shield_hit),play_loop(sfx_impact_shield_loop)`; `beam_hold … cues=play_pool(sfx_weapon_laser)` → `… cues=play_loop(sfx_mining_beam),play_pool(sfx_weapon_laser)` |
| **M1** | the cannon's 3.460 s cue against its 0.600 s cadence needed 5.8 of the 4 voices, so a sustained burst cut its own tail | `audio_manager.gd`: `_take_sfx_player(key)` re-triggers the voice that already holds that same take (AUDIO_SPEC §4.1's steal rule) instead of taking the round-robin's next | `DURATION cue=sfx_weapon_cannon sfx_weapon_cannon_01=3.460s` + `CADENCE family=cannon interval=0.60s` against `POOLTABLE cues=6 takes=24` and 4 SFX voices → a six-shot burst holds **one** voice (`[F4] LOCAL burst=6 shots=sfx_weapon_cannon voices=[sfx_weapon_cannon_01, "", "", ""]`) |
| **M2** | the manager owned one loop voice, so a miner who took a shielded hit never heard S6's bed | `audio_manager.gd`: one voice per bed, a priority table, a lease, and a cue-scoped stop | `ITEM loop_voice shield=sfx_impact_shield_loop then_beam=sfx_mining_beam after_release=sfx_mining_beam` → `… then_beam=sfx_impact_shield_loop after_release=sfx_mining_beam`, and the sounding set is measured: `sounding=[sfx_impact_shield_loop, sfx_mining_beam]` |
| **M3** | a rocket shot down by a beam stayed silent | `weapons.gd._fire_beam`'s projectile branch plays the blast and draws the explosion the projectile route gives a shot-down rocket | `ITEM beam_shotdown … ballistic_cues=play_pool(sfx_weapon_laser)` → `… ballistic_cues=play_loop(sfx_mining_beam),play_pool(sfx_weapon_laser),play_pool(sfx_weapon_explosion)` |

The gate grew from **271** to **277** passed, 0 failed (six new tests, 23 suites).

## 1. H1 — the beam's hits read, and a held beam is not silent

### 1.1 The hull branch's hit read

`weapons.gd:_apply_beam` already resolved the sink and the shield rule for its damage; those
two values are now read once and reused for the feedback, exactly as
`projectile.gd:_hit_body` does, so the cue, the ring and the damage can never disagree:

```gdscript
var shielded := not bypass and _shield_up(target)
…
_beam_hit_feedback(target, shielded, point, delta)
_deliver(target, amount, bypass, point, StringName(row.get(&"family", &"energy")), Vector2.ZERO)
```

`_beam_hit_feedback` (`weapons.gd:639`) is the wave's own seam
(`Projectile.play_impact` + `Projectile.spawn_shield_ripple` + `Projectile.hold_shield`) and
it is rate-gated **per contact**: a contact the beam has just reached reads on its own first
frame, and the frames after that wait until the contact has lasted `BEAM_HIT_INTERVAL` again.
`_hide_beam()` clears the contact, so a new hold on a hull already hit reads from its own
first frame. The FX hang from `_hit_fx_parent(target)` (`weapons.gd:801`) - the world node
the hit *hull* lives in - so the ring stays on the point the beam reached instead of riding
the ship that fired it.

Measured (`.agents/gen/weapon_fx_f4_probe.txt`):

```
[F4] LOCAL beam_hold seconds=0.50 cue=sfx_impact_shield_hit_02 bed=[&"sfx_impact_shield_loop", &"sfx_mining_beam"] reads=2 rings=shield_ripple@true,shield_ripple2@true hull=950.0->950.0 shield=600.0->585.0
[F4] CHECK beam_reads=true half a second of contact earns two reads, not ten
[F4] CHECK beam_cue=true a beam into a shield reads as the shield
[F4] CHECK beam_shield=true and the frame's damage still lands (1.5 per 0.05 s at 30 dps)
```

- Ten 0.05 s frames of contact with one hull = **2** reads (0.5 s / 0.25), not 10.
- A fresh contact and a fresh hold each read on their own first frame (both measured in the
  same log).
- The damage is untouched: F3's `beam_hit` line reads `shield=600.0->598.5` **before and
  after**, and my probe reads `30 dps x 0.05 s = 1.5` per frame with the hull untouched
  behind the shield.
- The **rock** branch of `_apply_beam` is deliberately unchanged: a gun's work on a rock is
  depletion only (`GUN_CHIP_RATE`, ruling 17) and F3's finding is the hull's - proposed as a
  follow-up rather than half-wired here (§8).

### 1.2 The held beam's bed

On the mining laser's model (`mining_laser.gd:_play_beam_loop` /
`_stop_beam_loop` / `_exit_tree`): `_draw_beam` asks for the bed, `_hide_beam` puts it out,
and a new `_exit_tree` puts it out on a hull swap or a death. The bed is idempotent through
`play_loop`, so asking every frame costs nothing.

One measurement changed the implementation, which is worth recording because it is the only
place the mining laser's model does not transfer cleanly. My first cut used the mining
laser's own guard (`current_loop() == my cue` → `stop_loop()`). The probe found the guard
fails exactly when the fix's other half is working:

```
[F4] LOCAL beam_release bed=[&"sfx_impact_shield_loop", &"sfx_mining_beam"]   # the bed did NOT go out
[F4] CHECK beam_release=false releasing the trigger puts the bed out
```

`current_loop()` is one value, and the impact hum (`sfx_impact_shield_loop`, priority 2)
outranks a held tool's bed (priority 1) - which is what makes S6's release reliable - so the
beam's own bed is not the foreground one while a shield is being chewed. The manager
therefore exposes a cue-scoped stop, and `weapons.gd:_stop_beam_bed` prefers it, keeping the
guarded route as the fallback for a service with the pre-fix surface (F3's probe stub is
that shape, and the fallback is measured against a stub of that shape in my probe):

```
[F4] LOCAL beam_release bed=[&"sfx_impact_shield_loop"]
[F4] CHECK beam_release=true releasing the trigger puts the beam's own bed out, not the hum it does not own
[F4] LOCAL legacy_surface is_stub=true asked_bed=true stopped_bed=true calls=[play_loop(sfx_mining_beam), play_pool(sfx_weapon_laser), stop_loop(sfx_mining_beam)]
```

F3's probe, with its own stub, shows the same release from the outside: the stub records one
`play_loop(sfx_mining_beam)` per frame it ticks (a stub records every call; the manager
answers a re-ask as a lease refresh, which is what the `sounding=[…]` line measures).

F3's probe **also gained a resolution proof** it did not have: `GATE unresolved_cues=0` with
`RESOLVE cue=sfx_mining_beam path=res://assets/audio/sfx/sfx_mining_beam_01.ogg
resource=true file=true stream=true` (its resolution list goes 7 → 8 cues). The cue is the
library's one energy-emission loop (§7).

## 2. M1 — the pool's same-take voice rule

`_take_sfx_player(key := &"")`: a pooled call hands the voice that already holds **that same
take** (the oldest such voice, by a monotonic stamp), and only falls back to the
round-robin's next voice when the take owns none. AUDIO_SPEC §4.1 states the rule
("overlapping triggers steal the oldest playing voice") and this is its per-cue reading: a
one-shot that outlasts its own cadence re-triggers itself instead of consuming the pool and
cutting another take's tail.

`play_sfx`'s rotation is untouched: the plain path calls `_take_sfx_player()` with no key,
whose body is still the pre-wave line (`_sfx_next`, then `(_sfx_next + 1) % size`), so F3's
measured `PLAIN_SFX … voice=2->3->0->1->2` behaviour is byte-identical, and
`POOL round_robin=[0, 1, 2, 3, 0, 1, 2, 3]` - the take variety - is unchanged too, because
the take *index* is chosen by `_pool_index` before the voice is.

Measured:

```
[F4] LOCAL burst=6 shots=sfx_weapon_cannon voices=[&"sfx_weapon_cannon_01", &"", &"", &""]
[F4] CHECK burst=true a six-shot burst holds one voice, not the whole pool
[F4] LOCAL burst+blast voices=[&"sfx_weapon_cannon_01", &"sfx_weapon_explosion_01", &"", &""]
[F4] CHECK blast=true another cue's voice does not displace the burst's own
```

Six cannon shots hold one voice (F3's arithmetic: 3.460 s / 0.600 s = 5.77 voices needed
against 4 available), and the three remaining voices stay available to the impacts and the
blasts instead of being stacked by the burst. The take is the key rather than the cue name,
so the cannon's tier-0 take and the railgun's tier-1 take - both `sfx_weapon_cannon` - own a
voice each instead of cutting one another.

## 3. M2 — the beds each own a voice

`audio_manager.gd` (`LOOP_VOICE_COUNT = 3`, `LOOP_LEASE = 1.2`, `LOOP_PRIORITY`) with three
rules:

- **Its own voice.** A bed takes a free voice; re-asking for a bed already sounding is a
  no-op that only refreshes its lease.
- **A priority, not a thrash.** When every voice is busy, a bed gives way only to a *higher*
  priority one (S6's impact hum 2, a held tool's bed 1); a peer's request is dropped. No two
  held beds can steal a voice from each other frame after frame.
- **A lease.** A bed nobody has asked for in `LOOP_LEASE` goes out by itself. Both existing
  callers identify their bed through `current_loop()`, one value that cannot name two
  sounding beds, so a bed whose stop call is skipped has no other release. A held bed
  re-asks every frame and never expires; a bed put out properly is never touched.

`current_loop()` keeps the meaning both existing callers rely on ("the bed I am about to
stop is mine"): the highest-priority bed sounding, most recently started of equals. The two
new readers are for measurement, in the same spirit as `last_sfx()`: `sounding_loops()` and
`voice_takes()`.

Measured, on the reported case:

```
[F4] LOCAL bed ask=shield sounding=[&"sfx_impact_shield_loop"] current=sfx_impact_shield_loop
[F4] LOCAL bed ask=shaft  sounding=[&"sfx_impact_shield_loop", &"sfx_mining_beam"] current=sfx_impact_shield_loop
[F4] CHECK beds=true a shield hit during a shaft hold leaves both beds sounding
[F4] LOCAL bed release=shield sounding=[&"sfx_mining_beam"] current=sfx_mining_beam
[F4] CHECK bed_release=true the shield's own release leaves the shaft bed sounding
[F4] CONTROL voices_busy=3 before_peer_ask=[shield, engine, beam] after_peer_ask=[shield, engine, beam]
[F4] CHECK peer_dropped=true a peer bed is dropped, not queued
[F4] CONTROL invented_bed_path= real_bed_path=res://assets/audio/sfx/sfx_mining_beam_01.ogg
```

F3's own `loop_voice` line moves too, and its move is exactly the cure: `then_beam` was the
shaft (the shaft had silenced the hum) and is now the hum (the hum keeps the foreground
while the shaft also sounds), and `after_release` is still the shaft because the shaft's bed
survives the hum's release. Its line cannot show the two beds at once - `current_loop()` is
one value by contract - which is what `sounding_loops()` is for.

## 4. M3 — the rocket a beam shoots down

`weapons.gd._fire_beam`'s projectile branch, which already stopped the beam on the rocket
and consumed it, now gives the kill the same two things the projectile route's `_blast`
gives it:

```gdscript
(collider as Node).call(&"fizzle")
ProjectileScript.play_blast(self)
ProjectileScript.spawn_explosion(_hit_fx_parent(collider), target[&"point"])
```

`fizzle()` only consumes (`projectile.gd:_consume`), so no cue is doubled. The blast cue is
the one line F3 asked for; the sheet is added because the finding's own comparison is
"where the projectile route plays the blast" and that route draws the explosion as well as
sounding it - leaving one of the two out would have made one destruction read differently
through two routes.

Measured:

```
[F4] LOCAL shotdown rocket_spent=true before=sfx_impact_shield_hit_03 cue=sfx_weapon_explosion_01 sheets=explosion@true
[F4] CHECK shotdown=true the beam kills a rocket on its segment
[F4] CHECK shotdown_cue=true and the kill takes the blast cue the projectile route plays
[F4] CHECK shotdown_sheet=true with the explosion sheet that route draws
```

## 5. The gate, and the suite this pass added

```
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
before: [SUMMARY] passed=271 failed=0      (F3's own measurement, re-run before the fixes)
after:  [SUMMARY] passed=277 failed=0      exit 0
```

- **+6**: the new `test_weapon_fx_f4.gd` (6 `test_*` methods). Cross-check by hand:
  23 `test_*.gd` suites, `grep -h "^func test_" | wc -l` = **277**.
- The suite covers one test per fix plus the two seams the fixes created:
  `test_a_beam_that_lands_on_a_hull_plays_the_impact_cue_and_the_ring` (H1, both target
  kinds, the ring's sheet/blend/collapsed start, the unchanged damage),
  `test_a_held_beam_reads_one_hit_per_contact_interval` (H1's guard: 10 frames → 2 reads, a
  fresh contact reads at once, a fresh hold reads at once),
  `test_a_held_beam_plays_a_bed_and_puts_it_out_with_the_beam` (H1's bed, including the
  release while an impact hum holds the foreground),
  `test_a_repeated_take_re_uses_its_own_voice` (M1),
  `test_the_two_world_beds_sound_at_once` (M2: both beds, the shield's release leaving the
  shaft's bed, a peer's bed dropped when every voice is busy),
  `test_a_rocket_shot_down_by_a_beam_takes_the_blast` (M3, the cue and the five-frame sheet).
- The suite is synchronous (the runner never awaits a frame) and every claim is read from
  the manager's own reported state or from the drawn node, never by ear.
- The exit warnings are unchanged in kind (the dummy audio driver never mixes): the gate
  reports `28 ObjectDB instances were leaked at exit` / `12 resources still in use at exit`
  where F3 measured `18 / 8` before this pass, and this pass's probe reports `47 / 13`
  against F3's probe's `11 / 4`. Those are the suites' own fixtures and the resources they
  create, not the wiring: the same warning moves with how many tests ran (F1's 22 tests
  alone report `22 / 10`, F2's 13 report `12 / 6`, this pass's 6 report `22 / 10` in one run
  and none at all in the next), and F3's report reached the same conclusion. The gate is
  green with exit code 0.

## 6. No balance number moved

Three checks, all clean:

1. **No removed numeric literal anywhere in the wave** (F3's own command,
   `git diff -U0 -- vajb-orbit/game vajb-orbit/autoload | grep -E '^-[^-]' | grep -E '[0-9]'`):
   the only rows are the relocated `_sfx_next` rotation line (now inside
   `_take_sfx_player`) and comment lines that contain section numbers
   (`## Section 4.1: a rocket dies…`). No constant, no damage, cadence, range, Energy or
   ammo value appears in a removed line.
2. **The family table is untouched**: `FAMILIES` (`weapons.gd`) and the section-4.2 terms
   block in `projectile.gd` compare byte-identical to `HEAD`. Every constant this pass added
   is new: `BEAM_HIT_INTERVAL`, `BEAM_BED_CUE` (`weapons.gd`), `LOOP_VOICE_COUNT`,
   `LOOP_LEASE`, `LOOP_PRIORITY`, `LOOP_PRIORITY_DEFAULT` (`audio_manager.gd`).
3. **The three new `weapons.gd` seams read only what already existed**: the feedback reads
   the sink and the shield rule `_apply_beam` had already computed, the bed asks the audio
   service, and the hit FX hang from the target's own world node. `_deliver` is called with
   the same arguments as before, one line later.

`git status` for this pass: only `vajb-orbit/game/weapons.gd`,
`vajb-orbit/autoload/audio_manager.gd`, the three new `vajb-orbit/tests/` files
(`test_weapon_fx_f4.gd`, `probe_f4_weapon_fx.gd`, `probe_f4_weapon_fx.tscn`) with the two
`.uid` sidecars Godot wrote beside them, and `.agents/gen/weapon_fx_f4_*`. The two
balance-bearing comparisons above were run in this pass, not quoted from F3:
`diff <(git show HEAD:…/weapons.gd | sed -n '/const FAMILIES/,/## 09 section 3.1/p') <(sed -n
'/const FAMILIES/,/## 09 section 3.1/p' …/weapons.gd)` → identical, and the same for
`projectile.gd`'s `KNOCKBACK_FRACTION` … `MIN_SHOCKWAVE_IMPULSE` block → identical.

## 7. Numbers this pass proposes (no spec states them)

Rule 3 of the wave brief: anything beyond the handoff's ranges is proposed, not invented
silently.

| Number | Where | Why this value |
|---|---|---|
| `BEAM_HIT_INTERVAL = 0.25` s | `weapons.gd` | AUDIO_SPEC states no rate for a beam's hits. The impact takes the read plays run 0.117-0.364 s (F3's `DURATION` lines), so a quarter second is a sustained read rather than a stack; owner-tunable. |
| `BEAM_BED_CUE = sfx_mining_beam` | `weapons.gd` | the library ships **one** energy-emission loop: S6's shield hum and S7's mining bed are the *same* source file (`staging/audio/build_audio.py` reuses `movingshield_sound.ogg`), and S7's take is the only shipped looping one. A dedicated `sfx_weapon_beam_loop` is the ideal asset (audio lane), and the beam bed shares the shaft's voice while both are up, so the same bed cannot be doubled. |
| `LOOP_VOICE_COUNT = 3` | `audio_manager.gd` | the beds the game can hold at once: a mining shaft, a held weapon beam, an impact hum. |
| `LOOP_LEASE = 1.2` s | `audio_manager.gd` | a held bed re-asks every frame (two do), an impact hum re-asks on every absorbed hit, so the lease only ever releases a bed whose owner's stop call was skipped. A shorter lease would cut a hum between spaced hits; a longer one leaves a skipped stop audible for longer. |
| `LOOP_PRIORITY` (hum 2, tool bed 1) | `audio_manager.gd` | an impact read must not be lost to a held tool's sustained bed. |

## 8. What this pass deliberately did not change

- **The rock branch of `_apply_beam`.** A weapon beam on a rock still plays no cue of its
  own, where a bolt on a rock plays S4. F3's finding is the hull's, a gun's work on a rock is
  depletion-only under ruling 17, and the mining laser's chip cue is the rock's sound - so
  wiring a second rock cue is an owner call, not a one-pass fix (LOW in F3's list).
- **`mining_laser.gd`.** Its `_stop_beam_loop` keeps the guarded stop, and that guard can
  still be missed when the impact hum is the foreground bed (the case my probe found). The
  file is outside this worker's set and the lease releases the orphan within 1.2 s; the clean
  cure is the same cue-scoped stop (one line) whenever that file is next opened.
- **`projectile.gd`.** Untouched: its `hold_shield`/`release_shield` calls work as shipped
  under the new manager (the release now finds its own bed, measured in §3).
- **F3's three LOW rows** (the 1.244 s laser take 04, the unassigned cannon tier 3, the
  muzzle at the origin) are untouched by instruction - they are owner calls.
- **Assets, theme, `project.godot`, `addons/**`, `docs/**`**: untouched.
- **`docs/design/ASSET_WIRING_HANDOFF.md`'s status column** stays a later pass, as the brief
  says.

Two observations for the orchestrator, neither of them this pass's doing:

1. The working tree carries deletions of `vajb-orbit/assets/**/*.job.json` (the generation
   logs) and a root scratch file. No command in this pass wrote or removed anything outside
   `/tmp`, `.agents/gen/` and `vajb-orbit/tests/`; the deletions are outside the FX wave's
   six `.gd` files, and this pass did not revert them (they belong to whichever lane removed
   them).
2. `vajb-orbit/autoload/audio_manager.gd` is **uniformly CRLF** in the working copy, while
   every other `.gd` in the tree is LF. It is not this pass's doing - a scratch file with LF
   survives an edit here unchanged, and every file this pass wrote is LF - and the edits to
   it are edit-only; git normalises the file on commit, so the diff stays clean.

## 9. Raw commands

```
# the reviewer's own probe, before and after (F3's command, unchanged)
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f3_weapon_fx.tscn --quit-after 900

# this pass's probe (34 [F4] lines, failures=0)
~/.local/bin/godot --headless --path vajb-orbit res://tests/probe_f4_weapon_fx.tscn --quit-after 900

# the gate
~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200

# the before/after diff of the reviewer's probe, wiring lines only
diff <(grep -E '^\[F3\]' .agents/gen/weapon_fx_f4_f3probe_before.txt) \
     <(grep -E '^\[F3\]' .agents/gen/weapon_fx_f4_f3probe_after.txt)

# no removed numeric literal in the wave (F3's command)
git diff -U0 -- vajb-orbit/game vajb-orbit/autoload | grep -E '^-[^-]' | grep -E '[0-9]'
```

The before/after diff of the reviewer's probe is six hunks, and every one of them is a fix:

1. `FIRE family=laser|plasma … cues=` gains `play_loop(sfx_mining_beam)` (the held beam's bed);
2. `ITEM beam_shotdown … cues=` gains `play_pool(sfx_weapon_explosion)` (M3);
3. `ITEM beam_hold … cues=` gains the bed loop (H1);
4. `ITEM beam_hit … fx_spawned=0 → 1` and gains S5's cue and S6's bed (H1);
5. `ITEM loop_voice … then_beam=` moves from the shaft to the hum (M2);
6. `RESOLVE cue=sfx_mining_beam` is added (the bed cue, now asked for on a line that records
   it). `GATE unresolved_cues=0` and `SHEETS total=16 missing=0` in both runs, and the
   `@AnimatedSprite2D@NN` node ids shift because the probe's own counter moves.
