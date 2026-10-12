# D24-A1 report — the station-overhaul design round (docs only)

**Worker:** D24-A1 (designer). **Law:** `D24_BRIEF.md`; source `STATION_HUB.md`
§22 + `phases/P4-station-overhaul/PHASE.md`. **Deliverables:** six doc
amendments, no code/scene/theme/asset file touched (`git status`: 6 modified
docs, nothing else). All new values **PROPOSED with reversal** (the S19
precedent); every derived number cites its standing law. `docs_index.py`
re-run — all touched indexes regenerated.

## The acceptance list, answered

| # | Item | Owning amendment | Cite |
|---|---|---|---|
| A1 | the 3×3 OVERVIEW grid: the exact nine-tile set (P25 rows retired), tile min re-derived **(240, 120)** (752≤756 pane; 620≤633 stack — fits unscrolled), flat Tokens chrome (C1's ±10 % band cannot seat 3 columns in 756; C1/S41 tokens re-present on pane/slab re-cut), hull block stays block 3 in a four-block deck, T-184 cured by `text_caption` modulate (SVG remaster staged) | STATION_HUB §23.1, pins P44–P47; ledger §23.11 rows 1–6 | `docs/design/STATION_HUB.md:2113` (P44 `:2117`–P47 `:2120`) |
| A2 | buy-confirmation law: the door list closed by criterion (8 doors incl. the refinery slot + craft; QUEUE/REPAIR/PAY BOUNTY/CANCEL-CONTRACT reported as the boundary), `DialogManager.confirm` route ("OK"/"CANCEL", never `message`), the wording law + one worked example per door | UI_SPEC §17, pins A4–A6 | `docs/design/UI_SPEC.md:1903` (A4 `:1917`, A5 `:1918`, A6 `:1919`) |
| A3 | Cargo overlay, one law both planes: C key (station handles `cargo_toggle`), N28-sheet surface read-only (420/720, N29/N32/N38/N39), the owner's five groups (AMMUNITION/ORE/INGOTS/COMPONENTS/FUEL CELLS), read-only seams (`cargo_items`/`cargo_qty`/`ammo_of` only) | UI_SPEC §18, pins A7–A9; station side STATION_HUB §23.2 | `docs/design/UI_SPEC.md:1921` (A7 `:1933`–A9 `:1935`); `docs/design/STATION_HUB.md:2122` |
| A4 | launch sequence: P29/§2 two-press stands; 3.0 s in-scene overlay beats (S27 clamp t+0 / S28 spool t+1 / fired pair re-pointed t+2.4 / route t+3, `launch_panel.gd:48,859` unchanged); non-cancellable; N29 reading reported (bucket 1); cue rows S27/S28 with takes, [P] sources, durations, buses, pools, seams | STATION_HUB §23.3, pin P48; AUDIO_SPEC §8.7, AUDIO-4/AUDIO-5 | `docs/design/STATION_HUB.md:2133` (P48 `:2137`); `docs/design/AUDIO_SPEC.md:488` |
| A5 | armory equipped list: one row per fitted item (cell id + name + 09 §3 stat line verbatim), grid order, in FIT CELLS' left sector under CELL INFO; row press selects that cell (one selection, two views) | STATION_HUB §23.4, pin P49 | `docs/design/STATION_HUB.md:2139` (P49 `:2143`) |
| A6 | refinery LOAD ALL + machine read + button layout: four-plate 360×56 cluster (T-181's words/band stand, cluster widens — 1 408≤1 765), LOAD ALL (cap 60, overflow stays, no credits), machine strip (per-slot AVAILABLE/RUNNING mm:ss/DONE chips + QUEUED, never colour alone) | STATION_HUB §23.5, P50–P51; 04 §9, R9–R11 | `docs/design/STATION_HUB.md:2145` (P50 `:2149`, P51 `:2150`); `docs/gameplay/04_refinery.md:202` (R9 `:214`–R11 `:216`) |
| A7 | CRAFT tab specced for real: mode pair + AUCTION-idiom list surface (P52); 07 §6 — recipe table with inputs verbatim, fees `ceil(0.35×list)` ≥ 2 000 CR (2 500/3 000/2 800/4 000), materials derived at S28 baselines (1 078/1 876/830/3 740), outputs in 09's language under the Obliterator band, §4's Q1–Q5 resolved, scrap-back 50 %, confirm door | 07 §6, C1–C10 (+ §6.2/§6.3 tables); STATION_HUB §23.6, P52 | `docs/gameplay/07_crafting.md:67` (C1 `:81`–C10 `:90`); `docs/design/STATION_HUB.md:2152` (P52 `:2156`) |
| A8 | exchange bulk sell: **checkboxes** picked (CheckChip 24×24, state by frame + mark, never colour alone), MARK ALL/CLEAR, `SELL MARKED` cluster plate, marked totals from `Exchange.quote`, per-row 56 px SELL plate retires (INSPECT stands) | STATION_HUB §23.7, pin P53 | `docs/design/STATION_HUB.md:2158` (P53 `:2162`) |
| A9 | shipyard build rework: AUCTION house style, HULLS/MODULES category shelves, materials bill as material runs with `<held>/<needed>`, labour the only CR figure, BUILD through the A2 door, `BUILD_HULL_FORMAT`'s CR figures retire; economics (10 §3.1–3.3) untouched | STATION_HUB §23.8, pin P54; 10 §3.5 | `docs/design/STATION_HUB.md:2164` (P54 `:2168`); `docs/gameplay/10_ship_acquisition.md:344` |
| A10 | T-174 (LAUNCH brief column → one flat Tokens box), T-175 (four header-caption surfaces → A1 variations), T-176 (staged row ink floor `text_caption`) folded, tickets cited | STATION_HUB §23.9 | `docs/design/STATION_HUB.md:2170` |
| A11 | the tick list: every new value (P44–P54, A4–A9, AUDIO-4/5, R9–R12, C1–C10) in one table with reversals — ready for the owner's sheet; unticked rows implement at PROPOSED | STATION_HUB §23.10 | `docs/design/STATION_HUB.md:2176` |

## Numbers and their derivations (one line each)

- Tile 240×120: `3×240+2×16=752 ≤ 756` (S41 pane, STATION_HUB.md:2016);
  stack `90+392+84+18+36=620 ≤ 633` (§19.3 split). C1 band h 510–624
  (UI_SPEC.md:1509) → flat box (A5.1).
- Craft fees: `ceil(0.35×list)` (10 §3.1 labour law, 10_ship_acquisition.md:185);
  ≥ 2 000 (07 §5). Materials at 03 §3 / 02's S28 table (02_minerals.md:526).
  %-of-list checked against 10 §3.1's live band 47.7–59.1 % (T-178) — three
  rows inside, Rail Refit flagged (45.4 %, lever +1 ingot).
- Machine strip / chips / captions: state by label + frame (A5.4 State chips),
  never colour alone; ink `text_caption` (UI_SPEC §16.1 A1, ratified).
- The 756 pane, the dialog sink, the shipped exchange/launch/shipyard facts:
  the brief's §3 measurements, cited not re-derived.

## Escalation-ladder disclosures

- **Bucket 1 (decided, reported):** N29 reads as governing the overlay's fade
  envelope only — the 3 s sequence is a game-state presentation (P48,
  STATION_HUB.md:2137); A4's door-list boundary (service spends excluded,
  UI_SPEC.md:1917).
- **Bucket 3 (owner ask supersedes, discharged at the request):** 07 §2's
  FOUNDRY module dies to the CRAFT tab (07_crafting.md:81); P18's 3×2 tile grid
  dies to the 3×3 ruling (§22's own words).
- **Owner rulings untouched:** §2's two-press law, T-181's words + 360×56 band
  (extended, not superseded), T-182's 32 px strip, the P29 hints, 10 §3's
  economics, UI_SPEC §16.1 A1, the owner-locked 18_engine_spec.

## Flagged for the owner (not fixed silently)

1. Rail Refit's 45.4 %-of-list (under the 47.7 % floor; lever: +1 ingot).
2. Shield Lattice 8 500 / Deep Scanner 11 400 list values sit above S28 L2's
   1–2 × SC(t) module band (exotic deviations, Hyperdrive precedent).
3. 07 §3's "3–6 sessions" supply math predates S28's value halving — re-measure
   at playtest.
4. A2's boundary: QUEUE/REPAIR/PAY BOUNTY/CANCEL-CONTRACT carry no dialog —
   widen by ruling if wanted.

## Close-out (the orchestrator's, per §12)

Gate ×2, `verify_wave.py verify --baseline d24_start --expect-reports <this
file>`, WAVEBOARD/TICKS refresh, wave-boundary commit. Indexes: regenerated
by this worker (STATION_HUB §23, UI_SPEC §17/§18, AUDIO_SPEC §8.7 rows in the
generated TOCs). No test moves (docs-only wave, brief §8).
