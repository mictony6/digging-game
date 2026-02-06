shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_burley;
group_uniforms Colors;
uniform vec4 primaryColor : source_color;
uniform vec4 secondaryColor: source_color;
uniform float roughness : hint_range(0.0, 1.0, 0.1)  = 0.2;
group_uniforms NormalMaps;
uniform sampler2D normalMapA : hint_normal, filter_linear_mipmap_anisotropic ;
uniform sampler2D normalMapB : hint_normal, filter_linear_mipmap_anisotropic;
uniform sampler2D heightMap;
uniform float normalMapAStrength = 0.5;
uniform float normalMapBStrength = 0.5;
group_uniforms Movement;
uniform float heightScale = 0.1;
uniform float uvScale = 1.0;
uniform vec2 movementDirection = vec2(0.1, 0.1);
uniform float movementStrength = 0.5;
group_uniforms Refraction;
uniform float refractionStrength : hint_range(0.0, 0.1, 0.001) = 0.02;
group_uniforms Foam;
uniform sampler2D foamTexture : filter_linear_mipmap_anisotropic;
uniform vec4 foamColor : source_color = vec4(1.0);
uniform float foamDepth : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float foamStrength : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float foamScale : hint_range(0.1, 10.0, 0.1) = 1.0;
varying vec2 uvMovement;
uniform sampler2D depthTexture : hint_depth_texture, repeat_disable, filter_linear_mipmap_anisotropic;
uniform sampler2D screenTexture: hint_screen_texture,  repeat_disable, filter_linear_mipmap_anisotropic;
group_uniforms Depth;
uniform float depthDistance : hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beersLaw : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float waterTransparency : hint_range(0.0, 1.0, 0.01) = 0.05;


float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0- clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
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
	
	// Refracted UV
	vec2 refractedUV = SCREEN_UV + blended.xy * refractionStrength;
	
	// Check if refracted sample is behind water surface
	float refractedDepth = textureLod(depthTexture, refractedUV, 0.0).r;
	float waterSurfaceDepth = FRAGCOORD.z;
	
	// Only use refraction if sample is behind water
	vec2 finalUV = refractedDepth < waterSurfaceDepth ? refractedUV : SCREEN_UV;
	
	float depth = textureLod(depthTexture, finalUV, 0.0).r;
	vec3 screen = textureLod(screenTexture, finalUV, 0.0).rgb;
	
	//depth
	vec3 ndc = vec3(finalUV * 2.0 - 1.0, depth);
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	float depthTextureY = world.y / world.w;
	float vertexY = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;
	
	float depthBlend = clamp((vertexY - depthTextureY) / depthDistance, 0.0, 1.0);
	depthBlend = exp(-depthBlend * beersLaw);
	
	// Foam
	vec2 foamUV = uv * foamScale - uvMovement;
	float foamTex = texture(foamTexture, foamUV).r;
	float foamMask = 1.0 - clamp((vertexY - depthTextureY) / foamDepth, 0.0, 1.0);
	float foam = foamTex * foamMask * foamStrength;
	
	vec3 depthColor = mix(secondaryColor, primaryColor, depthBlend).rgb;
	vec3 finalColor = mix(depthColor.rgb, screen, waterTransparency);
	finalColor = mix(finalColor, screen, depthBlend * (1.0 - basic_fresnel));
	
	// Add foam on top
	ALBEDO = mix(finalColor, foamColor.rgb, foam);
	ROUGHNESS = mix(roughness * (1.0 - basic_fresnel), 1.0, foam);
	NORMAL_MAP = blended * 0.5 + 0.5;
	METALLIC = 0.0;
}