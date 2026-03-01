shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float fov : hint_range(30.0, 170.0, 1.0) = 90.0;
uniform float panini_strength : hint_range(0.0, 1.0, 0.01) = 1.0;

void fragment() {
    // Map UV from [0,1] to [-1,1]
    vec2 uv = SCREEN_UV * 2.0 - 1.0;

    // Half FOV in radians
    float half_fov = radians(fov) * 0.5;
    float d = tan(half_fov);

    // Convert screen coords to view-space angles
    float x_angle = atan(uv.x * d);
    float y_angle = atan(uv.y * d);

    // Panini projection: cylindrical horizontal, rectilinear vertical
    // Map back from Panini space to rectilinear screen UV
    float panini_x = tan(x_angle) / d;
    float cos_x = cos(x_angle);
    float panini_y = (uv.y * d / cos_x) / d;

    // Blend between original and Panini based on strength
    vec2 warped = mix(uv, vec2(panini_x, panini_y), panini_strength);

    // Back to [0,1]
    vec2 final_uv = warped * 0.5 + 0.5;

    // Black outside valid range
    if (final_uv.x < 0.0 || final_uv.x > 1.0 || final_uv.y < 0.0 || final_uv.y > 1.0) {
        COLOR = vec4(0.0, 0.0, 0.0, 1.0);
    } else {
        COLOR = texture(screen_texture, final_uv);
    }
}