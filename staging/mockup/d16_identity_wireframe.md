# D16-A1 mockup — station identity, one worked plate per faction (wireframe)

Design law: `docs/design/STATION_HUB.md` §15.5 + `docs/design/UI_SPEC.md` §7
A5.4-1. Names and character lines are R-S24-1's rows (14's 2026-09-27 P3 block,
tick **W3**) verbatim. Accent = shipped chrome/Tokens only: the faction glyph
(`icon_insignia_<faction>_48`, ASSET_CATALOG.md:332-334) + the metal-ramp border
(UI_SPEC §1 — no new hue is legal). Wireframes, not rendered plates.

## Where the plate sits (station shell header band)

```
+================================================================================================+
|+------------------------------+                                        +-----------------------+|
|| [glyph] HALCYON ANCHORAGE    |          (header spacer)               | [credits] 12 400 CR ||
||          forge-grey bastion, |                                        +-----------------------+|
||          the full menu       |                                                            |
|+------------------------------+                                                            |
+================================================================================================+
 |__ name plate (A5.4-1, flat Tokens box)      Header HBox children only; no coordinates (A5.2).
```

The plate wraps the header's existing `StationMark` + `TitleBox` nodes
(STATION_HUB §4 node tree): the glyph replaces `icon_map_node_station_48`
(reversal: it returns), `StationName` keeps `HeroTitle` 48, and the character
line takes `StationLocation`'s `StationCaption` 13 slot (reversal: the location
caption returns).

## The three worked examples (one per faction)

```
CONCORD (S1 primary)                         MERIDIAN (S3 capital)                CHOIR (S6 capital)
+----------------------------- (border: metal_mid) ----------------+
| [C]  HALCYON ANCHORAGE        | [M]  SPANPORT MERIDIAN   | [Ch]  EMBERLIGHT                |
|      forge-grey bastion, the  |      the merchant's      |      cathedral dark, meanest    |
|      full menu                |      harbour, best       |      turrets                    |
|                               |      contract rates      |                                 |
+-------------------------------+--------------------------+---------------------------------+
  border `metal_mid`              border `metal_light`       border `metal_dark`
  glyph `icon_insignia_concord`   `icon_insignia_meridian`   `icon_insignia_choir`
  ("forge-grey bastion")          ("the merchant's harbour") ("cathedral dark")
```

Border tone = the per-faction accent (the ramp, UI_SPEC §1). Name in
`text_primary`, character line in `text_dim`, glyph `modulate text_primary`,
each drawn in its own rect (A5.2(iii)). A per-faction hue would need a Tokens
amendment the owner ticks — staged with the per-station emblem family.

## The nine places (R-S24-1's table → treatment)

| Place | Name + character (tick W3) | Faction | Plate border | Glyph |
|---|---|---|---|---|
| S1 primary (Concord capital) | **Halcyon Anchorage** — forge-grey bastion, the full menu | Concord | `metal_mid` | `icon_insignia_concord_48` |
| S2 primary (Concord) | **Ironworks Depot** — mill-town market floor | Concord | `metal_mid` | `icon_insignia_concord_48` |
| S2 outpost | **Marchgate Post** — a dock and a vending wall | Concord (proposed) | `metal_mid` | `icon_insignia_concord_48` |
| S3 primary (Meridian capital) | **Spanport Meridian** — the merchant's harbour, best contract rates | Meridian | `metal_light` | `icon_insignia_meridian_48` |
| S4 primary (Meridian) | **Ashveil Exchange** — free-port chaos, component prices | Meridian | `metal_light` | `icon_insignia_meridian_48` |
| S4 outpost | **Rimward Depot** — caravan stop | Meridian (proposed) | `metal_light` | `icon_insignia_meridian_48` |
| S5 primary (Choir) | **Cinder Gate** — incense and plasma scorch | Choir | `metal_dark` | `icon_insignia_choir_48` |
| S5 shrine (outpost) | **The First Ember** — the Choir's smallest rite | Choir (proposed) | `metal_dark` | `icon_insignia_choir_48` |
| S6 primary (Choir capital) | **Emberlight** — cathedral dark, meanest turrets | Choir | `metal_dark` | `icon_insignia_choir_48` |

The three outpost factions are **PROPOSED** as their sector primary's faction
(the pin states no outpost faction); reversal: the registry names its own.
Full law + reversals: STATION_HUB §15.5/§15.6 (tick **U17**).
