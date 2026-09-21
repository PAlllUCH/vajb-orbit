"""Rebuild the pre-fix player_ship.gd from the fixed one by reversing the M5 edits.

The wave is uncommitted (HEAD is the pre-slice-0 snapshot), so the only way to get a
true before/after is to reverse the fix. The reconstruction is proven exact by the
review's own published byte count (26 093) and md5 prefix (de16ff6528a0).
"""
import hashlib
import io
import sys

SRC = "vajb-orbit/game/player_ship.gd"
OUT = ".agents/gen/_m5_before_player_ship.gd"

T = "\t"
PAIRS = [
    # E1 header
    (
        "## so no flight number is duplicated here. The constants that do live here are the\n"
        "## section 13 values that belong to no class and to no module (brake multiplier,\n"
        "## arrive-steering radii, the afterburner's and the dash's fuel burn) plus the\n"
        "## section 7 warp quiet time.\n"
        "## This node also owns the reactor chain's hull half (section 4.4, rulings 11/14,\n"
        "## pinned in CONTRACTS sections 4 and 8.1): its physics frame is the frame that ticks\n"
        "## `PlayerState` (reactor refill and fuel-cell cooldown), it burns BOOST_FUEL through\n"
        "## `try_spend_fuel` while the afterburner runs, it reads `emergency_mode` to lock\n"
        "## thrust out, and it is where section 11's fuel-cell key spends a cell.\n"
        "## Contract: ENGINE_SPEC sections 3, 4.2 (items 6-8, ruling 16's push physics), 4.4,\n"
        "## 6, 7, 9, 13; engine-wave-1 brief section W2; slice-0 brief pinned interface item 1;\n"
        "## CONTRACTS sections 4 and 8.1.",
        "## so no flight number is duplicated here. The constants that do live here are the\n"
        "## section 13 values that belong to no class and to no module (brake multiplier,\n"
        "## arrive-steering radii) plus the section 7 warp quiet time.\n"
        "## Contract: ENGINE_SPEC sections 3, 4.2 (items 6-8, ruling 16's push physics), 6, 7,\n"
        "## 9, 13; engine-wave-1 brief section W2; slice-0 brief pinned interface item 1.",
    ),
    # E2 FUEL_CELL_ACTION const
    (
        "const MINE_ACTION: StringName = &\"mine\"\n"
        "\n"
        "## Section 11's in-flight refuel (ruling 13): one `fuel_cell` cargo item becomes\n"
        "## FUEL_CELL_UNITS of tank fuel. The action's binding is the input map's business; the\n"
        "## hull only reads it, guarded, so a build without the binding still flies.\n"
        "const FUEL_CELL_ACTION: StringName = &\"consume_fuel_cell\"",
        "const MINE_ACTION: StringName = &\"mine\"",
    ),
    # E3 BOOST_FUEL / DASH_FUEL consts
    (
        "const ARRIVE_RADIUS := 40.0\n"
        "\n"
        "## ENGINE_SPEC section 13 \"Energy & fuel (rulings 10-14)\": the afterburner burns\n"
        "## BOOST_FUEL 3.0 per second while it runs and a fold/dash burst spends DASH_FUEL 25.\n"
        "## Both are global calibration rows -- no class column and no module effect carries\n"
        "## them -- so the hull that spends them is their single owner, exactly as it is for\n"
        "## the brake multiplier and the arrive radii above (slice-0 review finding F3; the\n"
        "## dash's own activation and displacement stay slice 4's booster work, CONTRACTS\n"
        "## section 8.1). Both are spent through `PlayerState.try_spend_fuel`.\n"
        "const BOOST_FUEL := 3.0\n"
        "const DASH_FUEL := 25.0",
        "const ARRIVE_RADIUS := 40.0",
    ),
    # E4 _physics_process
    (
        "func _physics_process(delta: float) -> void:\n"
        + T + "_sync_hull_transform()\n"
        + T + "_update_boosters(delta)\n"
        + T + "_update_mining_laser()\n"
        + T + "_step_reactor(delta)\n"
        + T + "_update_fuel_cell()\n"
        + T + "_damage_quiet += delta\n"
        + T + "if _stats == null or _body == null:\n"
        + T + T + "return\n"
        "\n"
        + T + "## The stick is sampled raw: it is what cancels an autopilot order (section 3.1)\n"
        + T + "## and the reaction wheels keep answering it. Only the *thrust* is gated by ruling\n"
        + T + "## 14's lockout, so a dry tank still turns and still drifts (see `_thrust_locked`).\n"
        + T + "var stick := _manual_throttle()\n"
        + T + "var turn := _manual_turn()\n"
        + T + "if _has_move_target and (not is_zero_approx(stick) or not is_zero_approx(turn)):\n"
        + T + T + "cancel_orders()\n"
        + T + "if _has_move_target and global_position.distance_to(_move_target) <= ARRIVE_RADIUS:\n"
        + T + T + "cancel_orders()\n"
        "\n"
        + T + "var throttle := 0.0 if _thrust_locked() else stick\n"
        + T + "var desired_turn := 0.0\n"
        + T + "var desired_speed := 0.0\n"
        + T + "var rate := _coast_rate()\n"
        + T + "if _has_move_target:\n"
        + T + T + "desired_turn = _order_turn()\n"
        + T + T + "desired_speed = _order_speed()\n"
        + T + T + "## The autopilot commands thrust too, so ruling 14 locks it with the stick: a\n"
        + T + T + "## dry tank steers towards the order and coasts instead of accelerating.\n"
        + T + T + "if _thrust_locked():\n"
        + T + T + T + "desired_speed = 0.0\n"
        + T + T + "if absf(desired_speed) > absf(_velocity_along_heading()):\n"
        + T + T + T + "rate = _accel_rate()",
        "func _physics_process(delta: float) -> void:\n"
        + T + "_sync_hull_transform()\n"
        + T + "_update_boosters(delta)\n"
        + T + "_update_mining_laser()\n"
        + T + "_damage_quiet += delta\n"
        + T + "if _stats == null or _body == null:\n"
        + T + T + "return\n"
        "\n"
        + T + "var throttle := _manual_throttle()\n"
        + T + "var turn := _manual_turn()\n"
        + T + "if _has_move_target and (not is_zero_approx(throttle) or not is_zero_approx(turn)):\n"
        + T + T + "cancel_orders()\n"
        + T + "if _has_move_target and global_position.distance_to(_move_target) <= ARRIVE_RADIUS:\n"
        + T + T + "cancel_orders()\n"
        "\n"
        + T + "var desired_turn := 0.0\n"
        + T + "var desired_speed := 0.0\n"
        + T + "var rate := _coast_rate()\n"
        + T + "if _has_move_target:\n"
        + T + T + "desired_turn = _order_turn()\n"
        + T + T + "desired_speed = _order_speed()\n"
        + T + T + "if absf(desired_speed) > absf(_velocity_along_heading()):\n"
        + T + T + T + "rate = _accel_rate()",
    ),
    # E5 _thrust_locked
    (
        "func _manual_turn() -> float:\n"
        + T + "if not InputMap.has_action(TURN_RIGHT) or not InputMap.has_action(TURN_LEFT):\n"
        + T + T + "return 0.0\n"
        + T + "return Input.get_action_strength(TURN_RIGHT) - Input.get_action_strength(TURN_LEFT)\n"
        "\n"
        "\n"
        "## Ruling 14 / section 4.4: a dry tank is Emergency Flight Mode, which locks thrust\n"
        "## out. The ship drifts on the momentum the body already has and coasts it down at its\n"
        "## class coast rate, while the reaction wheels (`_manual_turn`) stay live. Read through\n"
        "## the state, so a hull that has not launched yet never locks its own controls.\n"
        "func _thrust_locked() -> bool:\n"
        + T + "return _state != null and _state.emergency_mode",
        "func _manual_turn() -> float:\n"
        + T + "if not InputMap.has_action(TURN_RIGHT) or not InputMap.has_action(TURN_LEFT):\n"
        + T + T + "return 0.0\n"
        + T + "return Input.get_action_strength(TURN_RIGHT) - Input.get_action_strength(TURN_LEFT)",
    ),
    # E6 booster burn + arm gate + _burn_boost_fuel
    (
        "func _update_boosters(delta: float) -> void:\n"
        + T + "if _boost_cooldown > 0.0:\n"
        + T + T + "_boost_cooldown = maxf(_boost_cooldown - delta, 0.0)\n"
        + T + "if _boost_remaining > 0.0:\n"
        + T + T + "_boost_remaining = maxf(_boost_remaining - delta, 0.0)\n"
        + T + T + "## Ruling 11 / section 13: the afterburner runs on the tank, BOOST_FUEL per\n"
        + T + T + "## second through the spending gate. A tank that cannot pay for the frame ends\n"
        + T + T + "## the burn at once, so a dry tank's afterburner dies the frame it runs dry\n"
        + T + T + "## instead of burning on credit.\n"
        + T + T + "if not _burn_boost_fuel(delta):\n"
        + T + T + T + "_boost_remaining = 0.0\n"
        + T + "if _boost_remaining > 0.0 or _boost_cooldown > 0.0:\n"
        + T + T + "return\n"
        + T + "if not has_booster(BOOSTER_AFTERBURNER):\n"
        + T + T + "return\n"
        + T + "if not InputMap.has_action(BOOST_ACTION) or not Input.is_action_pressed(BOOST_ACTION):\n"
        + T + T + "return\n"
        + T + "## The burn is charged *before* the afterburner lights: an empty tank refuses to arm\n"
        + T + "## it (ruling 14 locks boost out) and the arm frame pays its own share, so a lit\n"
        + T + "## afterburner has burned BOOST_FUEL for every frame it ran.\n"
        + T + "if not _burn_boost_fuel(delta):\n"
        + T + T + "return\n"
        + T + "var effect := _booster_effect(BOOSTER_AFTERBURNER)\n"
        + T + "_boost_remaining = float(effect.get(&\"duration\", 0.0))\n"
        + T + "_boost_cooldown = float(effect.get(&\"cooldown\", 0.0))\n"
        "\n"
        "\n"
        "## The afterburner's burn (ruling 11, section 13's BOOST_FUEL 3.0/s) through\n"
        "## `PlayerState.try_spend_fuel` -- the one gate boost and the dash share, so the tank\n"
        "## itself is the authority on whether a booster may run. A hull with no reactor yet (a\n"
        "## scene smoke test before `setup`) has no tank to bill and keeps the booster seam\n"
        "## working, exactly as `_manual_throttle` tolerates a missing input action.\n"
        "func _burn_boost_fuel(delta: float) -> bool:\n"
        + T + "if _state == null:\n"
        + T + T + "return true\n"
        + T + "return _state.try_spend_fuel(BOOST_FUEL * delta)",
        "func _update_boosters(delta: float) -> void:\n"
        + T + "if _boost_cooldown > 0.0:\n"
        + T + T + "_boost_cooldown = maxf(_boost_cooldown - delta, 0.0)\n"
        + T + "if _boost_remaining > 0.0:\n"
        + T + T + "_boost_remaining = maxf(_boost_remaining - delta, 0.0)\n"
        + T + "if _boost_remaining > 0.0 or _boost_cooldown > 0.0:\n"
        + T + T + "return\n"
        + T + "if not has_booster(BOOSTER_AFTERBURNER):\n"
        + T + T + "return\n"
        + T + "if not InputMap.has_action(BOOST_ACTION) or not Input.is_action_pressed(BOOST_ACTION):\n"
        + T + T + "return\n"
        + T + "var effect := _booster_effect(BOOSTER_AFTERBURNER)\n"
        + T + "_boost_remaining = float(effect.get(&\"duration\", 0.0))\n"
        + T + "_boost_cooldown = float(effect.get(&\"cooldown\", 0.0))",
    ),
    # E7 reactor tick + fuel cell, before _release_state
    (
        "## Section 4.4, and the contract pinned in CONTRACTS sections 4 and 8.1: the hull's\n"
        "## physics frame *is* the reactor's frame, so the refill (`energy_regen` at the\n"
        "## reactor's efficiency) and the fuel-cell cooldown advance here, once per physics\n"
        "## step, whatever the throttle is doing. Nothing else in the shipped game steps the\n"
        "## reactor, so without this call the two pools never refill in flight.\n"
        "func _step_reactor(delta: float) -> void:\n"
        + T + "if _state == null:\n"
        + T + T + "return\n"
        + T + "_state.tick(delta)\n"
        "\n"
        "\n"
        "## Section 11's `consume_fuel_cell` key is ruling 13's in-flight jerry can: one\n"
        "## `fuel_cell` cargo item becomes FUEL_CELL_UNITS of tank fuel, off cooldown, and it is\n"
        "## the only door out of Emergency Flight Mode in flight. Polled the way every other\n"
        "## one-shot in the shipped game is (game.gd reads its actions with the same call) and\n"
        "## guarded, so a hull on a build whose input map has not been patched behind it is\n"
        "## still safe. A refused burn -- cooling down, no cell aboard, tank already full -- is\n"
        "## a silent no-op: the fuel bar is the feedback.\n"
        "func _update_fuel_cell() -> void:\n"
        + T + "if _state == null:\n"
        + T + T + "return\n"
        + T + "if not InputMap.has_action(FUEL_CELL_ACTION):\n"
        + T + T + "return\n"
        + T + "if not Input.is_action_just_pressed(FUEL_CELL_ACTION):\n"
        + T + T + "return\n"
        + T + "_state.consume_fuel_cell()\n"
        "\n"
        "\n"
        "func _release_state() -> void:",
        "func _release_state() -> void:",
    ),
]

text = io.open(SRC, encoding="utf-8", newline="").read()
for i, (new, old) in enumerate(PAIRS, 1):
    if text.count(new) != 1:
        print("PAIR %d matched %d times -- abort" % (i, text.count(new)))
        sys.exit(1)
    text = text.replace(new, old)

io.open(OUT, "w", encoding="utf-8", newline="").write(text)
raw = text.encode("utf-8")
print("bytes:", len(raw))
print("lines:", text.count("\n") + 1)
print("md5:", hashlib.md5(raw).hexdigest())
print("want bytes 26093, want md5 de16ff6528a0...")
