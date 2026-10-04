---
slice: D19
worker: D19-F1
model: "xiaomi/mimo-v2.6-pro"
status: actionable
gate: "not re-run — docs + `staging/mockup/` only (per dispatch); orchestrator re-runs at close-out"
---

# D19-F1 report

## Result
F1–F11 cured at their named cites; F12–F17 (T-107–T-112) untouched. Both designer
rulings landed: N28's trigger amendment (F5) and §5.7's pinned action set restored
in §19.4 plus its §19.6 ledger row (F6). One directed cite is measured wrong and is
reported rather than written (F4's armory half). No code files, no gate run.

## Dispositions (F1–F11, finding by finding)

| F | Disposition | Landing cite | Evidence (one line) |
|---|---|---|---|
| F1 | cured | `staging/mockup/d19_overview_wireframe.md:22` | the SHIPYARD tile caption now reads `HULLS, MODULES AND REPAIRS` (P23 verbatim); the tile's middle column widened 18→28 chars (gaps 2→1, the trailing slack absorbed) so the 26-char caption fits and every ASCII line keeps its old width |
| F2 | cured | `staging/mockup/d19_overview_wireframe.md:26` | the meta line is `LANCER — LIGHT FIGHTER CLASS · 1000 HULL · 8 SLOTS`, the `META_FORMAT` `%s CLASS · %d HULL · %d SLOTS` (`shipyard_panel.gd:123`) shape exactly; 1000/8 are the mock's own `HULL 200 / 1000` and `8 CELLS` figures and `2 ENGINES` (not in the format) is gone |
| F3 | cured | `UI_SPEC.md` §12.5 row 16 (`:1309`) | the selection/hover grid-rebuild class added with `shipyard_panel.gd:508-527` via `_on_row_focused:1029` → `_preview_row:1105` → `_refresh_preview:966,975`, `armory_panel.gd:2906-2935` `_sync_grid` (via `_refresh_footer:3122-3127` on row 4's path), fitting twin `fitting_panel.gd:484`; verdict = violation (N31's bar), cure = RETROFIT — the rebuild rides the selection command (§3.1's own `rebuilt per selection` row) |
| F4 | cured — one half reported | `UI_SPEC.md` §12.5 row 4 (`:1297`) | the fitting cites are now `fitting_panel.gd:1192,1210` (the hover/focus `_refresh_footer()` calls, opened at both lines); the directed armory `:3767` measures `_candidate = _row_entry(…)` while the calls are `:3755`/`:3768` (`:3769` is `_inspect_browser`) — row 4 keeps `:3755,3768`, the directed value reported below |
| F5 | cured (ruling) | `UI_SPEC.md` §11.1 N28 row (`:1094`) + amendment note (`:1098-1106`) | the trigger reads the precise form `the row's own INSPECT inline chip; a grid cell is inspected through the cluster's INSPECT chip (N37)`; the dated note records the reason (the old cell half is physically impossible on a 48 px plate), the reversal and the owner-tick-pending mark |
| F6 | cured (ruling) | `STATION_HUB.md` §19.4 REFINERY row (`:1776`) + §19.6 row 16 (`:1825`) | the cluster cell is `REFINE N` + `REFINERY ALL` + `CANCEL` (§5.7 `:760-766` verbatim); the ledger row records the draft `CANCEL` + `REFINE` as superseded with §5.7 STANDING as the pin |
| F7 | cured | `STATION_HUB.md` §19.3 (`:1756` content box, `:1757` stack, `:1758` header, `:1762` cluster) + §19.5 **P31** (`:1801`) + `d19_overview_wireframe.md:44` | content box ends 1842 (derivation re-fixed to §3.4's chain `24+1+32+20 … 1895−1−32−20` = the host's `453..1842` at ±54); cluster `1482..1842` with the secondary at `1106..1466` (16 px gutter, both exactly P1's 360 plate); shared x 129 (77+40+12) in §19.3 and the wireframe, PROPOSED **P31** (reversal: 128) |
| F8 | cured | `STATION_HUB.md` §19.6 rows 9/10/12/13 (`:1818`, `:1819`, `:1821`, `:1822`) | `:719`→`:720`, `:922-923`→`:923-924`, `:1147/:1150/:1153`→`:1148/:1151/:1154`, `:1123`→`:1124`, `:1221-1222`→`:1222-1223`; every new line opened (the `:1151` target is the `ui_accept` rail-entry row P19 supersedes) |
| F9 | cured | `STATION_HUB.md` §19.1 block 3 (`:1705`) | meta cite is `shipyard_panel.gd:123` `META_FORMAT` and the pairs `:94-100` `STAT_ROWS` (the old `:82-84`/`:74-80` both sat inside `SLOT_GLYPHS`) |
| F10 | cured | `staging/mockup/d19_popup_wireframe.md:57` | element 5 cites `shipyard_panel.gd:764` (`_affix_lines`); `:741-751` is `_stat_block_of` |
| F11 | cured | `UI_SPEC.md` §12.5 row 7 (`:1300`) | the four `tooltip_text` writes `armory_panel.gd:1968,2029,3139,3645` added to the second-surface row (Godot's default tooltip path — N27's own reversal; `:3645` noted as already T-104) |

## The two rulings — landing cites
- **F5** lands at `UI_SPEC.md` §11.1: the N28 row (`:1094`) carries the precise
  form verbatim and the dated amendment note sits at `:1098-1106` with its
  reversal (the `row/cell` wording, viable only with a cell chip that fits the
  48 px plate) and the **owner tick pending** mark.
- **F6** lands at `STATION_HUB.md` §19.4's REFINERY row (`:1776`) and §19.6's
  ledger row 16 (`:1825`). Stating the three-plate seat needed **no** new value —
  that arithmetic is T-112's ticketed gap (F17) and the other three-plate clusters
  ride it unchanged — so the ruling's PROPOSED-at-next-free-P path was not taken
  and **P31** went to F7's shared x instead.

## Judgments inside the fixes (each reversible as written)
- **F4's armory half (reported, not changed — brief §9):** the directed `:3767`
  is one line above the hover-path call — `armory_panel.gd:3767` is
  `_candidate = _row_entry(profile, StringName(payload[&"base"])) if hovered else &""`,
  `:3768` is `_refresh_footer()`, `:3769` is `_inspect_browser(payload, hovered)`
  (opened with `nl -ba`; the file matches HEAD). Row 4's existing `:3755,3768` are
  the two `_refresh_footer()` calls, so the fixer wrote nothing there. Flip to
  `:3767` on owner/orchestrator say-so.
- **F7's stack width (1766 → 1765):** the named cluster `1482..1842` is exactly
  §8 P1's pinned 360 px plate at end − start, which makes the 77..1842 stack 1765;
  1766 would price the primary at 361. Reversal: inclusive counting (primary
  `1483..1842`, stack 1766).
- **F1's widened tile column:** the mock's truncation idiom (`BUY, FIT AND..`)
  could only carry a prefix of P23's caption; "match exactly" was read literally,
  so the middle column grew and the full caption ships.

## Files touched
- `docs/design/UI_SPEC.md` — §11.1 N28 + amendment note; §12.5 rows 4, 7, 16;
  section index regenerated (`staging/docs_index.py`).
- `docs/design/STATION_HUB.md` — §19.1 block 3, §19.3 four rows, §19.4 REFINERY,
  §19.5 **P31**, §19.6 rows 9/10/12/13 + new row 16; index regenerated.
- `staging/mockup/d19_overview_wireframe.md` — tile caption (+column), meta line,
  element-law row 1 shared x.
- `staging/mockup/d19_popup_wireframe.md` — element 5 cite.
- `.agents/gen/slices/D19-station-shell-v2/D19-F1_report.md` — this report.
