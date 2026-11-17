shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;
#include "res://components/vfx/sculpted_fire/fire_common.gdshaderinc"
#include "res://components/vfx/sculpted_fire/smoke_flow.gdshaderinc"
varying float ember_age;
varying float visibility;
varying float heat;

float ember_hash(float x) { return fract(sin(x*127.1+31.7)*43758.5453); }
vec3 ember_path(float age, float phase, float seed, float fast, float birth, float rate) {
	vec2 direction = vec2(cos(phase),sin(phase));
	vec2 sideways = vec2(-direction.y,direction.x);
	float drag = mix(1.4,2.7,fast);
	float rise = (1.0-exp(-age*drag))/(1.0-exp(-drag));
	float height = mix(0.72,1.0,seed);
	float y = fire_size.y*(0.26+rise*(spark_height-0.26)*height);
	vec2 drift = direction*fire_size.x*(0.10+seed*0.10+age*mix(0.16,0.40,fast));
	float flutter = sin(age*11.0+phase)+sin(age*19.0+seed*23.0)*0.35;
	drift += sideways*fire_size.x*age*(sin(age*5.5+phase)*0.09+flutter*mix(0.035,0.012,fast));
	float plume_h = clamp((y-smoke_base_height())/smoke_height,0.0,1.0);
	drift += smoke_center(plume_h,birth+age/rate).xz*age*0.65+wind*age*age*0.45;
	return vec3(drift.x,y,drift.y);
}
void vertex() {
	float t = fire_clock(TIME);
	float fast = step(0.50,INSTANCE_CUSTOM.w);
	float rate = mix(0.90,mix(0.62,1.35,fast)*mix(0.82,1.18,INSTANCE_CUSTOM.y),spark_variation);
	float group = floor(INSTANCE_CUSTOM.x*6.0);
	float emission_phase = mix(INSTANCE_CUSTOM.x,group/6.0+INSTANCE_CUSTOM.y*0.04,spark_burstiness);
	float clock = t*rate+emission_phase;
	float age = fract(clock);
	float birth = t-age/rate;
	float seed = ember_hash(floor(clock)+INSTANCE_CUSTOM.z*43.0);
	float phase = INSTANCE_CUSTOM.z*6.283185+seed*1.8;
	float size = spark_size*mix(1.0,mix(0.65,1.35,seed),spark_variation)*mix(1.0,0.70,fast)*intensity*recall_visibility;
	vec3 tangent = ember_path(min(age+0.005,1.0),phase,seed,fast,birth,rate)-ember_path(max(age-0.005,0.0),phase,seed,fast,birth,rate);
	float speed = length(tangent)*rate/0.01;
	// Reconstruct a short exposure of the actual trajectory, not a rigid dart.
	float history = min(age,rate*spark_trail_length*mix(0.65,1.35,seed));
	history = min(history,size*mix(2.8,6.0,fast)*rate/max(speed,0.01));
	float trail = clamp((UV.y-0.20)/0.80,0.0,1.0);
	float past_age = max(age-history*trail,0.0);
	vec3 p = ember_path(past_age,phase,seed,fast,birth,rate);
	vec3 velocity = normalize(tangent+vec3(0.0,0.00001,0.0));
	mat4 inverse_view = inverse(MODELVIEW_MATRIX);
	vec3 toward_camera = PROJECTION_MATRIX[3][3]>0.5 ? normalize((inverse_view*vec4(0.0,0.0,1.0,0.0)).xyz) : normalize((inverse_view*vec4(0.0,0.0,0.0,1.0)).xyz-p);
	vec3 head_axis = velocity-toward_camera*dot(velocity,toward_camera);
	if (dot(head_axis,head_axis)<0.0001) { head_axis = (inverse_view*vec4(0.0,1.0,0.0,0.0)).xyz; }
	head_axis = normalize(head_axis);
	vec3 right = normalize(cross(head_axis,toward_camera));
	float head = sqrt(max(1.0-pow((UV.y-0.13)/0.15,2.0),0.0));
	float width = size*max(head*0.28,pow(1.0-trail,1.4)*0.18*smoothstep(0.05,0.20,UV.y));
	float side = UV.x*2.0-1.0;
	width *= mix(0.85,1.15,ember_hash(INSTANCE_CUSTOM.z*21.0+UV.x*7.0+floor(UV.y*5.0)));
	p += head_axis*max(0.20-UV.y,0.0)*size*7.0;
	p += right*side*width;
	VERTEX = p;
	float flicker = 0.80+sin((t-birth)*19.0+seed*13.0)*0.13+sin((t-birth)*31.0+phase)*0.07;
	visibility = smoothstep(0.0,0.025,age)*(1.0-smoothstep(0.48,0.96,age));
	heat = flicker*mix(1.0,1.15,fast);
	ember_age = age;
}
void fragment() {
	if (visibility<0.01 || spark_amount<=0.0 || intensity<=0.0 || recall_visibility<=0.001) { discard; }
	float across = abs(UV.x*2.0-1.0);
	float core = 1.0-smoothstep(0.22,0.86,across);
	float head = 1.0-smoothstep(0.16,0.55,UV.y);
	float tail = clamp((UV.y-0.20)/0.80,0.0,1.0);
	vec3 color = mix(edge_color.rgb,flame_color.rgb,0.40+core*0.60);
	color = mix(color,core_color.rgb,head*core*0.90);
	color = mix(color,edge_color.rgb,smoothstep(0.55,1.0,ember_age)*0.55);
	ALBEDO = color*heat;
	EMISSION = color*glow_strength*(0.85+head*1.35)*heat;
	ALPHA = visibility*(0.12+core*0.88)*max(head,pow(1.0-tail,1.4)*0.85);
}
