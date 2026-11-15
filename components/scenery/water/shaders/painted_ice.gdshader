shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D shore_field : repeat_disable, filter_linear;
uniform vec2 field_origin;
uniform vec2 field_size = vec2(6.0);
uniform vec4 ice_color : source_color = vec4(0.66,0.78,0.85,1.0);
uniform vec4 frost_color : source_color = vec4(0.91,0.94,0.93,1.0);
uniform float crack_strength = 0.28;
uniform float ice_seed = 0.0;
uniform float recall_progress = 1.0;
uniform float recall_scale = 1.0;
uniform vec2 recall_center;
uniform sampler2D recall_outline_field : repeat_disable, filter_linear;
varying vec2 source_uv;
varying vec2 field_uv;
varying vec2 world_point;
vec2 hash(vec2 p) {
	return fract(sin(vec2(dot(p,vec2(127.1,311.7)),dot(p,vec2(269.5,183.3))))*43758.5453);
}
void vertex() {
	source_uv = (VERTEX.xz-field_origin)/field_size;
	if (recall_progress<1.0) VERTEX.xz = recall_center+(VERTEX.xz-recall_center)*max(recall_scale,0.0001);
	field_uv = (VERTEX.xz-field_origin)/field_size;
	world_point = (MODEL_MATRIX*vec4(VERTEX,1.0)).xz;
}
void fragment() {
	if (recall_progress<=0.0) discard;
	float shore = texture(shore_field,field_uv).r;
	if (shore< -0.025) discard;
	vec2 p = world_point*0.75+vec2(ice_seed,ice_seed*0.37);
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float nearest = 10.0;
	float second = 10.0;
	for (int y=-1;y<=1;y++) {
		for (int x=-1;x<=1;x++) {
			vec2 at = vec2(float(x),float(y));
			float d = length(at+hash(cell+at)-f);
			if (d<nearest) { second=nearest; nearest=d; }
			else { second=min(second,d); }
		}
	}
	float seam = 1.0-smoothstep(0.008,0.045,second-nearest);
	float wash = sin(p.x*1.8+sin(p.y*2.4))*sin(p.y*1.3+p.x*0.6)*0.5+0.5;
	float bank = 1.0-smoothstep(0.02,0.55,max(shore,0.0));
	vec3 color = mix(ice_color.rgb,frost_color.rgb,bank*0.65+wash*0.18);
	color = mix(color,ice_color.rgb*0.70,seam*crack_strength*0.40);
	color += seam*crack_strength*0.045;
	ALBEDO = mix(frost_color.rgb,color,smoothstep(0.0,1.0,recall_progress));
}
