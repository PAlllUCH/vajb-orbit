# S15 — Battery hardcap 5x4, armory B1-B5 (wave brief)

**Wave:** S15 (code lane, item 22 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S15-battery-cap/`
**Baseline:** gate **834/0**; `python3 staging/verify_wave.py snapshot --name s15_start` before the first dispatch.
**Owner ask (2026-09-25, verbatim):** "i want a hardcap of 5 gun batteries with
4 guns each. we have to rework the armory to reflect that as the cockpit has B1
to B5 as selected slot".

## 1. The law to read, in order

1. `slices/S15-battery-cap/SLICE.md` — scope, ACs, your file-set row.
2. `docs/gameplay/09_ship_slots_modules.md` §12 (this wave's pin) + §10/§11
   (the battery model as built).
3. `docs/design/STATION_HUB.md` §5.11's 2026-09-25 amendment (the armory).
4. The code: `game/weapons.gd` (`GROUPS_MAX` :204, `battery_ids` :726,
   `set_battery_groups` in `autoload/player_profile.gd:1252`),
   `ui/station/armory_panel.gd` (`RACK_COUNT` :136), `ui/station/armory_style.gd`
   (bay grid :54-59, `slot_count` :60-65, drums :66-72),
   `game/game.gd:2027-2034` (`_select_weapon`).

## 2. Pinned numbers (verbatim; ambiguity fixed below)

- `weapons.gd`: `const GROUPS_MAX := 5` (was 7) and a new
  `const BATTERY_CELLS_MAX := 4` beside it.
- A **battery** stays what CONTRACTS §16 and 09 §10/§11 say: a player-composed
  group of W cells (mixed kinds allowed), each cell firing from exactly one
  rack. The hardcap binds **every** W cell (guns and mining lasers alike).
- Hull W cells are unchanged (Lancer 2, Vanguard 3, Delver 2, Courier 1,
  Spearhead 4, Mule 1, Bulwark 5, Warden 4, Obliterator 7).

Rules:

1. **Refusals write nothing.** Composing a 6th battery, or dropping a 5th cell
   into a battery, refuses through the same transaction shape the fitting panel
   already uses (a refusal leaves the profile byte-identical). The armory's
   drop zones and the fitting panel's rack drop zones both enforce it.
2. **Profile clamp on load:** `set_battery_groups`/the load path clamps to
   ≤ 5 groups × ≤ 4 cells, cell order preserved (09 §12's proposed rule); the
   gate must stay byte-identical on a store carrying an old 7-group save.
3. **The armory follows `RACK_COUNT := GROUPS_MAX`** — five bays flowing 4+1
   (`armory_style.gd`'s `bay_row_count`), labels `B1`..`B5` (the `RACK_LABEL`
   `"B%d"` loop already does this), aligned 1:1 with the cockpit's five lamps
   (`cockpit_style.gd` `lamp_count: 5`): rack i ↔ lamp i, and the (i) key
   selection (`_select_weapon`) lights lamp i. `weapon_6`/`weapon_7` become
   inert; do **not** edit `project.godot`.
4. **The plate-fit correction** (playthrough finding F1,
   `session_2026-09-25_findings.md` §2): `ui_armory_rack_plate` is 194x182 with
   ink only at rows 49..132 (180x84) and its drawn slot recesses at a ~34.5 px
   pitch (dark-run centres x≈45/79/114/148). Lay the bay's slots, ledge and
   SALVO drums against the **ink** (the slot block must sit inside rows 49..132
   at ≈34.5 px pitch ±2, drums bottom-aligned to the ink edge), or re-render
   the plate to fill its canvas — pick one route, measure it, and say which.
   The approved look is `staging/mockup/out/armory_mockup.png` bay 1.

## 3. Tests that move (pinned; a row not listed here may not change)

- `tests/test_engine2_weapons.gd:264-267` — `GROUPS_MAX == 7` → 5.
- `tests/test_s4_batteries.gd:615-616` — `RACK_COUNT == GROUPS_MAX == 7` → 5.
- `tests/test_s5_batteries_v2.gd:346-347, 371` — the 7-rack rows and
  `WEAPON_ACTIONS[6] == "weapon_7"` (that rack no longer exists).
- `tests/test_p2b1_outfitting_panel.gd:647-670` — `RACK_COUNT` and the B1..B7
  drop zones → B1..B5.
- `tests/test_d7_armory.gd:85, 392, 394-400` — rack count and the 4+3 bay grid
  → the 4+1 five-bay grid; `:427-452` (slot/chip geometry) and `:468-522`
  (drums) follow the plate-fit correction; `:771-797` style pins follow.
- `tests/test_s10_armory_input.gd:454-473` — the (1)..(7) key rows → (1)..(5).
- `tests/test_ui_slot_layout.gd:240, 251, 726-730, 767-807` — the
  `GROUPS_MAX`-bounded rows follow 5.
- `tests/test_p2a_launch_fit.gd:340-358` — the 7-cell battery composes 4+3.
- `tests/test_s8_launch_ammo.gd:424` — ordinal bound 1..5.
- `tests/probe_s12_field_budget.gd:110-112`, `tests/probe_s12_rock_rate.gd:120-122`
  — the `max w_cells == GROUPS_MAX` agreement rows restated for the new
  invariants (5 batteries × 4 cells vs the hull's 7 cells).
- New: `tests/test_s15_battery_cap.gd` (AC1-AC3 + the refusal-is-silent proof)
  and `tests/test_s15_armory_layout.gd` (AC4-AC5, measured ink rows).
- **Not moved:** `tests/test_d7_cockpit.gd`'s lamp rows (AC5 keeps them green),
  `test_p2a_ship_roster.gd`/`test_ship_grids.gd`'s W-cell rows (hulls
  unchanged), `test_s13_*`. Pre-grep and report every row you touch; an
  unlisted row changed is HIGH at review.

## 4. Hard rules

- No `project.godot`, no `docs/`, no `addons/`, no `ui/hud/`, no `ui/screens/`.
- Shell edits forbidden — edit tools only.
- Bounded Godot runs, scratch `XDG_DATA_HOME`, never write the profile except
  through the tested clamp path in a scratch store.
- A worker who believes a pinned number is wrong reports it and leaves it.

## 5. Output contract

Report `slices/S15-battery-cap/S15-B1_report.md` (REPORT template, ≤120
lines): the pre-grep table, per-AC measured values (refusal proof, the clamp
read-back, the ink-row measurements before/after), gate `[SUMMARY]`
before/after, every deviation.

## 6. Skills (read by path when you need Godot idiom)

The shared Godot skill library referenced by `crushrc` resolves on this host
under `~/.local/share/crush/additional-skills/godot/`. Useful here:
`godot-master/godot-gdscript-mastery/SKILL.md`,
`godot-ui-containers/SKILL.md` (bay grid layout) and
`godot-master/godot-testing-patterns/SKILL.md`. Project rules override anything
you read there: signals travel UP, calls travel DOWN; cross-file scripts are
reached by preload path, never the global class table.

## 7. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (W8 method),
diffs against 09 §12 + STATION_HUB §5.11 (not this brief), greps the moved rows
against §3's list, updates `CONTRACTS.md` §9/§10 with the next free rows read at
write time, appends LOW rows at the next free ids.

## 8. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s15_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
   docs/gameplay/15_module_affixes.md docs/gameplay/04_refinery.md docs/design/
   ui/hud/ ui/screens/ addons/ --tests
   --expect-reports .agents/gen/slices/S15-battery-cap/S15-B1_report.md
   .agents/gen/slices/S15-battery-cap/S15-R1_review.md`
   (`docs/gameplay/09_ship_slots_modules.md` is deliberately not forbidden —
   R1's §9/§10 writes CONTRACTS; 09 is the pin but only the developer session
   edited it. The parallel S14 lane's touched files are attributed.)
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit; hand the owner the plate-fit route choice (ink layout
   vs re-render) if B1 had to pick.
