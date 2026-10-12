shader_type spatial;
// Coil spring. The mesh is built at its natural height; "stretch" spreads the coils out vertically
// (the wire keeps its round cross-section) and "bend" pushes the upper coils sideways.

uniform float stretch = 1.0;
uniform vec2 bend = vec2(0.0);
uniform float spring_height = 0.3;
uniform vec4 steel_color : source_color = vec4(0.5, 0.5, 0.52, 1.0);
uniform vec4 rust_color : source_color = vec4(0.36, 0.17, 0.07, 1.0);

varying float along;


float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}


void vertex() {
	along = COLOR.r;
	VERTEX.y += (stretch - 1.0) * along * spring_height;
	VERTEX.xz += bend * along * along;
}


void fragment() {
	float rust = smoothstep(0.35, 0.8, hash(floor(UV * vec2(3.0, 9.0))) * 0.7 + hash(floor(UV * vec2(11.0, 31.0))) * 0.3);
	ALBEDO = mix(steel_color.rgb, rust_color.rgb, rust);
	METALLIC = mix(0.85, 0.3, rust);
	ROUGHNESS = mix(0.35, 0.85, rust);
}
