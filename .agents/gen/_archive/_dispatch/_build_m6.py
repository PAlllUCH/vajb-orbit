"""Build the M6 re-review dispatch: the brief prompt, a wider file set, context.

M6 owns CONTRACTS.md and re-runs M4's probes, so it needs `vajb-orbit/tools/` in
its set for the same reason M5 did (M4's finding F6 reproduced the hook denying
the probe write). The addendum carries the rulings that changed what M6 must
verify: the action is R now, the refuel rate is free, and the asset paths stay
the graphics lane's.
"""
import io

src = ".agents/gen/_dispatch/slice0_m6.sh"
dst = ".agents/gen/_dispatch/slice0_m6_ruled.sh"

worker_files = "docs/CONTRACTS.md,vajb-orbit/tools/"

addendum = (
    " ORCHESTRATOR CONTEXT ADDENDUM, 2026-09-21. Read .agents/gen/slice0_m4_report.md first - it is the finding list you are verifying - then .agents/gen/slice0_m5_report.md, and .agents/gen/slice0_owner_rulings.md for the four owner rulings made while the wave ran."
    " Your file set is set for you in the dispatch prefix: docs slash CONTRACTS.md plus vajb-orbit slash tools slash. The tools entry is there because M4 reproduced finding F6 - every M-worker before you was blocked by the file hook from writing the probe the Global rules require, and had to fall back to the shell; this dispatch closes that gap, so write your probes normally and say so in the report."
    " What you verify, one line per finding: F1 HIGH, tests slash test_p1_profile.gd must now expect save_version 3, so the universal gate must read the full suite with ZERO failures - measure the actual total, the suite is 78 tests, and state it. F2 MED, at fuel 0 a full second of throttle must NOT accelerate the hull. F3 MED, one second of afterburner must burn 3.0 Fuel and boost must refuse to arm on an empty tank. F4 MED, spending 10 Energy must refill through the reactor tick in the shipped game. F5 MED, consume_fuel_cell must have a shipping caller. Re-run M4's own probe of the live hull and say before and after."
    " Three rulings change what a correct fix looks like, and you must verify against them, not against the brief: first, consume_fuel_cell is bound to R, not to C - the owner ruled that cargo_toggle keeps C, so 18_engine_spec section 11 is superseded on that key; verify R on disk in project.godot and record the deviation rather than flagging it as a bug. Second, refuel and recharge are free instant services and no CR rate may exist anywhere; if a fix reintroduced a rate, that is a finding. Third, the vajb-orbit slash assets tree belongs to the graphics lane and its re-layout is mid-flight, so failures that are only missing or moved asset paths stay environment-deferred, listed in .agents/gen/asset_path_fallout.md, and are not findings; the only acceptance they affect is the Small-rock pickup burst, which stays unproven end to end until that lane ships."
    " Still open and owned by the owner, not by any worker: F7 (the owner-locked spec still sells fuel for CR in three places - the owner will strike them in their own pass) and the section 13 speed table v2 tick. Record both as open in your close statement instead of attempting them."
)

text = io.open(src, encoding="utf-8").read()
text = text.replace('VAJB_WORKER_FILES="docs/CONTRACTS.md"', 'VAJB_WORKER_FILES="%s"' % worker_files)
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + addendum + text[cut:]
io.open(dst, "w", encoding="utf-8", newline="\n").write(out)

print("dst %d B; set substituted: %s" % (len(out), worker_files in out))
print("double quote in addendum:", '"' in addendum)
print("--- head ---")
print(out[:200])
