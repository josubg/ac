shader_type canvas_item;
// Transición entre escenas: una mancha de tinta que cubre la pantalla y se
// retira desde el centro con bordes irregulares (ruido fbm). progress 1 =
// pantalla cubierta, 0 = limpia.

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink_color : source_color = vec4(0.07, 0.045, 0.03, 1.0);
uniform vec4 edge_color : source_color = vec4(0.32, 0.18, 0.08, 1.0);
uniform vec2 aspect = vec2(1.7778, 1.0);
uniform float seed = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
	           mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}
float fbm(vec2 p) {
	float v = 0.0, a = 0.5;
	for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.03; a *= 0.5; }
	return v;
}

void fragment() {
	vec2 p = (UV - 0.5) * aspect;
	// Distancia al centro deformada por ruido: borde de mancha que se corre.
	float field = length(p) / length(aspect * 0.5) + (fbm(p * 5.0 + seed) - 0.5) * 0.55;
	float t = 1.0 - progress;               // radio limpio que va creciendo
	float r = t * 1.45 - 0.2;
	float a = smoothstep(r - 0.015, r + 0.015, field);
	float rim = smoothstep(r - 0.06, r, field) * (1.0 - smoothstep(r, r + 0.05, field));
	vec3 col = mix(ink_color.rgb, edge_color.rgb, rim * 0.8);
	COLOR = vec4(col, a * ink_color.a);
}
