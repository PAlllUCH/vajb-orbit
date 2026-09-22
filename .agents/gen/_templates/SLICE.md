---
slice: S2.5
phase: P2
lane: code            # code | design
status: draft         # draft | active | review | done
gate_baseline: ""     # e.g. "219/0" — the universal gate count this slice starts from
---

> **Use when:** a developer opens a new slice. Copy to `slices/<SliceID>-<slug>/SLICE.md`,
> fill every field, and get the owner's nod before the first dispatch.

# S2.5 — Feel

## Goal
3 lines max: what the game can do after this slice that it cannot do today.

## In scope
- Item, with the spec anchor that owns it (e.g. `18_engine_spec.md` §3.4)

## Out of scope
- Explicitly named non-goals — reviewers diff against this list too.

## Acceptance criteria
- [ ] AC1 — stated so a probe or the gate can prove it
- [ ] AC2 — every criterion is mechanically checkable; if it cannot be probed, it belongs in Out of scope or needs an owner ruling

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S2.5-V0 | `game/x.gd, ui/y.tscn` | `S2.5-V0_BRIEF.md` |

## References
- `docs/CONTRACTS.md` §n (pinned sections this slice codes against)
- Spec sections; asset specs if art is involved

## Carries forward
- Tickets/LOW items this slice absorbs (e.g. `T-26`), with the ruling that resolved them
