# Generation log - icons/weapon

**Generated:** 2026-09-21T00:37:43 by `staging/cut/pull.py`. Regenerate, never hand-edit.

One row per shipped file. `sheet` is the render it was cut out of, `panel` its cell. The prompt is the exact text sent to the image model for that render; identical prompts on different stamps are separate runs, not duplicates.

| File | Sheet | Panel | Model | Job | Stamp |
|---|---|---|---|---|---|
| `icon_ammo.png` | raw/icons/panel_glyphs.png | 8 of 9 | - | - | - |
| `icon_ammo_laser.png` | raw/icons/panel_equipment.png | 8 of 9 | - | - | - |
| `icon_ammo_rocket.png` | raw/icons/panel_equipment.png | 9 of 9 | - | - | - |
| `icon_weapon_cannon.png` | raw/icons/panel_weapons.png | 2 of 5 | - | - | - |
| `icon_weapon_laser.png` | raw/icons/panel_weapons.png | 1 of 5 | - | - | - |
| `icon_weapon_mine.png` | raw/icons/panel_weapons.png | 4 of 5 | - | - | - |
| `icon_weapon_plasma.png` | raw/icons/panel_weapons.png | 5 of 5 | - | - | - |
| `icon_weapon_rocket.png` | raw/icons/panel_weapons.png | 3 of 5 | - | - | - |

## The prompts

## Regeneration 2026-10-15 (T-203 — the pack icon masters regenerate bright)

The two pack masters were regenerated in place (same filenames, ICONS_SPEC §10);
the pre-regeneration bytes are `asset-library/_prekey_backup/pack_icons_2026-10-15/`
(md5 manifest beside them). Each master came from a single kie.ai run, then the
scripted post-pass: `staging/cut/lift_pack_icons.py` (linear RGB gain to the
§10.2 average-luminance gate, then LANCZOS downscale 1024→512) and the centre
shift to the 1.5 px tolerance (`center_check.py`'s math; laser shifted (-2,+6),
rocket (0,+4)).

| File | Chosen run | Model | Task id | Stamp |
|---|---|---|---|---|
| `icon_ammo_laser.png` | 20261015-223249 | `qwen2-1/text-to-image` (Qwen-Image 2.1) | `b08ae3c01b758f10976e94ca7eb75403` | 2026-10-15 |
| `icon_ammo_rocket.png` | 20261015-223202 | `qwen2-1/text-to-image` (Qwen-Image 2.1) | `8b56f42e23f8b697ef8910d7b411d410` | 2026-10-15 |

Superseded attempts (kept for the record, not shipped): gpt-image-2 runs
`0cd9e4c41f0ddbe483e09d1204b82a40` (laser, /tmp/kie_pack_icons/20261015-222702)
and `7c04c3c0f852f4fa92dcfdf8bf52e8ee` (rocket, /tmp/kie_pack_icons/20261015-222842)
— avg luminance 69, short of the §10.2 gate; qwen run
`1f535d947589fa42ef8932438f2b113d` (laser, /tmp/kie_pack_icons_qwen/20261015-223129)
— avg 75; qwen run `41a58b7fef90d1d9f505d5f317b8090d` (rocket,
/tmp/kie_pack_icons_q2/20261015-223320) — returned opaque (5.9 % alpha-0), unusable.

**Laser prompt** (chosen run): Single game icon for a sci-fi space shooter HUD,
centred on a transparent background: a squat vertical cylindrical
laser-capacitor canister, a steel drum with two reinforcing bands, a glowing
ember-orange charge window near the top, a small valve fitting on the lid. The
whole object is painted BRIGHT: average metal tone is light gunmetal #6E747B
with brushed-aluminium highlights #9AA0A8 on the bands, lid and edges; even
studio-style lighting across the entire object, the lower half exactly as
bright as the upper half, no dark bottom, no shadow falloff, no vignette. One
hot ember glow #E8703A only on the charge window, no other glow. Grimdark
painted sci-fi style, semi-realistic weathered metal, subtle wear and grime,
subtle film grain, top-down orthographic view, crisp readable silhouette,
generous transparent margin around the object, no background, no ground
shadow, no text, no watermark.

**Rocket prompt** (chosen run): Single game icon for a sci-fi space shooter
HUD, centred on a transparent background: a launch rack holding two identical
rocket shells side by side, pointed warheads up, each shell with an
ember-orange band near the tip, the rack a riveted steel bracket frame around
them. The whole object is evenly lit and clearly legible on a black background:
the lower half of the rack and shells is as bright as the upper half, no dark
bottom, no shadow-side falloff, no vignette. Average metal tone reads as bright
mid-grey steel #565C63; gunmetal #3A3F46 only in the recessed panel lines, a
bone-grey #C9CDD2 rim light along the top edges and frame edges. One hot ember
glow #E8703A only on the shells' bands, no other glow. Grimdark painted sci-fi
style, semi-realistic weathered metal, subtle wear and grime, subtle film grain,
top-down orthographic view, crisp readable silhouette, generous transparent
margin around the object, no background, no ground shadow, no text, no
watermark.

Both runs at 1K, `background: transparent` (native RGBA returned), via the
image-generator skill's `kie_generate.py`; spend in its usage ledger.
