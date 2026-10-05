---
slice: D21-chrome-family
worker: D21-G1
model: hyper/glm-5.3-flash (driver); renders on gpt-image-2-5-flare-text-to-image (owner ruling 2026-10-05)
status: informational
gate: "n/a — asset lane, no code touched; QC is the 13.5 aspect verify: 16/16 PASS"
---

# D21-G1 report

## Result
The §13 chrome-family batch ran complete: **16/16 runs** (C1–C12 + BG-1..BG-4) on
`gpt-image-2-5-flare-text-to-image` per the owner ruling, every result downloaded with its
`job.json`, every render measured and aspect-verified per §13.5 **before any cutting** —
**16/16 PASS** (≤ 2 %). Contact sheet built. No FAIL, so no re-run was owed; the
accepted-submission rule was never triggered.

## Dry-run estimate (the one --dry-run, C1 4:3 2K transparent, flare)
`"estimate": {"credits": 30, "usd": 0.15, "price_source": "hint"}` — the ledger hint basis.
§13.6's console authority prices every run at 10 credits = $0.05; the hint over-reports ~3×,
as the dispatch states.

## Per-run table
Shared output name in every run dir: `grimdark-painted-sci-fi-semi-realistic-1.png` under
`asset-library/raw/chrome-family/<dir>/` (each dir carries its `job.json`; prompts verbatim
per-run under `prompts/<ID>.txt` in the slice folder).

| ID | dir (20261005-*) | pixels | mode / alpha-0 % | aspect check |
|---|---|---|---|---|
| C1 | 201427 | 2368×1776 | RGBA / 59.9 | PASS (4:3, 0.0 %) |
| C2 | 201500 | 2368×1776 | RGBA / 0.0 — opaque | PASS (4:3, 0.0 %) |
| C3 | 201604 | 1916×821 | RGBA / 63.2 | PASS (21:9, 0.02 %) |
| C4 | 201632 | 2368×1776 | RGBA / 84.8 | PASS (4:3, 0.0 %) |
| C5 | 201700 | 2368×1776 | RGBA / 57.2 | PASS (4:3, 0.0 %) |
| C6 | 201732 | 3312×2480 | RGBA / 54.1 | PASS (4:3, 0.16 %) |
| C7 | 202052 | 2512×1664 | RGBA / 13.8 | PASS (3:2, 0.64 %) |
| C8 | 202141 | 2048×2048 | RGBA / 0.0 — opaque | PASS (1:1, 0.0 %) |
| C9 | 202203 | 2368×1776 | RGBA / 79.3 | PASS (4:3, 0.0 %) |
| C10 | 202312 | 1916×821 | RGBA / 74.3 | PASS (21:9, 0.02 %) |
| C11 | 202401 | 2048×2048 | RGBA / 0.0 — opaque | PASS (1:1, 0.0 %) |
| C12 | 202444 | 2048×2048 | RGBA / 0.0 — opaque | PASS (1:1, 0.0 %) |
| BG-1 | 202512 | 3136×1344 | RGB opaque — as required | PASS (21:9, 0.0 %) |
| BG-2 | 202550 | 3136×1344 | RGB opaque — as required | PASS (21:9, 0.0 %) |
| BG-3 | 202617 | 3136×1344 | RGB opaque — as required | PASS (21:9, 0.0 %) |
| BG-4 | 203106 | 3136×1344 | RGB opaque — as required | PASS (21:9, 0.0 %) |

Substrate law (§13 note): 8 of 12 plates verified RGBA with > 10 % alpha-0 (C1 59.9, C3 63.2,
C4 84.8, C5 57.2, C6 54.1, C7 13.8, C9 79.3, C10 74.3). **C2, C8, C11, C12 returned opaque
despite `--transparent`** (the models.md known failure mode) — §13's own route already covers
them: the local background-strip fallback keys them at the cut stage, free, no re-run owed.
Backdrops verify opaque with no alpha, exactly as §13.5 requires. C6's 4K tier measures
3312×2480 (flare's 4K long edge, not 4096) — the 340:129 crop rect still fits with margin.

## Spent total
- **Console basis (§13.6 authority): 16 runs × 10 credits = 160 credits = $0.80.**
- Ledger recorded: +16 flare generations, +480 credits est = $2.40 ledger-USD
  (usage-ledger.jsonl 90→106 gens, 2625→3105 cr; flare 78→94) — the known ~3× over-report.
- Ceiling untouched: 6 QC-gated state-variant runs (C1/C2/C3/C4/C8/C9, ≤ 60 cr / $0.30)
  remain inside 22 runs / 220 cr / $1.10.

## Contact sheet
`asset-library/_review/chrome_family_2026-10-05.png` — 4×4 grid, all 16 results labelled
ID + pixels + PASS. One visual check done on a downscaled copy: every render is on-class
(no text, no logos, BG-1..4 read as the four distinct deck walls).

## Acceptance list answers
1. Batch per §13.1 mapping + owner model ruling — DONE — 16/16 runs, table above.
2. One --dry-run estimate pasted — DONE — estimate line above.
3. Every result downloaded, job.json kept — DONE — 16/16 `find … job.json | wc -l` = 16.
4. 13.5 aspect verify before any cutting — DONE — 16/16 PASS, `g1_qc.json`.
5. Substrate verify per §13 — DONE — 8 transparent-sufficient, 4 opaque → free local key
   fallback, 4 backdrops opaque as required.
6. One contact sheet at the pinned path — DONE — path above.
7. Report ≤ 120 lines with spend + deviations — DONE — this file.

## Deviations from the spec / dispatch
1. **C3/C10 canvas is 21:9, not the mapped 3:1.** The owner's model ruling moved every run
   onto flare, whose aspect set has no 3:1 (evidence: dry-run exit 64, "Aspect '3:1' not
   supported by gpt-image-2-5-flare-text-to-image"). Ran `--aspect 21:9 --resolution 1K`
   (the spec's pinned 1K kept; 21:9 is flare's nearest landscape) and the plate now takes
   the spec's own crop-to-master route (§13.1's uniform rule) at the cut stage. Reversal:
   the mapping's own — rerun the family on nano-banana-pro, whose set carries 3:1/4:1.
2. **--style-file mechanism replaced by an inline combined --prompt.** The script demands
   `--prompt` for generation models and appends `--style-file` text *after* it
   (kie_generate.py:759-765), while §13 pins the style block as the *preamble*. Each run
    therefore passes style block + "\n" + class block, in §13's order, read from
   `prompts/<ID>.txt`. Reversal: switch to --prompt=class-block + --style-file=style-block
   and accept the appended order.

## Evidence
- `python3 .agents/gen/slices/D21-chrome-family/g1_driver.py dryrun` — the estimate JSON above
  plus the 3:1 refusal (exit 64).
- `python3 … g1_driver.py run` — 16 sequential runs, per-run logs `logs/<ID>.log`, rc 0 ×16,
  22–288 s each; per-run 480 s cap, 100-min global deadline, nothing left in background.
- `python3 … g1_driver.py qc` — the measured table above (Pillow `Image.open().size`).
- `python3 "$KIE_GENERATE" --usage` before/after — snapshots kept as
  `g1_usage_before.json` / `g1_usage_after.json`.

## Files touched
- `asset-library/raw/chrome-family/20261005-*/` — 16 run dirs, one PNG + one job.json each.
- `asset-library/_review/chrome_family_2026-10-05.png` — the contact sheet.
- `.agents/gen/slices/D21-chrome-family/` — `g1_driver.py`, `prompts/` (16 verbatim prompt
  files), `g1_plan.json`, `g1_batch_status.json`, `g1_qc.json`, `g1_usage_before.json`,
  `g1_usage_after.json`, `logs/` (16), `_sheet_preview.png` (the one visual check, disposable).
- Skill ledger (outside the workspace): +16 flare rows.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Key C2/C8/C11/C12 with the local background-strip fallback at the cut stage (free); if keying QC fails, a paid re-run is the candidate (10 cr / $0.05 each) | cut-stage step | D21-G2 / cut driver |
| State variants (≤ 1 per state-bearing class C1/C2/C3/C4/C8/C9) stay purchasable inside the $1.10 ceiling — order only where modulate fails QC (the pressed inset read is the expected case) | QC-gated purchase | §13.2 / cut-stage QC |
| C6 master 2720×1032 vs the 3312×2480 return — crop+resize covers it; if the cut stage disputes the fidelity, the §13.6 reversal is recraft/crisp-upscale at +5 cr | contingency | cut stage |
