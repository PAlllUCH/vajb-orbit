# D19-A1 mockup — the shell v2 and the TERMINAL drawer (wireframe)

Design law: `docs/design/UI_SPEC.md` §11 (N24–N30) + §12 (this wave's detail) +
`docs/design/STATION_HUB.md` §18 (P15–P21) + §19 (the one skeleton). A5.5 binds
every line; the tone is N29 (Tokens only, overlay-only motion). Wireframe, not a
rendered plate: sizes are schematic, ruled numbers live in the law blocks
(UI_SPEC §12.1/§12.4, STATION_HUB §19.3). Header + drawer open over the ARMORY
pane.

```
+========================================================================+
|| [TERMINAL] | (o) HALCYON ANCHORAGE              CREDITS 1 234 567 || [1][2][3]
||            | forge-grey bastion, the full menu    | CREDITS        ||
+========================================================================+
||+--------------+======================================================+||
||| MODULES      | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ || [4]
||| [>] OVERVIEW | ▒▒▒▒▒ scrim void_base 60 % over the BODY band ▒▒▒▒ || [5]
||| [w] ARMORY <<|▒▒▒ (current pane entry pressed — §10 idiom) ▒▒▒▒▒ ||
||| [o] REFINERY | ▒▒▒ the pane underneath stays put: the layout ▒▒▒▒ ||
||| [c] EXCHANGE | ▒▒▒ never reflows while the drawer slides ▒▒▒▒▒▒▒ ||
||| [c] AUCTION  | ▒▒▒ (A5.5 / N26 / N29 — translate + alpha only) ▒▒ ||
||| [h] SHIPYARD | ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ||
||| [r] LAUNCH   |            (ARMORY's pane content shows              ||
|||              |             dimmed but unmoved)                      ||
|||  (spacer)    |                                                      ||
||| SESSION      |                                                      ||
||| [x] LOG OUT  |                                                      ||
|+--------------+======================================================+|
|| ARROWS MOVE · ENTER CONFIRM · E INSPECT · PGUP/PGDN PANE · ESC BACK     || [6]
+========================================================================+
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | TERMINAL button — §8 `ActionInline` 96×32 at the header's left edge; press toggles the drawer | flat chip (theme `Button`, no asset) | UI_SPEC §12.1; the P1 360×56 plate is N25's reversal | N25 |
| 2 | the §15.5 name plate: faction glyph 48 + `StationName` + character line | A5.4-1 flat Tokens box, faction ramp border | UI_SPEC §12.4's header table; §15.5 (U17/W3) | P15 |
| 3 | credits housing (unchanged) | `PanelRaised` + `CreditsMargin` 16/8 | §3.1's measured row; `station.gd:129-133` width reserve | P15 |
| 4 | the drawer plate — 360 px over the Body band; the `ModuleRail` box verbatim (x 23..384, y 163..1021) | `PanelRaised` (`ui_panel_frame`) | UI_SPEC §12.1's measured table | N26 |
| 5 | the scrim — `void_base` 60 % over the Body band only (header/footer stay live) | §5.2's dimmer idiom | N26 + N40 (the extent) | N40 |
| 6 | the footer band: status strip (P6's status duty lands here) + the shared key hints | `StationCaption` 13 | UI_SPEC §12.4's footer table | P29 |

## Drawer internals (the §3.1 rail grid verbatim)

`MODULES` caption (`station.tscn:178`) → seven `StationButton` plates in P16's
order (OVERVIEW, ARMORY, REFINERY, EXCHANGE, AUCTION, SHIPYARD, LAUNCH) → the
spacer → `SESSION` caption (`station.tscn:193`) → LOG OUT, which opens the leave
confirm first (§2 unchanged). Entry icons are `MODULE_ICONS`
(`station.gd:91-98`) plus the N41 OVERVIEW glyph; plates are 56 tall on a 6 px
separation (428 px of entries inside the 769 px content box).

- Motion (N26): 0.18 s in / 0.12 s out, `TRANS_CUBIC` `EASE_OUT` — the drawer's
  `position.x` and the scrim's `color:a` only (N29).
- Focus (N39): trap inside the drawer from the current pane's entry; `ui_accept`
  switches panes, closes and runs the pane's `focus_primary()`.
- Close paths: TERMINAL toggle (N25) · `ui_cancel` (P19) · entry press · scrim
  press (N38) · a PageUp/PageDown/shoulder cycle press (N38).
