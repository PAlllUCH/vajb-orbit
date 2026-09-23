---
slice: S3
reviewer: S3-K4
verdict: blocked            # HIGH-1 remains: the fixer pass (S3-K5) is owed
gate: "491/0 → 491/0 (exit 0 in four full runs; live profile.cfg md5 unchanged)"
---

# S3-K4 review — the item economy (module instances with affixes + the AUCTION)

Reviewed against the **pins**, not the brief: `docs/CONTRACTS.md` §15 (v0.7.3), §13, §12,
§11, §9 and §10, `docs/gameplay/15_module_affixes.md` (§1–§9, end to end),
`docs/gameplay/10_ship_acquisition.md` §2/§2.2/§2.3/§2.4, `docs/gameplay/09_ship_slots_modules.md`
§3.1/§4/§10 and `docs/design/STATION_HUB.md` §5.1/§5.3/§5.10. Every number below was
re-measured on this machine this pass; the probe sources and every log are in
`.agents/gen/slices/S3-module-affixes/_review_probes/` (archived as text on purpose: no
`res://` file, so nothing in the folder can boot the profile autoload — T-93).

**Verdict: blocked.** One HIGH, no MED. The HIGH is an item-integrity defect on a shipped
surface the wave itself touched, and its cure is inside the pin (bucket 1), so a fixer pass
(`S3-K5`) is owed. Everything else the wave pins holds: the six-key record, the roll
tables row by row, the migration, the count round trip, L80's identity through the composed
transactions, the AUCTION's weights and prices, and the "no affix moves a flight stat" rule.

## 1. Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| HIGH-1 | **HIGH** | `vajb-orbit/ui/station/outfitting_panel.gd:661-680` (`remove_module`) | The FITTED WEAPONS strip's REMOVE empties the cell with the **raw** `set_fit_slot` and banks a **base-keyed** `add_module(base_id, 1)`, so a cell holding an **instance id** (every rolled weapon fitted through FITTING) loses the instance (stranded at `count` 0, invisible to `instances_of`, to every `OWNED ×<n>` and to `sell_instance` for good) and gains a plain **Common** base-keyed unit instead; if a base-keyed unit of that base is already in the bag the count is **incremented**, i.e. one physical unit becomes two. This is CONTRACTS §15's "REMOVE/SWAP hand the same instance back … never destroyed, never duplicated" (the `restore_instance` clause) violated on a surface inside the wave's own file set. Cure: call the composed `PlayerProfile.clear_fit_slot(hull, WEAPON_SLOT, index)` (which banks through `_bank_entry` → `restore_instance`) and drop the two raw calls. | S3-K5 (bucket 1) |
| LOW-1 … LOW-16 | LOW | see §7 | 16 rows appended to `_state/LOW_BACKLOG.md` as **L107–L122** | rides with the next wave |

**No MED.** The F lot's slot accounting, the reconciliation's ordering law, the per-instance
sell rows and the `F LOT`-first row order were the obvious MED candidates and each is either
pinned by the amended docs (`10 §2.2`'s 2026-09-23 block, `STATION_HUB §5.10`'s 2026-09-23
amendment, `docs/gameplay/15 §9.2`) or measured sound below.

### HIGH-1, measured

Probe: `_review_probes/probe_s3_k4_outfitting.gd.txt` +
`_review_probes/k4_outfitting_probe.txt`; it mounts the shipped `outfitting_panel.tscn` on
the shipped autoload (borrowed `save_path` → scratch file, and the whole run under
`XDG_DATA_HOME=/tmp/vajb_k4_xdg`), fits a rolled instance through the composed
`fit_module_at`, and then emits the shipped strip button's own `pressed` signal.

```text
[k4out] instance=mod_0001 fit_module_at=true
[k4out] BEFORE cell=mod_0001 record={ instance_id: mod_0001, base_id: w_laser, rarity: magic,
        prefixes: [{id: keen, value: 0.16}], suffixes: [whale], count: 0 } instances_of=[] bag_count=0
[k4out] strip line 0 text=W1 LASER MKII remove-visible=true
[k4out] AFTER  cell= record={ … the same record … count: 0 } instances_of=[&"w_laser"]
[k4out] AFTER  bag counts: { mod_0001: {count 0, base w_laser, rarity magic},
                             w_laser: {count 1, base w_laser, rarity common} }
[k4out] after: module_count(mod_0001)=0 restore_instance=true
# scenario B — a plain base-keyed unit of the same base already in the bag:
[k4out] B BEFORE bag counts: { mod_0002: {count 0, base w_laser, rarity rare},
                               w_laser: {count 1, base w_laser, rarity common} }
[k4out] B AFTER  cell='' bag counts: { mod_0002: {count 0, … rarity rare},
                                       w_laser: {count 2, base w_laser, rarity common} }
[k4out] B AFTER  instances_of(w_laser)=[&"w_laser"] module_count(w_laser)=2
```

Reading it: the cell is emptied, the rolled **Rare/Magic** instance is left at `count` 0 (a
record nothing can reach — `instances_of` does not offer it, `sell_instance` refuses a
`count`-0 record, and the only route back, `restore_instance`, has no caller left once the
cell is empty), and the bag's `w_laser` — a **Common** unit with no affixes — is what every
panel now shows. Scenario B is the duplication half: `1 → 2` from one unit, which
`Auction.sell_rows` then prices as two sellable Commons.

Why the wave's own tests miss it: `test_p2b1_outfitting_panel.gd:617-651` measures the strip
with **base-id** cells only (the standard fit's lasers and its own `set_fit_slot(…, RAILGUN)`),
where `_base_id` is the identity and the three raw calls are correct. `test_s3_instances.gd`
and `test_p2b_fitting_panel.gd` measure REMOVE/SWAP identity through FITTING's pane and the
composed transactions, which do use `clear_fit_slot`. Nothing measures the OUTFITTING strip
against an instance-keyed cell, and the code path predates the wave byte-for-byte
(`git show ff2375c:vajb-orbit/ui/station/outfitting_panel.gd`, identical `remove_module`) —
the wave changed the cell's meaning under it without converting it.

## 2. Verdict per pinned acceptance

| Pin (CONTRACTS §15 / the brief's restatement) | Verdict | Evidence |
|---|---|---|
| The six-key record `{instance_id, base_id, rarity, prefixes[], suffixes[], count}` under `modules: instance_id -> record` | **holds** | `test_s3_instances.gd:93-132` green; re-measured: exactly six keys, ids `mod_%04d` from one counter, both refusals spend no number |
| `count` 1 = bag / 0 = fitted, never erased; invisible to `instances_of`, `OWNED ×<n>` and `sell_instance` | **holds** | re-measured: 1→0→1 keeps id, rarity and affix rows; `sell_instance` on a `count`-0 record refuses and pays nothing; `modules().size()` stays 1 |
| Roll at creation, global RNG, outcomes persisted, never re-rolled | **holds** | 15 §2/§9's tables measured row by row (§4); K1's five seeded outcomes reproduced exactly; same seed twice ⇒ same affixes, different ids; the file holds them |
| The 12 prefix bands + 10 suffix boons, family pools, the three exclusives' Magic+ floor | **holds** | every prefix row and band read off the shipped table and matched to 15 §3; pools per family matched; shipyard (100 % Common) leaves all three exclusives Magic, `common=0` |
| Save v6 migration: each `{base_id, count}` → that many Common instances, idempotent | **holds** | a v5 file with `w_laser ×3` + `u_refine ×2` (5 records, counter 5) → five Common instances, the old keys gone, on-disk `save_version=6`, second `migrate_module_instances()` → **0**, a second load does not double |
| Fits may hold the `instance_id`; `resolved_fit`/`fit_legal` read through `instance()[&"base_id"]`; the composed transactions and the three panels translate before judging | **holds in the profile and in FITTING/shipyard; violated by OUTFITTING's strip REMOVE** | `player_profile.gd:863,908` translate; FITTING `:402,1240` and the shipyard read through `base_fit`; the OUTFITTING strip writes raw — **HIGH-1** |
| REMOVE/SWAP hand back the same instance (L80) | **holds through the composed transactions and FITTING's pane; not through OUTFITTING's strip** | `test_s3_instances.gd:320-356` and `test_p2b_fitting_panel.gd` green; re-measured by hand: SWAP banks the displaced instance as itself (its own rarity, `keen 0.08`, `ledger`), REMOVE the same, two records throughout — **HIGH-1** is the one path that does not |
| Prices: list × 15 §1's multiplier, the hot slot's −20 % **after**, sell = `base × rarity × 60 %` | **holds** | 35 rows × 3 rarities, **0** mismatches against an independently computed `cost × permille / 1000`; `w_laser` 900/1 440/2 340, sell 540/864/1 404, hot 720/1 152/1 872; no suffix term |
| The AUCTION: 6 hulls + 10 rolled listings, 20-minute bands, one hot slot, `F LOT` first, 85/15 | **holds** | 2 000 seeded shelves: exactly 6 hulls and 10 listings every draw; hot slot 158 hulls / 242 listings over 400 shelves (16 candidates); F lot first on 400/400, never Common; 20 000 `faction_lot` rolls = **0.8476 / 0.1525** (the table is 85/15), `common=0` |
| Tier weights I 50 / II 35 / III 15, pools excluding the exclusives | **holds** | 20 000 `draw_tier` draws = **0.5072 / 0.3403 / 0.1525**; pools 12 / 11 / 9 rows (32 non-exclusive rows partitioned, no exclusive in any pool) |
| `NEXT RESTOCK <m:ss>` computed at pane entry, no Timer | **holds** | `BAND_SECONDS=1200`, `restock_text(1200)="NEXT RESTOCK 20:00"`, `(65)="NEXT RESTOCK 1:05"`; `enter_pane` reads it, nothing ticks it (`Timer` appears in comments only, in both files) |
| The AUCTION owns its own footer strip; refusals gain no new wording | **holds** | pane's own `%RestockLabel`/`%StatusLabel`; wordings are §13's three + 09 §2's `<n> NEEDED` (`STATUS_REFUSED_CREDITS = "REFUSED · NOT ENOUGH CREDITS · %s NEEDED"`); the shell's strip is still written through `status_requested`, exactly as FITTING does |
| The three `rarity_*` tokens, `rare` = Ember Glow, only the theme touched | **holds** | `vajb_theme.tres:544-546` is the theme's whole diff (three lines); `rarity_magic` `#565C63`, `rarity_rare` `#E8703A`, `rarity_common` == `text_primary`; `STATION_HUB.md` §8 already lists them |
| OUTFITTING's seven module rows retire; `buy_module`/`ModuleCatalog` stay as the price source | **holds** | the rows, their constants and their helpers are gone from the pane; `outfitting_panel.tscn` lost the four module nodes; `PlayerProfile.buy_module` has no UI caller left; the pane keeps the strip + ammunition |
| No affix is applied to a flight stat (15 §9.3) | **holds** | see §6 |
| Frozen files and arithmetic untouched | **holds** | see §5 |

## 3. The pins, diffed against the shipped surface

Every member of §15's block exists with the pinned signature and semantics:
`INSTANCE_ID_FORMAT` (`player_profile.gd:99`), `add_instance` (`:462`), `instance` (`:477`),
`instances_of` (`:487`), `roll_instance` (`:510`), `buy_instance` (`:549`),
`sell_instance` (`:574`), `take_instance` (`:600`), `restore_instance` (`:615`),
`auction` (`:656`), `set_auction` (`:664`), `SAVE_VERSION := 6` (`:54`). The two top-level
keys are written in `_write_profile`'s fixed list (`:1781-1782`) and read in `_read_values`
(`:1220-1221`); `auction` is **not** a `market` sub-key and survives a reload (re-measured).

Two additions beyond the block, both reported not fixed:

- **`roll_listing(base_id, source) -> Dictionary`** (`:528`) — the shelf's mint: it rolls the
  listing, takes the next `mod_%04d` and **does not** enter the bag. §15 requires the shelf
  to hold "ordinary instance records keyed by their minted id" and the counter to move for
  every roll, so the member is necessary; §15's block just does not list it. Bucket 2 →
  developer session (LOW-14, `L120`), recorded in §10's v0.7.4 entry instead of edited into §15.
- **`game/auction.gd` as a whole** — `class_name Auction`, `evaluate_shelf`, `draw_shelf`,
  `draw_tier`, `tier_pool`, `exclusive_ids`, `hull_rows`/`listing_rows`/`sell_rows`,
  `buy_hull`/`buy_listing`/`sell_row`, `hot_price`/`sell_price`/`meta_of`/`rolled_name`/
  `rarity_token`/`rarity_fallback`, `next_restock_seconds`/`restock_text`. §15 pins the
  profile side and the shelf's shape but no `Auction` surface; the module is clean, split
  reads/writes the way `game/exchange.gd` is, and every price goes through `ModuleCatalog`.
  Same bucket, same row.

The §13 transactions kept their signatures and only their bodies changed, as pinned:
`fit_module_at` (`:850`) and `clear_fit_slot` (`:898`) now judge through `base_fit` (`:634`)
and bank through `_bank_entry` (`:1583`), which restores the *same* instance for a `count`-0
record and falls back to `add_module` for anything else. `set_fit_slot` (`:787`) still
accepts an arbitrary id (15 §6's note). The brief's `:523`/`:566`/`:469` line refs are
pre-wave numbers; the current file reads 787/850/898 and `base_module_id` at 354.

## 4. The roll tables, row by row (re-derived, not read from the brief)

Shipped `ModuleCatalog.SOURCE_ROLLS` against 15 §2, all seven rows exact:

| Source | §2 row | shipped | measured share (20 000 draws, seed 20260922) |
|---|---|---|---|
| auction | 65/30/5 | 65/30/5 | 0.6506 / 0.2984 / 0.0510 |
| shipyard | 100/—/— | 100/0/0 | 1.0000 / 0 / 0 |
| drop | 70/25/5 | 70/25/5 | 0.6992 / 0.2498 / 0.0510 |
| arena | 20/40/40 | 20/40/40 | 0.2074 / 0.3952 / 0.3974 |
| derelict | —/75/25 | 0/75/25 | 0 / 0.7468 / 0.2532 |
| crafting | 40/45/15 | 40/45/15 | 0.4051 / 0.4425 / 0.1525 |
| faction_lot (15 §9.2) | —/85/15 | 0/85/15 | 0 / 0.8476 / 0.1525 |

- **The twelve prefixes match 15 §3 verbatim**, name, slot, stat, unit and all three band
  columns (`sturdy` +10/15/20 shields … `deep_hold` 5/8/12 utility). The family pools read
  correctly per slot: weapons 3 (`keen`/`rapid`/`frugal`), shields 2, computers 2,
  armour/engines/power/boosters/utility 1 each — 12 rows, no row unreachable.
- **The ten suffixes match 15 §4 verbatim** (perk prose included), the three faction-bound
  ones only in their own pool: `w_proton` (choir) → +`choir`, `w_flak` (concord) →
  +`concord`, `u_vault` (meridian) → +`ports`.
- **The three exclusives' rows match 15 §9.1 exactly**: `w_proton`/`w_flak` weapons, tier III,
  draw 3, cost 5 200, `effects {}`, both on `icon_module_w_railgun.svg`; `u_vault` utility,
  tier III, draw 0, cost 4 500, `{vault_add: 20}`, `icon_service_vault.svg`. The two icon
  files exist and `vajb-orbit/assets/` is byte-identical to the pre-wave commit.
- **The floor holds for every exclusive × every source**: through the 100 %-Common shipyard
  row all three read `common=0`, magic 1.0000 (re-measured, 20 000 draws each).
- **The seeded outcomes K1 pinned reproduce exactly** (fresh seed 20260922, independent
  probe): `w_laser`/auction → Common, no affixes; `c_target`/derelict → magic,
  `surefire 0.05` + `leeches`; `u_vault`/faction_lot → magic, `deep_hold 12.0` + `leeches`;
  `w_proton`/shipyard → magic, `rapid 0.16` + `choir`; `b_fold`/arena → magic,
  `spry −0.25` + `silence`.

## 5. Frozen set, prices and weights

`python3 staging/verify_wave.py verify --baseline s3_start --forbidden
vajb-orbit/project.godot docs/gameplay/18_engine_spec.md --tests` → `"problems": []`, and
the run's own gate leg printed a green summary (exit 1 would mean any problem; exit 0
observed). The modified list carries no frozen path: `18_engine_spec.md`, `project.godot`,
`09_ship_slots_modules.md`, `12_factions.md`, `14_station_services.md`, `assets/`, `addons/`
are absent, and the theme is present only for the three `rarity_*` lines.

Independently: `git diff ff2375c..HEAD` over that whole set shows **only**
`module_catalog.gd` — 444 insertions and **three comment lines removed**, no `cost`, `draw`,
`tier`, `effects` or roll-weight line modified. `game/ship_fit.gd` (the frozen stat/fit
table, 09 §3.1's consumer) is byte-identical, and `station_catalog.gd` (08 §2's ship prices)
is not in the wave's diff at all.

The one arithmetic caveat, reported not resolved (already an owner tick in
`10 §2.2`'s 2026-09-23 block): 10 §2.1's "exactly 6 hulls" and 10 §2.2's nine independent
chances (which average 5.2) cannot both hold. The shipped reconciliation rolls every hull
against its own chance and then fills or trims to six **in chance order**. Re-measured over
2 000 shelves through `Auction.draw_shelf` (stream seed 20260922, global seed re-set per
shelf — the builder's own sequence) the rates are **byte-identical to K2's table and to the
doc's**: fighter/vanguard 1.0000, miner 0.9165, trader 0.8755, corvette 0.6105, freighter
0.8220, gunship 0.4175, patrol 0.2240, destroyer 0.1340 — strictly ordered by the pin's own
chance column, never fewer or more than six (size-bad = 0). The 45 % Corvette is measurably
*below* the 60 % Hauler, which was the defect K2 found in the first draft and cured. The
rates are a sample (LOW-3/L109: `_draw_hulls` alone with the same seed reads miner 0.9100 /
corvette 0.6265), which is why the doc should name the sequence.

## 6. No affix reaches a flight stat (15 §9.3)

- No flight file is in the wave's diff: `game.gd`, `weapons.gd`, `ship_stats.gd`,
  `ship_fit.gd` are untouched (`verify_wave`'s modified list), and no S3 worker set contains
  them.
- The one flight bridge, `game.gd:_profile_fit` (`:355-375`), resolves **every** cell through
  `PlayerProfile.base_module_id` (its own `_base_module_id` at `:382-385`), and
  `_hull_slot_cells` (`:1390-1409`) reads that translated fit, so the HUD's module ids and
  icons are base ids.
- Re-measured: a fit holding a Rare `w_plasma` instance (two prefixes, two suffixes) and the
  same fit written with `w_plasma` produce the **same** `ShipFit.power_budget` —
  `{out: 6, draw: 3, spare: 3, legal: true}` both ways — and `base_module_id` maps each
  instance id and the plain base id to `w_plasma`.
- The only readers of `rarity`/`prefixes`/`suffixes` outside the catalogue and the profile
  are the display surfaces (the three panes' tints and stat block); `weapons.gd` and
  `ship_stats.gd` contain no affix reference at all.

## 7. LOW rows appended (`L107`–`L122`)

`_state/LOW_BACKLOG.md` gained 16 rows under the file's own `L#` law (and its ticket counter
now reads **T-94**, T-93 being the incident row). In one line each: **L107** the stale
32-row assertion in `probe_r1_frames.gd`; **L108** `instances_of`'s "creation order" is key
order after a load (ConfigFile sorts a nested Dictionary — measured with the autoload absent
via `--script`); **L109** 10 §2.2's measured rates are sequence-dependent; **L110**
`module_count(base_id)` cannot aggregate an instance-keyed bag and under-reads a stack;
**L111** `base_fit`'s plain-vs-typed arrays; **L112** the retired-constant greps in
`tools/r1_p2b1_format_law.py`; **L113** `probe_r1_fit_panes.gd`'s stale rail index;
**L114** the AUCTION's owned-hull row stays enabled; **L115** `probe_w3_services.gd`'s stale
labels; **L116** three copies of the section machinery and two of the stat formatter;
**L117** the nested `▸` expander; **L118** the nondeterministic exit-time leak ledger;
**L119** `buy_listing`'s flat refusal reason; **L120** §15's block omits `roll_listing` and
the `Auction` surface (bucket 2); **L121** the wave's probes are not reproducible from the
tree; **L122** the station's boot draws and stamps the shelf.

## 8. My docs pass (CONTRACTS §9 / §10)

- **§9**: expected figure `passed=457 failed=0` → **`passed=491 failed=0`, exit 0, 43
  suites**, with the wave's growth recorded (`457 → 471 → 482 → 491`) and the history line
  extended (`→ 491 with S3, measured 2026-09-23`). The old readings stay as written.
- **§10**: a new **v0.7.4** entry (this wave's only CONTRACTS writer) recording the gate
  figure, the five measured notes (the additive `roll_listing`; the `instances_of` order
  caveat; the three theme tokens; the unchanged price/weight ledger with the
  `ff2375c`-to-HEAD evidence; the HIGH's location) and pointers to this review and the new
  LOW rows. §15 itself was **not** edited: its text is bucket 2.

## 9. Gate, live store, and what I did not verify

```text
# the gate, twice, full output captured (this pass)
... headless_runner.tscn -> [SUMMARY] passed=491 failed=0   (exit 0)
... headless_runner.tscn -> [SUMMARY] passed=491 failed=0   (exit 0)   # identical
# plus the verify_wave run above (exit 0, and its own leg checks "[SUMMARY]" + "failed=0":
# that run's tail kept the last 15 lines, so its count is unrecorded, not its exit)
# -- three green full runs; each captured log carries the one pre-existing SCRIPT ERROR,
# L61's line at tests/test_weapon_fx_f4.gd:178

# and a fourth on the tree as this report leaves it (both review probes removed):
... headless_runner.tscn -> [SUMMARY] passed=491 failed=0   (exit 0)   # identical again

# the live account (T-93), before and after everything this pass
md5(user://profile.cfg)     9182b34ffe0e51dc2ea8fa3051de4ae2  →  9182b34ffe0e51dc2ea8fa3051de4ae2
md5(user://economy_log.txt) 38b05767f005bafab286e4bbe8ed1764  →  38b05767f005bafab286e4bbe8ed1764
```

The `profile.cfg` reading is identical to the value `T-93` records as the restored state, its
mtime stays at 2026-09-23 01:22 and `economy_log.txt`'s at 00:28 — neither file moved. Every
probe this pass ran under its **own**
`XDG_DATA_HOME=/tmp/vajb_k4_xdg` with `PlayerProfile.save_path` repointed at a scratch file
(the two scene probes borrow the shipped autoload and hand every field back; the ConfigFile
probe runs `--script`, so no autoload is instantiated at all). All three probe files were
removed from the project before this report and archived as text under `_review_probes/`.

**Not verified, and why:**

- **K1's seven pre-fix dispositions** — reproducing `passed=450 failed=7` needs the pre-fix
  tree; the *closure* arithmetic is verified instead (per-suite method counts re-counted:
  instances 9, migration 5, auction 11; FITTING 27, services 14, ship_grids 27, p1 11,
  p2a 11, retirement 16, p2b1 9 — all as the builders report).
- **The pane's rendered pixels** — no GPU pass this review; the pane measurements come from
  the suites' own node reads (which the gate re-ran) plus the shipped scene's structure.
- **`Auction`'s shelf against a live clock crossing a band** — the suite measures bands
  (`test_s3_auction.gd:509-585`, green); I did not drive `WorldClock` over real time.
- **A base id the catalogue no longer ships** sitting in a bag (invisible to `sell_rows`
  because `_slot_order` walks `ModuleData.MODULES`, and unsellable) — read, not measured;
  not ticketed rather than asserted.
- **The five suffix perks with no system** and the two exclusive weapons' firing — 15 §9.3
  and §9.1 declare them staged; nothing in S3 can exercise them.

## 10. Owner ticks owed after this wave (unchanged from the brief, plus one)

The brief's seven stand (the §9.1 rows, the 85/15 split, the v5 stock migration's Common
default, the faction-lot interim flag, the rail position, affix application, the one-accent
rarity exception). Add: the reconciliation's owner word on `10 §2.2`'s "exactly six vs the
chance column" (already written as a tick in the doc), and **the fixer pass for HIGH-1**
before the wave's close-out commit.
