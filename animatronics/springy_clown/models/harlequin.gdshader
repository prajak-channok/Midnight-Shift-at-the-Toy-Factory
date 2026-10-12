shader_type spatial;
// Faded harlequin cloth wrapped around a Y-axis surface of revolution, with stitched seams and stains.

uniform vec4 color_a : source_color = vec4(0.55, 0.1, 0.09, 1.0);
uniform vec4 color_b : source_color = vec4(0.12, 0.34, 0.33, 1.0);
uniform vec4 stitch_color : source_color = vec4(0.05, 0.04, 0.03, 1.0);
uniform float around = 6.0;
uniform float along = 14.0;
uniform vec3 pattern_offset = vec3(0.0);

varying vec3 object_pos;


float hash(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}


float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}


void vertex() {
	object_pos = VERTEX;
}


void fragment() {
	vec3 p = object_pos + pattern_offset;
	float u = atan(p.x, p.z) / 6.2831853 * around;
	float v = p.y * along;
	float a = u + v;
	float b = u - v;
	float checker = mod(floor(a) + floor(b), 2.0);
	vec3 col = mix(color_a.rgb, color_b.rgb, checker);

	float edge = max(abs(fract(a) - 0.5), abs(fract(b) - 0.5));
	float seam = smoothstep(0.455, 0.49, max(abs(fract(a) - 0.5), abs(fract(b) - 0.5)));
	// weave and fade
	float weave = value_noise(p * 160.0) * 0.18;
	float fade = value_noise(p * 7.0);
	col *= 0.75 + weave + 0.25 * fade;
	col = mix(col, vec3(0.45, 0.4, 0.32), smoothstep(0.6, 0.95, value_noise(p * 12.0 + 3.0)) * 0.55);
	col = mix(col, stitch_color.rgb, seam * 0.9);

	ALBEDO = col;
	ROUGHNESS = 0.95;
	SPECULAR = 0.1;
}
