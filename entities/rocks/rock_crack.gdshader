shader_type spatial;
render_mode diffuse_burley, depth_draw_opaque, cull_back;

uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_rougness : hint_roughness_gray, filter_linear_mipmap_anisotropic;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap;
uniform sampler2D crack_map : source_color, filter_linear_mipmap_anisotropic;

instance uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform vec3 crack_color : source_color = vec3(1.0, 0.3, 0.0);
uniform float crack_emission_strength : hint_range(0.0, 5.0) = 2.0;
uniform float crack_edge_softness : hint_range(0.01, 0.5) = 0.1;
uniform float crack_normal_strength : hint_range(0.0, 5.0) = 2.0;
uniform float crack_scale : hint_range(0.1, 10.0) = 1.0;
uniform float rim : hint_range(0.0, 1.0, 0.01);
uniform float rim_tint : hint_range(0.0, 1.0, 0.01);
uniform sampler2D texture_rim : hint_default_white, filter_linear_mipmap, repeat_enable;

varying vec3 local_pos;
varying vec3 local_normal;
varying vec3 v_tangent;
varying vec3 v_binormal;

void vertex() {
    local_pos = VERTEX * crack_scale;
    local_normal = NORMAL;
    v_tangent = TANGENT;
    v_binormal = BINORMAL;
}

vec3 triplanar_weights(vec3 normal) {
    vec3 w = abs(normal);
    w = pow(w, vec3(4.0));
    return w / (w.x + w.y + w.z);
}

float sample_crack_triplanar(vec3 pos, vec3 weights) {
    float c_xy = texture(crack_map, pos.xy).r;
    float c_xz = texture(crack_map, pos.xz).r;
    float c_yz = texture(crack_map, pos.yz).r;
    return c_xy * weights.z + c_xz * weights.y + c_yz * weights.x;
}

float get_crack_triplanar(vec3 pos, vec3 weights) {
    float crack = sample_crack_triplanar(pos, weights);
    float threshold = 1.0 - damage;
    return smoothstep(threshold, threshold + crack_edge_softness, crack);
}

void fragment() {
    vec4 base = texture(rock_albedo, UV);
    vec3 rock_n = texture(rock_normal, UV).rgb;
    vec3 weights = triplanar_weights(local_normal);

    float crack_mask = get_crack_triplanar(local_pos, weights);

    // Crack normals via finite differences in local space
    float eps = 0.01 / crack_scale;
    float c  = get_crack_triplanar(local_pos, weights);
    float cx = get_crack_triplanar(local_pos + vec3(eps, 0.0, 0.0), weights);
    float cy = get_crack_triplanar(local_pos + vec3(0.0, eps, 0.0), weights);
    float cz = get_crack_triplanar(local_pos + vec3(0.0, 0.0, eps), weights);

    // Local-space gradient
    vec3 local_grad = vec3(cx - c, cy - c, cz - c) / eps;

    // Project onto tangent frame for tangent-space perturbation
    float grad_t = dot(local_grad, v_tangent);
    float grad_b = dot(local_grad, v_binormal);

    // Tangent-space crack normal
    vec3 crack_ts = normalize(vec3(
        grad_t * crack_normal_strength,
        grad_b * crack_normal_strength,
        1.0
    ));
    vec3 crack_n = crack_ts * 0.5 + 0.5;

    // RNM blend rock + crack normals
    vec3 base_unpack = rock_n * 2.0 - 1.0;
    vec3 crack_unpack = crack_n * 2.0 - 1.0;
    vec3 t = base_unpack + vec3(0.0, 0.0, 1.0);
    vec3 u = crack_unpack * vec3(-1.0, -1.0, 1.0);
    vec3 blended = normalize(t * dot(t, u) - u * t.z);
    vec3 final_normal = mix(rock_n, blended * 0.5 + 0.5, crack_mask);

    // Darken albedo along cracks
    vec3 final_albedo = mix(base.rgb, base.rgb * 0.15, crack_mask);

    // Glow
    vec3 emission = crack_color * crack_mask * crack_emission_strength * damage;

    ALBEDO = final_albedo;
    ROUGHNESS = texture(rock_rougness, UV).r;
    NORMAL_MAP = final_normal;
    NORMAL_MAP_DEPTH = 1.0;
    EMISSION = emission;

    // Rim
    vec2 rim_tex = texture(texture_rim, UV).xy;
    RIM = rim * rim_tex.x;
    RIM_TINT = rim_tint * rim_tex.y;
}