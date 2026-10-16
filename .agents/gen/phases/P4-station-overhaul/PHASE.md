---
phase: P4
title: Station overhaul (the UX round)
status: active
slices: [D24]
---

> **Use when:** a phase opens. Manifest and index only — work lives in slice
> folders; this file never grows a work log. Opened 2026-10-12 from the owner's
> build-2 playtest: P3 closed the same day (rulings in STATION_HUB §22).

# P4 — Station overhaul (the UX round)

## Goal
The station becomes fully usable without trial and error: every buy is
confirmed, the hold is visible everywhere, the overview navigates by one
3×3 grid, the refinery crafts as well as refines, the exchange sells in bulk,
the shipyard build reads as materials in the house style, and undocking is a
sequence with sound. Design first — **no implementation worker dispatches
before D24's amendments land** (owner: "workers need a design, they cannot
work blindly").

## Owner requirements (verbatim, 2026-10-12 — the source list)

1. "the current way of seeing ship overview in armory is okay but a list of all
   equipped items in slots would be nice as well."
2. "i cannot see my current inventory anywhere on station, i can buy ammo but
   cannot see what i have on ship (ammo, materials, etc). a button for Cargo (C)
   to popup would be nice, same in space"
3. "i like refinery slots but it needs a buttons for 'Load all' and a better
   graphical representation of current available machines and running ones.
   Also i think the layout of buttons might need a bit of work. also in
   refinery another tab for crafting items and components not only refining
   ores."
4. "in exchange add a button to my items: sell or add checkbox so that i can
   check them and sell in bulk"
5. "every buy action needs to have popup with 'OK' button. So when i buy a ship
   there should be a popup: Are you sure you want to buy SHIP X for Y credits"
6. "the SHIPYARD build segment needs rework as well. i want it looking more like
   refinery/auction, the same style. now it only uses credits. it should be
   separated into different categories and use materials."
7. (tick 3) "i want it the same as [the six-tile grid] above, so a grid of 9 3x3
   buttons in total" — the OVERVIEW ruling.
8. (tick 6) "i want a launch sequence not only loading screen and some sound"
9. (tick 2) "In overview: armory and launch tokens not visible" — T-184.

Direction record: `docs/design/STATION_HUB.md` §22 (every item, with the
measured current state and its owning section).

## Slices (one checkbox per slice — tick at close-out)

- [x] **D24 — the station-overhaul design round.** Amend the owning docs with
      the actual numbers for all nine items above; every new value PROPOSED
      with its reversal; the tick list for the owner. `slices/D24-station-overhaul-design/`
      · runs after: — (phase opener) · baseline `d24_start` · closed 2026-10-12
- [x] **S42–S49 — the implementation waves, re-cut from D24's output.** Eight
      waves closed 2026-10-12 → 2026-10-14 (the grid, the armory equipped
      list + buy doors, the bulk sell, the refinery craft tab, the shipyard
      build view, the launch sequence + audio, the cargo overlay, the confirm
      doors); gate 1330 → **1422/0 ×2** at every boundary; the done rows
      verbatim in `_archive/dispatch_done_2026-10-14.md` and each recap in
      `MASTER_REPORT.md` §6.
- [x] **The C-key cargo overlay rework + its follow-up rounds (owner-directed,
      in-session; the designer-lane round cancelled).** The rework (2026-10-14,
      UI_SPEC §18.2 A10–A13) closed, then the owner's audit verdict drove the
      visual audit round (2026-10-15, A14–A17 + V1–V4, `tools/audit_sweep.gd`),
      the playtest-pass answers (A18–A20), the cargo-windows round (2026-10-16,
      `slices/S50-cargo-window/`, A21–A24) and the capacity + stock laws
      (A25/A26); gate 1422 → **1430/0 ×2**, CONTRACTS v0.68, everything
      committed through the stock verdict. Recaps: `MASTER_REPORT.md` §6.

## Wave checklist (applies to every slice above)

- [ ] Docs first — the owning doc amended with the real numbers, each carrying
      its reversal path
- [ ] Five-piece handoff re-cut against the current shell (`BRIEF` + `prompts`)
- [ ] `staging/verify_wave.py snapshot` + commit before the first dispatch
- [ ] Builders run → mandatory review → fixer only if the review leaves HIGH/MED
- [ ] Close-out: `staging/gate.py --times 2`, `verify --baseline`, CONTRACTS
      §9/§10 (code waves only), WAVEBOARD + TICKS refresh, wave-boundary commit

## Exit criteria
- [x] D24 closed (all nine items designed, owner ticks presented)
- [x] The implementation waves closed per D24's split; gate green at every
      boundary (1422/0 ×2, re-verified 2026-10-14)
- [ ] Playtest build 3 exported, smoke-tested, and the owner's eye over it —
      waits for the cargo redo to land so the owner tests the finished
      surface

## Carries forward
- T-179 (the Pyre cascade, owner-postponed) re-presents at the next playtest;
  the S41 chrome tokens re-present with the reworked OVERVIEW.
- T-155/T-158/T-159/T-161/T-162/T-163/T-180 and the owner-approved
  T-174/T-175/T-176 cures ride the P4 implementation waves that touch their
  files.
- B2-1 (menu hover look) and B2-2 (blurry backdrops) stay owner direction
  picks; neither blocks P4.
