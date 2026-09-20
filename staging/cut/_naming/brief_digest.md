# The naming pass, in numbers

- Files: 710 (510 sprite, 30 plate, 163 sheet, 7 sheet-keyed).
- Names that cannot be kept: 253
  - `content-mismatch`: 9
  - `placeholder`: 188
  - `twin`: 19
  - `slug`: 32
  - `phase-prefix`: 5
- Names on disk, so a new name must not collide: 642.
- Names the docs and the catalog already use: 1138.
- Raw sheets: 163. Sheets whose panels are placeholders: 43.
- Code and scene files holding a literal asset path: 34 (201 paths).

## Files

| File | Rows | What it is |
|---|---|---|
| `_naming/broken.tsv` | 253 | every name that must change, with what the file shows and, for a cut sprite, the sheet and cell it came from and that sheet's own objects in reading order |
| `_naming/live_names.txt` | 642 | every name on disk now |
| `_naming/canonical.txt` | 1138 | every name the docs or the catalog use; reuse these rather than inventing near-duplicates |
| `_naming/sheets.tsv` | 163 | per sheet: family, grid, plate flag, its cut names in cell order, and the objects vision saw on it |
