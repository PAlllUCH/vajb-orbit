---
slice: S7
worker: S7-K3
model: opencode-go/deepseek-v4.1-flash
status: actionable
gate: "746/0 -> 753/0 (twice, scratch stores; my suite contributes 7 of the 753)"
---

# S7-K3 report — the suffix side: Leeches, Cartograph, Ledger, and the staged no-ops

## Result

The three suffix seams CONTRACTS section 20 leaves to this worker are landed and
measured. **Leeches** heals `0.05 x hull_max` inside `game.gd:_on_npc_died`'s credited
path, gated exactly as K0's F6 prescribes (the handler itself is the gate, because
killer identity is not knowable); **Cartograph** lifts the sector's fog at entry through
the shipped `Sector.reveal_pois()` and nothing else; **Ledger** multiplies the sell price
by 1.25 through the one price function, called by all three production sites (the pane's
displayed row, the transaction's quote, the payout) with each passing the record's own
suffix list. The five staged suffixes apply nothing. The gate reads **753/0 twice** on
scratch stores (7 of the 753 are `tests/test_s7_suffixes.gd`; the pre-K3 tree carried
K2's 746), the live store md5s are unmoved, and the only existing-test edit is the one
CONTRACTS section 20's test-law block ratifies.

## What was built (file:line)

- `game/auction.gd:86-92` — `SUFFIX_LEDGER` / `LEDGER_PERCENT := 125`, beside the hot
  slot's own percent.
- `game/auction.gd:625-650` — `sell_price(base_id, rarity, suffixes: Array = [])` (the
  pin's one optional parameter) applies the Ledger term, and `_carries_ledger(suffixes)`
  reads the record's own list in both stored spellings (a bare `"ledger"` id and a
  hand-built `{id, value}` row, through the file's own `_row_id`).
- `game/auction.gd:592` — `Auction._sell_row` (the pane's displayed price) now prices
  through `sell_price` with `_rows(record.get("suffixes"))`.
- `game/auction.gd:763` — `Auction.sell_row` (the quoted transaction price) does the same.
- `autoload/player_profile.gd:71-75` — `const AuctionData := preload("res://game/auction.gd")`,
  the payout's route to the one price function.
- `autoload/player_profile.gd:730-735` — `sell_instance` prices through
  `AuctionData.sell_price(base, rarity, _affix_names(record.get(KEY_SUFFIXES, [])))`,
  so the payout carries the Ledger term exactly when the displayed row does.
- `game/game.gd:70-79` — `FLAG_LEECHES`, `FLAG_CARTOGRAPH`, `LEECHES_FRACTION := 0.05`.
- `game/game.gd:705-724` — `_spawn_sector` ends with one `_reveal_pois_for_cartograph()`
  call (the `if`/`return` pair became an `if`/`else`, behaviour-identical because the
  function ended there), and the new `_reveal_pois_for_cartograph` calls
  `_sector.reveal_pois()` only when the launch summary carries the flag.
- `game/game.gd:2206-2224` — `_on_npc_died` pays Leeches after the credit it files
  (`KILL` log line, heat/standing, loot) and `_heal_leeches()` writes the pool through
  `PlayerState.set_hull`, so `hull_changed` (the HUD bar) follows the perk.
- `tests/test_s3_instances.gd:526-527` — the ratified fixture edit: the Rare laser's
  suffix list becomes `[]` (that row keeps proving the un-suffixed payout).
- `tests/test_s7_suffixes.gd` — new suite, 7 tests.

## Deviations from SLICE.md / judgment calls (bucket 1 unless named)

| # | Call | Why | Reversal |
|---|---|---|---|
| D1 | **The Ledger term lives in `Auction.sell_price`** (the delegate the pin names as the one carrying the parameter), and the two auction-side production sites plus `PlayerProfile.sell_instance` call it. `ModuleCatalog.sell_price` keeps its two-argument signature. | The pin's own block puts the optional parameter on `auction.gd`'s `sell_price` and says "the term lands on all three, each passing the record's own suffix list"; a term spelled at three sites would be three literals, and `module_catalog.gd` is in no S7 file set. One function, three callers. | Move the term into `ModuleCatalog.sell_price` (an additive optional parameter) and make `Auction.sell_price` a pure forwarder. |
| D2 | **`PlayerProfile.sell_instance` gained one preload edge** (`auction.gd`). | It is the payout and must read the same figure the pane shows; `auction.gd` takes `profile: Node` and preloads nothing of the profile, so the edge is one-way (the gate loads clean). | Duplicate the `ledger` check in the profile (a second literal) or keep the payout un-suffixed (the defect K0 F5 measured). |
| D3 | **§20's line "`Auction.sell_price:620` … no production caller" is now stale**: `_sell_row` and `sell_row` both call it. | The pin's own "the term lands on all three" cannot hold otherwise. | Have `_sell_row`/`sell_row` keep calling `ModuleData.sell_price` directly with the third argument (the term would then need to live in the catalogue). |
| D4 | **Leeches sits after `_spawn_kill_loot`, inside the credited path** (after the `_profile() == null` guard). | "the deaths the handler already credits": with no profile service the handler credits nothing, so the perk pays nothing. Not asserted by a test on purpose — that branch is a `push_warning` and the gate's warning ledger is part of CONTRACTS section 9, so the suite proves the gate by asserting the credit and the heal in the **same** call instead. | Move the call above the profile guard (a no-profile death would then heal). |
| D5 | **`_spawn_sector`'s `return` became an `else`.** | One call site after both entry branches instead of two duplicated ones; the `return` was the last statement of the function, so nothing else changed. | Duplicate the reveal call in both branches. |
| D6 | **The staged set is asserted as five suffix ids** (`silence`, `vault`, `choir`, `concord`, `ports`). The brief's test line says "the staged four"; read as the four staged *items* of 15 section 9.3 (Overflowing + Silence + Vault + the faction three), of which K1 proved Overflowing and this suite proves the whole suffix half. | A superset assertion cannot be wrong about which four were meant, and the pin's staged list is the five suffix rows. | Narrow the list if the owner meant a different four. |
| D7 | **The suite's Leeches/Cartograph fixtures fit a real instance through `PlayerProfile.fit_module_at`** rather than hand-building a summary. | The flag then reaches `_launch_summary` by the shipped path (`affix_summary` -> `Affixes.summary` -> `_affix_summary_for`), so the test proves the integration and not just the arithmetic. | Set `scene._launch_summary` by hand (one line per test). |

No pinned number looked wrong; nothing in bucket 2 or 3 was found.

## Tests that move

**Exactly the one ratified edit.** `tests/test_s3_instances.gd:526-527`'s fixture suffix
list is `[]`; the row's assertions are untouched and still green. No other existing suite
changed, no existing count moved: the gate went 746 -> 753 (+7, this suite).

## Evidence

```bash
# the new suite, scoped, on a scratch store
source ~/.profile && XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit \
  res://tests/headless_runner.tscn --quit-after 600 -- --suite=test_s7_suffixes
# [RUN] suites=test_s7_suffixes
# [PASS] ...test_a_launch_without_leeches_leaves_the_hull_alone
# [PASS] ...test_cartograph_reveals_the_sectors_pois_at_entry
# [PASS] ...test_ledger_pays_one_and_a_quarter_at_every_sell_site
# [PASS] ...test_leeches_heals_five_percent_of_the_hull_maximum_on_a_credited_kill
# [PASS] ...test_the_ledger_term_reads_both_suffix_spellings_and_nothing_else
# [PASS] ...test_the_staged_suffixes_are_byte_identical_no_ops
# [PASS] ...test_without_cartograph_the_sector_enters_fogged
# [SUMMARY] passed=7 failed=0

# full gate, twice, each on its own scratch store (XDG_DATA_HOME=$(mktemp -d))
# [SUMMARY] passed=753 failed=0   (twice, exit 0)
# the tree before my suite: 746 rows (K2); my suite contributes exactly 7 -> 753.
grep -h "^func test_" vajb-orbit/tests/test_*.gd | wc -l   # 753

# parse ledger of the touched files
godot --headless --path vajb-orbit --check-only --script res://game/auction.gd          # clean
godot --headless --path vajb-orbit --check-only --script res://autoload/player_profile.gd  # clean
godot --headless --path vajb-orbit --check-only --script res://tests/test_s7_suffixes.gd
# only the pre-existing autoload trap (game.gd:2130 `Router`, the same one K2 recorded);
# no error in my own code.

# the full gate's one SCRIPT ERROR line is the pre-existing L61 one
# (test_weapon_fx_f4.gd:178, present before any K3 edit).

# the live store, untouched by these runs (every run used a scratch XDG_DATA_HOME)
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg"
# b32fdb7b9c68e132e76d0771660f916b  (before and after both runs; CONTRACTS section 9's own figure)
md5sum "$HOME/.local/share/godot/app_userdata/Vajb Orbit/economy_log.txt"
# bd27929cd7b075e913d07e50a017bbcf  (before and after both runs)

# every consumer of a suffix flag, project-wide (the staged five appear nowhere):
grep -rn "has_suffix\|affix_flags" --include=*.gd game/ autoload/ ui/
# game/ship_fit.gd:960        -> &"whale"      (K1's resolve)
# game/weapons.gd:1937        -> FLAG_EMBERS   (K2's two deliveries)
# game/game.gd:722            -> cartograph    (this pass)
# game/game.gd:2212           -> leeches       (this pass)
# game/auction.gd:_carries_ledger -> ledger    (this pass)
# silence / vault / choir / concord / ports: no reader anywhere.
```

## Files touched

- `vajb-orbit/game/auction.gd` — +40/-7: the Ledger constants, `sell_price`'s optional
  parameter and term, `_carries_ledger`, and the two production call sites' own suffix
  lists.
- `vajb-orbit/autoload/player_profile.gd` — +12/-3: the `AuctionData` preload and
  `sell_instance`'s priced-through-the-one-function payout.
- `vajb-orbit/game/game.gd` — +38/-2: the two flag constants and the Leeches fraction,
  the Cartograph entry call and helper, the Leeches payout and helper.
- `vajb-orbit/tests/test_s3_instances.gd` — the ratified fixture edit (+4/-1).
- `vajb-orbit/tests/test_s7_suffixes.gd` — new suite, 7 tests.

No `ui/**`, `assets/**`, `staging/**`, `project.godot` or `docs/` write.

## Follow-ups

| Item | Kind | Where |
|---|---|---|
| `tests/test_s7_suffixes.gd.uid` is not written yet — the sidecar is an editor-import artifact and the editor session belongs to D7's lane (a headless `--editor --quit` would write the same import cache) | OWED (editor import) | `vajb-orbit/tests/test_s7_suffixes.gd` |
| §20's "`Auction.sell_price:620` … no production caller" is stale after D3 | DOC NOTE (bucket 1) | `docs/CONTRACTS.md` section 20 |
| L90 stays open; K2's Frugal route-around is unaffected by this pass | LOW (pre-existing) | `.agents/gen/_state/LOW_BACKLOG.md` L90 |
| The `d7r1_*` tools and the `tools/d7r1_probe.gd` editor-log parse error are D7's lane, not this wave's | ATTRIBUTION | `vajb-orbit/tools/` |
