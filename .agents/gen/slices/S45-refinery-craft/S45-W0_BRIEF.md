---
slice: S45
worker: S45-W0
role: coder
status: ready
tier: paid
---

# S45-W0 — the CRAFT tab: the crafting model + the craft list (P52, R12, C1–C10)

**Dispatched only after S45-V0's report landed** — one shared file (`refinery_panel.gd`), never parallel.

## Context (read in this order, by range)
1. `docs/gameplay/07_crafting.md` §6 (lines ~67–121, verbatim below) — the
   whole crafting economy you implement; §1–§5 stand.
2. `docs/design/STATION_HUB.md` §23.6 (P52, verbatim below) and §23.5 (the
   mode pair V0 landed).
3. `docs/design/UI_SPEC.md` §17 A4 door (8) + A6's material wording, §3.10
   A5.1–A5.5, §16.1; §12.3 (the N28 sheet your row press opens).
4. `vajb-orbit/ui/station/refinery_panel.gd` — V0's landed tree (the mode
   pair, the empty CRAFT body); `vajb-orbit/ui/station/auction_panel.gd` —
   the AUCTION list idiom your rows wear (P40's column-header band + N45 trim,
   rows `Button` + container children; grep `_make_row`/`shelf`).
5. The sheet seam: `sheet_requested` payload shape (the exchange's
   `exchange_panel.gd` INSPECT path and `station.gd`'s `_on_panel_sheet` —
   grep both) — the recipe's full bill renders through it.
6. The confirm seam contract (the S43 brief's disclosed reading, verbatim
   there; `contracts_panel.gd:426-435` + `station.gd:568-599`).

## Spec extract (the pinned law, verbatim)

**STATION_HUB §23.6 P52** — "**CRAFT mode's body is one AUCTION-idiom list**
(P40's column-header band + N45 trim law; rows are `Button` + container
children): columns **`RECIPE · INPUTS · FEE · STATE`**; one row per recipe
(07 §6's four): the output name + its stat line, the inputs as `<n>× <name>`
runs with the family glyph 24 at its own cut, the fee `<n> CR LABOUR`, and a
per-row state chip **`READY` / `MISSING <n>× <input>`** computed from
`cargo_qty` (read-only seam, no price recomputed). The row press opens the
**N28 sheet** (the recipe's full bill, read-only); the per-row `CRAFT` chip is
the commit — through UI_SPEC §17's confirm door. Foot band kept (P28
uniformity), no cluster; hint **`EVERY INPUT IS CONSUMED ON CRAFT · THE FEE IS
LABOUR`**. Empty state: `NOTHING TO CRAFT` caption (§19.4's idiom)."

**07 §6 C1–C10 (the binding rows; the recipe table is §6.2's, the derivation
§6.3's)** — "**C2** Recipes are data: one static table
`game/crafting_catalog.gd`, same style contract as 02 §3 / 03 §4 (a `const`
array of dictionaries: `id`, `name`, `inputs` (id→count), `fee`, `output`
(module id + effect), `description`). No price, fee or effect is ever computed
in panel code. **C4** `fee = ceil(0.35 × output list value)` rounded up to the
nearest 100; every fee ≥ 2 000 CR; the four fees land at 2 500 / 3 000 /
2 800 / 4 000. **C5** materials derive from the baselines — the panel
displays inputs as counts, never as CR. **C6** outputs are modules in 09's
families (REACTOR MK3 `+4 power output` · SHIELD LATTICE `+500 pool · regen
10/s` · RAIL REFIT `kinetic weapons +25 % damage` — unique · DEEP SCANNER
ARRAY `+45 % scanner range`). **C7** direct upgrades. **C8** reverse crafting
at 50 % of recipe materials (round down). **C9** four crafted-only items in
v1, none gate content. **C10** the `CRAFT` commit routes through UI_SPEC §17's
confirm door (`…CRAFT <NAME> FOR <BILL> + <FEE> CR LABOUR?`); the per-row
availability chip reads `cargo_qty`; refusal path STATION_HUB §5.6."

## The craft transaction (the one model addition, derived from the law)
- The commit consumes every `inputs` entry from the hold (`cargo_qty`), pays
  the fee from credits, and grants the output module to the player's module
  bag through the shipped acquisition seam the armory's own buys use (grep
  `add_module`/module grant in `game/player_profile` — the one seam; never a
  bespoke inventory write).
- All-or-nothing per confirmed craft (01 §7's law); refusal §5.6's strip with
  the missing input named (`MISSING 2× COBALT INGOT`).
- C8's reverse craft ships as the catalog's `scrap_value(recipe)` derivation
  (50 % of recipe materials, round down) — the UI door for it is **staged**
  (P52's surface carries no scrap control this wave); the derivation ships so
  the law is code, not prose.

## Acceptance list
1. `game/crafting_catalog.gd` exists: a `const` table of the four §6.2 recipes
   (`id`, `name`, `inputs` id→count, `fee`, `output` module id + effect,
   `description`), fees exactly 2 500 / 3 000 / 2 800 / 4 000, inputs exactly
   §6.3's ids and counts; no price is computed in any panel.
2. The CRAFT list wears the AUCTION idiom: the `RECIPE · INPUTS · FEE · STATE`
   column-header band, one `Button` row per recipe with the output name + stat
   line, the `<n>× <name>` input runs (family glyph 24 at its own cut), the
   fee as `<n> CR LABOUR`, and the per-row state chip `READY` /
   `MISSING <n>× <input>` computed from `cargo_qty`.
3. The row press opens the N28 sheet with the recipe's full bill (read-only);
   the sheet payload flows through the shipped `sheet_requested` seam.
4. The per-row `CRAFT` chip opens the confirm dialog through the shell seam:
   title `CONFIRM PURCHASE`, body `ARE YOU SURE YOU WANT TO CRAFT <NAME> FOR
   <BILL> + <FEE> CR LABOUR?` (`<BILL>` the `60× TUNGSTEN ORE · 35× COBALT ORE`
   run idiom); OK runs the transaction unchanged (which can still refuse).
5. The transaction consumes every input, pays the fee, grants the output
   module through the shipped acquisition seam, all-or-nothing; refusal
   §5.6's strip naming the missing input.
6. C8's scrap derivation ships in the catalog (`scrap_value`, 50 % of recipe
   materials rounded down) with a suite row proving it; no UI door this wave.
7. The CRAFT body's hint reads `EVERY INPUT IS CONSUMED ON CRAFT · THE FEE IS
   LABOUR`; the `NOTHING TO CRAFT` empty state renders when the catalog is
   unreachable (it cannot be in practice — the row pins the idiom).
8. The suite `tests/test_s45_craft.gd` pins items 1–6 (at least one row each;
   the fee/derivation rows read the live catalog); the report answers every
   item with a cite.

## Hard constraints
- **The 5-minute failsafe (the S43 process law):** every shell command you run must be
  bounded — run anything that can take longer than a minute as `timeout 280 <command>
  > /tmp/<log>.txt 2>&1; tail -n 40 /tmp/<log>.txt` and read the log; **never** wait on a
  background job, never use a background-run feature; poll the log file with short sleeps.
  If any single wait exceeds five minutes, stop, write the report with what is done, and
  say so.
- File set: `vajb-orbit/ui/station/refinery_panel.gd`,
  `vajb-orbit/ui/station/refinery_panel.tscn`,
  `vajb-orbit/game/crafting_catalog.gd`, `vajb-orbit/tests/test_s45_craft.gd`.
  Do not touch `game/refinery.gd` (V0's rows are settled), other panels, docs,
  the theme.
- No new hex; no new tokens; the fee/derivation numbers are the pinned C3–C5
  values — a number you believe wrong is reported, never changed.
- A5.1–A5.5 composition; every run bounded; probes self-quit; never leave a
  command in the background.
- Gate: `python3 staging/gate.py --times 1` for your own check; record
  before/after `[SUMMARY]`.

## Output contract
- Report: `.agents/gen/slices/S45-refinery-craft/S45-W0_report.md` (≤120
  lines, from `_templates/REPORT.md`).
- Deliverable: the four files above.

## Paste block
```bash
VAJB_SLIM=1 VAJB_WORKER_FILES="vajb-orbit/ui/station/refinery_panel.gd,vajb-orbit/ui/station/refinery_panel.tscn,vajb-orbit/game/crafting_catalog.gd,vajb-orbit/tests/test_s45_craft.gd" crush run "You are worker S45-W0. Read .agents/gen/slices/S45-refinery-craft/S45-W0_BRIEF.md end to end and execute it exactly." -m hyper/glm-5.3-flash --reasoning-effort max --cwd "$VAJB_WORKSPACE"
```
