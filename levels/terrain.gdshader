shader_type spatial;
render_mode diffuse_burley, cull_back, depth_draw_opaque;

vec4 triplanar_texture(sampler2D p_sampler, vec3 p_weights, vec3 p_triplanar_pos) {
	vec4 samp = vec4(0.0);
	samp += texture(p_sampler, p_triplanar_pos.xy) * p_weights.z;
	samp += texture(p_sampler, p_triplanar_pos.xz) * p_weights.y;
	samp += texture(p_sampler, p_triplanar_pos.zy * vec2(-1.0, 1.0)) * p_weights.x;
	return samp;
}
uniform float global_scale = 1.0;
uniform vec3 triplanar_scale = vec3(1.0, 1.0, 1.0);
uniform vec3 triplanar_offset;
uniform float triplanar_sharpness = 0.5;

varying vec3 triplanar_power_normal;
varying vec3 triplanar_pos;

group_uniforms Noise;
uniform sampler2D noise_texture : filter_linear_mipmap_anisotropic;
uniform bool noise_is_triplanar = false;

group_uniforms Main_Texture;
uniform sampler2D ground_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D ground_orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D ground_normal : hint_normal, filter_linear_mipmap_anisotropic;

group_uniforms Alt_Texture;
uniform sampler2D alt_ground_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D alt_ground_orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D alt_ground_normal : hint_normal, filter_linear_mipmap_anisotropic;

group_uniforms Cliff_Texture;
uniform sampler2D cliff_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D cliff_orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D cliff_normal : hint_normal, filter_linear_mipmap_anisotropic;

group_uniforms Alt_cliff_Texture;
uniform sampler2D alt_cliff_texture : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D alt_cliff_orm_texture : filter_linear_mipmap_anisotropic;
uniform sampler2D alt_cliff_normal : hint_normal, filter_linear_mipmap_anisotropic;


group_uniforms Transition;
uniform float separation = 0.5;
uniform float transition_sharpness = 0.1;

void vertex() {
	vec3 normal = NORMAL;
	
	// Generate tangent and binormal for triplanar normal mapping
	TANGENT = vec3(0.0, 0.0, -1.0) * abs(normal.x);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.y);
	TANGENT += vec3(1.0, 0.0, 0.0) * abs(normal.z);
	TANGENT = normalize(TANGENT);
	
	BINORMAL = vec3(0.0, 1.0, 0.0) * abs(normal.x);
	BINORMAL += vec3(0.0, 0.0, -1.0) * abs(normal.y);
	BINORMAL += vec3(0.0, 1.0, 0.0) * abs(normal.z);
	BINORMAL = normalize(BINORMAL);

	triplanar_power_normal = pow(abs(NORMAL), vec3(triplanar_sharpness));
	triplanar_power_normal /= dot(triplanar_power_normal, vec3(1.0));
	triplanar_pos = VERTEX * (triplanar_scale * global_scale) + triplanar_offset;
	triplanar_pos *= vec3(1.0, -1.0, 1.0);
}

void fragment() {
	vec4 noise;
	if (noise_is_triplanar){
		noise = triplanar_texture(noise_texture, triplanar_power_normal, triplanar_pos);
	} else{
		noise = texture(noise_texture, UV);
	}
	vec4 ground_albedo = triplanar_texture(ground_texture, triplanar_power_normal, triplanar_pos);
	vec4 alt_ground_albedo = triplanar_texture(alt_ground_texture, triplanar_power_normal, triplanar_pos);
	vec4 ground_orm = triplanar_texture(ground_orm_texture, triplanar_power_normal, triplanar_pos);
	vec4 ground_normal_map = triplanar_texture(ground_normal, triplanar_power_normal, triplanar_pos);
	vec4 alt_ground_normal_map = triplanar_texture(alt_ground_normal, triplanar_power_normal, triplanar_pos);
	vec4 alt_ground_orm = triplanar_texture(alt_ground_orm_texture, triplanar_power_normal, triplanar_pos);
	
	//Cliff
	vec4 cliff_albedo = triplanar_texture(cliff_texture, triplanar_power_normal, triplanar_pos);
	vec4 cliff_orm = triplanar_texture(cliff_orm_texture, triplanar_power_normal, triplanar_pos);
	vec4 cliff_normal_map = triplanar_texture(cliff_normal, triplanar_power_normal, triplanar_pos);
	vec4 alt_cliff_albedo = triplanar_texture(alt_cliff_texture, triplanar_power_normal, triplanar_pos);
	vec4 alt_cliff_orm = triplanar_texture(alt_cliff_orm_texture, triplanar_power_normal, triplanar_pos);
	vec4 alt_cliff_normal_map = triplanar_texture(alt_cliff_normal, triplanar_power_normal, triplanar_pos);
	
	vec3 world_normal = normalize(INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float is_ground = smoothstep(separation, separation * transition_sharpness, world_normal.y);
	

	vec3 final_ground_albedo = mix(ground_albedo.rgb, alt_ground_albedo.rgb, noise.r);
	vec3 final_cliff_albedo = mix(cliff_albedo.rgb, alt_cliff_albedo.rgb, noise.r);
	vec3 final_ground_orm = mix(ground_orm.rgb, alt_ground_orm.rgb, noise.r);
	vec3 final_cliff_orm = mix(cliff_orm.rgb, alt_cliff_orm.rgb, noise.r);
	vec3 final_ground_normal_map = mix(ground_normal_map.rgb, alt_ground_normal_map.rgb, noise.r);
	vec3 final_cliff_normal_map = mix(cliff_normal_map.rgb, alt_cliff_normal_map.rgb, noise.r);

	ALBEDO = mix(final_ground_albedo, final_cliff_albedo, is_ground);

	AO =  mix(final_ground_orm.r, final_cliff_orm.r, is_ground);
	ROUGHNESS = mix(final_ground_orm.g, final_cliff_orm.g, is_ground);
	METALLIC = mix(final_ground_orm.b, final_cliff_orm.b, is_ground);

	NORMAL_MAP =mix(final_ground_normal_map, final_cliff_normal_map, is_ground);
}