---
slice: S3
worker: S3-K2
model: ""             # the orchestrator fills what actually ran
status: actionable    # the Follow-ups table is LOW only; K4 tickets it (T-93+)
gate: "471/0 → 482/0 (exit 0 both runs; live profile.cfg md5 unchanged)"
---

# S3-K2 report — the AUCTION, and OUTFITTING's rows retired

## Result

The AUCTION ships as STATION_HUB §5.10: `game/auction.gd` draws 10 §2's shelf
(6 hulls by §2.2's weights, 10 rolled instances by §2.1's tier weights I 50 /
II 35 / III 15, the F lot first at 15 §9.2's 85/15, one hot slot uniform over the
sixteen listed ids), advances it lazily on `WorldClock.bands_between` with the state in
the profile's top-level `auction` key, and prices everything from `ModuleCatalog`
(list × 15 §1's multiplier, 10 §2.1's −20 % after; sell at × 60 %).
`ui/station/auction_panel.gd` + `.tscn` render the HULLS and MODULES lists, the
`SELL MODULES` sub-list and **its own** footer strip (`NEXT RESTOCK <m:ss>` read at pane
entry, then the pane's own refusal/status line). `station.gd`'s five parallel rail arrays
gain `AUCTION` at index 3, `vajb_theme.tres` gains §5.10's three `rarity_*` tokens, and
OUTFITTING returns to the FITTED WEAPONS strip + ammunition with its seven MODULES rows,
their constants and their tests gone.

Measured by the house gate, this machine, twice:

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=482 failed=0          (exit 0, run 1 and run 2)
```

K1's closing figure was `471/0`; the delta is exactly arithmetic — `+11` is
`tests/test_s3_auction.gd` (new) and `test_p2b1_outfitting_panel.gd` held at **9** through
its rewrite (9 → 9), so nothing was lost and nothing was padded. Per suite:
`test_s3_auction` **11/0**, `test_p2b1_outfitting_panel` **9/0**,
`test_p2b_fitting_panel` **20/0** (its `:336` rail index moved 4 → 5), and the thirteen
station/instance suites the wave touches together read **158/0**.

**The live account is untouched (T-93).** `md5(user://profile.cfg)` before and after the
two full gate runs: `9182b34ffe0e51dc2ea8fa3051de4ae2` /
`9182b34ffe0e51dc2ea8fa3051de4ae2`; `md5(user://economy_log.txt)`:
`38b05767f005bafab286e4bbe8ed1764` / `38b05767f005bafab286e4bbe8ed1764`. The two scratch
probes this pass wrote were run under their **own** `XDG_DATA_HOME` (`/tmp/vajb_k2_xdg`)
with `PlayerProfile.save_path` repointed, and both were deleted before this report;
`git status` shows no probe left in the tree.

## The measured rotation, and one number the wave must know

`staging`-style measurement, seeded (`SEED = 20260922`), through `Auction` alone:

| Measurement | Over | Result |
|---|---|---|
| tier weights (`draw_tier`) | 20 000 draws | I 0.5072 / II 0.3403 / III 0.1525 against the pinned 0.50 / 0.35 / 0.15 |
| tier pools | — | 12 / 11 / **9** rows: the 32 non-exclusive catalogue rows, the three 15 §9.1 exclusives excluded |
| F-lot split (`roll_rarity(faction_lot, …)`) | 2 000 rolls | Magic 0.8570 / Rare 0.1430, never Common; the three exclusives picked 667 / 667 / 666 |
| hot slot | 2 000 shelves | a hull 769 times, a listing 1 231 times (16 candidates, uniform) |
| one seeded shelf | — | 10 listings minted `mod_20001..mod_20010`; the F lot first (`w_proton`, magic, 8 320 CR); hulls `fighter, vanguard, miner, trader, freighter, destroyer`; hot `ship_fighter` |

Hull availability, the same 2 000 shelves:

| Hull | §2.2 chance | measured |
|---|---|---|
| `ship_fighter` | always | 1.0000 |
| `ship_vanguard` | always | 1.0000 |
| `ship_miner` | 0.60 | 0.9165 |
| `ship_trader` | 0.60 | 0.8755 |
| `ship_freighter` | 0.60 | 0.8220 |
| `ship_corvette` | 0.45 | 0.6105 |
| `ship_gunship` | 0.45 | 0.4175 |
| `ship_patrol` | 0.30 | 0.2240 |
| `ship_destroyer` | 0.20 | 0.1340 |

**The finding:** 10 §2.2's chances and 10 §2.1's "6 hulls at a time" cannot both hold
exactly. The shelf needs 6 of 9 and the independent chances average 5.2, so a short draw
fills and a long draw drops; the reconciliation is stated in one place
(`Auction._draw_hulls`) and is ordered **by the pin's own chance** (highest fills first,
lowest drops first, ties keeping `SHIPS` order), which is why the measured rates are
strictly ordered by chance as the table above shows while sitting above their literals.
The first draft reconciled by **class rank** (`SHIPS` order) and inverted the pin —
measured then: `ship_corvette` 0.7240 above `ship_freighter` 0.7085, a 45 % hull listed
more often than a 60 % one. **Both the inconsistency and the reconciliation are reported,
not resolved:** the numbers are the docs' own and no worker moves them. Owner options, in
the docs' own terms: drop §2.1's exactly-six to "up to six" (then the chances hold
exactly), or restate §2.2's chances as the reconciliation's measured rates. Reversal of
the code side: `_reconciles_before` returns the `HULL_ORDER` position instead of the
chance.

## Deviations from SLICE.md / the brief

Every one is bucket 1 (inside a pinned acceptance) unless marked; none changes a pinned
number, a `VAJB_WORKER_FILES` set, the tests-that-move list or any `docs/` text.

1. **The `SELL MODULES` row is per *instance*, not per base id.** §5.10 says "the §5.3
   OWNED MODULES anatomy, aggregated by `base_id`, with `SELL` at `base × rarity × 60 %`",
   but a sell price is per instance and an aggregate row cannot show one price for
   instances of two rarities. The rows are therefore the §5.3 anatomy's **per-instance
   sub-rows** (rolled name, rarity tint, `OWNED ×<n>` of the base id, `SELL`), ordered by
   `base_id` (`FIT_SLOT_KEYS` then catalogue order, creation order inside a base). The
   base-id aggregation survives as the ordering and the `OWNED ×<n>` column. Reversal: one
   `Auction.sell_rows` loop and the two sell-row builders — collapse to aggregate rows plus
   §5.3's `▸` expander.
2. **The pane refuses the two conditions it can see before it calls** (`can_afford`,
   `owns_ship`), which is what makes §5.10's "the footer is the pane's own" true in
   practice: §12.4's "let the profile decide" still governs the affordable path, and a
   refusal that would be priced through an instance id never reaches the shell's
   `station.gd:456-492` copy (whose `0 NEEDED` behaviour is pinned by the rewritten
   `test_p2b1_outfitting_panel.gd`). Reversal: drop the two pre-checks and render from the
   profile's `purchase_failed` instead.
3. **The F lot occupies one of the ten module slots**, not an eleventh row: §2.1 says "6
   hulls + 10 modules" and CONTRACTS §15 says "one listing per shelf is one of 15 §5's
   three exclusives", so the nine remaining slots come from the tier weights. It is drawn
   **first**, so the tag is the first row. Reversal: one line in `Auction._draw_listings`.
4. **The reconciliation of 6-of-9 hulls** (above), including its measured table.
5. **Three empty-state captions** §5.10 does not word: `NO HULLS IN THIS ROTATION`,
   `NO MODULES IN THIS ROTATION`, `NO MODULES IN THE BAG`. A bought-out shelf persists and
   refills at the next band, so the caption names the missing rotation rather than
   refusing. Reversal: three constants.
6. **The header-fit machinery is duplicated from `outfitting_panel.gd`** (`_make_section`
   / `_queue_section_fit` / `_fit_section` / `_row_grid` / `_connect_cells`, ~90 lines).
   §5.1's construct is the pin and the repo's precedent sanctions a byte-equivalent copy
   (the FITTING grid recipe), but a shared `ui/station/` helper would be better and **is
   a file outside this worker's set**. Reversal: one import, two deletions.
7. **`Auction.rolled_name` is the one 15 §7 name builder** and FITTING's/shipyard's rows
   should call it (K3's files): the AUCTION needs the same grammar for its own rows, so
   building a second copy in `fitting_panel.gd` would be two grammars for one document.
8. **No hull sell-back surface.** §5.10 mentions "hull sell-back keeps 10 §2.3's 60 %" but
   designs only the `SELL MODULES` sub-list, so no hull sell row and **no dead pricing
   helper** was added. Reported as a LOW below.
9. **`Auction.hull_rows` draws each hull's `preview` as its icon**, exactly as §5.10's
   amendment requires ("no class icon ships"), which makes the row's icon a 48 px scaled
   ship sprite rather than a glyph. Reversal: none owed; the pin's own instruction.
10. **The focus order's "then the footer" resolves to nothing**: the pane's footer strip is
    the restock line plus the status line, neither focusable, so the ring crosses from the
    sell sub-list to the rail. Section 5.10 does not name a focusable footer control on
    this pane. Reversal: give the footer a control (none is specified).
11. **The hot slot's row marker is its `WAS <n> CR` line**, the one caption on the shelf
    that differs from the others, plus the danger-grey price when it is unaffordable. No
    `HOT` badge was added: section 5.10 says only "the hot slot's marker on its row", and
    section 5.6's own pre-press channel is the price's colour. Reversal: one caption
    constant.
12. **The rarity tint sits on the row's name cell, not the whole row.** Section 5.10 says
    "rows are tinted by the rarity table" while section 5.3's own S3 amendment says "the
    rarity-tinted **name cell** (5.10's three tints)"; the more specific wording is the one
    built, and a whole-row tint would fight the selection chrome (the `Button` pressed
    state is `void_panel_raised`). Reversal: move the override from `Title` to the row
    `Button`.

## Evidence

```bash
# the full gate, twice, exit 0 both runs
... headless_runner.tscn -> [SUMMARY] passed=482 failed=0
... headless_runner.tscn -> [SUMMARY] passed=482 failed=0

# per suite (full basename, the L95/L99 rule)
... -- --suite=test_s3_auction          -> passed=11 failed=0
... -- --suite=test_p2b1_outfitting_panel -> passed=9 failed=0
... -- --suite=test_p2b_fitting_panel   -> passed=20 failed=0
# the thirteen suites this wave touches, together
... --suite=test_s3_auction --suite=test_p2b1_outfitting_panel --suite=test_p2b_fitting_panel \
    --suite=test_p2b_services --suite=test_p2b_retirement --suite=test_p1_profile \
    --suite=test_p2a_profile_fits --suite=test_ship_grids --suite=test_s3_instances \
    --suite=test_s3_migration --suite=test_ui_slot_layout --suite=test_p2a_launch_fit \
    --suite=test_s2_6_gate_hygiene      -> passed=158 failed=0

# the live account (T-93), before and after the two gate runs
md5(user://profile.cfg)     before 9182b34ffe0e51dc2ea8fa3051de4ae2
md5(user://profile.cfg)     after  9182b34ffe0e51dc2ea8fa3051de4ae2
md5(user://economy_log.txt) before 38b05767f005bafab286e4bbe8ed1764
md5(user://economy_log.txt) after  38b05767f005bafab286e4bbe8ed1764

# the rotation measurement (two scratch probes, both run under XDG_DATA_HOME=/tmp/vajb_k2_xdg
# with save_path repointed, both deleted before this report)
tiers={1:10144, 2:6807, 3:3049} shares=0.5072/0.3403/0.1525 pool=[12, 11, 9]
hulls fighter=1.0000 vanguard=1.0000 miner=0.9165 trader=0.8755 freighter=0.8220 \
      corvette=0.6105 gunship=0.4175 patrol=0.2240 destroyer=0.1340
hot slot: hull=769 listing=1231 over 2000 shelves
f_lot magic=0.8570 rare=0.1430 over 2000 rolls; picks={w_proton:667, w_flak:667, u_vault:666}
```

One **unidentified flake** in one of the full gate runs this pass (the earliest one, when
this suite carried 10 tests): `passed=480 failed=1`, the same 481 tests with one red,
while a sibling run of the same tree printed a `Cannot call method 'call' on a previously
freed instance` from `test_weapon_fx_f4.gd:178` — a suite this worker did not touch, and
one that passed in that same run. Every later full run was green (each `passed=482
failed=0`, exit 0), and three repeat runs of `test_s3_auction` were `11/0` each, so the
flake is **not** reproduced by this worker's suite and is reported here for K4 as a
pre-existing gate flake.

## Files touched

- `vajb-orbit/game/auction.gd` — **new**, `class_name Auction`: `evaluate_shelf` (lazy
  bands, the exchange's shape), `draw_shelf` / `draw_tier` / `tier_pool` / `exclusive_ids`,
  the §2.2 chance table and the chance-ordered 6-of-9 reconciliation, `next_restock_seconds`
  + `restock_text`, `hull_rows` / `listing_rows` / `sell_rows`, `buy_hull` / `buy_listing` /
  `sell_row`, `hot_price` / `sell_price` / `meta_of` / `rolled_name` / `rarity_token`
- `vajb-orbit/ui/station/auction_panel.tscn` — **new**: §5.1's host-pane construct (header,
  scroll, body) with HULLS / MODULES / SELL MODULES sections and the pane's own footer
- `vajb-orbit/ui/station/auction_panel.gd` — **new**: the pane — rows, rarity tints, the
  `F LOT` tag, the hot `WAS` line, the sell sub-list, the restock reading, the three
  refusals and the status line in the pane's own strip
- `vajb-orbit/ui/screens/station.gd` — `Module.AUCTION` at index 3 plus the four other
  parallel arrays, the rail comment, and the `_entry` note that an instance id has no
  catalogue price (which is why the AUCTION owns its strip)
- `vajb-orbit/ui/theme/vajb_theme.tres` — `Tokens/colors/rarity_common` (the default label
  colour), `rarity_magic` `#565C63`, `rarity_rare` `#E8703A`
- `vajb-orbit/ui/station/outfitting_panel.gd` — the MODULES section retired: rows,
  `MODULE_ROWS` / `EFFECT_TEXT` / `STATUS_*` / `ACTION_*` / `REFUSAL_*`, the module header
  and section, `module_row_ids` / `module_action` / `fit_index_of` / `_module_state` /
  `buy_module` / `install_module` / `swap_module` / `_candidate_fit` / `_first_empty_cell`
  all gone; the FITTED WEAPONS strip, its REMOVE, the ammo rows and the footer kept
- `vajb-orbit/ui/station/outfitting_panel.tscn` — the `ModulesMargin` / `ModulesCaption` /
  `ModulesHeader` / `ModuleRows` nodes deleted
- `vajb-orbit/tests/test_s3_auction.gd` — **new**, 11 tests
- `vajb-orbit/tests/test_p2b1_outfitting_panel.gd` — rewritten to the ammunition-only pane,
  9 tests (the SUITE header, the ammo row/state/purchase/greying coverage the pane never
  had, the retirement guards, the shell's refusal copy, the strip and its REMOVE, the
  refresh)
- `vajb-orbit/tests/test_p2b_fitting_panel.gd` — the rail test's index 4 → 5 and its two
  "fifth entry" comments (FITTING is the sixth since AUCTION took index 3)

No file outside the declared set was edited, and no `docs/` file was touched: CONTRACTS
§9's figure, §8's theme table (which should gain the three `rarity_*` tokens) and §5.10's
tick are the developer session's and K4's.

## Follow-ups

LOW only; the brief gives K4 the LOW rows (next free `T-93`).

| Item | Kind | Where |
|---|---|---|
| `tools/r1_p2b1_format_law.py` still greps `REFUSAL_SLOTS_FULL` / `REFUSAL_OVERLOAD` / the `buy_module` signature out of the OUTFITTING pane, which no longer carries them; a re-run of that analysis tool now fails | LOW (stale evidence tool) | `vajb-orbit/tools/r1_p2b1_format_law.py:80-113` |
| `tests/probe_r1_fit_panes.gd` reads `MODULE_LABELS[4]` and friends as FITTING, which is now SHIPYARD (FITTING is 5); the probe prints a mislabelled rail entry | LOW (stale probe) | `vajb-orbit/tests/probe_r1_fit_panes.gd:241-245` |
| The AUCTION's `_refresh_hull_row` keeps a row enabled for a hull the account owns and refuses on the press (`REFUSED · ALREADY OWNED · <name>`), because §5.10 names no `OWNED`/`IN SERVICE` action for a hull row the way §5.2 does; a disabled `OWNED` plate is the alternative if the owner prefers | LOW (behaviour note) | `vajb-orbit/ui/station/auction_panel.gd:667-680` |
| 10 §2.2's chances and 10 §2.1's exactly-six cannot both hold; the measured rates are in this report and only a docs pass can settle which one moves | LOW (docs finding, K4 to ticket) | `docs/gameplay/10_ship_acquisition.md` §2.1/§2.2 |
| STATION_HUB §8's theme-item table does not carry the three `rarity_*` tokens §5.10 added, so the table and the theme disagree until the developer session ticks it | LOW (docs drift) | `docs/design/STATION_HUB.md` §8 |
