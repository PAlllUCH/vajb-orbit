---
slice: D12
lane: design
title: UI readability audit — ARMORY in particular
status: open
opened: 2026-09-24
---

# D12 — UI readability audit (design lane)

## Why

Owner, 2026-09-24: *"i also want the current credits in the space scene. spawn
deepseek api deepseek flash reviewer on max reasoning to do review of
readibility in the pararell, the armory meny in particular (it looks pretty
bad) if its graphics lane make sure its well known."*

This slice is the **readability half** of the owner's request. The other half
(the station hover-description panel, the credits readout, the weapon ranges,
the flight-feel inertia) is code-lane wave work, briefed separately.

## In scope

- `D12-A0` — an independent readability audit of the station's panes, ARMORY
  first. Report only, no edits. Deliverable
  `slices/D12-ui-readability/D12-A0_report.md`, ≤150 lines.

## Out of scope

- Any fix. A0's findings are triaged by the developer session into either a
  graphics-lane fix wave or the code wave; nothing is edited in this slice.
- `slices/D11-station-scene/**`, `dispatch_designer.md` and
  `staging/mockup/**` — the owner runs the D11 designer lane in a parallel
  session; they are read-only to this slice.

## Worker file sets

| ID | role | VAJB_WORKER_FILES | deliverable |
|---|---|---|---|
| D12-A0 | reviewer (design lane) | `.agents/gen/slices/D12-ui-readability/D12-A0_report.md` | the audit report |

## Lane tag

Findings that are look, typography, contrast, spacing or layout are
**graphics lane** (they belong to the D11/D12 designer session, not to a coder
wave); findings that are structural or data are **code lane**. A0 tags each
finding with its lane so the triage cannot misroute one.
