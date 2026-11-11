shader_type canvas_item;
// Edificios sobre el plano: contorno de tinta sepia (como el grabado de Mancinelli)
// y un ligero virado cálido para que casen con el papel del mapa.

uniform vec4 tinta : source_color = vec4(0.16, 0.09, 0.05, 0.9);
uniform float grosor = 5.0; // en píxeles de la textura
uniform vec4 tono : source_color = vec4(1.0, 0.97, 0.91, 1.0);
uniform float saturacion = 1.15;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = TEXTURE_PIXEL_SIZE * grosor;
	float a = 0.0;
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 0.5235988;
		a = max(a, texture(TEXTURE, UV + vec2(cos(ang), sin(ang)) * px).a);
	}
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 col = mix(vec3(l), c.rgb, saturacion) * tono.rgb;
	vec4 contorno = vec4(tinta.rgb, a * tinta.a);
	COLOR = mix(contorno, vec4(col, c.a), c.a);
}
