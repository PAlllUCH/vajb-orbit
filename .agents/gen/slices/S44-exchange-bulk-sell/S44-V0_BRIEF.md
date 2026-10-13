---
slice: S44
worker: S44-V0
role: coder
status: ready
tier: paid
---

# S44-V0 — the EXCHANGE bulk sell (P53) + T-190's ink

## Context (read in this order, by range)
1. `docs/design/STATION_HUB.md` §23.7 (lines ~2158–2162, verbatim below) and
   §5.8 (the hold rows + clock law), §5.6 (the refusal strip family).
2. `docs/design/UI_SPEC.md` §3.10 A5.1–A5.5 (the composition law; A5.2(iii)'s
   "state by frame + mark"), §16.1 (the ink law).
3. `vajb-orbit/ui/station/exchange_panel.gd` — by grep then range: the hold
   row build (`_make_hold_row` region — grep `HoldRows`), `_quote` (`:1212`),
   the sell path (`grep _on_sell`), the `ConfirmStrip` (`:173`, text at
   `:694-701`), `SELL_WORD`/`SELL_UNITS_CAPTION` (`:121-129`), the foot band
   consts (`:49-53`).
4. `vajb-orbit/ui/station/exchange_panel.tscn` (the TradeBox stack:
   `SellUnitsRow`, `ConfirmStrip` at `:171`; the foot's `ActionsRow`:
   `SellButton` `:217`, `SellAllButton`, `CancelButton`; `HoldCaption` `:62`).
5. `vajb-orbit/game/exchange.gd` — `quote()` (`:305`), `sell()` (`:330`),
   `sell_all()` (`:372`, read-only reference for the idiom — you will NOT call
   `sell_all`; the marked path quotes per stack and sells per stack).

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.7 P53** — "**selection model: checkboxes.** Each hold row
gains a leading **`CheckChip`**, 24×24 flat `Button`: bare 1 px `metal_mid`
frame unchecked; checked = the frame steps to `metal_light` **plus a check mark
drawn in its own child rect** (A5.2(iii) — state by frame + mark, never colour
alone; no font-glyph check, §5.8's tofu finding). The row press keeps its
single-sale arm (`TradeBox`, N49); the chip toggles the **bulk set**. The
`YOUR HOLD` caption band gains a **`MARK ALL` / `CLEAR`** `ActionInline` pair.
`TradeBox` gains the marked read under the `ConfirmStrip` (05 §6's shape):
**`MARKED 3 STACKS — GROSS 8 120 · FEE 162 · YOU GET 7 958`** (sum of
`Exchange.quote` per marked stack at press time — the clock law §5.8, no new
pricing). The foot cluster is **not** re-laid: `SELL` / `SELL ALL RAW` /
`CANCEL` **keep their pinned seats and sizes** (the four-plate cluster drafted
here is dropped pre-land). The stack gains **`SELL MARKED`** (56 px, §5.8's
secondary size) directly beneath `SELL`, selling every marked stack (ore,
components, ingots alike — the owner's "my items") as one confirmed action,
disabled at an empty set (A5.4-2's unavailable idiom). Refusal path §5.6;
`SELL ALL RAW`'s raw-only law stands (05 §6). The **per-row 56 px SELL plate
retires** — single sale arms by row press, bulk by the chips; the per-row
INSPECT chip stands."

**T-190 (rider, cured docs-first)** — the check mark's ink is **`text_primary`**
(the §1 success law's ink) inside the stepped `metal_light` frame.

**The disclosed seat mapping (developer, bucket 1):** D24's pin quotes the
S28-era layout (`SELL` at 88 px inside `TradeBox`); the live tree seats
`SELL`/`SELL ALL RAW`/`CANCEL` in the foot's `ActionsRow` at 360×56
(`exchange_panel.tscn:217-236`) and has no per-row SELL or INSPECT plates
(N37/S31/S35 retired them — the trade column owns one INSPECT toggle). The
law's intent maps to the live tree as: **`SELL MARKED` seats in the foot's
`ActionsRow` between `SELL` and `SELL ALL RAW`** (56 px secondary size,
360 wide like its siblings — 4×360 + 3×16 = 1 488 ≤ 1 765, the §19.3 foot
band); the three existing plates keep their exact seats and sizes; the
per-row plates stay retired (you never resurrect one); the marked read seats
in the `TradeBox` stack under `ConfirmStrip` per the pin's own words.

## Measured facts (cite, do not re-derive)
- Hold rows are built in code under `%HoldRows` (`exchange_panel.tscn:73`);
  the row build and its press arm are the `_make_hold_row` region (grep
  `HoldRows` / `hold_row` in `exchange_panel.gd`).
- The single-sale arm is the trade column's stepper + `SELL` (`_sell_units`,
  `_quoted`, the `SELL` press → the existing sell path with the confirm strip
  `CONFIRM_FORMAT` at `:132` and the refusal family `:149`).
- `Exchange.quote(profile, item_id, qty, now)` returns
  `{unit, gross, fee, paid, …}` (`exchange.gd:305-327`); the marked read sums
  `gross`/`fee`/`paid` per marked stack, quoting each stack's own held qty at
  press time; the market re-evaluates inside `quote` (the one price read, 05 §8).
- A marked sale sells each marked stack through the same per-stack `sell()`
  the single-sale arm uses (all-or-nothing per stack; a refused stack reports
  §5.6's wording and stops — the marked set's own refusal names the stack).
- `YOUR HOLD` is `HoldCaption` (`exchange_panel.tscn:62-66`, already
  `SectionHeader` — T-175's EXCHANGE cure is landed); the caption band gains
  the `MARK ALL` / `CLEAR` pair beside it.
- The pane footer (`PaneFooter`, `:194`) is already `StationCaption` (T-175).
- Gate baseline 1330/0 (2026-10-12).

## Task
Add the CheckChip bulk set, the MARK ALL/CLEAR pair, the marked read, and
SELL MARKED per P53 mapped to the live tree; do not disturb the single-sale
arm or the foot trio. Add the new suite `tests/test_s44_exchange_bulk.gd`.

## Acceptance list
1. Every hold row leads with a `CheckChip`: 24×24 flat `Button`, bare 1 px
   `metal_mid` frame unchecked; checked steps the frame to `metal_light` and
   draws the check mark in its own child rect (code-drawn, `text_primary` ink
   — T-190); state never rides colour alone; no font glyph.
2. The chip toggles the bulk set; the row press keeps the single-sale arm
   unchanged (stepper, quote, confirm strip all as shipped).
3. The `YOUR HOLD` caption band carries `MARK ALL` / `CLEAR` (`ActionInline`
   chips, 32 px row idiom): MARK ALL marks every hold row, CLEAR empties the
   set; both are content-swap-safe (A5.5 — no reflow of the row stack).
4. The `TradeBox` carries the marked read under `ConfirmStrip`, worded
   `MARKED <n> STACKS — GROSS <g> · FEE <f> · YOU GET <p>` (grouped digits like
   the shipped figures), summed from `Exchange.quote` per marked stack at
   press time; an empty set hides the read.
5. `SELL MARKED` (56 px secondary) sits in the foot's `ActionsRow` between
   `SELL` and `SELL ALL RAW`; disabled at an empty set; the three existing
   plates keep their pinned seats and sizes (a diff proves no foot re-lay).
6. SELL MARKED sells every marked stack through the shipped per-stack `sell()`
   path — ore, components, ingots alike; a refused stack reports §5.6's
   wording on the footer strip and the run stops; successes log through the
   shipped seams.
7. The per-row SELL/INSPECT plates stay retired (none returns); the INSPECT
   toggle keeps its seat.
8. New suite `tests/test_s44_exchange_bulk.gd` pins items 1–6 (at least one
   row each); the report answers every item with a cite.

## Hard constraints
- **The 5-minute failsafe (the S43 process law):** every shell command you run must be
  bounded — run anything that can take longer than a minute as `timeout 280 <command>
  > /tmp/<log>.txt 2>&1; tail -n 40 /tmp/<log>.txt` and read the log; **never** wait on a
  background job, never use a background-run feature; poll the log file with short sleeps.
  If any single wait exceeds five minutes, stop, write the report with what is done, and
  say so.
- File set: `vajb-orbit/ui/station/exchange_panel.gd`,
  `vajb-orbit/ui/station/exchange_panel.tscn`,
  `vajb-orbit/tests/test_s44_exchange_bulk.gd`. `game/exchange.gd` is
  **read-only** (a read seam change would move §8's pinned signatures — if you
  find the marked path cannot ship without one, report it and stop).
  Do not touch the theme, other panels, docs.
- No new hex; no new tokens; A5.1–A5.5 composition; the check mark's `_draw`
  lives in its own child rect (the `Chevron` class in
  `overview_panel.gd:429-435` is the exemplar idiom).
- No dialogs: a bulk sale is not an A4 door; its verification is the marked
  read + the shipped refusal strip.
- Shell edits forbidden; every Godot run bounded (`--quit-after`); probes
  self-quit; never leave a command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S44-exchange-bulk-sell/S44-V0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the three files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/exchange_panel.gd,vajb-orbit/ui/station/exchange_panel.tscn,vajb-orbit/tests/test_s44_exchange_bulk.gd" crush run "You are worker S44-V0. Read .agents/gen/slices/S44-exchange-bulk-sell/S44-V0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
