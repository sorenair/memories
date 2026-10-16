shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 top_color : source_color;
uniform vec4 side_color : source_color;
uniform vec4 void_color : source_color;
uniform float pigment_strength = 0.006;
uniform float fade_start = 1.2;
uniform float fade_depth = 15.0;
varying vec3 local_point;
varying vec3 world_point;
varying vec3 face_normal;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	local_point=VERTEX;
	world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	face_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);
}
void fragment() {
	float top=COLOR.r;
	float depth=max(-local_point.y,0.0);
	float paint=noise(world_point.xz*0.22)*0.65+noise(world_point.xz*0.9)*0.35;
	vec3 cap=top_color.rgb+(paint-0.5)*pigment_strength;
	// Very restrained face variation reads as a pillar, without dark rock cliffs.
	float light=dot(normalize(face_normal.xz+vec2(0.0001)),normalize(vec2(-0.6,0.8)));
	vec3 wall=side_color.rgb*(0.985+light*0.015)+(noise(vec2(world_point.x*0.18,local_point.y*0.12))-0.5)*pigment_strength;
	wall=mix(cap,wall,smoothstep(0.0,0.28,depth));
	float fade=smoothstep(min(fade_start,fade_depth*0.5),fade_depth,depth);
	wall=mix(wall,void_color.rgb,fade);
	ALBEDO=mix(wall,cap,top);
}
