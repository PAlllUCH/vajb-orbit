---
slice: S11
worker: S11-B6
role: coder (continuation — inspector completeness and its title line)
status: ready
tier: deepseek-direct        # owner's ruling; high reasoning
---

# S11-B6 — the inspector's missing bodies and its identity line

## Why this worker exists

Two gaps B1 reported and the planner ruled on (§23.1 amended 2026-09-24):

1. **Bodies go missing where the prose already exists.** `describe` reads only `MODULES` /
   `SHIPS` / the ammo+service rows, so a REFINERY ore row and an EXCHANGE mineral or component
   hold row show a title and **no text**, though `MineralCatalog` and `ComponentCatalog` carry
   a `&"description"` for every one of those rows. The owner asked for the full description of
   whatever is hovered; those are purchase rows and they must show it.
2. **The title is a key hint, not an identity.** B1 reused each pane's `_row_hint` verbatim,
   so the always-visible identity line reads `ENTER BUY · CANNON MKI · 1 200 CREDITS`. The
   verb belongs to the status strip's hover line (which is unchanged); the inspector's title
   is the row's name and its price phrase.

## Read first

1. `docs/CONTRACTS.md` **§23.1** (both amended rows) and §23.6.
2. `slices/S11-legibility-gunnery-feel/S11-B1_report.md` — the shipped seams, its deviations
   1, 2 and 3, and the pane `file:line` list you are building on.
3. `game/station_catalog.gd` — your predecessor's `describe` and its helpers.

## Tasks

1. **Widen `describe`** to `MineralCatalog` and `ComponentCatalog` (keep the base-id and
   `ammo_*` handling B1 shipped; `""` still means "this row carries no prose", never
   invented text). Reversal: the two entries out of the source list.
2. **Give the six item panes a real title**: `name` plus the pane's own price phrase, joined
   by the pane's existing `" · "`, with the leading key-hint verb dropped. **The status
   strip's `status_requested` line keeps its verb and its wording byte-identically.** The
   pins for the two surfaces are in §23.1's table: one is the identity, the other is the
   hint. Do not change any other string, font size or colour.
3. **`tests/test_s11_describe.gd`** (new, yours): a mineral id and a component id resolve to
   their own catalogue's prose; a `mod_*` instance still appends its affix perks; an
   `ammo_*` cargo id still resolves to its pack; a description-less row still answers `""`;
   and each of the six panes' titles carries the row's name with no `ENTER` verb while the
   same pane's status line still carries it.
4. **Report** `S11-B6_report.md`: the gate line (twice, fresh scratch stores), the widened
   list, one before/after title per pane, and the reversal for each change.

## Hard rules

- Write **only** `game/station_catalog.gd`, the six item panes
  (`ui/station/{armory,shipyard,exchange,auction,refinery,fitting}_panel.gd`),
  `tests/test_s11_describe.gd` and your report. The two item-less panes, the shell
  (`ui/screens/station.*`), `game/module_catalog.gd` and `ui/hud/**` are B1's/B2's and are
  **not** yours.
- The ARMORY's existing type sizes and colours are the D12 graphics lane's — untouched.
- Fresh `XDG_DATA_HOME=$(mktemp -d)` per gate run, `--quit-after` on every run, never write
  the live profile, never leave a background command, never `git add`, never edit `docs/`.
- Report every deviation with its reversal; if a pane's own wording makes the pin ambiguous,
  report it rather than inventing a third string.
