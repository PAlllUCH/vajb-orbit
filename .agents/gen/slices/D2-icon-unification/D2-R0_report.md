# D2-R0 — icon review round and three-batch compile (report for the developer)

**Slice:** D2 icon unification · **Round:** post-close review, 2026-09-22 ·
**Routes (owner-confirmed):** B2 = `opencode-go/mimo-v2.6-flash`, reasoning medium;
B3 = `deepseek/deepseek-flash` (DeepSeek-V4.1-Flash), reasoning high.

## Why the round ran

Owner playtest finding: fine details disappear in play; icons must be more defined
and more unique per icon; the next round had to be "something in between" round 1
and round 2, authored on the 96 grid, one style across the whole set.

## What ran

1. **Review round** — 5 agents audited all 135 shipped (B1) icons against four
   questions: features below the legibility floor, similar-lightness tone pairs,
   cross-icon confusability at 24 px, and the signature feature each icon needs.
   Result: `staging/d2/review_v1_findings.tsv` (135 rows: weak / contrast /
   confusable / fix). Four systemic failures in B1: sub-5-unit detail; mid-tone
   detail on light bodies; dark outer masses sinking into the panel; identity
   carried by tiny marks instead of the silhouette.
2. **B2** — `staging/d2/svg_v2/`, 15 batches × mimo-v2.6-flash (medium), hardened
   directives: 5-unit size floor, light outer mass with large dark cutouts only,
   unique outline per icon plus a 24-unit-plus signature feature. Two workers died
   mid-round (one hung, one silent) and were re-dispatched; the set completed
   135/135.
3. **B3** — `staging/d2/svg_v3/`, 15 batches × deepseek-flash (high), the
   in-between: one shared STYLE CONSTITUTION plus three inline exemplar SVGs in
   every prompt (anti-drift), 4-unit floor, 12-28-unit signature feature, subject
   fidelity retained. The constitution lives in
   `staging/d2/build_worker_prompts_v3.py`. Completed 135/135 in one window.
4. **Compile surface** — six 3-way sheets
   (`staging/d2/review_v2/D2_COMPARE_01..06.png`: B1 | B2 | B3 at 16/24/48 px,
   B3 adds the 96 px detail reference) and `staging/d2/svg_compile.csv`
   (135 ids, owner-filled).
5. **Merge** — `staging/d2/merge_compile.py --apply` copied each winner into
   `vajb-orbit/assets/icons/<fam>/<name>.svg`. The three batch folders are
   evidence and were not touched.

## Owner compile and the shipped result

**B3: 66 · B2: 55 · B1: 14 · pending: 0.** The per-icon authority for which batch
shipped is `staging/d2/svg_compile_result.csv` (id, name, keep, source, target,
status). Re-merge at any time with `python3 staging/d2/merge_compile.py --apply`.

## What a developer must know now

- Project structure is unchanged from the D2 close: **135 SVG + 164 raster masters
  + 540 tint stencils = 839 files**; only SVG path data changed in this round
  (121 of 135 icons switched batch).
- SVGs import through the texture importer with `svg/scale=2` (192 px master =
  the documented detail band), mipmaps on, lossless, 3D-detection off. No
  reference paths were touched this round, so no re-point was needed.
- Proof state after the merge: `validate_svg.py` **135/135 pass**;
  `asset_path_fallout` **379 refs, 0 unresolvable** (379 grew with the coder
  lane's S3 additions); universal gate **`[SUMMARY] passed=524 failed=0`**
  (the suite has grown from 457 as the coder lane landed S3 tests).
- The style constitution (chamfered hard geometry, light `#c9cdd2` mass, dark
  `#232629` cuts, no mid-tone-on-light, no dots/rivets) is the law for any icon
  added later — extend a new icon in that language, do not invent a second one.
- D3 item 2 still owns the **540** surviving tint stencils; nothing in this
  round touched the tint pipeline.
- Review sheets, findings, prompts and batch folders are the audit trail; do not
  delete them without an owner call.

## File map

| Purpose | Path |
|---|---|
| B1 audit (135 rows) | `staging/d2/review_v1_findings.tsv` |
| B2 prompts / output | `staging/d2/prompts_v2/` · `staging/d2/svg_v2/` |
| B3 prompts + style constitution | `staging/d2/prompts_v3/` · `staging/d2/build_worker_prompts_v3.py` · `staging/d2/svg_v3/` |
| 3-way compile sheets | `staging/d2/review_v2/D2_COMPARE_01..06.png` |
| Owner compile / merge authority | `staging/d2/svg_compile.csv` → `staging/d2/svg_compile_result.csv` |
| Merge + compare tooling | `staging/d2/merge_compile.py` · `staging/d2/build_compare.py` |
| Fallout proof | `.agents/gen/slices/D2-icon-unification/asset_path_fallout.md` |
