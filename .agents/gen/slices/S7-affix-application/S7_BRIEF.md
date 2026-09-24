# S7_BRIEF — Affix application (15 §9.3's staged wave; engine slice 4's affix half)

Wave `S7`, slice `S7-affix-application`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder in the format rules; the folder law)
2. `docs/CONTRACTS.md` **§20** (this wave's pin), then §15/§16/§11 (the base pins
   §20 amends), §2/§3 (the signatures), §9 (the gate)
3. `docs/gameplay/15_module_affixes.md` **§1/§3/§4/§6/§9.3/§10**
4. `docs/gameplay/09_ship_slots_modules.md` **§5** (the resolution order §20 rides)
5. `docs/gameplay/17_coder_handoff.md` §2 (one owner per file) and
   `18_engine_spec.md` §14 slice 4 (read-only, owner-locked)
6. this brief end to end

## Owner request, verbatim

The queue row (dispatch_coder.md item 13): "**Affix-application wave** (15 §9.3 —
apply the stored affixes to stats; S3 stores/prices/names/displays but applies
none)". And the owner's dispatch instruction, 2026-09-24: "lets prepare for new
batch and wave of workers. Coder finished item 12, i work with designer on cockpit
implementation."

**Gate note (bucket 2, resolved):** S3's owner tick 6 read "Affix application:
schedule the follow-up wave, or park it." The 2026-09-24 instruction schedules it
(this wave); the reversal is recorded in CONTRACTS §10 v0.15 — park it, nothing has
to be undone. No other S3 tick gates this build.

**Docs-first is already landed:** CONTRACTS **§20** + changelog **v0.15**, 15 §10,
09 §5's dated note. A worker implements that text; who believes a number there is
wrong **reports it and leaves it** (escalation ladder bucket 2).

## What is already measured (file:line)

- The record carries `prefixes: [{id, value}]` / `suffixes: [id]` as **fractions**
  (`autoload/player_profile.gd:583,2163-2210`; tests pin `sturdy 0.15`, `keen 0.08`,
  `wideband 0.0`) — values are stored, never re-derived.
- `ModuleCatalog.PREFIXES` is the twelve-row table with `{name, slot, stat, unit,
  band}` (`game/module_catalog.gd:127-211`); `frugal`/`lightened`/`spry` store their
  band **negative** (`:161,168,203`); `prefix_value(prefix_id, tier)` (`:725`) and
  `roll_affixes(base_id, rarity)` (`:773`) are S3's own readers.
- `ModuleCatalog.SUFFIXES` is the ten-row flag table with faction bindings
  (`game/module_catalog.gd:219-250`).
- The bridge: `game.gd:_resolve_stats` (`:425-434`) builds `_launch_fit` and calls
  `ShipFit.resolve(hull_id, _launch_fit)` — one call site in production, 16 in tests
  (all two-argument today; §20's parameter is optional).
- The resolver chain: `ship_fit.gd:573-615` → `_apply_flat` (`:917`, hull/shield/cargo
  flats), `_apply_speed` (`:928`, armour penalty + mass, then the summed engine delta
  under `ENGINE_MULT_CEILING` 1.40), `_apply_computers` (`:967`, `damage_add` sums,
  `scanner_add` best, `damage_mult = 1 + Σ`), `_apply_shields` (`:982`, `regen_add`
  best + `BASE_SHIELD_REGEN` 2.0), `_apply_utility` (`:994`), `_apply_boosters`
  (`:1005`, ids only), then `_clamp` (`:1014`, speed floor 40 %, pool ceilings 3×)
  and `lock_range = scan_range` (`:614`).
- **`ShipStats.damage_mult` has no consumer** (measured project-wide: set at
  `ship_fit.gd:596,978`, declared `ship_stats.gd:32`, read nowhere) — the computers'
  pinned +damage (09 §3.4/§5) resolves and is inert. §20 wires the one delivery.
- The player's damage funnel is `weapons.gd:_deliver` (`:1774-1797`); `_sink_for`
  (`:1806`) resolves colliders to hulls. K0 must additionally measure whether beam
  frame damage (`_apply_beam` region `:1211-1336`) and the mining path reach
  `_deliver` or need the same one-line product — **report, do not guess.**
- Ammo: per-cell integer array, packs keyed per family
  (`game/player_state.gd:84-99`, `weapons.gd:_consume_ammo :1877-1883`,
  `ammo_slot :2201`). `_ammo_available` (`:1866`) gates on `ammo[slot] > 0`.
- The launch handshake: `game.gd:321-334` (`_resolve_stats`, `set_weapons`,
  `_seed_vitals`, `_seed_ammo`); `_launch_weapons` (`:502-510`) walks the fit's
  weapons cells **skipping empties** — `set_weapon_affixes` must walk the same list
  the same way.
- The kill seam is `game.gd:_on_npc_died` (`:2032-2049`, files heat/standing/loot).
  K0 measures whether non-player kills can reach it (killer identity) — Leeches
  gates on the handler's existing credit if identity is unknowable.
- Reveal: `sector.gd:335 reveal_pois()` (beacon's own call); POI fog read at
  `sector.gd:274-288` (`is_revealed`).
- Sell: `auction.gd:620 sell_price(base_id, rarity)` and `:725 sell_row(profile, id)`;
  `PlayerProfile.sell_instance` (§15's pin) is the second place the formula lives —
  K0 names every caller of `base × rarity × 60 %` before K3 runs; §20's term lands in
  each or one retires with a report line.
- Spry's consumer: `player_ship.gd:1124` reads the catalog row's `cooldown` straight
  (`_booster_effect :1148`) — the `× _stats.booster_cooldown_mult` lands there.
- Hunter detection is **distance** (`npc_brain.gd:421-427`, `aggro_radius()`), 13 §3
  pins no time component — Silence stages.
- No cargo-spill system exists anywhere (measured `spill` grep: the suffix's own
  flavor line only) — Vault stages.

## The pinned interface (CONTRACTS §20 is the source of truth; nothing here may drift)

```gdscript
# game/affixes.gd — NEW file, class_name Affixes extends RefCounted (statics only):
#   static func summary(profile, ship_id) -> Dictionary
#   static func has_suffix(summary: Dictionary, id: StringName) -> bool

# autoload/player_profile.gd — additive:
affix_summary(ship_id: StringName) -> Dictionary

# game/ship_fit.gd — ONE optional parameter; 16 test call sites and game.gd stay
# valid; byte-identical with {} or no third argument:
static func resolve(hull_id: StringName, fit: Dictionary, affixes: Dictionary = {}) -> ShipStats

# game/ship_stats.gd — §2's one additive field:
booster_cooldown_mult: float = 1.0

# game/player_state.gd — additive siblings of the set_weapons handshake:
weapon_affixes: Array[Dictionary]
set_weapon_affixes(per_cell: Array[Dictionary]) -> void   # sized with _resize_ammo
ammo_frac: Array[float]

# game/auction.gd — one optional parameter:
static func sell_price(base_id: StringName, rarity: StringName, suffixes: Array = []) -> int
```

Rules that fix every ambiguity (§20 repeats them; the brief restates the load-bearing
four):

- **Aggregation:** percent/points affix → its own instance's contribution; combine by
  09 §5's own rule; suffixes once-per-perk; **everything before `_clamp`**.
  Frugal/Lightened/Spry keep their stored negative signs; consumers read
  `(1 + Σ)` so negative means cheaper/shorter.
- **The three per-barrel prefixes ride `PlayerState.weapon_affixes[i]`** aligned
  with `weapons[i]` by the same walk as `_launch_weapons` — barrel index ↔ cell
  alignment is bucket 1: report mismatch, never guess.
- **`damage_mult` fires exactly once per delivered amount**, at `_deliver` and any
  parallel player path K0 names. Rocks included (owner-tick reading; reversal in
  §20). Mining TTK moving is expected under that reading and is not a defect.
- **Empty is identical:** `{}`/`[]`/no summary must reproduce today's numbers —
  K1's suite re-asserts a full pre-S7 stats fixture as proof.

## Worker table and run order

| ID | Role | Deliverable |
|---|---|---|
| S7-K0 | docs-drift check | report only: §20's every seam re-measured against the tree, the damage-metric flip-list, both sell-formula call sites, beam/mining delivery paths, `_on_npc_died` killer identity, barrel↔cell alignment — findings at file:line + bucket |
| S7-K1 | summary + resolve side | `affixes.gd`, `affix_summary`, `resolve`'s parameter, ship-stat prefixes + Whale + Spry's field, `tests/test_s7_affixes.gd` |
| S7-K2 | launch + barrel side | the `game.gd` bridge call, `set_weapon_affixes` + `set_affix_flags`, Keen/Rapid/Frugal + `ammo_frac`, the `damage_mult` delivery, **Embers** at `_deliver`, Spry's `player_ship` line, `tests/test_s7_weapon_affixes.gd` |
| S7-K3 | suffix side | Leeches (`_on_npc_died`), Cartograph (`Sector.reveal_pois` at entry), Ledger (`sell_price` ×1.25 through both call sites), the staged-marker assertions, `tests/test_s7_suffixes.gd` |
| S7-R1 | mandatory review | re-measure everything (W8 method), tier findings, LOW rows, §9/§10 notes sequenced after D7 |
| S7-F1 | fixer (HIGH/MED only) | named fixes + the gate |

**Run order: K0 → (orchestrator applies K0's dispositions to §20 + this brief, one
commit) → K1 → K2 → K3 → R1 → (F1 only if R1 leaves HIGH or MED).** K2 lands
`game.gd`'s launch handshake before K3 appends to the same file (shared files,
ordered — the S6 rule).

## Tests that move

**None expected.** The three suites are new prefixes (`test_s7_*`). The only hazard
is the `damage_mult` wiring flipping an existing assertion that pins exact delivered
damage with a computer fitted — **K0 names those rows before K1 runs**; any needed
existing-test edit is dispositioned in `S7-K0_report.md` and ratified by the
orchestrator in §20's disposition block (S6's `test_engine2_wiring` precedent). A
builder who believes an existing row must change reports it; it does not edit it.

## Hard rules

- Write sets exactly as `SLICE.md` §Worker file sets; `.agents/` reports are always
  allowed; **bash file edits are forbidden** (the hook does not see them).
- No `ui/**`, `assets/**`, `staging/**` — D7 is live in those directories
  (mid-C-wave as this wave preps: its `ui/hud/hud.gd` edit currently fails 6 gate
  rows in *its* files — attribute, never fix, never touch).
- No `project.godot`, no `docs/gameplay/18_engine_spec.md`, no `docs/` writes beyond
  K0's disposition pass (orchestrator-applied) and R1's §9/§10 measured notes.
- Every probe and gate runs on a **scratch store** (`XDG_DATA_HOME`; T-93 class) —
  the live account is never a target. Bounded probes only; no background processes.
- One prompt-line/one-owner: `game.gd` is K2's then K3's (ordered), never two holders.
- If a pinned number seems wrong: report it, leave it (bucket 2). Taste questions go
  on the owner tick list (bucket 3).

## Staged / deferred (each carries its reversal in §20)

Overflowing (budget frozen by §15 §6's "never the budget" + frozen `fit_legal`
signatures + the panels belong to D7), Silence (no detection-time mechanic exists),
Vault (no spill system), of the Choir/Concord/Ports (no faction station/arena can
roll them). Beyond the wave: quadrants (18 §4.5) and bosses/arena (14 §5) stay
slice 4's remaining queue items.

## Owner ticks owed after this wave

1. **S3 tick 6 answered** — scheduled by 2026-09-24's instruction (reversal: park).
2. **Overflowing** — staged vs re-emitted as `energy_max` (reversal in §20).
3. **Silence** — staged; does detection ever gain a time component? (13 §3 has none.)
4. **Vault** — staged until a cargo-spill system exists.
5. **Faction suffixes** — staged until 12 §5 / 14 §5 ship.
6. **`damage_mult` goes live** — computers' +15 % now really bites, rocks/mining
   included (reversal: ship sinks only).
7. **Keen per barrel** — the reading pinned; reversal: fold into `damage_mult`.
8. **Lightened's sign-flip** reading of "(multiplicative) −4/6/8 pp" (reversal:
   `penalty × (1 + Σ)`).
9. **Ledger ×1.25** supersedes §15's "no suffix term" (bucket-2, recorded; reversal:
   drop the term).

## Close-out (the orchestrator runs these, in order)

1. Gate **twice** on scratch stores: `source ~/.profile && XDG_DATA_HOME=$(mktemp -d)
   godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`
   → identical counts, expect `674 + the three suites`, 0 failed once D7's held
   files compile (if D7 is still mid-wave, attribute its rows and re-run the clean
   gate before declaring green). Live `profile.cfg`/`economy_log.txt` md5s unchanged.
2. Verify (the S4-corrected flag form):

   ```bash
   python3 staging/verify_wave.py verify --baseline s7_start \
     --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
       docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md \
     --tests \
     --expect-reports .agents/gen/slices/S7-affix-application/S7-K0_report.md \
       .agents/gen/slices/S7-affix-application/S7-R1_review.md
   ```

   A forbidden hit on `project.godot` from an attributed lane write (the L157 class)
   is accepted with attribution in the review, never silently.
3. R1 updates CONTRACTS §9 (measured figure) + §10 (v0.16 row), **sequenced after
   D7's own §9/§10 pass** — rebase on uncommitted lane edits, never revert them.
   LOW rows appended as **L158+** (next free ticket **T-94**).
4. WAVEBOARD: S7 row closed with the measured numbers, owner ticks recorded,
   in-flight D7 note refreshed.
5. Wave-boundary commit (untracked root strays excluded, L10/L105).
