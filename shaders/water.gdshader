shader_type spatial;
render_mode depth_draw_opaque, cull_back, diffuse_burley;

group_uniforms Colors;
uniform vec4 primaryColor : source_color;
uniform vec4 secondaryColor: source_color;
uniform float roughness : hint_range(0.0, 1.0, 0.1)  = 0.2;
group_uniforms NormalMaps;
uniform sampler2D normalMapA : hint_normal, filter_linear_mipmap_anisotropic ;
uniform sampler2D normalMapB : hint_normal, filter_linear_mipmap_anisotropic;
uniform float normalMapAStrength = 0.5;
uniform float normalMapBStrength = 0.5;
group_uniforms Movement;
uniform float heightScale = 0.1;
uniform float uvScale = 1.0;
uniform vec2 movementDirection = vec2(0.1, 0.1);
uniform vec2 movementDirectionA = vec2(0.1, 0.1);
uniform vec2 movementDirectionB = vec2(-0.1, 0.1);
uniform float movementStrength = 0.5;
group_uniforms Refraction;
uniform float refractionStrength : hint_range(0.0, 0.1, 0.001) = 0.02;
group_uniforms Reflection;
// Sampling the screen/depth textures forces this material into the
// transparent pass, which Godot's built-in SSR never touches. Reflections are
// instead raymarched here against the depth texture (see trace_ssr), with the
// ReflectionProbe/sky IBL as the fallback wherever the ray misses.
uniform float metallic : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform bool ssr_enabled = true;
uniform int ssr_steps : hint_range(4, 64) = 24;
uniform float ssr_max_distance : hint_range(1.0, 100.0, 0.5) = 20.0;
// Max depth gap at the refined hit still counted as a hit -- rejects rays
// that slip behind foreground objects instead of reflecting them.
uniform float ssr_thickness : hint_range(0.01, 5.0, 0.01) = 0.5;
uniform float ssr_strength : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform float ssr_edge_fade : hint_range(0.0, 0.5, 0.01) = 0.1;
// Screen-texture mip level for the reflection; scaled up with ray length so
// reflections soften the farther the reflected object is from the surface.
uniform float ssr_blur : hint_range(0.0, 6.0, 0.1) = 0.0;
// Full normal-map detail makes reflections noisy; blend toward the
// geometric normal for a calmer mirror.
uniform float ssr_normal_influence : hint_range(0.0, 1.0, 0.01) = 0.3;
group_uniforms Foam;
uniform sampler2D foamTexture : filter_linear_mipmap_anisotropic;
uniform vec4 foamColor : source_color = vec4(1.0);
uniform float foamDepth : hint_range(0.0, 5.0, 0.01) = 1.0;
uniform float foamStrength : hint_range(0.0, 1.0, 0.01) = 0.8;
uniform float foamScale : hint_range(0.1, 10.0, 0.1) = 1.0;
group_uniforms Depth;
uniform float depthDistance : hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beersLaw : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float waterTransparency : hint_range(0.0, 1.0, 0.01) = 0.05;
group_uniforms Ripples;
uniform vec2 ripple_origin = vec2(99999.0, 99999.0);
uniform float ripple_origin_scale : hint_range(0.0, 1.0, 0.01) = 1.0;
uniform vec2 ripple_trail_pos[12];
// Ages are initialized to sit past ripple_trail_lifetime by WaterEffects at
// _ready() so unpopulated slots fade to zero contribution instead of reading
// as an always-fresh ripple at (0,0) -- Godot doesn't support default values
// on uniform arrays.
uniform float ripple_trail_age[12];
uniform float ripple_trail_lifetime : hint_range(0.5, 5.0, 0.1) = 2.5;
uniform float ripple_speed : hint_range(0.5, 12.0, 0.1) = 4.0;
uniform float ripple_frequency : hint_range(1.0, 30.0, 0.5) = 9.0;
uniform float ripple_amplitude : hint_range(0.0, 0.15, 0.001) = 0.018;
uniform float ripple_trail_scale : hint_range(0.0, 1.0, 0.01) = 0.4;
uniform float ripple_falloff : hint_range(0.1, 5.0, 0.05) = 1.2;

varying vec2 uvMovement;
varying vec2 uvMovementA;
varying vec2 uvMovementB;
varying vec2 world_xz_pos;

uniform sampler2D depthTexture : hint_depth_texture, repeat_disable, filter_linear_mipmap_anisotropic;
// Unfiltered depth for the SSR trace: linear filtering blends foreground and
// background depths at silhouettes into a fake slope that rays hit, smearing
// object edges into the reflection.
uniform sampler2D ssrDepthTexture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screenTexture: hint_screen_texture,  repeat_disable, filter_linear_mipmap_anisotropic;


float fresnel(float amount, vec3 normal, vec3 view){
	return pow((1.0- clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}
vec3 blendNormalsWhiteout(vec3 n1, vec3 n2) {
    return normalize(vec3(n1.xy + n2.xy, n1.z * n2.z));
}

vec3 reorientNormals(vec3 n1, vec3 n2) {
    vec3 t = n1 + vec3(0.0, 0.0, 1.0);
    vec3 u = n2 * vec3(-1.0, -1.0, 1.0);
    return normalize(t * dot(t, u) / t.z - u);
}

float ripple_height(vec2 pos) {
	// Continuous ripple at current player position — always animated via TIME
	float dist0 = length(pos - ripple_origin);
	float falloff0 = exp(-dist0 * ripple_falloff);
	float live = sin(dist0 * ripple_frequency - TIME * ripple_speed) * ripple_amplitude * falloff0 * ripple_origin_scale;
	// Higher-frequency ripple on top breaks the single rounded sine into
	// sharper chop instead of one smooth bulging wave.
	live += sin(dist0 * ripple_frequency * 2.7 - TIME * ripple_speed * 1.6) * ripple_amplitude * 0.35 * falloff0 * ripple_origin_scale;

	// Trail wake — each point expands from where it was born, fades over lifetime
	float trail = 0.0;
	for (int i = 0; i < 12; i++) {
		float age = ripple_trail_age[i];
		float fade = 1.0 - smoothstep(0.5, 1.0, age / ripple_trail_lifetime);
		if (fade <= 0.0) continue;
		float dist = length(pos - ripple_trail_pos[i]);
		float falloff = exp(-dist * ripple_falloff);
		trail += sin(dist * ripple_frequency - age * ripple_speed) * ripple_amplitude * ripple_trail_scale * falloff * fade;
	}
	return live + trail;
}

vec2 view_to_uv(vec3 p, mat4 proj) {
	vec4 clip = proj * vec4(p, 1.0);
	return clip.xy / clip.w * 0.5 + 0.5;
}

float scene_view_z(vec2 uv, mat4 inv_proj) {
	float d = textureLod(ssrDepthTexture, uv, 0.0).r;
	vec4 v = inv_proj * vec4(uv * 2.0 - 1.0, d, 1.0);
	return v.z / v.w;
}

// View-space linear march + binary refinement. Returns (color, confidence).
vec4 trace_ssr(vec3 origin, vec3 dir, mat4 proj, mat4 inv_proj, float jitter) {
	float step_len = ssr_max_distance / float(ssr_steps);
	float t_prev = 0.0;
	float t = step_len * jitter;
	for (int i = 0; i < ssr_steps; i++) {
		t += step_len;
		vec3 p = origin + dir * t;
		if (p.z > -0.05) break; // ray went behind the camera
		vec2 uv = view_to_uv(p, proj);
		if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) break;

		// View space looks down -Z: positive delta means the ray is behind the scene.
		if (scene_view_z(uv, inv_proj) - p.z > 0.0) {
			float lo = t_prev;
			float hi = t;
			for (int j = 0; j < 5; j++) {
				float mid = (lo + hi) * 0.5;
				vec3 pm = origin + dir * mid;
				if (scene_view_z(view_to_uv(pm, proj), inv_proj) - pm.z > 0.0) hi = mid;
				else lo = mid;
			}
			vec3 hit = origin + dir * hi;
			vec2 hit_uv = view_to_uv(hit, proj);
			if (scene_view_z(hit_uv, inv_proj) - hit.z > ssr_thickness) {
				t_prev = t;
				continue;
			}
			vec2 edge = smoothstep(vec2(0.0), vec2(ssr_edge_fade), hit_uv)
				* smoothstep(vec2(0.0), vec2(ssr_edge_fade), 1.0 - hit_uv);
			float fade = edge.x * edge.y * (1.0 - smoothstep(0.6, 1.0, hi / ssr_max_distance));
			float lod = ssr_blur * mix(0.3, 1.0, clamp(hi / ssr_max_distance * 3.0, 0.0, 1.0));
			if (lod <= 0.0) return vec4(textureLod(screenTexture, hit_uv, 0.0).rgb, fade);
			// Four taps half a texel apart at the chosen mip smooth out the
			// blockiness of sampling a single low mip.
			vec2 texel = exp2(lod) * 0.5 / vec2(textureSize(screenTexture, 0));
			vec3 col = textureLod(screenTexture, hit_uv + vec2( texel.x,  texel.y), lod).rgb
				+ textureLod(screenTexture, hit_uv + vec2(-texel.x,  texel.y), lod).rgb
				+ textureLod(screenTexture, hit_uv + vec2( texel.x, -texel.y), lod).rgb
				+ textureLod(screenTexture, hit_uv + vec2(-texel.x, -texel.y), lod).rgb;
			return vec4(col * 0.25, fade);
		}
		t_prev = t;
	}
	return vec4(0.0);
}

void vertex() {
	uvMovement = movementDirection * TIME * movementStrength;
	uvMovementA = movementDirectionA * TIME * movementStrength;
	uvMovementB = movementDirectionB * TIME * movementStrength;
	vec2 uv = UV * uvScale;
	// Height derived straight from the two normal maps' tilt (no separate
	// height texture) -- the X-tilt channel is signed, so it bobs up where a
	// normal leans one way and down where it leans the other, roughly
	// tracking each map's local peaks/troughs.
	vec3 heightNormalA = texture(normalMapA, uv + uvMovementA).rgb * 2.0 - 1.0;
	vec3 heightNormalB = texture(normalMapB, uv + uvMovementB).rgb * 2.0 - 1.0;
	float height = heightNormalA.x * normalMapAStrength + heightNormalB.x * normalMapBStrength;
 	VERTEX.y += height * heightScale;

	world_xz_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	VERTEX.y += ripple_height(world_xz_pos);
}
void fragment() {
	vec2 uv = UV * uvScale;
	float basic_fresnel = fresnel(3.0, NORMAL, VIEW);
	vec3 normalA = texture(normalMapA, uv + uvMovementA).rgb * 2.0 - 1.0;
	vec3 normalB = texture(normalMapB, uv + uvMovementB).rgb * 2.0 - 1.0;

	normalA.xy *= normalMapAStrength ;
    normalB.xy *= normalMapBStrength;
	vec3 blended = reorientNormals(normalA, normalB);

	// Ripple normal via finite differences
	float eps = 0.06;
	float h0 = ripple_height(world_xz_pos);
	float dhdx = (ripple_height(world_xz_pos + vec2(eps, 0.0)) - h0) / eps;
	float dhdz = (ripple_height(world_xz_pos + vec2(0.0, eps)) - h0) / eps;
	vec3 ripple_norm = normalize(vec3(-dhdx, -dhdz, 1.0));
	blended = reorientNormals(blended, ripple_norm);

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

	// Screen-space reflections
	vec4 ssr = vec4(0.0);
	float reflectAmount = 0.0;
	if (ssr_enabled) {
		vec3 detailNormal = normalize(TANGENT * blended.x + BINORMAL * blended.y + NORMAL * blended.z);
		vec3 ssrNormal = normalize(mix(NORMAL, detailNormal, ssr_normal_influence));
		vec3 reflDir = reflect(normalize(VERTEX), ssrNormal);
		// Downward rays would just reflect the lakebed through the surface.
		if ((INV_VIEW_MATRIX * vec4(reflDir, 0.0)).y > 0.0) {
			float jitter = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
			ssr = trace_ssr(VERTEX, reflDir, PROJECTION_MATRIX, INV_PROJECTION_MATRIX, jitter);
		}
		float schlick = 0.02 + 0.98 * pow(1.0 - clamp(dot(ssrNormal, VIEW), 0.0, 1.0), 5.0);
		reflectAmount = ssr.a * schlick * ssr_strength * (1.0 - foam);
	}

	// Add foam on top
	ALBEDO = mix(finalColor, foamColor.rgb, foam) * (1.0 - reflectAmount);
	// The screen sample is already lit, so it goes in as emission rather than
	// albedo. Where SSR hits, the probe/sky specular is faded out so the two
	// reflections don't stack; where it misses, IBL reflection takes over.
	EMISSION = ssr.rgb * reflectAmount;
	SPECULAR = 0.5 * (1.0 - ssr.a * ssr_strength);
	ROUGHNESS = mix(roughness * (1.0 - basic_fresnel), 1.0, foam);
	NORMAL_MAP = blended * 0.5 + 0.5;
	METALLIC = mix(metallic, 0.0, foam);
}
