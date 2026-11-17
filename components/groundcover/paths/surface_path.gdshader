shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_prepass_alpha, fog_disabled;
uniform vec4 paving_color : source_color;
uniform vec4 shoulder_color : source_color;
uniform vec4 stone_color : source_color;
uniform vec2 end_fade = vec2(1.0);
uniform float edge_softness = 0.26;
uniform float breakup_size = 0.48;
uniform float path_width = 2.1;
uniform float path_length = 8.0;
uniform float paint_phase = 0.0;
uniform int surface_style = 0;
uniform bool twin_tracks = false;
varying vec2 path_uv;
varying vec2 kind_width;
varying vec3 world_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p),f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1)),f.x),f.y);
}
void vertex() {
	path_uv=UV;
	kind_width=UV2;
	world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
	vec2 p=vec2(path_uv.x*path_width*0.5,path_uv.y);
	vec2 phase=vec2(paint_phase,paint_phase*0.47);
	float wash=noise(p*vec2(0.85,0.60)+phase);
	float brush=noise(p*vec2(2.0,1.1)+vec2(wash*0.7)+phase);
	float ratio=abs(path_uv.x);
	float tread=1.0-smoothstep(0.28,0.86,ratio);
	if (twin_tracks) { tread=exp(-pow((ratio-0.48)/0.24,2.0)); }
	vec3 soil=mix(paving_color.rgb,shoulder_color.rgb,(1.0-tread)*0.35);
	if (twin_tracks) { soil=mix(shoulder_color.rgb,paving_color.rgb,smoothstep(0.10,0.88,tread)); }
	soil*=0.91+0.10*COLOR.r+0.07*smoothstep(0.25,0.76,wash);
	soil=mix(soil,paving_color.rgb*1.06,tread*smoothstep(0.35,0.7,brush)*0.24);
	if (surface_style>=2) { soil=paving_color.rgb*(0.90+wash*0.07); }
	vec3 stone=stone_color.rgb*(0.84+COLOR.r*0.23);
	stone=mix(stone,stone*1.045,smoothstep(0.35,0.73,brush)*0.4);
	vec3 pigment=kind_width.x>1.5 ? stone : soil;
	if (kind_width.x>2.5) { pigment*=0.92; }
	float light=dot(normalize(world_normal),normalize(vec3(-0.45,0.85,0.3)));
	pigment*=mix(0.93,1.0,smoothstep(0.30,0.75,light));
	float start=end_fade.x>0.001 ? smoothstep(0.0,end_fade.x,path_uv.y) : 1.0;
	float end=end_fade.y>0.001 ? smoothstep(0.0,end_fade.y,path_length-path_uv.y) : 1.0;
	float cells=noise(p/max(breakup_size,0.1)+phase+vec2(wash*0.7));
	float side_distance=(1.0-ratio)*kind_width.y;
	float sides=smoothstep(0.0,edge_softness,side_distance-(cells-0.35)*edge_softness*0.65);
	float pressure=min(sides,min(start,end));
	float breakup=smoothstep(mix(0.78,-0.25,pressure)-0.12,mix(0.78,-0.25,pressure)+0.12,cells);
	float alpha=pressure*breakup;
	if (alpha<0.008) { discard; }
	ALBEDO=pigment;
	ALPHA=alpha;
}
