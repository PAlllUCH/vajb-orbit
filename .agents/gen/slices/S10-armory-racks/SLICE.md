---
slice: S10
phase: P2
lane: code
status: active
gate_baseline: "770/0"   # S8's close, 2026-09-24
---

# S10 — ARMORY interactivity (owner-reported, live)

## Goal

The ARMORY's battery-rack window works through **real input**: a rack can be
selected, an inventory weapon can be dragged onto a rack and committed, and the
pane shows what a battery will fire and what it costs in ammo.

## In scope

- The owner's four verbatim sentences (see `S10_BRIEF.md` §Owner report) measured
  through real UI input, not by calling handlers directly.
- Whatever the audit proves broken, fixed in the pane that owns the seam
  (`ui/station/armory_panel.gd` / `.tscn`, `armory_style.gd`), or reported as a
  D7-restyle regression if the A/B proves it worked before 2026-09-24.
- Any missing readout the pin actually requires (checked against STATION_HUB
  §5.11, `09_ship_slots_modules.md` §11, CONTRACTS §17, UI_SPEC §3.10).

## Out of scope

- FITTING drag-and-drop (S8's O1/O2 owner UX call is still open — do not port
  anything into `fitting_panel.gd` here).
- Flight-side weapon-group keys, HUD ammo readouts, and the launch briefing
  (S8's H1 closed those).
- Any balance number, price, cadence or damage value.
- `docs/gameplay/18_engine_spec.md` (owner-locked).

## Acceptance criteria

- [ ] AC1 — the owner's "can't select current gun battery" is either fixed or
      proven already reachable, with the input path named.
- [ ] AC2 — a **real** drag (press on an inventory row, move, release on a rack
      bay) commits through `fit_into_rack`; the probe drives real `InputEvent`s
      and reports the Control that receives the drop.
- [ ] AC3 — the drag works on all seven racks and on a rack whose bay is empty.
- [ ] AC4 — the pane's per-battery readout answers "what ammo does this battery
      use" (or the audit proves the pin does not require it and files the gap as
      an owner tick), and the pane's racks show their state without a click.
- [ ] AC5 — the gate holds (`770/0` baseline) and every probe is on a scratch
      store.
- [ ] AC6 — an A/B against the pre-restyle tree says whether this is a D7
      surface regression or a never-wired seam.

## Worker file sets

| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S10-A0 | `vajb-orbit/tests/`, `vajb-orbit/tools/` (measure only) | `S10_BRIEF.md` |
| S10-B1 | `vajb-orbit/ui/station/armory_panel.gd`, `vajb-orbit/tests/` | `S10-B1_BRIEF.md` (written from A0's report) |
| S10-R1 | `vajb-orbit/tests/`, `vajb-orbit/tools/`, `docs/CONTRACTS.md` | `S10_BRIEF.md` |

## References

- `docs/design/STATION_HUB.md` §5.11 — the ARMORY rework pin (drag-and-drop
  battery composition, the `B1..B7` drop zones) and D7's **surface-only** restyle
  note; §5.1 for the pre-S5 rows.
- `docs/CONTRACTS.md` §17 (batteries v2 / the rack transactions), §16 (the
  composed `fit_into_rack`), §21 (the owner's O1/O2 table), §9 (the gate).
- `docs/gameplay/09_ship_slots_modules.md` §11 (battery composition).
- `docs/design/UI_SPEC.md` §3.9/§3.10 (the console language D7 applied).

## Carries forward

- The owner's live ARMORY report (2026-09-24) is this slice's input; it is
  recorded verbatim in the brief.
- `L171` (`game/weapons.gd:607`) if the fix touches that file (it should not).
- The S8 review's **L170** lesson applies: a probe that asserts a *call* proves
  the handler, never the plumbing.
