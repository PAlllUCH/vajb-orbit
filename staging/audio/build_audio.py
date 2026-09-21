"""Vajb Orbit - audio ingestion pipeline (AUDIO_SPEC.md).

Takes the raw CC0 sources downloaded into `asset-library/` and produces the
final, renamed files under `vajb-orbit/assets/audio/`.

Policy (see docs/design/AUDIO_SPEC.md, amendments in the audio phase log):
  * OGG sources are copied bit-exact (no re-encode, no quality loss).
  * WAV / FLAC / MP3 sources are encoded to Ogg Vorbis q5, peak-normalised to
    -1 dBFS (measurement-based, gain clamped to +/-12 dB) and, for one-shots,
    stripped of leading/trailing silence.
  * Every output is measured after the fact (duration, channels, sample rate,
    peak) and loop candidates get a seam-continuity QC (first vs last 50 ms
    RMS) so a closed loop can be verified without listening.

Usage:
    py -3.14 staging/audio/build_audio.py --list
    py -3.14 staging/audio/build_audio.py
    py -3.14 staging/audio/build_audio.py --only sfx_weapon_laser_01,ui_click
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

import imageio_ffmpeg
import numpy as np
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]
LIB = ROOT / "asset-library"
OUT = ROOT / "vajb-orbit" / "assets" / "audio"
REPORT = Path(__file__).resolve().parent / "audio_report.json"

FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()

CC0 = "CC0 1.0 Universal (public domain)"

# Pack provenance, keyed by the raw source folder name under asset-library/.
PACKS: dict[str, tuple[str, str]] = {
    "raw-audio-oga_yd_space_ambient": ("yd", "https://opengameart.org/content/i-swear-i-saw-it"),
    "raw-audio-oga_yd_industrial": ("yd", "https://opengameart.org/content/factory-ambiance"),
    "raw-audio-oga_combat_loops": ("Ville Nousiainen / XCVG", "https://opengameart.org/content/fast-fight-battle-music-looped"),
    "raw-audio-oga_nene_boss_metal": ("nene", "https://opengameart.org/content/boss-battle-9-metal"),
    "raw-audio-oga_subspaceaudio_horror": ("Juhani Junkala", "https://opengameart.org/content/horror-atmosphere"),
    "raw-audio-oga_tad_doomsday_laser": ("TAD", "https://opengameart.org/content/doomsday-laser-cannon"),
    "sci-fi-sfx": ("rubberduck", "https://opengameart.org/content/50-cc0-sci-fi-sfx"),
    "25-cc0-bang-sfx": ("OpenGameArt community", "https://opengameart.org/content/25-cc0-bang-firework-sfx"),
    "kenney_impact-sounds": ("Kenney", "https://kenney.nl/assets/impact-sounds"),
    "sfx_breaking_and_falling": ("OpenGameArt community", "https://opengameart.org/content/75-cc0-breaking-falling-hit-sfx"),
    "space-shield-sounds": ("bart", "https://opengameart.org/content/space-ship-shield-sounds"),
    "kenney_interface-sounds": ("Kenney", "https://kenney.nl/assets/interface-sounds"),
    "launch": ("qubodup", "https://opengameart.org/content/rocket-launch"),
    "projects": ("yd", "https://opengameart.org/content/background-space-track"),
    "raw-audio-oga_space_wind": ("OpenGameArt community", "https://opengameart.org/content/space-winds"),
    "raw-audio-oga_gmason_engine": ("gmason", "https://opengameart.org/content/underwater-or-space-engine-rumble"),
    "raw-audio-oga_ezduzziteh_thruster": ("EZduzziteh", "https://opengameart.org/content/thruster"),
    "raw-audio-oga_rocket_engine": ("OpenGameArt community", "https://opengameart.org/content/rocket-engine"),
    "raw-audio-oga_ship_floating": ("OpenGameArt community", "https://opengameart.org/content/space-ship-floating-sounds"),
    "sfx_loops": ("OpenGameArt community", "https://opengameart.org/content/30-cc0-sfx-loops"),
    "raw-audio-oga_bart_boiler_loop": ("bart", "https://opengameart.org/content/steam-boiler-sound-loop"),
    "raw-audio-oga_qubodup_device_loop": ("qubodup", "https://opengameart.org/content/electronic-device-loop"),
    "raw-audio-oga_machine_power_off": ("OpenGameArt community", "https://opengameart.org/content/machine-shutting-down"),
    "circuit-breaker": ("OpenGameArt community", "https://opengameart.org/content/sfx-circuit-breaker"),
    "raw-audio-oga_tree_creak": ("OpenGameArt community", "https://opengameart.org/content/tree-creaking"),
    "metal_interactions": ("OpenGameArt community", "https://opengameart.org/content/metal-interactions"),
    "deep_breaks": ("OpenGameArt community", "https://opengameart.org/content/deep-bone-crack-break-sfx"),
    "raw-audio-oga_monster_roar": ("OpenGameArt community", "https://opengameart.org/content/cc0-deep-monster-roar"),
    "horror_sfx": ("TinyWorlds", "https://opengameart.org/content/horror-sfx"),
    "raw-audio-oga_rumble_fx": ("OpenGameArt community", "https://opengameart.org/content/rumble-fx"),
    "dark_magic": ("OpenGameArt community", "https://opengameart.org/content/3-dark-magic-spells"),
    "raw-audio-oga_joth_space_sounds": ("Joth", "https://opengameart.org/content/7-space-sounds"),
    "raw-audio-oga_jordan4ibanez_mining": ("jordan4ibanez", "https://opengameart.org/content/mining-sample"),
    "raw-audio-oga_qubodup_energy_loop": ("qubodup", "https://opengameart.org/content/seamless-energy-emission-loop"),
}

# (source relative to asset-library, destination relative to assets/audio,
#  mode, quality, loops, trim silence, cue note)
# mode: copy = OGG passthrough, encode = transcode to Ogg Vorbis
E = "encode"
C = "copy"

ENTRIES: list[tuple[str, str, str, int, bool, bool, str]] = [
    # ---- music (M1-M5) -------------------------------------------------
    ("raw-audio-oga_yd_space_ambient/iswearisawit_0.ogg", "music/mus_menu_theme_01.ogg", C, 0, True, False, "M1 main menu theme"),
    ("raw-audio-oga_yd_industrial/factory.ogg", "music/mus_exploration_ambient_01.ogg", C, 0, True, False, "M2 exploration bed"),
    ("raw-audio-oga_subspaceaudio_horror/juhani-junkala-post-apocalyptic-wastelands-loop-ready-.ogg", "music/mus_exploration_dread_01.ogg", C, 0, True, False, "M5 dread bed (advertises seamless loop)"),
    ("raw-audio-oga_combat_loops/fight_looped.wav", "music/mus_combat_loop_01.ogg", E, 6, True, False, "M3 combat loop"),
    ("raw-audio-oga_nene_boss_metal/boss_battle_9_metal_opening.wav", "music/mus_boss_metal_01_opening.ogg", E, 6, False, False, "M4 boss one-shot opening"),
    ("raw-audio-oga_nene_boss_metal/boss_battle_9_metal_loop.wav", "music/mus_boss_metal_01_loop.ogg", E, 6, True, False, "M4 boss loop"),
    # ---- weapons (S1-S3) -----------------------------------------------
    ("sci-fi-sfx/shoot_01.ogg", "sfx/sfx_weapon_laser_01.ogg", C, 0, False, False, "S1 laser round-robin 1/4"),
    ("sci-fi-sfx/shoot_02.ogg", "sfx/sfx_weapon_laser_02.ogg", C, 0, False, False, "S1 laser round-robin 2/4"),
    ("sci-fi-sfx/retro_laser_01.ogg", "sfx/sfx_weapon_laser_03.ogg", C, 0, False, False, "S1 laser round-robin 3/4"),
    ("sci-fi-sfx/retro_laser_02.ogg", "sfx/sfx_weapon_laser_04.ogg", C, 0, False, False, "S1 laser round-robin 4/4"),
    ("raw-audio-oga_tad_doomsday_laser/doomsday_laser_cannon_short.wav", "sfx/sfx_weapon_cannon_01.ogg", E, 5, False, True, "S2 heavy cannon, tier 1 (short turret burst)"),
    ("raw-audio-oga_tad_doomsday_laser/doomsday_laser_cannon_midium_.wav", "sfx/sfx_weapon_cannon_02_medium.ogg", E, 5, False, True, "S2 heavy cannon tier 2"),
    ("raw-audio-oga_tad_doomsday_laser/doomsday_laser_cannon_long.wav", "sfx/sfx_weapon_cannon_03_long.ogg", E, 5, False, True, "S2 heavy cannon tier 3"),
    ("sci-fi-sfx/rocket_01.ogg", "sfx/sfx_weapon_rocket_01.ogg", C, 0, False, False, "S3 rocket launch layer"),
    ("25-cc0-bang-sfx/bang_04.ogg", "sfx/sfx_weapon_rocket_02_warhead.ogg", C, 0, False, False, "S3 warhead layer (+80 ms offset in code)"),
    ("sci-fi-sfx/explosion_01.ogg", "sfx/sfx_weapon_explosion_01.ogg", C, 0, False, False, "explosion pool 1/2"),
    ("sci-fi-sfx/explosion_02.ogg", "sfx/sfx_weapon_explosion_02.ogg", C, 0, False, False, "explosion pool 2/2"),
    # ---- impacts and shields (S4-S6) -----------------------------------
    ("sfx_breaking_and_falling/bfh1_rock_breaking_01.ogg", "sfx/sfx_impact_rock_01.ogg", C, 0, False, False, "S4 asteroid impact 1/4"),
    ("sfx_breaking_and_falling/bfh1_rock_breaking_02.ogg", "sfx/sfx_impact_rock_02.ogg", C, 0, False, False, "S4 asteroid impact 2/4"),
    ("sfx_breaking_and_falling/bfh1_rock_breaking_03.ogg", "sfx/sfx_impact_rock_03.ogg", C, 0, False, False, "S4 asteroid impact 3/4"),
    ("sfx_breaking_and_falling/bfh1_rock_hit_01.ogg", "sfx/sfx_impact_rock_04.ogg", C, 0, False, False, "S4 asteroid impact 4/4"),
    ("kenney_impact-sounds/Audio/impactMetal_heavy_000.ogg", "sfx/sfx_impact_hull_01.ogg", C, 0, False, False, "S4 hull impact 1/4"),
    ("kenney_impact-sounds/Audio/impactMetal_heavy_001.ogg", "sfx/sfx_impact_hull_02.ogg", C, 0, False, False, "S4 hull impact 2/4"),
    ("kenney_impact-sounds/Audio/impactMetal_heavy_002.ogg", "sfx/sfx_impact_hull_03.ogg", C, 0, False, False, "S4 hull impact 3/4"),
    ("kenney_impact-sounds/Audio/impactMetal_heavy_003.ogg", "sfx/sfx_impact_hull_04.ogg", C, 0, False, False, "S4 hull impact 4/4"),
    ("kenney_impact-sounds/Audio/impactPlate_medium_000.ogg", "sfx/sfx_impact_hull_05.ogg", C, 0, False, False, "S4 hull impact 5/5 (plate ring)"),
    ("space-shield-sounds/space shield sounds - 1.wav", "sfx/sfx_impact_shield_hit_01.ogg", E, 5, False, True, "S5 shield hit 1/9"),
    ("space-shield-sounds/space shield sounds - 2.wav", "sfx/sfx_impact_shield_hit_02.ogg", E, 5, False, True, "S5 shield hit 2/9"),
    ("space-shield-sounds/space shield sounds - 3.wav", "sfx/sfx_impact_shield_hit_03.ogg", E, 5, False, True, "S5 shield hit 3/9"),
    ("space-shield-sounds/space shield sounds - 4.wav", "sfx/sfx_impact_shield_hit_04.ogg", E, 5, False, True, "S5 shield hit 4/9"),
    ("space-shield-sounds/space shield sounds - 5.wav", "sfx/sfx_impact_shield_hit_05.ogg", E, 5, False, True, "S5 shield hit 5/9"),
    ("space-shield-sounds/space shield sounds - 6.wav", "sfx/sfx_impact_shield_hit_06.ogg", E, 5, False, True, "S5 shield hit 6/9"),
    ("space-shield-sounds/space shield sounds - 7.wav", "sfx/sfx_impact_shield_hit_07.ogg", E, 5, False, True, "S5 shield hit 7/9"),
    ("space-shield-sounds/space shield sounds - 8.wav", "sfx/sfx_impact_shield_hit_08.ogg", E, 5, False, True, "S5 shield hit 8/9"),
    ("space-shield-sounds/space shield sounds - 9.wav", "sfx/sfx_impact_shield_hit_09.ogg", E, 5, False, True, "S5 shield hit 9/9"),
    ("raw-audio-oga_qubodup_energy_loop/movingshield_sound.ogg", "sfx/sfx_impact_shield_loop_01.ogg", C, 0, True, False, "S6 shield-up hum (advertises seamless loop)"),
    # ---- mining (S7-S8) ------------------------------------------------
    ("raw-audio-oga_qubodup_energy_loop/movingshield_sound.ogg", "sfx/sfx_mining_beam_01.ogg", C, 0, True, False, "S7 beam bed (same loop as S6, pitched per tier in code)"),
    ("kenney_impact-sounds/Audio/impactMining_000.ogg", "sfx/sfx_mining_chip_01.ogg", C, 0, False, False, "S8 chip transient 1/4"),
    ("kenney_impact-sounds/Audio/impactMining_001.ogg", "sfx/sfx_mining_chip_02.ogg", C, 0, False, False, "S8 chip transient 2/4"),
    ("kenney_impact-sounds/Audio/impactMining_002.ogg", "sfx/sfx_mining_chip_03.ogg", C, 0, False, False, "S8 chip transient 3/4"),
    ("raw-audio-oga_jordan4ibanez_mining/mining_1.ogg", "sfx/sfx_mining_chip_04.ogg", C, 0, False, False, "S8 chip transient 4/4"),
    # ---- UI (S9-S10) ---------------------------------------------------
    ("kenney_interface-sounds/Audio/click_001.ogg", "ui/ui_click.ogg", C, 0, False, False, "S9 UI click (primary, exact name the AudioManager resolves)"),
    ("kenney_interface-sounds/Audio/click_002.ogg", "ui/ui_click_02.ogg", C, 0, False, False, "S9 UI click pool 2/5"),
    ("kenney_interface-sounds/Audio/click_003.ogg", "ui/ui_click_03.ogg", C, 0, False, False, "S9 UI click pool 3/5"),
    ("kenney_interface-sounds/Audio/click_004.ogg", "ui/ui_click_04.ogg", C, 0, False, False, "S9 UI click pool 4/5"),
    ("kenney_interface-sounds/Audio/click_005.ogg", "ui/ui_click_05.ogg", C, 0, False, False, "S9 UI click pool 5/5"),
    ("kenney_interface-sounds/Audio/select_001.ogg", "ui/ui_hover.ogg", C, 0, False, False, "S10 UI hover (primary)"),
    ("kenney_interface-sounds/Audio/select_002.ogg", "ui/ui_hover_02.ogg", C, 0, False, False, "S10 UI hover pool 2/3"),
    ("kenney_interface-sounds/Audio/select_003.ogg", "ui/ui_hover_03.ogg", C, 0, False, False, "S10 UI hover pool 3/3"),
    ("kenney_interface-sounds/Audio/scroll_001.ogg", "ui/ui_scroll_01.ogg", C, 0, False, False, "S10 menu scroll"),
    ("kenney_interface-sounds/Audio/error_004.ogg", "ui/ui_denied_01.ogg", C, 0, False, False, "S10 denied / blocked action"),
    ("kenney_interface-sounds/Audio/confirmation_002.ogg", "ui/ui_confirm_01.ogg", C, 0, False, False, "S10 confirmation"),
    # ---- ship, jump, engines (S11-S12, S16) ----------------------------
    ("sci-fi-sfx/teleport_01.ogg", "sfx/sfx_ship_jump_01.ogg", C, 0, False, False, "S11 teleport / jump 1/2"),
    ("sci-fi-sfx/teleport_02.ogg", "sfx/sfx_ship_jump_02.ogg", C, 0, False, False, "S11 teleport / jump 2/2"),
    ("launch/launch/launch.wav", "sfx/sfx_ship_boost_01.ogg", E, 5, False, True, "S12 boost / take-off"),
    ("raw-audio-oga_ezduzziteh_thruster/space_ship_0.ogg", "sfx/sfx_ship_engine_01.ogg", C, 0, True, False, "S16 thruster bed 1/2"),
    ("raw-audio-oga_rocket_engine/rocket_engine.001.wav", "sfx/sfx_ship_engine_02_loop.ogg", E, 5, True, False, "S16 thruster bed 2/2"),
    # ---- station machinery and failure (S18-S20) -----------------------
    ("sfx_loops/machine_01.ogg", "sfx/sfx_station_machine_loop_01.ogg", C, 0, True, False, "S18 machine loop 1/3"),
    ("sfx_loops/machine_02.ogg", "sfx/sfx_station_machine_loop_02.ogg", C, 0, True, False, "S18 machine loop 2/3"),
    ("sfx_loops/machine_03.ogg", "sfx/sfx_station_machine_loop_03.ogg", C, 0, True, False, "S18 machine loop 3/3"),
    ("raw-audio-oga_bart_boiler_loop/generator_loop.wav", "sfx/sfx_station_boiler_loop_01.ogg", E, 5, True, False, "S18 boiler body layer"),
    ("raw-audio-oga_qubodup_device_loop/qubodup-edev.flac", "sfx/sfx_station_hum_loop_01.ogg", E, 5, True, False, "S18 electrical hum layer"),
    ("raw-audio-oga_machine_power_off/machinepoweroff.ogg", "sfx/sfx_station_power_off_01.ogg", C, 0, False, False, "S19 blackout event"),
    ("circuit-breaker/switch on.wav", "sfx/sfx_station_breaker_on_01.ogg", E, 5, False, True, "S19 breaker ON"),
    ("circuit-breaker/switch off.wav", "sfx/sfx_station_breaker_off_01.ogg", E, 5, False, True, "S19 breaker OFF"),
    ("raw-audio-oga_tree_creak/tree_creak_0.ogg", "sfx/sfx_station_hull_groan_01.ogg", C, 0, False, False, "S20 hull groan body (pitch 0.6-0.8 in code)"),
    ("metal_interactions/metal_interactions/metal_interaction1.wav", "sfx/sfx_station_hull_ring_01.ogg", E, 5, False, True, "S20 metal ring layer 1/3"),
    ("metal_interactions/metal_interactions/metal_interaction2.wav", "sfx/sfx_station_hull_ring_02.ogg", E, 5, False, True, "S20 metal ring layer 2/3"),
    ("metal_interactions/metal_interactions/metal_button_press1.wav", "sfx/sfx_station_hull_ring_03.ogg", E, 5, False, True, "S20 metal ring layer 3/3"),
    ("deep_breaks/Deep Break 1.wav", "sfx/sfx_station_hull_crack_01.ogg", E, 5, False, True, "S20 fracture layer (low-pass 120 Hz in code)"),
    ("deep_breaks/Deep Break 2.wav", "sfx/sfx_station_hull_crack_02.ogg", E, 5, False, True, "S20 fracture layer 2"),
    ("deep_breaks/Deep Break 3.wav", "sfx/sfx_station_hull_crack_03.ogg", E, 5, False, True, "S20 fracture layer 3"),
    # ---- stingers (S21-S24) --------------------------------------------
    ("raw-audio-oga_monster_roar/monster_roar.wav", "sfx/sfx_stinger_boss_roar_01.ogg", E, 5, False, True, "S21 boss arrival"),
    ("horror_sfx/horror_effect1.wav", "sfx/sfx_stinger_scare_01.ogg", E, 5, False, True, "S22 scare stab 1/2"),
    ("horror_sfx/horror_effect2.wav", "sfx/sfx_stinger_scare_02.ogg", E, 5, False, True, "S22 scare stab 2/2"),
    ("raw-audio-oga_rumble_fx/rumble.wav", "sfx/sfx_stinger_rumble_pass_01.ogg", E, 5, False, False, "S23 something huge is near"),
    ("dark_magic/dark_magic/fout-01.flac", "sfx/sfx_stinger_anomaly_01.ogg", E, 5, False, True, "S24 anomaly stinger 1/3"),
    ("dark_magic/dark_magic/fout-02.flac", "sfx/sfx_stinger_anomaly_02.ogg", E, 5, False, True, "S24 anomaly stinger 2/3"),
    ("dark_magic/dark_magic/fout-03.flac", "sfx/sfx_stinger_anomaly_03.ogg", E, 5, False, True, "S24 anomaly stinger 3/3"),
    # ---- ambience (S13-S15, S17) ---------------------------------------
    ("projects/MyVeryOwnDeadShip.ogg", "ambience/amb_space_drone_01.ogg", C, 0, True, False, "S13 dead-ship sector drone"),
    ("raw-audio-oga_space_wind/space-wind_0.mp3", "ambience/amb_space_wind_01.ogg", E, 5, True, False, "S14 open-space wind bed"),
    ("raw-audio-oga_gmason_engine/underwater_or_space_engine_0.ogg", "ambience/amb_space_rumble_01.ogg", C, 0, True, False, "S15 capital-ship rumble"),
    ("raw-audio-oga_gmason_engine/deep_rumble.ogg", "ambience/amb_space_rumble_02.ogg", C, 0, True, False, "S15 deep rumble"),
    ("raw-audio-oga_ship_floating/space_ship_floating_sound_1.mp3", "ambience/amb_space_float_01.ogg", E, 5, True, False, "S17 floating ambience 1/2"),
    ("raw-audio-oga_ship_floating/space_ship_floating_sound.mp3", "ambience/amb_space_float_02.ogg", E, 5, True, False, "S17 floating ambience 2/2"),
    ("sfx_loops/ambient_01.ogg", "ambience/amb_station_room_01.ogg", C, 0, True, False, "S25 station room tone 1/3"),
    ("sfx_loops/ambient_02.ogg", "ambience/amb_station_room_02.ogg", C, 0, True, False, "S25 station room tone 2/3"),
    ("sfx_loops/ambient_03.ogg", "ambience/amb_station_room_03.ogg", C, 0, True, False, "S25 station room tone 3/3"),
    ("sfx_loops/pump_01.ogg", "ambience/amb_station_pump_loop_01.ogg", C, 0, True, False, "station machinery room bed"),
    ("sfx_loops/noise_01.ogg", "ambience/amb_station_noise_loop_01.ogg", C, 0, True, False, "station static bed"),
    ("raw-audio-oga_joth_space_sounds/7-space-sounds_1.mp3", "ambience/amb_space_misc_01.ogg", E, 5, False, False, "space cue pool (cut on silence, AUDIO_SPEC 8.4)"),
]

# Multi-cue source files that must be cut on their silence boundaries.
# The count is what the silence analysis actually finds; the OGA page copy is not
# authoritative (it advertises 7 cues, only 5 are separated by silence).
SPLIT_SOURCES = {
    "raw-audio-oga_joth_space_sounds/7-space-sounds_1.mp3": ("ambience/amb_space_misc_%02d.ogg", 5),
}
SPLIT_NOISE = "-40dB"
SPLIT_MIN_GAP = 0.12
SEAM_REPAIR_THRESHOLD_DB = 3.0


def run(args: list[str], capture: bool = True) -> str:
    proc = subprocess.run([FFMPEG, "-hide_banner", *args], capture_output=capture, text=True, errors="replace")
    if proc.returncode != 0:
        raise RuntimeError(f"ffmpeg failed ({proc.returncode}): {' '.join(args)}\n{proc.stderr[-800:]}")
    return (proc.stderr or "") + (proc.stdout or "")


def duration_of(path: Path) -> float:
    try:
        return float(sf.info(str(path)).duration)
    except Exception:
        return -1.0


def peak_db(path: Path) -> float:
    out = run(["-i", str(path), "-af", "volumedetect", "-f", "null", "-"])
    match = re.search(r"max_volume:\s*(-?[\d.]+) dB", out)
    return float(match.group(1)) if match else 0.0


def seam_delta_db(path: Path, window_ms: int = 50) -> float:
    """Level difference between the first and last window of a loop candidate."""
    try:
        data, rate = sf.read(str(path), dtype="float32", always_2d=True)
    except Exception:
        return -1.0
    span = max(1, int(rate * window_ms / 1000))
    if len(data) < span * 2:
        return -1.0
    head = float(np.sqrt(np.mean(np.square(data[:span]))))
    tail = float(np.sqrt(np.mean(np.square(data[-span:]))))
    if head <= 1e-9 or tail <= 1e-9:
        return 99.0
    return abs(20.0 * np.log10(head / tail))


def encode(src: Path, dest: Path, quality: int, trim: bool) -> None:
    filters: list[str] = []
    if trim:
        filters.append("silenceremove=start_periods=1:start_duration=0.02:start_threshold=-50dB")
        filters.append("areverse,silenceremove=start_periods=1:start_duration=0.02:start_threshold=-50dB,areverse")
    src_peak = peak_db(src)
    gain = max(-12.0, min(12.0, -1.0 - src_peak))
    filters.append(f"volume={gain:.2f}dB")
    dest.parent.mkdir(parents=True, exist_ok=True)
    run([
        "-y", "-i", str(src),
        "-af", ",".join(filters),
        "-c:a", "libvorbis", "-q:a", str(quality),
        str(dest),
    ])


def copy(src: Path, dest: Path) -> None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    run(["-y", "-i", str(src), "-c:a", "copy", str(dest)])


def split_source(rel: str, template: str, expect: int) -> list[tuple[Path, int]]:
    """Cut a multi-cue file on silence into its audible runs. Returns (tmp_path, index) pairs.

    A cue is the audio between one silence end and the next silence start, so cues
    carry no leading or trailing dead air.
    """
    src = LIB / rel
    out = run(["-i", str(src), "-af", f"silencedetect=noise={SPLIT_NOISE}:d={SPLIT_MIN_GAP}", "-f", "null", "-"])
    starts = [float(m) for m in re.findall(r"silence_start:\s*([\d.]+)", out)]
    ends = [float(m) for m in re.findall(r"silence_end:\s*([\d.]+)", out)]
    total = duration_of(src)
    if total <= 0:
        raise RuntimeError(f"cannot read duration of {src}")
    boundaries = list(zip(starts, ends))
    segments: list[tuple[float, float]] = []
    for index in range(len(boundaries) - 1):
        lo = boundaries[index][1]
        hi = boundaries[index + 1][0]
        if hi - lo >= 0.15:
            segments.append((lo, hi))
    if len(segments) != expect:
        print(f"  ! silence split found {len(segments)} segments (page advertises {expect})", file=sys.stderr)
    produced: list[tuple[Path, int]] = []
    tmp = Path(__file__).resolve().parent / "_split"
    tmp.mkdir(parents=True, exist_ok=True)
    for index, (lo, hi) in enumerate(segments, start=1):
        target = tmp / (template % index).replace("/", "_")
        run(["-y", "-ss", f"{lo:.3f}", "-to", f"{hi:.3f}", "-i", str(src),
             "-c:a", "libvorbis", "-q:a", "5", str(target)])
        produced.append((target, index))
    return produced


def loop_repair(path: Path, cross_s: float = 2.0, quiet_db: float = -50.0) -> dict:
    """Make a faded- or dead-air-ended bed loopable.

    Trims dead air from both ends, then crossfades the tail into the head so the
    loop point is level-continuous (the source tail's fade becomes part of the head
    instead of collapsing to silence at the seam).

    The blend is staged through a temporary PCM file and re-encoded by ffmpeg, then
    atomically swapped in: writing Vorbis straight over the source in one pass leaves
    a truncated file behind if anything dies mid-encode.
    """
    data, rate = sf.read(str(path), dtype="float32", always_2d=True)
    if len(data) == 0:
        return {"repaired": False, "reason": "source file has no frames"}
    envelope = np.max(np.abs(data), axis=1)
    loud = np.where(envelope > 10.0 ** (quiet_db / 20.0))[0]
    if len(loud) == 0:
        return {"repaired": False, "reason": "whole file is below the silence threshold"}
    info: dict = {"repaired": False}
    head_trim, tail_trim = int(loud[0]), len(data) - 1 - int(loud[-1])
    trimmed = False
    if head_trim or tail_trim:
        data = data[loud[0]:loud[-1] + 1].copy()
        info["trimmed_lead_s"] = round(head_trim / rate, 3)
        info["trimmed_tail_s"] = round(tail_trim / rate, 3)
        trimmed = True
    span = min(int(cross_s * rate), int(0.05 * len(data)))
    if span < 64:
        info["reason"] = "too short to crossfade"
        return info
    weight = np.linspace(0.0, 1.0, span, dtype="float32")[:, None]
    tail_block = data[len(data) - span:].copy()
    body = data[: len(data) - span].copy()
    body[:span] = data[:span] * weight + tail_block * (1.0 - weight)
    del data, tail_block, envelope
    staging = path.with_name(path.stem + ".prep.wav")
    encoded = path.with_name(path.stem + ".tmp.ogg")
    sf.write(str(staging), body, rate, subtype="PCM_16")
    del body
    run(["-y", "-i", str(staging), "-c:a", "libvorbis", "-q:a", "5", str(encoded)])
    staging.unlink(missing_ok=True)
    encoded.replace(path)
    info.update({"repaired": True, "trimmed": trimmed, "crossfade_s": round(span / rate, 3),
                 "length_s": round(sf.info(str(path)).duration, 3)})
    return info


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--list", action="store_true")
    parser.add_argument("--only", default="")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    if args.list:
        for src, dest, mode, quality, loops, trim, note in ENTRIES:
            exists = "ok " if (LIB / src).exists() else "MISSING"
            print(f"{exists} {mode:6} q{quality} {'loop' if loops else '    '} {dest:46} <- {src}  # {note}")
        return 0

    wanted = {name.strip() for name in args.only.split(",") if name.strip()}
    report: list[dict] = []
    failures: list[str] = []

    for src, dest, mode, quality, loops, trim, note in ENTRIES:
        stem = Path(dest).stem
        if wanted and stem not in wanted:
            continue
        source = LIB / src
        target = OUT / dest
        if not source.exists():
            failures.append(f"missing source: {src}")
            print(f"MISSING {src}")
            continue
        print(f"{mode:6} {dest}")
        if args.dry_run:
            continue
        if src in SPLIT_SOURCES:
            template, expect = SPLIT_SOURCES[src]
            produced = split_source(src, template, expect)
            for tmp_path, index in produced:
                final = OUT / (template % index)
                copy(tmp_path, final)
                split_note = f"{note.split(' (cut')[0]}, cue {index}/{len(produced)} cut on silence (AUDIO_SPEC 8.4)"
                report.append(qc(final, src, split_note, False, "copy"))
            continue
        try:
            if mode == C:
                copy(source, target)
            else:
                encode(source, target, quality, trim)
        except RuntimeError as exc:
            failures.append(f"{dest}: {exc}")
            print(f"  ! {exc}")
            continue
        entry = qc(target, src, note, loops, mode)
        if loops and entry["seam_delta_db"] > SEAM_REPAIR_THRESHOLD_DB:
            before = entry["seam_delta_db"]
            prep = loop_repair(target)
            after = round(seam_delta_db(target), 2)
            if prep.get("repaired") and after >= before:
                # The blend made the seam worse (usually a decaying one-shot rather than a
                # bed), so the untouched conversion is the better artefact: restore it.
                if mode == C:
                    copy(source, target)
                else:
                    encode(source, target, quality, trim)
                after = round(seam_delta_db(target), 2)
                prep["reverted"] = True
            entry["seam_before_db"] = before
            entry["loop_prep"] = prep
            entry["seam_delta_db"] = after
            entry["duration_s"] = round(sf.info(str(target)).duration, 3)
            entry["size_bytes"] = target.stat().st_size
            if prep.get("repaired") and not prep.get("reverted"):
                entry["mode"] = "loopfix"
            print(f"  loop-prep {before} dB -> {after} dB {prep}")
        report.append(entry)
    if not args.dry_run:
        REPORT.write_text(json.dumps(report, indent=2), encoding="utf-8")
        write_log(report)
    if failures:
        print("\nFAILURES:")
        for line in failures:
            print(f"  - {line}")
        return 1
    print(f"\n{len(report)} files written to {OUT}")
    return 0


def qc(path: Path, src: str, note: str, loops: bool, mode: str) -> dict:
    info = sf.info(str(path))
    entry = {
        "dest": str(path.relative_to(OUT.parent.parent)).replace("\\", "/"),
        "source": src,
        "note": note,
        "mode": mode,
        "loops": loops,
        "duration_s": round(info.duration, 3),
        "channels": info.channels,
        "samplerate": info.samplerate,
        "size_bytes": path.stat().st_size,
    }
    if loops:
        entry["seam_delta_db"] = round(seam_delta_db(path), 2)
    pack = src.split("/")[0]
    author, url = PACKS.get(pack, ("unknown", ""))
    entry["author"] = author
    entry["source_url"] = url
    entry["license"] = CC0
    return entry


def write_log(report: list[dict]) -> None:
    lines = [
        "# Audio generation log",
        "",
        "Generated by `staging/audio/build_audio.py` from the CC0 sources downloaded into",
        "`asset-library/` (see `asset-library/ASSET_MANIFEST.json` for checksums). Every entry",
        "below is CC0 1.0: public domain, no attribution required, none kept here only because",
        "the project credits policy rebuilds provenance after import.",
        "",
        "Policy: OGG sources pass through bit-exact; WAV/FLAC/MP3 sources are encoded to Ogg",
        "Vorbis (music q6, everything else q5) with measurement-based peak normalisation to",
        "-1 dBFS and silence trimming on one-shots. `seam` is the level difference between the",
        "first and last 50 ms of a loop: a small number means the seam is level-continuous.",
        "Loop candidates whose seam exceeded 3 dB were loop-prepared (dead air trimmed, tail",
        "crossfaded into the head); `seam was` shows the before value for those.",
        "",
        "| File | Cue | Source pack | Author | Mode | Len s | Ch | Hz | seam dB | seam was |",
        "|---|---|---|---|---|---|---|---|---|---|",
    ]
    for entry in sorted(report, key=lambda item: entry_key(item)):
        seam = entry.get("seam_delta_db")
        lines.append(
            "| `{dest}` | {note} | {pack} | {author} | {mode} | {duration_s} | {channels} | {samplerate} | {seam} | {before} |".format(
                dest=entry["dest"].replace("vajb-orbit/assets/", "res://assets/"),
                note=entry["note"],
                pack=entry["source"].split("/")[0],
                author=entry["author"],
                mode=entry["mode"],
                duration_s=entry["duration_s"],
                channels=entry["channels"],
                samplerate=entry["samplerate"],
                seam=("-" if seam is None else seam),
                before=entry.get("seam_before_db", "-"),
            )
        )
    lines += ["", "## Source URLs", ""]
    for pack, (author, url) in sorted(PACKS.items()):
        lines.append(f"- **{pack}** - {author} - {url} - {CC0}")
    (OUT / "generation_log_audio.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


def entry_key(entry: dict) -> tuple[str, str]:
    return (entry["dest"].split("/")[-2], entry["dest"])


if __name__ == "__main__":
    sys.exit(main())
