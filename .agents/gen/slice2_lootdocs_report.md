# Slice 2 — loot-docs report: land the reviewer-measured 06 figures (2026-09-21)

Worker: the slice-2 loot *doc* worker. Job: land the doc-arithmetic replacement
numbers two reviewers measured independently — nothing else. No code, no asset, no
`18_engine_spec.md` (owner-locked) and no doc outside the named sections were touched.

Read first, in order: `AGENTS.md`; `.agents/gen/slice2_review_report.md` (**F9** — the
authority); `.agents/gen/slice2_w4_report.md` (**F1** — the same defect from the loot
worker); `docs/gameplay/06_loot_drops.md` §3 (tables + the 2026-09-20 amendment block)
and §5; `docs/gameplay/11_galactic_map.md` §3. For the citation target only, read
`18_engine_spec.md` §13 (read, never written) and `13_heat_bounty.md` §4 (the hop that
already carries the numbers).

## 1. Files changed (bytes before → after)

| File | Bytes before | Bytes after | Δ | md5 before | md5 after |
|---|---:|---:|---:|---|---|
| `docs/gameplay/06_loot_drops.md` | 6 486 | 6 769 | +283 | `13db7bdb277589da6e7ab01551119f32` | `3dae19a93f2183adc11c177ea4def9a4` |
| `docs/gameplay/11_galactic_map.md` | 7 281 | 7 303 | +22 | `407a2ad729f91dbe5f0e312af67bedfa` | `8edfeb938465fb595d22428c21f5014c` |

Both files are LF-only before and after (measured: `crlf=0`, 149 → 154 lines in 06;
`crlf=0`, 148 → 148 lines in 11). `git diff --stat` for the pass:
`06_loot_drops.md | 19 ++++++++++++-------` · `11_galactic_map.md | 2 +-`
(13 insertions, 8 deletions total). `docs/gameplay/18_engine_spec.md` does not appear in
`git status` — untouched, as required.

## 2. Job one — `06_loot_drops.md`: every figure changed, before → after

Five figures in the prose, in three tables. No chance, amount, band, item id, §5 rule,
§6 check or §7 growth line was touched.

### 2.1 Fighter (§3.1) — items, CR, empty rate

Before:

```text
Expected haul per fighter: ≈ 1.1 items, ≈ 20 CR baseline value.
Empty-kill probability ≈ 17 %.
```

After:

```text
Expected haul per fighter: ≈ 2.15 items, ≈ 28.375 CR baseline value.
Empty-kill probability ≈ 11.83 %.
```

### 2.2 The amendment block's drift record (kept) + the dated re-check line (added)

The block's own record was **kept verbatim** (`docs/gameplay/06_loot_drops.md:56-62`):

```text
**Amendment 2026-09-20 (18_engine_spec §4.6):** lines 5–6 add the slice-2
countermeasures — `cm_chaff` breaks locks with 3 ghost signatures for 3 s,
`cm_flare` lures seeker rockets within 450 u. Each enters the fighter table
at 0.15 chance and may enter the swarmers' table (slice-2 W3) at the same
weight; the freighter/corvette/dreadnought tables are untouched. Expected
haul figures above predate the amendment and are re-checked in the wave
report, not by hand here.
```

Added directly after it, as its own paragraph (`docs/gameplay/06_loot_drops.md:64-67`):

```text
**Re-check 2026-09-21:** the expected-haul sentences in §3.1–§3.4 now carry
the re-checked figures that amendment deferred to the wave report,
recomputed from §3's own tables (`slice2_review_report.md` F9,
`slice2_w4_report.md` F1).
```

The deferral sentence is therefore still true in its own terms — it says the figures
"are re-checked in the wave report", and the new line names the two report findings that
did it. The drift record survives; the arithmetic it deferred to is now in the doc.

### 2.3 Freighter (§3.2) — items only

Before: `Expected haul per freighter: ≈ 1.6 items + occasional cache, ≈ 40 CR.`
After:  `Expected haul per freighter: ≈ 2.30 items + occasional cache, ≈ 40 CR.`

### 2.4 Corvette (§3.3) — items only

Before: `Expected haul per corvette: ≈ 1.3 items, ≈ 60 CR + caches. Corvettes are`
After:  `Expected haul per corvette: ≈ 1.50 items, ≈ 60 CR + caches. Corvettes are`

### 2.5 Maw dreadnought (§3.4) — items added, CR clause replaced

Before:

```text
Guaranteed minimum: line 1 + line 6 always pay. A Maw kill is a
progression event: **≈ 500–900 CR minimum, up to ≈ 1 300+ with all lines**,
plus the only Voidshard source in v1.
```

After:

```text
Expected haul per Maw: ≈ 6.375 items. Guaranteed minimum: line 1 + line 6
always pay. A Maw kill is a progression event: **a guaranteed floor of
1025 CR, a mean of 1584.75 CR**, plus the only Voidshard source in v1.
```

The Maw had no units sentence at all; the new one mirrors the §3.1/§3.2/§3.3 shape. The
stale CR range clause was replaced in full, because the `up to ≈ 1 300+` half is the same
defective figure as the `≈ 500–900` half (measured ceiling 2185 CR) and the two cannot
stand together with the floor and the mean. See §5 deviation 1.

## 3. Job two — `11_galactic_map.md` §3: the spec citation

One cell of the §3 population table; nothing else in the file was touched.

Before: `| Pirates | per 13 §4 | the risk tax |`
After:  `| Pirates | per 13 §4 / 18_engine_spec §13 | the risk tax |`

The pointer chain now ends in numbers: 11 §3 → 13 §4 → `18_engine_spec` §13's
"NPC counts per sector" block (`18_engine_spec.md:537-539`: S1 0–1 · S2 1–2 · S3 2–3 ·
S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8), without a second transcription that could drift. This
closes the optional third hop F11 named. The slash form matches §3's own row above it
(`per 02 §5/§8`, `11_galactic_map.md:98`).

## 4. Independent arithmetic check (before transcription, not after)

I refuse to transcribe a number I have not reproduced. Every figure landed here was
recomputed from 06's amended tables and 03 §3.1's CR values, without reading the
reviewers' derivations first:

- **Fighter units:** 0.55×1.5 + 0.30×1 + 0.35×1.5 + 0.20×1 + 0.15×1 + 0.15×1 = **2.15** ✓
- **Fighter empty rate:** 0.45×0.70×0.65×0.80×0.85×0.85 = 0.1183455 → **11.83 %** ✓
- **Fighter CR:** 0.55×1.5×12 + 0.30×1×22 + 0.35×1.5×15 + 0.20×1×20 + 0 (the two
  countermeasures are uncatalogued, so they price 0) = 9.90 + 6.60 + 7.875 + 4.00 =
  **28.375 CR** ✓
- **Freighter units:** 0.60×2.5 + 0.35×1 + 0.30×1.5 = **2.30** ✓
- **Corvette units:** 0.50×1.5 + 0.30×1 + 0.25×1 + 0.20×1 = **1.50** ✓
- **Maw units:** 1.00×4 + 0.75×1.5 + 0.60×1 + 0.40×1 + 0.25×1 = **6.375** ✓
- **Maw floor:** (1.00 × min 3 × 75) + (1.00 × 800 cache min) = 225 + 800 = **1025 CR** ✓
- **Maw mean:** 300 + 123.75 + 78 + 48 + 35 of components + 1000 of cache mean =
  **1584.75 CR** ✓

All eight reproduce to the digit. The 03 §3.1 figures used: `comp_scrap_1` 12 ·
`comp_weap_1` 22 · `comp_pow_1` 15 · `comp_elec_1` 20 · `comp_scrap_3` 75 ·
`comp_mech_3` 110 · `comp_weap_3` 130 · `comp_elec_3` 120 · `comp_ore_3` 140.

## 5. Deviations and judgement calls (all disclosed, none silent)

1. **The Maw's `up to ≈ 1 300+` clause was removed, not retyped.** The brief named a
   replacement for the *minimum* only, and says "change no other number or rule". The
   ceiling is part of the same figure sentence: keeping `up to ≈ 1 300+` beside a floor of
   1025 and a *mean* of 1584.75 would leave the doc self-contradictory (mean above its own
   ceiling), which is arithmetically worse than the defect being fixed. The measured
   ceiling (2185 CR) is a number the brief did **not** authorise, so it was **not**
   written; the clause was replaced by the floor and the mean as instructed. Nothing else
   in the sentence changed.
2. **`items`, not `units`, in the prose.** The replacement numbers are the reviewers' but
   06's own prose word is "items" (all three pre-existing expected-haul sentences use it).
   Transcribed numbers, unchanged vocabulary: `≈ 2.15 items`, `≈ 2.30 items`,
   `≈ 1.50 items`, `≈ 6.375 items`.
3. **A new units sentence for the Maw.** 06 had no Maw units figure to edit, so the
   6.375 had to land as a new sentence. It mirrors the §3.1/§3.2/§3.3 sentence shape
   rather than inventing a new construction or a new label.
4. **Thousands separators follow the reviewers' literal form.** §3.4's cache row writes
   `1 200`, but the brief writes `1025` and `1584.75`; the landed text is the brief's form
   (`1025 CR`, `1584.75 CR`) so the figures are greppable exactly as specified.
5. **§6 check 1 was not re-worded.** The defect was that the prose disagreed with the
   tables; with the prose corrected the check passes as written, and the brief's
   "change no other number or rule" puts §6 out of scope. No §6 text changed.
6. **`18_engine_spec.md` was read (§13) and never written** — it is owner-locked and stays
   byte-identical (`git status` lists it nowhere).
7. **Editor/LSP/MCP were not started for this pass** — doc-only work needs no engine, and
   no test gate applies to two `.md` files. No Godot process was launched, no asset was
   read or moved, no code file was opened for writing.

## 6. Verification

- `git diff` for the pass touches exactly two files, 13 insertions / 8 deletions, and the
  diff is itemised in §2–§3 above, before→after, in full.
- `git status --porcelain` shows `docs/gameplay/06_loot_drops.md` and
  `docs/gameplay/11_galactic_map.md` as the only two files this pass modified; every other
  entry is pre-existing wave work that was already dirty when the pass began.
- Byte counts, line counts and md5 sums in §1 are measured (`py -3.14`, `open(...,'rb')`),
  before and after, on both files.
