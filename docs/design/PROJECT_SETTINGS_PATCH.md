# PROJECT_SETTINGS_PATCH — `project.godot` changes for Phase C

**Emitted by:** W0 worker (the `autoload/` services half of W0).
**Applied by:** the orchestrator, through the live `godot-ai` editor. No worker writes `project.godot`
— the open editor holds that file in memory and would clobber a file write
(IMPLEMENTATION_PLAN §1, §5).

**Machine-readable.** Every applyable section is a fenced `json` block; §0 and §5 are the only prose
that changes how the blocks are used. No key in this document is optional.

## 0. Apply order (order is significant)

1. **Autoloads (§1)** — add in the listed order. `autoload_manage(op="add")` appends, and the four
   services read each other during `_ready()`, so `SettingsManager` must be registered before
   `AudioManager`, and `Router` before `DialogManager`.
2. **Input actions (§2)** — `input_map_manage(op="ensure_action")`, then
   `input_map_manage(op="ensure_binding")` with the listed keycode name.
3. **Audio buses (§3)** — nothing to apply: the tree is built at runtime by `AudioManager._ready()`.
   The block is the record of names and seeded volumes.
4. **`main_scene` (§4)** — **apply only after W1 lands `boot.tscn`.** The file does not exist yet, and
   `project_manage(op="set_main_scene")` refuses a scene that is not on disk.
5. **`filesystem_manage(op="scan")`** so the new `class_name` scripts (`UIPaths`, `Screen`) enter the
   global class table, then re-read `project.godot` to confirm.

`_mcp_game_helper` (godot-ai) is already present and stays **first and untouched**. Nothing in
`addons/godot_ai/` is ever edited (AGENTS.md).

## 1. Autoloads

```json
{
  "autoloads": [
    {
      "order": 0,
      "name": "_mcp_game_helper",
      "path": "res://addons/godot_ai/runtime/game_helper.gd",
      "singleton": true,
      "apply": "leave exactly as-is"
    },
    {
      "order": 1,
      "name": "SettingsManager",
      "path": "res://autoload/settings_manager.gd",
      "singleton": true,
      "apply": "autoload_manage(op=\"add\", params={name, path, singleton:true})"
    },
    {
      "order": 2,
      "name": "AudioManager",
      "path": "res://autoload/audio_manager.gd",
      "singleton": true,
      "apply": "autoload_manage(op=\"add\", params={name, path, singleton:true})"
    },
    {
      "order": 3,
      "name": "Router",
      "path": "res://autoload/router.gd",
      "singleton": true,
      "apply": "autoload_manage(op=\"add\", params={name, path, singleton:true})"
    },
    {
      "order": 4,
      "name": "DialogManager",
      "path": "res://autoload/dialog_manager.gd",
      "singleton": true,
      "apply": "autoload_manage(op=\"add\", params={name, path, singleton:true})"
    }
  ],
  "autoload_count_after_apply": 5,
  "expected_project_godot_block": {
    "_mcp_game_helper": "*res://addons/godot_ai/runtime/game_helper.gd",
    "SettingsManager": "*res://autoload/settings_manager.gd",
    "AudioManager": "*res://autoload/audio_manager.gd",
    "Router": "*res://autoload/router.gd",
    "DialogManager": "*res://autoload/dialog_manager.gd"
  }
}
```

Dependencies created by that order: `AudioManager` reads `SettingsManager` for the seeded bus volumes;
`Router` reads `SettingsManager.ui_scale()` for `live_theme()` and `AudioManager` for nothing;
`DialogManager` drives `Router.push_overlay`/`pop_overlay`. Every lookup is tolerant, so a missing
service degrades to defaults instead of crashing.

## 2. Input actions

17 actions, in the contract §3.7 order. The settings Controls tab lists exactly this list and no
other action; `ui_*` actions are engine defaults, are not rebindable, and must not be created or
modified here.

```json
{
  "input_actions": [
    {"order": 1,  "action": "thrust_forward",  "deadzone": 0.5, "events": [{"type": "key", "keycode": "W"}]},
    {"order": 2,  "action": "thrust_backward", "deadzone": 0.5, "events": [{"type": "key", "keycode": "S"}]},
    {"order": 3,  "action": "turn_left",       "deadzone": 0.5, "events": [{"type": "key", "keycode": "A"}]},
    {"order": 4,  "action": "turn_right",      "deadzone": 0.5, "events": [{"type": "key", "keycode": "D"}]},
    {"order": 5,  "action": "fire_primary",    "deadzone": 0.5, "events": [{"type": "key", "keycode": "Space"}]},
    {"order": 6,  "action": "fire_secondary",  "deadzone": 0.5, "events": [{"type": "key", "keycode": "Ctrl"}]},
    {"order": 7,  "action": "mine",            "deadzone": 0.5, "events": [{"type": "key", "keycode": "E"}]},
    {"order": 8,  "action": "boost",           "deadzone": 0.5, "events": [{"type": "key", "keycode": "Shift"}]},
    {"order": 9,  "action": "cargo_toggle",    "deadzone": 0.5, "events": [{"type": "key", "keycode": "C"}]},
    {"order": 10, "action": "weapon_1",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "1"}]},
    {"order": 11, "action": "weapon_2",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "2"}]},
    {"order": 12, "action": "weapon_3",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "3"}]},
    {"order": 13, "action": "weapon_4",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "4"}]},
    {"order": 14, "action": "weapon_5",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "5"}]},
    {"order": 15, "action": "target_next",     "deadzone": 0.5, "events": [{"type": "key", "keycode": "Q"}]},
    {"order": 16, "action": "interact",        "deadzone": 0.5, "events": [{"type": "key", "keycode": "F"}]},
    {"order": 17, "action": "warp",            "deadzone": 0.5, "events": [{"type": "key", "keycode": "H"}]}
  ],
  "input_action_count": 17,
  "keycode_names": "Godot keycode name strings accepted by input_map_manage(op=\"bind_event\", event_type=\"key\", keycode=...)",
  "notes": [
    "Tab is reserved by ui_focus_next, so target_next uses Q (contract §3.7).",
    "Space is also part of the engine default ui_accept; that overlap is accepted for Phase C and is a known gameplay/UI interaction to revisit when a combat spec lands.",
    "Left Ctrl is bound as the Ctrl keycode with no modifier flags.",
    "User rebinding writes user://inputs.cfg at runtime; project.godot keeps only these defaults.",
    "interact (F, dock/gate prompts) and warp (H, safe warp) are the ENGINE_SPEC §11 additions of the 2026-09-18 engine wave; they are appended so the existing 15 keep their order. Code reading them must be guarded with InputMap.has_action until they are applied.",
    "ui_cancel (ESC) keeps its engine-default binding and is not touched by this patch; only its in-game meaning changes (cancel fly-to order + lock; ESC docking is retired by ENGINE_SPEC decision 3, docking is the interact prompt)."
  ]
}
```

## 3. Audio buses and seeded linear volumes

Nothing here is written to `project.godot`. `AudioManager._ready()` builds the AUDIO_SPEC §4.3 tree
with `AudioServer.add_bus()` / `set_bus_name()` / `set_bus_send()`. `Master` already exists as bus 0.
The linear defaults are seeded into `user://settings.cfg` by `SettingsManager` and applied to those
buses at startup (contract §3.6).

```json
{
  "audio_buses": [
    {"name": "Master",    "send": null,     "is_new": false, "default_linear": 1.0,        "default_db": 0.0},
    {"name": "Music",     "send": "Master", "is_new": true,  "default_linear": 0.39810717, "default_db": -8.0},
    {"name": "SFX",       "send": "Master", "is_new": true,  "default_linear": 0.50118723, "default_db": -6.0},
    {"name": "UI",        "send": "Master", "is_new": true,  "default_linear": 0.31622777, "default_db": -10.0},
    {"name": "SFXWeapon", "send": "SFX",    "is_new": true,  "default_linear": 1.0,        "default_db": 0.0},
    {"name": "SFXImpact", "send": "SFX",    "is_new": true,  "default_linear": 1.0,        "default_db": 0.0},
    {"name": "SFXWorld",  "send": "SFX",    "is_new": true,  "default_linear": 1.0,        "default_db": 0.0}
  ],
  "audio_bus_count": 7,
  "bus_layout_file": "none — no default_bus_layout.tres is shipped (AUDIO_SPEC §4.3 leaves that open; contract §3.8 chooses the code path)",
  "source_of_defaults": "AUDIO_SPEC §4.3 mixing levels: Master 0 dB, Music -8 dB, SFX -6 dB, UI -10 dB. The sub-buses are unattenuated and inherit the SFX level through the send.",
  "contract_note": "IMPLEMENTATION_PLAN §3.6 writes the audio defaults as `db_to_linear(-8/-6/-6/-10)` against the keys master/music/sfx/ui. Read per-key that would put Master at -8 dB and duplicate -6 dB for music and sfx, which contradicts the AUDIO_SPEC §4.3 levels it cites (and would double-attenuate music through the Master send). This patch uses the AUDIO_SPEC levels mapped to the right buses: master 0 dB, music -8 dB, sfx -6 dB, ui -10 dB."
}
```

## 4. Main scene

```json
{
  "main_scene": {
    "path": "res://ui/screens/boot.tscn",
    "apply": "project_manage(op=\"set_main_scene\", params={path})",
    "apply_when": "ONLY AFTER W1 LANDS boot.tscn",
    "ready_now": false,
    "reason": "boot.tscn does not exist yet; set_main_scene validates that the scene loads as a PackedScene and will refuse"
  }
}
```

`editor/run/main_run_args` is unchanged and stays empty. With `main_scene` unset, running the project
opens an empty window — expected until W1 lands.

## 5. Deliberately not part of this patch

```json
{
  "not_in_patch": [
    {"key": "resolution / display_mode / vsync / render_scale", "owner": "SettingsManager", "where": "user://settings.cfg, applied through DisplayServer/Window at startup", "path_in_patch": null},
    {"key": "audio bus volumes", "owner": "SettingsManager + AudioManager", "where": "user://settings.cfg, applied to the runtime buses", "path_in_patch": null},
    {"key": "effects_quality", "owner": "SettingsManager", "where": "stored only in v1 (documented no-op, contract §3.6)", "path_in_patch": null},
    {"key": "audio bus layout resource", "owner": "AudioManager", "where": "built in _ready(), no .tres", "path_in_patch": null},
    {"key": "input bindings", "owner": "SettingsManager", "where": "user://inputs.cfg; this patch only creates the actions and their default events", "path_in_patch": null},
    {"key": "gui/theme/custom*", "owner": "nobody", "where": "the live theme is assigned by Router.live_theme() at runtime; scenes bake ui/theme/vajb_theme.tres themselves", "path_in_patch": null}
  ]
}
```

## 6. Confirmation after applying

```json
{
  "verify": [
    {"op": "autoload_manage(op=\"list\")", "expect": "5 entries; _mcp_game_helper first, then SettingsManager, AudioManager, Router, DialogManager"},
    {"op": "input_map_manage(op=\"list\")", "expect": "exactly the 17 user actions above, in order, one key event each"},
    {"op": "filesystem_manage(op=\"scan\")", "expect": "scan_completed true; UIPaths and Screen register as global classes"},
    {"op": "filesystem_manage(op=\"read_text\", params={path:\"res://project.godot\"})", "expect": "[autoload] holds the 5 entries in the order above and nothing else changed"},
    {"op": "project_manage(op=\"settings_get\", params={key:\"application/run/main_scene\"})", "expect": "empty until W1 lands, then res://ui/screens/boot.tscn"}
  ]
}
```
