shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, fog_disabled;

uniform sampler2D surface_field : filter_linear, repeat_disable;
uniform bool use_surface = false;
uniform float surface_fade = 1.0;
uniform vec2 footprint = vec2(16.0, 12.0);
uniform vec2 wind_direction = vec2(1.0, 0.0);
uniform float wind_speed = 3.5;
uniform float gust_strength = 0.76;
uniform float lift_height = 0.39;
uniform vec2 grain_size = vec2(0.014, 0.048);
uniform vec4 sand_color : source_color = vec4(0.73, 0.54, 0.36, 1.0);
uniform vec4 sparkle_color : source_color = vec4(1.0, 0.95, 0.8, 1.0);
uniform float glitter_strength = 0.82;
uniform float opacity = 0.85;
varying float visibility;
varying float flash;

void vertex() {
	vec4 seed = INSTANCE_CUSTOM;
	float time = TIME * wind_speed;
	vec2 side = vec2(-wind_direction.y, wind_direction.x);
	vec2 travel = wind_direction * time * mix(0.75, 1.24, seed.b);
	travel += side * sin(time * 0.43 + seed.a * TAU) * 0.33;
	vec2 uv = fract(seed.rg + travel / footprint);
	vec2 point = (uv - 0.5) * footprint;
	vec2 field = vec2(0.0, 1.0);
	if (use_surface) {
		field = textureLod(surface_field, uv, 0.0).rg;
	}

	float along = dot(point, wind_direction);
	float across = dot(point, side);
	float gust = sin(along * 0.54 + across * 0.38 - time * 0.78 + sin(across * 0.65)) * 0.65;
	gust += 0.35 * sin(across * 1.6 + along * 0.13 - time * 0.21);
	float gust_band = smoothstep(-0.46, 0.79, gust);
	float hop = pow(0.5 + 0.5 * sin(time * mix(2.3, 4.6, seed.b) + seed.a * TAU), 1.7);
	float lift = 0.043 + hop * pow(seed.a, 2.1) * lift_height * mix(0.50, 1.0, gust_band);
	vec3 world = (MODEL_MATRIX * vec4(point.x, field.r + lift, point.y, 1.0)).xyz;

	// Uncorrelated short reflections ride on coherent, wider gust bands.
	float tumble = sin(time * mix(1.0, 3.7, seed.a) + seed.b * 109.0);
	flash = smoothstep(0.89, 1.0, tumble) * smoothstep(0.45, 0.87, seed.b) * glitter_strength;
	float width = mix(grain_size.x, grain_size.y, pow(seed.b, 1.75));
	width *= 1.0 + 0.40 * flash;
	vec3 wind_world = mat3(MODEL_MATRIX) * vec3(wind_direction.x, 0.0, wind_direction.y);
	vec2 wind_view = (VIEW_MATRIX * vec4(wind_world, 0.0)).xy;
	vec2 direction = length(wind_view) > 0.001 ? normalize(wind_view) : vec2(1.0, 0.0);
	vec2 across_view = vec2(-direction.y, direction.x);
	float stretch = mix(1.55 + 1.4 * smoothstep(0.0, 5.0, wind_speed), 1.30, flash * 0.75);
	vec2 quad = direction * VERTEX.x * stretch + across_view * VERTEX.y;
	world += (INV_VIEW_MATRIX[0].xyz * quad.x + INV_VIEW_MATRIX[1].xyz * quad.y) * width;
	VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;

	vec2 margin = min(uv, 1.0 - uv) * footprint;
	float boundary = smoothstep(0.14, 1.65, min(margin.x, margin.y));
	float terrain = smoothstep(0.55, 0.98, field.g);
	visibility = boundary * terrain * surface_fade * mix(1.0, 0.14 + gust_band * 0.86, gust_strength);
}

void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float body = 1.0 - smoothstep(0.38, 1.0, length(point * vec2(1.0, 1.28)));
	float facet = 1.0 - smoothstep(0.52, 0.94, abs(point.x) + abs(point.y));
	ALBEDO = mix(sand_color.rgb, sparkle_color.rgb, 0.22 + 0.78 * flash);
	EMISSION = sparkle_color.rgb * flash * 0.24;
	ALPHA = mix(body, facet, flash) * visibility * opacity * mix(0.50, 1.0, flash);
}
