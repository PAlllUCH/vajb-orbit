---
slice: D21-chrome-family
worker: D21-G2
model: hyper/glm-5.3-flash @ max (owner image-lane assignment); all pixel ops scripted (g2_driver.py, pure Pillow)
status: actionable   # follow-ups need tickets at slice close
gate: "n/a — asset lane; cut-stage QC: containment 100% on all 15 landed cuts, centres ≤ 1 px, exact master pixels 15/15"
---

# D21-G2 report

## Result
15 landed cuts from the 16 renders: 5 plates (C3/C4/C5/C6/C7), the C8 master under the three
slot-face names, C10, C11, C12 and the four BG decks — every file exactly its §13.1 master
pixels, keyed/centred, `.import` stanzas in place. **C1, C2, C9 FAIL the §13.1 crop law** (their
master-aspect rects exceed the returned frame — the model ignored the class aspect) and land
nothing; **C5 lands but is unusable at its declared use**. Zero paid calls; variants stay
un-purchased (QC sheet says modulate carries the states).

## Class → landing (containment 100% and centre ≤ 1 px on every landed cut)

| ID | render (dir) | key route | cut → pixels | margins measured (master) vs declared | verdict |
|---|---|---|---|---|---|
| C1 | 201427 | substrate trim | — | — | **FAIL**: rect 3014×745 > frame 2368 w (ink 2209×744 = 2.97:1 vs master 4.05:1) |
| C2 | 201500 | strip flood, 81% keyed, solidity 0.995 | — | — | **FAIL**: rect 2495×389 > 2368 (ink 2076×388 = 5.35:1 vs 6.43:1) |
| C3 | 201604 | substrate trim | ui_inline_chip 192×64 | 24/24/23/23 vs 16/16/16/16 | landed; floats (fill 56%) |
| C4 | 201632 | substrate trim | ui_row_strip 1120×152 | 74/74/35/35 vs 24/24/16/16 | landed (fill 91%) |
| C5 | 201700 | substrate trim | ui_rack_bay_card 520×384 | 55/55/151/151 vs 20×4 (t/b method-limited; geometric pad 89/88) | landed but **unusable at 260×192** (fill 54%) |
| C6 | 201732 | substrate trim | ui_armory_console 2720×1032 (swap) | n/a (A6 whole-face) | landed; ~9 px transparent hairline t/b from the aspect pad |
| C7 | 202052 | substrate trim | ui_tooltip_frame 720×480 | 22/22/50/50 vs 24×4 — l/r PASS, t/b FAIL | landed; direct route (factors 0.2866/0.2885) |
| C8 | 202141 | strip-key refused (border = plate grey 53,56,58) | ui_slot_{weapon,cargo,inventory}_normal 112×112 ×3 (swap) | n/a (sprite, no nine-slice) | landed; fills frame (99.97%) |
| C9 | 202203 | substrate trim | — | — | **FAIL**: rect 2437×380 > 2368 (ink 2208×382 = 5.78:1 vs 6.43:1) |
| C10 | 202312 | substrate trim | ui_bar_caps 84×28 (swap) | n/a (sprite) | landed; caps fill 34%; the 28 px render gap resamples to a 1 px 67-alpha notch |
| C11 | 202401 | strip ladder 22→14 leak, **10 clean** (flood 2.4%, solidity 0.999) | ui_minimap_bezel 400×400 (swap) | 44×4 vs 32×4 | landed |
| C12 | 202444 | strip **refused after full ladder** (leaks at every tol; landed opaque = shipped convention) | ui_panel_frame 192×192 (swap) | 13/13/15/15 vs 64×4 — the model drew a thin band | landed |
| BG-1..4 | 202512/2055/2617/3106 | never keyed (RGB) | ui_backdrop_{armory,refinery,market,dock}_deck 2048×874 ×4 | n/a (cover-fit) | landed; exact chain: crop 3135×1338 → trim 2 px/side → 3131×1334 → one scale 0.655172 → 2051×874 → trim 2 px/side h → 2048×874 |

Uniform-band check (C7/C11/C12): **C7 PASS** (p95 2.1–6.6). **C11/C12 marginal**: p95 6.4–9.3 /
5.7–12.0, max ≤ 15.2 — grain-level, no structural ornament in any band (a rivet would read
max 100+). Strict "identical" reading fails both; the fallback they name is the shipped art,
recoverable from the backup store — flagged for R1, files left landed.

## State variants — NONE (spend $0.00, no KIE call this run)
`_review/qc_state_modulate_2026-10-05.png`: landed state-bearing cuts (C3/C4/C8; C2 has no cut)
simulated at modulate ×0.60 and ×0.45 — all stay legible and clearly distinct, so modulate
carries hover/pressed/disabled at cut stage. The pressed-inset read stays S36's wiring call.

## Swaps (shipped original → `asset-library/_prekey_backup/chrome_family_2026-10-05/`, md5 in manifest.json)
ui_armory_console 2720×1032; ui_slot_weapon_normal 48²; ui_slot_cargo_normal 40²;
ui_slot_inventory_normal 56²; ui_bar_caps 42×14; ui_minimap_bezel 200²; ui_panel_frame 96² —
each replaced in place at its §13.4 stem (existing `.import` kept, same uid). The 8 new stems
(ui_inline_chip, ui_row_strip, ui_rack_bay_card, ui_tooltip_frame, 4 backdrops) carry fresh
stanzas copied from the ui_status_panel template with new uids and the Godot md5-of-res-path
(verified against the shipped stanza). Slot `_hover/_pressed/_disabled` files untouched.

## Contact sheet
`asset-library/_review/chrome_family_cuts_2026-10-05.png` — 15 landed cuts + 3 FAIL tiles,
labelled class + stem + pixels + measured margins (checker = transparency).

## Acceptance list answers
1 — DONE — table above; dirs from `D21-G1_report.md`.
2 — DONE — 8 substrate trims; C2 keyed, C8 refused-measured, C11 ladder-clean, C12 refused-measured; BG never keyed (RGB, probe2).
3 — DONE — crop ran on C1/C2/C3/C4/C5/C6/C9/C10; C1/C2/C9 FAIL reported, never clipped; C7/C8/C11/C12 skipped; BG exact chain (resize_note in evidence).
4 — DONE — 15/15 landed at exact master pixels, single-scale (worst factor pair 0.5066/0.5050, C4).
5 — DONE — centre check (center_check.py semantics: measure → shift −offset → verify → rollback) on every sprite cut; BG exempt; all landed ≤ 1 px.
6 — DONE — containment 100% on every landed cut (evidence `containment.pct`); FAILs reported instead of clipped.
7 — DONE — margins table above (plateau + bright-band scans, max); no class passes ±2 at master except C7 l/r — the renders' band proportions differ from the §15.3 declared numbers, which were derived from the shipped art; S36 must wire with the measured values (N51's purpose).
8 — PARTIAL — C7 PASS; C11/C12 marginal (grain-level, no structural ornament) — flagged for R1 above, route + numbers reported, nothing hand-retouched.
9 — DONE — 15 files at the §13.4 stems; 7 swap pairs backed up + recorded; 8 new stanzas.
10 — DONE — zero variants; QC basis above; ceiling untouched.
11 — DONE — path above.
12 — DONE — this file.

## Deviations
1. C8's swap targets resolved to the shipped state-suffixed faces (`ui_slot_*_normal.png`) —
   the brief's bare stems exist only as the `_normal` files; reversal: land bare stems instead.
2. C12 landed opaque (key refused after the measured ladder) — the honest route outcome;
   reversal: force a lower-tolerance key (would eat the interior).
3. Uniform-band "identical" is unpinned numerically; I report p95/max and flag the marginal
   classes rather than silently passing or falling back — reversal: R1 applies the strict
   reading and restores both from the backup store.
4. Centre check replicated in-driver — `center_check.py` needs numpy/scipy, absent in this
   environment; semantics matched (offset formula, shift, verify, rollback).
5. C10's gap does not survive its 26× downscale (1 px 67-alpha notch) — reversal: slice the
   caps apart at use, or a paid re-run with a wider gap.

## Evidence
- `python3 .agents/gen/slices/D21-chrome-family/g2_probe.py` / `g2_probe2.py` — render + shipped
  conventions (g2_probe.json, g2_probe2.json).
- `python3 .agents/gen/slices/D21-chrome-family/g2_driver.py` — the whole pass; every number
  above is in `g2_evidence.json` (per-class rect/factors/margins/ladder/centre/containment).
- Import stanza md5 scheme verified: md5("res://assets/ui/ui_status_panel.png") =
  1d26fc0498e8b2602eb0aa549739f71a, matching the shipped stanza.
- Landed inventory re-opened with Pillow: 15/15 exact sizes (11 RGBA, 4 RGB backdrops).

## Files touched
- `vajb-orbit/assets/ui/` — 15 landed PNGs + 8 new `.import` stanzas (7 swap stems keep theirs).
- `asset-library/_prekey_backup/chrome_family_2026-10-05/` — 7 shipped originals + manifest.json.
- `asset-library/_review/` — the cut contact sheet + state-QC sheet (+_view jpgs).
- `.agents/gen/slices/D21-chrome-family/` — g2_driver.py, g2_probe*.py/json, g2_evidence.json,
  this report; `_opaque_preview*.png/jpg` (disposable).

## Follow-ups (ticket at slice close)
| Item | Kind | Where |
|---|---|---|
| C1/C2/C9 re-runs (aspect disobedience, 10 cr/$0.05 each) or reroute the family onto nano-banana-pro (§13.1 reversal) | paid candidate | §13.1/§13.6 |
| C5 lands unusable at 260×192 (fill 54%, t/b 151) — same re-run candidate; do not wire until resolved | paid candidate | §13.1 |
| C11/C12 keep-vs-fallback on the marginal band numbers | R1 decision | §13.5 |
| C10 middle gap: slice at use or accept the notch | S36 wiring | §15.3 |
| S36 dependencies: slots/bezel/frame/caps now 2× masters (derive at use); slot state files go unused once modulate carries states | wiring | §13.4/§13.2 |
| C6's ~9 px transparent t/b hairline: accept or pad opaque at wiring | S36 wiring | §13.1 |
