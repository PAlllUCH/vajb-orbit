#!/usr/bin/env python3
"""Universal test gate wrapper - CONTRACTS section 9's mechanical form.

Runs the pinned headless gate command and fails on:
  - a nonzero engine exit, a missing/duplicated [SUMMARY], or failed > 0
  - ANY "SCRIPT ERROR" line (T-183, closed 2026-10-12: a row that raises a
    runtime error mid-method still prints [PASS], so the engine's own counts
    are blind to it; the S41 close-out caught one only by reading the log by
    hand). Each error is attributed to the row line printed after it, which
    is the row whose execution raised it (a row's [PASS]/[FAIL] prints only
    after its method returns).

--times N (the close-out law is 2) repeats on a fresh scratch store per run
and additionally requires every [SUMMARY] line to be byte-identical.

The command wrapped is exactly CONTRACTS section 9's pin:

  $GODOT_CONSOLE --headless --path $VAJB_PROJ \
      res://tests/headless_runner.tscn --quit-after 1200

Stdlib only. `python3` on Linux, `py -3.14` on Windows.
"""

import argparse
import os
import re
import shutil
import subprocess
import sys
import tempfile

WORKSPACE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SUMMARY_RE = re.compile(r"\[SUMMARY\] passed=(\d+) failed=(\d+)")
ROW_PREFIXES = ("[PASS]", "[FAIL]", "[SKIP]")
RUN_TIMEOUT_SECONDS = 1200


def _godot_binary():
    """Same resolution order as verify_wave.py: env pins, then known hosts."""
    for env in ("VAJB_GODOT", "GODOT_CONSOLE"):
        override = os.environ.get(env)
        if override:
            return override
    windows = "C:/Godot_4_7_2/Godot_v4_7_2-stable_win64_console.exe"
    if os.path.exists(windows):
        return windows
    linux = os.path.expanduser("~/.local/bin/godot")
    if os.path.exists(linux):
        return linux
    return "godot"


def _project_dir():
    return os.environ.get("VAJB_PROJ", os.path.join(WORKSPACE, "vajb-orbit"))


def gate_cmd():
    return [
        _godot_binary(),
        "--headless",
        "--path",
        _project_dir(),
        "res://tests/headless_runner.tscn",
        "--quit-after",
        "1200",
    ]


def run_once(label):
    """One gate run on a fresh scratch store. Returns (ok, summary_line)."""
    env = dict(os.environ)
    scratch = None
    if os.name == "posix":
        # Hermetic scratch store (the WAVEBOARD law): user:// lands in a
        # throwaway dir. On Windows the runner's own CONTRACTS section 14
        # in-process sandbox is the isolation layer.
        scratch = tempfile.mkdtemp(prefix="vajb_gate_")
        env["XDG_DATA_HOME"] = scratch
    try:
        proc = subprocess.run(
            gate_cmd(),
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,  # merge: a SCRIPT ERROR (stderr) must
            # sit between the row lines around it for attribution to read
            # the true run order.
            text=True,
            cwd=WORKSPACE,
            timeout=RUN_TIMEOUT_SECONDS,
            env=env,
        )
    finally:
        if scratch is not None:
            shutil.rmtree(scratch, ignore_errors=True)

    log = proc.stdout.splitlines()
    problems = []

    summaries = [line for line in log if SUMMARY_RE.search(line)]
    if len(summaries) != 1:
        problems.append("expected exactly one [SUMMARY] line, found %d" % len(summaries))
        summary_line = "(no [SUMMARY])"
    else:
        summary_line = summaries[0].strip()
        failed = int(SUMMARY_RE.search(summary_line).group(2))
        if failed > 0:
            problems.append("failed rows: %d" % failed)
    if proc.returncode != 0:
        problems.append("engine exit code %d" % proc.returncode)

    script_errors = []
    for pos, line in enumerate(log):
        if "SCRIPT ERROR" not in line:
            continue
        context = "after suite load"
        for follow in log[pos + 1:]:
            if follow.startswith(ROW_PREFIXES):
                context = "inside %s" % follow
                break
        script_errors.append((line.strip(), context))
    for line, context in script_errors:
        print("[GATE] SCRIPT ERROR (%s): %s" % (context, line))
    if script_errors:
        problems.append("%d SCRIPT ERROR line(s)" % len(script_errors))

    ok = not problems
    print("[GATE] run %s: %s - %s" % (label, "ok" if ok else "FAIL", summary_line))
    for problem in problems:
        print("[GATE]   problem: %s" % problem)
    return ok, summary_line


def main():
    parser = argparse.ArgumentParser(
        description="Run the universal test gate (CONTRACTS section 9)."
    )
    parser.add_argument(
        "--times",
        type=int,
        default=1,
        help="run N times, each on a fresh scratch store; the close-out law is 2",
    )
    args = parser.parse_args()

    times = max(1, args.times)
    results = [run_once(i + 1) for i in range(times)]
    ok = all(result_ok for result_ok, _ in results)

    summary_lines = [line for _, line in results]
    if times > 1:
        if len(set(summary_lines)) != 1:
            ok = False
            print("[GATE] [SUMMARY] lines differ between runs:")
            for line in summary_lines:
                print("[GATE]   %s" % line)
        else:
            print("[GATE] %d runs byte-identical: %s" % (times, summary_lines[0]))

    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
