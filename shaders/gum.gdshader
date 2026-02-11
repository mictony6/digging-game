shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

uniform vec4 base_color : source_color = vec4(0.05, 0.15, 0.8, 0.4);
uniform vec4 rim_color : source_color = vec4(0.3, 0.6, 1.0, 1.0);
uniform float fresnel_power : hint_range(0.5, 8.0) = 2.5;
uniform float rim_intensity : hint_range(0.0, 3.0) = 1.5;
uniform float opacity_min : hint_range(0.0, 1.0) = 0.15;
uniform float opacity_max : hint_range(0.0, 1.0) = 0.85;
uniform float roughness_val : hint_range(0.0, 1.0) = 0.3;
uniform float specular_val : hint_range(0.0, 1.0) = 0.6;

float fresnel(vec3 normal, vec3 view, float power) {
    return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), power);
}

void fragment() {
    float fres = fresnel(NORMAL, VIEW, fresnel_power);

    // Color blends from deep interior to bright rim
    vec3 color = mix(base_color.rgb, rim_color.rgb, fres * rim_intensity);
    ALBEDO = color;

    // Opacity: transparent in center, opaque at edges
    ALPHA = mix(opacity_min, opacity_max, fres);

    ROUGHNESS = roughness_val;
    SPECULAR = specular_val;
    METALLIC = 0.0;

    // Slight emission for the glow
    EMISSION = rim_color.rgb * fres * 0.3;
}


