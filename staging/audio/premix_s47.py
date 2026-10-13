"""Pre-mix the two S47 launch-sequence cue sources (AUDIO_SPEC §8.7 AUDIO-4/5).

Produces the two WAV sources that `build_audio.py`'s S27/S28 table rows encode:

* `sfx_station_undock_01.wav` (≤ 1.0 s) — §3's S4 layer recipe at 1:1: a Kenney
  Impact Sounds plate clunk pitched down 20 % plus a sub-thump cut from Kenney
  Sci-Fi Sounds' low-frequency explosion take, summed at equal RMS.
* `sfx_station_spool_loop.wav` (exactly 2.0 s) — Kenney Sci-Fi Sounds'
  `spaceEngineLow_003` cut to the window whose head/tail RMS difference is
  smallest, so the encoded loop's seam stays level-continuous.

Both sources are CC0 (Kenney); the derivation is recorded in the ENTRIES notes
and in `vajb-orbit/assets/audio/generation_log_audio.md` after the build.

Usage:
    staging/audio/.venv/bin/python staging/audio/premix_s47.py
"""

from __future__ import annotations

import numpy as np
import soundfile as sf
from pathlib import Path

LIB = Path(__file__).resolve().parents[2] / "asset-library"
OUT = LIB / "derived" / "s47"

CLUNK = "kenney-impact-sounds/Audio/impactPlate_heavy_000.ogg"
SUB = "kenney-sci-fi-sounds/Audio/lowFrequency_explosion_000.ogg"
BED = "kenney-sci-fi-sounds/Audio/spaceEngineLow_003.ogg"

PITCH = 0.8          # S4's 15-40 % down: 20 %
UNDOCK_MAX_S = 1.0   # AUDIO-4's cap
SPool_S = 2.0        # AUDIO-5's bed length


def read_mono(path: str) -> tuple[np.ndarray, int]:
    data, rate = sf.read(str(LIB / path), dtype="float32", always_2d=True)
    return data.mean(axis=1), rate


def trim_lead(x: np.ndarray, threshold_db: float = -40.0) -> np.ndarray:
    loud = np.where(np.abs(x) > 10.0 ** (threshold_db / 20.0))[0]
    return x[loud[0]:] if len(loud) else x


def rms(x: np.ndarray) -> float:
    return float(np.sqrt(np.mean(np.square(x)))) or 1e-9


def make_undock() -> None:
    clunk, rate = read_mono(CLUNK)
    n = int(len(clunk) / PITCH)
    clunk = np.interp(np.linspace(0, len(clunk) - 1, n), np.arange(len(clunk)), clunk).astype("float32")
    sub, _ = read_mono(SUB)
    sub = trim_lead(sub)[:n]
    if len(sub) < n:
        sub = np.pad(sub, (0, n - len(sub)))
    mix = clunk / rms(clunk) + sub / rms(sub)          # 1:1 (equal-RMS layers)
    peak = float(np.abs(mix).max())
    if peak > 0.891:                                    # -1 dBFS headroom
        mix *= 0.891 / peak
    keep = min(n, int(UNDOCK_MAX_S * rate))
    out = np.stack([mix[:keep], mix[:keep]], axis=1).astype("float32")
    (OUT / "sfx_station_undock_01.wav").parent.mkdir(parents=True, exist_ok=True)
    sf.write(str(OUT / "sfx_station_undock_01.wav"), out, rate, subtype="PCM_16")
    print(f"undock: {keep / rate:.3f} s (clunk {CLUNK} @x{PITCH} + sub {SUB}, equal-RMS 1:1)")


def make_spool() -> None:
    bed, rate = read_mono(BED)
    win = int(SPool_S * rate)
    span = int(0.05 * rate)
    best: tuple[float, int] = (1e9, 0)
    for start in range(0, len(bed) - win, span // 2):
        head = float(np.sqrt(np.mean(bed[start:start + span] ** 2)))
        tail = float(np.sqrt(np.mean(bed[start + win - span:start + win] ** 2)))
        delta = abs(20.0 * np.log10(max(head, 1e-9) / max(tail, 1e-9)))
        if delta < best[0]:
            best = (delta, start)
    cut = bed[best[1]:best[1] + win]
    out = np.stack([cut, cut], axis=1).astype("float32")
    sf.write(str(OUT / "sfx_station_spool_loop.wav"), out, rate, subtype="PCM_16")
    print(f"spool: 2.000 s from {BED} at {best[1] / rate:.2f} s (seam {best[0]:.2f} dB)")


if __name__ == "__main__":
    make_undock()
    make_spool()
