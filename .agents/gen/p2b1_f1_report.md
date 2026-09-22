# P2-B1 — F1 report: the fixer pass (R1's two MED findings, one pass)

**Worker:** F1 (coder — fixer). **Wave:** P2-B1 — the weapon fit surface.
**Brief (law):** `.agents/gen/p2b1_weapon_fit_wave_task.md` §4 row F1 ("Only R1's HIGH/MED, one
pass, each re-measured before and after with R1's own command") + §6.
**Findings (authority):** `.agents/gen/p2b1_r1_report.md` — **HIGH none, MED two, LOW eight**.
R1's §5 close-out widened this pass's file set to `ui/screens/station.gd` for MED-1; MED-2 was
adjudicated to **seven rows** by the owner's dispatch (the wave's own §1 deliverable names
`w_mining` 600 as purchasable and the mining-laser swap is the launch-fit gate's symptom 2).
**File set (`VAJB_WORKER_FILES`):** `vajb-orbit/ui/station/outfitting_panel.gd`,
`vajb-orbit/ui/screens/station.gd`, `vajb-orbit/tests/`. Three files touched, all inside the
set; **no** `assets/**`, no theme, no `project.godot`, no `addons/**`, no `docs/**`, and **no
LOW** was fixed.
**Measured gate (mine):** **`[SUMMARY] passed=389 failed=0`**, exit 0 (was **387 / 0** before
this pass — the growth is the two new tests, additions only).

---

## 0. What I ran

| Capture | Command |
|---|---|
| `p2b1_f1_gate_before.txt` | `godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200` — **before** the first edit |
| `p2b1_f1_gate_after.txt` | the same — **after** the last edit |
| `p2b1_f1_suite.txt` | the same, `-- --suite=test_p2b1_outfitting_panel` |
| `p2b1_f1_before_review.txt` / `p2b1_f1_after_review.txt` | `godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn --quit-after 3000` (**R1's own probe**, before and after) |
| `p2b1_f1_w2probe_after.txt` | `... res://tests/probe_p2b1_panel_fit.tscn` (**W2's** probe, re-run) |
| `p2b1_f1_w1probe_after.txt` | `... --script res://tests/probe_p2b1_buy_module.gd` (**W1's** probe, re-run) |
| `p2b1_f1_layout_after.txt` | `... res://tests/probe_r1_p2b1_layout.tscn` (the laid-out pane, re-measured) |
| `p2b1_f1_format_law.txt` | `python3 vajb-orbit/tools/r1_p2b1_format_law.py` — **21 checks, 0 failures** |
| `p2b1_f1_signature_audit.txt` | `python3 vajb-orbit/tools/r1_p2b1_signature_audit.py` — **25 signatures, drift 0** |

Every Godot run is bounded (`--quit-after`; the probes also self-quit) and **no** command was
left in the background.

**Probe hygiene (L17).** Every probe borrows the shipped `PlayerProfile` and hands it back; the
owner's file is byte-identical before and after the whole pass:
`8dffef0c5bf8bb9f6444463d0d31f506  ~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg`
(checked before the first probe and after the last one — the same md5 R1 recorded).

---

## 1. The gate I measured myself

```text
BEFORE   godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=387 failed=0            exit 0        (387 [PASS], 0 [FAIL])   p2b1_f1_gate_before.txt
AFTER    the same command
[SUMMARY] passed=389 failed=0            exit 0        (389 [PASS], 0 [FAIL])   p2b1_f1_gate_after.txt
AFTER    ... -- --suite=test_p2b1_outfitting_panel
[SUMMARY] passed=9 failed=0              exit 0        (was 7)                  p2b1_f1_suite.txt
```

387 → 389 is **+2, additions only**: `test_every_catalogue_weapon_has_a_pressable_row` (MED-2's
closed-door guard) and `test_shell_refusal_names_a_module_cost` (MED-1's fabricated-price
guard). No existing test's assertion was weakened: `test_module_rows_are_09_3_1s_table_in_order`
gained assertions (it now checks the seventh row against 09 §4 item 7 as well as the six table
rows) and `test_mandatory_set_is_untouchable`'s row count moved 6 → 7 because the row set did.

---

## 2. MED-1 — the fabricated price (`… · 0 NEEDED`) — **FIXED**

### 2.1 Before (R1's own command, re-run by me)

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep 'station.gd _'
[r1] station.gd _entry_cost(w_railgun)=0 (a module is not an ammo pack, a ship or an upgrade)
[r1] station.gd _refusal_text(insufficient_credits, w_railgun)='REFUSED · NOT ENOUGH CREDITS · 0 NEEDED'
[r1] station.gd _refusal_text(insufficient_credits, laser)='REFUSED · NOT ENOUGH CREDITS · 120 NEEDED' (the ammo pack, for contrast)
```

Reproduced exactly as R1 published it, `p2b1_f1_before_review.txt`.

### 2.2 The change — one place, `ui/screens/station.gd:478-489`

`_entry_cost` and `_entry` resolve the `purchase_failed` id, and only the ammo packs, the ships
and the upgrades were in the chain. The chain gains the fourth catalogue the surface now sells
from — nothing else, no new string, the existing wording template untouched:

```gdscript
func _entry(id: StringName) -> Dictionary:
	## purchase_failed carries only the reason and the id, so the copy resolves the
	## entry and its price from the catalogue the panel bought from: the ammo packs,
	## the ships, the upgrades and the modules (P2-B1's OUTFITTING rows).
	var entry := Catalog.ammo_pack(id)
	if entry.is_empty():
		entry = Catalog.ship(id)
	if entry.is_empty():
		entry = Catalog.upgrade(id)
	if entry.is_empty():
		entry = ModuleCatalog.module(id)
	return entry
```

`ModuleCatalog` is the shipped global `class_name` the pane already reads (`game/module_catalog.gd`
— the catalogue's own row for `w_railgun` is 09 §3.1's 5 200), so the fix adds no preload, no
lookup table and no second price.

### 2.3 After

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep 'station.gd _'
[r1] station.gd _entry_cost(w_railgun)=5200 (a module is not an ammo pack, a ship or an upgrade)
[r1] station.gd _refusal_text(insufficient_credits, w_railgun)='REFUSED · NOT ENOUGH CREDITS · 5 200 NEEDED'
[r1] station.gd _refusal_text(insufficient_credits, laser)='REFUSED · NOT ENOUGH CREDITS · 120 NEEDED' (the ammo pack, for contrast)
```

**Reading of `5 200 NEEDED` (the requested "5200 NEEDED"):** the template is
`"REFUSED · NOT ENOUGH CREDITS · %s NEEDED" % _format_int(cost)` and `_format_int` is the
shell's own thousands-space grouper (`station.gd:609-618`) — the same grouping the pane's PRICE
cell uses (`5 200`), the same the document's own table prints (`| 5 200 |`), and the same the
ammo line has always used (`120 NEEDED`). The number is now **5 200, not 0**; no new string and
no new number was invented. The *digits* the copy names are 09 §3.1's, which is what the test
pins (§2.4).

**Reachability is unchanged and real** (R1 §MED-1): the module rows are pressable while `LOCKED`
and `_on_module_pressed` → `buy_module` → `purchase_failed(reason, id)` → `_on_purchase_failed`
→ `_refusal_text(reason, id)` is the shipped path (`player_profile.gd:657` emits the id;
`station.gd:445-450` renders it). This fix lands on that path, not beside it.

### 2.4 The test (new) — `test_shell_refusal_names_a_module_cost`

`vajb-orbit/tests/test_p2b1_outfitting_panel.gd` (the wave's suite, which already mounts the pane
behind the shell's own wiring). It instantiates the shipped `ui/screens/station.gd` the way R1's
probe does and asserts, with the expected numbers **parsed out of 09** (never literals):

* the shell's copy for `w_railgun` names 09 §3.1's table cost (digits `5200`) — not `0`;
* the shell's copy for `w_mining` names 09 §4 item 7's cost (digits `600`);
* `_entry_cost(w_railgun)` is the catalogue's 5 200;
* the ammo pack's line is **unchanged** (`laser` still reads its catalogue cost) and an id no
  catalogue ships still resolves to nothing rather than to a number.

Suite: **9 passed, 0 failed**.

---

## 3. MED-2 — the mining laser has no door — **FIXED (seven rows)**

### 3.1 Before (R1's own command, re-run by me)

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep -E 'no pressable row|weapon-slot ids'
[r1] catalogue weapon-slot ids=7 ["w_laser", "w_cannon", "w_rocket", "w_mine", "w_plasma", "w_railgun", "w_mining"]
[r1] weapon ids with no pressable row: ["w_mining"]
$ ... | grep 'pane rows='
[r1] pane rows=6 ids=[&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_railgun"]
```

### 3.2 The change — `ui/station/outfitting_panel.gd:95-121`

The six shipped rows stay exactly where they were and in their order; 09 §4 item 7's mining laser
becomes the seventh:

```gdscript
const MODULE_ROWS: Array[StringName] = [
	&"w_laser",
	&"w_cannon",
	&"w_rocket",
	&"w_mine",
	&"w_plasma",
	&"w_railgun",
	&"w_mining",
]
```

and its EFFECT string is 09's own words, verbatim as adjudicated (09 §3.1's family / shield-rule
note plus §4 item 7's W slot sentence) — `EFFECT_TEXT` gains one entry and no other entry moved:

```gdscript
	&"w_mining": "mining laser, tool family, rocks only; occupies a W slot",
```

Nothing else was needed and nothing else was touched: the seam already sells any catalogue id
(W1's `buy_module`), `ShipFit` already allows it in a W cell, the icon ships
(`assets/icons/module/icon_module_w_mining_48.png`), and the row renders its own catalogue name,
`W SLOT · DRAW 1` meta and 600 CR price. The two doc comments that claimed "six rows / no door"
were corrected in place.

### 3.3 After

```text
$ godot --headless --path vajb-orbit res://tests/probe_r1_p2b1_review.tscn | grep -E 'no pressable row|weapon-slot ids|pane rows='
[r1] pane rows=7 ids=[&"w_laser", &"w_cannon", &"w_rocket", &"w_mine", &"w_plasma", &"w_railgun", &"w_mining"]
[r1] catalogue weapon-slot ids=7 ["w_laser", "w_cannon", "w_rocket", "w_mine", "w_plasma", "w_railgun", "w_mining"]
[r1] weapon ids with no pressable row: []
```

The missing list is **empty** and the row count reads **7**. The full before/after diff of R1's
probe (`diff p2b1_f1_before_review.txt p2b1_f1_after_review.txt`) moves exactly these lines and
their consequences:

* `w_mining: … row=false pressable=false | status='<no row>'` → `row=true pressable=true | status='FOR SALE'`;
* the closed door's own seam probe (`panel.buy_module(w_mining) = true`, the one write that made
  the log counter read 1 at the start) no longer runs, so every later `log N -> M` line is one
  lower — the *balances, cells, strips and refusals are all unchanged*;
* one new informational line in the state-machine section: `w_mining: status='FOR SALE' action='BUY'`;
* `pane rows outside 09 section 3.1's table=["w_mining"]` — **expected and by design**: the
  seventh row is 09 §4 item 7's, which is precisely what this fix adjudicated. R1's own probe
  already carried `WEAPON_IDS` as "09 section 3.1's table plus 09 section 4 item 7's mining
  laser: every weapon module 09 ships" (`probe_r1_p2b1_review.gd:40-42`).

**Geometry (R1's layout probe, re-run):** the pane gains exactly one 76 px row, in the right
place — between `ModuleRailgun` and the ammo header — carrying the module rows' own 48 px icon
column and 160 px action column, and the scroll body grows by exactly one row height:

```text
[r1e]   ModuleMining pos=(1,785) size=(950,76) icon=pos=(13,793) size=(48,71) action_label_width=160
[r1e]   HeaderMargin … pos=(1,873)     (was 791)      OutfittingRows … pos=(1,916)   (was 834)
[r1e] the scroll body is taller than the viewport: body=1272 scroll=2      (was body=1190)
```

The rest of the layout diff is those two blocks moving down by 76 px; nothing else moved.

### 3.4 The tests (one updated, one new)

* **Updated — `test_module_rows_are_09_3_1s_table_in_order`**: 09 §3.1's six rows must all be
  present, in the table's own order, with the table's own costs, draws, PRICE cells, metas and
  effect prose (unchanged assertions), **and** the seventh row must be `w_mining` riding beside
  them at **09 §4 item 7's own draw and cost** — which the test parses out of the document
  (`_document_item(7, "**Mining laser rule")` → `draw 1`, `cost 600`, "occupies a W slot") and
  compares with the catalogue, the PRICE cell and the `W SLOT · DRAW n` meta. Its EFFECT is
  compared with the panel's transcription **and** that transcription is tied back to the
  document's words (09 §3.1's note must carry "tool" and "rocks only", item 7 must carry
  "occupies a W slot"), so the new string cannot drift from 09 either.
* **New — `test_every_catalogue_weapon_has_a_pressable_row`** (the closed-door guard): every
  weapon-slot id in `ModuleCatalog` must have a row, that row must be enabled and must carry an
  ACTION; then the guard proves the door opens by pressing the mining laser's own row and
  asserting it buys one, charges 09 §4 item 7's cost, and reads `OWNED ×1`. This is the test
  that would have caught MED-2.
* **Updated — `test_mandatory_set_is_untouchable`**: the row-count assertion moved 6 → 7 (the
  adjudicated row set) with the message naming 09 §4 item 7; every other assertion in it (no
  engine/reactor row, no engine installable into a W cell, the mandatory set intact) is
  unchanged and still passes.

---

## 4. What I deliberately did not touch

* **Every LOW (L76–L83 + D0's two lines)** — untouched, still in `.agents/gen/LOW_BACKLOG.md`.
  In particular L78 (a fitted module with an empty cell offers BUY/INSTALL), L79 (the seam trusts
  the caller's price), L80 (`base_module_id` on a swap), L81 (the seed's `set_fit`), L83 (the
  40/48 px icon tension), L76 (the pane's stale "ammunition only" subtitle) and L77 (the third
  refusal wording) are all as R1 found them.
* **The adjudicated exception I did not extend**: MED-2's fix is the seventh row and its EFFECT
  string only. No second surface (AUCTION), no slot picker, no STATUS/ACTION change, no new
  refusal wording.
* **Shipped bytes outside the three files**: `git status --short` shows exactly the wave's own
  set plus mine — `station.gd` (**+5 / −1**: one comment sentence widened, two code lines added),
  `outfitting_panel.gd` (the W2 body plus my three regions: one header comment, the `MODULE_ROWS`
  comment + one id, the `EFFECT_TEXT` comment + one entry), and the wave's new suite. No
  `assets/**`, no theme, no `project.godot`, no `addons/**`, no `docs/**`, and
  `player_profile.gd` / `test_p1_profile.gd` / the `.tscn` are **W1's and W2's**, untouched by
  this pass.
* **R1's two audit tools re-run clean** on the fixed tree: format law **21 checks / 0 failures**,
  signature audit **25 signatures / drift 0** (so the shell's `_entry` edit moved no pinned
  signature, and the six transcribed 09 §3.1 EFFECT strings are still byte-equal).

---

## 5. Notes for the orchestrator (no action needed unless you want them)

1. **The enforcement hook does not understand Linux paths.** `.crush/hooks/enforce_worker_files.py`
   normalises only the Windows roots (`g:/mój dysk/projekty/vajb orbit/`), so an **absolute**
   Linux path (`/home/…/vajb-orbit/ui/screens/station.gd`) never matches the relative entry and
   the first edit of this pass was denied. The pass proceeded by addressing files
   **workspace-relative** (which the hook compares correctly). Worth a LOW: either strip the
   workspace root generically or accept both forms, otherwise every future Linux worker hits it.
2. **R1's probe prints one line that is now expected rather than suspicious**:
   `pane rows outside 09 section 3.1's table=["w_mining"]`. The row set is deliberately §3.1's
   six **plus** §4 item 7's mining laser; a future reviewer should read that line against the
   owner's seven-row adjudication, not against the six-row reading.
3. **The probes' exit-time leak warning scales with the row count**: R1's probe printed
   `6 ObjectDB instances were leaked` / `2 resources still in use` before, `10` / `4` after —
   i.e. the one extra row's own controls. Same warning class as before, not a new leak; the
   panels' teardown is unchanged.
4. **W2's probe re-runs clean and grows as expected** (`MODULES rows=7 … w_mining=600/draw1`),
   and **W1's probe re-runs byte-identically except its log timestamp** (the same single
   irreproducible byte-range R1 documented) — so neither neighbour's evidence chain is broken by
   this pass.

---

## 6. Close-out summary

| Finding | Tier | Status | Before (R1's command) | After (same command) |
|---|---|---|---|---|
| MED-1 the fabricated price | MED | **fixed** | `_entry_cost(w_railgun)=0` → `'… · 0 NEEDED'` | `_entry_cost(w_railgun)=5200` → `'… · 5 200 NEEDED'` |
| MED-2 the mining laser has no door | MED | **fixed** | `no pressable row: ["w_mining"]`, `pane rows=6` | `no pressable row: []`, `pane rows=7` |
| HIGH | — | none existed | — | — |
| LOW ×8 (+2 from D0) | LOW | **not touched** | — | — |

Gate: **`passed=389 failed=0`, exit 0** (measured by me; 387 before the pass, +2 = the two new
tests). Suite `test_p2b1_outfitting_panel`: **9 / 0**. Owner profile: md5 unchanged.
