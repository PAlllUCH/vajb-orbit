---
slice: D12
worker: D12-A0
role: reviewer (design lane, readability)
model: deepseek api deepseek flash (tier: deepseek-direct, max reasoning)
status: actionable
gate: not run (report-only pass; VAJB_WORKER_FILES is this one .md)
---

# D12-A0 report — station readability audit, ARMORY first

## Measured state

- `main` @ `396b8f3`; the tree carries only `.agents/**` edits plus untracked `tests/*.gd.uid` sidecars — no `vajb-orbit/` source was edited by this pass.
- editor `vajb-orbit@6069225ff44d8b75` (4.7.2-stable, plugin/server 4.2.2), `armory_panel.tscn` open, `play_state: stopped` at attach; station run via `project_run mode=custom scene=res://ui/screens/station.tscn` (run tokens 6, 8, 9, 11, 12), stop called at the end — my own run only.
- the pane has **no theme of its own** (`ui/station/armory_panel.tscn:1-11`); the theme arrives from `ui/screens/station.tscn:17`, so every number below is a station render, never a lone-pane render.
- profile `profile.cfg` md5 `eb750728e6dbd9cbe944e32c96307c87`, mtime 2026-09-24 20:21:10; `economy_log.txt` has no row after 18:15:08 (balance 2 125, the figure the header shows), so no purchase, sale, repair or fit came from this pass and no action button was pressed. The md5 did move inside the session window and I cannot attribute that write.
- routes, named per finding: **R1** game framebuffer capture (`editor_screenshot source=game`, 1152) · **R2** live node measurement (`game_manage get_ui_elements`, `editor_manage game_eval`) · **R3** source text · **R4** plate pixel sample (Pillow) + WCAG 2.1 relative-luminance math. Measured at 1920x1080, ARMORY active.

## Findings

### HIGH-1 — the pane's ink is 9-13 px, under every spec floor, and no size follows `ui_scale`
- `armory_panel.gd:72-75` (12/11/13/11), `:1509` (`B1` 14), `:1515` (`(1)` 11), `:1529` (cue 9), `:1603`/`:1613` (barrel name, `✕` 11), `:1787`/`:1790` (inventory 13/11), `:1060-1069` (ammo card), `:415` + `armory_style.gd:77` (`SALVO s` 12). · lane: **graphics** (type scale), with a **code** half.
- measured (R2 runs 9+11): `B1` 14 px `#6b7484`; `(1)` 11; cue 9; barrel name 11; `✕` 11; inventory name 13, `OWNED ×1` 11; ammo name 12, meta 11, price/held values 12, captions 11; `SALVO s` 12; pane footer 13. Only this pane carries per-node overrides in `ui/station/` (12 of them).
- yardstick: `UI_SPEC.md:618-628` (body 14, captions/tooltips 13, readouts 18, titles 22) and `UI_SPEC.md:55` ("no per-node `add_theme_font_size_override`" — the accessibility scale must reach every size); `STATION_HUB.md:950` sets 13 px as the pane floor.
- why it hurts: the figures a player compares while buying (pack name, price, held) are the smallest ink on the screen, a third under the spec's body size; as literals they escape `Router.FONT_SIZE_ITEMS` (`autoload/router.gd:22-51`, applied `:317-326`), so `ui_scale` grows every other label and leaves the ARMORY's smallest text unchanged — the text that needs it most.
- fix: lift the pane onto the §6 scale (name 18 / value 14 / caption 13, floor 13) and expose the sizes as named armory-style items registered in `FONT_SIZE_ITEMS`. Keeping §3.10's compact bands instead is a pin change (bucket 2), not a worker's choice.

### HIGH-2 — every `text_dim` caption sits on painted metal at 1.9-2.8:1
- captions tinted from `armory_panel.gd:196` (`ROLE_TEXT_DIM`, applied `:947-975`) over `assets/ui/ui_armory_console.png`, `_rack_plate.png`, `_row_plate.png`. · lane: **graphics**.
- measured (R4, 12 px patches of the shipped plates): `#6b7484` on the console plate `(61,60,61)` = **2.3:1** (`BATTERY RACKS`); on `(52,46,42)` = **2.8:1** (`INVENTORY · DRAG A WEAPON ONTO A RACK`, `AMMUNITION`); on the rack ledge `(62,59,58)` = **2.4:1** (`SALVO s`); on the row plate `(73,74,78)` = **1.9:1** (every ammo caption). `text_primary` on the same seats is 5.7-7.1:1.
- yardstick: `UI_SPEC.md:31` — the contrast floor (`text_dim` is labels-only, rated ~4.0:1 on `void_base`; token at `vajb_theme.tres:550`). 16 px and 13 px text owe AA 4.5:1; none of the four pairs reaches even the 3.0:1 large-text floor.
- why it hurts: the pane's section captions, the `SALVO` unit and every ammo caption vanish into the plate; the screen reads as unlabelled metal with floating figures.
- fix: seat caption bands, the engraved ledge and the row plate on a dark token band (`void_base`/`void_panel`, as the drum cells already are at `armory_panel.gd:509`) or set captions on painted metal to `text_primary`; keep `text_dim` for void-backed text only.

### HIGH-3 — the loudest ink on an ammo card is the least legible: ember on brushed metal
- `armory_panel.gd:1404-1412` (`_style_danger` re-tints the state label) and `:1374` (unaffordable price), both landing on the row plate. · lane: **graphics**.
- measured (R2 run 11 + R4): the tag `OVER CAP` is **18 px** in `accent_danger #c8471f` on the row plate `(73,74,78)` = **1.8:1** (3.0:1 on the console plate); the pack's own name on that card is 12 px `text_primary`, and the figures (`60 / 30`, price) stay `text_primary` — the hierarchy is inverted.
- yardstick: `UI_SPEC.md:31`; `UI_SPEC.md:431-474` sanctions the form (danger label + 1 px frame, digits never recolour) but nothing sanctions the pair. 18 px is under WCAG's large-text boundary (24 px, or 18.66 px bold), so the tag owes 4.5:1.
- why it hurts: the first word the eye lands on is the one it cannot read, while the word it needs (what the pack is) is the smallest text on the card.
- fix: give the state label a dark seat (a `void_base` band, as the drum cells have) or use `accent_danger_bright` on that seat only, drop the tag to 13-14 px and lift the pack name to 16-18 px.

### HIGH-4 — at 1920x1080 the pane's whole AMMUNITION half is below the fold
- `armory_style.gd:42` (canvas 436x478 → 872x956 drawn) inside `ui/screens/station.tscn`'s host. · lane: **graphics (layout)**; any fix touches a pin → **bucket 2/3**.
- measured (R1 + R2 run 6): `ArmoryScroll` viewport 1392x680 (global y 261..941); console 872x956; the `AMMUNITION` caption at y 995.5 and the six cards at y 1025..1161 → **0 of 6 pack cards visible** without scrolling; the inventory's third row (`OwnedWMining`, 924..968) is cut at 941; the host is 1392 wide against an 872-wide plate, so **520 px (37 %) of the host is empty** while the content is starved.
- yardstick: `STATION_HUB.md:108` (§3.1's grid measured at 1920x1080) and `:924-934` (§5.11: the pane is BATTERY RACKS **and** ammunition, a purchase surface with PRICE cells).
- why it hurts: the pane's prices, HELD/MAX figures and terms caption cannot be seen at the project's reference resolution; half the pane costs a scroll.
- fix: the §3.10 Amendment 2 canvas is pinned, so this is a designer/owner question: widen the canvas to the host's 1392 (racks 4+3 left, six packs as one row or a right-hand column), or keep the canvas and seat the ammo well beside the racks. A smaller `art_scale` is a stopgap that shrinks the small ink.

### HIGH-5 — a fitted barrel has no visible name: the rack reads as unlabelled machined blocks
- `armory_panel.gd:1602-1603` (`font_color` alpha 0, 11 px; class note `:205-209`) and `:1605-1613` (`✕`). · lane: **graphics** (visible ink) + **code** (the override).
- measured (R2 run 9): the `Name` button's text is `W1 CANNON MKI` with `font_color` `000000` **alpha 0.0** and an 11 px rect inside a 40x44 chip; the `✕` is 11 px in a 28 px box and the chip is the whole affordance; the name survives only in `text`/`tooltip_text`.
- yardstick: `STATION_HUB.md:924-930` (drag composition — the player must see which weapon sits in which cell) and §5.1's `W1 LASER MKII` line; `UI_SPEC.md:412-413` (§3.9 rule 3: no baked text, which puts the name on the code, not the plate).
- why it hurts: three fitted cells in B1 look identical; knowing what is fitted means hovering each one, and the control that removes a barrel is a bare glyph on bare metal.
- fix: draw a short visible name in the chip (`LASER`, at the §6 caption size), keeping full `text` and tooltip for the suites, and give the `✕` a 1 px frame or a 20 px hit plate.

### MED-1 — the ammo cards are drawn outside their well, and a 7th spacer row grows the group
- `armory_panel.gd:906-931` (`_lay_ammo` counts every child, spacer included) vs `:842-849` (`_group_content_heights` counts packs only) and `:1195` (`_add_slack`). · lane: **code**.
- measured (R2 run 12): `AmmoMargin` local y 766 h 166 → its code-drawn recess is 796..932; `AmmoBox` local y **-32**, h 231; `ArmoryRows` h 208 holding **7** children (6 packs + `Slack`, 64 px); card 0 at global y 1025 = console-local 763, i.e. **33 px above the recess's lip**; the rows' bottom (971) overruns the plate (956).
- yardstick: §3.10 Amendment 2 (the ammo well's height derives from content) and §3.4's recessed-well pattern — a well holds its rows, not the reverse.
- why it hurts: the first card row straddles the well's lip and the group's caption is pushed above its own band; the spacer buys a third, empty row (64 px) the block's arithmetic never sees.
- fix: count only real cards in `_lay_ammo` (or drop the spacer) and re-run `_lay_groups` after the rows' minimum size is set.

### MED-2 — the ammo card mixes rounds and units, and `HELD` carries no unit
- `armory_panel.gd:95` (`%d ROUNDS PER PACK`), `:112` (`%d / %d`), `:1380-1382` (held via `ammo_units`/`_unit_cap`). · lane: **code** (wording).
- measured (R2 run 11): name `Laser Cells` 12 px; meta `300 ROUNDS PER PACK` 11 px; `HELD` `60 / 30` 12 px; caption `CAPACITY IS ADVISORY` 11 px.
- yardstick: `STATION_HUB.md:931` (units = rounds / 10) and §5.1's `HELD / MAX` contract, which was in rounds while the column existed.
- why it hurts: one card shows 300 rounds per pack and 30 units held, with no unit word to resolve it.
- fix: label the figure (`60 UNITS`) or show the rounds equivalent the meta uses — one constant either way.

### MED-3 — the shell strip: one 13 px line cannot carry an item description
- `ui/screens/station.tscn:226-242` (`StatusLabel`, `HintLabel`, `StationCaption` 13 px) and `ui/screens/station.gd:530-538` (the only writer; the pane's refusals arrive via `armory_panel.gd:53` → `station.gd:434`). · lane: **code** (strip) + **graphics** (type).
- measured (R2 run 8 + R1): `Footer` 1872x18 at y 1038; `StatusLabel` 174x18 (min 174, exact); `HintLabel` 405x18, min 405 for its 65-char string → 6.2 px/char at 13 px, no slack; the free centre is 1233 px ≈ 198 chars.
- yardstick: `UI_SPEC.md:624` (13 px) and §1's dim floor; `STATION_HUB.md:950` measures this caption at 3.89-4.05:1.
- why it hurts: a refusal raised at a rack (top-middle) is announced 13 px in the bottom-left corner, in the line that has read `DOCKED · ALL SYSTEMS NOMINAL` all session; and the strip cannot hold a description at all.
- fix: one line carries ~198 chars, i.e. a sentence. A description block needs a **3-line, ~57 px** strip (3 x 17 px + 6 px), and that height must come out of the `Body` (860 px today for a 956 px console) — so on this screen the description belongs in the pane, not the shell. If the shell keeps it, reserve 57 px and give the centre spacer an autowrap 13 px `Label`.

### MED-4 — the `SALVO` figure has no adjacent unit, and the pane's own answer is invisible by design
- `armory_panel.gd:1547-1550` (`state.modulate.a = 0.0`, the label that reads `SALVO 0.6 s`) and `armory_style.gd:74-77` (caption origin x 5, drums at x 32). · lane: **graphics**.
- measured (R2 run 9): drum cells 40x72 at bay-local x 64/106/148; `SALVO s` 12 px at x 5, ~59 px left of the digits; the decoding rule is seconds x 100 (`060` = 0.60 s, `armory_panel.gd:137-143`).
- yardstick: §3.10's approved Mockup A strip (figure plus caption, one readout) and §5.1's own state line, which the pane hides.
- why it hurts: `060` reads as sixty or as 0.60 s, and the unambiguous text is transparent.
- fix: place `SALVO s` immediately left of the drums (they end at 188 of 194) or print the decimal point in the drum decode; keep the hidden state line for the suites.

### LOW-1 — the empty-rack drop cue is clipped
- `armory_panel.gd:1522-1532`. · lane: **graphics**.
- measured (R2 run 11): the cue's rect is 154 px and the string measures **162 px** at 9 px with `clip_text` and no ellipsis → 8 px cut. The cue hides correctly on a rack holding a barrel.
- why it hurts: the only instruction the empty racks carry loses its last characters.
- fix: 13 px and a two-line wrap in the bay, or shorten the copy to `DROP A WEAPON HERE`.

### LOW-2 — recorded check: the pane's key hints are honest
- `armory_panel.gd:132`/`:703-707` against `vajb-orbit/project.godot:78-160`. · lane: **code**.
- measured (R3): `(1)`..`(7)` are drawn on all seven bays and `weapon_1..7` are bound (keycodes 49-55); `PGUP`/`PGDN` in the shell hint are read by keycode at `station.gd:194-199`. No hint names an unbound key; no pane label is stale (`PaneSubtitle` counts are live, the hidden `State` label is intentional).
- why it is here: so triage does not "fix" a working hint — brief item 4's example does not occur here.

### LOW-3 — two caption lines doing the same job in two places
- `armory_panel.gd:97` (the pane's static `HOLD CAPACITY IS ADVISORY · A PURCHASE IS NEVER CLAMPED` footer) and the shell's `StatusLabel`. · lane: **graphics**.
- measured (R2 run 8): the pane's footer is 1392x23 of static text at y 947 while its live refusals render in the shell at y 1038 — 950 px from the racks.
- why it hurts: the pane owns a footer that never changes and delegates the one message that matters.
- fix: render refusals in the pane's own footer, or mark the pane footer as a legend.

## problems: []

- Panes other than the ARMORY were **not measured live**: `shipyard/exchange/auction/repairs/fitting/launch/refinery_panel.gd` carry no per-node size override (R3), so their floor is the theme's 13 px `StationCaption`, but their rows, hover/disabled states and contrasts are unmade here.
- `ui_scale > 1` on the ARMORY was **not measured** (the setting lives in `user://`, which I do not write); the escape from `Router.FONT_SIZE_ITEMS` is a code reading.
- The AMMUNITION cards were never seen as pixels (0 of 6 visible at 1080p), so MED-1/MED-2 rest on node measurement; focus rings and refusal states beyond `OVER CAP` are likewise unmade, and only the eight contrast pairs above were computed.
- `game_eval` answers only while the game's main loop advances (it freezes when the game window loses focus); every R2 figure was taken on a fresh `project_run`.
