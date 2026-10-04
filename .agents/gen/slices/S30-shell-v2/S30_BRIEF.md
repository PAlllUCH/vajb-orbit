# S30 — Station shell v2 build (wave brief)

**Wave:** S30 (code lane, item 36 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S30-shell-v2/`
**Baseline:** gate 1074/0 (D19 close `f22a151`); `python3 staging/verify_wave.py
snapshot --name s30_start` before the first dispatch.
**Owner go (2026-10-03):** "everything in ticks looks good. assume default if
not chosen. proceed with coder" — every `.agents/gen/_state/TICKS.md` decision
row takes its default. Routing: code `hyper/deepseek-v4.1-flash`, review
`hyper/glm-5.3-flash`, each at the provider's max reasoning effort.

## 1. The law to read, in order
1. `slices/S30-shell-v2/SLICE.md` — scope, file sets.
2. `docs/design/UI_SPEC.md` §11 (A5.5 + N24–N30 and the N28 amendment note) +
   §12 (N31–N41: the drawer table, the tooltip, the modal, the census) + §8
   (P1/P2 tokens) + §5.1/§5.2 (the idioms N27/N28 instantiate).
3. `docs/design/STATION_HUB.md` §18 (P15–P21 + the supersession ledger) + §19
   (P22–P31: OVERVIEW, the skeleton conformance rows, the art list) + §3.1/§3.4
   (the grid arithmetic).
4. The wireframes `staging/mockup/d19_shell_wireframe.md`,
   `d19_overview_wireframe.md`, `d19_popup_wireframe.md`.
5. The §5 acceptance lists below.

## 2. The owner's request (verbatim)
> "the containers dont sit in the same place when hovering between different
> sections. First the select menu… has to be gone but only the visual aspect,
> not the functionality. i want it to slide from left of the screen when you
> press a Menu button… new pane: space station overwiew… Lets remove the bottom
> panel with description… popup when you hover… or add 'inspect' button. if we
> inspect a module make a screen popup as well, it was bo be responsive menu."

> "i want the screen to look grimdarky but operate smoothly."

Tick answers 2026-10-03: both description sinks; OVERVIEW = all five blocks;
OVERVIEW lands on dock; the button is TERMINAL; both instability defects in
scope. 2026-10-03 second go: every TICKS row at its default.

## 3. What is already measured (file:line)
| Fact | Site |
|---|---|
| the band to delete | `ui/screens/station.tscn:214`, `station.gd:150-151,273-301` |
| the rail to delete (360 px measured) | `station.gd:149,324-331`; `STATION_HUB.md` §3.1 |
| the hover→describe chain (keep; swap the sink) | `station.gd:518-540`, `tests/test_s11_inspector.gd:140-233` |
| the A5.5 census — 15 rows, cure each as named | `UI_SPEC.md` §12.5 |
| the in-flow hover block twin pair | `shipyard_panel.gd:703-733`, `fitting_panel.gd:1469-1491` |
| grid-rebuild class (census F3 row) | `shipyard_panel.gd:508-527`, `armory_panel.gd:2906-2935`, `fitting_panel.gd:484` |
| `tooltip_text` second-surface writes | `armory_panel.gd:1968,2029,3139,3645` |
| the ESC one-operation precedent | `game.gd:951` (S29-F1) |
| the plate art measures 254 wide in a 270 box | `station.tscn` (x 71..325) → **R-S30-1** |

## 4. Pinned interface + rules
The N/P rows live at source (§11/§12/§18/§19) and are not copied here. New pins:

- **R-S30-1 (T-111's cure):** the drawer's content box is **272 px** (x 68..340
  at 1920) so the §8 P8 272×56 plate seats without squeeze. Reversal: 254-wide
  plates in the 270 box.
- **R-S30-2 (T-102's default):** `player_profile.gd` gains a first-class
  `map_filters` save door and `map_deck.gd:496-534` reads/writes the public
  door instead of `get(&"_config")`. Reversal: keep the borrow.
- **T-105's ruling:** restore the L18/L122 clock rows' equality with a
  frozen-clock fixture (`test_s21_stability.gd:906-922`); do not weaken them
  back to `> before`.
- **T-112's derivation:** the three-plate clusters (EXCHANGE, LAUNCH, REFINERY,
  SERVICES) derive their seat from §8's token sizes + §19.3's box arithmetic;
  report the arithmetic; any widened box ships PROPOSED with a reversal and a
  fresh P id.

Rules that fix ambiguity:
1. **A5.5 is the acceptance bar** (hover/focus/selection mutate colour,
   `modulate`, `_draw` only). The reviewer re-measures it: a pane node's `y` is
   identical before/during/after every hover.
2. **Seam law:** B1 ships the popup sinks first; B2 deletes the band and the
   rail only after B1's sinks are live. The game is coherent at every commit.
3. **New input actions ride raw-key fallbacks** (`map_toggle`'s idiom,
   `map_deck.gd:486-490`); InputMap registration happens at close-out —
   `project.godot` is outside every worker set.
4. **Tokens only, no new art** (N29). Reuse shipped icons for tiles/drawer
   entries. Motion ≤ 0.2 s `TRANS_CUBIC` `EASE_OUT`, overlays only.
5. Every moved gate row is disclosed in the report; every judgement a builder
   makes inside its acceptance list is stated there (bucket 1). A number not
   derivable from the law ships PROPOSED with a reversal — never invented
   silently.

## 5. Spec extract (verbatim) + acceptance lists
`UI_SPEC.md` §11.1 (A5.5):
> "**A5.5 (extends §3.10's Amendment 5): hover, focus and selection mutate
> colour, `modulate` and `_draw` only — never size, never an in-flow node's
> `visible`, never position.** Hover-revealed content lives in the popup layer
> or in one fixed reserved slot per pane"

`STATION_HUB.md` §18 (P15):
> "the shell is header (TERMINAL · station identity line · credits housing) /
> body (one pane at full body width) / footer status strip — and nothing else"

**S30-B1 — the popup layer, the census, the one skeleton (A1–A6)**
- **A1** — N27 tooltip + N28 modal built to §12.2/§12.3 anatomy (size-to-content
  within min 420 / max 720, the clamp rule, the `INSPECT` hint line), wired to
  the existing `inspect_requested` chain (P21); the N28 triggers per its
  amendment (rows carry the inline chip, cells route through the cluster chip).
- **A2** — the §12.5 census cured **row by row** (15 rows: delete → tooltip,
  delete → reserved slot, legal-stated), including `shipyard_panel.gd:703-733`,
  the fitting twin, the grid-rebuild class and the four `tooltip_text` writes.
- **A3** — the one skeleton (P7 extension + §19.3): `PaneHeader` / content
  split / §8 P2 cluster / shared footer hint on **every** pane, per §19's
  conformance rows.
- **A4** — A5.5 held everywhere in `ui/` (the reviewer's hover-never-moves probe
  must pass on all panes).
- **A5** — tests: `test_s11_inspector.gd` retargeted to the popup sinks; new
  rows for tooltip show/hide/timeout, modal open/ESC/queue, and
  hover-never-moves (pane geometry equal across a hover).
- **A6** — gate twice on fresh scratch `XDG_DATA_HOME` stores, every moved row
  disclosed; `S30-B1_report.md` (REPORT template, ≤120 lines) answering A1–A6.

**S30-B2 — the shell, the drawer, OVERVIEW (A1–A6)**
- **A1** — the shell re-lay per P15 (header with the N25 TERMINAL button +
  identity line + credits housing; body = one pane; footer strip) and the
  **deletion** of the ModuleRail and the Inspector band (§18's ledger).
- **A2** — the TERMINAL drawer per §12.1 + N26 + P16: 360 px overlay with the
  §5.2 scrim, the entry plates on R-S30-1's box, 0.18/0.12 s motion, focus
  order, and P19's topmost-first `ui_cancel` (each step one operation).
- **A3** — the OVERVIEW landing pane per §19.1/§19.2 + P17/P18: identity block,
  the 3×2 department tiles (navigate on press), the active-hull + repair summary
  with `REPAIR →` deep-linking to SHIPYARD, the U2 services rows, one flavour
  line.
- **A4** — P20 cycling (`PageUp`/`PageDown` + shoulders wrap the six panes),
  LOG OUT's confirm flow unchanged, and the new actions' raw-key fallbacks
  (TERMINAL toggle, `station_inspect`, prev/next) per rule 3.
- **A5** — tests: drawer open/close/ESC/entry-navigation rows, OVERVIEW tile
  navigation + landing-on-dock rows, cycling wrap row; `test_s29_station_panels`
  and `test_s21_stability` boot rows moved **and disclosed**; the frozen-clock
  fixture per T-105's ruling.
- **A6** — gate twice on fresh scratch, every moved row disclosed;
  `S30-B2_report.md` (≤120 lines) answering A1–A6.

## 6. Worker table
| ID | Role | `VAJB_WORKER_FILES` | Deliverable |
|---|---|---|---|
| S30-B1 | builder | `vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B1_report.md` | A1–A6 + report |
| S30-B2 | builder | `vajb-orbit/ui/,vajb-orbit/tests/,.agents/gen/slices/S30-shell-v2/S30-B2_report.md` | A1–A6 + report |
| S30-R1 | review | `vajb-orbit/ui/,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/S30-R1_review.md` | REVIEW ≤150 lines, findings `S30-B1/F##` / `S30-B2/F##` |
| S30-F1 | fixer (HIGH/MED only) | `vajb-orbit/ui/,vajb-orbit/autoload/player_profile.gd,vajb-orbit/tests/,docs/CONTRACTS.md,.agents/gen/slices/S30-shell-v2/` | dispositions `S30-F1_report.md` |

## 7. Run order
B1 → B2 → R1 → (F1 only if R1 leaves HIGH or MED). Sequential (they share
`ui/`); one worker in flight at a time; block on each; a wedged worker is
SIGKILLed (wrapper + inner pid) and re-dispatched with an inspect-partial-diff
instruction (the S29-B1 precedent).

## 8. Tests that move
`test_s11_inspector.gd` (band → popup sinks), `test_s29_station_panels` (rail
entries → drawer), `test_s21_stability.gd` (station boot + T-105's two rows);
new rows per A5/A5. Projected gate: 1074 → ~1090. Every moved row is listed in
the builder's report; an unlisted move is a review HIGH.

## 9. Hard rules
Docs are read-only (report drift, never edit); `project.godot` untouched;
no art generation; no pinned value changed (R-S30-1/2 are the only new pins);
one fix+re-review cycle max unless HIGH remains; reports ≤120 lines with
`file:line` cites.

## 10. Staged / deferred
The A6 art pass (9 staged sprites behind an owner-approved sheet); the close-out
docs batch (T-94–T-97, T-99, L267, L268 — cites into files this wave rewrites,
so they re-measure after it); the input-map rows (T-101/T-110, close-out).

## 11. Owner tick status
**All TICKS.md decision rows took their defaults at the owner's word
(2026-10-03)** — N28-amend stands, U14 = 40/60/80, U17 replaces, outpost =
sector primary, B2-1 = none, T-98 = `CR EACH`, T-100/T-106 keep, T-102 = the
key grant (R-S30-2), T-107 = P22 scroll, T-108 = chevron, T-109 applied
(`U2`), T-113 = leave the runner. N31–N41/P22–P31 implement at PROPOSED.

## 12. Close-out steps (orchestrator)
Gate ×2 → `verify --baseline s30_start` → input-map rows via the sanctioned
writer (`map_toggle`, `station_inspect`, `station_prev_module`,
`station_next_module`; T-101/T-110) → docs cite batch + `docs/CONTRACTS.md` §9
gate figure → TICKS.md refresh → WAVEBOARD/`dispatch_coder` updates →
`MASTER_REPORT.md` §6 recap → wave-boundary commit.
