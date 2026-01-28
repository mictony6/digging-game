shader_type spatial;
render_mode   depth_draw_opaque, cull_back;

uniform sampler2D normalMapA : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D normalMapB : hint_normal, filter_linear_mipmap_anisotropic;
uniform float normalMapAStrength = 0.5;
uniform float normalMapBStrength = 0.5;
uniform float uvScale = 1.0;
uniform vec2 movementDirection = vec2(0.1, 0.1);
uniform float movementStrength = 0.5;
uniform float roughness : hint_range(0.0, 1.0, 0.1) = 0.2;
uniform sampler2D heightMap;
uniform float heightScale = 0.1;
varying vec2 uvMovement;

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), amount);
}

vec3 blendNormalsWhiteout(vec3 n1, vec3 n2) {
    return normalize(vec3(n1.xy + n2.xy, n1.z * n2.z));
}

void vertex() {
    uvMovement = movementDirection * TIME * movementStrength;
	vec2 uv = UV * uvScale;
 	float height = texture(heightMap, uv + uvMovement).x;
 	VERTEX.y += height * heightScale;
}

void fragment() {
    vec2 uv = UV * uvScale;
    float basic_fresnel = fresnel(3.0, NORMAL, VIEW);
    
    vec3 normalA = texture(normalMapA, uv + uvMovement).rgb * 2.0 - 1.0;
    vec3 normalB = texture(normalMapB, uv - uvMovement).rgb * 2.0 - 1.0;
    normalA.xy *= normalMapAStrength;
    normalB.xy *= normalMapBStrength;
    vec3 blended = blendNormalsWhiteout(normalA, normalB);
    
    ALBEDO = vec3(0.0);
    ROUGHNESS = roughness;
    METALLIC = 0.0;
    SPECULAR = 0.5;
    NORMAL_MAP = blended * 0.5 + 0.5;
}