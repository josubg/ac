shader_type canvas_item;
// Postprocesado del mundo (mapa y edificios). Va en el lienzo del mapa, por
// encima de él y por debajo de la interfaz, así que nunca toca los textos.
//  - Ondas de tinta: hasta 4 anillos que deforman el mapa (sellos, umbrales).
//  - Desaturación / virado sepia: el Madrid "se apaga" cuando sube el Descontento
//    o cuando el Rey se enfada.
//  - Viñeta de Descontento (tinte en los bordes, con latido opcional).
//  - Grano de papel muy sutil.

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform vec2 aspect = vec2(1.7778, 1.0);

// x, y en SCREEN_UV; z = edad 0..1; w = fuerza (0 = inactiva)
uniform vec4 ripples[4];
uniform float ripple_radius = 0.22;

uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float sepia : hint_range(0.0, 1.0) = 0.0;

uniform vec4 tint : source_color = vec4(0.35, 0.03, 0.02, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

uniform float grain : hint_range(0.0, 0.2) = 0.03;
uniform float grain_speed = 1.0; // 0 = grano estático (movimiento reducido)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	float ink = 0.0;
	for (int i = 0; i < 4; i++) {
		vec4 r = ripples[i];
		if (r.w <= 0.0) continue;
		vec2 d = (uv - r.xy) * aspect;
		float dist = length(d);
		float radius = r.z * ripple_radius;
		float band = 1.0 - smoothstep(0.0, 0.035, abs(dist - radius));
		float fade = (1.0 - r.z) * (1.0 - r.z);
		uv -= normalize(d + 1e-5) / aspect * band * fade * r.w * 0.018;
		ink += band * fade * r.w;
	}
	vec3 col = textureLod(screen_texture, uv, 0.0).rgb;

	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(lum), desaturate);
	vec3 sep = vec3(lum * 1.07, lum * 0.88, lum * 0.66);
	col = mix(col, sep, sepia);

	// Anillo de tinta: oscurece un poco la banda de la onda.
	col *= 1.0 - clamp(ink, 0.0, 1.0) * 0.22;

	vec2 v = (SCREEN_UV - 0.5) * vec2(1.6, 1.0);
	float edge = smoothstep(0.3, 0.9, length(v));
	float beat = 1.0 - pulse * 0.35 * (0.5 + 0.5 * sin(TIME * 2.4));
	col = mix(col, tint.rgb, edge * intensity * beat * 0.9);

	float g = hash(floor(SCREEN_UV * vec2(960.0, 540.0)) + floor(TIME * 12.0 * grain_speed)) - 0.5;
	col += g * grain;

	COLOR = vec4(col, 1.0);
}
