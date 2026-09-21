"""Build every slice-2 dispatch script from the prompts file.

The prompts file carries the owner's prompt text per worker; the brief's file-set
table says which files each worker owns. This builder assembles:

  VAJB_WORKER_FILES="<the brief's set, plus tools/ and tests/>" \
  crush run "<prompt verbatim> + <orchestrator addendum>" -m deepseek/deepseek-v4-flash ...

Two set additions over the brief's table, both from slice 0's own review (M4
finding F6): `vajb-orbit/tools/` because the Global rules require probes there
while the hook denied the write, and `vajb-orbit/tests/` because a wave must add
its slice's tests and the runner auto-discovers `tests/test_*.gd`.
"""
import io
import os
import re

SRC = ".agents/gen/slice2_prompts.md"
OUT_DIR = ".agents/gen/_dispatch"

FILE_SETS = {
    "W0": ["docs/design/IMPLEMENTATION_PLAN.md", "docs/gameplay/06_loot_drops.md",
           "docs/gameplay/08_ship_classes.md", "docs/gameplay/09_ship_slots_modules.md"],
    "W1": ["vajb-orbit/game/weapons.gd", "vajb-orbit/game/projectile.gd",
           "vajb-orbit/tests/", "vajb-orbit/tools/"],
    "W2": ["vajb-orbit/game/damage.gd", "vajb-orbit/game/player_state.gd",
           "vajb-orbit/tests/", "vajb-orbit/tools/"],
    "W3": ["vajb-orbit/game/npc_registry.gd", "vajb-orbit/game/npc_ship.gd",
           "vajb-orbit/game/npc_brain.gd", "vajb-orbit/tests/", "vajb-orbit/tools/"],
    "W4": ["vajb-orbit/game/loot_tables.gd", "vajb-orbit/tests/", "vajb-orbit/tools/"],
    "W5": ["vajb-orbit/ui/hud/hud.gd", "vajb-orbit/ui/hud/hud.tscn",
           "vajb-orbit/game/game.gd", "vajb-orbit/game/sector.gd",
           "vajb-orbit/game/player_ship.gd", "vajb-orbit/tests/", "vajb-orbit/tools/"],
    "W6": ["docs/CONTRACTS.md", "vajb-orbit/tools/"],
    "W7": ["<per-finding sets from the W6 report>"],
    "W8": ["docs/CONTRACTS.md", "vajb-orbit/tools/"],
}

# The context every slice-2 worker needs, assembled from slice 0's own records.
SHARED = (
    " ORCHESTRATOR CONTEXT ADDENDUM, 2026-09-21. Engine slice 0 (physics and fuel) CLOSED and is review-verified before you start, so code against the shipped tree, not against a pre-migration assumption: the player hull is a RigidBody2D whose motion is forces and torque, game slash impact dot gd exists with the pinned statics (collision_damage, knockback, recoil_impulse, explosion_impulse, apply_shockwave), PlayerState carries the energy and fuel pools with try_spend_energy, try_spend_fuel, emergency_mode, consume_fuel_cell and tick, the station services refuel and recharge exist and are free, and the save schema is v3. docs slash CONTRACTS dot md sections 2, 4, 5 and 8 carry those pins; read them. The wave report is .agents/gen/slice0_report.md and the rulings log is .agents/gen/slice0_owner_rulings.md."
    " Four owner rulings are in force. One: refuel and recharge are FREE instant services and no CR rate may exist anywhere. Two: the vajb-orbit slash assets tree belongs to the graphics lane, whose naming re-layout may still be in flight, so a failure that is only a missing or moved asset path is environment-deferred and is NOT a finding - do not touch assets, do not sweep asset paths, and do not widen your file set; the pending list is .agents/gen/asset_path_fallout.md. Three: an R key event spends a fuel cell; consume_fuel_cell is bound to R, not to C, because the owner ruled that cargo_toggle keeps C. Four: do not invent a number anywhere; a missing spec value is reported, not guessed."
    " Two corrections to the brief's Global rules, both from the slice-0 review. First, the universal gate has grown: the suite is 78 tests today and you will add your own, so the gate must read whatever total you measure with ZERO failures - never compare against the 53 the brief still prints. Second, your dispatch file set adds vajb-orbit slash tools slash and vajb-orbit slash tests slash to the brief's table. tools slash is there because the Global rules require your probe at res slash tools slash underscore probe, which the file hook used to deny and workers had to write through the shell - the prevention layer depends on bash writes being forbidden, so use the write tool normally and say in your report that you did. tests slash is there because a wave adds its slice's tests as res slash tests slash test underscore engine2 underscore star dot gd; the headless runner discovers them automatically, so there is no registration file to edit."
    " Shell facts in this workspace, so you do not lose a pass to tooling: there is no grep, head, tail, wc, cat, sleep or seq on PATH - use py dash 3 dot 14 and the Grep and View tools instead, and never the PATH python, which is Inkscape's and cannot verify TLS. Every Godot run is bounded with --quit-after and its stdout goes to a log you read afterwards; never leave a run in the background, and never treat an exit code alone as a gate."
)


def extract_prompts(text):
    """Map each '## <id>' section to the first fenced block under it."""
    prompts = {}
    for m in re.finditer(r"^## ([A-Z]\d+) .*$", text, re.M):
        wid = m.group(1)
        rest = text[m.end():]
        fence = re.search(r"\n```[a-z]*\n(.*?)\n```\n", rest, re.S)
        if fence:
            prompts[wid] = fence.group(1).strip()
    return prompts


def main():
    text = io.open(SRC, encoding="utf-8").read()
    prompts = extract_prompts(text)
    print("prompts found:", sorted(prompts))

    for wid in sorted(prompts):
        prompt = prompts[wid]
        assert '"' not in prompt.replace('\\"', ""), "%s prompt carries a bare double quote" % wid
        files = FILE_SETS.get(wid)
        if not files:
            print("SKIP %s (no file set)" % wid)
            continue
        joined = ",".join(files)
        body = prompt + SHARED
        script = 'VAJB_WORKER_FILES="%s" \\\ncrush run "%s" \\\n-m deepseek/deepseek-v4-flash --cwd "G:/Mój dysk/Projekty/Vajb Orbit"\n' % (joined, body)
        path = os.path.join(OUT_DIR, "slice2_%s.sh" % wid.lower())
        io.open(path, "w", encoding="utf-8", newline="\n").write(script)
        print("%-34s %6d B  set=%s" % (path, len(script), joined[:60]))


if __name__ == "__main__":
    main()
