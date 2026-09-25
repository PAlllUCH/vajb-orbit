# D8 item 10 — In-flight HUD visibility (wave brief)

**Wave:** D8-HUD (design lane, item 10 of `dispatch_designer.md`)
**Slice folder:** `.agents/gen/slices/D8-hud-visibility/`
**Baseline:** gate **852/0**; `python3 staging/verify_wave.py snapshot --name d8hud_start` before the first dispatch.
**Owner picks (2026-09-24):** top-left content + minimap legend + 1080p glyphs.
**Amended 2026-09-25 (owner):** the top-left pick is **retired** — hull/shield
state is already live in the cockpit cluster (the QA row predates D6/D7), and
nothing may duplicate it. The wave is the **minimap legend** and the **1080p
glyph floor**.
**QA input:** `.agents/gen/slices/S7-affix-application/S7_QA_playtest_review_2026-09-24.md`
— read the in-flight HUD rows first; they name the offenders (the empty
top-left, the legend-less minimap, the 1080p glyph rows) and bind this brief
where it is silent.

## 1. Pinned rules

1. **No duplication (owner 2026-09-25).** The cockpit cluster owns
   SPD/HULL/SHLD/AMMO and FUEL/ENRG; the HUD may not repeat those readouts.
   The top-left quadrant may stay empty. Nothing new is invented anywhere.
2. **The minimap legend** names exactly the blip kinds `minimap.gd` draws (read
   its draw code; the legend must not promise a kind that does not exist). It
   sits inside the HUD chrome, not over the play field's centre.
3. **1080p legibility:** every HUD text/glyph measures ≥ 12 px cap height at
   1920x1080. Fix the offenders at their source (per-node overrides must not
   escape `ui_scale` — D12-A0's lesson from the armory). List each offender
   row with before/after pixel measurements.
4. **The lane seam:** `ui/hud/**` is yours; `ui/station/**` (S15), `game/**`
   (S14), `autoload/**`, `project.godot`, `docs/` and `addons/` are not. If a
   fix needs one of those, report it as bucket 2 and stop at the boundary.
5. **The cockpit is display-only and stays as it is** — `test_d7_cockpit`'s
   lamp rows must stay green untouched (S15 is reworking the rack ordinals
   beside you; attribute, never fix).

## 2. Tests that move

- New: `tests/test_d8_hud_visibility.gd` — AC2 (the legend
  names each `minimap.gd` draw kind), AC3 (the glyph measurements),
  AC4 (the untouched-cockpit guard). AC1's retirement is proven by the
  no-duplication row (the top-left stays empty).
- **Not moved:** `test_d7_cockpit.gd`, `test_d7_armory.gd`, `test_s10_*`,
  `test_s11_*`, `test_s13_*`, `test_s14_*`, `test_s15_*`, `test_ui_slot_layout.gd`
  unless the QA row names it. Pre-grep and report every row you touch; an
  unlisted row changed is HIGH at review.

## 3. Hard rules

- Shell edits forbidden — edit tools only.
- Bounded Godot runs (`--quit-after`), scratch `XDG_DATA_HOME`, never write the
  profile or a live `user://`.
- The QA review is the finding source; `docs/` edits are barred (the UI_SPEC
  amendment lands at close-out, S8's pattern).

## 4. Output contract

Report `slices/D8-hud-visibility/D8-B1_report.md` (REPORT template, ≤120
lines): the chosen top-left composition with its justification, the legend
kinds table, the glyph before/after pixel table, the pre-grep table, the gate
`[SUMMARY]` before/after, every deviation (bucket-tagged).

## 5. Skills (read by path when you need idiom)

The shared skill library referenced by `crushrc` resolves on this host under
`~/.local/share/crush/additional-skills/godot/`: `godot-ui/SKILL.md`,
`godot-ui-containers/SKILL.md`, `godot-ui-theming/SKILL.md` (per-node override
rules matter here), `godot-master/godot-testing-patterns/SKILL.md`. Project
rules override anything you read there: signals travel UP, calls travel DOWN;
cross-file scripts reached by preload path.

## 6. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (including
re-measuring the PNG/text pixels), diffs against the QA rows and §1 above,
writes `slices/D8-hud-visibility/D8-R1_review.md` (REVIEW template, ≤150
lines), appends LOW rows at the next free ids read at write time. No
`docs/CONTRACTS.md` writes on this wave (no gate row moves are expected; if
one does, it is a finding).

## 7. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores; `verify --baseline d8hud_start
   --forbidden vajb-orbit/project.godot docs/ vajb-orbit/game/ vajb-orbit/autoload/
   vajb-orbit/ui/station/ addons/ --tests
   --expect-reports .agents/gen/slices/D8-hud-visibility/D8-B1_report.md
   .agents/gen/slices/D8-hud-visibility/D8-R1_review.md`
   (the S14/S15 lanes' touched files are attributed).
2. The `UI_SPEC.md` dated amendment (the top-left block + legend + glyph floor).
3. WAVEBOARD + `dispatch_designer.md` one-liners; MASTER_REPORT §6 recap;
   wave-boundary commit; the owner eyeballs the HUD at close-out (one
   `editor_screenshot` pass) and may request taste changes.
