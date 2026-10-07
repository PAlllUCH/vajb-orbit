---
slice: D21-chrome-family
reviewer: D21-G2-B2-R1
verdict: passed-with-followups
gate: "n/a — asset lane; B2-R1 re-measurement: all 8 checks confirmed from raw pixels; 1 MED (flare alpha veil reintroduced on the C5 re-land) → D21-G2-B2-F1; the family's aspect calls stay with the owner (B3 round already in flight)"
---

# D21-G2-B2-R1 review

Method: independent Pillow re-derivation — `D21-G2-B2-R1_measure.py` →
`D21-G2-B2-R1_evidence.json` (+ three rebuild PNGs), this folder. Own keying
(border-connected flood tol 22 from a 12 px band median; transparent returns
inked at my own α≥48 gate; the opaque C5 render bounded by my own
bright-structure box dist≥60/density≥9 + 3×3 opening against star specks), own
two-pass law-rect maths, own margin profiles, own sheet rebuilds diffed
pixel-wise against the shipped ones. No paid call; nothing in the landed family
edited; nothing left running. My C1/C2/C9 ink boxes match the builder's
byte-for-byte; my C5 box [244,508,2124,1219] sits within 1–4 px of the
builder's [243,507,2125,1223].

## Check table (dispatch items a–h + prompt spot-check)

1 — pass — (a) C5 landed = exactly 520×384 (`landed_c5.px`); C1/C2/C9 correctly NOT landed: `ui_tile_slab/ui_action_bar/ui_drawer_entry.png` + their `.import` stanzas all absent (`state.stem_absent_*` true); verdicts independently re-derived: my two-pass master-aspect rects 2706×669 / 2430×378 / 2501×390 all exceed frame 2368 → FAIL, never clipped.
2 — pass — (b) C5 aspect exactly 65:48 (`w*48 == h*65` true); all four frames 2368×1776 = 4:3 diff 0.0 % (§13.5 run verify). Plate aspect obedience still fails everywhere — ink 3.24/5.68/5.74/2.64 vs masters 4.05/6.43/6.43/1.354 — which is the report's own central verdict, confirmed.
3 — pass — (c) C5 containment recomputed with my own key: 100.0 % (0 of 1,338k ink px outside the builder rect) ≥ 95; C1/C2/C9 n/a (no crop ran; the FAIL branch fired instead).
4 — pass — (d) nothing clipped: in-crop ink bbox [2,338,1882,1049] == expected exactly, clipped_ink_px = 0; my law rect vs builder's [242,170,2125,1561] differs ≤ 3 px/axis (integer rounding of the same maths); factors 0.276155/0.27606, skew 0.034 % (inherent, ≤ R1's accepted class).
5 — FAIL-as-declared — (e) C5 margins nowhere near §15.3: mine l/r 43 (first gradient 33), t/b 153 (gradient 95) vs declared 20 at master — the report's own FAIL verdict stands; C1/C2/C9 n/a. Table below.
6 — pass — (f) backup `asset-library/_prekey_backup/chrome_family_b2_2026-10-05/ui_rack_bay_card.png` present, md5 d4ade9d6… == manifest `old_md5`, 520×384; landed md5 12e3c4de… == report; swap pair recorded (`manifest.json`).
7 — pass — (g) owner sheet 1370×1516: my independent rebuild is byte-identical (diff bbox null, max delta 0); a rebuild with the OLD cut differs only in the C5 tile art region [14,505,336,637] → the tile shows the new cut; C1/C2/C9 tiles draw "FAIL - not landed"; state sheet 932×760 also byte-identical (C1/C2/C9 rows "no landed cut (state QC n/a)").
8 — pass — (h) B2 spend: ledger delta = exactly the 4 flare rows 819343bc/f04d80f7/e6d014ca/a15e6507 (20:45:17–20:46:35Z), nothing between the last G1 row (18:31:06Z) and the first B2 row; no variants (state-suffixed files all 09-22; `_keying/recraft` empty; no new stems). Console basis 10 cr/2K is the owner-verified price law (AGENTS.md) → 4 × 10 = 40 cr = $0.20.
9 — pass — prompts: per class, line 1 == §13.1's shared style block verbatim; body minus the inserted clause == §13.1's class block verbatim == the G1 prompt body byte-for-byte; clause count 1; negative list untouched (it lives inside the body). Delta-only proven (`D21-G2-B2-R1_evidence.json` §prompts).

## Measured vs declared margins (master px; declared = §15.3 × 2 — §15.3 states margins at use scale, its own C12 line "32 at the 96 cut (64 at the 192 master)" fixes the mapping)

| class | B2-R1 mine (settled / first-gradient) | builder (plateau / band-end) | declared | verdict |
|---|---|---|---|---|
| C1 slab | n/a — no cut | n/a | 32×4 | n/a (FAIL crop, reported) |
| C2 action bar | n/a — no cut | n/a | 40/40/24/24 | n/a (FAIL crop, reported) |
| C9 drawer entry | n/a — no cut | n/a | 32/32/16/16 | n/a (FAIL crop, reported) |
| C5 rack card | 43/43/153/153 (grad 33/33/95/95) | 48/48/175/175 (34/34/139/139) | 20×4 | fail on every side (≥ +23), as the report says |

Method note: three independent margin methods (my settled/gradient, builder's
plateau/band-end) agree within 5–22 px and all sit 2–9× past the declaration;
the verdict is method-robust.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | vajb-orbit/assets/ui/ui_rack_bay_card.png | B2's re-land reintroduced the flare partial-alpha veil that D21-G2-F1 had normalized away: landed α200–249 = 25,999 px (13.0 %), α≥250 only 37.5 % — vs the F1-fixed G2 cut (the backup) at α200–249 = 1,095 px, α≥250 52.4 %; the raw render carries it (61 % of px at α200–249) and the strip-key passes `darker(raw_alpha, mask)` straight through (`g2b2_driver.py:262`) | D21-G2-B2-F1 (free scripted fix) |
| F2 | MED | family state | Re-confirmed, not new: C1/C2/C9 have no landed art and C5 stays unusable at its fixed 260×192 use (ink 2.64:1, fill 51.2 %, plate full-bleed l/r) — three family classes uncovered, owner call 1 blocked; resolution is the owner's B3 round (already owner-authorized and executed 2026-10-06, see L2), never my recommendation | owner tick (B3 outcome) |
| L1 | LOW | D21-G2-B2_report.md:15 | The reported needed rects are the one-pass form (2702×668 / 2424×378 / 2495×389); the true smallest two-pass rects are 2706×669 / 2430×378 / 2501×390 — verdict unchanged (all ≫ 2368) | report wording at slice close |
| L2 | LOW | usage-ledger.jsonl | The ledger now also carries the owner-authorized B3 round (4 flare rows 29e7e1fd/2c2149e6/fd7aaad7/26e01a6c, 2026-10-06 17:59–18:01Z; `g2c3_driver.py` header records the owner's "do yourself a third flare attempt" quote) — B2's own delta stays exactly 4 runs; B3's report must reconcile the wave total | D21-G2-B3 report |
| L3 | LOW | ui_rack_bay_card.png.import | The follow-ups row still lists the editor reimport as owed, but the stanza + `.godot/imported/*.ctex|*.md5` were regenerated 22:50 (post-swap) and the ctex name = md5("res://assets/ui/ui_rack_bay_card.png") = 0c4ddb… verified — reimport appears done; catalog/gate/verify remain owed | close-out checklist |
| L4 | LOW | D21-G2-B2_report.md:20 | Narrative G1 baselines differ slightly from `g2_evidence.json` boxes (C9 5.78 vs 5.826) — method noise; "unchanged within noise" holds | none (record) |

## Fix list for D21-G2-B2-F1

1. Re-apply F1's alpha-floor normalization to `ui_rack_bay_card.png` only
   (α ≥ 200 → 255, soft fringe < 200 preserved — the exact D21-G2-F1 recipe),
   then re-run the alpha-bucket probe as the verify. Do not touch pixels,
   margins, geometry, or the backup.
2. Nothing else: the aspect problem is the owner's (B3 round in flight); the
   three FAIL classes stay unlanded; margins/bands are S36 wiring inputs.

## Verified fixes

(none — first B2 review)

## Gate

n/a — asset lane. Negative control recorded: the owner-sheet rebuild with the
REJECTED G2 cut differs from the shipped sheet only inside the C5 tile art
region, proving the shipped tile discriminates new from old; both sheet
rebuilds are otherwise byte-identical to the shipped artifacts.
