shader_type spatial;
render_mode unshaded, cull_back;

uniform vec4 base_color : source_color = vec4(1.0);
uniform float soil_height = 0.234;
uniform float canopy_scale = 1.0;
uniform float coverage = 1.0;
uniform bool inverse_coverage = false;
uniform int outline_cut = 0;
uniform float pot_height = 0.26;
uniform float sway_time = 0.0;
varying float original_height;

void vertex() {
	original_height = VERTEX.y;
	float height = max(0.0, VERTEX.y - soil_height);
	VERTEX.xz *= mix(0.65, 1.0, canopy_scale);
	VERTEX.y = soil_height + (VERTEX.y - soil_height) * canopy_scale;
	VERTEX.x += sin(sway_time * 2.0 + height * 5.0) * height * 0.008;
}

void fragment() {
	if (outline_cut == 1 && original_height > pot_height + 0.003) { discard; }
	if (outline_cut == 2 && original_height <= pot_height + 0.003) { discard; }
	// Opaque screen-door dissolve avoids transparent double surfaces and sorting.
	float noise = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
	if ((!inverse_coverage && noise >= coverage) || (inverse_coverage && noise < coverage)) { discard; }
	ALBEDO = base_color.rgb;
}
