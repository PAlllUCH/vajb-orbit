# Vajb Orbit — Ships Spec (v1)

**Status:** Locked for v1. Roster may not be expanded. Every generation prompt copies the fixed style block file `vajb-orbit/assets/style-block.txt` verbatim; wording in this spec follows `docs/design/STYLE_BIBLE.md`.

**Amendment 2026-09-17 (user decision):** the v1 roster above is the launch set and is unchanged, but the roster lock is lifted — Phase D hull classes 7 to 15 are specced in `docs/design/ASSET_EXPANSION_SPEC.md` §3 and generated against the same §1 framing constant and §6 negative list.

**Sources:** palette, lighting, weathering vocabulary, framing and silhouette rules are copied from STYLE_BIBLE sections 2, 3, 4, 5, 6. Silhouette and damage-state conventions also draw on `docs/assets/research/grimdark_ships.md` (intact/damaged pair convention, class-marker readability).

---

## 1. Framing Constant

Every ship render in this spec uses, verbatim:

> top-down orthographic, facing right, ship occupies about 60 percent of frame width, centroid at frame centre, background flat void black 0A0E14, transparent where a sprite is required.

No perspective, no tilt, per STYLE_BIBLE section 5.

**Rim light rule (repeated):** thin cold pale steel rim 2 to 4 px tracing the shadow-side silhouette, key light upper-left.

---

## 2. Roster (locked)

| # | Entry | Role |
|---|-------|------|
| 1 | Vanguard cutter | Player ship |
| 2 | Vanguard cutter, damaged variant | Player battle-damaged variant |
| 3 | Fighter | Enemy hull class |
| 4 | Corvette | Enemy hull class |
| 5 | Freighter | Enemy hull class |
| 6 | Maw dreadnought | Boss |

**Amendment 2026-09-18 (Phase F, `docs/gameplay/16_art_design_brief.md`):** hull 16
`ship_miner` is added — the only missing player hull in the class roster
(`docs/gameplay/08_ship_classes.md` §4). The two arena bosses (§3.8–3.9) are
re-liveries of the gunship and frigate bands per brief §P1; they are enemy-only.

| # | Entry | Role |
|---|-------|------|
| 16 | Delver miner (`ship_miner`) | Player ship, mining specialist |
| 17 | Boneyard Behemoth (`ship_boss_boneyard`) | Arena boss, S3 Meridian |
| 18 | Pyre Hierophant (`ship_boss_pyre`) | Arena boss, S6 Choir |

---

## 3. Ship Entries

### 3.1 Vanguard cutter (player)

- **Silhouette (STYLE_BIBLE §6):** central hull is the largest mass, a broad arrow-head cutter body; one large asymmetric weapon mount pod projects forward-left and a smaller rail mount forward-right, so the base plan stays bilaterally symmetric and the asymmetry lives in the mounts without breaking the primary outline. Two engine blocks sit at the trailing corners, large enough to catch the rim light on their edges.
- **Class markers:** asymmetric weapon mounts are the distinguishing read at a glance (§6.1); twin trailing engines are secondary. The dart/twin-engine read belongs to the Fighter (§3.3), not to the Vanguard.
- **Weathering density (§4 vocabulary only):** moderate — scratches, hull grime, oil stains; light pitted metal on older plates.
- **Engines / glow:** 2 engines, twin trailing nozzles. Burnt ember C8461B flare at each nozzle mouth with a small, hot ember glow E8703A halo — small and hot, no other glow.

### 3.2 Vanguard cutter — damaged variant

- **Silhouette:** identical outline to 3.1; damage must not break the primary silhouette read. One engine block is dead (no glow).
- **Class markers:** same asymmetric mounts; damage states per research convention (intact/damaged pair of the same hull).
- **Weathering density (§4 vocabulary only):** heavy — battle damage (dents, torn plate edges, scorch-blackened craters, weld beads over repairs), scorch marks, oil stains, rust streaks, pitted metal over the standard scratches, hull grime.
- **Engines / glow:** 2 engines, one dead. Single ember C8461B flare with ember glow E8703A halo on the live nozzle, small and hot.

### 3.3 Fighter (enemy)

- **Silhouette:** short dart-like hull, length-to-width ratio visibly tighter than the Vanguard; twin engines close together at the tail; two small stubby wing pods project enough to catch rim light.
- **Class markers:** short, dart-like, twin engine (§6.5) — the tight dart read is exclusive to this hull; the Vanguard reads by its asymmetric mounts first.
- **Weathering density (§4 vocabulary only):** moderate-plus — scratches, hull grime, oil stains, plus light scorch marks and pitted metal on the veteran hostile hull.
- **Engines / glow:** 2 engines, twin tail nozzles, burnt ember C8461B with small hot ember glow E8703A.

### 3.4 Corvette (enemy)

- **Silhouette:** elongated hull, clearly longer and narrower than the fighter; a row of spine ridges along the dorsal spine, each ridge large enough to catch the rim light on its edge; central hull dominates, ridges and pylons project cleanly.
- **Class markers:** elongated with spine ridges (§6.5).
- **Weathering density (§4 vocabulary only):** heavy — rust streaks from rivets and seams, battle damage, scorch marks at weapon ports, over moderate scratches, hull grime, oil stains.
- **Engines / glow:** 2 engines in a single recessed exhaust block at the tail; burnt ember C8461B flares with ember glow E8703A halos, small and hot.

### 3.5 Freighter (enemy)

- **Silhouette:** boxy hull in three visible segmented blocks (bow block, cargo block, engine block) with clear panel breaks; widest hull of the roster; minimal appendage so the box read is primary.
- **Class markers:** boxy and segmented (§6.5).
- **Weathering density (§4 vocabulary only):** heavy — hull grime toward trailing edges, rust streaks, oil stains, scratches, pitted metal; light battle damage on the cargo block.
- **Engines / glow:** 2 engines side by side in the stern block, burnt ember C8461B with ember glow E8703A, small and hot.

### 3.6 Maw dreadnought (boss)

- **Silhouette:** huge central mass with thorned protrusions radiating from the bow and flanks — each thorn projects far enough to catch the rim light; a visible ember core glows through a gap in the forward plating, the single dominant emissive point of the roster.
- **Class markers:** hostile hulls carry thorned protrusions and a visible ember core (§6.5).
- **Weathering density (§4 vocabulary only):** heaviest in the roster — battle damage (dents, torn plate edges, scorch-blackened craters, weld beads), scorch marks radiating from the core and vents, rust streaks, oil stains, hull grime, pitted metal, scratches.
- **Engines / glow:** 4 engines in two paired stern blocks; burnt ember C8461B flares with ember glow E8703A halos, small and hot. The exposed ember core glows ember glow E8703A over a burnt ember C8461B heart — the largest single contained glow in the roster, still local to the core gap, never ambient scene glow (§3).

### 3.7 Delver miner (player)

- **Silhouette (STYLE_BIBLE §6):** the central hull is the largest mass and is a **broad flat slab, wider than it is long** — the flattest, widest player hull in the roster. A **ventral cutter bar** projects below the centreline along the mid-hull, carrying a row of cutting teeth large enough to catch the rim light on their tips; a **dorsal ore bin** rides above the mid-hull as a boxed, lidded mass; **twin side engines** sit on outboard pods flanking the stern, clear of the slab so the pod edges read. The base plan stays bilaterally symmetric; there are no weapon mounts and no thorns.
- **Class markers:** the ventral cutter bar plus the dorsal ore bin (§6.1) — the mining platform read is exclusive to this hull. It must not share a silhouette with the Corvette (elongated + spine ridges), the Freighter (boxy + segmented) or the Gunship (broad + oversized broadside pods): the Delver's mass is a *low, wide slab*, not a box and not a barge with outboard guns.
- **Weathering density (§4 vocabulary only):** heavy industrial — hull grime toward the trailing edges, ore dust staining over the slab and the bin lid, oil stains around the engine pods, rust streaks from the rivet seams, pitted metal on the cutter bar, scratches; light battle damage on the forward plate only.
- **Engines / glow:** 2 engines in the twin outboard side pods, **dim civilian burnt ember C8461B flares** with a faint small ember glow E8703A halo — civilian throttle, small and contained, no other glow.

### 3.8 Boneyard Behemoth (arena boss, S3 Meridian)

- **Silhouette:** the gunship band's broad short hull with two oversized broadside weapon pods flanking a squat core — the boss re-livery of the Gunship class (`ASSET_EXPANSION_SPEC.md` §3 #8), produced by image-to-image from the shipped gunship sprite, changing **only** weathering and the unique core: the forward plate is split open to expose a single **wide horizontal ember core slot** across the bow shoulder, flanked by two short thorned protrusions the line Gunship does not carry.
- **Class markers:** broadside pods (band) + the horizontal bow core slot and two bow thorns (boss read) — hostile hulls carry thorned protrusions and a visible ember core (§6.5).
- **Weathering density (§4 vocabulary only):** heaviest — battle damage (dents, torn plate edges, scorch-blackened craters, weld beads over repairs), scorch marks radiating from the pods and the core slot, rust streaks, oil stains, hull grime, pitted metal, scratches.
- **Engines / glow:** 2 engines, twin recessed nozzles, burnt ember C8461B flares with small hot ember glow E8703A halos. The exposed core slot glows ember glow E8703A over a burnt ember C8461B heart — contained to the slot, never ambient scene glow.

### 3.9 Pyre Hierophant (arena boss, S6 Choir)

- **Silhouette:** the frigate band's mid-length hull with its forward lance mount and single tall dorsal fin — the boss re-livery of the Patrol/Frigate class (`ASSET_EXPANSION_SPEC.md` §3 #12), produced by image-to-image from the shipped patrol sprite, changing **only** weathering and the unique core: the dorsal fin is replaced by a **tall stacked altar of three plate segments** carrying a vertical ember core in a recessed channel down its face, with thorned nodes along both flanks.
- **Class markers:** forward lance (band) + the stacked altar and its vertical core channel (boss read) — hostile hulls carry thorned protrusions and a visible ember core (§6.5).
- **Weathering density (§4 vocabulary only):** heaviest — battle damage, torn plate edges, scorch-blackened craters, weld beads over repairs, scorch marks radiating from the core channel, rust streaks, oil stains, hull grime, pitted metal, scratches.
- **Engines / glow:** 2 engines, burnt ember C8461B flares with small hot ember glow E8703A halos. The altar's vertical channel glows ember glow E8703A over a burnt ember C8461B heart, small and contained, no other glow.

---

## 4. Generation Plan

Every ship is generated from the fixed style block file **`vajb-orbit/assets/style-block.txt`**, passed unchanged to the image generator on every run, then extended with the per-ship subject wording from section 3.

### 4.1 Rotation sheets (per ship class)

- One **2×2 grid sheet per ship class** showing **front, three-quarter, side, back** views.
- **2K resolution, 1:1 aspect ratio**, then **auto-split** into four angle sprites.
- **Per-cell view orientation (restated per angle, all top-down orthographic, no tilt):** front = bow pointing up; back = bow pointing down; side = bow pointing right; three-quarter = bow rotated 45°. The §1 framing constant applies **per grid cell**: each ship occupies about 60 percent of its own cell width, cells separated by clean void black margins for splitting.

### 4.2 Boss

- The Maw dreadnought is a **single centred render at 2K** (no rotation sheet for v1).

### 4.3 Damaged player variant

- Produced by **image-to-image editing from the intact Vanguard reference**, changing **only damage**: battle damage, torn plate edges, scorch-blackened craters, one dead engine. Palette, silhouette, framing and lighting stay identical to the intact reference.

---

## 5. File Naming Convention

snake_case, per angle, e.g. `ship_vanguard_front.png`. Full set:

```
ship_vanguard_front.png
ship_vanguard_three_quarter.png
ship_vanguard_side.png
ship_vanguard_back.png
ship_vanguard_damaged_front.png
ship_vanguard_damaged_three_quarter.png
ship_vanguard_damaged_side.png
ship_vanguard_damaged_back.png
ship_fighter_front.png
ship_fighter_three_quarter.png
ship_fighter_side.png
ship_fighter_back.png
ship_corvette_front.png
ship_corvette_three_quarter.png
ship_corvette_side.png
ship_corvette_back.png
ship_freighter_front.png
ship_freighter_three_quarter.png
ship_freighter_side.png
ship_freighter_back.png
ship_boss_maw.png
```

**Amendment 2026-09-18 (Phase F)** adds:

```
ship_miner_front.png
ship_miner_three_quarter.png
ship_miner_side.png
ship_miner_back.png
ship_boss_boneyard.png
ship_boss_pyre.png
```

The Phase F hunter liveries keep the same `<hull>_<faction-code>_<view>.png` shape as
`ASSET_EXPANSION_SPEC.md` §4 (`ship_fighter_concord_*`, `ship_fighter_meridian_*`,
`ship_fighter_choir_*`); the two arena bosses are single centred renders per §4.2.

---

## 6. Negative List (repeated per panel)

no chrome, no neon, no saturated colours, no second accent, no perspective, no tilt, no text, no watermark, no grid lines, no labels.
