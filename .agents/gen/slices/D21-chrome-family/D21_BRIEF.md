# D21_BRIEF — the one true-aspect UI chrome family (spec + generation prompts)

## §0 Owner request verbatim

"The problem is that the panels used are stretched out of proportion. we can
run a full redesign with different aspect ratios. wont this be good solution?
this would unify the panels in all the game" — and, on the route question
(2026-10-05): "regenerate all the UI panels not only in overview. i like the
style of ui_cockpit_panel and panel_cockpit panel_armory_playes panel_armory
panel_status and the chromes in main menu make sure that they are in different
aspect ratios and they are respected always. we can generate few unique
backgrounds as well for all the space station panels". Scope answer: **full**
(every chrome surface in the game). Original note 1: "in overview. lets look
for new backgrounds for the buttons. these ones dont look good. search in the
assets first" — the search is done:
`.agents/gen/slices/S33-shell-v3/button_candidates.md`.

## §1 Law to read in order

1. This brief (the constraints, the acceptance list).
2. `docs/design/UI_SPEC.md` §5 (nine-patch panels), §8 (P1/P2 buttons),
   §14 (the fault record + the N50/N51 supersede note), §3.10 A5 (chrome
   composition law), §11.1 A5.5/N24.
3. `docs/design/UI_CHROME_ASSETS_SPEC.md` §2 (nine-slice recipes) + §11–§12
   (the anchor family: `ui_cockpit_panel`, `ui_cockpit_frame`,
   `ui_armory_console`, `ui_armory_rack_plate`, `ui_armory_row_plate`,
   `ui_status_panel` — prompt recipes + the ≥95 % ink-box QC law).
4. `docs/design/STYLE_BIBLE.md` (palette), `ASSET_NAMING_SPEC.md` (name law).
5. `docs/design/STATION_HUB.md` §19.2 + §21 (the surfaces this family lands
   over — do not change their layout).

## §2 Measured facts (file:line)

Surfaces and their true aspects — the family draws each at its own aspect:

| Class | Target size / aspect | Source |
|---|---|---|
| OVERVIEW tile slab | 300×140 (15:7) | `overview_panel.gd:48` `TILE_MIN` |
| P1 primary bar | 360×56 and 360×88 | UI_SPEC §8 |
| P2 inline chip | 96×32 (3:1) | `overview_panel.gd:56` `CHIP_SIZE` |
| data row strip | pane-width × 76 | STATION_HUB §12.3 `ROW_HEIGHT` |
| armory console face | 1360×516 | STATION_HUB §20.1's post-S32-R1 amendment |
| tooltip frame | 360 px cap | UI_SPEC §13.1 N47 |
| slot cell | 48 and 40 (1:1) | STATION_HUB §12.3 |
| drawer entry plate | 360×56 | STATION_HUB §12.3 |
| HUD bar caps / minimap bezel | 317×178 / 1063×1065 | `asset-library/INDEX.md:120,130` |

Shipped-art reality (reconcile in the spec): `file` measurements
(2026-10-05) — `ui_button_plate_*` 280×56 true 5:1 bars (`ASSET_CATALOG.md`
right; `INDEX.md:122-125`'s 1041×1087 is the pre-downscale library cut),
`ui_cockpit_panel` 928×512, `ui_armory_console` 2720×1032 (1360×516 @2×),
`ui_status_panel` 1440×1040, `ui_armory_row_plate` 192×64,
`ui_armory_rack_plate` 194×182, `ui_cockpit_frame` 192×192, `ui_panel_frame`
96×96. The fault is use-aspect mismatch: a 5:1 bar stretched into the 15:7
tile smears its rivets and bevel (evidence in `button_candidates.md`). A1
measures every remaining file and completes the census (grep every
`StyleBox*`, `theme_override`, `*_plate` site in `vajb-orbit/ui`, `ui/hud`,
`ui/screens`) — any surface missing from the table above gets the same row
treatment.

## §3 Pinned interface / hard constraints

- Style anchors (owner's, resolved in `button_candidates.md`): the
  `ui_cockpit_*` / `ui_armory_*` / `ui_status_panel` family of
  `UI_CHROME_ASSETS_SPEC.md` §11–§12 **plus the main-menu chromes** — the new
  family must read as their sibling. Never invent an anchor.
- **Aspect law ("respected always"):** every plate is drawn at its class's
  true aspect; caps/corners/rivets never stretch; nine-slice stretch is legal
  only in the flat bands the spec declares per class; a surface whose aspect
  the family cannot cover gets a new plate, not a stretch.
- States (normal/hover/pressed/disabled) are derived by modulate + stylebox
  tint where possible; at most **one paid variant per class** where modulate
  fails QC.
- Generation runs through `$KIE_GENERATE` (kie.ai, 2 K runs: 10 credits =
  $0.05 each) with one shared style block; **no generation in this wave** —
  the deliverable is the prompt set with per-run credit cost summed.
- Unique station backgrounds: PROPOSED **4** unique panel backdrops at the
  pane-content aspect, assigned across the 7 station panes (table in the
  spec) — tick **T-131** (reversal: 1 shared backdrop; or 7 per-pane).
- Every new value is PROPOSED with a one-line reversal. Naming follows
  `ASSET_NAMING_SPEC.md` (`ui_*` prefix, state suffix).

## §4 Spec extract → acceptance list

Deliverables: `docs/design/UI_SPEC.md` **§15** (family law: census table
surface → class → true-aspect target → nine-slice margins → legal stretch
bands; the aspect law; what chrome pins it supersedes) and
`docs/design/UI_CHROME_ASSETS_SPEC.md`'s **2026-10-05 amendment** (one
shell-safe kie.ai prompt per class at true aspect, style anchors named, one
style block, the unique-backgrounds set + assignment, summed credit cost).
Acceptance:

1. AC1 — the census table is complete against grep evidence (cited
   `file:line`), every surface class carries a true-aspect target.
2. AC2 — one shell-safe prompt per class (no `()`, backticks, `&&`, `<`, `>`
   inside prompts), each naming aspect + style anchors + negative list; the
   credit cost is summed (≈10 runs ≈ $0.5 expected; report the exact number).
3. AC3 — the margins law names, per class, where stretch is allowed and pins
   "caps never stretch".
4. AC4 — the unique station backgrounds carry count + assignment as PROPOSED
   values with reversals + tick T-131.

## §5 Worker table

| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D21-A1 | design author — `xiaomi/mimo-v2.6-pro` @ high | `docs/design/,staging/mockup/` | `UI_SPEC.md` §15 + `UI_CHROME_ASSETS_SPEC.md` amendment (+ 1 mockup if needed) → `D21-A1_report.md` |
| D21-R1 | reviewer — `hyper/glm-5.3-flash` @ max | `vajb-orbit/tests/,.agents/gen/slices/D21-chrome-family/` | `D21-R1_review.md` |
| D21-F1 | fixer — as A1 (only if the review leaves HIGH/MED) | `docs/design/,staging/mockup/` | `D21-F1_report.md` |

## §6 Run order
A1 → R1 → (F1 only if HIGH or MED). D21 runs **beside coder 39 (S33)** —
disjoint file sets (docs vs `vajb-orbit/ui`), the D18/S28 parallel-pair shape.

## §7 Tests that move
None in this wave (design-only; gate n/a — no row moves). S35's brief will
name the rows the re-skin moves.

## §8 Hard rules
Docs + mockups only (the hook enforces the file set). No generation spend in
this wave. No invented anchors, names or numbers (PROPOSED + reversal or
report). This brief is law: a number you believe is wrong gets reported, not
changed.

## §9 Staged / deferred
The generation batch (orchestrator, after the owner approves the prompts) →
owner review sheet → cuts/keying/centering per `asset-library/README.md` →
**S35** re-skin wave. T-128/T-129/T-130 ride untouched (T-130 is closed by
S33's P38, not here).

## §11 Tick sheet
| Tick | The call | Default if silent |
|---|---|---|
| **T-131** | unique station backgrounds: PROPOSED 4 across the 7 panes | 4 as proposed |

## §12 Close-out
R1 grades AC1–AC4 first, then the two spec sections' internal consistency;
`staging/verify_wave.py verify --baseline d21_start`; `staging/docs_index.py`
re-run (new sections); TICKS refresh; `MASTER_REPORT.md` §6 recap;
wave-boundary commit. Gate not run (no code).
