shader_type canvas_item;
render_mode unshaded;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
	float glyph_alpha = COLOR.a;
	vec3 background = textureLod(scene_color, SCREEN_UV, 0.0).rgb;
	float brightness = dot(background, vec3(0.2126, 0.7152, 0.0722));
	// Push inverted grayscale to black or white: a simple inversion vanishes
	// against middle gray. Sample per fragment so only the glyph changes color.
	float contrast = 1.0 - step(0.5, brightness);
	COLOR = vec4(vec3(contrast), glyph_alpha);
}
