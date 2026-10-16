shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float intensity = 0.7;
uniform float fall_speed = 8.0;
uniform vec4 rain_color : source_color;
uniform vec4 highlight_color : source_color;
uniform float splash_opacity = 0.32;
varying float age;
varying float water;
varying float fade;
void vertex() {
	float time=TIME*fall_speed/8.0;
	float cycle=mix(1.6,3.7,INSTANCE_CUSTOM.g);
	age=mod(time+INSTANCE_CUSTOM.r*cycle,cycle);
	water=INSTANCE_CUSTOM.a;
	float duration=mix(0.38,0.9,water);
	fade=(1.0-smoothstep(0.05,duration,age))*step(INSTANCE_CUSTOM.b,intensity);
	VERTEX=vec3(VERTEX.x,0.0,VERTEX.y)*mix(0.15,0.32,water);
}
void fragment() {
	vec2 p=UV*2.0-1.0;
	float duration=mix(0.38,0.9,water);
	float progress=clamp(age/duration,0.0,1.0);
	float radius=mix(0.12,0.88,progress);
	float angle=atan(p.y,p.x);
	float wobble=1.0+sin(angle*3.0+progress*2.0)*0.04;
	float d=abs(length(p)*wobble-radius);
	float aa=max(fwidth(d),0.015);
	float ring=1.0-smoothstep(0.035,0.035+aa,d);
	float broken=smoothstep(-0.45,0.15,sin(angle*3.0+progress*2.0));
	float center=(1.0-smoothstep(0.0,0.22,length(p)))*(1.0-smoothstep(0.0,0.2,progress));
	ALBEDO=mix(rain_color.rgb,highlight_color.rgb,mix(0.35,0.85,water));
	ALPHA=max(center,ring*mix(broken,0.85,water))*fade*splash_opacity;
}
