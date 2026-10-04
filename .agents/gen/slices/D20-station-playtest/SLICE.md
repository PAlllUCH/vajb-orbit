---
slice: D20
phase: P3
lane: design
status: done
gate_baseline: "n/a (review only; live gate 1093/0 at open)"
---

# D20 — Station playtest pass (owner-delegated, 2026-10-03)

## Goal
Two independent in-game reviews of the rebuilt station shell (D20-P1
`xiaomi/mimo-v2.6-pro` @ high, then D20-P2 `hyper/glm-5.3-flash` @ max, same
prompt), compiled with the owner's own five playtest notes into
`D20_synthesis.md` for his tick. No code changes.

## In scope
- Live playthrough via godot-ai: boot → main menu (one glance) → station shell:
  DOCK/OVERVIEW, EXCHANGE, ARMORY, TERMINAL (drawer), AUCTION, plus the
  hover-inspect behaviour on the way
- Verification + measurement of the owner's five notes (verbatim in
  `D20_BRIEF.md`): exchange "marker board" vs "your hold" parity and equal
  height, the armory "modules owned and buyable" overflow + the 2-module split,
  inspect hover time ×2 + legibility
- `D20_synthesis.md`: both reports merged with the owner's notes, tiered and
  deduped, with the fix split (quick fixes vs the armory rework wave)

## Out of scope
- Any code, scene, doc or asset edit — each reviewer writes only its report
- Implementing fixes (they ride the wave after the owner ticks the synthesis)
- Main menu depth and flight/undock (D17 already covered both)

## Acceptance criteria
- [ ] Each reviewer ran the live game and cited evidence per finding (screenshot described / state read / `file:line`)
- [ ] Each report ≤120 lines at its own path, tiered HIGH/MED/LOW
- [ ] Synthesis merges both reports with the owner's notes item by item and proposes the fix split

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Model |
|---|---|---|
| D20-P1 | `.agents/gen/slices/D20-station-playtest/` | `xiaomi/mimo-v2.6-pro` @ high |
| D20-P2 | `.agents/gen/slices/D20-station-playtest/` | `hyper/glm-5.3-flash` @ max |

**Both dispatch WITHOUT `VAJB_SLIM`** — playtest needs the godot-ai editor
bridge (D17 precedent); `VAJB_SLIM=1` would strip it. Run strictly one after
another: one game window, one shared player profile (P2 inherits P1's session
state — the reports must note it).

## References
- `skills/vajb-orbit-environment/SKILL.md` — godot-ai runbook + the proven debugging loop
- `docs/design/UI_SPEC.md` §11–§12 + `docs/design/STATION_HUB.md` §18–§19 — the shell-v2 pins to judge against (**by range only**)
- `vajb-orbit/ui/screens/station.gd`, `vajb-orbit/ui/station/*`, `vajb-orbit/ui/components/{tooltip,inspect_chip,inspect_sheet}.gd` — what they look at

## Carries forward
- Findings await the owner's tick before filing (D17 rule: they ride the wave
  that owns their file; taste → the owner's list). The owner's notes 1–3 are
  already directives and become the next fix wave's law.
- T-117 (drawer 1 px box) and T-113 (`ScriptErrorCapture` in the gate) stay in
  `TICKS.md`; out of scope here.
