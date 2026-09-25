# S13 — Ore caps, mining batteries, dev tuning (wave brief)

**Wave:** S13 (code lane, item 20 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S13-ore-caps-devmenu/`
**Baseline:** gate **812/0**; `python3 staging/verify_wave.py snapshot --name s13_start` before the first dispatch.
**Owner ticks this wave implements (2026-09-25):** `GUN_BURST_SHARE` = 0.10;
`FRAGMENT_CORE_SHARE` = 0.25 (the reserve variant); multiple `w_mining` must
work; a dev overlay with sliders over these values; `DOCK_RING_RADIUS` = 175.
Rule B (bigger/clustered rocks, ⅓-of-hold, T4 curve) is **DEFERRED — do not
implement any of it.**

## 1. The law to read, in order

1. `slices/S13-ore-caps-devmenu/SLICE.md` — scope, AC1–AC7, your file-set row.
2. `docs/gameplay/01_economy_core.md` §5.6 and `docs/gameplay/02_minerals.md`
   §5.1 Rule A (by range) — the ticked rules and their reversals.
3. `slices/S12-ore-budget/S12-K0_report.md` + `S12-K1_report.md` §tables — the
   measured numbers your change moves.
4. `docs/CONTRACTS.md` §5 lines 345–375 (R1 only) — the two sentences that change.

## 2. Pinned interface (verbatim; ambiguity is fixed below)

```gdscript
# vajb-orbit/game/ore_tuning.gd — the one live balance surface.
# Defaults = the docs' owner-ticked numbers. Reached by preload path only
# (project convention: never the global class table — D11-C1's lesson).
extends RefCounted

static var gun_burst_share: float = 0.10        # 01 §5.6, owner-ticked
static var fragment_core_share: float = 0.25    # 02 §5.1 Rule A, owner-ticked
static var gun_chip_rate: float = 0.10          # weapons.gd:216's declared default
static var mine_cycle: float = 1.2              # mining_laser.gd:34's
static var work_per_unit: float = 1.0           # asteroid.gd:56's
static var tier_base_yield: Dictionary = {1: 6, 2: 5, 3: 4, 4: 3}
static var yield_variance_min: float = 0.5
static var yield_variance_max: float = 1.5
static var pickup_burst: Vector2i = Vector2i(1, 2)

static func reset_to_defaults() -> void
static func to_dict() -> Dictionary
static func from_dict(d: Dictionary) -> void
```

Rules that fix every ambiguity:

1. **Owner files keep their `const` declarations** — they are the declared
   defaults and committed probes/tests read them. Live arithmetic reads
   `OreTuning.<field>`; `test_s13_caps.gd` asserts every default == its const
   (AC6). No circular preload: `ore_tuning.gd` preloads nothing in `game/`.
2. **Setup split** (B1): at roll, `_bore_ore` splits into
   `extractable = _bore_ore × (1 − OreTuning.fragment_core_share)` and
   `reserve = _bore_ore × OreTuning.fragment_core_share`. Extraction (mining
   work) realises only `extractable`. The reserve pays at the shatter.
3. **Shatter attribution** (B1): the route delivering the final work unit
   attributes the shatter — mining work (`mining_laser.gd`'s apply path) vs gun
   chip work (the projectile path). A **mining-attributed** shatter pays the
   full reserve: a Small as pickups, an M/L by handing its children Σ yield ==
   reserve (split across `FRAGMENT_SPLIT` counts; **no fresh roll**; each child's
   own `_bore_ore` = its share, and the split compounds down the cascade). A
   **gun-attributed** shatter pays pickups worth at most
   `OreTuning.gun_burst_share × _bore_ore`; the excess reserve burns. Payouts
   accumulate float credit per field and pay whole pickup units when credit
   crosses 1.0 — never a fractional pickup.
4. **`OreTuning.gun_chip_rate` changes the chip rate live but its default stays
   0.10** — `test_engine2_cleaving.gd:302`'s chip arithmetic and
   `test_combat_repair_c5.gd`'s ram payout must keep passing unchanged.
5. **Multi-mining** (B1): N fitted `w_mining` modules deliver
   N × `OreTuning.work_per_unit` of extraction work per `OreTuning.mine_cycle`
   (N beam nodes or N work channels on one node — B1's route; document it).
   The named single-instance suspects are `player_ship.gd:208` (one `_laser`),
   `player_ship.gd:1289-1291` (`_mount_mining_laser` early-return) and
   `mining_laser.gd`'s single `_cycle`. One unit of work never realises twice.
6. **Dev overlay** (B2): `ui/dev/dev_tuning_menu.gd`, toggled by raw `KEY_F1`
   (`_unhandled_key_input`; **no `project.godot` edit**, no InputMap action).
   On open it loads and applies `user://dev_tuning.cfg` if present; Save writes
   it; Reset calls `OreTuning.reset_to_defaults()` and deletes it. The file is
   **never read at boot** (the gate must stay byte-identical on any `user://`).
   A TUNED badge shows while any field ≠ default. Sliders cover every field
   above (tier_base_yield gets four int sliders, pickup_burst two). The overlay
   is a `CanvasLayer` opened/closed by the player in-game; it does not pause
   the game and touches no shipped UI file.
7. **Ring** (B1): `game/sector.gd:73`'s `const DOCK_RING_RADIUS := 175.0`; the
   dock trigger (`:234`), spawn placement (`:188`) and ring draw (`:554`) keep
   reading the one constant.

## 3. Tests that move (pinned; a row not on this list may not change)

- `tests/test_engine2_cleaving.gd:365-367` — fragment yield "re-rolled (02 §5)"
  → children's Σ == parent reserve, no roll.
- `tests/test_engine2_cleaving.gd:620-621` — "a Small bursts 1-2 pickups" → the
  reserve/cap-derived payout.
- `tests/probe_rock_cleave_a2.gd:244-249, 670-671, 696-699` — re-roll band
  expectations → reserve-split expectations.
- `tests/probe_s12_field_budget.gd:176-199` and `tests/probe_s12_rock_rate.gd`
  cascade rows — the measured rows follow the new rules (keep the probes'
  `failures=0` contract; never weaken an assertion to hide a change).
- `tests/test_d11_station.gd` — the DockZone radius row 120 → 175.
- **New:** `tests/test_s13_caps.gd` (rules 2-4 + AC1/AC2/AC6), the renamed/updated
  `tests/test_s13_mining_batteries.gd` (AC3), `tests/test_s13_devmenu.gd` (AC4,
  including the gate-hermeticity guard: an applied save file does not leak into
  default-path behaviour).
- **Not moved:** `test_engine2_cleaving.gd:302,332-338`, `test_combat_repair_c5.gd`,
  `test_s2_6_burst.gd`, `test_p1_catalogues.gd`, `test_s6_poi_loot.gd`.

## 4. Hard rules

- No `project.godot`, no `docs/` write (reports excepted), no `ui/station/**`,
  `ui/screens/**`, `ui/hud/**`, no `addons/`, no `18_engine_spec.md`.
- Shell edits are forbidden (the hook's known gap) — use edit tools only.
- Every Godot run bounded (`--quit-after`), probes self-quitting, scratch
  `XDG_DATA_HOME` per run; never write the profile or a live `user://`.
- No re-declared numbers: the values live in `OreTuning` and nowhere else in
  new code. A worker who believes a pinned number is wrong reports it and
  leaves it (escalation ladder, bucket 2).

## 5. Output contract

Report `slices/S13-ore-caps-devmenu/S13-B1_report.md` / `S13-B2_report.md` (from
`_templates/REPORT.md`, ≤120 lines): the pre-grep of §3's rows, per-AC measured
values, the gate `[SUMMARY]` before/after, every deviation with its route.

## 6. Run order

**B1 → B2 → R1 → F1 only on HIGH/MED.** B2 depends on B1's `ore_tuning.gd`.
R1 re-measures every AC itself (W8's byte-identical replay for probes), diffs
against the docs (not this brief), updates `CONTRACTS.md` §5's two sentences
(lines 350, 374) + §9/§10 with the next free rows read at write time, appends
LOW rows at the next free ids, and puts the **proposed `18_engine_spec.md`
§6/§13/§17 wording** in its review (it may not edit that file). F1 fixes only
HIGH/MED at their named file:line.

## 7. Close-out (the orchestrator runs these)

1. Gate twice on fresh scratch stores (identical counts, live md5s unchanged).
2. `python3 staging/verify_wave.py verify --baseline s13_start --forbidden
   vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
   docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md
   docs/gameplay/04_refinery.md docs/design/ ui/station/ ui/screens/ ui/hud/
   --tests --expect-reports .agents/gen/slices/S13-ore-caps-devmenu/S13-B1_report.md
   .agents/gen/slices/S13-ore-caps-devmenu/S13-B2_report.md
   .agents/gen/slices/S13-ore-caps-devmenu/S13-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit; hand the owner the moved-row summary and R1's proposed
   `18_engine_spec` wording for the owner-locked edit.
