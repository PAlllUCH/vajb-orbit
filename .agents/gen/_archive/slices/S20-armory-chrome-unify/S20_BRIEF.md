# S20 — ARMORY chrome unification & the shell inspector pin (wave brief)

Owner request, verbatim (2026-09-26, after playing the S18 armory): *"coder
finished the implementation of s18 all wired up. let me what "over cap" means.
i very much like the layout but i need to unify it to the rest of game
(chromes) and on hover the bottom description panel sometis gets "bigger" and
all shifts up."* The OVER CAP question is answered at handoff (two meanings on
this screen: §5.1's stock chip `OVER CAP` = held units > the advisory hold
ceiling; the bay chip `▲ OVER CAP` = the battery holds the 4-cell hardcap).
Tick T6 is the wording fork that question raised.

## 1. The law to read, in order
1. `docs/design/UI_SPEC.md` §3.10 **Amendment 4** (2026-09-26) — the pin:
   A4.1–A4.5 + the owner tick list. Amendment 3 (the layout) and §5.3 (the
   chrome family) are its two halves; §3.1/§3.1b is the chip/row treatment.
2. `docs/design/STATION_HUB.md` §5.11 (armory render law) and §5.1 (the four
   stock states, the advisory ceiling).
3. `docs/design/UI_CHROME_ASSETS_SPEC.md` §1.3 (chrome palette), §2 (panel
   frame), §9 (the 2× law).
4. `.agents/gen/slices/D13-armory-rework/D13-A0_report.md` — the design of
   record whose **geometry** survives untouched (P1–P6).
5. `.agents/gen/_state/LOW_BACKLOG.md` **L227** (the contrast row this wave
   closes) and **L229** (probe hygiene: scratch stores only).
6. `vajb-orbit/tools/build_theme.gd` (the only hex store; the chrome
   registration) and `vajb-orbit/ui/station/armory_style.gd` (the pane's one
   style surface).

## 2. Pinned interface (verbatim — what stands and what changes shape)

**Stands unmoved (a moved number is HIGH):**
- Every Amendment 3 geometry pin: the landscape console 1360×516 at the
  (452,214)+1392×610 host, the five bays with their P3 2×2 cells, the wells
  band, `ArmoryStyle.console_rect(host)` P6 derivation, the 13 px ink floor,
  captions ≥ 4.5:1, the P5 `HELD %d ROUNDS - HOLD %d UNITS` wording, the §5.1
  four stock states, T7 chip semantics (`READY` / `▲ OVER CAP`, shape + label,
  never colour alone), T8's salvo ledge (A4.5).
- The data law: five batteries × ≤ 4 cells, the pack cards, the §13/§16
  transactions (refusals write nothing), CONTRACTS §17's seams.
- The `inspect_requested(title, body, danger)` seam and
  `INSPECTOR_BODY_MAX_LINES := 2` (`ui/screens/station.gd:129`).
- `ArmoryStyle` stays the single style surface: a `CockpitStyle` (the
  `ui_seg_*` digits stay), the `armory_style_user.tres` override path intact.

**Changes shape (A4.1–A4.4; the docs are the pin):**
- `ui_armory_console` retires from the pane (file stays on disk,
  `ASSET_CATALOG.md` records it unwired); bay cards, wells halves and pack/row
  plates wear the §5.3 `ui_panel_frame` nine-patch idiom (`panel_frame` /
  `PanelRaised`, 32 px patch margin, 1 px border convention); the module
  host's own frame is the pane's outer edge; nine-slice flat bands only (the
  D3 defect class).
- The bays' 2×2 cells wear the `ui_slot_weapon_*` slot chrome (the
  `SlotButtonWeapon` family FITTING wears); `BUY`, `✕` and any pressable chip
  wear `StationButton` / `ui_button_plate_*`.
- State chips keep §3.1/3.1b's label + 1 px frame in theme **Tokens** tones;
  `ArmoryStyle`'s hex palette fields resolve from the theme (hex lives only in
  `tools/build_theme.gd`); the `OVER CAP` label clears **4.5:1** (L227 closes).
- The station shell's `Inspector` reserves a constant height — the title line
  + 2 body lines + the margins as font-derived `custom_minimum_size` on
  `InspectorTitle`/`InspectorBody` — so the empty hover state reserves the
  same box and the module host never reflows when `inspect_requested` fires.

**Worker-decided (bucket 1):** the code route (StyleBoxTexture vs the §5.3
NinePatchRect scene pattern; how the Tokens lookup lands in `ArmoryStyle`),
test helper shapes, exact nine-slice margins as long as the result reads as
the sibling panels' chrome.

**Escalate (bucket 2/3):** any Amendment 3 geometry number, any docs text
beyond the pre-approved Amendment 4 / catalog notes, anything that weakens an
existing assertion, anything that would change tick T8's look.

## 3. Existing rows (pre-grep before any edit; no unlisted row may move)
| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_d7_armory.gd:325-327` plate texture = `console_path` | A4.1 master retires | **moves** — re-point at the chrome surface |
| `test_d7_armory.gd:741, 798-807` console master ships / plate paths | A4.1 | **moves** — master-unwired rows |
| `test_d7_armory.gd:784` `ArmoryStyle is CockpitStyle` | A4.5 keeps `ui_seg_*` | unchanged |
| `test_s15_armory_layout.gd:32` `CONSOLE_PATH` + master-dimension rows | A4.1 | **moves** — plate rows only |
| `test_s15_armory_layout.gd` geometry pins (ink rect, ink rows, slot pitch) | layout frozen | **unchanged — a move is HIGH** |
| `test_s18_armory_rework.gd:429-430` rack/row plates null | already retired | unchanged |
| `test_s18_armory_rework.gd` 13 px / contrast / P5 / P6 rows | floors stand | unchanged |
| `test_s11_inspector.gd:291` `max_lines_visible == 2` | seam unchanged | unchanged; **gains** A4.4 rows |
| `test_s10_armory_input.gd`, `test_p2b1_outfitting_panel.gd` structure rows | skin only | unchanged unless naming a retired plate → 1:1 re-point |

## 4. Hard rules
- Gate law: starts **887/0**, rows may only be added; every moved row's
  old→new value goes in the report.
- Hex literals only in `tools/build_theme.gd`; `ui/theme/vajb_theme.tres` is
  regenerated by running the builder, never hand-edited.
- No paid calls, no new art: the chrome family already ships the textures
  (`assets/ui/ui_panel_frame.png`, `ui_slot_weapon_*`, `ui_button_plate_*`).
- Probes that mount the station run under `XDG_DATA_HOME=$(mktemp -d)`
  (L229); every Godot run bounded with `--quit-after`; no command left in the
  background.
- Docs in the worker's file set carry only the pre-approved Amendment 4 text
  and `ASSET_CATALOG.md` unwired-entry notes; a value the worker disagrees
  with is reported, never edited.

## 5. Output contract
`S20-B1_report.md` (REPORT template, 120 lines max): the pre-grep table, the
A4 surface mapping as built (surface → chrome asset/stylebox), the measured
`OVER CAP` contrast ratio, the inspector pin measured at content states `""`,
1, 2 and 3+ lines (identical heights, identical ModuleHost rect), the moved
rows old→new, both `[SUMMARY]` lines, every deviation. `S20-R1_review.md`
(REVIEW template, 150 lines max): findings `S20-B1/F##` with tier + one
evidence line each; LOW rows at the next free ids read from
`.agents/gen/_state/LOW_BACKLOG.md` at write time.

## 6. Skills (read by path when you need Godot idiom)
`godot-ui-theming` (StyleBox / nine-patch), `godot-gdscript-mastery`,
`godot-ui-containers` — the shared library paths in `crushrc`.

## 7. Run order
`verify_wave.py snapshot --name s20_start` + `git tag s20_start` →
**S20-B1** → **S20-R1** → **S20-F1 only on HIGH/MED**. One live session at a
time (L82); the S19 wave queued behind this one also holds
`vajb-orbit/tests/` and `vajb-orbit/tools/` — that collision is why S20 runs
first and S19 second.

## 8. Close-out (the orchestrator)
Gate ×2 on fresh scratch stores (hermetic, L229),
`python3 staging/verify_wave.py verify --baseline s20_start`, the owner's
ticks T1–T6 recorded in `UI_SPEC.md` §3.10 A4 and the WAVEBOARD,
`MASTER_REPORT.md` §6 recap, wave-boundary commit.
