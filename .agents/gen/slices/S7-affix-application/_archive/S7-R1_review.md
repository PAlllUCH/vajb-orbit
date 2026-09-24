---
slice: S7
reviewer: S7-R1
verdict: clean
gate: "753/0 → 753/0 (twice on fresh scratch stores, plus 753/0 inside the verifier; the wave's pre-K1 baseline was 711)"
---

# S7-R1 review — affix application

## Verdict

**No HIGH, no MED.** The wave is clean: every pin CONTRACTS §20 states was
re-measured against the tree with the reviewer's own probes and every figure holds;
the five LOW rows below are hygiene/copy/harness notes that move to
`.agents/gen/_state/LOW_BACKLOG.md` as **L163–L167**. Nothing is fixed here.

Attribution of the gate's growth, measured rather than carried forward:

| stage | rows | source |
|---|---|---|
| `s7_start` (`faa24ad`) | **711** | S6's 674 + D7's in-flight 37 (measured: `grep -h "^func test_" vajb-orbit/tests/test_*.gd \| wc -l` in a worktree at `faa24ad`) |
| D7's wave-boundary commit (`12278d2`, mid-wave) | +1 → 712 | `test_d6_status.gd` 16 → 17 (D7's §3.1b bars row); measured by per-suite count diff |
| S7-K1 | +15 → 727 | `tests/test_s7_affixes.gd` |
| S7-K2 | +19 → 746 | `tests/test_s7_weapon_affixes.gd` |
| S7-K3 | +7 → **753** | `tests/test_s7_suffixes.gd` |

The only pre-existing suite whose row count moved is `test_d6_status.gd` (16 → 17),
and it is **D7's**, not this wave's. Every other suite's count is byte-identical to
the pre-wave tree. The brief's "711 + the three suites" arithmetic is therefore
**753**, and 753 is what both runs and the verifier's own gate print.

## Method

1. **Four reviewer probes** written for this pass (`vajb-orbit/tests/probe_s7r1_*.gd`,
   scene probes, run on fresh `XDG_DATA_HOME` stores): `_prestats` (the pre-S7
   resolution A/B), `_affixes` (the summary, every §20 prefix row, the clamps, the
   empty-argument proof, the staged no-op), `_delivery` (the per-barrel prefixes,
   `damage_mult` at all five sites, Embers, Spry) and `_suffixes` (the three suffix
   seams, the Ledger arithmetic, the launch→barrel alignment). **46 + 47 + 37 = 130
   checks, 0 failures** (each probe prints `done failures=0`).
2. **A pre-wave worktree at `faa24ad`** (`git worktree add /tmp/s7pre faa24ad`, then
   one headless import so the `class_name` table exists) running the *identical*
   `probe_s7r1_prestats.gd` file; the two outputs diffed line for line.
3. The builders' suites re-run byte-identically, scoped: 15 / 19 / 7.
4. The gate twice on fresh scratch stores, plus the verifier's own gate.
5. A per-file warning ledger, pre vs post, by attributed `GDScript::reload` rows.
6. `git diff` of the pinned doc blocks (§11/§15/§16) and a per-suite row-count diff.

## What I re-measured, with the numbers

### 1. The summary off stored records (§20's aggregation law)

A mixed Vanguard-class fit (one instance per slot, stored values only) answers
`Affixes.summary`:

```text
tempered=0.12 | keen=0.08 | sturdy=0.15 | lightened=-0.06 | overflowing=2.0
suffixes=[leeches, whale]           # one entry per perk, a repeat is one flag
instances=[engines/0/e_ion, weapons/0/w_laser, shields/0/s_light,
           armour/0/h_plate_light, power/0/p_mk2]   # 5 rows, FIT_SLOT_KEYS then cell order
```

Signs are the stored ones (`lightened` stays **−0.06**), a bare-id prefix stores
**0.0** and is never re-read from the band (`c_scanner` + bare `wideband` → scan
1125.0, not the band's 1158.75), `{}` for a null profile and for an unknown hull, and
a hull with no stored fit answers a real (empty) summary with 0 rows. `has_suffix`
reads the flag list and answers false for a flag the summary does not carry.

### 2. Every §20 prefix row, worked, and 09 §5's three clamps

| prefix | measurement | expected |
|---|---|---|
| Sturdy | corvette 700 + `s_light` 200 Sturdy 0.15 + `s_heavy` 400 Sturdy 0.10 → **1370.0** | per-instance sum; the summed-magnitude reading would be 1450.0 |
| Sturdy (K0 F1 counter-example) | 200 @ 0.10 + 400 @ 0.15 → **+80** (1380.0) | not 0.25 × 600 = +150 |
| Sturdy, same base twice | `s_ion`/`s_ion`, only cell 1 carrying 0.20 → 700 + 700 + 350 × 0.20 = **1470.0** | the row alignment holds for a duplicate base |
| Vigilant | best instance wins (2 + 9 = **11.0**); two carriers at Σ 0.40 → 2 + 9 × 1.40 = **14.6** | `own × (1 + Σown)`, best kept |
| Wideband | `c_nexus` plain beside `c_scanner` Wideband 0.25 → 900 × 1.3125 = **1181.25**, `lock_range` follows | best × (1 + Σ), lock follows scan |
| Surefire | `c_target` 0.10 + `c_twin` 0.05 → 1 + 0.15 × 1.15 × 2 = **1.345**; no suffix → **1.15** | per-instance × (1 + Σ), computers still sum |
| Tempered | freighter `e_std` + `e_ion` 0.12 + `e_vector` → Σ 1.418 → unclamped 415.474, **got 410.2 = 293 × 1.40** | inside `ENGINE_MULT_CEILING` as part of the sum |
| Tempered, solo | fighter `e_ion` 0.12 → 450 × 1.168 = **525.6** | no clamp below the ceiling |
| Lightened | `h_plate_light` −0.05 + abs(−0.08) → clamped to **0** → speed 450.0 (plain 427.5); the accel/coast mass terms follow (4.0/1.6 vs 4.2/1.68) | never crosses 0 into a bonus, speed **and** mass |
| Lightened, partial | `h_plate_heavy` −0.12 + 0.04 → **414.0 = 450 × 0.92** | a real lift, still a penalty |
| Deep-hold | vanguard 40 + `u_cargo` 15 + 12 units = **67** | units added |
| Spry | booster + spry −0.15 → `booster_cooldown_mult` **0.85**, plain **1.0** | `1 + Σ` over fitted boosters |
| Whale | +50 flat (`s_light` fit 950 → **1000**); a second carrier is still **+50** (1850 → 1900) | once per perk |
| Overflowing | aggregated (2.0) but **resolve unchanged** | staged |

Clamps, all with the affix in place:

- **speed floor 40 %**: 10 × `h_composite` on the fighter → raw 156.905, floor 180.0,
  **got 180.0**.
- **pool ceiling 3×**: destroyer 900 + 5 × `s_ion` at Sturdy 0.20 → raw 3000, plain
  2650, **capped 2700** (the affix lands **before** the clamp, and the plain fixture
  is under the ceiling so the row discriminates).
- **hull ceiling 3× with Whale**: 2200 + 5000 + 50 → raw 7250, **got 6600**.

### 3. `{}` / `[]` / no-third-argument is byte-identical — A/B against the pre-wave tree

The identical probe file run in the `faa24ad` worktree and in the wave's tree prints
every `ShipStats` field for the nine standard fits plus five hand-built fits (the
speed floor, the three-engine ceiling, the legacy singular `engine` key, two shields,
two computers): **the two outputs are identical** once the field that does not exist
pre-S7 (`booster_cooldown_mult`, `<null>` there) is excluded.

In-tree: `resolve(hull, fit)`, `resolve(hull, fit, {})` and
`resolve(hull, fit, empty_profile.affix_summary(hull))` agree field-for-field on
**all nine hulls, 0 mismatches**; the pre-S7 Vanguard fixture holds exactly
(hull 1250 / shield 800 / regen 6 / speed 406.6 / accel 5.04 / coast 2.1 / turn 1.5 /
mult 1.0 / cargo 40).

### 4. Per-barrel isolation, and Frugal's bank

- **Keen**: a two-cannon battery with Keen 0.15 in cell 2 → barrel 1's shot
  **27.0** (byte-identical), barrel 2's **31.05** = 27 × 1.15; the mirror (Keen in
  cell 1) is 31.05 / 27.0. Through the beam, the paid weight is `Σ(1 + keen)`:
  affix-free **6.0** = 2 × dps × delta, Keen in cell 2 **6.45** = base × 2.15.
- **Keen + `damage_mult` together**: with a `c_target` (0.15) fitted and Keen 0.15 in
  the cell, the sink receives **35.7075 = 27 × 1.15 × 1.15**, one delivery — not the
  cube (41.063625). Each product lands exactly once.
- **Rapid**: cell 2 only → interval **0.521739** = 0.6 / 1.15, cell 1 **0.6**; the
  armed timers follow the same read (0.6 / 0.5217).
- **Frugal**: 20 shots at −0.15 spend **exactly 17** rounds (bank lands on 0.000000),
  through both `_consume_ammo_at` and the real `_fire_projectile` release path; a
  non-Frugal barrel spends 20 from the shipped family slot; the bank is per slot.
- **Alignment through the real launch**: a fighter fit of `[w_mining, w_laser]` with
  Keen on the laser launches `weapons=[&"", &"laser"]`,
  `weapon_affixes=[{}, {keen: 0.15}]`, and the component's only barrel resolves
  **slot 1**; the mirror fit resolves **slots [0, 1]**. The family-less cell does not
  shift the map.

### 5. `damage_mult` at all five sites, exactly once, null-tolerant

Resolved from a `c_target` launch: **1.15**. Per site, with a value that would be
wrong if the product landed twice:

| site | measured | twice would be |
|---|---|---|
| `weapons.gd:_deliver` (beam frame) | **3.45** = 3.0 × 1.15, 1 delivery | 3.9675 |
| `weapons.gd:1268` (beam rock chip) | **0.345** = 3.0 × 0.10 × 1.15, 1 call | 0.39675 |
| `projectile.gd:_deliver` | **115.0** = 100 × 1.15, 1 delivery | 132.25 |
| `projectile.gd:773` (projectile chip) | **11.5** = 100 × 0.10 × 1.15, 1 call | 13.225 |
| `player_ship.gd:940` (the ram's peer half) | **0.55** = 0.478261 × 1.15, 1 call | 0.6325 |

No computer: the beam delivers **3.0** (today's figure) and `damage_mult` is **1.0**;
a shot with no `damage_mult` key delivers **100.0**. A **null** stats argument
delivers the un-multiplied 3.0 (no crash), and `PlayerShip._damage_scale` /
`_booster_cooldown_scale` answer 1.0 with no snapshot. The launch→delivery loop
closes: a launched `c_target` fit resolves `_stats.damage_mult == 1.15` **and** the
mounted component's `_damage_scale()` reads 1.15.

### 6. Spry

`booster_cooldown_mult` 0.85 with spry −0.15, 1.0 without; driven through the hull's
own line (`Input.action_press(BOOST_ACTION)` → `_update_boosters`), the afterburner's
cooldown is written **6.8 s** (row 8.0 × 0.85).

### 7. The applied suffixes, each at its own seam

- **Embers** — NPC hull only: the beam heals 100 → **120.0** for a 200 dealt amount,
  a rock and the player's own hull heal nothing, and the heal clamps at `shield_max`
  (600.0). With a computer fitted it heals the **delivered** amount (200 × 1.15 × 0.10
  = **23.0**). The projectile path heals through `_source.heal_from_damage` (120.0)
  and skips a rock. No flag → no heal. The launch's flag reaches the shot:
  `affix_flags=[&"embers"]`, `shot.embers == true`, `shot.damage_mult == 1.0`.
- **Leeches** — the credited path: no Leeches, a kill leaves the hull at 1050.0; with
  a Leeches instance fitted the same call credits the kill (KILL lines 1 → 2) and
  heals to **1112.5** = 1050 + 0.05 × hull_max.
- **Cartograph** — entry lifts the fog (0 fogged, the derelict and anomaly revealed);
  the control sector enters fogged (3–5 POIs) and one manual `reveal_pois()` leaves
  the identical fog state, so the entry reads like exactly one call.
- **Ledger** — the worked row: 900-cost Common, plain **540**, Ledger **675**
  (= 540 × 125 / 100, an exact integer). All three production sites carry it: the
  pane's displayed row (`sell_rows` → 675), the transaction quote (`sell_row` →
  cost 675, price 675, credits +675) and the payout (`PlayerProfile.sell_instance` →
  +675). Two `ledger` rows are still one term (675, not 843). The Rare row scales too
  (1404 → 1755). The term is integral over **every** catalogue module × all three
  rarities. Only `ledger` carries it (whale/embers/leeches/cartograph/staged ignored);
  no argument and `[]` are the pre-S7 call.

### 8. The staged five

`silence`, `vault`, `choir`, `concord`, `ports`: fitted and flagged, `resolve` is
byte-identical to the same fit with `{}`, and `sell_price` adds no term (1404 = 1404).
No consumer reads their ids anywhere in the tree.

### 9. No pin drift

- `docs/CONTRACTS.md` §15 + §16 (the S3/S4 pins): **byte-identical** to `faa24ad`.
- §11: the only change is §20's additive cross-reference sentence in rule 2 (the
  two-argument `resolve` stays valid); the `player_state.gd` pin block is untouched.
- §2/§3: the two additive lines (`booster_cooldown_mult`, the optional third
  parameter) — both landed in the docs-first pass, before any builder.
- `docs/gameplay/09_ship_slots_modules.md` and `15_module_affixes.md` are **unchanged
  since `s7_start`** — their S7 text was already in the baseline commit (`faa24ad`
  swept in the uncommitted docs-first pass; measured: §10 and §5's note are present
  in `git show faa24ad:…`). So the forbidden-file check on them is meaningful.

### 10. Write set

`python3 staging/verify_wave.py verify --baseline s7_start --forbidden
vajb-orbit/project.godot docs/gameplay/18_engine_spec.md
docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md --tests
--expect-reports …S7-K0_report.md …S7-R1_review.md` → **`problems: []`**, exit 0.
No forbidden hit at all (not even the L157-class `project.godot` one). The modified
list carries D7's lane files (`staging/phase_g/*`, `ui/**`, `tests/test_d7_*.gd`,
`test_engine2_hud.gd`, `docs/design/UI_SPEC.md`) — all attributed to D7's close-out
(`12278d2`) landing after the baseline, none of them S7's. S7's own writes are
`game/affixes.gd` (new) plus nine `game/`/`autoload/` files, the three suites and the
one ratified `test_s3_instances.gd` fixture edit — nothing in `ui/`, `assets/`,
`staging/`, `project.godot` or the engine spec. `game/sector.gd` was in K3's set and
correctly needed no write (Cartograph goes through the shipped `reveal_pois`).

### 11. Gate and the live store

`godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200`
on two fresh `XDG_DATA_HOME` stores: **`[SUMMARY] passed=753 failed=0` twice**, exit 0.
The single `SCRIPT ERROR` is L61's pre-existing
`test_weapon_fx_f4.gd:178` (`Cannot call method 'call' on a previously freed
instance.`). The verifier's own gate also printed 753/0.

The live store was measured before and after a full scratch-store gate run:
`profile.cfg` md5 `b10c3f568b4e9767394291e97c154e36` and `economy_log.txt` md5
`13a2517626897c7e7babafcc7e39a923` — **unmoved**. Its 13:37 rewrite predates this
review's runs and is **not** this wave's (no S7 run touches the live path; every
probe and gate used a scratch `XDG_DATA_HOME`, and the two suites that borrow the
autoload repoint `save_path`/`EconomyLog.log_path` first). Note the figure is not
D7's recorded `b32fdb7b…`: that one moved at 13:37, outside this wave's write set.

### 12. Warning ledger (attributed `GDScript::reload` rows, pre → post)

| file | pre | post |
|---|---|---|
| `game/affixes.gd` (new) | — | **0** (K1's D5 `SHADOWED_VARIABLE` is gone) |
| `game/ship_fit.gd` | 0 | 0 |
| `game/ship_stats.gd` | 0 | 0 |
| `game/player_state.gd` | 0 | 0 |
| `game/projectile.gd` | 3 | 3 |
| `game/player_ship.gd` | 2 | 2 |
| `game/game.gd` | 1 | 1 (the pre-existing `Router` autoload trap) |
| `game/weapons.gd` | 29 | **34** → LOW L163 |
| `game/auction.gd` | 1 | **2** → LOW L166 |
| the three new suites | — | 0 each |

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `game/weapons.gd` (`_barrel_affixes:1885`, `_slot_of_barrel:1901`, `_ammo_available_at:2014`, `_consume_ammo_at:2043`, `_barrel_interval:2066`) | Five new `The local function parameter "position" is shadowing an already-declared property in the base class "Node2D"` rows — the file's ledger went **29 → 34**, the only new warning class this wave added. Exactly the class K1's D5 fixed for `has_suffix`. Nothing functional. | → `L163` |
| F2 | LOW | `game/weapons.gd:363` and `game/player_ship.gd:72` | One spec number (`Embers` 10 %) is spelled as two constants (`EMBERS_FRACTION` in both files). The pin routes the two deliveries differently, but does not require two literals; a future retune of one silently diverges from the other. | → `L164` |
| F3 | LOW | `ui/station/auction_panel.gd:443` (`status_idle`) | The pane's idle line still states the catalogue's **60 %** sell share (`ModuleData.SELL_PERCENT`) while a Ledger instance's row displays and pays **75 %** of the plain share. §20 names only the three price sites, so this is copy, not arithmetic. | → `L165` |
| F4 | LOW | `game/auction.gd:638` | The Ledger line adds one `Integer division. Decimal part will be discarded.` row — the same idiom as the shipped `hot_price` (auction.gd:622) and integer-exact by the pin's own requirement. Recorded so the ledger is not misread as a regression. | → `L166` |
| F5 | LOW | `.agents/gen/slices/S7-affix-application/S7_BRIEF.md` §Close-out; `S7_prompts.md` | The brief's close-out and the reviewer prompt both planned the next LOW ids at **L158+** and the changelog at **v0.16**; D7's close-out (`12278d2`, mid-wave) had already consumed **L158–L162** and **v0.16**. R1 rebased to **L163+** and **v0.17** (never reverting D7's rows) — recorded so the next planner does not hand out a used id. | → `L167` |

Nothing else was found. In particular, two candidate findings were **eliminated by
measurement**: `set_fitted` and `_slot_of_barrel` drop a cell by the *same* test
(`weapon_id(value) == &""`), so the barrel→slot map is aligned by construction (K2's
D8 confirmed, not just claimed); and `PlayerState.set_ammo` clamps to
`[0, ammo_max]`, so Frugal's `floor(bank)` spend cannot write a negative pack.

## Builder claims re-run byte-identically

- `tests/test_s7_affixes.gd` **15/0**, `tests/test_s7_weapon_affixes.gd` **19/0**,
  `tests/test_s7_suffixes.gd` **7/0** (scoped runs, scratch stores).
- The full gate twice, 753/0, and once inside the verifier.
- The builders' reported numbers I could not reproduce independently are none: each
  one is either re-derived in the reviewer's probes (the summary shape, every prefix
  row, the five sites, Frugal's 17, Spry's 6.8, the Ledger 540 → 675, the staged
  no-op) or re-run as a suite.

## Dispositions I accept (orchestrator's K0/K1/K2/K3 blocks)

- **K1's D1** (Sturdy reads `instances`, not the aggregate): the corrected §20 text is
  what the code does; the reviewer's own counter-example measures 1370 / +80, never
  1450 / +150.
- **K1's D7** (the pool-clamp rows ride a hand-built over-capacity summary): justified
  by measurement — the best legal shield fit is the destroyer's 3 cells at
  900 + 3 × 350 × 1.20 = 2160 against a 2700 ceiling, so no legal fit reaches 3×.
- **K2's D1** (L90 routed around, not fixed): confirmed — a one-slot cannon state
  cannot address `ammo_slot`'s const index at all (the reviewer's first probe attempt
  hit exactly that), so scoping the live-slot map to Frugal-carrying barrels is the
  only reading that leaves every un-affixed number byte-identical.
- **K3's D3** (§20's "`Auction.sell_price` has no production caller" is stale): the
  shipped callers are `_sell_row`, `sell_row` and `PlayerProfile.sell_instance`
  (grep-verified); the corrected §20 text is accurate.
- **K0's F12b** (the ram takes the multiplier): measured at site 5; it stays an owner
  tick with its reversal named.

## Owner ticks owed (unchanged by this review; the ones my measurements touch)

1. S3 tick 6 — answered (scheduled by the 2026-09-24 instruction; reversal: park).
2. Overflowing — staged; measured: aggregated in the summary, absent from `resolve`
   and from `power_budget` (the reactor's own `power_add` still reads 10).
3. Silence — staged; no detection-time mechanic exists.
4. Vault — staged; no spill system exists.
5. Faction suffixes — staged; no faction station/arena can roll them.
6. **`damage_mult` goes live** — measured live at all five sites, rocks and the ram
   included (reversal: ship sinks only, or drop site 5).
7. Keen per barrel — measured per barrel (reversal: fold into `damage_mult`).
8. Lightened's sign-flip reading — measured (reversal: `penalty × (1 + Σ)`).
9. Ledger ×1.25 — measured 540 → 675 at all three sites (reversal: drop the term).

## Gate / evidence

```text
# gate, twice, fresh scratch stores
source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=753 failed=0     (both runs, exit 0; the one SCRIPT ERROR is
                                   L61's test_weapon_fx_f4.gd:178)

# the reviewer's probes
godot --headless --path vajb-orbit res://tests/probe_s7r1_prestats.tscn --quit-after 600
godot --headless --path vajb-orbit res://tests/probe_s7r1_affixes.tscn  --quit-after 600  # 46 OK / 0 BAD
godot --headless --path vajb-orbit res://tests/probe_s7r1_delivery.tscn --quit-after 600  # 47 OK / 0 BAD
godot --headless --path vajb-orbit res://tests/probe_s7r1_suffixes.tscn --quit-after 600  # 37 OK / 0 BAD

# the pre-wave A/B
git worktree add /tmp/s7pre faa24ad && cp tests/probe_s7r1_prestats.* /tmp/s7pre/vajb-orbit/tests/
godot --headless --editor --path /tmp/s7pre/vajb-orbit --quit     # the class_name table
# identical probe in both trees, outputs diffed (booster_cooldown_mult excluded)
→ PRE/POST IDENTICAL

# wave verification
python3 staging/verify_wave.py verify --baseline s7_start \
  --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md \
    docs/gameplay/09_ship_slots_modules.md docs/gameplay/15_module_affixes.md \
  --tests --expect-reports …/S7-K0_report.md …/S7-R1_review.md
→ problems: [] (exit 0)

# live store, before and after a full gate run (unmoved)
b10c3f568b4e9767394291e97c154e36  profile.cfg
13a2517626897c7e7babafcc7e39a923  economy_log.txt

# row counts
grep -h "^func test_" vajb-orbit/tests/test_*.gd | wc -l      # 753
# per-suite diff vs faa24ad: only test_d6_status.gd 16 -> 17 (D7) + the three S7 suites

# warning ledger, attributed rows
godot --headless --debug --path vajb-orbit --check-only --script res://game/weapons.gd
# 29 -> 34 (five "position" shadowing rows) ; auction.gd 1 -> 2 (integer division)
```

## Files touched

- `.agents/gen/slices/S7-affix-application/S7-R1_review.md` — this review.
- `vajb-orbit/tests/probe_s7r1_prestats.gd/.tscn`, `probe_s7r1_affixes.gd/.tscn`,
  `probe_s7r1_delivery.gd/.tscn`, `probe_s7r1_suffixes.gd/.tscn` — the four probes
  (scene probes, never discovered by the gate).
- `docs/CONTRACTS.md` — §9's measured figure and §10's v0.17 row (sequenced after
  D7's v0.16; D7's rows are untouched).
- `.agents/gen/_state/LOW_BACKLOG.md` — L163–L167.

No `game/`, `autoload/`, `ui/`, `assets/`, `staging/` or `project.godot` write. Nothing
was fixed.
