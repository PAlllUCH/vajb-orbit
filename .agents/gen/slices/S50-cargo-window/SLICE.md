---
slice: S50
phase: P4
lane: code
status: done
gate_baseline: "1429/0"
---

# S50 — the cargo window unification

## Goal
The armory's cargo preview (A19) and the launch manifest (A20) render the C
overlay's own window — chrome, tab strip, category grouping, scroll — at the
host column's width; the capped caption+rows block grammar retires.

## In scope
- `docs/design/UI_SPEC.md` §20 amendment (new A21 pin; A19/A20 superseded)
- `vajb-orbit/ui/station/cargo_summary.gd` — the shared window builder
- `vajb-orbit/ui/station/armory_panel.gd` + `.tscn`, `launch_panel.gd` + `.tscn` wiring
- Test re-cuts (`test_ui_slot_layout`, `test_s43_armory_equipped`, `test_s47*` reads)

## Out of scope
- The C overlay itself (A7–A16 pins and every s48 row stand untouched)
- The HUD's flight cargo block (A17's cap law stays HUD-only)
- Dispose chips in the read-only summaries

## Acceptance criteria
- [ ] AC1 — both surfaces render the window chrome (PanelRaised panel, 16 px
  margin, always-on vertical scroll, disabled horizontal) at the host column's width
- [ ] AC2 — ALL view groups rows under the A13 category headers; a tab press
  filters; the full list scrolls (no 6-row cap, no "+N MORE" tail)
- [ ] AC3 — `python3 staging/gate.py --times 2` zero-fail byte-identical after re-cuts

## References
- `docs/design/UI_SPEC.md` §20, §3.10 Amendment 5 (A5 composition law)
- `docs/design/STATION_HUB.md` §23.11 supersession ledger
