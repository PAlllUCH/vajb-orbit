# Engine Wave 1 — dispatch prompts (paste-ready, one per worker)

Run order: **W0 first**, then **W1–W4 in parallel**, then **W5**, then **W6**,
then fix/re-review prompts as findings demand. Model for every dispatch:
`deepseek/deepseek-v4-flash` (your fixed choice; slug verified in fix wave 1,
2026-09-18 — re-check the live catalog before each dispatch).

```
crush run "<prompt>" -m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"
```

---

## W0 — doc amendments (run first, before W1)

```
Read .agents/gen/engine_wave1_task.md section W0 and apply it: transcribe the doc amendments listed in ENGINE_SPEC.md section 12 into docs/design/IMPLEMENTATION_PLAN.md, docs/gameplay/08_ship_classes.md, docs/gameplay/09_ship_slots_modules.md, docs/gameplay/11_galactic_map.md and docs/design/PROJECT_SETTINGS_PATCH.md. Mechanical transcription only - no new numbers, no design decisions, everything comes from ENGINE_SPEC.md. Follow the global rules in the brief. Write your report to .agents/gen/engine_wave1_w0_report.md.
```

## W1 — ShipFit / ShipStats (parallel with W2–W4)

```
Read AGENTS.md, ENGINE_SPEC.md and .agents/gen/engine_wave1_task.md fully, then implement section W1 exactly. Stay to spec: ENGINE_SPEC.md and the numbered gameplay docs are law; never invent a number; report deviations instead of redesigning. Follow the brief's global rules and the pinned ShipStats and ShipFit interfaces exactly - other parallel workers code against them. Write your report to .agents/gen/engine_wave1_w1_report.md.
```

## W2 — Player ship flight + game.gd rewire (parallel)

```
Read AGENTS.md, ENGINE_SPEC.md and .agents/gen/engine_wave1_task.md fully, then implement section W2 exactly. Stay to spec: ENGINE_SPEC.md and the numbered gameplay docs are law; never invent a number; report deviations instead of redesigning. Follow the brief's global rules and the pinned PlayerShip interface exactly - other parallel workers code against it. Write your report to .agents/gen/engine_wave1_w2_report.md.
```

## W3 — Asteroids, mining, pickups (parallel)

```
Read AGENTS.md, ENGINE_SPEC.md and .agents/gen/engine_wave1_task.md fully, then implement section W3 exactly. Stay to spec: ENGINE_SPEC.md and the numbered gameplay docs are law; never invent a number; report deviations instead of redesigning. Follow the brief's global rules and the pinned Asteroid, MiningLaser and Pickup interfaces exactly - other parallel workers code against them. Write your report to .agents/gen/engine_wave1_w3_report.md.
```

## W4 — Sector, registry, spawns, dock zone (parallel)

```
Read AGENTS.md, ENGINE_SPEC.md and .agents/gen/engine_wave1_task.md fully, then implement section W4 exactly. Stay to spec: ENGINE_SPEC.md and the numbered gameplay docs are law; never invent a number; report deviations instead of redesigning. Follow the brief's global rules and the pinned Sector and SectorRegistry interfaces exactly - other parallel workers code against them. Write your report to .agents/gen/engine_wave1_w4_report.md.
```

## W5 — HUD pass (only after W1–W4 reports exist)

```
Read AGENTS.md, ENGINE_SPEC.md and .agents/gen/engine_wave1_task.md fully, then implement section W5 exactly. First read the W1 to W4 reports in .agents/gen to learn the landed interfaces. Stay to spec: additions only to the frozen HUD API, existing theme items only, no new theme items. Follow the brief's global rules. Write your report to .agents/gen/engine_wave1_w5_report.md.
```

## W6 — review (mandatory, after W5)

```
Read ENGINE_SPEC.md sections 2, 3, 6, 7, 8, 9 and 13, then read every file changed in .agents/gen/engine_wave1_w0_report.md through w5_report.md plus the reports themselves. Measure, never trust reports: re-run key headless probes - sector spawn counts, ship handling times, mining cycles, pickup behaviour - and check every number against ENGINE_SPEC.md section 13 and the gameplay docs. Check the pinned interfaces match across all files: filenames, identifiers, function signatures, data shapes, wiring, and flag any invented constant or scope creep beyond ENGINE_SPEC.md. Classify findings HIGH, MED, LOW. Write your report to .agents/gen/engine_wave1_review_report.md.
```

## W7 — fixes (one per finding batch, after W6)

```
Read .agents/gen/engine_wave1_review_report.md and the brief's global rules, then fix the findings assigned to you: <paste the findings or say "all HIGH and MED findings">. Do not redesign; every fix stays inside ENGINE_SPEC.md and the pinned interfaces. Write your report to .agents/gen/engine_wave1_w7_report.md.
```

## W8 — re-review (after W7; loop until clean, max 3 cycles)

```
Re-run the W6 review gates on the files fixed in .agents/gen/engine_wave1_w7_report.md, same method: measure, never trust reports. Confirm each finding is fixed and no new issues were introduced. Write your report to .agents/gen/engine_wave1_review2_report.md.
```
