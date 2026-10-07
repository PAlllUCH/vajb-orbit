---
slice: S34
worker: S34-R1
model: "hyper/glm-5.3-flash"
status: complete
verdict: blocked
---

# S34-R1 review

Re-measured, not trusted: gate ×2 on fresh scratch (`XDG_DATA_HOME=$(mktemp -d)`,
`~/.local/bin/godot --headless --path vajb-orbit res://tests/headless_runner.tscn
--quit-after 1200`), an independent 57-check probe (`tests/probe_s34_review.tscn`,
left in place as evidence), the W3 lint probe, and a row-by-row diff of the change
set. Probe end line: `[S34R] PASS 0`.

## Acceptance list (graded first)

| # | Grade | Evidence (re-measured) |
|---|---|---|
| 1 R1 exact | **pass** | Probe: Iron 10, Gold 40, Copper 10 (floors), Krilium 60 (ceilings), unknown 10; `clamp(round(ingot_value/10),10,60)` recomputed per `Catalog.MINERALS` row — exact for all 16. `game/refinery.gd:109-114`. |
| 2 queue all-or-nothing + duration | **pass** | Probe: empty-input, poor-account, count-0, unknown-mineral refusals all leave credits/input/jobs untouched; success spends 15, takes 3, mints 1 job. `ready_at = now + conversions × RESOURCE_SECONDS` probed at 1×10 s and 2×40 s (±2 s). The spend→take restore branch (`refinery.gd:236-238`) is unreachable single-threaded but restores symmetrically. Jobs never fail: no RNG in the module, settle is deterministic. |
| 3 slots | **pass** | Probe: 2 base; 3 upgrades × 3,000 CR flat (= 9,000 total); refusal at 5 with `max_slots`, zero charge; 2 run + 1 FIFO pending; upgrade + settle promotes the pending job. QUEUE ALL: one job per mineral in catalogue order, combined fee charged once. |
| 4 inventory | **pass, with F1** | Probe: over-cap LOAD refused whole (`input_full`, ore stays in hold); CANCEL refunds the stored fee and returns ore to input, overflow to the hold when input is full; COLLECT fills the hold to its resolved cap (39 free → 39), overflow stays in output. F1 below is a done-row-lifecycle fault inside this family. |
| 5 settle wall-clock | **pass** | Probe: not-ready settles 0; fake-ready (`ready_at = 0`) settles 1 into `refinery_output`. The three triggers driven through the mounted panel: `refresh_profile(&"refinery")`, `_tick()` (1 Hz timer, `refinery_panel.gd:241-247,263-271`), `_on_visibility_changed()` (`:250-258`) each settle a forced-ready job. |
| 6 panel P42/P43 | **pass, with F3** | Probe on the mounted scene: `QUEUE 1` / `QUEUE ALL` / `CANCEL` / `LOAD` / `COLLECT ALL`, `SLOTS 2/5`, `UPGRADE (3,000 CR)` in the header band; `_mmss(95) = 01:35`; a running row's countdown label matches mm:ss of `ready_at − now`; empty states `NO ORE IN HOLD` / `NO JOBS QUEUED`, footer idiom `BRING RAW ORE FROM THE BELT` → `LOAD ORE TO START A JOB` (`:85-86,637-647`). A5.5/N24 clean: hover tweens `modulate:a` only (`:789-796`), descriptions go through `inspect_requested` (the fixed sink), no `tooltip_text` anywhere (the §12.5 census row 7 refinery entry is resolved). |
| 7 gate + disclosed rows | **pass** | Gate 1131/0 twice on fresh scratch. Sealed row `test_stacks_lists_only_convertible_minerals` is **byte-identical** (function-level diff clean); it moved 192 → 239 (report said 238 — F5). Every disclosed move verified: the five P1 rows restated queue/settle/collect; `test_s23_content.gd` u_refine row moved + borrow/restore covers the four new stores; `probe_w3_lint.gd` pins 576→2210, 735→2795, 533→778 all hold (`[W3] passed=49 failed=7`, the 7 all in settings_manager/audio_manager/station.gd — files this wave never touched); `probe_s23_r1.gd` md5-identical to HEAD; test_s8/test_s11 untouched and green. |

## Pin table (graded second)

| Pin | Grade | Note |
|---|---|---|
| §3 signatures (the 12 statics) | met | All present with the pinned names/shapes; `stacks`/`convertible` retained for the sealed row + LEFT hold rows. |
| §3 profile keys + save names | met (dev disclosed) | Five stores private behind ten doors; the save keys keep the pinned names (`player_profile.gd:2772-2777`); every write emits `profile_changed(&"refinery")` (probed). Old saves default 2/{}/{}\/[]/1 (probed). |
| Extra job fields `fee`/`settled` | met (dev disclosed) | Reversal stated; `cancel` refunds the stored fee — the correct choice (a recompute at cancel could diverge from what was charged). |
| R1–R8 values | met | All at PROPOSED values; constants single-sourced (`refinery.gd:35-46`). |
| 01 §7 ordering | met per the brief, docs note F4 | Brief/04 §7.2 R2 pin verify → spend → take; 01 §7 says verify → take → pay. Code follows the brief; restore is symmetric; no leak (probed). |
| `test_p1_refinery.gd:192` sealed | met | Byte-identical row; line number moved (disclosed). |
| Hard rules (file set, doors, no invented doors) | met | Production writes only through doors (`rg '_refinery_'` on game/ ui/: zero direct hits; test scaffolding uses the pre-existing snapshot idiom). |

## Findings

- **S34-B1/F1 — MED — `collect_all` prunes every done+settled job even when it collected nothing, so a COLLECT ALL pressed with a full hold erases all "DONE · COLLECT" rows while `refinery_output` still holds the ingots — and the output inventory has no other UI surface, so uncollected ingots become invisible until the next collect.** No value is ever lost (output keeps the units; COLLECT ALL stays enabled and a later press collects them — probed both the zero-yield prune and the later recovery), so this is a player-visible fault, not a leak. `game/refinery.gd:466-467` + `:506-515`; probe line `[S34R] ok F1 evidence: a zero-yield COLLECT prunes the done row while the ingot stays uncollected in output`.
- **S34-B1/F2 — LOW — hold rows render the *input's* conversions/fee in the inspect title: `refinery_panel.gd:393-394` computes `input_conversions`/`fee_for` for hold rows too, so a "6 ORE HELD" row with an empty input inspects as "0 CONVERSIONS · 0 FEE"** (the row's own cells are correct; only the inspect line misdescribes the hold).
- **S34-B1/F3 — LOW — the scene seeds carry the literals `UPGRADE (3,000 CR)` and `QUEUE 1` (`refinery_panel.tscn`); both are overwritten at ready by `_refresh_slots`/`_refresh_box` so no *displayed* number is hardcoded, but the report's "grep finds no hardcoded price" is not literally clean.**
- **S34-B1/F4 — LOW — 04 §7.2 R2 pins verify → spend → take while 01 §7 pins verify → take → pay; the code follows the brief (spend before take, `refinery.gd:234-238`, symmetric `add_credits` restore) — reconcile 01 §7 at the review wave's docs pass.**
- **S34-B1/F5 — LOW — report cite drift: the sealed row's new line is 239, not 238; panel word constants sit at `:77-81`, not `:71-75`; a few module cites overshoot by 3-5 lines. Substance everywhere correct.**

## Verdict

**blocked** — one MED. Fixer item list (S34-F1):

1. **F1**: a done job may leave the job list only once its conversions have actually reached the hold. Minimal root-cause fix in `game/refinery.gd`: gate `_prune_collected` on what the collect actually moved (e.g. prune a done+settled job only when the post-collect `remaining` holds none of its mineral's ingots — or when `collected == 0` skip pruning entirely and drop rows as the output drains). Keep the F1-evidence probe green inverted: after a zero-yield collect the done row must still be listed; after the output fully drains the row must leave. Re-run the gate ×2 and update the S34 report's evidence lines.

F2–F5 are polish; fold F3's tscn seed text and F4's docs reconciliation into the review wave's docs pass if the fixer does not take them.
