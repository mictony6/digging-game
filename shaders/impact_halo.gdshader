shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_test_disabled;

// Procedural impact halo: a camera-facing radial glow placed at the beam's
// hit point. Purely fragment-driven — no texture.

uniform vec4 color : source_color = vec4(0.96, 0.45, 0.34, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 0.96, 0.98, 1.0);
uniform float intensity : hint_range(0.0, 20.0) = 4.0;
uniform float core_size : hint_range(0.0, 1.0) = 0.18;
uniform float halo_falloff : hint_range(0.5, 8.0) = 3.5;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.3;

void vertex() {
	// Face the camera, keeping only the node's translation.
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
		INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);

	// Breathing scale so the halo feels alive even before flicker.
	float breathe = 1.0 + 0.12 * sin(TIME * 9.0) * sin(TIME * 3.7);
	VERTEX *= breathe;
}

void fragment() {
	float d = length(UV - vec2(0.5)) * 2.0; // 0 center, 1 edge of the quad

	float core = 1.0 - smoothstep(0.0, core_size, d);
	float halo = pow(max(1.0 - d, 0.0), halo_falloff);
	float flicker = 1.0 - flicker_strength * (0.5 + 0.5 * sin(TIME * 27.0) * sin(TIME * 13.0));

	vec3 col = mix(color.rgb, core_color.rgb, core);
	float a = (halo * 0.8 + core) * flicker;

	// Unshaded: HDR color through ALBEDO so WorldEnvironment glow blooms it.
	ALBEDO = col * a * intensity;
	ALPHA = clamp(a, 0.0, 1.0) * color.a;
}
