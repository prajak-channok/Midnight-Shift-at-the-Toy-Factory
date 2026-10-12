shader_type spatial;
// Old toy-box wood with optional faded paint. Everything is procedural in object space:
// grain, flaking paint (reveals the bare wood), craquelure and grime.

uniform vec4 wood_dark : source_color = vec4(0.17, 0.09, 0.05, 1.0);
uniform vec4 wood_light : source_color = vec4(0.38, 0.21, 0.11, 1.0);
uniform vec4 paint_color : source_color = vec4(0.5, 0.1, 0.08, 1.0);
uniform vec4 grime_color : source_color = vec4(0.07, 0.05, 0.035, 1.0);
uniform float paint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float flake : hint_range(0.0, 1.0) = 0.35;
uniform vec3 grain_scale = vec3(70.0, 5.0, 70.0);
uniform vec3 pattern_offset = vec3(0.0);
uniform float crack_scale = 9.0;
uniform float grime_amount : hint_range(0.0, 1.0) = 0.5;

varying vec3 object_pos;


vec3 hash33(vec3 p) {
	p = vec3(dot(p, vec3(127.1, 311.7, 74.7)),
			dot(p, vec3(269.5, 183.3, 246.1)),
			dot(p, vec3(113.5, 271.9, 124.6)));
	return fract(sin(p) * 43758.5453123);
}


float value_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash33(i).x;
	float n100 = hash33(i + vec3(1.0, 0.0, 0.0)).x;
	float n010 = hash33(i + vec3(0.0, 1.0, 0.0)).x;
	float n110 = hash33(i + vec3(1.0, 1.0, 0.0)).x;
	float n001 = hash33(i + vec3(0.0, 0.0, 1.0)).x;
	float n101 = hash33(i + vec3(1.0, 0.0, 1.0)).x;
	float n011 = hash33(i + vec3(0.0, 1.0, 1.0)).x;
	float n111 = hash33(i + vec3(1.0, 1.0, 1.0)).x;
	return mix(mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
			mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y), f.z);
}


vec2 worley_edge(vec3 p) {
	vec3 ip = floor(p);
	vec3 fp = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	for (int k = -1; k <= 1; k++) {
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec3 g = vec3(float(i), float(j), float(k));
				vec3 o = hash33(ip + g);
				vec3 r = g + o - fp;
				float d = dot(r, r);
				if (d < f1) {
					f2 = f1;
					f1 = d;
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
	}
	return vec2(sqrt(f1), sqrt(f2));
}


void vertex() {
	object_pos = VERTEX;
}


void fragment() {
	vec3 p = object_pos + pattern_offset;

	float g = value_noise(p * grain_scale) * 0.65 + value_noise(p * grain_scale * 2.3 + 4.1) * 0.35;
	float rings = abs(fract(g * 5.0 + value_noise(p * 3.0) * 1.5) - 0.5) * 2.0;
	vec3 wood = mix(wood_dark.rgb, wood_light.rgb, smoothstep(0.15, 0.85, g));
	wood *= 0.78 + 0.35 * smoothstep(0.55, 0.95, rings);

	// long splits following the grain
	vec2 w = worley_edge(p * grain_scale * vec3(0.05, 0.012, 0.05) * crack_scale / 9.0);
	float split = 1.0 - smoothstep(0.01, 0.045, w.y - w.x);
	wood = mix(wood, grime_color.rgb, split * 0.85);

	// paint: flakes away in patches, crazes into small cells
	float m = value_noise(p * 22.0) * 0.55 + value_noise(p * 70.0) * 0.3 + value_noise(p * 6.0) * 0.15;
	float kept = 1.0 - smoothstep(1.0 - flake * 0.55 - 0.12, 1.0 - flake * 0.55, m);
	float paint_mask = paint_amount * kept;
	vec2 cw = worley_edge(p * crack_scale * 2.0);
	float craze = 1.0 - smoothstep(0.02, 0.07, cw.y - cw.x);
	vec3 paint = mix(paint_color.rgb, grime_color.rgb, craze * 0.6);
	paint = mix(paint, grime_color.rgb, smoothstep(0.55, 0.9, value_noise(p * 9.0 + 2.0)) * 0.45 * grime_amount);

	vec3 col = mix(wood, paint, paint_mask);
	float dirt = smoothstep(0.45, 0.85, value_noise(p * 4.0 + 9.0)) * grime_amount;
	col = mix(col, grime_color.rgb, dirt * 0.5);

	ALBEDO = col;
	ROUGHNESS = mix(0.72, 0.55, paint_mask);
	SPECULAR = 0.35;
}
