shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D coverage_mask : repeat_disable, filter_linear;
uniform sampler2D footprint_field : repeat_disable, filter_linear;
uniform vec2 field_texel = vec2(0.00390625);
uniform vec2 field_size = vec2(5.2,3.6);
uniform float snow_time = 0.0;
uniform float footprint_linger = 8.0;
uniform float footprint_fade_duration = 2.5;
uniform float footprint_depth = 0.025;
uniform vec4 snow_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 edge_color : source_color;
varying vec3 world_point;
varying vec3 base_normal;
varying vec3 axis_x;
varying vec3 axis_z;
float compression(vec2 uv) {
	vec2 stamp=textureLod(footprint_field,uv,0.0).rg;
	float fade=1.0-smoothstep(footprint_linger,footprint_linger+footprint_fade_duration,max(snow_time-stamp.g/max(stamp.r,0.00001),0.0));
	return stamp.r*fade;
}
void vertex() {
	float bank=smoothstep(0.5,0.95,textureLod(coverage_mask,UV,0.0).r);
	VERTEX.y=max(0.003,(VERTEX.y-compression(UV)*footprint_depth)*bank);
	world_point=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	base_normal=normalize(mat3(MODEL_MATRIX)*NORMAL);
	axis_x=normalize(MODEL_MATRIX[0].xyz);
	axis_z=normalize(MODEL_MATRIX[2].xyz);
}
void fragment() {
	float coverage=texture(coverage_mask,UV).r;
	if (coverage<0.5) { discard; }
	float depth=compression(UV);
	float dx=(compression(UV+vec2(field_texel.x,0))-compression(UV-vec2(field_texel.x,0)))*footprint_depth/(2.0*field_texel.x*field_size.x);
	float dz=(compression(UV+vec2(0,field_texel.y))-compression(UV-vec2(0,field_texel.y)))*footprint_depth/(2.0*field_texel.y*field_size.y);
	vec3 normal=normalize(base_normal+axis_x*dx+axis_z*dz);
	float light=dot(normal,normalize(vec3(-0.45,0.82,-0.35)));
	float pigment=sin(world_point.x*1.8+sin(world_point.z*1.3))*sin(world_point.z*2.1-world_point.x*0.35);
	float paint=smoothstep(0.7,0.92,light+pigment*0.025);
	vec3 color=mix(shade_color.rgb,snow_color.rgb,0.55+paint*0.45);
	color=mix(color,shade_color.rgb,depth*0.17);
	// The thin irregular bank melts toward the platform's pigment, without a border.
	float edge=max(smoothstep(0.82,1.0,COLOR.r),1.0-smoothstep(0.5,0.95,coverage));
	ALBEDO=mix(color,edge_color.rgb,edge);
}
