shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform float UVScale : hint_range(0.0, 100.0, 0.1) = 1.0;
uniform sampler2D albedo :  source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec3 tint :  source_color;
uniform sampler2D ORM_texture :   hint_roughness_g, filter_linear_mipmap, repeat_enable;


uniform sampler2D normalMapA : hint_normal;
uniform sampler2D normalMapB: hint_normal ;
uniform float ratio : hint_range(0.0, 1.0, 0.1) = 0.5;

vec3 blendNormalsWhiteout(vec3 n1, vec3 n2) {
    return normalize(vec3(n1.xy + n2.xy, n1.z * n2.z));
}

void fragment() {
	vec3 normalA = texture(normalMapA, UV).rgb;
	vec2 uv = UV* UVScale;
	vec3 orm = texture(ORM_texture, uv).rgb;
	vec3 normalB = texture(normalMapB, uv).rgb;
	//normalA.xy*= ratio;
	//normalB.xy *= (1.0-ratio);
	
	NORMAL_MAP = blendNormalsWhiteout(normalA, normalB);
	ALBEDO = texture(albedo, uv).rgb ;
	AO = orm.r;
	ROUGHNESS = orm.g;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
