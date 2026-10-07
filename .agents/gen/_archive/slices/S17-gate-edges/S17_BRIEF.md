# S17 — Jump gates to sector edges (wave brief)

**Wave:** S17 (code lane, item 17 of `dispatch_coder.md`)
**Slice folder:** `.agents/gen/slices/S17-gate-edges/`
**Baseline:** gate **866/0** (S16's close, 2026-09-25); `python3 staging/verify_wave.py snapshot --name s17_start` before the first dispatch.
**Owner go (2026-09-25):** on the 2026-09-24 ask — "same gates, spawn placement only".

## 1. The law to read, in order

1. `slices/S17-gate-edges/SLICE.md` — scope, ACs, your file-set row.
2. `docs/gameplay/11_galactic_map.md` **§6** (this wave's pin) + §2.1/§2.2 (the
   gate/corridor law) + §5 (the S6 wiring pin it supersedes on placement).
3. `vajb-orbit/game/sector.gd` — the seams in §2 below; `sector_registry.gd`
   `edge_band`/`CORRIDOR_DEPTH` (read-only — you must not touch this file).

## 2. Pinned interface (verbatim — the change and its shape)

Today's placement (`sector.gd:95-103`, the constants):

```gdscript
## 11 §2.1's "gate structure near its primary station": the ring is placed on the
## bearing of the destination's own map edge, this far from the arena centre. No doc
## gives the radius, so 900 u is this file's placement value (one edit reverses it).
const GATE_RING_RADIUS := 900.0

## No doc places a nav beacon beyond "1 per corridor + 1 per gate" (11 §3), so a gate's
## beacon stands this far outside the ring (clear of the 200 u trigger) and a corridor's
## sits on its band's centre. One edit reverses it.
const BEACON_GATE_OFFSET := 300.0
```

Today's gate construction (`sector.gd:586-593`) — the one line that moves:

```gdscript
func _add_gate(centre: Vector2, dest: int) -> void:
	var gate: Node2D = GateScript.new() as Node2D
	gate.name = "Gate%d" % dest
	gate.position = centre + _gate_bearing(dest) * GATE_RING_RADIUS
	add_child(gate)
	gate.call(&"setup", dest)
	gate.call(&"set_origin_sector", Registry.sector_number(sector_id()))
	_gates.append(gate)
```

The bearing helper stands unchanged (`sector.gd:655-666`): the direction of
the link's corridor band centre (east fallback) — with today's spine it is
always cardinal east or west. The beacon block stands unchanged
(`sector.gd:612-616`): `gate.position + gate.position.normalized() *
BEACON_GATE_OFFSET`. The arena centre is the sector node's origin
(`sector.gd:151-153`, `var centre := Vector2.ZERO`), arena
`Registry.SECTOR_SIZE` = (10000, 10000), corridor bands
`CORRIDOR_DEPTH` 600 inward from each edge (`sector_registry.gd:61,176-184`),
fields/POIs keep `FIELD_EDGE_MARGIN` 800 (`sector.gd:88,432,642`).

**The fix shape (11 §6):** `_add_gate` becomes

```gdscript
	var bearing := _gate_bearing(dest)
	gate.position = centre + bearing * _edge_reach(bearing)
```

with a new private helper `_edge_reach(bearing: Vector2) -> float` on
`sector.gd`: the distance from the arena centre to the map edge along
`bearing`, inset `FIELD_EDGE_MARGIN` — per-axis
`(half - FIELD_EDGE_MARGIN) / abs(component)`, the minimum of the two axes,
guarding a zero component (a zero-bearing cannot occur — the east fallback —
but the helper must not divide by zero). `GATE_RING_RADIUS` **retires**
(delete the const and its comment; 11 §6's reversal records the restore).
Rules that fix every ambiguity:

1. **No new tunable.** The inset is the existing `FIELD_EDGE_MARGIN` (800);
   today's cardinal bearings put every gate at ±4200 u on its link's axis.
2. **`gate.gd` and `sector_registry.gd` are forbidden files** — byte-identical
   at verify. Ring art, `TRIGGER_RADIUS` 200, fees, the spine: untouched.
3. **Only `_add_gate`'s position line and the retired const change** in
   `sector.gd`; `_gate_bearing`, the beacon block, `_spawn_pois`, `gates()`,
   the minimap mapping (`:282-284`) and `populate` are byte-identical.
4. **The beacon formula is byte-identical** — do not "fix" its
   `gate.position.normalized()` bearing; with edge gates it lands inside the
   link's corridor band, which is the design (a beacon at the mouth).
5. **Tangency is the law, not a defect:** a gate's 200 u trigger circle is
   exactly tangent to its corridor band's inner edge (600 + 200 = 800); AC2
   asserts the interiors stay disjoint — do not add clearance.

## 3. Existing rows (pre-grep before any edit; no unlisted row may move)

Candidate rows that touch gates, their route, and the expected verdict.
"unchanged" = the row reads no placement geometry.

| Row (`file:line`) | Route | Verdict |
|---|---|---|
| `test_engine2_wiring.gd:211-221` blip count | counts gates via `sector.gates()`; position-agnostic | unchanged |
| `test_s6_travel.gd:109-126` registry spine | row data only | unchanged |
| `test_s6_travel.gd:169-220` fee/distance/name | bare `_gate` fixtures, no field placement | unchanged |
| `test_s6_travel.gd:301` `gate.position = Vector2(900,0)` | manually placed fixture | unchanged |
| `test_s6_travel.gd:398` ship at `gate.global_position` | reads a gate's position, asserts no distance | unchanged |
| `test_s6_heat.gd:485` ship at gate | same pattern | unchanged |
| `test_s2_6_gate_hygiene.gd` | the *runner's* hygiene, no jump gates | unchanged |
| `test_s2_6_flight.gd`/`test_s2_6_blur.gd`/`probe_s2_6_flight.gd` "gate" | the W-gate input naming and the runner, not jump gates | unchanged |
| `probe_f4_weapon_fx.gd` "ring" | FX rings, no jump gates | unchanged |

Expected gate growth: **baseline + the new suite's rows only** (a hermetic
`[SUMMARY]` with any other suite's count moved is a red). Any existing row
that must move is a **bucket-2 pause**: report it, leave it, stop.

## 4. Hard rules

- Docs are read-only for you (the 11 §6 amendment is already applied); any
  number you believe is wrong is reported, never edited.
- `--forbidden` at verify: `vajb-orbit/game/gate.gd`,
  `vajb-orbit/game/sector_registry.gd` (plus the standing set).
- Bounded Godot runs (`--quit-after`), self-quit probes, scratch
  `XDG_DATA_HOME` per run; never write the profile or a live `user://`.
- Signals travel UP, calls travel DOWN (Layer Cake); cross-file scripts by
  preload path, never the global class table.

## 5. Output contract

Report `slices/S17-gate-edges/S17-B1_report.md` (REPORT template, ≤120
lines): the pre-grep table (every candidate row, route, verdict), the
per-AC measured values (seeded sectors, re-derived expected positions), the
gate `[SUMMARY]` before/after, every deviation.

## 6. Skills (read by path when you need Godot idiom)

The shared Godot skill library resolves on this host under
`~/.local/share/crush/additional-skills/godot/`. Useful here:
`godot-master/godot-gdscript-mastery/SKILL.md`, `godot-best-practices/SKILL.md`,
`godot-master/godot-testing-patterns/SKILL.md`. Project rules override
anything you read there (Layer Cake; preload paths).

## 7. Run order

**B1 → R1 → F1 only on HIGH/MED.** R1 re-measures every AC itself (W8's
byte-identical replay), diffs against 11 §6 (not this brief), greps the moved
rows against §3's list, updates `CONTRACTS.md` §19's placement paragraph
(`:2278`'s "three placement values reported" now names a retired constant)
plus §9/§10 at the next free rows read at write time, and appends LOW rows at
the next free ids.

## 8. Close-out (the orchestrator)

1. Gate twice on fresh scratch stores (identical counts).
2. `python3 staging/verify_wave.py verify --baseline s17_start --forbidden
   vajb-orbit/project.godot docs/ vajb-orbit/ui/ vajb-orbit/addons/
   vajb-orbit/autoload/ vajb-orbit/game/gate.gd
   vajb-orbit/game/sector_registry.gd --tests --expect-reports
   .agents/gen/slices/S17-gate-edges/S17-B1_report.md
   .agents/gen/slices/S17-gate-edges/S17-R1_review.md`
3. WAVEBOARD + `dispatch_coder.md` one-liners; MASTER_REPORT §6 recap.
4. Wave-boundary commit.
