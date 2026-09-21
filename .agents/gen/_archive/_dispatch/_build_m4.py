"""Build the M4 review dispatch: the verbatim brief prompt plus the wave context.

M4 measures rather than trusts, so it needs the two owner rulings, the
environment-deferred asset rule, the grown test gate, and the list of findings
the workers already reported - otherwise it either re-litigates the rulings or
blames the wave for the graphics lane's mid-flight re-layout.
"""
import io

src = ".agents/gen/_dispatch/slice0_m4.sh"
dst = ".agents/gen/_dispatch/slice0_m4_context.sh"

addendum = (
    " ORCHESTRATOR CONTEXT ADDENDUM, compiled from this wave's own reports on 2026-09-21. Read the worker reports before you start: .agents/gen/slice0_m0_report.md, slice0_m0b_report.md, slice0_m1_report.md, slice0_m2_report.md, the M3 report slice0_m3_report.md, and .agents/gen/asset_path_fallout.md."
    " Owner ruling item 1: refuel and recharge are FREE instant station services. The refuel CR rate is not a spec number and no worker may invent one; docs/gameplay/14_station_services.md and docs/design/IMPLEMENTATION_PLAN.md section 9.9 already record the ruling, so do not open a finding that asks for a rate."
    " Owner ruling item 2: the graphics lane owns the vajb-orbit/assets tree and its naming re-layout is MID-FLIGHT. Any failure that is only a missing or moved asset path is environment-deferred until the designer ships, per the dispatcher hard rule, and is NOT a code finding: do not open findings against assets, and do not ask a fixer to sweep asset paths outside its own file set. The paths still awaiting that lane are listed in .agents/gen/asset_path_fallout.md; the icon families were already swept by that lane during this wave, which is why the gate that was red at wave start is expected to be green now."
    " Owner ruling item 3: the universal gate has GROWN. Worker M2 added tests/test_engine2_pools.gd and tests/test_engine2_cleaving.gd, so the correct expectation is the measured pass count with zero failures, not the 53 that docs/CONTRACTS.md section 9 still states. Measure the real number, report it, and state the delta and its cause; also update CONTRACTS section 9 and its changelog, since that section is yours to maintain."
    " Item 4, judge each of these on the spec rather than on the reporting worker's own confidence - they are claims, not conclusions: M1 D10 (the probe-in-tools hook gap: the worker file sets omit vajb-orbit/tools, so the enforcement hook denies the write the Global rules require and the worker used the shell instead), M0 items D1 D2 D4 D5 D6 (transcription form and placement discrepancies plus two genuine spec gaps), M0b items D-A and D-B (the superseded refuel wording survives inside the owner-locked spec and inside the wave brief itself), M2 item 6.1 (game/pickup.gd keeps a stale env preload and belongs to no slice-0 file set, so a Small rock's pickup burst could not be proven), M2 item 6.2 (Emergency Flight Mode's thrust gate is not wired into game/player_ship.gd, so the state flag is inert at the controls), M2 item 6.3 (the env family path sweep), M2 item 6.4 (the dash's 0.8 s invulnerability and its displacement are b underscore fold module scope, not slice-0 state)."
    " Item 5: your CONTRACTS changelog entry must record the two owner rulings above, or the next wave will re-litigate them."
)

text = io.open(src, encoding="utf-8").read()
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + addendum + text[cut:]
io.open(dst, "w", encoding="utf-8", newline="\n").write(out)

print("src %d B -> dst %d B, addendum %d B" % (len(text), len(out), len(addendum)))
print("double quote in addendum:", '"' in addendum)
print("backtick in addendum:", chr(96) in addendum)
print("--- tail ---")
print(out[-200:])
