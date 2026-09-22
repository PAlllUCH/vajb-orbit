# S3 incident — a builder probe wrote the owner's live account (2026-09-23)

**Class:** the S2.6/L106 class (a worker instrument booting the profile autoload
against the live `user://`), one wave later and by a different route: the runner's
sandbox protects the **gate**, but a `--script` / `--headless` probe that instantiates
the autoload writes `user://profile.cfg` and appends to `user://economy_log.txt`
exactly where the owner plays.

## What is measured

| Fact | Value |
|---|---|
| Live file at wave start (recorded by the orchestrator 00:10) | `05074143da4bb8e50f5f957de37f4d37`, 2139 B, `mtime 2026-09-22 21:17:47` |
| Live file after the incident | `596b88947fc65a3cecde803b7f2f92bd`, 2202 B, `mtime 2026-09-23 00:33:10` |
| Live file after this pass's restore | `9182b34ffe0e51dc2ea8fa3051de4ae2`, 2261 B |
| The owner's last legitimate log line | `2026-09-22T19:17:46, MINE, mineral_aluminium, 1, +0, 186` (= 21:17:46 local, the recorded mtime) |
| The probe's four lines (live log) | `22:28:04 REFINE all 15 -75 -> 111`, `22:28:06 SELL mineral_iron 2 +25 -> 136`, `22:28:06 SELL mineral_silicon 1 +15 -> 151`, `22:28:08 SELL ingot_aluminium 5 +418 -> 569` |
| Discovery | the orchestrator's post-K1 verification read the live md5 and found it moved |

All four probe lines are UTC (`22:28` UTC = `00:28:08` local), i.e. inside S3-K1's
**first** dispatch window (started ~00:22, last file write 00:32:45, stalled 00:33+).
Two probe runs are implied: one at 00:28 that refined and sold on the live store (the
tree was still save v5 then) and one at 00:33:10 that loaded, migrated and saved under
the new v6 code — which is why the file carries `save_version=6` and the v6 shape.

## What the owner lost, and the restore

The probe consumed the owner's mined ore and sold it (`REFINE all 15` → 5 ingots, then
the three `SELL`s). The pre-probe state is **exactly determined** by the log plus the
wave-start record (credits 186; cargo `mineral_aluminium 15 / mineral_iron 2 /
mineral_silicon 1`; the log's own `186 - 75 + 25 + 15 + 418 = 569` closes the
arithmetic). The orchestrator restored those two fields in place, changing nothing
else, and verified the result with Godot's own `ConfigFile` loader:

```
[READBACK] err=0 save_version=6 credits=186
[READBACK] cargo={ "mineral_aluminium": 15, "mineral_iron": 2, "mineral_silicon": 1 }
[READBACK] modules={ "mod_0001": {w_mining, common, count 1} } instance_counter=1
[READBACK] auction={ hot: &"", hulls: [], last_band: 0, modules: {} }
```

Every other field — the two owned hulls, the active hull, both fits, the ammo, the
market, `heat`/`standing`/`contracts`/`vaults`/`vitals` — is the owner's own and was
untouched by both the probe and the restore. The v5→v6 migration the probe triggered is
this wave's pinned behaviour and is kept.

**The economy log cannot be un-written**: the four probe lines stay in
`economy_log.txt` (honest history) and are preserved here as
`economy_log.to_2228utc.txt`.

## Preserved artefacts

| File | What it is |
|---|---|
| `profile.after_k1_probe.cfg` | the live file as the probe left it (`596b8894…`, v6, credits 569, empty cargo) |
| `profile.restored.cfg` | the live file after the restore (`9182b34f…`), byte-identical to what the owner's account holds now |
| `economy_log.to_2228utc.txt` | the live log through the probe's four lines |

## The cure this wave adopts (and the next wave must keep)

1. **No worker instrument may boot the profile against the live `user://`.** A probe
   that needs a profile sets `PlayerProfile.save_path` to a scratch path **and**
   `XDG_DATA_HOME` on the shell that runs the engine, or it runs through
   `headless_runner.tscn` (whose sandbox is the only sanctioned live-path reader).
2. The dispatch blocks for the rest of this wave carry that rule explicitly, and a
   reviewer checks the live md5 **before and after** every builder pass, not only at
   close-out.
3. `PlayerProfile` could make this class impossible rather than documented — e.g. a
   `sandbox_only` flag a headless/script run sets, or `_write_profile` refusing a
   `save_path` that is the live default when `OS.has_feature("headless")` is not the
   game's own run. Ticket row: `T-93` (LOW_BACKLOG L107).
