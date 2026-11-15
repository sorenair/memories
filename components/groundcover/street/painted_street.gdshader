shader_type spatial;
render_mode unshaded, fog_disabled;
uniform vec2 footprint = vec2(9.4,42.0);
uniform vec4 asphalt_color : source_color = vec4(0.635,0.671,0.655,1.0);
uniform vec2 end_fade = vec2(3.0);
uniform float edge_softness = 0.35;
uniform float paint_phase = 0.0;
varying vec2 local_ground;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { local_ground = VERTEX.xz; }
void fragment() {
	vec2 p = local_ground;
	float wash = noise(p*0.24+paint_phase);
	float brush = noise(p*vec2(0.70,0.34)+wash);
	float erosion = noise(p*1.4+paint_phase)*0.30;
	float side = smoothstep(0.0,edge_softness,footprint.x*0.5-abs(p.x)-erosion);
	float near_end = end_fade.x>0.0 ? smoothstep(0.0,end_fade.x,p.y+footprint.y*0.5-erosion) : 1.0;
	float far_end = end_fade.y>0.0 ? smoothstep(0.0,end_fade.y,footprint.y*0.5-p.y-erosion) : 1.0;
	float clarity = side*near_end*far_end;
	if (clarity<0.018) { discard; }
	vec3 paint = asphalt_color.rgb*(0.96+wash*0.06+brush*0.035);
	ALBEDO = mix(vec3(0.87,0.86,0.77),paint,clarity);
}
