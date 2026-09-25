---
slice: D8
phase: P4
lane: design
status: active
gate_baseline: "852/0"
---

# D8 — In-flight HUD visibility (item 10)

## Goal
The flight HUD reads at a glance: the top-left carries live state, the minimap
explains itself, and every glyph is legible at 1920x1080.

## In scope
- Top-left content block (the owner's pick) built from the **existing** HUD
  state set — nothing invented
- Minimap legend naming the blip kinds it draws
- 1080p glyph legibility (the owner's pick; the QA rows name the offenders)

## Out of scope
- The cockpit instruments (D6/D7 shipped), the station panes, the ARMORY
  (S15 holds `ui/station/`), new readouts not already in the HUD state, audio

## Acceptance criteria
- [ ] AC1 — the top-left quadrant carries a named block of ≥ 2 live readouts
      drawn from the HUD's existing state (which ones is the designer's call,
      justified in the report); no state item disappears from the HUD
- [ ] AC2 — a minimap legend is visible in flight and names every blip kind
      the minimap draws (checked against `minimap.gd`'s draw kinds)
- [ ] AC3 — every HUD text/glyph at 1920x1080 measures ≥ 12 px cap height
      (the QA's 1080p offenders listed row by row with before/after pixels)
- [ ] AC4 — `test_d7_cockpit` and the shipped HUD suites stay green untouched;
      gate grows only by `test_d8_hud_visibility` rows, twice on scratch stores
- [ ] AC5 — `verify --baseline d8hud_start` clean; the S14/S15 lanes' touched
      files are attributed, never fixed

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D8-B1 | `vajb-orbit/ui/hud/,vajb-orbit/tests/,vajb-orbit/tools/` | `D8_BRIEF.md` |
| D8-R1 | `vajb-orbit/tests/,vajb-orbit/tools/` | `D8_BRIEF.md` |
| D8-F1 | union of B1 | `D8_BRIEF.md` |

## References
- `.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`
  — the in-flight HUD QA rows this wave answers (the brief input; S8's precedent)
- `docs/design/UI_SPEC.md` — the HUD section (its dated amendment lands at
  close-out, S8's pattern)
- `vajb-orbit/ui/hud/` (`hud.gd`, `hud.tscn`, `minimap.gd`, `cockpit_*.gd`)

## Carries forward
- The parallel S14/S15 waves hold `game/`, `autoload/`, `ui/station/` and the
  `test_s1*` prefixes — never touch those; LOW ids read at write time
