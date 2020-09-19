shader_type canvas_item;
render_mode blend_mix;


// Particle animation uniforms
uniform int particles_anim_h_frames;
uniform int particles_anim_v_frames;
uniform bool particles_anim_loop;
// Alpha erosion uniforms
uniform sampler2D alpha_texture:hint_black;
uniform sampler2D erosion_curve:hint_black;
uniform sampler2D color_ramp:hint_black;
uniform float erosion_smoothness : hint_range(0.,0.5,0.01) = 0.1;
uniform bool use_hue_shift = false;
uniform sampler2D shift_curve : hint_black;
varying float lifetime;

vec4 HueShift (in vec3 color, in float Shift)
{
    vec3 P = vec3(0.55735)*dot(vec3(0.55735),color);
    
    vec3 U = color-P;
    
    vec3 V = cross(vec3(0.55735),U);    

    color = U*cos(Shift*6.2832) + V*sin(Shift*6.2832) + P;
    
    return vec4(color,1.0);
}

void vertex() {
	// Particle animation support
	float h_frames = float(particles_anim_h_frames);
	float v_frames = float(particles_anim_v_frames);
	VERTEX.xy /= vec2(h_frames, v_frames);
	float particle_total_frames = float(particles_anim_h_frames * particles_anim_v_frames);
	float particle_frame = floor(INSTANCE_CUSTOM.z * float(particle_total_frames));
	if (!particles_anim_loop) {
		particle_frame = clamp(particle_frame, 0.0, particle_total_frames - 1.0);
	} else {
		particle_frame = mod(particle_frame, particle_total_frames);
	}	UV /= vec2(h_frames, v_frames);
	UV += vec2(mod(particle_frame, h_frames) / h_frames, floor(particle_frame / h_frames) / v_frames);
	// Passing lifetime
	lifetime = INSTANCE_CUSTOM.y;
}

void fragment(){
    vec4 col = texture(TEXTURE,UV);
    col *= texture(color_ramp,vec2(lifetime,0));
	if (use_hue_shift){
		col.rgb = HueShift(
			col.rgb,
			texture(shift_curve,vec2(lifetime,0)).r
		).rgb;
	}
    float erosion = texture(alpha_texture,UV).r;
	
    float t = texture(erosion_curve,vec2(lifetime,0)).x;
    t = t + mix(0.,erosion_smoothness,t);
	
    float is_alpha_zero = smoothstep(0.01,0.,erosion);
    col.a = (
		smoothstep(
			t-erosion_smoothness,
			t,
			erosion)
		- is_alpha_zero
	) * texture(color_ramp,vec2(lifetime,0)).a;
    col.a = clamp(col.a,0.,1.);
    COLOR = col;
}
