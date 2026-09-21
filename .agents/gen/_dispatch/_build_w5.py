"""Append the W5-specific addendum to the slice-2 W5 dispatch.

W5 owns the wiring, so it needs the handoffs the parallel workers measured but
could not close (W2's five, W3's registry/brain/ship and its spec gaps) plus the
two lanes that touch its files: batch-2's committed-free hud.gd zoom fix and the
graphics lane's chrome regression, which W5 must not try to fix.
"""
import io

SRC = ".agents/gen/_dispatch/slice2_w5.sh"
DST = ".agents/gen/_dispatch/slice2_w5_ruled.sh"

addendum = (
    " W5-SPECIFIC ORCHESTRATOR ADDENDUM, 2026-09-21. The four parallel workers have landed; read their reports before you wire anything: .agents/gen/slice2_w1_report.md (weapons and projectiles, 95 probe checks), slice2_w2_report.md (the damage pipeline), slice2_w3_report.md (the NPC archetypes, 28 tests), slice2_w4_report.md (loot tables, 13 tests). The universal gate is GREEN right now at 168 tests with zero failures - measure the total yourself, keep it green, and add your own slice-2 wiring tests as res slash tests slash test underscore engine2 underscore star dot gd."
    " The five wiring items W2 measured but could not close are yours, because they live in files W2 did not own: the player hull has no take underscore damage, so nothing routes a hit into PlayerState; the ram path passes no context, so the damage call carries no direction, impulse or family; nothing seeds shield underscore regen from the launch snapshot; nothing calls Damage dot regen, so shields never recover; and W1 duplicated the delivery seam privately inside weapons dot gd and projectile dot gd instead of sharing it. Close all five in your set and report each with a measurement; if a shared seam should be extracted from W1's files rather than duplicated, say so in your report as a MED for the reviewer instead of editing W1's files, which are outside your set."
    " W3 shipped three new files to mount: game slash npc underscore registry dot gd (nine archetype rows, the spec section 13 per-sector band, swap-ready sprite paths, seam rows that never spawn), game slash npc underscore brain dot gd (one state set, injected line-of-sight, leash 2500, aggro cooldown 5.0, intent only - it applies no forces) and game slash npc underscore ship dot gd (a RigidBody2D hull on the same physics law as the player, take underscore damage mirroring the Damage sink, a died signal, and engaged underscore with for the warp gate). Spawn the sector's ships from the registry rows on entry, push hostile and neutral blips, and drive PlayerShip's warp gate with the real engagement state through W3's query."
    " W3 reported spec gaps rather than inventing values, and you must do the same: the human/alien split of the section 13 band is not written down (W3 used a stated fill-order rule and reports it), the patrol count is a proposal, the alien hulls have no ship-class row in doc 08, the station turret has neither a class row nor a damage figure, the NPC armament is unspecified so the fire intent ships unarmed, and there is no stand-off range or turret scan radius. Implement what the spec does state, leave the gaps as reported seams, and list every one you had to work around in your report - do not invent a number to close one."
    " Two lanes touch files near yours. First, the batch-2 playtest worker already changed ui slash hud slash hud dot gd: the two minimap zoom constants are renamed ZOOM underscore DELTA underscore IN and ZOOM underscore DELTA underscore OUT and the two pressed bindings were swapped so plus zooms in - keep that change, and if you restructure around it, say so in your report. Second, the graphics lane's asset redesign left the UI chrome regressed (measured evidence and both fix routes are in .agents/gen/ui_chrome_regression.md: the button plates are whole sheet cells so the theme stretches a mostly transparent canvas, the menu wordmark crop is now empty, the bezel nine-patch band draws three pixels instead of sixteen). That is NOT yours: the theme is a forbidden file, the assets belong to the graphics lane, and the owner has the routing decision. Do not restyle anything to compensate, and do not touch the theme or the plates."
    " Assets remain mid-re-layout by that lane, so any failure that is only a missing or moved asset path is environment-deferred and not a finding. Your boot gates must exit zero; if one fails only on an asset path, record that and continue."
)

text = io.open(SRC, encoding="utf-8").read()
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + addendum + text[cut:]
io.open(DST, "w", encoding="utf-8", newline="\n").write(out)

print("src %d B -> dst %d B, addendum %d B" % (len(text), len(out), len(addendum)))
print("double quote in addendum:", '"' in addendum)
print("head:", out[:140])
