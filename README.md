# Vajb Orbit

A Dark Orbit style space game built in **Godot 4.7.2** (Forward+ renderer, Jolt
physics). Fly a hull, mine asteroids, fight, dock at a station, and build a ship
out of modules you buy, roll and fit.

The project is pre-alpha and built wave by wave: every wave is specced in the
docs first, implemented, then measured by an independent review rather than
declared finished. The live state of that work is
`.agents/gen/_state/WAVEBOARD.md`; the running history is
`.agents/gen/MASTER_REPORT.md`.

## Running it

Needs the Godot 4.7.2 editor or console binary and a Vulkan/D3D12 capable GPU.

```bash
godot --path vajb-orbit             # play
godot --editor --path vajb-orbit    # open in the editor
```

Controls: the nose follows the cursor, `W`/`S` thrust and reverse, `A`/`D`
strafe, `Shift` boosts, `Space` fires the armed battery, `1`–`5` select a
battery, `E` mines, `F` interacts, `H` warps, `C` opens cargo, `Q` cycles
targets, `Z`/`X` drop countermeasures.

## Tests

One gate, the headless runner. Zero failures is the law; the pass count moves
with every wave.

```bash
godot --headless --path vajb-orbit res://tests/headless_runner.tscn --quit-after 1200
# [SUMMARY] passed=524 failed=0
```

`vajb-orbit/tests/probe_*.gd` are instruments, not tests: each one measures a
single behaviour and prints numbers for a report. They are not part of the gate.

## Building a playtest build

`vajb-orbit/export_presets.cfg` defines two desktop presets — `Linux` and
`Windows Desktop`, 64-bit, single file, release templates. Both exclude
`addons/` (the editor's MCP plugin), `tests/` and `tools/`, so a build handed to
a tester carries the game and nothing else.

```bash
godot --headless --path vajb-orbit --export-release "Linux" builds/linux/vajb-orbit.x86_64
godot --headless --path vajb-orbit --export-release "Windows Desktop" builds/windows/vajb-orbit.exe
```

`builds/` is gitignored. A release is not done until the Linux binary boots and
exits clean (`--quit-after 400`; the only expected noise is Godot's benign
leak-at-exit warning).

## Repository layout

| Path | What lives there |
|---|---|
| `vajb-orbit/` | the Godot project: gameplay, UI, autoloads, tests |
| `docs/design/` | style bible, screen specs, asset specs and the asset catalog |
| `docs/gameplay/` | the RPG/economy layer (01–19) and the engine contract (`18_engine_spec.md`) |
| `docs/CONTRACTS.md` | the pinned-interface contract every wave codes against |
| `AGENTS.md` | how work is specced, dispatched, reviewed and closed out |
| `.agents/gen/` | agent state: waveboard, backlog, slice briefs and reports |
| `staging/` | asset pipelines (generation, cutting, keying, review sheets) |
| `asset-library/` | the art library, its manifest and its review sheets |
| `skills/`, `crush.json`, `crushrc` | the tooling setup this workspace runs on |

## Assets

The repository is **text only** — art, audio, fonts and models are all
gitignored. Generated art is kept in `asset-library/` on the development
machine, and only what a feature actually uses is pulled into
`vajb-orbit/assets/`.

- **Art** is AI-generated via kie.ai and is therefore **not** CC0. Provenance
  (prompt, job id, model, date) is recorded next to each asset in a `.job.json`
  and in per-family `generation_log*.md` files.
- **Audio** is **CC0 1.0**, sourced and license-checked through `assetmcp`; the
  manifest and `CREDITS.md` carry provenance, and no attribution is required.

## Licensing

There is no `LICENSE` file yet, so nothing here is granted for reuse outside
this project. Third-party asset provenance is recorded as described above.
