# D19-A1 mockup — the popup layer: N27 tooltip + N28 INSPECT sheet (wireframe)

Design law: `docs/design/UI_SPEC.md` §5.1/§5.2 (the idioms) + §11 N27/N28 +
§12.2/§12.3 (this wave's detail). A5.5: the popups are the only hover/explicit
description surfaces — nothing is revealed in-flow (N30). Wireframe, not a
rendered plate: sizes schematic, ruled numbers in the law blocks.

## The tooltip over a hovered grid cell (N27)

```
+===============================================================+
|| [TERMINAL] | (o) HALCYON ANCHORAGE      CREDITS 1 234 567  ||
+===============================================================+
||  SLOT LAYOUT · 8 CELLS · 2 ENGINES  || MODULES · OWNED & BUYABLE [ALL x] ||
||  [w][w][e]                            || [WEAPONS][DRIVES][SHIELDS]...    ||
||  [e][s][u] <- hovered cell            || +------------------------------+ ||
||                                       || | [i] Thruster Mk II OWNED x2  | ||
||                +--------------------+ || +------------------------------+ ||
||                | Thruster Mk II     | || | [i] Hyperdrive  12 000 CR    | ||
||                | +12 % thrust       | || +------------------------------+ ||
||                | PWR 2 · DRAW 3     | ||                                  ||
||                |                    | ||                                  ||
||                | INSPECT            | ||                                  ||
||                +--------------------+ ||                                  ||
||                 ^ cursor + 12/12      ||                                  ||
||  PWR 4 / 12 · CANDIDATE 6 / 12        ||                                  ||
|+--------------------------------------------------------------------------+|
+===============================================================+
```

## The INSPECT sheet over the same pane (N28)

```
+===============================================================+
|| ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ || [3]
|| ▒▒▒▒▒▒▒▒▒▒▒+===============================+▒▒▒▒▒▒▒▒▒▒▒▒▒ || [4]
|| ▒▒▒▒▒▒▒▒▒▒▒ || Thruster Mk II                  || ▒▒▒▒▒▒▒▒▒▒▒▒▒ ||
|| ▒▒▒▒▒▒▒▒▒▒▒ || +12 % thrust · SCAVENGED         || ▒▒▒▒▒▒▒▒▒▒▒▒▒ || [5]
|| ▒▒▒▒▒▒▒▒▒▒▒ || PWR 2 · DRAW 3 · CYCLE 0.73 s    || ▒▒▒▒▒▒▒▒▒▒▒▒▒ || [6]
|| ▒▒▒▒▒▒▒▒▒▒▒ || SLOT FAMILY · ENGINES             || ▒▒▒▒▒▒▒▒▒▒▒▒▒ || [7]
|| ▒▒▒▒▒▒▒▒▒▒▒ ||                    OWNED ×2 || ▒▒▒▒▒▒▒▒▒▒▒▒▒ || [8]
|| ▒▒▒▒▒▒▒▒▒▒▒ || ESC · CLOSE                       || ▒▒▒▒▒▒▒▒▒▒▒▒▒ || [9]
|| ▒▒▒▒▒▒▒▒▒▒▒ +===============================+ ▒▒▒▒▒▒▒▒▒▒▒▒▒ ||
|| ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒ ||
+===============================================================+
   size-to-content inside min 420 / max 720 wide (N28), clamped (N32)
```

## Element law

| # | Surface | Chrome (A5.4 row) | Asset / theme cite | Tick |
|---|---|---|---|---|
| 1 | the hovered cell | A5.4 `Bay cell` (unchanged — hover mutates colour/`modulate` only) | `fitting_panel.gd:565-574` glyph table | N24 |
| 2 | N27 tooltip — `tooltip_panel` + BBCode `RichTextLabel`, 320 px cap, 0.25 s delay, cursor +12/12, `MOUSE_FILTER_IGNORE` | `tooltip_panel` (UI_SPEC §2.1) | §5.1's grammar + N27's `INSPECT` hint line | N27, N33 |
| 3 | the sheet dimmer — `void_base` 60 % (the §5.2 idiom) | `ColorRect` | UI_SPEC §12.3 | N28 |
| 4 | row 1 name (`Label` 18 `text_primary`) | `panel_raised` sheet, `MarginContainer` 16, `VBox` 12 | §5.2's modal tree | N28 |
| 5 | row 2 rolled affixes (13 `text_dim`; a danger clause `accent_danger`) | as row 4 | the shipped `_affix_lines` output (`shipyard_panel.gd:764`) | N35 |
| 6 | row 3 stat block (13 `text_dim`) | as row 4 | the shipped `_stat_block_of` output | N35 |
| 7 | row 4 `SLOT FAMILY · %s` (`StationCaption` 13) | as row 4 | the format is N35's | N35 |
| 8 | row 5 price / `OWNED ×%d` (`StationValue` 18, right-aligned) | as row 4 | N28's fields; formats N35 | N35 |
| 9 | row 6 close hint `ESC · CLOSE` | as row 4 | — | N36 |

Triggers: the row's `INSPECT` inline chip (pointer or `ui_accept`, N37) and
`station_inspect` = `E` / pad X on the focused row or cell (N34). Hover never
opens the sheet; it is N27's alone. Sizing: content inside min 420 / max 720
(N28), clamped per N32 — the tooltip flips to the cursor's opposite quadrant
before clamping and the sheet scrolls its body before exceeding 80 % of the
viewport height. One sheet at a time (§5.2's queue); ESC and the scrim (N38)
close it and focus returns to the trigger (N39).
