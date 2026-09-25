---
slice: S11
worker: S11-R1
role: reviewer
tree: af933be (HEAD, shipped)
verdict: passed — no HIGH, no MED, no fixer
---

# S11-R1 — review of station legibility, space gunnery, one-vector inertia (CONTRACTS §23)

## Instruments

- Tree `af933be`; wave diff `396b8f3..HEAD` = 27 modified, 3 new suites, 0 deleted.
- Gate, twice, fresh `XDG_DATA_HOME=$(mktemp -d)` each, `--quit-after 1200`, exit 0 both: **`[SUMMARY] passed=807 failed=0`** (`/tmp/s11_gate1.log`, `/tmp/s11_gate2.log`); the two runs' `[S11FS]`/`[S26F]` rows and fail lists are byte-identical.
- `staging/verify_wave.py verify --baseline s11_start` → exit **0**, `"problems": []`, modified 27 / added 130 / deleted 0 (the adds are D11's `staging/phase_g/**`, `assets/env/poi/*.import` and this wave's three suites — D11's edits are not S11's).
- Live store `profile.cfg` **eb750728e6dbd9cbe944e32c96307c87** / `economy_log.txt` **8b9414b7e9545abfc865c337ce5199af**: both unmoved around both gate runs and around every headless probe/verifier run. The editor bridge moved the profile (L180); `economy_log.txt` never moved at any point.
- Live editor session `vajb-orbit@6069225ff44d8b75` (plugin 4.2.2). Every bridge run was mine (`project_run` custom → … → `project_manage(op="stop")`); no purchase, repair, fit, launch or ENTER was pressed, and no game I did not start was stopped.

## Attribution — 775 → 807 (per-suite `func test_` counts, baseline vs HEAD)

Baseline `396b8f3` = **775** test methods, HEAD = **807**; the only count changes are the three new suites, and no pre-existing suite moved: `tests/test_s11_inspector.gd` **0 → 18** (B1's 13 + B2's credits 5), `tests/test_s11_flight_stop.gd` **0 → 3**, `tests/test_s11_describe.gd` **0 → 11** = **+32**. `test_engine2_weapons.gd` (48), `test_s7_affixes.gd`, `test_ship_grids.gd` (27), `test_s2_6_flight.gd` (7), `test_engine_c3_flight_decay.gd` (3) and all others hold their counts — B5 re-derived rows *inside* those files and added no test method.

## AC1/AC2 and the first hazard — the inspector through real input

Route: `res://ui/screens/station.tscn` on the live bridge, real `InputEventMouseMotion`/`InputEventKey` through `Input.parse_input_event` + `Input.flush_buffered_events()` (S10-R1's route), `gui_get_hovered_control()` as the path's canary; the ARMORY (default module) was scrolled with twelve real wheel events to put the rows on screen; a canary status line was planted through the shell's own writer first.

| step | hovered control (canary) | title | body | status strip |
|---|---|---|---|---|
| plant | — | `W1 CANNON MKI` (unmoved) | cannon prose (unmoved) | `REFUSED · NOT ENOUGH CREDITS · 999 CANARY` |
| hover | `OwnedWLaser:<Button>` | `LASER MKII` | `Beam weapon. It never misses and never s…` | canary, **byte-identical** |
| hover | `AmmoLaser:<Button>` | `LASER CELLS · 120 CREDITS` | `Standard laser capacitors. Cheap, and th…` | canary, **byte-identical** |
| leave | — | `""` | `""` | canary, **byte-identical** |

- **Hover fills, unhover clears** (§23.1 signal row): three transitions, the hovered-control identity naming the exact row each time — no path is inferred.
- **The inspector is not a second writer of the strip** (the wave's first hazard): the canary survived all three hovers byte-identically, and planting it left the inspector untouched; the writers share no node (`station.gd:454-466` writes only `_inspector_title`/`_inspector_body`; `:558` writes only `_status_label` + beacon).
- **Title/status split**, same row (TAB focus on `AmmoLaser`): title `LASER CELLS · 120 CREDITS`, status `ENTER BUY · LASER CELLS · 120 CREDITS` — measured on all four ammo rows; the verb is the strip's alone.
- **`describe`** (§23.1 body-text row), called live: `describe(mod_0737)` = `Three seconds of hard burn, eight seconds between them. · Spry -15 % · kills restore 5 % hull` → base-id resolution through `b_afterburner` **and** the affix-perk join; `mod_0001`/`mod_0319` (no affixes) = base prose only; `iron`/`mineral_iron`/`ingot_iron` answer the same `MineralCatalog` prose (B6's widened source, `station_catalog.gd:364-377`); `ammo_laser` answers its pack's prose; `no_such_row` → `""`.
- **`group_int`** (the one copy): `1200`→`1 200`, `30000`→`30 000`, `0`→`0`; `station.gd:658` `_format_int` delegates to it.
- **Nothing reworded**: the only removed lines in the eight panes' diffs are ARMORY's `_on_barrel_focused.bind(rack)` → `.bind(rack, cell, entry)` and its comment; no `STATUS_*` / `_row_hint` / `BARREL_TEXT` / `STATUS_READY` literal changed or was deleted.

## AC3 — the 35 descriptions

Programmatic byte comparison of §23.2's table against `game/module_catalog.gd`: **35/35 identical, 0 missing, 0 extra**, in table order; the file's diff is **+35 / −0**, so no other key of any row moved. Also read by eye: `w_laser:261`, `h_composite:406` (`1 000`, thin space), `u_holds:536`, `e_std:558`, `p_core:608` — character-for-character.

## AC4 — the credits block

Live, `res://game/game.tscn`: `CreditsValue` (Label, `theme_type_variation HudReadout`) under `CreditsBlock` → `Blocks`, whose children are `[EmergencyBanner, HullBlock, ShieldBlock, EnergyBlock, FuelBlock, CreditsBlock]` — last child, below the fuel block (§23.3); `CreditsTitle` `CREDITS` and `CreditsIcon` = `res://assets/icons/cargo/icon_credits.svg` exist (`hud.gd:131-133`). Value **`2 125`** == `group_int(profile.credits())` == the profile's own `credits=2125`. Follow proof: label forced to `CANARY-SENTINEL`, `profile.emit_signal(&"profile_changed", &"credits")` → restored to `2 125`; forced again, `profile_changed(&"hull")` → sentinel **stays** (credits key only). Never writes: the only profile call in the file is the read `profile.call(&"credits")` (`hud.gd:1100`), no setter appears in `ui/hud/**`, `hud.tscn` is byte-identical, and the live pair was unmoved around every gate run.

## AC5 — near-infinite range (§23.4)

Live: `range_of` → laser/plasma/cannon/railgun **30000.0**, rocket **900.0** unmoved, mine **0.0** unmoved; `NEAR_INFINITE_RANGE == 30000.0`. `game/weapons.gd`'s whole diff is the const + those four literals (checked hunk by hunk); the beam's `span := minf(offset.length(), reach)` (`:1129`, the ray's own hit point still shortens a shot) and `game.gd:1431`'s readout are byte-identical; `projectile.gd` (`:441/503/635`) and `game.gd` are untouched by the wave. `range_of` is the single reader in `game/`; the tests' rows moved to the const with rocket left a literal.

## AC6 — one-vector inertia (§23.5) and the second/third hazards

- My own gate runs print the acceptance: vanguard `v_release=406.616 drift=0.000000 deg cross_share=0.000000000 sampled=143 t_tenth=2.3833 derived=2.3626 coast_time=2.6250`; fighter `426.987 / 0.000000 / 1.9000 / 1.8877 / 2.1000`; freighter `277.972 / 0.000000 / 6.1500 / 6.1342 / 6.8250` — every hull holds its bearing on every tick and lands on the T1 envelope (bound 5.0 deg, `test_s11_flight_stop.gd:48`; the release leg presses `thrust_forward` **and** `strafe_right`, `:303-304`).
- **Independently, my own `probe_s2_6_flight` run** (bounded, scratch store, `[S26F] done failures=0`): `damp_forward == damp_lateral` and identical axial/lateral decay rows on **all nine hulls** (vanguard `axis=axial v0=200.0 t_10=1.150 dist_10=126.41` == `axis=lateral`; freighter 4.400 both; miner 2.500 both) — one rate, one stop; the coast envelope is T1's (`t_10 2.367` vs derived `2.363`); `mirror … sweep_error=0.000000 mirrored=true`.
- **The strafe is not slowed**: `[S11FS] strafe hull=ship_vanguard sideways=367.717 ceiling=406.600 after=4.533 s` (90 % of the ceiling in 90 % of `accel_time`); fighter `386.101 / 427.500 / 3.767 s`; the chase still runs `_step_strafe` → `_thrust_axis(..., _lateral_damp())` (`player_ship.gd:848`).
- `LATERAL_DAMP_MULT` is unread: in `game/` it appears only in comments (`ship_fit.gd:509,527`; `player_ship.gd:659,903,1127-1128`); `_lateral_extra_damp()` = `maxf(_lateral_damp() - _linear_damp(), 0.0)` = exactly `0.0` and `_step_lateral_drag` returns on its `extra <= 0.0` guard (`player_ship.gd:1130,1139-1140,918`). T1 `2.5`, T2 `0.5` (`ship_fit.gd:526-528`), `ACCEL_TIME_MULT` untouched.
- **T3 held**: `STRAFE_RATE_MULT` has exactly one hit in `vajb-orbit/` — the sentence at `game/ship_fit.gd:521` recording it as held and implemented nowhere.

## AC7/AC8 — gate, scope, wave hygiene

- Every changed `vajb-orbit/` file lies in a worker's set: `game/weapons.gd` (B3/B5), `game/ship_fit.gd` + `game/player_ship.gd` + the three flight suites (B4), `game/module_catalog.gd` + `ui/hud/hud.gd` (B2), `game/station_catalog.gd`, the eight panes, `ui/screens/station.{gd,tscn}`, `test_s11_inspector.gd` (B1/B6), the three probes + `test_engine2_weapons.gd` + `test_s7_affixes.gd` (B5), the three new suites. The one file outside any set is `tests/test_ship_grids.gd`, re-derived by the **developer session** and named for that in §23.6's amendment — verified: its single hunk reads `published.size() == 8` with `…/effects/description` plus a non-empty `description` assertion, and nothing else in the suite moved.
- No reformat churn: `git diff -w` is 2119/161 against 2121/163 — **2 lines** of whitespace-only movement, all in `game/player_ship.gd`. No `hud.tscn`, no `assets/**`, no `docs/**` outside §23's docs-first `CONTRACTS.md`, no `.tscn` outside `station.tscn`, no `git add`, no commit, no background command left running.

## probe_c3_flight_decay is not this wave's (kept out of the verdict)

Reproduced by me, not taken from B5: a detached worktree at **4c19812** (pre-dispatch, `/tmp/s11_base`, assets symlinked, pruned after) reads `[C3] done cases=4 failures=4`, all four dying in the *accelerate* leg (`never reached <cruise> u/s; not measured`, `MAX_ACCEL_SECONDS=30.0`, `tests/probe_c3_flight_decay.gd:56`); the shipped tree reads the same. That leg is `Input.action_press(thrust_forward)` into `_hold_until` — no wave file is on its path and the probe file is byte-untouched. The printed snapshot does differ between the trees (HEAD vanguard **83.312** / fighter **346.793**; pre-dispatch **147.236** / **73.081**): the leg grows at `rate + damp·along`, so T1's `damp` (`1/coast_time`, 0.476190 → 0.380952 on the vanguard) alone can move a budget-end snapshot, and both logs show the speed peaking and dipping inside the 30 s budget. Identical failure mode, no number pinned by the file → LOW row with both readings, never a finding.

## Findings

**HIGH — none. MED — none.** LOW (all appended to `_state/LOW_BACKLOG.md` as L178–L183):

- **L178 — `tests/probe_c3_flight_decay.gd:56`**: fails 4/4 in the accelerate leg on both trees; snapshot speeds 4c19812 `147.236/73.081` vs af933be `83.312/346.793`. §23.6 does not own this probe's red. Route: my worktree + shipped-tree headless runs.
- **L179 — `vajb-orbit/tests/test_s11_{inspector,flight_stop,describe}.gd.uid`**: untracked (the editor minted them during this review). §23.6 ignores `.uid`; same class as L177. Route: `git status --short vajb-orbit/tests/`.
- **L180 — `autoload/player_profile.gd:277-280`**: the live-bridge route rewrites the owner's profile on game exit (`flush()`), so a bridge reviewer cannot keep the live pair byte-identical — `profile.cfg` `eb750728…` → `f92040ca…` (5961 → 6093 B) after my runs while `economy_log.txt` stayed `8b9414b7…` (no transaction). §23 pins no store: a measurement hazard, not an S11 defect.
- **L181 — `ui/station/auction_panel.gd:140,1025-1030`**: AUCTION's status line fills the verb-led `ENTER %s · %s · %s CREDITS` with `[name, cost, action]` → `ENTER VANGUARD · 5 000 · BUY CREDITS`, while its title is the identity `VANGUARD · 5 000 CREDITS` (`:145`). §23.1's title row keeps the strip byte-identical (the addendum's open pin).
- **L182 — `game/player_ship.gd:873-884`**: a *pure lateral* release now stops on the class coast ramp, not the exponential damp §22's amended T4 / §23.5's "(1/coast_time)" parenthetical names — axial == lateral at v0 200 (vanguard `t_10 1.150 s`, was `2.383 s` lateral) with the axial row unmoved. Route: my `probe_s2_6_flight` run.
- **L183 — `game/station_catalog.gd:368-380`**: the empty-body answer has no live specimen — minerals 20/20, components 18/18, ships+ammo+services 18/18, modules 35/35 all carry prose, so `""` is reachable only for an id no catalogue holds (`no_such_row` → `""`). §23.1's body-text row. Route: catalogue counts + the live `describe` sweep.

Two observations, not findings: the item-less panes' inert `inspect_requested` is reported by the editor's lint ledger (`ui/station/repairs_panel.gd:29`, `ui/station/launch_panel.gd:41`, "declared but never explicitly used") because the pin's own row asks for exactly that; and the `title == ""` state keeps the 130 px raised panel mounted with empty text, which is the pin's paid height.

## Verdict

**passed** — no HIGH, no MED, no fixer. Every §23 acceptance re-measured on `af933be`: the inspector fills and clears through real input while the status strip is provably a separate writer; the title/status split holds per row; `describe` resolves base ids and joins affix perks; the 35 descriptions are verbatim with no other key moved; the credits block reads and follows the profile without writing it; the four families read `30000.0` through `range_of` with rocket/mine unmoved and the beam's hit-shortening intact; the released hull holds its bearing at `0.000000 deg` on one decay with the commanded strafe at its class rate; T3 is implemented nowhere. `probe_c3_flight_decay` is pre-existing and excluded. §9 gains the S11 expected row with the `775 → 807` attribution and §10 the next free row.

## What I could not measure

- **The flight acceptance flown in the live game window.** `res://game/game.tscn` accepted the two bridge evals that measured AC4, then refused every further `game_eval` on relaunch (`EVAL_GAME_NOT_READY`: the helper's main loop stops advancing while the window is backgrounded on this Wayland host), so AC6's numbers are the suite's and the probe's, run by me on scratch stores — not a live-keyboard flight.
- **The two new suites' individual rows**: read as suite counts in the gate plus the live measurements above, not line by line.

`problems: []`
