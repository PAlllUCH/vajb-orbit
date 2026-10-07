---
slice: S34
worker: S34-F1
model: "hyper/deepseek-v4.1-flash"   # the fixer assignment per the brief
status: complete
gate: "1131/0 -> 1132/0"
---

# S34-F1 report

## Result

F1 cured at the root: a done job now leaves the list only once its ingots have
actually left `refinery_output`. F2 and F3 taken as ride-alongs. Gate 1132/0 on
two fresh-scratch runs; the S34 review probe green inverted (`[S34R] PASS 0`);
the W3 lint probe back to its B1 baseline (49/7, all 7 in files this wave never
touched).

## Fix-list answers

1. **F1 (MED, mandatory) — DONE.** `collect_all` now prunes with the post-collect
   store (`_prune_collected(profile, remaining)`, `game/refinery.gd:467`), and the
   new `_is_collected` (`game/refinery.gd:523-528`) counts a done+settled job as
   collected only when its mineral's ingots are absent from that store. A
   zero-yield collect over a full hold prunes nothing; the row leaves as the
   output drains. A settled job's ingots can only leave output via a collect, so
   "absent from remaining" is exactly "reached the hold".
2. **F2 (LOW, optional) — TAKEN.** `ui/station/refinery_panel.gd:393` now reads the
   row's own `conversions` off the stack (hold rows carry `convertible` from
   `RefineryModule.stacks`, `game/refinery.gd:143`; input rows fall back to
   `input_conversions`), so a "6 ORE HELD" row with an empty input inspects as
   "2 CONVERSIONS · 30 FEE", not "0 · 0".
3. **F3 (LOW, optional) — TAKEN.** `ui/station/refinery_panel.tscn:63` seeds
   `UPGRADE` and `:249` seeds `QUEUE`; the `(3,000 CR)` price and `QUEUE 1` count
   literals are gone (the runtime text is still set at ready, probe-verified).
4. **F4 / F5 — out of scope** (designer docs pass / reporting note), untouched.

## Deviations

- F2 was implemented **line-count-neutral** (one line in, one line out) so the W3
  line pin `refinery_panel.gd:778` does not move; the first two-line draft shifted
  it and tripped `[W3-FAIL] refinery_panel.gd:778`, reverted. No pin changed.
- Added one regression test to `test_s34_refinery_queue.gd`; the gate count moves
  1131 → 1132 for that reason only. Reversal: delete the test.
- Extended the review probe with an F2 evidence line (the probe is the wave's
  evidence family; F1's own check was inverted as instructed).

## Evidence

- Gate before: `[SUMMARY] passed=1131 failed=0`.
- Gate after ×2 (fresh `XDG_DATA_HOME=$(mktemp -d)`):
  `[SUMMARY] passed=1132 failed=0` / `[SUMMARY] passed=1132 failed=0`.
- S34 review probe (`res://tests/probe_s34_review.tscn --quit-after 300`):
  - `[S34R] ok   F1 evidence: a zero-yield COLLECT keeps the done row while the ingot stays in output`
  - `[S34R] ok   F1 evidence: once the output drains the done row leaves the list`
  - `[S34R] ok   F2 evidence: a hold row inspects as its own hold numbers (2 conversions, 30 fee)`
  - `[S34R] PASS 0`
- W3 lint probe (`res://tests/probe_w3_lint.tscn --quit-after 600`):
  `[W3] passed=49 failed=7`, the 7 all in `settings_manager.gd` / `audio_manager.gd`
  / `station.gd` — files this wave never touched (B1 baseline).
- `rg '3,000|QUEUE 1|UPGRADE \(' vajb-orbit/ui/station/refinery_panel.tscn` → no match.

## Files touched

- `game/refinery.gd` — `_prune_collected` takes the post-collect output; new
  `_is_collected` gates pruning on the mineral's ingots actually leaving output.
- `ui/station/refinery_panel.gd` — a row's inspect numbers come from its own stack.
- `ui/station/refinery_panel.tscn` — neutral seed text (no hardcoded price/count).
- `tests/probe_s34_review.gd` — F1 check inverted (row kept on zero yield, leaves
  on drain) + an F2 hold-row check.
- `tests/test_s34_refinery_queue.gd` — new `test_done_row_leaves_only_once_its_ingots_are_collected`.

## Follow-ups

None. F4 (01 §7 wording) and F5 (report cites) stay with the designer's close-out.
