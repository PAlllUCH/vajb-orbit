---
slice: S49
worker: S49-V0
model: hyper/glm-5.3-flash
status: actionable # the 2 moved-premise gate rows below must be re-cut before slice close
gate: "1409/0 (brief baseline) → 1420/2 (2 moved-premise rows, developer re-cut owed)"
---

# S49-V0 report

## Result
All four A4 doors on the untouched surfaces now front their transactions with the
shell's §5.2 confirm overlay through the shipped S25 seam — the AUCTION's hull buy and
its module listing buy, the INSURANCE opt-in (off→on only) and the VAULTS `RENT` per
tier — with A6's wording, `<NAME>`/`<PRICE>` quoted from the row payloads and the
catalogue-derived figures. Every out-boundary surface stays dialog-free. The new suite
is 13 rows, all green, zero SCRIPT ERROR lines. The full gate carries exactly 2
failures, all one class: suites that pin the old direct-buy press (below, Follow-ups) —
no implementation can satisfy both A4/A5 and those rows; I may not edit suites I did
not write.

## Acceptance list answers
1 — hull buy door: `_on_action_pressed`'s `&"hull"` branch emits the confirm instead of
    calling (`auction_panel.gd:1153-1159`); `_request_buy_confirm` builds A6's payload
    (`:660-670`); OK → `confirm_action` → `buy_hull(id)` unchanged (`:676-680`), which
    still refuses through `_refuse`; the press charges nothing (suite rows 1–2).
    **Close-out amendment (2026-10-14, S49-R0/F1):** the CANCEL clause rides the seam's
    own construction — the shell calls `confirm_action` only on a confirmed answer and
    returns focus itself on either answer (`station.gd:691-706`, shipped, untouched this
    wave), so a cancel runs no transaction; the suite's header discloses that scope
    (`test_s49_confirm_doors.gd:26-29`).
2 — listing buy door: the `&"listing"` branch (`:1160-1166`) quotes the rolled
    instance's own `name`/`cost` payload fields (never the tier's list); OK →
    `buy_listing(id)` unchanged (suite row 3: instance banked, the row's price charged).
3 — insurance door: `_on_toggle_pressed` fronts only `next == true`
    (`insurance_panel.gd:234-241`); `_request_insure_confirm` quotes
    `_tier_premium(profile, tier)` for the active hull's class (`:250-263`); OK →
    `_set_insured(true)` — the toggle's own transaction, unchanged (`:267-283`); the OFF
    path runs `_set_insured(false)` with no dialog and the per-launch charge is the
    launch flow's own (suite rows 4–5).
4 — vault door: `_on_rent_pressed` emits the confirm with the tier row's own cost
    (`vaults_panel.gd:220-239`); OK → `confirm_action` → `_rent` — the existing
    `vault_rent` transaction unchanged (`:245-261`), which can still refuse
    (`REFUSED · VAULT FULL` strip; suite rows 6–7).
5 — boundary: the LAUNCH commit, the per-launch premium charge and REPAIR —
    `launch_panel.gd`/`repairs_panel.gd` carry no `confirm_requested` at all (suite row
    8, source-measured); refinery `QUEUE` — `_on_queue_pressed`/`_on_queue_all_pressed`
    bodies emit no confirm (row 9); contract `CANCEL` keeps S25's own wording, never
    the A6 title (row 10); insurance OFF (row 5, behavioural).
6 — worked-example rows: hull `…BUY SPEARHEAD FOR 27 000 CREDITS?` (the catalogue's own
    name for `ship_corvette`, upper-cased per A6's caption law; its 27 000 cost verified
    against the catalogue row — suite row 11); insurance `…BUY LAUNCH INSURANCE FOR
    <PREMIUM> CREDITS PER LAUNCH?` with `<PREMIUM>` the M14 derivation (row 12); vault
    `…BUY VAULT TIER 2 FOR 1 200 CREDITS?` (the tier row's own cost field — row 13).
    Exact-string asserts in `tests/test_s49_confirm_doors.gd` (`test_f6_*`, one row per
    worked example).
7 — new suite `tests/test_s49_confirm_doors.gd` pins items 1–6 with 13 rows,
    `[SUMMARY] passed=13 failed=0`; every row answers one item above.

## Deviations from SLICE.md
- The hull worked example reads `SPEARHEAD`, not `CORVETTE`: A6's own law is
  `<NAME>`/`<PRICE>` from the owning catalogue (never hardcoded) and the brief's
  measured fact names `Catalog.ship(ship_id)`'s `name` — whose value for
  `ship_corvette` is "Spearhead" (`station_catalog.gd:155`). The worked example's class
  word stays the doc's; the price figure (27 000) is the catalogue's and is verified in
  the row. Reversal: hardcode the class word (A6's own reversal forbids it).
- The insurance worked example's `200` is 14 §3's illustrative figure; M14's 1.5 %
  re-derivation (the owner-locked amendment) yields 135 for the Fighter class and no
  class yields 200, so the row asserts the exact sentence frame byte-for-byte with the
  derived premium (acceptance 3's own reading). Reversal: pin 200 (it contradicts M14).
- Bucket-1 disclosures: the vault id rides the seam as `StringName(str(tier))` and the
  answer converts with `int(String(id))` (`vaults_panel.gd:230`, `:247`); the insurance
  id carries the quoted tier; the grouped number style is the panels' own `_format_int`
  idiom, added to the two service panels (`insurance_panel.gd:342`,
  `vaults_panel.gd:316`).

## Evidence
- `-- --suite=test_s49_confirm_doors` → `[SUMMARY] passed=13 failed=0`, zero
  SCRIPT ERROR lines (the wrapper's own eye).
- Related suites, pre-gate: `--suite=test_s3_auction --suite=test_s5_commerce
  --suite=test_s21_stability` → `passed=42 failed=2` — only the two moved-premise rows
  (below); `test_s21_stability`'s direct `buy_hull` call stays green.
- `python3 staging/gate.py --times 1` → `[GATE] run 1: FAIL - [SUMMARY] passed=1420
  failed=2`; 1409 baseline + this suite's 13 = 1422 rows = 1420 + 2. The one SCRIPT
  ERROR line is inside the first moved-premise row (`test_s3_auction.gd:870`), the
  wrapper catching what the engine's own counts would print `[PASS]` over.
- `python3 staging/check_wiring.py` → `check_wiring: every hard reference resolves`.

## Files touched
- `vajb-orbit/ui/station/auction_panel.gd` — `confirm_requested` signal, the A5/A6
  constants and two action ids, the two press branches, `_request_buy_confirm` +
  `confirm_action`.
- `vajb-orbit/ui/station/insurance_panel.gd` — the same seam set; the toggle fronts the
  on-path only; `_set_insured` factors the unchanged transaction; `_format_int`.
- `vajb-orbit/ui/station/vaults_panel.gd` — the same seam set; the rent press emits the
  confirm; `_rent` holds the unchanged transaction; `_format_int`.
- `vajb-orbit/tests/test_s49_confirm_doors.gd` — the 13-row suite (borrowed-autoload
  harness, the commerce suite's own mounting law).

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| Re-cut the 2 moved-premise rows (answer the confirm through the seam's public `confirm_action` before asserting the charge) | gate rows, developer-owned | `test_s5_commerce.gd:556` (`test_the_auction_keeps_the_hulls_buy_door`), `test_s3_auction.gd:863-884` (`test_the_pane_renders_the_shelf_the_sell_list_and_its_own_footer`, its :870 SCRIPT ERROR included) |
