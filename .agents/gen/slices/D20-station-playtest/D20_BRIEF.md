---
slice: D20
worker: D20-P1 + D20-P2 (same brief, dispatched one after another)
role: reviewer
status: ready
tier: paid — models owner-pinned per worker (SLICE.md table)
---

# D20_BRIEF — station playtest pass (owner-delegated, 2026-10-03)

## The law to read, in order
1. `slices/D20-station-playtest/SLICE.md` — scope + your row in Worker file sets
2. This file — the owner's notes verbatim + the acceptance list you answer
3. `skills/vajb-orbit-environment/SKILL.md` — godot-ai runbook (boot, drive, screenshot, debug loop)
4. `docs/design/UI_SPEC.md` §11–§12 + `docs/design/STATION_HUB.md` §18–§19 — **by range only**, the shell-v2 pins to judge against
5. `vajb-orbit/ui/screens/station.gd`, `vajb-orbit/ui/station/*_panel.gd`, `vajb-orbit/ui/components/{tooltip,inspect_chip,inspect_sheet}.gd` — only when a finding needs its cause

## The owner's request (verbatim, 2026-10-03)
> 1. in exchange the "marker board" is the best looking thing. scrollable with clear info. make the "your hold" in exchange look the same and make sure that they are even = on same height, you can spawn reviewers to run the game and see, will be best.
> 2. in armory the "modules owned and buyable" shifts out of screen. make the armory more like 2 separate modules not all on 1 screen. first module where i select cell and get info what the cell is, what i have that can be slotted there and select/drag fit items. second to create battery configurations based on fitted weapons.
> 3. inspect time twice as long on hover, make it a bit clearer maybe to read?
> 4. terminal works nice
> 5. auction as well. all clear, readable

## What is already measured
- Shell v2 shipped `43613d1` (S30): the rail and the inspector band are deleted, OVERVIEW lands on dock, one pane template everywhere, TERMINAL is a 360 px right drawer (`UI_SPEC.md` §11 N24–N30, `STATION_HUB.md` §18 P15–P21). These notes are the first external read of that build.
- D17's exchange finding (YOUR HOLDINGS had no column headers) was against the **pre-shell-v2** build — re-verify against the current one.
- Gate n/a (review only; live gate 1093/0 at open). Editor session live (`vajb-orbit@a7ecd5aa375f7a60`); game starts stopped.
- Judging stance (owner): grimdark, but it must operate smoothly and read clearly.

## Pinned interface
None — no code ships. Where the build and a pin disagree: report it as a finding, never fix it (escalation ladder bucket 2).

## Spec extract (the acceptance spine, verbatim)
The owner's five notes above are the extract: item 1 grades EXCHANGE panel parity + equal height, item 2 grades the ARMORY overflow + the 2-module split (cell-fit / battery-config), item 3 grades hover-inspect time + legibility, items 4–5 grade TERMINAL and AUCTION as the idiom EXCHANGE must borrow.

## Acceptance list (the report answers each, with cites)
1. **EXCHANGE (note 1):** "marker board" vs "your hold" compared panel by panel — scrolling, row/column headers, data density, typography, panel chrome — and both panels' height + alignment measured (owner wants them even, same height). Every difference named with its style/layout cause (`file:line`). Screenshots: whole screen + each panel.
2. **ARMORY (note 2):** the "modules owned and buyable" overflow reproduced — window size recorded, the widget that leaves the screen and the exact trigger moment named (on open / hover / scroll), layout cause cited, before/after screenshots. Block-by-block inventory of the armory today. What serves the owner's module (a) cell-fit and (b) battery-config today vs missing; "battery" grounded in code/docs (`rg battery vajb-orbit/ docs/`).
3. **HOVER INSPECT (note 3):** appear + stay timings measured and cited `file:line`; legibility judged at 640 (font size, contrast, padding, chrome); the exact values a ×2 change touches listed.
4. **TERMINAL + AUCTION (notes 4–5):** verified clear/readable; the working idiom named precisely so the exchange restyle can borrow it.
5. **CLEANUP SWEEP:** any other visible fault at the game's default window size (clipping, overlap, unreadable text, misalignment, stale state), tiered HIGH/MED/LOW.
6. **Contract:** report ≤120 lines at your own path; game left stopped; no background jobs left.

## Worker table
| ID | Role | `VAJB_WORKER_FILES` | Model | Deliverable |
|---|---|---|---|---|
| D20-P1 | reviewer | `.agents/gen/slices/D20-station-playtest/` | `xiaomi/mimo-v2.6-pro` @ high | `D20-P1_report.md` |
| D20-P2 | reviewer | `.agents/gen/slices/D20-station-playtest/` | `hyper/glm-5.3-flash` @ max | `D20-P2_report.md` |

## Run order
`D20-P1` → `D20-P2` strictly one after another (one game window; the save profile carries P1's session state). Then the orchestrator writes `D20_synthesis.md` (both reports + the owner's notes, tiered, deduped, fix split).

## Tests that move
None — no code changes. Gate n/a.

## Hard rules
- Write exactly one file: your report. No code/scene/doc/asset edits (hook-enforced).
- Screenshots at `max_resolution` 640; 1152 at most once for small-text verification; never re-request a frame you already have.
- Every probe bounded; leave the game **stopped**; never leave a background command running.
- Report only what you saw or measured: one evidence line per finding, no source pastes, no transcripts.
- If a pin and the build disagree: report, don't fix (escalation bucket 2).

## Staged / deferred
- Fix implementation (the owner ticks the synthesis first). The armory 2-module rework needs its own design + build wave.
- Main-menu depth and flight/undock (D17 covers both).

## Owner tick list (settled by the synthesis)
1. Fix split: quick (exchange parity + inspect timing/legibility) vs wave (armory 2-module rework) — approve the split.
2. Armory shape: two tabs inside ARMORY or two separate panes.
3. "Battery configuration": what the builder outputs (grounded in what the code/docs say today).
4. Inspect ×2 exact values + the legibility treatment.

## Close-out (orchestrator)
1. `D20_synthesis.md` written; both reports cited `file:line`.
2. `TICKS.md` rows refreshed for the tick list above.
3. `WAVEBOARD.md` one-line outcome + `MASTER_REPORT.md` §6 recap.
4. Wave-boundary commit; report back: findings by tier + the owner ticks.
