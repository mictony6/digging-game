shader_type spatial;

render_mode blend_mix, depth_prepass_alpha, cull_back, diffuse_burley, specular_schlick_ggx;
uniform sampler2D DEPTH_TEXTURE : hint_depth_texture;
uniform sampler2D albedo_texture : source_color;
uniform float fade_distance : hint_range(0.01, 0.5) = 0.08;
uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;

void fragment() {

    vec4 tex = texture(albedo_texture, UV);
    ALBEDO = tex.rgb;
    ROUGHNESS = roughness;
    METALLIC = metallic;

    float scene_depth = textureLod(DEPTH_TEXTURE, SCREEN_UV, 0.0).r;
    float frag_depth = FRAGCOORD.z;

    float depth_diff = scene_depth - frag_depth;

    float fade = depth_diff / fade_distance;

    if (fade <= 0.0) {
        discard;
    }
}