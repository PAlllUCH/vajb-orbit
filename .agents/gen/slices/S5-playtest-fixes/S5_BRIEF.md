# S5_BRIEF — Playtest fixes (the owner's ten findings)

Wave `S5`, slice `S5-playtest-fixes`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder in the format rules; the folder law)
2. `docs/CONTRACTS.md` **§17** (this wave's pin), then §13/§16 (the seams it wraps)
3. `docs/design/STATION_HUB.md` **§5.11** (+ §5.1/§5.2/§5.8/§5.10)
4. `docs/gameplay/10_ship_acquisition.md` **§6.1** and `docs/gameplay/09_ship_slots_modules.md` **§11** (+ §3.1/§8/§10)
5. this brief end to end

## Owner findings, verbatim (2026-09-23 playtest)

1. "Auction needs to be separeted into families: weapons, drives etc,"
2. "Shipyard should only have yours buyed ships on auction, no buying ships here,"
3. "selecting in shipyard should first preview, then click set active, right now it auto sets active"
4. "outfitting screen should be for weapons battery grouping, i want to be able to drag and drop there different kinds of weapons, the rof will be limited by the slowest weapon, so we can do mix n match of different weapons. also we can change the 'outfitting' name, sounds strange"
5. "in space station the icons on 'MODULES' left menu should have only painted icons so no svg" → **designer lane, not this wave**
6. "no fuel cells to buy as a reserve fuel"
7. "ammo, shells, pods etc should be sellable and should take slots in cargo"
8. "i want each ship to have mapped where he has back thrusters, front (for reverse) and side. same for weapon slots. i want it all mapped on a ship so that it will fire from different angles/positions etc"
9. "i want weapons to not turn as fast. weapons can have different turn speeds and in one weapon battery they can have different turn speeds as well"

## The pinned interface (CONTRACTS §17 is the source of truth; nothing here may drift)

```gdscript
# J1 — auction family tabs over the SAME draw (weights/hot slot/prices byte-identical);
#      shipyard = owned hulls only, select previews, SET ACTIVE is the sole commit
# J2 — cargo items &"ammo_laser" &"ammo_cannon" &"ammo_rocket" &"ammo_mine"
#      &"ammo_plasma" &"ammo_railgun"; ROUNDS_PER_CARGO_UNIT := 10 (reversal 1)
#      buy -> cargo (units = rounds / 10); launch auto-fills packs from cargo up to
#      ammo_max (drawn units leave the hold); EXCHANGE sells units at 60 % of list;
#      fuel cells delisted everywhere (existing stacks keep working on R)
# J3 — batteries: {ship_id: Array[Array[cell_ref]]}; SAVE_VERSION := 7
#      (v6->v7: group fitted weapons by base_id, cells ascending)
#      ARMORY (owner-ratified 2026-09-23) racks B1..B7 = drop zones for weapon_1..7;
#      drags install/swap via the §13/§16 transactions (refusals write nothing);
#      GROUPS_MAX := 7 (was 5)
#      salvo gate = max(members' cadence) — one trigger releases every armed barrel
#      (strum 0..40 ms); dry/empty rules stay per barrel (§16 rule 4's carve-outs)
# J4 — ShipFit.HARDPOINTS[ship_id] = {thrusters: {rear, front, left, right: Array[Vector2]},
#      weapon_mounts: [{pos, facing}…]}; W cell i binds weapon_mounts[i]; values
#      MEASURED OFF THE RENDERS into 09 §11's table (J4's deliverable); no map = the
#      §8 derivation fallback (the reversal)
#      thrust FX at rear anchors, brake/retro at front, strafe at the side's anchors
#      per-barrel tracking at 09 §3.1 track_dps (proposed: laser 180, mining 150,
#      cannon 120, railgun 100, plasma 75, rocket 60, mine fixed); shots fly along the
#      barrel's CURRENT FACING from its mount (owner tick: hold-until-aligned);
#      beam connects within TRACK_TOLERANCE := 5.0 deg. Reversal: TRACK_MULT := 0.
```

Rules that fix every ambiguity:
- **Escalation ladder:** inside a pinned acceptance decide and proceed; pause only on
  pin/owner-ruling findings, naming the bucket (AGENTS.md's format rules).
- J1's tabs are **display grouping** — the draw, weights, hot slot and prices are
  S3's frozen arithmetic and must measure byte-identical.
- J2's auto-load happens **once at launch**, never in flight; a pack that empties in
  flight stays empty until the next launch (no cargo-teleport).
- J3's batteries store **cell refs** (09 §4.5's layout indices), never bare ids; a
  drag that would break `fit_legal` or the mandatory set is refused **before** any
  write (S4's rules 7/8 stand — refusals write nothing). The battery's components
  positions vs W-cell divergence (09 §10's note) is resolved HERE: `battery()` answers
  cell refs, and the mount binding follows J4's `weapon_mounts[i]`.
- J4's hardpoint values are a **measurement deliverable**: probe the renders (the same
  sprite the game draws), record hull-local px in 09 §11's table, and cite the render
  path + method in the report. Never eyeball without a probe line.
- A travelling shot spawns AT its mount position with its barrel's current facing as
  its base direction; the ship's nose velocity adds as today. `w_mine` keeps its drop
  behaviour (fixed barrel, no tracking).
- Probes and gates run against scratch stores (`XDG_DATA_HOME` or repointed
  `save_path`) — twice a probe has written the owner's live account (T-93 class).
  Bounded probes only (L82); workspace-relative file paths (L92a).

## J0 dispositions (owner-ratified 2026-09-23 — read before coding)

The J0 pass found ten contradictions (`.agents/gen/slices/S5-playtest-fixes/S5-J0_report.md`);
the owner ruled on all ten. Where this section differs from a prompt line, this section wins:

- **Label:** `ARMORY` is ratified; the label lives in `ui/screens/station.gd` (not the theme).
- **Railgun ammo is its own pack:** rounds 150, cost 360, `ammo_max` 150 (2× the cannon
  pack's cost, ½ its rounds and ½ `AMMO_MAX`); icon
  `assets/icons/module/icon_module_w_railgun.svg`.
- **Ammo rows stay in ARMORY** and buy cargo units (rounds / 10) through the hold; EXCHANGE
  **buys** the units from the hold at 60 % of the per-unit list
  (`roundi(0.6 * 10 * cost / rounds)`); the `ammo_*` id maps to its family by prefix.
- **The AUCTION's `DRIVES` tab keys on `engine`**, the catalogue's slot key.
- **`GROUPS_MAX` 7 grows its consumers** (`game/game.gd`: `WEAPON_ACTIONS` + the W-slot
  ordinal call; `ui/hud/hud.gd`: the three five-entry tables to seven, railgun/mining icons
  from `assets/icons/module/`). Sets amended: J2 += `game/exchange.gd`,
  `game/component_catalog.gd`, `game/station_catalog.gd`; J3 += `ui/screens/station.gd`,
  `game/game.gd`, `ui/hud/hud.gd`.
- **The shipyard row carries no icon** (none ship).
- **Fuel cells:** J0 measured no sale surface carries a `fuel_cell` row — the delist is
  already the tree's state; assert it, change nothing.
- **Pointers in the owning docs:** §16→§17 (`battery()` answers cell refs), §5.2→§5.11,
  09 §8→§11. The rest of J0's record (stale citations, pre-D2 art paths) rides the close-out
  LOW rows and moves no code.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S5-J0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S5-J0_report.md` — the pin set vs the tree (post-D2/S3/S4), contradictions at `file:line`, no numbers invented |
| S5-J1 | commerce & hangar | `vajb-orbit/ui/station/auction_panel.{gd,tscn},vajb-orbit/ui/station/shipyard_panel.{gd,tscn},vajb-orbit/ui/screens/station.gd,vajb-orbit/tests/` | AC1/AC2 + `tests/test_s5_commerce.gd` |
| S5-J2 | consumables economy | `vajb-orbit/game/module_catalog.gd,vajb-orbit/game/game.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/ui/station/exchange_panel.{gd,tscn},vajb-orbit/tests/` | AC4 + `tests/test_s5_ammo_cargo.gd` |
| S5-J3 | batteries v2 + rename | `vajb-orbit/ui/station/outfitting_panel.{gd,tscn},vajb-orbit/ui/station/armory_panel.{gd,tscn},vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/weapons.gd,vajb-orbit/tests/` | AC3 + `tests/test_s5_batteries_v2.gd` |
| S5-J4 | hardpoints & gunnery | `vajb-orbit/game/ship_fit.gd,vajb-orbit/game/player_ship.gd,vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/game/mining_laser.gd,vajb-orbit/tests/` | AC5/AC6 + the measured hardpoint table + `tests/test_s5_hardpoints.gd` |
| S5-R1 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S5-R1_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S5-F1 | fixer | the union of J1–J4 sets + `docs/CONTRACTS.md` | only if R1 leaves HIGH/MED |

**Run order:** J0 → **(J1 ∥ J2)** → J3 → J4 → R1 → (F1 only on HIGH/MED). J1 and J2
are disjoint. J3 before J4 (`weapons.gd` is shared: J3 the group/salvo seam, J4 the
tracking/muzzle seam). Each builder writes only its own `test_s5_*.gd`.

## Tests that move, and why

- `test_s4_batteries.gd` — grouping becomes mixed + the salvo gate becomes the
  slowest cycle (09 §11 supersedes §10's identical-only + S4's per-barrel cadence).
- `test_engine2_weapons.gd` — volley-gating rows re-derive to the slowest-cycle rule;
  tracking/muzzle rows are additions.
- `test_p2b1_outfitting_panel.gd` — the pane renames to `ARMORY` and its rows become
  racks (counts move with the surface).
- `test_p2a_ship_roster.gd` / `test_p2a_launch_fit.gd` — shipyard = owned-only
  (roster assertions move to the auction's) and launch gains the auto-load seam.
- `test_s3_auction.gd` — the family tabs are display-only (its arithmetic rows hold).
- `test_p1_catalogues.gd` — the six `ammo_*` rows join the cargo catalogue.
- New: `test_s5_commerce.gd`, `test_s5_ammo_cargo.gd`, `test_s5_batteries_v2.gd`,
  `test_s5_hardpoints.gd`. Expected gate: **524 → ~565**; the measured number at
  close-out goes into CONTRACTS §9.

## Hard rules

- Frozen: `project.godot` (the `weapon_6`/`weapon_7` rows are **orchestrator-applied**
  at close-out per §1 — workers never touch the input map), `docs/gameplay/18_engine_spec.md`,
  `docs/gameplay/08_ship_slots_modules.md`, `assets/`, `addons/`, the theme (frozen; the
  `ARMORY` label lives in `ui/screens/station.gd`, not the theme).
- No balance number moves (damage, cadence, prices, `track_dps` excepted — it is a
  NEW column with proposed values and an owner tick). `max_speed` never moves.
- Scratch stores for every probe/gate; bounded probes (L82); no shell file edits;
  workspace-relative `VAJB_WORKER_FILES` (L92a); never leave a background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- The shipyard build queue (10 §3); countermeasure packs in cargo; the FITTING pane
  stays the per-cell surface (unchanged); `L123–L129` ride their own fixes.

## Owner ticks owed after this wave

1. **CLOSED 2026-09-23** — the label is `ARMORY`; the railgun pack ships its own numbers
   (rounds 150, cost 360, `ammo_max` 150); the shipyard row carries no icon.
2. `ROUNDS_PER_CARGO_UNIT := 10` (the ammo granularity; reversal 1).
3. Fire-along-facing (built) vs hold-fire-until-aligned (the §17 alternative).
4. The `track_dps` taste table (09 §3.1's new column; one value per family).
5. Standing debt unchanged: `18_engine_spec.md` §6/§13/§15, the flight-taste
   constants, slice 2.5's two calls, the Windows-vs-Linux profile question, S3's eight.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s5_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests --expect-reports .agents/gen/slices/S5-playtest-fixes/S5-J0_report.md .agents/gen/slices/S5-playtest-fixes/S5-R1_review.md` (the S4-corrected flag form)
3. CONTRACTS §9/§10 measured notes by R1; the `weapon_6`/`weapon_7` input-map rows
   applied by the orchestrator (godot-ai or the owner's `project.godot` pass).
4. `_state/WAVEBOARD.md` closed; LOW rows at the next free ids.
5. Wave-boundary commit.
