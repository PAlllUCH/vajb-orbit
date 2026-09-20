# Fix Wave 1 — W1 (main menu) report — 2026-09-18

Worker W1. Brief: `.agents/gen/fix_wave1_task.md` §W1, rulings in `docs/design/IMPLEMENTATION_PLAN.md` §9.8
items 1–3. Specification read first: `AGENTS.md`, `IMPLEMENTATION_PLAN.md` §9.8, then the two W1 files.

Result: **all three W1 items implemented and measured.** Two files changed, no others. `tools/` holds no W1
artefact (the brief's `_probe_w1.gd` and, had one existed, its `.uid` sidecar are deleted; the `_probe_w2.gd`
and `_probe_w3.gd` in `tools/` belong to the parallel waves and are untouched). Every number below comes from
an output captured in this session; the few derived values are marked **derived**.

---

## Files changed

| File | Before | After | Delta | Lines before → after |
|---|---|---|---|---|
| `vajb-orbit/ui/components/menu_button.gd` | 5786 B | 5369 B | −417 B (−7.2 %) | 206 → 186 |
| `vajb-orbit/ui/screens/main_menu.gd` | 11722 B | 13222 B | +1500 B (+12.8 %) | 326 → 363 |

`git` is not available in this workspace (not a repository), so no other version of these files exists. The
before/after hunks are quoted in full below as the reversal path. No file outside the two was written; a
`glob` over `vajb-orbit/**/*` sorted by mtime shows no stray output from the probe or the smoke runs, and
`project.godot` is untouched.

---

## 1. Item 1 — focus ring deleted

`ui/components/menu_button.gd`. The ring was contract in §3.11 and is retired by §9.8 item 1; it is gone for
every `MenuButton` consumer (main menu, settings, quit dialog) by construction, since the drawing lives in this
one script.

Removed (the whole focus branch and its plumbing):

```gdscript
## Reusable menu button: breathing 1 px border, hover ember glow, press inset, focus ring.
## Contract: docs/design/IMPLEMENTATION_PLAN.md section 3.11.
```
```gdscript
const FOCUS_BORDER: StringName = &"accent_danger_bright"
var _focus_color: Color = Color.WHITE
var _focused: bool = false
	_button.focus_entered.connect(_on_focus_entered)
	_button.focus_exited.connect(_on_focus_exited)
	_focus_color = _token(FOCUS_BORDER)
func _set_focused(enabled: bool) -> void:
	_focused = enabled
	queue_redraw()
func _on_focus_entered() -> void:
	_set_focused(true)
func _on_focus_exited() -> void:
	_set_focused(false)
```

Replaced with:

```gdscript
## Reusable menu button: breathing 1 px border, hover ember glow, press inset.
## The focus ring of IMPLEMENTATION_PLAN section 3.11 is retired by section 9.8 item 1,
## so this control draws nothing extra for focus and the owning screen cues selection.
## Behaviour: docs/design/MAIN_MENU_SPEC.md section 4.
```
```gdscript
func _draw() -> void:
	var ring := Rect2(
		BORDER_WIDTH * 0.5,
		BORDER_WIDTH * 0.5,
		size.x - BORDER_WIDTH,
		size.y - BORDER_WIDTH
	)
	if _hovered:
		draw_rect(ring, _hover_color, false, BORDER_WIDTH)
	else:
		draw_rect(ring, _border_color, false, BORDER_WIDTH)
```

`_refresh_colors()` keeps the two breathing endpoints and the hover colour; the `NOTIFICATION_THEME_CHANGED`
handler, the breath tween, the press tween, the glow underlay and the three signals are unchanged. The old
branch order (focus → hover → idle) is now hover → idle, which is exactly what the ruling asks: a focused
button draws what an idle or hovered button draws.

`_focused` was also the only write-only leftover once the branch went, so it went with the ring. Grep over the
whole project for `_focused|FOCUS_BORDER|_focus_color|_set_focused` now returns **only** unrelated
`focus_entered` connections in the station panels (their own `_on_row_focused` handlers) — i.e. no consumer of
the removed state exists. Note for the owner (item 3 of "open points"): `AGENTS.md` gap 10 cites
`menu_button.gd._focused` as a `game_eval` focus check; the equivalent live check is the inner
`Button.has_focus()`, which the probe measured as `true` for the focused PLAY plate.

### Evidence (probe, one run, `--fixed-fps 60`)

```
[w1] menu_button.gd FOCUS_BORDER const present: false
[w1] menu_button.gd '_focus_color' occurrences in source: 0
[w1] menu_button.gd 'accent_danger_bright' occurrences in source: 0
[w1] menu_button.gd '_focused' occurrences in source: 0
[w1] menu_button.gd '_set_focused' occurrences in source: 0
[w1] menu_button.gd 'draw_rect' occurrences in source: 2
[w1] PLAY plate focus owner: true  has_focus()=true
```

`FOCUS_BORDER present: false` is read from the loaded script's constant map (not from text), and the constant
map is how a `game_eval` consumer would look for it. `draw_rect` count 2 = the two remaining branches; the
pre-W1 source had three plus the `if _focused:` test. `accent_danger_bright` no longer appears in the file at
all, so no red rectangle can be drawn from this script; the token itself stays in the theme (other consumers).

---

## 2. Item 2 — emblem pulse as the new cue

`ui/screens/main_menu.gd`. The left band (`_ticks`, `TICK_IN`/`TICK_OUT`) is untouched; the pulse rides on the
emblem's existing brighten modulate, so it introduces no new token and no new colour.

Constants added next to `EMBLEM_BRIGHTEN` (line 40–49):

```gdscript
## Every theme token is a dimmer, so the dark insignia is lifted by a white modulate
## multiplier rather than by a token (MAIN_MENU_V2 section 15.3). Focus flares it
## brighter instead of drawing the retired focus ring (IMPLEMENTATION_PLAN 9.8 item 1).
const EMBLEM_BRIGHTEN: float = 2.0
const EMBLEM_PULSE_PEAK: float = 2.35
const EMBLEM_PULSE_IN: float = 0.10
const EMBLEM_PULSE_OUT: float = 0.30
```

New code (`:96` the state, `:225` the call site, `:228–244` the pulse):

```gdscript
var _emblem_pulse: Tween
```
```gdscript
func _set_active_verb(index: int) -> void:
	_active_verb = index
	_readout.text = READOUT[index]
	_set_tick(index)
	_pulse_emblem()


func _emblem_color(level: float) -> Color:
	return Color(level, level, level, 1.0)


func _pulse_emblem() -> void:
	## The emblem carries the focus cue the retired ring used to (IMPLEMENTATION_PLAN
	## section 9.8 item 1): it flares from the resting brighten and settles back to it.
	_stop_emblem_pulse()
	_emblem_pulse = create_tween()
	_emblem_pulse.tween_property(_badge, "modulate", _emblem_color(EMBLEM_PULSE_PEAK), EMBLEM_PULSE_IN).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_emblem_pulse.tween_property(_badge, "modulate", _emblem_color(EMBLEM_BRIGHTEN), EMBLEM_PULSE_OUT).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_emblem_pulse() -> void:
	if _emblem_pulse != null and _emblem_pulse.is_valid():
		_emblem_pulse.kill()
	_emblem_pulse = null
```

`_set_active_verb` is the single funnel for both focus paths (`_on_verb_focused` from the plate's
`focus_entered`, `_on_verb_hovered` which grabs focus) and for `_ready`'s initial `_focus_verb(PLAY)`, so every
route that lands focus on a verb pulses and the tick/readout move in the same call. `_apply_token_colours()`
(the `NOTIFICATION_THEME_CHANGED` handler) now reads `_badge.modulate = _emblem_color(EMBLEM_BRIGHTEN)` after
killing any in-flight pulse, so a theme change cannot leave the emblem stuck bright — the resting value is
authoritative at 2.0. `_exit_tree()` kills the pulse with the other tweens. The two tween legs both use
`TRANS_SINE`/`EASE_OUT`; the brief fixed `TRANS_SINE EASE_OUT` for the 0.10 s flare and left the 0.30 s return
open, so the same curve is used there (fast decay, gentle settle). The kill-then-retrigger is unconditional, as
asked.

### Evidence (same probe run; modulate.r sampled at 60 Hz)

```
[w1] pulse 0 trigger at t=1.000, modulate.r=2.0000
[w1] pulse 1 trigger at t=1.717, modulate.r=2.0000
[w1] pulse 2 trigger at t=2.617, modulate.r=2.0000
[w1] pulse 3 trigger at t=2.767, modulate.r=2.2594
[w1] emblem modulate at the end of the run: 2.0000
[w1] pulse trace: A rest->flare at t=1.00, B rest->flare at t=1.70, C at t=2.60, D (mid-flight) at t=2.75
[w1]   t=0.95  modulate.r=2.0000
[w1]   t=1.00  modulate.r=2.0000
[w1]   t=1.10  modulate.r=2.3500
[w1]   t=1.20  modulate.r=2.1750
[w1]   t=1.30  modulate.r=2.0469
[w1]   t=1.40  modulate.r=2.0000
[w1]   t=1.50  modulate.r=2.0000
[w1]   t=1.70  modulate.r=2.0000
[w1]   t=1.80  modulate.r=2.3381
[w1]   t=1.90  modulate.r=2.2021
[w1]   t=2.10  modulate.r=2.0013
[w1]   t=2.20  modulate.r=2.0000
[w1]   t=2.60  modulate.r=2.0000
[w1]   t=2.70  modulate.r=2.3381
[w1]   t=2.80  modulate.r=2.3047
[w1]   t=2.85  modulate.r=2.3469
[w1]   t=2.95  modulate.r=2.2021
[w1]   t=3.05  modulate.r=2.0633
[w1]   t=3.15  modulate.r=2.0013
[w1] pulse A (from rest): peak=2.3500 at rel=0.100, rel 0.40=2.0000
[w1] pulse B (from rest): peak=2.3500 at rel=0.117, rel 0.40=2.0013
[w1] pulse C (from rest): peak=2.3500 at rel=0.117
[w1] pulse D (mid-flight re-trigger): value before=2.3500 after=2.2594, peak=2.3500 at rel=0.117, rel 0.40=2.0013
```

Readings: a pulse from rest reaches exactly **2.3500 at 0.100 s** and is back to **2.0000 at 0.400 s** — the
brief's envelope, to the sample. B and C reproduce it from rest (peak one frame later, 0.117 s, because their
trigger frames land at 1.717/2.617 rather than on a 0.05 boundary). D is the kill-and-retrigger case: the value
is 2.3500 at the kill and 2.2594 on the next frame, i.e. the emblem never snaps down to 2.0 and re-flares;
the new flare then peaks at 2.3500 and settles at 2.0013 (2.0 one frame later). The resting value at the end of
a 45.5 s run is exactly 2.0000.

Observed, and intended by item 2's wording: focus lands on PLAY during `_ready`, so the emblem also pulses once
as the menu appears (frame 3 of the probe read modulate 2.175 mid-flare, decaying). If the owner wants the
entrance to stay pulse-free, the fix is to move the `_pulse_emblem()` call out of `_set_active_verb` into the
two focus handlers; not done, because the brief names `_set_active_verb` as the hook.

---

## 3. Item 3 — backdrop drift retune

```gdscript
const DRIFT_DISTANCE: float = 96.0     # was 24.0
const DRIFT_SECONDS: float = 20.0      # was 40.0
```

`_start_ambient()` is unchanged: the same two-leg sine ping-pong (`position` 0 → (−D,−D) over one leg, back to
`Vector2.ZERO` over the second, `set_loops()`, `TRANS_SINE`/`EASE_IN_OUT`), and the ember pulse tween is
untouched.

### Evidence — amplitude, seam continuity, cycle coverage (same probe run, 45.5 s of simulated time)

```
[w1] frames=2731 samples=2731 sim_time=45.517
[w1] drift min position x=-96.0000 at t=20.017, y=-96.0000 (target -96.0, so amplitude measured)
[w1] edge margins over the run, against the clip layer rect: right=-0.0015 (t=19.967) bottom=-0.0015 (t=19.967) left=0.0000 (t=0.017) top=0.0000 (t=0.017)
[w1] counterfactual with the scene's 24 px slack: right/bottom band = 96 - 24 = 72 px uncovered
[w1] max per-frame drift step=0.17772 px at t=10.000
[w1] drift reversal (velocity turn): t=20.033 pos=(-96.000, -96.000) step=0.00024
[w1] drift reversal (velocity turn): t=40.033 pos=(-0.000, -0.000) step=0.00023
```

- **Amplitude:** the plate reaches (−96.0000, −96.0000) at t = 20.017 s — the retuned distance exactly, and at
  the retuned leg length (the old constants topped out at 24 px at t = 40 s).
- **No pop/seam:** the run covers a whole cycle and one reversal boundary of the next. Both velocity turns are
  near-stationary — 0.00024 px and 0.00023 px of movement in the frame of the turn, against a peak of
  0.17772 px — and the second turn is the loop seam itself, where the position is (−0.000, −0.000), i.e. the
  tween leg hands over at the origin with zero velocity and no positional jump. Only those two sign changes
  were detected in 2731 frames, so the wobble is the intended single ping-pong and nothing jitters.
- **Perceptibility:** peak speed 0.17772 px/frame = 10.66 px/s on the diagonal (7.54 px/s per axis, which is
  (π/2)·(96/20) for the sine ease-in-out **derived** and matched by the measurement), mean 4.8 px/s per axis
  (96 px over 20 s). Against the pre-W1 24 px over 40 s (0.6 px/s per axis) that is 4× the travel at 8× the
  speed, so the drift is now a visible pan rather than a sub-pixel crawl.
- **Edge coverage:** measured against the clip layer's own rect (the `BackdropLayer` with
  `clip_contents = true`, 1920×1080 in canvas space at `(0,0)`), the worst right/bottom margin over the whole
  run is **−0.0015 px** (negative = the plate still overlaps the edge) and the worst left/top margin is 0.0000
  at rest. No frame exposes any gap.

### The one judgement call — drift slack reserved in code (deviation)

The scene's `Backdrop` carries `offset_right = 24.0` / `offset_bottom = 24.0`, which **is** the old drift
budget: `MAIN_MENU_V2.md` §6.3/§15.3 calls the plate "rect 1944 x 1104 (1920 x 1080 + 24 px of drift slack)"
and `ENVIRONMENT_SPEC.md` §2 asks the art to tolerate "24 px / 40 s". At 96 px of drift the plate's right and
bottom edges would pull 72 px inside the canvas at the far end of the leg and uncover the frame — the "seam"
half of item 3's acceptance. `main_menu.tscn` is not in W1's file list, so the slack is reserved in the only
file W1 owns, in `_ready()` before the first layout-dependent call:

```gdscript
func _reserve_drift_slack() -> void:
	## The scene reserves 24 px of backdrop oversize, the pre-W1 drift budget
	## (MAIN_MENU_V2 section 6.3). Reserving DRIFT_DISTANCE here keeps the plate covering
	## the viewport edge at the far end of the retuned drift, and the ember, which is a
	## child of the plate, stays anchored on the wreck.
	_backdrop.offset_right = DRIFT_DISTANCE
	_backdrop.offset_bottom = DRIFT_DISTANCE
```

called from `_ready()` between `_connect_router()` and `_prime_entrance()` (`:111`), i.e. before the explicit
`_reanchor_ember()` and before the `resized` connection it also triggers. The resulting plate is 2016×1176 —
byte-identical in geometry to what the scene would carry if its two offsets were edited to 96, so this is not a
new framing, it is the expected one expressed in code. The measurable consequences:

```
[w1] canvas rect (MainMenu): (1920.0, 1080.0)  clip layer rect: (1920.0, 1080.0) at (0.0, 0.0)
[w1] backdrop offsets: right=96.0 bottom=96.0  size=(2016.0, 1176.0)
```

**Derived**, not measured (arithmetic on the measured rect and the 2048×1152 source): the visible horizontal
crop of the vista grows from 9.33 px per side (1944×1104 rect) to 37.33 px per side (2016×1176), 1.8 % of the
drawn width; the vertical crop is 0 in both cases because the drawn height equals the rect height. The ember
stays on the wreck by construction: `_reanchor_ember()` recomputes the cover placement from `_backdrop.size`
with the same `max(size/native)` rule Godot uses for `KEEP_ASPECT_COVERED`, so the anchor fraction is unchanged
by the slack. Flagged for the owner only because the wider plate is a small composition change on screen.

Consequence to tidy later: `main_menu.tscn`'s `offset_right/offset_bottom = 24.0` are now placeholders that
`_ready()` overwrites. Anyone who later opens the scene should set them to 96.0 (or drop the code-side reserve
in the same change) — W5 touches this file's screen, and W6 should decide which side keeps the constant.

---

## Commands run, with their output

All from the workspace root `G:/Mój dysk/Projekty/Vajb Orbit`, project path
`G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit`, binary
`C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe`. No editor and no graphical game was launched.

**1. The mandated parse check, `menu_button.gd` — passes**

```
..._console.exe --headless --path <proj> --check-only --script res://ui/components/menu_button.gd
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

exit=0
```

**2. The mandated parse check, `main_menu.gd` — cannot pass, and the limitation is the command's, not this file's**

```
..._console.exe --headless --path <proj> --check-only --script res://ui/screens/main_menu.gd
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

SCRIPT ERROR: Compile Error: Identifier not found: AudioManager
   at: GDScript::reload (res://ui/screens/main_menu.gd:118)
ERROR: Failed to load script "res://ui/screens/main_menu.gd" with error "Compilation failed".
   at: load (modules/gdscript/gdscript_resource_format.cpp:46)
exit=1
```

`--check-only --script` compiles before the autoload singletons exist, so **any** screen that names one fails
identically. Proof, on a file W1 never touched:

```
..._console.exe --headless --path <proj> --check-only --script res://ui/screens/settings.gd
SCRIPT ERROR: Compile Error: Identifier not found: SettingsManager
   at: GDScript::reload (res://ui/screens/settings.gd:100)
ERROR: Failed to load script "res://ui/screens/settings.gd" with error "Compilation failed".
exit=1
```

The error is an unresolved autoload **identifier** at the `play_music` call site, not a syntax error; a genuine
parse fault would be reported as one. `main_menu.gd`'s compile-and-run is covered by commands 3 and 4 below,
which load it with the autoloads live. Recommended for the brief's checklist: keep the `--check-only` line for
scripts without autoload references and pair it with the scene smoke run for screens.

**3. Probe run, `--fixed-fps 60`, `extends SceneTree`, deleted afterwards** (source in the appendix)

```
..._console.exe --headless --path <proj> --fixed-fps 60 --script res://tools/_probe_w1.gd
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[w1] menu_button.gd FOCUS_BORDER const present: false
[w1] menu_button.gd '_focus_color' occurrences in source: 0
[w1] menu_button.gd 'accent_danger_bright' occurrences in source: 0
[w1] menu_button.gd '_focused' occurrences in source: 0
[w1] menu_button.gd '_set_focused' occurrences in source: 0
[w1] menu_button.gd 'draw_rect' occurrences in source: 2
[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
[w1] canvas rect (MainMenu): (1920.0, 1080.0)  clip layer rect: (1920.0, 1080.0) at (0.0, 0.0)
[w1] backdrop offsets: right=96.0 bottom=96.0  size=(2016.0, 1176.0)
[w1] emblem resting modulate: (2.175, 2.175, 2.175, 1.0)
[w1] PLAY plate focus owner: true  has_focus()=true
[w1] pulse 0 trigger at t=1.000, modulate.r=2.0000
[w1] pulse 1 trigger at t=1.717, modulate.r=2.0000
[w1] pulse 2 trigger at t=2.617, modulate.r=2.0000
[w1] pulse 3 trigger at t=2.767, modulate.r=2.2594
[w1] frames=2731 samples=2731 sim_time=45.517
[w1] emblem modulate at the end of the run: 2.0000
[w1] drift min position x=-96.0000 at t=20.017, y=-96.0000 (target -96.0, so amplitude measured)
[w1] edge margins over the run, against the clip layer rect: right=-0.0015 (t=19.967) bottom=-0.0015 (t=19.967) left=0.0000 (t=0.017) top=0.0000 (t=0.017)
[w1] counterfactual with the scene's 24 px slack: right/bottom band = 96 - 24 = 72 px uncovered
[w1] max per-frame drift step=0.17772 px at t=10.000
[w1] drift reversal (velocity turn): t=20.033 pos=(-96.000, -96.000) step=0.00024
[w1] drift reversal (velocity turn): t=40.033 pos=(-0.000, -0.000) step=0.00023
[w1] pulse trace: A rest->flare at t=1.00, B rest->flare at t=1.70, C at t=2.60, D (mid-flight) at t=2.75
[w1]   t=0.95  modulate.r=2.0000
[w1]   t=1.00  modulate.r=2.0000
[w1]   t=1.10  modulate.r=2.3500
[w1]   t=1.20  modulate.r=2.1750
[w1]   t=1.30  modulate.r=2.0469
[w1]   t=1.40  modulate.r=2.0000
[w1]   t=1.50  modulate.r=2.0000
[w1]   t=1.70  modulate.r=2.0000
[w1]   t=1.80  modulate.r=2.3381
[w1]   t=1.90  modulate.r=2.2021
[w1]   t=2.10  modulate.r=2.0013
[w1]   t=2.20  modulate.r=2.0000
[w1]   t=2.60  modulate.r=2.0000
[w1]   t=2.70  modulate.r=2.3381
[w1]   t=2.80  modulate.r=2.3047
[w1]   t=2.85  modulate.r=2.3469
[w1]   t=2.95  modulate.r=2.2021
[w1]   t=3.05  modulate.r=2.0633
[w1]   t=3.15  modulate.r=2.0013
[w1] pulse A (from rest): peak=2.3500 at rel=0.100, rel 0.40=2.0000
[w1] pulse B (from rest): peak=2.3500 at rel=0.117, rel 0.40=2.0013
[w1] pulse C (from rest): peak=2.3500 at rel=0.117
[w1] pulse D (mid-flight re-trigger): value before=2.3500 after=2.2594, peak=2.3500 at rel=0.117, rel 0.40=2.0013

exit=0
```

The probe triggers pulses by calling the screen's own `_set_active_verb(index)` (the brief's noun for the hook);
`_ready`'s focus chain is what makes the focus owner readable, not the trigger.

**4. Headless scene smoke run — `main_menu.tscn`, 300 frames**

```
..._console.exe --headless --path <proj> res://ui/screens/main_menu.tscn --quit-after 300
Godot Engine v4.7.2.stable.official.ed1daf0bf - https://godotengine.org

[godot_ai game_helper] registered mcp capture (debugger active=false, logger=true)
EXIT=0

WARNING: 4 ObjectDB instances were leaked at exit (run with `--verbose` for details).
ERROR: 2 resources still in use at exit (run with `--verbose` for details).
```

No parse error, no missing resource, no node-not-found, no theme-item or orphan-node complaint; the two
teardown messages are pre-existing and unrelated to W1 (see open point 4).

**5. Teardown-baseline runs on untouched scenes (same binary/path)** — the leak is specific to a scene that
starts music, not to `main_menu.gd`:

```
res://ui/screens/loading.tscn --quit-after 300   EXIT=0  (silent, no leak lines)
res://ui/screens/boot.tscn    --quit-after 300   EXIT=0  (silent, no leak lines)
```

**6. Leak attribution (`--verbose`, first run above repeated)** — the leaked objects are the menu music:

```
Leaked instance: AudioStreamPlaybackOggVorbis - Reference count: 1
Leaked instance: OggPacketSequencePlayback - Reference count: 1
Leaked instance: OggPacketSequence - Reference count: 3
Leaked instance: AudioStreamOggVorbis - Reference count: 1
Resource still in use: res://assets/audio/music/mus_menu_theme_01.ogg (AudioStreamOggVorbis)
Orphan StringName: Music (static: 0, total: 2)
```

No tween, texture or scene resource is leaked, so nothing in the W1 diff contributes. `AudioManager.play_music`
is called from exactly one place in the project (`main_menu.gd:118`, unchanged), which is also why only this
scene exhibits it.

**7. `tools/` after the work**

```
tools/_probe_w2.gd          (parallel wave W2, untouched)
tools/_probe_w3.gd          (parallel wave W3, untouched)
tools/build_theme.gd        (+ .uid)
tools/derive_icon_tints.gd  (+ .uid)
```

`tools/_probe_w1.gd` is deleted; it never acquired a `.uid` sidecar (files created outside the editor get their
sidecar on the editor's next scan, and the probe was removed first — verified by `ls` before deletion).
A second probe file was also deleted: none. No new `res://` file exists from this wave.

---

## Acceptance summary

| Item | Criterion (brief) | Measurement | Verdict |
|---|---|---|---|
| 1 | Focus ring gone; focused draws what idle/hover draw | `FOCUS_BORDER` absent from the constant map; `_focus_color`/`_focused`/`_set_focused`/`accent_danger_bright` 0 occurrences; `draw_rect` 2 (hover/idle); focus chain intact (`PLAY` `has_focus()` true) | pass |
| 1 | Removal applies everywhere `MenuButton` is used | Ring drawing exists only in `menu_button.gd`, which all three consumers instance | pass (by construction) |
| 2 | Pulse 2.0 → 2.35 over 0.10 s, back to 2.0 over 0.30 s | peak 2.3500 at rel 0.100 s; 2.0000 at rel 0.400 s; reproducible from rest (3 events) | pass |
| 2 | Previous pulse killed before re-trigger | mid-flight re-trigger at 2.767 s: 2.3500 → 2.2594 → peak 2.3500 → 2.0013, no snap to rest | pass |
| 2 | Left band untouched; resting value 2.0 | `_ticks`/`TICK_*` untouched; end-of-run modulate exactly 2.0000 | pass |
| 3 | `DRIFT_DISTANCE` 24 → 96, `DRIFT_SECONDS` 40 → 20, shape kept | source; amplitude −96.0000 at t = 20.017 s; two legs, two reversals, one full cycle in 45.5 s | pass |
| 3 | Motion clearly perceptible | 0.17772 px/frame peak (10.66 px/s diagonal), 4.8 px/s mean per axis vs 0.6 px/s before — 4× travel at 8× speed | pass |
| 3 | No pop/seam across a cycle | loop seam at t = 40.033 s: step 0.00023 px at position (−0.000, −0.000) vs 0.17772 px peak; no positional jump anywhere in 2731 frames | pass |
| — | Only W1 files touched | `glob` mtime order; `project.godot`, `vajb_theme.tres`, `build_theme.gd` and `docs/` untouched | pass |
| — | No hex literals, no per-node font-size overrides | added code uses `Color(level, level, level, 1.0)` (white multiplier, the file's existing pattern) and no colour names | pass |

---

## Open points / deviations

1. **Drift slack reserved in code (deviation, §3 above).** Required to keep item 3's "no seam" acceptance with
   `main_menu.tscn` outside W1's file list. It reproduces exactly the geometry the scene would have at
   `offset_right/bottom = 96`. Owner action if preferred otherwise: set those two offsets in `main_menu.tscn`
   and delete `_reserve_drift_slack()`; the two must stay in step. The scene's current `24.0` values are dead
   once `_ready` has run.
2. **The mandated `--check-only` parse check cannot validate `main_menu.gd`** (autoload identifiers, proven
   with the untouched `settings.gd` baseline). The brief's checklist should pair it with the headless scene run.
   W2/W3/W4 screens that name autoloads have the same limitation.
3. **`_focused` retired with the ring, and `AGENTS.md` gap 10 cites it.** The reliable live focus check is now
   the inner `Button.has_focus()` (measured `true` on the focused PLAY plate). `AGENTS.md` is outside W1's
   files, so it is reported rather than edited.
4. **Pre-existing teardown warning on this scene.** `4 ObjectDB instances leaked / 2 resources still in use` at
   quit is the `mus_menu_theme_01.ogg` stream held by `AudioManager` (verbose attribution above); the untouched
   `loading.tscn`/`boot.tscn` runs print none of it. Out of W1's scope; noted so W6 does not attribute it here.
5. **Rapid focus movement gives a sustained, not a full-amplitude, flare.** A re-trigger inside the 0.40 s
   envelope keeps the current brightness (2.35 → 2.26) instead of dropping to rest first (measured). If the
   owner prefers a full 2.0 → 2.35 flare on every move, the change is to set `_badge.modulate` to the resting
   value inside `_pulse_emblem()` before the tween — deliberately not done, since the brief asks only to kill
   the previous tween.
6. **The boot pulse is intentional but observable.** Focus lands on PLAY during `_ready`, so the emblem flares
   once as the menu appears (measured mid-flare at frame 3). Moving the call to the two focus handlers removes
   it if the owner rules that way.

---

## Appendix — probe source (deleted; re-create at `res://tools/_probe_w1.gd` to re-measure)

Run with `..._console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --fixed-fps 60 --script res://tools/_probe_w1.gd`.
`--fixed-fps` makes the run deterministic in simulated time and lets 45.5 s of drift and four pulse events
complete in seconds of wall clock.

```gdscript
extends SceneTree
## Throwaway W1 measurement probe (deleted, with its .uid, before the W1 report lands).
## Measures: ring plumbing absence, emblem pulse envelope (rest, flare, settle, re-trigger),
## backdrop drift amplitude, loop-seam continuity and viewport edge coverage.
## Run: ..._console.exe --headless --path <proj> --fixed-fps 60 --script res://tools/_probe_w1.gd

const MENU_SCENE: String = "res://ui/screens/main_menu.tscn"
const MENU_BUTTON_SCRIPT: String = "res://ui/components/menu_button.gd"
const RUN_SECONDS: float = 45.5
## Pulse triggers: A and B from rest (envelope), C then D 0.15 s later (re-trigger continuity).
const PULSES: Array[float] = [1.0, 1.7, 2.6, 2.75]
const TABLE_START: float = 0.95
const TABLE_END: float = 3.40

var _menu: Control
var _layer: Control
var _backdrop: Control
var _badge: CanvasItem
var _button_script: Script

var _t: float = 0.0
var _frames: int = 0
var _samples: Array[Dictionary] = []
var _mod_times: PackedFloat32Array = PackedFloat32Array()
var _mod_values: PackedFloat32Array = PackedFloat32Array()
var _pulses_fired: int = 0
var _reported: bool = false


func _initialize() -> void:
	_button_script = load(MENU_BUTTON_SCRIPT)
	var constants: Dictionary = _button_script.get_script_constant_map()
	print("[w1] menu_button.gd FOCUS_BORDER const present: ", constants.has("FOCUS_BORDER"))
	print("[w1] menu_button.gd '_focus_color' occurrences in source: ", _count(MENU_BUTTON_SCRIPT, "_focus_color"))
	print("[w1] menu_button.gd 'accent_danger_bright' occurrences in source: ", _count(MENU_BUTTON_SCRIPT, "accent_danger_bright"))
	print("[w1] menu_button.gd '_focused' occurrences in source: ", _count(MENU_BUTTON_SCRIPT, "_focused"))
	print("[w1] menu_button.gd '_set_focused' occurrences in source: ", _count(MENU_BUTTON_SCRIPT, "_set_focused"))
	print("[w1] menu_button.gd 'draw_rect' occurrences in source: ", _count(MENU_BUTTON_SCRIPT, "draw_rect"))
	var packed: PackedScene = load(MENU_SCENE)
	_menu = packed.instantiate()
	root.add_child(_menu)
	_layer = _menu.get_node(^"BackdropLayer")
	_backdrop = _menu.get_node(^"%Backdrop")
	_badge = _menu.get_node(^"%InsigniaBadge")


func _process(delta: float) -> bool:
	_frames += 1
	_t += delta
	if _backdrop == null or _badge == null:
		print("[w1] FAILED to resolve Backdrop/InsigniaBadge")
		quit()
		return true
	if _frames == 3:
		print("[w1] canvas rect (MainMenu): ", _menu.size, "  clip layer rect: ", _layer.size, " at ", _layer.global_position)
		print("[w1] backdrop offsets: right=%.1f bottom=%.1f  size=%s" % [_backdrop.offset_right, _backdrop.offset_bottom, str(_backdrop.size)])
		print("[w1] emblem resting modulate: ", _badge.modulate)
		var plate: Button = _menu.get_node(^"SafeArea/Bands/MiddleBand/CommandColumn/VerbStack/PlayRow/PlayButton/Button")
		print("[w1] PLAY plate focus owner: ", plate.get_viewport().gui_get_focus_owner() == plate, "  has_focus()=", plate.has_focus())
	var origin: Vector2 = _layer.global_position
	_samples.append({
		"t": _t,
		"x": _backdrop.position.x,
		"y": _backdrop.position.y,
		"left": _backdrop.global_position.x - origin.x,
		"top": _backdrop.global_position.y - origin.y,
		"right": (origin.x + _layer.size.x) - (_backdrop.global_position.x + _backdrop.size.x),
		"bottom": (origin.y + _layer.size.y) - (_backdrop.global_position.y + _backdrop.size.y),
	})
	if _pulses_fired < PULSES.size() and _t >= PULSES[_pulses_fired]:
		print("[w1] pulse %d trigger at t=%.3f, modulate.r=%.4f" % [_pulses_fired, _t, _badge.modulate.r])
		_menu._set_active_verb(1 + _pulses_fired % 2)
		_pulses_fired += 1
	if _t >= TABLE_START and _t <= TABLE_END:
		_mod_times.append(_t)
		_mod_values.append(_badge.modulate.r)
	if _t >= RUN_SECONDS and not _reported:
		_reported = true
		_report()
		_menu.free()
		_menu = null
		quit()
		return true
	return false


func _report() -> void:
	print("[w1] frames=%d samples=%d sim_time=%.3f" % [_frames, _samples.size(), _t])
	print("[w1] emblem modulate at the end of the run: %.4f" % _badge.modulate.r)
	var min_x: float = 0.0
	var min_y: float = 0.0
	var min_x_t: float = 0.0
	var max_right: float = -1e9
	var max_right_t: float = 0.0
	var max_bottom: float = -1e9
	var max_bottom_t: float = 0.0
	var max_left: float = -1e9
	var max_left_t: float = 0.0
	var max_top: float = -1e9
	var max_top_t: float = 0.0
	var max_step: float = 0.0
	var max_step_t: float = 0.0
	var reversals: Array[String] = []
	for index in _samples.size():
		var sample: Dictionary = _samples[index]
		if sample["x"] < min_x:
			min_x = sample["x"]
			min_x_t = sample["t"]
		if sample["y"] < min_y:
			min_y = sample["y"]
		if sample["right"] > max_right:
			max_right = sample["right"]
			max_right_t = sample["t"]
		if sample["bottom"] > max_bottom:
			max_bottom = sample["bottom"]
			max_bottom_t = sample["t"]
		if sample["left"] > max_left:
			max_left = sample["left"]
			max_left_t = sample["t"]
		if sample["top"] > max_top:
			max_top = sample["top"]
			max_top_t = sample["t"]
		if index > 0:
			var previous: Dictionary = _samples[index - 1]
			var dx: float = sample["x"] - previous["x"]
			var dy: float = sample["y"] - previous["y"]
			var step: float = sqrt(dx * dx + dy * dy)
			if step > max_step:
				max_step = step
				max_step_t = sample["t"]
			if index > 1:
				var previous_dx: float = previous["x"] - _samples[index - 2]["x"]
				if absf(previous_dx) > 0.0 and signf(dx) != signf(previous_dx):
					reversals.append("t=%.3f pos=(%.3f, %.3f) step=%.5f" % [sample["t"], sample["x"], sample["y"], step])
	print("[w1] drift min position x=%.4f at t=%.3f, y=%.4f (target -96.0, so amplitude measured)" % [min_x, min_x_t, min_y])
	print("[w1] edge margins over the run, against the clip layer rect: right=%.4f (t=%.3f) bottom=%.4f (t=%.3f) left=%.4f (t=%.3f) top=%.4f (t=%.3f)" % [max_right, max_right_t, max_bottom, max_bottom_t, max_left, max_left_t, max_top, max_top_t])
	print("[w1] counterfactual with the scene's 24 px slack: right/bottom band = 96 - 24 = 72 px uncovered")
	print("[w1] max per-frame drift step=%.5f px at t=%.3f" % [max_step, max_step_t])
	for line in reversals:
		print("[w1] drift reversal (velocity turn): ", line)
	print("[w1] pulse trace: A rest->flare at t=1.00, B rest->flare at t=1.70, C at t=2.60, D (mid-flight) at t=2.75")
	for target in [0.95, 1.00, 1.10, 1.20, 1.30, 1.40, 1.50, 1.70, 1.80, 1.90, 2.10, 2.20, 2.60, 2.70, 2.80, 2.85, 2.95, 3.05, 3.15]:
		print("[w1]   t=%.2f  modulate.r=%.4f" % [target, _value_at(target)])
	print("[w1] pulse A (from rest): peak=%.4f at rel=%.3f, rel 0.40=%.4f" % [
		_peak(PULSES[0], PULSES[1]),
		_peak_rel(PULSES[0], PULSES[1]),
		_value_at(PULSES[0] + 0.40),
	])
	print("[w1] pulse B (from rest): peak=%.4f at rel=%.3f, rel 0.40=%.4f" % [
		_peak(PULSES[1], PULSES[2]),
		_peak_rel(PULSES[1], PULSES[2]),
		_value_at(PULSES[1] + 0.40),
	])
	print("[w1] pulse C (from rest): peak=%.4f at rel=%.3f" % [
		_peak(PULSES[2], PULSES[3]),
		_peak_rel(PULSES[2], PULSES[3]),
	])
	print("[w1] pulse D (mid-flight re-trigger): value before=%.4f after=%.4f, peak=%.4f at rel=%.3f, rel 0.40=%.4f" % [
		_value_at(PULSES[3] - 0.02),
		_value_at(PULSES[3] + 0.02),
		_peak(PULSES[3], PULSES[3] + 0.6),
		_peak_rel(PULSES[3], PULSES[3] + 0.6),
		_value_at(PULSES[3] + 0.40),
	])


func _value_at(time: float) -> float:
	var best: float = -1.0
	for index in _mod_times.size():
		if _mod_times[index] <= time + 0.0001:
			best = _mod_values[index]
	return best


func _peak(from_time: float, to_time: float) -> float:
	var best: float = -1.0
	for index in _mod_times.size():
		if _mod_times[index] >= from_time and _mod_times[index] < to_time:
			best = maxf(best, _mod_values[index])
	return best


func _peak_rel(from_time: float, to_time: float) -> float:
	var best: float = -1.0
	var best_time: float = 0.0
	for index in _mod_times.size():
		if _mod_times[index] >= from_time and _mod_times[index] < to_time and _mod_values[index] > best:
			best = _mod_values[index]
			best_time = _mod_times[index] - from_time
	return best_time


func _count(path: String, needle: String) -> int:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		return -1
	return text.count(needle)
```
