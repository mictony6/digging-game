shader_type particles;

// -- Emission --
uniform float emission_radius : hint_range(0.0, 5.0) = 0.5;
uniform float emission_speed_min : hint_range(0.0, 20.0) = 1.0;
uniform float emission_speed_max : hint_range(0.0, 20.0) = 3.5;

// -- Motion --
uniform float gravity : hint_range(-10.0, 10.0) = -1.5;
uniform float drag : hint_range(0.0, 10.0) = 2.0;
uniform float turbulence_strength : hint_range(0.0, 5.0) = 0.4;
uniform float turbulence_speed : hint_range(0.0, 10.0) = 2.0;

// -- Appearance --
uniform float scale_min : hint_range(0.01, 2.0) = 0.08;
uniform float scale_max : hint_range(0.01, 2.0) = 0.25;
uniform float fade_in : hint_range(0.0, 1.0) = 0.05;
uniform float fade_out_start : hint_range(0.0, 1.0) = 0.4;
uniform vec4 color_start : source_color = vec4(0.65, 0.55, 0.4, 0.9);
uniform vec4 color_end : source_color = vec4(0.5, 0.45, 0.35, 0.0);

// Simple hash-based random
float hash(float n) {
	return fract(sin(n) * 43758.5453123);
}

vec3 random_point_on_sphere(float seed) {
	float theta = hash(seed) * 6.2831853;
	float phi = acos(2.0 * hash(seed + 1.0) - 1.0);
	return vec3(
		sin(phi) * cos(theta),
		sin(phi) * sin(theta),
		cos(phi)
	);
}

void start() {
	float seed = float(INDEX) * 13.37 + float(RANDOM_SEED);

	// Spawn on a random point within a sphere
	vec3 dir = random_point_on_sphere(seed);
	float radius_t = pow(hash(seed + 2.0), 0.333); // cube root for uniform volume distribution
	TRANSFORM[3].xyz = dir * radius_t * emission_radius;

	// Velocity: burst outward from center
	float speed = mix(emission_speed_min, emission_speed_max, hash(seed + 3.0));
	VELOCITY = dir * speed;

	// Random rotation
	float angle = hash(seed + 4.0) * 6.2831853;
	TRANSFORM[0].xyz = vec3(cos(angle), -sin(angle), 0.0);
	TRANSFORM[1].xyz = vec3(sin(angle), cos(angle), 0.0);
	TRANSFORM[2].xyz = vec3(0.0, 0.0, 1.0);

	// Random scale per particle
	float s = mix(scale_min, scale_max, hash(seed + 5.0));
	TRANSFORM[0].xyz *= s;
	TRANSFORM[1].xyz *= s;
	TRANSFORM[2].xyz *= s;

	// Store initial custom data (we'll use CUSTOM.x for per-particle random)
	CUSTOM.x = hash(seed + 6.0);
	CUSTOM.y = 0.0;
}

void process() {
	float t = CUSTOM.y / LIFETIME;

	// Apply drag (exponential slowdown)
	VELOCITY *= 1.0 - drag * DELTA;

	// Gravity
	VELOCITY.y += gravity * DELTA;

	// Turbulence: small random-ish sideways drift
	float turb_time = TIME * turbulence_speed + CUSTOM.x * 100.0;
	vec3 turb = vec3(
		sin(turb_time * 1.1 + float(INDEX) * 0.7),
		sin(turb_time * 0.9 + float(INDEX) * 1.3),
		sin(turb_time * 1.3 + float(INDEX) * 0.5)
	) * turbulence_strength;
	VELOCITY += turb * DELTA;

	// Color interpolation with alpha fade
	float fade_alpha = 1.0;
	if (t < fade_in) {
		fade_alpha = t / fade_in;
	} else if (t > fade_out_start) {
		fade_alpha = 1.0 - (t - fade_out_start) / (1.0 - fade_out_start);
	}
	fade_alpha = clamp(fade_alpha, 0.0, 1.0);

	COLOR = mix(color_start, color_end, t);
	COLOR.a *= fade_alpha;

	// Track lifetime
	CUSTOM.y += DELTA;
}
