# D21-R1 review — the one true-aspect chrome family (grades D21-A1)

Reviewer re-measured everything; nothing below trusts the report. Line cites in
`vajb-orbit/ui/**` drift ±6 lines against the working tree (parallel S33/S34
coder edits moved lines after A1's snapshot) — values were re-verified at their
moved positions, so only material drift is flagged.

## Re-measure summary

- (a) Census: re-ran the three greps over `ui`, `ui/hud`, `ui/screens`
  (69 / 525 / 217 today vs the saved 69 / 519 / 217 — the delta is S33 line
  drift, not a coverage change). Re-measured all 53 `assets/ui/*.png` with
  `file`: every pixel figure in the report and both spec sections matches
  (280×56 plates, 928×512, 2720×1032, 1440×1040, 192×64, 194×182, 192×192,
  96×96, 42×14, 317×178, 200×200). Verified the cited constants at their moved
  lines: `TILE_MIN` 300×140, `ROW_HEIGHT` 76, `CHIP_SIZE` 96×32, console
  1360×516, `MODAL_SIZE` 720×520, `POOL_BAR_SIZE` 260×14, `DIAL_SIZE` 120×120,
  bezel margins 16 (`hud.tscn`), `CAP_WIDTH` 360, menu min 70, `PANE_MARGIN`
  36, `HOLD_CONTENT_WIDTH` 560, `AMMO_CARD` 320×68, `DRAWER_ENTRY_WIDTH` 272
  (:129) vs `RAIL_ENTRY_HEIGHT` 56 (:122), STATION_HUB §19.3 pane x 23..1896 /
  y 163..1021 / content 1765×753 / `ActionPrimary` 360×56 at x 1482..1842.
- (b) Prompts: mechanically scanned all 14 fenced blocks + the 4 BG subject
  lines for `(` `)` backtick `&&` `<` `>` — zero hits; shell-safety claim
  verified. Every class block states its aspect in prose; the shared style
  block carries the owner's anchor family, so every run names anchors; all 13
  class prompts carry the negative list incl. the four mandated negatives.
- (c) Cost re-summed from the prompt count: 12 class runs + 4 backdrop runs =
  16 × 10 credits = 160 = $0.80; ceiling 6 state-bearing classes ≤ 6 runs =
  220 / $1.10. Arithmetic exact.
- (d) Every new value carries PROPOSED + a one-line reversal (margins, bands,
  C7/C8/C13 masters, AUCTION move, stems, substrate, supersessions). T-131
  carries count (4) + assignment table (BG-1..BG-4 → panes) + both reversals +
  the §14 tick-ID collision note.
- (e) Aspect law: A1–A7 close every loophole they name (A2 caps, A3 bands,
  A4 escape, A5 C12-by-construction, A6 contain, A7 states). The failures are
  in what the law is applied to — see F1/F2/F3/F4.

## Acceptance grades

| AC | Verdict | Basis |
|---|---|---|
| AC1 | met with defects | Table complete in structure; 53/53 pixel measures correct; but two surface kinds missing (F4, F5) and two targets wrong against drawn rects (F2 covers C4's, F3 covers C1's) |
| AC2 | **unmet** | Prompts are shell-safe, anchored and negatived, but 6 of 13 classes state aspects the kie.ai generators cannot render (F1) — as written the set cannot produce the family |
| AC3 | **unmet** | The margins law names no legal dressing for the majority of C4's own assigned rows (F2) |
| AC4 | met | Count + assignment + reversals + T-131 + collision note all present and consistent |

## Findings

- D21-A1/F1 — HIGH — AC2 unmet in substance: C2 45:7, C4 140:19, C9 45:7, C6
  340:129 exceed the generators' widest supported aspect (3:1 / 21:9 per the
  skill's model table), and C1 15:7 / C5 65:48 match no supported value; the
  spec states aspects in prose only, names no `--aspect` value per run, no
  crop-to-master route, and §13.5 QC never verifies a returned render's
  aspect — evidence `UI_CHROME_ASSETS_SPEC.md:356,376-470,516-523` vs
  image-generator `references/models.md:29-61` and
  `scripts/kie_generate.py:61,79,97` (aspect sets cap at 3:1 / 21:9).
- D21-A1/F2 — HIGH — AC3 unmet for the row strips: §15.3 caps C4's legal
  width at 960 while the census itself assigns C4 to rows that expand-fill to
  the ~1765 pane width (OVERVIEW service rows `overview_panel.gd:340` in the
  pane stack; AUCTION/SHIPYARD/REFINERY/LAUNCH/settings rows same idiom,
  `exchange_panel.gd:424,559`; brief §2 pinned the row strip "pane-width ×
  76") — for those rows the law names no legal stretch at all, and the
  deviation from the brief's pinned fact is unreported — evidence
  `UI_SPEC.md:1476,1483-1493,1583-1586`.
- D21-A1/F3 — MED — C1's target and ±10 % band cannot cover the drawn tiles:
  tiles are `SIZE_EXPAND_FILL` in a 3-column grid over the 1765 content box ⇒
  ~567 wide drawn vs 300×140 target (band ceiling 330), so the owner's
  flagship surface fails A4 on day one; A1 followed the brief's pin but did
  not report the contradiction its own band creates — evidence
  `UI_SPEC.md:1478,1537-1539` vs `overview_panel.gd:48-49,203-204`.
- D21-A1/F4 — MED — the small pressables are missing census rows: armory
  `BUY` 64×16 and barrel `✕` 24×29 wear the `StationButton` plate in live
  code, have no §15.1 row, and fit no class (C2's v band is 56–88); §15.4
  item 2 supersedes the §8 plate rule but leaves A5.4's Pressables sizes
  classless — evidence `armory_panel.gd:1493,1657` vs `UI_SPEC.md:687,1476`.
- D21-A1/F5 — MED — `repairs_panel.tscn` / `fitting_panel.tscn` carry chrome
  inside the census's own grep scope (`PanelRaised` at
  `repairs_panel.tscn:93`; 15 override hits in `fitting_panel.tscn`) yet have
  no §15.1 row — not even the retired/dev rows the census grants
  `_mockup_station` and `dev_tuning_menu`; scenes are unreferenced (scripts
  preloaded as helpers only), so retired rows suffice — evidence
  `staging/mockup/d21_census/*` vs `UI_SPEC.md:1446-1531`.
- D21-A1/F6 — LOW — census evidence double-counts: the greps passed `ui`
  together with its own subdirs `ui/hud`, `ui/screens`, so those files appear
  twice; saved 69/519/217 vs unique 47/337/148. Coverage conclusions
  unaffected — evidence `staging/mockup/d21_census/*.txt`.
- D21-A1/F7 — LOW — cite drift on four verified-correct values: dialog min
  420 lives at `dialog.tscn:37` not `dialog.gd:121-127`; cluster 464×256 is
  `cockpit_style.gd:79` (`box_size`) not :193; `AMMO_CARD` is :158 not :152;
  `DIAL_SIZE` :202 not :200 — evidence `UI_SPEC.md:1510,1521,1501,1520`.
- D21-A1/F8 — LOW — §13.4's C8 wording "keeps the existing cuts" contradicts
  the C8 paid run and §15.4 item 6 ("shipped atlases keep their names until
  S35 swaps them"); say "replaces the slot faces in place under the existing
  names" — evidence `UI_CHROME_ASSETS_SPEC.md:507-508` vs `:421-429,529`.
- D21-A1/F9 — LOW — §15.1's single C13 row conflates the full-rect shell
  backdrop (ships `ui_backdrop_hangar`, 2048×1152, stays per §13.3) with the
  pane backdrops' 1765×753 target; cover-fit crops so no stretch is possible
  either way, but the row should name the pane backdrops as C13's users —
  evidence `UI_SPEC.md:1465` vs `UI_CHROME_ASSETS_SPEC.md:483-501`.

## Verdict

**Blocked** — two HIGH (F1, F2). Fixer (D21-F1) items, in order:

1. F1: add a per-class generator mapping — a supported `--aspect` value
   (21:9 / 3:1 / 4:3 / 3:2 / 1:1) plus the declared crop-to-master route for
   the six unmatched classes, a §13.5 step that verifies each returned
   render's pixel aspect against the class's stated aspect before cutting,
   and the re-summed cost if any class needs a wider run. All PROPOSED with
   reversals.
2. F2: re-measure the widest C4 users (OVERVIEW service rows, pane data rows,
   AUCTION/SHIPYARD/REFINERY/LAUNCH rows, settings rebind rows, station name
   plate height in the 123 band) and either extend the C4 h band to the
   measured maximum or split a long-strip class; restore the brief's
   "pane-width × 76" fact and report the deviation from 560×76.
3. F3: re-derive the tiles' drawn aspect (~567×140) and re-declare C1's
   target/band to cover it (or order a tile-class plate at the drawn aspect),
   PROPOSED with reversal.
4. F4: add census rows for the small pressables (BUY 64×16, ✕ 24×29) with
   their class or the A5.4 flat-chip escape, and reconcile A5.4's Pressables
   row in §15.4.
5. F5: add retired/dev rows for `repairs_panel.tscn` / `fitting_panel.tscn`.
6. F6–F9: polish — unique-count the census evidence, fix the four cites, the
   C8 naming wording, and split the C13 row.

AC4 and the cost arithmetic need no fixer work. Re-run `staging/docs_index.py`
after the fixer's section edits (close-out law).
