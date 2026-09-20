# D4c — Main menu v2 mockup: final revision (scale + emblem)

You are a **designer** worker (Godot 4.7 UI scene medium). The mockup and spec are approved in substance; two final owner decisions must be applied before the coder wave implements them.

## State you inherit

- `vajb-orbit/ui/screens/_mockup_main_menu.tscn` + `.gd` — the revised mockup (housing removed, emblem header, `VAJB ORBIT v0.2`).
- `docs/design/MAIN_MENU_V2.md` — the spec, section 14 now lists resolved decisions.
- `.agents/gen/d4b_report.md` — the previous revision's measurements.
- `.agents/gen/previews/d4b_menu_v2_rev_1920x1080_preview.jpg` — the render the owner saw.

Read all four, plus `.agents/gen/d4_task.md` (the original specification) before changing anything.

## The two decisions to apply

1. **Scale the verb stack up about 25 percent.** Plates go from 280x56 to **350x70**, the emblem block and the read-out grow to stay in proportion, and the stack keeps its left alignment and its position. The button type does **not** change size (the theme's `MenuButtonPlate` stays 34 px); this is a geometry change only, so record in the spec exactly which properties change (the `custom_minimum_size`, the container separation, any offsets) and what stays. The 1 px border must stay exactly 1 px: it is drawn from the plate texture's nine-patch, so confirm by measuring a border run in the render, not by assuming.
2. **Brighten the emblem.** The emblem currently reads as a dark blob. Brighten it so its highlights clear **4.5:1** measured against the actual backdrop-plus-grain behind it, without making it look like a UI button: it is a stamp, not an icon in a frame. Use a theme token or a `modulate` with a documented value; if no token reaches the target, say so and pick the closest token, then report the achieved ratio and the shortfall instead of inventing a colour. Do not add a panel or a frame behind it.

## Also required in this pass

**Row height must follow the font, not a constant.** At `ui_scale` 1.4 the plate buttons grow to 67 px inside a 56 px row, tightening the separation from 14 px to 3 px. Fix that in the mockup so the stack's rows are font-driven: the row height must come from the button's minimum size rather than a pinned constant, and the separation must stay visually constant at `ui_scale` 1.0, 1.2 and 1.4. Prove it with measurements at all three scales, and write the rule into the spec as an implementation instruction for the coder: no pinned row height in the shipping scene.

## Verification

1. Headless: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300` exits 0, clean stdout.
2. Re-render at 1920x1080 and at `ui_scale` 1.4, plus one 1600x900 geometry capture. Save to `.agents/gen/previews/` as `d4c_menu_v2_*`.
3. Measure with `py -3.14` and Pillow, and report the numbers: each plate's box, the border run thickness, the separation at 1.0 / 1.2 / 1.4, the emblem's brightest highlight luminance and its contrast ratio, the read-out and version stamp contrast, and that nothing clipped or moved off-screen at 1600x900.
4. Confirm every `res://` path in the spec resolves on disk.
5. Leave `user://settings.cfg` exactly as you found it if you touch it at all, and report its sha256 before and after.

## Files you may write

- `vajb-orbit/ui/screens/_mockup_main_menu.tscn` and `.gd`
- `docs/design/MAIN_MENU_V2.md`
- `.agents/gen/d4c_report.md`
- `.agents/gen/previews/` (your renders)

Touch nothing else: not `main_menu.tscn`, not the theme or `tools/build_theme.gd` (the panel-frame margin was just corrected to 8 px by the orchestrator; do not revert or re-run the generator), not `router.gd`, not `project.godot`, not the station files.

## Rules

- An editor is open (PID 9048). Never run `--headless --editor`. Never touch `project.godot` or `addons/`.
- No hex literals; colours come from the theme.
- No `class_name`, no autoload calls, no `Router` calls in the mockup.
- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No em dashes. No comments in code unless the why is non-obvious.
- Measurements, not assertions.
