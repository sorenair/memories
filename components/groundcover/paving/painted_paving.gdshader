shader_type spatial;
render_mode unshaded, fog_disabled;
uniform vec4 paving_color : source_color = vec4(0.76, 0.73, 0.65, 1.0);
varying vec3 world_position;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x), mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x), f.y);
}
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	vec2 p = world_position.xz;
	float wash = noise(p*1.4 + noise(p*0.8));
	float brush = floor(noise(p*vec2(5.0, 2.8))*4.0)/3.0;
	vec3 paint = paving_color.rgb * (0.95 + wash*0.08 + brush*0.025);
	paint = mix(paint, vec3(0.69,0.63,0.49), smoothstep(0.65,0.9,noise(p*0.65))*0.06);
	float haze = smoothstep(25.0,60.0,length(VERTEX));
	ALBEDO = mix(paint,vec3(0.87,0.86,0.77),haze);
}
