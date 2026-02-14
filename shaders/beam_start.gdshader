shader_type spatial;
render_mode diffuse_burley, cull_disabled;
uniform vec4 color : source_color;
uniform float radius : hint_range(0.0, 1.0) = 0.5;
uniform float softness : hint_range(0.001, 1.0) = 0.2;
uniform float falloff : hint_range(0.1, 8.0) = 2.0;
uniform float emission_energy  = 2.0;
void vertex() {
    float sway = sin(TIME * 3.0) * 0.1;
    float ripple = sin(VERTEX.y * 2.0 - TIME * 12.0) * 0.06;
    float vibration = sin(VERTEX.y * 10.0 - TIME * 25.0) * 0.02;
    
    float displacement = (sway + ripple + vibration) ;
    VERTEX.z += displacement;
	Z_CLIP_SCALE = 0.99;
}

void fragment() {
	float d = distance(UV, vec2(0.5));
    float gradient = smoothstep(radius, radius - softness, d);

    // Shape the curve
    gradient = 1.0 - pow(1.0 - gradient, falloff);
	ALBEDO = color.rgb;
	EMISSION = color.rgb * emission_energy;
	ALPHA = gradient;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
