---
slice: S49
reviewer: S49-R0
verdict: passed-with-followups
gate: "1420/2 (report) → 1422/0 (re-measured 2026-10-14)"
---

# S49-R0 review

## Acceptance list

1 — pass — the hull press emits the confirm and charges nothing; the answer runs
    `buy_hull` unchanged (`auction_panel.gd:1153-1159` press branch, `:655-668`
    `_request_buy_confirm`, `:676-681` `confirm_action` → `buy_hull`); suite rows 1–2:
    unaffordable answer refuses through the strip (`STATUS_REFUSED_CREDITS`, danger
    flagged), never a dialog. The CANCEL clause holds by construction — the shell calls
    `confirm_action` only on a confirmed answer and returns focus itself
    (`station.gd:691-706`, untouched, shipped) — but the report's item-1 answer carries
    no CANCEL cite (→ F1).
2 — pass — the listing branch quotes the rolled instance's own `name`/`cost`
    (`auction_panel.gd:1160-1166`); suite row 3 asserts the body equals the row
    payload's own figures; the transaction prices from the same `listing_rows` row
    (`auction.gd:889-907` — "the pane and the transaction cannot disagree"), so no
    recomputation and no tier-list leak.
3 — pass — the door fronts only `next == true` (`insurance_panel.gd:234-244`); the
    body quotes `_tier_premium` for the active hull's class (`:250-261`) =
    `insurance_premium()`'s own derivation (`player_profile.gd:2264-2276`), the same
    figure the launch charge reads (`:2329-2337`); OK → `_set_insured(true)` — the
    toggle's transaction verbatim (`:274-282`); the OFF path runs `_set_insured(false)`
    with no dialog and the per-launch charge stays in the model (suite rows 4–5, 8).
4 — pass — `_on_rent_pressed` emits the confirm with `_tier_cost`
    (`vaults_panel.gd:220-239`) = `vault_tier_cost`, the exact function `vault_rent`
    charges (`player_profile.gd:2191-2213`); `_rent` is the former press body verbatim
    (`:251-261`); suite rows 6–7: refusal keeps `REFUSED · VAULT FULL` + danger.
5 — pass — diff-proven: `git diff --name-only` carries none of
    `refinery_panel.gd`/`contracts_panel.gd`/`launch_panel.gd`/`repairs_panel.gd`;
    suite rows 8–10 pin launch + repairs whole-file, the refinery queue bodies, and
    the contract cancel keeping S25's own wording (never A6's title). PAY BOUNTY rides
    `launch_panel.gd` (`station_catalog.gd:247`, `launch_panel.gd:419-431`), so row 8's
    whole-file assert covers it; the insurance-OFF absence is row 5. The "at least
    LAUNCH + insurance-OFF" minimum is met with margin.
6 — pass, disclosed deviations verified — hull: the catalogue's own name for
    `ship_corvette` is "Spearhead" (`station_catalog.gd:154-156`), so A6's first clause
    (`<NAME>` from the owning catalogue, never hardcoded) yields SPEARHEAD; 27 000
    verified (`:156`) and row 11 asserts the exact derived string. Insurance: the
    fighter premium is 135 = 9 000 × 1.5 % (`station_catalog.gd:112`,
    `player_profile.gd:132, :2269-2276`); no class yields 200 (hull costs × 0.015 span
    135–1 080, 200 unreachable), so row 12 pins the exact sentence frame with the
    derived figure — A6's 200 is the doc's illustrative figure (T-199's own class of
    doc drift; the deviation is reported, not doc-edited — correct bucket). Vault:
    VAULT TIER 2 · 1 200 exact off the tier row's own field (row 13;
    `vaults_panel.gd:141`, `player_profile.gd:2191-2197`).
7 — pass — `tests/test_s49_confirm_doors.gd` is 13 rows pinning items 1–6 one-to-one;
    `_assert_confirm_shape` (`:246-253`) asserts title/body/OK/CANCEL exactly; the
    report answers every item with a cite; the one omission is F1's.

## The boundary reading (graded per the dispatch)

pass — the in-list (AUCTION hull + module listing, insurance opt-in only, vault rent
per tier) matches the queue verbatim; A4's door 2 is the ARMORY browser's BUY, a
different surface this wave does not claim. The out-list holds: QUEUE, REPAIR, PAY
BOUNTY, contract `CANCEL · 100 CR FEE`, the LAUNCH commit — no dialog on any of them,
diff-proven (the files are absent from the diff) and suite-asserted (rows 8–10). The
SELL press stays out (a sale is not an acquisition — `auction_panel.gd:181-183`).

## The developer re-cuts (post-report, graded per the dispatch)

- `test_s5_commerce.gd:563-577` (`test_the_auction_keeps_the_hulls_buy_door`) — pass —
  press asserts zero charge + one door + A6 title + the A6 sentence frame, then answers
  through the pane's public `confirm_action`, then asserts the charge and ownership;
  the S43 pattern.
- `test_s3_auction.gd:863-884`
  (`test_the_pane_renders_the_shelf_the_sell_list_and_its_own_footer`) — pass — same
  pattern for the listing buy; the drained-balance refusal now runs through the door's
  answer and still asserts §5.6's strip wording; the `:870` SCRIPT ERROR the report
  flagged is gone (this review's gate re-run is clean, so the wrapper saw no such line).

## Diff scope

The brief's four files plus four developer-side edits, none the worker's: the
`VAJB_WORKER_FILES` hook pinned the worker to the four deliverables, so the two test
re-cuts, the LOW_BACKLOG T-186 close-out re-point and the brief's own 1330→1409
baseline correction are the developer session's edits (the re-cuts are sanctioned by
the dispatch note; the two doc edits are close-out bookkeeping — T-186's close cites
the §17 A6 craft example the D24 developer amendment already carried). Not worker
drift; the four-file rule is not breached by the worker.

No coordinates, no new hex: a mechanical scan of the full diff for `Color(`, hex
literals, `position` and `Vector2(` returns nothing; the suite's
`WINDOW := Vector2(1920.0, 1080.0)` (`:52`) is the harness viewport — the commerce and
s3 suites' own mounting idiom (`test_s5_commerce.gd:189`, `test_s3_auction.gd:186`) —
not a composition coordinate.

## Findings

| ID | Tier | File:area | Finding | Fix owner |
|---|---|---|---|---|
| F1 | LOW | `S49-V0_report.md` item 1 | Acceptance 1's CANCEL clause ("CANCEL returns focus; no transaction on cancel") is satisfied only by construction (the shell's answer handler calls nothing on cancel, `station.gd:691-706`; only `confirm_action` runs transactions) and the suite header discloses the scope (`test_s49_confirm_doors.gd:26-29`), but the report's own item-1 answer never cites it. Report-text gap, no code defect. | report text at close-out → ticketed as T-202. **Close-out correction (2026-10-14): cured without a ticket** — the dated amendment now sits in the report's item 1 (the S46-F1 precedent: a finding the close-out itself cures takes no ticket); the consolidation finding below takes T-202 instead (the ticket IDs this review named shift one; nothing external referenced T-202/T-203 before this correction) |
| F2 | LOW | `insurance_panel.gd:342`, `vaults_panel.gd:316` | `_format_int` now exists in four copies (auction's pre-existing `auction_panel.gd:1544`, the two new service-panel copies, the suite's own `test_s49_confirm_doors.gd:612`). The disclosed bucket-1 helper choice; consolidate into one shared helper at the next UI touch. | ticketed as T-203. **Close-out correction: T-202** (F1 took no ticket; see its row) |
| F3 | LOW | `vaults_panel.gd:224` vs `:255` | The press fetches `_station_row(profile)` that `_rent` fetches again — a duplicate read-only call, harmless. Fold into T-203's consolidation touch. | fold into T-203. **Close-out correction: folded into T-202** |

## Verified fixes

None — review only; no HIGH or MED remained, so no fixer ran.

## Gate

`python3 staging/gate.py --times 1` → `[GATE] run 1: ok - [SUMMARY] passed=1422
failed=0` (2026-10-14). Matches the dispatch baseline 1422/0 exactly; the wrapper's
SCRIPT ERROR sweep is clean (the report-time 1420/2's two moved-premise rows plus
their SCRIPT ERROR are cured by the re-cuts). Arithmetic checks: 1409 baseline + this
suite's 13 rows = 1422. The byte-identical `--times 2` re-run is the close-out's own
step, not this review's.
