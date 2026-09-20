# M1 — Implement the main menu v2 shipping screen

You are a **coder** worker. The design is finished and approved; your job is to build the shipping screen from the spec. **Do not redesign anything.** If the spec is silent on a detail, follow the closest existing convention in the project and say so in your report.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Godot 4.7.2, base render target 1920x1080, stretch `canvas_items`, aspect `expand`.
- **An editor is open on this project (PID 9048). Never run `--headless --editor`.** Never touch `project.godot`, `addons/`, or the theme resource.
- Headless: `"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" res://ui/screens/main_menu.tscn --quit-after 300`
- Kill only a hung Godot of your own; never the editor.

## Read first

1. `AGENTS.md`
2. **`docs/design/MAIN_MENU_V2.md`** — the approved spec. Sections 12 and 15 carry the final numbers (350x70 plates, emblem at `EMBLEM_BRIGHTEN = 2.0`, 6x60 focus tick, the read-out on the `HudReadout` item, the row-height-follows-the-font rule). This document is the single source of truth for geometry, motion and copy.
3. `docs/design/IMPLEMENTATION_PLAN.md` — the binding contract. Read §3.11 (`MenuButton` component), §3.12 (theme assignment), §4.3 (the current menu), §7 (coding rules), and §9 (Phase D amendments: the 1920x1080 base, the new flow, the mockup workflow).
4. `docs/design/UI_SPEC.md` and `docs/design/MAIN_MENU_SPEC.md` — the standing UI laws.
5. The current implementation: `vajb-orbit/ui/screens/main_menu.tscn`, `main_menu.gd`, `ui/components/menu_button.tscn`, `menu_button.gd`, `ui/screens/_mockup_main_menu.tscn`, `_mockup_main_menu.gd` (the approved mockup you are porting).
6. `vajb-orbit/ui/screen.gd` — the screen contract you must satisfy.

## What to build

**1. `ui/screens/main_menu.tscn` + `main_menu.gd`** rebuilt to the spec: container-driven layout (no pinned absolute offsets for the major regions), the 350x70 verb stack, the emblem header, the footer read-out, the version stamp `VAJB ORBIT v0.2`, the entrance motion, the hover and focus treatment, the ambient backdrop layer. Every number comes from the spec.

Contract requirements that must hold:

- Root is a `Control` on the full-rect preset, `extends Screen`, and the `.tscn` bakes `theme = ExtResource("res://ui/theme/vajb_theme.tres")` so F6 works; the router replaces it at runtime.
- Intents only, never `change_scene_to_*`:
  - PLAY → `route_requested(&"loading", {destination: destination})` where `destination` is `&"station"` when `UIPaths.route_exists(&"station")` is true and `&"game"` otherwise. This guard is deliberate: the station route does not exist yet at the time you write this, and PLAY must not break. Use the constant `UIPaths` (`res://ui/paths.gd`) for the check.
  - OPTIONS → `overlay_requested(&"settings", {})`
  - EXIT → `overlay_requested(&"quit_confirm", {})`
  - `ui_cancel` → `overlay_requested(&"quit_confirm", {})`, skipped while `Router.overlay_depth() > 0` (keep the existing guard).
- Focus: order PLAY, OPTIONS, EXIT; PLAY focused on entry and on `on_route`; the ring must be unmistakable; `Router.overlay_popped` returns focus to the opener as the current screen does.
- Audio: start the menu music with `AudioManager.play_music(&"mus_menu_theme_01")` and stop it in `_exit_tree()`, and keep the hover and click calls on the verbs.
- Row heights must follow the font (the spec's rule) so `ui_scale` 1.0, 1.2 and 1.4 all keep a constant visual gap. No pinned row height anywhere.
- No `_process` for animation: `Tween`s on the owning node only, killed in `_exit_tree()` when they outlive their node.
- No hex literals; read colours from the theme. No comments unless the why is non-obvious.

**2. `ui/components/menu_button.tscn` + `menu_button.gd`** — update the component to the new geometry (350x70) while preserving its published interface: the root keeps its script, the inner child must stay named `Button`, the `pressed` / `hovered` / `unhovered` signals must keep working, the screen still owns the `AudioManager` calls, and the 1 px border/focus behaviour from §3.11 must survive. If the spec's design no longer needs a separate component, say so and justify it in your report rather than silently deleting it.

**3. Delete the mockup** once the shipping screen passes verification: `ui/screens/_mockup_main_menu.tscn`, `_mockup_main_menu.gd`, `_mockup_main_menu.gd.uid`. This is required by contract §9.6. Confirm in your report that the paths are gone.

**4. Do NOT add the station route to `ui/paths.gd`.** A parallel worker owns that file for the station wave. You only read `UIPaths.route_exists`.

## Verification (measurements, not assertions)

1. Headless run of `res://ui/screens/main_menu.tscn`, exit 0, clean stdout.
2. Headless run of `res://ui/screens/boot.tscn`, `res://ui/screens/settings.tscn` and `res://game/game.tscn`: all exit 0, no new errors or warnings. Your menu is the entry point of the whole flow; nothing may regress.
3. Prove the row-height rule: run a probe or a scripted check at `ui_scale` 1.0, 1.2 and 1.4 and report the plate box, the row pitch and the measured gap at each. A throwaway probe at `res://tools/_probe_m1.gd` (`extends SceneTree`, calls `quit()`) is fine; delete it and its `.uid` afterwards and confirm `tools/` holds only `build_theme.gd` and `derive_icon_tints.gd` plus their sidecars.
4. Confirm the focus ring is exactly 1 px and that every asset path you reference resolves on disk.
5. `user://settings.cfg` must be byte-identical before and after. Report its sha256 for both. Do not touch `user://profile.cfg`.
6. Report the exact commands and their output in `.agents/gen/m1_report.md`, plus anything you could not verify and any place you had to make a judgement call.

## Files you own

`ui/screens/main_menu.tscn`, `main_menu.gd`, `ui/components/menu_button.tscn`, `menu_button.gd`, the mockup deletion, `.agents/gen/m1_report.md`. Nothing else. In particular not `ui/paths.gd`, `ui/screens/loading.gd`, `game/game.gd`, the theme, `project.godot`, or any `ui/station/` file.

## Rules

- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`. Prefer separate calls.
- No em dashes in code or config.
- Never edit a file you have not read in this session.
- If the spec contradicts the frozen contract, follow the spec and say so in your report.
