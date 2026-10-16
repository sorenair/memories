shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec2 flame_size = vec2(0.9,1.5);
uniform float intensity = 1.0;
uniform float animation_speed = 1.0;
uniform float fire_phase = 0.0;
uniform vec4 flame_color : source_color;
uniform float glow_strength = 0.3;
void vertex() {
	VERTEX=vec3((UV.x-0.5)*flame_size.x*3.0,0.025,(UV.y-0.5)*flame_size.x*3.0);
}
void fragment() {
	float radius=length(UV*2.0-1.0);
	float t=TIME*animation_speed+fire_phase;
	float pulse=0.85+sin(t*2.3)*0.08+sin(t*4.1)*0.07;
	ALBEDO=flame_color.rgb;
	ALPHA=pow(max(1.0-radius,0.0),2.5)*glow_strength*pulse*intensity*0.45;
}
