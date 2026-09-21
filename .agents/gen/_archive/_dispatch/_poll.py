"""Poll a worker report/log pair until the report lands or the budget runs out.

Usage: py -3.14 .agents/gen/_dispatch/_poll.py <report> <log> [budget_seconds]
Exit 0 when the report exists, 2 on timeout. Prints the log tail either way.
"""
import io
import os
import sys
import time

# The Windows console is cp1250 here, so logs carrying arrows or deltas crash a
# plain print. Degrade unencodable glyphs instead of dying.
sys.stdout.reconfigure(errors="backslashreplace")

report = sys.argv[1]
log_path = sys.argv[2]
budget = float(sys.argv[3]) if len(sys.argv) > 3 else 300.0

started = time.time()
deadline = started + budget
while True:
    if os.path.exists(report):
        break
    if time.time() >= deadline:
        break
    time.sleep(10)

found = os.path.exists(report)
elapsed = int(time.time() - started)
print("report=%s found=%s after %ds" % (report, found, elapsed))

if os.path.exists(log_path):
    text = io.open(log_path, encoding="utf-8", errors="replace").read()
    print("--- log %d B ---" % len(text))
    print(text[-2000:])
else:
    print("log %s missing" % log_path)

sys.exit(0 if found else 2)
