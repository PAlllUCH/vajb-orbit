---
slice: D24
reviewer: D24-R1
verdict: passed-with-followups    # four MEDs remain after the disclosed cure → fixer pass per the run order
gate: "1330/0 ×2 byte-identical (post-cure, staging/gate.py)"
---

# D24-R1 review — the station-overhaul design round (docs only)

**Read:** `D24_BRIEF.md` (law) → `D24-A1_report.md` → the six amended docs,
diffed against the brief's §3 measured cites and the standing laws (UI_SPEC
§3.10 A5 / §15 / §16 / N-pins, STATION_HUB §2/§19/§21/§22, 01/02/03/05/09/10
tables). No CONTRACTS diff owed (docs-only wave, brief §8). One one-line doc
slip cured in review, disclosed as F2.

## Acceptance list (graded first, per the template law)

- **A1 — pass** — 3×3 nine-tile set (P25 rows retired), `TILE_MIN` re-derived (240, 120) with 752/756 + 620/633 arithmetic, hull block seated as block 3 of the four-block deck, T-184 cured by `text_caption` modulate with reversal (SVG remaster staged) — `docs/design/STATION_HUB.md:2117-2120`.
- **A2 — pass** — 8-door list closed by criterion (the brief's six named doors + refinery slot + craft), `DialogManager.confirm`/`"OK"`/`"CANCEL"` route, wording law; one worked example per named door (craft rides the material-door template — F6) — `docs/design/UI_SPEC.md:1917-1919`.
- **A3 — drift** — the C key and the five contents groups are answered, but "one law for station and flight" picks the N28 overlay surface while flight keeps `cargo_toggle` on the HUD `CargoBlock`; the overlay's flight seat is never chosen — `docs/design/UI_SPEC.md:1926,1933-1934` (F5, MED).
- **A4 — pass** — P29/§2 two-press stands; 3.0 s in-scene overlay beats with the route exit (`launch_panel.gd:48,859` unchanged); §8.7 rows carry the full §3 row shape (id, take, [P] source, duration, bus, pool, seam) — `docs/design/STATION_HUB.md:2137`; `docs/design/AUDIO_SPEC.md:500-501`.
- **A5 — pass** — one row per fitted item (cell id + name + 09 §3 stat line), grid order, seated under CELL INFO in the left sector, row press selects the cell — `docs/design/STATION_HUB.md:2143`.
- **A6 — pass** — LOAD ALL door beside the three T-181 plates (words + 360×56 band stand), machine strip `AVAILABLE`/`RUNNING mm:ss`/`DONE` + `+ n QUEUED` (never colour alone), cluster re-laid out — `docs/design/STATION_HUB.md:2149-2150`; `docs/gameplay/04_refinery.md:214-217`.
- **A7 — drift** — specced for real with recipe rows, byte-exact 01/02/03-derived costs and reversals per number, but two of the S28 value-ladder checks misfire: the %-of-list band read (F1) and the SC(t) tier multiples (F3) — `docs/gameplay/07_crafting.md:92-114`.
- **A8 — drift** — checkboxes picked (frame + own-child-rect mark), MARK ALL/CLEAR, `SELL MARKED`, `Exchange.quote` totals, per-row plate retired; but the sell buttons re-lay into a foot cluster that contradicts N48/N49 and §5.8 with no ledger row (F4) — `docs/design/STATION_HUB.md:2162`.
- **A9 — pass** — AUCTION house style, HULLS/MODULES shelves, materials bill as `<held>/<needed>` runs, labour the only CR figure, BUILD through the A2 door, `BUILD_HULL_FORMAT`'s fate named; 10 §3.1–3.3 economics untouched — `docs/design/STATION_HUB.md:2168`; `docs/gameplay/10_ship_acquisition.md:344-362`.
- **A10 — pass** — T-174/T-175/T-176 land inside the amended sections with the tickets cited and their reversals — `docs/design/STATION_HUB.md:2170-2174`.
- **A11 — pass** — one tick table (P44–P54, A4–A9, AUDIO-4/5, R9–R12, C1–C10), every row PROPOSED with its reversal; the two no-tick exclusions (10 §3.5 view pointer, the owner-approved cures) reasoned — `docs/design/STATION_HUB.md:2176-2202`.

## The review's four questions

1. **Number + reversal + tick row per owner ask: yes.** All nine §22/PHASE asks resolve to pins that carry values, reversal columns and §23.10 rows (07 §6.3's per-row reversal covers the derived materials; 10 §3.5 carries its own reversal).
2. **A5-lawful: yes.** Every layout number is a container minimum, separation or cut size (GridContainer 3/16, `TILE_MIN` (240, 120), CheckChip 24×24, plates 360×56); marks draw in own child rects (A5.2(iii)); no coordinates, no `_draw` over content anywhere in the round.
3. **§16 ink lawful: yes.** All ink is §1 tokens or the §16.1 A1 variations (`text_caption`, `metal_light` frame step); no new hex; `text_dim` appears only in reversal columns; state by label + frame throughout (one unwritten ink — F10).
4. **Costs from 01/02/03: derived, with the checks misfiring.** Materials re-computed byte-exact vs 03 §3 + 02's S28 table (1 078 / 1 876 / 830 / 3 740 all verify); fees = `ceil(0.35 × list)` per 10 §3.1:185 under 07 §5's ≥ 2 000 floor (2 500/3 000/2 800/4 000 verify); build economics untouched. The ladder *checks* carry F1/F3.
5. **Owner rulings:** §2's two-press, §16.1 A1, T-181/T-182 and 10 §3 stand as claimed (`docs/design/STATION_HUB.md:2215-2217`); the bucket-3 deaths (FOUNDRY, P18's 3×2) are reported as discharged at the owner's request; §23.11's ledger carries ten supersession rows — but misses the one in F4.

## Measured-cites diff (brief §3)

All ten §3 cites are cited, not re-derived (tiles `overview_panel.gd:33,38,251`,
the 756 pane, the dialog sink, `CargoBlock`/`cargo_toggle`,
`launch_panel.gd:48,859`, the refinery band, `exchange_panel.gd:39,51`,
`shipyard_panel.gd:146`, the armory blocks, the three cures); the one required
re-derivation (the tile minimum) is done against the §3 frames. Caveat: the
arithmetic mixes two measurement frames (S41's pane width vs D19's content
split height) and spends the full 756 px — F9.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | `07_crafting.md:100-102` | The band read "three rows inside, one flagged" holds only over the union of the live and sketch bands; against the standing live band 47.7–59.1 % (T-178) just two rows sit inside and DEEP SCANNER's 67.9 % is outside above, unflagged on that axis (the report's derivation line repeats the miscount). Evidence: `07_crafting.md:102` vs `10_ship_acquisition.md:189`. | fixer |
| F2 | MED | `07_crafting.md:98` | RAIL REFIT's stated lever "+1 ingot (→ 47.6 %)" lands below the 47.7 % floor it cites (3 810/8 000 = 47.63 %) — **cured in review, disclosed**: the row now reads "+2 ingot (→ 49.9 %)" (3 990/8 000). Evidence: `07_crafting.md:98` vs `10_ship_acquisition.md:189`. | cured here |
| F3 | MED | `07_crafting.md:97-99` | The exotic-deviation flags price SHIELD LATTICE at 2.83 × SC(3) although the row labels its output tier IV (1.42 × SC(4) = in L2's 1–2 × band), and RAIL REFIT/DEEP SCANNER carry no tier label, so no multiple is derivable; the report's flag #2 also omits RAIL REFIT 8 000 = 2.67 × SC(3). Evidence: `07_crafting.md:97-99` vs `01_economy_core.md:311,325-331`. | fixer |
| F4 | MED | `STATION_HUB.md:2162` | P53 re-lays `SELL`/`SELL ALL RAW`/`CANCEL` into a horizontal four-plate "foot cluster" while N48/N49 pin them in the trade-column stack and §5.8 sizes `SELL` at 88 px; §23.11's ledger carries no N48/N49 row and P53's reversal names neither. Evidence: `UI_SPEC.md:1415-1416`, `STATION_HUB.md:829`. | fixer |
| F5 | MED | `UI_SPEC.md:1926,1933-1934` | "One law, both planes" leaves the overlay's flight seat unchosen: A7 keeps flight's `cargo_toggle` on the HUD `CargoBlock`, A8 seats the N28 sheet over a pane — the owner's "same in space" is answered only station-side. Evidence: `UI_SPEC.md:1926` (header) vs `:1933-1934` (A7/A8). | fixer |
| F6 | LOW | `UI_SPEC.md:1919` | The craft door (A4's #8) has only the generic `BUILD/CRAFT` template, no instantiated worked example; the brief's six named doors all have one. Evidence: `UI_SPEC.md:1917,1919`. | → `T-187` |
| F7 | LOW | `STATION_HUB.md:2120` | P47 calls §16.1 A3 "the ratified cure"; only A1 carries a RATIFIED mark (A2/A3 remain PROPOSED pins). Evidence: `UI_SPEC.md:1876-1883`. | → `T-188` |
| F8 | LOW | `AUDIO_SPEC.md:500-501` | Cue rows S27/S28 continue the audio series but "S28" now also names the 2026-10-08 value law inside the same file set's derivations; the pre-existing S-series/​wave-id collision reaches the cost prose here. Evidence: `07_crafting.md:88`, `04_refinery.md:208`. | → `T-189` |
| F9 | LOW | `STATION_HUB.md:2117` | P44's 752 ≤ 756 leaves 4 px and spends the whole measured pane width with no content-inset allowance, while its height check uses the content split; re-measure the grid seat at implementation. Evidence: `STATION_HUB.md:2117` vs `:1794`. | → `T-190` |
| F10 | LOW | `STATION_HUB.md:2162` | P53's CheckChip leaves the check mark's ink unnamed (§1's success law reads `metal_light` + `text_primary`); the frame step already carries the state, so no §16 violation, just unwritten. Evidence: `UI_SPEC.md:64`. | → `T-191` |

Ticket ids continue the series after `T-186` (LOW_BACKLOG's current max);
they are assigned at the close-out ticketing pass.

## Verified fixes

- F2 — fixed in review (one-line, disclosed above), arithmetic verified against the 47.7–59.1 % band.
- F1/F3/F4/F5 — awaiting the fixer pass (the review leaves MED).
- F6–F10 — no fix owed here; ticket at close-out.

## Gate

Docs-only wave (brief §8/§12). Run after this review's one-line doc cure:
`python3 staging/gate.py --times 2` → `[SUMMARY] passed=1330 failed=0`, two
runs byte-identical (the live count, not a target). The cure touches
`docs/gameplay/07_crafting.md` prose only, so `verify_wave.py verify
--baseline d24_start` will show that one file beyond the builder's set — that
diff is F2 and is expected.
