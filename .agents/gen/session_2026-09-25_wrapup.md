# Session report — 2026-09-25 (waves S13, S14, S15, D8)

Readable record of what this session shipped. Numbers live in
`MASTER_REPORT.md` §6; this file is the human summary.

## What shipped (gate 812 → 859/0, hermetic throughout)

**1. Ore caps + dev tuning + mining batteries (S13).** Your ticked rules are
live: a gun-shattered rock realises at most 10 % of its own yield (measured
under the cap), a cleave hands fragments a quarter-share reserve instead of
re-rolling (family realises its own budget, was 4×), 1–3 mining lasers now
stack 1/2/3× (the 2nd and 3rd used to do nothing), the dock ring is 175 u, and
**F1 in flight opens the dev overlay**: 13 sliders over every ore constant with
Save/Reset and a TUNED badge.

**2. Four asteroid sizes, debris splits (S14).** XL > L > M > S; each shatter
rolls a random mix of strictly smaller rocks (XL → few L + few M + few S, down
to Smalls). 200-shatter probe verified, ore budget conserved through every
mixed cascade. Spawn mix measured 37.6/34.5/20.7/7.2 vs the proposed
40/32/20/8 — **your tick** if you want the weights moved.

**3. Battery hardcap 5×4 + armory B1–B5 (S15).** At most 5 batteries of 4 guns;
a 6th battery or 5th cell refuses silently; old 7-group saves clamp on load;
the 7-cell hull composes 4+3 with nothing rackless. The armory draws 5 bays
labeled B1–B5 mapped 1:1 to the cockpit's five lamps, and the rack plate's
slots finally sit on the art's ink (the playthrough plate defect is gone).
`weapon_6`/`7` are inert; deleting those key bindings stays your optional
`project.godot` pass.

**4. HUD visibility (D8).** Per your call, hull/shield top-left is **hidden**
again (the cockpit already shows it). The minimap gained a legend naming its
blip kinds and its two zoom glyphs are legible; every HUD text/glyph now
measures ≥ 12 px at 1080p.

## Your decisions this session

Ticks: `GUN_BURST_SHARE` 0.10, `FRAGMENT_CORE_SHARE` 0.25, mining yields
untouched (Rule B deferred), `class_name` drop ratified, ring 175. Rules:
design workers run **mimo-2.6-pro only**; workers must be waited on; hull/shield
stay in the cockpit only. Open for you: the `18_engine_spec.md` §6/§13
rewording (exact text in `slices/S13-ore-caps-devmenu/_archive/S13-R1_review.md`),
and the S14 spawn-mix tick.

## Incidents worth remembering

- `crush run` workers can wedge silently (0 sockets, frozen I/O) or crawl on
  big prompts at `medium`/`low` effort; the remedy (health-check → python
  SIGKILL → re-dispatch) is now written into the coder/designer skills. This
  shell has no `kill` builtin.
- One "killed" worker survived and finished its work anyway (H1's top-left
  block), which is why the hide pass re-retired it rather than never existing.
- Three mimo-2.6-pro worker dispatches at `medium` produced nothing in 30–36
  min each; split tiny prompts + `low` effort made the lane usable again.

## Queued next (in `dispatch_coder.md` / `dispatch_designer.md`)

Item 17 (jump gates to sector edges), slice 4's remainder (quadrants/armour,
bosses), the D12 armory readability fix wave, designer items 9–12/1/2a/2b/3/4,
and S8's old owner gates (O1–O3, L168/L169).
