shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform vec4 color: source_color = vec4(1.0, 0.8, 0.2, 1.0);
uniform float speed: hint_range(0.1, 4.0) = 1.0;
uniform float wibble_strength: hint_range(0.0, 0.4) = 0.12;
uniform float smoke_scale: hint_range(0.5, 8.0) = 3.0;
uniform float opacity: hint_range(0.0, 4.0) = 1.8;
uniform sampler2D noise_texture: hint_default_white, repeat_enable;
instance uniform float time_offset: hint_range(0.0, 100.0) = 0.0;
instance uniform vec2 uv_offset = vec2(0.0, 0.0);

void vertex() {
	// Billboard Mode: Y-Billboard
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), MAIN_CAM_INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(MAIN_CAM_INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float t = TIME * speed + time_offset;

	// Warp layer: slow-scrolling noise used to distort UV.x
	float warp = texture(noise_texture, vec2(UV.x * 1.5, UV.y * 2.0 + t * 0.5) / smoke_scale + uv_offset).r * 2.0 - 1.0;
	vec2 warped_uv = vec2(UV.x + warp * wibble_strength, UV.y);

	// Two smoke layers scrolling upward
	float smoke  = texture(noise_texture, vec2(warped_uv.x, warped_uv.y + t * 0.5) / smoke_scale + uv_offset).r;
	float smoke2 = texture(noise_texture, vec2(warped_uv.x + 0.4, warped_uv.y + t * 0.35 + 2.3) / smoke_scale * 0.75 + uv_offset).r;
	float combined = smoke * 0.6 + smoke2 * 0.4;

	// UV.y: 0 = top, 1 = bottom — power curve thins the top aggressively
	float height_fade = pow(UV.y, 2.5);

	// Soft horizontal edges
	float edge_fade = smoothstep(0.0, 0.18, UV.x) * smoothstep(1.0, 0.82, UV.x);

	ALBEDO = color.rgb;
	ALPHA  = clamp(combined * height_fade * edge_fade * color.a * opacity, 0.0, 1.0);
}
