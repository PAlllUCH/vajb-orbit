# Changelog

Notable waves, newest first. Dates are close-out dates; the authoritative
per-wave record (what was measured, what stayed open, what the owner still has
to tick) is `.agents/gen/_state/WAVEBOARD.md` §Closed.

## Unreleased — S5 playtest fixes (pinned 2026-09-23)

The owner's ten playtest findings are pinned in the docs and queued as wave S5;
no code has landed yet. Expected: the auction split into family tabs, hulls sold
on the auction only and the shipyard turned into a hangar, ammunition as a cargo
item with auto-load at launch, fuel cells delisted, OUTFITTING turned into
`ARMORY` with drag-and-drop mixed weapon batteries gated by the slowest member,
per-hull hardpoint maps measured off the renders, and per-barrel weapon tracking
speeds.

## 2026-09-23 — Playtest build 1

Two desktop presets and the first build handed to testers: 64-bit single-file
release exports for Linux and Windows, both excluding the editor plugin, the
test harness and the audit scripts. The Linux binary is smoke-tested on Vulkan
before shipping.

## 2026-09-23 — Weapon batteries (S4; gate 493 → 524)

Grouped weapon systems: one trigger releases every barrel of a battery as a
staggered salvo (0–40 ms apart), each with its own damage, recoil and cadence,
all drawing on the family's one ammunition pack. OUTFITTING shows one row per
battery with bulk actions and an expander back to the per-cell actions. Fixed
before close-out: a held trigger stopped after a single salvo, and a refused
bulk action still stored a fit on a hull that had none.

## 2026-09-23 — Item economy: module instances and the AUCTION (S3; gate 457 → 493)

Modules became instances with rolled affixes, and rolled identity now shows
wherever a fit is read. The AUCTION joined the station as the hull and module
shelf, with draw weights, a hot slot, restock and sell paths behind one
transaction seam.

## 2026-09-22 — Truth and feel (S2.6)

Landed the owner's seven feel rulings and made the measurement honest: flight
constants are derived from the fit (accelerate, coast, strafe, steering), the
beam and blur contracts were rewritten, and the gate gained a hygiene suite
after a probe wrote the owner's live account — the store now refuses a write
unless it is the sandbox.

## 2026-09-22 — Fitting, rock cleave and weapon fit (P2-B, P2-B1)

The station's OUTFITTING panel installs, swaps and removes modules cell by cell
through one composed transaction, refusing illegal fits without writing
anything. Asteroid death reads as a break rather than a silent split, and
individual weapons can be fitted to a hull's W cells.

## 2026-09-22 — Icons to one master

Every icon symbol collapsed to a single master and the glyphs were remade as
SVG; the owner's three icon batches were compiled into the shipped masters.

## 2026-09-21 — Ship slots, the feel pass and combat polish

Each ship class got its own slot count and layout (P2-A). Slice 2.5 added the
speed fantasy — motion blur, camera pull-back, dust and thruster feedback — with
every effect re-cut onto its own frames and the five that mix keyed to alpha.
Weapon fire and impacts gained sprites and sounds, asteroid collisions push and
damage both sides, oversized UI art stopped breaking panel layout, and flying
changed to cursor steering with `A`/`D` strafe and a slower turn.

## 2026-09-21 — Engine slices 0 and 2

Slice 0 put the hull on a real `RigidBody2D` with forces, torque, contact damage
and the fuel/reactor chain. Slice 2 added combat end to end: six weapon
families, the lock seam, countermeasures, NPCs and death. Engine wave 1 (fly and
mine) closed on top of them.

## 2026-09-20 — Baseline

The engine wave-1 state, the docs cleanup that folded every root document into
`docs/`, and the brief that opened slice 2.
