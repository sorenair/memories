shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
// Leaf geometry forms the whole canopy. Shared clump colors replace face lighting.
uniform vec4 root_color : source_color;
uniform vec4 shade_color : source_color;
uniform vec4 leaf_color : source_color;
uniform vec4 sun_color : source_color;
uniform float tree_height = 3.8;
uniform float wind_strength = 0.09;
uniform float wind_speed = 0.8;
uniform float tree_phase = 0.0;
// Disabled by default; bushes enable this without affecting tree wind.
uniform float disturbance_strength = 0.0;
uniform float disturbance_radius = 0.8;
uniform vec4 disturbance_sources[2];
varying vec3 painted_color;
varying vec3 paint_position;
varying float haze;
void vertex() {
	vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float tint = INSTANCE_CUSTOM.r;
	float anchor = smoothstep(0.15, 1.0, INSTANCE_CUSTOM.a);
	float breeze = sin(TIME * wind_speed + world.x * 0.65 + world.z * 0.45 + tree_phase);
	float gust = 0.8 + 0.2 * sin(TIME * wind_speed * 0.37 + tree_phase);
	vec3 world_motion = vec3(breeze, 0.0, cos(TIME * wind_speed * 0.7 + tree_phase) * 0.45) * wind_strength * anchor * gust;
	vec3 disturbed = vec3(0.0);
	if (disturbance_strength > 0.0) {
		for (int i = 0; i < 2; i++) {
			vec3 origin = MODEL_MATRIX[3].xyz;
			vec2 away = origin.xz - disturbance_sources[i].xz;
			float influence = 1.0 - smoothstep(0.0, disturbance_radius, length(away));
			float height_gate = 1.0 - smoothstep(0.9, 1.8, abs(origin.y - disturbance_sources[i].y - 0.6));
			// A soft center prevents abrupt direction flips as the player crosses a spray.
			vec2 push = away / sqrt(dot(away, away) + 0.0144);
			disturbed += vec3(push.x, -0.25, push.y) * influence * height_gate * disturbance_sources[i].w;
		}
	}
	// Bound the combined push when two players disturb the same bush.
	disturbed /= max(1.0, length(disturbed));
	world_motion += disturbed * disturbance_strength * anchor;
	// MultiMesh transforms scale each spray down. Convert world displacement
	// into that spray's local coordinates so wind isn't shrunk to subpixel motion.
	vec3 axis_x = MODEL_MATRIX[0].xyz;
	vec3 axis_y = MODEL_MATRIX[1].xyz;
	vec3 axis_z = MODEL_MATRIX[2].xyz;
	vec3 local_motion = vec3(dot(world_motion, axis_x) / dot(axis_x, axis_x),
		dot(world_motion, axis_y) / dot(axis_y, axis_y), dot(world_motion, axis_z) / dot(axis_z, axis_z));
	// Faster, phase-varied leaf flutter sits on top of the coherent canopy sway.
	float flutter = sin(TIME * wind_speed * 2.7 + INSTANCE_CUSTOM.b * 6.28318);
	float angle = flutter * wind_strength * 2.0 * anchor;
	float c = cos(angle);
	float s = sin(angle);
	VERTEX.xy = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy;
	VERTEX += local_motion;
	vec3 color = mix(root_color.rgb, shade_color.rgb, smoothstep(0.05, 0.30, tint));
	color = mix(color, leaf_color.rgb, smoothstep(0.28, 0.70, tint));
	color = mix(color, sun_color.rgb, smoothstep(0.60, 0.95, tint) * 0.75);
	painted_color = color * mix(0.97, 1.03, INSTANCE_CUSTOM.g);
	paint_position = world;
	haze = smoothstep(25.0, 60.0, length((VIEW_MATRIX * vec4(world, 1.0)).xyz));
}
void fragment() {
	// Small pigment shifts run across neighboring leaf forms, independent of triangles.
	float pigment = sin(paint_position.x * 15.0 + sin(paint_position.y * 18.0)) * sin(paint_position.z * 19.0 + paint_position.y * 9.0);
	vec3 color = painted_color * (1.0 + pigment * 0.035);
	ALBEDO = mix(color, vec3(0.87, 0.86, 0.77), haze);
}
