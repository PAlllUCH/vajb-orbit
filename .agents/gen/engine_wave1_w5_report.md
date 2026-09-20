# Engine wave 1 — W5 report (HUD pass)

Worker: **W5**. Status: **done; acceptance measured clean (HUD probe 56 checks / 0 failures,
flight-scene probe 10 / 0, both boot gates clean, P1 suite 53/53)**, with the deviations and open
points in §6. Brief: `.agents/gen/engine_wave1_task.md` §W5 + the global rules. Contract:
`ENGINE_SPEC.md` §7 (dock prompt, safe warp), §8 (blip classes) and §10 (HUD/UX additions);
`docs/design/IMPLEMENTATION_PLAN.md` §3.10 (frozen `Hud` API and the 2026-09-18 amendment), §4.7
(forced structure), §9.9 (engine-wave amendments and retirements), `docs/design/UI_SPEC.md` §3
(HUD structure, §3.1 bar law, §3.3 minimap classes, §3.5 reticle).

Read first, in order: `AGENTS.md`, `ENGINE_SPEC.md` §2/§7/§8/§9/§10/§13/§14, this brief, then the W0
(doc freeze) and W1–W4 reports for the landed interfaces.

No number below originates in this worker: every gameplay value cited (220 u beam, 0-or-less hides,
1920×1080) is the spec's or a shipped scene's. The one class of new values is **presentation
geometry** (draw offsets, bar size, glyph radius), which no doc pins; §6 item 4 lists every one of
them for the audit.

---

## 0. Files changed (before → after) and scope proof

Measured with `py -3.14` (the interpreter AGENTS.md mandates). All four files are LF-only
(`crlf=0`), tab-indented (`0` lines starting with four spaces), with no hex literal, no
`get_node(`, no `print(` and no `_process`.

| File | Bytes | Lines | Δ | md5 after |
|---|---:|---:|---:|---|
| `vajb-orbit/ui/hud/hud.gd` | 18 978 → **21 142** | 567 → **630** | +2 164 B, +63 L | `0AE885ACDC87F6DC06ED5480F7419BBE` |
| `vajb-orbit/ui/hud/hud.tscn` | 17 210 → **18 780** | 542 → **592** | +1 570 B, +50 L | `343D63F205AAF24282AE5BFB908FE674` |
| `vajb-orbit/ui/hud/minimap.gd` | 4 610 → **5 698** | 144 → **173** | +1 088 B, +29 L | `8EB85539C5E7924A5152422CB2AD1675` |
| `vajb-orbit/ui/hud/target_reticle.gd` | 2 101 → **6 553** | 78 → **215** | +4 452 B, +137 L | `98FEA21048E6746F9B6D3ACA2DF7BDD5` |

Total +9 274 bytes, +279 lines, no file created or deleted. `target_reticle.gd` is the one file
beyond the brief's list — §6 item 1 carries the justification and the reversal path; the other three
are the listed pair plus the minimap (allowed "only if the blip-kind change requires it", and it
does: the friendly class needs its own colour and glyph).

**Untouched, measured.** `vajb-orbit/ui/theme/vajb_theme.tres` 25 771 B, md5
`F0BF1B434CB19EDD0FEE7001B17632B4`, mtime **15:16:36** (fix wave 1) — the theme was not written, so
this pass cannot have added a theme item. `tools/build_theme.gd` md5
`3962995AA4E7C48E02B647A4B5DA630D`, mtime 15:11:39. `game/game.gd` md5
`03144938FA5FDB92D30CBD5AA6DB8914`, mtime 16:21:21 (W2's). `project.godot` md5
`1E69D6C2F84C9FAF26F631FDBD202A7B`, mtime 15:25:32. No `docs/`, `assets/`, `addons/` or
`autoload/` byte was written; no editor instance was launched and no reimport was run.

**Scope proof** (mtime scan of everything under `vajb-orbit/`, `addons/` and `.godot/` excluded, 90
minute window; 26 entries, of which these four are this worker's):

```
17:08:59 ui\hud\target_reticle.gd   <- this worker
17:09:48 ui\hud\minimap.gd          <- this worker
17:14:57 ui\hud\hud.tscn            <- this worker
17:16:11 ui\hud\hud.gd              <- this worker
```

The other 22 entries are W1–W4's `game/` files and their `.uid` sidecars (16:16–17:02). Recorded so
the picture is unambiguous, not this worker's: `user://economy_log.txt` (17:09:49) and
`user://profile.cfg` (17:09:50) moved during the window while this worker's first probe ran at
17:12:37 — §4.5 shows the owner's profile was neither read nor written by W5 (md5
`248E69488904A91F88E0FFE1D05C82EE`, mtime 17:09:50 before and after).

`vajb-orbit/tools/` ends holding only `build_theme.gd` (+`.uid`) and `derive_icon_tints.gd`
(+`.uid`); the four probe files and their `.uid` sidecars were deleted after the final run (§4.6).

---

## 1. What was implemented, per brief item

### 1.1 `set_prompt(text: String)` — the interaction prompt strip

`hud.gd` gains the public setter and a private renderer; `hud.tscn`'s `BottomCenter` zone gains
`PromptBlock` → `PromptLabel`. An empty string hides the label, identical text is a no-op
(`_prompt_text` mirror), and the label keeps the retired hint's exact slot and styling
(`StationCaption`, 13 px, centred, full-width rect `P(12,1042) S(1896,18)`; measured — §3.2).

`game.gd` already pushes `"F · DOCK"` / `""` through its `has_method`-guarded `_push_prompt`
(W2, `game.gd:346`), so the strip is live in the shipped scene the moment W5 landed (§5.4).

### 1.2 `set_warp_channel(progress: float)` — the safe-warp bar

`hud.gd` gains the setter (clamped to 0…1; progress ≤ 0 hides) plus `_apply_warp_channel()`;
`hud.tscn` gains `WarpBlock` (hidden by default) holding a `WARP` caption, a percent readout and the
bar. Styling uses **existing theme items only**: caption `StationCaption`, readout `HudReadout`,
bar the `HudShieldBar` `ProgressBar` variation (steel fill on `progress_bg`). Ember is deliberately
not used — STYLE_BIBLE §7.3 and UI_SPEC §3.1 reserve it for warnings/hostile/critical, and a warp
channel is neither (§6 item 5).

W2's `_push_warp_channel` (`game.gd:354`) already drives it on 0…1, and its `_cancel_warp` pushes
`0.0`, which now hides the bar. Measured through the flight scene: hidden → `1.1` → `12.2` →
hidden on cancel (§5.3).

### 1.3 Friendly blips

`minimap.gd` gains `KIND_FRIENDLY` = `&"friendly"`, its own `COLOR_FRIENDLY` (`text_primary`, from
the theme), and a distinct glyph: friendly blips are drawn as a **diamond** (`draw_colored_polygon`,
`FRIENDLY_RADIUS` 3.0) while self/hostile/neutral stay circles (self 3.0, others 2.0). Reason: the
station is the one landmark that can sit right next to the always-centred self blip, and UI_SPEC
§3.3's palette leaves friendly and self sharing `text_primary` (ember is unavailable) — shape is
what keeps them apart (§6 item 6). An unknown kind still falls through to `neutral`, so
ENGINE_SPEC §8's "POI subkinds ride as data on the blip dict" needs no code: extra keys are simply
ignored by the draw.

### 1.4 Cursor reticle with plain / in-range / out-of-range / hostile states

`target_reticle.gd` becomes a two-mode reticle, and `hud.gd` relays the state:

- **Cursor mode** (the default, and the only mode slice 1 reaches): the Control is centred on the
  pointer and `_draw_cursor()` selects by state — `PLAIN` / `HOSTILE` draw the offset crosshair (4
  ticks + centre dot), `IN_RANGE` / `OUT_OF_RANGE` draw the mining focus box (4 corner brackets at
  `CURSOR_RADIUS`), and `OUT_OF_RANGE` adds the range slash. Colours are theme tokens only:
  `accent_danger` for hostile, `text_primary` for in-range ("beam reaches it"), `text_dim` for plain
  and out-of-range. Slice 1 scope is the spec's: plain + mining states (ENGINE_SPEC §10, §9.9);
  `HOSTILE` ships as the drawn state so slice 2 only has to supply the reading.
- **Tracking** needs no caller and no per-frame poll: the reticle takes the pointer position from
  its own `InputEventMouseMotion` (`_input`, which never consumes the event) and seeds the current
  position in `_ready`; `set_cursor_position(screen_position)` remains available for a caller or a
  probe. `_process` and `_physics_process` stay absent from the file.
- **Lock mode** (the frozen §3.10 pair, untouched in meaning): `set_target(screen_position,
  hull_fraction)` draws UI_SPEC §3.5's four 8 px corner brackets + the 60×4 hull micro-bar at the
  marked target, exactly as shipped; `clear_target()` returns the draw to the cursor reticle, which
  is always visible now, so the lock's brackets and micro-bar are what appear and disappear
  (§6 item 2 carries the semantics change and its reversal).
- **Hardware cursor unchanged**: `Input.mouse_mode` is neither read nor set anywhere in the HUD; the
  reticle is drawn *around* the pointer, with `mouse_filter = IGNORE` on everything so it never eats
  a click (measured, §5.2).

`hud.gd` exposes `set_reticle_state(state: int)` (clamped into the enum's range) which relays to
`TargetReticle.set_state`; the enum is `TargetReticle.State` so the state and the draw have one
home. **Open point for the orchestrator/W6: no slice-1 caller pushes the state yet** — W5's file
list excludes `game.gd`, and W2 shipped before this API existed. §7 carries the exact one-line
refresh to add, using W3's already-published `MiningLaser.is_active()` / `has_target()`.

### 1.5 The static ESC hint retires

`hud.tscn`'s `DockHint` label (text `ESC · DOCK AT KEPLER-9`, §9.8 item 4) is gone; its node is
replaced by the prompt strip of §1.1. Measured: no node in the instantiated HUD carries that string
(21 labels scanned) and `find_child("DockHint")` returns null (§5.2).

### 1.6 The frozen API stays intact

Additions only. All eight §3.10 methods (`bind`, `set_sector_name`, `set_minimap_scale`,
`set_minimap_blips`, `set_target`, `set_target_info`, `clear_target`, `set_cargo_open`) and all three
signals are present and unchanged, `set_target`/`clear_target` are kept (unused until slice 2), and
the `HUD_METHODS`/`HUD_SIGNALS` guard lists in `game.gd` still pass (`_hud_api_ready` verified live,
§5.4). `hud.gd`'s `bind` → `PlayerState` path is re-measured end to end (§5.1).

**Out of scope, deliberately (slice 2/3, not shipped):** reticle hit markers (they are combat
feedback, ENGINE_SPEC §4.2; slice 1 has no damage source), the `set_target_info` range state (needs
a selected weapon's range and a target), and POI subkinds (needs slice 3's POIs). None is
half-implemented and none adds dead API surface.

---

## 2. Pinned-interface conformance (brief "Pinned interfaces" item 9 + §W5)

| Pinned requirement | Implementation |
|---|---|
| `set_prompt(text: String)` (empty hides) | `hud.gd:237`, `_apply_prompt()` at `hud.gd:493` |
| `set_warp_channel(progress: float)` (≤ 0 hides) | `hud.gd:247`, `_apply_warp_channel()` at `hud.gd:500` |
| blip kinds gain `&"friendly"` | `minimap.gd` `KIND_FRIENDLY` / `COLOR_FRIENDLY` / `_draw_blip()` |
| reticle drawn at the cursor, plain/in-range/out-of-range states (slice 1: plain + mining) | `target_reticle.gd` `enum State`, `_draw_cursor()`, `_input()`; relay `hud.gd:258` |
| static `ESC · DOCK AT KEPLER-9` hint retires | `hud.tscn` `DockHint` deleted, replaced by `PromptBlock` |
| frozen HUD API intact, additions only; `set_target`/`clear_target` stay | §1.6, probed (§5.1) |
| existing theme items only (`StationCaption`, `HudReadout`), no new theme items, no font-size overrides | §1.1/§1.2 + §0 theme md5/mtime + measured `has_theme_*_override == false` (§5.3) |
| `ui/hud/minimap.gd` only if the blip change requires it | required: friendly needs a colour + glyph |
| acceptance: probe loads `hud.tscn` at 1920×1080, calls the new methods, verifies visibility states + blip kinds, no parse errors | §4/§5: 56 checks, 0 failures, exit 0 |

**Scene inventory added** (`hud.tscn`), all `mouse_filter = 2` (IGNORE):

```
BottomCenter (MarginContainer, PRESET_BOTTOM_WIDE, margins 12/12/12/20)   [pre-existing zone]
└─ PromptBlock (VBoxContainer, separation 6)
   ├─ WarpBlock (VBoxContainer, visible=false, SIZE_SHRINK_CENTER, separation 2)
   │  ├─ WarpHeader (HBoxContainer, min 260×0, separation 6)
   │  │  ├─ WarpCaption (Label, StationCaption, "WARP")
   │  │  ├─ WarpSpacer (Control, EXPAND)
   │  │  └─ %WarpValue (Label, HudReadout)
   │  └─ %WarpBar (ProgressBar, min 260×14, HudShieldBar, max 100, show_percentage=false)
   └─ %PromptLabel (Label, StationCaption, centred, empty)
CenterOverlay/TargetReticle (now drawn without a target; ReticleBarBox starts hidden)
```

---

## 3. Geometry and layout measurements (all in the project's 1920×1080 logical space)

### 3.1 Viewport

`viewport = (1920.0, 1080.0)`, `hud size = (1920.0, 1080.0)` — the acceptance resolution, from the
project's `viewport_width/height` (§9.1) rather than a probe-side override.

### 3.2 Prompt strip

| State | visible | text | variation | font size | colour | rect |
|---|---|---|---|---|---|---|
| boot | false | `''` | `StationCaption` | 13 | `text_dim` `(0.4196,0.4549,0.5176)` | `P(12,1042) S(1896,18)` |
| `set_prompt("F · DOCK")` | true | `F · DOCK` | `StationCaption` | 13 | `text_dim` | `P(12,1042) S(1896,18)` |
| `set_prompt("")` | false | `''` | — | — | — | — |

The rect is **identical to the retired hint's** measured rect (`fix_wave1_w3_report.md` §4 item 2:
`(12,1042)–(1908,1060)`, bottom gap 20): the strip replaces the hint in its own slot rather than
moving it. `has_theme_font_size_override` and `has_theme_color_override` are both false.

### 3.3 Warp bar

| `progress` | block visible | bar value / max | readout |
|---|---:|---:|---|
| boot (`-1`) | false | 0 / 100 | — |
| `0.4` | true | **40.0** / 100 | `40%` |
| `1.0` | true | **100.0** / 100 | `100%` |
| `0.0` | false | (100.0 left) | — |
| `-3.0` | false | — | — |
| `2.5` | true | **100.0** / 100 (clamped) | `100%` |

Bar variation `HudShieldBar`, `has_theme_stylebox_override("fill") == false`, and
`get_theme_stylebox("fill")` **is** the theme's `HudShieldBar/fill` (object identity). Readout
`HudReadout` at 18 px, no override. Geometry with **both** the prompt and the bar visible (worst
case, since the strip shares the bottom edge with the two corner panels):

| Element | Rect |
|---|---|
| `WarpBlock` | `P(830,1001) S(260,35)` |
| `WarpBar` | `P(830,1022) S(260,14)` |
| `PromptLabel` | `P(12,1042) S(1896,18)` |
| `PromptLabel` text box (centred, `get_minimum_size().x`) | `P(938,1042) S(44,18)` |
| `AmmoPanel` | `P(12,939) S(258,73)` |
| `MinimapPanel` | `P(1706,834) S(202,234)` |

Warp block above the prompt (`1001+35 = 1036 ≤ 1042`) ✓; warp block hugs its content
(`260 = bar width`) ✓; board-and-text clear of the ammo panel ✓ and of the minimap panel ✓ (the
label's own full-width rect overlaps the minimap panel's rect at x ≥ 1706 exactly as the retired
hint did, and it draws only its centred text — hence the text-box measurement).

### 3.4 Cursor reticle

| Fact | Measured |
|---|---|
| boot | `visible = true`, `state = 0` (PLAIN), `size = (48,48)`, micro-bar hidden |
| `set_reticle_state(IN_RANGE)` / `(OUT_OF_RANGE)` / `(99)` | `1` / `2` / **`3`** (clamped to HOSTILE) |
| `set_cursor_position((960,540))` | `position = (936,516)` = cursor − `size/2` exactly |
| injected `InputEventMouseMotion` raw `(300,200)` in a 2560×1440 host window | delivered `(225,150)` (×0.75 into the 1920×1080 logical space) → `position = (201,126)` = delivered − `size/2` exactly |
| `set_target((600,400), 0.62)` | `position = (576,376)`, micro-bar **visible**, `value = 62.0` |
| `clear_target()` | micro-bar hidden, `visible = true`, position back on the cursor `(201,126)` |
| mouse | `mouse_filter = IGNORE`; `Input.mouse_mode == MOUSE_MODE_VISIBLE` |

Colour keys: `TargetReticle.COLOR_LOCK = accent_danger`, `COLOR_PLAIN = text_dim`,
`COLOR_ENGAGED = text_primary`, resolved against the live theme's
`(0.7843,0.2784,0.1216)` / `(0.4196,0.4549,0.5176)` / `(0.7882,0.8196,0.8627)`.

---

## 4. Commands run, with output

Engine binary `C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`. The editor was left alone
throughout: no editor was launched, no `--editor` reimport and no graphical game run, per the brief.

### 4.1 Acceptance probe — HUD (scene run)

```
"…_console.exe" --headless --path "…/vajb-orbit" res://tools/_probe_w5_hud.tscn
exit 0   === checks 56, failures 0 ===
```

Full stdout archived at `.agents/gen/engine_wave1_w5_probe.txt` (4 704 B, md5
`BB8F9E80DDA7A235EECF49E507C5C3F2`); source archived at
`.agents/gen/engine_wave1_w5_probe_source.gd` + `…_source.tscn`. The archived source was restored to
`tools/` and re-run against the shipped revision after the last (comment-only) edit: same 56/0 and a
byte-identical log, so the record reproduces.

The probe loads `res://ui/hud/hud.tscn`, `add_child`s it, applies `Router.live_theme()` the way
`game.gd:478` does, binds a real `PlayerState`, and drives the new API. It prints every measured
fact quoted in §3 and §5 and ends with `=== checks 56, failures 0 ===`.

### 4.2 Acceptance probe — flight scene wiring (scene run)

```
"…_console.exe" --headless --path "…/vajb-orbit" res://tools/_probe_w5_game.tscn
exit 0   === checks 10, failures 0 ===
```

Archived at `.agents/gen/engine_wave1_w5_game_probe.txt` (1 277 B, md5
`6AC9BAFB06B1D6FB6A29B77BCE13825B`) + `…_game_probe_source.gd`/`.tscn`. It boots `game.tscn`,
teleports the ship to the sector's station and back, starts and cancels a warp through W2's own
functions, and reads the labels. Owner-data safety: `PlayerProfile.save_path` is repointed at
`user://probe_w5_profile.cfg` before the scene is instantiated and restored afterwards; §4.5 is the
verification.

### 4.3 Boot / regression gates

```
"…_console.exe" --headless --path <proj> --quit-after 180 res://game/game.tscn  -> exit 0, 159 B log, no error/warning
"…_console.exe" --headless --path <proj> --quit-after 120 res://ui/hud/hud.tscn -> exit 0, 159 B log, no error/warning
"…_console.exe" --headless --path <proj> --quit-after  90 res://ui/screens/boot.tscn -> exit 0, 159 B log
"…_console.exe" --headless --path <proj> res://tests/headless_runner.tscn      -> exit 0, [SUMMARY] passed=53 failed=0
```

Logs: `engine_wave1_w5_boot_game.txt`, `…_boot_hud.txt`, `…_boot_boot.txt` (all 159 B, md5
`7A59E3F71560B95CBC41DBAF9210CFF3` — the two-line clean banner) and `…_tests.txt` (3 931 B, md5
`C0B93FF33EBF63F11A6629830F249ED6`). The P1 suite is byte-identical to W3's run, so nothing in the
economy layer moved. The suite's single `WARNING: EconomyLog: could not open …` line is its own
deliberate unwritable-path test (`test_p1_unwritable_log_path_is_survivable`).

### 4.4 Why the probes are scene runs, not `--script` runs

A `--script` probe whose script statically references a HUD-typed identifier fails to compile the
dependency, because a custom main loop has no autoloads registered as compile-time identifiers:

```
"…_console.exe" --headless --path "…/vajb-orbit" --script res://tools/_probe_w5_script_try.gd
SCRIPT ERROR: Compile Error: Identifier not found: SettingsManager
   at: GDScript::reload (res://ui/hud/hud.gd:298)
SCRIPT ERROR: Compile Error: Failed to compile depended scripts.
   at: GDScript::reload (res://tools/_probe_w5_script_try.gd:0)
[w5-control] typed reference present = true
[w5-control] hud.tscn load -> ok
```

Log `.agents/gen/engine_wave1_w5_script_try.txt` (653 B, md5 `C8BC6F4E8E805CFCF648C50DDB4371CA`),
control source `engine_wave1_w5_script_control_source.gd`. Note the two sides of it: the **static
reference** breaks the compile, while a runtime `load()` of the same `hud.tscn` prints `ok`. The
acceptance probe therefore runs as a scene (autoloads registered before the main scene compiles) —
the same conclusion W2 (`§6 item 11`) and W3 (`§3.1`) reached. No `--check-only` run was used as a
gate (the brief's known trap).

### 4.5 Owner-data safety

```
profile.cfg  md5 248E69488904A91F88E0FFE1D05C82EE  mtime 17:09:50  (measured after the last W5 run, 17:2x)
profile.cfg  mtime 17:09:50  < 17:12:37  (the first W5 run)  -> no W5 run wrote it
probe_w5_profile.cfg  = absent
```

The HUD itself never touches the profile; only the flight-scene probe instantiates `game.gd`, and it
redirects `save_path` first.

### 4.6 Cleanup

```
tools/ after: ['build_theme.gd', 'build_theme.gd.uid', 'derive_icon_tints.gd', 'derive_icon_tints.gd.uid']
tools/ _probe_* count: 0
```

`_probe_w5_hud.gd`/`.tscn`, `_probe_w5_game.gd`/`.tscn`, `_probe_w5_script_try.gd` and every `.uid`
sidecar are gone; §0's scope scan shows the four shipped files as the only project writes.

---

## 5. Acceptance evidence per item

### 5.1 Frozen API and frozen state path

| Check | Measured |
|---|---|
| 8 frozen methods present | `bind`, `set_sector_name`, `set_minimap_scale`, `set_minimap_blips`, `set_target`, `set_target_info`, `clear_target`, `set_cargo_open` — all `has_method` true |
| 3 signals present | `weapon_slot_selected`, `cargo_toggled`, `minimap_zoom_changed` |
| 3 additions present | `set_prompt`, `set_warp_channel`, `set_reticle_state` |
| `bind(PlayerState)` still pulls the pools | `hull = '1000/1000'`, `cargo = 'CARGO 0/40'`; `set_hull(750)` → `'750/1000'` |
| `game.gd`'s guard list still passes | live `HUD_METHODS` = the same 8 names; the flight scene instantiates the HUD and binds it |
| `clear_target` no longer hides the reticle | explicit §6 item 2 |

### 5.2 Retirements and mouse behaviour

| Check | Measured |
|---|---|
| ESC hint string gone | 0 of 21 labels in the instantiated HUD contain `ESC · DOCK AT KEPLER-9` |
| `DockHint` node gone | `find_child("DockHint", true, false) == null` |
| reticle never eats clicks | `mouse_filter == Control.MOUSE_FILTER_IGNORE` on the reticle; all new nodes carry `mouse_filter = 2` |
| hardware cursor unchanged | `Input.mouse_mode == Input.MOUSE_MODE_VISIBLE`; no `mouse_mode` write anywhere in `ui/hud/` |

### 5.3 Prompt, warp and theme-item usage

| Check | Measured |
|---|---|
| prompt has/keeps its styling | `StationCaption` @13, `text_dim`, no font-size override, no colour override |
| warp bar is a pure variation | `HudShieldBar`, no stylebox override, `get_theme_stylebox("fill")` **is** the theme object |
| warp readout/caption | `HudReadout` @18 (no override) / `StationCaption` @13 |
| no new theme item, no hex literal | theme resource md5+mtime unchanged (§0); 0 hex literals in all four files; `add_theme_*_override` call count 5 → 5 (the pre-existing ones) |
| no font-size override anywhere new | the two new labels resolve 13 and 18 from their variations |

### 5.4 Wiring into the shipped flight scene (probe 2)

| Check | Measured |
|---|---|
| prompt off away from the dock zone | spawn `(0,420)` → `visible=false text=''` |
| `game.gd` pushes `F · DOCK` inside the zone | station centre `(0,0)` → `visible=true text='F · DOCK'` |
| leaving the zone clears it | station + 600 u → `visible=false text=''` |
| warp bar hidden before a channel | `WarpBlock.visible == false` |
| channel fills the bar | `_start_warp()` → 2 frames `1.1 %`, +20 frames `12.2 %` (WARP_CHANNEL 3 s at 60 Hz) |
| cancel hides it | `_cancel_warp()` → `visible=false` |
| live reticle | `visible=true`, state `PLAIN`, `set_target`/`clear_target` present |
| blip feed survives | 4 kinds in one `set_minimap_blips` call, no error |

### 5.5 Blip classes

| Kind | Colour | Theme token |
|---|---|---|
| `self` | `(0.7882,0.8196,0.8627)` | `text_primary` |
| `friendly` | `(0.7882,0.8196,0.8627)` | `text_primary` (diamond glyph) |
| `neutral` | `(0.4196,0.4549,0.5176)` | `text_dim` |
| `hostile` | `(0.7843,0.2784,0.1216)` | `accent_danger` |
| `""` (unknown) | `(0.4196,0.4549,0.5176)` | `text_dim` (back-compatible fall-through) |

---

## 6. Deviations, interpretations and open points

1. **`ui/hud/target_reticle.gd` is edited, one file beyond the brief's list (MED, needs no
   reversal to proceed).** The brief's §W5 file list is `hud.gd`, `hud.tscn` and (conditionally)
   `minimap.gd`, but item 1 *requires* "cursor reticle (plain/in-range/out-of-range states drawn at
   the mouse position)" — states that by definition live with the class that draws the reticle.
   `IMPLEMENTATION_PLAN.md` §2's worker table assigns `ui/hud/target_reticle.gd` to this same HUD
   worker, no other slice-1 file list contains it, and the alternative (a second draw path inside
   `hud.gd`, whose root Control is outside the HUD `CanvasLayer` and therefore in world space) would
   duplicate the token lookup and the draw. **Reversal:** revert the file to its pre-W5 content and
   drop `set_reticle_state` — the HUD loses the cursor states entirely.
2. **`clear_target()` no longer hides the reticle (by requirement, MED).** §9.9 makes the reticle a
   cursor reticle, and a cursor reticle is drawn whether or not a target is locked; so the frozen
   pair now toggles the lock's brackets + micro-bar rather than the whole Control's visibility. The
   method signature, the names and the locked-target look (UI_SPEC §3.5) are unchanged. **Reversal:**
   `visible = _has_target` in `_apply()`.
3. **The cursor follows the pointer from its own motion event (LOW, design choice).** No caller
   exists for a cursor position in slice 1 (W2's `game.gd` pushes only targets), and a per-frame
   poll would put `_process` into a HUD file. `_input` receives `InputEventMouseMotion` without
   consuming it, so nothing else changes behaviour; `set_cursor_position` stays public for callers
   and probes. **Reversal:** move the assignment into a `game.gd` push.
4. **New presentation constants (LOW, listed for the W6 number audit; no doc pins any of them).**
   `target_reticle.gd`: `CURSOR_GAP 4.0`, `CURSOR_TICK 6.0`, `CURSOR_RADIUS 11.0`, `CURSOR_DOT 1.0`,
   `CURSOR_SLASH 9.0` — chosen so the glyphs fit the shipped 48×48 reticle box; `BRACKET_ARM 8.0` and
   `BRACKET_WIDTH 1.0` are the shipped lock values, preserved. `minimap.gd`: `FRIENDLY_RADIUS 3.0`
   (= the existing `SELF_RADIUS`). `hud.tscn`: warp block 260 wide (the hull/shield bar width) and
   14 high (UI_SPEC §7's "HUD bar height"), prompt and bar text sizes come from variations rather
   than overrides. `hud.gd`: `PERCENT_FORMAT "%d%%"`, the warp readout's string shape. No gameplay
   number is invented anywhere in this pass.
5. **The warp bar borrows `HudShieldBar` (LOW, interpretation).** §9.9/§10 say "warp bar" without
   naming a style, and the brief forbids new theme items. The base `ProgressBar` item pair paints an
   **ember** fill (`progress_fill` = `accent_danger`), which STYLE_BIBLE §7.3 and UI_SPEC §3.1
   reserve for warnings/hostile/critical values; `HudShieldBar` is the existing steel-fill bar (and
   §3.1 already reasons that a regenerating, non-danger quantity must not be orange). If the owner
   wants a dedicated warp item, that is a one-line `build_theme.gd` addition plus a `theme_type_variation`
   swap — a theme change, explicitly out of this pass's scope.
6. **Friendly blips are diamonds (LOW, presentation).** UI_SPEC §3.3 predates the friendly class
   (it lists only `accent_danger`/`text_dim`/`text_primary`), ENGINE_SPEC §8 adds it, and the ember
   accent is unavailable for a non-hostile — so friendly takes `text_primary`, shared with self, and
   is distinguished by glyph. **Reversal:** drop the `KIND_FRIENDLY` branch in `_draw_blip` and
   friendly falls back to the neutral-sized circle in `text_primary`.
7. **The mining reticle states have no caller in slice 1 (HIGH for the wave, not for this file).**
   `set_reticle_state` is implemented, measured and relayed, and the plain state is live in the
   shipped scene, but nothing pushes `IN_RANGE`/`OUT_OF_RANGE` yet: W5's file list excludes
   `game.gd`, and W2 shipped its HUD wiring before this API existed. W3 left
   `MiningLaser.is_active()`, `has_target()` and `target_position()` public for exactly this. §7
   carries the paste-ready refresh for the orchestrator/W6 to assign (one hunk in `game.gd`).
8. **Not shipped, deliberately:** hit markers (combat feedback, ENGINE_SPEC §4.2 — slice 1 has no
   damage source), the `set_target_info` range state (needs a selected weapon + a target), POI
   subkinds (slice 3). No dead API was added for them; the blip dict already tolerates extra keys.
9. **No pixel/visual verification is possible in this pass (LOW, limitation).** The brief forbids
   launching the editor or the graphical game, and the headless renderer is a dummy (no framebuffer
   to sample), so `_draw()` correctness is carried by parse/boot plus the measured state, colour-key
   and geometry facts above, not by a rendered image. A rendered check of the four reticle states and
   the prompt/warp strip is the natural first item for the owner's live walkthrough.
10. **`--script` probes cannot statically reference HUD-typed identifiers (LOW, not a W5 defect).**
    §4.4 has the verbatim evidence; the acceptance probe is a scene run for that reason, matching
    W2 §6 item 11 / W3 §3.1.
11. **`PERCENT_FORMAT` is a new const (LOW).** It follows `DISTANCE_FORMAT`'s shipped pattern for a
    formatted readout; if W6 prefers an inline format string, it is a two-line removal.

---

## 7. Handoff to W6 (and the one missing wire)

**W6 should re-measure, not trust this report:** the four file md5s (§0), the theme resource's
md5+mtime, the two probe runs (`56/0` and `10/0`), the boot gates (three 159-byte logs) and
`tests/headless_runner.tscn` (53/53). The archived probe sources re-run unchanged:
`py`-free, just copy `.agents/gen/engine_wave1_w5_probe_source.gd|tscn` back to
`res://tools/_probe_w5_hud.gd|tscn` (and the `game` pair) and run the two commands in §4.1/§4.2,
then delete them again.

**Aggregation checklist for the interfaces this file touches.**

| Interface | As shipped here |
|---|---|
| `Hud.set_prompt(text: String)` / `set_warp_channel(progress: float)` | exactly §3.10's amended signatures; empty/≤ 0 hides |
| `Hud.set_reticle_state(state: int)` | additive; clamps into `TargetReticle.State` |
| `TargetReticle.State` | `PLAIN 0`, `IN_RANGE 1`, `OUT_OF_RANGE 2`, `HOSTILE 3` |
| `TargetReticle.set_target(screen_position, hull_fraction)` / `clear_target()` | frozen signatures and lock look; `clear_target` returns the draw to the cursor |
| blip dict | `{"pos": Vector2 (world), "kind": &"self"|&"friendly"|&"neutral"|&"hostile"}`; unknown keys ignored |
| HUD scene paths | `CanvasLayer/BottomCenter/PromptBlock/PromptLabel`, `…/PromptBlock/WarpBlock/WarpBar`, `…/WarpHeader/WarpValue`, `%TargetReticle` |

**The one missing wire (for the orchestrator to assign to a `game.gd` owner — W7 or slice 2).**
`game.gd` already refreshes the HUD on `HUD_REFRESH_INTERVAL` (0.1 s) and already owns the ship; the
mining state is one guarded call, using W3's published API:

```gdscript
## ENGINE_SPEC section 10 / IMPLEMENTATION_PLAN section 9.9: the mining reticle states.
## MINE_LASER_RANGE (220 u) and the cycle live in MiningLaser, so has_target() already
## answers "in range" for the cursor's ray.
func _push_reticle_state() -> void:
	if _hud == null or _ship == null or not _hud.has_method(&"set_reticle_state"):
		return
	var laser := _ship.get_node_or_null(^"MiningLaser")
	var state: int = TargetReticle.State.PLAIN
	if laser != null and bool(laser.call(&"is_active")):
		state = TargetReticle.State.IN_RANGE if bool(laser.call(&"has_target")) else TargetReticle.State.OUT_OF_RANGE
	_hud.call(&"set_reticle_state", state)
```

Called from `_refresh_hud()` (or `_physics_process` next to `_update_mining_laser`), it turns the
mining states on without touching W5's files. Slice 2 replaces it with the targeting reading
(`HOSTILE` + the weapon-range state).
