---
slice: D21
worker: D21-A1
model: xiaomi/mimo-v2.6-pro
status: informational
gate: "n/a — design-only (D21_BRIEF §7, no rows move)"
---

# D21-A1 report — the one true-aspect UI chrome family

## Result
`UI_SPEC.md` §15 now carries the family law: a 67-row census (surface → class →
true-aspect target → nine-slice margins → legal stretch bands) built on 805
grep lines and `file` pixel re-measures, the aspect law A1–A7 ("respected
always"), the per-class margins law pinning "caps, corners and rivets never
stretch", and the supersession list (§15.4). `UI_CHROME_ASSETS_SPEC.md` §13
carries 13 shell-safe kie.ai prompts (one per class; C13 with four subjects),
the one shared style block, the state law, the 4 PROPOSED station backdrops with
tick T-131, and the exact cost: **16 runs = 160 credits = $0.80** (ceiling 22
runs = $1.10 with QC-gated variants).

## Acceptance list answers
1 — DONE — 67 surface rows against the three greps (69 `StyleBox*` + 519 `theme_override` + 217 `*_plate` = 805 lines) plus `file` measures of all 53 shipped `assets/ui/*.png`; every class C1–C13 carries a true-aspect target — `UI_SPEC.md` §15.1.
2 — DONE — 13 prompts, each naming its aspect + the anchor family + a negative list carrying "no text, no logos, no bevel smear, no white backgrounds"; shell-safety verified mechanically (0 banned chars in the 14 fenced blocks); cost summed exactly 16 runs / 160 credits / $0.80 — `UI_CHROME_ASSETS_SPEC.md` §13.1–§13.6.
3 — DONE — the margins law names every class's legal band (C1 interior ±10 %; C2 h 272–450 / v 56–88; C3 h 80–160; C4 h 320–960 / v 68–84; C7 h 280–360 / v 120–400; C9 h 272–360; C12 edge tiles; the rest none) and pins "caps, corners and rivets never stretch" — `UI_SPEC.md` §15.3 + A2.
4 — DONE — 4 PROPOSED backdrops at the pane-content aspect 1765×753 (STATION_HUB §19.3) assigned ARMORY / REFINERY / EXCHANGE+AUCTION / SHIPYARD+LAUNCH+OVERVIEW, each with a one-line reversal plus the count reversal (1 shared, or 7 per-pane), tick T-131 — `UI_CHROME_ASSETS_SPEC.md` §13.3.

## Deviations from D21_BRIEF
- Brief §2's drawer entry plate "360×56" vs code 272×56: `station.gd:129` `DRAWER_ENTRY_WIDTH := 272.0` with `RAIL_ENTRY_HEIGHT` 56 (`:122`); UI_SPEC §8's P1 reversal also measures "rail 272×56"; 360 is the drawer width (`station.gd:133`). Left at the brief's 360×56 (law); the C9 band h 272–360 covers both. Reversal: adopt 272×56 as the C9 target.
- Brief §2's "HUD bar caps / minimap bezel 317×178 / 1063×1065" (INDEX.md library cuts) vs shipped `file` measures 42×14 / 200×200 (`ui_bar_caps_alt` is the 317×178 file) — reconciled exactly as the brief's own button-plate paragraph instructs (library cut vs shipped art). Targets = shipped pixels; `UI_CHROME_ASSETS_SPEC.md` §9's cross-check agrees.
- Tick-ID collision: UI_SPEC §14's closing note retires T-131 with N50/N51, while D21_BRIEF §3/§11 assign T-131 to the station backgrounds. Implemented per the brief; the reuse is noted in §13.3. Reversal: give the backgrounds a fresh tick at the TICKS refresh.
- The family grew from the seed's 9 classes to 13 (census additions C5 rack bay card, C12 panel frame; C13 backdrop family per §3) — exact cost 16 runs / $0.80 vs the brief's ≈10 runs / ≈$0.5. Reversal: keep bays flat per A5.3 and the frame shipped → 11 runs / $0.55.
- C8's empty centre (weapon/item silhouettes become engine icons over the plate) — design call inside the prompt set (escalation bucket 1). Reversal: baked silhouettes as one paid variant per slot family.
- `UI_CHROME_ASSETS_SPEC.md` §1.2's white-split substrate conflicts with the mandated "no white backgrounds" negative; resolved via the transparent-request + local-key route (`UI_SPEC.md` §15.4 item 7, PROPOSED). Reversal: restore the white substrate and drop that negative.
- `ui_cockpit_panel` / `ui_status_panel` faces stay shipped — aspect-matched `contain` anchors with no proportion fault (§12); PROPOSED, noted in the census. Reversal: regenerate them as siblings too in S35.
- AUCTION rows move from the base `Button` bevel to C4 (PROPOSED supersession of A5.4 Q5's wording). Reversal: AUCTION rows keep theme bevels.

## Evidence
- Census greps (saved at `staging/mockup/d21_census/`): `rg -n 'StyleBox'` 69 lines, `rg -n 'theme_override'` 519 (all `theme_override_constants`), `rg -n '_plate'` 217 — 805 total over `vajb-orbit/ui`, `ui/hud`, `ui/screens` (`*.gd` + `*.tscn`).
- `file vajb-orbit/assets/ui/*.png` (2026-10-05), 53 files: `ui_button_plate_*` 280×56, `ui_cockpit_panel` 928×512, `ui_armory_console` 2720×1032, `ui_status_panel` 1440×1040, `ui_armory_row_plate` 192×64, `ui_armory_rack_plate` 194×182, `ui_cockpit_frame` 192×192, `ui_panel_frame` 96×96, `ui_bar_caps` 42×14, `ui_bar_caps_alt` 317×178, `ui_minimap_bezel` 200×200.
- Shell-safety scan of the 14 fenced prompt blocks for parentheses, backticks, `&&`, `<`, `>`: 0 blocks with banned chars; the mandated four negatives appear in 13/13 class prompts.
- Cost arithmetic: 12 class runs + 4 backdrop runs = 16 runs × 10 credits = 160 credits = $0.80 (10 credits = $0.05 per 2K run); variant ceiling 6 state-bearing classes × 10 credits = 60 credits.

## Files touched
- `docs/design/UI_SPEC.md` — new §15 (census, aspect law A1–A7, margins law, supersession).
- `docs/design/UI_CHROME_ASSETS_SPEC.md` — new §13 (prompt set, states, T-131 backdrops + assignment, naming, QC, cost).
- `staging/mockup/d21_census/grep_stylebox.txt`, `grep_theme_override.txt`, `grep_plate.txt` — the census evidence.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| T-131 decision (4 backdrops; the §14 tick-ID collision is noted) | tick | TICKS refresh at close-out |
| C9 target 360×56 vs measured 272×56 — owner call | decision | owner review sheet |
| S35 measures every use rect and reports band violations (A4) before art is ordered | law | S35 brief |
| `staging/docs_index.py` re-run (new §15 / §13 ranges) | close-out | D21 close-out |
| Generation batch after the owner approves the prompts (§13.6 cost) | staged | D21_BRIEF §9 |
