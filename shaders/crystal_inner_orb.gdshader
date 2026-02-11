shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// =============================================================
// Inner Orb / Bubble Shader
// Apply to SphereMesh instances placed INSIDE the body.
// Set render_priority = -2 (draws before both body passes).
//
// These are the visible internal orbs/bubbles seen through
// the translucent body.
// =============================================================

group_uniforms color;
uniform vec4 orb_color : source_color = vec4(0.08, 0.2, 0.9, 1.0);
uniform vec4 orb_rim_color : source_color = vec4(0.4, 0.7, 1.0, 1.0);

group_uniforms fresnel;
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.0;
uniform float rim_intensity : hint_range(0.0, 3.0) = 1.2;

group_uniforms opacity;
uniform float opacity_center : hint_range(0.0, 1.0) = 0.35;
uniform float opacity_edge : hint_range(0.0, 1.0) = 0.75;

group_uniforms surface;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.15;
uniform float specular_val : hint_range(0.0, 1.0) = 0.8;

group_uniforms emission;
uniform float emission_strength : hint_range(0.0, 2.0) = 0.25;

float fresnel(vec3 normal, vec3 view, float power) {
	return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), power);
}
void vertex() {
    VERTEX.y += sin(TIME * 1.5 + VERTEX.x * 3.0) * 0.02;
}
void fragment() {
	float fres = fresnel(NORMAL, VIEW, fresnel_power);

	vec3 color = mix(orb_color.rgb, orb_rim_color.rgb, fres * rim_intensity);

	ALBEDO = color;
	ALPHA = mix(opacity_center, opacity_edge, fres);

	ROUGHNESS = roughness_val;
	SPECULAR = specular_val;
	METALLIC = 0.0;

	EMISSION = orb_rim_color.rgb * fres * emission_strength;
}
