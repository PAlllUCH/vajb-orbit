shader_type canvas_item;
render_mode blend_mix, unshaded;

// FX_SPEC section 5 row 1 / docs/gameplay/18_engine_spec.md section 3.4 (owner ruling
// 18): the screen-space directional motion blur. Everything it reads is the speed
// fantasy's single input, `speed_ratio = |v| / v_max`, and the three values the spec
// names - `blur_strength` (0.1 at cruise -> 0.8 during a dash), `blur_direction =
// v / |v|` and a chromatic aberration that scales with the strength. Strength is 0
// below the 0.70 onset, and 0 draws the screen through untouched (the CPU also hides
// the ColorRect, so a stationary hull pays no full-screen draw at all).
//
// Two pixel scales are the shader's own, because FX_SPEC states the strength band and
// no pixel figure: `blur_span_px` is the smear length a full-strength sample spans and
// `aberration_px` is the widest channel split. Both are uniforms with one caller
// (`speed_fantasy.gd`, which leaves them at these defaults) so the owner has one line
// to tune; they are reported in `.agents/gen/slice2_5_s1_report.md`.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// FX_SPEC section 5: `blur_strength` clamps 0.1 at cruise -> 0.8 during a dash.
uniform float blur_strength : hint_range(0.0, 1.0) = 0.0;
// FX_SPEC section 5: `blur_direction = v / |v|`.
uniform vec2 blur_direction = vec2(1.0, 0.0);
// FX_SPEC section 5: "chromatic_aberration scales with strength" - this is the
// strength-scaled value, not a second curve.
uniform float chromatic_aberration : hint_range(0.0, 1.0) = 0.0;

// The shader's own pixel scale for a full-strength smear (reported, one line).
uniform float blur_span_px : hint_range(0.0, 64.0) = 24.0;
// The shader's own widest channel split at chromatic_aberration 1.0 (reported).
uniform float aberration_px : hint_range(0.0, 8.0) = 2.0;

// Odd tap count, so the tap at t = 0 lands exactly on the pixel being shaded, and dense
// enough that consecutive taps land closer together than a texel's own bilinear footprint
// (measured: a one-pixel rule stays a continuous streak rather than a comb of copies).
const int TAPS = 17;

// One axis-aligned box average of the screen along `dir`, spanning `span` texture
// units either side of the sample point.
vec3 smear(vec2 uv, vec2 dir, float span) {
	vec3 acc = vec3(0.0);
	float total = 0.0;
	for (int i = 0; i < TAPS; i++) {
		float t = (float(i) / float(TAPS - 1)) - 0.5;
		float w = 1.0 - abs(t * 2.0);
		acc += texture(screen_texture, uv + dir * t * span).rgb * w;
		total += w;
	}
	return acc / max(total, 0.0001);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 dir = blur_direction;
	float magnitude = length(dir);
	dir = magnitude > 0.0001 ? dir / magnitude : vec2(1.0, 0.0);
	// Below the onset the screen is passed through, and the sampler is read once and
	// smeared by nothing: the processor has no early return, so the branch is what
	// keeps a stationary hull's pass at one tap.
	vec3 tint = texture(screen_texture, uv).rgb;
	if (blur_strength > 0.0) {
		tint = smear(uv, dir, blur_span_px * blur_strength * SCREEN_PIXEL_SIZE.x);
		// The channel split rides the same strength ramp as the smear.
		vec2 side = vec2(-dir.y, dir.x) * aberration_px * chromatic_aberration;
		vec2 split = side * blur_strength * SCREEN_PIXEL_SIZE;
		tint.r = texture(screen_texture, uv + split).r;
		tint.b = texture(screen_texture, uv - split).b;
	}
	COLOR = vec4(tint, 1.0);
}
