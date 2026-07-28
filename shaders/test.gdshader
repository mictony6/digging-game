// Star Nest by Pablo Roman Andrioli
// License: MIT
// World-space version: put this on a large sphere mesh (inverted or
// cull_disabled so you can see it from inside) parented to the player/camera.
// Because the ray direction comes from the sphere's own vertex positions
// instead of screen UV, the field stays fixed in world space as you look
// around — turning your head reveals different parts of it instead of the
// pattern following the screen.
//
// Setup:
//  - MeshInstance3D with a big SphereMesh (radius bigger than your scene,
//    e.g. 500+), material using this shader.
//  - render_mode cull_disabled lets you see the inside surface without
//    needing to flip the mesh normals.
//  - Parent the sphere to the player (or re-center it on the camera each
//    frame) so you're always inside it, but do NOT rotate the sphere with
//    the camera — only follow position.
//  - Parallax: the sphere's own world position nudges the raymarch origin,
//    so walking through the level shifts the field instead of it looking
//    glued in place. `parallax_scale` controls how strong that is.
//
//  Tuning for a sparse "dust near the player" look instead of a dense
//  swirling nebula: this fractal's default settings render 20 raymarch
//  steps of glowing fog, which is why it reads as vast outer space and why
//  parallax_scale felt so touchy — with that much rendered volume, the
//  chaotic formula has a lot of material to visibly swirl. The three
//  uniforms below control density directly:
//    - density_steps: how many of the (max 20) raymarch steps actually
//      render. Lower = less accumulated fog, more discrete specks.
//    - darkmatter_amount: how much of each step gets culled as "empty".
//      Higher = sparser, more gaps between visible dust.
//    - star_brightness: intensity per speck. Lower keeps individual motes
//      dim and pinprick-like instead of blown-out glowing clouds.
//  Defaults below are already set toward the sparse/dust end. Turning
//  density_steps and darkmatter_amount toward "sparse" also calms the
//  jitter/parallax sensitivity, since there's simply less volume for the
//  chaotic formula to swirl in response to small position changes.
//
//  IMPORTANT — jitter: this fractal is chaotic (each of the 17 iterations
//  amplifies tiny differences in the input), so the raymarch origin is
//  sensitive to noisy or high-frequency changes in position. Feeding it a
//  raw, un-smoothed position every frame — especially one only updated on
//  physics ticks — can show up as visible flicker. Fix it on the CPU side
//  by smoothing the follow position rather than snapping it exactly every
//  frame, e.g. in the script that keeps this sphere on the player:
//
//    func _process(delta: float) -> void:
//        var follow_speed := 6.0  # higher = snappier, lower = smoother
//        global_position = global_position.lerp(player.global_position, delta * follow_speed)

shader_type spatial;
render_mode blend_add, cull_disabled, depth_draw_never;

const int ITERATIONS = 17;
const float FORMUPARAM = 0.53;
const int MAX_VOLSTEPS = 20;
const float STEPSIZE = 0.1;
const float TILE = 0.850;
const float SPEED = 0.010;
const float DISTFADING = 0.730;
const float SATURATION = 0.850;

// Fixed initial orientation (was mouse-driven in the original Shadertoy demo).
const float A1 = 0.5;
const float A2 = 0.8;

// --- Density / "dust vs. nebula" controls ---
uniform int density_steps : hint_range(1, 20) = 8;
uniform float darkmatter_amount : hint_range(0.0, 1.0) = 0.65;
uniform float star_brightness : hint_range(0.0001, 0.01) = 0.0008;

// How much of the sphere's world-space movement bleeds into the fractal's
// own coordinate space. Keep this small — even 0.01-0.02 gives a clear
// sense of motion once density is turned down toward the dust end.
uniform float parallax_scale : hint_range(0.0, 1.0) = 0.02;

varying vec3 world_dir;
varying vec3 world_pos;

void vertex() {
	// VERTEX is local-space position on the sphere. For a sphere centered
	// at the mesh's origin, that's already the outward direction. Rotate
	// by the model matrix (w=0 so translation is ignored) so only the
	// mesh's own rotation affects it, then normalize.
	world_dir = normalize((MODEL_MATRIX * vec4(VERTEX, 0.0)).xyz);
	// Translation column of the model matrix — the sphere's (i.e. the
	// player's, if you keep it centered on them) position in world space.
	world_pos = MODEL_MATRIX[3].xyz;
}

void fragment() {
	vec3 dir = world_dir;
	float time = TIME * SPEED + 0.25;

	mat2 rot1 = mat2(vec2(cos(A1), sin(A1)), vec2(-sin(A1), cos(A1)));
	mat2 rot2 = mat2(vec2(cos(A2), sin(A2)), vec2(-sin(A2), cos(A2)));
	dir.xz *= rot1;
	dir.xy *= rot2;
	vec3 from = vec3(1.0, 0.5, 0.5);
	from += vec3(time * 2.0, time, -2.0);
	from += world_pos * parallax_scale;
	from.xz *= rot1;
	from.xy *= rot2;

	// volumetric rendering
	float s = 0.1;
	float fade = 1.0;
	vec3 v = vec3(0.0);
	for (int r = 0; r < MAX_VOLSTEPS; r++) {
		if (r >= density_steps) {
			break;
		}
		vec3 p = from + s * dir * 0.5;
		p = abs(vec3(TILE) - mod(p, vec3(TILE * 2.0))); // tiling fold
		float pa = 0.0;
		float a = 0.0;
		for (int i = 0; i < ITERATIONS; i++) {
			p = abs(p) / dot(p, p) - FORMUPARAM; // the magic formula
			a += abs(length(p) - pa); // absolute sum of average change
			pa = length(p);
		}
		float dm = max(0.0, darkmatter_amount - a * a * 0.001); // dark matter
		a *= a * a; // add contrast
		if (r > 6) {
			fade *= 1.0 - dm; // dark matter, don't render near
		}
		v += fade;
		v += vec3(s, s * s, s * s * s * s) * a * star_brightness * fade; // coloring based on distance
		fade *= DISTFADING; // distance fading
		s += STEPSIZE;
	}
	v = mix(vec3(length(v)), v, SATURATION); // color adjust

	ALBEDO = v * 0.01;
}
