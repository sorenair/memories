shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform int score = 0;
uniform int digit_count : hint_range(1,6,1) = 6;
uniform vec4 digit_color : source_color = vec4(0.914,0.749,0.486,1.0);
float segment(vec2 p, vec2 center, vec2 size) {
	vec2 q = abs(p-center)-size+vec2(0.028);
	float distance = length(max(q,vec2(0)))+min(max(q.x,q.y),0.0)-0.028;
	float aa = max(fwidth(p.x),fwidth(p.y))*0.75;
	return 1.0-smoothstep(-aa,aa,distance);
}
int mask_for(int digit) {
	if (digit==0) return 63;
	if (digit==1) return 6;
	if (digit==2) return 91;
	if (digit==3) return 79;
	if (digit==4) return 102;
	if (digit==5) return 109;
	if (digit==6) return 125;
	if (digit==7) return 7;
	if (digit==8) return 127;
	return 111;
}
#include "res://components/effects/recall/shaders/assembled_recall.gdshaderinc"
void vertex() {
	assembly_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float assembly = assembly_clarity(assembly_position);
	if (assembly <= 0.001) { discard; }
	int count = clamp(digit_count,1,6);
	int cell = int(clamp(floor(UV.x*float(count)),0.0,float(count-1)));
	int divisor = 1;
	for (int i=0; i<5; i++) { if (i<count-1-cell) divisor*=10; }
	int mask = mask_for((score/divisor)%10);
	vec2 p = vec2(fract(UV.x*float(count))*2.0-1.0,1.0-UV.y*2.0);
	float ink = 0.0;
	if ((mask&1)!=0) ink=max(ink,segment(p,vec2(0,0.74),vec2(0.45,0.065)));
	if ((mask&2)!=0) ink=max(ink,segment(p,vec2(0.54,0.37),vec2(0.065,0.28)));
	if ((mask&4)!=0) ink=max(ink,segment(p,vec2(0.54,-0.37),vec2(0.065,0.28)));
	if ((mask&8)!=0) ink=max(ink,segment(p,vec2(0,-0.74),vec2(0.45,0.065)));
	if ((mask&16)!=0) ink=max(ink,segment(p,vec2(-0.54,-0.37),vec2(0.065,0.28)));
	if ((mask&32)!=0) ink=max(ink,segment(p,vec2(-0.54,0.37),vec2(0.065,0.28)));
	if ((mask&64)!=0) ink=max(ink,segment(p,vec2(0,0),vec2(0.45,0.065)));
	ALBEDO = digit_color.rgb;
	EMISSION = digit_color.rgb*0.12;
	ALPHA = ink*digit_color.a;
}
