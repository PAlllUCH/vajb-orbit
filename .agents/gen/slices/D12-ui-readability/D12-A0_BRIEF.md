---
slice: D12
worker: D12-A0
role: reviewer (design lane, readability)
status: ready
tier: deepseek-direct        # owner's ruling: deepseek api deepseek flash, max reasoning
---

# D12-A0 — Station readability audit, ARMORY first

## What you are

An **independent readability auditor**. You measure and report; you never edit a
source file, never commit, never touch `user://` on purpose, never press a
button that buys, sells, repairs or fits anything. The delivery is one report.

## Context (read in this order, by range — never whole)

1. `slices/D12-ui-readability/SLICE.md` — why this exists and your file set.
2. `docs/design/UI_SPEC.md` — **the yardstick**. Every finding must cite the
   token or rule it violates. Read the station/token sections only.
3. `docs/design/STYLE_BIBLE.md` — the palette (hex values) the contrast rows
   are computed from.
4. `docs/design/STATION_HUB.md` **§5.11** (the ARMORY pane contract) and §5.1.
5. `vajb-orbit/ui/theme/vajb_theme.tres` — 576 lines, the actual font sizes,
   colours and styleboxes every pane resolves through **when the station screen
   provides the theme**.
6. The panes: `vajb-orbit/ui/station/armory_panel.tscn` (180 lines) +
   `armory_panel.gd` (2357 lines — read the `const` block and the plate/rack
   builders by range, never the whole file) + `armory_style.gd` (232).
   Then, in priority order: `shipyard_panel`, `exchange_panel`, `auction_panel`,
   `repairs_panel`, `fitting_panel`, `launch_panel`, `refinery_panel`, and the
   shell: `vajb-orbit/ui/screens/station.tscn` + `station.gd` (the footer strip
   and the `HintLabel`).

## The one thing you must not get wrong

`armory_panel.tscn` carries **no** theme resource; the theme reaches a pane from
`ui/screens/station.tscn`. A screenshot of the pane opened on its own therefore
renders with Godot's **default** theme and proves nothing about readability.
Measure the pane **inside the station**, or do not claim a visual finding.

## Evidence routes (use at least two, name the route on every finding)

- **The live editor is open** with `res://ui/station/armory_panel.tscn` and
  `play_state: stopped`. Use the `godot-ai` bridge:
  - `project_run` with `mode: custom` and `scene: res://ui/screens/station.tscn`
    — the ARMORY is the first rail module, so it renders directly. Screenshot
    it with `editor_screenshot` `source: game` at `max_resolution` 1152.
    **Do not stop a game you did not start**; stop your own with
    `project_manage op=stop` when you are done. Do not navigate the rail, do not
    press any action button.
  - `game_manage` `op: get_ui_elements` on the running station gives every
    visible Control's path, text, disabled state and rect — that is where the
    measured box sizes come from.
  - `game_eval` reads a resolved value directly, e.g. a Label's
    `get_theme_font_size` or a Control's `size` after a frame. Prefer this over
    guessing from the `.tscn`.
- **The files**: `theme_override_font_sizes`, `custom_minimum_size`, anchors and
  the theme's own type variations, read as text. Cite `file:line`.
- **Contrast**: compute WCAG relative-luminance ratios yourself from the theme's
  real hex colours against the panel's real background. Report the ratio to one
  decimal and the AA threshold it fails (normal text 4.5, large text 3.0).

## What to look for (in this order)

1. **Font sizes** — any text under the UI_SPEC's own minimum for its role; the
   ARMORY's rack captions, barrel names, `SALVO` figures, refusal text and the
   `(1)..(7)` key hints first. This is the owner's "looks pretty bad".
2. **Contrast** — dim captions, ember/ink-on-metal pairs, disabled states.
3. **Hierarchy and crowding** — too many competing labels at the same weight,
   figures with no unit, labels that clip or ellipsize at the pane's real width,
   a caption whose value is unreadable at a glance.
4. **Dead or unreadable affordances** — a hint that names a key the map does not
   bind, a label that never updates, a hover line that overwrites a status line.
5. **The shell** — the single-line footer strip (`station.gd`, `StatusLabel` /
   `HintLabel`): is one line enough to carry a full item description, and at
   what size? Say what it would take for a description block to fit there.

## Deliverable — `slices/D12-ui-readability/D12-A0_report.md`, ≤150 lines

- Header: the edits state you measured (branch + `git log -1 --format=%h`), the
  gate count if you ran it (you need not), the editor session id, and whether
  the live profile md5 moved.
- Then findings, **tiered HIGH / MED / LOW**, each one on its own block and each
  carrying: `file:line` · the `lane:` tag (`graphics` or `code`) · the measured
  value · the yardstick it violates · one line of why it hurts · the concrete
  suggested change. Cite the route you measured with.
- A `problems: []`-style close: anything you could not measure and why.
- **No source pasting, no screenshots embedded, no transcript.** Every line you
  write is re-sent to the reader on every later request.

## Hard rules

- One report file, nothing else. `VAJB_WORKER_FILES` holds exactly that path.
- Never edit a file under `vajb-orbit/` or `docs/`. Never commit. Never write to
  `docs/archive/`. Never touch `slices/D11-station-scene/**`,
  `dispatch_designer.md` or `staging/mockup/**`.
- Never leave a command running in the background; bound any Godot run and read
  its log instead of waiting on it.
- If a fact cannot be measured, write "not measured" — never guess a number.
