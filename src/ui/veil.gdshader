shader_type canvas_item;
// Voile des ecrans modaux : flou leger de la scene + teinte de phase + vignette.
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec4 tint : source_color = vec4(1.0, 0.7, 0.4, 1.0);
uniform vec4 edge : source_color = vec4(0.1, 0.05, 0.1, 1.0);
uniform float amount = 0.4;
uniform float brightness = 0.78;
uniform float blur = 2.6;
uniform float vignette = 0.4;

void fragment() {
	vec3 col = textureLod(screen_tex, SCREEN_UV, blur).rgb;
	float lum = dot(col, vec3(0.3, 0.55, 0.15));
	col = mix(col, vec3(lum), 0.12);
	col = mix(col, col * tint.rgb * 1.25 + tint.rgb * 0.06, amount) * brightness;
	float v = smoothstep(0.3, 0.95, length((SCREEN_UV - 0.5) * vec2(1.25, 1.0)) * 1.35);
	col = mix(col, edge.rgb, v * vignette);
	COLOR = vec4(col, 1.0);
}
