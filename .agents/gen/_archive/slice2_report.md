# Engine slice 2 — Fight: wave report (orchestrator, 2026-09-21)

Second wave of the queue in `.agents/gen/dispatch_coder.md`. Executed
W0 → W1–W4 → W5 → W6 → W7 → W8, plus one closing fix (W9) and three
orchestrator-owned steps (input map, the rulings, the doc close-outs).

**Verdict: closed.** Weapons fire and a shot's damage lands on a ship, the damage
pipeline carries §4.2 item 5's context, six archetypes plus the alien swarmer run
on one brain, loot rolls from the amended tables, the HUD gained the lock ring,
the radial speedometer, the pool bars and the ghost blips, and death respawns
docked. The universal gate reads **219 tests, zero failures, exit 0**;
`verify_wave.py verify --baseline slice2_start` returns `problems: []` with
`hud.tscn` and the theme provably untouched.

---

## 1. What the wave delivered

| File | Bytes | md5 | Nature |
|---|---:|---|---|
| `game/weapons.gd` | 36 853 | `6541e43e613d` | **new** `WeaponComponent`: the six-family table (§4.1 + §13), trigger/ammo/Energy draw, the lock seam, both countermeasures, guns-on-rocks, recoil. W7 added `_sink_for` |
| `game/projectile.gd` | 24 143 | `dab92bb0eff6` | **new** `Projectile`: ballistic + 2.2 rad/s homing, the mine's arm/trigger, range fizzle, flare `retarget`, knockback + blast. W7 added `_sink_for` |
| `game/damage.gd` | 17 047 | `3f7ce9bed092` | **new** `Damage`: `apply`, `regen`/`REGEN_QUIET` 4.0, the item-5 `context`/`bearing`, and `ram`/`knockback`/`detonate` routed through slice 0's `impact.gd` |
| `game/npc_registry.gd` | 28 937 | `fbec7c519f6e` | **new**: nine archetype rows, §13's per-sector band, doc 13 heat tiers, swap-ready sprite paths, seam rows |
| `game/npc_brain.gd` | 18 789 | `86b6d9accd20` | **new**: one state set, injected LOS, leash 2 500, `AGGRO_COOLDOWN` 5.0, intent only |
| `game/npc_ship.gd` | 30 262 | `cb2ca1e428fa` | **new**: `RigidBody2D` hull on the player's physics law, the `Damage` sink, `died`, `engaged_with()` |
| `game/loot_tables.gd` | 10 121 | `f05585db6be1` | **new**: the four `06` tables weighted, `cm_chaff`/`cm_flare` at 0.15 |
| `game/game.gd` | 55 904 | `4cacbf1ca7ae` | targeting, the lock channel with LOS, Q/ESC, the target window, countermeasure triggers, the real warp gate, ammo filing, the death flow; W9 made the ammo settle idempotent |
| `game/sector.gd` | 18 153 | `75c83cb8bf14` | §8's on-entry NPC population, hull blips, the clock's hull re-roll |
| `game/player_ship.gd` | 36 402 | `01618268e26b` | the `WeaponComponent` mount, `take_damage`/`shield_up`, the ram's `ctx`, the `Damage.regen` frame step (on top of slice 0's reactor chain) |
| `game/player_state.gd` | 12 005 | `850a07f6a3c5` | `SHIELD_REGEN_DEFAULT` + `shield_regen` (+21 lines, additions only) |
| `ui/hud/hud.gd` | 48 056 | `5ec803118fb3` | `set_lock_progress`, `set_speedometer`, `hit_marker`, the payload's `in_range`/`threat`, and the three widgets. Carries batch-2's minimap zoom fix |
| `ui/hud/minimap.gd` | 9 274 | `063535874c08` | W7: the `ghost` flicker kind (0.3–0.7 at 6 Hz) and the `swarmer` kind |
| `autoload/player_profile.gd` | 21 441 | `248ad2d684b4` | W7: `set_ammo(weapon_id, rounds)`, the writer §4.3 needed |
| `docs/CONTRACTS.md` | 50 647 | `b085df77cfdd` | W6's **§8.2** + §1/§7/§9 + changelog **v1**; W8's **v1.1** |
| `project.godot` | 8 156 | `ab35549ae2ce` | **orchestrator-applied** via godot-ai only: `countermeasure_chaff` = Z, `countermeasure_flare` = X (20 actions) |
| `ui/hud/hud.tscn` | 18 780 | `343d63f205aa` | **byte-identical** — W6 ruled the code-built widgets acceptable (L19) and the verifier proves the file is absent from the diff |

Six new test suites: `test_engine2_{weapons,npc,loot,hud,wiring,fixes}.gd` —
**139 tests** added by this wave (the suite went 80 → 219 as the wave progressed;
219 is the final frozen count).

## 2. Acceptance, as measurements

| Requirement | Measured |
|---|---|
| A shot damages a ship (the HIGH) | 1 s of laser at 300 u drains the shield **800 → 770 = exactly 30** (§13 dps) while the shooter pays 100 → 98.92 Energy; a released cannon bolt charges the hull **by exactly 27** |
| Plasma's shield rule | shields up: **70.0** drained; shields down: **87.5** hull (70 × 1.25) |
| Range cap and the extraction monopoly | the beam at 620 u drains **0**; a second of fire on a rock drains **3 ore units** (30 × 10 %) and spawns **no pickup** |
| Absorb / regen / ctx | 900 into an 800 shield → shield 0, hull untouched; regen off at `REGEN_QUIET` − 0.001 and on at `REGEN_QUIET`; the ctx round trip records direction/impulse/family |
| The brain | no contact → patrol; a player inside 900 u → engage with `fire`; blocked LOS holds **alert**; a pirate at **29 %** hull flees and at **31 %** does not; engaged at 4.6 s, clear at 5.5 s; a **swarmer** engages on the same brain |
| Loot | chance sums 1.70/1.70/1.40/1.35/4.00; expected units 2.15/2.30/1.50/6.375; the maw's floor 1025 CR, mean 1584.75; EV drift ≤ 0.65 % over 20 000 seeded rolls |
| Countermeasures | **Z** → chaff 1 → 0 with **3 ghosts**, `jamming` true; **X** → flare 1 → 0 with a live flare node; **R** → fuel 20 → **60**, cooldown 10.0 s, cell 1 → 0 |
| HUD | the lock ring, the radial dial, the hit marker and both pool bars read back from the live `hud.tscn`; `swarmer` == `hostile` == `accent_danger`; `ghost_alpha` peaks 0.7000 / troughs 0.3000 |
| Boot gates | five scenes exit 0, logs **byte-identical to the pre-fix review's** |
| Universal gate | **`passed=219 failed=0`**, exit 0, no `SCRIPT ERROR` |

## 3. Findings: W6 → W7/W9 → W8

| # | Tier | Finding | Disposition |
|---|---|---|---|
| F1 | **HIGH** | **no weapon damaged a real ship** — a hull's collider is its bare `HullBody`, and both delivery sites handed the hit to it unresolved | **fixed** by W7's `_sink_for` (route a, the reviewer's); W6's own probe went `124/2 → 126/0`, W8 re-ran it byte-identically and independently measured 800 → 770 |
| F2 | MED | the ammo half of §4.3 was inert (`PlayerProfile` had no writer) | **fixed**: `set_ammo` added; filed 300 → 297 for 3 rounds fired, the unfired pack untouched, surviving a save round trip |
| F3 | MED | the item-5 delivery seam has three owners | **open, owner/spec** (a refactor, no behaviour change) |
| F4 | MED | the minimap lacked the `ghost` flicker and the `swarmer` kind | **fixed** by W7; measured 0.3–0.7 at 6 Hz, no new theme item, no hex literal |
| F5 | MED | `cm_chaff`/`cm_flare` had no key (§11 binds none) | **fixed by the orchestrator** under ruling **R5**: Z and X, bound through godot-ai and proved by three real key events in a running game |
| F6 | MED | four values trace to no spec row (mine alpha, kinetic cadence, projectile mass, seeker fuse) | **accepted** under ruling **R6**; the next spec pass records 180 and 0.6 s |
| F7 | MED | W3's six doc holes (the human/alien split, the patrol count, alien/turret class rows, NPC armament, stand-off, turret scan radius) | **open, owner/spec** |
| F8 | MED | `cm_*` have no `03` §3 row | **open** — the P2/station-shop pass |
| F9 | MED | `06`'s prose hauls were stale against its own tables | **closed** by a doc worker: 2.15 / 28.375 / 11.83 %, 2.30, 1.50, 6.375, floor 1025, mean 1584.75 |
| F10 | MED | a credit cache has no distinct visual | **open** — needs the graphics lane's salvage glyph |
| F11 | MED | the NPC band's pointer chain was two hops from numbers | **closed**: `11_galactic_map.md` §3 now cites `18_engine_spec §13` |
| R1 | MED | **new in W8**: `_file_ammo_report` was not idempotent within one launch — a second dock press inside Router's 0.2 s fade window re-applied the fired delta (297 → 294) | **fixed** by the closing pass W9 (297 → 297), with a negative control proving the new test catches the regression |
| LOW ×11 | LOW | L19–L29, including L19 (`hud.tscn` kept byte-identical — ruled **acceptable**) | `.agents/gen/LOW_BACKLOG.md` |

The pattern worth remembering: W1–W5 each implemented their slice correctly and
each left the **seam between them** unwired. W6 found the missing link by firing at
a real ship, and W8 found that the fix for F2 had *turned on* a latent double
charge. Both were invisible to the workers who wrote the code.

## 4. Owner rulings made during the wave

Full table with the action taken: `.agents/gen/slice2_owner_rulings.md`.

1. **R5 — `countermeasure_chaff` = Z, `countermeasure_flare` = X.** Applied by the
   orchestrator through godot-ai; proved live (chaff spawns 3 ghosts, the flare
   node appears).
2. **R6 — the mine's borrowed alpha 180 and the kinetics' borrowed 0.6 s cadence
   are accepted**; the spec pass records them.
3. **R7 — the UI chrome regression goes to the art lane**, which re-cuts the
   plates tight rather than patching the theme.
4. **R8 — the backdrop target is 4K**, so a 2× cut is owed for every large
   element.

## 5. Environment, and the two lanes running beside this one

- **The assets re-layout completed during this wave**: the `env/` family was
  re-pathed (the star tiles now resolve under `assets/env/tile/`), and the
  graphics lane shipped the swarmer, Sibelon and Apex hull sheets plus all eight
  Phase G FX. The remaining chrome geometry defects are routed to that lane by
  ruling R7/R8 (`.agents/gen/ui_chrome_regression.md`).
- **The slice-0 leftovers are all closed**: the REPAIRS panel rows are still
  open (the free-service rows), and the C/R binding question is settled R3/R5.
- `docs/gameplay/19_testing_notes.md` B2-3 is ticked and B2-1/B2-2 annotated by
  the batch-2 doc worker; the `IMPLEMENTATION_PLAN` §9.8 follow-up line landed.

## 6. Open items, ranked

1. **Owner (the spec is owner-locked, so no worker may touch it):** strike the
   superseded refuel wording (§2.1 ruling 13, §4.4, §12 item 8); correct §11's
   `consume_fuel_cell` = C to **R** and add the two countermeasure rows (Z/X);
   tick the §13 speed table v2 △ rows; add the mine's 180 alpha and the kinetics'
   0.6 s cadence as their own rows (R6).
2. **Graphics lane:** the chrome re-cut (R7) and the 4K 2× backdrop cuts (R8),
   plus the tint stencils' lost import settings and the `_48` zoom-button swap.
3. **Spec/economy items, none blocking:** F3's seam refactor, F7's six holes,
   F8's `03` rows for `cm_*`, F10's cache visual, and the free-service rows in
   the REPAIRS panel.
4. **Slice 2.5 (Feel)** is the next engine brief: motion blur + camera pull +
   dust, damage smoke/ripple/shatter, dash charge FX (§3.4 + FX_SPEC §7) — all
   signals it needs now exist.

## 7. Evidence index

| Artifact | Path |
|---|---|
| Worker reports (the chain) | `.agents/gen/slice2_{w0,w0b,w1..w9}_report.md` |
| Review + re-review | `.agents/gen/slice2_review_report.md`, `slice2_w8_report.md` |
| Owner rulings | `.agents/gen/slice2_owner_rulings.md` |
| LOW backlog | `.agents/gen/LOW_BACKLOG.md` (L19–L29) |
| Context files given to the long passes | `.agents/gen/slice2_w{5,6,7,8}_context.md` |
| Final gate + wave diff | `.agents/gen/_slice2_gate_final.log` (219/0), `_slice2_verify.log` (`problems: []`) |
| Adjusting lanes | `batch2_report.md`, `batch2_docs_report.md`, `slice2_lootdocs_report.md`, `ui_chrome_regression.md` |
