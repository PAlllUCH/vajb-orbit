# D19 — Station shell v2 (wave brief)

**Wave:** D19 (design lane, item 19 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D19-station-shell-v2/`
**Baseline:** gate 1074/0 (S29 + F2 hotfix close); `python3 staging/verify_wave.py
snapshot --name d19_start` before the first dispatch.
**Owner go (2026-10-03):** the shell-v2 ruling quoted in §2, routed "heavy design
work → xiaomi/mimo 2.6 pro … review on glm5.3-flash … run everything on max
possible reasoning", grimdark-but-smooth tone, kie.ai art budget open for this
wave. Nothing heavier than these three models runs without asking first.

## 1. The law to read, in order
1. `slices/D19-station-shell-v2/SLICE.md` — scope, file sets.
2. `docs/design/UI_SPEC.md` §11 (the owner's words, A5.5, N24–N30) + §3.10
   Amendment 5 (A5.1–A5.4) + §5.1/§5.2 (the tooltip and modal idioms N27/N28
   instantiate) + §8 (P1/P2 button tokens).
3. `docs/design/STATION_HUB.md` §18 (supersession ledger, P15–P21, art budget)
   + §2 (navigation model) + §3.1 (the measured-grid table idiom) + §15 (the
   identity treatment OVERVIEW reuses) + §16/§17 (what supersedes what).
4. The §5 spec extract below.

## 2. The owner's request (verbatim, 2026-10-03)
> "the containers dont sit in the same place when hovering between different
> sections. First the select menu where i select 'auction' 'refinery' etc has to
> be gone but only the visual aspect, not the functionality. i want it to slide
> from left of the screen when you press a Menu button (come up with something)
> and also i want new pane: space station overwiew (where you will be able to
> press on shipyard on move to shipyard instead of using menu) Lets remove the
> bottom panel with description it occupies way too much space. instead of it
> lets make a popup when you hover on something? or add 'inspect' button. if we
> inspect a module make a screen popup as well, it was bo be responsive menu."

> "i want the screen to look grimdarky but operate smoothly. if new sprites are
> needed then there are credits on kie.ai to use"

Tick answers the same day: descriptions = **both** hover tooltip + INSPECT
modal; OVERVIEW = tiles + identity + ship + services + **all five**; landing
pane on dock = **OVERVIEW**; button name = **TERMINAL**; instability = **both**
(cross-pane misalignment and hover-induced movement).

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the inspector band's nodes and pinned height | `ui/screens/station.tscn:214`, `station.gd:150-151,273-301` |
| the hover→describe chain every pane publishes on | `station.gd:518-540`, `tests/test_s11_inspector.gd:140-233` |
| the hover-induced movement: `HoverStatBlock` in-flow Label, visibility-toggled + rewrapped per cell hover | `ui/station/shipyard_panel.gd:703-733` (fitting twin shares the formatter) |
| cross-pane drift: per-scene `custom_minimum_size` counts 1–10, zero `offset_` placements | `ui/station/*.tscn` census 2026-10-03 |
| the rail's measured width the drawer reuses | `STATION_HUB.md` §3.1 (`ModuleRail` 360 px) |
| rail nav functionality to preserve | `STATION_HUB.md` §2 (`PageUp`/`PageDown`, pad shoulders) |
| the ESC one-operation precedent | `game.gd:951` (S29-F1) |
| auction filter-tab idiom the tiles/browser inherit | `ui/station/auction_panel.gd:82-100` |

## 4. Pinned interface + rules
`UI_SPEC.md` §11 (N24–N30) and `STATION_HUB.md` §18 (P15–P21) are law and are
quoted nowhere here — read them at the source. Rules that fix ambiguity:

1. **A5.5 binds every line of the detail**: hover/focus/selection may change
   colour, `modulate` and `_draw` and nothing else. Any hover-revealed content is
   either in the popup layer (N27/N28) or in one fixed reserved slot whose height
   the detail states explicitly.
2. **The detail invents no decision** — where N24–N30/P15–P21 already fix a
   value, the detail restates it with its tick id; where the detail must choose
   (responsive breakpoints, popup clamp margins, tile internals, focus order),
   the value ships **PROPOSED** with a reversal and a fresh tick id (N31+/P22+
   continuing each series).
3. **Popups are responsive** (the owner's word): size-to-content within their
   min/max, clamped to the viewport at every window size the `canvas_items`
   stretch produces; state the clamp rule.
4. **Grimdark, smooth** (N29): Tokens only; motion ≤ 0.2 s `TRANS_CUBIC`
   `EASE_OUT`, overlays only. A worker who wants a flourish writes it as a
   PROPOSED row, never into the wireframe as settled.
5. **Reports and docs cite `file:line` or tick id**; no pasted source.

## 5. Spec extract (verbatim) + acceptance list
`UI_SPEC.md` §11 (owner's words, first block):
> "the containers dont sit in the same place when hovering between different
> sections… the select menu… has to be gone but only the visual aspect, not the
> functionality. i want it to slide from left of the screen when you press a Menu
> button… new pane: space station overwiew… Lets remove the bottom panel with
> description… make a popup when you hover on something? or add 'inspect'
> button. if we inspect a module make a screen popup as well, it was bo be
> responsive menu."

`STATION_HUB.md` §18 (supersession block):
> "P7 is amended… the `ModuleRail` dies entirely… P7's one-panel-template half
> stands and is extended to every pane, OVERVIEW included: `PaneHeader` (icon +
> title at the shared x) / content split / the §8 P2 action cluster / the shared
> footer hint, and nothing else."

Acceptance list (the report answers these, in order):

- **A1 — `UI_SPEC.md` §12: shell-v2 design detail.** The drawer (geometry, entry
  plates, scrim, motion, focus order, close paths), the N27 tooltip (content
  grammar per §5.1 + the hint line, clamp rule, delay/positioning), the N28 modal
  (sheet anatomy row by row, triggers incl. the keyboard route, sizing law), the
  header/footer at measurement level — the §3.1 table idiom.
- **A2 — `STATION_HUB.md` §19: OVERVIEW + the one skeleton at measurement
  level.** The five blocks' grid rows (identity / tiles / hull+repair / services /
  flavour), the department tile component (internals, focus, pressed state), the
  `REPAIR →` deep-link, and **one skeleton measured once** with per-pane
  conformance rows for all seven panes (OVERVIEW, ARMORY, REFINERY, EXCHANGE,
  AUCTION, SHIPYARD, LAUNCH): where each PaneHeader/content split/action cluster/
  footer sits, and what each pane moves into its content split.
- **A3 — three wireframes** in `staging/mockup/`:
  `d19_shell_wireframe.md` (header + drawer open over a pane),
  `d19_overview_wireframe.md`, `d19_popup_wireframe.md` (tooltip + INSPECT modal
  over a pane) — the D18 wireframe idiom.
- **A4 — the A5.5 defect census:** every shipped hover/focus/selection handler
  under `vajb-orbit/ui/` that violates A5.5, each with `file:line` and its cure
  (delete → tooltip / reserved slot / already legal). The two known
  (`shipyard_panel.gd:703-733`, the fitting twin) must appear; the census is
  closed when S30 can cure from the list alone.
- **A5 — the supersession ledger:** every `docs/design/` sentence this wave
  re-points, old cite → new cite (the three named in §18's ledger plus anything
  else found, e.g. §2's rail wording, §3.1's `ModuleRail` row as a live row).
- **A6 — the staged art-needs list:** any sprite this shell wants (tile icons,
  drawer glyphs, chrome), each with prompt draft, model, price estimate (10
  credits = $0.05 per 2K run) and the pipeline route — **staged only**, nothing
  generated or shipped (§18's art-budget block gates on an owner-approved sheet).

## 6. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| D19-A1 | design detail | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/D19-A1_report.md` | A1–A6 + `D19-A1_report.md` (REPORT template, ≤120 lines) |
| D19-R1 | review | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,vajb-orbit/ui/,.agents/gen/slices/D19-station-shell-v2/D19-R1_review.md` | REVIEW template ≤150 lines; findings `D19-A1/F##` |
| D19-F1 | fixer (only on HIGH/MED) | `docs/design/UI_SPEC.md,docs/design/STATION_HUB.md,staging/mockup/,.agents/gen/slices/D19-station-shell-v2/` | dispositions + cures, `D19-F1_report.md` |

## 7. Run order
A1 → R1 → (F1 only if R1 leaves HIGH or MED). One worker in flight at a time;
block on each (`job_output`, `wait: true`); a wedged worker is SIGKILLed
(wrapper + inner pid) and re-dispatched.

## 8. Tests that move
**None in D19** — it is design-only and the gate must re-run at 1074/0.
Projected for S30 (stated now so its brief cannot forget): `test_s11_inspector.gd`
(sink retarget band→tooltip/modal), `test_s29_station_panels` (rail → drawer
entries), `test_s21_stability` (station boot rows); new rows: skeleton parity
across panes, **hover-never-moves** (pane node y unchanged across a hover),
drawer overlay open/close/ESC, OVERVIEW tile navigation, INSPECT modal roundtrip.

## 9. Hard rules
Docs and `staging/mockup/` only (file sets enforced by hook); every new number
PROPOSED with its reversal; `18_engine_spec.md` untouched; no code, no art
generation; a number the worker believes is wrong is **reported, never changed**;
escalation ladder applies (inside a pinned acceptance → decide and proceed;
touches a pin → report; taste superseding an owner ruling → escalate).

## 10. Staged / deferred
Art generation (after owner sheet approval, pipeline law); S30's build split
proposed as B1 shell/drawer/overview ∥ B2 popups + skeleton + A5.5 cures (the
S30 brief re-checks the split against §12/§19's final shape); T-102's
`map_filters` key and the rest of T-94–T-106 ride.

## 11. Owner tick list (status at dispatch)
**Ticked 2026-10-03 (the Q&A + rulings):** both description sinks; OVERVIEW =
all five blocks; OVERVIEW lands on dock; the name TERMINAL; both defects in
scope; grimdark-but-smooth; kie.ai budget open for this wave.
**PROPOSED — unticked rows implement at their PROPOSED value (S19 precedent):**
N25's P2 sizing, N26's motion pair, N28's min/max widths, P16's entry order,
P18's tile grid + min size, and every value §12/§19 adds (N31+/P22+).

## 12. Close-out steps (orchestrator)
Gate re-run (1074/0 expected — a move is a finding) → `python3
staging/verify_wave.py verify --baseline d19_start` → WAVEBOARD §Queued row →
closing paragraph → `MASTER_REPORT.md` §6 recap → wave-boundary commit → then
S30's five-piece (coder item 36) on the ticked rows.
