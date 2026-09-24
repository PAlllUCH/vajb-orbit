# S10_BRIEF — ARMORY interactivity (the owner's live report, measured)

Wave `S10`, slice `S10-armory-racks`. Read in this order before working:
1. `AGENTS.md` (rules; the escalation ladder; the folder law)
2. `docs/design/STATION_HUB.md` **§5.11** (the ARMORY pin + D7's surface-only
   restyle note) and **§5.1** (the pane's pre-S5 rows)
3. `docs/gameplay/09_ship_slots_modules.md` **§11** (battery composition)
4. `docs/CONTRACTS.md` **§17** (the rack transactions), **§16** (the composed
   `fit_into_rack`), **§21** (the owner's O1/O2 rows), **§9** (the gate)
5. `docs/design/UI_SPEC.md` **§3.9/§3.10** (the console language D7 applied)
6. this brief end to end

## Owner report, verbatim (2026-09-24)

> "I'm still not able to either select current gun battery in ARMORY, drag
> equipped weapons to batteries, have preview of what ammo is used in battery,
> battery stats, overall ARMORY doesnt seem to work. You might need to spawn
> independent reviewer to check it."

S8 did not answer this. Its AC10 passed on a **direct-handler** probe, and S8's
own review filed the method as **L170** ("a probe that asserts a *call* proves
the handler, never the plumbing"). This slice re-measures through real input.

## What is already measured (do not re-derive, do re-check)

- **Q0's O1/O2 probe** called the three handlers directly —
  `ui/station/armory_panel.gd:1950 install_weapon` →
  `autoload/player_profile.gd:1316 fit_into_rack` → `set_battery_groups`
  (`:1252`) — and read `[[0]]` → `[[0,1]]`. **R1's AC10** re-ran the same
  method and passed it. Neither ever started a real drag.
- The pane's drag payloads exist: a barrel payload (`armory_panel.gd:203-238`,
  `_get_drag_data` on a barrel chip, `_can_drop_data`/`_drop_data` on a barrel
  target), the inventory row's `_get_drag_data` (`:266` →
  `drag_inventory`), and the rack body's `_can_drop_data`/`_drop_data`
  (`RackRow`, `:248-255` → `can_drop`/`drop` with `DROP_RACK_BODY := -1`).
- Hit-test filters set in code: inventory row `MOUSE_FILTER_STOP` (`:1443`),
  per-barrel `chip` STOP (`:1547`), the code-drawn `ConsoleWells` chrome IGNORE
  (`:688`). **The `RackRow` itself never sets `mouse_filter`** — measure what the
  viewport actually hits at a bay's centre.
- Selection exists as presentation only: `_selected_rack` (`:575`),
  `selected_rack()` (`:658`), `set_selected_rack()` (`:663`, "nothing is
  written — the frame is presentation"). Its **only caller in the whole project**
  is `_on_barrel_focused` (`:1583`), connected at `:1577` to a barrel chip's
  `name_button.focus_entered`. The pane declares **no** `_gui_input`/`_input`/
  `_unhandled_input` and no `weapon_1..7` key handling, so an **empty rack has
  no chip, no focus target and no selection path**; a plain click on a bay does
  nothing.
- Per-battery readout today is `RACK_SALVO` (`:134`) / `RACK_READY` (`:143`) plus
  the barrel chips. The pane's ammo section (`:932`) is the cargo-purchase rows.
  **Whether a per-battery ammo preview is pinned at all is an open question the
  audit answers** against §5.11 / 09 §11 / UI_SPEC §3.10.
- **D7 restyled this pane on 2026-09-24** (STATION_HUB §5.11: "Surface only —
  every seam, number and transaction in this section, 09 §11 and CONTRACTS §17
  survives untouched"; `armory_style.gd`, `ConsoleWells`). A restyle that eats
  input is a **D7 regression**, not a spec gap — the A/B below decides which.

## The pinned UX (STATION_HUB §5.11, verbatim in substance)

A left list of **inventory weapons** (the OWNED MODULES rows) and right-side
**battery racks `B1..B7`** mapped to `weapon_1..7`; dragging a weapon row onto a
rack installs it into the rack's **next free W cell** through the §13/§16
transactions (refusals write nothing); dragging within/between racks re-orders
and swaps; a `✕` on a barrel removes it back to inventory. Ammunition rows stay
in the pane and buy cargo units (units = rounds / 10).

## Task — Phase A0 (this dispatch): measure, fix nothing

Answer these five questions with measurements and `file:line`, and deliver
`S10-A0_report.md`:

1. **Can a rack be selected through real input?** Click a bay; click a barrel
   chip; press `1..7` while the pane has focus. Report what changes
   (`selected_rack()`, the ember frame) and what does not. Name the seam that
   would have to carry the input.
2. **Does a real drag commit?** Drive a genuine press → move → release from an
   inventory row onto a rack bay through the **real input pipeline** (see
   methods) and report: does the drag start, does the drop arrive, which Control
   receives it, and does `battery_groups()` change? Compare with Q0's direct
   call. Test an **empty** bay and a **filled** one, on at least two racks.
3. **What is the pane actually showing per battery?** Inventory the rack row's
   live Controls (text, visibility, rects) and say whether the owner's "what
   ammo is used in battery / battery stats" exists, is pinned and missing, or is
   not pinned at all (then it is an owner tick, not a build).
4. **Is the pane reachable and interactable at all?** The station screen opens
   the ARMORY (`ui/screens/station.gd`); confirm the pane's rails/scroll/plates
   do not swallow clicks, and name any Control that does.
5. **A/B: was it ever wired, or did D7 break it?** Run the same probe against the
   pre-restyle tree (`git worktree add` at `db4dbcd` — the parent of `faa24ad`,
   which introduced `armory_style.gd`; **A0 corrected this brief**: `12278d2^` is
   not pre-restyle) and report whether the drag/selection path differs. This
   decides whether the fix is a UI-plumbing repair or a restyle regression.

### Methods (in order of preference)

- **Live editor game** (closest to the owner's window): `godot-ai`
  `session_manage(op='list')` must show the session; locate the pane's nodes with
  `game_manage(op='get_ui_elements')`, drive with `input_key`/`input_mouse`
  (note: `input_action` raises no `InputEvent`, so drags need real mouse events),
  read state with `game_eval`, and use `editor_screenshot(source='game')`
  sparingly at `max_resolution` 640. A backgrounded game window freezes its main
  loop and screenshots go stale — focus it or fall back.
- **Headless real-input probe** (deterministic, preferred for the record):
  instantiate the station screen + ARMORY pane in a probe scene and inject
  **real** events with `Input.parse_input_event(InputEventMouseButton/Motion)`, so
  the `Viewport`'s drag routing and hit-testing run. Name the receiving Control
  with `Viewport.gui_get_hovered_control()` / `gui_get_drag_data()` at each bay's
  global centre. A probe that calls `can_drop`/`drop` directly is **not
  evidence** for this wave.
- **Static audit**: `mouse_filter` on the drop zone and every ancestor/sibling
  that can cover it; `rg -n 'set_selected_rack' vajb-orbit/` (one caller today);
  whether any input handler exists in the pane.

## Hard rules

- **A0 fixes nothing.** No `game/` or `ui/` writes; the file set is
  `vajb-orbit/tests/`, `vajb-orbit/tools/` plus the slice's own folder. Shell
  edits are forbidden (the hook gap).
- **Every probe on a scratch store** (`XDG_DATA_HOME=$(mktemp -d)`, and repoint
  `save_path` for any probe that boots `PlayerProfile`) — the live `user://`
  store is the owner's account. Record the live pair's md5s before and after.
- Every run bounded (`--quit-after`, self-quitting probes); never leave a command
  in the background; read a probe's stdout from a log you own.
- Report ≤120 lines, one evidence line per finding, `file:line` citations, no
  pasted source.
- Say the **bucket** for each finding: (1) implementer decides, (2) changes a pin
  / a file set, (3) taste or an owner call.

## Output contract

`S10-A0_report.md` (from `_templates/REPORT.md`): the five answers, each with its
verdict (reproduced / not reproduced / missing feature / regression), the exact
Control and `file:line` seam, the bucket, and the probe paths. A short "what the
fix wave must touch" section so `S10-B1`'s brief can be written from it.

## Run order after A0

A0 → (brief written from its report) → B1 fix → R1 review → F1 only on HIGH/MED
→ close-out (gate ×2 scratch stores, `verify --baseline s10_repro_start` for A0 /
`s10_start` for the fix wave, WAVEBOARD, wave-boundary commit; CONTRACTS §9/§10
take the next free rows read at close-out, sequenced after any parallel lane).

## Owner ticks this slice will owe

The four sentences' outcomes; anything A0 files as not-pinned (e.g. a per-battery
ammo readout if nothing pins it); plus S8's still-open list (O1/O2's FITTING UX
call, O3, L168, L169, `REFINE ALL`, the refinery hide, the live-profile restore).
