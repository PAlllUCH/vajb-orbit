---
slice: D13
reviewer: D13-R1
verdict: clean
gate: "877/0 → 877/0 (unmoved; the brief's 866 predates the S17 suite's 11 rows)"
---

# D13-R1 review — armory rework design

Re-derivation pass over `D13-A0_report.md`, the mockup script and the ticked
yardstick (brief §5). In-session review by the design session (A0 ran
interactively per the owner's flow); an independent `crush run` R1 remains
available via `D13_prompts.md` if the owner wants a second pair of eyes.

## Re-derivation results

| Check | How re-derived | Result |
|---|---|---|
| Mockups byte-identical from the script | `armory_mockup_v2.py` run twice, `md5sum -c` on all 5 PNGs | pass, identical |
| Audit findings addressed-or-deferred with a reason | each of the 13 rows traced to a drawn element in the renders (names on cells, head chips, in-cell cues, wells band, unit wording, inspector lines) | pass |
| Data model (5×4 batteries, pack cards, salvo, §13/§16, CONTRACTS §17) | counted in the render source: 5 bays × 4 cell slots, 5 salvo ledges, 6 barrel rows, 6 pack cards with price + BUY; seams named unchanged in the report §Design-6 | pass, nothing dropped |
| Ink floor 13 px | every pane text call uses `F_13`/`F_13B` (13 px); no smaller font exists in the script | pass |
| `text_dim` ≥ 4.5:1 | CAP (172,178,186) on METAL (42,46,53) ≈5.5:1; CAP_VOID (150,157,165) on (24,27,33) ≈5.9:1 (computed sRGB) | pass |
| Colour never sole state carrier | `READY`/`▲ OVER CAP` chips carry label + chevron; fitted vs empty reads by name vs `DROP HERE`; the ember fit line is decorative | pass |
| No CSS idiom / engine-drawable | plates, recesses, chips, seven-seg drums, chevrons — all existing Godot Control treatments; B has no tabs/scrollers | pass |
| Canvas pin bucket 3 | P1–P6 all PROPOSED with a reversal line; the pinned values are never assumed moved | pass |
| Zero writes outside the file set | `git status`: `vajb-orbit/` and `docs/` untouched | pass |

## Findings
| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `staging/mockup/armory_mockup_v2.py` (all text calls) | The one-line name fit is measured against DejaVu (RAILGUN = 58 px in a ≥112 px cell, 1.9× headroom), not the theme face. If the theme face is wider than 2× DejaVu the variant wraps to its own line (allowed by the cell layout) — but the implementation must measure once with the real face. | implementation wave → backlog row L221 |
| F2 | LOW | resolution law P6 / T1 condition | Window-mode and resolution changes are inert in a `project_run` game (AGENTS.md godot-ai gap), so "all resolutions work" cannot be proven through godot-ai; the implementation wave must verify at ≥3 window sizes in a standalone run (e.g. 1280×720, 2560×1080, 1280×1024) against the three canvas proofs. | implementation wave → backlog row L222 |

No HIGH, no MED — **no fixer pass**. The two LOW rows ride with the next wave
per the LOW_BACKLOG law.

## Deviations noted (not findings)
- The re-render was verified against the working-tree script; the wave-boundary
  commit lands it, after which the same md5 check holds (the script is
  deterministic).
- The tick T1 condition changed the mockup's geometry law from pinned rects to
  proportional derivation after the first render; the delivered renders are all
  from the final (proportional) script — no stale variant exists on disk.
