shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// ── Helpers ───────────────────────────────────────────────────────────────────

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy)               * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz)               * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}

// ── Varyings ──────────────────────────────────────────────────────────────────

varying vec3 triplanar_power_normal;
varying vec3 triplanar_pos;

// ── Uniforms ──────────────────────────────────────────────────────────────────

group_uniforms Triplanar;
uniform float global_scale         = 1.0;
uniform vec3  triplanar_scale      = vec3(1.0);
uniform vec3  triplanar_offset;
uniform float triplanar_sharpness  = 0.5;
uniform bool  textures_are_triplanar = true;

group_uniforms Noise;
uniform sampler2D noise_texture : filter_linear_mipmap_anisotropic;
uniform bool noise_is_triplanar = false;

group_uniforms Main_Texture;
uniform sampler2D ground_texture     : source_color,        filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal      : hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_orm_texture : hint_roughness_g,    filter_linear_mipmap_anisotropic;

group_uniforms Alt_Texture;
uniform sampler2D alt_ground_texture     : source_color,        filter_linear_mipmap_anisotropic;
uniform sampler2D alt_ground_normal      : hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D alt_ground_orm_texture : hint_roughness_g,    filter_linear_mipmap_anisotropic;

group_uniforms Cliff_Texture;
uniform sampler2D cliff_texture     : source_color,        filter_linear_mipmap_anisotropic;
uniform sampler2D cliff_normal      : hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D cliff_orm_texture : hint_roughness_g,    filter_linear_mipmap_anisotropic;

group_uniforms Alt_Cliff_Texture;
uniform sampler2D alt_cliff_texture     : source_color,        filter_linear_mipmap_anisotropic;
uniform sampler2D alt_cliff_normal      : hint_roughness_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D alt_cliff_orm_texture : hint_roughness_g,    filter_linear_mipmap_anisotropic;

group_uniforms Transition;
uniform float separation           = 0.5;
uniform float transition_sharpness = 0.1;

// ── Vertex ────────────────────────────────────────────────────────────────────

void vertex() {
	vec3 n = NORMAL;

	TANGENT = normalize(
		vec3(0.0, 0.0, -1.0) * abs(n.x) +
		vec3(1.0, 0.0,  0.0) * abs(n.y) +
		vec3(1.0, 0.0,  0.0) * abs(n.z)
	);
	BINORMAL = normalize(
		vec3(0.0,  1.0, 0.0) * abs(n.x) +
		vec3(0.0,  0.0,-1.0) * abs(n.y) +
		vec3(0.0,  1.0, 0.0) * abs(n.z)
	);

	triplanar_power_normal  = pow(abs(NORMAL), vec3(triplanar_sharpness));
	triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
	triplanar_pos           = VERTEX * (triplanar_scale * global_scale) + triplanar_offset;
	triplanar_pos          *= vec3(1.0, -1.0, 1.0);
}

// ── Fragment ──────────────────────────────────────────────────────────────────

void fragment() {
	// Noise
	vec4 noise = noise_is_triplanar
		? triplanar_texture(noise_texture, triplanar_power_normal, triplanar_pos)
		: texture(noise_texture, UV);

	// Texture sampling — triplanar or UV
	vec2 scaled_uv = UV * global_scale;

	vec4 ground_albedo,       ground_nm,       ground_orm;
	vec4 alt_ground_albedo,   alt_ground_nm,   alt_ground_orm;
	vec4 cliff_albedo,        cliff_nm,        cliff_orm;
	vec4 alt_cliff_albedo,    alt_cliff_nm,    alt_cliff_orm;

	if (textures_are_triplanar) {
		ground_albedo     = triplanar_texture(ground_texture,         triplanar_power_normal, triplanar_pos);
		ground_nm         = triplanar_texture(ground_normal,          triplanar_power_normal, triplanar_pos);
		ground_orm        = triplanar_texture(ground_orm_texture,     triplanar_power_normal, triplanar_pos);
		alt_ground_albedo = triplanar_texture(alt_ground_texture,     triplanar_power_normal, triplanar_pos);
		alt_ground_nm     = triplanar_texture(alt_ground_normal,      triplanar_power_normal, triplanar_pos);
		alt_ground_orm    = triplanar_texture(alt_ground_orm_texture, triplanar_power_normal, triplanar_pos);
		cliff_albedo      = triplanar_texture(cliff_texture,          triplanar_power_normal, triplanar_pos);
		cliff_nm          = triplanar_texture(cliff_normal,           triplanar_power_normal, triplanar_pos);
		cliff_orm         = triplanar_texture(cliff_orm_texture,      triplanar_power_normal, triplanar_pos);
		alt_cliff_albedo  = triplanar_texture(alt_cliff_texture,      triplanar_power_normal, triplanar_pos);
		alt_cliff_nm      = triplanar_texture(alt_cliff_normal,       triplanar_power_normal, triplanar_pos);
		alt_cliff_orm     = triplanar_texture(alt_cliff_orm_texture,  triplanar_power_normal, triplanar_pos);
	} else {
		ground_albedo     = texture(ground_texture,         scaled_uv);
		ground_nm         = texture(ground_normal,          scaled_uv);
		ground_orm        = texture(ground_orm_texture,     scaled_uv);
		alt_ground_albedo = texture(alt_ground_texture,     scaled_uv);
		alt_ground_nm     = texture(alt_ground_normal,      scaled_uv);
		alt_ground_orm    = texture(alt_ground_orm_texture, scaled_uv);
		cliff_albedo      = texture(cliff_texture,          scaled_uv);
		cliff_nm          = texture(cliff_normal,           scaled_uv);
		cliff_orm         = texture(cliff_orm_texture,      scaled_uv);
		alt_cliff_albedo  = texture(alt_cliff_texture,      scaled_uv);
		alt_cliff_nm      = texture(alt_cliff_normal,       scaled_uv);
		alt_cliff_orm     = texture(alt_cliff_orm_texture,  scaled_uv);
	}

	// Noise blend between base and alt variants
	vec3 final_ground_albedo = mix(ground_albedo.rgb,    alt_ground_albedo.rgb, noise.r);
	vec3 final_cliff_albedo  = mix(cliff_albedo.rgb,     alt_cliff_albedo.rgb,  noise.r);
	vec3 final_ground_orm    = mix(ground_orm.rgb,       alt_ground_orm.rgb,    noise.r);
	vec3 final_cliff_orm     = mix(cliff_orm.rgb,        alt_cliff_orm.rgb,     noise.r);

	// Normal maps: unpack → noise blend → repack after cliff blend
	vec3 final_ground_normal = normalize(mix(
		ground_nm.rgb    * 2.0 - 1.0,
		alt_ground_nm.rgb * 2.0 - 1.0,
		noise.r
	));
	vec3 final_cliff_normal = normalize(mix(
		cliff_nm.rgb     * 2.0 - 1.0,
		alt_cliff_nm.rgb * 2.0 - 1.0,
		noise.r
	));

	// Cliff weight: 0 = flat ground, 1 = vertical cliff
	vec3  world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float cliff_blend  = smoothstep(separation, separation + transition_sharpness, 1.0 - world_normal.y);

	ALBEDO     = mix(final_ground_albedo, final_cliff_albedo, cliff_blend);
	NORMAL_MAP = normalize(mix(final_ground_normal, final_cliff_normal, cliff_blend)) * 0.5 + 0.5;
	AO         = mix(final_ground_orm.r, final_cliff_orm.r, cliff_blend);
	ROUGHNESS  = mix(final_ground_orm.g, final_cliff_orm.g, cliff_blend);
	METALLIC   = mix(final_ground_orm.b, final_cliff_orm.b, cliff_blend);
}
