# D24_prompts — the dispatch blocks (P4 opener: the station-overhaul design round)

Run the snapshot + commit line FIRST, then dispatch in order. One live session
per workspace; every worker runs `VAJB_SLIM=1`.

```bash
# before the first dispatch
python3 staging/verify_wave.py snapshot --name d24_start && \
  git add -A && git commit -m "Open the D24 station-overhaul design round"
```

## D24-A1 — the designer (very demanding: hyper/glm-5.3 @ high)

```bash
VAJB_SLIM=1 \
VAJB_WORKER_FILES="docs/design/STATION_HUB.md,docs/design/UI_SPEC.md,docs/design/AUDIO_SPEC.md,docs/gameplay/04_refinery.md,docs/gameplay/07_crafting.md,docs/gameplay/03_components.md,docs/gameplay/10_ship_acquisition.md" \
crush run --model hyper/glm-5.3 \
"Read .agents/gen/slices/D24-station-overhaul-design/D24_BRIEF.md and execute the D24-A1 task, in full. The owner's asks are quoted verbatim in the brief's law; STATION_HUB.md section 22 carries each one's measured current state. Amend the owning docs with the actual numbers per the brief's acceptance list A1-A11 - every value derived from a standing law or written PROPOSED with its reversal, never chosen silently. Docs only: no code, scene, theme or asset file. Write your report to .agents/gen/slices/D24-station-overhaul-design/D24-A1_report.md, answering each acceptance item with the amendment that owns it and a file:line cite."
```

## D24-R1 — the mandatory review (hyper/glm-5.3 @ high)

```bash
VAJB_SLIM=1 \
VAJB_WORKER_FILES="docs/design/STATION_HUB.md,docs/design/UI_SPEC.md,docs/design/AUDIO_SPEC.md,docs/gameplay/04_refinery.md,docs/gameplay/07_crafting.md,docs/gameplay/03_components.md,docs/gameplay/10_ship_acquisition.md" \
crush run --model hyper/glm-5.3 \
"Review the D24 design round. Read .agents/gen/slices/D24-station-overhaul-design/D24_BRIEF.md, then D24-A1_report.md, then grade the acceptance list A1-A11 item by item against the amended docs: does every owner ask have a number, a reversal and a tick row; is every layout number A5-lawful (containers, no coordinates); is every ink lawful under UI_SPEC section 16; are crafting and build costs derived from the 01/02/03 tables; did anything supersede an owner ruling instead of reporting it? Diff the amendments against the brief's measured-cites section 3. Findings tiered HIGH/MED/LOW, one evidence line each with a cite. You may cure a one-line doc slip inside the file set, disclosed. Write .agents/gen/slices/D24-station-overhaul-design/D24-R1_review.md."
```

## After R1

Fixer only if R1 leaves HIGH or MED (same file set, `hyper/glm-5.3` @ high,
report `D24-F1_report.md`). Then the brief's §12 close-out: gate pair, docs
index, verify, WAVEBOARD/TICKS refresh, boundary commit — and the P4
implementation waves re-cut from the landed design.
