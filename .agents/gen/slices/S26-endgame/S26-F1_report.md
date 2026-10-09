---
slice: S26
worker: S26-F1
model: "deepseek-v4.1-flash"
status: informational
gate: "1237/0 (s26_start) -> 1258/0 x2 hermetic"
---

# S26-F1 report

## Result
F1-F5 fixed at their named sites; F6/F7 are LOW and untouched. The gate is
`1258/0` twice on fresh scratch stores with byte-identical row sets (the same
count R1 graded, because every added assertion rides an existing test row). The
reviewer's probe re-measures `passed=81 failed=0` (was `80/1`, the 1 R2's F1
row) with R4's rows flipped lawful and R7's in-game EVIDENCE line equal to the
flat run.

## Findings — disposition
| ID | Tier | Fix | Re-measure |
|---|---|---|---|
| F1 | HIGH | `autoload/player_profile.gd` — new `insurance_standing_multiplier()` (docked station's faction standing through `StationData.insurance_multiplier`, the S24 seam) and `insurance_charge` multiplies the premium by it before `_charge`. The base `insurance_premium()` stays the panel/U9 figure. | probe R2 `charged = roundi(1080 x 0.8) = 864`; suite `test_a5_the_premium_is_m14_and_champion_scales` asserts the charge. |
| F2 | MED | `player_profile.gd:insurance_payout` — the replacement branch is gated on `insured` (`elif insured: hull = replacement`); an uninsured loss with a surviving fleet grants nothing and `_active_ship` falls back to `_owned_ships[0]`. | probe R4 case 1: no re-grant, lost fit gone, active = the surviving Fighter; suite `test_a5_charge_and_payout_flow`. |
| F3 | MED | `player_profile.gd:insurance_payout` — the "bare hull" `_fits.erase` moved inside `if not _owned_ships.has(hull)`; the lost hull's own fit is erased once, up front. | probe R4 case 2 (insured): replacement into an owned freighter keeps its fit; suite `test_a5_charge_and_payout_flow`. |
| F4 | MED | `game/loot_tables.gd` — `MAW_BAND` + `cache_scale_for(kind, tier)` (1.0 for the Maw band, `cache_scale(tier)` otherwise); `game/game.gd:_spawn_kill_loot` calls it. One owner, so the probe reads the shipped decision. | probe R7 EVIDENCE: S7 tier 4 `scale 1.0`, in-game EV 1581.68 / floor 1025 = the flat run. |
| F5 | MED | `ui/station/vaults_panel.gd`/`.tscn` — render U15's `CAPTION_NOT_CARGO` (`NotCargoCaption`) and U16's `OUTPOST_CAPTION` (`OutpostCaption`, shown when the ceiling is below `VAULT_MAX_TIER`); the unavailable outpost tier now sets the **row** `button.disabled`, not only its action. | suite `test_a7_the_panels_mount_in_the_services_deck`: both captions verbatim, outpost caption visible, tiers 2/3 whole-row disabled. |

No LOW item touched; no pinned value changed. The §8 gate prediction held: the
only two files with new rows are `test_s26_endgame.gd` (+20, unchanged) and
`test_s25_contracts.gd` (+1 net, S38's own re-cut).

## Deviations from SLICE.md
- F4's exception is owned by `LootTables.cache_scale_for`, not inlined at the
  call site: the reviewer's close-out requires R7's in-game EVIDENCE line to
  read the flat run, which needs the probe to read the *shipped* decision rather
  than re-spell it. `MAW_BAND` names the string `TABLES` and the kill path share.
  Reversal: inline `if kind == &"maw": scale = 1.0` in `game.gd` and hardcode
  1.0 in the probe.
- Probe R4 case 2 sets `set_insured(true)`: F3's "erase an already-owned hull's
  fit" only exists on the insured path (after F2), which the review's own F3
  prose names ("the gunship dies insured"). The shipped probe left it uninsured,
  so it proved F2, not F3.
- Test assertions were added inside existing rows (A5, A7), so the row count
  stays 1258 and no §8 count moved.

## Evidence
- Gate, fresh stores, final tree: `XDG_DATA_HOME=/tmp/s26f1_a2 godot --headless
  --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200` ->
  `[SUMMARY] passed=1258 failed=0`; the same with `/tmp/s26f1_b2` ->
  `[SUMMARY] passed=1258 failed=0`. The two `[PASS]`/`[FAIL]` row sets are
  `diff`-identical; the only whole-log diff is the known T-155 frame-timing
  jitter (`[s5-racks]`, `[s4-weapons]`, `[s5-batteries]`, `[S22B2]`).
- Probe: `XDG_DATA_HOME=/tmp/s26f1_probe godot --headless --path "$VAJB_PROJ"
  res://tests/probe_s26_r1.tscn --quit-after 2400` -> `[S26R1] passed=81
  failed=0`. Decisive lines: R2 `Champion charge is x0.8 of the base 1080
  (charged 864)`; R4 `the uninsured loss grants no replacement hull` / `the
  surviving freighter keeps its own fit`; R7 `S7 tier 4 scale 1.0: in-game EV
  1581.68 floor 1025 (doc flat: 1584.75 / 1025)`.
- Baseline `s26_start` `1237/0` (R1's snapshot); this fixer moved no test row.

## Files touched
- `vajb-orbit/autoload/player_profile.gd` — F1 `insurance_standing_multiplier` +
  charge; F2/F3 `insurance_payout` replacement gate and fit erase.
- `vajb-orbit/game/loot_tables.gd` — F4 `MAW_BAND` + `cache_scale_for`.
- `vajb-orbit/game/game.gd` — F4 kill path reads `cache_scale_for`.
- `vajb-orbit/ui/station/vaults_panel.gd`, `vaults_panel.tscn` — F5 captions,
  outpost caption, whole-row grey, probe accessors.
- `vajb-orbit/tests/test_s26_endgame.gd` — A5 charge/no-grant/kept-fit rows, A7
  caption + outpost-grey assertions.
- `vajb-orbit/tests/probe_s26_r1.gd` — R4 rows flipped lawful, R7 reads
  `cache_scale_for`.
- `.agents/gen/slices/S26-endgame/S26-R1_review.md` — `Verified fixes` filled.

## Follow-ups
None new. F6/F7 remain R1's LOW tickets (T-161/T-162/T-163), untouched.
