class_name Fx
extends RefCounted
## The shared spawn-play-free seam for the shipped FX sheets: a caller names its
## per-frame file, and this file builds the node, blends it with the sheet's own alpha
## and frees it when the animation ends.
##
## Contract: docs/design/FX_SPEC.md section 0 (the void-black masters are never edited),
## section 2's 2026-09-21 amendment (the frames are separate files, because a
## `GPUParticles2D` draws its texture at the texture's own size) and section 3 (file
## naming); docs/design/ASSET_WIRING_HANDOFF.md section 3 (consumer rules: the art is
## never re-keyed, re-cut or tinted in code). The blend is the owner's 2026-09-21 ruling
## (`alpha_material`): the re-cut frames carry their own alpha, so every effect blends
## with it.
##
## Nothing here is written back to `assets/`: a frame is a whole per-frame file, or - for
## a row that draws one frame of a sequence - a region of that frame at the art's own
## measured ink box, and every path is checked before it is loaded, so a missing sheet
## leaves the caller silent rather than crashing a headless run.
##
## Geometry stays with the feature that owns it - this file owns only the mechanics
## (frame, material, scale, lifetime). `projectile.gd` and `weapons.gd` hold their
## own region tables; the impact and death FX reuse these same calls.

## The animation name every `SpriteFrames` built here carries.
const ANIMATION: StringName = &"default"

## FX_SPEC sections 1.2/1.4/1.6 state 20 FPS for the muzzle flash and the mining
## sparks and 15 FPS for the explosion; a caller passes its own rate, this is only
## the fallback for a sheet the spec gave no rate.
const DEFAULT_FPS := 20.0

## The draw pass that sizes a `GPUParticles2D`'s quad. A particle emitter draws its
## texture at the texture's own size: the node's `scale` never reaches what is drawn
## (measured on a 64 x 64 texture at scale 0.5, 0.017 and a non-uniform pair - every
## one drew 64 x 64; `.agents/gen/slice2_5_s2_report.md` section 2.2), and the process
## material's `scale_min/max` is uniform, so it cannot give FX_SPEC section 1.3's
## length *and* width. The draw pass can: this vertex stage scales the quad's own
## vertices, so `quad_scale` is exactly the drawn rectangle's size in texels
## (`probe_s3_trail_quad.tscn` measures the rectangle it produces).
##
## No `render_mode` is declared, so the pass blends with the default MIX - the alpha
## blend the re-cut sheets now carry their own alpha for (owner ruling 2026-09-21).
const QUAD_SHADER := """shader_type canvas_item;
uniform vec2 quad_scale = vec2(1.0, 1.0);
void vertex() {
	VERTEX *= quad_scale;
}
"""

## The one compiled quad shader, shared by every emitter that sizes its quad: a
## per-emitter `Shader` would compile a copy per engine cell.
static var _quad_shader: Shader = null


## The blend every re-cut FX sheet is drawn with (owner ruling 2026-09-21: "address
## `fx_effect_fN` directly with alpha blending as the sheets now carry their own
## alpha"). FX_SPEC section 0.1's carve-out is the same rule for the four effects that
## were already keyed; the re-cut gives every effect its own alpha, so every row now
## blends with it. The reversal for one row is one word: `additive_material()`.
static func alpha_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	return material


## The one blend mode the void-black sheets may use (FX_SPEC section 0).
static func additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


## The shared vertex-scaling shader, built once.
static func quad_shader() -> Shader:
	if _quad_shader == null:
		_quad_shader = Shader.new()
		_quad_shader.code = QUAD_SHADER
	return _quad_shader


## A draw pass that renders a quad of `quad_scale` texels - the size a particle
## emitter cannot get from its node.
static func quad_material(quad_scale: Vector2 = Vector2.ONE) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = quad_shader()
	material.set_shader_parameter(&"quad_scale", quad_scale)
	return material


## Re-size a quad already drawn through the draw pass. False when the material is not
## this file's quad pass, so a caller can tell "re-sized" from "left alone".
static func set_quad_scale(material: Material, quad_scale: Vector2) -> bool:
	var quad := material as ShaderMaterial
	if quad == null:
		return false
	quad.set_shader_parameter(&"quad_scale", quad_scale)
	return true


## The quad scale a row reads at: its `world` length over the drawn frame's own pixels,
## and its own width over them. `source` is the drawn texture's pixel size (the row's
## measured region, or the frame's whole canvas).
static func quad_scale_for(source: Vector2, world_length: float, world_width: float) -> Vector2:
	if source.x <= 0.0 or source.y <= 0.0:
		return Vector2.ONE
	return Vector2(world_length / source.x, world_width / source.y)


## The per-frame files of a row, each as the texture it draws: the whole frame, or - for
## a row that draws one frame of a sequence - the art's own measured ink box inside it.
##
## The re-cut ships one file per frame (`fx_explosion_f1..f5.png`), so a row addresses
## those files directly and the 2K masters are no longer an atlas source (owner ruling
## 2026-09-21). A `region` is applied to every frame it is given, which is how the
## single-frame reads (the streak, the ring, the charge) keep reading the *object*
## rather than the frame's own margin. Returns [] when any file is missing, so a missing
## sheet leaves the caller silent rather than half-drawn.
static func frame_textures(paths: Array, region: Rect2 = Rect2()) -> Array:
	var out: Array = []
	for path: Variant in paths:
		var file := String(path)
		if file.is_empty() or not ResourceLoader.exists(file):
			return []
		var texture := load(file) as Texture2D
		if texture == null:
			return []
		out.append(texture if region.size.x <= 0.0 or region.size.y <= 0.0 else frame(texture, region))
	return out


## One frame of a sheet: an `AtlasTexture` over `region` of the shipped master.
static func frame(texture: Texture2D, region: Rect2) -> AtlasTexture:
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	return atlas


## An animation over several regions of one sheet, in the order given. FX_SPEC section 2's
## 2026-09-21 amendment supersedes the route for every shipped row (the frames are separate
## files now), so this survives only for a caller holding a sheet of its own; `texture_frames`
## is what the shipped rows use.
static func sheet_frames(
	texture: Texture2D, regions: Array, fps: float = DEFAULT_FPS, loop: bool = false
) -> SpriteFrames:
	var frames := _new_frames(fps, loop)
	for region: Variant in regions:
		if region is Rect2:
			frames.add_frame(ANIMATION, frame(texture, region))
	return frames


## An animation over whole textures - the pre-cut per-frame files
## (`fx_muzzle_flash_f1..f4.png`), which need no region.
static func texture_frames(
	textures: Array, fps: float = DEFAULT_FPS, loop: bool = false
) -> SpriteFrames:
	var frames := _new_frames(fps, loop)
	for texture: Variant in textures:
		if texture is Texture2D:
			frames.add_frame(ANIMATION, texture)
	return frames


## The uniform scale that renders a sprite's longest side as `world_length` world
## units. `source_size` is the sheet's own pixel size (or its region's), so the size a
## sprite reads at comes from its own pixels rather than a guessed multiplier.
static func scale_for(source_size: Vector2, world_length: float) -> float:
	var longest := maxf(source_size.x, source_size.y)
	if longest <= 0.0 or world_length <= 0.0:
		return 1.0
	return world_length / longest


## Spawn a one-shot sheet at `at` (in the parent's own space), rotated, blended with the
## sheet's own alpha, and freed when the animation finishes. Returned so a caller can
## nudge it (a z index, a longer life); null when there is nothing to draw with.
##
## `centered` false puts the frame's top-left corner, not its centre, on the node's
## own origin - the muzzle flash uses that so the frame's mouth, not the frame's
## middle, sits on the muzzle.
static func play_once(
	parent: Node,
	frames: SpriteFrames,
	at: Vector2 = Vector2.ZERO,
	rotation: float = 0.0,
	scale_factor: float = 1.0,
	centered: bool = true,
	material: Material = null
) -> AnimatedSprite2D:
	if parent == null or not _has_frames(frames):
		return null
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = ANIMATION
	sprite.centered = centered
	sprite.material = material if material != null else alpha_material()
	sprite.position = at
	sprite.rotation = rotation
	sprite.scale = Vector2.ONE * scale_factor
	sprite.animation_finished.connect(sprite.queue_free)
	parent.add_child(sprite)
	sprite.play(ANIMATION)
	return sprite


## Spawn a single-frame sheet (FX_SPEC's ripple, spark, plume and pulse rows are one
## texture apiece) as a plain alpha-blended sprite. The caller owns its lifetime; pair it
## with `fade_and_free` when the spec gives the frame an engine-side fade.
static func display(
	parent: Node,
	texture: Texture2D,
	at: Vector2 = Vector2.ZERO,
	rotation: float = 0.0,
	scale_factor: float = 1.0,
	centered: bool = true,
	material: Material = null
) -> Sprite2D:
	if parent == null or texture == null:
		return null
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = centered
	sprite.material = material if material != null else alpha_material()
	sprite.position = at
	sprite.rotation = rotation
	sprite.scale = Vector2.ONE * scale_factor
	parent.add_child(sprite)
	return sprite


## The engine-side lifetime FX_SPEC gives a single-frame effect ("scale 0 -> 1.5x over
## 0.3 s with alpha fade in engine" - section 1.5's shield ripple and section 1.7's
## cargo pulse): fade the sprite out over `seconds` and free it when the fade ends.
static func fade_and_free(sprite: CanvasItem, seconds: float) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	var tween := sprite.create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, maxf(seconds, 0.0))
	tween.tween_callback(sprite.queue_free)


## A fresh `SpriteFrames` may or may not already carry a "default" animation
## depending on the engine's own default, so the name is only added when it is
## missing (`add_animation` on an existing name is an engine error).
static func _new_frames(fps: float, loop: bool) -> SpriteFrames:
	var frames := SpriteFrames.new()
	if not frames.has_animation(ANIMATION):
		frames.add_animation(ANIMATION)
	frames.set_animation_speed(ANIMATION, maxf(fps, 0.0))
	frames.set_animation_loop(ANIMATION, loop)
	return frames


static func _has_frames(frames: SpriteFrames) -> bool:
	if frames == null:
		return false
	if not frames.has_animation(ANIMATION):
		return false
	return frames.get_frame_count(ANIMATION) > 0
