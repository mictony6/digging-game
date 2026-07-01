shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float darkness : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float dark_threshold : hint_range(0.0, 1.0, 0.01) = 0.05;
uniform float bright_threshold : hint_range(0.0, 1.0, 0.01) = 0.35;
uniform float peripheral_strength : hint_range(0.0, 1.0, 0.01) = 0.3;
uniform float blur_amount : hint_range(0.0, 6.0, 0.1) = 2.0;

uniform mat3 camera_basis;
uniform float fov_tan = 0.577;
uniform float aspect_ratio = 1.777;

const vec3 LUM_WEIGHT = vec3(0.2126, 0.7152, 0.0722);

void fragment() {
	vec4 sharp = texture(SCREEN_TEXTURE, UV);
	float lum = dot(sharp.rgb, LUM_WEIGHT);

	vec4 blurred = textureLod(SCREEN_TEXTURE, UV, blur_amount * darkness);

	float dark_mask = smoothstep(bright_threshold, dark_threshold, lum) * darkness;

	vec3 base = mix(sharp.rgb, blurred.rgb, dark_mask);
	float grey = dot(base, LUM_WEIGHT);
	vec3 desaturated = mix(base, vec3(grey), dark_mask * 0.85);

	vec3 eigengrau = vec3(0.086, 0.082, 0.102);
	vec3 low_contrast = mix(desaturated, eigengrau, dark_mask * 0.6);
	low_contrast = mix(low_contrast, vec3(grey * 0.5 + 0.1), dark_mask * 0.4);

	float edge = smoothstep(0.1, 0.5, length(UV - 0.5));
	low_contrast += vec3(grey * edge * peripheral_strength * dark_mask * 0.4);

	COLOR = vec4(mix(sharp.rgb, low_contrast, darkness), sharp.a);
}
