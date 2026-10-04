# dispatch_designer.md — the graphics lane's queue of record

Purged and regenerated 2026-09-25 (owner ask: "too much shit to keep track of
it" — the queue carries only live items; closed work lives in
`MASTER_REPORT.md` §6 and git). Execute one item per order; briefs/prompts
live in the slice folders. **Model: `opencode-go/mimo-v2.6-pro` for every
design worker** on `--reasoning-effort low` (owner standing rule 2026-09-25;
measured that day, `medium` stalls on long worker loops while `low` is fast).
The owner pastes only the handoff block at the bottom.

**2026-10-02 (owner, item 17/D16):** this wave runs A1 on `xiaomi/mimo-v2.6-pro`
@ `high` and R1 on `hyper/glm-5.3-flash` @ `high` — owner's routes, recorded in
the wave's prompts file; later items return to the standing rule unless ruled.
**2026-10-03 (owner, standing):** the design roster moves to Charm Hyper —
**very demanding design work runs `hyper/glm-5.3` @ high**; other design work
`hyper/glm-5.3-flash` (or `hyper/qwen3.8-flash`) @ high. MiMo stays available
when named.

**File-collision law:** two waves never hold one file (nor the same `test_*`
prefix, nor one `staging/` driver). One live session per workspace.

## The standing ruling (owner, 2026-09-22) — lane law, applies to every item

- Glyph-type icons are **remade as SVG masters** (flat symbol side); depictive
  icons keep **one raster master only** ("we will scale it"); delete all
  non-master rasters **project-side only** (`asset-library/` keeps every
  cut). SVG: flat shapes, `viewBox="0 0 96 96"`, 8-14 flat shapes, fills
  only, at most two tones (Steel `#565C63` + ember `#C8461B`/`#E8703A` where
  danger/warn). A remade glyph's tint variants die with it.

## Queue

| # | Wave | Item | What | Status |
|---|---|---|---|---|
| 17 | D16 | Station identity & contracts UI design (phase P3) | CONTRACTS panel spec (14 §2 + R-S25-1), insurance/vaults panels (14 §3/§4), the nine places' identity treatment with shipped chrome only, the W3 name tick sheet. Five-piece: `slices/D16-station-ui/`. Design only. | **closed 2026-10-03** (see Done) |
| 18 | D18 | Map deck & station panel consolidation design (the owner's 2026-10-03 overhaul ruling) | The map deck spec + wireframes on UI_SPEC §9's N1–N6 pins (expand, pan, zoom, per-sector filters, pin navigation + hold-LMB hyperdrive jump), the merged ARMORY and SHIPYARD panels on STATION_HUB §16's P4–P7 pins (drag-and-drop, slot filter tabs, hover→describe, equipped items, repair block), the N/P tick detail. Five-piece: `slices/D18-map-panels/`. Design only; S29 (coder 35) implements. | **closed 2026-10-03** (0 HIGH / 3 MED cured by the fixer / 4 LOW T-94–T-97; law: UI_SPEC §10 N7–N23 + STATION_HUB §17 P8–P14) |

## Parked (owner-gated — not queued; say the item and its five-piece lands)


## Done

Item 17 = **D16 station identity & contracts UI design** closed **2026-10-03**:
A1 → R1 → F1 on the owner's routes (`xiaomi/mimo-v2.6-pro` @ high for design,
`hyper/glm-5.3-flash` @ high for review). `STATION_HUB.md` §15 + `UI_SPEC.md`
§7 (A5.4-1…6, incl. the L263 SALVO-drum answer, tick U18) + four wireframe
mockups; presentation values U1–U20. R1: 0 HIGH / 2 MED cured / 2 LOW
(L267–L268). `verify --baseline d16_start` green; gate n/a. The tick sheet
(W3 + U1–U20) is with the owner; next in the phase is coder 30 (S24).

Item 16 = **D15 flight feel & feedback design** closed **2026-09-29**: the 25-row
feel tick sheet (`slices/D15-flight-feedback/D15-A1_report.md` — T-feel-1..7 +
T-feel-1b, S19 T1–T7/M4–M7, §22 T3, L39/L103/L182/L57; unticked rows implement
at their PROPOSED value at S22's open), `FX_SPEC.md` §8 + `AUDIO_SPEC.md` §8.6
append-only amendment blocks, and the A5.2 feedback composition; A1 → R1,
0 HIGH / 2 MED cured / 2 LOW (L250–L251). **Ticked the same day: every row y,
T-feel-5 to its §6 reversal (random 1.6–2.6 s); forks resolved = the seeker fuze
pair + laser_04 drop-then-trim.** Gate 941/0 unmoved.
Items 1-15 closed (D2 icon unification, D6 instruments, D7 cockpit rework,
D11 station scene, the D8/D12 fix waves ditched or absorbed); detail in
`.agents/gen/MASTER_REPORT.md` §6. Item 15 = **D14 armory chrome composition**
closed **2026-09-29** (owner): Amendment 5's follow-ups and the §3.10 **A5.4**
per-surface chrome table landed in `4c0de38`, and the armory's own cure shipped in
the coder lane's S20/A5 (gate 914/0 unmoved, the pane's chrome chosen by each
surface's own cut size). Item 14 = **D13 armory rework — design**
closed 2026-09-25 (gate 877/0 unmoved, 0 HIGH / 0 MED / 2 LOW L221-L222; A0 ran
interactively in the owner's session, R1 in-session; owner ticks: T1 y with
"all resolutions work", **T2 = B full-width dashboard**, T3-T8 y). Before that:
item 13 = **D11 station scene** (2026-09-25, gate 807 → 812/0, 0 HIGH / 2 MED
cured / 7 LOW L184-L190). The D12 ARMORY fix wave and D8 item 9 were
**ditched by the owner 2026-09-25** — the armory takes the D13 rework instead;
the audit recap is preserved in the D13 brief.

## Pipeline law (read before any generation run — AGENTS.md "Asset Generation")

Panel order: render → find objects (`panels.py --detect`) → cut each → key
each → trim. `flare` never returns native alpha — `--post-only`. FX stay RGB
except the four §0.1 names. 2K run = 10 credits = $0.05. Delivery order:
generate → stage → **review sheet → owner approval** → ship → reimport →
`validate_names.py --library`. Generation logs beside every shipped family.

## Handoff (live)

**Item 19 = D19 station shell v2 design — done 2026-10-03** (2 HIGH + 9 MED
cured by F1 under two designer rulings — N28's cell trigger becomes the cluster
chip N37, §5.7's `REFINE N` · `REFINERY ALL` · `CANCEL` restored verbatim; 6 LOW
T-107–T-112 + close-out T-113; `UI_SPEC.md` §12 N31–N41 + `STATION_HUB.md` §19
P22–P30 + three wireframes + the A5.5 census landed; gate 1074/0 ×2, verify
green vs `d19_start`). Items 17 (D16) and 18 (D18) are closed (2026-10-03).
**The design queue is empty again.** Next action is the coder lane's S30
station shell v2 build (coder 36, `dispatch_coder.md`) against §12/§19; then
coder 30 (S24 world identity) resumes its docs-first opening on the ticked W3
names and cites `STATION_HUB.md` §15 + `UI_SPEC.md` §7 as its design law (order
and collisions in `WAVEBOARD.md` §Queued).
**Item 16 = D15 closed and ticked 2026-09-29**: the 25-row feel tick sheet is
ruled (all y except T-feel-5 = the §6 reversal 1.6–2.6 s; `slices/D15-flight-feedback/
D15-A1_report.md` carries the tick record; 0 HIGH / 2 MED
cured / 2 LOW L250–L251). The coder lane's
queue is phase **P3** (`dispatch_coder.md` items 28–33; order and collisions in
`WAVEBOARD.md` §Queued) and runs its items between this lane's — item 28 (S22)
opens docs-first on the ticked sheet, D16 (item 17) feeds items 30/31/32.
