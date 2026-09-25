---
slice: D11
worker: D11-A1
model: mimo-v2.6-flash
status: complete
gate: "1 scratch-store run: [SUMMARY] passed=790 failed=5 — all five are the parallel coder
lanes' mid-wave rows (exchange_panel.gd parse error + s11 inspector, s7 affixes x2,
engine2 weapons laser, ship_grids module_catalog); zero env/poi rows, attributed not fixed"
---

# D11-A1 report — station element renders → cut → key → trim → QC → ship

## Result
All **15/15 approved files** (A0's plan of record) ran the panel-order pipeline and ship
green to `vajb-orbit/assets/env/poi/`; generation log beside the family at
`vajb-orbit/assets/env/generation_log_d11.md` (prompt, job id, model, date, route).
Key route: **auto (local `--strip-only`) on every file** — recraft fallback never needed
(0 paid keying calls). Review sheet: `staging/phase_g/_review/d11_ship.png` / `.jpg`;
driver: `staging/phase_g/wave_d11.py` (render / build / qc / ship / review subcommands).

**Pipeline per row (law order):** flare 2K 1:1 render (style block verbatim preamble,
§8) → `panels.py --detect --grid 1x1` → `panels.py --cut` → auto-key on the cut →
`qc_fx_alpha`-style containment on cut-vs-keyed → trim (4 % pad; hero to a 2048 canvas)
→ final QC (transparent > 10 %, §9 accent scan, §6 emissive line, ink retention).

## Per-file QC table (measured; full rows in `staging/phase_g/env/d11/qc_results.json`)
| file | size | transp | box Δ (tol 8) | sealed gaps* | hot share | accent | ink ret | verdict |
|---|---|---|---|---|---|---|---|---|
| `env_station_arm_a.png` | 971x2121 | 70.5% | ±6 | 18.26% | 0.00013 | 0.00002 | 0.992 | GREEN |
| `env_station_arm_b.png` | 2026x1440 | 71.7% | ±6 | 16.11% | 0.00004 | 0.00000 | 0.994 | GREEN |
| `env_station_gantry_a.png` | 1901x2115 | 75.3% | ±6 | 9.85% | 0.00000 | 0.00008 | 0.982 | GREEN |
| `env_station_gantry_b.png` | 2069x1679 | 75.7% | ±4 | 12.41% | 0.00000 | 0.00003 | 0.988 | GREEN |
| `env_station_hero.png` | 2048x2048 | 63.3% | ±6 | 35.84% | 0.00197 | 0.00006 | 0.956 | GREEN |
| `env_station_lamp_a.png` | 2072x657 | 57.2% | ±6 | 7.49% | 0.01060 | 0.00065 | 0.973 | GREEN |
| `env_station_lamp_b.png` | 1459x2106 | 66.6% | ±6 | 6.48% | 0.00190 | 0.00050 | 0.967 | GREEN |
| `env_station_mast_a.png` | 1129x2136 | 64.2% | ±5 | 8.16% | 0.00000 | 0.00002 | 0.984 | GREEN |
| `env_station_mast_b.png` | 1314x1935 | 65.3% | ±6 | 8.26% | 0.00000 | 0.00021 | 0.979 | GREEN |
| `env_station_plate_a.png` | 1239x2163 | 60.1% | ±6 | 5.23% | 0.00000 | 0.00002 | 0.980 | GREEN |
| `env_station_plate_b.png` | 1059x2141 | 51.9% | ±4 | 11.46% | 0.00001 | 0.00000 | 0.977 | GREEN |
| `env_station_shuttle_a.png` | 1856x2105 | 67.5% | ±3 | 5.08% | 0.00000 | 0.00000 | 0.973 | GREEN |
| `env_station_shuttle_b.png` | 1954x2013 | 63.8% | ±5 | 7.77% | 0.00001 | 0.00011 | 0.976 | GREEN |
| `env_station_windows_a.png` | 1989x2089 | 55.1% | ±6 | 5.24% | 0.00000 | 0.00000 | 0.975 | GREEN (pass2) |
| `env_station_windows_b.png` | 2090x1493 | 63.9% | ±4 | 13.89% | 0.00000 | 0.00000 | 0.966 | GREEN (pass2) |

\* `qc_fx_alpha`'s sealed-gap column, report-only: truss/frame openings that legitimately
show space (its own docstring rule); no matte crop anywhere (box Δ ≤ 6 px vs 8 tolerance),
no inverted matte, transparent > 10 % on every file (floor 51.9 %).
**One-emissive (hard line):** hero + lamp rows carry ember points (0.0019–0.0106 hot
share, hot = r>170 & r−b>80); every other row ≤ 0.00013 vs the 0.0005 fail line.
**§9 negative list:** accent scan (sat > 0.6, hue outside 340–40°, visible art only)
≤ 0.00065 everywhere; no text/watermark/grid/planet in the visual pass
(`_review/d11_ship.jpg`, one full-batch view).

## Hero scale floor (the approved pin, measured)
`env_station_hero.png` ships on a **2048² canvas**: at the pin's effective scale
0.1459 → frame **298.80 u ≥ 298.8**, half **149.40 ≥ 2.2 × 67.9 = 149.38** → footprint
**×2.20** of today's 135.8 u. Content bbox 1939×1903 px (94.7 %/92.9 % of canvas) →
visible hull **282.9 × 277.6 u = 2.38×/2.33×** today's 119.1 u (mockup floor 2.20×).
Ember-lamp retention through trim 0.875; hero design language matches the shipped
`env_station.png` (ring + cross spokes + ember points; visual check against it).

## Credits spent
**17 paid runs** = 17 × 10 = **170 credits ≈ $0.85** (console law, 2K run = 10 cr;
the ledger reads +510 because it over-reports 3× — AGENTS.md; 61→78 generations).
Plan was 15 runs = 150 cr = $0.75; **+20 cr** = the two sanctioned re-prompts below.
Recraft keying: 0 calls. Dry-run priced before the batch.

## Deviations (recorded, none shipped violating)
1. **`env_station_windows_a/b` re-prompted once each** (job `5190dc5d…` / `66f5ff9e…`,
   pass 2): pass-1 renders painted an orange furnace glow in the vents (hot 0.00133 /
   0.00099 > 0.0005) — §6's one-emissive breach on a "painted light only" row. Pass 2
   reinforced "no glow, painted matte steel"; both measured hot 0.0 and ship. First
   attempts kept as `*_render.png` for provenance.
2. **Mechanism (worker bucket):** `wave_g.keep_main`'s 10 % component floor deleted real
   art from these multi-part sprites (measured: lamp_a 7019 → 157 ember px, shuttle_a
   lost both wings, windows_a lost hull modules — all on pass-1 finals). Replaced with
   `keep_parts()` (800 px floor) in `wave_d11.py`; largest dropped component now ≤ 796 px
   everywhere, ink retention 0.956–0.994. Renders were never the problem; no re-render
   was spent on it.
3. **QC thresholds (measured, not invented):** HOT_NONE_MAX 0.0005 sits in the gap
   between clean rows (≤ 0.00013) and furnace rows (≥ 0.00099); the accent scan ignores
   keyed void-blue remnants (they measured mean RGB (7, 10, 14) — near-black, not a
   colour accent).
4. **Wiring notes for C1 (plan pins no orientation):** lamp_a is a horizontal run,
   lamp_b a vertical column on a hull section (all glow ember, §6 satisfied);
   arm_a/mast_a/plate_a ship vertical — rotate in code per the mockup geometry.

## Import settings + reimport (quiet window, game stopped)
`staging/phase_g/import_settings_d11.py --apply` rewrote all 15 sidecars to
`mipmaps/generate=true`, `compress/mode=0` (lossless), `detect_3d/compress_to=0`; editor
`filesystem_manage scan` created the sidecars, then `reimport` **15/15 reimported**
(`env_station_hero.png` resolves as `CompressedTexture2D`). Verify pass: 0 files need
rewriting. Reimport ran only while `editor_state` showed the game stopped.

## Files touched
- ship: `vajb-orbit/assets/env/poi/env_station_{hero,arm_a,arm_b,mast_a,mast_b,gantry_a,
  gantry_b,windows_a,windows_b,plate_a,plate_b,lamp_a,lamp_b,shuttle_a,shuttle_b}.png`
  (+ editor-written `.import` sidecars) and `vajb-orbit/assets/env/generation_log_d11.md`
- staging: `wave_d11.py`, `import_settings_d11.py` (new), `env/d11/*` (15 renders,
  detect JSONs, cuts, keyed, finals, `qc_results.json`), `_review/d11_ship.png/.jpg`,
  `_d11_render.log`, `_d11_build.log`
- this report. **No `game/` writes, no `docs/` writes, no `project.godot`.**

## Evidence
`python3 staging/phase_g/wave_d11.py qc` reproduces the table (15 green, 0 fail);
gate line above; `staging/phase_g/env/d11/qc_results.json`; per-run records
`staging/phase_g/env/d11/<name>_render*.json`.
