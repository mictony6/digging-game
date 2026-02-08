shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D colorA : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D colorB : source_color, filter_linear_mipmap_anisotropic ;
uniform sampler2D normalA : hint_normal;
uniform sampler2D normalB : hint_normal;
uniform float UVScale= 1.0;
void fragment() {
	
	vec2 uv = UV * UVScale;

	vec3 albedoA = texture(colorA, uv).rgb;
	vec3 albedoB = texture(colorB, uv).rgb;
	
	vec3 normalMapA = texture(normalA, uv).rgb;
	vec3 normalMapB = texture(normalB, uv).rgb;
	ALBEDO = mix(albedoA, albedoB, COLOR.rgb);
	NORMAL_MAP = mix(normalMapA, normalMapB, COLOR.rgb);
}

