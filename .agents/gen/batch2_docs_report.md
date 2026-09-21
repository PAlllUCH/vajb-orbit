# Batch-2 doc close-out report (2026-09-21)

Worker: batch-2 doc close-out. Briefs read: `.agents/gen/batch2_task.md`,
`.agents/gen/batch2_report.md`, `docs/design/CLEANUP_PLAN.md` (the absorption rule),
`AGENTS.md`, `docs/design/IMPLEMENTATION_PLAN.md` §9.8, `.agents/gen/ui_chrome_regression.md`.
No editor was opened. No code, asset, theme or scene file was read for write or written:
`vajb-orbit/**`, `docs/design/vajb_theme.tres`-side art and every asset path were untouched
(`git status` confirms it). Two files changed, both `docs/`.

---

## 1. Bytes before and after

| File | Bytes before | Bytes after | Delta | Git diff |
|---|---|---|---|---|
| `docs/gameplay/19_testing_notes.md` | 4 335 | 5 504 | **+1 169** | 19 insertions, 1 deletion (the retitled B2-3 heading) |
| `docs/design/IMPLEMENTATION_PLAN.md` | 49 163 | 50 280 | **+1 117** | 1 insertion |

Both "before" sizes are the **working-tree** sizes at dispatch time, not `HEAD`:
`IMPLEMENTATION_PLAN.md` already carried uncommitted slice-2 doc hunks (the "Slice 2 — Fight"
paragraph, the companion-doc-amendment bullet, the 2026-09-21 refuel ruling) written by another
lane before this dispatch. Those hunks are **not mine** and were left byte-identical; my change
is the single item-6 line below.

---

## 2. File one — `docs/gameplay/19_testing_notes.md`

### 2.1 B2-3 ticked (job one, part one)

Heading retitled:

```diff
-### B2-3 — Minimap zoom is inverted
+### B2-3 — Minimap zoom is inverted — FIXED (batch 2, measured)
```

Verdict line appended at the end of the B2-3 section:

```text
**Fixed 2026-09-21 (batch 2, measured).** `ui/hud/hud.gd`: the zoom deltas are renamed to
the direction they mean and the two `pressed` bindings are swapped, so `%ZoomPlus` emits
`-1` (world radius 3200 → 2400 = zoom in) and `%ZoomMinus` `+1` (3200 → 4000 = zoom out);
clamp 800–6400, step 800 and the wheel-zoom camera are untouched. Evidence:
`.agents/gen/batch2_report.md` §3 B2-3.
```

### 2.2 B2-1 and B2-2 annotated, not ticked (job one, part two)

Appended at the end of the B2-1 section:

```text
**Batch-2 verdict (2026-09-21): not fixed, not approved.** Not a button-code or colour
defect — the hover plate art ships as a whole sheet cell, so the theme stretches a mostly
transparent canvas and the plate renders as a thin bar; the look direction pick (flicker /
directional glow / tick-carried ember) is still the owner's. Evidence:
`.agents/gen/batch2_report.md` §3 B2-1 and `.agents/gen/ui_chrome_regression.md`.
```

Appended at the end of the B2-2 section:

```text
**Batch-2 verdict (2026-09-21): not a filter or mip defect — source resolution.** Every
`@2x` cut was deleted by the redesign, so the backdrops upscale above 1080p; the display
target to design for is still the owner's call. Evidence: `.agents/gen/batch2_report.md`
§3 B2-2 and `.agents/gen/ui_chrome_regression.md`.
```

Both headings kept their original text, so the two items read as unticked against B2-3's
`FIXED` marker — the same convention the file already uses for `### B2-4 — PASSED in wave 1`.

---

## 3. File two — `docs/design/IMPLEMENTATION_PLAN.md` §9.8

New numbered item after item 5, before `### 9.9`:

```text
6. **Batch-2 playtest follow-up (2026-09-21).** `19_testing_notes.md` B2-3 was a real code defect and is **fixed and measured**: `ui/hud/hud.gd` bound `%ZoomPlus` to `+1` and the map's world radius grows with the delta (`delta * 800`, clamp 800–6400), so `+` zoomed out — the deltas are now named for the direction they mean and the two `pressed` bindings swapped (`%ZoomPlus` → `-1` → world radius 3200 → 2400 = zoom in; `%ZoomMinus` → `+1` → 3200 → 4000 = zoom out), the clamp, the step and the wheel-zoom camera unchanged, and the gate is green (78/78). B2-1 and B2-2 are **not** button-code or texture-filter defects but measured art-side regressions awaiting the owner: the plate art ships as a whole sheet cell, so the theme stretches a mostly transparent canvas and the plate renders as a thin bar (the hover look is not approved — the direction pick is the owner's), and every `@2x` cut was deleted by the redesign, so the backdrops upscale above 1080p. No asset, theme or scene file was changed by this lane. Evidence: `.agents/gen/batch2_report.md`, `.agents/gen/ui_chrome_regression.md`.
```

Item 6 is one unwrapped paragraph, matching items 1–5 of §9.8.

---

## 4. Numbers, and where each one comes from

No number was invented. Every figure written is a figure the evidence or the receiving doc
already carried:

| Number | Source |
|---|---|
| 3200 → 2400 (plus), 3200 → 4000 (minus) | `batch2_report.md` §2.1 probe output and §3 B2-3; the brief states the same pair |
| clamp 800–6400, step 800 | `19_testing_notes.md` B2-3 (pre-existing text), `batch2_report.md` §3 B2-3 |
| `delta * 800` | `batch2_report.md` §3 B2-3 |
| gate 78/78 | `batch2_report.md` §2.2 (`[SUMMARY] passed=78 failed=0`), `ui_chrome_regression.md` ("The gate is green (78/78)") |
| above 1080p | `batch2_report.md` §3 B2-2, `ui_chrome_regression.md` backdrop row |
| 2026-09-21 | the dispatch date and the redesigned-art mtimes both files record |

---

## 5. Deviations, and things deliberately left alone

1. **"Tick" was read as the file's own convention** (a state marker in the `###` heading, plus
   the verdict line), because the file has no checkbox syntax and `B2-4` establishes the
   heading-marker form. Nothing else about the B2-3 section was rewritten.
2. **B2-3's existing body still describes the pre-fix wiring** ("Current wiring: `ZoomPlus`
   emits `+1` …" and "Batch-2 fix: invert the emitted deltas …"). Left as written: it is the
   record of the defect and of the fix that was asked for, and the appended verdict line states
   the outcome directly beneath it. Rewriting it would have been a larger edit than the brief
   asked for.
3. **The file's preamble — `**Nothing here is fixed yet** — this is the batch-2 work list` — is
   now stale for B2-3, and it was left untouched**, on the same minimal-edit rule. Flagged here
   because it is the one place the file still contradicts its own B2-3 marker, and because
   `CLEANUP_PLAN.md` §3 retires this file into an `IMPLEMENTATION_PLAN` amendment, which is the
   natural place to settle it.
4. **`IMPLEMENTATION_PLAN.md`'s pre-existing uncommitted hunks** are untouched and are not part
   of this dispatch (see §1). Consequence for review: `git diff` on that file shows four hunks,
   of which only the §9.8 item-6 one is mine (+1 117 bytes).
5. **Nothing was ticked or amended for B2-2's other candidates** (the tint-stencil import
   settings, the `_48` zoom-button swap) — they are follow-ups inside `batch2_report.md` and
   `ui_chrome_regression.md`, not `19_testing_notes.md` dispositions, so they stay where they
   are until the art route is chosen.
6. **No other file was touched.** Verified: `git status --porcelain` over `docs/`,
   `vajb-orbit/assets/` and `vajb-orbit/ui/theme/` shows only the two docs above written by this
   dispatch; the asset, theme, scene and code files that B2-1/B2-2 would need remain byte for
   byte as the redesign left them.
