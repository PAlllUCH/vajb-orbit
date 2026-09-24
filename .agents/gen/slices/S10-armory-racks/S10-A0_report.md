---
slice: S10
worker: S10-A0
model: deepseek/deepseek-v4-flash
status: informational
gate: "770/0 (unchanged, scratch store)"
---

# S10-A0 report — the ARMORY, measured through real input

## Result
The owner's four sentences split into five facts: **(1)** rack selection is wired to **no** input path; **(2)** the barrel-chip drag is **dead — a D7 regression** (pre-D7 committed a move, HEAD cannot start the drag); **(3)** the `✕` remove is dead for the same cause; **(4)** the pinned SALVO drum reads **blanks for instance-keyed cells**, the owner's own fit shape; **(5)** a refused hover gives **no feedback at all**. The inventory→rack install drag, by contrast, **works** (`[[0]] → [[0,1]]` on a real press/move/release). Gate 770/0 before and after; live profile md5 `acf3161108605c9cc30f710099a11e24` unchanged across every run.

## Probe paths (re-runnable)
- Headless real-input probe (A0's own files, the record): `vajb-orbit/tests/probe_s10_a0_armory.gd` + `.tscn`, run as `XDG_DATA_HOME=$(mktemp -d) godot --headless --path vajb-orbit res://tests/probe_s10_a0_armory.tscn --quit-after 4000` (log `/tmp/s10_a0_head_final.log`). It mounts the shipped `station.tscn`, seeds a scratch account and injects genuine `InputEventMouseButton`/`Motion`/`Key` via `Input.parse_input_event`, so `Viewport` hit-testing and drag routing run.
- **Injection canary** (same probe, `DragCanary` above the station): a probe-owned drag completes — `CANARY drags=1 drops=1` — proving the pipeline before any pane reading.
- A/B tree: `git archive db4dbcd vajb-orbit | tar -x -C /tmp/s10_pre`, assets symlinked, `--headless --editor --quit` for the class cache, probe copied in (`/tmp/s10_a0_preD7c.log`).
- Live game, session `vajb-orbit@6069225ff44d8b75`: `get_scene_tree` read the whole station (all eight panes, `Armory` mounted) and `profile.cfg` was read read-only. `game_eval`/`editor_screenshot` could not run — **a backgrounded window freezes the helper's liveness probe** (AGENTS.md's fallback) — so input was driven headlessly. Disclosed: an early `game_eval` with a wrong node path raised a runtime error and parked the owner's game in a debugger break; it was stopped and relaunched on `res://ui/screens/station.tscn` (run token 4). No profile write (md5 pair identical).

## Q1 — rack selection through real input: missing feature (never wired), bucket 1
- The pane declares **no** input handler: `Q1 seam handlers=[]`; `_gui_input`/`_input`/`_unhandled_input`/`_shortcut_input` are all absent from `ui/station/armory_panel.gd`.
- Click a bay: the hit is the bay itself (`Rack2`/`Rack4[PanelContainer]`), `selected_rack()=0`, frames `[1,0,0,0,0,0,0]` unchanged, `status=[]`.
- Click a barrel chip at `(529,446)`: the hit is `Barrel1[HBoxContainer]`, `selected_rack()` stays 0 — the chip's `Name` Button, the only thing with `focus_entered → _on_barrel_focused` (`:1577-1583`), is **0 px wide** (Q2).
- Keys `1..7` with an inventory row focused: `weapon_1..7` are mapped and the action is **held** (`mapped=true action_pressed=true`), yet `selected_rack()` reads 0 for all seven — the drawn `(1)..(7)` hints (`RACK_KEY`, `:132`) advertise keys nothing listens for; `ui/screens/station.gd:181-210` handles only `ui_cancel`, `PageUp/PageDown`, shoulders.
- **Seam:** `set_selected_rack` (`:663`, only caller in the project `:1583`) needs a caller on a real event — a pane `_gui_input`/`_unhandled_input` mapping `weapon_1..7` plus bay clicks, or a per-bay Button. Wiring is bucket 1; what a selection should *do* beyond the ember frame (`:662`, presentation only) is bucket 3.

## Q2 — the real drag
**2a inventory → rack body: WORKS (not a defect).** Press on `OwnedWLaser[Button]` → `drag_data={kind:inventory, base:w_laser}`, hovered `Rack2[PanelContainer]`, `can_drop=true` → `battery_groups [[0]] → [[0],[1]]`, `fit.weapons ["w_laser","mod_0001",""]`, `INSTALLED · LASER MKII · B2`; onto a filled bay → `[[0,2],[1]]`, `INSTALLED · CANNON MKI · B1`. Q0/R1's reading holds — now through the plumbing, not the handler.

**2b a fitted barrel's chip is not draggable: REPRODUCED, D7 regression, bucket 1.**
- HEAD: chip `Barrel1` is `(509,424) 40x44`, `mouse_filter=0`, but its `Name` Button measures `(0,44)` with `custom_minimum_size=(0,0)` (`:1558`; `:1561` transparent ink; `_position_slots :1631` sizes it `(40,30)` but the chip's own `HBoxContainer` re-sorts it to width 0). The hover at the chip centre **and** at the Name rect centre both return `Barrel1[HBoxContainer]`; the real press/move yields `drag_data=<null>` (the Viewport asks `BarrelCell`, which has no `_get_drag_data`) → **no barrel drag can start**, groups unchanged.
- pre-D7 (`db4dbcd`): the same Button carried `custom_minimum_size=(160,0)`, measured `(160,29)`; the hover hit `Barrel1/Name[Button]`, the drag opened with `{kind:barrel, rack:0, position:0}`, `can_drop=true`, and the drop **committed**: `[[0,2],[1]] → [[2],[1],[0]]` + `MOVED · CANNON MKI · B3` — the restyle broke a working seam (the owner's "cannot drag equipped weapons to batteries").

**2c the `✕` on a barrel: REPRODUCED, same cause, bucket 1.** `Close` also measures `(0,44)` (`:1570 custom_minimum_size=ZERO`); a real click at its centre hits the chip and groups are unchanged. §5.11's "a `✕` removes it back to inventory" is unreachable by mouse at HEAD (pre-D7 it measured `(28,29)`).

**2d a refused drop is silent: measured, bucket 2.** With every W cell taken the drag opens over `Rack4[PanelContainer]` but `can_drop=false`, so the Viewport never calls `_drop_data`, `_refuse` (`:2112`) never runs and **no footer wording appears**; the pinned `REFUSAL_W_SLOTS_FULL` (`:171`) is unreachable through the only UI path. The owner's live account is in exactly this state, so a legitimate drag looks like "nothing happens". Changing when the refusal is emitted moves a pinned reading (§16 rule 9 / §5.11) → escalate.

**2e why the owner's live session feels inert.** Live `profile.cfg` (read-only): `active_ship="ship_vanguard"`, `batteries={}` (empty), Vanguard `weapons:["mod_0319","mod_0471","w_cannon"]` (all three W cells taken), spares `w_mining`/`w_laser`/`w_plasma` in the bag. With `_batteries` empty the profile derives one trailing rack holding every fitted weapon, so B1 looks full and B2..B7 empty; every inventory drop is then refused (2d, silently) and every barrel move is dead (2b). Trailing-rack reading is bucket 3 (S8's H2 row, an open owner tick); recorded, not changed.

## Q3 — what the pane actually shows per battery
- Draws: `Label='B1'`, `Key='(1)'`, `State='READY'` at **alpha 0.0** (`:1509`), a `Hint` on empty racks only, the `Salvo` strip (`caption='SALVO s'`, three cells) and a code-drawn `BayMarks` block per fitted cell; a rack with no cadence reads `salvo=---`.
- **Defect (bucket 1): the drum is blank for instance-keyed cells.** `_rack_cycle` (`:1651-1661`) resolves each cell with `WeaponComponent.weapon_id` on the **raw** fit entry; measured `weapon_id("mod_0002")=''` (`game/weapons.gd:2431-2436` strips only the `w_` prefix) while `weapon_id("w_cannon")='cannon'`, `interval_of("cannon")=0.6`. The hull's weapons were `["w_laser","mod_0001","mod_0002"]` → `figure=-1` on both racks holding a cannon. Only a base-keyed fit yields a figure, so a bought/rolled battery always reads blanks. Cure is one resolution (`_base_id`/`ModuleData`) before `weapon_id`; no pin text moves.
- **Not pinned (bucket 3, owner tick):** no per-battery **ammo preview** and no **battery stats** exist anywhere. §5.11 pins inventory + drags + `✕` + ammo rows; 09 §11 the group semantics; UI_SPEC §3.10 the bay plate + SALVO drum only; §17 keeps the ammunition rows as *cargo purchases*. Nothing pins a per-battery rounds/cost readout → a spec addition, not a build.

## Q4 — reachability
- The pane opens by default (`Module.OUTFITTING == 0`: `station.gd:64`, `:67`, `:146`) and the live game showed `Armory` mounted. No handler-less filter swallows a bay: every bay centre hits its own `Rack1..7[PanelContainer]` (`mouse_filter=0`), chain `RackRows:1 < RacksBox:1 < RacksMargin:2 < ArmoryBody:0 < ArmoryScroll:1 < Armory:0 …`. D7's chrome is inert — `ConsoleWells:2` (`:688`), `ConsolePlate:2`, `PaneFooter:2` — as are the station overlays (`Fade`/`Backdrop`/`Grain:2`; `LeaveConfirm:0` but `visible=false`). All seven bays sit inside the scroll rect, so the **drop zone is intact**; only the two things that must be *hit* on a fitted rack (2b/2c) are broken.

## Q5 — A/B: regression, not a never-wired seam
- Same probe, pre-restyle tree: the barrel drag commits (`MOVED · CANNON MKI · B3`); HEAD: `drag_data=<null>`. The diff that did it is D7's own commit `faa24ad` (which added `ui/station/armory_style.gd`): `custom_minimum_size = Vector2(COL_ACTION, 0.0)` → `Vector2.ZERO`, plus `_position_slots` (`:1617`).
- Selection is the opposite: pre-D7 has **no** `selected_rack`/`set_selected_rack`/`BayMarks` at all (`bay_marks=false`; `selected_rack` raises "Nonexistent function") — D7 introduced the frame *and* left it unwired. So Q1 is a never-wired seam; Q2b/2c are D7 regressions.

## Deviations
- The brief's A/B tree `12278d2^` is **not** pre-restyle: `faa24ad` introduced `armory_style.gd`/`ConsoleWells`, so the A/B used its parent `db4dbcd`. Bucket 2 — correct the brief text.
- A0 wrote two files in `vajb-orbit/tests/` (probe scene + script). Both are `probe_*`, so `headless_runner` does not discover them; the gate was re-measured anyway (770/0).

## What the fix wave must touch (for S10-B1's brief)
1. `armory_panel.gd:1550-1578` + `:1617-1636` — make the barrel `Name` plate and the `Close` `✕` hittable again (a real min width, or `_get_drag_data`/`pressed` on the chip itself): restores 09 §11's move/swap drags and §5.11's remove.
2. `:1651-1661 _rack_cycle` — resolve each cell to its base id before `weapon_id`, so the pinned §3.10 SALVO drum reaches a figure for rolled instances.
3. A selection seam calling `set_selected_rack` from real input (bay click and/or the drawn `(1)..(7)` hints): wiring bucket 1, what selection *means* bucket 3.
4. Refusal feedback when the preview refuses a hover (bucket 2 — tick before coding).
5. Tests that move: `tests/test_d7_armory.gd` (chip/`Name`/salvo rows) plus a new real-input suite modelled on `probe_s10_a0_armory.gd` — a probe that calls handlers is not evidence (S8's L170). Gate baseline 770/0.
6. Owner ticks: the per-battery ammo preview and battery stats (not pinned), the trailing rack, and seven racks drawn on a 3-W hull.
