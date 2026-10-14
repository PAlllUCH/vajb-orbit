# dispatch_coder.md — the code-lane queue of record

Purged and regenerated 2026-10-14 (P4's implementation waves closed; live items
only — items 46–53 live verbatim in `_archive/dispatch_done_2026-10-14.md`, items
31–38 in `_archive/dispatch_done_2026-10-12.md`, the earlier done rows in
`_archive/dispatch_coder_done_2026-10-07.md` and `_archive/dispatch_done_2026-10-08.md`,
the wave recaps in `MASTER_REPORT.md` §6). Execute **one item per order**, close
out per the brief's close-out section.

**Design law (P4):** every item below implements D24's landed amendments —
`docs/design/STATION_HUB.md` §23 (P44–P54 + the §23.10 tick table + the §23.11
supersession ledger), `UI_SPEC.md` §17/§18 (A4–A9), `AUDIO_SPEC.md` §8.7
(AUDIO-4/5), `04_refinery.md` §9 (R9–R12), `07_crafting.md` §6 (C1–C10),
`10_ship_acquisition.md` §3.5. A worker who believes a number is wrong reports
it and leaves it; every unticked value implements at its PROPOSED value (the
S19 precedent).

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit
→ builders → mandatory review → fixer only on HIGH/MED → close-out (gate ×2
hermetic, `verify --baseline`, CONTRACTS §9/§10 sequenced with any parallel
lane, `build_code_map.py`, WAVEBOARD, wave-boundary commit).

**`build_code_map.py` in the close-out (adopted 2026-10-08, S24's close-out).** A
wave that adds or renames files leaves `docs/CODE_MAP.md` stale; S24's new
`game/station_registry.gd` plus its two suites proved it (22 changed map lines).
The step is law from this wave on; reversal: drop it from this paragraph, the
AGENTS.md handoff template and the slice briefs' close-out sections. **Provenance,
recorded so the guard stays honest:** S24-F1 added it out of scope, through bash,
undisclosed; the developer session re-authored it here with its rationale and its
reversal, so the law changed by a ruling and not by an implementer.

**Model roster (owner, 2026-10-03, shell-v2 round):** code runs
`hyper/deepseek-v4.1-flash`, heavy design runs `xiaomi/mimo-v2.6-pro`, review
runs `hyper/glm-5.3-flash` — every run at the provider's max reasoning effort
(mimo's enum caps at `high`, measured 2026-10-03). Nothing heavier without
asking the owner first. **Owner directive (2026-10-12): don't spawn on
`hyper/glm-5.3` — `xiaomi/mimo-v2.6-pro` @ high takes its slot** (D24's review
and fixer ran there); the directive as given names `glm-5.3`, so the flash-tier
reviewer stands until the owner widens it.

## Queue

Empty — **P4's eight implementation waves (items 46–53) are closed** (S49, the
last, on 2026-10-14; gate 1330 → **1422/0 ×2 byte-identical**, re-verified at
the 2026-10-14 phase review; the rows verbatim in
`_archive/dispatch_done_2026-10-14.md`). What stands before the next queued
code:

- **In flight, designer lane (owner, 2026-10-14): the C-key cargo overlay's
  redesign.** The owner wants S48's built overlay redone; the design round runs
  now and owns its slice folder and `dispatch_designer.md`. Its implementation
  wave queues here through the brief loop (docs-first five-piece in
  `slices/<SliceID>-<slug>/`) once that round closes — one live session, no
  parallel lane.
- **Then the P4 exit pass** — playtest build 3 and the owner's eye over it
  (`phases/P4-station-overhaul/PHASE.md`'s exit criteria; T-179 and the S41
  chrome tokens re-present there). The build waits for the cargo redo so the
  owner tests the finished surface.

## Parked (owner-gated — not queued; say the word and the five-piece lands)

- **T-179 — the Pyre ring's own-kill cascade** (owner postponed 2026-10-12:
  "didn't test, postpone"); code stays as shipped; re-presents at the P4 exit
  playtest. Ratify the cascade or gate the ring on the killing blow's source.
- **B2-1/B2-2 — the build-2 owner direction picks** (`19_testing_notes.md`):
  the menu hover look (flicker / steady) and the blurry station backgrounds.
  B2-2 could ride a P4 station wave once the owner picks the direction.

## Done

Items 1–53 closed (gate 437 → 1422/0 through the waves). Detail:
`_archive/dispatch_coder_done_2026-10-07.md`,
`_archive/dispatch_done_2026-10-08.md`, `_archive/dispatch_done_2026-10-12.md`,
`_archive/dispatch_done_2026-10-14.md` and `MASTER_REPORT.md` §6.

## Handoff (live)

**P4's code queue is empty** — the eight waves landed and the lane waits on
the designer (the cargo-overlay redo in flight; its implementation wave queues
here when that round closes), then the P4 exit pass: playtest build 3 and the
owner's eye. The owner's tick sheet is STATION_HUB **§23.10** (unticked rows
already implemented at their PROPOSED value — the S19 precedent) and its four
flagged decisions (Rail Refit's 45.4 %, the two exotic lists, 07 §3's stale
supply math, A2's door boundary) are the owner's alone. Open riders for the
next code waves: **T-180** (the tooltip vs a pane's header, one line in
`ui/components/tooltip.gd`) is a free rider on any wave that touches the
tooltip; **T-188** rides AUDIO_SPEC's next growth; **T-191–T-202** ride their
named files per LOW_BACKLOG. Lessons the last waves taught: a
brief's `VAJB_WORKER_FILES` set must cover every file an acceptance item's own
text reaches (S27-B1 and S41's F8/F15 both stopped on this — the stop is
correct, but the fix is to scope the set, and a completion builder is the cheap
repair); a `tests/` pin a wave's own rows obsolete is the developer's bucket-2
re-cut, not a builder's (item 46's `test_s40_legibility.gd` rows are already
known); a brief that contradicts a pinned doc is the **developer's** error, not
the worker's (always re-read the pin the finding touches); the four S19 sealed
files (`damage.gd`, `npc_ship.gd`, `npc_brain.gd`, `weapons.gd`) re-pin to the
finished tree by the S22 procedure when a wave edits one; a parallel wave's
per-worker gate line is not the wave's gate — run the settled tree before
believing a failure count; and a green gate is not evidence a suite row still
tests what it says (T-183's lesson — `staging/gate.py` owns the `SCRIPT ERROR`
guard now).

Order and the collisions that force it are in `WAVEBOARD.md` §Queued. The
parked list stands owner-gated.
