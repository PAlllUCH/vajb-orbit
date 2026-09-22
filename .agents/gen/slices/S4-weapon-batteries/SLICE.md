---
slice: S4
phase: P2
lane: code
status: draft
gate_baseline: "S3's close-out figure"
---

# S4 — Weapon batteries

## Goal
Fitted weapon systems manage and fire as batteries: 3 lasers are one row with
one trigger in OUTFITTING's FITTED WEAPONS strip, not three unrelated cells to
click. After S4 a capital hull reads as "3× LASER · 2× CANNON" and its volleys
read as salvos.

## In scope
- Battery grouping in OUTFITTING's FITTED WEAPONS strip (one row per `base_id`,
  bulk FIT ALL / REMOVE ALL / SWAP ALL, per-barrel expander) — 09 §10
- Bulk profile transactions over the §13 composed calls (atomic per batch) — CONTRACTS §16
- The volley: one trigger per battery, one round per barrel, `BATTERY_STRUM_MS := 40`

## Out of scope
- Fit storage changes (one instance per W cell stands — the owner's ruling)
- The FITTING pane's per-cell grid (it stays the cell-surgery surface)
- Anything S3 owns if S3 has not closed (run S4 strictly after)

## Acceptance criteria
- [ ] AC1 — the strip groups by `base_id` with correct W-cell ranges and counts;
      bulk actions round-trip and a failed batch rolls back to its starting fit
- [ ] AC2 — one trigger discharges every barrel of the battery (one round per
      barrel, per-barrel damage) with per-barrel release offsets within 0–40 ms
- [ ] AC3 — the per-barrel expander reaches every single-cell action
- [ ] AC4 — the gate holds green with the S4 suites (measured number into §9)

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S4-H0 | `docs/,vajb-orbit/tests/,vajb-orbit/tools/` | `S4_BRIEF.md` |
| S4-H1 | `vajb-orbit/ui/station/outfitting_panel.{gd,tscn},vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/` | `S4_BRIEF.md` |
| S4-H2 | `vajb-orbit/game/weapons.gd,vajb-orbit/game/projectile.gd,vajb-orbit/tests/` | `S4_BRIEF.md` |
| S4-H3 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | reviewer |
| S4-H4 | the union of H1+H2 sets + `docs/CONTRACTS.md` | fixer, only on HIGH/MED |

## References
- `docs/gameplay/09_ship_slots_modules.md` §10 (the battery law; owner rulings verbatim)
- `docs/design/STATION_HUB.md` §5.10 (the strip rows) and §5.1
- `docs/CONTRACTS.md` §16 (this wave's pin), §13 (the transactions it wraps), §8.2 (the volley seam's home)

## Carries forward
- The owner's ruling is settled (N barrels keep N W mounts) — no ticks owed here
  beyond keeping `BATTERY_STRUM_MS`'s reversal honest
