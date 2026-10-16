shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
uniform vec2 flame_size = vec2(0.9,1.5);
uniform float intensity = 1.0;
uniform float animation_speed = 1.0;
uniform float wind = 0.12;
uniform float fire_phase = 0.0;
uniform vec4 core_color : source_color;
uniform vec4 flame_color : source_color;
uniform vec4 tip_color : source_color;
varying float age;
varying float fade;
void vertex() {
	float t=TIME*animation_speed+fire_phase;
	age=fract(t*(0.16+INSTANCE_CUSTOM.g*0.07)+INSTANCE_CUSTOM.r);
	vec3 center=vec3((INSTANCE_CUSTOM.a-0.5)*0.7+sin(t*0.7+INSTANCE_CUSTOM.r*13.0)*age*0.28+wind*age*age,0.28+age*1.8,(INSTANCE_CUSTOM.g-0.5)*0.4);
	center*=vec3(flame_size.x,flame_size.y,flame_size.x);
	vec3 world=(MODEL_MATRIX*vec4(center,1.0)).xyz;
	float angle=t*0.9+INSTANCE_CUSTOM.b*6.28;
	vec2 point=mat2(vec2(cos(angle),sin(angle)),vec2(-sin(angle),cos(angle)))*VERTEX.xy;
	float size=mix(0.018,0.042,INSTANCE_CUSTOM.b)*flame_size.x*(1.0-age*0.5);
	world+=(INV_VIEW_MATRIX[0].xyz*point.x+INV_VIEW_MATRIX[1].xyz*point.y)*size;
	VERTEX=(inverse(MODEL_MATRIX)*vec4(world,1.0)).xyz;
	fade=smoothstep(0.0,0.12,age)*(1.0-smoothstep(0.65,1.0,age))*step(INSTANCE_CUSTOM.g,intensity);
}
void fragment() {
	ALBEDO=mix(core_color.rgb,flame_color.rgb,smoothstep(0.1,0.5,age));
	ALBEDO=mix(ALBEDO,tip_color.rgb,smoothstep(0.5,1.0,age));
	ALPHA=fade*intensity;
}
