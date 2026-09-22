# P2-B proper — R1 review report (2026-09-22)

**Role:** R1, the mandatory reviewer of wave P2-B proper (the FITTING surface). **I fixed nothing.**
**Files I added:** `vajb-orbit/tests/probe_r1_v5_migration.gd`/`.tscn`/`.uid`,
`vajb-orbit/tests/probe_r1_fit_profile.gd`/`.tscn`/`.uid`, `vajb-orbit/tests/probe_r1_fit_panes.gd`/`.tscn`/`.uid`
(R1's declared set is `vajb-orbit/tests/, vajb-orbit/tools/`), plus this report and the evidence bundle
`.agents/gen/p2b_proper_r1_*.txt`. Nothing else was written; no shipped file, doc or asset was touched.
`vajb-orbit/project.godot` is byte-identical to HEAD after my bounded `--headless --editor --quit` uid pass.

**The gate I measured myself, twice, on two scratch `XDG_DATA_HOME` roots: `[SUMMARY] passed=431 failed=0`,
exit 0.** That is `1f794cc`'s 389 plus the wave's own 13 + 18 + 11 = 42, and it reproduces W1's, W2's and W3's
figures exactly. Against a byte copy of the owner's live profile the same tree reads **`passed=428 failed=3`** (W1's pre-wave
live baseline, 386, plus the wave's own 42; the three failures are pre-existing and data-dependent, LOW-6
below). The owner's
`user://profile.cfg` was **not** written by any run of this review: md5
`9a04bea68fbe90c4d017e66245ceee7e` before and after every probe, suite and gate (evidence
`p2b_proper_r1_probe_reruns.txt`).

**Verdict: no HIGH. Two MED (each a one-pass fix, one of them needing a one-sentence CONTRACTS amendment),
and eight LOW that ride to `.agents/gen/LOW_BACKLOG.md` (L85–L92).** Every one of the wave's §3 deliverables
is present and measured; the wave's numbers are 09's and 08's own and none moved. The wave is green by count
*and* by log: the only surviving `SCRIPT ERROR` line is the pre-existing `tests/test_weapon_fx_f4.gd` freed
instance (L61), which is in every HEAD-era log.

---

## 1. What I re-ran and what I built

| # | Measurement | Command | Result |
|---|---|---|---|
| 1 | The gate, twice, sandboxed | `XDG_DATA_HOME=<scratch> godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` | `passed=431 failed=0 ×2`, exit 0, one pre-existing `SCRIPT ERROR` |
| 2 | The gate against a byte copy of the live profile | the same, `XDG_DATA_HOME=/tmp/r1_live` with `profile.cfg` copied in | `passed=428 failed=3`, exit 1 — the same three W1 reported pre-wave |
| 3 | W1's two probes, byte-identically | `res://tests/probe_w1_type_hole.tscn`, `probe_w1_lint.tscn --debug` | 6 and 20 marker lines, **zero diff** |
| 4 | W2's two probes, byte-identically | `probe_w2_fitting.tscn` (68 lines), `probe_w2_lint.tscn --debug` (14) | **zero diff** |
| 5 | W3's two probes, byte-identically | `probe_w3_services.tscn` (36), `probe_w3_services_lint.tscn --debug` (14) | **zero diff** |
| 6 | The three new suites, alone | `-- --suite=test_p2b_retirement|test_p2b_fitting_panel|test_p2b_services` | `13/18/11`, all `failed=0` |
| 7 | **My own v4 fixture** → the flag day | `python3`-free: the fixture is written by my probe's own `ConfigFile` calls (Array *and* Dictionary spellings), and by hand as text for the boot case | §3 below |
| 8 | The flag day on a **real boot** | `XDG_DATA_HOME=/tmp/r1_boot godot --headless --path vajb-orbit res://ui/screens/boot.tscn --quit-after 400` | the hand-written v4 file came back v5 with the six modules, zero `upgrade` tokens, zero errors, exit 0 |
| 9 | The transactions, from a throwaway profile instance | `godot --headless --path vajb-orbit res://tests/probe_r1_fit_profile.tscn --quit-after 600` | §4 below |
| 10 | The panes, mounted from the shipped scenes | `godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600` | §5 below |
| 11 | The two audit tools + the frozen-file check | `python3 vajb-orbit/tools/r1_p2b1_signature_audit.py`, `r1_p2b1_format_law.py`, `git diff --stat -- <frozen files>` | 27 signatures / 0 drift, 21 format checks / 0 failures, no frozen file touched |

Every probe I wrote carries its own hard bound: `FRAME_CAP` (quits the run at 600 frames) plus a `LOOP_CAP`
of 64–128 on every iteration, *and* `--quit-after` on the command line (L82's lesson). Both probes exit 0
with no `SCRIPT ERROR`.

**Where the evidence lives:** `p2b_proper_r1_gate.txt` (both gate runs),
`p2b_proper_r1_gate_raw.txt` (the full 479-line gate log), `p2b_proper_r1_gate_livecopy.txt` (the live-profile
copy and the bisect), `p2b_proper_r1_probe_reruns.txt` (the six byte-identical re-runs and the three suites),
`p2b_proper_r1_migration_probe.txt`, `p2b_proper_r1_boot_migration.txt`, `p2b_proper_r1_profile_probe.txt`,
`p2b_proper_r1_panes_probe.txt`, `p2b_proper_r1_audits.txt`.

---

## 2. The gate, and the three live-profile failures

```text
$ XDG_DATA_HOME=/tmp/r1_sandbox godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
479:[SUMMARY] passed=431 failed=0                       # exit 0
$ XDG_DATA_HOME=/tmp/r1_sb2     godot --headless ... --quit-after 1200
479:[SUMMARY] passed=431 failed=0                       # exit 0, second scratch root
$ rg -n "SCRIPT ERROR" <either log>
469:SCRIPT ERROR: Cannot call method 'call' on a previously freed instance.   # tests/test_weapon_fx_f4.gd, L61, pre-existing
```

The log's other exit-0 noise is pre-existing too, and I checked it against W1's pre-wave log rather than
assuming it: `ERROR: Parameter "data.tree" is null.` (`at: get_tree (scene/main/node.h:559)`) and
`WARNING: EconomyLog: could not open user://p1l_missing_dir_do_not_create/…` are both in
`p2b_proper_w1_gate_before_sandbox.log` as well. **No new error, warning or leak line is attributable to this
wave.**

Against the live profile copy:

```text
$ XDG_DATA_HOME=/tmp/r1_live godot --headless ... --quit-after 1200
57:[FAIL] test_engine2_dock.gd.test_a_settle_charges_the_rounds_fired_since_the_last_one: the first settle charges its three (300 -> 300)
58:[FAIL] test_engine2_dock.gd.test_the_dock_report_is_idempotent_within_one_launch: the launch seeded the live pack from the store (300 of 300)
71:[FAIL] test_engine2_fixes.gd.test_the_dock_report_settles_a_fired_pack: the launch seeded the live pack from the store (300 of 300)
479:[SUMMARY] passed=428 failed=3                        # exit 1
```

and the bisect that proves it is the profile, not the code:

```text
$ XDG_DATA_HOME=/tmp/r1_sb2  godot --headless ... -- --suite=test_engine2_dock   → passed=2  failed=0
$ XDG_DATA_HOME=/tmp/r1_live godot --headless ... -- --suite=test_engine2_dock   → passed=0  failed=2   (the two above)
$ XDG_DATA_HOME=/tmp/r1_sb2  godot --headless ... -- --suite=test_engine2_fixes  → passed=17 failed=0
$ XDG_DATA_HOME=/tmp/r1_live godot --headless ... -- --suite=test_engine2_fixes  → passed=16 failed=1
```

Both suites pass on a fresh account and fail on the owner's own fit; neither suite, `game/game.gd` nor
`game/player_state.gd` is in this wave's diff, and W1's pre-wave log on the same tree state reads
`passed=386 failed=3` with the identical three lines. The arithmetic closes: 386 + 42 = 428 (live), 389 + 42 =
431 (sandbox). This is LOW-6, not a wave finding.

---

## 3. The save v5 flag day (my own fixtures)

**Probe 1 — `probe_r1_v5_migration.tscn`** (fixtures written by the probe itself, both `upgrades` spellings):

```text
[R1-MIGRATION] table size=6
[R1-MIGRATION] row 0 upgrade_generator -> p_mk2 (shipped=p_mk2)
[R1-MIGRATION] row 1 upgrade_shield -> s_heavy (shipped=s_heavy)
[R1-MIGRATION] row 2 upgrade_engine -> e_ion (shipped=e_ion)
[R1-MIGRATION] row 3 upgrade_module -> c_scanner (shipped=c_scanner)
[R1-MIGRATION] row 4 upgrade_extra -> u_cargo (shipped=u_cargo)
[R1-MIGRATION] row 5 upgrade_drone -> u_drones (shipped=u_drones)
[R1-MIGRATION] v4 load: modules=6
[R1-MIGRATION] v4 successor p_mk2 count=1 (retired upgrade_generator count=0)     … one line per successor, all six at 1 and all six retired ids at 0
[R1-MIGRATION] v4 credits=4321 (the rest of the file reads as it always did)
[R1-MIGRATION] a v5 file loads as 6 records and has 0 left to migrate
[R1-MIGRATION] v4 second call answers 0, a second load reads 6 records            ← idempotence: 6, never 12
[R1-MIGRATION] v4 on disk: save_version=5 upgrades_key=false module_records=6     ← the one-way door wrote itself
[R1-MIGRATION] dict spelling: migrated=0 modules=1 e_ion=1 s_heavy=0              ← a Dictionary of flags migrates truthy keys only
[R1-MIGRATION] v1 fixture: credits=4321 modules=2 e_ion=1 p_mk2=1
[R1-MIGRATION] v3 fixture, no record: credits=4321 modules=0 migrate=0
[R1-MIGRATION] v3 on disk stays save_version=3 (nothing to migrate, so no rewrite)
[R1-MIGRATION] v5 fixture: modules=0 migrate=0
[R1-MIGRATION] v5 with a stale record: modules=0 (the `version < 5` gate held)
[R1-MIGRATION] v5 with a stale record, migration called by hand: 1 -> u_drones=1
[R1-MIGRATION] profile instance methods present: has_upgrade=false installed_upgrades=false install_upgrade=false
[R1-MIGRATION] profile constants: KEY_UPGRADES=false KEY_RETIRED_UPGRADES=true LEGACY_UPGRADE_MODULES=true EVENT_FIT_MODULE=true
[R1-MIGRATION] save version constants: SAVE_VERSION=5 MIN_READABLE_VERSION=1
[R1-MIGRATION] StationCatalog constants: UPGRADES=false UPGRADE_SLOTS=false
[R1-MIGRATION] the six successors are catalogue modules: p_mk2=true, s_heavy=true, e_ion=true, c_scanner=true, u_cargo=true, u_drones=true
[R1-MIGRATION] the six retired ids are not module ids: upgrade_generator=true, … upgrade_drone=true
```

Every claim in the brief's rule 2 and CONTRACTS §13 rule 2 holds, on my fixtures. The `v5-with-a-stale-record`
case is not reachable from a shipped writer (a v4 build writes 4) and is only recorded so the `version < 5`
gate is visible.

**Probe 1b — the same fixture as text, booted through the real game:**

```text
$ cat > /tmp/r1_boot/godot/app_userdata/"Vajb Orbit"/profile.cfg <<'EOF'
[profile]

save_version=4
credits=4321
owned_ships=["ship_vanguard"]
active_ship="ship_vanguard"
upgrades=["upgrade_generator", "upgrade_shield", "upgrade_engine", "upgrade_module", "upgrade_extra", "upgrade_drone"]
EOF
$ XDG_DATA_HOME=/tmp/r1_boot godot --headless --path vajb-orbit res://ui/screens/boot.tscn --quit-after 400
# exit 0, zero SCRIPT ERROR / WARNING / ERROR lines
$ rg -n upgrade <the file after>          → exit 1 (no token)
$ head -40 <the file after>
[profile]
save_version=5
credits=4321
owned_ships=["ship_vanguard"]
active_ship="ship_vanguard"
cargo={…} ammo={…}
modules={ "c_scanner": {count 1}, "e_ion": …, "p_mk2": …, "s_heavy": …, "u_cargo": …, "u_drones": … }
```

So the flag day is one-way, it writes itself through the real boot path, the account's credits survive, and
the six installed legacy upgrades become exactly six inventory modules (one each). The migration's write
rides the 0.5 s debounce and a test-only run quits inside that window, which is why a real boot is the
instrument (W1's own note, reproduced).

---

## 4. The two composed transactions (`probe_r1_fit_profile.tscn`)

Throwaway `Profile.new()` instances, scratch `save_path` *and* a scratch economy-log path, so neither the
owner's profile nor `user://economy_log.txt` is touched.

```text
[R1-PROFILE] hull=ship_fighter grid_counts={ engines 1, weapons 2, shields 1, armour 1, computers 1, boosters 1, utility 0, power 1 } power_out(fit_legal)={ out 6, draw 4, spare 2, legal true }
[R1-PROFILE] delivered fit: weapons=["w_laser", "w_laser"] engines=["e_std"] power=p_std shields=["s_light"]
[R1-PROFILE] fit_for(NPC ship_swarmer)={  }
[R1-PROFILE] install into W2 (index 1): ok=true weapons ["w_laser", "w_laser"] -> ["w_laser", "w_cannon"] cannon=0 laser=4
[R1-PROFILE] engine and power cells untouched: engines=["e_std"] power=p_std
[R1-PROFILE] the install's log lines: total=1 fit_module=1
[R1-PROFILE] the install's signals: [&"modules", &"modules", &"fits"]
[R1-PROFILE] W1 laser -> cannon: ok=true weapons=["w_cannon", "w_laser"] laser=3 cannon=1
[R1-PROFILE] W1 cannon -> laser (the swap): ok=true weapons=["w_laser", "w_laser"] laser=2 cannon=1
[R1-PROFILE] the displaced cannon came back at 1 (0 would be a lost module)
[R1-PROFILE] remove the delivered shield: ok=true shields=[""] laser=1
[R1-PROFILE] removing an already-empty cell answers false (no second write)
[R1-PROFILE] MANDATORY_SLOT_KEYS=[&"engines", &"power"] (the pin reads FitData, not a copy)
[R1-PROFILE] clear engines[0]=false clear power=false fit unchanged=true
[R1-PROFILE] the swap that is allowed: true
[R1-PROFILE] engines=["e_ion"] e_std back in the inventory=1 power=p_std
[R1-PROFILE] a reactor swap is allowed too: true -> power=p_mk2 p_std=1
[R1-PROFILE] fighter W capacity=2 utility capacity=0
[R1-PROFILE] guard index == capacity -> false            (then: index –1, utility-on-the-fighter, unknown slot key,
[R1-PROFILE] guard unknown hull -> false                   unknown hull, an NPC hull, an unowned module, an
[R1-PROFILE] guard an empty module id -> false              empty id — all eight false)
[R1-PROFILE] every guard refused without a write: fit unchanged=true new lines=0
[R1-PROFILE] plasma into W1: ok=true weapons=["w_plasma", "w_laser"] power={ out 6, draw 6, spare 0, legal true }
[R1-PROFILE] plasma into W2: ok=false (candidate power={ out 6, draw 8, spare -2, legal false } over_by=2)
[R1-PROFILE] the refused call wrote nothing: weapons=["w_plasma", "w_laser"] plasma=1 new lines=0
[R1-PROFILE] one success writes 1 line(s):
[R1-PROFILE]   2026-09-22T14:59:33, FIT_MODULE, w_cannon, 1, +0, 10000
[R1-PROFILE] the success's signals in order: [&"modules", &"modules", &"fits"]
[R1-PROFILE] the refused install emits nothing: []
```

Read against CONTRACTS §13: the guards fire in the pinned order and *before* any write; the displaced module
returns before the take (a swap cannot lose it); one `EVENT_FIT_MODULE` line per success with the pinned
shape (`w_cannon, 1, +0, balance`); both keys signal, and the refusal path signals nothing; `clear_fit_slot`
refuses every `FitData.MANDATORY_SLOT_KEYS` cell while allowing an engine and a reactor **swap** (the
replacement is taken and the delivered `e_std`/`p_std` comes back). The pin's own over-budget case is
reproduced with the Fighter's numbers: a candidate of 8 against 6, `spare = -2`.

---

## 5. The panes (`probe_r1_fit_panes.tscn`)

### 5.1 The rail swap, the retirement, and the catalogue

```text
[R1-PANES] rail enum=["OUTFITTING", "REFINERY", "EXCHANGE", "SHIPYARD", "FITTING", "REPAIRS", "LAUNCH"] (FITTING present=true, UPGRADES present=false)
[R1-PANES] rail labels=["OUTFITTING", "REFINERY", "EXCHANGE", "SHIPYARD", "FITTING", "REPAIRS", "LAUNCH"]
[R1-PANES] rail files=["outfitting", "refinery", "exchange", "shipyard", "fitting", "repairs", "launch"]
[R1-PANES] entry 4: label=FITTING file=fitting icon=res://assets/icons/equip/icon_equip_generator_48.png tinted=false bed=amb_station_noise_loop_01
[R1-PANES] retired files on disk: upgrades_panel.gd=false .tscn=false ; fitting pane: .gd=true .tscn=true
[R1-PANES] StationCatalog constants: UPGRADES=false UPGRADE_SLOTS=false SHIPS=true SERVICES=true
[R1-PANES] shell rail entries: ["OutfittingEntry=OUTFITTING", … "FittingEntry=FITTING", "RepairsEntry=REPAIRS", "LaunchEntry=LAUNCH"]
[R1-PANES] shell panes under HostMargin: ["Outfitting", "Refinery", "Exchange", "Shipyard", "Fitting", "Repairs", "Launch"]
[R1-PANES] shell has Fitting=true Upgrades=false
```

`git show HEAD:…/station.gd` compared by hand: **only** `MODULE_FILES[4]` and `MODULE_LABELS[4]` changed —
`MODULE_ICONS[4]` (the retired generator icon), `MODULE_TINTED[4]` (`false`) and `MODULE_BEDS[4]`
(`amb_station_noise_loop_01`, STATION_HUB §11) are byte-identical, and **nothing else in the rail moved**.
The retired pane files are gone from disk, the catalogue no longer declares `UPGRADES`/`UPGRADE_SLOTS`, and a
tree-wide token scan (`res://**/*.gd`, `*.tscn`, `addons/` and `.godot/` excluded, 235 files) finds **zero live
references** to `has_upgrade`, `installed_upgrades`, `install_upgrade`, `Catalog.upgrade`, `UPGRADES`,
`UPGRADE_SLOTS`, `upgrades_panel` or `upgrade_ids` outside (a) the migration's own key name and
`_legacy_upgrade_ids` helper, (b) comments in `player_profile.gd`/`station_catalog.gd`/`station.gd` that
record the retirement, (c) the tests that guard it, and (d) the retired Phase C mockup (LOW-3).

### 5.2 The grid, and the shipyard's own recipe

```text
[R1-PANES] FITTING grid: cells=16 gaps=5 columns=4 h_sep=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[R1-PANES] shipyard grid: cells=16 columns=4 h_sep=4 caption=SLOT LAYOUT · 11 CELLS · 1 ENGINES
[R1-PANES] the two grids agree on 16 of 16 cells' cell size
[R1-PANES] a FITTING cell: class=Button variation=SlotButtonWeapon focus=2 toggle=true disabled=false min=(48.0, 48.0)
[R1-PANES] the cell's focus ring: StyleBoxFlat border=1 colour=(0.9098, 0.3843, 0.1647, 1.0)
[R1-PANES] the grid's first child is a gap Control: Control
```

The Vanguard's 08 §3.2 matrix (`.WW.`/`HSCB`/`HWU.`/`.EP.`) is 16 cells with 5 gaps, 4 columns, 11 plates at
48 px, caption `SLOT LAYOUT · 11 CELLS · 1 ENGINES` (08 §3's Total, gaps not counted) — and the two grids
agree cell for cell, with the one intended difference (W2's own probe, re-run byte-identically: the FITTING
cell is a `FOCUS_ALL` `Button` carrying the theme's `SlotButtonWeapon` art and the shared focus ring; the
shipyard's is a `disabled` `TextureButton` with `FOCUS_NONE`).

### 5.3 The pinned wordings and the meter, against `ShipFit.fit_legal`

```text
[R1-PANES] pinned wordings checked=17 mismatches=0 []
[R1-PANES] idle: pane=PWR 3 / 8 fit_legal={ out 8, draw 3, spare 5, legal true } expected=PWR 3 / 8 equal=true
[R1-PANES] candidate: pane=PWR 3 / 8 · CANDIDATE 4 / 8 fit_legal={ out 8, draw 4, … } expected=… equal=true
[R1-PANES] one plasma installed: weapons=["w_plasma", "w_laser"] power={ out 6, draw 6, spare 0, legal true }
[R1-PANES] over budget: pane=PWR 6 / 6 · CANDIDATE 8 / 6 — OVER BY 2 expected=… equal=true danger_colour=true
[R1-PANES] danger colour=(0.7843, 0.2784, 0.1216, 1.0) Tokens/accent_danger=(0.7843, 0.2784, 0.1216, 1.0) equal=true
[R1-PANES] the over-budget press refuses: footer=8 / 6 PWR — OVER BY 2 danger=true strip=8 / 6 PWR — OVER BY 2
[R1-PANES] the refused over-budget call wrote nothing: weapons=["w_plasma", "w_laser"] plasma=1
[R1-PANES] rows: shipped=[&"w_laser", &"w_cannon", &"s_heavy", &"u_cargo"]
[R1-PANES] rows: expected=[&"w_laser", &"w_cannon", &"s_heavy", &"u_cargo"] equal=true
[R1-PANES] a row's cells: title=Laser MkII meta=SLOT WEAPONS · DRAW 1 owned=OWNED ×1 action=SELECT A CELL
[R1-PANES] empty state: rows=1 text=NO MODULES OWNED · BUY THEM IN OUTFITTING disabled=true pinned=true
```

I did not take the pane's own constants on trust: my probe re-derives the expected string for each meter form
from `fit_legal`'s `power` dictionary (idle, candidate, over-budget) and compares, and it re-derives the
OWNED MODULES order from `ModuleCatalog.MODULES` walked in `FitData.FIT_SLOT_KEYS` order. **17 pinned
constants match the pin character for character** (`ACTION_FIT/SWAP/SELECT A CELL`, `METER_IDLE`,
`METER_CANDIDATE`, `METER_OVER`, `REFUSAL_OVERLOAD`, `REFUSAL_MANDATORY`, `REFUSAL_FIT_ILLEGAL`,
`EMPTY_ROW`, `SELECTION_FORMAT`, `CELL_EMPTY`, `META_FORMAT`, `OWNED_FORMAT`, `HARDPOINT_CAPTION`,
`ACTIVE_HULL`, `OWNED_CAPTION`). The over-budget form is 09 §2's own arithmetic shape
(`8 / 6 PWR — OVER BY 2`) in the danger token, and the refusal beside it carries the same numbers.

### 5.4 The per-cell actions and the mandatory refusal

```text
[R1-PANES] W2 selected (holds ): cannon ACTION=FIT laser ACTION=FIT
[R1-PANES] after the row press: weapons=["w_laser", "w_cannon", ""] (cell 0 untouched=true) cannon=0 laser=2
[R1-PANES] the swapped-in cell reads W2 · CANNON MKI · OWNED ×0; the selection survived as { type weapons, token W, index 1 }
[R1-PANES] swap into W1 (held a laser): weapons=["w_cannon", "", ""] laser 2 -> 3 cannon=0
[R1-PANES] E1 selected (holds e_std): can_remove=true remove_selected=false
[R1-PANES] footer=MANDATORY CELL — SWAP ONLY, NEVER EMPTY danger=true strip=MANDATORY CELL — SWAP ONLY, NEVER EMPTY engines=["e_std"]
[R1-PANES] the profile underneath refuses it too: false
[R1-PANES] REMOVE on the delivered shield: true shields=[""] s_light back=1
```

A row press targets **that** cell (W1/W3 untouched), a swap returns the displaced laser, the mandatory cell
answers the pin's exact wording in the footer *and* the shell strip in the danger colour while the fit stays
untouched, and an ordinary filled cell empties through the composed remove with its module back.

### 5.5 The shipyard's hover line, and the two service rows

```text
[R1-PANES] hover fitted=W1 · LASER MKII · OWNED ×3
[R1-PANES] hover empty=W2 · EMPTY · OWNED ×0
[R1-PANES] hover gap= (a gap carries no line)
[R1-PANES] after a fit write, W2 hovers as W2 · LASER MKII · OWNED ×2     ← read live, no refresh key needed
[R1-PANES] a hull with no stored fit: W1 · EMPTY · OWNED ×0
[R1-PANES] FREE_FEE=0 fuel pool=200 energy pool=100
[R1-PANES] REFUEL: strip=FUEL_MAX 200 danger=false fuel=200 credits 10000 -> 10000
[R1-PANES] REFUEL label=REFUEL (catalogue name=REFUEL)
[R1-PANES] RECHARGE: strip=ENERGY_MAX 100 danger=false label=RECHARGE (catalogue name=RECHARGE)
[R1-PANES] full tank: strip=FUEL_FULL danger=true credits 10000 -> 10000 fuel=200 disabled=false
[R1-PANES] the service's own full-tank result={ "ok": false, "reason": &"fuel_full" }
[R1-PANES] no report: strip=NO_DAMAGE_REPORT danger=true
[R1-PANES] DECK CONTROL children: ["0:ActionCaption", "1:HullFrame", "2:ServiceRow", "3:LaunchButton", "4:ConfirmStrip"]
```

Both services call `Repairs`' own functions, render the service's own result key with its figure, move no
credits, print no price, keep the button pressable through a refusal, and render the full tank as the
service's own `fuel_full` reason in `Tokens/accent_danger` (identical to the token). The buttons' labels are
`StationCatalog`'s own `name` values, and LAUNCH stays the last, lowest control.

---

## 6. The drift checks

- **The pin's signatures.** `r1_p2b1_signature_audit.py`: **27 signatures, 0 drift** — every §11 API
  (`grid_rows` … `mount_offset`), every §11 `PlayerProfile`/`PlayerState`/HUD/`ModuleCatalog` name, §12's
  `buy_module`, and §13's `clear_fit_slot`/`retire_legacy_upgrades`. Its blind spot (LOW-4) is `fit_module_at`,
  which I verified by hand against §13: the shipped signature is
  `func fit_module_at(ship_id: StringName, slot_key: StringName, index: int, module_id: StringName) -> bool`
  — the pin's parameters, in the pin's order, line-broken only.
- **The pinned formats.** `r1_p2b1_format_law.py`: **21 checks, 0 failures**, including §12's two refusal
  wordings rendered as `13 / 11 PWR — OVER BY 2` and `"W SLOTS FULL — SWAP OR REMOVE FIRST"`.
- **The mandatory-key law.** `rg -n FIT_MANDATORY_KEYS vajb-orbit/` → no output (the constant the prompts
  named does not exist; D0's drift note 1 holds). Every guard reads the one source: `FitData.MANDATORY_SLOT_KEYS`
  (`autoload/player_profile.gd:537`) and `ShipFit.MANDATORY_SLOT_KEYS` (`ui/station/fitting_panel.gd:321`) are
  the same script, and no copy of the list exists anywhere.
- **No 09 or 08 number moved.** `git diff --stat` over `game/ship_fit.gd`, `game/module_catalog.gd`,
  `game/player_state.gd`, `game/game.gd`, `game/repairs.gd`, `project.godot`, `ui/theme/`, `assets/`,
  `addons/` and `docs/gameplay/08_ship_classes.md` is **empty** — every frozen file is byte-identical to HEAD.
  The catalogue is unchanged, so I checked it against 09 anyway: **31 of its 32 rows match 09 §3's tier, draw
  and cost exactly**, and `w_mining` (the 32nd) matches 09 §4 item 7's prose (Tier I, draw 1, cost 600). The
  docs diffs are additive only — 09 gains §4 items 9–13 and the §7 note, 10 §6 gains four lines, 15 §6 gains
  the dated next-wave note, and **no numeric line changed in any of them**.
- **The new constants.** Every constant the wave adds is a string, a key name or a presentation number
  (`SERVICE_ROW_HEIGHT` 56, the EXCHANGE pane's own secondary height, with a documented reversal; the row
  separations; the glyph paths). **No cost, draw, capacity, cell count or refusal wording is invented** — all
  of them are 09's, 08's, §5.1's or the pin's.
- **The frozen surfaces.** No `assets/**`, no theme, no `project.godot`, no `addons/**` in the wave's diff;
  `docs/**` is D0's alone.

---

## 7. Findings

### MED-1 — the pane previews one fit and the profile commits against another, so the surface is dead on any hull with no stored fit

**Tier: MED** (one fixer pass *after* a one-sentence CONTRACTS §13 amendment; W2 measured it, I re-measured
it independently and extended it to the two-hull case).

```text
$ XDG_DATA_HOME=/tmp/r1_probe_sb godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600 | rg 'unfit hull'
[R1-PANES] unfit hull: stored fit holds a module=false action=SWAP meter=PWR 4 / 6 · CANDIDATE 4 / 6
[R1-PANES] unfit hull: install through the pane=false footer=REFUSED · FIT ILLEGAL
[R1-PANES] unfit hull: the stored candidate fit_legal={ &"legal": false, &"overflow": {  }, &"missing": [&"engines", &"power"], &"duplicates": [], &"power": { &"out": 6, &"draw": 0, &"spare": 6, &"legal": true } }
```

The pane resolves `_resolved_fit` = `fit_for` **falling back to `ShipFit.standard_fit`** (the fit the launch
flies), so it previews a legal, fully-powered fit and offers `FIT`/`SWAP`; `fit_module_at` composes its
candidate from the **stored** fit (`fit_for(ship_id)` with one cell set, CONTRACTS §13 verbatim), which for an
unfit hull is `missing = [engines, power]`, so it refuses and the player reads `REFUSED · FIT ILLEGAL`.
§13 rule 6's promise — "the pane calls `fit_legal` … the profile re-checks on commit. Both read the same
function" — holds for the *function* but not for the *candidate*, and on this path the two disagree.

**Reachability.** Every hull the account buys in SHIPYARD arrives with no stored fit (09 §7's bare hulls; the
only writers that materialise one are OUTFITTING's `_seed_fit` and the tests), so after `SET ACTIVE` on a new
hull FITTING cannot install anything until the player first presses INSTALL in OUTFITTING. The owner's own two
hulls both carry stored fits, so their live surface works — which is why this is MED and not HIGH, and why the
workaround exists. It is not a regression: FITTING is new in this wave.

**Either cure needs one sentence in §13 first** (that is why I did not tier this as a one-pass code fix):
(a) profile-side — `fit_module_at`/`clear_fit_slot` compose their candidate from the fit the launch would fly
(`fit_for`, else `ShipFit.standard_fit`, the same resolution `game.gd:_launch_fit_for` and the pane already
use) — §13's `fit_module_at` comment and 09 §4 item 9 both spell out the stored-fit candidate, so the doc
moves with it; or (b) pane-side — the pane seeds the standard fit before its first write, exactly as
OUTFITTING's `_seed_fit` does (P2-B1's precedent, recorded as L81) — and then §13 rule 5's allowed-call list
must name `set_fit`. (a) makes the preview and the commit read one shape and needs no new pane call; (b) keeps
`fit_module_at`'s text and puts the write in the pane. Either is one branch. **Reversal:** the pin's present
text.

### MED-2 — a refusal's line outlives the successful action that follows it

**Tier: MED** (one line, no pin change).

```text
$ XDG_DATA_HOME=/tmp/r1_probe_sb godot --headless --path vajb-orbit res://tests/probe_r1_fit_panes.tscn --quit-after 600 | rg 'refused REMOVE|then a legal swap|footer now'
[R1-PANES] refused REMOVE=false footer=MANDATORY CELL — SWAP ONLY, NEVER EMPTY
[R1-PANES] then a legal swap on the same cell: ok=true engines=["e_ion"]
[R1-PANES] footer now=MANDATORY CELL — SWAP ONLY, NEVER EMPTY (still the refusal=true) meter=PWR 3 / 8 · CANDIDATE 3 / 8
```

`_notice()` latches `_line_override` and only `_select()`/`clear_selection()` clear it, so a **successful**
`install_module`/`remove_selected` on the same cell leaves the previous refusal on screen — here the footer and
the shell strip keep saying `MANDATORY CELL — SWAP ONLY, NEVER EMPTY` while the engine cell has just been
swapped, legally, to `e_ion`, and the meter has already moved. That contradicts §5.3's "the selected cell's
line reads `<TYPE><n> · …`" and puts a false statement in front of the player. **Cure:** clear
`_line_override`/`_line_danger` on the success path of `install_module` and `remove_selected` (or set the
override only in `_refuse` and have the success paths call `_refresh_footer()` after clearing). **Reversal:**
let the override latch again. W2's §2 item 1 and its suite do not cover this case.

### LOW-1 — `fit_module_at` does not compare the module's slot type with the cell's type

W1's §6.4, re-measured byte-identically by me (`probe_w1_type_hole.tscn`, 6 marker lines, zero diff): an
`e_std` fits a **W** cell through the profile API (`fit_module_at(weapons, 0, e_std) -> true`, `fit_legal`
`legal=true`). 09 §4 item 3 says "One module per slot, slots are typed: a weapon never sits in an H slot",
but §13's refusal list is exhaustive and omits the check, and the pane gates by the module's own type
(`_row_target_cell`), so **no shipped surface can express it**. Cure when someone owns it: one
`ModuleCatalog.module(id)[&"slot"] == slot_key` comparison (with W2's `engine`→`engines` alias) — after a
§13 amendment, because adding a refusal the pin does not name is a spec change.

### LOW-2 — `clear_fit_slot` refuses a cell that already holds nothing

W1's judgement call 1, re-measured (`probe_r1_fit_profile.tscn`): `removing an already-empty cell answers
false`. §13's refusal list does not name that case; W1's stated reason (an empty cell has no module to return
and the success path's one line would be a phantom `FIT_MODULE, "", 1, +0`) is sound and the pane disables
REMOVE for an empty cell (`can_remove=false`), so nothing is reachable. One sentence in §13 would close it.

### LOW-3 — the retired Phase C mockup still carries its own UPGRADES rows

`ui/screens/_mockup_station.gd` has a local `const UPGRADES`, a `MOCK_INSTALLED_UPGRADES`, an `UPGRADES`
enum member and a `"UPGRADES"` label, and `_mockup_station.tscn:474` a matching label; line 22 mentions
`install_upgrade` in a doc comment only (the mockup calls no profile method). It is not in the shipped rail
(`station.tscn` is), D0's header records it as the retired mockup's own measurement, and STATION_HUB §12.6 /
IMPLEMENTATION_PLAN §9.6 delete it with the real screen. **No live reference; hygiene only.**

### LOW-4 — the signature audit cannot see a two-line pin

`vajb-orbit/tools/r1_p2b1_signature_audit.py:40` matches `\bfunc\s+(\w+)\s*\(([^)]*)\)` per line, so
CONTRACTS §13's `fit_module_at` (whose parameters wrap) is silently skipped: the run reports
`signatures checked: 27, drift: 0` and never names it. Verified by hand instead, so this review's §13 coverage
is complete, but the next wave's audit inherits the hole. Cure: join a wrapped signature (`func` … `) ->`) into
one logical line before matching.

### LOW-5 — 09 §3.8's own sentence and the retirement table's generator row disagree in effect lineage

`docs/gameplay/09_ship_slots_modules.md:233-235` reads: "Lineage: `upgrade_generator` (+30/+20 % regen) does
**not** carry over as a power module — regen moves to shield modules (§3.2) where it belongs; the existing
upgrade retires into the auction book as a legacy entry (10 §5)." The wave's `LEGACY_UPGRADE_MODULES` maps
`upgrade_generator` → `p_mk2` (a power module), reading 09 §3.8's *name* provenance ("the old Reactor Mk2,
rebased") as the lineage — which is what the brief's §2 pins as "09's own, already written". Both readings cite
§3.8; the *name* lineage is `p_mk2`, the *effect* lineage is a shield module. No player-visible regression is
possible today (the brief's §1 measures that nothing in flight ever read `has_upgrade`, so the six rows bought
no effect), and the brief is law, but the doc now carries a sentence that reads as a contradiction of the
constant beside it. Cure: one clause in §3.8 naming the retirement table's name-lineage reading (or in 09 §4
item 13 saying the same). Owner-gated: 09's §3 tables are D0's only under the brief's direction.

### LOW-6 — the three data-dependent failures against a live profile are pre-existing test assumptions

Measured above (§2). The mechanism is in the fixtures, not the game: `tests/test_engine2_dock.gd:31`
(`FIRED_WEAPON = &"laser"`) and `_slot()` (`Weapons.ammo_slot(laser)` = index 0 of `PlayerState.WEAPONS`)
assume **slot 0 holds the laser**, but since P2-A/P2-B1 `PlayerState.set_weapons` sizes the slots in the
*launched fit's* order (`game/player_state.gd:126`), and the owner's Vanguard fit is
`["w_cannon", "w_laser", "w_laser"]`, so slot 0 is the cannon's pack. With a fresh profile the standard fit is
laser-first and all three pass. `game/game.gd` and `game/player_state.gd` are not in this wave's diff, and
W1's pre-wave log reads the same three failures (`passed=386 failed=3`). Cure: make the two suites resolve the
slot from `_state.weapons` instead of `WEAPONS` order. **Owner-facing note:** it is also worth knowing that
the gate is only green on a sandboxed `user://`; any future worker that runs the gate against the live profile
will see these three and must not read them as a regression.

### LOW-7 — the exit-time leak lines are nondeterministic on an unchanged tree

`WARNING: N ObjectDB instances were leaked at exit` / `ERROR: M resources still in use at exit`: 80/34
(W1 before), 80/34 (W1 after), 84/36 (W2 before), 16/8 (W2 after), **none** (W3 before and my run 1), 52/20
(W3 after), 38/… (my run 2) — the same tree, different counts, and the pre-wave log already carries them. Not
a wave finding; recorded so nobody diffs those lines as evidence. (Both the two `SCRIPT ERROR`-free runs and
the ones carrying the leak lines report the identical `passed=431 failed=0`.)

### LOW-8 — carried-forward harness items that bit this pass

`.agents/gen/LOW_BACKLOG.md` **L75** (the worker-file hook normalises Windows prefixes only, so an absolute
Linux path inside the declared set is refused) cost this review one blocked write: `write` to
`/home/kamil-paluszkiewicz/VajbOrbit/vajb-orbit/tests/probe_r1_v5_migration.gd` was denied with "outside
this worker's declared file set. Allowed: vajb-orbit/tests/, vajb-orbit/tools/"; every write after that used
workspace-relative paths, which pass. **L82** (probe scripts are untracked in a committed tree) applies again:
this review adds three probe scenes (nine files with `.uid`/`.tscn`) that the wave-boundary commit should ship
deliberately or drop.

---

## 8. Verified clean (measured, for the close-out)

1. **The gate:** `passed=431 failed=0`, exit 0, twice, two scratch roots. CONTRACTS §9 still reads 389 —
   **431 is the figure the close-out writes.** Growth is fully accounted: 13 + 18 + 11, and `[PASS]` lines in
   the log = 431.
2. **The save v5 flag day:** six upgrades → six inventory modules on my own fixture, in both `ConfigFile`
   spellings; credit and the rest of the file preserved; the file rewritten as v5 with no `upgrades` key;
   `retire_legacy_upgrades()` = 0 on the second call and a second load reads 6, not 12; a v1 file migrates, a
   v3 file with no record is left alone (and not rewritten), a v5 file has nothing to migrate; and the same
   conversion happens on a real `boot.tscn` run from a hand-written v4 file with zero error lines.
3. **The two composed transactions:** every pinned guard (hull, slot key, index, ownership, `fit_legal`)
   refuses before any write; the displaced module returns before the take; the per-cell install targets the
   cell it is given; the remove empties an ordinary cell and refuses every mandatory one; one
   `FIT_MODULE, <id>, 1, +0, <balance>` line per success and none per refusal; `[modules, modules, fits]` on
   success and nothing on a refusal.
4. **The retirement is complete:** `UPGRADES`/`UPGRADE_SLOTS` gone from `StationCatalog`,
   `has_upgrade`/`installed_upgrades`/`install_upgrade`/`KEY_UPGRADES` gone from the profile (measured on a
   live instance's method list and the script's constant map), the pane files deleted, the rail renamed at the
   retired entry's index with the retired icon/tint/bed, the shell loads `Fitting` and no `Upgrades`, and no
   live reference survives anywhere in `res://`.
5. **The pane:** the shipyard's recipe cell for cell (16 cells, 5 gaps, 4 columns, 48 px, `h_sep` 4,
   `SLOT LAYOUT · 11 CELLS · 1 ENGINES`); selectable one at a time with the theme's focus ring and
   `FOCUS_ALL`; row order and the row cells (`SLOT WEAPONS · DRAW 1`, `OWNED ×1`) derived independently; the
   pinned empty state; the meter idle/candidate/over forms equal to `fit_legal`'s own numbers with the danger
   colour equal to `Tokens/accent_danger`; the over-budget refusal `8 / 6 PWR — OVER BY 2`; the mandatory
   refusal word for word; `REFUSED · FIT ILLEGAL` reachable on the unfit-hull path (MED-1); and the focus walk
   cells → rows → footer (`probe_w2_fitting`, re-run byte-identically).
6. **The shipyard's hover line** for a fitted cell, an empty cell, a gap (no line) and a hull with no stored
   fit, plus the live re-read after a fit write.
7. **LAUNCH's two services:** `REFUEL` → `FUEL_MAX 200`, `RECHARGE` → `ENERGY_MAX 100`, both labels from
   `StationCatalog`, no credits moved on any call, the full tank rendered as the service's own `FUEL_FULL` in
   the danger token with the button still pressable, and `NO_DAMAGE_REPORT` for an unfiled hull.
8. **No drift:** 27 pinned signatures EXACT and 21 format checks PASS, no re-declared mandatory list, no
   invented number, no frozen file touched (31 of 32 catalogue rows verified against 09 §3's tables and the
   32nd against 09 §4 item 7).
9. **The owner's profile was never written** by this review (md5 identical before and after every run).

## 9. Notes for F1 and the close-out

- **F1's set:** MED-2 is one line in `ui/station/fitting_panel.gd` (`_line_override`/`_line_danger` cleared on
  the success path of `install_module` and `remove_selected`). MED-1 needs **D0 first**: either amend §13's
  `fit_module_at`/`clear_fit_slot` candidate sentence (profile-side fallback) or §13 rule 5's allowed-call
  list (pane-side seed). If the owner prefers to leave MED-1 open, the workaround in play is one INSTALL press
  in OUTFITTING, and the finding should stay in the backlog rather than ship unrecorded.
- **CONTRACTS §9** should read the measured **431**; §13 already carries the pin and the v0.5 changelog line,
  and the six §13 rules are numbered 1–6 in reading order (the brief's duplicated "2.").
- **Owner ticks:** 1 (the rail entry) and 2 (the six-row retirement) are measured landed with their
  reversals recorded in `09 §4 item 13`, `STATION_HUB §5.3` and the constants themselves; 3 (the pinned
  strings) is character-exact; 4 (the four requests) is measured landed; 5 (affixes next) is recorded in
  `15 §6` and this wave creates no instances.
- **W2's five judgement calls and W3's three** I checked against the pin and accept as documented: the
  footer REMOVE control, the candidate's source, the base-id aggregation, the `_grid_hull` guard (the pin does
  not require a rebuild when the matrix has not moved, and rebuilding would drop the player's selection on
  every install), the `engine`→`engines` alias, the programmatic service row (W3's file set holds no `.tscn`),
  the 56 px row height (EXCHANGE's own secondary height) and the service report's wording (the service's own
  key, upper-cased).
- **Two readings I did not treat as findings:** `_grid_hull`'s narrower refresh than STATION_HUB §12.4's
  wording (the rendered grid cannot differ while the matrix has not moved), and `base_module_id`'s hand-back
  of a *base* id on a remove of an instance id (15 §6's own future wave; recorded as L80). A v5 file read by a
  pre-v5 build falls back to defaults, which is this project's rule for every earlier bump (`version >
  SAVE_VERSION`), §13 rule 2's own one-way door.

## 10. What I did not measure

- No live editor run: every measurement here is headless, so nothing in this report speaks to how the pane
  *looks* (W2's §5.1 and W3's §4.2 hold the frame evidence) — only to what it holds and computes.
- I did not re-measure the hitbox-free UI feel (hover tween, audio cues) beyond what W2's re-run probe prints.
- I did not bisect the leak lines to a file; they are nondeterministic on an unchanged tree and pre-date the
  wave.
- I did not re-run the gate at HEAD: W1's pre-wave logs are the HEAD-side evidence for the three failures
  (`p2b_proper_w1_gate_before.log` / `…_before_sandbox.log`), and I proved data-dependence by bisecting the
  profile instead of by stashing the tree.
