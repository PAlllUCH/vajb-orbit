---
slice: D11
phase: n/a (designer lane; the owner's O6 station-scene rework)
lane: design
status: prepared (queued as dispatch_designer.md item 13; READY — mockup gate first)
gate_baseline: "753/0 (S7/S8-prep tree; D11 rides parallel with coder item 14 (S8) — disjoint sets, both briefs carry the cross-lane rules)"
---

# D11 — Space-station scene rework (composed hero + static/moving elements)

## Goal
The dockable station stops being one sprite: a much bigger hero render plus a
composed scene of static and moving elements, drawn from ENVIRONMENT_SPEC's own
vocabulary, wired without disturbing the group/DockZone invariants.

## In scope
- **A0:** mockup (`staging/mockup/station_mockup.py` → `out/station_mockup_v1.*`)
  pinning hero footprint + element layout + motion paths, element render plan,
  one review sheet — **STOP for owner approval**
- **A1:** the renders (panel-order law: render → detect → cut → key → trim),
  QC, ship to `assets/env/poi/`, generation log, import settings
- **C1:** new `game/station_scene.gd` (the composed node tree + motion
  constants) and the `game/sector.gd:_spawn_station` swap; `tests/test_d11_station.gd`
- Naming rows in `ASSET_NAMING_SPEC` at ship (proposed names in
  ENVIRONMENT_SPEC §11; the `--library` pass stays host-deferred)

## Out of scope
- **Every S8 set** (game.gd, profile, hud, status, repairs, weapons,
  player_ship, impact, asteroid*, exchange*, refinery, fitting, armory,
  module_catalog, projectile, `tests/test_s8_*`) — parallel lane, never touch
- `ui/**`, `project.godot`, `docs/` beyond this wave's own ENVIRONMENT_SPEC
  (already landed docs-first) and R1's CONTRACTS §9/§10 (sequenced after the
  parallel lane's)
- The `env_station.png` file's history (kept as provenance — the hero supersedes
  its *drawn role*, not the file), MMO/base station variants (§ naming row 5),
  the hostile-station §6 wording

## Acceptance criteria
- [ ] AC1 — the approved mockup sheet (owner tick) pins hero footprint, element
      layout and motion paths; nothing renders before that approval
- [ ] AC2 — shipped elements: hero ≥ 2.2× today's footprint + ≥ 6 static kinds +
      ≥ 3 moving kinds, all through the panel-order pipeline, QC green
      (containment/alpha), generation log beside the family
- [ ] AC3 — the station draws composed: probe asserts node count ≥ the element
      set, hero scale == the approved pin, `&"station"` group intact, DockZone
      radius still in **world** units (sibling, not a scaled child), placement
      centre unchanged; `blips()`/dock checks behave byte-identically
- [ ] AC4 — motion: a probe samples two frames and shows the strobe/shuttle/slew
      positions changing under the named constants (or standing still on a
      ticked reversal)
- [ ] AC5 — no other spawn changed (one `git diff` scoped to
      `sector.gd:_spawn_station` + the new file)
- [ ] AC6 — gate `753 + test_d11_station, 0 failed`, twice on scratch stores;
      live store untouched; `verify --baseline d11_start` clean; the parallel
      S8 lane's failures (if any mid-wave) attributed, never fixed
- [ ] AC7 — owner ticks: the mockup, the hero scale as approved, the element
      inventory, the three motion constants

## Worker file sets
| Worker | Files (becomes `VAJB_WORKER_FILES`) | Brief |
|---|---|---|
| D11-A0 | `vajb-orbit/assets/env/**,staging/**,asset-library/**` (mockup + plan + review sheet; STOP) | `D11_BRIEF.md` |
| D11-A1 | `vajb-orbit/assets/env/**,staging/**,asset-library/**` (renders → QC → ship) | `D11_BRIEF.md` |
| D11-C1 | `vajb-orbit/game/sector.gd,vajb-orbit/game/station_scene.gd,vajb-orbit/tests/` (**the owner's grant, one file each in `game/`** — ratified by the dispatch handoff) | `D11_BRIEF.md` |
| D11-R1 | `vajb-orbit/tests/,vajb-orbit/tools/,docs/CONTRACTS.md` | `D11_BRIEF.md` |
| D11-F1 | union of A0–C1 sets + `docs/CONTRACTS.md` | `D11_BRIEF.md` |

## References
- `docs/design/ENVIRONMENT_SPEC.md` **§11** (this wave's pin) + §1.1/§6
  (vocabulary, the one-emissive rule) + §8/§9 (plan, negative list)
- `docs/design/ASSET_NAMING_SPEC.md` (rows at ship), `ASSET_WIRING_HANDOFF` §2
  (superseded note), `AGENTS.md` Asset Generation / Phase G lane (panel order,
  `flare --post-only`, 2K = 10 credits = $0.05)
- `docs/CONTRACTS.md` §21 O6 (the owner's verbatim ask), `game/sector.gd:54-71`
  (the current single sprite + the invariants)

## Carries forward
- LOW ids and changelog rows are **read from the files at close-out** (L167's
  lesson — the parallel S8 lane is live; reserve nothing in advance)
