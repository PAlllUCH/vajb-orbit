---
slice: S42
reviewer: S42-R0
verdict: passed-with-followups   # no HIGH; two MED findings take the one fixer pass
gate: "1330/0 (baseline) → worker 1317/6 (premise rows, pre re-cut) → reviewer on this tree 1341/0"
---

# S42-R0 review

Context read in the brief's order: S42-V0_BRIEF (acceptance list + spec extract),
STATION_HUB §23.1 P44–P47 + §23.10 tick rows P44–P47 + §23.11 ledger rows 1–6,
S42-V0_report, the four deliverables, UI_SPEC §3.10 A5.1–A5.5 + §16.1.

## Acceptance list

1 — pass — nine entries row-major in P44's order (`overview_panel.gd:44-54`); one
      GridContainer, columns 3, h/v separation 16 (`:199-206`); every tile's
      `custom_minimum_size` (240, 120) (`:212`). Rows `test_s42_overview_grid.gd:116-145`.
2 — pass — no `SERVICE_ROWS`/`ServiceRows`/`%ServiceHost`/`Open` chip anywhere in the
      touched files (grep clean; `overview_panel.tscn` is 60 lines with `%BlockScroll`/
      `%BlockStack` kept); the stack is IdentityBlock/TileGrid/HullBlock/FlavourLine.
      Rows `:148-177`.
3 — drift → F1 — the probe ships and runs (`:182-215`); my re-run on this tree:
      stack (1756, 636) min 636 ≤ scroll viewport 636 (unscrolled, 0 px slack), grid
      min (752, 392) = P44's 3×240+2×16 exactly — but "first tile seated (575.0, 120.0)",
      not the report's "(240, 120)": the report's evidence predates the close-out
      expand re-cut. The hull-123-vs-84 and pane-width deviations are real and reported.
4 — pass — `_apply_tile_chrome` (`overview_panel.gd:282-292`): flat box, `void_panel`
      fill, 1 px `metal_mid`, zero corners; hover/pressed/disabled/focus stay the theme's
      own Button boxes (P23/P45); no `ChromeCanvas`, no `chrome_class`, no
      `ChromeFamily.apply_tile` on tiles (the chip's `apply_chip` is the hull block's C3,
      not a tile). Rows `:220-272`.
5 — pass — press emits `navigate_requested(SERVICES, &"contracts"|&"insurance"|&"vaults")`
      (`:295-297`; non-service tiles emit their deck with an empty hint — today's
      behaviour); `station.gd:1608-1615` consumes the hint via `_show_service` and clears
      the seam. End-to-end row `:301-330` (VAULTS tile → vaults pane the one showing).
6 — pass — the five P23 captions verbatim vs HEAD's `TILES`, AUCTION re-cut to
      `THE 20-MINUTE SHELF`, the three service captions exactly P46's strings
      (`:44-54`); data and built labels both asserted (`:333-351`).
7 — pass — all nine glyphs rest at `text_caption` (`:248`, every tile `tinted: true`) and
      step to `text_primary` on hover, back on unhover (`:302-311`); no glyph renders
      WHITE at runtime. Rows `:356-383`. The surviving `else Color.WHITE` arm is F2.
8 — pass — `_apply_service_availability` (`:466-485`): label kept, `button_disabled`,
      the registry's reason on the caption line in `text_dim`, in-place swap (A5.5); an
      unresolvable station leaves every tile as shipped. Row `:388-426` (s2_outpost →
      INSURANCE disabled; hover keeps rest ink on a disabled tile — the report's
      disclosed bucket-1 call, verified).
9 — pass — `focus_primary()` seats the ring on the first non-disabled tile (`:120-124`);
      hover publishes title + caption on `inspect_requested`, un-hover clears (N46)
      (`:302-311`). Row `:431-460`.
10 — pass — the suite pins items 1–2 (`:116`, `:148`), 5 (`:277`, `:301`), 6 (`:333`),
      7 (`:356`), 8 (`:388`), 9 (`:431`), plus the T-189 probe (`:182`) and the P45
      chrome rows (`:220`, `:244`); 11 rows, my run 11/0.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | S42-V0_report.md vs overview_panel.gd:213-218 + test:266-272 | The report no longer describes the deliverable: its deviation bullet says tiles do not expand ("tiles hug left") and its T-189 evidence reads "first tile seated (240, 120)", while the shipped code expands the tiles (`SIZE_EXPAND_FILL`, seated (575, 120) — my own probe) and the suite's P45 row was re-cut to `>= (240, 120)`. Both files carry "developer … (disclosed)" comments, but the disclosure is in no graded document (not the report, not SLICE.md, not the WAVEBOARD diff); the report's item cites also sit ~6 lines stale of the close-out insertions. | fixer pass: amend the report's deviation bullet + T-189 evidence to the shipped numbers and re-cite |
| F2 | MED | overview_panel.gd:248 | The `tinted` branch survives with its `else Color.WHITE` arm — T-184's defect shape preserved behind all-true data — against the review yardstick ("the tinted branch is gone"). The report's stated reason (keeping S40's A3 census row alive, `test_s40_legibility.gd:166-167`) requires only the KEY, not the branch: all nine tiles are `tinted: true`, so hardcoding the caption ink keeps that row green. | fixer pass: drop the branch, hardcode `_token(&"text_caption")`, keep the key (the report's own named reversal) |
| F3 | LOW | overview_panel.gd:289-292 | The state styleboxes are copied from the theme once at build time; `NOTIFICATION_THEME_CHANGED` re-applies only `_apply_tokens` (`:100-102`), so a theme hot-swap would leave the tiles' copied hover/pressed/disabled/focus boxes stale. Latent only — the theme is static in-game. | → ticketed, not fixed here |
| F4 | LOW | overview_panel.gd:218 | The expansion itself, recorded: tiles seat ~575×120 at the measured 1768 pane, not the pin-arithmetic's 240 seat; `TILE_MIN` (240, 120) stands as the pinned minimum and the D19 full-width tile look (P45's own reversal-row cite, 567–578 wide) returns. Unpinned sizing behaviour, disclosed in the deliverable with its reversal named; the owner may reverse to the 752-px hug. | recorded — owner's call, not fixed here |
| F5 | LOW | STATION_HUB.md:2019 vs test:36 | P44's width premise ("752 ≤ 756, the S41-measured pane, §22's own note") disagrees with the S41 harness's own content box (1768×756 — 756 is the height; project base is 1920×1080). The worker surfaced this ("the pane-width reading") and left the pin per T-189; the doc figure is the developer/owner's to correct. | → ticketed, not fixed here |

## Specific checks

- File set: the S42 delta lives only in the four brief files (+ the report). The other
  working-tree diffs attribute to the developer/orchestrator: the four premise-suite
  re-cuts (S42-branded comments; anticipated by the V0 brief), the docs amendments
  (P47's T-187 wording fix, P53's T-190, UI_SPEC A6's T-186 — other waves' boundaries),
  and the WAVEBOARD/dispatch queue updates. No HIGH.
- No coordinate layout in the wave's delta (grep clean; `set_anchors_and_offsets_preset`
  is the anchor idiom, A5.2(i); station.gd's pre-existing `offset_*` lines are the S30
  drawer, untouched by the 7-line diff).
- No new hex/Color literal (the file's WHITE sites are the three pre-existing idioms plus
  F2's branch; Chevron draws in its own child rect, A5.2(iii)).
- Retired surface: `SERVICE_ROWS`, `VAULT_BASE_CAPACITY`, `ROW_HEIGHT`, `VAULT_FORMAT`
  gone from the touched files; `CHIP_SIZE` alive on its pre-existing user (the hull
  chip, old `:441` → new `:375`). No dead export.
- Hint seam: all three hints resolve (`_service_panes` built from `SERVICES_STRIP`,
  `station.gd:114-118/1183`); an unknown hint skips the seam (`:1612`) and degrades to
  the CONTRACTS default (today's behaviour), with `_show_service` double-guarding
  (`:1218-1221`).
- Gate arithmetic reconciles: 1330 − 18 (s24 unparseable) + 11 (s42 new) = 1323 =
  1317 passed + 6 failed, exactly the worker's pre-re-cut state; the re-cuts since
  restore the 6 and add the 11 (my 1341/0 below).

## Verified fixes

(none — review only; F1/F2 await the fixer pass)

## Gate

`python3 staging/gate.py --times 1` on this tree → `[SUMMARY] passed=1341 failed=0`.
Worker's own line (1317/6, 3 SCRIPT ERRORs, all six rows over the retired deck)
reconciles per the check above. Suite alone:
`--suite=test_s42_overview_grid` → `[SUMMARY] passed=11 failed=0`, exit 0, with the
T-189 line re-printed under my own run (the F1 numbers). `staging/check_wiring.py`
reproduced: 1550 hard refs, every reference resolves.
