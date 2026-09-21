# Engine slice 0 — M6 re-review report (physics & fuel, after the M5 fixer pass)

Worker **M6**, re-reviewer. Date **2026-09-21**. Engine Godot 4.7.2, headless only,
every run bounded (`--quit-after`) and its stdout redirected to a log that was read
afterwards. Nothing was left in the background. File set as dispatched:
`docs/CONTRACTS.md` + `vajb-orbit/tools/` (`.agents/` implicitly).

**Verdict: every finding M4 raised against this wave is verified fixed, and the one
HIGH is closed — the universal gate reads `passed=78 failed=0` (exit 0) on the frozen
tree, measured three times. F1–F5 each re-measured by this worker's own probes and by
M4's own probe re-run on the fixed hull (`ok=8 failed=5` → `ok=13 failed=0`), F6 is
closed by this dispatch's file set, and all three owner rulings that change what a
correct fix looks like are verified against, not against the brief. The wave's two
open items remain the owner's (F7's superseded refuel wording in the locked spec, and
the §13 speed table v2 tick) — recorded below, not attempted.**

| Tier | Count | Items |
|---|---:|---|
| HIGH | 1 | F1 — **fixed, gate green** |
| MED | 7 | F2, F3, F4, F5 — **fixed and re-measured**; F6 — **closed by dispatch**; F7 — **open, owner** |
| Acceptance | 1 | Small-rock pickup burst — no longer path-blocked, still unproven end to end (ruling R2) |
| Owner-gated | 2 | F7; §13 speed table v2 tick |

---

## 1. Verdict per finding — the verification table

Every row is a measurement made by this worker in this pass, not a report read back.
Log files are in `.agents/gen/`.

| # | Claim to verify | Method (this pass) | Measured | Verdict |
|---|---|---|---|---|
| **F1** HIGH | `tests/test_p1_profile.gd` must expect save_version **3**, so the gate reads the full suite with ZERO failures; measure the actual total | `git diff HEAD -- vajb-orbit/tests/test_p1_profile.gd` (HEAD = the pre-slice-0 snapshot) + `headless_runner.tscn --quit-after 1200`, three runs + an independent `func test_` count | diff is **exactly one line** (`2,"writes always persist v2"` → `3,"writes always persist v3"`); gate **`passed=78 failed=0`, exit 0**, no `SCRIPT ERROR` (runs 1/2/3); independent count of `func test_` across `tests/test_*.gd` = **78** (9+16+11+4+13+5+9+6+5) | **FIXED** — the suite is 78 and all 78 pass |
| **F2** MED | at fuel 0 a full second of throttle must NOT accelerate the hull | M4's probe re-run + M6 probe A: 1 s of full throttle at fuel 0, with a funded control and the two other thrust sources | fuel 0 → **0.0 u/s** (was **203.571319580078**); the same throttle with fuel aboard → **203.571319580078 u/s**; reaction wheels at fuel 0 → **3.39999985694885 rad/s**; a 400 u autopilot order at fuel 0 → **0.0 u/s** | **FIXED** |
| **F3** MED | one second of afterburner must burn 3.0 Fuel; boost must refuse to arm on an empty tank | M4's probe re-run + M6 probe A (`BOOST_FUEL` owner, arm refusal, dry-tank burn end) | 1 s of `boost`, full tank → burned **3.00000000000068** (was **0.0**); empty tank → `_boost_remaining` **0.0 s** (was **2.51666666666667 s armed**); tank 0.05 + 0.3 s boost → fuel **0.0**, `_boost_remaining` **0.0**; `PlayerShip.BOOST_FUEL` **3.0**, `PlayerShip.DASH_FUEL` **25.0**, `ShipFit` carries neither | **FIXED** |
| **F4** MED | spending 10 Energy must refill through the reactor tick in the shipped game | M4's probe re-run + M6 probe A (full efficiency **and** the emergency penalty) | 10 E spent → **90.0 → 94.9999999999997** in 1 s (refill **4.99999999999972**, spec 5.0; was **0.0**); the same spend at fuel 0 → refill **3.50000000000023** (spec ×0.7 = 3.5) | **FIXED** |
| **F5** MED | `consume_fuel_cell` must have a shipping caller, bound to **R** (ruling R3) | M6 probe A: the live `InputMap` keycodes, plus a **real `InputEventKey`** parsed from the probe root's `_physics_process` (R, held 4 frames, released; then a second press; then C as the negative control) | `consume_fuel_cell` → keycodes **[82] = R**; `cargo_toggle` → **[67] = C**; one real R press → **exactly 1** call (0 → 1), held 4 frames → **still 1** (an edge, not a per-frame poll), a second press → **2**; a real **C** press → **0** calls. On disk `project.godot:128` binds `consume_fuel_cell` keycode 82 | **FIXED** — ruling R3 is what ships |
| **F6** MED | the probe-in-`tools/` hook gap (harness, not code) | written normally, with the `write` tool, in this pass | `vajb-orbit/tools/` was in `VAJB_WORKER_FILES` (`docs/CONTRACTS.md,vajb-orbit/tools/`, read from the live environment): `_probe_s0m6_hull.gd`, `_probe_s0m6_hull.tscn`, `_probe_s0m6_witness.gd`, `_probe_s0m6_services.gd` were all created with **`write`, no shell fallback, no hook denial** | **CLOSED** — the gap was in the dispatch, and this dispatch closes it |
| **F7** MED | the owner-locked spec still sells fuel for CR in three places | not attempted, per the dispatch | `18_engine_spec.md` §2.1 ruling 13 / §4.4 / §12 item 8 still carry the superseded wording; the mitigation (docs 14 §1, IMPLEMENTATION_PLAN §9.9, CONTRACTS §8/§8.1 + changelog) is in place and **no CR rate exists in code** (measured: services probe B and the project-wide token scan) | **OPEN — owner's pass** |
| — | §13 speed table v2 tick | not attempted, per the dispatch | §13's "△" interpolations are still unticked; the wave used the shipped class columns as law | **OPEN — owner's tick** |

### 1.1 M4's own probe, verbatim, before and after

M4's probe was re-run unchanged (`res://tools/_probe_s0m4_live.tscn`, archived at
`.agents/gen/slice0_m4_probe_live.{gd,tscn}`, restored byte-for-byte for the run):

```
                                             BEFORE (M4, .agents/gen/          AFTER (M6, .agents/gen/
                                             slice0_m4_probe_live.txt)         slice0_m6_probe_m4_live_after.txt)
emergency: at fuel 0 the hull ignores thrust   FAIL 203.571319580078 u/s        OK 0.0 u/s
emergency: at fuel 0 the afterburner locks out FAIL boost_remaining=2.51666…    OK boost_remaining=0.0
boost: 1 s burns BOOST_FUEL 3.0                FAIL fuel 200.0 -> 200.0 (0.0)   OK 200.0 -> 196.999999999999 (3.00000000000068)
reactor: a spent buffer refills at 5/s         FAIL energy 90.0 -> 90.0 (0.0)    OK 90.0 -> 94.9999999999997 (4.99999999999972)
input: consume_fuel_cell is in the map         FAIL has_action = false          OK has_action = true
SUMMARY                                        ok=8 failed=5 (exit 1)            ok=13 failed=0 (exit 0)
```

The five flight/collision checks are identical in both logs (max **424.106689453125**
u/s at **2.08333333333333 s**, flat-wall **144.196558395699** = formula, autopilot
closest **39.9171447753906** u), i.e. the fixes moved the reactor chain and nothing
else. M5's intermediate before/after pair (`ok=9 failed=4` → `13/0`) is reproduced
digit for digit by this run.

**The before-state is genuine, not assumed:** the pre-fix hull is archived at
`.agents/gen/_m5_before_player_ship.gd` with md5 **`de16ff6528a0`**, identical to
M4's published hash, and it contains **zero** occurrences of `_thrust_locked`,
`_burn_boost_fuel`, `_step_reactor`, `_update_fuel_cell` or `BOOST_FUEL` (the fixed
file carries 4/3/2/2/7). The before log was measured on bytes that cannot contain the
fixes.

## 2. Final test-gate output (frozen tree)

```
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" \
  res://tests/headless_runner.tscn --quit-after 1200
```

| Run | Log | Result | Exit |
|---|---|---|---|
| 1 | `.agents/gen/slice0_m6_testgate.txt` | `[SUMMARY] passed=78 failed=0` | 0 |
| 2 (profile-attribution run) | `.agents/gen/slice0_m6_testgate_attr.txt` | `[SUMMARY] passed=78 failed=0` | 0 |
| 3 (final, frozen tree, after every probe was removed) | `.agents/gen/slice0_m6_testgate_final.txt` | `[SUMMARY] passed=78 failed=0` | 0 |

No `FAIL` line and no `ERROR` in any of the three logs; the single `WARNING` each
carries is the `p1l` suite's own deliberately-missing-directory probe
(`EconomyLog: could not open user://p1l_missing_dir_do_not_create/...`), identical in
M4's and M5's final gate logs. **The suite is 78 tests and all 78 pass.**

Run 3 is the tree as it closes: every probe removed from `vajb-orbit/tools/`, the code
tree byte-identical to §5's hashes (the only later write was a docs line-wrap
correction in `CONTRACTS.md` §9, which the gate does not read). `vajb-orbit/tools/` ends the pass at the wave's
invariant (`build_theme.gd`, `derive_icon_tints.gd`, their `.uid` sidecars,
`desktop.ini`).

## 3. The four resolutions the dispatch made — verified against, not against the brief

### R3 — `consume_fuel_cell` is bound to **R**, not §11's C

Verified **on disk**, not in a report: `vajb-orbit/project.godot:128-132` binds
`consume_fuel_cell` to `keycode 82` (R), and `:83-87` keeps `cargo_toggle` on
`keycode 67` (C). Measured live through the `InputMap` too (keycodes `[82]` / `[67]`),
and functionally: a real R key event burns exactly one cell, a real **C** key event
burns none. `18_engine_spec.md` §11 still says C, so this is a **recorded deviation**,
not a bug: the spec row is superseded by the owner's ruling and is a spec-edit item.
CONTRACTS §1 now carries R with the ruling cited (see §5).

### R1 — refuel and recharge are free and instant, and no CR rate may exist

Probe B (`_probe_s0m6_services.gd`, `ok=15 failed=0`) measures the shipped code with a
**charged control**, so "credits unchanged" is a measurement and not a blind read:

| Check | Measured |
|---|---|
| `Repairs.refuel` on a partial tank | `ok=true fee=0`, filed fuel **200** (= the fit's `fuel_max`) |
| Credits after refuel | **4321 → 4321** (unchanged) |
| Hull/shield after refuel | **800 / 300**, exactly as filed (a refuel never moves them) |
| Second refuel (full tank) | `{ok:false, reason:&"fuel_full"}` |
| `Repairs.recharge` | `ok=true fee=0 energy_max=100`, credits **4321 → 4321**, vitals unchanged (Energy recomputes at launch) |
| `StationCatalog.SERVICES` rows | both `free: true`, `instant: true`, **no price field** (scanned: no cost/price/rate key) |
| `Repairs` constants | no fuel CR/rate constant exists; `FREE_FEE = 0`; the only rates are the hull/shield **repair** fees of 01 §6 |
| Project-wide token scan | **no** `CR_PER_FUEL` / `per fuel point` / `refuel_cost` / `fuel_price` anywhere in the source |
| **Control**: `Repairs.repair` on a damaged ship | fee **350** charged, credits **4321 → 3971** — the probe can see a charge when one exists |

The tank then persists: the scratch file reads back `save_version 3` with the filed
fuel, i.e. §12 item 13's v3 schema, and **nothing in this pass reintroduced a rate**.

### R2 — the asset tree is the graphics lane's; path failures are deferred, not findings

Measured, and the deferral list has since **emptied**: a scan of every
`res://assets/...` literal in all `.gd` / `.tscn` / `.tres` outside `addons/` finds
**181 literals, 0 unresolvable, 0 files**. The env family healed after M4's review
(`game/pickup.gd`, `game/sector.gd`, `game/game.tscn` carry per-family paths as of
02:11), and the boot gates agree: `game` **exit 0** with only the pre-existing
`invalid UID … using text path instead` warnings (**no `SCRIPT ERROR`; `game.gd`
compiles again**), `menu` clean (M4's `env_menu_bg` error is gone), `settings` clean,
`station` clean apart from the pre-existing **ObjectDB leak** note that M4 also saw.
No asset, no code and no file outside this pass's set was touched; the measurement
was appended to the fallout note as a dated status block (`.agents/`, which every
worker may write).

**Consequence carried forward, unchanged by the measurement:** the Small-rock pickup
burst. M2's rocks probe's one `[BLOCK]` is gone — it now reads
**`ok=25 failed=0 blocked=0`** ("cleave S b: a depleted Small bursts 1-2 pickups |
1 pickup(s) in the world") because `pickup.gd`'s preload resolves again — so the
burst's **spawn** half measures green. The acceptance item still counts as
**unproven end to end**: spawn → drift → collect → cargo is not measured here, and
the ruling that it waits for the graphics lane stands.

**One dev-side note from the measurement, not a finding:** the profile write I saw in
`user://profile.cfg` is the **station boot gate's** market-band roll, proven by
isolation — the universal gate leaves the file byte-identical
(`771 B / c2d10a7efb32`), M6's services probe leaves it byte-identical, and a single
`station.tscn --quit-after 600` run rewrites it (`1678 B / 52a016e84a19`,
`last_band` bumped, **no `fuel` key**, credits and vitals untouched). That is M4's
L17/L18 behaviour, pre-existing. I restored the wave-start record
(`771 B / c2d10a7efb32`) and re-confirmed the final gate leaves it alone. My probes
also appended the expected `REFUEL` / `RECHARGE` / `REPAIR` lines to
`user://economy_log.txt` — the services' own logging, no state changed.

## 4. Every other probe re-run, and what it proves

| Probe | Result this pass | vs M4 | Log |
|---|---|---|---|
| M4's live hull (F2–F5) | **`ok=13 failed=0`**, exit 0 | 8/5 → 13/0 | `slice0_m6_probe_m4_live_after.txt` |
| M6 probe A — hull, key-level fuel cell, reactor chain | **`ok=18 failed=0`**, exit 0 | new | `slice0_m6_probe_hull.txt` |
| M6 probe B — free services, no CR rate, filed tank | **`ok=15 failed=0`**, exit 0 | new (M3's probe sources were not archived) | `slice0_m6_probe_services.txt` |
| M1's flight acceptance | **44 checks, 0 failures**, exit 0 | unchanged | `slice0_m6_probe_m1_flight.txt` |
| M2's pools probe | **`ok=31 failed=0 blocked=0`**, exit 0 | unchanged | `slice0_m6_probe_m2_pools.txt` |
| M2's rocks/cleaving probe | **`ok=25 failed=0 blocked=0`**, exit 0 | 24/0/**1 blocked** → 25/0/0 (the block was the stale `pickup.gd` path, now healed) | `slice0_m6_probe_m2_rocks.txt` |
| Boot gates `game` / `menu` / `settings` / `station` | **all exit 0**; `game` warnings only (invalid UID, text path resolves), `menu`/`settings` clean, `station` the pre-existing leak note | M4's `game` carried a path `SCRIPT ERROR` (a stale `sector.gd` preload) and `menu` a missing-`ext_resource` parse error, both since healed | `slice0_m6_boot_{game,menu,settings,station}.txt` |

**M3's three probes (`station` 26/0, `hud` 23/0, `game` 14/0) were not re-run: their
sources were not archived**, so only the halves I could reach were re-measured —
services, persistence and the catalogue, by probe B above. That is not a gap in
coverage of *this* pass's risk surface: the files those probes measure are
**byte-identical to what M4 measured green** (`ui/hud/hud.gd` `f72eedaac0d7`,
`game/game.gd` `4fbcac310b25`, `autoload/player_profile.gd` `f744d0ea0acc`,
`game/repairs.gd` `d70f9b3a69c0`, `game/station_catalog.gd` `239a92a6adaa` — all
re-hashed here and unchanged since 01:43–01:49), and this pass's only code deltas are
`player_ship.gd` and one digit in `test_p1_profile.gd`.

## 5. Files: what changed, and my CONTRACTS pen

Measured md5s (first 12) on the frozen tree. Everything M4 published reproduces
except the two files the fixer pass was allowed to touch:

| File | M4 | Now | Note |
|---|---|---|---|
| `game/player_ship.gd` | 26 093 · `de16ff6528a0` | **30 880 · `3c40642034d6`** | the fixer pass; 5 additive hunks (below) |
| `tests/test_p1_profile.gd` | 14 440 · `af4e6f305ab1` | **14 440 · `6a9e4fa06977`** | one line, size unchanged |
| `game/ship_fit.gd` | `4f0f19662ecd` | `4f0f19662ecd` | **untouched**, as M5 claimed |
| `game/player_state.gd` · `impact.gd` · `ship_stats.gd` · `player_ship.tscn` · `asteroid.gd` · `asteroid_field.gd` · `repairs.gd` · `station_catalog.gd` · `autoload/player_profile.gd` · `ui/hud/hud.gd` · `game/game.gd` · both new test files | — | **all identical** to M4's hashes | nothing else moved in this wave |
| `game/pickup.gd` | not in M4's set | `920016bbe383` (02:11) | the graphics lane's re-path, not a slice-0 edit |
| `docs/CONTRACTS.md` | 22 762 | **24 813 · `565bfff342ea`** | this pass (see below) |

The whole fix diff, isolated by differencing the archived pre-fix hull against the
current one (`.agents/gen/slice0_m6_fixdiff_player_ship.txt`, 5 hunks): the
`FUEL_CELL_ACTION` const; `BOOST_FUEL`/`DASH_FUEL` as the hull's consts; the raw-stick
/ gated-throttle split plus `_thrust_locked()` and the autopilot's zeroed
`desired_speed`; the boost burn + arm charge in `_update_boosters` and
`_burn_boost_fuel`; `_step_reactor` and `_update_fuel_cell` in `_physics_process`.
**No pinned signature changed** — `setup`, `set_move_target`, `cancel_orders`,
`warp_available`, every `PlayerState` signature and the `Impact` statics are intact
(M1's acceptance probe re-run covers the hull's API at 44/0).

**CONTRACTS.md (this worker's pen; the only docs file in my set)** — the dispatch says
to touch the changelog only if a fix changed a pinned interface. Three pins did change
state, so I corrected them and recorded it, and nothing else:

- **§1** — `consume_fuel_cell` moves C → **R** with ruling R3 cited (the input map is a
  pinned interface and §1 named a key that is not on disk), and the measured note now
  reads the landed bindings plus the caller.
- **§4** — the reactor-chain paragraph's "none of that is wired yet" becomes the
  before/after measurements, because a future worker coding against "not wired" would
  re-do the fixer's work.
- **§8.1** — `BOOST_FUEL`/`DASH_FUEL` ownership: the false "no shipping-code owner yet"
  becomes `PlayerShip`.
- **§9** — the expected gate is the measured `passed=78 failed=0` (three runs), with
  F1's cause and its one-line repair recorded.
- **§10** — a **v0.1.1** changelog entry naming the above and stating explicitly that
  no pinned signature changed.

`.agents/gen/asset_path_fallout.md` gained a dated measured status block (§3/R2).
Nothing else was written outside `.agents/`: no slice-0 source, no test, no asset, no
`project.godot`.

## 6. Wave-close statement

**Engine slice 0 (physics & fuel) is verifiably closed.**

- **Gate:** `passed=78 failed=0`, exit 0, no `SCRIPT ERROR` — measured three times,
  the last on the frozen tree. The suite is 78 tests; the wave's single red (F1) was
  a one-line stale assertion, now `save_version 3`.
- **Findings:** F1 (HIGH) fixed; F2, F3, F4, F5 (MED) fixed and re-measured by this
  worker with before/after numbers, including on M4's own probe (`8/5` → `13/0`);
  F6 closed by this dispatch (probes written with the `write` tool, no shell
  fallback). No fix invented a number: every constant traces to a §13 row or a
  §2.1/§4.4 ruling, and no pinned interface changed.
- **Owner rulings honoured:** refuel/recharge are free and instant and **no CR rate
  exists anywhere** (measured, with a charged control); the asset tree is the graphics
  lane's and the deferral is now empirically **empty** (0 of 181 literals
  unresolvable) — the Small-rock pickup burst's spawn half measures green but the
  acceptance stays unproven end to end; `consume_fuel_cell` is **R** on disk, with
  §11's C recorded as a superseded spec row.
- **Still open, owned by the owner, untouched by this pass:**
  1. **F7** — `18_engine_spec.md` §2.1 ruling 13, §4.4 and §12 item 8 still sell fuel
     for CR; the owner strikes those three lines in their own spec pass.
  2. **§13 speed table v2 (ruling 26)** — the Cutter 700 / Miner 380 / Frigate 450
     interpolations (and their turn rates) are unticked; no test may bake v2 until the
     owner ticks them.
  3. **§11's "C"** — the same pass should record R.
- **Environment, measured and not a finding:** the station boot gate rewrites the dev
  profile's market band on every run (pre-existing, L17/L18); the wave-start record
  was restored (`771 B / c2d10a7efb32`) and the final gate leaves it byte-identical.

## 7. Deviations of this review

- **D1 — archived probes were restored by byte copy, my own probes were written with
  the `write` tool.** M4's, M1's and M2's probe sources were copied out of
  `.agents/gen/` (they are archived there, and byte-exactness matters more than the
  route for re-running someone else's measurement); the four files this pass authored
  were created with `write` in `vajb-orbit/tools/`, which is exactly what F6 asked
  for — **no hook denial, no shell fallback**. All ten probe files were removed from
  `tools/` afterwards and my four are archived at
  `.agents/gen/slice0_m6_probe_{hull.gd,hull.tscn,witness.gd,services.gd}`.
- **D2 — two of my own probe checks were wrong first and are fixed in the recorded
  logs.** (a) Probe B's price-key filter matched `description` (it contains "cr");
  narrowed to whole names (`cost`/`price`/`rate`/`fee`/`credits` and their
  affixes) — the final log is the corrected run. (b) My first four boot-gate commands
  passed `res://vajb-orbit/...`, so all four failed to load the scene and exited 1;
  re-run with project-relative paths all four exit 0, and the corrected runs
  **overwrote** those logs, so the bad ones are not on disk. Neither wrong check was a
  code defect, and both were caught by the probe itself failing loudly.
- **D3 — M3's probe sources are not archived**, so its station/HUD/game probes could
  not be re-run; §4 records the byte-identity argument that carries M4's green result
  forward, and probe B covers the services/persistence halves this pass needed.
- **D4 — one dev-profile observation needed isolation to attribute** (§3/R2): three
  runs (gate, my services probe, a single station boot gate) were made against a
  restored byte-identical profile to prove which actor writes it. That is the only
  reason the gate was run three times rather than two.
