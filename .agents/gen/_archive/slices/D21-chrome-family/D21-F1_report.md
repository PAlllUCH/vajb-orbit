---
slice: D21
worker: D21-F1
model: xiaomi/mimo-v2.6-pro
status: informational
gate: "n/a — design-only (D21_BRIEF §7, no rows move)"
---

# D21-F1 report — the D21-R1 fix list (F1–F9)

## Result
All five HIGH/MED findings (F1–F5) and the four ride-along items (F6–F9) are
cured in `UI_SPEC.md` §15 and `UI_CHROME_ASSETS_SPEC.md` §13;
`staging/docs_index.py` re-ran on both (15 / 13 sections indexed). Every new
value is PROPOSED with a one-line reversal and no pin changed silently. The
prompt set re-verifies shell-safe (13 subject blocks, 0 banned chars) and every
run now names a `--aspect` value the generator's own sets accept.

## Findings cured (D21-R1's numbered list, in its order)
1. F1 (HIGH) — DONE — per-class run mapping (13 rows: `--aspect` / `--resolution`
   / route; six crop-to-master classes sourced at 4:3) + the uniform crop rule +
   the §13.5 aspect-verify step before cutting — `UI_CHROME_ASSETS_SPEC.md:412,438,593`; cost re-summed `:624`.
2. F2 (HIGH) — DONE — every C4 user re-measured; widest is 1765 (OVERVIEW
   service rows + identity block, AUCTION lists), the 64-tall name/identity
   plates set the v floor, so the C4 band extends to h 320–1765 / v 64–84;
   brief §2's "pane-width × 76" pin restored and the 560×76 draw deviation
   (1205 px) reported with reversal — `UI_SPEC.md:1481,1556` + §15.3 C4.
3. F3 (MED) — DONE — tile draw re-derived (3 cols / separation 16 over the 1765
   stack → 574–578×140; the review's ≈ 567 reads `TILE_MARGIN` as a grid inset);
   C1 re-declared at the drawn **567×140** (≈ 4:1), band ±10 % (h 510–624, v
   126–154) — `UI_SPEC.md:1483` + §15.3 C1 `:1602`.
4. F4 (MED) — DONE — census rows for `BUY` 64×16 and barrel `✕` 24×24 / 24×29 on
   the A5.4 flat-chip escape, and §15.4-8 reconciles A5.4's `Pressables` row
   (every sub-band pressable wears the flat §3.1 chip) — `UI_SPEC.md:1509-1510,1673`.
5. F5 (MED) — DONE — retired rows for `repairs_panel.tscn` / `fitting_panel.tscn`
   (live-unreferenced, test-mounted only) — `UI_SPEC.md:1539-1540`.
6. F6 — DONE — census evidence unique-counted: 47 / 337 / 148 = **632** unique
   vs raw 69 / 519 / 217 = 805, derivation saved at
   `staging/mockup/d21_census/unique_counts.txt` — `UI_SPEC.md:1449-1455`.
7. F7 — DONE, one item reported — cites fixed: `dialog.tscn:37` (`UI_SPEC.md:1515`),
   `cockpit_style.gd:79` `box_size` (`:1528`), `AMMO_CARD` `:158` (`:1506`);
   `DIAL_SIZE` measures at `hud.gd:200` in this tree (file carries no diff) so
   the cite stays and the constant is now named (`:1527`) — see Deviations.
8. F8 — DONE — §13.4 C8 now "replaces the slot faces in place under the existing
   names" — `UI_CHROME_ASSETS_SPEC.md:581`.
9. F9 — DONE — C13 row split: shell `ui_backdrop_hangar` 2048×1152 `keep` vs the
   four pane backdrops at 1765×753 as C13's only users — `UI_SPEC.md:1469-1470`.

## Re-summed cost (runs / credits / USD)
**Base 16 runs / 160 credits / $0.80; ceiling 22 / 220 / $1.10** — the mapping
adds no run, so the totals stand. One class needs a wider run and rides inside
them: **C6 orders 4K** (its 2720×1032 master exceeds a 2 K render's long edge),
priced PROPOSED at the flat 10-credit basis — reversal: 2K + the free local
resize to 2720×1032, or `recraft/crisp-upscale` at +5 credits (+$0.025). C3/C10
run 1K (3:1 refused above 1K client-side) at the same flat basis. If the
console prices 4K above 2K, only C6's line moves (160 + Δ).

## Deviations (each with its one-line reversal)
- Brief §3 pins "2 K runs"; C3/C10's `3:1` is refused above 1K by the client
  gate (`kie_generate.py:781-783`) — bucket (2), brief wording — reversal:
  route C3/C10 through the 4:3 2K crop and every run is 2K again.
- F7(4) not applied as written: `DIAL_SIZE` measures `hud.gd:200` (hud.gd
  carries no diff; the review's :202 unreproducible) — reversal: move the cite
  when a tree reproduces :202.
- The review's "settings/LAUNCH rows same pane-width idiom" measured otherwise
  (settings rebind ≈ 1872×32 plain `HBox`; LAUNCH manifest 560-wide `ItemList`
  items; SHIPYARD ≥ 340) — first two re-classed flat, bucket (1) — reversal:
  keep both C4 and extend the bands to their measured 560 / 1872.
- Barrel `✕` cite: review `armory_panel.gd:1657` vs measured `:1393-1395`
  (24×24 written; 24×29 is the `StationButton` plate minimum, §3.10 A3/L236) —
  reversal: cite :1657 when a tree reproduces it.
- `kie_generate.py:26-27` (NANO_ASPECTS) adds 4:1 / 8:1 beyond the review's
  3:1 / 21:9 cap — reported, mapping kept to 21:9 / 3:1 / 4:3 / 3:2 / 1:1 —
  reversal: the mapping's own named reversal swaps the family to nano values.

## Files touched
- `docs/design/UI_SPEC.md` (§15.1 evidence + 22 rows, §15.3 C1/C4, §15.4-5/-8)
- `docs/design/UI_CHROME_ASSETS_SPEC.md` (§13 run mapping, crop route, six
  prompt framings, §13.4, §13.5, §13.6)
- `staging/mockup/d21_census/unique_counts.txt` (new, F6)
- `.agents/gen/slices/D21-chrome-family/D21-F1_report.md` (this)
