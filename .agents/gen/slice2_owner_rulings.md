# Slice 2 — owner rulings log (orchestrator record, 2026-09-21)

Every ruling the owner made while the fight wave ran, with the action taken.
Companion to `.agents/gen/slice0_owner_rulings.md`; the slice-0 rulings still
stand and are restated in `docs/CONTRACTS.md`.

| # | Question raised | Ruling | Action taken |
|---|---|---|---|
| R5 | W6 finding F5: the wave ships `cm_chaff` and `cm_flare` fully wired (the `weapons.gd` seams, the hold spend in `player_ship`/`game.gd`, `InputMap.has_action` guards), but `18_engine_spec.md` §11 binds no key for either, so the player cannot press them | **Z = chaff, X = flare** | Orchestrator bound `countermeasure_chaff` = **Z** and `countermeasure_flare` = **X** through godot-ai. The action names are the ones W5 already reads in `game.gd:113-116`. Verified: 20 actions, both bound, both loaded in the live map. `18_engine_spec.md` §11 is therefore one binding short of the shipped truth and is a spec-edit item. |
| R6 | W6 finding F6: values that trace to no spec row, which the workers refused to invent — the mine's blast alpha, which borrows the rocket's 180, and the railgun's rate of fire, which borrows the cannon's 0.6 s burst cycle | **Accept the borrowed values** | Nothing changed. The next spec pass records 180 and 0.6 s as the mine's and the kinetics' own rows so the provenance stops being a borrowing. |
| R7 | The UI chrome geometry no longer matches its art: the four `ui_button_plate_*` files are whole sheet cells, so the theme stretches a mostly transparent canvas (plate renders 287 × 8.6 px, 90 % empty); the menu wordmark crop holds 0 ink; the bezel nine-patch draws 3 px instead of 16 | **Art lane re-cuts the plates** | Routed to the graphics lane as route 1 of `.agents/gen/ui_chrome_regression.md`: re-cut the plates tight (`staging/phase_f/plates_cut.py`, `box_1x 280×56`) or fix the crop rule in `staging/cut/cut_sheets.py`, then re-pull and re-import — the same re-cut covers the bezel, the four slot families, the panel frame, the bar caps and the wordmark crop. No coder touches the theme or the art. |
| R8 | Batch-2 finding B2-2: the backdrops are 1.0667× the 1920×1080 design canvas and every `@2x` cut was deleted by the redesign (0 files, 19 sidecar deletions recorded), so they upscale above 1080p (1.250× at 1440p, 1.875× at 4K) | **4K matters** | The graphics lane owes a **2× cut for every large element**, backdrops included (≥3840×2160; the menu's covered draw needs ≥4032×2352). Also recorded: the tint stencils lost their F.1/F.2 import settings (1 080 files `mipmaps/generate=false`) and the HUD zoom buttons minimise 3.43 texels/px, so `_48` cuts are the ICONS_SPEC §9.2 fix — both ride the same art pass. |

## Orchestrator-applied project settings, slice 2

Applied through the editor via godot-ai, never by hand, and verified on disk:

| Action | Key | Note |
|---|---|---|
| `countermeasure_chaff` | **Z** | new this wave (ruling R5); the code already read this action name |
| `countermeasure_flare` | **X** | new this wave (ruling R5) |
| `consume_fuel_cell` | R | slice 0; §11 says C and is superseded |
| `interact` / `warp` | F / H | engine wave 1 |

## Still open, owner-gated

- **`18_engine_spec.md` edits owed** (it is owner-locked, so no worker may touch
  it): §11's `consume_fuel_cell` = C → R; §11's missing `countermeasure_chaff` /
  `countermeasure_flare` rows; §2.1 ruling 13 / §4.4 / §12 item 8's superseded
  "stations sell fuel for CR"; the §13 speed table v2 △ tick; and now the mine
  alpha 180 + kinetic cadence 0.6 s rows from ruling R6.
- **W6 findings F7 (W3's six doc holes), F8 (`cm_*` have no `03` §3 row), F10 (a
  credit cache has no distinct visual), F11 (a doc pointer)** — owner/spec pass;
  none of them changes behaviour today.
- **W6's LOW backlog** — `.agents/gen/LOW_BACKLOG.md` L19–L29 (including L19, the
  `hud.tscn` follow-up, which W6 ruled **acceptable**, not a finding).
