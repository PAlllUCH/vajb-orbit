---
slice: D19
reviewer: D19-R1
verdict: blocked (HIGH remains)
gate: "1074/0 → 1074/0 (A1's post-edit run; the diff surface is docs + mockups only, so the gate cannot move — close-out re-runs per brief §12)"
---

# D19-R1 review

Diffed against `UI_SPEC.md` §11 (N24–N30) + §3.10 A5.1–A5.5 + §5.1/§5.2 + §8, and
`STATION_HUB.md` §18 (P15–P21) + §2/§3.1/§15/§16/§17 — never against A1's report.
Every census/ledger cite below was opened in the code or doc it names.

## Acceptance list
- A1 — pass — §12.1–§12.4 restate §3.1's rail/header/footer rows, §5.1/§5.2 and §8 P1/P2 exactly (drawer table = §3.1 verbatim, §3.4's inset arithmetic honoured on the left edge); drift is F5/F7.
- A2 — drift — §19.1–§19.4 carry the §5.7 cluster contradiction (F6), two derived-arithmetic slips (F7) and re-propagated stale cites (F9); P22–P30 and the five blocks/conformance otherwise match P18/§3.1/§15.
- A3 — drift — `d19_overview_wireframe.md` contradicts its own spec text twice (F1, F2 HIGH); the popup wireframe mis-cites one range (F10); shell wireframe clean.
- A4 — drift — rows 1–3 and 5–15 verified in code as cited; one violation class is missing (F3), row 4's fitting cites do not resolve (F4), the row-7 class has four live instances the census omits (F11).
- A5 — drift — all 15 old cites resolve by content (§16 P6/P7, §17.1/§17.2/§17.4, §2/§3.1/§3.2/§4/§5.5/§5.10/§9/§10/§12/§15.1, A4.4, `station.tscn:273` all read); line numbers are off by one on four rows (F8).
- A6 — pass — route order, `flare`/`sunburst` (GENERATION_PLAN.md:11), 10 cr = $0.05/2K and the staged-only gate all match the pipeline law; nothing generated (working tree adds docs/mockups/reports only); one harness note (F15).

Series discipline: N31–N41 (§12.6) and P22–P30 (§19.5) are fresh, each with a reversal; the 09-series S19 P-rows stop at P8 (§17's namespace note), so no collision.

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | HIGH | `staging/mockup/d19_overview_wireframe.md:22` | the SHIPYARD tile caption reads `HULLS & REPAIR`, contradicting P23's pinned verbatim caption `HULLS, MODULES AND REPAIRS` (§19.2; the other five tiles are exact prefixes or exact) | D19-F1 |
| F2 | HIGH | `staging/mockup/d19_overview_wireframe.md:26` | the active-hull meta line `… LIGHT FIGHTER CLASS · 8 SLOTS · 2 ENGINES` contradicts §19.1 block 3's own template `<class> CLASS · <hull> · <slots>` and the shipped `META_FORMAT` (`shipyard_panel.gd:123` = `%s CLASS · %d HULL · %d SLOTS`) — slots/engines printed, the HULL figure dropped | D19-F1 |
| F3 | MED | `UI_SPEC.md` §12.5 census | misses the selection/hover-driven grid-rebuild class: `shipyard_panel.gd:508-527` (`_set_layout_grid` remove/queue_free/add_child) fires from `_on_row_focused:1029` → `_preview_row:1105` → `_refresh_preview:966,975` — a node-tree mutation on focus, N31's own bar; `armory_panel.gd:2906-2935` (`_sync_grid`) rides the same `_refresh_footer` hover path row 4 cites (:3755/:3767), fitting twin `:484` | D19-F1 |
| F4 | MED | `UI_SPEC.md` §12.5 row 4 | the fitting cites `:1209,1253` resolve to nothing — the `_refresh_footer()` calls on the hover/focus path sit at `fitting_panel.gd:1192,1210` (armory's `:3768` is the `_inspect_browser` line; the call is `:3767`) — S30 cannot cure row 4 from the list alone | D19-F1 |
| F5 | MED | `UI_SPEC.md` §12.6 N37 vs §11.1 N28 | N37 routes grid cells to the cluster chip, superseding pinned N28's "opens from the row/cell `INSPECT` inline chip" for the cell half without an N28 amendment; the deviation is recorded only in A1's report — owner tick owed (bucket 2) | owner (D19-F1 records) |
| F6 | MED | `STATION_HUB.md` §19.4 REFINERY row | cluster `CANCEL` + `REFINE` contradicts §5.7's pinned action set `REFINE N` · `REFINERY ALL` · `CANCEL` (`:760-766`) — REFINERY ALL is dropped and REFINE N renamed, with no §19.6 ledger row; S30 cannot resolve it from the docs | D19-F1 + owner |
| F7 | MED | `STATION_HUB.md` §19.3 | derived arithmetic slips: content box `x 77..1843` is self-inconsistent (its "1766 wide" needs the end at 1842, the §3.4/host precedent `453..1842` off a `399..1896` plate = ±54), and the cluster row inherits it (`x 1483..1843` → 1482..1842); "the shared x 128" is a fresh value with no PROPOSED tick (brief rule 2) and its own row gives 129 (77 + 40 + 12) | D19-F1 |
| F8 | MED | `STATION_HUB.md` §19.6 rows 9/10/12/13 | ledger line cites off by one: `:719`→`:720`; `:922-923`→`:923-924`; §10's `:1147/:1150/:1153`→`:1148/:1151/:1154`; `:1123`→`:1124`; `:1221-1222`→`:1222-1223` | D19-F1 |
| F9 | MED | `STATION_HUB.md` §19.1 block 3 | cites `shipyard_panel.gd:74-80` (labelled pairs) and `:82-84` (meta) — both ranges land in `SLOT_GLYPHS`; the pairs are `STAT_ROWS` `:94-100`, the meta `META_FORMAT` `:123` — re-propagates T-95's stale-cite class into the new law, now doubly shifted | D19-F1 |
| F10 | MED | `staging/mockup/d19_popup_wireframe.md:57` | element 5 cites "`_affix_lines` output (`shipyard_panel.gd:741-751`)" — that range is `_stat_block_of` (§12.2's own cite); `_affix_lines` starts `:764` | D19-F1 |
| F11 | MED | `UI_SPEC.md` §12.5 census | the row-7 class (a description surface beyond N27/N28) has four live instances the census omits: `armory_panel.gd:1968,2029,3139,3645` all write `tooltip_text` (Godot's default tooltip path — N27's reversal; `:3645` is already T-104) | D19-F1 |
| F12 | LOW | `STATION_HUB.md` §19.1/P22 | P18's stack arithmetic (776 vs 633) rests on per-block minima §19.1's table never states; P22's scroll is the PROPOSED cure and implements at stated value (brief §11), so the wave stands — owner tick owed | ticketed as `T-107`, not fixed here |
| F13 | LOW | `STATION_HUB.md` §19.5 P30 | P18's `REPAIR →` glyph risk is real (§5.8:805-806's measured finding) and P30's chevron mark covers the render; P18's wording stands untouched — owner may still amend the pin | ticketed as `T-108`, not fixed here |
| F14 | LOW | `STATION_HUB.md` §16 P18 | P18's "§15's W3 names" mis-cite stands in the pin (U2 owns the strip labels, §15.6); §19.1 row 4 cites U2 correctly — one-word owner amendment owed | ticketed as `T-109`, not fixed here |
| F15 | LOW | `UI_SPEC.md` §12.6 N34 | `station_inspect` (+ P20's `station_prev_module`/`station_next_module`) is absent from `project.godot`'s input map and §12.6/§19.5 carry no registration note (§10's own note is the precedent) | ticketed as `T-110`, not fixed here |
| F16 | LOW | `UI_SPEC.md` §12.1 | seats §8's 272×56 `StationButton` plates inside the 270 px content box it re-homes verbatim from §3.1 (x 69..339) — 2 px overflow; the shipped plate art measures x 71..325 (`station.tscn`) | ticketed as `T-111`, not fixed here |
| F17 | LOW | `STATION_HUB.md` §19.3 | the cluster box seats one primary + one secondary; the three-plate clusters §19.4 itself names (EXCHANGE, LAUNCH, SERVICES) have no stated seat or gutter arithmetic | ticketed as `T-112`, not fixed here |

Weighed reported-not-changed items: P18's stack arithmetic → F12 (LOW, P22 already carries the cure); the arrow glyph risk → F13 (LOW, P30 covers it); the W3/U2 cite → F14 (LOW); N28's cell-chip impossibility → F5 (MED — it changes a pinned trigger, so the N28 amendment must land, not just the report note); N31's command/auto-reveal clauses and the RETROFIT vocabulary are bucket-1 judgments inside the pinned acceptance and stand.

## Verified fixes
None yet — fixer pass owed (HIGH/MED present).

## Gate
A1 measured `[SUMMARY] passed=1074 failed=0` after the doc edits (report Evidence); `git diff --stat` shows the wave's surface is `UI_SPEC.md`/`STATION_HUB.md` + three mockups + the report — no `.gd`/`.tscn`/`.tres` touched, so the gate cannot move; the orchestrator re-runs it at close-out per brief §12. Working-tree note: `dispatch_coder.md` and `phases/P3-content-feel-push/PHASE.md` carry edits outside every D19 worker set (orchestrator queue bookkeeping, not a wave deliverable). Probes this review: doc/code reads only — no editor or game probes needed for a design-only wave. LOW rows T-107–T-112 are assigned here; `_state/LOW_BACKLOG.md` sits outside this worker's file set, so the orchestrator files them at close-out.
