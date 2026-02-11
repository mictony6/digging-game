shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_front, unshaded;

// =============================================================
// Crystal / Jelly Body Shader — BACK FACE PASS
// Apply this to a DUPLICATE of the body mesh.
// Set this mesh's render priority LOWER than the front face
// (e.g., render_priority = -1) so it draws first.
//
// This renders the inside/back faces darker, creating a
// sense of volume and depth when seen through the front pass.
// =============================================================

group_uniforms color;
uniform vec4 back_color : source_color = vec4(0.02, 0.05, 0.5, 1.0);
uniform vec4 back_rim_color : source_color = vec4(0.1, 0.3, 0.9, 1.0);

group_uniforms fresnel;
uniform float fresnel_power : hint_range(0.5, 10.0) = 2.0;
uniform float rim_intensity : hint_range(0.0, 3.0) = 1.0;

group_uniforms opacity;
uniform float opacity_center : hint_range(0.0, 1.0) = 0.25;
uniform float opacity_edge : hint_range(0.0, 1.0) = 0.7;

group_uniforms emission;
uniform float emission_strength : hint_range(0.0, 1.0) = 0.15;

float fresnel(vec3 normal, vec3 view, float power) {
	// Flip normal since we're rendering back faces
	return pow(1.0 - clamp(dot(normalize(-normal), normalize(view)), 0.0, 1.0), power);
}
void vertex() {
    VERTEX.y += sin(TIME * 1.5 + VERTEX.x * 3.0) * 0.02;
}

void fragment() {
	float fres = fresnel(NORMAL, VIEW, fresnel_power);

	vec3 color = mix(back_color.rgb, back_rim_color.rgb, fres * rim_intensity);

	ALBEDO = color + back_rim_color.rgb * fres * emission_strength;
	ALPHA = mix(opacity_center, opacity_edge, fres);
}
