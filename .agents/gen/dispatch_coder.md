# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22 after the purge (the previous file held items 1–7, all DONE;
their record is `.agents/gen/session_2026-09-22_items_4_to_7_report.md` and
`.agents/gen/MASTER_REPORT.md`). Execute **one item per order**, close out per the
brief's close-out section before starting the next. Model for every worker:
`deepseek/deepseek-v4-flash` (owner instruction 2026-09-22;
`opencode-go/deepseek-v4.1-flash` is broken). Briefs and prompts live in the
slice folders; the owner pastes only the short handoff paragraph.

**File-collision law:** two waves may never hold one file at once. The order
below is forced by it (S2.6 owns `tests/` + its `game/` files; S3 owns
`player_profile.gd` + `ship_fit.gd` + the station panels; S4 owns
`outfitting_panel.gd` + `weapons.gd` — S3 and S4 both touch `outfitting_panel.gd`,
so S4 is strictly after S3). **Parallelism:** inside item 8 the four builders
R2/R3/R4/R5 are pairwise file-disjoint and may run as four concurrent `crush run`
workers; **across waves nothing runs in parallel** — waves share `tests/`, the
gate close-out and git state (L82's recorded lesson: one live session per
workspace).

## Current queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 8 | **S2.6 truth-and-feel** (gate hermeticity L90/L93 + the owner's seven feel requests + L65: rock burst, beam scatter/middle, mining chips, slower accel, blur excludes the hull, neutral turn + symmetric inertia) | `slices/S2.6-truth-and-feel/` | `S2.6_BRIEF.md` / `S2.6_prompts.md` | **DONE 2026-09-22** — gate 437 → 457/0 hermetic on the live path (see WAVEBOARD §Closed; the wave's own harness first destroyed the owner's live profile — `slices/S2.6-truth-and-feel/_incident/README.md`, L106) |
| 9 | **S3 the item economy** (module instances with affixes + the AUCTION; the owner: "We need AUCTION. without it we cannot test all items") | `slices/S3-module-affixes/` | `S3_BRIEF.md` / `S3_prompts.md` | **DONE 2026-09-23** — gate 457 → 493/0 hermetic (K0's 7 HIGH answered by the docs pass first; one HIGH found by the review and fixed by K5). See WAVEBOARD §Closed; the wave's own first dispatch wrote the owner's live account (`slices/S3-module-affixes/_incident/README.md`, **T-93**) |
| 10 | **S4 weapon batteries** (group weapon systems in OUTFITTING; owner ruling: N barrels keep N W mounts) | `slices/S4-weapon-batteries/` | `S4_BRIEF.md` / `S4_prompts.md` | **DONE 2026-09-23** — gate 493 → 524/0 hermetic (H0's 4 HIGH/5 MED answered by the docs pass first: CONTRACTS §16 rewritten as v0.8.0; one HIGH found by the review, a held trigger firing one salvo instead of a stream, and one MED, both fixed by H4). See WAVEBOARD §Closed. |
| 11 | **S5 playtest fixes** (the owner's ten findings 2026-09-23: auction family tabs, shipyard hangar + preview/`SET ACTIVE`, `ARMORY` drag-and-drop **mixed** batteries with the slowest-cycle salvo gate, ammo as cargo + auto-load + fuel-cell delist, per-hull hardpoints + per-barrel `track_dps` tracking) | `slices/S5-playtest-fixes/` | `S5_BRIEF.md` / `S5_prompts.md` | QUEUED — run next |
| 12 | **Engine slice 3 (Travel) merged with RPG P3** | not opened | — | NOT BRIEFED — needs its docs-first pass |

Every wave runs **R0/K0/H0 (docs drift) → builders → review → fixer only on
HIGH/MED**, with a `verify_wave.py snapshot` + commit before the first dispatch
and the brief's close-out (gate ×2 hermetic, `verify_wave.py verify`, CONTRACTS
§9/§10 measured notes, WAVEBOARD, wave-boundary commit) at its end.

## Done (items 1–10)

1–3 (chrome, combat repair, weapon FX) — closed 2026-09-21, see `MASTER_REPORT.md`.
4 P2-A ship slot frames (`8d189bf`), 5 Rock cleave (`0e419f7`), 6 P2-B1 weapon fit
(`1f794cc`), 7 P2-B proper fitting panel (`3e79e61`) — closed 2026-09-22, gate 437
tests, see `session_2026-09-22_items_4_to_7_report.md`. 8 S2.6 truth-and-feel
(`8d0691d`, gate 457), 9 S3 the item economy (gate 493) and 10 S4 weapon batteries
(gate 524) — closed 2026-09-22/23, see `WAVEBOARD.md` §Closed.

## Next beyond this queue (not briefed)

- Engine slice 3 (Travel) merged with RPG P3 — gates/corridors/POIs/scanner/sector
  transitions + heat/hunters. Needs its own docs-first pass first.
- The owner's requests #6/#7 land in item 8; no other owner request is unbriefed.
- Owner-locked homework stays the owner's: `18_engine_spec.md` §6/§13/§15 (cleaving
  + `FRAGMENT_OUTWARD_KICK`), the §13 turn/`coast_time` ticks, slice 2.5's two calls.
