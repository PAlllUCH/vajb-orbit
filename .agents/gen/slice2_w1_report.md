# Engine slice 2 — W1 (weapons + projectiles): worker report (2026-09-21)

Worker: W1. File set: `vajb-orbit/game/weapons.gd`, `vajb-orbit/game/projectile.gd`
(+ `vajb-orbit/tools/`, `vajb-orbit/tests/` per the dispatch addendum).
Status: **complete**. Universal gate green, probe 95/95, nothing outside the set
touched, probes deleted with their `.uid`, `tools/` holds only `build_theme.gd`
and `derive_icon_tints.gd`.

---

## 1. Files

| File | Bytes | md5 (12) | Nature |
|---|---:|---|---|
| `vajb-orbit/game/weapons.gd` | 35 272 | `8df060f1c5b0` | **new** `class_name WeaponComponent extends Node2D`: the six-family table (§4.1 + §13), the trigger, ammo and Energy draw (§4.3/§4.4), the lock seam the seeker follows, the two countermeasures (§4.6), guns on rocks (§6/ruling 17) and the shooter's recoil (§4.2 item 7) |
| `vajb-orbit/game/projectile.gd` | 23 243 | `19bb29fb3c13` | **new** `class_name Projectile extends Area2D`: `configure(config)` with the pinned keys, flight (ballistic + 2.2 rad/s homing), the mine's arm/trigger, the range fizzle, `retarget` (the flare half, §4.6), knockback + the blast wave at the hit site (§4.2 items 7–8), `signal detonated` |
| `vajb-orbit/tests/test_engine2_weapons.gd` | 15 872 | `1756d7736e3f` | **new**, **29 tests**, all synchronous (no tree, no physics): the table, the group/ammo seams, the dry states, the lock/countermeasure seams, `configure`'s key normalization, the projectile's kind→family map |
| `.agents/gen/_s2w1_probe_weapons.txt` | 4 159 | `593ec9de586c` | probe log (95 checks, `[SUMMARY] ok=95 failed=0 blocked=0`, exit 0) |
| `.agents/gen/slice2_w1_probe_weapons.gd` | 34 284 | `98add159fed9` | archived probe source with the re-run header |
| `.agents/gen/_s2w1_testgate.txt` | 12 735 | `951ca30550d2` | universal gate log (`passed=168 failed=0`, exit 0) |
| `.agents/gen/_s2w1_boot_game.txt` | 159 | `7a59e3f71560` | `game.tscn` boot log (exit 0, zero `SCRIPT ERROR`) |

Both new files are additive and unreferenced by the shipped scenes (W5 mounts the
component), so nothing in the running game changed this pass.

## 2. Commands, exactly as run

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path \
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  --script res://tools/_probe_s2w1_weapons.gd --quit-after 20000 \
  > .agents/gen/_s2w1_probe_weapons.txt 2>&1            # exit 0

"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path \
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  res://tests/headless_runner.tscn --quit-after 1200 \
  > .agents/gen/_s2w1_testgate.txt 2>&1                 # [SUMMARY] passed=168 failed=0

"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path \
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --quit-after 200 \
  > .agents/gen/_s2w1_boot_game.txt 2>&1                # exit 0, no SCRIPT ERROR
```

Every run was bounded, stdout went to a log, nothing was left in the background.
The probes were written with the **write tool** (not through the shell) and are
gone from `tools/` together with their `.uid`; the archived copy is in
`.agents/gen/` (a `cp` into `.agents/` report space, which the hook always
allows).

The gate total is the **measured** one: the suite read **168 passed / 0 failed**
with my 29 tests in it (this tree also carries other slice-2 workers' tests, so
the number is not the brief's stale 53/78).

## 3. Acceptance, as measurements

The probe builds a real scene tree — a host hull with the physics seams, a real
`PlayerState`, real `Projectile`s, a real `Asteroid` — and lets the component's own
`_physics_process` drive the trigger, so every figure below is the shipped path,
not a helper. Each check passes only inside its stated tolerance; the exact
measured value prints on failure, so a re-run of the archived probe reproduces it.

| Acceptance item (brief W1) | Measured |
|---|---|
| fires each family at a dummy target | laser, plasma, cannon, railgun, rocket, mine all fire; each spawn/hit observed through the real frame loop |
| energy resolves at the range cap (no damage past it) | laser at 300 u deals 30 damage/s to the shield (±1.0); the same laser at 600 u deals **0** to shield and hull |
| cannon bolt travels 1000 u/s | bolt velocity length `is_equal_approx 1000.0` on the frame it spawns |
| railgun slug 1400 u/s bypasses shields | slug velocity `is_equal_approx 1400.0`; the shield reads **600.0** after the hit while the hull is short exactly 36.0 |
| rocket homes at 2.2 rad/s with a lock, dies to one hit | course rotates 0.03666 rad in one frame (2.2 × 1/60, ±0.003) while the speed holds 900.0; aimed at a locked hull it lands exactly 180 alpha; a laser frame in its path removes it |
| mine arms at 2 s, triggers at 60 u | silent at 1.9 s with a hull at 59 u; detonates (180 to the trigger hull) at 2.0 s; armed but silent with the hull at 61 u |
| dry-fire on an empty pack | one `dry_fired` per pull, no projectile, `dry_reason()` `&"ammo"` |
| power draw (§4.4) | laser 100 → 94 Energy over 1 s of fire (±0.3) and the fuel toll lands (200 → 199.4); plasma 10 E/s; an empty pool dry-fires once and deals **0** |
| plasma "+25 % to hull once shields are down" | 70 damage/s into a live shield (no hull bonus while it holds); 87.5 damage/s to the hull once it is down (±2.0) |
| chaff (§4.6) | 3 ghosts, each answering `blip_kind() == &"ghost"`, `jamming()` true, still live at 2.0 s, cleared at 3.3 s; the lock target cleared and `locks_broken` raised once; ghosts drift away from a moving hull |
| flare (§4.6) | a rocket inside 450 u retargets to the decoy and detonates on it (detonation position within 30 u of the decoy); a rocket at 600 u keeps its own target; the decoy is freed once nothing chases it |
| guns on rocks (§6, ruling 17) | one second of laser fire = 3.0 work on the rock (±0.4) and **0** pickups spawned |
| recoil (§4.2 item 7) | the hull's `apply_recoil` is called once per released shot with `muzzle velocity (1000, 0)` and mass 1.0 |
| groups (§4.3) | `weapon_3` selects the third fitted weapon, groups clamp to 1..5, module ids normalize (`w_laser` → `laser`), unknown ids never become dead groups |
| ammo (§4.3) | one round per shot; the railgun spends the cannon's pack |

Additional spec behaviours the probe pinned down: the cannon releases one bolt per
burst cycle (36-frame gaps over 2.4 s of held fire) and a bolt fizzles at its
600 u; a rocket's next round is 1.2 s after the last (its launch interval, first
observed as a 72-frame gap); `ctx` rides every damage call with `family`,
`direction` and `impulse`.

## 4. Deviations and unpinned values (ruling 4: reported, never guessed)

Every number in the family table is a §4.1 or §13 transcription. The values below
had **no spec row**; each is a named constant, chosen as narrowly as possible and
listed here for the owner/review.

1. **Rate of fire for the kinetics.** §4.1 states DPS and (for the cannon) a burst
   cycle; the railgun has neither a cycle nor a rate, and no row anywhere states
   shots per second. Chosen: **one shot per burst cycle** for the cannon
   (0.6 s = 0.35 + 0.25 — the spec's own cycle supplies the cadence) and the same
   cadence for the railgun (`KINETIC_INTERVAL`), with per-shot damage
   `DPS × interval` — cannon 27, railgun 36 — so a stream of hits delivers exactly
   the spec's 45/60 DPS. Alternative reading (a bolt every physics tick) would
   drain 180 shells in 3 s, which no pack size supports.
2. **The mine's blast damage.** §4.1/§13 pin the arm (2 s) and the trigger (60 u)
   and give no alpha. Chosen: the rocket's documented 180 (`MINE_ALPHA`), the only
   missile-class alpha in §13. Flagged as the likeliest number an owner wants to
   retune.
3. **The mine's drop cadence.** "drop" is not "held", so one mine per trigger pull
   (`edge`), with the kinetics' 0.6 s interval as the cooldown floor.
4. **A projectile's mass.** §4.2 item 7 needs `projectile_mass` and no row gives
   one. Chosen: `SHOT_MASS := 1.0` (unit mass), so a shot's recoil is its muzzle
   speed and a hit's knockback is 40 % of `0.5 × 1 × v²`. One-line tunable.
5. **A projectile's hit radius.** A detection detail, not a balance number:
   `HIT_RADIUS := 4.0` (the render size is slice 2.5's and reads nothing here).
6. **The chaff ghosts' drift.** §4.6 pins 3 signatures and 3.0 s, not a drift
   speed. Chosen: the hull's own velocity **plus an evenly spread outward copy of
   it** — the hull's own speed is the yardstick, so no new magnitude is invented
   (a stationary hull leaves three stationary signatures, measured).
7. **The flare's lifetime.** §4.6/§13 pin the lure radius only. Chosen: the decoy
   lives *while something is chasing it* (freed once it holds no lured rockets, and
   within a frame if nothing was in range), so no duration is invented. A decoy
   with a burn timer would need a number the spec does not carry.
8. **Beam recoil.** §4.2 item 7 is written as `projectile_mass × muzzle_velocity`;
   an instant beam has neither term, so energy weapons apply **no** recoil. All
   four travelling families apply theirs through the hull's `apply_recoil`.
9. **Energy cadence.** The instant families deal `DPS × delta` per frame while the
   beam is up, paid for by `draw × delta` through `try_spend_energy` first — the
   only reading that makes a DPS figure exact without inventing a shot interval.
   `shot_fired` is raised once per beam hold (not per frame).
10. **A seeker's fuse radius — a gameplay question, not a guess.** At the spec's
    900 u/s and 2.2 rad/s a rocket's minimum turn radius is **409 u**, so a lock
    acquired abeam at less than roughly that distance is orbited rather than
    struck (measured: a rocket aimed 78° off a target 400 u away flew its full
    900 u range and fizzled without a hit; the same rocket aimed at the target
    lands exactly 180). Nothing in §4.1/§13 gives a proximity fuse, so none is
    added here; the flare's "detonates on it" works because the decoy sits on the
    flight path. **Owner/review call: add a fuse radius, or accept orbiting.**

## 5. Interface findings outside this file set (not edited here)

1. **`PlayerState.WEAPONS` carries five ids** (`laser, cannon, rocket, mine,
   plasma`) while the brief's pinned interface lists six (with `railgun`). The
   railgun therefore maps onto the cannon's slot (§4.3's shared pack, CONTRACTS
   §3) rather than getting one — `weapons.gd` declares that mapping as data and
   does not touch `player_state.gd`. W2/W6 decide whether the array should grow.
2. **Six families vs five groups.** `weapon_1..5` is the input map's range, so a
   fit carrying all six weapons can drive five by key. `set_fitted` keeps the list
   whole (no silent truncation, `fitted()` reports the mismatch) and
   `select_group` clamps to 1..5. The HUD's slot meaning is W5's call.
3. **The plasma's +25 % hull bonus needs the victim's shield state**, which the
   pinned target seam (`take_damage(amount, bypass_shield, ctx)`) does not expose.
   `_shield_up()` reads, in order, a `shield_up()` method, a `shield` property, or
   a `state` property whose `shield` is readable. **When nothing is readable the
   bonus is not applied** — the conservative direction, so the family can never
   exceed its own row. Request: a one-line `shield_up() -> bool` on `PlayerShip`
   (W2) and `NpcShip` (W3) so the bonus lands on real ships too.
4. **The mining laser's 5 E/s beam drain still has no owner** (mining_laser.gd and
   player_ship.gd are in no slice-2 set; it was already a slice-0 LOW). Untouched
   here; `weapons.gd` owns only the 6/10 E/s of its own two families.
5. **Damage delivery.** My files call the pinned target seam directly —
   `take_damage(amount, bypass_shield, ctx)` when the method takes the context
   (arity-detected, cached per script), else `take_damage(amount, bypass_shield)`,
   else `PlayerState.damage` — so `ctx` (direction/impulse/family, §4.2 item 5)
   rides every hit now, and W2's `Damage.apply` can absorb the call sites later
   without behaviour changing. Nothing preloads `damage.gd` (parallel lanes must
   not race a peer file).
6. **The hull layer.** The aim mask is layers 1 (rocks) and 2 (`player_ship.tscn`'s
   `HullBody`), so W3's NPC hulls must share layer 2 to be shootable; projectiles
   own bit 3 so a shot can see a rocket without seeing rocks or hulls. Mines
   trigger on the pinned groups (`player_ship`/`npc_ship`) instead of a layer, so
   they do not depend on that decision.
7. **No art.** Nothing is drawn: the projectile has no sprite and the beam no FX
   (the graphics lane owns `assets/**`). W3's visual pass / slice 2.5 owns all of
   it; the structural seams (`kind`, `velocity()`, `hit_radius()`, `blips`-shaped
   ghost nodes) are in place for it.

## 6. For W5 (the mount seam, so the wiring lands first try)

```gdscript
var guns := WeaponComponent.new()          # or a scene child named for it
ship.add_child(guns)                       # the hull owns `apply_recoil`/`velocity`
guns.setup(stats, state)                   # the launch handshake (pinned)
guns.set_fitted(fit_ids)                   # module ids or weapon ids, both land
guns.select_group(slot)                    # HUD weapon_slot_selected -> here
guns.set_lock_target(target)               # when the 1.2 s channel completes
guns.clear_lock_target()                   # the channel breaks
guns.use_countermeasure(&"cm_chaff")       # spends through PlayerProfile.remove_cargo
guns.jamming()                             # true while chaff blocks re-acquisition
guns.ghosts()                              # the &"ghost" blips for the minimap
guns.flare()                               # the live decoy, if any
guns.shot_fired / dry_fired / locks_broken / countermeasure_used   # signals up
```

The component reads `fire_primary` itself (held), so the hull only has to mount it,
and `set_firing(active)` / `set_aim_point(pos)` exist for a probe or a caller that
owns the input. Beams ground their Energy first: a short pool raises `dry_fired`
once per pull and fires nothing.

## 7. Open items, ranked

1. **Owner:** the four unpinned numbers in §4 (kinetic rate of fire, mine alpha,
   projectile mass, and whether seekers get a fuse radius). None blocks the wave.
2. **W2/W3:** expose `shield_up() -> bool` on the target hulls so plasma's +25 %
   reaches ships (finding 3); W2 owns whether `PlayerState.WEAPONS` grows a
   railgun slot (finding 1).
3. **W5:** the mount + lock + countermeasure wiring in §6, the HUD's weapon-slot
   meaning with six families and five groups (finding 2), and the ghost blips.
4. **Slice 2.5 / W3:** every visual.
5. **Slice 4:** module affixes' `+fire rate` (15 §3) has no base rate to modify
   until item 1 is ruled on.
