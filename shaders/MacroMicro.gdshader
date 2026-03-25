shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D macroNormalMap :hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D microNormalMap :hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ORM_texture :   hint_roughness_g, filter_linear_mipmap, repeat_enable;
uniform float detailScale : hint_range(0.1, 100.0, 0.1) = 1.0;
void vertex() {
	// Called for every vertex the material is visible on.
}
vec3 blendNormalsRNM(vec3 n1, vec3 n2) {
    vec3 t = n1 + vec3(0.0, 0.0, 1.0);
    vec3 u = n2 * vec3(-1.0, -1.0, 1.0);
    return normalize(t * dot(t, u) - u * t.z);
}
void fragment() {
	vec2 uv = UV * detailScale;
	ALBEDO = texture(albedo, uv).rgb;
    vec3 normalA = texture(macroNormalMap, UV).rgb * 2.0 - 1.0;
    vec3 normalB = texture(microNormalMap, uv).rgb * 2.0 - 1.0;
	vec3 orm = texture(ORM_texture, uv).rgb;
	ROUGHNESS = orm.g;
	AO = orm.r;
	METALLIC = orm.b;
    NORMAL_MAP = blendNormalsRNM(normalA, normalB) * 0.5 + 0.5;
}

