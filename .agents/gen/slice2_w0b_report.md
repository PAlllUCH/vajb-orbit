# Slice 2 — W0b report: D4 transcription into 13 §4 (2026-09-21)

Worker: W0b (one-edit doc follow-up to W0's discrepancy **D4**, recorded in
`.agents/gen/slice2_w0_report.md` lines 94–108). Read first, in order:
`AGENTS.md`, `.agents/gen/slice2_task.md` (W0 + Global rules),
`.agents/gen/slice2_w0_report.md` (the D4 entry), `docs/gameplay/13_heat_bounty.md`
§4 (lines 57–65), `docs/gameplay/18_engine_spec.md` §13 (the "NPC counts per
sector" block, lines 537–539) and `docs/gameplay/11_galactic_map.md` §3 (line 103).

No headless run was performed (doc-only pass; no code, probe or asset path was
read). `18_engine_spec.md` was read and **not** modified — it is the
owner-locked spec and the source of every number below.

## Files changed

| File | Bytes before | Bytes after | Change |
|---|---:|---:|---|
| `docs/gameplay/13_heat_bounty.md` | 4 461 | 4 694 | +233 |

Nothing else in the tree was touched. `git diff --stat` for the file reports
`1 file changed, 4 insertions(+)` — the insertion is the only difference, and the
file's LF line endings are unchanged (0 CR bytes before and after; 93 LF before,
97 after). `docs/gameplay/18_engine_spec.md`, `11_galactic_map.md` and every
other doc are byte-identical. `13`'s byte count in the W0 report (4 461 B) is
confirmed as the pre-edit size.

## Added text (exact)

Inserted as the second bullet of `docs/gameplay/13_heat_bounty.md` §4, directly
after the existing density bullet (now lines 61–64):

```
- Per-sector NPC counts (the density shape's numbers live in
  18_engine_spec §13): S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 ·
  S6 4–6 · S7 6–8, patrols only in owned space, one convoy per inhabited
  sector.
```

Diff hunk (`git diff -- docs/gameplay/13_heat_bounty.md`):

```
 - Pirates exist per-sector per 11 §3's spawn rules; their density
   multiplies by tier band (S1 rare, S7 swarming).
+- Per-sector NPC counts (the density shape's numbers live in
+  18_engine_spec §13): S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 ·
+  S6 4–6 · S7 6–8, patrols only in owned space, one convoy per inhabited
+  sector.
 - Killing pirates in faction X's space: +1 standing, −3 heat with X. This
```

## Provenance of every number (nothing invented)

| Transcribed | Source |
|---|---|
| S1 0–1 · S2 1–2 · S3 2–3 · S4 3–4 · S5 3–5 · S6 4–6 · S7 6–8 | `18_engine_spec.md` §13 lines 537–538, verbatim |
| "patrols only in owned space" | `18_engine_spec.md` §13 line 538, verbatim |
| "one convoy per inhabited sector" | `18_engine_spec.md` §13 lines 538–539, verbatim |

No new value, band, unit or rounding was introduced. The bullet adds no number
that §13 does not already carry, and it does not restate the §13 band beyond the
seven bands plus the two qualifiers the brief named.

## Style / placement

- En dashes, `·` separators and the seven-band run match §13's own text; the
  surrounding doc already uses en dashes (`11 §3`, `S1 rare`) and italic/bold
  sparingly, and the bullet adds neither.
- Wrapping is the doc's two-space continuation indent, break points inside
  72 columns.
- Citation form follows house style for the spec elsewhere in `docs/gameplay/`
  (`06_loot_drops.md` line 56 "18_engine_spec §4.6", `09_ship_slots_modules.md`
  line 89 "18_engine_spec §4.1/§4.4"), i.e. `18_engine_spec §13`, no backticks.
- Placed in §4 ("Pirates (the grindable crime)") because §4 is where
  `11_galactic_map.md` §3 line 103 ("Pirates | per 13 §4") points and where
  `slice2_task.md` pinned interface 7 sends `NpcRegistry` ("the 13 §4 density
  shape"). The pointer chain 11 §3 → 13 §4 → 18 §13 now terminates in numbers
  instead of a loop.

## Effect on D4

D4's gap is closed: `11_galactic_map.md` §3's "per 13 §4" now resolves to the
counts, and `13_heat_bounty.md` §4 states where the numbers live. No edit was
made to `11_galactic_map.md` (out of this pass's file set, and its pointer is now
correct as written). W3's `NpcRegistry` can read 13 §4 and will still find the
authoritative values in 18 §13.

## Deviations

- **One wording choice, content-neutral.** The brief's draft wording in D4 was
  "the per-sector NPC count band"; the shipped bullet says "Per-sector NPC
  counts (the density shape's numbers live in 18_engine_spec §13)". This
  preserves the spec's own noun ("NPC counts per sector") and states the
  citation as a sentence rather than a bare parenthetical so the bullet reads as
  the doc's other cross-references do. No number, qualifier or meaning changed.
- **Placement.** The brief said "add one bullet"; the position inside §4 was not
  specified. It sits after the density bullet and before the standing/heat
  bullet, which keeps the two density statements adjacent.
- None otherwise: one bullet added, nothing else in the file changed, no other
  file written, `18_engine_spec.md` untouched.
