---
slice: S3
worker: S3-K0
model: ""             # the orchestrator fills what actually ran
status: actionable    # every row below is a follow-up for K1-K4 or the owner
gate: "457/0 → 457/0 (unchanged; no code touched)"
---

# S3-K0 report — docs drift check

## Result

The pinned set (brief, 15, 10 §2/§2.4/§5/§6, 09 §3.1/§4/§10, STATION_HUB
§5.1/§5.3/§5.10, CONTRACTS §15/§12/§13) was read against the tree, file by file:
`player_profile.gd`, `module_catalog.gd`, `ship_fit.gd`, `outfitting_panel.gd`,
`fitting_panel.gd`, `shipyard_panel.gd`, `station.gd`, the theme, the named
suites, the seeders, the templates and the state files. **Nothing was fixed and
no number was invented** — every value below is a read of a document or a line of
code, or one command whose output is quoted.

Result: **7 HIGH, 7 MED, 13 LOW** findings. The HIGHs are not worker discretion —
they are places where the wave as pinned cannot be built without inventing a
number or a shape, so they escalate (bucket 2 = would change a pin, bucket 3 =
taste/owner ruling, per `AGENTS.md` §"Designer lane"). The gate is green and
unchanged: measured `passed=457 failed=0`, exit 0, on a scratch store (EXHIBIT 1).

Bucket key: **(1)** inside a pinned acceptance → worker decides; **(2)** would
change a pin → developer/designer session; **(3)** taste or supersedes an owner
ruling → owner, through the designer.

## Findings index

| # | Tier | Bucket | One line | Anchor |
|---|---|---|---|---|
| H1 | HIGH | 2+3 | The three faction exclusives have no catalogue row, price, tier, draw, slot, effect or icon | `module_catalog.gd:41-330`, `15:87-97`, `16_art_design_brief.md:99` |
| H2 | HIGH | 2 | §15 has no store for a *shelf listing*: every instance lands in the player's inventory | `player_profile.gd:334-344`, `CONTRACTS.md:1384-1393` |
| H3 | HIGH | 2 | `buy_instance(id)` takes no price, so the shelf's hot slot −20 % cannot reach the profile | `CONTRACTS.md:1378`, `STATION_HUB.md:735-739` |
| H4 | HIGH | 2 | The pinned instance record has no `count`, but every count consumer needs it | `CONTRACTS.md:1384`, `17_coder_handoff.md:109`, `player_profile.gd:528` |
| H5 | HIGH | 2 | "REMOVE/SWAP return the same instance" is unreachable through the pinned §13 signatures | `player_profile.gd:334-344`, `LOW_BACKLOG.md:200` (L80) |
| H6 | HIGH | 2 | Affix stat effects have no owner file: `ShipFit`/`game.gd` are in no S3 worker set | `game.gd:351-385`, `ship_fit.gd:504-517`, brief `S3_BRIEF.md:84-91` |
| H7 | HIGH | 2+3 | 15 §4's "of the Ledger" (+25 % sell) contradicts the pinned sell formula; six perks have no system | `15:74-82`, `CONTRACTS.md:1379` |
| M1 | MED | 2 | The close-out verify command cannot pass; its frozen-file guard is inert | `S3_BRIEF.md:140`, `verify_wave.py:139-153` |
| M2 | MED | 2 | The `rarity_*` tokens are this wave's by rule, but no worker owns the theme file | `S3_BRIEF.md:114-115`, `vajb_theme.tres:541-552` |
| M3 | MED | 2 | The AUCTION shelf's home key is unnamed, and `market` would silently drop it | `player_profile.gd:1196-1217`, `CONTRACTS.md:1390-1393` |
| M4 | MED | 2 | Three documents still carry the pre-S2.6 gate figures; measured today 457/0 | `CONTRACTS.md:802`, `S3_BRIEF.md:42-43`, `SLICE.md:5` |
| M5 | MED | 2 | The shell's refusal copy cannot price or name an auction instance | `station.gd:456-492` |
| M6 | MED | 2+3 | A live `NEXT RESTOCK <m:ss>` footer contradicts the one-lazy-accumulator rule | `STATION_HUB.md:741-742`, `05_exchange.md:131-132` |
| M7 | MED | 2 | 15 §2 says exclusives roll "any rarity"; §5 says the floor is Magic | `15:40-42` vs `15:95-97` |
| L1 | LOW | 1 | Stale `file:line` citations (brief and CONTRACTS §13) | `S3_BRIEF.md:37`, `CONTRACTS.md:1238` |
| L2 | LOW | 1 | A frozen file in the hard rules does not exist | `S3_BRIEF.md:113` |
| L3 | LOW | 1 | The close-out's ticket numbering (`L94+`) is occupied and the law moved to `T-###` | `S3_BRIEF.md:142`, `LOW_BACKLOG.md:18-19` |
| L4 | LOW | 2 | Four suites that will move are not on the tests-that-move list | `test_ship_grids.gd:785`, `test_p2b_services.gd:318` |
| L5 | LOW | 1 | 17 §3's save table stops at v4 and carries `count` | `17_coder_handoff.md:102-109` |
| L6 | LOW | 1 | STATION_HUB §12.1/§12.2/§10 still describe the pre-AUCTION screen | `STATION_HUB.md:891,940,951-955` |
| L7 | LOW | 3 | Rarity tints vs the one-accent law; Magic tints *darker* than Common | `STYLE_BIBLE.md:15,50,154,156`, `STATION_HUB.md:755-759` |
| L8 | LOW | 2 | The hulls' "48 px class icon slot" has no shipped asset | `STATION_HUB.md:731`, `station_catalog.gd:64-160` |
| L9 | LOW | 1 | The rail's enum/parallel arrays and a dispatch sentence about file ownership | `station.gd:54-86`, `dispatch_coder.md:12-15` |
| L10 | LOW | 1 | Root worktree hygiene rides the wave-boundary commit | `RCLONE_TEST`, 7 untracked root files |
| L11 | LOW | 1 | A suite comment calls the AUCTION future | `test_p2b1_outfitting_panel.gd:481` |
| L12 | LOW | 1 | L61's `SCRIPT ERROR` line moved; CONTRACTS §9 cites the old one | `CONTRACTS.md:890-892,926` |
| L13 | LOW | 1 | 10 §2.2 mixes a class name with a ship name | `10:51` vs `08_ship_classes.md:31` |

## HIGH

### H1 — the three faction exclusives have no data and no art anywhere in the tree

15 §5 (`15_module_affixes.md:89-97`) names `w_proton` (Choir), `w_flak` (Concord)
and `u_vault` (Meridian) with a Magic+ floor, and 15 §8 (`:159-163`) pins the
interim that makes the AUCTION carry **one tagged F LOT** of them. Measured:

- `game/module_catalog.gd:41-330` carries 32 rows and none of the three
  (`Catalog.MODULES`), so `ModuleCatalog.module(id)` is `{}` →
  `slot_of` `&""`, `icon_path` `""` (`:344-358`), no `cost`, no `tier`, no
  `draw`, no `effects`. Every auction row's meta (`SLOT <TYPE> · DRAW <n> ·
  <RARITY>`, `STATION_HUB.md:735-739`) and its price (`09 list × 15 §1's
  multiplier`) needs exactly those fields.
- No asset exists: `vajb-orbit/assets/icons/module/` holds 27 SVG glyphs (the 32
  catalogue rows minus the five base weapons, which draw the weapon-family
  glyphs) and no `icon_module_w_proton.svg`, `icon_module_w_flak.svg`,
  `icon_module_u_vault.svg`; `assets/` is frozen this wave
  (`S3_BRIEF.md:113-115`). `docs/gameplay/16_art_design_brief.md:99-100` records
  the sanctioned answer — `w_proton`/`w_flak` "share family silhouettes with
  plasma/cannon until a Phase F icon pass" — so the first-party icon this wave
  needs was deliberately never made.
- No price exists anywhere: 12 §5 (`12_factions.md:81-95`) lists only the −15 %
  station discounts, 14 §4 (`14_station_services.md:85-89`) describes `u_vault`
  as a *station technology* (40-unit vaults, +25 % tier cost) rather than a
  module, and 15 §2's four other tables give no exclusive row beyond the
  auction's 65/30/5.

Consequence: the F lot cannot be built as §5.10 specifies without inventing a
base cost, a tier, a draw, a slot and an effect, and without either a missing
icon or a per-id icon-rule exception. It also breaks a suite that is not on the
wave's list (L4). This is bucket 2 (a pin and a catalogue number must be added by
the developer/designer) **and** bucket 3 (the `u_vault`-as-module-vs-station-tech
question is an owner ruling). No value is proposed here.

### H2 — §15 has no home for a *shelf listing*: rolling a listing would hand the player the item

`CONTRACTS.md:1384-1393` pins `roll_instance(base_id, source) -> StringName`
(15 §2's tables), "module listings are rolled instances drawn at restock", and
`instances_of(base_id) -> Array  # ids, for the grouped rows`
(`:1377`, the *inventory's* rows). The only store the profile has is `modules`:

- `player_profile.gd:334-344` `add_module` writes into `_modules`, which is the
  player's inventory (`modules()` `:289-290`, `module_count` `:320-324`, and the
  FITTING/auction row readers at `fitting_panel.gd:525-538`).
- There is no shelf accessor in §15 and no `owned`/`listed` flag on the pinned
  record (`{instance_id, base_id, rarity, prefixes[], suffixes[]}`).
- Therefore a restock draw that registers listings through the pinned API makes
  ten unowned modules show up in the player's inventory, in `instances_of`, in
  FITTING's OWNED MODULES rows and in the auction's own `SELL MODULES` sub-list
  (`STATION_HUB.md:744-746`), and `sell_instance` would sell items never bought.

Also unpinned inside the same hole: the F lot's **Magic/Rare split** — 15 §8
(`:161-162`) says "rolled at its Magic+ floor (§5)" but §2's auction row
(65/30/5) bans Common, and no document renormalises 30/5 (or 40/40, or any other
pair) for an exclusive. That number is not derivable from the pinned docs.

### H3 — `buy_instance(id)` cannot be told the price the shelf displays

`CONTRACTS.md:1378` pins `buy_instance(id: StringName) -> bool` with no price or
discount parameter, while `STATION_HUB.md:735-739` says the row's price is
"09 list × 15 §1's rarity multiplier, −20 % after for the hot slot" and
`10_ship_acquisition.md:38-39` makes the hot slot a *listing* property. Two
consequences: either the profile recomputes `base × rarity` and silently charges
20 % too much on the hot row, or the panel must pass a price the signature does
not accept. The hull path does not have this problem — `buy_ship(id, cost)` takes
the cost (`station.gd:487-492` resolves it for the refusal copy, and the
shipyard's action passes it). The same shape question applies to `sell_instance`
when a `of the Ledger` suffix is in play (H7).

### H4 — the pinned record drops `count`, which every count consumer reads

The record is pinned twice, differently:

- `CONTRACTS.md:1384` and `15:139-142`: `{instance_id, base_id, rarity,
  prefixes[], suffixes[]}` — no `count`.
- `17_coder_handoff.md:109`: `module_instance_id -> {base_id, rarity, prefixes,
  suffixes, count}` — with `count`.

The tree's whole inventory machinery is count-based: `module_count`
(`player_profile.gd:320-324`, `maxi(0, int(record.get("count", 0)))`),
`add_module` (`:342`), `take_module` (`:354-363`), and the composed install's
first guard `if module_count(module_id) == 0: return false`
(`:528`, so a `count`-less record is **unfittable**). Readers that would render
`OWNED 0` for every instance: `fitting_panel.gd:531`, `shipyard_panel.gd:466`,
`outfitting_panel.gd:885`, `:914`, and the affordability tags
(`STATION_HUB.md:990-991`). The migration's own acceptance ("a v5 file with a
stacked record reads back as that many instances", brief `:65-68`) is satisfiable
either way, but the transaction law is not: the pin must say whether each
instance record keeps `count: 1` (then 17's shape wins and §15's record text is
wrong) or whether `module_count`/`take_module`/`add_module` learn instances (then
§13's signatures change meaning, which §15 forbids).

### H5 — L80's cure cannot be met through the pinned §13 transactions

The brief (`:70-72`) and `SLICE.md` (AC2) require that REMOVE/SWAP return **the
same instance** and close L80. The shipped writers cannot do that:

- `player_profile.gd:334-344`: `add_module` writes only `base_id` (set to the
  record key when absent) and `count`; it never carries `rarity`, `prefixes` or
  `suffixes`.
- `fit_module_at` (`:534-538`) returns the displaced id with
  `add_module(displaced, 1)` and takes with `take_module(module_id, 1)`;
  `clear_fit_slot` (`:577-578`) does the same. `take_module` **erases** the record
  at count 0 (`:358-359`), so the instance's affixes are gone the moment it is
  fitted.
- L80's measurement is exactly this failure, already on the board:
  `LOW_BACKLOG.md:200` — `weapons=["mod_0007","",""]` → REMOVE →
  `modules={ "mod_0007": { "base_id": "mod_0007", "count": 1 } }`, i.e. the
  record comes back as its own key-name with no rarity. It is listed there as
  "[CODE] `ui/station/outfitting_panel.gd:990-992`, `:1011-1017`, `:1131-1134`;
  `autoload/player_profile.gd:306-313`", cure = "return the entry … or keep
  base-id fits and document that instances never enter a fit".

So the wave's rule ("the §13 transactions keep their signatures",
brief `:48-49`) and L80's cure are in conflict: either `add_module` gains an
instance-preserving form (a new signature, i.e. a pin change), or the fitted
instance is never taken out of the inventory (then `module_count` over-counts
fitted items and `sell_instance` can sell an installed module), or fits keep base
ids (then AC2's "fits hold instance ids" is dropped). All three are pin-level
choices.

### H6 — affix stat effects have no owner, and `fit_legal` mis-scores instance ids

15 §1/§3 (`15:20-27`, `:44-63`) say affixes modify the good stats (+pool,
+damage, +speed, +cargo, +output). The shipped route from a fit to live stats
reads **base ids only**:

- `game.gd:351-375` (`_profile_fit`) resolves every cell through
  `PlayerProfile.base_module_id` and hands the base-id fit to `ShipFit.resolve`;
  the instance's rarity and affixes are dropped on the way (`:382-385` is the
  bridge).
- `game.gd` and `game/ship_stats.gd` are in **no** S3 worker's
  `VAJB_WORKER_FILES` (brief `:84-91`, `SLICE.md` "Worker file sets"), so no
  worker in this wave may touch the one path that would carry an affix into
  flight.
- The pins do not fill the gap: `CONTRACTS.md:1389` says only that
  "`resolved_fit` / `fit_legal` see through `instance()[&"base_id"]`". But
  `ShipFit.fit_legal` is a static on the catalogue reader with no profile access
  (`ship_fit.gd:621-653`), and its power arithmetic reads rows through
  `_row`/`_warn_unknown` (`:828-836`, `:504-517`). Fed an instance id it counts
  **draw 0** (`:510-512` continues on an empty row) and emits one
  `ShipFit: unknown module id 'mod_0007' (ignored)` warning per instance. Both
  callers that will see instance-bearing fits do this today:
  `player_profile.gd:532` (`fit_module_at`'s legality re-check) and
  `player_profile.gd:575` (`clear_fit_slot`), plus the panes'
  previews — `fitting_panel.gd:814` reads the fit and `:866` feeds it to
  `fit_legal` for the meter, `outfitting_panel.gd:963`/`:990` via
  `_candidate_fit`/`_resolved_fit` (`:1055-1120`), `shipyard_panel.gd:443-459`.

Net effect as pinned: an overloaded fit containing a rare `w_plasma` instance
would pass `fit_legal` (draw 0 ≤ out) while the meter reads the same wrong
number, and no affix would change any flight stat. The pin needs to say where the
id→base and affix→stat resolution happens (the profile? a `ShipFit` hook? a
resolver owned by `game.gd`, i.e. one more file in a worker's set).

### H7 — 15 §4's suffix perks: one contradicts the pinned sell formula, six have no system

`sell_instance` is pinned as "base × rarity multiplier × 60 %"
(`CONTRACTS.md:1379`, `15:109-111`, `15:164-165`), while 15 §4's table
(`15:74-82`) gives `of the Ledger — sell value +25 %`. The two cannot both be
literal: either the formula gains a suffix term (a pin change, and the reversal
line with it) or the Ledger's perk is unimplemented.

Measured consumers for the other nine perks: `of the Whale` (+50 hull) and
`of the Choir` (+1 power) can land in `ShipFit._apply_flat` /
`_power_arithmetic` (`ship_fit.gd:713-722`, `:516`); `of the Concord`
(+5 % armour effect) and `of the Ports` (+10 % booster duration) have effect keys
to ride (`hull_add`/`speed_penalty`/`boost_speed_mult` in `module_catalog.gd`).
But there is **no** lifesteal/shield-on-damage (`of Embers`), no
kill-hull-restore (`of Leeches`), no hunter-detection system (`of Silence`,
13 §3 — measured: `rg -l "detect" vajb-orbit/game/*.gd` returns only
`game/projectile.gd`, a mine's own proximity check), no POI-reveal API
(`of the Cartograph`, 11 §3.3), and the profile holds no cargo-spill policy
(`of the Vault`; `insured` exists, spill does not — `player_profile.gd:667-679`).
Nothing in §15 or §5.10 says whether S3 implements, stores-only, or defers those
perks, and the brief's staged list (`S3_BRIEF.md:122-127`) names only *roll
sources*, not suffix effects. Bucket 2 for the Ledger (pin), bucket 3 for the
scope ruling on the other five.

## MED

### M1 — the close-out verify command cannot pass, and its frozen guard is inert

`S3_BRIEF.md:140` (and `S3_prompts.md`'s K4 block; the same defect is in
`S4_BRIEF.md:113`) runs:

```
python3 staging/verify_wave.py verify --baseline s3_start \
  --forbidden vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md \
  --expect-reports S3-K0_report.md,S3-K4_review.md --tests
```

Measured (EXHIBIT 2), three independent defects:

1. `--forbidden` and `--expect-reports` are declared `nargs="*"`
   (`verify_wave.py:186-187`), so a comma-joined token is **one** string. The
   forbidden set becomes
   `{"vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md"}`,
   which no relative path can equal (`:144-146`) → the guard never fires.
2. The engine spec's snapshot key is `docs/gameplay/18_engine_spec.md` — verified
   in `_wave_state/s3_start.json` (`vajb-orbit/docs/gameplay/…` is absent) — so
   even split into two tokens, that one can never match.
3. `--expect-reports` resolves each entry under the workspace root (`:149-153`),
   so the bare names point at `<workspace>/S3-K0_report.md`. The run exits **1**
   with `problems: ["expected report missing/empty:
   S3-K0_report.md,S3-K4_review.md"]`. The working form is the full path
   `.agents/gen/slices/S3-module-affixes/S3-K0_report.md`.

The probe form that works is S2.6's own: `--forbidden vajb-orbit/project.godot`
as a single token (`S2.6-R6_review.md:164`). Also note the hard rules freeze
`08`, `assets/`, `addons/` and the theme (`S3_BRIEF.md:113-115`) but the command
guards only two paths — the theme exception (M2) is unprotected in both
directions. Good news for the orchestrator: `s3_start` is exactly HEAD
(`modified/added/deleted` all empty), so the baseline is valid.

### M2 — the three `rarity_*` tokens are this wave's by rule, but no worker owns the theme

`S3_BRIEF.md:113-115` freezes the theme "except the three `rarity_*` theme tokens
STATION_HUB §5.10 names — those are this wave's, through the theme file only".
`STATION_HUB.md:755-759` says the values "live in the theme as `rarity_common` /
`rarity_magic` / `rarity_rare` (fallback to the hexes above when a token is
missing)". Measured: `vajb-orbit/ui/theme/vajb_theme.tres` has 12
`Tokens/colors/*` entries (`:541-552`) and **no** `rarity_*`; the panels read
tokens as `has_theme_color(name, &"Tokens")` with a fallback
(`station.gd:231-233`, `fitting_panel.gd:1022-1024`,
`outfitting_panel.gd:279-281`). No worker's declared set contains
`vajb-orbit/ui/theme/vajb_theme.tres`, and the write hook denies writes outside
the set (`.crush/hooks/enforce_worker_files.py`). So either the orchestrator adds
the theme to K2's `VAJB_WORKER_FILES`, or the wave ships on the fallbacks and the
hard rule is unmet. Not a code judgement — a dispatch decision.

### M3 — the AUCTION shelf's persisted home is unnamed, and `market` silently drops strangers

`CONTRACTS.md:1390-1393` and `10_ship_acquisition.md:40-41` require the rotation
to persist "in the profile's market family". Measured: `_normalise_market`
(`player_profile.gd:1200-1217`) rebuilds the dictionary from
`MARKET_KEYS = ["demand","stock","queue","trend"]` plus `last_band` (`:82`,
`:1196-1197`) and copies nothing else, so a new `market["auction"]` sub-key is
**discarded on load**; `_write_profile` (`:1235-1253`) writes a fixed key list
with no shelf key. Nothing pins a key for the shelf or for the `mod_%04d`
counter §15 promises ("one per-profile counter", `CONTRACTS.md:1385`). K1/K2
must not invent either name; the pin needs both.

### M4 — three documents still carry pre-S2.6 gate figures

Measured today on a scratch store (EXHIBIT 1): `[SUMMARY] passed=457 failed=0`,
exit 0, 457 `[PASS]` lines. Stale texts:

- `CONTRACTS.md:802-807`: "Expected: **`[SUMMARY] passed=455 failed=2`** … where
  the two failures are the two assertions the wave's hit-FX jitter moved" — the
  fixer pass landed; the same section's later block (`:905-934`) already records
  455/2 as an intermediate reading of the *pre-fix* run.
- `S3_BRIEF.md:42-43` "run the gate with a scratch profile until wave S2.6's
  harness fix lands (it runs first)" and `:108` "Expected gate: **437 → ~455**" —
  S2.6 is DONE (`_state/WAVEBOARD.md:16-19`, `:84-88`; `dispatch_coder.md:22`),
  the baseline is **457**, and CONTRACTS §14 (`:1309-1323`) records the cure.
- `SLICE.md:5` gate_baseline `"437/0 (sandboxed; 433/4 on the live save — L93)"`.
- `LOW_BACKLOG.md:232` L93 still reads open although CONTRACTS §14 names it
  closed by the runner sandbox. The brief's instruction to K4 ("run the gate
  twice") is right; its caution text is not.

### M5 — the shell's refusal copy cannot price or name an auction instance

`CONTRACTS.md:1397-1398` says the auction's buy refusals are covered by "§13's
three pinned wordings plus 09 §2's `<n> NEEDED`". Measured: that wording is built
by the shell from the catalogue, not by the pane — `station.gd:456-461`
(`"REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(_entry_cost(id))`) and
`_entry` (`:482-492`) resolves an id through `Catalog.ammo_pack` →
`Catalog.ship` → `ModuleCatalog.module`, so an instance id (`mod_0007`) resolves
to `{}` and the footer reads `0 NEEDED` (and `_entry_name` would render the raw
id, `:474-475`). The auction therefore needs the panel-owned footer (as FITTING
has, `fitting_panel.gd:14-16`) or `station.gd` must learn instances (`:456-492`)
— either is a pin/design decision, not a worker's call.

### M6 — a live `NEXT RESTOCK <m:ss>` footer contradicts the one-lazy-accumulator rule

`STATION_HUB.md:741-742` pins the footer as `NEXT RESTOCK <m:ss>` on "20-minute
station clock, 10 §2.1". Measured: the clock is `autoload/world_clock.gd` with
`BAND_SECONDS := 1200` (`:16`) and exactly four statics — `now`,
`bands_between`, `set_override`, `clear_override` (`:24-57`); there is no
remaining-time accessor, and its own header forbids per-consumer work
("evaluated lazily, at station entry and at each transaction; there are no
per-consumer Timers, ever", `:1-8`). 05 §8 repeats the rule for the same clock
(`05_exchange.md:131-132`: "not on a live Timer in menus"). A ticking `m:ss` in
the auction is a live timer in a menu; bucket 3 wants the owner's word on
whether the countdown is a static "as of entry" line or the rule bends.

### M7 — 15 §2 and 15 §5 disagree on whether an exclusive can be Common

`15:40-42`: exclusives "**only spawn at faction stations** — but any of their
rarity rolls. The proton missile you covet may be a plain Common or a named
Rare". `15:95-97`: "Exclusives never spawn Common; their floor is Magic". §8
(`:161-162`) follows §5. The wave implements §5/§8; §2's sentence is the stale
one and should be corrected in the same docs pass that answers H1 (it is also
what makes the F lot's distribution unpinned).

## LOW

- **L1 — stale `file:line`.** `S3_BRIEF.md:37` cites `player_profile.gd:501/:534`
  for `fit_module_at` / `clear_fit_slot`; measured **523 / 566** (`set_fit_slot`
  is 469, `resolved_fit` 432). `CONTRACTS.md:1238` cites "`FitData.FIT_SLOT_KEYS`
  already is at `player_profile.gd:456`"; measured — 456 is `_touch(KEY_FITS)` and
  the reads are at **472** and **1014**. `CONTRACTS.md:1237`'s
  `game/ship_fit.gd:117` is correct (`MANDATORY_SLOT_KEYS`).
- **L2 — a frozen file that does not exist.** `S3_BRIEF.md:113` freezes
  `docs/gameplay/08_ship_slots_modules.md`; `docs/gameplay/` holds
  `08_ship_classes.md` and `09_ship_slots_modules.md`. The brief's own reading
  list (`:8`) names 09 correctly.
- **L3 — ticketing law.** `S3_BRIEF.md:90`, `:142` say "next free `L94+`";
  measured: L94–L106 already exist (`LOW_BACKLOG.md:238-261`) and the file's own
  law (`:18-19`) is one global `T-###` counter, next free **T-93**. K4's block
  ("append LOW rows … next free L numbers") carries the same stale wording.
- **L4 — the tests-that-move list is short.** `test_ship_grids.gd:785` asserts
  `Catalog.MODULES.size() == MODULE_ROWS.size()` (both 32 today) and its loops
  (`:786-846`) assert name/slot/draw/tier/cost/effects/icon-exists for that local
  32-row table: **any** new catalogue row breaks it, so if H1 is answered by
  adding exclusive rows this suite moves too. `test_p2b_services.gd` reads the
  shipyard hover through `module_count`/`fit_for` and its pinned wording
  (`:318`, `:373`, `:430`, `:433`) and will move when K3 shows rolled names.
  `test_p2b_retirement.gd` (16) drives `fit_module_at`/`module_count` with base
  ids throughout (`:175-190`, `:325-338`) — it should hold if base ids stay legal
  in fits (the pin implies they do, `CONTRACTS.md:1373-1374`), but it is not
  named anywhere. The brief names only `test_p2b1_outfitting_panel.gd` (9,
  verified), `test_p2b_fitting_panel.gd` (20, verified) and `test_p1_profile.gd`
  (11, verified; its `save_version` assertion is `:213`).
- **L5 — 17 §3's save table is two versions behind.** `17_coder_handoff.md:102-104`
  ends the migration list at v3→v4 while the tree is v5 (`player_profile.gd:44`)
  and S3 makes 6; `:109` also carries the `count` variant of the record (H4).
- **L6 — STATION_HUB still describes the pre-AUCTION screen.** `:940`
  "instances the four panels" (the panels are loaded from `MODULE_FILES` today,
  `station.gd:270-291`, so no `station.tscn` edit is needed for AUCTION — worth
  stating because K2 does not own `station.tscn`); `:891` lists the rail as
  "(OUTFITTING, SHIPYARD, FITTING, LAUNCH, LOG OUT)", which was already wrong
  before AUCTION (the shipped order is OUTFITTING, REFINERY, EXCHANGE, SHIPYARD,
  FITTING, REPAIRS, LAUNCH, `station.gd:65-73`); `:951-955` "then the other three
  panels".
- **L7 — rarity tints vs the one-accent law (bucket 3, taste).**
  `STATION_HUB.md:755-759` renders Rare in `#E8703A`. Measured constraints:
  `STYLE_BIBLE.md:15` ("If a second accent appears anywhere in a render or UI
  spec, the asset is wrong"), `:50` (Ember Glow as "emissive rim of the accent"),
  `:154` ("The only colour permitted in UI is Burnt Ember `#C8461B` … never as
  decoration"), `:156` (the ember-glow hover halo is "the single sanctioned
  decorative use of the accent"). §5.10 declares its own exception; the owner may
  want it written into STYLE_BIBLE. Second observation: Magic = `#565C63` is
  *darker* than Common's `text_primary` (theme `:548`), so the escalation reads
  Common (bright) → Magic (dim) → Rare (accent) rather than a brightness ramp.
- **L8 — the hulls' `48 px class icon slot` has no asset.** `STATION_HUB.md:731`
  asks for it; `station_catalog.gd:64-160`'s nine rows carry `preview` only and
  there is no `assets/icons/ship/` directory (checked `vajb-orbit/assets/icons/`).
  Assets are frozen, so the row must reuse `preview` (as the shipyard does,
  `STATION_HUB.md:448`) — the pin should say so.
- **L9 — the rail insertion and one dispatch sentence.** Adding `Module.AUCTION`
  after `EXCHANGE` (`STATION_HUB.md:726-727`, `10:74-75`) renumbers every later
  ordinal in `station.gd:54`, so all five parallel arrays (`:56-86`) gain an entry
  at index 3; "no other entry moves" holds for the rendered rail only. Also
  `dispatch_coder.md:12-15` says S4 owns `outfitting_panel.gd` two lines after
  saying S3 owns "the station panels" and that "S3 and S4 both touch
  `outfitting_panel.gd`" — the brief (`:88`, K2) and `SLICE.md` give that file to
  S3's K2. Nothing here is a blocker; the sentence is just self-contradictory.
- **L10 — worktree hygiene at the boundary commit.** `git status --short`:
  ` D RCLONE_TEST` (the file is absent from disk and absent from `s3_start.json`,
  so `verify` cannot see it) plus seven untracked root files (`PROMPTS.md`,
  `cannon_96.svg`, `gear.svg`, `gear_96.svg`, `lasergun.svg`, `lasergun_96.svg`,
  `rocket_48.svg`). L105 is still open for the first; the second is the same
  L82-class leftover. They will ride the wave-boundary commit unless the
  orchestrator excludes them.
- **L11 — a suite comment calls the AUCTION future.**
  `test_p2b1_outfitting_panel.gd:481-483` ("the AUCTION is future"), part of that
  suite's rewrite.
- **L12 — a pre-existing error line moved.** CONTRACTS §9 (`:890-892`, `:926`)
  places L61's `SCRIPT ERROR` at `tests/test_weapon_fx_f4.gd:176`; today's run
  prints it at `:178` (`_hide_beam` after `_clear()`); the same run also prints
  the pre-existing `Parameter "data.tree" is null` and a `26 ObjectDB instances /
  12 resources still in use` exit line. None of this is S3's, but the citation is
  stale.
- **L13 — 10 §2.2 mixes a class name with a ship name.** `10:51` says
  "Delver, Trader, Hauler 60 %"; 08's Class column (`08_ship_classes.md:28-38`)
  is Fighter / Cutter / **Miner** (Delver) / Trader (Courier) / Corvette
  (Spearhead) / Hauler (Mule) / Gunship / Frigate / Destroyer. The shelf's hull
  rows key off ids, so K2 must map class→id from 08 §2; the doc's own wording is
  inconsistent (a ship name where the other eight are classes).

## Verified as consistent (no finding)

Recorded so K4 does not re-derive them: the currency of the pin
(`CONTRACTS.md:1370-1398` = brief `:47-58`, plus the brief's `resolved_fit`
rule); `SAVE_VERSION := 5` at `player_profile.gd:44` and the v5 migration
threshold `:825-826`; the inventory record today is `{base_id, count}` written by
`add_module` (`:334-344`); `base_module_id` already exists and is pinned by §11
(`CONTRACTS.md:1057`, consumer `game.gd:382-385`, panes `fitting_panel.gd:534`
and `:972-975`, `shipyard_panel.gd:492`, `outfitting_panel.gd:1142`);
OUTFITTING's seven-row interim is `MODULE_ROWS` = 09 §3.1's six + `w_mining`
(`outfitting_panel.gd:97-105`, `:113-121`, bought through `buy_module`
`:933-942`); 09 §2's `<n> NEEDED` refusal already ships (`station.gd:458`);
`WorldClock`'s band is 1200 s and one clock serves exchange/auction/contracts/
arena/sector (`world_clock.gd:1-8`); the three rarity multipliers are integral
against every 09 cost (every catalogue cost is a multiple of 100, so ×1.6/×2.6
and the ×60 % sell need no rounding rule); hull weights and the 6+10 shelf
arithmetic are all present in 10 §2.1/§2.2; `STANDARD_FITS` covers the nine hulls
(`ship_fit.gd:371-421`) and 09 §9's Lancer/Vanguard rows match the auction's
delivery rule; the deck is green with S3 absent (EXHIBIT 1), so every number this
wave adds is genuinely new.

## Evidence

**EXHIBIT 1 — the gate, measured this pass (scratch store; no account touched):**

```
mkdir -p /tmp/s3k0 && source ~/.profile
XDG_DATA_HOME=/tmp/s3k0/xdg timeout 600 godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 1200 > /tmp/s3k0/gate.log 2>&1
# exit=0
# grep -c '^\[PASS\]' → 457
# [SUMMARY] passed=457 failed=0
```

The one `SCRIPT ERROR` is L61's pre-existing `test_weapon_fx_f4.gd:178` (L12);
no `[FAIL]` line exists.

**EXHIBIT 2 — the brief's verify command, dry-run (read-only):**

```
python3 staging/verify_wave.py verify --baseline s3_start \
  --forbidden vajb-orbit/project.godot,vajb-orbit/docs/gameplay/18_engine_spec.md \
  --expect-reports S3-K0_report.md,S3-K4_review.md
# exit=1
# {"baseline": "s3_start", "modified": [], "added": [], "deleted": [],
#  "problems": ["expected report missing/empty: S3-K0_report.md,S3-K4_review.md"]}
```

`modified/added/deleted` all empty is also the proof that `s3_start` is exactly
HEAD, i.e. a valid baseline.

**EXHIBIT 3 — the missing data behind H1 (reads only):**

```
rg -n "w_proton|w_flak|u_vault" docs vajb-orbit staging .agents
# 15:91-93, 15:159, 12:87-91, 14:88, 16_art_design_brief.md:99 — no catalogue row, no cost
ls vajb-orbit/assets/icons/module/*.svg | wc -l   # 27 glyphs, no exclusive glyph
```

**EXHIBIT 4 — the count consumers behind H4/H5:**

```
rg -n "module_count" vajb-orbit --glob '*.gd'
# player_profile.gd:320, :342, :354, :528 (the install guard) …
# fitting_panel.gd:531, shipyard_panel.gd:466, outfitting_panel.gd:885, :914, :961, :988
```

**EXHIBIT 5 — the instance-id path through the resolver (H6):**

```
rg -n "base_module_id" vajb-orbit/game/game.gd
# game.gd:361 (:profile_fit), :369 (the per-cell loop), :382-385 (the bridge)
rg -n "_warn_unknown|_row\(" vajb-orbit/game/ship_fit.gd
# ship_fit.gd:508 (warn), :510-512 (draw 0 on an empty row), :828-836
```

## Files touched

- `.agents/gen/slices/S3-module-affixes/S3-K0_report.md` — this report. No other
  file in the tree was written; every other command in this pass was a read.

## Follow-ups

Each row becomes a `T-###` ticket (next free **T-93**) at slice close — K0 does
not ticket and does not fix. Bucket says who can resolve it.

| Item | Kind | Where | Bucket |
|---|---|---|---|
| H1 exclusive data/art + `u_vault` module-vs-station-tech | SPEC + DOC | `module_catalog.gd:41-330`, 15 §5/§8, 12 §5, 14 §4, 16 §3 | 2 + 3 |
| H2 shelf store + the F lot's Magic/Rare split | SPEC | `CONTRACTS.md:1374-1393` | 2 |
| H3 `buy_instance` price/hot slot | SPEC | `CONTRACTS.md:1378`, `STATION_HUB.md:735-739` | 2 |
| H4 the instance record's `count` (15/§15 vs 17) | SPEC + DOC | `CONTRACTS.md:1384`, `17_coder_handoff.md:109` | 2 |
| H5 L80's cure through §13's signatures | SPEC | `player_profile.gd:334-344`, `:534-538`, `LOW_BACKLOG.md:200` | 2 |
| H6 affix→stat ownership + `fit_legal` id blindness | SPEC + FILESET | `game.gd:351-385`, `ship_fit.gd:504-517`, `S3_BRIEF.md:84-91` | 2 |
| H7 Ledger sell conflict + 15 §4 scope | SPEC + DOC | `15:74-82`, `CONTRACTS.md:1379` | 2 + 3 |
| M1 close-out verify command (3 defects) | HARNESS | `S3_BRIEF.md:140`, `verify_wave.py:139-153,186-187` | 2 |
| M2 the theme file's owner | FILESET | `S3_BRIEF.md:114-115`, `vajb_theme.tres:541-552` | 2 |
| M3 shelf/counter keys (and `market`'s normaliser) | SPEC | `player_profile.gd:1196-1217`, `:1235-1253` | 2 |
| M4 stale gate figures (CONTRACTS §9, brief, SLICE.md, L93) | DOC | `CONTRACTS.md:802`, `S3_BRIEF.md:42,108`, `SLICE.md:5` | 2 |
| M5 the shell's instance refusal copy | SPEC | `station.gd:456-492` | 2 |
| M6 `NEXT RESTOCK` vs the lazy accumulator | SPEC + 3 | `STATION_HUB.md:741-742`, `05_exchange.md:131-132` | 2 + 3 |
| M7 15 §2 vs §5 on exclusives' Common | DOC | `15:40-42` | 2 |
| L1–L13 | DOC / HARNESS / SPEC | anchors in the index table | 1–3 |
