---
slice: S22
worker: S22-B2
model: deepseek/deepseek-flash
status: actionable
gate: "941/0 → 958/1 (959 rows = 941 + B1's 11 + this suite's 7; the failure is S19's byte-seal row, red by design until B3 re-pins it — amendment 6)"
---

# S22-B2 report

## Result
A5–A7 + A14 land: the HUD feeds the four real armour pools to the status screen, section
4.1's exactly three anti-flam rules enforce in `play_pool`, the mine's release plays a CC0
deploy clunk sourced through `assetmcp` (two takes, 0.351/0.359 s), and `laser_04` drops
from the laser pool. The new suite carries **7 green rows**; the full gate ran twice on
fresh scratch stores, identical both times: `[SUMMARY] passed=958 failed=1` (the one
failure is S19's byte-seal row — Deviations 7). No gameplay number moved (wave rule 1).
**Owner rulings implemented:** 18 (feedback is cosmetic), AUDIO-1..3 and §4.1's three rules
(D15's tick sheet, ticked 2026-09-29).

## Acceptance list answers
- **A5 (L241) — DONE.** `hud.gd:862` `_push_status` now also pushes
  `_status.set_quadrants(...)` from four `PlayerState.pool_of()` reads, so every
  hull/shield-driven status update feeds `ship_status_screen.gd:843`; the setter and its
  even-split fallback are unchanged. Probe `test_s22_audio.gd:145`: a routed port hit leaves
  `PORT 0 / 313` while its peers read `313 / 313` (hull 937.5 — the fallback would print
  234 each). The repairs panel's own even-split fallback stays disclosed and untouched
  (`repairs_panel.gd:212-224`: the station holds no flight pools).
- **A6 (L54) — DONE.** Three rules, no fourth: (i) `_pool_interval_open`
  (`audio_manager.gd:951`) drops a trigger inside 30 ms of the cue's last accepted one,
  consuming no variant; (ii) `_pool_voice_open` (`:960`) + `_active_class_voices` (`:971`)
  drop a fresh-voice trigger when its class is at `POOL_CAPS` (weapons 4 / impacts 6 /
  mining 1 / UI 2); a take whose own voice still holds it re-triggers that voice (the
  pre-existing cannon reuse, not a rule — no steal-oldest path exists); (iii) `_pool_index`
  (`:936`) skips the last used variant when N > 2. Probes: double trigger gap **1 ms**
  refused, next take 02 (`test_s22_audio.gd:193`); four long weapon voices open, the 5th
  dropped and an impact still plays (`:222`); 01 → explicit 02 → next round-robin **03**
  (`:251`); the numbers read off the constants (`:183`).
- **A7 (L48) — DONE.** Sourced via `assetmcp` (search → `get_asset_details` licence read →
  `download_asset` with the checked record): **qubodup, "7 mechanical clicks and buzzes",
  CC0 1.0 Universal (public domain)**, https://opengameart.org/content/7-mechanical-clicks-and-buzzes
  (archive https://opengameart.org/sites/default/files/mechanical.7z, sha256 `3884bdb7…`).
  Takes saved as `sfx_weapon_mine_drop_01.ogg` (**0.351 s**, from `mechanical_button-01.flac`)
  and `_02.ogg` (**0.359 s**, `mechanical_clicks-05.flac`), both ≤ 0.5 s, Ogg q5 + −1 dBFS +
  trim per the audio policy; `.import` sidecars landed. `CUE_POOLS[&"sfx_weapon_mine_drop"]`
  (`audio_manager.gd:121`, round-robin, no pitch/volume — the spec row states none);
  `FIRE_CUES[&"mine"]` (`weapons.gd:279`) plays it on release; the detonation keeps
  `BLAST_CUE` (`projectile.gd:171`). Probe `test_s22_audio.gd:282`: a real mine release
  through the shipped component plays `sfx_weapon_mine_drop_01`. Rows added to
  `generation_log_audio.md` (+ source URL); `asset-library/ASSET_MANIFEST.json` entry
  `license_status: allowed_public_domain`; `CREDITS.md` regenerated (CC0 needs none).
- **A14 (L49) — DONE.** `CUE_POOLS[&"sfx_weapon_laser"][&"takes"]` is 01–03
  (`audio_manager.gd:78-88`); take 04's file stays on disk (trim staged); cycle probe
  `01, 02, 03, 01` with skip-last at N = 3 (`test_s22_audio.gd:329`).
- **CUE_POOLS coexistence — kept.** Only the laser row was edited and the mine row added;
  no other row of `CUE_POOLS` was touched in this pass.

## Deviations from SLICE.md
1. **Four existing rows updated (bucket 1, test mechanics).** They pinned behaviour AUDIO-2
   and AUDIO-1/3 supersede: `test_weapon_fx_f1.gd`'s energy row now spaces its same-cue
   bursts (`:320`), its mine row becomes "drops with the mine pool's own cue" (`:351`), its
   round-robin row expects 01–03 + spacing (`:386`), its cannon-tier row spaces its tier
   reads (`:419`); `test_engine2_cleaving.gd:623` spaces the rock pool's second read.
   Counts unchanged. Reversal: restore the rows with the pre-tick behaviour.
2. **The runner clears the anti-flam memory between methods**
   (`headless_runner.gd:90` calling `audio_manager.gd:666 clear_pool_history`, beside
   `_sandbox_log`). The floor is wall clock and every gate method runs in one frame
   microseconds apart: without it 8 rows were timing-dependent (first full run, measured).
   `_pool_next` cursors are untouched, so round-robin-order rows keep their semantics.
   Reversal: drop the call and space every same-cue row manually.
3. **The cap's drop consumes the round-robin pick** (the pick precedes the fresh-voice
   gate; the 30 ms drop consumes nothing). Reversal: gate the cap before `_pool_index`.
4. **Same-take voice reuse kept** (pre-existing, reported in an earlier wave): at cap a
   same-take re-trigger reuses its voice and passes; §4.1's steal-oldest stays
   non-operative and no fourth rule is invented. Reversal: remove the reuse and let the cap
   drop sustained streams.
5. **A6's "20 ms" probe is a ~1 ms double-trigger** (tighter than the example; the suite
   prints the measured gap). Reversal: sleep 20 ms instead.
6. **The audio import ran in this pass.** Brief §8 puts it at close-out, but the gate cannot
   resolve the new cue without its `.import` sidecar: `godot --headless --editor --path
   "$VAJB_PROJ" --quit` exit 0, import params identical to an existing weapon one-shot.
   Reversal: delete the two sidecars and re-run at close-out.
7. **S19's byte-seal row is red by design** (amendment 6): untouched; B3 re-pins
   `weapons.gd`/`npc_ship.gd` from the finished tree.

## Evidence
- Gate, twice, fresh stores, identical: `XDG_DATA_HOME=/tmp/s22b2_gate{A,B}/xdg
  "$GODOT_CONSOLE" --headless --path "$VAJB_PROJ" res://tests/headless_runner.tscn
  --quit-after 1200` → both `[SUMMARY] passed=958 failed=1`; both fail exactly
  `test_s19_quadrants.gd.test_the_four_forbidden_files_are_byte_identical: res://game/npc_ship.gd`.
- The suite's probe lines: `A5 port=PORT 0 / 313 prow=PROW 313 / 313 hull=937.5 quarter=312.5`;
  `A6 double_trigger gap=1ms refused=true next=…02`, `A6 cap weapons_active=4
  fifth_dropped=true impact_plays=true`, `A6 skip_last first=…01 tier=…02 next=…03`;
  `A7 cue=sfx_weapon_mine_drop played=…01 seconds=[0.3509, 0.3594]`;
  `A14 cycle=[01,02,03,01] take_04_staged=true`.
- Cue facts: sha256 of the downloaded archive in the manifest; `ffprobe` 0.351/0.359 s;
  `.import` diff vs `sfx_weapon_laser_01.ogg.import` identical except the cache hash.
- `--forbidden` check: no diff in `project.godot`, `game/damage.gd`, `docs/CONTRACTS.md`,
  `addons/` (`git diff --stat HEAD -- <paths>` empty).

## Files touched
- `autoload/audio_manager.gd` — the mine pool row, laser_04 drop, the three anti-flam rules
  and their state, `clear_pool_history`
- `game/weapons.gd` — `FIRE_CUES[&"mine"]` + the S1/S26 comment
- `ui/hud/hud.gd` — `_push_status` pushes `set_quadrants`
- `tests/test_s22_audio.gd` — new suite, 7 rows (A5 ×1, A6 ×4, A7 ×1, A14 ×1)
- `tests/headless_runner.gd` — anti-flam memory cleared between methods
- `tests/test_weapon_fx_f1.gd`, `tests/test_engine2_cleaving.gd` — the rows in Deviation 1
- `assets/audio/sfx/sfx_weapon_mine_drop_01/02.ogg` + `.import`; `generation_log_audio.md`
- `asset-library/ASSET_MANIFEST.json`, `asset-library/CREDITS.md` — the assetmcp pass's own rows

## Follow-ups
| Item | Kind | Where |
|---|---|---|
| S19 byte-seal re-pin (both strings, once, finished tree) | bucket 2 / wave close | `tests/test_s19_quadrants.gd:94-105` |
| Laser take 04's 0.06–0.09 s trim, returning as `_04` | staged (audio lane) | AUDIO_SPEC §8.6 AUDIO-3 |
