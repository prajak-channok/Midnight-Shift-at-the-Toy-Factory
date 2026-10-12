shader_type spatial;
// Cracked porcelain glaze. Cracks are procedural (3D cellular noise in object space),
// so they stay glued to each mesh while it is animated and need no UVs or textures.

uniform vec4 glaze_color : source_color = vec4(0.94, 0.92, 0.87, 1.0);
uniform vec4 bisque_color : source_color = vec4(0.6, 0.56, 0.48, 1.0); // bare clay showing through chipped glaze
uniform vec4 crack_color : source_color = vec4(0.04, 0.03, 0.025, 1.0);
uniform vec4 grime_color : source_color = vec4(0.46, 0.4, 0.31, 1.0);
uniform vec3 pattern_offset = vec3(0.0); // different value per material so parts do not share one crack pattern
uniform float fine_scale = 22.0; // craquelure frequency
uniform float fracture_scale = 6.0; // large fracture frequency
uniform float fine_width : hint_range(0.0, 0.5) = 0.05;
uniform float fracture_width : hint_range(0.0, 0.5) = 0.03;
uniform float fine_strength : hint_range(0.0, 1.0) = 0.5;
uniform float fracture_strength : hint_range(0.0, 1.0) = 1.0;
uniform float chip_amount : hint_range(0.0, 1.0) = 0.04;
uniform float grime_amount : hint_range(0.0, 1.0) = 0.35;
uniform float glaze_roughness : hint_range(0.0, 1.0) = 0.16;

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


// x = distance to nearest feature point, y = distance to second nearest, z = random id of the nearest cell.
vec3 worley(vec3 p) {
	vec3 ip = floor(p);
	vec3 fp = fract(p);
	float f1 = 8.0;
	float f2 = 8.0;
	float id = 0.0;
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
					id = o.x;
				} else if (d < f2) {
					f2 = d;
				}
			}
		}
	}
	return vec3(sqrt(f1), sqrt(f2), id);
}


void vertex() {
	object_pos = VERTEX;
}


void fragment() {
	vec3 p = object_pos + pattern_offset;
	// Wobble the lookup so cracks wander instead of forming straight polygon edges.
	vec3 q = p + 0.018 * (vec3(value_noise(p * 31.0), value_noise(p * 31.0 + 7.3), value_noise(p * 31.0 + 13.1)) - 0.5) * 2.0;

	vec3 big = worley(q * fracture_scale);
	vec3 fine = worley(q * fine_scale);

	float big_edge = big.y - big.x;
	float fine_edge = fine.y - fine.x;
	float aa_big = fwidth(big_edge);
	float aa_fine = fwidth(fine_edge);

	float fracture = (1.0 - smoothstep(fracture_width - aa_big, fracture_width + aa_big, big_edge)) * fracture_strength;
	float crazed_region = step(0.3, big.z); // craquelure only covers some of the large cells
	float craquelure = (1.0 - smoothstep(fine_width - aa_fine, fine_width + aa_fine, fine_edge)) * fine_strength * crazed_region;
	float crack = clamp(max(fracture, craquelure), 0.0, 1.0);

	float halo = (1.0 - smoothstep(0.0, fracture_width * 6.0, big_edge)) * 0.5 * fracture_strength;
	float patchy = value_noise(p * 14.0) * 0.6 + value_noise(p * 40.0) * 0.4;
	float grime = clamp(halo + smoothstep(0.55, 0.9, patchy) * 0.7, 0.0, 1.0) * grime_amount;

	float chip = step(1.0 - chip_amount, fine.z);

	vec3 col = glaze_color.rgb;
	col = mix(col, grime_color.rgb, grime);
	col = mix(col, bisque_color.rgb, chip);
	col = mix(col, crack_color.rgb, crack);

	ALBEDO = col;
	ROUGHNESS = mix(glaze_roughness, 0.9, max(chip, crack));
	SPECULAR = mix(0.85, 0.15, max(chip, crack));
}
