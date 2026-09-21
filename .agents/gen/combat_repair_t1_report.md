# T1 — `--only` scope for `staging/phase_f/apply_import_settings.py`

Worker T1 (coder — tooling), wave **combat/collision repair**, 2026-09-21.
Declared file set: `staging/phase_f/apply_import_settings.py` (plus `.agents/` for this
report). Nothing else was written: no `.import` file, no asset, no theme, no
`project.godot`, no `addons/**`, no `docs/**`.

**Deliverable:** `--only <pattern…>` restricts every write to the matching files; with the
flag absent the tool behaves exactly as before. Proof: the unscoped dry run is byte-for-byte
identical to the pre-change baseline (`1080 of 1620`), and a sandbox run proves the write
path is confined to the matched files.

## 1. What changed

`git diff --stat` — **97 insertions, 3 deletions**, one file:

```
 staging/phase_f/apply_import_settings.py | 100 ++++++++++++++++++++++++++++++-
 1 file changed, 97 insertions(+), 3 deletions(-)
```

Added (all new, none of the existing behaviour touched):

| New function | Job |
|---|---|
| `candidate_names(path)` | the forms a pattern may address a file by |
| `select(files, patterns)` | narrows the target list, and reports patterns that matched nothing |
| `usage_error(message)` | usage line to stderr, `exit 2` |
| `parse_args(argv)` | returns `(apply, patterns)`; rejects an unknown flag or a patternless `--only` |

Unchanged in the diff (context only): `WANT`, `targets()`, `rewrite()` and the summary
line. **The import settings themselves are untouched** — still
`mipmaps/generate=true`, `compress/mode=0`, `detect_3d/compress_to=0`, still only the
`[params]` block.

### Matching rules

| Pattern form | Example that works |
|---|---|
| asset-relative path | `icons/ingot/icon_ingot_iron_96.png.import` |
| asset-relative path, no `.import` | `icons/ingot/icon_ingot_iron_96.png` |
| workspace-relative path (± `.import`) | `vajb-orbit/assets/icons/ingot/icon_ingot_iron_96.png` |
| bare file name (± `.import`) | `icon_ingot_iron_96.png.import` |
| bare name | `icon_ingot_iron_96` |
| glob | `icons/tint/*`, `icons/ingot/icon_ingot_ir*` |
| folder scope (trailing `/`) | `icons/ingot/`, `icons/tint/` |

Matching is case-insensitive (the mirror authors on Windows, runs on Linux). Values may be
space-separated or comma-separated (`a.png,b.png`, the `ship_batch.py` convention), and
`--only=pattern` is accepted too. A pattern that matches **nothing** aborts the run with
`exit 2` **before any write**, so one typo cannot half-apply a scope. `--only` can only
narrow `targets()` — it can never add a file the `_96`/`_192`/`@2x` rule does not cover.

## 2. Raw evidence — MODE 1 (flag absent) vs MODE 2 (`--only`)

Commands run from the workspace root with `python3` (3.14.4). The unscoped output was
diffed against a baseline captured **before** the edit (`/tmp/t1_baseline.txt`).

```
==================== MODE 1: whole tree (flag absent) ====================
$ python3 staging/phase_f/apply_import_settings.py
  total lines: 1082  (1080 file lines + 1 blank + 1 summary)
  head:
    icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
    icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  tail:
    icons/tint/icon_zoom_plus_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0

    DRY RUN: 1080 of 1620 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]
  diff against the pre-change baseline (/tmp/t1_baseline.txt):
    IDENTICAL, byte for byte
```

```
==================== MODE 2: scoped (--only) ====================
### icons/tint/* (the R8 tint-stencil scope; 1080 file lines, head/tail shown)
$ python3 staging/phase_f/apply_import_settings.py --only icons/tint/*
SCOPE: 1080 of 1620 .import files match 1 pattern(s): icons/tint/*
  total lines: 1083
  head:
    SCOPE: 1080 of 1620 .import files match 1 pattern(s): icons/tint/*
    icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
    icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  tail:

    DRY RUN: 1080 of 1080 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)

### one bare name
$ python3 staging/phase_f/apply_import_settings.py --only icon_alt_angled_armor_plates_96
SCOPE: 3 of 1620 .import files match 1 pattern(s): icon_alt_angled_armor_plates_96
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0

DRY RUN: 2 of 3 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### two names, comma-separated
$ python3 staging/phase_f/apply_import_settings.py --only icon_alt_angled_armor_plates_96,icon_alt_angled_armor_plates_192
SCOPE: 6 of 1620 .import files match 2 pattern(s): icon_alt_angled_armor_plates_96, icon_alt_angled_armor_plates_192
icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0

DRY RUN: 4 of 6 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### two names, space-separated
$ python3 staging/phase_f/apply_import_settings.py --only icon_alt_angled_armor_plates_96 icon_alt_angled_armor_plates_192
SCOPE: 6 of 1620 .import files match 2 pattern(s): icon_alt_angled_armor_plates_96, icon_alt_angled_armor_plates_192
icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_192.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0
icons/tint/icon_alt_angled_armor_plates_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; detect_3d/compress_to=1 -> detect_3d/compress_to=0

DRY RUN: 4 of 6 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### asset-relative glob (files already carry the quartet)
$ python3 staging/phase_f/apply_import_settings.py --only icons/ingot/icon_ingot_ir*
SCOPE: 4 of 1620 .import files match 1 pattern(s): icons/ingot/icon_ingot_ir*

DRY RUN: 0 of 4 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### folder scope without a wildcard
$ python3 staging/phase_f/apply_import_settings.py --only icons/ingot/
SCOPE: 40 of 1620 .import files match 1 pattern(s): icons/ingot/

DRY RUN: 0 of 40 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### workspace-relative path
$ python3 staging/phase_f/apply_import_settings.py --only vajb-orbit/assets/icons/ingot/icon_ingot_iron_96.png.import
SCOPE: 1 of 1620 .import files match 1 pattern(s): vajb-orbit/assets/icons/ingot/icon_ingot_iron_96.png.import

DRY RUN: 0 of 1 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### path to the .png itself (no .import suffix)
$ python3 staging/phase_f/apply_import_settings.py --only icons/ingot/icon_ingot_iron_96.png
SCOPE: 1 of 1620 .import files match 1 pattern(s): icons/ingot/icon_ingot_iron_96.png

DRY RUN: 0 of 1 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
[exit=0]

### one good pattern + one typo -> aborts, no writes
$ python3 staging/phase_f/apply_import_settings.py --only icons/tint/ icons/nope/*
SCOPE: 1080 of 1620 .import files match 2 pattern(s): icons/tint/, icons/nope/*
UNMATCHED PATTERN: 'icons/nope/*' matches no file in the target set
no writes: fix the pattern(s) and re-run
[exit=2]

### --only with no pattern
$ python3 staging/phase_f/apply_import_settings.py --only
--- stderr ---
usage: apply_import_settings.py [--apply] [--only PATTERN [PATTERN ...]]
--only needs at least one pattern
[exit=2]

### unknown flag
$ python3 staging/phase_f/apply_import_settings.py --scope icons
--- stderr ---
usage: apply_import_settings.py [--apply] [--only PATTERN [PATTERN ...]]
unknown argument: --scope
[exit=2]
```

## 3. Write restriction proved in a sandbox (`--apply`, real bytes, md5 before/after)

The real tree was never run with `--apply`, so the write path was exercised on a scratch
copy: `/tmp/t1_scope/` holds a copy of the script at
`staging/phase_f/apply_import_settings.py` plus four seeded `.import` files
(`icons/tint/a_96`, `icons/tint/b_96`, `icons/ingot/c_96`, `icons/alt/d_96`), all three
keys wrong. `WORKSPACE` is derived from `__file__`, so the copy points at the sandbox.
`5da0388b` is the untouched seed, `d0a63bf7` the rewritten file.

```
== sandbox: 4 seeded .import files (2 tint, 1 ingot, 1 alt), all three keys wrong ==
  md5 before:
  5da0388b  vajb-orbit/assets/icons/alt/d_96.png.import
  5da0388b  vajb-orbit/assets/icons/ingot/c_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/a_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/b_96.png.import

### --only a_96
  $ python3 staging/phase_f/apply_import_settings.py --only a_96 --apply
  SCOPE: 2 of 6 .import files match 1 pattern(s): a_96
  icons/tint/a_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; compress/mode=2 -> compress/mode=0; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  
  APPLIED: 1 of 2 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
  [exit=0]  md5 after:
  5da0388b  vajb-orbit/assets/icons/alt/d_96.png.import
  5da0388b  vajb-orbit/assets/icons/ingot/c_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/tint/a_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/b_96.png.import

### --only 'icons/ingot/'
  $ python3 staging/phase_f/apply_import_settings.py --only icons/ingot/ --apply
  SCOPE: 1 of 6 .import files match 1 pattern(s): icons/ingot/
  icons/ingot/c_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; compress/mode=2 -> compress/mode=0; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  
  APPLIED: 1 of 1 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
  [exit=0]  md5 after:
  5da0388b  vajb-orbit/assets/icons/alt/d_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/ingot/c_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/a_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/b_96.png.import

### --only 'icons/tint/*'
  $ python3 staging/phase_f/apply_import_settings.py --only icons/tint/* --apply
  SCOPE: 4 of 6 .import files match 1 pattern(s): icons/tint/*
  icons/tint/a_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; compress/mode=2 -> compress/mode=0; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  icons/tint/b_96.png.import: mipmaps/generate=false -> mipmaps/generate=true; compress/mode=2 -> compress/mode=0; detect_3d/compress_to=1 -> detect_3d/compress_to=0
  
  APPLIED: 2 of 4 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
  [exit=0]  md5 after:
  5da0388b  vajb-orbit/assets/icons/alt/d_96.png.import
  5da0388b  vajb-orbit/assets/icons/ingot/c_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/tint/a_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/tint/b_96.png.import

### --only 'icons/ingot/nope_96' (typo, must write nothing)
  $ python3 staging/phase_f/apply_import_settings.py --only icons/ingot/nope_96 --apply
  SCOPE: 0 of 6 .import files match 1 pattern(s): icons/ingot/nope_96
  UNMATCHED PATTERN: 'icons/ingot/nope_96' matches no file in the target set
  no writes: fix the pattern(s) and re-run
  [exit=2]  md5 after:
  5da0388b  vajb-orbit/assets/icons/alt/d_96.png.import
  5da0388b  vajb-orbit/assets/icons/ingot/c_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/a_96.png.import
  5da0388b  vajb-orbit/assets/icons/tint/b_96.png.import

### whole-tree --apply, and the duplicate in targets()
  $ python3 staging/phase_f/apply_import_settings.py              # dry run
  DRY RUN: 6 of 6 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
  $ python3 staging/phase_f/apply_import_settings.py --apply
  APPLIED: 4 of 6 .import files need the quartet settings (mipmaps on, lossless, 3D detection off)
  md5 after (all four rewritten):
  d0a63bf7  vajb-orbit/assets/icons/alt/d_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/ingot/c_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/tint/a_96.png.import
  d0a63bf7  vajb-orbit/assets/icons/tint/b_96.png.import
```

Readings: each scoped `--apply` changed **only** the matched files (every other md5 stayed
at the seed value), the typo scope changed nothing at all, and the whole-tree `--apply`
changed all four.

## 4. The real tree was not touched

```
.import files modified in the last 2 hours: 0
newest .import mtime: 2026-09-21+07:54:19  vajb-orbit/assets/ships/ship_drone_swarm_front.png.import
git status --porcelain
 M staging/phase_f/apply_import_settings.py
```

Only the one declared script is modified. `python3 -m py_compile` passes; the file keeps the
repo's **CRLF** line endings (as `ship_batch.py` and `qc_f2.py` do), so the diff is the 100
lines of the change rather than a whole-file rewrite. No gate run: the change is one Python
staging script and touches no `.gd`, `.tscn` or `.import` byte, so the headless suite
(passed=226) is unaffected — the count cannot move.

## 5. Findings (reported, not fixed — outside this worker's deliverable)

1. **`targets()` lists every `icons/tint` file twice.** Measured on the real tree:

   ```
   len(targets()) = 1620
   unique          = 1080
   duplicated      = 540        (all of them icons/tint)
   ```

   The `icons` `rglob` already covers `icons/tint`, and the second loop
   (`(ASSETS/"icons"/"tint").glob(...)`, lines 67-70) adds the same 540 again: non-tint 540
   + tint 540 × 2 = 1620. Consequences, both measured in the sandbox's `### whole-tree`
   block above: a **dry run** counts each duplicated entry twice (`6 of 6`, i.e. the real
   tree's `1080 of 1620` is 540 files counted twice), while **`--apply`** is honest (`4 of 6`
   — the second pass re-reads the file it just rewrote and reports no change). This is a
   pre-existing defect, not introduced here, so the headline numbers stay as the docs record
   them; the one-line cure is to drop the trailing tint loop. A scoped **dry run over tint**
   inherits the same doubling — compare `SCOPE … of 1620` (entries) with the dry-run count
   before trusting the second number.
2. **`targets()` has no `@2x` member today** — `find vajb-orbit/assets -name '*@2x*'`
   returns 0, so the `ui` branch of the rule contributes nothing to the 1620 and `--only`
   cannot currently reach an `@2x` cut. When the F.2 chrome `@2x` cuts are shipped into the
   project, they become reachable by name (`--only 'ui/*@2x*'`).

## 6. For the graphics lane (the blocked pass)

```bash
# R8 tint-stencil scope, dry run first (540 unique files, listed twice — see finding 1)
python3 staging/phase_f/apply_import_settings.py --only 'icons/tint/*'
# then the write, still scoped to exactly those files
python3 staging/phase_f/apply_import_settings.py --only 'icons/tint/*' --apply
```

Or per shipped asset, without a path: `--only ui_slot_weapon_normal,ui_slot_cargo_normal`
(space- or comma-separated), or a folder: `--only ui/`. The editor reimport and
`qc_f2.py` follow as before. A pattern that matches nothing stops the run with `exit 2`
instead of writing a partial scope, so a typo is safe to re-run.

## 7. Reversal path

The change is purely additive: `git checkout staging/phase_f/apply_import_settings.py`
(or `git revert` of the wave commit) restores the pre-T1 file, and the default code path is
already byte-identical to it (proved in §2) — so dropping the flag changes nothing for any
caller that does not use `--only`.
