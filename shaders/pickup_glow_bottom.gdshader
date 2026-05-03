shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 color: source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float speed: hint_range(0.1, 4.0) = 1.2;
uniform float swirl_strength: hint_range(0.0, 20.0) = 6.0;
uniform float opacity: hint_range(0.0, 4.0) = 1.5;
uniform sampler2D noise_texture: hint_default_white, repeat_enable;

void fragment() {
	// Centered UV: -1..1
	vec2 uv = UV * 2.0 - 1.0;
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	// Swirl: rotate angle outward — more twist near center, unwinds at edge
	float swirl_angle = angle + swirl_strength * (1.0 - dist) + TIME * speed;

	// Sample noise in swirled polar space, scroll outward over time
	vec2 swirl_uv = vec2(swirl_angle / (2.0 * 3.14159), dist - TIME * speed * 0.15);
	float ring = textureLod(noise_texture, swirl_uv, 0.0).r;

	// Second layer counter-offset for thickness variation
	vec2 swirl_uv2 = vec2(swirl_angle / (2.0 * 3.14159) + 0.5, dist * 1.3 - TIME * speed * 0.1);
	float ring2 = textureLod(noise_texture, swirl_uv2, 0.0).r;

	float combined = ring * 0.6 + ring2 * 0.4;

	// Fade at center and at outer edge
	float radial_fade = smoothstep(0.0, 0.15, dist) * smoothstep(1.0, 0.6, dist);

	ALBEDO = color.rgb;
	ALPHA = clamp(combined * radial_fade * color.a * opacity, 0.0, 1.0);
}
