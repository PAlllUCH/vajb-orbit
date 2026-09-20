# D6 — Defringe the insignia sprite edges (local pipeline, no API)

You are a **coder** worker doing a small, measurable asset-repair task. No image generation, no API calls: this is a local pixel fix with an existing tool style, plus its documentation.

## Environment

- Workspace: `G:/Mój dysk/Projekty/Vajb Orbit` (your cwd). Godot project: `vajb-orbit/`.
- Use `py -3.14` (python.org 3.14 with Pillow 12, numpy and scipy installed). **Never** use bare `python` (Inkscape's interpreter, no CA roots).
- An editor is open on this project (PID 9048). Never run `--headless --editor`, never touch `project.godot` or `addons/`. You do not need Godot at all for this task.

## The defect (measured, reproduce it yourself first)

`vajb-orbit/assets/ui/ui_insignia_{neutral,mic,ven,mmo}.png` are 776-783 x 889-894 RGBA sprites keyed from a light background. Their anti-aliased boundary retained near-white RGB: pixels with `0 < alpha < 250` carry RGB around 253-255 while the sprite interior is dark (mean luminance of opaque pixels 38-51). On a dark backdrop that reads as a white halo around the emblem.

The existing `staging/phase_d/cleanup_fringe.py` does **not** catch these: its criterion is an *opaque* near-white pixel adjacent to outer transparency (alpha < 16), and these files have a wide soft anti-aliased band, so it reports `DRY RUN: 0 files` for the `ui` family. Confirm that for yourself by running it before you write anything.

## What to build

Create `staging/phase_d/defringe_edges.py`:

- For every target PNG: for each pixel with `0 < alpha < 250`, replace its RGB with the RGB of the **nearest fully-opaque pixel** (alpha >= 250), using a distance transform so the replacement colour follows the local interior. Pixels with `alpha == 0` and with `alpha == 255` must be left **byte-identical**.
- Command line: `py -3.14 staging/phase_d/defringe_edges.py [--apply] [paths ...]`, defaulting to a dry run that prints a per-file table (edge pixels found, mean edge luminance before and after, the pixels that would change) and writes nothing.
- Back up each original to `staging/phase_d/_fringe_backup/<filename>` **once**, before its first modification, so a second run never overwrites the pristine copy.
- Idempotent: running `--apply` twice must produce an identical result the second time, and the report must show it.
- Style it like the sibling scripts in that folder: module docstring explaining the defect and the fix, constants at the top, `if __name__ == "__main__":` entry point, no prints beyond a compact table.

## What to run

1. Dry run on the four insignia, report the table.
2. `--apply` on exactly those four files. **Do not touch any other asset family; do not modify any other file under `vajb-orbit/assets/`.**
3. Re-run `--apply` to prove idempotence.
4. Verify with `py -3.14` and Pillow, and report the numbers:
   - per file, before and after: the mean luminance of the anti-aliased band (0 < alpha < 250), the maximum luminance in that band, and the fraction of band pixels above 175,
   - the count of pixels whose RGB changed, and the count with `alpha == 0` or `alpha == 255` whose RGB changed (must be 0),
   - that image dimensions and the alpha channel as a whole are unchanged, by comparing the alpha arrays before and after,
   - the sha256 of each file before and after.
5. Keep the pre-change originals available and say where they are.

## Documentation

Append to the existing derived-art section of `docs/ASSETS.md`: the pass, the tool path, the four files it covers, the reason (light-background keying left a white halo in the anti-aliased edge band), and the backup location. Match the style of the existing derived-tint entry. Do not rewrite the rest of the document.

## Deliverables

| Action | Path |
|---|---|
| create | `staging/phase_d/defringe_edges.py` |
| modify (pixels) | `vajb-orbit/assets/ui/ui_insignia_neutral.png`, `ui_insignia_mic.png`, `ui_insignia_ven.png`, `ui_insignia_mmo.png` |
| create (backups) | `staging/phase_d/_fringe_backup/ui_insignia_*.png` |
| edit | `docs/ASSETS.md` (derived-art entry only) |
| create | `.agents/gen/d6_report.md` |

Touch nothing else. Note in your report that the editor will need to reimport these four PNGs before the change is visible in the engine; the orchestrator will do that.

## `.agents/gen/d6_report.md`

The dry-run table, the apply output, the idempotence check, every measurement listed above, the backup paths, the hashes, and anything you could not verify. Measurements, not assertions.

## Rules

- Shell-safe commands: no parentheses, backticks, `&&`, `>`, `<`.
- No em dashes.
- Do not regenerate or re-key anything with an image API. Do not change the alpha channel. Do not touch the RGB of fully opaque or fully transparent pixels.
