---
slice: S35
phase: P3
lane: code
status: draft
gate_baseline: "1132/0"   # the universal gate count this slice starts from
---

> The owner's 2026-10-05 fix round ("spawn fixer"). Naming note: the chrome
> re-skin build wave is **S36** — earlier notes called it "S35" before this
> fix wave took the next free code-slice ID.

# S35 — Owner fix round: one sell selector (MAX/0), preview clear, one shared menu

## Goal
The exchange carries one sell-quantity control with MAX/0 quick buttons, the
armory preview clears when you click away, and FIT CELLS / BATTERY CONFIG
share exactly one right-side menu.

## In scope
- N49a: one quantity control + MAX/0 (`UI_SPEC.md` §14's 2026-10-05 amendment)
- P38a: click-away clears the selection/preview (`STATION_HUB.md` §21.1)
- P39a: one shared right menu in both modes (same section)

## Out of scope
- The chrome family art (D21-G1 generates; the **S36** re-skin consumes it)
- The refinery (S34, closed), `game/`/`autoload/` (not in the file set)

## Acceptance criteria
- [ ] AC1–AC6 = `S35_BRIEF.md` §4's acceptance list

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S35-B1 | `vajb-orbit/ui/,vajb-orbit/tests/` | `S35_BRIEF.md` |
| S35-R1 | `vajb-orbit/tests/,.agents/gen/slices/S35-owner-fixes/` | `S35_BRIEF.md` (acceptance list) |
| S35-F1 | as B1 (only if HIGH/MED) | `S35_BRIEF.md` |

## References
- `docs/design/UI_SPEC.md` §14 (+ §13.1 N42–N47, §11.1 A5.5/N24, §3.10 A5)
- `docs/design/STATION_HUB.md` §21.1 (+ §20.1 P32–P35 as amended)
- `slices/S33-shell-v3/S33-B1_report.md` + `S33-F1_report.md` (the S33 shapes)

## Carries forward
- T-134 (the duplicate selector) — resolved by this wave per the owner.
