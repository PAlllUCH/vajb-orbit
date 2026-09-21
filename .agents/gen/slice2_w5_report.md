# Engine slice 2 — W5 (HUD + wiring) report (2026-09-21)

Worker: W5. File set as dispatched: `vajb-orbit/ui/hud/hud.gd`,
`vajb-orbit/ui/hud/hud.tscn`, `vajb-orbit/game/game.gd`, `vajb-orbit/game/sector.gd`,
`vajb-orbit/game/player_ship.gd`, plus `vajb-orbit/tools/` and `vajb-orbit/tests/`
(the dispatch addendum). Status: **complete**, probe 65/65, universal gate
`passed=200 failed=0`, five boot gates exit 0, probes deleted with the `.uid`,
`tools/` holds `build_theme.gd` and `derive_icon_tints.gd` only.

Read first, in order: `AGENTS.md`, `.agents/gen/slice2_w5_context.md`, the brief
`.agents/gen/slice2_task.md` (Global rules, pinned items 1–10, the 2026-09-20
amendments), `docs/CONTRACTS.md` §2–§9, `docs/gameplay/18_engine_spec.md`
§2.1/§4/§5/§7/§8/§10/§13, `docs/design/UI_SPEC.md` §3.1b/§3.3/§3.5/§3.6, then the
shipped tree (the four W1–W4 files, `player_state.gd`, `impact.gd`, `pickup.gd`,
`asteroid.gd`, `npc_registry.gd`, `minimap.gd`, `target_reticle.gd`, `player_profile.gd`,
`economy_log.gd`, `headless_runner.gd`) and the four W1–W4 reports.

No asset was read, moved or swept (addendum ruling two): the only asset contact is the
`ResourceLoader.exists` check `NpcRegistry.sprite_path` already performs. No number was
invented (ruling four) — every constant added this pass is a §13/§10/§3.x row, a
drawing detail of a spec'd widget, or a placement decision named and reported in §5.

---

## 1. Files

| File | Before | After | md5 (12) | Nature |
|---|---:|---:|---|---|
| `vajb-orbit/ui/hud/hud.gd` | 32 096 | 48 056 | `5ec803118fb3` | +15 960 B: the slice-2 API (`set_lock_progress`, `set_speedometer`, `hit_marker`, the payload's `in_range`/`threat`, read-only read-backs) and the three widgets (lock ring, hit marker, radial dial) |
| `vajb-orbit/game/game.gd` | 21 652 | 55 873 | `b3dceaf67488` | +34 221 B: the targeting wiring (pick, lock channel with LOS, mark/Q, ESC), the target window and hit marker, the countermeasure triggers, the speedometer and ghost-blip pushes, the real warp gate, the ammo seed/filing and the death flow |
| `vajb-orbit/game/sector.gd` | 12 417 | 18 153 | `75c83cb8bf14` | +5 736 B: §8's on-entry NPC population from `NpcRegistry.spawns_for`, per-hull anchors, the hull blips and the clock's hull re-roll |
| `vajb-orbit/game/player_ship.gd` | 30 880 | 36 402 | `01618268e26b` | +5 522 B: the `WeaponComponent` mount, `take_damage`/`shield_up`, the ram's item-5 context through `Damage.ram`, the `Damage.regen` frame step |
| `vajb-orbit/ui/hud/hud.tscn` | 18 780 | **18 780 (unchanged)** | `343d63f205aa` | deliberately untouched — see §5.10 |
| `vajb-orbit/tests/test_engine2_hud.gd` | — | 12 288 | `736ee2b474ed` | new, **19 tests** (suite `engine2_hud`) |
| `vajb-orbit/tests/test_engine2_wiring.gd` | — | 14 015 | `e7bea3c4198e` | new, **13 tests** (suite `engine2_wiring`) |
| `.agents/gen/slice2_w5_probe.txt` | — | 8 588 | `98db8d40b14a` | probe log, `[SUMMARY] ok=65 failed=0 blocked=0`, exit 0 |
| `.agents/gen/slice2_w5_probe_source.gd` | — | 28 655 | `6d24a5d5046d` | archived probe source with the re-run header (deleted from `tools/`); the file it describes is `b8ab4fcc774f8249e132facde1292427` |
| `.agents/gen/slice2_w5_testgate.txt` | — | 16 841 | `62fbec192791` | universal gate log (`passed=200 failed=0`, exit 0) |
| `.agents/gen/slice2_w5_boot_{boot,game,menu,settings,station}.txt` | — | — | — | five boot gates, exit 0, zero `SCRIPT ERROR` |

`git diff --stat` for the four shipped files: 3 files changed, 713 insertions(+), 29
deletions(-) plus `game.gd`'s 860/40 — every deletion is a replaced line, never a
removal of shipped behaviour (the two that were: the slice-1 mock `_fire` and the
`_unhandled_input` that now also carries the lock click, both dated in §5.9).

`tools/` ends holding `build_theme.gd` (+ `.uid`), `derive_icon_tints.gd` (+ `.uid`) and
the pre-existing Windows `desktop.ini`; the probe and its (never generated — a headless
run does not import) `.uid` are gone.

The two new test files have no `.uid` yet: a headless run does not import, and the
`.uid` sidecars the tree carries for other new files were written by an editor session.
The next editor open generates them; nothing reads them.

---

## 2. Commands, exactly as run

```text
1. probe   "C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path
           "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit"
           --script res://tools/_probe_s2w5_wiring.gd --quit-after 4000
           > .agents/gen/slice2_w5_probe.txt 2>&1
   -> exit 0, [SUMMARY] ok=65 failed=0 blocked=0, no SCRIPT ERROR

2. gate    ... res://tests/headless_runner.tscn --quit-after 1200
           > .agents/gen/slice2_w5_testgate.txt 2>&1
   -> exit 0, [SUMMARY] passed=200 failed=0, no SCRIPT ERROR, no RID leak line

3. boots   ... res://game/game.tscn            → .agents/gen/slice2_w5_boot_game.txt     exit 0
           ... res://ui/screens/boot.tscn      → .agents/gen/slice2_w5_boot_boot.txt     exit 0
           ... res://ui/screens/main_menu.tscn → .agents/gen/slice2_w5_boot_menu.txt     exit 0
           ... res://ui/screens/settings.tscn  → .agents/gen/slice2_w5_boot_settings.txt exit 0
           ... res://ui/screens/station.tscn   → .agents/gen/slice2_w5_boot_station.txt  exit 0
   (--quit-after 300 each; zero `SCRIPT ERROR`, zero `Parse Error`. The menu and station
   logs carry their own "2 resources still in use at exit" chatter, the same lines earlier
   waves recorded and not script errors.)
```

Per-suite breakdown of the gate: `engine2_cleaving 9 · engine2_damage 20 · engine2_hud 19 ·
engine2_loot 13 · engine2_npc 28 · engine2_pools 16 · engine2_weapons 29 ·
engine2_wiring 13 · p1_catalogues 11 · p1_clock_log 4 · p1_market 13 · p1_pricing 5 ·
p1_profile 9 · p1_refinery 6 · p1_repairs 5` = **200**. The total is the one measured on
the frozen tree; the brief's 53 and slice 0's 78 are both long superseded (the wave added
`engine2_hud`'s 19 and `engine2_wiring`'s 13 to W1–W4's 136).

---

## 3. Acceptance, as measurements

The brief's W5 line, item by item, from `.agents/gen/slice2_w5_probe.txt` (a real
`game.tscn`, a real `PlayerState`, real `NpcShip` hulls, a real `Asteroid`, the component's
own `_physics_process`, frames stepped with `await physics_frame`):

| Acceptance | Measured |
|---|---|
| "scene run spawns the sector with NPC counts per §13" | seven rows, fixed seed: S1 1/2 · S2 3/3 · S3 3/4 · S4 5/5 · S5 4/6 · S6 7/7 · S7 7/8 hostiles (pirate+swarmer+patrol; patrol only in owned space, 0 in S7, convoys 0 in S7), every archetype inside its own expanded registry band, and 46/46 hulls art-ready (printed, never gated — ruling two) |
| blip kinds hostiles/neutral per §8 | every pirate, swarmer and patrol answers `&"hostile"`, every convoy hull `&"neutral"`; the sector's feed carries one blip per hull, one per field and the station's `&"friendly"` |
| "lock channel completes after 1.2 s clean LOS and shows the ring" | ring 0.417 at 0.6 s; the lock lands on the hull at 1.2 s; the completed ring stays drawn at 1.0; a rock placed on the live line resets the channel to 0 and the lock never lands; clearing the line lands it; ESC clears the mark, the lock and the ring |
| "HUD shows range state + hit markers" | payload `{name: "Lancer", hull, shield, distance_m, in_range, threat: "HOSTILE"}`; the distance row prints `1 240 m  IN RANGE` / `OUT OF RANGE`; a 30-point pool drop between two pushes flashes the marker, which is hidden again 0.4 s later |
| "pools bars" | the Energy and Fuel bars read `PlayerState` exactly (`_pool_current` == `state.energy`/`state.fuel`), the banner is dark with a tank aboard |
| "radial speedometer" | 120 × 120 dial, ratio 0.587 at 0.59 of the class maximum after a 1.5 s burn, 6 filled segments, no overdrive segment below 0.9; the needle is `#6fb8c4` (the theme carries no `accent_nav` yet, so the spec's own literal is in play) |
| "a chaff use breaks the lock and spawns 3 ghost blips for 3 s" | one use spends an item, spawns exactly 3 ghosts, breaks the lock immediately, refuses re-acquisition while they live, reaches the minimap feed as 3 `&"ghost"` blips, is still 3 at 2.0 s and gone (with `jamming()` false) after 3.0 s |
| "a flare retargets a homing rocket inside 450 u" | a live rocket is launched by the mounted rocket family, the flare is live, and every rocket inside the lure radius answers `decoy() == the flare` |
| "boot gates (game/menu/settings/station) exit 0" | five scenes, exit 0, no `SCRIPT ERROR` |
| "test gate green" | `passed=200 failed=0`, exit 0 |

The five wiring items W2 measured but could not close, each measured here:

| Item | Measured |
|---|---|
| 1. no `take_damage` on the player hull | `PlayerShip.take_damage` exists and forwards: shield 1000 → 950 on a 50-point hit |
| 2. the ram carried no context | the shipped `_on_hull_body_entered` charges **82.594** (110 t into a 560 t peer at 300 u/s, the pipeline's own reduced-mass figure) and records `{direction: 0.0081617, impulse: 0.0, family: collision}` |
| 3. nothing seeded `shield_regen` | `PlayerState.shield_regen` == the snapshot's == **6.0** (base 2/s + `s_light` 4) |
| 4. nothing called `Damage.regen` | after a 4.1 s quiet window the shield gains **6.0** in 1 s (the state's rate) |
| 5. the delivery seam has three owners | reported, not edited — see §4 MED-2 |

Two further measurements the probe pinned down:

- **The wave's HIGH: a shot's damage is delivered to the hull's *body*, not to the hull**
  (§4 HIGH-1). `Damage.apply(hull, 120, false, {})` charges the hull's own pool (600 → 480
  on a Fighter); `Damage.apply(hull.impact_body(), 120, false, {})` charges **nothing**, and
  a real second of laser fire at a real pirate leaves its shield at its maximum while the
  scene's Energy drops (6 E/s drawn against the 5 E/s refill: a net 0.92 E over 1 s).
- **`PlayerShip` is a real damage sink now**, so the player's own half of a ram, a mine's
  blast (W1 resolves mine victims through the `player_ship`/`npc_ship` groups) and
  `Damage.apply(ship, …)` all land on the shield.

The HP bar and the dial were also read through the HUD's own read-backs, so the numbers
above are what the HUD holds, not what a private field happened to say.

---

## 4. Findings outside this file set (ranked; nothing here was edited)

**HIGH-1 — a hull's ray collider carries no sink, so no weapon damage reaches any hull.**
`weapons.gd:_deliver` / `projectile.gd:_hit_body` deliver to the object the ray hit, which
for a hull is its `HullBody` (`RigidBody2D`, layer 2) — a bare body with no `take_damage`
and no `damage`, so the call is a silent no-op. Measured (§3): the same `Damage.apply`
charges the hull node 120 and charges its body 0, and a real laser hit on a real pirate
leaves its shield untouched. W1's own probe could not see this because its `DummyHull`
*extends RigidBody2D and carries the sink itself*; the shipped hulls put the sink on the
ship node. Mines are unaffected (they resolve their victim through the group scan, so they
hand the *ship* node to `_deliver`). Two fix routes, both one edit in W1's file:
(a) `_deliver` resolves the sink through the collider's owner — the collider itself when it
answers, else its nearest ancestor in the player/NPC groups (W5's `game.gd:_hull_of` does
exactly this walk for the lock pick and is two lines); or (b) the hull bodies carry a small
forwarding script. Route (a) keeps one owner and needs no new file.

**MED-1 — `PlayerProfile` publishes no writer for a weapon pack, so the ammo half of §4.3
cannot be filed.** The section says the packs are profile-owned, `PlayerState` seeds at
launch and the shot deltas go back on dock; `PlayerProfile` owns `ammo_of`/`ammo_max`/
`buy_ammo`, and `buy_ammo` only ever *adds* (a fired delta is a subtraction). The wiring is
therefore in place, guarded and inert (`game.gd:_seed_ammo` loads each pack from the
profile's own store and remembers what it loaded; `_file_ammo_report` files the spent
delta through `profile.set_ammo(weapon_id, rounds)` when that method exists and writes one
`economy_log` `AMMO` line per pack), and the one line that closes it is a profile addition
mirroring `set_vitals`: `set_ammo(weapon_id: StringName, rounds: int) -> void` with
`_touch(KEY_AMMO)`. Until then the packs keep today's behaviour (reseeded to
`AMMO_DEFAULT` at every launch).

**MED-2 — the item-5 delivery seam has three owners** (W1's private `_deliver`/`_ctx`/
`_impact_bearing`/`_takes_ctx` in `weapons.gd` and `projectile.gd`, and W2's
`Damage.apply`/`context`/`bearing`). They agree on the data shape and the bearing formula
(W2 read them, this pass did not re-derive them). W2 suggested collapsing them onto
`Damage.apply(target, amount, bypass, Damage.context(...))`; that is one call per site in
W1's files and is W6's call to tier, not a W5 edit.

**MED-3 — UI_SPEC §3.3's chaff-blip flicker needs `ui/hud/minimap.gd`, which is outside
this worker's file set.** The `&"ghost"` blip kind ships and renders as a dim `text_dim`
dot through the minimap's neutral fallback (correct class, correct colour), but the
"alpha 0.3–0.7 at 6 Hz" flicker is per-blip alpha in the minimap's `_draw` and is not
implemented. One edit in `minimap.gd` (a `&"ghost"` key in `_color_for` plus a time-based
alpha) closes it.

**MED-4 — `PASSIVE_RADIUS` (1 500 u) has no UI contract.** §4.1 says the passive radar
"auto-tags signatures" and no doc states what a tag renders. This pass gave the radius and
§3.1's `target_next` (Q) one coherent reading and reported it (§5.7): Q marks, from the
passive radar's own signatures, the nearest hostile that is not the current mark, without a
lock — the channel is still the only route to a lock. If the owner's reading is different
(Q cycling *locks* only, or a tag auto-filling the target window), the change is inside
`_cycle_mark`/`_mark`.

**MED-5 — §10's `&"swarmer"` blip sub-kind is not pushed.** §8 classes swarmers as hostile
and `NpcShip.blip_kind()` answers `&"hostile"` (W3's row), and the minimap's colour map has
no `swarmer` key, so pushing the sub-kind today would render the aliens dim rather than
hostile-red. One key in `minimap.gd` (MED-3's file) would let the sector pass the
sub-kind through.

**LOW-1 — a countermeasure has no bound key.** §11 adds `interact`/`warp`/
`consume_fuel_cell` only; nothing binds `cm_chaff`/`cm_flare`. The wiring reads
`countermeasure_chaff`/`countermeasure_flare` behind `InputMap.has_action` guards, so the
mechanic ships and the two actions are what the orchestrator would add to `project.godot`
(which this pass may not edit). The probe drives `WeaponComponent.use_countermeasure`
directly, the same seam a binding reaches.

**LOW-2 — the deaths' wreck is not recoverable across a transition.** §2.7's 5-minute
window is implemented as the drop's own lifetime (`pickup._age = LIFETIME − 300`, measured:
≥ 295 s of life), but the flight scene is discarded when the respawn route lands, so the
wreck does not survive it. A sector-persistence record (the wreck + its drop) is slice 4;
until then a death costs the hold, which §2.7 contemplates but does not intend as
permanent. `Pickup.setup` growing a `lifetime` argument is the clean seam.

**LOW-3 — no explosion visual.** §4.2 item 8's death shockwave ships as physics only
(`Impact.apply_shockwave` over `EXPLOSION_WINDOW` to every rigid body the sector holds,
plus the hull); the bloom and the debris are FX and slice 2.5's.

**LOW-4 — the hull flies for the frames between death and the respawn route.** The wiring
switches the wreck off (`set_physics_process(false)`, `set_process_unhandled_input(false)`,
the `player_ship` group left) rather than giving `PlayerShip` a death state, which this
pass may not add (mount seam only). A `dead` gate on the hull is slice 4's.

---

## 5. Deviations, decisions and the values no doc states

**5.1 Mounting (no contract change).** `PlayerShip` mounts `WeaponComponent` exactly as it
mounts the mining laser: the node name is a const (`WEAPONS_NODE`) the wiring resolves, the
script is reached by `load` (never by `class_name`, so a headless run of a tree a parallel
worker is still writing cannot fail), and the mount is gated on the fit carrying a weapon
module (`WeaponComponent.weapon_id` normalizes `w_laser` → `laser`; an unknown id is not a
gun). The v1 standard fit carries `w_laser`, so a launched ship has one group. A hull swap
to a weaponless fit releases the node, mirroring `_sync_mining_laser`.

**5.2 The trigger moved off the scene.** `game.gd` no longer fires anything by hand: the
slice-1 `_fire(slot)` placeholder (spend a round per key press) is deleted, because the
mounted component owns the shot, the pack and the Energy draw, and keeping both would
double-spend. `fire_primary` is read by the component (`held` = fire the selected group).

**5.3 `_lock_progress` empty convention: "≤ 0 hides".** UI_SPEC §3.5 says only "(empty
hides)". The HUD uses the warp bar's own convention (`set_warp_channel`: ≤ 0 hides), so the
ring's first frame is 0.0 and it appears on the frame after; a landed lock holds 1.0.

**5.4 The ring's running colour.** §3.5's running arc is "Steel Highlight `#565C63`", which
the shipped theme does not carry as a token — and `accent_nav` is this worker's single
sanctioned hex, so a second literal was not available. The running arc takes the nearest
existing steel (`text_dim`) and completes to `metal_light` exactly as the spec writes. One
theme token (`steel_highlight`) would close it; the theme is a forbidden file.

**5.5 The heading marker's `bone_text`.** §3.6 asks for a white (`bone_text`) tick; the
theme carries no `bone_text` and the prompt's carve-out covers `accent_nav` only, so the
marker falls back to the nearest existing near-white (`text_primary`) and is reported.
One theme token closes it.

**5.6 Drawing details with no spec row (render, not balance).** The dial's arc stroke is
`THICKNESS_RATIO` 0.05 of the dial's short side, the ring's stroke 1 px and the marker's arm
4 px; the dial's segment gaps are zero (the spec states only "gap at the bottom"), and the
marker's fade is `SECONDS` 0.25. Each is a named constant on its own widget, one edit to
retune, and none is a gameplay value. The marker's life is the one a reviewer may want
shorter or longer.

**5.7 Q and the passive radar.** See MED-4: `target_next` (which has existed in the input
map with no consumer since the wave-1 amendment) now cycles the passive radar's marks.
A mark is not a lock: the ring, the seeker and countermeasure interaction all still need
the 1.2 s channel.

**5.8 The lock pick is a point query, not a distance.** §4.1 says "clicking a hostile inside
lock range". The pick is a `PhysicsPointQueryParameters2D` on the hull layer, so the click
must land on the hull's own collision circle (art-derived) — no invented pick radius — and
the result is then filtered to hostiles inside `ShipStats.lock_range`. A click that misses
every hull falls through to the ship's own fly-to order (slice 1's behaviour), and a
successful lock order cancels the order that same click placed, deferred, so the outcome
does not depend on which node saw the event first (measured: a click on a hostile starts a
channel and leaves no move order).

**5.9 Guarded seams, named not invented.** `countermeasure_chaff`/`countermeasure_flare`
(the missing bindings, LOW-1), `COUNTERMEASURE_ACTIONS`/`TARGET_NEXT_ACTION`/`PLAYER_GROUP`
as consts with their owners named in the comment, and `EVENT_AMMO`/`EVENT_DROP`/`EVENT_KILL`
as this scene's additions to 01 §7's event vocabulary (the file gains the three names, not
new numbers).

**5.10 `hud.tscn` is byte-identical on purpose.** My file set includes it, and CONTRACTS §7
records that the slice-0 pool blocks are built in code "until they move into the scene". I
left them where they are: moving them in changes a shipped, owner-approved look (the bars
would either gain the scene's atlas caps or need new sub-resources), no slice-2 requirement
needs it, and this pass's three new widgets cannot live in the scene anyway (an inner class
cannot be attached from a `.tscn`). The documented follow-up therefore stands, now with the
scene's owner (this worker) having read it and chosen.

**5.11 The HUD's three new widgets are inner classes built in code**, the same idiom
`_build_pool_blocks` established for exactly the same reason (`target_reticle.gd` and the
theme are other owners' files, and an inner class cannot be attached from a scene). They
are self-contained: each reads its own tokens off the theme (an inner class cannot see the
enclosing class's constants — the limitation `weapons.gd`'s `ChaffGhost` documents) and the
Hud only builds, positions and drives them. The dial joins `CanvasLayer/BottomLeft/Blocks`
below the ammo panel and centres itself: §3.6 says "bottom-centre inside `BottomLeft`'s
parent column (below the ammo panel)", and the column below the ammo panel is that
container, whose MarginContainer is anchored bottom-left rather than bottom-centre. Reported
for the owner's reading of the sentence.

**5.12 Four read-only read-backs joined the HUD API** (`lock_progress()`,
`speedometer_ratio()`, `lock_ring()`, `speedometer()`, `hit_marker_node()`,
`target_info()`), the same reason `TargetReticle.state()` exists: so a caller — and a
headless probe — can assert what the HUD holds without reaching into a sub-node. Nothing
frozen changed; W6's CONTRACTS §7 pass can decide whether to pin them.

**5.13 `_lock_acquired` was written and never read, and is gone.** The landed lock stays
`WeaponComponent.lock_target`'s answer, so the scene keeps no second copy.

**5.14 One placement decision worth a reviewer's eye (`sector.gd`).** A hull is anchored on
an existing POI, never on an invented offset: §5's "guards asteroid fields/wrecks" takes the
next field (round-robin over the sector's own fields), and a patrol or convoy takes the
station (the arena centre in a sector without one). Consequences, both measured: a hull
spawns on top of its POI, and the hulls of one row share an anchor until the solver
separates them. A scatter radius or a patrol-route row is the owner's call.

**5.15 The clock re-rolls the hulls with the fields** (§8's "local respawn happens on the
20-minute clock", W3's spawn model). A despawn is not a kill (no `died`, no loot, no heat),
and the fresh set is rolled from the registry's band again.

**5.16 The scene kills a confirmed hit from the target's own pools.** §4.2 item 4 puts the
marker on the HUD and W1's components publish no "hit landed" signal, so the wiring reads
the marked hull's hull+shield total between two window pushes and flashes the marker on a
drop. A hit on a hull that is not the marked target has no feedback; one
`hit_landed(target, amount)` signal on the component would close that, and is W6's call.

**5.17 A hull's transform does not follow a post-entry assignment (a probing note, not a
finding).** Placing a `RigidBody2D` fixture by setting `global_position` after `add_child`
is overwritten by the body's own state (measured: a rock placed mid-way between two hulls
snapped back to the world origin and the LOS ray sailed past it; the same rock positioned
*before* entering the tree stays put and blocks the ray). Probes and suites that place
rocks or bodies should set the transform first. `NpcShip` is unaffected in practice (its
`setup` re-syncs), which is why W3's placement worked.

---

## 6. What W6 should re-run

1. `.agents/gen/slice2_w5_probe_source.gd` → copy to `vajb-orbit/tools/_probe_s2w5_wiring.gd`
   and run (§2, command 1) → `ok=65 failed=0 blocked=0`; delete the copy and its `.uid`.
2. The full gate (§2, command 2) → `passed=200 failed=0` (re-measure; the number belongs to
   the frozen wave).
3. The five boot gates (§2, command 3) → exit 0 each.
4. The three claims worth attacking: HIGH-1 (a beam or bolt on a real hull charges nothing —
   run the probe's `[damage]` block, then `Damage.apply` the same hull node and watch the
   shield move); the 1.2 s channel's rock block (freeze the target before placing the rock,
   §5.17); and `_enemy_engaged()`'s two conditions (§7's "no hostile in Alert/Engage
   targeting the player").
5. `docs/CONTRACTS.md` §7 (the HUD's slice-2 additions) and a new slice-2 section for the
   wiring consts and the `Sector`/`NpcShip` spawn contract — W6 is this wave's only
   CONTRACTS writer.

---

## 7. Environment, deferrals and disclosures

- No editor was used; every run was headless and bounded with `--quit-after`, stdout went to
  a log read afterwards, and nothing was left in the background.
- `res://game/player_ship.tscn:4` and `res://game/game.tscn:4-6` carry stale `ext_resource`
  UIDs (they fall back to the text path). Environment-deferred per addendum ruling two
  (already recorded by W2); not touched.
- **Disclosures.** Four writes went through the shell rather than the tools, all inside the
  project file set this worker owns or in `.agents/` report space: (1) the removal of the
  write-only `_lock_acquired` field (§5.13) was applied with a `py -3.14` one-liner instead
  of the `edit` tool — a deviation from the addendum's "use the write tool normally";
  (2) that one-liner's text-mode write turned `game.gd`'s line endings into CRLF, and a
  second `py -3.14` pass restored LF (git reported the CRLF, the file is LF again and the
  diff is clean; measured: 0 CRLF, 1451 LF); (3) the probe was archived into
  `.agents/gen/slice2_w5_probe_source.gd` and deleted from `tools/` with `py -3.14`
  (W1 recorded `cp` for the same step); (4) the archived copy was normalized to LF and
  re-run from `tools/` once more so the log in §1/§3 is measured on the *frozen* tree, then
  deleted again. Every other write — both suites, the probe, and every edit to `hud.gd`,
  `game.gd`, `sector.gd` and `player_ship.gd` — went through the `write`/`edit`/`multiedit`
  tools.
- No asset was read, moved or swept; the `assets/` tree is the graphics lane's and its
  naming re-layout stays environment-deferred.
