---
slice: S3
worker: S3-K5
model: ""             # the orchestrator fills what actually ran
status: informational # every HIGH/MED dispositioned; the LOW rows ride with the next wave
gate: "491/0 → 493/0 (exit 0 in four full runs this pass; live profile.cfg md5 unchanged)"
---

# S3-K5 report — the fixer pass: OUTFITTING's strip REMOVE hands back the instance

## Result

The one HIGH of `S3-K4_review.md` is fixed at its named site and nothing else moved.
`ui/station/outfitting_panel.gd:664` `remove_module` now empties the cell through the
composed `PlayerProfile.clear_fit_slot(hull, WEAPON_SLOT, index)` instead of the raw
`set_fit_slot(hull, WEAPON_SLOT, index, &"")` + `add_module(base_id, 1)` pair, so the
FITTED WEAPONS strip's REMOVE banks the entry the cell holds **as itself**: an instance
fitted through FITTING comes back at `count` 1 with its own id, rarity and affix rows, and
a base-keyed unit already in the bag is no longer incremented (CONTRACTS §15's
"REMOVE/SWAP hand the same instance back … never destroyed, never duplicated").

Two regression tests were added at the defect's own surface and are **red on the pre-fix
panel, green after it** (measured): `tests/test_p2b1_outfitting_panel.gd:662` and `:703`.

Measured, this machine, the four full gate runs of this pass (the two final ones on the
tree this report describes):

```
$GODOT_CONSOLE --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn --quit-after 1200
[SUMMARY] passed=493 failed=0          (exit 0, run 3 and run 4, the final tree)
[SUMMARY] passed=493 failed=0          (exit 0, run 1 and run 2, the same code tree)

$ XDG_DATA_HOME=/tmp/vajb_k5_xdg <the same command>       # an independent scratch store
[SUMMARY] passed=493 failed=0          (exit 0)
```

The wave's growth is `491 → 493` (two tests), all 43 suites green, zero `[FAIL]` lines,
exit 0 in all four runs; the one `SCRIPT ERROR` in every log is the pre-existing L61 line
at `tests/test_weapon_fx_f4.gd:178` (the review's own reading).

## Finding-by-finding disposition

| Finding | Tier | Disposition | Evidence |
|---|---|---|---|
| HIGH-1 `outfitting_panel.gd:661-680` `remove_module` banks a base-keyed Common and strands the fitted instance | HIGH | **FIXED** — the cure the review named, verbatim: the composed `clear_fit_slot`; the two raw calls are gone | `tests/test_p2b1_outfitting_panel.gd:662`/`:703` red on the pre-fix panel (`passed=9 failed=2`), green after (`passed=11 failed=0`); sandboxed probe below |
| (no MED) | — | nothing to fix | review §1: "**No MED**" |
| LOW-1 … LOW-16 (`L107`–`L122`) | LOW | **untouched**, as instructed: no LOW is in this pass's scope; they stay in `.agents/gen/_state/LOW_BACKLOG.md` for the next wave | `git diff` carries no LOW_BACKLOG change |

No new finding was raised on either side of the fix: the identical raw-cell shape was
grepped for across the wave's own file set and exists in no other shipped surface —
`grep -rn 'set_fit_slot\|add_module(' vajb-orbit --include='*.gd' | grep -v '/tests/'`
returns raw-cell calls only in `player_profile.gd` itself (its own two definitions and its
internal callers `buy_module`, `retire_legacy_upgrades`, `_bank_entry`) plus two comments in
`outfitting_panel.gd:697`; outside `player_profile.gd`
they appear only in test fixtures (`test_p2b1_outfitting_panel.gd:755`,
`test_p2b_fitting_panel.gd:928/1039`, `test_p2b_services.gd:511/547`); FITTING
(`fitting_panel.gd:405,427`) and the shipyard already go through the composed pair.

## What changed, at file:line

| File | Change | Reversal |
|---|---|---|
| `vajb-orbit/ui/station/outfitting_panel.gd:676` | `remove_module`'s write is `profile.call(&"clear_fit_slot", hull, WEAPON_SLOT, index)`; the `add_module` line is deleted | restore the two raw calls (the review's `git show ff2375c:…` body) |
| `vajb-orbit/ui/station/outfitting_panel.gd:16-20`, `:657-663` | the two doc comments that named the raw pair now name the composed transaction (comments only; no behaviour) | revert the wording |
| `vajb-orbit/tests/test_p2b1_outfitting_panel.gd:282` `_module_count` | one read-back helper: a **record's own** `count`, which `_module_held` (an `instances_of` aggregate) cannot express | delete the helper with the two tests |
| `vajb-orbit/tests/test_p2b1_outfitting_panel.gd:662`, `:703` | the two regression tests | delete them; the gate returns to 491 |
| `docs/CONTRACTS.md` §9 | the expected figure `491/0 → 493/0`, growth `457 → 471 → 482 → 491 → 493` | revert the figure |
| `docs/CONTRACTS.md` §10 | a **v0.7.5** entry (this pass, what moved, the two tests) | delete the entry |

`_seed_fit` still precedes the call (the composed remove reads the **stored** fit for the
cell it banks, so the launch's standard fit must be materialised first, exactly as before);
`_base_id` still translates the cell only for the footer's wording and the empty-cell
guard, so a strip line still shows the base name and REMOVE still refuses an empty cell.

### One behaviour delta, measured, not asserted

The strip's REMOVE now writes the composed transaction's own economy-log line
(`EVENT_FIT_MODULE`, one line, qty 1, delta 0) where the raw `set_fit_slot` + `add_module`
wrote none — the same line FITTING's REMOVE has written since §13. Measured with a
T-93-sandboxed scene probe (removed from the tree again before this report, see the next
section):

```text
[k5probe] default_save_path=user://profile.cfg
[k5probe] scratch_save_path=user://k5_probe/profile.cfg scratch_log=user://k5_probe/economy_log.txt
[k5probe] fit_module_at=true instance=mod_0001
[k5probe] log lines before=1
[k5probe] strip remove_module=true
[k5probe] cell= module_count(instance)=1
[k5probe] log lines after=2
[k5probe] appended=2026-09-23T00:29:00, FIT_MODULE, mod_0001, 1, +0, 10000
```

Bucket 1 (inside the pinned acceptance): §13's composed remove pins that line, and no
wording, price or stat is involved.

## Evidence

The commands, their decisive outputs, the probe source and the live-store readings are
archived as text beside this report in `_k5_probes/README.md` (no `res://` file, so nothing
there can boot the profile autoload — T-93).

```text
# the fix's discriminating power — the p2b1 suite against the PRE-FIX panel (git checkout --),
# the fixed panel restored immediately after (cp of a kept copy; verified by git diff)
$ … res://tests/headless_runner.tscn -- --suite=test_p2b1_outfitting_panel
[FAIL] test_p2b1_outfitting_panel.gd.test_strip_remove_does_not_duplicate_a_base_keyed_unit: the fitted instance is back as itself
[FAIL] test_p2b1_outfitting_panel.gd.test_strip_remove_hands_back_the_fitted_instance: and the same instance is back in the bag
[SUMMARY] passed=9 failed=2                        (exit 1)

# the same suite after the fix (inside the full gate, gate3.log:311-313)
[PASS] test_p2b1_outfitting_panel.gd.test_strip_remove_does_not_duplicate_a_base_keyed_unit
[PASS] test_p2b1_outfitting_panel.gd.test_strip_remove_hands_back_the_fitted_instance
[PASS] test_p2b1_outfitting_panel.gd.test_strip_remove_is_the_ammo_panes_one_fit_action

# the four full gate runs
gate1.log: [SUMMARY] passed=493 failed=0   (exit 0)   # default user://, pinned command
gate2.log: [SUMMARY] passed=493 failed=0   (exit 0)   # identical
gate3.log: [SUMMARY] passed=493 failed=0   (exit 0)   # final tree
gate4.log: [SUMMARY] passed=493 failed=0   (exit 0)   # identical
```

## T-93 — the live account, before and after everything this pass

```text
md5(user://profile.cfg)     9182b34ffe0e51dc2ea8fa3051de4ae2  →  9182b34ffe0e51dc2ea8fa3051de4ae2
md5(user://economy_log.txt) 38b05767f005bafab286e4bbe8ed1764  →  38b05767f005bafab286e4bbe8ed1764
mtime(profile.cfg)          2026-09-23 01:22:35  →  unchanged       (2 268 B, same size and inode-time)
```

Both readings were taken **before the first edit** and **after the last gate run**; the
`profile.cfg` value is the byte-identical md5 the review and `_incident/README.md` record
as the restored state, so nothing this pass touched the owner's store.

- Both full gate runs of the final tree (and the two before them) used the **pinned
  command with the default `user://`** — `headless_runner.tscn` is the sanctioned live-path
  reader and sandboxes both stores itself (`headless_runner.gd:54-65`).
- One further full run was made under **`XDG_DATA_HOME=/tmp/vajb_k5_xdg`** and read the
  identical `passed=493 failed=0` — an independent check that the count does not depend on
  the account (CONTRACTS §14/L90).
- The one probe this pass needed (`tests/probe_s3_k5_strip_log.gd|.tscn`) set
  `PlayerProfile.save_path` to `user://k5_probe/profile.cfg` **and** `EconomyLog.log_path`
  to `user://k5_probe/economy_log.txt`, and ran under its own
  `XDG_DATA_HOME=/tmp/vajb_k5_xdg_probe`; both files were deleted from the project
  immediately after the run (`git status` carries no `probe_s3_k5*` entry, and the `.uid`
  sidecar was never created), so nothing in the tree can boot the profile against the live
  path.
- No background job was left: every Godot run was bounded with `--quit-after` and read from
  a captured log.

## Hard rules check

- **No price, roll weight, multiplier or 09 §3.1 stat moved**; no new refusal wording (the
  strip's footer still emits §13's `STATUS_REMOVED`).
- **No affix reaches a flight stat**: this pass touches no `game.gd`, `weapons.gd` or
  `ship_stats.gd`; the only readers of `rarity`/`prefixes`/`suffixes` this pass added are a
  test's own read-backs.
- Frozen set untouched: `git diff --name-only` = `ui/station/outfitting_panel.gd`,
  `tests/test_p2b1_outfitting_panel.gd`, `docs/CONTRACTS.md` (+ the pre-existing
  `RCLONE_TEST` deletion and the untracked designer-lane files, neither of them this pass's).
- Workspace-relative paths only (an absolute path inside `vajb-orbit/` is refused by the
  hook), and every kept edit went through the editor tools; the one shell pair
  (`cp` a kept copy out → `git checkout --` the panel → `cp` it back) existed only to
  produce the pre-fix regression proof, and the restored file was verified byte-for-byte
  with `git diff` before any further run.

## Deviations from `S3_BRIEF.md`

1. **Two tests were added** (the brief's test list is the builders' own; `test_p2b1` 9 → 11,
   gate 491 → 493). Why: the review states the wave's tests miss this exact path
   ("Nothing measures the OUTFITTING strip against an instance-keyed cell"), so the fix
   without a test would leave the cured defect unguarded. Reversal: delete the two tests,
   the gate returns to 491.
2. **`docs/CONTRACTS.md` §9's expected figure was updated** (491 → 493) rather than only
   noted in §10, because §9 is the figure the close-out leg reads and leaving it stale
   would pin a number the gate no longer prints. Both edits are in this pass's own file set;
   nothing in §15/"the pin" was touched (bucket 2 stays the developer session's).

## Follow-ups

None that this pass owns: the review's 16 LOW rows (`L107`–`L122`) are already ticketed in
`.agents/gen/_state/LOW_BACKLOG.md` and ride with the next wave, and the review's §10 owner
ticks are unchanged. The wave is ready for close-out: gate green, HIGH cured, no MED owed.
