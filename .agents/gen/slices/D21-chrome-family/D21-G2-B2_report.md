---
slice: D21-chrome-family
worker: D21-G2-B2
model: hyper/glm-5.3-flash @ max (owner image-lane assignment); renders on gpt-image-2-5-flare-text-to-image (T-140), all pixel ops scripted (g2b2_driver.py, pure Pillow)
status: actionable   # a third attempt needs a fresh owner call
gate: "n/a — asset lane; B2 outcome: 1 of 4 landed (C5, still aspect-disobedient), C1/C2/C9 FAIL re-confirmed — reported, never clipped, no third run"
---

# D21-G2-B2 report

## Result
The owner-approved 4-run re-batch (T-140, 4 × 10 cr = $0.20) ran complete with the class
aspect re-stated (numeric proportion added to the aspect clause; style block + negative list
verbatim — diff-proven delta-only). **C1/C2/C9 FAIL the §13.1 crop law again** (needed rects
2702×668 / 2424×378 / 2495×389 > frame 2368 wide — reported, never clipped, no third run per
the spend rule). **C5 landed** per the law (containment 100 %, one uniform scale 0.2762) but
the plate is again aspect-disobedient: ink 2.63:1 vs master 1.354 → t/b pads 93/93,
fill 51.2 % — still unusable at its fixed 260×192 use, the same verdict as the G2 cut it
replaced (swap pair recorded). The failure mode shifted, not fixed: the numeric proportion
moved the drawn aspects toward target (C1 2.97→3.24, C2 5.35→5.68, C9 5.78→5.74, unchanged
within noise) but the three bars now fill 90–94 % of frame width, so the master-aspect rect
cannot fit; C5 obeyed "four fifths" (79.5 % of frame width) and ignored the ratio.

## The 4-run table (T-140)
| class | prompt delta | output px | crop rect | containment | margins measured (master) vs declared |
|---|---|---|---|---|---|
| C1 | + "the plate's width about 4.05 times its height" | 2368×1776 (4:3 exact) | — FAIL: 2702×668 needed | n/a (ink 2161×667 = 3.24:1, 91 % frame w) | n/a (no cut) vs 32×4 |
| C2 | + "the plate's width about 6.43 times its height" | 2368×1776 | — FAIL: 2424×378 needed | n/a (ink 2142×377 = 5.68:1, 90 % frame w) | n/a vs 40/40/24/24 |
| C9 | + "the plate's width about 6.43 times its height" | 2368×1776 | — FAIL: 2495×389 needed | n/a (ink 2225×388 = 5.74:1, 94 % frame w) | n/a vs 32/32/16/16 |
| C5 | + "the plate's width about 1.35 times its height" | 2368×1776 (opaque → strip-key, bg [4,8,13], solidity 0.994) | [242,170,2125,1561] | 100 % | 48/48/175/175 vs 20×4 — FAIL |

Key routes: C1/C2/C9 substrate trim (alpha-0 64.7/79.6/79.1 %); C5 opaque (alpha-0 0.0 %) →
the local background-strip fallback keyed it (the route the dispatch anticipated). §13.5 run
aspect verify: all four frames 4:3 exact, PASS — the frames obeyed; the plates inside them
did not. Ink aspect vs target: C1 3.24/4.05, C2 5.68/6.43, C9 5.74/6.43, C5 2.63/1.354.

## Spend (exactly the T-140 sum, no variants)
- Console basis (§13.6 authority): **4 runs × 10 credits = 40 credits = $0.20.**
- Ledger over-report noted: usage-ledger.jsonl 106→110 entries (flare 94→98), est +120 cr /
  $0.60 hint — the known ~3× over-report; the console is the authority.
- The one --dry-run (C1, 4:3 2K transparent): `"estimate": {"credits": 30, "usd": 0.15,
  "price_source": "hint"}` — same hint basis G1's dry-run printed.
- Variant ceiling untouched: 6 runs / $0.30 stays pinned for state variants; zero variant
  purchases this run.

## Landing / backup
| class | stem | action | record |
|---|---|---|---|
| C5 | ui_rack_bay_card.png | replaced in place | old cut (520×384, md5 d4ade9d6cc2b0cbb74f2e4c0e101611b) → `asset-library/_prekey_backup/chrome_family_b2_2026-10-05/`; new landed md5 12e3c4deceba8602c4dab8f6884988ad; pair in that folder's manifest.json; the existing `.import` stanza kept (its res-path md5 is name-derived, unchanged) |
| C1/C2/C9 | ui_tile_slab / ui_action_bar / ui_drawer_entry | not landed | FAIL verdicts above; no stems, no `.import` stanzas written (the law writes them only on landing) |

## State-QC (the x0.60/x0.45 modulate sheet, rebuilt)
`asset-library/_review/qc_state_modulate_2026-10-05.png` now carries all six state-bearing
classes: the C1/C2/C9 rows read "no landed cut (state QC n/a)" — modulate cannot be judged
on cuts that do not exist; the C3/C4/C8 rows are unchanged from D21-G2 (legible and clearly
distinct at both factors, so modulate carries their states). C5 is not state-bearing.
Verdict: **state QC for C1/C2/C9 is n/a this run**; zero variant purchases (a variant of an
unlanded class is moot).

## Owner sheet (rebuilt)
`asset-library/_review/chrome_family_cuts_2026-10-05.png`: 16 tiles — the four B2 results
replace their old tiles (C5 shows the new cut; C1/C2/C9 labelled FAIL, not landed), the 15
D21-G2 cuts unchanged, every tile labelled class + stem + master px + measured margins.

## Mandate checks
1 — DONE — 4 runs submitted with delta-only prompts (diff-proven: deleting the inserted
    clause restores the G1 prompt byte-for-byte); prompts at `prompts/<ID>_b2.txt`.
2 — DONE — spend exactly 40 cr / $0.20 console basis, ledger delta recorded, no variants.
3 — DONE — cut law applied verbatim (g2b2_driver.py pipeline = g2_driver.py functions,
    copied because g2_driver runs on import); C1/C2/C9 FAILs reported, never clipped; C5
    landed at master px with one uniform scale (0.276155/0.27606), centre check applied,
    margins measured from its own rivet/bevel bands.
4 — DONE — backup swap + pair recorded; owner sheet + state sheet rebuilt; evidence in
    `g2b2_evidence.json`; this file is the report.

## Deviations
1. C5 landed while remaining unusable at its fixed 260×192 use (ink 2.63:1, fill 51.2 %) —
   the mandate's cut law lands any fitting rect, so the swap executed and the honest verdict
   is recorded rather than withholding the replacement. Reversal: restore the G2 cut from
   the b2 backup (md5 above), or §13.1's pad-to-master route / nano-banana-pro reroute, on a
   fresh owner call.
2. None otherwise — the three FAILs are reported verdicts, not deviations; no third run was
   attempted (the spend rule reserves that for a fresh owner call).

## Evidence
- `python3 g2b2_driver.py prep|dryrun|run|cut|sheets` (this folder); per-run logs
  `logs/b2_*.log`; `g2b2_batch_status.json` (task ids 819343bc…, f04d80f7…, e6d014ca…,
  a15e6507…); `g2b2_evidence.json` (per-class ink/rect/factors/margins/pads/key ladder).
- Raw renders: `asset-library/raw/chrome-family/20261005-224{4516,4538,4600,4628}/`, each
  with its `job.json` (prompt + task id recorded by the generator).
- Landed C5 re-measured independently of the driver: ink box [0,93,520,290], pads l0/t93/
  r−1/b93, fill 51.22 % — matches.

## Files touched
- `vajb-orbit/assets/ui/ui_rack_bay_card.png` — replaced (same name/stanza, art swapped).
- `asset-library/_prekey_backup/chrome_family_b2_2026-10-05/` — rejected G2 cut + manifest.
- `asset-library/raw/chrome-family/20261005-224*/` — 4 new renders + job.json (paid).
- `asset-library/_review/` — owner cut sheet + state-QC sheet rebuilt (+ `_view` jpgs).
- `.agents/gen/slices/D21-chrome-family/` — g2b2_driver.py, g2b2_{plan,batch_status,
  evidence}.json, prompts/<ID>_b2.txt, logs/b2_*.log, this report.

## Follow-ups (ticket at slice close)
| Item | Kind | Where |
|---|---|---|
| Third attempt for C1/C2/C9/C5 needs a fresh owner call: the plates now fill 90–94 % of frame width at near-target aspect, so a strengthened size clause (e.g. three quarters of the frame width) or §13.1's own reversals (pad-to-master crop; nano-banana-pro reroute, whose aspect set adds 4:1/8:1) are the candidate routes | owner decision | §13.1/§13.6 |
| C5 stays do-not-wire at its fixed 260×192 use until resolved (the G2 follow-up stands) | wiring guard | S36 |
| Close-out owes: editor reimport of ui_rack_bay_card.png, `build_catalog.py`, gate ×2, `verify --baseline g2b2_start` | orchestrator close-out | D21-G2_prompts.md |
