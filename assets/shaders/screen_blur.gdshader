shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_strength : hint_range(0.0, 8.0) = 2.5;
uniform vec4 tint_color : source_color = vec4(0.0, 0.0, 0.0, 0.45);

void fragment() {
	vec2 pixel = blur_strength / vec2(textureSize(SCREEN_TEXTURE, 0));
	vec4 col = vec4(0.0);

	// 3x3 box blur with weighted center
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel.x, -pixel.y)) * 0.0625;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0,      -pixel.y)) * 0.125;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( pixel.x, -pixel.y)) * 0.0625;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel.x,  0.0))     * 0.125;
	col += texture(SCREEN_TEXTURE, SCREEN_UV)                            * 0.25;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( pixel.x,  0.0))     * 0.125;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-pixel.x,  pixel.y)) * 0.0625;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0,       pixel.y)) * 0.125;
	col += texture(SCREEN_TEXTURE, SCREEN_UV + vec2( pixel.x,  pixel.y)) * 0.0625;

	// Blend blurred result with dark tint
	col.rgb = mix(col.rgb, tint_color.rgb, tint_color.a);
	COLOR = vec4(col.rgb, 1.0);
}
