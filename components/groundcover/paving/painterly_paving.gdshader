shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_prepass_alpha, fog_disabled;

uniform vec4 paving_color : source_color = vec4(0.74,0.72,0.66,1.0);
uniform vec2 footprint = vec2(1.6,13.5);
uniform vec2 end_fade = vec2(2.4,2.6);
uniform float edge_softness = 0.18;
uniform float breakup_size = 0.48;
uniform float irregularity = 0.7;
uniform float paint_phase = 0.0;
varying vec2 position_on_strip;
varying vec3 surface_normal;
varying float paint_layer;

float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p), f=fract(p);
	f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}

void vertex() {
	position_on_strip = VERTEX.xz;
	surface_normal = MODEL_NORMAL_MATRIX*NORMAL;
	paint_layer = UV2.x;
}

void fragment() {
	vec2 p = position_on_strip;
	vec2 phase = vec2(paint_phase,paint_phase*0.47);
	float wash = noise(p*vec2(0.85,0.62)+phase);
	float brush = noise(p*vec2(1.8,0.95)+vec2(wash*0.8)+phase);
	// Quiet, broad painted planes. No granular concrete or regular grout grid.
	float tone = 0.84 + COLOR.r*0.19 + wash*0.065;
	vec3 pigment = paving_color.rgb*tone;
	pigment = mix(pigment,paving_color.rgb*vec3(1.12,1.09,1.02),smoothstep(0.42,0.73,brush)*0.35);
	float light = dot(normalize(surface_normal),normalize(vec3(-0.45,0.85,0.30)));
	pigment *= mix(0.96,1.0,smoothstep(0.38,0.7,light));
	// Dissolve through large, softly torn brush cells. The last geometry edge is invisible.
	float start = end_fade.x>0.001 ? smoothstep(0.0,end_fade.x,p.y+footprint.y*0.5) : 1.0;
	float end = end_fade.y>0.001 ? smoothstep(0.0,end_fade.y,footprint.y*0.5-p.y) : 1.0;
	float ends = min(start,end);
	float wobble = (sin(p.y*1.7+paint_phase)*0.045 + sin(p.y*3.8-paint_phase)*0.02)*irregularity;
	float side_distance = footprint.x*0.5+wobble-abs(p.x);
	float warp = noise(p*1.3+phase);
	float cells = noise(p/vec2(breakup_size,breakup_size*1.2)+vec2(warp*1.1)+phase);
	float sides = smoothstep(-0.025,edge_softness,side_distance+(cells-0.5)*edge_softness*0.75);
	float pressure = min(sides,ends);
	float threshold = mix(0.78,-0.28,pressure*pressure);
	float broken = smoothstep(threshold-0.13,threshold+0.13,cells);
	float opacity = pow(pressure,0.85)*broken;
	if (paint_layer>0.5) { opacity *= 0.32; }
	if (opacity<0.008) { discard; }
	ALBEDO = pigment;
	ALPHA = opacity;
}
