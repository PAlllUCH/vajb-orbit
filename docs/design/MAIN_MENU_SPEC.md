# Vajb Orbit — Main Menu & Boot/Loading Spec

**Status:** final Phase-A spec. Depends on `STYLE_BIBLE.md` (palette, motifs) and `UI_SPEC.md` (theme tokens, scene conventions). Visual asset inputs come from `ENVIRONMENT_SPEC.md` (menu background) and `UI_CHROME_ASSETS_SPEC.md` (logo, button plates, nine-patch frame).

**Scope decision (A1):** Boot → Main Menu (PLAY / OPTIONS / EXIT) → Loading → placeholder game scene. The MMO screens in `MENU_FLOW.md` (Login, Company Select, Hangar, Starmap) are untouched future scope; this menu is inserted as the new post-boot screen.

**Token note:** Godot-side styling below uses UI_SPEC §1 theme tokens (`void_base`, `metal_mid`, `text_primary`, `accent_danger_bright`, …). Generated art uses STYLE_BIBLE hexes. Mapping for Phase C: `metal_mid` ≈ gunmetal family, `accent_danger` ≈ burnt ember `#C8461B`, `accent_danger_bright` ≈ ember glow `#E8703A`.

---

## 1. Boot sequence (total ≤ 3 s)

Scene: `vajb-orbit/ui/screens/boot.tscn`. Root `Control` full-rect, `vajb_theme.tres`, bg `void_base` (full-rect `ColorRect`).

| t (s) | What happens |
|---|---|
| 0.0–0.5 | Solid `void_base`. Nothing else. |
| 0.5–1.4 | Logo fades in (alpha 0→1, 0.9 s, ease out). The logo is the generated lockup art (UI_CHROME spec). |
| 1.4–1.7 | One "ember flicker": logo modulate briefly (0.15 s) toward `accent_danger_bright` then back — single pulse, never looping. |
| 1.4–2.4 | Thin 2 px progress line under the logo, width 240, centred. Fill `metal_light`; 3 scripted ticks (25 % / 60 % / 100 %) with 0.3 s gaps — preflight is cosmetic in v1 (no server). |
| 2.4–3.0 | 0.6 s crossfade to Main Menu (`Tween` on a full-rect black `ColorRect` alpha 0→1→0 across the scene swap). |

- Any key press during boot is ignored (sequence is short by design).
- Skip guard: if the engine reports load already finished, jump to t=1.4 immediately.

## 2. Loading screen (the only bridge into gameplay)

Scene: `vajb-orbit/ui/screens/loading.tscn`. Same skeleton as boot.

- Background: generated splash backdrop (UI_CHROME spec) at 40 % opacity over `void_base`.
- Centred: destination label — "ENTERING SECTOR — <name>" in Blaec 22 px `text_primary`; placeholder v1: "ENTERING SPACE".
- Lower third: progress bar 260×14 (`progress_bg`/`progress_fill` styleboxes from UI_SPEC §2.1). In v1 fill tweens 0→100 % over the 1.2 s minimum display time — real asset streaming replaces this later. Background: `env_loading_bg.png` (ENVIRONMENT_SPEC §3 — the wreck vista at 40 % opacity; UI_CHROME's `ui_loading_backdrop.png` plate is parked as fallback).
- Minimum display time 1.2 s (anti-strobe). Fade-out 0.4 s into the game scene.
- No cancel button in v1 (cancel exists only for return-to-hangar direction, which is future scope).

## 3. Main Menu layout

Scene: `vajb-orbit/ui/screens/main_menu.tscn`.

```
MainMenu (Control, full rect, theme = vajb_theme.tres)
├─ BackgroundLayer (TextureRect, full rect, EXPAND_FIT_HEIGHT / keep aspect covered)
│  └─ generated menu background (ENVIRONMENT_SPEC §2), modulate #ffffff at 100 %
├─ GrainLayer (TextureRect, full rect, film-grain tile at 8 % alpha, additive off)
├─ Title (TextureRect or Label stack)  — logo lockup, anchored top-left 8 %, 12 % from top
├─ MenuButtons (VBoxContainer, anchors left-centre-lower: x 8 %, y 58 %, separation 14)
│  ├─ PlayButton    (Button "PLAY")     — 280×56
│  ├─ OptionsButton (Button "OPTIONS")  — 280×56
│  └─ ExitButton    (Button "EXIT")     — 280×56
└─ VersionLabel (Label, bottom-right margin 12, 13 px, text_dim)
```

- Button text: Blaec 34 px, `text_primary` (menu-screen title-size exception — UI_SPEC §6 gains a "Menu button title, 34 px" row). Button bodies use the generated 4-state button-plate atlas (UI_CHROME §3) wired as `StyleBoxTexture`s (normal / hover / pressed / disabled) — not flat StyleBoxFlats, so the painted bevel and rivets read.
- Background must never compete with text: art spec caps it dark (see ENVIRONMENT_SPEC §2); GrainLayer sits above background, below everything interactive.

## 4. Button interaction states (the hover-glow policy)

Per the amended STYLE_BIBLE §7.3 / UI_SPEC §2.2: **ember glow is a menu-screen privilege; the in-game HUD keeps the strict rule.**

| State | Visual |
|---|---|
| Idle | 1 px `metal_mid` border; a 4 s looping `Tween` modulates the border colour between `metal_mid` and `metal_light` (slow "breathing", ease in-out sine, desynchronised per button by ±0.6 s offsets so the stack doesn't pulse in unison) |
| Hover | Border → `text_primary` (Ash), plate brightens one step, **plus ember bloom:** a 6 px soft outer glow in `#E8703A` at 60 % alpha around the plate, plus a faint ember under-light on the plate's lower bevel (baked into the hover plate art; the 6 px halo is a `StyleBoxFlat` duplicate with `expand_margin_* = 6` and `bg_color = #E8703A` at 60 %, drawn *behind* the plate stylebox via a `GlowUnderlay` child `Panel`, or a shader if Phase C prefers — one implementation, applied to all three buttons) |
| Pressed | Inset bevel per UI_SPEC `button_pressed` (borders flipped), glow removed, scale 0.98 for 80 ms (Tween) |
| Focus | 1 px `accent_danger_bright` border ring (UI_SPEC shared focus stylebox) — identical geometry to hover border but no glow, so keyboard and mouse states are distinguishable |
| Disabled | n/a in v1 (no disabled menu buttons) |

- Sound hooks (AUDIO_SPEC): hover → S10 menu scroll (UI bus, fixed volume), press → S9 click. Emitted from the menu controller, never from individual buttons.

## 5. Idle background animation

Two looping `Tween`s owned by the menu controller (never per-node `_process`):

1. **Dust drift:** background TextureRect UV offset moves 96 px over 20 s, wrapping (shader or `region_rect` scroll on a wider-than-screen texture). Slow but perceptible; must not read as a slide.
2. **Wreck ember pulse:** the background art contains one small burning wreck (ENVIRONMENT_SPEC §2). A `PointLight2D`-free approach: a small radial-glow `Sprite2D` (`fx_ember_pulse.png` — see FX_SPEC §3) positioned over the wreck, alpha 0.25↔0.45 sine loop, 8 s period.

## 6. Actions, routing, focus

- PLAY → `router.route("loading", {destination: "game"})` → placeholder `game.tscn` (empty starfield + player ship + camera, enough to prove the loop).
- OPTIONS → `router.push_overlay("settings")` (UI_SPEC §4 scene, overlay semantics with focus restore).
- EXIT → `router.push_overlay("quit_confirm")` — shared dialog (MENU_FLOW §3.13 semantics: default focus Cancel, Quit requires activation).
- Focus order: PLAY → OPTIONS → EXIT (visual order; containers guarantee it). Default focus on entry: PLAY. Enter activates; Esc opens quit confirmation (menu-screen convention; no gameplay context to cancel to).
- Gamepad: A/Enter activate, B opens quit confirm, shoulder cycle = Tab groups (only one group here).

## 7. Transitions

| From → To | Style |
|---|---|
| Boot → Menu | 0.6 s black crossfade (boot spec §1) |
| Menu → Loading | 0.4 s fade to `void_base`, then loading scene handles its own fade-in |
| Menu ⇄ Settings overlay | Overlay push/pop, focus restored to the opener |
| Menu → Quit dialog | Overlay push; on confirm, graceful quit |

## 8. Acceptance checklist (for the Phase-C reviewer)

- [ ] Boot ≤ 3 s end-to-end; no interactive elements during boot.
- [ ] Exactly one accent colour visible; ember appears only as: logo flicker, button hover bloom/focus ring, background wreck pulse.
- [ ] Hover glow appears on menu buttons only — no `#E8703A` halo is reachable anywhere else in this scene graph.
- [ ] Keyboard-only run: PLAY reachable without mouse, focus ring visible on all three buttons, Esc → quit dialog, Cancel returns focus to EXIT.
- [ ] Background animation runs without `_process` in any UI node (controller-owned Tweens only).
