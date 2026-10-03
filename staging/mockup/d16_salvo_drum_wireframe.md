# D16-A1 mockup — armory SALVO ledge, four-cell drum (wireframe)

Answers `LOW_BACKLOG` **L263** ("the armory SALVO drum grew a fourth cell, and
the zero-padded figures re-render (`073` → `0073`, `120` → `1200`)") with the
drum's A5 treatment. Design law: `docs/design/UI_SPEC.md` §7 **A5.4-6** (amends
A5.4's `Salvo ledge` row). Shipped assets only: the twelve `ui_seg_*` cells
(ASSET_CATALOG.md:467). No code moves (`armory_style.salvo_cells` is already 4
in the code L263 measured). Tick **U18**.

## The ledge (240×34, bay-y 150 — A3 geometry unchanged)

```
+----------------------------------------------------------------------+
|  +----+ +----+ +----+ +----+                            SALVO s       |
|  |0073| |0000| |    | |1200|                            (caption)     |
|  +----+ +----+ +----+ +----+                                          |
+----------------------------------------------------------------------+
 |__ four ui_seg_* marks, 18x32 each (cut 48x88), HBox separation 2 ___|
     = the 20 pitch; each mark its own TextureRect (A5.2(iii))
                                   |__ 13 px StationCaption, measured
                                       origin 78 px from the block start
                                       (L263: 74 -> 78 with the drum block)
```

## Element law

| Element | Treatment | Cite | Tick / reversal |
|---|---|---|---|
| ledge surface | flat Tokens `ledge_bg` + 1 px `metal_mid` (`_flat()`) | UI_SPEC §7 A5.4-6; `build_theme.gd:450-457` | U18 / the S18 ledge returns |
| drum cells (4) | `ui_seg_*` seven-seg marks at 18×32 (cut 48×88), 20 pitch, blanks when no cadence | ASSET_CATALOG.md:467; A5.4 `Salvo ledge` amended | U18 / `salvo_cells 3` + `SALVO_MAX 999` + pin rows back (L263's reversal) |
| figures | seconds ×100, four zero-padded cells: `0073` = 0.73 s, `1200` = 12.00 s, `SALVO_MAX` 9999 | UI_SPEC §3.10 A3 (×100 rule), L263 | U18 (ticks the `0073` look) / three cells re-pad to `073` |
| caption | `SALVO s` 13 px `StationCaption` beside the block (origin 78 px measured) | A4.5 ticked look stands | U18 / caption returns to origin 74 |
| heavy-cadence icon | 16 px line mark beside the drum for 10.00–15.00 s cooldowns (the fourth cell's reason) — **STAGED pending generation budget**; no shipped icon exists, no art may be generated (owner 2026-09-27), so the figure carries the read alone until then | — | staged / never generate it |

Figures at the cadence split's extremes (from L263's world): 0.60 s → `0060`,
1.20 s → `0120`, 10.00 s → `1000`, 15.00 s → `1500`, no cadence → blank cells.
The heavy-cadence icon is what would flag the ≥ 10.00 s band at a glance; until
a generation budget exists the four digits are the whole read.
