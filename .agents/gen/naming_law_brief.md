# Brief: the asset naming law

You are writing **one file**: `docs/design/ASSET_NAMING_SPEC.md`. It is the law a rename engine
executes mechanically. You are writing the law, not the per-file assignments: a separate pass
owns those and cites the evidence for each one.

## Read only these, then write

| File | Size | What it is |
|---|---|---|
| `staging/cut/_naming/brief_digest.md` | 1 KB | the counts, so you do not have to infer the shape of the problem |
| `staging/cut/_naming/canonical.txt` | 25 KB | every name the docs and the shipped catalog already use, one per line |
| `staging/cut/_naming/live_names.txt` | 17 KB | every name on disk now, one per line |
| `staging/cut/_naming/sheets.tsv` | 36 KB | per raw sheet: family, grid, cells, plate flag, its cut names in cell order |

**Do not run any command.** Do not open any other file, and in particular do not open
`_vision.json`, `_library.json`, `INDEX.md` or `ASSET_CATALOG.md`: they are 0.3 to 1.7 MB and
reading them will spend your whole context on data this law does not need. Everything you need
is above. If you believe something is missing, say so in your reply rather than going looking.

## What the law must settle

1. **The grammar.** One line every name obeys. Fix the character set: lowercase `a` to `z`,
   digits and underscore. No dots, no capitals, no stamps, no version markers, no spaces.
2. **The families.** The prefix list and the folder each prefix means. The catalog's own six
   folders are `ships`, `icons`, `env`, `ui`, `fx` and `audio`; `audio` is out of scope. Say
   where the logo, the three `panel_*` atlases and the non-icon phase-F deliverables go.
3. **The closed variant vocabulary.** From the names on disk you will see these in use: ship
   views `_front`, `_three_quarter`, `_side`, `_back`; UI states `_normal`, `_hover`,
   `_pressed`, `_disabled`; asteroid size bands `_L1.._L3`, `_M1.._M3`, `_S1.._S3` and
   `_b1.._b6`; rotation views on the enemy sheets. State the full closed list and forbid
   anything outside it. `_16`, `_48`, `_96`, `_192` and `@2x` are **derived** names, produced by
   appending to a master, and must stay derivable by a plain string append: this is a hard
   constraint, because `vajb-orbit/tools/derive_icon_tints.gd` and
   `staging/phase_f/recut_quartet.py` depend on it. No master may carry a derived suffix.
4. **The icon containers.** `icons` holds 288 files. Decide the subgroups a reader can navigate,
   state which prefix pattern belongs to each, and keep the rule mechanical (a prefix match, not
   a judgement). The families visible on disk include `icon_mineral`, `icon_ingot`, `icon_cargo`,
   `icon_contract`, `icon_map`, `icon_booster`, `icon_equip`, `icon_module`, `icon_ammo`,
   `icon_weapon`, `icon_insignia`, `icon_status`, `icon_service`, `icon_slot`, `icon_zoom`,
   `icon_credits`, and the bare HUD glyphs `icon_gear`, `icon_hull`, `icon_shield`, `icon_ammo`,
   `icon_close`, `icon_logout`.
5. **Five name shapes that must not survive**, each with its rule:
   - `<family>_sheet_<cols>x<rows>_<stamp>[__pNN]` - a placeholder, 188 of them;
   - `<name>__<stamp>` - a second render colliding with a live name, 19 of them; the owner's
     decision is that the stamped twin is **dropped** and the plain name survives. State how the
     drop is reported rather than performed silently.
   - the generator's own filename, e.g. `grimdark-painted-sci-fi-semi-realistic__20260918-111044`,
     32 of them;
   - a phase prefix such as `f1_ice_moon` or `p2_contracts`, 5 of them;
   - a name whose subject contradicts the picture, 9 of them.
6. **Collision rules.** How a qualifier is added so two siblings can never resolve to the same
   name, and what happens when a re-derived name would collide with a name in `canonical.txt`.
7. **The blast radius.** 34 code and scene files hold 201 literal `res://assets/...` paths, and
   every name in `canonical.txt` is cited by some doc. State the dependency direction this repo
   runs on, which is docs first, then code, then tests, and name what must change in lockstep.
8. **What a rename must never do.** Never invent a subject that no doc, no catalog entry and no
   render supports. Never keep a stamp in a name. Never rename a file to a name that already
   exists on disk. Never let a master carry a derived suffix. Never leave a `panel_*` atlas
   unusable as a whole while also cutting its icons.

## Hard constraints

- **`ICONS_SPEC.md` section 7 sanctions exactly twenty flat-icon names and says no others are
  sanctioned.** They are, verbatim:
  `icon_weapon_laser`, `icon_weapon_cannon`, `icon_weapon_rocket`, `icon_weapon_mine`,
  `icon_weapon_plasma`, `icon_cargo_ore`, `icon_cargo_crate`, `icon_cargo_container`,
  `icon_cargo_fuel_cell`, `icon_cargo_salvage`, `icon_cargo_data_core`, `icon_gear`,
  `icon_close`, `icon_zoom_plus`, `icon_zoom_minus`, `icon_credits`, `icon_shield`, `icon_hull`,
  `icon_ammo`, `icon_logout`. A later amendment sanctions more; anything you propose beyond
  these must be justified by a brief, and you must say which.
- **The twenty minerals follow section 8.1's tier order exactly**, in this order:
  `iron`, `copper`, `chromium`, `silicon`, `aluminium`, `titanium`, `nickel`, `cobalt`,
  `tungsten`, `silver`, `gold`, `platinum`, `neodymium`, `iridium`, `osmium`, `palladium`,
  `cerulite`, `emberite`, `voidglass`, `krilium`. The two 5x4 sheets are the ore panel and the
  ingot panel, twenty cells each, and the cell order is this order, not the order a vision model
  reported.
- **`logo_vajb_orbit` is load-bearing.** `MAIN_MENU_V2.md` wires it as
  `AtlasTexture(logo_vajb_orbit, Rect2(44,707,1961,615))`, so the file name and that geometry
  survive unchanged.
- The three `panel_*` atlases ship whole *and* are cut into icons. Keep both.
- No em dashes anywhere: use commas, periods, parentheses or semicolons.
- Under 250 lines. Tables, not prose.

## Deliverable

`docs/design/ASSET_NAMING_SPEC.md`, and nothing else. End your reply with the five decisions that
matter most, and a list of anything you could not settle from the four files you were given.
