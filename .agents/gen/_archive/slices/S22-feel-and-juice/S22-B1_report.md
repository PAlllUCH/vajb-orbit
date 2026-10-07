---
slice: S22
worker: S22-B1
model: deepseek/deepseek-flash (reasoning-effort max)
status: actionable
gate: "941/0 → 951/1 (952 rows = 941 + the new suite's 11; the one failure is S19's byte-seal row — Deviations (a))"
---

# S22-B1 report

## Result
A1–A4 + A8 + A12 + A13 land: one `hit_landed` seam (beams and projectiles), the marker
for any hull with the pool-drop poll retired, ram foley + one spark on both monitors, the
flash's mouth at the bow (shot spawn untouched) and the tool slot's `ModuleCatalog` label.
A4/A8/A13 were measured at their ticked values, not rewritten. The new suite carries **11
green rows**; the full gate ran twice on fresh scratch stores, identical both times:
`[SUMMARY] passed=951 failed=1` (S19's byte-seal row — Deviations (a)); `damage.gd` and
`npc_brain.gd` byte-identical; no gameplay number moved (rule 1). **Owner rulings
implemented:** ruling 18 (feedback is cosmetic), "hits must read" (S2.6), tick T-feel-4
(flash at the nose) and T-feel-6 (tool label), D15's composition §A5.2 (marker verb, ram spark).

## Acceptance list answers
- **A1 (L28) — DONE.** One `WeaponComponent` signal `hit_landed(target, amount)`
  (`weapons.gd:64`), emitted at both `_deliver` sinks (`:1892,:1899`; the beam path calls
  it at `:1317`); a shot reports its own hit back through the `&"hit_landed"` Callable the
  spawner hands it (`weapons.gd:1256`, `projectile.gd:517-519,941-956`; shot call sites
  `:808,866`), so all families share one signal. HUD: `bind_weapons` (`hud.gd:596`) →
  `_on_hit_landed` (`:608`) → `hit_marker()`, bound at launch (`game.gd:815-816`).
  Poll retired: `_target_pools_seen` gone (var, four resets, the drop check). Rows:
  unmarked hull marks (`test_s22_feedback.gd:147`), a bare pool drop does not (`:162`),
  projectile seam names target + amount + marks (`:176`).
- **A2 (L56) — DONE.** Player monitor `player_ship.gd:1185-1194` and NPC monitor
  `npc_ship.gd:566-575` both play S4's cue (`IMPACT_KIND_HULL` / `IMPACT_KIND_ROCK`,
  `projectile.gd:159-163,1238-1243`) and spawn one `spawn_chip_sparks` (`projectile.gd:1364`)
  at `_contact_point` (`player_ship.gd:1206`, `npc_ship.gd:588`). Rows: player/hull cue+spark
  at (30,0) (`:208`), player/rock (`:238`), NPC/rock (`:251`).
- **A3 (L51, tick T-feel-4) — DONE.** `PlayerShip.nose_point()` (`player_ship.gd:544`) = the
  `ShipFit.HARDPOINTS` bow band (`thrusters.front` average) × the sprite scale, else a
  radius-forward point; `_flash_anchor` (`weapons.gd:1488`) feeds `_spawn_muzzle_flash`
  (`:1454-1474`), whose mouth offset is now the rotated mouth vector, so the mouth lands on
  the anchor for any aim. Shots untouched (`muzzle_position`, `weapons.gd:1697`). Row `:279`
  asserts mouth == nose, nose forward of the middle, spawn == `muzzle_position(0)`, and that
  flash and shot genuinely desync on a mapped hull.
- **A4 (L52/L65) — verify-only, measured.** Shipped read intact: `mining_laser.gd:214-225`
  (`_apply_cycle` → `_play_chip()` + `ProjectileScript.spawn_chip_sparks`), cue
  `mining_laser.gd:53,296`; row `test_s22_feedback.gd:327` drove a real laser over a real
  rock: `[S22B1] A4 chip burst=4 cue=true world=40.0 fps=20.0`. No edit.
- **A8 (L55) — verify-only, measured.** Constants still the ticked pair
  (`player_ship.gd:207-213`), update unchanged (`:1787-1810`); row `:370` fired six arcs:
  `[S22B1] A8 arcs=6 intervals=[1.76317191123962, 2.37592267990112, 2.43622922897339,
  1.66052865982056, 2.01087355613708, 2.57118439674377]` — all inside 1.6–2.6 s, varied. No edit.
- **A12 (L70, tick T-feel-6) — DONE.** `_battery_module` (`hud.gd:1087`) gives
  `_refresh_weapon` (`:1570-1587`) the rack's cell module; a family-less tool labels by
  `ModuleCatalog.module(module).name` ("Mining Laser"), a firing family keeps the family
  label. Row `:402`.
- **A13 (FX-1/FX-2a–e/T-feel-7) — verify-only, measured.** Row `:450` asserts every pin
  against its owner: trail 12 FPS/loop/48 u (`projectile.gd:124-135`), mine 22 u (`:111-123`),
  plume constants (`:198-206`), chip 40 u @ 20 FPS (`:336-346`), arc 40 u (`:314-324`),
  bolt/slug 64/96 (`:94-106`); FX-1's 4-cell playback from the same chip row. Measured:
  `[S22B1] A13 trail=12.0/loop=true/48.0 mine=22.0 plume=16.0/1.4/14.0 chip=40.0 arc=40.0 bolt=64.0 slug=96.0`.

## Deviations from SLICE.md
- **(a) BUCKET 2 — S19's byte-seal row is red, by design.** A1 edits `weapons.gd` and A2
  edits `npc_ship.gd`, both pinned in `test_s19_quadrants.gd:94-105`; live hashes
  `weapons.gd ab861ce9…`, `npc_ship.gd e5ae0b72…` (pinned `fcdc549f…` / `a694170c…`). An
  implementer must not edit the yardstick (AGENTS.md's ladder; `S21-B1_report.md`
  Deviation (b) left the same row red, `S21-B3` re-pinned the finished tree, R1-accepted).
  **Resolution:** the wave's last editor (B2/B3 or R1) re-pins both strings once the tree
  is finished; B2/B3 move these files again, so an intermediate re-pin would be churn.
  Reversal: restore the two pinned strings and accept the red row. Nothing else in the
  seal moved (`damage.gd` `5cabf3d9…`, `npc_brain.gd` `e39440bf…` = seals).
- **(b) A3's "nose" reading.** The tick's "(`ShipFit.HARDPOINTS` mount, else radius-forward
  point)" is read as the map's **bow band** (`thrusters.front` average): the weapon mounts
  sit amidships (±7 u on the Vanguard, whose bow is ~29 u), so anchoring there would leave
  the flare over the hull's middle — the exact complaint L51 records. A fixture host with no
  `nose_point` seam keeps the pre-wave origin, so `test_weapon_fx_f1.gd` is unchanged.
  Reversal: anchor at the firing barrel's `muzzle_position`, or restore the origin.
- **(c) A3 rotates the mouth offset with the flash.** The frame pivots on its top-left, so
  the shipped constant offset let the mouth drift once the aim left the hull's axis; the
  offset is now the mouth vector turned with the flash. At rest it is byte-identical.
  Reversal: `-FLASH_MUZZLE_PX * scale_factor`, unrotated.
- **(d) `test_engine2_wiring.gd:428`'s row rewritten.** It pinned the retired poll's exact
  behaviour ("a pool drop between two pushes is a confirmed hit"), so it now proves the drop
  does **not** mark and a landed delivery does. Same row count; not in §8's move list.
- **(e) A2's spark point.** "The contact point the handler already resolves" (D15's sheet) is
  read as the hull's own surface point on the centre line (`_contact_point`), midpoint only
  as the radius-less fallback. Reversal: `(own + peer) / 2`.
- **(f) The projectile half rides an additive `configure` key** (`&"hit_landed"` Callable)
  rather than a second signal on the projectile — wave rule 2's "one signal".

## Evidence
- Gate, twice, fresh stores, identical output:
  `XDG_DATA_HOME=/tmp/s22b1_final{1,2}/xdg "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ"
  res://tests/headless_runner.tscn --quit-after 1200` → `[SUMMARY] passed=951 failed=1`
  (both); `[FAIL] test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical:
  res://game/npc_ship.gd is byte-identical` (both) — Deviations (a).
- Targeted rerun of every touched/adjacent suite → `passed=179 failed=0`
  (`--suite=` test_s22_feedback, engine2_wiring, weapon_fx_f1/f2/f4, flight_beam_g2,
  engine2_weapons, engine2_hud, d7_cockpit, engine2_npc, s2_6_flight).
- The three verify-only measurements are the `[S22B1] A4/A8/A13` lines above (both gate logs); the suite rows carry the cites.
- `sha256sum` after the pass: `damage.gd 5cabf3d9302fe942aff2ad97b4f3dc85c298e7e204fffb0e86f89e444cbf6269`,
  `npc_brain.gd e39440bf410b535c50f924208290e54dc8085eea52731890b778a4ad3fbe5d22`,
  `weapons.gd ab861ce957239ecf5f39034fc433c4e174cc263129052a6f7e1b081dbfab6c27`,
  `npc_ship.gd e5ae0b72df1dd3a7a781c64a2a4e546a288ae2f5830d0a854064e5bdf98b53c5`.

## Files touched
- `game/weapons.gd` — `hit_landed` signal + emits + `_note_projectile_hit`; nose-anchored flash
- `game/projectile.gd` — the `&"hit_landed"` config Callable + `_report_landed`
- `game/player_ship.gd` — `nose_point()`, the ram cue + spark, `_contact_point`
- `game/npc_ship.gd` — the ram cue + spark, `_contact_point`
- `game/game.gd` — `bind_weapons` at launch; the `_target_pools_seen` poll retired
- `ui/hud/hud.gd` — `bind_weapons`/`_on_hit_landed`; tool-slot `ModuleCatalog` label
- `tests/test_s22_feedback.gd` — new suite, 11 rows (one per AC, A1×3, A2×3)
- `tests/test_engine2_wiring.gd` — the marker row (Deviations (d))

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| S19 byte-seal re-pin (both strings, once, at the finished tree) | bucket 2 / wave close | `tests/test_s19_quadrants.gd:94-105` |
| A3's bow-band nose vs the tick's literal "mount" | R1/owner confirm | `game/player_ship.gd:544` |
