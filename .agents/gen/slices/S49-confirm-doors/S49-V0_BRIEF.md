---
slice: S49
worker: S49-V0
role: coder
status: ready
tier: paid
---

# S49-V0 — the A2 doors on the untouched surfaces + the wording law (UI_SPEC §17 completed)

## Context (read in this order, by range)
1. `docs/design/UI_SPEC.md` §17 (lines ~1903–1920, verbatim below) — A4's door
   list and boundary, A5's route, A6's wording law + worked examples.
2. `vajb-orbit/ui/station/auction_panel.gd` — `buy_hull` (`:551-569`), the
   module listing buy (grep `buy_listing`), `_refuse`/`_refusal` (the §5.6
   family), the row payload's price/name fields.
3. `vajb-orbit/ui/station/insurance_panel.gd` — `_on_toggle_pressed`
   (`:216-227`), `_tier_premium` (`:234-237`), `TOGGLE_ON`/`TOGGLE_OFF` (`:46`).
4. `vajb-orbit/ui/station/vaults_panel.gd` — `_on_rent_pressed` (`:203-214`),
   the tier row's cost field (the row the press reads).
5. The confirm seam contract (the S43 brief's disclosed reading, verbatim
   there; `contracts_panel.gd:426-435` + `station.gd:568-599`) — the same seam
   all four P4 door waves use.

## Spec extract (the pinned law, verbatim)

**UI_SPEC §17 A4** — "**the door list** — closed by criterion: *every action
whose primary effect is acquiring something for CR and/or materials*. The
doors: (1) **hull buy** — the AUCTION's hull row purchase (§5.10, 10 §2.3);
(2) **module buy** — the ARMORY browser's `BUY` … (4) **insurance** — the
`INSURE LAUNCHES` opt-in (STATION_HUB §15.3 U13; the per-launch premium itself
is charged at launch, 14 §3 — no dialog on the charge); (5) **vault rent** —
`RENT` (STATION_HUB §15.4 U14) … **Explicitly out** (service spends with their
own verify/refusal paths, STATION_HUB §5.6 — the boundary reading is this
wave's, reported; the owner may widen): refinery `QUEUE`, `REPAIR`, `PAY
BOUNTY`, contract `CANCEL · 100 CR FEE`; the LAUNCH commit is P48's two-press
law, not a dialog."

**A5 (route)** — "every door goes through `DialogManager.confirm(id, title,
body, "OK", "CANCEL")` — never `message` … `dialog_confirmed(id)` runs the
existing transaction path unchanged (a confirmed press can still refuse);
`dialog_cancelled(id)` returns focus to the trigger (N39). The buttons carry
the existing dialog cue (§5.2's CLICK). Esc maps to CANCEL."

**A6 (wording)** — "title `CONFIRM PURCHASE`; body **`ARE YOU SURE YOU WANT TO
BUY <NAME> FOR <PRICE> CREDITS?`** — `<NAME>`/`<PRICE>` from the owning
catalogue (never hardcoded). Worked examples: hull `ARE YOU SURE YOU WANT TO
BUY CORVETTE FOR 27 000 CREDITS?` (10 §3.1); … insurance `…BUY LAUNCH
INSURANCE FOR 200 CREDITS PER LAUNCH?` (14 §3, the class's own premium); vault
rent `…BUY VAULT TIER 2 FOR 1 200 CREDITS?` (U14)."

**The disclosed route reading** — identical to S43's (the shell's §5.2 confirm
overlay via `confirm_requested`/`confirm_action`; the pane never owns a
modal). `confirm_text: "OK"`, `cancel_text: "CANCEL"`.

## The boundary this wave implements (verbatim from the queue)
- **In:** the AUCTION's hull buy AND its module listing buy (A4's criterion
  covers both — the listing's own name/price word the dialog); the INSURANCE
  opt-in only (`INSURE LAUNCHES` — the OFF path stays dialog-free; the
  per-launch charge stays dialog-free per A4's own note); the VAULTS `RENT`
  per tier.
- **Out (A1's reported boundary — widen by owner ruling only):** refinery
  `QUEUE`, `REPAIR`, `PAY BOUNTY`, contract `CANCEL · 100 CR FEE`, the LAUNCH
  commit. None of these surfaces grows a dialog.

## Measured facts (cite, do not re-derive)
- `buy_hull` (`auction_panel.gd:551`) runs `AuctionScript.buy_hull` and
  refuses through `_refuse` — the confirm fronts it; the hull name/price come
  from `Catalog.ship(ship_id)` (`name`, the buyout price `Auction` computes —
  the row payload already carries the price the press will charge).
- The module listing buy runs `AuctionScript.buy_listing` (grep it) — the
  listing instance's own price field words the dialog (a rolled instance's
  price, never the tier's list).
- `_on_toggle_pressed` (`insurance_panel.gd:216`) reads `insured`, flips
  `set_insured`, refreshes — the door fronts only the `next == true` path; the
  premium the dialog quotes is `_tier_premium(profile, tier)` for the active
  hull's class (M14's 1.5 % re-derivation, 14 §3).
- `_on_rent_pressed` (`vaults_panel.gd:203`) runs `profile.vault_rent(...)`;
  the tier row's cost field words the dialog (`…BUY VAULT TIER <n> FOR <cost>
  CREDITS?`).
- The dialog cue: the shell's confirm overlay carries §5.2's CLICK on its
  buttons already (the seam's own behaviour) — you add no cue.
- Gate baseline 1330/0 (2026-10-12).

## Task
Front the four doors with the confirm dialog (A6's wording, the shell seam),
keep every out-boundary surface dialog-free, and add the wording-law suite
`tests/test_s49_confirm_doors.gd` — including the worked-example rows T-186
asks for (one row per A6 worked example, asserting the exact body string the
door emits).

## Acceptance list
1. The AUCTION's hull buy press opens the confirm dialog: title
   `CONFIRM PURCHASE`, body `ARE YOU SURE YOU WANT TO BUY <NAME> FOR <PRICE>
   CREDITS?` (name upper-cased from the ship catalogue, price the buyout the
   press will charge); OK runs `buy_hull` unchanged (which can still refuse
   through `_refuse`); CANCEL returns focus; no transaction on cancel.
2. The AUCTION's module listing buy press opens the same dialog with the
   listing's own name/price; OK runs `buy_listing` unchanged.
3. The INSURANCE opt-in (`INSURE LAUNCHES`, the off→on path only) opens the
   dialog with body `ARE YOU SURE YOU WANT TO BUY LAUNCH INSURANCE FOR
   <PREMIUM> CREDITS PER LAUNCH?` (`<PREMIUM>` the active hull's class
   premium); OK runs `set_insured(true)` unchanged; the off path and the
   per-launch charge stay dialog-free.
4. The VAULTS `RENT` press per tier opens the dialog with body
   `ARE YOU SURE YOU WANT TO BUY VAULT TIER <n> FOR <cost> CREDITS?`; OK runs
   `vault_rent` unchanged (which can still refuse).
5. No dialog appears on: refinery `QUEUE`/`REPAIR`/`PAY BOUNTY`, contract
   `CANCEL · 100 CR FEE`, the LAUNCH commit, the insurance OFF path, the
   per-launch premium charge (A4's boundary — assert at least the LAUNCH and
   insurance-OFF absences in the suite).
6. The wording-law rows: the suite instantiates A6's worked examples verbatim
   (hull CORVETTE 27 000; insurance per-launch; vault tier 2 1 200) — the
   exact strings, `<NAME>`/`<PRICE>` derived from the catalogues.
7. New suite `tests/test_s49_confirm_doors.gd` pins items 1–6; the report
   answers every item with a cite.

## Hard constraints
- File set: `vajb-orbit/ui/station/auction_panel.gd`,
  `vajb-orbit/ui/station/insurance_panel.gd`,
  `vajb-orbit/ui/station/vaults_panel.gd`,
  `vajb-orbit/tests/test_s49_confirm_doors.gd`. Do not touch `station.gd`
  (the seam is shipped), the game model files (the transactions are
  read-called only), other panels, docs, the theme.
- No new hex; no new tokens; no wording invention — A6's strings, derived
  values only.
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S49-confirm-doors/S49-V0_report.md` (≤120 lines,
  from `_templates/REPORT.md`).
- Deliverable: the four files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/auction_panel.gd,vajb-orbit/ui/station/insurance_panel.gd,vajb-orbit/ui/station/vaults_panel.gd,vajb-orbit/tests/test_s49_confirm_doors.gd" crush run "You are worker S49-V0. Read .agents/gen/slices/S49-confirm-doors/S49-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
