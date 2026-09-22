# S3_BRIEF — The item economy (module instances with affixes + the AUCTION)

**v2, 2026-09-22.** Amended by the developer session after **S3-K0** measured 7 HIGH,
7 MED, 13 LOW against v1 — the wave as first pinned could not be built without
inventing a number. Every change below is either a pin that now exists (CONTRACTS §15,
`15 §9`, STATION_HUB §5.1/§5.3/§5.10, 10 §2.2/§2.4, 17 §3), a file set that now covers
the file the work needs, or a figure that was stale. **v1's text is the fallback for
anything not restated here; the pins named below win over both.** Full findings:
`S3-K0_report.md`.

Wave `S3`, slice `S3-module-affixes`. Read in this order before working:
1. `AGENTS.md` (rules; the folder law; the worker-file enforcement; the escalation ladder)
2. `docs/gameplay/15_module_affixes.md` **end to end** — §1–§7 the design, §8 the
   2026-09-22 amendment, **§9 this pass's exclusive rows, the F-lot split and the
   "stored and displayed, not applied" rule**
3. `docs/gameplay/10_ship_acquisition.md` §2/§2.2/§2.4/§5/§6 and
   `docs/gameplay/09_ship_slots_modules.md` §3.1/§4/§10
4. `docs/design/STATION_HUB.md` §5.1/§5.3/§5.10
5. `docs/CONTRACTS.md` **§15 (v0.7.3 — the load-bearing pin)**, then §12/§13/§14
6. `S3-K0_report.md` (what was broken and what this version changed), then this brief

## Owner requests, verbatim

- (2026-09-22, deferring affixes out of P2-B proper) — affixes are the next wave:
  the instance shape `{base_id, rarity, prefixes[], suffixes[]}`, the roll sources
  and the 15 §7 naming/stat grammar.
- (2026-09-22) "We need AUCTION. without it we cannot test all items."

That second sentence is why the auction is **inside** this wave: only the auction
carries every module family and the three faction exclusives (15 §5), so the
instance system cannot be tested on all items without it. Instances roll at
creation and the auction sells the rolled shelf — one design, one wave.

## What is already measured (do not re-derive, do verify)

- 15 §1–§8 pins the economy: rarity contract (Common 0 / Magic 1+1 / Rare 2+2), value
  multipliers ×1.0/×1.6/×2.6, source roll tables (§2), the 12 prefix bands and 10
  suffix boons (§3/§4), the three exclusives' Magic+ floor (§5), the naming grammar
  (§7), instance identity, save v6, roll timing and the faction-lot interim (§8).
  **15 §9 (new)** adds the three exclusives' catalogue rows (tier III, draw 3/3/0,
  cost 5 200/5 200/4 500, icon fallbacks), the F lot's **85 % Magic / 15 % Rare** split,
  and the rule that affixes are stored/named/priced/displayed but **applied by no S3
  worker** — the launch path stays base-id.
- 10 §2 pins the auction's mechanics: 6 hulls + 10 modules, 20-minute station-clock
  restock, tier weights I 50 / II 35 / III 15, hull weights (§2.2, corrected to 08
  §2's asset ids), buyout at list, 60 % sell-back, rotation persists with the save.
- The inventory record today is `{base_id, count}` in `modules`
  (`autoload/player_profile.gd`, save v5, `SAVE_VERSION` at the top of the file).
  **The v6 record is `{instance_id, base_id, rarity, prefixes[], suffixes[], count}`**
  (CONTRACTS §15 / 17 §3): `count` is 1 in the bag, **0 while fitted**, and the record
  is never erased — that is how REMOVE/SWAP hand the same instance back (L80) without
  moving a §13 signature. The new top-level keys are `instance_counter` and `auction`.
- `fit_module_at` / `clear_fit_slot` (**CONTRACTS §13; measured `player_profile.gd:523`
  and `:566` — v1 cited 501/534, corrected**) and `set_fit_slot` (`:469`) already
  tolerate arbitrary cell values (15 §6's note). `base_module_id` (`:306`) is the one
  id→base bridge.
- OUTFITTING's seven weapon rows are the interim this wave retires
  (`ui/station/outfitting_panel.gd`, `ModuleCatalog`, `buy_module`; 10 §2.4/§6 close it).
  L80 documents the instance-vs-base-id seam this wave resolves.
- **The gate is hermetic and green: measured `passed=457 failed=0`, exit 0, twice**
  (2026-09-22, this pass, scratch store). v1's "run the gate with a scratch profile
  until S2.6's harness fix lands" and "expected 437 → ~455" are both stale — S2.6
  closed and CONTRACTS §14/§9 carry the cure and the current figure.
- `--suite=` takes the **full file basename** (`--suite=test_s3_instances`); a bare
  suite name selects nothing and prints `passed=0 failed=0` exit 0 (L95/L99).

## The pinned interface (CONTRACTS §15 v0.7.3 is the source of truth)

```gdscript
# PlayerProfile — additive. The §13 transactions keep their signatures and accept
# instance ids where they accepted module ids; only their bodies change.
const INSTANCE_ID_FORMAT := "mod_%04d"
add_instance(base_id: StringName, rarity: StringName, prefixes: Array, suffixes: Array) -> StringName
instance(id: StringName) -> Dictionary      # the record below; {} when absent
instances_of(base_id: StringName) -> Array  # ids held in the bag (count 1), creation order
roll_instance(base_id: StringName, source: StringName) -> StringName  # 15 §2/§9's tables, rolls + adds
buy_instance(id: StringName, cost: int) -> bool   # the shelf's listing, at the price it shows
sell_instance(id: StringName) -> bool             # base × rarity multiplier × 60 %
take_instance(id: StringName) -> bool             # 1 -> 0: fitting; the record survives
restore_instance(id: StringName) -> bool          # 0 -> 1: REMOVE/SWAP hands the same instance back
auction() -> Dictionary
set_auction(state: Dictionary) -> void
SAVE_VERSION := 6
```

Rules that fix every ambiguity (all from §15 v0.7.3; **do not re-litigate them**):

- **Roll at creation**, global RNG, outcomes persisted, never re-rolled; auction
  listings roll at **restock draw** (the rolled name and price are visible —
  "hunting the good roll"); drops roll at the drop. Tests seed the RNG first and
  assert the seeded outcomes.
- **`count` 1 = in the bag, 0 = fitted.** A `count`-0 record is invisible to
  `instances_of`, to every `OWNED ×<n>` aggregate and to `sell_instance`.
- **Migration v5→v6:** each `{base_id, count}` record → `count` **Common** instances,
  idempotent (the P2-B flag-day pattern; measured acceptance: a v5 file with a
  stacked record reads back as that many instances and a second migration call
  returns 0). Owner tick on retro-rolling is listed below — **build Common**.
- **A fit cell holds the `instance_id`.** `resolved_fit` / `fit_legal` read through
  `instance()[&"base_id"]`, so **the composed transactions and the three panels
  translate cells through `base_module_id` before judging a fit** — that is the
  required fix for `fit_legal` scoring an instance as draw 0 (K0 H6). REMOVE/SWAP
  return **the same instance** (never destroyed, never duplicated).
- **Prices:** 09 §3.1's frozen costs are the `base`; the rarity multipliers apply to
  the base; the hot slot's −20 % applies after (15 §1). Sell = `base × rarity × 60 %`,
  no suffix term.
- **Affixes are displayed, not applied** in S3: 15 §7's full rolled name plus the
  two-line stat block (base stats + one line per affix) on FITTING's and the
  shipyard's hover; no flight stat moves. The affix-application wave is staged (owner
  tick) and is why no S3 worker set contains `game.gd`, `weapons.gd` or `ship_stats.gd`.
- **The auction UI is `STATION_HUB.md` §5.10 verbatim** (rows, footer, sell sub-list,
  rarity tints, focus order), with this pass's three additions: the AUCTION owns its
  own footer strip (the shell's copy would print `0 NEEDED` for an instance), the
  `NEXT RESTOCK <m:ss>` line is computed **at pane entry** (no Timer — the clock
  forbids one), and the HULLS rows reuse each hull's `preview` (no class-icon asset).
- **`AUCTION_FACTION_LOTS_INTERIM := true`** (15 §8) with three exclusives' rows from
  15 §9.1 and the 85/15 split from §9.2.
- **OUTFITTING's module rows retire completely** (rows + their tests); the pane
  returns to ammunition + the FITTED WEAPONS strip. `buy_module`/`ModuleCatalog`
  stay as the price source with no new UI callers.
- **Refusals gain no new wordings:** §13's three + 09 §2's `<n> NEEDED`.

## Worker table

| ID | Role | VAJB_WORKER_FILES | Deliverable |
|---|---|---|---|
| S3-K0 | docs drift check | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | **DONE** — `S3-K0_report.md`, 7 HIGH / 7 MED / 13 LOW; this brief is its answer |
| S3-K1 | instance core + save v6 | `vajb-orbit/autoload/player_profile.gd,vajb-orbit/game/module_catalog.gd,vajb-orbit/game/ship_fit.gd,vajb-orbit/tests/` | the §15 API, the roll tables, **15 §9.1's three catalogue rows**, the migration, the base-id translation in the composed transactions; `tests/test_s3_instances.gd`, `tests/test_s3_migration.gd` |
| S3-K2 | the AUCTION + retirement | `vajb-orbit/game/auction.gd,**vajb-orbit/ui/station/auction_panel.gd**,vajb-orbit/ui/station/auction_panel.tscn,vajb-orbit/ui/station/outfitting_panel.gd,vajb-orbit/ui/station/outfitting_panel.tscn,vajb-orbit/ui/screens/station.gd,**vajb-orbit/ui/theme/vajb_theme.tres**,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | §5.10's screen (rotation, hot slot, F lots, sell sub-list, panel-owned footer), the rotation module, the three `rarity_*` tokens, OUTFITTING's rows retired; `tests/test_s3_auction.gd` |
| S3-K3 | naming + fitting integration | `vajb-orbit/ui/station/fitting_panel.gd,vajb-orbit/ui/station/shipyard_panel.gd,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | 15 §7 names + stat lines + the rarity tints + the OWNED MODULES expander, instance-true install/remove round-trips |
| S3-K4 | mandatory review | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `S3-K4_review.md` + LOW rows in `_state/LOW_BACKLOG.md` (next free **T-93**, per the file's own `T-###` law) |
| S3-K5 | fixer | the union of K1–K3 sets + `docs/CONTRACTS.md` | only if K4 leaves HIGH/MED |

**Run order:** K0 → K1 → K2 → K3 → K4 → (K5 only on HIGH/MED). K1 lands the
records before K2 sells them; K2's retirement lands before K3 shows names
everywhere. K2 and K3 both touch `player_profile.gd` — sequential, never parallel.
**Every builder runs its own suite by full basename** (`--suite=test_s3_instances`)
and leaves the full gate to the orchestrator.

## Tests that move, and why

- `test_p2b1_outfitting_panel.gd` (9) — the MODULES row tests rewrite to the
  ammunition-only pane (rows retired into the auction); its `:481` comment calling
  the AUCTION "future" goes with them.
- `test_p2b_fitting_panel.gd` (20) — hover/stat lines now carry rolled names; counts
  hold. **Its rail test hardcodes `module := 4`** (`:335-357`): inserting AUCTION at
  index 3 makes FITTING 5, and the five parallel arrays in `station.gd:54-86` each
  gain an entry.
- `test_p1_profile.gd` (11) — the save-version digit moves 5 → 6 at `:213`.
- **`test_p2a_profile_fits.gd`** — `SAVE_VERSION == 5` at `:264` and the on-disk digit
  at `:290`.
- **`test_p2b_retirement.gd`** (16) — the on-disk digit at `:110`.
- **`test_ship_grids.gd`** — `Catalog.MODULES.size() == MODULE_ROWS.size()` (`:785`)
  and its per-row loops assert the catalogue's **32** rows against a local table: the
  three 15 §9.1 rows make it 35, so the table grows with them.
- **`test_p2b_services.gd`** — reads the shipyard hover through `module_count`/`fit_for`
  and its pinned wording (`:318`, `:373`, `:430`, `:433`); moves when K3 shows rolled
  names.
- New: `test_s3_instances.gd` (rolls, seeded outcomes, never re-roll, the count
  0/1 round trip, L80's remove/swap identity, two same-base instances distinguishable),
  `test_s3_migration.gd` (v5→v6 idempotence), `test_s3_auction.gd` (rotation draw,
  weights over N seeded draws, hot slot, F lot at the Magic+ floor with the 85/15
  split, buy → instance in the bag, sell price).
- Expected gate: **457 → ≈475** (the three new suites); the measured number at
  close-out is the one that goes in CONTRACTS §9.

## Hard rules

- Frozen: `project.godot`, `docs/gameplay/18_engine_spec.md`,
  `docs/gameplay/09_ship_slots_modules.md`, `docs/gameplay/12_factions.md`,
  `docs/gameplay/14_station_services.md`, `vajb-orbit/assets/`, `vajb-orbit/addons/`,
  and the theme — **except the three `rarity_*` tokens** STATION_HUB §5.10 names,
  which are this wave's through `vajb_theme.tres` only. (v1's list named a
  non-existent `08_ship_slots_modules.md`; 09 was the file it meant.)
- No base price, roll weight, multiplier or 09 §3.1 stat moves — 09/10/12/14 are
  frozen arithmetic. 15 and 10 gained **documented, dated** blocks this pass (§9, the
  §2.2 correction, the §2.4 tick); a worker who thinks one of those numbers is wrong
  reports it and leaves it.
- No shell-based file edits; workspace-relative `VAJB_WORKER_FILES` paths (L92a). An
  absolute path inside the set is still denied by the hook.
- **Never boot the profile against the live `user://` (T-93, measured this wave).** A
  probe or script that instantiates the autoload writes the owner's real account and
  appends to their real `economy_log.txt`; S3-K1's first dispatch did exactly that
  (`_incident/README.md`). A probe must set `PlayerProfile.save_path` to a scratch
  path **and** run under its own `XDG_DATA_HOME`, and only `headless_runner.tscn`
  (whose sandbox is the sanctioned live-path reader) may touch the default path.
  Never leave a probe that does otherwise in the tree.
- Bounded probes only (hard iteration bounds — L82). Never leave a background job.
- A number not in the pinned docs: **report it, never invent it.**

## Staged / deferred

- **Affix application** (the prefixes' and suffixes' stat effects reaching flight):
  staged as its own wave — it owns `game.gd`'s fit→flight bridge and the weapon-stat
  families. 15 §9.3 states the rule and the reason.
- The five suffix perks with no system (`of Embers`, `of Leeches`, `of Silence`,
  `of the Cartograph`, `of the Vault`) roll, are named and display their line, and are
  applied by nothing yet — the same shape as the roll sources below.
- **The two exclusive weapons' firing behaviour** (`w_proton`, `w_flak` have no
  `weapons.gd` `FAMILIES` entry): a weapon-family pass, owner tick. Their rows exist so
  the F lot can list and sell them (15 §9.1).
- Crafting rolls (15 §2's 40/45/15), derelict and arena roll sources — those
  systems do not exist yet; the roll tables gain their rows but no callers.
- Faction stations (12 §5) — the F-lot interim stands until they ship (owner tick).
- Weapon batteries (09 §10) are wave S4, after this one.

## Owner ticks owed after this wave

1. **15 §9.1's three exclusive rows** (proposed: tier III, draw 3/3/0, cost
   5 200/5 200/4 500, the two icon fallbacks) — keep as built or move the numbers.
2. **The F lot's 85 %/15 % split** (15 §9.2) — keep or re-derive.
3. **v5 stock migration**: Common instances (as built) vs retro-rolled through
   their source tables (one call at migration). One constant.
4. **Faction lots**: the `AUCTION_FACTION_LOTS_INTERIM := true` shelf tag until
   faction stations exist — keep (as built) or false.
5. **Rail position**: AUCTION directly after EXCHANGE — keep or move (one enum value).
6. **Affix application**: schedule the follow-up wave, or park it.
7. **The rarity tints' one-accent exception** (STATION_HUB §5.10: Rare in Ember Glow)
   — bless it into STYLE_BIBLE or move Magic/Rare.

## Close-out (the orchestrator runs these, in order)

1. Gate twice (scratch store is automatic now; identical counts) + the live-profile
   untouched check.
2. The corrected verify command (v1's three defects — `nargs` commas, the engine spec's
   path, the bare report names — are fixed here):

   ```bash
   python3 staging/verify_wave.py verify --baseline s3_start \
     --forbidden vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests \
     --expect-reports .agents/gen/slices/S3-module-affixes/S3-K0_report.md \
       .agents/gen/slices/S3-module-affixes/S3-K4_review.md
   ```
3. CONTRACTS §9 figure + §10 measured note updated by K4; 15 §8/§9, 10 §2.4 and
   STATION_HUB §5.1/§5.3/§5.10 ticked by the developer session.
4. `_state/WAVEBOARD.md` row closed; LOW findings appended as **L107+** (L94–L106 are
   taken; the file's own counter law is one global `T-###`, next free **T-93**).
5. Wave-boundary commit, with the untracked root strays excluded (L10/L105).
