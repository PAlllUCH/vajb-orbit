# dispatch_coder.md — the code-lane queue of record

Rebuilt 2026-09-22, reorganised 2026-09-24 (open items only — closed work lives
in the Done pointer below, `MASTER_REPORT.md` and `_state/WAVEBOARD.md` §Closed).
Execute **one item per order**, close out per the brief's close-out section.
Model for every worker: `deepseek/deepseek-flash` (DeepSeek API direct, owner
ruling 2026-09-24; supersedes the same-day go order; fallback
`opencode-go/deepseek-v4.1-flash`) on `--reasoning-effort high`. The owner pastes
only the handoff block at the bottom.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). Across lanes only with provably disjoint
write sets (the S5∥D6 precedent); one live session per workspace (L82).
**Wave anatomy:** docs-first five-piece → `verify_wave.py snapshot` + commit →
Q0/K0 dispositions into CONTRACTS → builders → review → fixer only on
HIGH/MED → close-out (gate ×2 hermetic, `verify --baseline`, §9/§10 sequenced
with any parallel lane, WAVEBOARD, wave-boundary commit).

## Open queue

| # | Wave | Slice folder | Brief / prompts | Status |
|---|---|---|---|---|
| 15 | **Flight-feel retune** (owner O4/O5) — **folded into item 18** | — | — | **TICKED 2026-09-24.** The owner answered "go ahead with all": T1 `COAST_TIME_MULT` 2.5 and T2 new `ANGULAR_DAMP_MULT` 0.5 are implemented by item 18's **S11-B4**; **T4 is superseded** by the one-vector decay; **T3 is HELD** (§22's row contradicts itself — notice with the owner). |
| 17 | **Jump gates to sector edges** (owner ask 2026-09-24: same gates, spawn placement only) | not opened | — | **QUEUED — brief at dispatch-prep.** Runs after item 19; the `game/sector.gd` seam is **free** since D11's close-out (2026-09-25). Editor-only change otherwise. |
| 18 | **Station legibility, space gunnery, one-vector inertia** (owner ask 2026-09-24: hovered-item description panel, credits in the space scene, near-infinite kinetic/beam range, the two-stop inertia) — pin **CONTRACTS §23** | `slices/S11-legibility-gunnery-feel/` | `S11_BRIEF.md` / `S11_prompts.md` | **DONE 2026-09-24** — gate 775 → **807/0**, 0 HIGH / 0 MED / 6 LOW (L178–L183). Six builders (B1 inspector, B2 prose + HUD credits, B3 ranges, B4 one-vector inertia, B5 test rows, B6 describe + titles) + R1; the readability half is the design lane's **D12-A0** audit. |
| 19 | **Ore budget — the two K0 probes** (owner ruling 2026-09-25: shooting rocks stays possible but mining must always be more profitable; asteroids could be bigger, in clusters and fields) — docs already amended, these are the numbers | `slices/S12-ore-budget/` | `S12_BRIEF.md` / `S12_prompts.md` | **IN FLIGHT 2026-09-25** — K0/K1 measured (byte-identical ×2, `failures=0`; laser out/in **4.07×** T1 / **3.83×** T3 the spawn budget; gun racks deliver the same **25 units at 3 and 7 barrels**, 0.714 of a rock's own yield = 7× the proposed `GUN_BURST_SHARE`); **S12-R1 replay next**. No production file and no gate row moves (the +5 = D11's `test_d11_station`; gate now 812/0); the caps and scale rows wait on the owner ticks the tables feed. |

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework stays the owner's (`18_engine_spec.md` §6/§13/§15, the
§13 turn/coast column ticks, slice 2.5's two calls).

## Done

Items 1–16 and 18 closed: chrome, combat repair, weapon FX (→ `MASTER_REPORT.md`);
P2-A `8d189bf`, Rock cleave `0e419f7`, P2-B1 `1f794cc`, P2-B `3e79e61` (→
`session_2026-09-22_items_4_to_7_report.md`, gate 437); S2.6 (457), S3 (493),
S4 (524), S5 (578), S6 (674), S7 (753), S8 (770), S10 (775), S11 (807) — detail, reviews,
incidents and LOW rows in `MASTER_REPORT.md` §6 +
`session_2026-09-24_items_8_to_13_report.md`; evidence archived in each
slice's `_archive/` (S8's, S10's and S11's still in their slice folders).

## Handoff (live)

**Item 19** is in flight: K0/K1 landed 2026-09-25 (the tables are the wave's
deliverable), **S12-R1's byte-identical replay is next**, then close-out and the
§10 tick list to the owner — the caps are **not** implemented on this wave.
**Item 17** (jump gates to sector edges) is next in the queue and **unblocked**
(D11 closed 2026-09-25); it needs its own five-piece at dispatch-prep. Slice 4's
remainder (quadrants and directional armour, bosses/arena) still needs its own
five-piece.

Beyond the queue: **slice 4's remainder** (quadrants/directional armour — 18
§4.5 + ruling 23; bosses/arena — 14 §5, blocked on P4 contracts + boss art).
Owner-locked homework stays the owner's (`18_engine_spec.md` §6/§13/§15, the
§13 turn/coast column ticks, slice 2.5's two calls).

## Design lane (not mine to dispatch)

**D12-A0's readability audit is on disk** (`slices/D12-ui-readability/D12-A0_report.md`, 5
HIGH / 4 MED / 3 LOW, every finding lane-tagged). Its four graphics findings are the ARMORY
pane's type scale (9-13 px with per-node overrides that escape `ui_scale`), `text_dim`
captions on painted metal at 1.9-2.8:1, the ember tag at 1.8:1, and the pane's ammunition
half sitting below the fold at 1920x1080 with 37 % of its host empty. **They are the design
lane's — the owner's D11/D12 designer session owns the fix**, and any fix that edits
`ui/station/armory_panel.gd` must land **after** S11-B1 (which holds that file for the hover
wiring). Raised to the owner as a notice; not briefed here.
