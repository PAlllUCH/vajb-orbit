"""Rebuild the W5 dispatch short enough for the Windows command line.

The full addendum went to `.agents/gen/slice2_w5_context.md` instead, because a
9794-byte prompt came back as "The command line is too long."; the prompt now
carries a pointer to that file.
"""
import io

SRC = ".agents/gen/_dispatch/slice2_w5.sh"
DST = ".agents/gen/_dispatch/slice2_w5_ruled.sh"

pointer = (
    " ORCHESTRATOR ADDENDUM, 2026-09-21: before you start, read .agents/gen/slice2_w5_context.md. It is your pass's context file and it carries the state the four parallel workers left, the five wiring items W2 measured but could not close, what W3 shipped to mount, the spec gaps W3 reported rather than invented, the two lanes touching files near yours including a batch-2 change to hud.gd you must keep, and the standing rulings from the owner. Then follow your brief and this prompt. The universal gate is green at 168 tests right now: measure the total yourself and keep it green."
)

text = io.open(SRC, encoding="utf-8").read()
marker = '" \\'
cut = text.rindex(marker)
out = text[:cut] + pointer + text[cut:]
io.open(DST, "w", encoding="utf-8", newline="\n").write(out)

print("src %d B -> dst %d B" % (len(text), len(out)))
print("double quote in pointer:", '"' in pointer)
