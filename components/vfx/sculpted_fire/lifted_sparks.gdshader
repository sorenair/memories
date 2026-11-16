shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float age_mix;
varying float visibility;
varying float sparkle;
float ember_hash(float x) { return fract(sin(x*127.1+31.7)*43758.5453); }
vec3 ember_path(float age, float phase, float seed, float t) {
	vec2 direction = vec2(cos(phase),sin(phase));
	vec2 sideways = vec2(-direction.y,direction.x);
	vec2 drift = direction*fire_size.x*(0.10+seed*0.06+age*(0.16+seed*0.10));
	drift += sideways*sin(age*4.5+phase)*age*fire_size.x*0.09;
	float rise = 1.0-pow(1.0-clamp(age,0.0,1.0),1.45);
	float y = fire_size.y*(0.35+rise*(spark_height-0.35));
	float plume_h = clamp((y-smoke_base_height())/smoke_height,0.0,1.0);
	drift += smoke_center(plume_h,t).xz*0.70+wind*age*age*0.50;
	return vec3(drift.x,y,drift.y);
}
void vertex() {
	float t = fire_clock(TIME);
	float group = floor(INSTANCE_CUSTOM.x*6.0);
	float emission_phase = mix(INSTANCE_CUSTOM.x,group/6.0+INSTANCE_CUSTOM.y*0.04,spark_burstiness);
	float clock = t*(0.72+INSTANCE_CUSTOM.y*0.32)+emission_phase;
	float age = fract(clock);
	float seed = ember_hash(floor(clock)+INSTANCE_CUSTOM.z*43.0);
	float phase = INSTANCE_CUSTOM.z*6.283185+seed*0.65;
	float attack = smoothstep(0.0,0.025,age);
	float envelope = attack*(1.0-smoothstep(0.55,0.95,age));
	float variation = spark_variation;
	float size = spark_size*mix(1.0,mix(0.65,1.35,INSTANCE_CUSTOM.w),variation)*sqrt(attack)*intensity*recall_visibility;
	vec3 center = ember_path(age,phase,seed,t);
	vec3 velocity = normalize(ember_path(min(age+0.01,0.99),phase,seed,t)-ember_path(max(age-0.01,0.0),phase,seed,t)+vec3(0.0,0.0001,0.0));
	mat4 inverse_view = inverse(MODELVIEW_MATRIX);
	vec3 toward_camera = PROJECTION_MATRIX[3][3]>0.5 ? normalize((inverse_view*vec4(0.0,0.0,1.0,0.0)).xyz) : normalize((inverse_view*vec4(0.0,0.0,0.0,1.0)).xyz-center);
	vec3 right = normalize(cross(velocity,toward_camera));
	vec3 across = normalize(cross(right,velocity));
	float u = UV.y;
	float angle = UV.x*6.283185;
	float stroke_length = size*mix(3.0,mix(1.8,6.0,INSTANCE_CUSTOM.y),variation);
	// A pointed ember head flows into a narrow, slightly bent trailing stroke.
	// The thin closed cross section remains a fleck, never a lit little sphere.
	float width = size*0.40*max(min(u/0.20,(1.0-u)/0.80),0.0);
	float bend = (INSTANCE_CUSTOM.z-0.5)*u*u*stroke_length*0.36;
	bend += sin(age*6.0+phase)*u*(1.0-u)*stroke_length*0.15*variation;
	vec3 p = center+velocity*(0.28-u)*stroke_length;
	p += right*(cos(angle)*width+bend)+across*sin(angle)*width*0.24;
	VERTEX = p;
	age_mix = age;
	visibility = envelope;
	sparkle = 0.94+sin(t*(8.0+seed*4.0)+phase)*0.06;
}

void fragment() {
	if (visibility<0.01 || spark_amount<=0.0 || intensity<=0.0 || recall_visibility<=0.001) { discard; }
	float head = 1.0-smoothstep(0.10,0.45,UV.y);
	float tail = smoothstep(0.40,1.0,UV.y);
	vec3 color = mix(flame_color.rgb,edge_color.rgb,tail*0.80);
	color = mix(color,mix(flame_color.rgb,core_color.rgb,0.90),head);
	color = mix(color,edge_color.rgb,smoothstep(0.65,1.0,age_mix)*0.25);
	ALBEDO = color*sparkle;
	EMISSION = color*glow_strength*(0.65+head*0.70);
	ALPHA = visibility*(1.0-smoothstep(0.72,1.0,UV.y));

}
