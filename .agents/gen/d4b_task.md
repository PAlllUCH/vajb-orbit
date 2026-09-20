# D4b — Main menu v2 mockup: revision pass

You are a **designer** worker (Godot 4.7 UI scene medium). The mockup and its spec already exist and the owner has reviewed a render of it, giving five decisions. Your job is to apply those decisions, re-render, re-measure, and bring the spec in line. This is a revision, not a rebuild: keep everything the decisions do not touch.

## What exists

- `vajb-orbit/ui/screens/_mockup_main_menu.tscn` + `.gd` — the approved mockup.
- `docs/design/MAIN_MENU_V2.md` — the spec, with the owner's questions answered in section 14.
- `.agents/gen/d4_report.md` — the previous run's measured evidence.
- `.agents/gen/previews/menu_v2_mockup_1920x1080.jpg` — the render the owner saw.

Read all four, plus the original brief `.agents/gen/d4_task.md` (still the specification of the screen), before changing anything.

## The owner's five decisions

1. **Drop the metal housing panel.** Remove the `ui_panel_frame.png` rail around the three verbs entirely, and remove every node that existed only to carry it. The plates float on the scrimmed vista. The chrome role on this screen is deliberately given up: do not substitute another frame or border device for it, and do not re-use the panel frame elsewhere on the menu.
2. **The version stamp reads `VAJB ORBIT v0.2`** exactly, and it must be **brighter**: pick the token that clears 4.5:1 measured contrast against the actual backdrop-plus-grain it sits on. If no existing token clears it, add a stamp-specific colour as a theme item through `tools/build_theme.gd` and re-generate, or raise the stamp's own type variation. Do not touch the grain layer: the owner declined the grain change.
3. **Keep the three footer read-outs** exactly as they are: `ENTER THE STATION HUB`, `OPEN SYSTEM AND INTERFACE SETTINGS`, `END THE SESSION`.
4. **Accept the 14 percent vertical plate stretch at `ui_scale` 1.4.** Record it in the spec as accepted behaviour, with the reason, and remove the open question.
5. **Keep the insignia emblem**, but it must no longer depend on the housing for its place (see below).

## What to do about the emblem and the caption

With the rail gone, the emblem and the `COMMAND` caption lose their frame. Re-compose them as a lightweight header group sitting above the verb stack: the emblem plus the caption, aligned to the same left edge as the plates, no panel behind them. If the caption reads as noise without the frame, keep the emblem and drop the caption; decide by looking at the render, and say which you chose and why in the report. Either way the emblem stays on screen: it is the only use of the insignia asset on this menu, and the audit lists it as a role worth spending.

## Required verification

1. Headless: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/_mockup_main_menu.tscn --quit-after 300` exits 0, clean stdout.
2. Re-render at 1920x1080 and at 1600x900 with the same `--write-movie` method you used before, write both to `.agents/gen/previews/` with names that say which is which, and **measure** the frames with `py -3.14` and Pillow:
   - the absence of the housing (there is no frame border in the region the rail used to occupy),
   - the position and ink extent of each remaining element,
   - the version stamp's string is confirmable from the spec, and its measured contrast ratio is at or above 4.5:1 against the pixels behind it,
   - the read-out, verb and caption contrast ratios,
   - that the composition still holds at 1600x900 (no clipping, no overlap, no element off-screen).
3. Confirm `ui_scale` 1.0 and 1.4 still behave, and that every asset path in the spec still resolves on disk.

## Files you may write

- `vajb-orbit/ui/screens/_mockup_main_menu.tscn` and `.gd` (edit in place)
- `docs/design/MAIN_MENU_V2.md` (update; section 14 becomes "Resolved decisions" with all five and their outcomes, and a fresh short list of any new open questions)
- `.agents/gen/d4b_report.md`
- `.agents/gen/previews/` (your renders)
- `vajb-orbit/tools/build_theme.gd` and the regenerated `vajb-orbit/ui/theme/vajb_theme.tres` **only if** decision 2 forces a new theme item; if you do, you must also add any new font-size item to `Router.FONT_SIZE_ITEMS` in `vajb-orbit/autoload/router.gd` so `ui_scale` still reaches it, and you must report the before/after item count.

Touch nothing else. In particular do not edit `main_menu.tscn`, `menu_button.tscn`, any autoload other than `router.gd`'s font list, `project.godot`, or the station mockup (`_mockup_station.*`, `STATION_HUB.md`) which a parallel worker owns.

## Rules

- An editor is open on this project (PID 9048). Never run `--headless --editor`. Never touch `project.godot` or `addons/`.
- No hex literals; colours come from the theme.
- No `class_name`, no autoload calls, no `Router` calls in the mockup.
- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No em dashes. No comments in code unless the why is non-obvious.
- Measurements, not assertions. State plainly anything you could not verify.
