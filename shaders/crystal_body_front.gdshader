shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// =============================================================
// Crystal / Jelly Body Shader — FRONT FACE PASS
// Apply this to the main body mesh.
// Pair with crystal_body_back.gdshader on a duplicate mesh
// to get a convincing volumetric translucent look.
// =============================================================

group_uniforms color;
uniform vec4 base_color : source_color = vec4(0.03, 0.10, 0.75, 1.0);
uniform vec4 rim_color : source_color = vec4(0.35, 0.65, 1.0, 1.0);
uniform vec4 inner_glow_color : source_color = vec4(0.1, 0.3, 1.0, 1.0);

group_uniforms fresnel;
uniform float fresnel_power : hint_range(0.5, 10.0) = 3.0;
uniform float rim_intensity : hint_range(0.0, 5.0) = 1.8;

group_uniforms opacity;
uniform float opacity_center : hint_range(0.0, 1.0) = 0.1;
uniform float opacity_edge : hint_range(0.0, 1.0) = 0.85;

group_uniforms surface;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.2;
uniform float specular_val : hint_range(0.0, 1.0) = 0.7;
uniform float metallic_val : hint_range(0.0, 1.0) = 0.0;

group_uniforms refraction;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.05;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_linear;

group_uniforms emission;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.4;
uniform float inner_glow_strength : hint_range(0.0, 2.0) = 0.3;

group_uniforms thickness;
// Fake thickness: use a noise texture or leave white for uniform thickness
uniform sampler2D thickness_map : hint_default_white;
uniform float thickness_scale : hint_range(0.0, 3.0) = 1.0;

float fresnel(vec3 normal, vec3 view, float power) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), power);
}
void vertex() {
    VERTEX.y += sin(TIME * 1.5 + VERTEX.x * 3.0) * 0.02;
}
void fragment() {
	float fres = fresnel(NORMAL, VIEW, fresnel_power);

	// --- Color ---
	vec3 surface_color = mix(base_color.rgb, rim_color.rgb, fres * rim_intensity);

	// --- Fake thickness / subsurface ---
	float thickness = texture(thickness_map, UV).r * thickness_scale;
	vec3 sss = inner_glow_color.rgb * (1.0 - fres) * thickness * inner_glow_strength;
	
	// Pulsing inner glow
	float pulse = sin(TIME * 2.0) * 0.5 + 0.5;
	sss *= (0.7 + 0.3 * pulse);
	
	// --- Refraction (screen-space) ---
	vec2 refracted_uv = SCREEN_UV + NORMAL.xy * refraction_strength * (1.0 - fres);
	vec3 refracted_color = texture(screen_texture, refracted_uv).rgb;

	// Blend refracted background with surface color based on opacity
	float alpha = mix(opacity_center, opacity_edge, fres);
	vec3 final_color = mix(refracted_color, surface_color, alpha) + sss;


	
	ALBEDO = final_color;
	// We handle transparency via refraction blending, so keep alpha high
	// but still allow some transparency at the center
	ALPHA = clamp(alpha + 0.2, 0.0, 1.0);

	ROUGHNESS = roughness_val;
	SPECULAR = specular_val;
	METALLIC = metallic_val;

	// Rim emission
	EMISSION = rim_color.rgb * fres * emission_strength + sss * 0.5;
}
