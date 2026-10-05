---
slice: D21-chrome-family
worker: D21-G2-F1
model: hyper/glm-5.3-flash @ max (brief-pinned fixer)
status: actionable   # fix-list item 2 awaits the owner's spend decision
gate: "n/a — asset lane; verify = re-run of R1's alpha-bucket probe: all 7 veiled cuts a200_249 → 0.00, RGB byte-identical, 0 alpha-rule violations"
---

# D21-G2-F1 report

## Result
Fix-list item 1 executed: alpha-floor normalization on the 7 veiled chrome cuts
(α ≥ 200 → 255, α < 200 byte-identical, RGB untouched), one scripted Pillow pass,
edited in place at the landed stems. Every post-fix bucket matches the expected
shape; C8's corners verified hard-square with their soft tips preserved. Item 2
is restated below as awaiting the owner; item 3 respected — margins, bands, pixel
content, names and `.import` files untouched.

## Acceptance list answers
1 — DONE — per-file before/after below (bucketing = `D21-G2-R1_measure5.py`:
a0 / a1_49 / a50_199 / a200_249 / a250_255; only the veil and opaque columns move).

| file | a200_249 before → after | a250_255 before → after | fringe (a1_49 + a50_199) | match |
|---|---|---|---|---|
| ui_slot_weapon_normal | 42.04 → 0.00 | 54.42 → 96.46 | 0.03 + 3.51 unchanged | expected |
| ui_slot_cargo_normal | 42.04 → 0.00 | 54.42 → 96.46 | 0.03 + 3.51 unchanged | expected |
| ui_slot_inventory_normal | 42.04 → 0.00 | 54.42 → 96.46 | 0.03 + 3.51 unchanged | expected |
| ui_minimap_bezel | 96.30 → 0.00 | 1.02 → 97.32 | 1.25 + 0.42 unchanged | expected |
| ui_panel_frame | 99.98 → 0.00 | 0.02 → 100.00 | 0.00 + 0.00 unchanged | expected |
| ui_bar_caps | 4.89 → 0.00 | 28.36 → 33.25 | 13.90 + 0.94 unchanged | expected |
| ui_inline_chip | 3.55 → 0.00 | 49.51 → 53.06 | 3.14 + 3.17 unchanged | expected |

- Probe verify: every file re-opened from disk after save and re-bucketed; all 7
  `matches_expected: true`; all 7 pre-fix buckets re-measured equal to R1's
  `evidence5.json alpha_buckets` (`matches_R1_before: true`).
- C8 corners read hard-square: each slot's four corner 3×3 alpha rings are
  byte-identical before/after (tips α 34/37/41 kept — fringe rule), sub-200 px
  count unchanged at 444 per slot, and the α=255 region now spans bbox
  [1,1,111,111] of the 112² canvas (was veiled to ~54 % opaque). The face draws
  fully opaque to its square edges — the hard-square read the C8 prompt pins.
- Residual note (not a defect): the chip's post-floor non-transparent α250+ share
  is 89.4 %, below the 94.7–99.4 shipped convention only because its preserved
  soft fringe (6.31 %) and true transparency (40.62 % a0) remain — the veil
  itself (a200_249) is gone, which is the fix's defined end state.

2 — NOT DONE (owner tick, not mine) — awaiting the owner: re-run C1, C2, C9, C5 —
4 × 10 cr = $0.20 with the class aspect re-stated in the prompt; §13.6's remaining
ceiling is 6 runs / $0.30 but it is pinned for state variants, so the spend needs
the owner's go; then re-cut per §13.1 and land at the §13.4 stems. Alternatives
without spend: those surfaces keep shipped art, or the family re-routes onto
nano-banana-pro (§13.1's own reversal). No paid call was made.

3 — ACKNOWLEDGED — margins/bands are S36 wiring inputs (L1/L2), C10's notch (L3)
and C6's hairline (L4) stay wiring decisions; nothing outside the alpha floor was
changed. Guards in the pass prove it: RGB channels byte-identical per file,
per-pixel rule verified with 0 violations (α < 200 identical, α ≥ 200 → 255),
sizes/mode unchanged, `.import` stanzas untouched (their uid is md5-of-res-path,
not of content — L5 wording issue unaffected).

## Deviations from SLICE.md
1. Seventh veiled file identified as `ui_inline_chip.png` — F3's file column names
   six; the chip is the only remaining landed cut below the shipped convention on
   non-transparent α250+ share (83.4 % vs 94.7–99.4; all other unnamed cuts ≥ 95.5 %)
   and carries the α200–249 veil signature (3.55 %). Reversal: drop it from the set
   and copy its backup back over `assets/ui/ui_inline_chip.png`.
2. Added a pre-fix reversal store at `asset-library/_prekey_backup/chrome_veil_prefix_2026-10-05/`
   (7 PNGs + manifest.json, md5s in `D21-G2-F1_evidence.json`): the floor is not
   self-reversible (floored 200–249 px are indistinguishable from native 255), and
   the existing `chrome_family_2026-10-05/` store holds the shipped originals, not
   the D21-G2 veiled cuts. Reversal: copy the 7 files back over `assets/ui/`.

## Evidence
- `python3 .agents/gen/slices/D21-chrome-family/D21-G2-F1_fix.py` — single pass,
  foreground, no background process left. Per-file guards recorded in
  `D21-G2-F1_evidence.json`: `rgb_untouched: true`, `alpha_rule_violations: 0`,
  before/after/expected buckets, md5 before/after per file.
- Slot trio observation: all three slot faces share one md5 before (c6f07162…)
  and one after (4b9b91d8…) — the C8 master was landed under three names
  (D21-G2 report landing table), consistent with R1's identical buckets. Expected.
- Reversal store verified on disk: `chrome_veil_prefix_2026-10-05/` holds exactly
  the 7 pre-fix PNGs + manifest.json; exactly those 7 files changed under
  `vajb-orbit/assets/ui/` (mtime scan), nothing else.

## Files touched
- `vajb-orbit/assets/ui/` — the 7 PNGs, alpha channel only (floor α ≥ 200 → 255).
- `asset-library/_prekey_backup/chrome_veil_prefix_2026-10-05/` — 7 pre-fix PNGs
  + manifest.json (reversal store).
- `.agents/gen/slices/D21-chrome-family/` — `D21-G2-F1_fix.py`,
  `D21-G2-F1_evidence.json`, this report.

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Owner tick: C1/C2/C9/C5 re-runs, 4 × 10 cr = $0.20 (class aspect re-stated), then re-cut per §13.1 and land at §13.4 stems; or keep shipped art / re-route onto nano-banana-pro | owner decision (paid) | §13.1/§13.6 |
| S36 wires measured margins (L1), band calibration (L2), C10 notch (L3), C6 hairline (L4) | wiring | §15.3/§13.5 |
