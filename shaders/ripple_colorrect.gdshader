shader_type canvas_item;

// Per-instance: each CanvasItem using this same ShaderMaterial gets its
// own value, so tweening one ripple doesn't drive every other node's ring.
// Set via node.set_instance_shader_parameter("time", t), not the material.
instance uniform float time : hint_range(0.0, 1.0) = 0.0;
uniform float max_radius : hint_range(0.0, 1.0) = 0.5;
uniform float ring_width : hint_range(0.001, 0.2) = 0.02;
uniform vec4 ring_color : source_color = vec4(0.22, 0.54, 0.87, 1.0);
uniform vec2 center = vec2(0.5, 0.5);
// Set this from GDScript to the node's actual pixel size, e.g.
// material.set_shader_parameter("rect_size", color_rect.size)
uniform vec2 rect_size = vec2(300.0, 300.0);

// Cubic ease-out, matches the JS version
float ease_out_cubic(float t) {
	return 1.0 - pow(1.0 - t, 3.0);
}

void fragment() {
	// UV is 0-1 across the node's own bounds, so on a non-square rect
	// x and y cover different pixel distances per unit -- that's the squash.
	// Rescale by the node's own aspect ratio, not the screen's.
	float aspect = rect_size.x / rect_size.y;
	vec2 uv = UV;
	uv.x *= aspect;
	vec2 c = center;
	c.x *= aspect;

	float eased = ease_out_cubic(time);
	float radius = max_radius * eased;
	float alpha = 1.0 - time;

	float dist = distance(uv, c);
	float ring = smoothstep(radius - ring_width, radius, dist)
			- smoothstep(radius, radius + ring_width, dist);

	float fill = smoothstep(radius, radius - ring_width * 2.0, dist) * 0.12;

	float a = clamp(ring + fill, 0.0, 1.0) * alpha;

	COLOR = vec4(ring_color.rgb, a * ring_color.a);
}
