# P2-B1 — R1 report: the mandatory review of the weapon fit surface

**Worker:** R1 (coder — reviewer, **mandatory**). **Wave:** P2-B1 — the weapon fit surface.
**Brief (law):** `.agents/gen/p2b1_weapon_fit_wave_task.md` (its §3 the pin, §4 R1's row, §5, §6).
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/tests/,vajb-orbit/tools/` (plus `.agents/**`,
which the hook allows). **Nothing shipped was edited by this pass** — the two tools and the
probes below are new, additive files; `git status` shows no modification to any file a W1/W2/D0
row owns.
**Measured gate (mine, §1):** `[SUMMARY] passed=387 failed=0`, exit 0.

**Verdict.** The wave's contract holds. **No HIGH.** Two MED findings, both with a one-place
fix and both outside the wave's own code paths in a way the orchestrator must route (one needs
`ui/screens/station.gd`, which no worker of this wave owns; one needs an owner tick because the
brief's §1 and §3 name two different six-module shop lists). Eight LOW findings ride to
`.agents/gen/LOW_BACKLOG.md` as L76–L83. Everything the brief told me to verify was
re-measured from outside the wave: the row table, the round trip (including a save/reload
round trip W1/W2 never measured), every refusal byte-for-byte, the state machine, the profile
transaction order, the pinned signatures, the frozen numbers and the mandatory set.

---

## 0. What I ran, and one artifact caveat

Every figure in this report is a raw capture in `.agents/gen/`:

| Capture | Command |
|---|---|
| `p2b1_r1_gate.txt` | `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` |
| `p2b1_r1_suite.txt` | the same, `-- --suite=test_p2b1_outfitting_panel` |
| `p2b1_r1_w2probe_rerun.txt` | `godot --headless --path vajb-orbit res://tests/probe_p2b1_panel_fit.tscn` (**W2's** probe, re-run) |
| `p2b1_r1_w1probe_rerun.txt` | `godot --headless --path vajb-orbit --script res://tests/probe_p2b1_buy_module.gd` (**W1's** probe, re-run) |
| `p2b1_r1_review_probe.txt` | `godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn` (R1's own: rows, door, states, round trip, refusals, mandatory set, transaction law, strip, shell copy) |
| `p2b1_r1_edge_probe.txt` | `... res://tests/probe_r1_p2b1_edge.tscn` (full-cells refusal with a genuinely full grid, unreachable install calls, the bare-hull seed, `clear_fit`, an instance id, the seam's price trust, the refresh) |
| `p2b1_r1_edge2_probe.txt` | `... res://tests/probe_r1_p2b1_edge2.tscn` (focus order, an instance with no record, 09 §2's power arithmetic with `p_std` vs `p_mk2`) |
| `p2b1_r1_edge3_probe.txt` | `... res://tests/probe_r1_p2b1_edge3.tscn` (a fitted instance with no record; the pane's stale copy) |
| `p2b1_r1_layout_probe.txt` | `... res://tests/probe_r1_p2b1_layout.tscn` (render order, the 48/40 px icon columns, header alignment, `CELL_SEPARATION`) |
| `p2b1_r1_persist_probe.txt` | `... res://tests/probe_r1_p2b1_persist.tscn` (**new this pass**: the panel's writes re-read out of the file after every step) |
| `p2b1_r1_format_law.txt` | `python3 vajb-orbit/tools/r1_p2b1_format_law.py` (21 byte checks, 0 failures) |
| `p2b1_r1_signatures.txt` | `python3 vajb-orbit/tools/r1_p2b1_signature_audit.py` (25 signatures, 0 drift) |

New, additive, re-runnable: `vajb-orbit/tests/probe_r1_p2b1_persist.gd`/`.tscn`,
`vajb-orbit/tools/r1_p2b1_format_law.py`, `vajb-orbit/tools/r1_p2b1_signature_audit.py`.

**Probe hygiene (L17).** Every probe borrowed the shipped `PlayerProfile`, repointed its
`save_path` at a scratch file, restored every field and flushed **before** handing `save_path`
back. `md5sum` of the owner's file, before and after the whole run:
`8dffef0c5bf8bb9f6444463d0d31f506  ~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`
— identical, twice (§ before the gate, § after the last probe).

**One caveat the orchestrator should know.** The workspace has **concurrent writers**: three
live `crush` sessions and the Godot editor are running (`ps`: pids 70817 / 103510 / 105584 /
63876), and `vajb-orbit/tests/probe_r1_p2b1_fit.gd` changed **under my first run** (mtime
`2026-09-22 07:11:29`, size 21 133 → 21 155 bytes, i.e. edited while my probe batch was
executing). That same file's earlier revision ran away — the first `probe_r1_p2b1_fit.tscn` run
exited 137 (SIGKILL, OOM) with an **80 867 189-byte** log holding **1 650 272** identical
`[r1] emptying W3 to build the overload candidate` lines — while the current revision of the
same probe finishes in 20 s with exit 0 (`p2b1_r1_fit_probe_rerun.txt`). So that probe is an R1
scratch artifact mid-edit by another session, **not** evidence about shipped code: everything
this report rests on was measured against files whose mtimes predate the wave's own reports and
never moved: `outfitting_panel.gd` 01:30:18, `player_profile.gd` 00:52:34,
`test_p2b1_outfitting_panel.gd` 01:25:06, `STATION_HUB.md` 00:46:47, `CONTRACTS.md` 00:45:35 —
re-checked at the end of the pass, all five unchanged. The gate was run **twice**, before and
after the whole probe batch, with the same result (§1). `L82` in the backlog has the
housekeeping consequence.

---

## 1. The gate I measured myself

```text
$ godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=387 failed=0          exit 0    (387 [PASS], 0 [FAIL])   # run twice: before and after the probe batch
$ ... -- --suite=test_p2b1_outfitting_panel
[SUMMARY] passed=7 failed=0            exit 0    (the new suite alone)
```

`passed=387` matches W2's claim (380 → 387, +7 = the new suite) and the growth is additions
only: `test_p1_profile.gd`'s diff is `+119 / −1` and the one deleted line is a doc-comment
sentence (`-## contract and the pre-existing API.`), not an assertion — 47 added `assert*`
lines, no existing test's body moved. **What I did not re-measure:** the pre-wave baselines
(D0's 378, W1's 380). Re-deriving 378 needs the wave's files stashed, and stashing this tree
while another session is writing into it would corrupt that session's state; the −7 arithmetic
above (387 − 7 = 380, 380 − 2 = 378) is consistent with both reports' own records.

---

## 2. Verdict by mandate item, with the raw output

### A. Every row's cost and draw against 09 §3.1's table — **PASS**

`probe_r1_p2b1_review.txt` §A parses 09 §3.1's WEAPONS table out of the document and compares
id, draw, cost, the `W SLOT · DRAW n` meta, the PRICE cell and the EFFECT prose with the
catalogue and the rendered cells:

```text
[r1] 09 section 3.1 table rows=6 ids=["w_laser", "w_cannon", "w_rocket", "w_mine", "w_plasma", "w_railgun"]
[r1] pane rows=6 ids=[&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_railgun"]
[r1] per-row check (cost, draw, PRICE, EFFECT, meta): ALL MATCH
[r1] pane rows outside 09 section 3.1's table=[]
```

Independently, `p2b1_r1_format_law.txt` byte-compares all six EFFECT strings with 09 §3.1's
Effect column and all six `W SLOT · DRAW n` metas: **21 checks, 0 failures**. `ModuleCatalog`
holds the same six `(draw, cost)` pairs (draws 1/1/2/1/3/3, costs 900/1 200/2 400/1 800/4 800/
5 200); the DPS figures inside the effect prose (30/45/70/60) are `weapons.gd`'s own `dps`
values (`weapons.gd:65,75,85,96`), so the prose cannot drift from the code.

**The row set is 09 §3.1's six** (W2's reading), and `w_mining` — 09 §4 item 7's seventh weapon
module, 600 CR, draw 1 — has **no row**. That is MED-2 below, not a mis-transcription: §5.1 and
§12 carry the brief's own bytes (verified byte-identical, `format_law` + the transcript check:
`STATION_HUB[371:388] == brief[77:94] -> True`, `CONTRACTS[1044:1061] == brief[77:94] -> True`).

### B. The buy / install / swap / remove round trip — **PASS**, and it persists

W2's probe (re-run byte-identical, §I below) and R1's review probe both walk the four actions.
The measurement W1/W2 did not make is in `p2b1_r1_persist_probe.txt`: after every action the
store is flushed and **re-read out of the file**, then reloaded through `reload()`.

```text
[r1p] after BUY + INSTALL | credits=18800 cells=["w_laser", "w_cannon", ""] inv=[]
[r1p] after BUY + INSTALL: save_version=4
[r1p]   filed fits={ "ship_vanguard": { "armour": ["h_plate_light", ""], "boosters": [""], "computers": [""],
      "engines": ["e_std"], "power": "p_std", "shields": ["s_light"], "utility": [""], "weapons": ["w_laser", "w_cannon", ""] } }
[r1p] after BUY + INSTALL: reloaded credits=18800 cells=["w_laser", "w_cannon", ""] inv=[] legal=true
[r1p] after SWAP: reloaded credits=14600 cells=["w_mine", "w_cannon", "w_rocket"] inv=[w_laser:1] legal=true
[r1p] after both REMOVEs: reloaded credits=14600 cells=["", "", "w_rocket"] inv=[w_laser:1 w_cannon:1 w_mine:1] legal=true
```

* **INSTALL fills the first empty W cell** — the cannon lands in W2 while the standard fit's
  laser holds W1 (`cells=["w_laser","w_cannon",""]`).
* **SWAP displaces, never destroys (09 §4.8)** — the laser comes back (`inv=[w_laser:1]`,
  `filed modules={ "w_laser": {…count 1} }`) and is still there after the reload.
* **REMOVE returns to the inventory** — both removals land, and the filed record agrees.
* **Nothing is created or destroyed:** 20 000 → 18 800 → 16 400 → 14 600 = exactly the three
  catalogue prices (1 200 + 2 400 + 1 800 = 5 400), and the modules in play (one laser, one
  cannon, one mine held, one rocket fitted) equal the standard fit's laser plus the three
  purchases = 4.
* The seeded fit is the launch's own fit with the §11 array shape and the §7 mandatory set
  (`engines:["e_std"], power:"p_std"`, H padded to its capacity of 2).

Cross-checked on a hull with **no** stored fit: `probe_r1_p2b1_edge.txt` §3 buys and installs
onto the destroyer and measures `weapons=["w_cannon","","","","","",""] engines=["e_std","e_std","e_std"] power=p_std`, `fit_legal legal=true missing=[] overflow={}` — the seed writes
what the launch would fly (`game.gd:337-341` + `:351-375`), so the panel can never hand flight
an unlaunchable hull.

### C. Every refusal, with the exact wording — **PASS for the two the pin names**, one extra word

**The power overload, against 09 §2's own format** (`probe_r1_p2b1_review.txt` §E3, and again
with a different candidate in `probe_r1_p2b1_edge2.txt` §3):

```text
[r1]   w_plasma action with an empty W3 and one owned=INSTALL
[r1]   install_module(w_plasma) = false | footer='11 / 8 PWR — OVER BY 3' danger=true purchase_failed=[]
[r1]   09 section 2's own example=13 / 11 PWR — OVER BY 2
[r1]   the pane's own format applied to it='13 / 11 PWR — OVER BY 2' equal=true
[r1]   cells unchanged=true | module still owned=true | credits unchanged=true
[r1c] Vanguard power_out=8 ; p_std effect={ &"power_add": 0.0 } ; p_mk2 effect={ &"power_add": 2.0 }
[r1c] three plasma + light shield with p_std: power={ &"out": 8, &"draw": 11, &"spare": -3, &"legal": false }
[r1c] install the third plasma with p_mk2: false | footer=["11 / 10 PWR — OVER BY 1"]
```

The arithmetic is 09 §2's (`Σ draws ≤ hull power output + power module output`, engines free),
the format is 09 §2's byte-for-byte, and **nothing auto-removes**: cells, the module's ownership
and the balance are all unchanged after the refusal.

**The full-cells refusal, byte-equal to STATION_HUB §5.1's own line** (`probe_r1_p2b1_edge.txt`
§1, on a genuinely full grid — W2's own probe measured the same state):

```text
[r1b] cells=["w_laser", "w_laser", "w_cannon"] strip=["W1 LASER MKII", "W2 LASER MKII", "W3 CANNON MKI"]
[r1b] w_plasma action with a full grid and one owned=SWAP
[r1b] install_module(w_plasma) = false
[r1b] footer emitted=["W SLOTS FULL — SWAP OR REMOVE FIRST/danger=true"]
[r1b] STATION_HUB 5.1's own line='W SLOTS FULL — SWAP OR REMOVE FIRST' ; rendered='W SLOTS FULL — SWAP OR REMOVE FIRST' ; equal=true
[r1b] nothing written: cells unchanged=true owned unchanged=true credits unchanged=true
[r1b] after SWAP: cells=["w_plasma", "w_laser", "w_cannon"] ; the displaced module came back: w_laser owned=1
```

Note the two-step honesty of that state: the *call* refuses, while the *row* offers `SWAP` — the
pin's own two sentences, both measured. **A reviewer warning for the record:** W2's review-probe
run of this check (`.agents/gen/p2b1_r1_review_probe.txt` §E4) reports `equal=false` only
because its sequence reached the full-cells check with W3 still empty and therefore measured the
*overload* line again (`9 / 8 PWR — OVER BY 1`). That is a probe-sequencing artifact of the
review probe, not a panel fault; the edge probe's genuinely-full-grid sequence above is the
valid measurement, and W2's own suite test measures the same state.

**The purchase refusals** (`purchase_failed`, reused vocabulary per §12 rule 1):

```text
[r1]   panel.buy_module(w_not_a_module) = false | credits 20000 -> 20000 | log 8 -> 8 | purchase_failed=[]
[r1b] install_module(w_railgun) with none owned = false | footer=[] | cells=["", "", ""]
[r1]   buy_module(w_railgun, 5200) = false | credits 10 -> 10 | log 14 -> 14 | signals=[] credits=10
```

An unknown id refuses with no write and no signal (the panel's own entry point answers `false`
before the seam is reached for `w_not_a_module`); an unaffordable buy refuses with
`insufficient_credits`, does not move credits, gives nothing, emits no `profile_changed` and
writes no log line. **A third wording exists** — `REFUSED · FIT ILLEGAL` — reachable only from a
fit another API caller wrote; LOW-2.

### D. Every state transition against the brief's §3 — **PASS with one reading to tick**

STATUS (`probe_r1_p2b1_review.txt` §C): `FITTED (W1)` for the standard fit's laser, `OWNED ×1`
/ `OWNED ×2` after buys, `FOR SALE` for the rest, `LOCKED` with `price='4 800'` at 10 CR — all
four states, in the pin's precedence order (fitted → owned → for sale → locked).

ACTION: `BUY` (nothing owned, empty cell) → `INSTALL` (`OWNED ×1`, empty cell) → `SWAP` (full
grid, one owned, not fitted: `w_railgun: status='OWNED ×1' action='SWAP'`) → `REMOVE` (full grid,
fitted: `w_cannon (fitted, full grid): status='FITTED (W2)' action='REMOVE'`). All four
measured, and each press does what its label says (the round trip above).

The reading to tick (LOW-3): a **fitted** module with an empty W cell offers `BUY`/`INSTALL`,
never `REMOVE` — `w_laser: status='FITTED (W1)' action='BUY'` (C0/C1) and
`w_rocket: status='FITTED (W3)' action='BUY'` (C9). The strip's REMOVE covers every fitted cell
in every state, so removal is never unreachable; W2 disclosed this and its reversal is one line.

### E. The profile writes against the transaction law (17 §5) — **PASS**

`buy_module` (`player_profile.gd:378-385`) is verify (`ModuleData.module(id).is_empty()` or
`cost < 0` → `unknown_id`) → charge (`_charge`) → give (`add_module` once) → emit
(`&"credits"` then `&"modules"`) → log (one `EconomyLog.append(EVENT_BUY_MODULE, id, 1, −cost,
balance)`). Measured: paid buy `log 13 -> 14 signals=["credits", "modules"]`, the line's own
fields `2026-09-22T04:57:20, BUY_MODULE, w_railgun, 1, -5200, 4800`; refused buy
`log 14 -> 14 signals=[]`; the whole 3-buy sequence in `p2b1_r1_persist_probe.txt` is exactly 3
log lines, one per purchase, and **no** line for install/swap/remove (a swap is free, 09 §4.8).

The panel's write path follows the same order and is the only writer the surface has — the
panel's own mutations, all through public profile APIs:

```text
outfitting_panel.gd:959-960   take_module → set_fit_slot            (INSTALL, hands back on a failed write)
outfitting_panel.gd:986-992   take_module → set_fit_slot → add_module(displaced)   (SWAP)
outfitting_panel.gd:1015-1017 set_fit_slot("") → add_module         (REMOVE, write first)
outfitting_panel.gd:1067      set_fit(hull, standard)               (the seed, once per hull)
```

`grep -n 'profile\.set|_profile\.set|_credits'` over the panel is empty: it never touches
`save_path`, `_fits`, `_modules` or `_credits` (§8's "only `PlayerProfile` mutates"). One
literal deviation from §12 rule 2's list is the seed's `set_fit` — LOW-5.

### F. CONTRACTS §8 / §11 / §12 pinned signatures — **PASS, 0 drift**

`python3 vajb-orbit/tools/r1_p2b1_signature_audit.py` → **25 signatures checked, drift 0**:
every §11 pin (`ShipFit.grid_rows/grid_size/grid_cells/grid_counts/slot_capacity/fit_legal/
standard_fit/mount_offset`, `ModuleCatalog.module/icon_path/slot_of`, `PlayerProfile.fit_for/
set_fit/set_fit_slot/clear_fit/base_module_id/module_count/add_module/take_module`,
`PlayerState.set_weapons`, `HUD.set_hull_slots/hull_slots`), §12's `buy_module`, and §8's two
seams this wave could move (`set_ammo`, `EconomyLog.append`) are byte-identical to the pin. The
profile's whole diff is `+30 / −0` (two preloads, one event const, `buy_module`), so no §8 line
was touched. The panel calls only pinned APIs plus `can_afford`/`credits`/`clear_fit`-free
reads; `clear_fit` is deliberately unused (it drops a whole fit and cannot empty one cell).

### G. No §13 row and no weapon damage/cadence/range/energy value moved — **PASS**

The wave's changed set is 9 files (`git diff --name-only`): 4 `docs/**`, `player_profile.gd`,
`test_p1_profile.gd`, `outfitting_panel.gd`, `.tscn`, `WAVEBOARD.md`. **No flight, weapon,
catalogue or spec file is in it** — `game/weapons.gd`, `game/player_ship.gd`,
`game/ship_fit.gd`, `game/module_catalog.gd`, `docs/gameplay/18_engine_spec.md` are all
untouched. Read against 18 §13 directly:

| §13 row | Live constant | File |
|---|---|---|
| ranges 500 / 450 / 600 / 800 / 900 | `weapons.gd:64,73,84,95,104` | untouched |
| DPS 30 / 70 / 45 / 60 | `weapons.gd:65,74,85,96` | untouched |
| weapon draw laser 6 · plasma 10 E/s, kinetics 0 | `weapons.gd:66,75` (`draw`), no `draw` on the kinetic/missile/deployable rows | untouched |
| rocket 180 alpha, 1.2 s, 2.2 rad/s, 900 u/s | `weapons.gd:105-108` | untouched |
| mine arm 2 s, trigger 60 u | `weapons.gd:119-120` | untouched |

The panel carries the DPS figures only as 09 §3.1's prose (`EFFECT_TEXT`, byte-checked above).
The wave's new numbers are exactly two: the overload format's three `%d`s and nothing else — 09
§3.1's costs, 09 §4 item 7's 600, and the brief's own two wordings are the only other numerals,
all transcribed. *(One unrelated observation, not a moved value: §13's "mining 5 E/s" row has no
code owner anywhere — `game/mining_laser.gd` never touches the Energy pool. That is LOW
backlog L11's pre-existing entry, not this wave's.)*

### H. The mandatory engine / reactor set cannot be touched — **PASS**

`probe_r1_p2b1_review.txt` §F and `probe_r1_p2b1_edge.txt` §2:

```text
[r1] rows whose slot is not weapons=[]
[r1] catalogue engine ids=["e_std", "e_ion", "e_vector"] power ids=["p_std", "p_mk2", "p_core"]
[r1] install_module(e_std)=false install_module(p_mk2)=false swap_module(p_std,0)=false swap_module(e_ion,0)=false
[r1] footer lines emitted by those calls=[]           (the one REMOVED line came from the W-cell removal)
[r1b] install_module(s_light) = false | swap_module(s_light, 0) = false | footer=[]
[r1b] swap_module(w_cannon, 9) = false | remove_module(9) = false | remove_module(-1) = false
[r1b] remove_module(2) (empty cell) = false | footer=[]
[r1] the mandatory set after the whole probe: engines=["e_std"] power=p_std missing=[] overflow={  }
```

Four independent guards hold it: the six rows are all `weapons`-slot; `install_module`/
`swap_module` require `ModuleCatalog.slot_of(id) == &"weapons"` **before** anything else; the
strip and `remove_module` address only the cells `ShipFit.grid_cells` reports as `weapons`, so
no engine or reactor cell is addressable from this surface; out-of-range indices are refused
silently; and the fit's mandatory set is intact at the end of every probe
(`engines=["e_std"], power=p_std, missing=[]`).

### I. W2's probe re-run byte-identically — **PASS**

```text
$ diff .agents/gen/p2b1_w2_probe.txt <(godot --headless --path vajb-orbit res://tests/probe_p2b1_panel_fit.tscn)
(no output — IDENTICAL, 54 [probe] lines, exit 0)
```

W1's probe differs in exactly one byte-range that cannot be reproduced: the log line's timestamp
(`[probe] log lines=1 raw=2026-09-21T22:53:17, BUY_MODULE, …` → `2026-09-22T04:55:44, …`); every
number on every other line is identical (12 `[probe]` lines, exit 0).

### J. The construct, the strip and the focus order — **PASS**

`probe_r1_p2b1_layout.txt` reads the laid-out pane: render order top to bottom is
`FittedMargin` (strip) → `ModulesMargin` (caption + header) → `ModuleRows` →
`HeaderMargin` (ammo header) → `OutfittingRows` (ammo), which is §5.1's order; module icons are
a 48 px column against the ammo rows' 40 px; both headers' left edge equals their rows' grid
left (`13`), which is the W2.2 alignment half; `CELL_SEPARATION` 2 on the strip and the module
box; the Vanguard shows 3 of the 7 built strip lines (the widest hull is the destroyer's 7), and
an empty line's REMOVE is `visible=false disabled=true` while a fitted one is
`visible=true disabled=false` (measured twice, here and in §H of the review probe).
`probe_r1_p2b1_edge2.txt` §1 measures the focus order: with the standard fit `focus_primary()`
lands on `W1/Remove` (the strip), with every W cell empty it lands on
`ModuleRows/ModuleLaser` — strip, then module rows, then the ammo rows, §5.1's order.

---

## 3. Findings

### HIGH — none

Nothing found blocks the wave. The four capabilities the brief demands (BUY, INSTALL, SWAP,
REMOVE), both pinned refusals, the two state machines, the strip, the focus order, the
mandatory-set guard and the transaction law are all measured working, and the gate is green.

### MED-1 — an unaffordable module purchase shows the player a fabricated price: `… · 0 NEEDED`

*Where:* `ui/screens/station.gd:453-458` (`_refusal_text`) → `:474-486` (`_entry_cost`/`_entry`,
which resolves only `StationCatalog.ammo_pack/ship/upgrade`), reached from the profile's
`purchase_failed` (`station.gd:208-209` → `:445-450`).
*Repro + raw output* (`p2b1_r1_review_probe.txt:140-143`):

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep "station.gd _"
[r1] station.gd _entry_cost(w_railgun)=0 (a module is not an ammo pack, a ship or an upgrade)
[r1] station.gd _refusal_text(insufficient_credits, w_railgun)='REFUSED · NOT ENOUGH CREDITS · 0 NEEDED'
[r1] station.gd _refusal_text(insufficient_credits, laser)='REFUSED · NOT ENOUGH CREDITS · 120 NEEDED' (the ammo pack, for contrast)
```

*Why it is reachable in ordinary play:* the module rows are pressable while `LOCKED` (measured:
`w_railgun status/action with 500 CR = LOCKED / BUY`, then the press returns `false` with
`purchase_failed=["insufficient_credits/w_railgun"]`), and the pane renders **nothing** for a
failed purchase itself — `_on_module_pressed` → `buy_module` → on failure only
`_pulse(price)`. The shell's line is therefore the only feedback, and it names a price of
**0** where §5.6 promises `<cost> NEEDED`. The wave added a fourth purchasable family and did
not extend the shell's resolution.
*Fix (one place, either side):* add `ModuleCatalog.module(id)` to `station.gd:_entry`/`_entry_cost`,
or render the module purchase refusal in the pane's own footer strip (`status_requested`, the
pin's own channel for this surface). **Routing note for the orchestrator:**
`ui/screens/station.gd` is in **no** worker's file set for this wave (D0 `docs/`, W1
`player_profile.gd`+tests, W2 `ui/station/outfitting_panel.*`+tests, R1 `tests/`+`tools/`, F1 per
finding), so the fixer's set must be widened to that one file, or the finding must be re-tiered
onto the next wave.

### MED-2 — the mining laser has no door: `w_mining` is purchasable by the seam but has no row

*Where:* `ui/station/outfitting_panel.gd:95-102` (`MODULE_ROWS` = 09 §3.1's six).
*Repro + raw output* (`p2b1_r1_review_probe.txt:18-27`, `p2b1_r1_edge_probe.txt:17-19`):

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep -E "weapon-slot ids|no pressable row|closed door"
[r1] catalogue weapon-slot ids=7 ["w_laser", "w_cannon", "w_rocket", "w_mine", "w_plasma", "w_railgun", "w_mining"]
[r1] weapon ids with no pressable row: ["w_mining"]
[r1] the closed door's own seam: panel.buy_module(w_mining) = true | log 0 -> 1 | signals=["credits", "modules"] | owned=1
$ ... res://tests/probe_r1_p2b1_edge.tscn | grep w_mining
[r1b] w_mining owned=1 ; panel.install_module(w_mining) = true | footer=["INSTALLED · MINING LASER · W2/danger=false"] | fit_legal=true
```

So the seam and the fit path both work; only the row is missing, and with no row the mining
laser **cannot be obtained anywhere in play** (the AUCTION is future, 10 §2).
*Why this is the reviewer's to flag, not to decide:* the brief contradicts itself — **§1** says
"the six weapon modules of 09 §3.1 are purchasable … `w_cannon` 1 200, **`w_mining` 600**,
`w_rocket` 2 400, …" (no `w_laser`) while **§3** says the rows are "one per module in 09 §3.1's
table order (`w_laser` 900 first, … `w_mining` 600)" (seven ids, no 09 §3.1 row for `w_mining`).
09 §3.1's table itself has six rows and `w_mining` is 09 §4 item 7. D0 recorded the same
discrepancy and left it standing (`p2b1_d0_report.md` §7 finding 1); `WAVEBOARD`/CONTRACTS §12
carry the brief's bytes unchanged. W2 shipped the §3 reading and disclosed it.
*Fix if the owner ticks "seven rows":* `&"w_mining"` in `MODULE_ROWS` plus one transcribed
EFFECT string (09 §3.1's own note: "The mining laser (`w_mining`, §4 item 5) is family tool with
shield rule rocks only" — note the doc's own §4 item number for it is *7*), and nothing else:
the seam already sells it, `ShipFit` already allows it in a W cell and the icon ships
(`assets/icons/module/icon_module_w_mining_48.png`). *Fix if the owner ticks "six rows = §3.1":*
one sentence in `docs/gameplay/09_ship_slots_modules.md` §4 item 7 saying the AUCTION is the
mining laser's door, so the gap is documented rather than accidental. Either way the owner's tick
is what unblocks the file, and I have tiered it MED because the wave's §1 deliverable list names
`w_mining` as purchasable.

### LOW — eight items, written to `.agents/gen/LOW_BACKLOG.md` as L76–L83

| # | Item | Evidence |
|---|---|---|
| L76 | The pane's own copy still describes an ammunition-only surface: `AMMUNITION AND CONSUMABLES · 5 PACKS IN THE CATALOGUE`, `IDS laser · cannon · rocket · mine · plasma` | `p2b1_r1_edge3_probe.txt:12-13` |
| L77 | A third refusal wording, `REFUSED · FIT ILLEGAL`, beyond the pin's two, reachable only from a fit another API caller wrote | `p2b1_r1_review_probe.txt:112-115`, `p2b1_r1_fit_probe_rerun.txt:70` |
| L78 | ACTION precedence: a fitted module with an empty W cell offers `BUY`/`INSTALL`, never `REMOVE` (the strip covers removal in every state) — W2's disclosed reading, owner tick recommended | `p2b1_r1_review_probe.txt:30,59`, `p2b1_r1_persist_probe.txt:17` |
| L79 | The purchase seam trusts the caller's price: `panel.buy_module` always passes the catalogue cost, but `profile.buy_module(id, 1)` charges 1 and `(id, 0)` is free | `p2b1_r1_edge_probe.txt:46-48`, `p2b1_r1_review_probe.txt:131-132` |
| L80 | REMOVE/SWAP hand back `base_module_id(entry)`, not the entry: with an inventory record present the returned id is the base (a new base record appears beside the untouched instance); with the record gone the entry returns as itself and the strip then renders `W1 MOD_0007` while its base id's row reads `FOR SALE` | `p2b1_r1_edge_probe.txt:41-45`, `p2b1_r1_edge2_probe.txt:8-15`, `p2b1_r1_edge3_probe.txt:4-10` |
| L81 | The seed writes a whole fit through `set_fit`, a method §12 rule 2 does not name (rule 2 lists `set_fit_slot`/`clear_fit`); the panel still only requests, and the alternative ships an unlaunchable hull | `outfitting_panel.gd:1060-1067`, `p2b1_r1_edge_probe.txt:23-29` |
| L82 | Housekeeping: nine untracked R1/W1/W2 probe scripts sit in `vajb-orbit/tests/` (a committed tree), one of them a superseded scratch probe that was edited by another session mid-review — the boundary commit should ship the probes deliberately or drop them | `git status --short`, §0's mtime note |
| L83 | The brief's own icon-size tension: §2 calls the OUTFITTING construct "40 px icon" while §3's bullet asks for a "48 px module icon"; the shipped pane is 48 for the module rows, 40 for the ammo rows, and §7.1's art map now records both | `p2b1_r1_layout_probe.txt:20-31`, `STATION_HUB.md:686` |

D0's two stale-copy items (`STATION_HUB.md:49` "4 hulls", `10_ship_acquisition.md:154`
"09 §4.6") are L84, recorded here so they are not lost with D0's report alone.

---

## 4. What I did not re-measure, and why

* **The pre-wave gate baseline (378) and W1's midpoint (380).** Re-deriving them needs the
  wave's nine files stashed; another session was editing `vajb-orbit/tests/` during my pass, so
  stashing would have destroyed its state. The arithmetic is consistent (387 − 7 = 380,
  380 − 2 = 378) and both are the wave's own records.
* **The live station render (`project_run` + `editor_screenshot`, W2 §10).** Deliberately not
  repeated: L18 records that the station's boot/market normalisation **writes the player file**,
  and the other session holds the editor. The construct is instead measured geometrically,
  headlessly, behind the shell's own wiring and with a scratch save.
* **A kind of check I tried and could not reach:** I looked for a path that installs a module the
  account does not own (`install_module(w_railgun)` with none owned → `false`), that writes an
  illegal fit through the surface (the only illegal candidate the panel can propose is the
  over-budget one, which is refused), that destroys or duplicates a module across a swap
  (credits and the module census balance exactly), or that empties a W cell without handing the
  module back (`remove_module` on an empty cell → `false`; the strip's REMOVE hands the module
  back — measured after a reload). None exists in the shipped code paths.

---

## 5. Close-out note for the orchestrator

* Gate re-run: **387 / 0**, exit 0 (I measured it; W2's number matches).
* W2's probe re-runs byte-identically; every number W1, W2 and D0 published that I could check
  myself reproduces.
* **R1 leaves HIGH none, MED two, LOW eight.** Per the brief's run order, F1 exists to take
  R1's MED **only**; MED-1 needs `ui/screens/station.gd` added to the fixer's file set (or a
  re-tier onto the next wave), and MED-2 needs the owner's tick between the brief's §1 and §3
  lists before a fixer may move a row. If the orchestrator prefers not to widen any file set,
  both MEDs can be re-tiered to LOW with that reasoning recorded — neither breaks the surface:
  a module purchase refusal shows a wrong number, and one 600 CR tool has no shop.
* LOW-1…LOW-8 (plus D0's two stale lines) are in `.agents/gen/LOW_BACKLOG.md`; the re-runnable
  checks are `vajb-orbit/tools/r1_p2b1_format_law.py` and
  `vajb-orbit/tools/r1_p2b1_signature_audit.py` (both exit 0 today), and the evidence set is the
  twelve `p2b1_r1_*` captures in `.agents/gen/`.
