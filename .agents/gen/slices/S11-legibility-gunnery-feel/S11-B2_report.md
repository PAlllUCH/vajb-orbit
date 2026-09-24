---
slice: S11
worker: S11-B2
model: ""             # the orchestrator records the slug that actually ran
status: informational
gate: "805/2 then 806/1 on fresh scratch stores; the one standing failure is test_ship_grids.gd, outside this worker's file set (bucket-2 finding below)"
---

# S11-B2 report — module descriptions + HUD credits block (CONTRACTS §23.2, §23.3)

## Result

`ModuleCatalog.MODULES` carries one `&"description"` key per row (35/35, verbatim from
§23.2, in table order); every other key of every row is byte-identical (the diff is 35
insertions, 0 deletions). The HUD builds a `CreditsBlock` in the top-left column below the
retired fuel block, reads `PlayerProfile.credits()` by name through a `has_method`-guarded
lookup, connects `profile_changed` and moves only on `&"credits"`; it never writes the
profile. `tests/test_s11_inspector.gd` grows the credits half and reads `passed=18
failed=0` in isolation.

## Task one — the 35 descriptions (all verbatim, verified programmatically)

A script parsed §23.2's table and the table in `game/module_catalog.gd` and compared all
35 pairs: **VERBATIM OK**, order preserved, no extra, no missing. `git diff --stat` is 35
insertions / 0 deletions, so no other key moved. `file:line` per row:

| id | gd:line | description (verbatim) |
|---|---|---|
| `w_laser` | `game/module_catalog.gd:261` | Beam weapon. It never misses and never stops asking the reactor for more. |
| `w_cannon` | `:271` | Kinetic burst. Ignores the shield and puts its damage straight into the plate. |
| `w_rocket` | `:281` | Homing warheads. Lock a target or they fly straight and dumb. |
| `w_mine` | `:291` | Drop one behind you and let the pursuit solve itself. |
| `w_plasma` | `:301` | Superheated beam. The heaviest hit a bare hull will ever take. |
| `w_railgun` | `:311` | Sabot slug at speed. Kinetic reach with nothing in its way. |
| `w_mining` | `:321` | Mining tool, not a gun. Cuts rock and leaves the hulls alone. |
| `w_proton` | `:336` | Exclusive launcher on the tier three line. No family row fires it yet. |
| `w_flak` | `:346` | Exclusive battery on the tier three line. No family row fires it yet. |
| `s_light` | `:356` | 200 shield for the least money. The cheapest way to stop bleeding. |
| `s_heavy` | `:366` | 400 shield and a little more regen. A buffer you can hold a lane with. |
| `s_ion` | `:376` | It comes back faster than they can take it away. |
| `h_plate_light` | `:386` | 250 hull structure for five percent of your speed. Plate always costs speed. |
| `h_plate_heavy` | `:396` | 600 hull structure. Twelve percent slower, built to be shot at. |
| `h_composite` | `:406` | 1 000 hull structure for ten percent of your speed and a little mass. |
| `c_target` | `:416` | Fifteen percent more damage out of every gun on the hull. |
| `c_scanner` | `:426` | A quarter more scanner reach, so the sector reads to its edges. |
| `c_twin` | `:436` | The second generation of the targeting line, and more damage for it. |
| `c_ewar` | `:446` | Electronic warfare suite. Fitted and recognised, with no effect row yet. |
| `c_nexus` | `:456` | Both halves at once: more damage and more scanner reach. |
| `b_afterburner` | `:466` | Three seconds of hard burn, eight seconds between them. |
| `b_fold` | `:476` | Blinks the hull four hundred units. Fitted now, firing on a later slice. |
| `u_cargo` | `:486` | Fifteen more cargo units in the hold. |
| `u_salvage` | `:496` | Doubles tractor reach and pull, so loose rock comes to you. |
| `u_refine` | `:506` | A refinery on the hull. Fitted and recognised, with no effect row yet. |
| `u_drones` | `:516` | Repair drones on call. Fitted and recognised, with no effect row yet. |
| `u_tractor` | `:526` | One more tractor stream, so a second rock can be pulled. |
| `u_holds` | `:536` | Forty more cargo units. The volume answer to the cargo line. |
| `u_vault` | `:548` | Station-secured storage that survives a lost hull. |
| `e_std` | `:558` | The stock drive. No bonus, no penalty, and every yard knows it. |
| `e_ion` | `:568` | Fifteen percent more speed at the same mass. |
| `e_vector` | `:578` | More speed and a faster turn. The quick hull's engine. |
| `p_std` | `:588` | The stock reactor. It powers the hull you bought and nothing more. |
| `p_mk2` | `:598` | Two more power output for the modules that ask for it. |
| `p_core` | `:608` | Four more power output. The reactor a full fit is built around. |

No row's wording was judged wrong; all 35 transcribed as written.

## Task two — the HUD credits block (§23.3)

- Constants `ui/hud/hud.gd:130-135` (`CREDITS_BLOCK`, `CREDITS_TITLE`, `CREDITS_ICON`
  preloaded from `res://assets/icons/cargo/icon_credits.svg`, `PROFILE_SERVICE`,
  `PROFILE_KEY_CREDITS`); vars `:311-314`.
- `_build_credits_block` `:1015` builds `CreditsBlock` (VBox) → `CreditsHeader` (HBox:
  `CreditsIcon` = the svg, `CreditsTitle` = "CREDITS", `CreditsSpacer`) + `CreditsValue`
  (`Label`, `HudReadout`); called at `:325` after `_build_pool_blocks`, so it is the
  column's last child, below `FuelBlock`.
- Guarded service lookup `_profile` `:1063` (root-anchored, `has_method(&"credits")`);
  `_connect_profile` `:1072` connects `profile_changed`; `_on_profile_changed` `:1085`
  moves only on `PROFILE_KEY_CREDITS`; `_refresh_credits` `:1090` writes
  `StationCatalog.group_int(_credits())` (`:1093`); `_credits` `:1096` only reads. The
  theme-change path re-tints the icon at `:1419`. Nothing calls a profile setter.
- **`hud.tscn` is byte-identical** (not in the diff): §23.3 pins the block as
  code-built by `_build_credits_block`, the `_build_pool_blocks` idiom; the scene carries
  no credits node and the file is in the set as a permission, not a mandate.
- Tests `tests/test_s11_inspector.gd`: pinned nodes `:325`, reads the profile `:314`,
  follows a credits change `:351`, ignores other keys `:366`, absent-safe `:380`
  (renames the autoload for one mount, restores it, block reads zero). Helpers `:412`,
  `:424`.

## Gates (fresh `XDG_DATA_HOME=$(mktemp -d)` each; the tree is mid-wave — B5/B6 are live)

- Run 1 → `[SUMMARY] passed=805 failed=2`: `test_s11_describe.gd.test_exchange_title_is_the_identity_and_the_hint_keeps_its_verb`
  (B6's suite, in flight) + the finding below.
- Run 2 → `[SUMMARY] passed=806 failed=1`: only the finding below.
- Isolation: `-- --suite=test_s11_inspector` → `[SUMMARY] passed=18 failed=0`.
- Mid-flight runs while B3/B4's re-derivation was landing read 790/5, 793/2, 802/4, so the
  live count is volatile until B5/B6 close.

## Finding — bucket (2): `test_ship_grids.gd` pins the MODULES key count (report, not edit)

`tests/test_ship_grids.gd:794-812` asserts `published.size() == 7` with the comment
"carries exactly name/slot/draw/tier/cost/icon/effects" (`:806-808`). §23.2 adds an eighth
key, so that row must become `8` and name `description`. The file is **outside** this
worker's `VAJB_WORKER_FILES` and §23.6's tests-that-move list does not name it, so it is a
pin change: escalated to the developer/designer, not edited here. §23.6's "and nothing
else" sentence needs the same amendment B3/B4 already earned; the fix is one literal plus
its comment, and the wave needs a continuation worker or an amended grant for it.

## Files touched

`vajb-orbit/game/module_catalog.gd` (+35), `vajb-orbit/ui/hud/hud.gd` (+115),
`vajb-orbit/tests/test_s11_inspector.gd` (+99/-4). `vajb-orbit/ui/hud/hud.tscn` unchanged.
No `docs/**`, no live profile write.
