"""Build the M5 fixer dispatch: the brief prompt with the real file set + context.

The prompts file carries a placeholder for the fixer's file set because it is
per-finding. The set below comes from M4's report: F1 is a test file in no
slice-0 worker's set, F2-F5 are the hull, F3 may touch the fit's booster row, and
`vajb-orbit/tools/` is added because M4's F6 reproduced the hook denying the probe
write the Global rules require.
"""
import io

src = ".agents/gen/_dispatch/slice0_m5.sh"
dst = ".agents/gen/_dispatch/slice0_m5_ruled.sh"

worker_files = ",".join([
    "vajb-orbit/tests/test_p1_profile.gd",
    "vajb-orbit/game/player_ship.gd",
    "vajb-orbit/game/ship_fit.gd",
    "vajb-orbit/tools/",
])

addendum = (
    " ORCHESTRATOR CONTEXT ADDENDUM, compiled from the M4 review of 2026-09-21. Your file set is set for you in the dispatch prefix and it is the fixer set M4 prescribed: the test file for F1, the hull for F2 to F5, the fit for F3's booster row, and vajb-orbit slash tools slash so you are NOT blocked by the hook gap M4 reproduced as finding F6 (that gap is fixed in this dispatch and it is the reason every earlier worker had to write probes through the shell). Do not widen it; if a fix genuinely needs another file, stop and report which file and why instead of editing it."
    " The findings to fix, from .agents/gen/slice0_m4_report.md - read that report first, it is the authority on each one: F1 HIGH, tests slash test_p1_profile.gd line 204 asserts that a write persists save_version 2, which slice 0's mandated SAVE_VERSION 3 falsified, so the gate reads passed 77 failed 1; make the assertion expect 3 and update its message, and change nothing else in that test. F2 MED, Emergency Flight Mode must ignore thrust (ruling 14, measured 203.57 u/s at fuel 0): gate the throttle sample on emergency_mode in game slash player_ship.gd, leaving turning live as reaction wheels. F3 MED, the afterburner must burn BOOST_FUEL 3.0 per second through try_spend_fuel and must refuse to arm on an empty tank, and the BOOST_FUEL and DASH_FUEL constants need their single code owner - M4 assigns them to the hull or to the b_afterburner row of the fit, your choice, one owner only. F4 MED, PlayerState.tick has no caller so the reactor never refills in the shipped game: call the tick from the hull's physics step, which is the contract M4 pinned in docs slash CONTRACTS.md section 4 and 8.1. F5 MED, nothing in shipping code calls consume_fuel_cell: add the caller on the C action, guarded with InputMap.has_action so the code is safe whether or not the action exists; the action itself is already applied for you - the orchestrator added consume_fuel_cell equals C to project.godot through the editor, so do not touch project.godot and do not rebind anything."
    " Owner rulings in force: refuel and recharge are FREE station services with no CR rate (do not reintroduce one anywhere), and the vajb-orbit slash assets tree belongs to the graphics lane, whose naming re-layout is mid-flight - any failure that is only a missing or moved asset path is environment-deferred and is NOT yours to fix, and the paths still awaiting that lane are listed in .agents/gen/asset_path_fallout.md. Do not touch assets and do not sweep asset paths."
    " Acceptance for you: the universal gate must read the measured total with ZERO failures (the suite is 78 tests; the only expected red today is F1 and you are fixing it), your probe must show the four hull-side behaviours fixed with before and after numbers, and your report must record for each finding the spec section it implements and the measurement that proves it. One known item you must NOT try to fix: the C key is bound both to cargo_toggle and to consume_fuel_cell, which is a contradiction inside the owner's own spec (18_engine_spec section 11 versus the P1 patch table); the orchestrator has raised it with the owner and no worker may rebind it."
)

text = io.open(src, encoding="utf-8").read()
text = text.replace('"<per-finding file sets from the M4 report>"', '"%s"' % worker_files)
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + addendum + text[cut:]
io.open(dst, "w", encoding="utf-8", newline="\n").write(out)

print("dst %d B; files substituted: %s" % (len(out), worker_files in out))
print("double quote in addendum:", '"' in addendum)
print("backtick in addendum:", chr(96) in addendum)
print("--- head ---")
print(out[:260])
