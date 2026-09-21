# Slice 2 — W3 (NPC archetypes) report

Worker: W3 (engine slice 2, fight). Brief: `.agents/gen/slice2_task.md` worker set W3 +
Global rules + its 2026-09-20 amendments, the pinned interfaces 5/6/7, and the
orchestrator addendum of 2026-09-21 (`slice2_prompts.md` W3 prompt). Spec read in order:
`AGENTS.md`, `docs/CONTRACTS.md` §2/§3/§4/§6 (+ §5 and §8/§8.1 per the addendum),
`docs/gameplay/18_engine_spec.md` §2/§2.1/§4.2/§5/§7/§8/§13/§14/§15/§16,
`docs/gameplay/13_heat_bounty.md` in full, `docs/gameplay/11_galactic_map.md`,
`docs/gameplay/06_loot_drops.md`, `docs/design/STYLE_BIBLE.md` §2.5/§3/§9.1,
`docs/design/ASSET_NAMING_SPEC.md` §1, then the shipped tree: `player_ship.gd`/`.tscn`,
`player_state.gd`, `ship_stats.gd`, `ship_fit.gd`, `impact.gd`, `damage.gd` (landed while
this pass ran), `loot_tables.gd` (idem), `asteroid.gd`, `sector_registry.gd`, `sector.gd`,
`game.gd`, `tests/headless_runner.gd` and `addons/godot_ai/testing/test_suite.gd`.

Status: **implemented and measured.** Probe 22/22, universal gate 168/0, five boot gates
exit 0. Deviations and the values no doc states are §6 — every one of them reported, none
guessed into the code.

---

## 1. Files

| File | Bytes | Lines | md5 (12) | Note |
|---|---:|---:|---|---|
| `vajb-orbit/game/npc_registry.gd` | 28 937 | 741 | `fbec7c519f6e` | new — archetype rows, §13 count shape, doc 13 heat tiers |
| `vajb-orbit/game/npc_brain.gd` | 18 789 | 515 | `86b6d9accd20` | new — one state set, injected LOS, leash/aggro |
| `vajb-orbit/game/npc_ship.gd` | 30 262 | 863 | `cb2ca1e428fa` | new — the hull, its body, the sink contract, `died` |
| `vajb-orbit/tests/test_engine2_npc.gd` | 19 920 | 481 | `a863c57062f5` | new — 28 tests (suite `engine2_npc`) |
| `.agents/gen/slice2_w3_probe_source.gd` | 18 662 | 517 | `6093cf925e7c` | the archived probe (3. of §2), deleted from `tools/` |

Engine-generated sidecars, left in place as the tree's convention:
`vajb-orbit/game/npc_{registry,brain,ship}.gd.uid`,
`vajb-orbit/tests/test_engine2_npc.gd.uid`.

Nothing else in the tree was written. `docs/**` (including `docs/CONTRACTS.md`, which W6
owns this wave), `project.godot`, `addons/**`, `ui/**`, `assets/**` and
`player_ship.gd`/`player_state.gd`/`sector.gd`/`game.gd` are byte-identical to the wave
start (`git status` shows no modification for any of them from this pass). No asset path
was read or swept beyond the `ResourceLoader.exists` checks the sprite resolver performs
(addendum ruling two), and no file was ever written through the shell: the probe, the
three shipping files and the suite were all created with the `write` tool, then edited with
`edit`/`multiedit` (addendum to the Global rules, "use the write tool normally and say in
your report that you did").

---

## 2. Commands and their output

### 2.1 The probe (bounds: `--quit-after 2400`)

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
  --script res://tools/_probe_s2w3_npc.gd --quit-after 2400
```
→ log `.agents/gen/slice2_w3_probe.txt`, **exit 0**, `[SUMMARY] ok=22 failed=0`. The probe
runs on a real scene tree (live `RigidBody2D` hulls, a real `Asteroid` as the LOS blocker)
and its own report lines are the measurements quoted below.

### 2.2 The universal test gate (bounds: `--quit-after 1200`)

```text
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
  "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://tests/headless_runner.tscn
  --quit-after 1200
```
→ log `.agents/gen/slice2_w3_testgate.txt`, **exit 0**,
`[SUMMARY] passed=168 failed=0`, no `SCRIPT ERROR`, no leaked RIDs. The suite count is read
from the run, never compared with a number printed in the brief (addendum correction one):
the wave's own tests (W1/W2/W4/W5) landed while this pass ran, and this suite's 28 tests are
inside that total (`-- --suite=test_engine2_npc` → `passed=28 failed=0`, log
`.agents/gen/slice2_w3_testgate_npc.txt`). One intermediate whole-gate run carried a single
red, `test_engine2_weapons.gd.test_projectile_configure_accepts_string_keys` — W1's file,
edited at 07:44:52 while that run was in flight; the re-run of §2.2 is green and that test
is outside this worker's set (§6, O5).

### 2.3 The five boot gates (bounds: `--quit-after 300` each)

```text
res://ui/screens/boot.tscn → .agents/gen/slice2_w3_boot_boot.txt     exit 0
res://ui/screens/main_menu.tscn → slice2_w3_boot_menu.txt            exit 0
res://ui/screens/settings.tscn → slice2_w3_boot_settings.txt         exit 0
res://ui/screens/station.tscn → slice2_w3_boot_station.txt           exit 0
res://game/game.tscn → slice2_w3_boot_game.txt                       exit 0
```
No `SCRIPT ERROR` in any of them (the two "2 resources still in use at exit" lines in the
menu and station logs are that scene's own exit chatter, present in earlier waves' logs and
not a script error).

---

## 3. Acceptance, as measured

The brief's W3 acceptance list, item by item:

- **"probe spawns each archetype including the alien swarmer"** — pirate
  (`ship_fighter`, 80 t, radius 29.7 u), swarmer (`ship_fighter` stats,
  `ship_swarmer_side.png`, radius 35.5 u), patrol (`ship_patrol`, 220 t, 33.4 u), trader
  (`ship_freighter`, 260 t, 32.6 u) and the turret (`ship_turret_platform`, frozen) all
  spawn with art loaded, a live body, the row's blip class (`hostile`/`hostile`/`hostile`/
  `neutral`/`hostile`) and state `idle` (probe lines 10–15). Radii are art-derived at
  runtime (half the longest axis at the shipped 0.0663 scale), so they moved with the
  graphics lane's re-renders during this pass — nothing asserts a fixed radius.
- **"walks the brain states on synthetic positions (LOS blocked by a rock)"** — twice:
  - synthetic walk (no physics): `[idle, patrol, alert, engage, engage, flee, return]`,
    where the second `engage` is the `AGGRO_COOLDOWN` grace and `alert` is the blocked LOS;
  - the shipping ray: a real `Asteroid` at (150, 0) between a pirate at (0, 0) and the
    player at (300, 0) keeps the state in `alert`; parking the rock at (0, 6000) turns the
    same contact into `engage` with `fire=true`, `los=true` and `target` = the player node,
    and `engaged_with(player)` is true while the brain holds it (§13's "rocks block").
- **"leash + AGGRO_COOLDOWN clears"** — with the player pulled to (4000, 0): at 4.7 s the
  state is still `engage`; at 5.3 s it is `return`, and `engaged_with(player)` is false —
  i.e. section 7's safe-warp gate opens exactly one `AGGRO_COOLDOWN` after the contact left
  the radius. A hull placed at (2900, 0) (past the 2500 u leash) with the player 300 u away
  in radius returns instead of chasing.
- **"pirate flees at 30 % hull"** — 31 % → not `flee`; 29 % → `flee`; a recovered 80 % →
  `return` (suite `test_pirates_flee_below_thirty_percent_hull`).
- **"trader flees on Suspect+"** — end to end through the real profile: heat 20 with
  `concord` → tier `suspect` → the convoy's state is `flee`; heat back to 0 → the flight
  ends (`patrol`, back on its route).
- **Registry shape against §13** — the seven hostile bands print exactly
  `(0,1) (1,2) (2,3) (3,4) (3,5) (4,6) (6,8)` as pirate+swarmer; patrol is `(1,1)` in the
  six owned sectors and `(0,0)` in unaligned S7; the convoy is `(1,1)` in the six inhabited
  sectors and `(0,0)` in S7; no seam row (`hunter`, `boss`, `sibelon`, `apex`) and no
  station row (`turret`) reaches a sector's spawn list.
- **The sink contract (brief item 4, coded against the parallel file)** —
  `Damage.apply(ship, 120, false, ctx)` with `ctx = Damage.context(...)`: shield 1000 → 880,
  hull 2050 unchanged, and the recorded context reads `direction=-3.142` (a hit from dead
  astern, `wrapf(PI, -PI, PI)`), `family=laser`; a following `apply(ship, 40, true, {})`
  takes the hull 2050 → 2010. `NpcShip.take_damage(amount, bypass_shield, ctx)` declares the
  third parameter, so `damage.gd`'s arity probe hands it the context and W1's
  `weapons.gd`/`projectile.gd` do the same (both were read after they landed: they detect
  the three-argument form and pass `ctx`).

---

## 4. Every constant, and its source

No number in the three files lacks a doc row. Nothing was guessed; the values no doc
carries are absent from the code and listed in §6 instead.

| Value in the code | Source |
|---|---|
| pirate aggro radius 900 | `18_engine_spec.md` §13 "Aggro radii": "pirate 900" |
| patrol scan radius 1 000 (and its aggro radius) | §13 "patrol scan 1 000" |
| turret aggro radius 750 | §13 "turret 750" |
| `LEASH_RADIUS` 2 500 | §13 "leash 2 500" |
| `AGGRO_COOLDOWN` 5.0 s | §13 "`AGGRO_COOLDOWN` 5 s (aggro clears; warp becomes available)" |
| flee below 30 % hull (pirate, swarmer) | §13 "flee at 30 % hull" |
| trader flees at Suspect+ | `13_heat_bounty.md` §5 "traders gain `flee` behaviour while your Suspect+ tier is active"; the tier threshold (20) is 13 §3's table |
| patrol scans Suspect+, attacks Outlaws | 13 §2 "scans Suspect+ (20+) on sight; attacks Outlaws (80+)"; thresholds from 13 §3 |
| heat on kill: pirate −3 / trader +15 / patrol +25 / turret +25 | 13 §4 (pirate, −3 heat +1 standing), 13 §2's gain table (trader 15, patrol 25, turret 25) |
| standing +1 (pirate only) | 13 §4 "Killing pirates in faction X's space: +1 standing, −3 heat" |
| convoy = 1 hauler + 1–2 fighter escorts | §5's trader row, "convoy = 1 hauler + 1-2 fighter escorts" |
| hunter wing 2–3 fighters (seam data only) | 13 §3 "2–3 hunter hulls" / §5 "2–3 hulls" |
| per-sector hostile band S1 0-1 … S7 6-8 | §13 "NPC counts per sector (13 §4 density shape)"; the only home of the figures (W0 report D4) |
| one convoy per inhabited sector, patrols only in owned space | §13 (both qualifiers) + 11 §3 ("Patrols: Concord/Meridian/Choir space only", "Trade convoys: 1 active per inhabited sector") |
| heat tiers 0/20/50/80 | 13 §3's tier table |
| `HULL_LAYER` 2 / `HULL_MASK` 1 | the shipped `player_ship.tscn` hull body (CONTRACTS §4); the mask is read from `Asteroid.COLLISION_LAYER`, not restated |
| hull mass, speeds, damp, turn rates, shield pools and regen | `ShipStats`, resolved by `ShipFit` from §13's class column and 08 §2 — the NPC reads the snapshot, it owns none of it |
| `SLOW_DOWN_RADIUS` / `ARRIVE_RADIUS` | `PlayerShip`'s consts (§13's autopilot row, single owner per CONTRACTS §4/§8.1) |
| collision damage, knockback, explosion arithmetic | `Impact` (§4.2 items 6–8, §13's row) |
| `REGEN_QUIET` | read from `damage.gd`'s own const when the file is present (see §6, N3); `npc_ship.gd` keeps the same §13 value only as a fallback for a tree without the pipeline |
| `HULL_SCALE` 0.0663 | the shipped art scale (`player_ship.tscn` `Hull.scale`, `sector.gd` `STATION_SCALE`) — a pre-existing convention, §6 D9 |

Deliberately **not** in the code: a patrol radius (the patrol leg reuses the row's own aggro
radius), a stand-off/preferred range, an NPC weapon family/damage/interval, the turret's
"high damage" figure, a swarmer heat value, a human/alien mix fraction, and any despawn
dwell timer. Each is reported in §6.

---

## 5. The interface W5 codes against

```gdscript
# Preload by path, not by class name: a brand-new class_name is only in the global class
# cache after a project scan, and `damage.gd`/`projectile.gd` reach their siblings the
# same way.
const NpcRegistry := preload("res://game/npc_registry.gd")
const NpcShip := preload("res://game/npc_ship.gd")

# What a sector spawns (spec section 8's on-entry set + the 20-minute clock, which stay
# the sector's business): one entry per hull, counts already resolved.
for spawn: Dictionary in NpcRegistry.spawns_for(sector_id):
    var hull_id: StringName = spawn[NpcRegistry.KEY_HULL_ID]
    var stats: ShipStats = ShipFit.resolve(hull_id, ShipFit.STANDARD_FIT)  # null for the
                                                                            # turret row
    var count := rng.randi_range(int(spawn[&"min"]), int(spawn[&"max"]))
    for _i in count:
        var ship: Node2D = NpcShip.new()
        world.add_child(ship)
        ship.setup(spawn[NpcRegistry.KEY_ARCHETYPE], stats, hull_id, {
            NpcShip.OPT_HOME: anchor,                  # the leash is measured from here
            NpcShip.OPT_SPACE_OWNER: NpcRegistry.space_owner(sector_id),
            NpcShip.OPT_ROUTE: route,                  # a convoy's fixed route (11 section 3)
        })
        # spawn[NpcRegistry.KEY_GROUP_KIND] == &"convoy" marks one group (one route);
        # spawn[NpcRegistry.KEY_FACTION_ID] is the resolved faction for standing/heat;
        # spawn[NpcRegistry.KEY_SPRITE_PATH] is the swap-ready file the hull will draw.
```
`NpcShip` publishes, for the wiring: `died(position, archetype)` (loot roll + heat + the
wreck are the wiring's; the hull then leaves the tree, deferred), `heat_on_kill()`,
`standing_on_kill()`, `blip_kind()` (section 8's hostile/neutral), `faction()`,
`archetype()`, `hull_id()`, `row()`, `hull()/shield()/hull_fraction()`, `is_alive()`,
`state_name()`, `target()`, `engaged_with(node)` (section 7's safe-warp gate: true only in
Alert/Engage on that node), `intent()` (`state`, `waypoint`, `speed`, `fire`,
`target_pos`, `los`), `despawn()` (the external recycle, no death flow), `impact_body()`,
`velocity()`, `apply_impulse()`, `art_ready()`, and `take_damage(amount, bypass_shield,
ctx)` / `apply_collision_damage(amount)` as the sinks.

The warp gate in `game.gd:_enemy_engaged()` becomes:

```gdscript
for node: Node in get_tree().get_nodes_in_group(NpcRegistry.GROUP):
    if node.has_method(&"engaged_with") and bool(node.call(&"engaged_with", _ship)):
        return true
```

`NpcRegistry.heat_tier(heat)` / `heat_min(tier)` / `tier_at_least(tier, floor)` are the
only owners of 13 §3's thresholds (20/50/80), so a HUD or panel that needs the tier reads
them there instead of restating the numbers.

---

## 6. Deviations, decisions and what no doc states

Tiering follows the wave's vocabulary (HIGH blocks, MED = one fixer pass, LOW → backlog).

### Reported — a value a slice-2 consumer needs and no doc carries

- **D1 (MED, needs one owner tick). The human/alien split of a sector's hostile band.**
  Ruling 24 requires the alien `swarmer` to be live in slice 2; §13 gives **one total band
  per sector** and no doc says how much of it is human. Read literally, the briefs' two
  mechanisms (`HOSTILE_FILL` order or a per-sector mix column) are both choices, so the file
  states the rule it uses and nothing else: the band is filled in `HOSTILE_FILL` order
  (pirate first, swarmers for the rest), which needs no fraction and sums back to §13's
  figure exactly. Effect today: S1 0–1 pirate and no swarmer; S2 1 pirate + 0–1 swarmer; …
  S7 1 pirate + 5–7 swarmers. A different mix is a one-line edit to that array; the
  registry, the suite and the probe all assert the sum, so a bad edit fails immediately.
- **D2 (MED, needs one owner tick). The patrol count.** 11 §3 says patrols exist in
  Concord/Meridian/Choir space and §13 repeats only the qualifier; no count exists anywhere.
  `PATROL_PRESENCE := Vector2i(1, 1)` (one patrol per owned sector) is declared **as this
  wave's proposal**, named as such in the file comment, zeroed in unaligned S7, and reported
  here rather than presented as spec.
- **D3 (MED). Alien hulls have no 08 class row.** `ShipFit.HULLS` carries the nine human
  hulls; `ship_swarmer_*`/`ship_sibelon_*`/`ship_apex_*` have art (graphics lane, landed
  2026-09-21) but no class, so the swarmer flies the §13 Fighter column — the same band
  W4's `swarmer` loot table reuses (06 §3.1's weights). An 08 amendment for the alien hulls
  is what closes it; the row is one edit.
- **D4 (MED). The station turret has no class row and its damage figure has no number.**
  08 §5 lists `ship_turret_platform` as an enemy-only hull with "class entries may be added
  later as amendments", so `ShipFit.resolve(&"ship_turret_platform", …)` refuses and the
  hull has no snapshot. What ships: the section 5 behaviour (static, frozen body, aggro on
  attack, holds until its release radius clears, +25 heat on death) and a one-time warning;
  what does not: its vitals and its "high damage" (§5's words, no §13 row). A hull with no
  snapshot cannot absorb a hit and dies on its first one, which is documented in
  `take_damage` and announced once in `setup` rather than left as a silent invulnerability.
- **D5 (MED). NPC armament does not exist as a spec.** No doc gives an archetype a weapon
  family, a damage figure or a firing interval, so the brain's `engage` produces a `fire`
  **intent** with no consumer and the report raises the gap: giving NPCs real guns needs one
  owner ruling (family + damage + interval per archetype, and the turret's "high damage"),
  after which `NpcShip` can hang a `WeaponComponent`-shaped seam off the intent. Nothing in
  this pass invented a number to paper over it.
- **D6 (LOW). No stand-off row.** §5's "hold preferred range, strafe" names a range none of
  the docs state, so the engage orbit runs on the row's **own** §13 aggro radius (pirate
  900, patrol 1 000, turret 750). It is the alternative to inventing a second radius per
  archetype, and the behaviour probe shows the ring working.
- **D7 (LOW). The turret's release radius.** §5 says turret aggro holds "until scan range
  clears" and §13 states no turret scan radius; `release_radius()` falls back to the row's
  own aggro radius (750) rather than picking a number.
- **D8 (LOW, doc pointer). The per-sector band still lives only in §13.** W0's finding D4
  (13 §4 and 11 §3 point at each other with no numbers) is unchanged; this registry cites
  §13 directly and the transcription into 13 §4 remains the orchestrator's/W6's call.

### Deviations from the letter of the brief (reported, not hidden)

- **D9 (LOW). `HULL_SCALE` 0.0663 now has a third home.** The shipped art scale exists as
  `player_ship.tscn`'s sprite scale and `sector.gd`'s `STATION_SCALE`; `npc_ship.gd` needs it
  to size a hull circle from a texture and had no owner to read it from. One shared
  "art scale" constant is the cleanup.
- **D10 (LOW). The flight maths is duplicated from `player_ship.gd`.** The brief requires
  the same physics pattern and forbids a second movement system, and `player_ship.gd` is not
  in W3's file set, so `npc_ship.gd` carries the derivation (`_step_turn`, `_step_speed`,
  `_order_turn`, `_order_speed`, the damp/inertia helpers) with the same comments naming the
  same sources. **Every number stays single-owner**: the class values come from the
  `ShipStats` snapshot and the two autopilot radii + `UNRESOLVED_HULL_MASS` are read off
  `PlayerShip`, so no §13 row has two homes. Recommended cleanup: extract a shared
  `HullFlight` (or move the helpers onto `PlayerShip` as statics) when `player_ship.gd` is
  next in someone's set.
- **D11 (LOW, note). Ships do not pair with ships.** The shipped hull body is layer 2 /
  mask 1 (CONTRACTS §4), so an NPC mirrors it and a ship-vs-ship contact never resolves.
  Consequence: an NPC's own contact monitor only ever reports rocks (so it cannot
  double-charge a player ram, which is why the monitor is safe to keep), and a ram *between*
  two hulls is nobody's job today. If slice 4 wants ramming damage between ships it needs a
  ram authority (one side charging both halves), which is a design decision, not this
  pass's.

### Notes

- **N1.** `NpcShip.despawn()` defers its free on the message queue when the hull is outside
  a tree (`call_deferred(&"free")`), because a probe or a unit test has no SceneTree delete
  queue to join; in the game it is a plain `queue_free()`, and either way the hull stays
  valid for the rest of the frame so `died` listeners run on a live node.
- **N2.** The suite frees its own hulls in `teardown()`: `McpTestSuite.track()` is the
  **editor** runner's cleanup and `headless_runner.gd` never calls `_free_tracked`, so a
  tracked node leaks under the gate. Measured before and after: 6 leaked `GodotBody2D` +
  6 `GodotShape2D` + 24 `CanvasItem` RIDs → none.
- **N3.** `NpcShip` reads `damage.gd`'s `REGEN_QUIET` through a guarded `load()` +
  `get_script_constant_map()` when the file is present, with the same §13 value as a
  fallback. That keeps the 4 s row single-owner once the pipeline exists (it did land during
  this pass) while letting the hull still load in a tree without it — the brief's "code
  against the signature even if that file is still being written" is honoured without a hard
  parse dependency. The mirroring the pinned item 4 asks for is otherwise literal: shield
  first, no carry-over, `ctx` recorded.
- **N4.** The alien sheets **have landed** (`vajb-orbit/assets/ships/ship_swarmer_*`,
  `ship_sibelon_*`, `ship_apex_*`, with the alien style block per STYLE_BIBLE §9.1), so the
  swarmer draws its own hull on the `side` view and needs no placeholder. The brief's
  "placeholder art" seam is `opts.sprite_path` (any caller may point a hull at another
  file), and a missing file degrades to "no art, no collision circle, one warning" — the
  environment-deferred case of addendum ruling two, never a behaviour gate.
- **N5.** `npc_brain.gd`'s patrol leg is a quarter-turn walk around the hull's own POI at
  the row's aggro radius. That is a shape this file chose (no doc states a patrol pattern);
  the moment a doc states one it is a two-line change. A convoy's route (`set_route`)
  replaces the walk entirely.
- **N6.** `DESPAWN` is only reachable from outside: the sector recycles a hull with
  `despawn()` (or `request_despawn()` on the brain), because §5's spawn model makes the
  sector the owner of when a hull goes away. No dwell timer was invented to make the state
  self-triggering.
- **N7.** The probe was written to `vajb-orbit/tools/_probe_s2w3_npc.gd` with the `write`
  tool (never through the shell), and deleted with its `.uid` before this report; its source
  is archived at `.agents/gen/slice2_w3_probe_source.gd` with the re-run command in its
  header. W1's two probe files (`_probe_s2w1_dbg.gd`, `_probe_s2w1_weapons.gd`, with their
  `.uid`) are still in `tools/` — not this pass's to delete, but the brief's "tools/ holds
  only `build_theme.gd` + `derive_icon_tints.gd`" is therefore not yet true.
- **O5 (observation, not a finding).** The first whole-gate run of this pass caught
  `test_engine2_weapons.gd.test_projectile_configure_accepts_string_keys` red while W1's file
  was being edited (mtime 07:44:52). The re-run is `168/0`; the red was outside this
  worker's file set and is recorded only so the orchestrator knows the earlier log exists.

---

## 7. Evidence

| Log | What it proves |
|---|---|
| `.agents/gen/slice2_w3_probe.txt` | the probe, 22/22, exit 0 — every measurement in §3 |
| `.agents/gen/slice2_w3_probe_source.gd` | the probe's source (archived copy) |
| `.agents/gen/slice2_w3_testgate.txt` | `passed=168 failed=0`, exit 0, no `SCRIPT ERROR`, no RID leak |
| `.agents/gen/slice2_w3_testgate_npc.txt` | `passed=28 failed=0` — this suite alone |
| `.agents/gen/slice2_w3_boot_{boot,menu,settings,station,game}.txt` | five boot gates, exit 0, no `SCRIPT ERROR` |

`docs/CONTRACTS.md` was deliberately left untouched: W6 is this wave's only writer of it, and
the pinned additions it will need (the `NpcShip`/`NpcBrain`/`NpcRegistry` sections, the
`opts` bag, the `spawns_for` row shape and the registry's heat-tier helpers) are all in §5
above for that pass to transcribe.
