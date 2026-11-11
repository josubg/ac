shader_type canvas_item;
// Viñeta para el Descontento y los avisos: oscurece y tiñe los bordes, deja el
// centro limpio. Compatible con Compatibility/WebGL2 (solo aritmética y TIME).

uniform vec4 tint : source_color = vec4(0.35, 0.03, 0.02, 1.0);
uniform float intensity : hint_range(0.0, 1.0) = 0.0;
// 0 = estática; > 0 = late lentamente (desactivado con "reducir movimiento").
uniform float pulse : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV - 0.5;
	uv.x *= 1.6;
	float d = length(uv);
	float edge = smoothstep(0.3, 0.9, d);
	float beat = 1.0 - pulse * 0.35 * (0.5 + 0.5 * sin(TIME * 2.4));
	COLOR = vec4(tint.rgb, edge * intensity * beat * 0.9);
}
