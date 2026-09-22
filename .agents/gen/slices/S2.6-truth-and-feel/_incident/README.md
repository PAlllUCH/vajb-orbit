# Incident — the S2.6 harness destroyed the owner's live account (2026-09-22)

**Severity: HIGH (owner data).** Recorded here because the wave's own artifact caused it;
`S2.6-R1_report.md` §Deviations 2 is the worker's account, this is the orchestrator's.

## What happened

At **20:21** (R1's first full run of the new harness, `r1_gate_runA.log`) the gate wrote
`user://profile.cfg` — the owner's live account:

1. `tests/test_engine2_pools.gd` handed `PlayerProfile.save_path` back to the **literal**
   `Profile.SAVE_FILE` (the live path) in its teardown, instead of the path it captured when
   its setup began.
2. R1's new `tests/test_s2_6_gate_hygiene.gd` then wrote its *mutation* (a deliberate bad
   account: credits `999999`, laser pack `7`, fit `["w_cannon"]`) to "the store's path",
   which that teardown had just pointed at the live file.

Result: the live file went **2151 B / md5 `bb2ad1d724a6dd900c099584390d48de`** →
**359 B / md5 `3c9c167bca59e20682396757f43065fa`**, i.e. every field R0 did not happen to
record was replaced by a shipped default (modules, cargo, the second hull, the market,
vitals/fuel).

## Recovery performed

| Step | Result |
|---|---|
| R1 stopped, both defects fixed (`pools` restores its captured path; the hygiene test's write is guarded), verified by R1 and independently by this session | gate `passed=440 failed=0`, live file byte-identical and its mtime *unmoving* across a full run |
| Orchestrator re-verified hermeticity before any further dispatch | `profile.cfg` md5 `b2174b2e…`, `stat` unchanged 20:39:54 before/after one full gate run; live `economy_log.txt` unchanged (`60651 B`, 20:01) |
| Best-effort reconstruction written to the live path (20:39) | 949 B, reads back cleanly (`err=0`): `credits 852`, `owned_ships ["ship_vanguard","ship_fighter"]`, both fit blocks with their exact recorded array shapes, the six recorded market demand values and `last_band 1790092422` |
| Artifacts preserved | `profile.r1_reconstruction.cfg` and `profile.r1_reconstructed_artifact.cfg` — the same 359 B file, kept under two names (`3c9c167b…`, R1's reconstruction as it stood on disk at 20:28 and in /tmp at 20:28), plus `r1_gate_runA.log` (which reads `passed=428 failed=12` — the twelve log-reading suites of R1's deviation 3, a figure neither report quotes) |

**Not preserved (R6's record nit, measured):** the orchestrator's 20:39 reconstruction
(949 B, `b2174b2e…`) — the intermediate between R1's 359 B file and the owner's current
account — was written to the live path and then superseded by the owner's own play, so it
exists nowhere as a file. Its exact recipe is this document's "Recovered from evidence"
paragraph plus the field list above; the live file has since moved on legitimately
(the owner played at 20:58 and 21:17: cargo, a bought `w_mining`, a normalised market).

**Recovered from evidence** (`S2.6-R0_report.md` §0 read the live file before the incident, and
the same session read its `fits` and `market` blocks): `save_version`, `credits`, `active_ship`,
both hulls' fit cells (Vanguard: `["w_mining","w_cannon",""]`; Fighter: two empty W cells), the
market's six demand values and its `last_band`.

**NOT recoverable on this host** (no copy exists anywhere under `$HOME`, `/tmp`, the cloud-drive
mount or the trash — searched): the module inventory (`modules`), cargo, ammo counts, the
market's `stock`/`queue`/`trend` and the other minerals' demand, and `vitals` (hull/shield/fuel).

## Owner action

The **Windows host's own** `%APPDATA%\Godot\app_userdata\Vajb Orbit\profile.cfg` is the only
exact copy of the account. Copy it over
`~/.local/share/godot/app_userdata/Vajb Orbit/profile.cfg` to restore it; the reconstruction
above is what the Linux host holds until then.

## Rules this changes for the rest of the wave

- No worker runs the gate against the real `user://`: the four builders get their own
  `XDG_DATA_HOME` (`/tmp/s26_R<n>`), and the two hermetic close-out runs plus R6's are the only
  ones on the real path — each verified against the live md5 before and after.
- The gate's own hermeticity is now the wave's *first* deliverable, so this class of write is
  impossible for later waves (CONTRACTS §14, `S2.6-R1_report.md` AC1 table).
