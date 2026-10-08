# LOW backlog — findings that ride with the next wave

This file is `.agents/gen/_state/LOW_BACKLOG.md` under the folder law
(`AGENTS.md` §Slice / folder law) — the single list of open items; reports and
reviews are history.

Tiering per the WAVEBOARD: **HIGH blocks the wave**, **MED gets one fixer pass**,
**LOW lands here and rides with the next wave**.

**2026-10-08 (owner clear-out):** the workspace keeps only S24–S27, so this file
holds only the rows that ride them. Every S36/S37 chrome-family row (T-136,
T-137, T-141, T-144–T-151) moved verbatim to
`_archive/low_backlog_s36_s37_rows_2026-10-08.md`; earlier retired rows are in
`_archive/low_backlog_open_rows_retired_2026-10-07.md` and
`_archive/low_backlog_closed_rows_2026-10-07.md`; closed slice folders live in
`_archive/slices/`. Repro paths in retired rows are historical; the finding text
is self-contained. Ticket IDs are stable forever — retired numbers are never
reused, so **the next free ticket is T-152**.

Legend: **[DOC]** = a docs pass, **[SPEC]** = needs the owner's spec lock,
**[CODE]** = a code change when someone owns the file, **[HARNESS]** = agent
tooling, **[TOOL]** = a shipped repo tool/script.

**Tickets:** new items take the next global `T-###` (next free **T-152**) and
follow `_templates/TICKET.md` — one row here is the index; skip a detail file
when the row says it all. **2026-10-08 (S24-R1): T-152/T-153 filed; the next free
ticket is T-154.**

**Closure protocol:** when an item closes, record it in its Disposition as
`CLOSED in <slice/wave>` with the evidence pointer — never delete the row. A
carried-over item (e.g. `L26` = `L11`) closes in **both** rows. A brief
referenced by an open row survives until the row closes.

| # | Item | Kind | Where | Disposition |
|---|------|------|-------|-------------|
| T-138 | **SERVICES deck placeholder:** the deck ships a `MODULE OFFLINE` placeholder until the contracts/insurance/vaults strip (D22-P1/F03). | [UI] | `ui/screens/station.gd` (SERVICES deck) | CLOSED in S25 (S25-R1/A7: the deck ships the real CONTRACTS panel, `station.gd:1060`; the only placeholders left are D11's own not-installed INSURANCE/VAULTS seam). |
| T-152 | **Launch destination flavour (S24-R1/F2):** the undock destination still reads the mockup-era `OPEN SPACE · HELIOS DRIFT` (`ui/station/launch_panel.gd:53`) — a sector name the map doesn't carry (11 §1) — instead of the docked sector's own name. Pre-existing (S30 chrome, file untouched in S24); surfaced by S24-R1's "no placeholder anywhere" sweep. | [UI] | `ui/station/launch_panel.gd:53` | CLOSED in S25 (S25-R1/A8: `destination_line()` reads the docked sector's own name, `launch_panel.gd:281`; `test_a8` pins `OPEN SPACE · MERIDIAN SPAN`). |
| T-153 | **Reserved slot's tier clamp (S24-R1/F3):** V5's reserved slot is clamped into the catalogue's 1–3 (`game/auction.gd:421`), so a tier-4 sector (S6/S7) reserves its slot at tier 3 — `tier_pool(4)` is empty and a dropped slot would break the pinned 6 + 20 shelf. The real fix is a tier-4 catalogue row (a data addition, not a mechanic change). | [CODE] | `game/auction.gd:421` (clamp) + `game/module_catalog.gd` (a tier-4 row) | Rider on S27 (catalog breadth & shipyard); S24-R1 graded the clamp pass-as-shipped. Reversal: drop the clamp and skip the slot at tier 4. |
| T-154 | **Stale fee example in `game/refinery.gd:130`:** `resource_seconds`' doc comment still restates the retired figures ("Gold's 395 reads 40 s"); the formula is live and derives gold's 26 s, but the example lies against 02's 2026-10-08 table (S28-R1, low: comment-only, no behaviour). | [CODE] | `game/refinery.gd:129-130` | CLOSED in S25 (S25-R1/A8: the comment reads the live derivation, git diff is the one comment line, `resource_seconds` unmoved). |
| T-155 | **Gate-log jitter, `[s5-racks]` salvo diagnostic (`tests/test_engine2_weapons.gd:542`):** the cannon-salvo frame list jitters one frame between hermetic gate runs (S28-R1's two runs: `[0,37,73,…]` vs `[0,38,74,…]`), so a whole-log byte-diff false-positives; the `[SUMMARY]` law is unaffected. Pre-existing, surfaced by S28-R1's log diff. | [HARNESS] | `tests/test_engine2_weapons.gd:542` | Fix when the harness is next touched: seed the salvo print or drop it from the run log. Reversal: keep the print as-is. |
| T-156 | **U7's staged row under-dims (S25-R1/F4):** the Expedition row greys only its type label (`contracts_panel.gd:234-236`); STATION_HUB §15.2's row greys the whole row at `text_dim`, the type icon included (`_make_icon` sets no modulate). | [UI] | `ui/station/contracts_panel.gd:234-236,529` | Rider on the next wave that touches the CONTRACTS panel. Reversal: keep the label-only dim. |
| T-157 | **A board row survives its own accept (S25-R1/F5):** the seeded re-roll re-presents an accepted job, so the same contract can be accepted twice within one band and two active records share one id — `contracts_panel.gd:343`'s cancel map then keeps only the last card's button. Filter board rows whose id is already active, or refuse a duplicate id at `accept`. | [CODE] | `ui/station/contracts_panel.gd:343` + `game/contract_registry.gd:625` | Rider on the next wave that owns the CONTRACTS panel (S25-F1 was scoped to HIGH/MED only by the brief and left it). Reversal: keep the re-presented row. |

**2026-10-08 (S28-R1): T-154/T-155 filed; the next free ticket is T-156.**
**2026-10-08 (S25-R1): T-138/T-152/T-154 closed; T-156/T-157 filed; the next free ticket is T-158.**
