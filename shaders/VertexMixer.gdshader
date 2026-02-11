shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D colorA : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D colorB : source_color, filter_linear_mipmap_anisotropic ;
uniform sampler2D normalA : hint_normal;
uniform sampler2D normalB : hint_normal;
uniform float UVScale= 1.0;
uniform sampler2D depth_texture : hint_depth_texture;
uniform float proximity_fade_distance : hint_range(0.0, 10.0, 0.01);
void fragment() {
	
	vec2 uv = UV * UVScale;

	vec3 albedoA = texture(colorA, uv).rgb;
	vec3 albedoB = texture(colorB, uv).rgb;
	
	vec3 normalMapA = texture(normalA, uv).rgb;
	vec3 normalMapB = texture(normalB, uv).rgb;
	ALBEDO = mix(albedoA, albedoB, COLOR.rgb);
	NORMAL_MAP = mix(normalMapA, normalMapB, COLOR.rgb);

	
	// Proximity Fade: Enabled
	float proximity_depth_tex = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	vec4 ndc = OUTPUT_IS_SRGB ? vec4(vec3(SCREEN_UV, proximity_depth_tex) * 2.0 - 1.0, 1.0) : vec4(SCREEN_UV * 2.0 - 1.0, proximity_depth_tex, 1.0);
	vec4 proximity_view_pos = INV_PROJECTION_MATRIX * ndc;
	proximity_view_pos.xyz /= proximity_view_pos.w;
	ALPHA *= clamp(1.0 - smoothstep(proximity_view_pos.z + proximity_fade_distance, proximity_view_pos.z, VERTEX.z), 0.0, 1.0);
}

