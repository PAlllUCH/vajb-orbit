# Slice 2, W7 — fixer context for this pass (2026-09-21)

You are the fixer for engine slice 2. The reviewer's report is the authority:
`.agents/gen/slice2_review_report.md`. Read it in full first, then this file.

## Your file set for this dispatch

```
vajb-orbit/game/weapons.gd
vajb-orbit/game/projectile.gd
vajb-orbit/autoload/player_profile.gd
vajb-orbit/ui/hud/minimap.gd
vajb-orbit/tests/
vajb-orbit/tools/
```

Do not widen it. If a fix genuinely needs another file, stop and report which
file and why instead of editing it.

## What to fix, in the reviewer's own order

**F1 (HIGH, blocks the wave) — a shot's damage never reaches a ship.**
The measured defect: a hull's collider is its `HullBody` (`RigidBody2D`, layer 2),
which carries no `take_damage`/`damage`, and both `weapons.gd:_deliver` (line 664)
and `projectile.gd:_deliver` (line 502) hand the hit to the collider as-is with no
owner resolution. Measured: 1 s of laser at 300 u left the victim's shield at 800
while the beam spent its Energy; a bolt crossing the same 300 u left the hull at
1250. Mines work because they resolve their victim through the `player_ship` /
`npc_ship` groups and hand the *ship* node.

Fix route (a), which the reviewer recommends: resolve the sink through the
collider's nearest ancestor in the `player_ship` / `npc_ship` groups — the exact
walk `game.gd:_hull_of` (line 640) already demonstrates for the lock pick. Route
(b) would be a forwarding script on the hull bodies; route (a) keeps one owner and
needs no new file. Then re-run the reviewer's probe
(`.agents/gen/slice2_w6_probe_source.gd`, copy it back to `res://tools/`) and show
sections B and C go green: the laser at 300 u must drain ~30 shield/s and the bolt
must charge the hull ~27. Re-measure **both** families (beam and projectile), plus
the mine as the unchanged control.

**F2 (MED, one line) — the ammo half of §4.3 is inert.**
`PlayerProfile` publishes `ammo_of` / `ammo_max` / `buy_ammo` but no writer, so
`game.gd:_file_ammo_report`'s `set_ammo` guard never passes and shot deltas are
never filed on dock (read `autoload/player_profile.gd:143-158` and
`game.gd:1090-1113`). Add the writer mirroring `set_vitals` — `set_ammo(weapon_id,
rounds)` plus the `_touch`/`profile_changed` handling the other writers use — and
prove it with a round trip: fire, dock, and read the filed pack back.

**F4 (MED) — two §10 blip requirements are unmet in the minimap.**
`ui/hud/minimap.gd:_color_for` (line 150) knows only `hostile` / `friendly` /
`self`, so UI_SPEC §3.3's chaff blip is drawn as a neutral dot with no
"alpha 0.3–0.7 at 6 Hz" flicker, and §10's `&"swarmer"` sub-kind cannot be pushed
without rendering the aliens dim (they are correctly hostile-red today through
`NpcShip.blip_kind()`). Add a `ghost` key with the time-based alpha and a
`swarmer` key mapping to the hostile colour. Use the existing theme tokens only —
no new theme item, no font-size override, no hex literal — and keep the existing
kinds' colours byte-identical.

## What NOT to fix — the reviewer assigned these elsewhere

- **F3** (the item-5 delivery seam has three owners): a refactor, not behaviour.
  It rides the owner/spec pass. If your F1 fix naturally collapses one of the
  three, say so in the report; do not go looking for the refactor.
- **F5** (no bound keys for `cm_chaff` / `cm_flare`): the orchestrator owns the
  input map. Do not touch `project.godot` and do not add a key in code.
- **F6, F7, F8, F11**: spec holes, an owner tick, a doc pointer. Report only.
- **F9** (06 §3's prose hauls are stale): a separate doc worker owns it.
- **F10** (a credit cache has no distinct visual): needs art; not this pass.
- The assets re-layout and the UI chrome regression: not findings, do not touch.

## Rules that still apply

- Universal gate: it is green at **200 tests**; keep it green and re-measure the
  total yourself. Add a test for each behaviour you fix.
- Every fix cites the spec section it implements and carries a before/after
  measurement. Never invent a number.
- `consume_fuel_cell` = R; refuel/recharge are free; assets are environment-
  deferred.
- Write your probes with the `write` tool (your set includes `tools/` and
  `tests/`), delete them with their `.uid` before the report, and leave `tools/`
  holding only `build_theme.gd` + `derive_icon_tints.gd`.
- Report to `.agents/gen/slice2_w7_report.md` with per-finding before/after
  numbers, files changed with byte sizes, exact commands and output.
