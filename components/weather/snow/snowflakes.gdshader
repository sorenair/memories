shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float snow_height = 8.0;
uniform float intensity = 0.7;
uniform float fall_speed = 0.65;
uniform vec2 wind = vec2(0.5,0.18);
uniform float flutter = 0.45;
uniform vec2 flake_size = vec2(0.04,0.11);
uniform vec4 snow_color : source_color;
uniform vec4 shade_color : source_color;
uniform float opacity = 0.85;
varying float fade;
varying float individuality;
void vertex() {
	float time=TIME*fall_speed;
	float phase=INSTANCE_CUSTOM.r*6.28318;
	float progress=fract(time*mix(0.75,1.25,INSTANCE_CUSTOM.g)/snow_height+INSTANCE_CUSTOM.r);
	float height=(1.0-progress)*snow_height;
	// Broad lazy swirls layer over a slower drift, with no abrupt lateral wrap.
	vec2 swirl=vec2(sin(time*0.75+phase),cos(time*0.53+phase*1.7));
	vec2 drift=wind*(progress-0.5)*3.0+swirl*flutter*(0.35+sin(progress*3.14159)*0.65);
	vec3 world=(MODEL_MATRIX*vec4(drift.x,height,drift.y,1.0)).xyz;
	float turn=time*0.35+phase;
	vec2 point=mat2(vec2(cos(turn),sin(turn)),vec2(-sin(turn),cos(turn)))*VERTEX.xy;
	float size=mix(flake_size.x,flake_size.y,INSTANCE_CUSTOM.b*INSTANCE_CUSTOM.b);
	float flutter_scale=0.78+0.22*sin(time*1.1+phase);
	world+=(INV_VIEW_MATRIX[0].xyz*point.x+INV_VIEW_MATRIX[1].xyz*point.y*flutter_scale)*size;
	VERTEX=(inverse(MODEL_MATRIX)*vec4(world,1.0)).xyz;
	fade=smoothstep(0.0,0.3,height)*(1.0-smoothstep(snow_height-0.6,snow_height,height));
	fade*=step(INSTANCE_CUSTOM.a,intensity)*mix(0.65,1.0,INSTANCE_CUSTOM.b);
	individuality=INSTANCE_CUSTOM.g;
}
void fragment() {
	vec2 p=UV*2.0-1.0;
	float radius=length(p);
	float painted=sin(p.x*5.0+individuality*6.28)*sin(p.y*4.0+individuality*9.0);
	float edge_radius=radius+painted*0.045;
	float aa=max(fwidth(radius),0.04);
	float edge=1.0-smoothstep(0.65-aa,1.0,edge_radius);
	ALBEDO=mix(shade_color.rgb,snow_color.rgb,1.0-smoothstep(0.25,0.95,radius)*0.65);
	ALPHA=edge*fade*opacity;
}
