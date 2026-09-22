# Vajb Orbit — `.agents/gen/` workflow law

Adopted 2026-09-22 (workflow restructure). The six templates in this folder are
the contract for every slice, brief, report, review, ticket and phase. Workers
copy them into the slice folder; they never edit `_templates/`.

> Migration rule: no big-bang reorg. New work uses this structure from the next
> slice. Old flat files move into their slice folder only when a worker touches
> them, or in one developer pass for an open lane. Executed briefs are archived
> into their slice folder, never deleted, so ticket references never dangle.

## ID law

Every file traces to exactly one of these. IDs are stable forever — never
renumber, only retire.

| Object | ID form | Examples | Notes |
|---|---|---|---|
| Phase | `P##` | `P1`, `P2` | Continues existing numbering (P1 economy → P2 = docs 08/09/10). |
| Slice (code lane) | `S<n>` | `S0`, `S2`, `S2.5` | Exactly the names already used on the WAVEBOARD. |
| Slice (design lane) | `D<n>` | `D1` | Graphics orchestrator's slices; next free number. |
| Worker within slice | `<SliceID>-<letter><##>` | `S0-M2`, `S2-W7`, `S2.5-V0` | One fresh letter per slice (M, W used; next slices pick unused letters). Worker IDs are unique per slice, so parallel workers never collide. |
| Report file | `<WorkerID>_report.md` | `S2.5-V0_report.md` | Lives inside the slice folder — the slice ID is in the worker ID, no repetition needed. |
| Ticket (bug / follow-up / LOW finding) | `T-###` global counter | `T-30` | One counter across all lanes. Grandfathered: LOW_BACKLOG `L1`–`L29` = `T-1`–`T-29`; new items start at `T-30` and cite `L#` when carried over. |
| Review finding | `F##` within its review | `S2-W6/F3` | Cite as `<WorkerID>/F##`. Already the WAVEBOARD's habit (W6's F3, F7, F8). |

## Folder law

```
.agents/gen/
├── _templates/          # the 6 templates. Read-only for workers.
├── _state/              # WAVEBOARD.md, LOW_BACKLOG.md, _wave_state/ baselines
├── _dispatch/           # dispatch .sh/.log evidence
├── slices/
│   ├── S00-physics-fuel/
│   ├── S02-fight/
│   ├── S2.5-feel/       # created by the developer from _templates/SLICE.md BEFORE first dispatch
│   └── D1-ship-rework/
├── phases/
│   ├── P1-economy/      # closed: PHASE.md + pointers into slices/
│   └── P2-rpg-08-10/
├── previews/            # owner-approved screen renders
└── _archive/            # closed slices / executed waves move here whole at phase close
```

- **One folder per slice**, named `<SliceID>-<short-slug>`. The developer creates
  it (copy `_templates/SLICE.md` → `SLICE.md`, fill it) before the first
  dispatch of that slice. No slice starts without a folder.
- **One `PHASE.md` per phase** in `phases/<P##>-<slug>/` — a manifest and index,
  not a work log. Slices stay in `slices/`; the phase references them. A slice
  that spans phases stays in one folder and is listed by both phases.
- **Every file a worker produces goes inside its slice folder** and starts with
  the worker's full ID. Nothing new is written loose in `.agents/gen/` root.
- **Archival, not deletion**: when a slice closes, its briefs, dispatch logs and
  superseded reports move to `slices/<id>/_archive/`; WAVEBOARD cites the folder.
  The owner-sealed tree under `docs/` is unaffected.
- **Historical note (2026-09-21/22):** the pre-law flat files (wave reports,
  briefs, evidence logs) were archived to `.agents/gen/_archive/` and the state
  files moved to `.agents/gen/_state/`; citations of the form
  `.agents/gen/<report>.md` and `.agents/gen/WAVEBOARD.md` in older reports
  resolve one level deeper now.

## Who writes what

| Actor | Writes | Never writes |
|---|---|---|
| **Developer** session | `SLICE.md`, `BRIEF.md` (one per worker wave), `PHASE.md`, WAVEBOARD updates | Implementation code, worker reports |
| **You (owner)** | Edits the BRIEF before pasting, owner rulings, tick/approve review sheets | — |
| **Coder / Designer** session | Decomposes BRIEF → per-task dispatches (picks models per task), then `REPORT.md` per worker, `REVIEW.md` when in reviewer role | SPEC (request a developer amendment instead), other workers' files (enforced by `VAJB_WORKER_FILES`) |
| Reviewer worker | `REVIEW.md` findings + appends LOW rows to LOW_BACKLOG | Fixes (one fixer pass per WAVEBOARD rules) |

**Brief flow (the paste loop):** developer fills `_templates/BRIEF.md` for the
next wave, tells you "BRIEF ready at `slices/S2.5-feel/S2.5-V0_BRIEF.md`" with a
3-line summary. You review/edit the paste block, paste it into the coder
session. The coder decides per-task model dispatch; the BRIEF pins only tier,
file set, and the output contract.

## Slice lifecycle

`draft` → `active` (folder created, SPEC filled, baseline snapshot + commit) →
`review` (review wave ran, gate re-measured) → `done` (every finding tiered:
HIGH fixed, MED fixed, LOW in backlog; WAVEBOARD row closed; briefs archived).
Status lives in the SLICE.md front matter AND the WAVEBOARD table — WAVEBOARD is
the display, SLICE.md is the record.
