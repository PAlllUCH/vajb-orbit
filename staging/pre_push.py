#!/usr/bin/env python3
"""The repo's pre-push gate: audit, then the universal gate twice.

Installed into `.git/hooks/pre-push` by `staging/install_hooks.py` (the hook
file itself is host-local, this script is the versioned half). The push is
refused when the audit fails or the gate is not `failed=0`, byte-identical
across two runs, with zero `SCRIPT ERROR` lines - CONTRACTS section 9's law.

`VAJB_SKIP_GATE=1 git push ...` is the deliberate escape hatch; it prints a
warning and skips the gate (use only for a docs-only push during an incident).
"""

import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _run(label, cmd, capture=False):
    print("[pre-push] %s: %s" % (label, " ".join(cmd)), flush=True)
    result = subprocess.run(
        cmd,
        cwd=ROOT,
        stdout=subprocess.PIPE if capture else None,
        stderr=subprocess.STDOUT if capture else None,
        text=True,
    )
    if result.returncode != 0 and capture and result.stdout:
        print(result.stdout[-4000:], flush=True)
    return result.returncode


def main():
    if os.environ.get("VAJB_SKIP_GATE") == "1":
        print(
            "[pre-push] WARNING: VAJB_SKIP_GATE=1, the audit and the gate are skipped.",
            flush=True,
        )
        return 0
    if _run("audit", [sys.executable, "staging/code_audit.py"], capture=True) != 0:
        print("[pre-push] refused: the code audit failed.", flush=True)
        return 1
    if _run("gate", [sys.executable, "staging/gate.py", "--times", "2"]) != 0:
        print(
            "[pre-push] refused: zero failures is the law (CONTRACTS section 9).",
            flush=True,
        )
        return 1
    print("[pre-push] ok: audit clean, gate passed twice.", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
