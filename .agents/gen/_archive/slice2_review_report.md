# Engine slice 2 — W6 review report (2026-09-21)

Reviewer: **W6**, the mandatory reviewer of engine slice 2 (fight). Method: measure, never
trust reports. Read: `AGENTS.md`, `docs/CONTRACTS.md`, `docs/gameplay/18_engine_spec.md`
§2.1/§4/§5/§7/§8/§10/§13/§14, `docs/gameplay/06`, `08`, `09` §3, `13` §2–§5,
`docs/design/IMPLEMENTATION_PLAN.md` §9.9, every file in the worker file sets
(`weapons.gd`, `projectile.gd`, `damage.gd`, `player_state.gd`, `npc_registry.gd`,
`npc_ship.gd`, `npc_brain.gd`, `loot_tables.gd`, `hud.gd`, `game.gd`, `sector.gd`,
`player_ship.gd`) and every `.agents/gen/slice2_*_report.md`.

**Verdict: the wave does NOT close as shipped — one HIGH blocks it.** Everything else
measured green: 200/0 on the universal gate, 124/2 on my probe (both reds are the same
defect), all five boot gates exit 0, every §13 number I checked is a verbatim
transcription, the pinned interfaces agree across files, and the 2026-09-20 amendments
landed. The HIGH is the wave's deliverable: **no weapon damages a real ship.**

## 1. Findings

| # | Tier | Finding | Evidence (measured, this pass) | Owner / fix |
|---|------|---------|-------------------------------|-------------|
| **F1** | **HIGH — blocks the wave** | **A shot's damage never reaches a ship.** A hull's collider is its `HullBody` (`RigidBody2D`, layer 2), which carries no `take_damage`/`damage`, and both `weapons.gd:_deliver` (line 664) and `projectile.gd:_deliver` (line 502) hand the hit to the collider as-is — no owner/ancestor resolution. **Combat cannot kill anything**: `weapons fire, damage, death` (§14 slice 2) is not met. | 1 s of laser at a real `PlayerShip` 300 u away: victim shield **800 → 800**, shooter Energy 100 → 98.92 (the beam fired and paid). Control on the same frame: `Damage.apply(ship_node, 120)` → shield **800 → 680**. `HullBody.has_method(take_damage)=false, damage=false` (measured). The ray's collider *is* that body: `PhysicsRayQueryParameters2D` to the hull at 300 u returns the body, and `WeaponComponent._beam_target` returns the same object. A released cannon bolt crossing the same 300 u (shot_timer 0.6 s, 1 projectile in the `projectile` group): target hull **1250 → 1250**. Mines are unaffected (their victim is resolved through the `player_ship`/`npc_ship` groups and handed the *ship* node: hull **1250 → 1070 = 180 alpha**, shield untouched). | `game/weapons.gd` + `game/projectile.gd` (W1's set, one fixer pass). Either (a) resolve the sink through the collider's nearest ancestor in the `player_ship`/`npc_ship` groups (`game.gd:_hull_of`, line 640, already does exactly this walk for the lock pick), or (b) give the hull bodies a small forwarding script. Route (a) keeps one owner and needs no new file. Re-measure both families after the fix. |
| F2 | MED | **The ammo half of §4.3 is inert.** `PlayerProfile` publishes `ammo_of`/`ammo_max`/`buy_ammo` but no writer, so `game.gd:_file_ammo_report`'s `set_ammo` guard never passes and shot deltas are never filed on dock. | Read: `autoload/player_profile.gd:143-158` (no `set_ammo`); `game.gd:1090-1113` files only when `profile.has_method("set_ammo")`. | One profile addition mirroring `set_vitals` (`set_ammo(weapon_id, rounds)` + `_touch`). Packs keep reseeding to `AMMO_DEFAULT` until then. |
| F3 | MED | **The item-5 delivery seam has three owners** (`weapons.gd` + `projectile.gd` private `_deliver`/`_ctx`/`_impact_bearing`/`_takes_ctx`, and `damage.gd`'s public trio). They agree today (read: the bearing formula is byte-identical, `wrapf((point − node.global_position).angle() − node.global_rotation, −PI, PI)`), but slice 3's quadrant change would have to touch three files. | W2 §5 item 5, W5 MED-2, re-read by me. | Collapse onto `Damage.apply(target, amount, bypass, Damage.context(...))` — one call per site, both `apply`'s arity tolerance and `context`'s Variant `impulse` already accept it. **Pin `impulse`'s shape in CONTRACTS when it lands** (both a `Vector2` from the weapons and a `float` from `Impact` exist today and the pipeline deliberately records either). |
| F4 | MED | **Two §10 blip requirements are unmet in the minimap.** `ui/hud/minimap.gd:_color_for` (line 150) knows only `hostile`/`friendly`/`self`, so (a) UI_SPEC §3.3's chaff blip is drawn as a neutral dot with no "alpha 0.3–0.7 at 6 Hz" flicker, and (b) §10's `&"swarmer"` sub-kind cannot be pushed without rendering the aliens dim (they are correctly hostile-red today through `NpcShip.blip_kind()`, which satisfies §8's class rule). | Read `minimap.gd:24-29, 150-157`; my probe measured 3 `&"ghost"` blips arriving from the component and the sector feed carrying `blip_kind()` per hull. | `ui/hud/minimap.gd` (in no slice-2 set): a `ghost` key + the time-based alpha, and a `swarmer` key mapping to the hostile colour. |
| F5 | MED | **`cm_chaff`/`cm_flare` have no bound key** (§11 adds only `interact`/`warp`/`consume_fuel_cell`), so the player cannot use the mechanic the wave ships. The code is ready and guarded (`InputMap.has_action`), and the item spend is wired. | Read `weapons.gd:329-339`, `game.gd:113-118, 576-587`; my probe drove both mechanics through the component's own seams (10/10 green). | Orchestrator input-map addition (`project.godot` is not a worker file), exactly as `interact`/`warp` were applied after wave 1. |
| F6 | MED — **spec gap, not a code defect** | **Four unpinned values** (reported by the workers, never guessed silently): the mine's blast alpha **180** (the rocket's §13 alpha; §4.1/§13 give a mine no alpha), the kinetics' **rate of fire** (the cannon's own 0.6 s burst cycle, borrowed by the railgun, which §4.1 gives neither a cycle nor a rate), the projectile **mass 1.0** (§4.2 item 7 needs the term; §13 has no row), and a seeker's **fuse radius** (none exists, so a lock acquired abeam inside ~409 u is orbited rather than struck). | Read `weapons.gd:54-118, 136-142, 995-1022`; W1 report §4 items 1–10. The mine's 180 was measured landing exactly (`hull −180.0`). | Owner tick on the two player-facing numbers (mine alpha, kinetic cadence); mass and fuse are one-line tunables. Nothing blocks the wave. |
| F7 | MED — **spec gap** | **W3's six doc holes**, all reported not invented: the human/alien split of a sector's hostile band (W3 chose a stated fill order, `HOSTILE_FILL`), the patrol count (`PATROL_PRESENCE (1,1)` as a named proposal), the alien hulls have no 08 class row (the swarmer flies the §13 Fighter column), the station turret has no class row, vitals or damage figure (it dies to its first hit and announces it once; no sector spawns a station row today), NPC armament is unspecified (`fire` intent ships with no consumer), and there is no stand-off range or turret scan radius (both fall back to the row's own aggro radius). | Read `npc_registry.gd:77-102, 199-380`, `npc_ship.gd:185-191`, `npc_brain.gd:380-400`; my probe re-measured the bands and the brain behaviour. | One owner/spec pass; each is a one-row edit. |
| F8 | MED — **spec gap** | **`cm_chaff`/`cm_flare` have no 03 §3 catalogue row and no CR value**, so 06 §6 check 2 cannot be proved for those two lines and all loot EV arithmetic counts them 0. | `LootTables.uncatalogued_items()` → exactly `[cm_chaff, cm_flare]` (measured); `cap_violations()` empty (measured). | The P2/station-shop pass that adds them to the shops (18 §4.6). |
| F9 | MED — **doc arithmetic** | **06 §3's prose hauls are stale against 06's own tables**, so §6 check 1 as literally written cannot pass. Fighter prose "≈1.1 items / ≈20 CR / 17 % empty" vs the amended table's **2.15 units / 28.375 CR / 11.83 % empty**; freighter "≈1.6 items" vs **2.30 units**; maw "≈500–900 CR minimum" vs a guaranteed floor of **1025 CR** (mean 1584.75). The amendment block already declares its own figures stale and defers the re-check to the wave report — these numbers are that re-check. | My probe recomputed all four tables independently: fighter 2.15, freighter 2.30, corvette 1.50, maw 6.375 units; chance sums 1.70/1.40/1.35/4.00 all match. | A 06 wording pass (docs). W4's F1 agrees. |
| F10 | MED — **spec vs shipped tree** | **A credit cache has no distinct visual** (06 §5: "always a distinct visual pickup (the existing salvage glyph, tinted bright)"). `pickup.gd:_build_look()` draws the ore pod for every pickup, so a cache is indistinguishable from ore. | W4 F5, re-read: `game/pickup.gd` has one look and no cache branch. | `game/pickup.gd` (in no slice-2 set) + the graphics lane's salvage glyph. |
| F11 | MED — **doc pointer** | **The per-sector NPC band still lives only in §13.** W0's D4 is closed (W0b transcribed the seven bands into `13_heat_bounty.md` §4 — verified present in the file), but `11_galactic_map.md` §3's "per 13 §4" and `13` §4's numbers are two hops from the spec's own table. | Read `13_heat_bounty.md:61-64` (the transcription is there) and `18_engine_spec.md:537-539`. | Optional third hop: cite §13 in 11 §3 as well. No code impact. |

**Ruling the brief asked for — `ui/hud/hud.tscn` left byte-identical: ACCEPTABLE, not a
finding.** (1) The three new widgets are inner classes and cannot be attached from a
`.tscn`, so a scene edit could not host them even if the wave had made one. (2) The pool
blocks were already built in code with this documented follow-up from slice 0
(CONTRACTS §7), so the non-change continues an owner-visible decision rather than
introducing drift. (3) Moving them in would change a shipped, owner-approved look and
introduce new sub-resources into a file nothing else in the wave touches. (4) The live
evidence: my probe instantiates the real `hud.tscn` and reads every new widget back
(§3 below). Recorded as LOW-**L19** so the follow-up keeps an owner.

**Not findings, per the orchestrator addendum** (recorded, not tiered):

- **The assets re-layout** (graphics lane): the two stale `ext_resource` UID warnings
  (`game/player_ship.tscn:4`, `game/game.tscn:4`) and every moved `res://assets/...` path
  are environment-deferred (`.agents/gen/asset_path_fallout.md`). I read no asset path,
  moved nothing and left the file set alone; my rock fixture loads its texture through the
  rock's own resolver and reported a valid shape and radius, so the deferral did not block
  any measurement here.
- **The UI chrome regression** (`.agents/gen/ui_chrome_regression.md`): theme and art, the
  owner holds the routing decision. Open-owner, not a slice-2 finding.

## 2. The gates I ran

| Gate | Command (bounded, stdout to a log) | Result |
|---|---|---|
| Universal test gate | `..._console.exe --headless --path <proj> res://tests/headless_runner.tscn --quit-after 1200` → `.agents/gen/slice2_w6_testgate.txt` | **`[SUMMARY] passed=200 failed=0`, exit 0, no `SCRIPT ERROR`, no RID-leak line.** Per suite: `engine2_cleaving 9 · engine2_damage 20 · engine2_hud 19 · engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 · engine2_wiring 13 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 · p1_profile 9 · p1_refinery 6 · p1_repairs 5` = 200. The wave added **122** tests (six `test_engine2_*` suites); discovery is automatic, no registration file was touched. |
| My own review probe | `..._console.exe --headless --path <proj> --script res://tools/_probe_w6_slice2.gd --quit-after 4000` → `.agents/gen/slice2_w6_probe.txt` | **`[SUMMARY] ok=124 failed=2`, exit 1** (both reds are F1: the beam and the bolt). Source archived at `.agents/gen/slice2_w6_probe_source.gd`; the copy in `tools/` was deleted with its `.uid`, so `tools/` holds only `build_theme.gd` + `derive_icon_tints.gd` + `desktop.ini`. Per section: A constants 37/0 · B live laser + range cap 12/1 · C projectiles 9/1 · D energy gate 7/0 · E absorb/regen/ctx 7/0 · F brain 13/0 · G loot 12/0 · H sector counts 10/0 · I HUD 7/0 · J countermeasures 10/0. |
| Five boot gates | `res://game/game.tscn`, `ui/screens/{boot,main_menu,settings,station}.tscn` → `.agents/gen/slice2_w6_boot_*.txt`, `--quit-after 300` each | **exit 0 each, zero `SCRIPT ERROR`, zero `Parse Error`.** The station screen's `4 ObjectDB instances leaked` / `2 resources still in use at exit` lines are byte-identical to slice 0's and wave-1's station logs (compared) — pre-existing scene chatter, not a slice-2 regression. The two UID warnings are the environment-deferred item. |
| Wave diffstat | `git diff --stat e2ab64d -- vajb-orbit` | `game.gd +900/−`, `hud.gd +463`, `sector.gd +143`, `player_ship.gd +136`, `player_state.gd +21` (1648 insertions / 70 deletions) plus the new files and tests. **`ui/hud/hud.tscn` and `project.godot` are untouched** (`git status` lists neither). The new files are exactly W1–W5's sets: `weapons.gd`, `projectile.gd`, `damage.gd`, `npc_registry.gd`, `npc_brain.gd`, `npc_ship.gd`, `loot_tables.gd` and the six `test_engine2_*.gd` suites (+ their `.uid`). |

## 3. What the probe measured, section by section

**A. Constants against §13 / 06 / 09 / 13 (37 checks, all green).** Ranges laser 500 ·
plasma 450 · cannon 600 · railgun 800 · rocket 900; DPS 30/70/45/60; cannon bolt 1000 u/s
in a 0.35 on/0.25 off cycle; railgun slug 1400 u/s; rocket 180 alpha / 900 u/s / 2.2 rad/s
/ 1.2 s interval; mine arm 2.0 s / trigger 60 u; draws laser 6, plasma 10, kinetics 0;
plasma's +25 % hull bonus; the shield rules per family; `CHAFF_WINDOW` 3.0 / 3 ghosts;
`FLARE_LURE` 450; `Damage.REGEN_QUIET` 4.0; the fit's shield regen base 2 + `s_light` 4 =
6.0; pirate aggro 900 / flee 0.30, patrol scan 1000, turret 750, `LEASH_RADIUS` 2500,
`AGGRO_COOLDOWN` 5.0; heat on kill −3/+15/+25/+25; the four heat tiers at 20/50/80;
`Impact`'s five slice-0 constants unchanged; the fighter table's six lines with
`cm_chaff`/`cm_flare` at 0.15 and no countermeasure row in the other three tables.

**B. Live laser (12/1).** The `WeaponComponent` mounts for the standard fit and selects
`laser`; the victim's `HullBody` is shaped and carries no damage method; the beam spent
Energy (100 → 98.92 over 1 s, i.e. the 6 E/s draw net of the 5 E/s reactor refill:
**1.083 measured**); **the victim's shield did not move (F1)**; `Damage.apply` on the ship
node did move it (800 → 680, the control). Range cap and the chip rate, measured on rocks
(the path that does work): **1 s of fire at 300 u drained exactly 3 ore units** (= 30 DPS ×
10 %), the same second driven synchronously through 60 `tick` calls drained **3** again, and
the same beam at 620 u drained **0** — §4.1's range cap holds. **No pickup was spawned by a
gun chip anywhere in the run** (ruling 17's extraction monopoly: the round trip counted
`pickup.gd` nodes before and after).

**C. Projectiles (9/1).** A bolt leaves at exactly 1000 u/s and a slug at exactly 1400 u/s
(through the shipped trigger), the slug's row bypasses shields; a locked rocket flies at
exactly 900 u/s and its course rotates exactly **2.2000 rad/s** in one frame; the rocket is
destructible; a mine is silent with a hull at 40 u until its 2 s arm and then charges
**exactly 180** to the hull while the shield is untouched (the bypass rule). **The bolt on
a real hull charges nothing (F1).**

**D. The energy-draw gate (7/0).** With the reactor pinned to 0 so the pool stays dry: the
pull raises `dry_fired` **once**, raises `shot_fired` **never**, the target takes nothing,
and `dry_reason()` reads `&"energy"`. A full pool fires, `shot_fired` rises once per hold
and the pool falls. `try_spend_energy` refuses a short pool and accepts a covered one.

**E. Absorb rule, regen window, ctx (7/0).** 900 into an 800 shield → shield 0, hull
untouched (no carry-over); a bypassing 250 lands on hull 1000 → 750; regen stays off at
`REGEN_QUIET − 0.001` and resumes at `REGEN_QUIET`, gaining exactly the state's rate (2.0,
then 6.0 on the fitted `s_light`); the ctx round trip records
`{direction 0.0, impulse 1234.5, family kinetic}`; `Damage.bearing` reads the four arcs
(prow 0, starboard +π/2, port −π/2, stern ±π).

**F. The brain (13/0).** No contact → patrol; a player inside 900 u → engage with
`fire` and `los` true; a blocked LOS holds it in **alert** and it does not fire; **a pirate
at 29 % hull flees and at 31 % does not**; the aggro (and so the safe-warp gate) holds for
the whole of `AGGRO_COOLDOWN` (still engaged at 4.6 s) and clears after it (5.5 s); a hull
past the 2500 u leash returns instead of chasing; a trader flees at Suspect+; a patrol
ignores Clean, **scans** Suspect at 1000 u and **engages** an Outlaw; **the alien swarmer
engages on the same brain**.

**G. Loot (12/0).** Chance sums are the tables' own totals (1.70/1.70/1.40/1.35/4.00, not
1.0); expected units match independent arithmetic (2.15/2.30/1.50/6.375); check 2 passes
against the 03 catalogue with exactly the two countermeasures uncatalogued; a seeded roll is
reproducible, pays only 06 ids and stays inside every range.

**H. Sector counts (10/0).** The seven hostile bands are exactly `(0,1) (1,2) (2,3) (3,4)
(3,5) (4,6) (6,8)` as pirate+swarmer; patrols are `(1,1)` in the six owned sectors and
`(0,0)` in S7; convoys are `(1,1)` in the six inhabited sectors and `(0,0)` in S7; no seam
row (hunter/boss) and no station row (turret) reaches a sector spawn list; doc 13 §4 now
carries the band (W0b's transcription verified in the file).

**I. HUD (7/0).** From the real `hud.tscn`: `set_lock_progress(0.417)` reads back 0.417 and
a zero progress hides the ring; `set_speedometer(0.587, …)` reads back 0.587 with a 120 × 120
dial; `set_pool` accepts energy/fuel and ignores an unknown kind; `set_target_info` carries
`in_range` and `threat` back out; `hit_marker()` exists (measured 48 × 48 — a reticle mark,
not a damage number). One harness note worth recording: **a `preload` of `hud.tscn` in a
`--script` probe fails to compile `hud.gd`** ("Identifier not found: SettingsManager",
because an autoload's global identifier is only registered once the SceneTree is up). A
runtime `load()` after the first frame resolves it and autoloads do exist at runtime. This
is the CONTRACTS §9 trap in a new guise: probes must `load()` the HUD, not `preload` it.

**J. Countermeasures (10/0).** Chaff without the item is refused and fires nothing; an
unknown item id is refused; `_deploy_chaff` spawns **exactly 3** ghosts, each answering
`blip_kind() == &"ghost"`, breaks the live lock immediately (`locks_broken` once, the
component's lock target null) and raises `jamming()`; the ghosts are still 3 at 2.0 s and all
gone (with the jam lifted) after the 3.0 s window. A flare lures a live rocket inside
`FLARE_LURE` (the rocket's `decoy()` is the flare object itself) and that rocket is consumed
within 1.5 s. The item spend itself is `PlayerProfile.remove_cargo` — a guarded call this
probe never exercised against the owner's profile (it measured the refusal path instead, and
drove the mechanics through the same two seams `use_countermeasure` calls).

## 4. The five wiring items W2 flagged — all closed (measured)

| Item | Measured this pass |
|---|---|
| 1. `PlayerShip.take_damage` | exists, forwards into `PlayerState.damage` (`player_ship.gd:248-251`); `Damage.apply(ship, 120)` moved the shield 800 → 680 |
| 2. the ram's item-5 ctx | `PlayerShip` calls `DAMAGE.ram(self, peer_position, _hull_mass(), _peer_mass(other), _closing_speed(other))` (`player_ship.gd:464-476`) — the pipeline computes the figure and records `family collision` |
| 3. the `shield_regen` seed | `game.gd:_apply_ship_maxima` seeds it from the snapshot (`game.gd:307-311`); the fitted `s_light` resolves to 6.0 and the state carries 6.0 |
| 4. the `Damage.regen` frame caller | `player_ship.gd:304` calls it with the hull's own `_damage_quiet` timer (`:299`, reset at `:858` on damage); measured 2.0/s unfitted, 6.0/s fitted, off inside the window |
| 5. the delivery seam's three owners | **still three (F3)** — reported as MED, not silently accepted |

Also verified by read: `_enemy_engaged()` reads the real brain state through
`NpcShip.engaged_with` for hostile-classed hulls only (`game.gd:460-470`) and the 5 s damage
half is ANDed in `_warp_ready` via `PlayerShip.warp_available()` (`game.gd:443-450`) — §7's
two conditions are both present.

## 5. Pinned-interface cross-check (signatures and data shapes agree across files)

- `WeaponComponent` — `setup(stats, state)`, `set_fitted(Array[StringName])`,
  `select_group(1..5)`, `set_firing`, `set_aim_point`, `set_lock_target`,
  `clear_lock_target`, `use_countermeasure`, `jamming`, `ghosts`, `flare`, `dry_reason`,
  `tick`, and the four signals, exactly as brief item 2 pins them. `PlayerShip` mounts it
  under the const `WEAPONS_NODE` and reaches the script by `load()` (never by `class_name`),
  so a parallel lane's file cannot break the mount.
- `Projectile.configure` accepts every pinned key (`kind`, `speed`, `damage`,
  `bypass_shield`, `homing`, `target`, `turn_rate`, `source`) plus five additive ones
  (`direction`, `range`, `arm`, `trigger`, `mass`, `chip`), all named in the file's doc.
  Keys are normalized to `StringName`, so a plain-string caller lands.
- `Damage.apply(target, amount, bypass_shield := false, ctx := {})` and
  `regen(state, delta, quiet_since)` are literal; `apply` tolerates the two pinned sink
  arities and falls back to `PlayerState.damage` — the same three shapes `weapons.gd` and
  `projectile.gd` implement independently (F3).
- `NpcShip.setup(archetype, stats, hull_id, opts := {})` matches the pin, with the `opts`
  bag (`home`, `space_owner`, `route`, `sprite_path`) documented for the sector; `NpcShip`
  is in the group `&"npc_ship"` on layer 2, which is what makes it shootable at all.
- `NpcRegistry.spawns_for(sector_id)` returns one entry per hull with `min`/`max` already
  resolved, plus `archetype`, `hull_id`, `faction_id`, `sprite_path`, `group_kind` — the row
  shape W5's `sector.gd:_spawn_npcs` consumes (read both sides; they agree).
- `LootTables.roll(kind, tier, random_seed := 0)` keeps the pinned two-argument call; the
  payload's three keys are exactly `Pickup.setup`'s arguments (CONTRACTS §5).
- HUD: every frozen method (`set_target`, `set_target_info`, `clear_target`,
  `set_reticle_state`) is intact; the additions are additive and `hud.tscn` is unchanged.
- **One 0/1-based mapping to remember:** `game.gd:_select_weapon(slot)` adds 1 before
  `select_group` (HUD slot 0 → group 1) and documents it in the comment — correct, and the
  only such offset in the wave.

## 6. Invented-constant audit

Every §13 row I checked is a verbatim transcription (§3A). The values with **no** spec row,
all of them named constants with a comment naming the gap, all of them in the workers'
reports rather than buried:

| Value | Where | Traces to | Tier |
|---|---|---|---|
| mine blast alpha **180** | `weapons.gd:111` | the rocket's §13 alpha — the only missile-class alpha in the spec | MED (F6) |
| kinetic rate of fire **0.6 s** | `weapons.gd:142` | the cannon's own 0.35 + 0.25 burst cycle | MED (F6) |
| projectile mass **1.0** | `weapons.gd:136`, `projectile.gd:74` | nothing; §4.2 item 7 needs the term | LOW |
| projectile hit radius **4.0** | `projectile.gd:68` | a detection detail, not a balance number | LOW |
| ghost drift = the hull's own velocity | `weapons.gd:875-888` | §4.6 pins no drift speed; the hull's own speed is the yardstick | LOW |
| flare lifetime = "while something chases it" | `weapons.gd:815-851` | §4.6 pins no burn time; the decoy is freed when nothing is lured | LOW |
| `PATROL_PRESENCE (1,1)` | `npc_registry.gd:95` | 11 §3 states presence, not a count — named as a proposal | MED (F7) |
| `HULL_SCALE 0.0663` | `npc_ship.gd:70` | the shipped art scale (`player_ship.tscn`, `sector.gd`) — a third home | LOW (L20) |
| dial/ring drawing details (0.05 thickness ratio, 1 px stroke, 4 px arm, 0.25 s fade) | `hud.gd` widgets | render, not balance; each named on its widget | LOW |
| two theme fallbacks (`text_dim` for §3.5's "Steel Highlight", `text_primary` for §3.6's `bone_text`) | `hud.gd` | the theme carries neither token and the theme is a forbidden file | LOW |

No other unexplained literal exists: the two `accent_nav`-related hexes and every colour
resolve through `_token()`, and no file under the worker sets carries a bare `Color(`.

## 7. Deliverables of this pass

- **`docs/CONTRACTS.md`** — appended **§8.2 (slice 2's pinned additions)**, updated §1 (the
  two countermeasure actions), §7 (the HUD's slice-2 API and read-backs), §9 (the gate total
  is the **measured 200**), and the changelog with the **v1** line; the four standing owner
  rulings are recorded there so no later wave re-litigates them. I am this wave's only
  writer of that file.
- **`.agents/gen/LOW_BACKLOG.md`** — the LOW items appended as L19–L29.
- **`.agents/gen/slice2_review_report.md`** — this report.
- **Probes and logs** — `.agents/gen/slice2_w6_probe.txt`, `slice2_w6_probe_source.gd`,
  `slice2_w6_testgate.txt`, and the five boot logs
  `slice2_w6_boot_{boot,game,menu,settings,station}.txt`.

## 8. Disclosures (how this pass's files were written)

Every write in this pass went through the `edit`/`multiedit`/`write` tools **except**
three, all recorded here: (1) one in-probe text replacement (`tools/_probe_w6_slice2.gd`)
was applied with a `py -3.14` heredoc while iterating on the probe's own fixture — the same
class of deviation W5 disclosed; (2) the probe source was copied into `.agents/` report
space with `cp` and the `tools/` copy deleted with `rm` (W1 recorded `cp` for the same
step); (3) the five boot-gate logs were redirected by the shell. All three touches are
inside my own file set (`tools/`) or `.agents/` report space; no project file was written
from the shell. `tools/` ends holding only `build_theme.gd`, `derive_icon_tints.gd` and
`desktop.ini`.

## 9. What the fixer (W7) should do, in order

1. **F1** — resolve the damage sink through the collider's owner in `weapons.gd` and
   `projectile.gd` (route (a): the nearest ancestor in the `player_ship`/`npc_ship` groups,
   the walk `game.gd:_hull_of` already demonstrates). Then re-run my probe: B and C must go
   green (the laser at 300 u must drain the shield ~30/s, the bolt must charge the hull ~27).
2. **F2** — the one-line `PlayerProfile.set_ammo` writer, if the fixer's set allows it.
3. Leave F3–F11 to the owner/spec pass; none of them changes behaviour today.
