---
slice: D13
phase: P2
lane: design
status: active
gate_baseline: "866/0 (must not move — this wave writes no code)"
---

# D13 — Armory rework (design: vision, reasoning, brainstorming, mockups)

## Goal
A owner-tickable design for the ARMORY pane's rework — approaches with
trade-offs, a recommended composition, and pixel mockups — that fixes the
D12-A0 readability audit without breaking the shipped seams.

## In scope
- The design only: `staging/mockup/armory_mockup_v2.py` (PIL renders,
  1920x1080) + outputs, and the report with proposed values, reversals and
  the owner tick list
- Input evidence: `slices/D13-armory-rework/_evidence/` (live capture
  2026-09-25), the D12-A0 recap (pinned in `D13_BRIEF.md` §3), LOW L208

## Out of scope
- Any write to `vajb-orbit/` (code, scenes, art) — the implementation wave
  follows the owner's ticks
- Any write to `docs/` — the proposal rides the report; the ticked values
  land in the owning docs at the next boundary (bucket 2/3)
- Paid image generation (kie.ai) — new plate art belongs to the
  implementation wave's asset pass, not the design

## Acceptance criteria
- [ ] AC1 — vision: the report's "today" section is grounded in the pinned
      live capture (and PIL crops of it), not in assumptions
- [ ] AC2 — brainstorming: 2-3 approaches with explicit trade-offs, one
      recommended with reasons; every approach rendered as a mockup
- [ ] AC3 — the audit: every D12-A0 finding (5 HIGH / 4 MED / 3 LOW) and
      L208 is addressed by the recommended design or explicitly deferred
      with a reason
- [ ] AC4 — the yardstick holds: the data model is unchanged (5 batteries ×
      4 cells, the pack cards, the §13/§16 transactions, CONTRACTS §17);
      palette/typography from STYLE_BIBLE; text meets the audit's floors
      (ink ≥ 13 px, `text_dim` ≥ 4.5:1); no CSS idiom (Godot Control and
      drawn plates)
- [ ] AC5 — every proposed value carries its reversal and rides the owner
      tick list; nothing is presented as decided
- [ ] AC6 — the mockups re-render byte-identically from the committed script

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D13-A0 | `staging/mockup/, .agents/gen/slices/D13-armory-rework/` | `D13_BRIEF.md` |
| D13-R1 | `staging/mockup/, .agents/gen/slices/D13-armory-rework/` | `D13_BRIEF.md` |
| D13-F1 | `staging/mockup/, .agents/gen/slices/D13-armory-rework/` | `D13_BRIEF.md` |

## References
- `docs/design/STATION_HUB.md` §5.11 + the D7 restyle + S15 + rework-open
  amendments; `docs/design/UI_SPEC.md` §3.9/§3.10 (+ Amendment 2, the canvas
  pin); `docs/design/STYLE_BIBLE.md` (palette, type, floors)
- `docs/gameplay/09_ship_slots_modules.md` §11/§12 (the data law)
- `~/.local/share/crush/skills/brainstorming/SKILL.md` (the owner-mandated
  method) — read by path

## Carries forward
- LOW L208 (the bay head floats above the plate ink) — the design must
  resolve or supersede it
