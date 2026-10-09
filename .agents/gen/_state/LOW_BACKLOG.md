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

**Tickets:** new items take the next global `T-###` (next free **T-164**) and
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
| T-156 | **U7's staged row under-dims (S25-R1/F4):** the Expedition row greys only its type label (`contracts_panel.gd:234-236`); STATION_HUB §15.2's row greys the whole row at `text_dim`, the type icon included (`_make_icon` sets no modulate). | [UI] | `ui/station/contracts_panel.gd:234-236,529` | CLOSED in S38 (S38-R1/A5: the staged row's inner box is dimmed whole at `_apply_tokens` (`contracts_panel.gd:672-686`), the type icon descending under it, `_dim_rows` at `:155`; re-measured by suite row and by R1's own probe, with the live rows' `Color.WHITE` as the negative control). Reversal: keep the label-only dim. |
| T-157 | **A board row survives its own accept (S25-R1/F5):** the seeded re-roll re-presents an accepted job, so the same contract can be accepted twice within one band and two active records share one id — `contracts_panel.gd:343`'s cancel map then keeps only the last card's button. Filter board rows whose id is already active, or refuse a duplicate id at `accept`. | [CODE] | `ui/station/contracts_panel.gd:343` + `game/contract_registry.gd:625` | CLOSED in S38 (S38-R1/A5: `_without_active` (`contracts_panel.gd:496-509`) filters accepted ids at `_refresh`, and the panel's `accept` door refuses a second attempt with `REASON_UNKNOWN` (`:406`); measured accept → rows 6→5, second `accept(id)` `ok=false`, `active=1`). `game/contract_registry.gd` was left byte-identical, so §26's pinned signature stands. Reversal: keep the re-presented row. |
| T-158 | **The shipped S38 probe's countdown window is too tight (S38-R1/F2):** `probe_s38_start_board.gd:30,144-146` waits 1.2 s over a 1.0 s tick — 0.2 s of slack — so one slow frame flips the read to `moved=false` (R1's run 1 did exactly that while its nine-sample probe showed the readout live at every sample). Harness only; the shipped readout is correct. | [HARNESS] | `tests/probe_s38_start_board.gd:30,144-146` | Fix when the probe is next touched: widen `TICK_WAIT` to ≥2.2 s or take three reads and require two to differ. Reversal: keep the 1.2 s window. |
| T-159 | **`world_clock.gd`'s header contradicts the shipped display ticks (S38-R1/F3):** the header still claims "there are no per-consumer Timers, ever" (`autoload/world_clock.gd:6`) while two consumers now own 1 Hz display-tick timers (`ui/station/refinery_panel.gd:250`, `ui/station/contracts_panel.gd:518`). Comment-only: 14's S38 block pins the tick idiom, so the spec is not in tension — only the header is. | [DOC] | `autoload/world_clock.gd:6` | Fix when that file is next touched: scope the sentence to band evaluation (the clock itself still owns no Timer). Reversal: keep the sentence. |
| T-160 | **The board drew no rows on the real screen (the owner's playtest, 2026-10-09):** "there are no contracts available, even when they refresh". The board was rolled and live (six rows, the countdown counting) but the shell's service host mounted each service pane into a `VBoxContainer` without a vertical size flag, so the CONTRACTS pane answered its own 173 px minimum and its board `ScrollContainer` collapsed to the **2 px** minimum — a header, a note and no rows. The same collapse hid the `MODULE OFFLINE` INSURANCE/VAULTS placeholders. Every existing test read the board's data, and the harness runs a whole suite in one frame, so no row could see a layout. | [UI] | `ui/screens/station.gd` (`_build_services`) | CLOSED 2026-10-09 (owner playtest fix, gate 1236 → 1237/0): `content.size_flags_vertical = Control.SIZE_EXPAND_FILL` on every service pane (`station.gd:1164`), measured off a rendered 1920×1080 frame — board 568 px, scroll 397 px, five rows drawn plus the sixth on scroll; pinned by `test_a7_the_services_host_expands_every_pane`; recorded in `docs/CONTRACTS.md` §10 **v0.52**. Reversal: drop the flag. |
| T-161 | **STATION_HUB §15.3's premium rows predate M14 (S26-R1/F6):** the deck law still pins the six rows "verbatim from the §3 table (Fighter 200 … Destroyer 700)" while S26's implementation charges M14's 1.5 %-of-list re-derivation (135–1 080) — the shipped INSURANCE panel prices M14 (the only coherent reading), so the deck doc and the panel disagree on the numbers. [DOC] `docs/design/STATION_HUB.md` §15.3 premium-rows row | Fix when STATION_HUB is next touched: re-cut the row to M14's figures with the S28 block as the cite (and note the per-row keying, D5). Reversal: keep the flats. |
| T-162 | **The OVERVIEW vault row disagrees with the VAULTS panel at tier 0 (S26-B1/D8):** `overview_panel.gd:74` carries `VAULT_BASE_CAPACITY := 40` against 14 §4's 20-unit base, so a tier-0 station reads 40 on OVERVIEW and 20 on VAULTS (Meridian: 40 is right only there). S24's own PROPOSED reading, its comment admits the reversal; S24 is read-only. [CODE] `ui/station/overview_panel.gd:74` | Fix when the overview panel is next touched: read the base off the station's faction (20, Meridian 40) the way `vault_capacity` does. Reversal: keep the flat 40. |
| T-163 | **The arena props are absent from the generated catalog (S26-B1 follow-up):** `env_arena_nav_pylon`/`env_arena_barricade` ship under `assets/env/prop/` and render in the arena rings (`npc_registry.gd` `PYLON_TEXTURE`/`BARRICADE_TEXTURE`), but `ASSET_CATALOG.md` carries no row for either, so the catalog under-describes the shipped tree. [DOC] `docs/design/ASSET_CATALOG.md` | Fix at the next catalog regeneration that touches `assets/env/`: re-run `staging/phase_d/build_catalog.py` and check the two rows appear. Reversal: none (generated file). |

**2026-10-08 (S28-R1): T-154/T-155 filed; the next free ticket is T-156.**
**2026-10-08 (S25-R1): T-138/T-152/T-154 closed; T-156/T-157 filed; the next free ticket is T-158.**
**2026-10-08 (S38-R1): T-156/T-157 closed; T-158/T-159 filed; the next free ticket is T-160.**
**2026-10-10 (S26-R1): T-161/T-162/T-163 filed; the next free ticket is T-164.**
