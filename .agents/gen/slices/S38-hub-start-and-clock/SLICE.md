---
slice: S38
phase: P3
lane: code
status: ready
gate_baseline: "post-S25 (1226/0)"
finding: "the owner's 2026-10-08 playtest note, verbatim: 'there is 20 minute
refresh timer for contrats but i cannot see in real time how much time is left
for refresh and there should be contracts on the start'"
---

# S38 — The board's clock and the hub's cold start

> **ID note:** S0–S37 are taken (`S28` twice, `_archive/slices/`), so this wave
> is **S38**. It is a code slice, so its workers use the letter **B** (builder)
> and the usual `R`/`F`.

## Goal
The contracts board is readable the moment the game starts: the hub entered from
the main menu offers a full board instead of the empty state, and a live
countdown says when the next roll lands.

## In scope
- The hub's cold start — an unfiled docked place resolves to the starting
  sector's primary (14's **H1**)
- The roll countdown — `NEW JOBS IN mm:ss` in the U3 header strip, 1 Hz, and the
  re-roll at zero (14's **H2/H3**; STATION_HUB §15.2's **U22**)
- The empty-id sentinel's meaning — a sector with no station files its own id,
  so S7 keeps its no-place fallback (14's **H1**)
- Riders: **T-156** (U7 dims the whole row) and **T-157** (a board row must not
  survive its own accept)
- `tests/test_s38_start_and_clock.gd` — new suite (A1–A6)

## Out of scope
- The board's own rules: the reward law, the gates, the escrow, the escort loop
  (S25's, pinned in `CONTRACTS.md` §26 — this wave adds no reward number)
- Any new contract type, objective wording or art
- The INSURANCE/VAULTS panels (S26), Expedition going live (S26)
- `docs/gameplay/18_engine_spec.md` (owner-locked) and the S26/S27 briefs

## Acceptance criteria
- [ ] AC1 — the hub entered with no filed place offers a full board: the probe's
      cold-start board reads **6** rows where it reads **0** today, and the plate
      reads the row's own name + character line, not the scene's placeholder copy
- [ ] AC2 — the header strip shows `NEW JOBS IN mm:ss` reading the true remainder
      (`BAND_SECONDS − now % BAND_SECONDS`), and it moves on its own (a 1 Hz tick,
      not a value written once at build)
- [ ] AC3 — at zero the board re-rolls in place (the next band's rows appear, the
      readout restarts at `20:00`), with no scene change and no player action
- [ ] AC4 — a sector with no station still resolves to no place (the readers'
      fallback stands; S7 is unchanged)
- [ ] AC5 — T-156 and T-157 closed: the staged row dims whole (icon included) and
      an accepted row leaves the board
- [ ] AC6 — the gate ×2 hermetic on fresh scratch stores; every moved row
      enumerated in the reports

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S38-B1 | `vajb-orbit/game/sector_registry.gd, vajb-orbit/game/game.gd, vajb-orbit/game/station_registry.gd, vajb-orbit/game/contract_registry.gd, vajb-orbit/ui/station/contracts_panel.gd, vajb-orbit/ui/station/contracts_panel.tscn, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/station/overview_panel.gd, vajb-orbit/tests/test_s38_start_and_clock.gd, vajb-orbit/tests/probe_s38_start_board.gd, vajb-orbit/tests/probe_s38_start_board.tscn, .agents/gen/slices/S38-hub-start-and-clock/S38-B1_report.md` | `S38_BRIEF.md` |
| S38-R1 | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S38-hub-start-and-clock/S38-R1_review.md` | `S38_BRIEF.md` |
| S38-F1 | B1's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S38-hub-start-and-clock/` | `S38_BRIEF.md` |

Read-only throughout (never in a worker's set): `autoload/world_clock.gd`,
`autoload/player_profile.gd`, `game/exchange.gd`, `game/refinery.gd`,
`ui/station/refinery_panel.gd` (the tick idiom's source), `docs/`.

## References
- `docs/gameplay/14_station_services.md` **2026-10-08 S38 block** (the law:
  H1–H3, each with its reversal) + §2/§9
- `docs/design/STATION_HUB.md` §15.2 (U3–U8, **U22**) + §15.6 (U21/U22) + §15.5
  (the plate) + §15.1 (the strip)
- `docs/CONTRACTS.md` §24 (S24's docked-station seam — the resolution this wave
  extends), §26 (S25's registry and reward law)
- `docs/CODE_MAP.md` — by range

## Carries forward
- **T-156** (U7's dim scope) and **T-157** (a board row surviving its own accept)
  — both ride this wave, which owns `contracts_panel.gd`
- **T-155** (gate-log jitter) stays where it is; **T-153** rides S27
