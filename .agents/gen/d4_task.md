# D4 — Main menu v2 mockup (live Godot scene) + spec

You are a **designer** worker whose medium is a **Godot 4.7 UI scene**. You build a throwaway, fully working mockup scene so the owner can look at the real renderer with the real fonts and the real art, and you write the spec a coder will follow to build the shipping screen. Nothing you build here ships as-is, but it must RUN and LOOK like the final thing.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2, Forward+, D3D12. **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot` or `addons/`.
- Base render target is now **1920x1080** (`display/window/size/viewport_*`), stretch `canvas_items`, aspect `expand`. Design against 1920x1080 and state what happens at 21:9 and 4:3.
- Headless check: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300` must exit 0 with a clean stdout. The scene will also be launched in the real renderer by the orchestrator, so it must not print anything and must not need a mouse to look right.
- Kill a hung Godot after 60 s: `powershell -Command "Get-Process Godot* | Stop-Process"`. Never kill PID 9048.

## Read first (all of it, in this order)

1. `AGENTS.md`
2. `docs/design/MAIN_MENU_SPEC.md` — the current frozen intent for this screen
3. `docs/design/UI_SPEC.md` — the UI laws (palette roles, 1 px borders, no `_process` for animation, focus rules)
4. `docs/design/STYLE_BIBLE.md` — the art direction you must stay inside
5. `docs/design/IMPLEMENTATION_PLAN.md` — the contract: read §2 (art crops), §3.11 (`MenuButton` component), §3.12 (theme assignment), §4.3 (current menu structure), and **§9 Phase D amendments** (new viewport, new flow, new theme items, mockup workflow)
6. `docs/design/ASSET_AUDIT.md` — **section E `MENU_V2_SHORTLIST` and section F art gaps**. This is your art palette for this job. Use only the exact `res://` paths it lists, and read its verdicts before choosing.
7. `docs/design/THEME_AUDIO_EXTENSION.md` — the exact new theme items and variations available to you
8. `vajb-orbit/ui/screens/main_menu.tscn` + `main_menu.gd` and `vajb-orbit/ui/components/menu_button.tscn` + `.gd` — the current implementation you are redesigning. Read them; you will keep what works and replace what does not.

## Deliverables

| Action | Path |
|---|---|
| create | `vajb-orbit/ui/screens/_mockup_main_menu.tscn` |
| create (only if it needs code) | `vajb-orbit/ui/screens/_mockup_main_menu.gd` |
| create | `docs/design/MAIN_MENU_V2.md` |
| create | `.agents/gen/d4_report.md` |

Touch nothing else. Do **not** edit `main_menu.tscn`, `main_menu.gd`, `menu_button.tscn`, the theme, any autoload, or `project.godot`.

## The brief

Make the main menu feel **modern, deliberate and responsive**, inside a grimdark industrial space-fiction identity (Dark Orbit lineage): rusted metal, cold void, ember-orange accent, film grain, no glossy sci-fi UI, no drop shadows, no rounded cartoon corners.

Required properties:

1. **Responsive, container-driven.** The current menu is point-anchored with fixed pixel offsets, which is why it desyncs on non-16:9. Rebuild the composition so every region is placed by containers and anchors and stays correct at 1920x1080, 1600x900 and 2560x1440. Say in the spec, per region, which container or anchor preset carries it and what its `size_flags` are. No magic offsets for the major regions.
2. **Keep the verbs.** PLAY, OPTIONS, EXIT, and the version stamp. PLAY's intent becomes `route_requested(&"loading", {destination: &"station"})` per contract §9.2 (note it in the spec; you do not wire the router in a mockup).
3. **Use the unwired art.** The current menu ignores most of what is on disk. Put at least two of the audit's `MENU_V2_SHORTLIST` entries to work (backdrop, insignia, chrome) and say why each earns its place. Every asset path must come from the audit.
4. **Motion with intent.** Specify and implement: an entrance sequence, a hover and focus treatment, an ambient idle layer (the backdrop should breathe or drift), and the button press feel. Give exact durations, easing curves, and what property animates on which node. No `_process` for animation: `Tween` only, created on the owning node, killed in `_exit_tree()` if it outlives it.
5. **Readable hierarchy.** State the type scale you use (the theme now carries `HeroTitle` 48, `MenuButtonPlate` 34, `Version` 13, `default_font_size` 14, and the station variations). Text must be legible against the backdrop at 1920x1080 — prove it by picking backdrop regions that do not fight the text, or by adding a legibility device (gradient scrim, dimmer panel) that is itself justified in the spec.
6. **Keyboard-first.** Focus order, a visible focus ring that is unmistakable at 1 m viewing distance, Esc behaviour unchanged (`quit_confirm` overlay), and hover/focus states that do not rely on colour alone.
7. **`ui_scale` compatibility.** The screen must look correct at `ui_scale` 1.0 and 1.4. Do not hard-code font sizes on nodes; use the theme items, and name every theme item you rely on in the spec.

## Rules for the scene

- Root is a `Control` with the full-rect anchor preset, and it bakes `theme = ExtResource("res://ui/theme/vajb_theme.tres")`.
- No hex literals anywhere. Read colours from the theme (`Tokens` type) as the existing code does.
- No `class_name`, no autoload lookups, no `Router` calls: a mockup must stand alone. If you need a stand-in behaviour, fake it locally in the mockup script and say so in the spec.
- Reuse `menu_button.tscn` for the main verbs if it serves the design; you may propose a replacement component, but then describe its exact node tree and name it in the spec (`_mockup_*` prefix for anything you create in the mockup namespace).
- The mockup must render a complete, presentable screen on its own with zero input.

## `docs/design/MAIN_MENU_V2.md` contents

- **Intent**: one paragraph on what the screen is for and the feeling it must produce.
- **Composition**: the layout grid with coordinates and proportions, per region, plus the responsive rule per region.
- **Node tree**: exact names, types, containers, anchor presets, `size_flags`, `custom_minimum_size`.
- **Type scale**: every text element with its theme item or variation and why.
- **Art map**: every asset with its `res://` path, its role, and its in-scene size and blend mode (remember: backdrops and FX are RGB and must be additive, sprites are RGBA).
- **Motion table**: element, property, from, to, duration, transition, easing, trigger.
- **Focus and input table**: what is focusable, in what order, what each key does.
- **Audio hooks**: which `AudioManager` calls the screen makes and when (the service now has `play_ui`, `play_sfx`, `play_music`, `play_ambience`), naming real files from the audit's shortlist.
- **Implementation notes for the coder**: what to keep from the current `main_menu.tscn`, what to delete, and every constant the coder needs. Be specific enough that the coder never has to invent a value.
- **Open questions** for the owner, if any, at the end.

## `.agents/gen/d4_report.md`

What you built, the exact commands you ran with their output, the headless exit code, your asset list with a verification that each path exists on disk, and anything you could not verify. Measurements, not assertions.

## Rules

- Invent no asset filename, theme item, node name or colour. Every asset path must exist on disk and appear in the audit; every theme item must exist in the generated theme.
- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No comments in code unless the why is non-obvious; no em dashes.
- Another designer is building `_mockup_station.tscn` in the same folders at the same time. Do not touch their files, and do not rename anything they might use.
