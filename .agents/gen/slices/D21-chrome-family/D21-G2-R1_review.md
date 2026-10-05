---
slice: D21-chrome-family
reviewer: D21-G2-R1
verdict: passed-with-followups
gate: "n/a — asset lane; R1 re-measurement: 15/15 landed at exact master px, render-side containment 100%, law-rect recon mean ≤ 1.01; no paid calls re-run"
---

# D21-G2-R1 review

Method: independent Pillow re-derivation from the raw renders and the landed cuts —
`D21-G2-R1_measure{,2,3,4,5}.py` → `D21-G2-R1_evidence{,2,3,4,5}.json` (this folder).
Ink boxes re-keyed with my own border-connected flood/threshold profiles; law rects
re-computed from §13.1's formula; margins re-scanned with a composite criterion
(mean-abs structure + sparse-bright + faint-band); band check recomputed with a
per-channel mean metric and negative-controlled against the shipped backups. No paid
call, nothing in the family edited, nothing left running.

## Acceptance list

1 — pass — 16/16 raw dirs present, render px re-measured = G1 table; class→render map in report matches.
2 — pass — 8 substrate trims verified (landed alpha shares); C2 key re-derived independently (my tol-26 profile box 2069×384 vs builder 2076×388); C8 refusal verified (border_med [43,42,43] = plate grey — nothing to strip); C12 same; C11 keyed; BG-1..4 RGB unkeyed.
3 — pass — law rects re-computed: C1 3018×746, C2 2469×385, C9 2469×385 — all exceed frame w 2368 → FAIL reported, never clipped (stems correctly absent); landed crops equal my law rects (recon mean: C3 0.19, C4 0.83 — builder rect [78,735,2289,1036] = mine exactly, C5 0.44, C6 0.00, C10 0.02); C7 direct verified (recon 0.0 after its centre shift (1,−4)); BG crop 1765:753 + trim verified (≤ 0.57).
4 — pass — 15/15 exact master pixels re-measured; single-scale skew inherent to integer rects: C4 0.31 %, C6 0.08 %, C7 0.67 % (direct frame 2512×1664 vs 3:2, inside §13.5's 2 %), C8/C11/C12 0 %.
5 — pass — centre offsets re-measured: all ≤ 1 px (C11 exactly 1.0).
6 — pass — render-side containment 100 % on every fitted law rect; recon match rules out clipping; ≥ 95 % satisfied on all 15.
7 — pass (measurement+report) — my margins agree with the builder's within method noise; per-class ±2-at-master match fails everywhere except C7-l → S36 must wire measured values (N51); table below; LOW ticket.
8 — pass (calibrated) — C7 PASS (p95 2.32–6.75 ≤ 8); C11/C12 8.07–13.72 with zero structural sections; negative control: the shipped fallbacks themselves read 5.25–9.10 under the same metric, so byte-"identical" is unsatisfiable; at use scale C11/C12 halve to shipped levels → keep landed, ticket the calibration.
9 — pass — 15 files at the §13.4 stems (names verified; bare slot stems don't exist — `_normal` trio is the shipped convention, deviation 1 legitimate); all 7 swap md5s = manifest `old_md5`; landed md5 ≠ backups; 8 new stanzas valid (`source_file` correct) with unique uids, zero collisions across `assets/ui`.
10 — pass — zero variants: no new state-suffixed files (slot states untouched, Sep 22), raw dirs still exactly G1's 16, `_keying/recraft/` has no Oct-5 entries; QC sheet exists.
11 — pass — `asset-library/_review/chrome_family_cuts_2026-10-05.png` present.
12 — pass — every claim re-verified; two corrected: C8 "fills frame/opaque" and C12 "landed opaque = shipped convention" are alpha-veiled (F3 below).

## Measured vs declared margins (master px; declared = §15.3 × 2)

| class | R1 (l/r/t/b) | builder | declared | ±2 verdict |
|---|---|---|---|---|
| C3 chip | 8/34/20/39 | 24/24/23/23 | 16×4 | fail (l/r−8, t/b+4..23) |
| C4 strip | 70/73/32/49 | 74/74/35/35 | 24/24/16/16 | fail (+46..+33) |
| C5 card | method-limited (recessed ref) | 55/55/151/151 | 20×4 | fail; geometry pads 89/88 are the real story (F2) |
| C7 tooltip | 22/43/50/64 | 22/22/50/50 | 24×4 | fail (t/b +26..+40; l/r −2..+19) |
| C11 bezel | 42/59/42/62 | 44×4 | 32×4 | fail (+10..+30) |
| C12 frame | 13/32/13/33 | 13/13/15/15 | 64×4 | fail (−51; band drew thin and l/r≠r/b) |

l/r-t/b asymmetry in my column is the renders' upper-left rim light; max(the two methods) is the safe wiring value.

## Uniform-band check (p95 of per-cross-section mean deviation; ≤ 8 = builder's line)

| cut | l | r | t | b | structural sections |
|---|---|---|---|---|---|
| C7 landed | 6.75 | 4.19 | 4.93 | 2.32 | 0 (isolated keyed-fringe speckle max_abs 255 in t/r) |
| C11 landed | 10.72 | 9.71 | 11.08 | 8.07 | 0 |
| C12 landed | 13.72 | 6.23 | 7.75 | 9.45 | 0 |
| control: shipped bezel | 7.18 | 5.25 | 6.61 | 5.67 | 0 |
| control: shipped frame | 9.10 | 6.25 | 8.92 | 6.97 | 0 |

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | MED | C1/C2/C9 — no landed art | Crop-law FAILs independently confirmed (rects 3018×746 / 2469×385 / 2469×385 > frame 2368; renders ignored the class aspect, §13.1:438-448) — 3 family classes uncovered and owner call 1 (drawer entries → C9) blocked | owner tick → paid re-runs |
| F2 | MED | ui_rack_bay_card.png | Landed unusable at its fixed 260×192 use: render ink aspect 2.52 vs master 1.354 → t/b pads 89/88 px, fill 53.5 % — same aspect disobedience class as F1 | owner tick → paid re-run |
| F3 | MED | ui_slot_{weapon,cargo,inventory}_normal, ui_minimap_bezel, ui_panel_frame, ui_bar_caps | Flare's partial-alpha veil shipped: slots 42 % of px at α200-249 + corners α34; bezel 96.3 % < 250; frame 99.98 % < 250; caps body mostly < 250 — vs shipped convention 94.7-99.4 % at α250+ (`evidence5.json` alpha_buckets); draws 84-98 % opaque in-engine | D21-G2-F1 (free scripted fix) |
| L1 | LOW | all nine-slice cuts | Measured margins ≠ §15.3 declared beyond ±2-at-master on every class but C7-l → S36 wires the measured numbers (N51's law; builder disclosed) | ticket → S36 |
| L2 | LOW | C7/C11/C12 bands | Strict "identical" unsatisfiable (shipped controls fail it too); calibrated keep recorded; C7 t/r keyed-fringe speckle (isolated max_abs 255 px) is a seam watch at wiring | ticket → S36 |
| L3 | LOW | ui_bar_caps.png middle third | 169 partial-α px, min α 0 — the 26× gap resample notch (builder deviation 5) | ticket → S36 wiring |
| L4 | LOW | ui_armory_console.png | 8 px transparent t/b hairline from the aspect pad (verified; builder disclosed) | ticket → S36 wiring |
| L5 | LOW | 8 new `.import` stanzas | "Godot md5-of-res-path" uid claim: md5 value verified (`1d26fc…`) but the uid text does not re-derive from it under base36/base62 tests; uids unique and well-formed, so wording fix only | ticket → report wording |

## Fix list for D21-G2-F1

1. Execute (free, scripted, within the file set): alpha-floor normalization on the 7 veiled
   files — α ≥ 200 → 255, soft fringe (< 200) preserved; C8's corners read hard-square after
   the floor (the C8 prompt pins hard corners). Re-run the alpha-bucket probe as the verify.
   Do not touch margins, bands, or pixel content.
2. Owner tick (paid): re-run C1, C2, C9, C5 — 4 × 10 cr = $0.20 with the class aspect
   re-stated in the prompt; §13.6's remaining ceiling is 6 runs / $0.30 but it is pinned for
   state variants, so the spend needs the owner's go; then re-cut per §13.1 and land at the
   §13.4 stems. Alternative without spend: those surfaces keep shipped art, or the family
   re-routes onto nano-banana-pro (§13.1's own reversal).
3. Nothing else: margins/bands are wiring inputs (S36), not cut defects; C10's notch and
   C6's hairline are wiring decisions already recorded.

## Verified fixes

(none — first review)

## Gate

n/a — asset lane. Negative control run and recorded: the shipped `ui_panel_frame` /
`ui_minimap_bezel` backups fail byte-identity under the same band metric (5.25–9.10 p95),
which is the basis for the L2 calibration ruling.
