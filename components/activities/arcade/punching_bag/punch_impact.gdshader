shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, fog_disabled;
uniform float progress = -1.0;
void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	float size = length(MODEL_MATRIX[0].xyz);
	vec3 world = center + INV_VIEW_MATRIX[0].xyz * VERTEX.x * size
		+ INV_VIEW_MATRIX[1].xyz * VERTEX.y * size;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world,1.0)).xyz;
}
void fragment() {
	vec2 p = UV*2.0-1.0;
	float radius = length(p);
	float angle = atan(p.y,p.x);
	float t = clamp(progress,0.0,1.0);
	float target = 0.22+t*0.58;
	float brush = sin(angle*3.0+1.3)*0.025;
	float ring = 1.0-smoothstep(0.035,0.13,abs(radius-target+brush));
	float dabs = smoothstep(-0.1,0.45,sin(angle*4.0+0.7));
	float life = smoothstep(0.0,0.07,t)*(1.0-smoothstep(0.25,1.0,t));
	ALBEDO = vec3(1.0,0.965,0.86);
	ALPHA = ring*dabs*life*0.75*(progress>=0.0 ? 1.0 : 0.0);
}
