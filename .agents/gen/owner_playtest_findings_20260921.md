# Owner playtest findings — 2026-09-21 (live, mid-wave)

Recorded by the coding orchestrator while the UI-chrome code lane was in flight.
The owner's words are quoted; every "measured" line below names the command or
probe that produced it. **Nothing here has been fixed yet.**

## The owner's report

> "if enemy is selected pressing buttons doesnt do anything"
> "shooting is not working" — "i cannot shoot asteroids"
> "there is no collision damage yet"
> "the collision works on ship (when i hit the asteroid) but the asteroid isnt moving"
> "there is a weird drag in movement — i press W and release and it still goes forward
> for a second, making movement weird — less realistic. inertia should be there but
> not with weird drag"
> "reticle moves on its own — at the start, after game launch, the reticle jumps for a
> second or two"
> "i press [fire] in the hangar before launching and the ship fires"

## What is measured so far

**A. The trigger works.** In a live run of `res://game/game.tscn` (godot-ai
`project_run` + `input_action`): pressing `fire_primary` (Space) set
`WeaponComponent.is_firing()` true and drained Energy 100.0 → 93.73 over ~1 s
(the laser's 6 E/s beam draw), with `dry_reason()` empty and `fitted()` `["laser"]`.
So the keyboard trigger, the energy spend and the beam path all function in a
direct-scene run.

**B. Weapons have no route to a rock.** `game/asteroid.gd` exposes neither
`take_damage` nor `damage` (it exposes `apply_work(amount)`, the mining cleave).
`game/weapons.gd:_deliver` returns silently when the sink answers to neither name,
so a weapon shot at a rock does nothing at all. Whether weapons *should* chip rocks
is a spec question (§6 cleaving is mining work, §4.1 defines the weapon families),
not a code defect — owner ruling needed.

**C. A rock's half of a ram has no receiver.** `game/asteroid.gd:193-194` sets
`collision_layer = 1`, `collision_mask = 0`. `player_ship.gd:_on_hull_body_entered`
offers the peer's half through `apply_collision_damage`, which `Asteroid` does not
implement (`npc_ship.gd:338` and the player hull do). `asteroid.gd:103`'s own comment
claims "a momentum-conserving contact", and `LINEAR_DAMP` 3.71 was derived from a
450 u/s ram handing the rock ~409 u/s — but nothing in the shipped code was measured
to move a rock. **A rock ram is therefore unverified end-to-end.**

**D. The ram probe I ran was invalid — do not cite it.** I teleported the player hull
420 u from a rock and set its `linear_velocity` to 450 u/s toward it. The ship's root
is a `Node2D` whose `HullBody` owns the transform, so the teleport did not hold: the
ship began ~3080 u away, travelled 415 u and its velocity decayed to 34 u/s — which
is the ship's own flight-model drag, not a contact. Rock velocity stayed (0, 0) and
position delta 0.0, hull 950.0 and shield 600.0 unchanged, i.e. **no contact ever
occurred**. This matches `docs/CONTRACTS.md` §9's own trap list: a live but
*unfocused* game window is unreliable for input and timing measurements, and the
embedded game freezes when the editor loses focus.

**E. Collision damage has a documented floor.** `game/impact.gd`:
`COLLISION_MIN_DV` 40.0 u/s and `COLLISION_FACTOR` 2.0e-5 — below 40 u/s a contact is
free by §13's own row ("light bumps cost nothing"). Whether the owner's rams were
above that floor is unmeasured.

**F. The reticle seeds itself from the mouse, then follows it.**
`ui/hud/target_reticle.gd:59-64` (`_ready`) sets `_cursor_position` from
`viewport.get_mouse_position()` and `:72-77` (`_input`) overwrites it on every
`InputEventMouseMotion`; the crosshair itself is drawn at the node's own centre
(`:142-144`), so the visible jump is the node being placed at the seeded position and
then snapped to the first real motion event — or the window warping the pointer on
focus. The owner's "jumps for a second or two after launch" is consistent with this
path; **unmeasured**, and the fix depends on what the seed reads in the real flow.

**G. The hangar cannot fire through the weapon path.** `grep -rn WeaponComponent`
finds the component mounted only in `game/player_ship.tscn` and `game/npc_ship`
construction; `ui/screens/station.gd` and `ui/screens/station.tscn` contain no
`WeaponComponent` and no fire handling. So "I press fire in the hangar and the ship
fires" is either a different effect (a launch-panel cue, an audio hook, or the
preview's own animation) or the owner was already in flight. **Needs a
reproduction**, not a code fix yet.

## Why this is a wave and not a patch

- Four of the six items are **measurement questions** first (C, D/E, F, G): the
  project's law is probe-by-measurement, and §9 records that a `--script` run cannot
  exercise `Input` state and that an unfocused live window is unreliable. The probes
  must be deterministic headless scenes, as `tests/probe_w5_lint.tscn` and
  `tests/test_ui_slot_layout.gd` already are.
- Two items are **owner rulings, not code**: weapons-versus-rocks (B) and the
  inertia/drag feel (the flight model's `DRAG` 120 / `ACCELERATION` 420 pair is a
  §13-adjacent feel number, i.e. slice-2.5 territory).
- The combat pipeline is slice-2 contract surface (`docs/CONTRACTS.md` §8.2, §4) and
  the collision pipeline is slice-0's (`§4`, `impact.gd`), so a repair wave must diff
  against CONTRACTS.md and add a test per fix, exactly as the slice waves did.

## Owner rulings on these findings (2026-09-21, after this report was written)

1. **Weapon fire must damage asteroids** — the rock gains the damage sink and weapon
   damage reaches it through the existing cleave channel (`apply_work`); the
   damage→work conversion is one named constant proposed for the §13 tick.
2. **The flight drag/inertia is retuned now** (inertia kept, the ~1 s carry trimmed),
   measured before and after.
3. **The reticle jump and the hangar shot are dropped** — the owner reports both
   resolved, and `ui/screens/station.gd` contains no `WeaponComponent` or fire
   handling, so the hangar observation had no weapon path.
4. **Approved: the measurement wave runs now** (C1 ram, C2 weapons, C3 decay, T1 the
   `--only` tooling flag, C5 fixer, C6 review) — brief
   `.agents/gen/combat_repair_wave_task.md`, prompts
   `.agents/gen/combat_repair_wave_prompts.md`. The hook's absolute-path cure (L31)
   was **not** approved and stays in `LOW_BACKLOG.md`.

## Proposed wave shape (for the owner to approve)

| ID | Job | Evidence it must produce |
|---|---|---|
| C1 | coder — deterministic ram probe: hull vs rock in a headless scene, fixed velocity step | rock velocity/position delta, both sides' pool deltas, and whether `collision_mask = 0` one-ways the pair |
| C2 | coder — deterministic weapon probe: each fitted family vs an NPC hull and vs a rock | per-family damage landed on an NPC hull, and the rock case's exact no-op path |
| C3 | coder — reticle drift: log `target_reticle.gd`'s target/offset over the first 3 s of a flight scene | the source of the jump or its absence |
| C4 | coder — hangar fire: does the station preview mount a live `WeaponComponent` | yes/no + the mount site |
| C5 | fixer — only what C1–C4 prove broken, one pass | before/after measurement per finding |
| W? | reviewer — re-runs every probe byte-identically | tiers, and CONTRACTS.md drift |
