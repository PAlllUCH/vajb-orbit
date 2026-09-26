---
slice: D14
phase: P3
lane: design
status: active
gate_baseline: "895/0"
---

# D14 — ARMORY chrome composition (design lane)

## Goal
The ARMORY pane must read as clean as AUCTION and SHIPYARD do: every surface a
composed node (container + theme stylebox), chrome that fits the surface the art
was cut for, no hand-drawn chrome over content, no content over chrome. The
owner's standing rule (2026-09-26, verbatim): **"we always should use anchors and
relative positioning"** — this slice writes that law into the docs and pins the
per-surface chrome, so two workers dispatched on the same brief produce the same
pane.

## In scope
- `docs/design/UI_SPEC.md` §3.10 **Amendment 5** (per-surface chrome table + the
  composition law, with reversals).
- A mockup revision of the bays/wells band if any frozen number has to move
  (`staging/mockup/armory_mockup_v2.py` is the D13 renderer of record).
- The art question if the composition needs a small-surface frame variant.

## Out of scope
- The code wave (a coder slice follows the ticks; no file shared with S19's
  `vajb-orbit/tests/` + `tools/` while that wave is live).
- Any gameplay/number change; the §5.1 four stock states, the P5 wording, the
  salvo ledge (T5 = keep) and the 13 px ink floor stand.

## Evidence
`_evidence/` — the live pane at 1920×1080, the bay band 1:1, the pack cards 1:1,
the three chrome assets 1:1, the slot plate at 4×.
