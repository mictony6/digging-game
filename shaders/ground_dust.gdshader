shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;
uniform sampler2D base_texture: source_color ;
uniform float uv_scale  = 1.0;
uniform float radius = 0.18;
uniform float edge_softness = 0.08;
void vertex() {

	// Billboard Mode: Enabled
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			MAIN_CAM_INV_VIEW_MATRIX[0],
			MAIN_CAM_INV_VIEW_MATRIX[1],
			MAIN_CAM_INV_VIEW_MATRIX[2],
			MODEL_MATRIX[3]);
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}



void fragment() {
	float d = length(UV - vec2(0.5)) ; // 0 center, 1 edge of the quad
	vec2 uv = UV * uv_scale + vec2(-TIME * 0.1, 0);
	vec3 base_texture_color = texture(base_texture, uv).rgb;
	vec2 mid_uv = (uv * 0.25) + vec2(TIME * 0.05, 0);
	vec3 mid_texture_color = texture(base_texture, mid_uv).rgb;

	float fade = 1.0 - smoothstep(radius - edge_softness, radius, d);
	ALBEDO = (base_texture_color*mid_texture_color  ) * fade;

}
