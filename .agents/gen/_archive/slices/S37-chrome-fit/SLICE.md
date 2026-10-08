---
slice: S37
phase: P3
lane: code
status: landed
gate_baseline: "1151/0"
---

# S37 — Chrome fit (sprite vs content)

## Goal
Determine, per chrome-bearing surface, where the family sprite is drawn smaller than its own
icon+text content. The owner reports: the TERMINAL drawer entries and the OVERVIEW tiles are
"too small, text goes over them"; the ARMORY EQ slots, the REFINERY job rows ("ALUMINUM 2
INGOTS") and the AUCTION rows read "stretched". This slice delivers the measured list only.

## In scope
- A headless probe that walks the station (all decks + the shell + the drawer) and, per surface,
  compares the chrome's drawn rect against the content box (`icon + text`, +10 % padding).
- The report: every surface where drawn < needed, or where the drawn aspect is far from the
  cut's (a stretch), with `file:line` and the numbers.

## Out of scope
- Any production `.gd`/`.tscn` change. Any asset change.

## Amendment (owner, 2026-10-07): the fix landed
The owner widened the slice: "go ahead" on the replacement cuts. S37-F1 cured
the theme plate; S37-B2 generated five replacement cuts on one qwen2-1 sheet
and wired them (C1/C2/C9 clean, C3/C4 bands re-measured). `too_small 180 -> 95`,
`DISTORT 0`, gate `1151/0`. The residual 95 are content (C4 x) and
pinned/theme, ticketed. See `S37-B2_report.md`; §15.8 carries the doc record.

## Acceptance criteria
- [ ] AC1 — the probe prints, per surface: deck, node path, class, drawn chrome rect, content
      needed rect (icon + font-measured text + 10 %), the deficit, and a stretch ratio.
- [ ] AC2 — the report lists every surface where drawn < needed, with `file:line`, covering at
      least the owner-named surfaces (drawer entries, overview tiles, armory EQ slots, refinery
      job rows, auction rows).
- [ ] AC3 — no production file changes (the gate baseline `1151/0` stands untouched).

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| S37-R1 | `vajb-orbit/tests/, .agents/gen/slices/S37-chrome-fit/` | `S37-R1_body.txt` |

## References
- `docs/design/UI_SPEC.md` §15.1 (the census), §15.3 (the margins law), §15.6 (the rail look)
- `vajb-orbit/ui/theme/chrome_family.gd` (`make_canvas`, `canvas_rect`, `cut_size`, `cut_aspect`)
- `vajb-orbit/tests/probe_s36_r1_scene.gd` (the measurement template)

## Carries forward
- The fix wave this determination feeds (T-147's C3 clamp, T-144's small-plate class).
