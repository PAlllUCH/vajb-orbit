"""Build the M3 dispatch: the verbatim brief prompt plus the owner ruling addendum.

The prompts file is law and runs verbatim; the addendum carries the two owner
rulings of 2026-09-21 (refuel is free, the icon re-path is the graphics lane's).
"""
import io

src = ".agents/gen/_dispatch/slice0_m3.sh"
dst = ".agents/gen/_dispatch/slice0_m3_ruled.sh"

addendum = (
    " ORCHESTRATOR RULING ADDENDUM from the owner, dated 2026-09-21, which overrides the brief and this prompt wherever they differ."
    " Item 1: the refuel CR-per-fuel-point row does not exist in 18_engine_spec section 13, so the owner has ruled that refuel and recharge are FREE instant station services."
    " Implement refuel so it fills the tank and returns the same ok and fee shaped dictionary as repair, with fee 0, and recharge likewise at fee 0."
    " Do not invent a CR rate, do not add any price number anywhere, and treat the fee field as the free-rate report."
    " Item 2: the graphics lane is re-laying the whole vajb-orbit/assets tree into per-family subdirectories as this wave runs. Icons now live under assets/icons slash family slash, environment art under assets/env slash backdrop, body, pickup, poi, prop or tile, and assets/icons/tint is gone. Worker M1 measured 24 files with 133 unresolvable asset references across game, ui, autoload, tests and tools, which makes lots of compile-time preloads and every boot gate fail for reasons that are not yours."
    " That re-path is the graphics lane follow-up and NOT your task: leave every stale path string exactly as it is, do not touch assets, do not sweep any file outside your own five, and record the failures it causes as environment-deferred in your report."
    " M2 is re-pathing only its own file asteroid.gd, and the graphics lane has already fixed mineral_catalog.gd, so the sweep is in hand - do not race it."
    " Item 3: the universal test gate is therefore expected to read passed equals 52 with failed equals 1, and boot gates for game, main menu, settings and station may fail on missing asset paths. Treat exactly those asset-path failures as pre-existing and outside your scope, and make sure every other test and every check that does not depend on moved art still passes."
)

text = io.open(src, encoding="utf-8").read()
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + addendum + text[cut:]
io.open(dst, "w", encoding="utf-8", newline="\n").write(out)

print("src %d B -> dst %d B, addendum %d B" % (len(text), len(out), len(addendum)))
print("addendum carries a double quote:", '"' in addendum)
print("addendum carries a backtick:", chr(96) in addendum)
print("--- dst head ---")
print(out[:160])
print("--- dst tail ---")
print(out[-260:])
