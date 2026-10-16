shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform float leaf_count = 12.0;
uniform float leaf_rate = 1.0;
uniform float max_height = 4.0;
uniform float wind_strength = 0.09;
uniform float wind_speed = 0.8;
varying vec3 painted_color;
varying float fade;
void vertex() {
	float duration = max(INSTANCE_CUSTOM.a, 0.1) / 0.55;
	float cycle = max(max_height / 0.55 + 0.2, leaf_count / max(leaf_rate, 0.001));
	float age = mod(TIME + INSTANCE_CUSTOM.r * cycle, cycle);
	float progress = clamp(age / duration, 0.0, 1.0);
	float phase = INSTANCE_CUSTOM.b * 6.28318;
	// A real curved leaf tumbles in space; it is not a billboard or a sprite.
	float roll = sin(age * 2.1 + phase) * 0.9;
	float yaw = phase + age * 0.65;
	vec3 leaf = VERTEX * mix(0.09, 0.15, INSTANCE_CUSTOM.b);
	leaf.xy = mat2(vec2(cos(roll),sin(roll)),vec2(-sin(roll),cos(roll))) * leaf.xy;
	leaf.xz = mat2(vec2(cos(yaw),sin(yaw)),vec2(-sin(yaw),cos(yaw))) * leaf.xz;
	vec2 flutter = vec2(sin(age*1.7+phase),cos(age*1.2+phase));
	vec2 breeze = vec2(0.65,0.35)*progress*wind_strength*3.0;
	breeze += vec2(sin(TIME*wind_speed+phase),cos(TIME*wind_speed*0.7+phase))*wind_strength*0.4;
	VERTEX = leaf + vec3(flutter.x * 0.25 * sin(progress*3.14159)+breeze.x, -progress*INSTANCE_CUSTOM.a + 0.025, flutter.y*0.25*sin(progress*3.14159)+breeze.y);
	fade = smoothstep(0.0,0.35,age)*(1.0-smoothstep(max(duration-0.7,0.0),duration,age));
	float tint = INSTANCE_CUSTOM.g;
	vec3 color = mix(root_color.rgb,shade_color.rgb,smoothstep(0.05,0.3,tint));
	color = mix(color,leaf_color.rgb,smoothstep(0.28,0.7,tint));
	painted_color = mix(color,sun_color.rgb,smoothstep(0.6,0.95,tint)*0.75);
}
void fragment() {
	ALBEDO = painted_color * (0.97 + 0.03 * sin(UV.x*8.0+UV.y*5.0));
	ALPHA = fade;
}
