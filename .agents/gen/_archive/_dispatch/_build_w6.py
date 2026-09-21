"""Point the W6 and W8 dispatches at their context files.

Both reviews carry the same long context, so the prompt holds a pointer and the
detail lives in `.agents/gen/slice2_w6_context.md` (a 9k prompt is rejected by
the Windows command line).
"""
import io

POINTER = (
    " ORCHESTRATOR ADDENDUM, 2026-09-21: before you start, read .agents/gen/slice2_w6_context.md. It is your pass's context file and it lists what each worker shipped with byte sizes, the five wiring items W2 flagged and W5 claimed to close, the exact spec rows to check the weapons/loot/brain/HUD tables against, the worker-reported spec gaps you must tier rather than assume, the two things that are explicitly NOT code findings (the assets re-layout and the UI chrome regression), the two other lanes that touched your subject matter, and the standing rulings. The universal gate is green at 200 tests right now: measure it yourself and record the real total in docs/CONTRACTS.md, because the brief's 53 and slice 0's 78 are both stale. You are the only writer of docs/CONTRACTS.md in this wave."
)

for src, dst in [(".agents/gen/_dispatch/slice2_w6.sh", ".agents/gen/_dispatch/slice2_w6_ruled.sh"),
                 (".agents/gen/_dispatch/slice2_w8.sh", ".agents/gen/_dispatch/slice2_w8_ruled.sh")]:
    text = io.open(src, encoding="utf-8").read()
    marker = '" \\'
    cut = text.rindex(marker)
    out = text[:cut] + POINTER + text[cut:]
    io.open(dst, "w", encoding="utf-8", newline="\n").write(out)
    print("%-42s %6d B -> %6d B" % (dst, len(text), len(out)))

print("pointer double quote:", '"' in POINTER)
