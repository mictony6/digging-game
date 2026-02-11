shader_type spatial;
render_mode diffuse_burley, depth_draw_opaque, cull_back;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_rougness: hint_roughness_gray,filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D crack_map : source_color, filter_linear_mipmap_anisotropic;
instance uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.3, 0.0);
uniform float crack_emission_strength : hint_range(0.0, 5.0) = 2.0;
uniform float crack_edge_softness : hint_range(0.01, 0.5) = 0.1;
uniform float crack_normal_strength : hint_range(0.0, 5.0) = 2.0;
uniform float rim : hint_range(0.0, 1.0, 0.01);
uniform float rim_tint : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_rim : hint_default_white, filter_linear_mipmap, repeat_enable;

// compute the revealed crack value at a given UV
float get_crack(vec2 uv) {
    float crack = texture(crack_map, uv).r;
    float threshold = 1.0 - damage;
    return smoothstep(threshold, threshold + crack_edge_softness, crack);
}

// derive a normal from the crack heightmap using finite differences
vec3 crack_normal(vec2 uv, vec2 texel_size) {
    float center = get_crack(uv);
    float right  = get_crack(uv + vec2(texel_size.x, 0.0));
    float up     = get_crack(uv + vec2(0.0, texel_size.y));

    // gradient (crack = height, so invert for grooves)
    float dx = (right - center);
    float dy = (up - center);

    // construct tangent-space normal
    // negative because cracks are indentations, not bumps
    vec3 n = normalize(vec3(-dx * crack_normal_strength, -dy * crack_normal_strength, 1.0));

    // remap from [-1,1] to [0,1] for NORMAL_MAP
    return n * 0.5 + 0.5;
}

void fragment() {
    vec4 base = texture(rock_albedo, UV);
    vec3 rock_n = texture(rock_normal, UV).rgb;
    float crack_mask = get_crack(UV);

    // crack normals from heightmap
    vec2 texel = vec2(1.0) / vec2(textureSize(crack_map, 0));
    vec3 crack_n = crack_normal(UV, texel);

    // blend rock normals with crack normals
    // use RNM (reoriented normal mapping) for proper blending
    vec3 base_unpack = rock_n * 2.0 - 1.0;
    vec3 crack_unpack = crack_n * 2.0 - 1.0;

    vec3 t = base_unpack + vec3(0.0, 0.0, 1.0);
    vec3 u = crack_unpack * vec3(-1.0, -1.0, 1.0);
    vec3 blended = normalize(t * dot(t, u) - u * t.z);
    vec3 final_normal = mix(rock_n, blended * 0.5 + 0.5, crack_mask);

    // darken albedo along cracks
    vec3 final_albedo = mix(base.rgb, base.rgb * 0.15, crack_mask);

    // glow
    vec3 emission = crack_color * crack_mask * crack_emission_strength * damage;

    ALBEDO = final_albedo;
	ROUGHNESS = texture(rock_rougness, UV).r;
    NORMAL_MAP = final_normal;
    NORMAL_MAP_DEPTH = 1.0;
    EMISSION = emission;
	

	// Rim: Enabled
	vec2 rim_tex = texture(texture_rim, UV).xy;
	RIM = rim * rim_tex.x;
	RIM_TINT = rim_tint * rim_tex.y;
}