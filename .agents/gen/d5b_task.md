# D5b — Finish the space station hub mockup (continuation)

You are a **designer** worker whose medium is a **Godot 4.7 UI scene**. **A previous run of this same task died mid-verification on a gateway error.** Its work survived on disk. Your job is to finish it, not to restart it.

## State you inherit (verify, do not trust)

- `vajb-orbit/ui/screens/_mockup_station.tscn` — 26,983 bytes, written by the previous run.
- `vajb-orbit/ui/screens/_mockup_station.gd` — 43,705 bytes, written by the previous run.
- `docs/design/STATION_HUB.md` — **does not exist**. You must write it.
- `.agents/gen/d5_report.md` — **does not exist**. You must write it.
- Headless check already passes: `--headless ... res://ui/screens/_mockup_station.tscn --quit-after 300` exits 0 with clean stdout. That is NOT proof of correctness, only that it loads.

The previous run's last recorded finding: **the slot plates only render when their textures are copied onto the node** (see `vajb-orbit/ui/components/slot_button.gd:89-103`, `_apply_plates`). It was mid-fix on that when it died. Verify whether that fix landed and complete it if not.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2. **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot` or `addons/`.
- Base render target is **1920x1080**, stretch `canvas_items`, aspect `expand`.
- Headless check: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_station.tscn --quit-after 300`
- The orchestrator will launch your scene in the real renderer and screenshot it. It must render a complete, presentable screen with **zero input** and print nothing.
- Kill only your own hung Godot after 60 s: `powershell -Command "Get-Process Godot* | Stop-Process"` would kill the editor too, so target the PID you started instead.

## Read first

1. **`.agents/gen/d5_task.md`** — the original brief. It is still the specification of what this screen must be. Follow it in full.
2. The files the original brief lists as required reading: `docs/design/STATION_SPEC.md`, `docs/design/UI_SPEC.md`, `docs/design/STYLE_BIBLE.md`, `docs/design/IMPLEMENTATION_PLAN.md` (especially **§9** Phase D amendments), `docs/design/ASSET_AUDIT.md` (sections E and F), `docs/design/THEME_AUDIO_EXTENSION.md`, `docs/design/MAIN_MENU_V2.md` (the sibling mockup, for identity consistency — it kept the metal housing panel, the 1 px border language, the ember accent and the COMMAND caption style; your station must look like the same game).
3. The two files you inherited, in full.

## Your job

1. **Audit what exists against the original brief.** In your report, list every brief requirement as MET / PARTIAL / MISSING with the evidence you used. Do not assume the previous run finished anything it did not.
2. **Fix the plate rendering** so the ship/upgrade/ammo slot plates actually draw, and prove it: render a frame and measure it, or assert the node's `texture_normal` is non-null for every slot at runtime.
3. **Complete the missing requirements.** At minimum check: the four modules plus LOG OUT, real catalogue data with the exact names and prices from `STATION_SPEC.md`, the owned/affordable and unaffordable states, the ship preview at a size that reads as a ship with its stat rows, `PanelRaised` for panels, the new `ItemList` and `ScrollContainer` chrome for lists, container-driven responsive layout with `size_flags` named in the spec, the motion table, the focus traversal, `ui_scale` 1.0 and 1.4 correctness, no hex literals, no `class_name`, no autoload calls, no `Router` calls.
4. **Verify with measurements, then produce a visual proof.** The sibling worker produced a preview by rendering frames with `--write-movie` and measuring them with Pillow (`py -3.14`). Do the same: render at least three frames covering three module states, write them to `.agents/gen/previews/`, and report the measured pixel evidence that the composition is right (positions, sizes, contrast ratios). Contrast must be measured, not eyeballed.
5. **Write `docs/design/STATION_HUB.md`** with exactly the sections the original brief lists, including the per-module spec, the responsive rules, the implementation notes for the coder wave, and open questions for the owner at the end.
6. **Write `.agents/gen/d5_report.md`** with the requirement audit table, every command and its output, the headless exit code, the measured evidence, the asset list with each path verified on disk, and anything you could not verify.

## Files you may write

- `vajb-orbit/ui/screens/_mockup_station.tscn` and `_mockup_station.gd` (edit in place)
- `docs/design/STATION_HUB.md`
- `.agents/gen/d5_report.md`
- `.agents/gen/previews/` (your renders)

Touch nothing else. Do not edit `STATION_SPEC.md`, `station_catalog.gd`, `player_profile.gd`, the theme, `main_menu.tscn`, `_mockup_main_menu.*`, or `project.godot`.

## Rules

- Invent no asset path, theme item, catalogue id, price or node name. Everything must come from the specs and exist on disk.
- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No em dashes; no comments in code unless the why is non-obvious.
- Measurements, not assertions. If you cannot verify something, say so plainly in the report rather than claiming it works.
