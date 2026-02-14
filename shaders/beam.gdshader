shader_type spatial;
render_mode cull_disabled;
uniform sampler2D main_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 base_color : source_color;
uniform float brightness : hint_range(0.0, 10.0, 0.1) = 1.0;
uniform float fade_progress : hint_range(0.0, 1.0, 0.01) = 1.0; // 0 = invisible, 1 = fully visible



//void vertex() {
//
    //float movement_y = sin(TIME * 6.0) * 0.25;
    //float taper = 1.0 - UV.x; // 1 at start, 0 at end
    //VERTEX.y += cos(VERTEX.x * 0.5) * movement_y * taper;
//}
void vertex() {
    float taper = 1.0 - UV.y; 
    
    float sway = sin(TIME * 3.0) * 0.1;
    float ripple = sin(VERTEX.y * 2.0 - TIME * 12.0) * 0.06;
    float vibration = sin(VERTEX.y * 10.0 - TIME * 25.0) * 0.02;
    
    float displacement = (sway + ripple + vibration) * taper * taper;
    VERTEX.x += displacement;
	Z_CLIP_SCALE = 0.8;
}

void fragment() {


    
    vec2 uv = vec2(UV.y - TIME * 0.5, UV.x);
    uv.x *= 0.1;
    vec4 base_tex = texture(main_tex, uv);
    ALBEDO = base_tex.rgb * base_color.rgb;
    EMISSION = (base_tex.rgb * base_color.rgb) * brightness;
    ALPHA = base_tex.a * base_color.a ;
    float start_fade = smoothstep(0.0, 0.15, UV.y) ; // adjust 0.15 for fade length
    float end_fade = 1.0 - smoothstep(0.0, 1.0, UV.y) ; // adjust 0.15 for fade length
    
	// Fade in from start (UV.y = 0) to finish (UV.y = 1)
    float fade_in = smoothstep(0.0, 1.0, fade_progress / UV.y);
    fade_in = clamp(fade_in, 0.0, 1.0);
	ALPHA *= start_fade * end_fade * fade_in;
	
	}
