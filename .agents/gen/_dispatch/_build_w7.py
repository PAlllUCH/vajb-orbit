"""Build the W7 fixer dispatch: the reviewer's file set plus a context pointer."""
import io

SRC = ".agents/gen/_dispatch/slice2_w7.sh"
DST = ".agents/gen/_dispatch/slice2_w7_ruled.sh"

WORKER_FILES = ",".join([
    "vajb-orbit/game/weapons.gd",
    "vajb-orbit/game/projectile.gd",
    "vajb-orbit/autoload/player_profile.gd",
    "vajb-orbit/ui/hud/minimap.gd",
    "vajb-orbit/tests/",
    "vajb-orbit/tools/",
])

POINTER = (
    " ORCHESTRATOR ADDENDUM, 2026-09-21: your file set is set for you in the dispatch prefix and it is the reviewer's set for the findings assigned to you. Before you start, read .agents/gen/slice2_review_report.md in full - it is the authority on every finding - and then .agents/gen/slice2_w7_context.md, which is your pass's context file: it restates the three findings you own with their measured evidence and the reviewer's fix route, lists the findings that are explicitly NOT yours so you do not go looking for them, and repeats the rules that still apply. In short: fix F1 (HIGH, shots do not damage ships, fix weapons.gd and projectile.gd by resolving the damage sink through the collider's owner in the player_ship and npc_ship groups) and re-measure both the beam and the projectile families; fix F2 (a one-line PlayerProfile set_ammo writer so dock filing is not inert); fix F4 (minimap ghost and swarmer blip kinds per UI_SPEC section 3.3 and section 10). Do not touch project.godot, the theme, the assets, or any file outside your set. The universal gate is green at 200 tests: keep it green, add a test per fix, and report before and after numbers."
)

text = io.open(SRC, encoding="utf-8").read()
text = text.replace('"<per-finding sets from the W6 report>"', '"%s"' % WORKER_FILES)
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + POINTER + text[cut:]
io.open(DST, "w", encoding="utf-8", newline="\n").write(out)

print("dst %d B; set substituted: %s" % (len(out), WORKER_FILES in out))
print("double quote in pointer:", '"' in POINTER)
print("head:", out[:200])
