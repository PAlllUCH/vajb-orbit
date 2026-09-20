# Fix Wave 1 — W5 (fonts) report

Date: 2026-09-18. Scope: **W5 only** from `.agents/gen/fix_wave1_task.md`, implementing
`docs/design/IMPLEMENTATION_PLAN.md` §9.8 item 2 (typography) and retiring §3.2's
`default_font intentionally unset`.

Method: the three shipped fonts are imported by the editor, so the headless theme build
loads them exactly like the existing UI textures. Everything below is a measurement: the
generator's own report, two consecutive regenerations compared by sha256, a throwaway
`res://tools/_probe_w5.gd` scene tree, and file hashes taken before and after.

**No editor and no graphical game was launched.** Every engine call is
`C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" ...`.

---

## 1. Files changed

| File | Bytes before | Bytes after | sha256 before | sha256 after |
|---|---|---|---|---|
| `vajb-orbit/tools/build_theme.gd` | 18285 | **21341** | `2DFF63AE…F88684` | `42B6B97F…2DF7D8` |
| `vajb-orbit/autoload/router.gd` | 10993 | **11044** | `7AE606BB…0AC665` | `C82C756D…C650AE` |
| `vajb-orbit/ui/theme/vajb_theme.tres` (regenerated) | 24310 | **25708** | `A1784A8F…EA0ED6` | `B92C03A5…7ADE59` |
| `vajb-orbit/ui/screens/main_menu.gd` | 13222 | **13576** | `65977882…FE202DC` | `9733A665…38BC877` |
| `vajb-orbit/ui/screens/station.tscn` | 10435 | **10432** | `03B4BF52…ADB5AF` | `3DE19EAF…61F3F2` |
| `vajb-orbit/ui/hud/hud.tscn` | 17212 | **17210** | `C570FC89…EF3004` | `215DC80A…27851B9` |

`router.gd` before-size is arithmetic, not a snapshot: the file is LF-only and exactly one
51-byte line was inserted (49 characters + tab + LF), measured afterwards as 341 lines /
11044 bytes with zero CRLF pairs. Every other before-value was hashed on disk before the
first edit.

Nothing else under `vajb-orbit/` was written by W5. `project.godot`, `addons/godot_ai/`,
`docs/`, `assets/` and the W1–W4 files are untouched; the only other project file with a
recent mtime is W2's `ui/station/outfitting_panel.gd` (14:33, not mine).

---

## 2. `tools/build_theme.gd` — the typography block

New constants (`:31-57`), all paths, no hex literal added anywhere:

```gdscript
## Typography (IMPLEMENTATION_PLAN section 9.8 item 2). Three OFL families ship in
## assets/fonts with their licence texts beside them: Oxanium (variable) as the display
## face pinned to wght 700, Rajdhani as the body face, Saira Stencil One as the flavour
## face. They are imported like any other resource, so this headless build loads them too.
const FONT_OXANIUM := "res://assets/fonts/Oxanium[wght].ttf"
const FONT_RAJDHANI_REGULAR := "res://assets/fonts/Rajdhani-Regular.ttf"
const FONT_RAJDHANI_MEDIUM := "res://assets/fonts/Rajdhani-Medium.ttf"
const FONT_RAJDHANI_SEMIBOLD := "res://assets/fonts/Rajdhani-SemiBold.ttf"
const FONT_SAIRA_STENCIL := "res://assets/fonts/SairaStencilOne-Regular.ttf"

const TITLE_WEIGHT := 700

## Which face each variation draws, keyed by the role names _load_fonts() returns.
## `body` is also Theme.default_font, so an unlisted type inherits Rajdhani-Regular.
const FONT_ROLES: Dictionary = {
	&"ScreenTitle": &"display",
	&"HeroTitle": &"display",
	&"StationPanelTitle": &"display",
	&"DialogTitle": &"display",
	&"HudReadout": &"display",
	&"MenuButtonPlate": &"display",
	&"StationValue": &"semibold",
	&"SectionHeader": &"medium",
	&"StationCaption": &"medium",
	&"Version": &"flavour",
	&"FlavourText": &"flavour",
}
```

New `FlavourText` variation, registered like every other label variation:
`LABEL_VARIATIONS` `&"FlavourText": 13` (`:99`), `VARIATION_BASE` `&"FlavourText": &"Label"`
(`:113`), colour `text_dim` (`:301`, next to `StationCaption`).

Registration (`_register_fonts` `:183`, `_load_fonts` `:195`, `_first_font` `:209`), called
from `_build()` right after `theme.default_font_size = BASE_FONT_SIZE`:

```gdscript
func _register_fonts(theme: Theme) -> void:
	var fonts: Dictionary = _load_fonts()
	theme.default_font = fonts[&"body"]
	for variation: StringName in FONT_ROLES:
		var font: Font = fonts[FONT_ROLES[variation]]
		theme.set_font(&"font", variation, font)


func _load_fonts() -> Dictionary:
	var body: FontFile = _first_font(FONT_RAJDHANI_REGULAR, null)
	var display: FontVariation = FontVariation.new()
	display.base_font = _first_font(FONT_OXANIUM, body)
	display.variation_opentype = {&"wght": TITLE_WEIGHT}
	return {
		&"display": display,
		&"body": body,
		&"medium": _first_font(FONT_RAJDHANI_MEDIUM, body),
		&"semibold": _first_font(FONT_RAJDHANI_SEMIBOLD, body),
		&"flavour": _first_font(FONT_SAIRA_STENCIL, body),
	}
```

`_first_font()` reports a missing face with `printerr` and falls back to the body face, so
a failed load can never leave a variation without a font (no silent unstyled type).

The superseded report line (`:501-509`) now reads its own facts and prints the face of
every wired variation:

```gdscript
	print("[build_theme] default_font = %s" % _font_label(theme.default_font))
	print("[build_theme] default_font_size = %d" % theme.default_font_size)
	for variation: StringName in FONT_ROLES:
		print("  font %s = %s @ %d" % [ … ])
```

**Interpretation choices taken inside the brief's latitude:** Rajdhani-Medium is applied to
`SectionHeader` and `StationCaption` ("where a caption needs more presence"), and the
flavour face is wired to exactly the two variations the brief names — `Version` (the
existing stamp variation, font swap) and the new `FlavourText`. No other face is used and
no fourth family was introduced.

---

## 3. `autoload/router.gd` — the FONT_SIZE_ITEMS mirror

`FlavourText` is a new variation carrying a font size, so it is a new font-size item and
`Router.FONT_SIZE_ITEMS` had to grow or `ui_scale` would silently stop reaching it:

```gdscript
 	{&"type": &"StationCaption", &"item": &"font_size"},
+	{&"type": &"FlavourText", &"item": &"font_size"},
 	{&"type": &"ItemList", &"item": &"font_size"},
```

**Item counts: 27 → 28 both sides.** The theme now holds 28 font-size items (probe line
below), the Router list holds 28 entries, and the two-way coverage check is `0` and `0` —
so every theme item still follows `ui_scale`.

---

## 4. The four applies

| Target | Where | Before | After |
|---|---|---|---|
| main-menu read-out (`FocusReadout`) | `ui/screens/main_menu.gd` — new `READOUT_VARIATION` const + one line in `_ready()` | `HudReadout` (now display face) | `FlavourText` |
| station header subline (`StationLocation`) | `ui/screens/station.tscn:100` | `StationCaption` | `FlavourText` |
| HUD minimap sector label (`SectorLabel`) | `ui/hud/hud.tscn:409` | `SectionHeader` | `FlavourText` |
| version stamp (`VersionLabel`) | `ui/theme/vajb_theme.tres` via the `Version` variation (font swap) | Rajdhani (default) | Saira Stencil One |

`ui/screens/main_menu.gd`:

```gdscript
## The footer read-out carries the flavour face (IMPLEMENTATION_PLAN section 9.8 item 2).
## The scene declares HudReadout, which the display face now owns, so the swap to the
## flavour variation lands here rather than in a per-node font override.
const READOUT_VARIATION: StringName = &"FlavourText"
…
	_apply_token_colours()
	_readout.theme_type_variation = READOUT_VARIATION
	_readout.text = READOUT[_active_verb]
```

The version stamp needed no scene edit: `main_menu.tscn:274` already declares
`theme_type_variation = &"Version"`, and the variation itself is what changed. Note for the
reviewer: the stamp keeps its pre-existing per-node `font_color` override
(`main_menu.gd:157`, `text_primary`, the owner's contrast ruling from D4b) — the face is the
flavour face, the colour stays the brighter stamp colour. No per-node **font-size** override
exists anywhere in the project (`add_theme_font_size_override` appears only inside
`addons/godot_ai/`).

---

## 5. Regeneration and determinism

Baseline first — the **pre-existing** generator reproduced the committed theme byte for
byte, so the later comparison is against a stable artifact:

```
$ …_console.exe --headless --path <proj> --script res://tools/build_theme.gd
[build_theme] saved res://ui/theme/vajb_theme.tres
[build_theme] variations: 18 [ScreenTitle, SectionHeader, HudReadout, DialogTitle, Version, SlotNumber, HeroTitle, StationPanelTitle, StationValue, StationCaption, MenuButton, MenuButtonPlate, StationButton, HudHullBar, HudShieldBar, SlotButtonWeapon, SlotButtonCargo, PanelRaised]
[build_theme] default_font_size = 14 (default_font intentionally unset)
exit=0
theme sha256 before this run = A1784A8F2551225F2CC936E899B0124BE0F056C5C73994C23A5EA60B8DEA0ED6
theme sha256 after  this run = A1784A8F2551225F2CC936E899B0124BE0F056C5C73994C23A5EA60B8DEA0ED6   (identical)
```

Then the two required runs of the **new** generator
(`.agents/gen/w5_determinism.ps1`, logs `w5_theme_run1.txt` / `w5_theme_run2.txt`):

```
Run Exit Sha256                                                            Size
--- ---- ------                                                            ----
  1    0 B92C03A5AB96573361BBE573A7A1E67AFE505CB5BA13AD28BD5CE14C287ADE59 25708
  2    0 B92C03A5AB96573361BBE573A7A1E67AFE505CB5BA13AD28BD5CE14C287ADE59 25708

DETERMINISTIC: run1 and run2 .tres sha256 identical
```

A third run (`w5_theme_run3.txt`, exit 0) also left the file at
`B92C03A5…7ADE59 / 25708` bytes. Determinism therefore holds across three separate
processes, including the `FontVariation` sub-resource and the four new `FontFile`
ext-resources the saver had to emit.

Generator output after the change (`w5_theme_run1.txt`, the closed form of it):

```
[build_theme] saved res://ui/theme/vajb_theme.tres
[build_theme] Tokens colours: 12
… (23 stylebox types, unchanged)
[build_theme] variations: 19 [ScreenTitle, SectionHeader, HudReadout, DialogTitle, Version, SlotNumber, HeroTitle, StationPanelTitle, StationValue, StationCaption, FlavourText, MenuButton, MenuButtonPlate, StationButton, HudHullBar, HudShieldBar, SlotButtonWeapon, SlotButtonCargo, PanelRaised]
[build_theme] default_font = res://assets/fonts/Rajdhani-Regular.ttf
[build_theme] default_font_size = 14
  font ScreenTitle = FontVariation (embedded) @ 22
  font HeroTitle = FontVariation (embedded) @ 48
  font StationPanelTitle = FontVariation (embedded) @ 20
  font DialogTitle = FontVariation (embedded) @ 18
  font HudReadout = FontVariation (embedded) @ 18
  font MenuButtonPlate = FontVariation (embedded) @ 34
  font StationValue = res://assets/fonts/Rajdhani-SemiBold.ttf @ 18
  font SectionHeader = res://assets/fonts/Rajdhani-Medium.ttf @ 16
  font StationCaption = res://assets/fonts/Rajdhani-Medium.ttf @ 13
  font Version = res://assets/fonts/SairaStencilOne-Regular.ttf @ 13
  font FlavourText = res://assets/fonts/SairaStencilOne-Regular.ttf @ 13
```

The `FontVariation` shows as `(embedded)` because it has no `resource_path` of its own; the
`.tres` carries it as a `[sub_resource]` over the Oxanium ext-resource:

```
[ext_resource type="FontFile" path="res://assets/fonts/Oxanium[wght].ttf" id="2_85h1f"]
[ext_resource type="FontFile" path="res://assets/fonts/SairaStencilOne-Regular.ttf" id="3_tcy2p"]
[ext_resource type="FontFile" path="res://assets/fonts/Rajdhani-Medium.ttf" id="8_4cpsb"]
[ext_resource type="FontFile" path="res://assets/fonts/Rajdhani-SemiBold.ttf" id="17_0g3d5"]
[ext_resource type="FontFile" path="res://assets/fonts/Rajdhani-Regular.ttf" id="18_i4by3"]

[sub_resource type="FontVariation" id="FontVariation_u8swm"]
base_font = ExtResource("2_85h1f")
variation_opentype = {
&"wght": 700
}

default_font = ExtResource("18_i4by3")
default_font_size = 14
```

and the per-type wiring, read straight out of the generated `.tres`:

```
ScreenTitle/fonts/font       = SubResource("FontVariation_u8swm")   @ 22
HeroTitle/fonts/font         = SubResource("FontVariation_u8swm")   @ 48
StationPanelTitle/fonts/font = SubResource("FontVariation_u8swm")   @ 20
DialogTitle/fonts/font       = SubResource("FontVariation_u8swm")   @ 18
HudReadout/fonts/font        = SubResource("FontVariation_u8swm")   @ 18
MenuButtonPlate/fonts/font   = SubResource("FontVariation_u8swm")   @ 34
StationValue/fonts/font      = ExtResource("17_0g3d5")              @ 18   (Rajdhani-SemiBold)
SectionHeader/fonts/font     = ExtResource("8_4cpsb")               @ 16   (Rajdhani-Medium)
StationCaption/fonts/font    = ExtResource("8_4cpsb")               @ 13   (Rajdhani-Medium)
Version/fonts/font           = ExtResource("3_tcy2p")               @ 13   (Saira Stencil One)
FlavourText/fonts/font       = ExtResource("3_tcy2p")               @ 13   (Saira Stencil One)
FlavourText/base_type        = &"Label"
FlavourText/colors/font_color = Color(0.41960785, 0.45490196, 0.5176471, 1)   (text_dim)
```

Inventory deltas: **font-size items 27 → 28**, **variations 18 → 19** (18 registered
`base_type` entries after the change, measured; `MenuButton` remains the deliberate
native-class exception), stylebox types unchanged at 23, `Tokens` unchanged at 12, and
`default_font_size` unchanged at 14.

---

## 6. Acceptance evidence — probe run

Throwaway `res://tools/_probe_w5.gd` (`extends SceneTree`, `quit()`-terminated), run twice;
the [w5] lines of the two runs are **byte-identical** (`Compare-Object` found no
difference). Deleted with its `.uid` afterwards; the source is archived as
`.agents/gen/w5_probe_source.gd` (sha256 `22D32EAD…E3578BF5`) so the appendix is exact.

Theme resolution, as measured in the engine (not asserted):

```
[w5] theme path = res://ui/theme/vajb_theme.tres
[w5] default_font = res://assets/fonts/Rajdhani-Regular.ttf
[w5] default_font_size = 14
[w5] ScreenTitle -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 22 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] SectionHeader -> res://assets/fonts/Rajdhani-Medium.ttf @ 16 colour (0.4196, 0.4549, 0.5176, 1.0)
[w5] HudReadout -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 18 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] DialogTitle -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 18 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] Version -> res://assets/fonts/SairaStencilOne-Regular.ttf @ 13 colour (0.4196, 0.4549, 0.5176, 1.0)
[w5] HeroTitle -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 48 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] StationPanelTitle -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 20 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] StationValue -> res://assets/fonts/Rajdhani-SemiBold.ttf @ 18 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] StationCaption -> res://assets/fonts/Rajdhani-Medium.ttf @ 13 colour (0.4196, 0.4549, 0.5176, 1.0)
[w5] FlavourText -> res://assets/fonts/SairaStencilOne-Regular.ttf @ 13 colour (0.4196, 0.4549, 0.5176, 1.0)
[w5] MenuButtonPlate -> FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @ 34 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] Label -> res://assets/fonts/Rajdhani-Regular.ttf @ 14 colour (0.7882, 0.8196, 0.8627, 1.0)
[w5] theme font-size items = 28, Router.FONT_SIZE_ITEMS = 28
[w5] in theme not in router = 0 []
[w5] in router not in theme = 0 []
[w5] FlavourText in Router = true
```

Runtime resolution of the four applies — the three scenes instantiated under the real
autoloads, laid out, and their labels asked what face they actually draw:

```
[w5] read-out (main_menu.tscn): variation=FlavourText face=res://assets/fonts/SairaStencilOne-Regular.ttf size=13 text=ENTER THE STATION HUB
[w5] PLAY row: plate size=(350.0, 70.0) custom_minimum=(350.0, 70.0) inner min=(77.0, 35.0) font=FontVariation over res://assets/fonts/Oxanium[wght].ttf opentype={ &"wght": 700 } @34
[w5] station subline (station.tscn): variation=FlavourText face=res://assets/fonts/SairaStencilOne-Regular.ttf size=13 text=DOCKING RING 04 · HELIOS DRIFT · HULL TRAFFIC LOW
[w5] minimap sector label (hud.tscn): variation=FlavourText face=res://assets/fonts/SairaStencilOne-Regular.ttf size=13 text=
```

Reading:

1. All three edited labels resolve `FlavourText` → Saira Stencil One at 13 px, dim
   (`0.4196, 0.4549, 0.5176`) — the station subline still carries the W4 string.
2. The sector label is empty by design: `hud.gd` only writes it from `set_sector_name()`
   (`hud.gd:441-443`), and `game.gd` calls that at boot. The variation, face and size are
   what W5 owns, and they are measured.
3. The display face at 34 px does not disturb the menu geometry: the plate row still
   measures **350 × 70** with `custom_minimum_size = (350, 70)` and an inner Button minimum
   of only `(77, 35)`, so `menu_button.gd`'s "row follows the font above the 70 px art
   floor" rule (MAIN_MENU_V2 §12.1) is unaffected at `ui_scale` 1.0.

---

## 7. Side effects on `user://`

| File | Before W5 | After W5 | Verdict |
|---|---|---|---|
| `user://settings.cfg` | `EDB17B3F…233617`, mtime 09:02:50 | `EDB17B3F…233617`, mtime 09:02:50 | **byte-identical**, untouched |
| `user://profile.cfg` | `A2396199…6D9259`, 1686 B, mtime 14:20 | `2F114DBE…910DA6`, 1681 B, mtime 14:42:22 | written once, by the market band roll (below) |

`profile.cfg` was rolled one market band during the first probe run — the WorldClock band
accumulator calling `Exchange.evaluate_market()` → `profile.set_market()`
(`game/exchange.gd:178-209`), which persists `last_band` plus the drifted `demand`/`trend`
values. Evidence that this is a wall-clock band boundary and not W5 code:

- the immediately following generator run (`w5_theme_run3.txt`, exit 0) left the file at
  `2F114DBE…910DA6`, byte-identical before and after;
- the re-run of the probe (same source, same output) left it at `2F114DBE…910DA6` too;
- no W5 code path touches the profile, and the only writer that ran is
  `Exchange.evaluate_market`, which mutates and persists the `market` dictionary alone
  (`state["last_band"] = now` / `profile.set_market(state)`), so every other key is what the
  previous workers left: credits 9625, one owned ship, empty cargo, the five default ammo
  stacks, default vitals. The 5-byte shrink is consistent with changed float digit counts
  inside `demand`.

`.agents/gen/profile_backup_20260918.cfg` (13:35, `B2A5E5FF…`) is an **earlier, richer**
probe state — 92349 credits, three ships, upgrades and cargo — saved before the profile was
reset, so it cannot witness the 14:20 bytes; it is context only, not a restore source.

The exact pre-run bytes were not snapshotted before the probe booted, so they cannot be
restored — the rolled values themselves are the output of a random walk
(`_drift_demand`) and are not derivable backwards. The post-run file is archived as
`.agents/gen/w5_profile_after.cfg` for the record. **Flagged for W6**: this is inherent to
booting the project headless (the earlier workers' runs crossed bands too); if the reviewer
wants the file reset to the 14:20 bytes, that needs a snapshot taken before the run.

---

## 8. Deviations and open points

1. **The main-menu read-out is swapped in `main_menu.gd`, not in `main_menu.tscn`.** W5's
   file list names `ui/screens/main_menu.gd` (readout) and omits `main_menu.tscn`, so the
   screen sets `theme_type_variation` in `_ready()` and the scene's `HudReadout`
   declaration stands as a stale-but-harmless property (`main_menu.tscn:265`). The run-time
   measurement above is the proof it lands. If the reviewer prefers the declaration in the
   scene (one-line change at `main_menu.tscn:265`), that is a strictly cosmetic relayout of
   ownership and needs a second W5 pass; I did not touch it because it is outside W5's file
   list.
2. **`--check-only` cannot validate `main_menu.gd`** — it compiles before autoload
   singletons exist, so `AudioManager` is unresolved. Same finding as W1's report, and it
   reproduces on an untouched file (`ui/screens/settings.gd` fails with `SettingsManager`).
   `main_menu.gd` is instead proven to compile and run by the probe above, which loads it
   with the autoloads live.
3. **Probe exit noise:** the probe run ends with
   `WARNING: 8 ObjectDB instances were leaked at exit` / `ERROR: 4 resources still in use at
   exit`. This is the project's known engine artifact (s2_task: "Known engine artifact, do
   not chase it"; `.agents/gen/leak_verbose.log` isolated it to Ogg playback objects),
   counted higher here because the probe quits mid-frame with three instantiated scenes and
   the menu's music stream still live. No project script leaks: the generator runs are
   clean.
4. **No picture of the type on screen.** W5's acceptance is the regenerated theme and its
   determinism, which is measured; a 1920×1080 render of the new faces would need the
   editor or the movie writer, which the brief forbids for this wave (no editor, no graphical
   game). Text-width/legibility of the stencil face at 13 px is therefore unmeasured and is
   the one judgement left to the live walkthrough.

---

## 9. Cleanliness

`tools/` after the run — only the two contract tools and their sidecars:

```
build_theme.gd            21341
build_theme.gd.uid           20
derive_icon_tints.gd       3598
derive_icon_tints.gd.uid     20
```

`Get-ChildItem -Recurse -Filter "_probe*"` over `vajb-orbit/`: **0 matches**.
Parse checks (`--check-only --script`, exit codes):

| Script | Exit |
|---|---|
| `res://tools/build_theme.gd` | 0 |
| `res://autoload/router.gd` | 0 |
| `res://ui/screens/main_menu.gd` | 1 — `Identifier not found: AudioManager` (see §8.2) |
| `res://ui/screens/settings.gd` (control, untouched) | 1 — `Identifier not found: SettingsManager` |

Evidence files left in `.agents/gen/`: `w5_theme_run1.txt`, `w5_theme_run2.txt`,
`w5_theme_run3.txt`, `w5_probe.txt`, `w5_probe_rerun.txt`, `w5_probe_source.gd`,
`w5_profile_after.cfg`, `w5_determinism.ps1`, and this report.

---

## Appendix A — the probe source that produced §6

Archived as `.agents/gen/w5_probe_source.gd` (152 lines, 4933 bytes) — the exact source
that was run, deleted from `res://tools/_probe_w5.gd` with its `.uid` after the
measurement, and reproduced here in full. Re-running the archived copy from the same
`res://tools/` path reproduces the §6 `[w5]` lines byte for byte (`Compare-Object` over
both logs: no difference).

```gdscript
extends SceneTree
## Throwaway W5 probe (deleted with its .uid after the run). Prints what the regenerated
## theme resolves to: the default face, every variation's face and size, the theme versus
## Router font-size item coverage, and the face the three edited scenes resolve at runtime.

const PATHS := preload("res://ui/paths.gd")

const VARIATIONS: Array[StringName] = [
	&"ScreenTitle",
	&"SectionHeader",
	&"HudReadout",
	&"DialogTitle",
	&"Version",
	&"HeroTitle",
	&"StationPanelTitle",
	&"StationValue",
	&"StationCaption",
	&"FlavourText",
	&"MenuButtonPlate",
	&"Label",
]

const TARGETS: Array[Dictionary] = [
	{
		&"scene": "res://ui/screens/main_menu.tscn",
		&"path": "%FocusReadout",
		&"note": "read-out",
		&"plate": "%PlayButton",
	},
	{
		&"scene": "res://ui/screens/station.tscn",
		&"path": "Layout/Page/Header/TitleBox/StationLocation",
		&"note": "station subline",
	},
	{
		&"scene": "res://ui/hud/hud.tscn",
		&"path": "CanvasLayer/BottomRight/MinimapPanel/MinimapBox/MinimapFooter/SectorLabel",
		&"note": "minimap sector label",
	},
]

var _theme: Theme


func _initialize() -> void:
	_run()


func _run() -> void:
	_theme = load(PATHS.THEME) as Theme
	if _theme == null:
		print("[w5] theme failed to load")
		quit()
		return
	print("[w5] theme path = %s" % PATHS.THEME)
	print("[w5] default_font = %s" % _face(_theme.default_font))
	print("[w5] default_font_size = %d" % _theme.default_font_size)
	for variation: StringName in VARIATIONS:
		print("[w5] %s -> %s @ %d colour %s" % [
			String(variation),
			_face(_theme.get_font(&"font", variation)),
			_theme.get_font_size(&"font_size", variation),
			_theme.get_color(&"font_color", variation),
		])
	_report_coverage()
	await _report_scenes()
	quit()


func _report_coverage() -> void:
	var theme_items: Dictionary = {}
	for type: StringName in _theme.get_font_size_type_list():
		for item: StringName in _theme.get_font_size_list(type):
			theme_items["%s/%s" % [String(type), String(item)]] = true
	var router_items: Dictionary = {}
	for entry: Dictionary in Router.FONT_SIZE_ITEMS:
		router_items["%s/%s" % [String(entry[&"type"]), String(entry[&"item"])]] = true
	var theme_only: Array[String] = []
	var router_only: Array[String] = []
	for key: String in theme_items:
		if not router_items.has(key):
			theme_only.append(key)
	for key: String in router_items:
		if not theme_items.has(key):
			router_only.append(key)
	theme_only.sort()
	router_only.sort()
	print("[w5] theme font-size items = %d, Router.FONT_SIZE_ITEMS = %d" % [theme_items.size(), router_items.size()])
	print("[w5] in theme not in router = %d %s" % [theme_only.size(), theme_only])
	print("[w5] in router not in theme = %d %s" % [router_only.size(), router_only])
	print("[w5] FlavourText in Router = %s" % str(router_items.has("FlavourText/font_size")))


func _report_scenes() -> void:
	for target: Dictionary in TARGETS:
		var packed: PackedScene = load(target[&"scene"]) as PackedScene
		if packed == null:
			print("[w5] %s failed to load" % target[&"scene"])
			continue
		var instance: Node = packed.instantiate()
		root.add_child(instance)
		await process_frame
		await process_frame
		var node: Node = instance.get_node_or_null(NodePath(target[&"path"]))
		if node == null:
			print("[w5] %s (%s): node %s not found" % [target[&"note"], target[&"scene"], target[&"path"]])
		else:
			var label := node as Label
			print("[w5] %s (%s): variation=%s face=%s size=%d text=%s" % [
				target[&"note"],
				target[&"scene"].get_file(),
				String(label.theme_type_variation),
				_face(label.get_theme_font(&"font")),
				label.get_theme_font_size(&"font_size"),
				label.text,
			])
		if target.has(&"plate"):
			_report_plate(instance, target[&"plate"])
		instance.queue_free()
		await process_frame


## The plate row height follows its font above the 70 px art floor (MAIN_MENU_V2 section
## 12.1), so the display face is measured here rather than assumed.
func _report_plate(instance: Node, path: NodePath) -> void:
	var plate: Control = instance.get_node_or_null(path) as Control
	if plate == null:
		print("[w5] plate %s not found" % String(path))
		return
	var button: Button = plate.get_node_or_null(^"Button") as Button
	print("[w5] PLAY row: plate size=%s custom_minimum=%s inner min=%s font=%s @%d" % [
		str(plate.size),
		str(plate.custom_minimum_size),
		str(button.get_minimum_size()) if button != null else "<no Button>",
		_face(button.get_theme_font(&"font")) if button != null else "<none>",
		button.get_theme_font_size(&"font_size") if button != null else -1,
	])


func _face(font: Font) -> String:
	if font == null:
		return "<none>"
	if font is FontVariation:
		var variation := font as FontVariation
		return "%s over %s opentype=%s" % [
			variation.get_class(),
			_face(variation.base_font),
			str(variation.variation_opentype),
		]
	if font.resource_path.is_empty():
		return "%s (embedded)" % font.get_class()
	return font.resource_path
```

## Appendix B — commands, verbatim

```
# 1. baseline regeneration of the pre-existing generator (proves the comparison artifact is stable)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/build_theme.gd
# 2. the two required runs + sha256 comparison
powershell -ExecutionPolicy Bypass -File "G:/Mój dysk/Projekty/Vajb Orbit/.agents/gen/w5_determinism.ps1"
# 3. parse checks (per changed script)
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --check-only --script res://<file>.gd
# 4. measurement probe, then deletion
"C:/Godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe" --headless --path "G:/Mój dysk/Projekty/Vajb Orbit/vajb-orbit" --script res://tools/_probe_w5.gd
Remove-Item "…/vajb-orbit/tools/_probe_w5.gd","…/vajb-orbit/tools/_probe_w5.gd.uid"
```
