shader_type spatial;
render_mode cull_disabled, depth_test_disabled;
uniform sampler2D main_tex : source_color, filter_linear_mipmap_anisotropic;
uniform vec4 base_color : source_color;
uniform float brightness : hint_range(0.0, 10.0, 0.1) = 1.0;


//void vertex() {
//
    //float movement_y = sin(TIME * 6.0) * 0.25;
    //float taper = 1.0 - UV.x; // 1 at start, 0 at end
    //VERTEX.y += cos(VERTEX.x * 0.5) * movement_y * taper;
//}
void vertex() {
    float taper = 1.0 - UV.y; // UV.y is now the length axis for FACE_Z quad
    
    float sway = sin(TIME * 3.0) * 0.1;
    float ripple = sin(VERTEX.y * 2.0 - TIME * 12.0) * 0.06;
    float vibration = sin(VERTEX.y * 10.0 - TIME * 25.0) * 0.02;
    
    float displacement = (sway + ripple + vibration) * taper * taper;
    VERTEX.x += displacement;
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
	ALPHA *= start_fade * end_fade;
	
	}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
