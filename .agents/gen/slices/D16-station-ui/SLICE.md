---
slice: D16
phase: P3
lane: design
status: draft
gate_baseline: "n/a (design only)"
---

# D16 — Station identity & contracts UI design

## Goal
The design law for the world-identity and contracts waves: how the nine named
places present themselves with shipped chrome only, and how the CONTRACTS,
insurance and vaults panels read under the A5 composition law. Plus the station
name tick sheet for the owner.

## In scope
- The CONTRACTS panel spec (14 §2 + R-S25-1): board rows (type/objective/
  reward/faction), accept/cancel affordances (the 100 CR fee shown), the
  escrow readout, Expedition's staging state — under UI_SPEC §3.10 A5
- Insurance + vaults panel specs (14 §3/§4): premium rows per class, the
  one-death/mercy readout, vault tier rows + contents view
- Station identity treatment (R-S24-1's names): name plate + character line per
  place, using existing chrome/assets only — the treatment, not the code
- The name tick sheet (W3) presented ready-to-tick
- Mockups (`staging/mockup/`)

## Out of scope
- Code (S24/S25/S26 implement); `docs/gameplay/*`, `CONTRACTS.md`, `18_engine_spec.md`
- New art (owner 2026-09-27); the armory's D14 questions (that slice owns them)

## Acceptance criteria
See `D16_BRIEF.md` §6 (A1–A5).

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D16-A1 | `docs/design/, staging/mockup/, .agents/gen/slices/D16-station-ui/` | `D16_BRIEF.md` |
| D16-R1 | `docs/design/, .agents/gen/slices/D16-station-ui/D16-R1_review.md` | `D16_BRIEF.md` |

## References
- `docs/gameplay/14_station_services.md` §1–§4/§8/§9 + **2026-09-27 P3 block**
  (read-only — the pin)
- `docs/design/UI_SPEC.md` §3.10 Amendment 5 (A5.1–A5.3) · `STATION_HUB.md`
  (the station screen contract) · `docs/design/ASSET_CATALOG.md` (usable chrome)
- `slices/S25-contracts/S25_BRIEF.md` §5 (the board pin) ·
  `slices/S24-world-identity/S24_BRIEF.md` §11 (the name rows)

## Carries forward
- The ticked names travel to the developer's 14 §5 block (tick W3) and the
  panel specs become S25/S26's design law (their briefs name this report).
