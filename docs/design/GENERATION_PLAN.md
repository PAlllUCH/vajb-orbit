# Vajb Orbit — Phase B Generation Plan

**Status:** executed + audited 2026-09-17. All six batches complete: **109 final PNGs** (env 16, ui 20, icons 43, ships 21, fx 9), zero API failures. Conformance audit (glm-5.3-flash): inventory, naming, sizes, parked items all PASS; log/manifest gaps on the orchestrator fix-ups closed same-day (job ids + full prompts backfilled, button-plate manifests repointed, icon-derivation provenance recorded, NOT-white wording waived with verified outputs). Actual submissions: 47 paid runs (44 batch runs incl. in-batch retries + 3 orchestrator i2i fix-ups) = **$2.35 real** vs $1.65 base + $0.30 contingency planned; the $0.40 overage came from G5 ship-in-frame retries (3), G1 off-subject renders (3) and one G3 style regen. Pixel-audit clamps and fix-ups logged per family in `generation_log.md`. Known accepted deviations: env 16:9 renders are 2048×1152 (flare 2K long-edge cap) vs the spec's 2560×1440; button plates cut at ~4.5:1 vs the ideal 5:1 (mild squeeze in the 280×56 resize).

**Tool:** `C:/Users/Kamil/AppData/Local/crush/skills/image-generator/scripts/kie_generate.py`.

**Derived art (no API, Phase C):** `tools/derive_icon_tints.gd` produces the 40 runtime-tintable white icon stencils in `assets/icons/tint/` from the Phase B icon cuts — re-runnable after any new icon batch. See `docs/ASSETS.md` § "Derived art".

## Model + price (locked by user 2026-09-17)

- **Primary model: `flare`** (`gpt-image-2-5-flare-text-to-image`); **fallback: `sunburst`** (same schema, same price) — one retry per failed run.
- Editing runs use **`flare-i2i`** (`gpt-image-2-5-flare-image-to-image`, `--ref` local upload).
- **Price basis: 10 tokens = $0.05 per 2K request** (kie.ai console, user-verified). The script's printed estimates show a stale hint ($0.15 / 30 credits) — ignore for budgeting; `--yes` bypasses its refusal gate.
- Historical spend before Phase B: $1.57 (13 generations, earlier testing). kie.ai console is the authoritative balance.

## Batch table (33 runs → ~109 final files)

| Batch | Runs | Assets | Files out | Cost |
|---|---|---|---|---|
| G1 environments (ENVIRONMENT_SPEC §2–3, §7) | 5 | `env_menu_bg` (16:9), `env_loading_bg` (16:9), stars ×3 (1:1) | 5 | $0.25 |
| G6 chrome (UI_CHROME §2–7) | 7 | panel frame, button 2×2, slot 2×2 ×3, caps+bezel panel, logo | 20 | $0.35 |
| G3 icons (ICONS_SPEC §5) | 3 | `panel_weapons` (2×3), `panel_cargo` (2×3), `panel_glyphs` (3×3) | 43 | $0.15 |
| G4 ships (SHIPS_SPEC §4) | 6 | rotation sheets ×4 (2×2 each), boss single, damaged Vanguard i2i | 21 | $0.30 |
| G5 FX (FX_SPEC §1) | 9 | laser, muzzle 4f, **engine trail (`fx_engine_trail.png`, added 2026-09-17)**, explosion 5f, shield, mining 4f (amended 2026-09-17), cargo pulse, vignette, ember pulse | 9 | $0.45 |
| G2 asteroids + props (ENVIRONMENT_SPEC §4–6) | 3 | asteroid 3×3 panel, wreck hulk, station | 11 | $0.15 |
| **Total** | **33** | | **~109** | **$1.65** |

**Contingency:** one retry per failed run on `sunburst` (+up to ~$0.30). `--split-only` re-cuts are free. Optional i2i fix-ups for style drift: $0.05 each.

## Execution rules (delegated to workers)

1. Per run: one `--dry-run` sanity pass, then the identical command with `--yes`. Workers may submit without waiting for per-run approval (user-approved 2026-09-17); batch totals were approved up front.
2. Every prompt = verbatim `vajb-orbit/assets/style-block.txt` (via `--style-file`) + the spec's subject/prompt-notes block + per-spec addenda.
3. Worker renames the script's timestamped download to the exact final filename in the family folder and copies the run's `job.json` alongside as `<final>.job.json`.
4. Generation log per family folder: `generation_log.md` — date, model, job id, final file, full subject prompt, status (AI art is not CC0 — AGENTS.md).
5. `--usage` checked at each batch end; failures logged and reported, never blind-retried after a code-200 acceptance.
6. Orchestrator visually verifies one output per batch; style drift is fixed via i2i after all batches, not by regen loops.

## Output tree

```
vajb-orbit/assets/
├── env/        (G1, G2: env_*)            + generation_log.md
├── icons/      (G3: icon_*, panel_*)      + generation_log.md
├── ships/      (G4: ship_*)               + generation_log.md
├── fx/         (G5: fx_*)                 + generation_log.md
└── ui/         (G6: ui_*, logo_vajb_orbit.png) + generation_log.md
```

## Spec amendments applied 2026-09-17 (user decisions)

- FX_SPEC §3: engine trail row added (`fx_engine_trail.png`).
- FX_SPEC §1.6: mining chip sparks locked to a **4-frame** sheet (frame-synced animation policy).
- Batch order (approved): G1 → G6 → G3 → G4 → G5 → G2, executed in parallel as worker sessions.
