# S4_BRIEF — Weapon batteries (group weapon systems in OUTFITTING)

**v2, 2026-09-23.** v1 was written before the wave's drift check. H0 measured four HIGH and
five MED conditions the v1 pin could not be built under (`S4-H0_report.md` F1–F9), so the
developer session amended the pin first (CONTRACTS §16 rewritten as **v0.8.0**, 09 §10 got a
dated amendment, STATION_HUB §5.1 got the strip's battery anatomy). This brief is that pin's
summary; **CONTRACTS §16 is the source of truth** and every rule below cites it. The v1 text is
in git history at the S4 pre-wave commit `f3b0d24`.

Wave `S4`, slice `S4-weapon-batteries`. Read in this order before working:
1. `AGENTS.md` (rules; the folder law; the worker-file enforcement)
2. `docs/gameplay/09_ship_slots_modules.md` **§10** (the battery law — the owner's
   rulings verbatim, plus the 2026-09-23 amendment on ammo, the strum's home, the two
   index spaces and the empty cells) and §4 (the transactions it loops)
3. `docs/design/STATION_HUB.md` **§5.1** (the strip's law since 2026-09-23) and §5.10
   (the summary of it)
4. `docs/CONTRACTS.md` **§16 v0.8.0** (this wave's pin), §13 (the transactions) and
   §8.2 (where the fire side lives)
5. this brief end to end

## Owner requests, verbatim

- "in outfitting there should be option to group weapon systems. Like 3 lasers
  together, 3 bolters together etc. Its pointless to have each weapon on separate slot."
- (asked directly how a group sits in the mounts — the ruling this wave is built on)
  **N barrels keep N W mounts**: the battery is one row and one trigger; 08's W
  counts stay the barrel cap.

## What is already measured (do not re-derive, do verify)

- **The measure-first item is answered: no volley exists, and the grouping data is already
  destroyed at the seam.** `WeaponComponent.tick` fires exactly one weapon
  (`game/weapons.gd:520` reads `selected_weapon()`), and `set_fitted` drops any duplicate id
  (`game/weapons.gd:365-371`, the `_fitted.has(id)` guard at `:369`), so a
  `[w_laser, w_laser, w_laser]` fit reaches the component as **one** group while
  `ShipFit.fitted_ids` (`game/ship_fit.gd:481-489`) hands over three entries. No
  `volley`/`salvo`/`strum`/`battery` symbol exists anywhere in the tree.
  **So H2's volley is new work, not a strum-and-read reduction** (CONTRACTS §16 rules 1–4).
- **Ammo is per family, one pack shared by every barrel** (`WeaponScript.ammo_slot`,
  `game/weapons.gd:1519-1526`; `game/player_state.gd:84-89`; `game/game.gd:1247-1249`).
  "One round per barrel" therefore spends three rounds from the one `laser` pack for a
  3-barrel volley (CONTRACTS §16 rule 5).
- **The component is handed a flat id list with no cell indices** — `player_ship.gd:1205-1206`
  passes `_fit_ids` (`ShipFit.fitted_ids`), which drops family-less modules, so a component
  position is not a W-cell index (CONTRACTS §16 rule 3).
- OUTFITTING's FITTED WEAPONS strip today is **one line per W cell** with a single REMOVE
  plate and no aggregation (`ui/station/outfitting_panel.gd:590-616`, `:628-649`); the strip's
  node set is **fixed** (pre-built `_max_weapon_cells()` rows, shown/hidden by index, because
  the profile emits `profile_changed` from inside the handler that started it — `:147-148`,
  `:591-596`). `OWNED ×%d` and the three §13 refusal literals live only in
  `ui/station/fitting_panel.gd:111`, `:147-149`, which is in no S4 worker's set. The FITTING
  pane (`ui/station/fitting_panel.gd`) stays the per-cell surface.
  **v1's two stale claims, corrected:** the strip does **not** aggregate by `base_id` today
  (F10), and there is no `module_action` at `outfitting_panel.gd:873-882` — the file is 813
  lines and S3 retired the MODULES rows (F11). L78's precedence question is reachable now only
  through the single-cell actions the expander reveals.
- The fit is one instance per W cell (`fit_module_at`/`clear_fit_slot`, CONTRACTS §13; layout
  indices 09 §4.5) — **this wave changes no fit shape**. After S3, fitted cells hold
  `instance_id`s; the strip resolves each cell through `base_module_id`.
- `module_count(base_id)` does **not** aggregate a base's instances (it reads 0 for an
  instance-keyed bag — `player_profile.gd:368-372`), and `fit_module_at` refuses on
  `module_count(module_id) == 0` (`:855`), so a batch must resolve its instances through
  `instances_of(base_id)` (`:487-500`), which is why §16 rule 7 pins the pairing.

## The pinned interface (CONTRACTS §16 v0.8.0 is the source of truth; nothing here may drift)

```gdscript
# PlayerProfile — bulk wrappers over the §13 composed transactions
fit_battery(ship_id: StringName, base_id: StringName, indices: Array) -> bool
clear_battery(ship_id: StringName, base_id: StringName) -> bool
# WeaponComponent — the volley seam
const BATTERY_STRUM_MS := 40            # per-barrel release offset ceiling, ms; reversal: 0
fitted() -> Array                       # one entry per barrel, fit order, duplicates kept
battery_ids() -> Array                  # the distinct weapon ids in fitted(), first-barrel order
battery(base_id: StringName) -> Array   # that battery's barrel positions in fitted()
```

Rules that fix every ambiguity (each is §16's, with the reversal §16 names):

- **`fitted()` is per barrel and keeps duplicates** (§16 rule 1). The `_fitted.has(id)` guard
  at `game/weapons.gd:369` goes; unknown/foreign ids are still dropped and the fit's order is
  preserved.
- **Groups address batteries, not barrels** (§16 rule 2): `battery_ids()` is the distinct ids in
  `fitted()` in first-barrel order, `select_group(g)` selects `battery_ids()[g - 1]` (clamped
  `1..GROUPS_MAX`), `selected_weapon()` returns that id. On a fit of distinct families this is
  element-for-element today's `fitted()`, so every existing group, cadence and dry test holds.
- **`battery(base_id)` answers barrel positions in `fitted()`, not cell indices** (§16 rule 3);
  it normalises through `weapon_id` (`&"w_laser"` and `&"laser"` are the same list) and answers
  `[]` for a base with no firing family (`w_mining` — the strip still draws its row).
- **The volley** (§16 rule 4): on the pull's rising edge the selected battery arms; each barrel
  draws a release offset uniformly in `[0, BATTERY_STRUM_MS]` ms and releases when its offset
  has elapsed **and its own cadence timer is ready** (one timer per barrel replaces the single
  `_shot_timer`, so three cannons deliver three shots per burst window and a held trigger is a
  stream of salvos). A released travelling barrel spawns its own shot, charges one round from
  its family's pack, applies its own recoil and emits `shot_fired`; a released instant (beam)
  barrel opens its own beam. A barrel the family's own rules refuse is dry (`dry_fired`) and
  never holds the rest back.
- **The battery row** is STATION_HUB §5.1's law: `3× LASER MKII · W1·W2·W3 · OWNED ×<n>` (the
  bag count of that base, read through `instances_of`), one row per battery in first-cell order,
  plus one read-only `W<n> — EMPTY` line per empty W cell, its controls disabled by state; the
  `▸` expander reveals the P2-B1 single-cell lines and every single-cell action with L78's
  precedence unchanged. Focus order per row: `▸`, `FIT ALL`, `REMOVE ALL`, `SWAP ALL`.
- **The batch is atomic over the fit *and* the bag** (§16 rules 7–8): `fit_battery` takes the
  next unused instance of the base from `instances_of(base_id)` in creation order, ascending
  cells, snapshots `fit_for` + `modules()` first, and restores both through `set_fit` /
  `set_modules` on any refusal. `clear_battery` empties exactly the battery's cells and answers
  `false` (writing nothing) when the hull holds none.
- **The refusal copy**: OUTFITTING declares its own three constants with the exact literals from
  `fitting_panel.gd:147-149` (the L116 precedent, §16 rule 9) — `REFUSED · FIT ILLEGAL`, or
  `13 / 11 PWR — OVER BY 2` with `fit_legal`'s own numbers when the candidate is over budget.
  `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` is **unreachable for a W battery** (measured:
  `FitData.MANDATORY_SLOT_KEYS` = `[&"engines", &"power"]`, `game/ship_fit.gd:117`) — carry the
  constant for completeness, assert it nowhere.
- **The strip keeps its fixed node set** (§16 rule 10): rows are rewritten by
  text/visibility/`disabled`, never rebuilt, because the profile emits `profile_changed` from
  inside the handler that started the write.
- The FITTING pane, the fit shape, prices and stats do not move.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S4-H0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | **DONE** — `S4-H0_report.md`: 4 HIGH / 5 MED / 6 LOW, all with `file:line` |
| S4-H1 | battery strip + bulk transactions | `vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | §5.1's battery rows + `fit_battery`/`clear_battery` with the fit-and-bag rollback; `tests/test_s4_batteries.gd` (AC1/AC3) |
| S4-H2 | volley + strum | `vajb-orbit/game/weapons.gd,vajb-orbit/tests/` | per-barrel `fitted()`, `battery_ids()`, `battery()` + one-trigger discharge + `BATTERY_STRUM_MS` (AC2); extend `tests/test_engine2_weapons.gd` with volley coverage |
| S4-H3 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S4-H3_review.md` + LOW rows in `_state/LOW_BACKLOG.md` |
| S4-H4 | fixer | the union of H1+H2 sets + `docs/CONTRACTS.md` | only if H3 leaves HIGH/MED |

`game/projectile.gd` was dropped from H2's set (H0 F13: `configure` has no delay/strum key and
the strum is a weapon-side release offset, so nothing pinned lands there). **Reversal:** add it
back if H2 measures that a shot needs its own delay key — report, do not edit a set silently.

**Run order:** H0 → H1 → H2 → H3 → (H4 only on HIGH/MED). H1 and H2 are disjoint-safe but run
sequential anyway (H2's `battery()`/`battery_ids()` is what the strip's rows read).

## Tests that move, and why

- `test_p2b1_outfitting_panel.gd` — the strip's per-cell row tests rewrite to the battery rows;
  the empty-cell assertions (`:603-604`, `:606-607`, `:633-634`) stay, because the empty cells
  keep their own read-only lines, and the expander keeps the single-cell assertions alive.
- `test_engine2_wiring.gd:243-255` — **its `fitted()` assertion moves** (H0 F9): it de-duplicates
  `_state.weapons` itself and asserts `fitted() == launched`, which turns red the moment
  `fitted()` keeps duplicates (a Lancer's `[w_laser, w_laser]`). The fixture flies the default
  one-laser fit, so the assertion must be rewritten to the per-barrel reading before it can
  silently pass.
- `test_engine2_weapons.gd` (29) — additions only (volley, rounds per barrel, per-barrel damage,
  the strum bound, `battery()`/`battery_ids()`); the existing family, group, cadence and
  dry-state tests hold.
- New: `tests/test_s4_batteries.gd` (grouping, bulk round-trip, batch rollback of fit **and**
  bag, expander reachability, strum bound). Expected gate: **S3's figure + ~10**; the measured
  number at close-out goes into CONTRACTS §9.

## Hard rules

- Frozen: `project.godot`, `docs/gameplay/18_engine_spec.md`, `08_ship_slots_modules.md`,
  `assets/`, `addons/`, the theme.
- **No fit shape change** — one instance per W cell; N barrels keep N mounts (the owner's own
  ruling). No price, damage, cadence or ammo value moves; the one behavioural change is that a
  volley charges one round per barrel out of the family's single pack (§16 rule 5), which is
  the ruling.
- No shell-based file edits; workspace-relative `VAJB_WORKER_FILES` paths (L92a).
- **Every probe that boots `PlayerProfile` must run against a scratch store** —
  `XDG_DATA_HOME` scratch or repoint `save_path` before `_ready`. Twice now a probe has written
  the owner's live account (S2.6/L106 and the S3 incident,
  `slices/S3-module-affixes/_incident/README.md`, T-93); a third is a process failure. The
  runner sandbox protects the gate only — **probes are not covered**. A reviewer compares the
  live `profile.cfg` md5 before *and* after every pass.
- Bounded probes only (L82). Never leave a background job.
- A number not in the pinned docs: **report it, never invent it**.

## Staged / deferred

- Player-defined mixed groups (e.g. 2 lasers + 1 cannon on one trigger) — out; batteries group
  by identical `base_id` only. If wanted, it is its own later wave.
- L92's bare-hull mandatory-cell residual still rides its own fix.
- L107–L122 (the S3 review's rows) and L123+ (this wave's) are untouched by S4 except where the
  wave's own files appear in them.

## Owner ticks owed after this wave

- None new: the mount semantics are ruled (Q1, 2026-09-22). `BATTERY_STRUM_MS := 40`
  is proposed with reversal 0 — a tick only if the owner wants it different.
- One reading the owner may want to overrule: the strip keeps one read-only `W<n> — EMPTY` line
  per empty W cell (09 §10's 2026-09-23 amendment), so a hull with one laser in a three-cell W
  row shows one battery row and two empty lines. Reversal: drop the empty lines.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch profile; identical counts) + the live-profile untouched check.
2. `python3 staging/verify_wave.py verify --baseline s4_start --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests --expect-reports .agents/gen/slices/S4-weapon-batteries/S4-H0_report.md .agents/gen/slices/S4-weapon-batteries/S4-H3_review.md`
   *(Corrected 2026-09-22 in the S3 docs pass: the flags are `nargs="*"`, so comma-joined tokens became one path, the engine spec's snapshot key has no `vajb-orbit/` prefix, and `--expect-reports` resolves under the workspace root — the v1 line exited 1 with an inert frozen-file guard. Re-measured working form above.)*
3. CONTRACTS §9 figure + §10 measured note updated by H3; 09 §10 ticked.
4. `_state/WAVEBOARD.md` row closed; LOW findings appended at the next free row — L94–L106 and L107–L122 are taken (the S2.6 review's and the S3 review's), and **T-93 is the S3 incident's row**, so the next free LOW row is **L123** and the next free ticket detail file is **T-94**.
5. Wave-boundary commit.
