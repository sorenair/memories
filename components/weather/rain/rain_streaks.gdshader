shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float rain_height = 10.0;
uniform float intensity = 0.7;
uniform float fall_speed = 8.0;
uniform vec2 wind = vec2(0.55,0.16);
uniform float streak_length = 0.42;
uniform float streak_width = 0.009;
uniform vec4 rain_color : source_color;
uniform vec4 highlight_color : source_color;
uniform float opacity = 0.42;
varying float fade;
varying float tint;
void vertex() {
	float t=TIME*fall_speed/8.0;
	float speed=mix(6.8,9.6,INSTANCE_CUSTOM.g);
	float phase=fract(t*speed/rain_height+INSTANCE_CUSTOM.r);
	float height=(1.0-phase)*rain_height;
	vec3 center=vec3(wind*(phase-0.5)*rain_height/speed,0.0).xzy;
	center.y=height;
	center.xz+=vec2(sin(t*0.6+INSTANCE_CUSTOM.b*6.28),cos(t*0.43+INSTANCE_CUSTOM.b*6.28))*0.07;
	vec3 world=(MODEL_MATRIX*vec4(center,1.0)).xyz;
	vec3 direction=normalize(mat3(MODEL_MATRIX)*vec3(wind.x,-speed,wind.y));
	vec3 view=normalize(INV_VIEW_MATRIX[3].xyz-world);
	vec3 across=cross(direction,view);
	if (length(across)<0.001) { across=INV_VIEW_MATRIX[0].xyz; }
	across=normalize(across);
	float length_scale=mix(0.65,1.3,INSTANCE_CUSTOM.b);
	world+=direction*VERTEX.y*streak_length*0.5*length_scale+across*VERTEX.x*streak_width*0.5;
	VERTEX=(inverse(MODEL_MATRIX)*vec4(world,1.0)).xyz;
	fade=smoothstep(0.0,0.45,height)*(1.0-smoothstep(rain_height-0.8,rain_height,height));
	fade*=step(INSTANCE_CUSTOM.a,intensity)*mix(0.55,1.0,INSTANCE_CUSTOM.g);
	tint=INSTANCE_CUSTOM.b;
}
void fragment() {
	float across=abs(UV.x*2.0-1.0);
	float edge=1.0-smoothstep(0.15,1.0,across);
	float ends=pow(max(sin(UV.y*3.14159),0.0),0.7);
	ALBEDO=mix(rain_color.rgb,highlight_color.rgb,(1.0-across)*0.35+tint*0.15);
	ALPHA=opacity*fade*edge*ends;
}
