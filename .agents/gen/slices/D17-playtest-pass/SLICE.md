---
slice: D17
phase: P3
lane: design
status: active
gate_baseline: "n/a (review only)"
---

# D17 — In-game playtest pass (owner-delegated, 2026-10-03)

## Goal
Two independent agent playthroughs of the live game (GLM-5.3-Flash then
MiMo V2.6 Pro, same prompt), whose observations the owner reads when back;
the orchestrator reviews and tiers them. No code changes.

## In scope
- Full playthrough via godot-ai: boot → menu → station → undock → flight →
  dock → every station module; special attention on the station menu
  (coherence + layout, the owner's ask)
- Observation reports, tiered; findings become LOW rows / owner items

## Out of scope
- Any code, scene, doc or asset edit; the reviewer only plays and writes its
  report (+ its slice folder)

## Acceptance criteria
- [ ] Each reviewer ran the game live (screenshots/logs cited per observation)
- [ ] Each report is written to its own file in this folder

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Model |
|---|---|---|
| D17-P1 | `.agents/gen/slices/D17-playtest-pass/` | `hyper/glm-5.3-flash` @ high |
| D17-P2 | `.agents/gen/slices/D17-playtest-pass/` | `xiaomi/mimo-v2.6-pro` @ high |

## References
- `skills/vajb-orbit-environment/SKILL.md` (editor/godot-ai runbook)
- `docs/design/MENU_FLOW.md`, `docs/design/STATION_HUB.md`, `docs/gameplay/19_testing_notes.md`

## Carries forward
- Playtest findings ride the wave that owns their file (PHASE owner-gate rule);
  taste items go to the owner's list, not the backlog.
