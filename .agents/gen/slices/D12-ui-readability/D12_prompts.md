# D12_prompts.md — dispatch lines (one per worker, run only as the queue says)

Route ruling (owner, 2026-09-24): the readability reviewer runs on
`deepseek/deepseek-flash` (DeepSeek API direct) at `--reasoning-effort max`.
`VAJB_SLIM` is **not** set for this worker: its first evidence route is the
`godot-ai` editor bridge, which the slim profile drops.

Run each line as a background shell and stay in the session until it exits:

```bash
cd /home/kamil-paluszkiewicz/VajbOrbit && source ~/.profile \
  && VAJB_WORKER_FILES='.agents/gen/slices/D12-ui-readability/D12-A0_report.md' \
     crush run "You are worker D12-A0, an independent readability auditor for the Vajb Orbit Godot project. Read .agents/gen/slices/D12-ui-readability/D12-A0_BRIEF.md end to end first and follow it exactly. Report only, never edit a source file. Write your deliverable to .agents/gen/slices/D12-ui-readability/D12-A0_report.md, 150 lines maximum, and nothing else." \
     -m deepseek/deepseek-flash --reasoning-effort max --cwd /home/kamil-paluszkiewicz/VajbOrbit \
  > /tmp/d12_a0.log 2>&1
```

`crush run` prints only narration, so a silent log is normal; poll with
`pgrep -af 'worker D12-A0'` and read the report when the process exits.
