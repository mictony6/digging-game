shader_type spatial;
render_mode blend_add, unshaded, cull_disabled;

// Fully procedural laser. The mesh is a unit quad whose geometry is rebuilt in
// vertex(): stretched along local -Z to beam_length and billboarded around
// that axis so it always faces the camera. No textures, no curves.

uniform vec4 color : source_color = vec4(0.43, 0.4, 0.82, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float beam_width : hint_range(0.005, 0.5) = 0.05;
uniform float core_size : hint_range(0.01, 1.0) = 0.35;
uniform float emission_energy : hint_range(0.0, 20.0) = 6.0;
uniform float pulse_speed : hint_range(0.0, 30.0) = 8.0;      // meters per second toward target
uniform float pulse_frequency : hint_range(0.0, 20.0) = 4.0;  // waves per meter
uniform float pulse_strength : hint_range(0.0, 1.0) = 0.35;
uniform float flicker_strength : hint_range(0.0, 1.0) = 0.15;
uniform float impact_boost : hint_range(0.0, 5.0) = 2.0;      // extra brightness at the hit point
uniform float curve_arc : hint_range(-1.0, 1.0) = 0.12;       // midsection arc: positive = up, negative = droop
uniform float wave_amplitude : hint_range(0.0, 0.5) = 0.05;   // side-to-side wander of the midsection, meters
uniform float wave_amplitude_vertical : hint_range(0.0, 0.5) = 0.03; // up-and-down wander, meters
uniform float wave_frequency : hint_range(0.0, 8.0) = 1.5;    // wander waves along the beam
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wave_tip_fade : hint_range(0.0, 2.0) = 0.4;     // meters before the hit point where the wander dies out

uniform float launch_strength : hint_range(0.0, 2.0) = 0.5;  // how far it commits to the emitter's direction before bending

// Set per-frame from beam.gd via set_instance_shader_parameter().
instance uniform float beam_length = 1.0;
instance uniform vec3 target_local = vec3(0.0, 0.0, -1.0);    // hit point in the beam node's space
instance uniform float progress : hint_range(0.0, 1.0) = 1.0; // grow-out reveal on show

varying float side; // -1..1 across the beam
varying float dist; // world-space meters along the beam

void vertex() {
	float t = UV.y; // 0 = emitter, 1 = target
	side = UV.x * 2.0 - 1.0;

	mat4 inv_model = inverse(MODEL_MATRIX);

	// Quadratic Bezier spine: leaves the emitter along the node's own -Z
	// (wherever the tool is pointing), then bends over to reach the target.
	vec3 p2 = target_local;
	float chord = max(length(p2), 0.001);
	vec3 p1 = vec3(0.0, 0.0, -1.0) * chord * launch_strength;

	float u = 1.0 - t;
	vec3 pos = 2.0 * u * t * p1 + t * t * p2;
	vec3 tangent = normalize(2.0 * u * p1 + 2.0 * t * (p2 - p1) + vec3(1e-5));

	dist = t * beam_length;

	// Extra bending on top of the spine. The envelope is zero at both ends,
	// so the beam stays anchored to the tool tip and the hit point.
	float env = sin(PI * t);
	float len_scale = clamp(beam_length * 0.5, 0.0, 1.0); // short beams bend less

	vec3 up_local = normalize((inv_model * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec3 bend = up_local * curve_arc * env * env;

	// Midsection wander: independent side-to-side and up-and-down waves, each
	// layered with an offbeat harmonic so the motion isn't metronomic. The two
	// axes run at unrelated frequencies so the combined path never repeats.
	vec3 side_horiz = normalize(cross(tangent, up_local) + vec3(1e-5, 0.0, 0.0));
	float wh = sin(t * TAU * wave_frequency - TIME * wave_speed)
			+ 0.5 * sin(t * TAU * wave_frequency * 2.3 - TIME * wave_speed * 1.31 + 1.7);
	float wv = sin(t * TAU * wave_frequency * 1.4 - TIME * wave_speed * 0.83 + 0.9)
			+ 0.5 * sin(t * TAU * wave_frequency * 3.1 - TIME * wave_speed * 1.7 + 2.6);
	// Wavy as it leaves the tool, settling into a straight line at the target.
	float tip_env = smoothstep(0.0, max(wave_tip_fade, 0.001), beam_length - dist);
	bend += (side_horiz * wh * wave_amplitude + up_local * wv * wave_amplitude_vertical) * env * tip_env;

	pos += bend * len_scale;

	// Billboard around the local tangent of the curve toward the camera.
	vec3 cam_local = (inv_model * vec4(INV_VIEW_MATRIX[3].xyz, 1.0)).xyz;
	vec3 side_dir = normalize(cross(tangent, cam_local - pos) + vec3(1e-5, 0.0, 0.0));

	float breathe = 1.0 + 0.08 * sin(TIME * 4.0);
	VERTEX = pos + side_dir * side * beam_width * breathe;
}

void fragment() {
	float r = abs(side);

	// Radial profile: hot core, soft glow.
	float core = 1.0 - smoothstep(0.0, core_size, r);
	float glow = pow(1.0 - r, 2.0);

	// Energy pulses traveling toward the target, layered with an offbeat
	// harmonic so the rhythm doesn't read as a plain sine.
	float pulse = 1.0 - pulse_strength * (0.5 + 0.5 * sin(dist * pulse_frequency - TIME * pulse_speed));
	pulse *= 1.0 - pulse_strength * 0.5 * (0.5 + 0.5 * sin(dist * pulse_frequency * 2.7 - TIME * pulse_speed * 1.9));

	// Whole-beam flicker.
	float flicker = 1.0 - flicker_strength * (0.5 + 0.5 * sin(TIME * 43.0) * sin(TIME * 17.0));

	// Soft fade at the emitter; brighten near the impact point.
	float head = smoothstep(0.0, 0.05, dist);
	float impact = 1.0 + impact_boost * smoothstep(beam_length - 0.15, beam_length, dist);

	// Grow-out reveal: the front edge sweeps from emitter to target on show.
	float reveal = 1.0 - smoothstep(progress * beam_length - 0.05, progress * beam_length + 0.15, dist);

	vec3 col = mix(color.rgb, core_color.rgb, core);
	float intensity = (glow * 0.6 + core) * pulse * flicker * head * reveal;

	// EMISSION is ignored in unshaded mode: output HDR color through ALBEDO
	// so WorldEnvironment glow still picks it up.
	ALBEDO = col * intensity * emission_energy * impact;
	ALPHA = clamp(intensity, 0.0, 1.0) * color.a;
}
