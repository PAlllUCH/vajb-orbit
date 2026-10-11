# S41 — the composition pass (wave brief)

**Wave:** S41 (code lane; implements the design audit **D23**).
**Slice folder:** `.agents/gen/slices/S41-composition/`
**Source:** `.agents/gen/slices/D23-panel-audit/D23-R1_audit.md` (D23-R1, a visual /
UI designer audit of the station panels, `hyper/glm-5.3-flash` @ high, **visual
mode** — all ten 1920×1080 renders viewed and every finding source-verified).
**Owner go (2026-10-11, verbatim):** "go with all fixes possible, when you finish
update all docs."
**Baseline:** the gate after S27's close — **1300/0**;
`python3 staging/verify_wave.py snapshot --name s41_start` before the first
dispatch.

## 1. The law to read, in order

1. `slices/D23-panel-audit/D23-R1_audit.md` — the audit. Its per-deck section
   (§A1) explains *why* each fix is wanted; read it, do not just skim the table.
2. `docs/design/UI_SPEC.md` — **§3.10 Amendment 5 (A5.1–A5.3)** in full: the
   owner ruling of 2026-09-26 is **containers and relative positioning, never
   coordinates**; a surface's chrome is a theme stylebox or a sibling node,
   **never a `_draw` pass over content**; chrome is picked by the asset's own cut
   size. Then **§8 P1/P2** (the action-cluster pin), **§16** (the S40 legibility
   pass) and **§19.3** (the shell's measured skeleton) by range.
3. `docs/design/STYLE_BIBLE.md` — palette and tone; `docs/design/STATION_HUB.md`
   §19–§21 — the shell contract.
4. `docs/design/MENU_FLOW.md` — the deck inventory.
5. The files in your own set (below).

**The layout law, restated because four findings touch it:** a panel's layout is
containers + anchors + `custom_minimum_size` + size flags. **Never** position a
child by writing `position`/`offset_*` in code, and never give a *visual* box a
layout-filler size flag — that is the T-160 defect (a visual box that stretched
to 384 px because it carried `size_flags_vertical = 3`). A visual element must
hug its content.

**The token law:** every hex colour literal in the station UI lives in
`vajb-orbit/tools/build_theme.gd`. A panel that hard-codes a colour is a defect.
A new or changed colour is written **once** in `build_theme.gd`, regenerated into
`ui/theme/vajb_theme.tres`, and marked **PROPOSED** with its reversal in the
report (the owner ratifies shared-chrome tones; see TICKS).

## 2. The findings (all 16, verbatim intent — the tiers are the audit's)

| ID | Tier | Site | The fix |
|---|---|---|---|
| **F1** | **HIGH** | `ui/station/overview_panel.tscn:34`, `overview_panel.gd:330-336` | The OVERVIEW pane's identity block repeats the shell header's name plate ~200 px below it, and the stack overruns the pane so the services block is cut after CONTRACTS: **INSURANCE and VAULTS are below the fold with no visible scroll cue.** Shorten the identity block by one line and/or give the services stack a bottom `size_flags_vertical = 3` spacer so all three rows sit flush at the fold. The pane's navigation promise (P26) must be visible without scrolling. |
| **F2** | MED | `ui/station/armory_panel.tscn:108` | `FitLeftBox` carries `size_flags_vertical = 0`, so the roofed box hugs the grid + CELL INFO at the top and the lower half of the left sector is raw BG-1. Set `FitLeftBox` `size_flags_vertical = 3` (`CellInfoBlock` already v=3 and absorbs the slack). Containers only, no geometry number moves. |
| **F3** | MED | `ui/station/armory_panel.gd:158-159, 3890` | In battery mode the list wears the browser's shared band `[STATE, COST]` while its rows print `FITTED` / `OWNED ×n` (`READ_FITTED` `:331`, `OWNED_FORMAT` `:328`). Build the battery band as `STATE` / `HELD` (a new const beside `BAND_COST`); the band builder already takes the pair as an argument. |
| **F4** | LOW | `ui/station/armory_panel.gd:115, 164` | Two caption-only empty plates at the battery fold (`EMPTY CELLS - 0`, the `PANE_HINT_BATTERY` block) read as unfinished panels. Collapse each to its caption line height (`custom_minimum_size.y = 22`, the empty-cell line's own size). Hide nothing (A5.5). |
| **F5** | MED | `ui/station/refinery_panel.gd:442` | Held ore and loaded input ore are appended to one undivided VBox, so two different states read as one list (only the `LOADED` tag at `:424` distinguishes). Insert one `SectionHeader` row (`IN INPUT`) before the first loaded row — colour must not be the only channel, so keep the tag too. |
| **F6** | LOW | `ui/station/exchange_panel.tscn` (SALE column) | ~450 px of dead backdrop under the quote line. Move the footer hint into the SALE column's lower half as a `FlavourText` block, or let the quote strip `size_flags_vertical = 3` so the readout centres in the column. |
| **F7** | MED | `tools/build_theme.gd:317, 342` | Disabled = a borderless `metal_dark` plate with `text_dim` ink, so a disabled control is indistinguishable from absent (the refinery `−`/`+` steppers and QUEUE row nearly vanish). Give the disabled stylebox a 1 px `metal_mid` border (one line in the `_flat()` call). Do **not** change the disabled ink — that is S40's A1 territory. |
| **F8** | MED | `ui/station/auction_panel.tscn:59` | With ALL selected, the fold lands exactly after the MODULES caption + band, orphaning a header with zero rows. Move the shelf section captions (HULLS / MODULES) into fixed chrome above `AuctionScroll` — the armory's `FITS W1 - W9` pattern — so the fold can only cut rows, never a header. |
| **F9** | MED | `tools/build_theme.gd:415-416` | The themed scrollbar's track/grabber do not read at 1080p on **any** deck, yet OVERVIEW, AUCTION and the armory browser all scroll. Grabber `metal_light` → `text_meta`, track gains a 1 px `metal_dark` border, minimum grabber height 48 px. Theme-only; every deck benefits. |
| **F10** | LOW | `ui/station/shipyard_panel.gd` / `.tscn` (preview fit) | A ~150 px sprite centred in a ~560×430 frame — the void dwarfs the subject. Scale the preview to a fixed fraction of `PreviewFrame` (`custom_minimum_size` ≈ 60 % of the box, `STRETCH_KEEP_ASPECT_CENTERED`) so the hull owns the frame. |
| **F11** | LOW | `ui/station/launch_panel.tscn:153`, `launch_panel.gd:155, 157` | Three competing caption sources in the foot region: the pane footer, the brief note, and the live confirm line. Move `BRIEF_NOTE` into the briefing column's last row (it is cargo commentary, not foot-band text) and keep the foot band to footer + confirm line. |
| **F12** | LOW | `ui/screens/station.gd:123, 1176` | `ONE SERVICE AT A TIME · ESC BACK` renders twice on the SERVICES deck — the shell's `SERVICES_HINT` (`station.gd:123`, written at `:1176`) duplicates the pane's own `%PaneHint` (`contracts_panel.tscn:121`). **Delete the shell's hint** so the words have one source. |
| **F13** | MED | `ui/station/contracts_panel.gd:320-375` | The active card stacks head + escrow lines + the `CANCEL - 100 CR FEE` chip into one `ROW_HEIGHT` card, so the chip crowds the reward figure. Widen active cards to two stack rows (head + one action row carrying the escrow summary with CANCEL right-aligned). Container children only. |
| **F14** | MED | `ui/station/refinery_panel.tscn` action block; `ui/station/armory_panel.gd` actions | Three action geographies on one screen. The shell pins the cluster right-aligned in the foot band at **360×56** (UI_SPEC §8 P1, §19.3). REFINERY: move QUEUE / LOAD / COLLECT into the pane foot cluster (P1 sizes, `REFINE N` primary rightmost). ARMORY: same foot-band home on both modes. EXCHANGE already complies — use it as the exemplar. |
| **F15** | LOW | `ui/station/shipyard_panel.tscn:73-99`, `contracts_panel.tscn` tabs | The shipyard's large HANGAR/BUILD/QUEUE/SCRAP plates and the services' full-width segment tabs share no visual DNA with the chip family (no shared height, corner or ink treatment). Give them the chip row's height (32) and ink treatment; **keep the counts** — mode vs filter vs service are different semantics. |
| **F16** | LOW | `ui/components/tooltip.gd:117-127` | The hover tooltip can cover the pane header band (163 px) when a top row is hovered. In `_place`, flip below the cursor when `pos.y < 163` before the viewport clamp. |

### 2.1 The rider this wave also clears (T-177)

**T-177** (open since S40) is "`build_theme.gd` writes a uid-less theme". Its
stated fix point is *the next theme touch* — **this wave is that touch**, so it
rides W1: make the generator preserve the committed `.tres`'s `uid://` lines (the
theme's own and all 18 `ext_resource` uids) instead of writing a fresh
`Theme.new()`. Acceptance: after the change, running the generator against the
committed file produces a **no-op diff** (`git diff --stat` empty) when no token
changed, and only the intended lines when one did. Reversal: go back to editing
the `.tres` in place by hand (the S37/S40 precedent).

## 3. Worker table

| ID | Role | `VAJB_WORKER_FILES` | Findings |
|---|---|---|---|
| S41-B1 | builder (theme + shell) | `vajb-orbit/tools/build_theme.gd, vajb-orbit/ui/theme/vajb_theme.tres, vajb-orbit/ui/screens/station.gd, vajb-orbit/ui/components/tooltip.gd, vajb-orbit/tests/test_s41_shell.gd, .agents/gen/slices/S41-composition/S41-B1_report.md` | F7, F9, F12, F16, **T-177** |
| S41-B2 | builder (overview + exchange + auction) | `vajb-orbit/ui/station/overview_panel.tscn, vajb-orbit/ui/station/overview_panel.gd, vajb-orbit/ui/station/exchange_panel.tscn, vajb-orbit/ui/station/auction_panel.tscn, vajb-orbit/tests/test_s41_panels_a.gd, .agents/gen/slices/S41-composition/S41-B2_report.md` | F1, F6, F8 |
| S41-B3 | builder (armory) | `vajb-orbit/ui/station/armory_panel.tscn, vajb-orbit/ui/station/armory_panel.gd, vajb-orbit/ui/station/armory_style.gd, vajb-orbit/tests/test_s41_armory.gd, .agents/gen/slices/S41-composition/S41-B3_report.md` | F2, F3, F4, F14 (armory) |
| S41-B4 | builder (refinery + launch + contracts + shipyard) | `vajb-orbit/ui/station/refinery_panel.tscn, vajb-orbit/ui/station/refinery_panel.gd, vajb-orbit/ui/station/launch_panel.tscn, vajb-orbit/ui/station/launch_panel.gd, vajb-orbit/ui/station/contracts_panel.tscn, vajb-orbit/ui/station/contracts_panel.gd, vajb-orbit/ui/station/shipyard_panel.tscn, vajb-orbit/ui/station/shipyard_panel.gd, vajb-orbit/tests/test_s41_panels_b.gd, .agents/gen/slices/S41-composition/S41-B4_report.md` | F5, F10, F11, F13, F14 (refinery), F15 |
| S41-R1 | reviewer (code + visual) | `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S41-composition/S41-R1_review.md` | grade all 16 + T-177 |
| S41-F1 | fixer (only on HIGH/MED) | every builder's set + `vajb-orbit/tests/, docs/CONTRACTS.md, .agents/gen/slices/S41-composition/` | the review's HIGH/MED |

Read-only throughout: `docs/`, `vajb-orbit/game/`, `vajb-orbit/autoload/`,
`vajb-orbit/tests/` for B1–B4 (a builder never edits another builder's suite).

**File-set note (S27's lesson):** a builder's set must cover every file its own
findings reach. If a fix needs a file outside your set, **stop and report it** —
do not edit it. F14 spans B3 and B4; each edits only its own panel.

## 4. Acceptance list (the report answers each with a cite)

- **A1** — each of the 16 findings is either fixed at its named site with a cite,
  or reported NOT DONE with the reason. No finding may be silently dropped.
- **A2** — no fix writes `position`/`offset_*` on a child from code, and no visual
  box carries a layout-filler size flag. Any `size_flags_vertical = 3` you add is
  on a container that owns the slack (name the node in the report).
- **A3** — every colour you add or change is written once in `build_theme.gd` and
  regenerated; the new/changed token is tabled **PROPOSED** with its reversal.
- **A4** — F1's fix is proved: on the fixed tree the OVERVIEW pane's three service
  rows (CONTRACTS, INSURANCE, VAULTS) are all inside the pane's content box
  unscrolled. Prove it with a layout assertion (a row's `global_position.y +
  size.y` inside the pane's content rect), not a pixel guess.
- **A5** — F14 is proved against the pin: the moved clusters use §8 P1's `360×56`
  primary/secondary sizes in the pane foot band on the same anchor EXCHANGE uses.
- **A6** — T-177's no-op-diff proof (W1).
- **A7** — your suite's new rows are load-bearing: name, for each, the assertion
  that would fail if the fix were reverted. Watch the silent-abort false-green
  class — read a variable with `get()`, never `call()`; an `await` must fire.
- **A8** — no gate row outside §6's list moved.

## 5. Hard rules

- Docs read-only (`--forbidden` at verify: `vajb-orbit/project.godot`,
  `vajb-orbit/addons/`; `docs/CONTRACTS.md` is the reviewer's to update only).
- **Do not run `staging/` scripts**, do not touch `vajb-orbit/game/`, and never
  edit `vajb-orbit/addons/`.
- **`vajb_theme.tres` is generated.** Until T-177's fix lands (W1, in this wave),
  a plain generator run writes a uid-less file — so **W1 fixes T-177 first, then
  regenerates**, and every other worker must **not** run the generator at all.
- Bounded runs; scratch `XDG_DATA_HOME`; no shell edits; Layer Cake (signals up,
  calls down).
- A number the audit does not supply is **PROPOSED** in the report with its
  reasoning and reversal — never silently chosen.

## 6. Run order + the tests that move

**B1 ‖ B2 ‖ B3 ‖ B4 (parallel — disjoint file sets) → R1 → F1 only on HIGH/MED.**
Expected gate growth: **+ the three new suites' rows only**.

| Suite | Why | Verdict |
|---|---|---|
| `test_s40_legibility.gd` | F7 touches the disabled stylebox, F9 the scrollbar | **unchanged** — neither is the caption token S40 pinned; if a row moves, report it |
| `test_ui_slot_layout.gd`, `test_s18_armory_rework.gd`, `test_s32_armory_modes.gd`, `test_d7_armory.gd`, `test_p2b_fitting_panel.gd` | B3's armory layout changes | **unchanged** (the fixes are additive flags/bands); a moved row is a bucket-2 pause |
| `test_p2b_services.gd`, `test_s25_contracts.gd` | B4's contracts card + services hint | **unchanged** |
| `test_s27_catalog.gd` | B4's shipyard views | **unchanged** |
| `test_d7_status.gd`, `test_d7_cockpit.gd`, `test_p2b1_outfitting_panel.gd` | the shell/panels this wave touches | **unchanged** |

Any *other* count moving is a **bucket-2 pause**: report it, leave it, stop.
The reviewer re-derives every moved row against §1's law, never against a
builder's stated value.

## 7. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts; only T-155's salvo
   jitter may differ).
2. `python3 staging/verify_wave.py verify --baseline s41_start --forbidden
   vajb-orbit/project.godot vajb-orbit/addons/ --expect-reports <the four
   builder reports + the review>`.
3. **Re-render and re-audit visually:** run
   `"$GODOT_CONSOLE" --path "$VAJB_PROJ" res://tests/probe_s40_panes.tscn
   --quit-after 3000`, and have R1 (or a short D24 pass) compare the new renders
   against the D23 findings — a layout fix that cannot be seen is not done.
4. `python3 staging/build_code_map.py`; CONTRACTS §9 + §10 if the reviewer wrote
   them; WAVEBOARD + `dispatch_coder.md`; `MASTER_REPORT.md` §6 recap; TICKS
   (the PROPOSED tokens); LOW_BACKLOG (the D23 findings are closed as tickets —
   file them at the next free ids and close them in the same row); the
   wave-boundary commit.
