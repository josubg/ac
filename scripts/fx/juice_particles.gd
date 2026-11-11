class_name JuiceParticles
extends RefCounted
## Fábrica de ráfagas CPUParticles2D con estética barroca (lacre, tinta, oro,
## polvo de pergamino). CPUParticles2D funciona igual en Compatibility/WebGL2,
## que es lo que usa la build web.
##
## Las texturas se generan por código (círculo suave, esquirla, destello) para
## no depender de ficheros; si existe res://assets/vfx/particles/<nombre>.png se
## usa esa en su lugar.

const TEX_DIR := "res://assets/vfx/particles/"

const WAX := Color(0.55, 0.06, 0.07)
const WAX_DARK := Color(0.32, 0.03, 0.04)
const INK := Color(0.07, 0.05, 0.06)
const GOLD := Color(1.0, 0.82, 0.38)
const GOLD_PALE := Color(1.0, 0.95, 0.75)
const PARCHMENT := Color(0.42, 0.3, 0.18)   # polvo sepia: se ve sobre el mapa
const ASH := Color(0.55, 0.52, 0.5)

static var _textures: Dictionary = {}


## Lista de tipos de ráfaga disponibles (para la demo y la documentación).
static func kinds() -> Array[StringName]:
	return [&"dust", &"wax", &"ink", &"gold", &"coins", &"glint", &"stamp"]


## Crea (sin añadir al árbol) un emisor one-shot del tipo `kind`.
## `amount_scale` permite rebajar la densidad (p. ej. con movimiento reducido).
static func make_burst(kind: StringName, amount_scale: float = 1.0, speed_scale: float = 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 6.0
	p.spread = 180.0
	p.direction = Vector2.UP
	match kind:
		&"dust":   # polvo de pergamino: lento, flota y se disipa
			_setup(p, 16, 0.9, &"soft", 0.35, 0.8, Color(PARCHMENT, 0.7))
			_velocity(p, 20, 70, speed_scale)
			p.gravity = Vector2(0, -25)
			p.damping_min = 20; p.damping_max = 40
			p.emission_sphere_radius = 14.0
		&"wax":    # esquirlas de lacre: saltan y caen
			_setup(p, 22, 0.9, &"shard", 0.7, 1.3, WAX, WAX_DARK)
			_velocity(p, 120, 260, speed_scale)
			p.gravity = Vector2(0, 520)
			p.angular_velocity_min = -540; p.angular_velocity_max = 540
			p.angle_min = 0; p.angle_max = 360
		&"ink":    # salpicadura de tinta: sale rápida y frena en seco
			_setup(p, 18, 0.7, &"soft", 0.2, 0.75, INK)
			_velocity(p, 90, 240, speed_scale)
			p.damping_min = 260; p.damping_max = 420
			p.gravity = Vector2.ZERO
		&"gold":   # destellos dorados: suben un poco y titilan
			_setup(p, 40, 1.2, &"spark", 0.35, 0.9, GOLD_PALE, GOLD)
			_velocity(p, 90, 300, speed_scale)
			p.gravity = Vector2(0, -30)
			p.damping_min = 60; p.damping_max = 120
			p.angular_velocity_min = -180; p.angular_velocity_max = 180
		&"coins":  # monedas: saltan hacia arriba y caen
			_setup(p, 10, 0.8, &"coin", 0.45, 0.7, GOLD)
			_velocity(p, 140, 230, speed_scale)
			p.spread = 35.0
			p.gravity = Vector2(0, 600)
		&"glint":  # brillo pequeño para invitar a abrir un lacre resuelto
			_setup(p, 6, 0.8, &"spark", 0.3, 0.6, GOLD_PALE, GOLD)
			_velocity(p, 10, 40, speed_scale)
			p.emission_sphere_radius = 22.0
			p.gravity = Vector2.ZERO
		&"stamp":  # anillo de tinta al sellar/enviar
			_setup(p, 22, 0.55, &"soft", 0.18, 0.35, INK)
			_velocity(p, 150, 170, speed_scale)
			p.damping_min = 300; p.damping_max = 340
			p.gravity = Vector2.ZERO
			p.emission_sphere_radius = 2.0
		_:
			push_warning("JuiceParticles: tipo desconocido %s" % kind)
			_setup(p, 10, 0.6, &"soft", 0.2, 0.4, Color.WHITE)
	p.amount = maxi(1, int(round(p.amount * amount_scale)))
	return p


## Emisor continuo a pantalla completa (ceniza en la derrota, motas doradas en
## la victoria). `rect` es el área visible.
static func make_ambient(kind: StringName, rect: Rect2, amount_scale: float = 1.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.local_coords = false
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.position = rect.get_center()
	p.emission_rect_extents = rect.size * 0.5
	match kind:
		&"ash":
			_setup(p, 70, 9.0, &"shard", 0.3, 0.7, ASH)
			p.direction = Vector2(0.3, 1)
			p.spread = 25
			_velocity(p, 15, 45, 1.0)
			p.gravity = Vector2(4, 8)
			p.angular_velocity_min = -60; p.angular_velocity_max = 60
		&"motes":
			_setup(p, 80, 8.0, &"spark", 0.25, 0.6, GOLD_PALE, GOLD)
			p.direction = Vector2.UP
			p.spread = 40
			_velocity(p, 8, 30, 1.0)
			p.gravity = Vector2(0, -6)
		_:
			push_warning("JuiceParticles: ambiente desconocido %s" % kind)
	p.preprocess = p.lifetime
	p.amount = maxi(1, int(round(p.amount * amount_scale)))
	return p


# --- Configuración común ------------------------------------------------------

static func _setup(p: CPUParticles2D, amount: int, lifetime: float, tex: StringName,
		scale_min: float, scale_max: float, color: Color, color_end: Color = Color(0, 0, 0, 0)) -> void:
	p.amount = amount
	p.lifetime = lifetime
	p.lifetime_randomness = 0.35
	p.texture = texture(tex)
	p.scale_amount_min = scale_min
	p.scale_amount_max = scale_max
	var end := color if color_end.a == 0.0 else color_end
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(end, 0.0))
	ramp.add_point(0.6, Color(end, 0.85))
	p.color_ramp = ramp
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1, 0.5))
	p.scale_amount_curve = curve


static func _velocity(p: CPUParticles2D, vmin: float, vmax: float, speed_scale: float) -> void:
	p.initial_velocity_min = vmin * speed_scale
	p.initial_velocity_max = vmax * speed_scale


# --- Texturas procedurales ----------------------------------------------------

static func texture(tex: StringName) -> Texture2D:
	if _textures.has(tex):
		return _textures[tex]
	var t: Texture2D = null
	var path := "%s%s.png" % [TEX_DIR, tex]
	if ResourceLoader.exists(path):
		t = load(path)
	else:
		match tex:
			&"shard": t = _shard_texture()
			&"spark": t = _spark_texture()
			&"coin":  t = _coin_texture()
			_:        t = _soft_texture()
	_textures[tex] = t
	return t


static func _soft_texture() -> Texture2D:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var d := (Vector2(x + 0.5, y + 0.5) - c).length() / (size * 0.5)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a * (3.0 - 2.0 * a)))
	return ImageTexture.create_from_image(img)


static func _spark_texture() -> Texture2D:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var v := Vector2(x + 0.5, y + 0.5) - c
			var d := v.length() / (size * 0.5)
			# Estrella de cuatro puntas + halo.
			var rays := maxf(0.0, 1.0 - absf(v.x) / 1.6) * maxf(0.0, 1.0 - d) \
				+ maxf(0.0, 1.0 - absf(v.y) / 1.6) * maxf(0.0, 1.0 - d)
			var halo := pow(clampf(1.0 - d, 0.0, 1.0), 3.0)
			img.set_pixel(x, y, Color(1, 1, 1, clampf(rays + halo, 0.0, 1.0)))
	return ImageTexture.create_from_image(img)


static func _coin_texture() -> Texture2D:
	var size := 24
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) * 0.5
	for y in size:
		for x in size:
			var d := (Vector2(x + 0.5, y + 0.5) - c).length() / (size * 0.5)
			var a := clampf((1.0 - d) * 6.0, 0.0, 1.0)
			var rim := 0.75 if d > 0.72 else 1.0
			img.set_pixel(x, y, Color(rim, rim, rim, a))
	return ImageTexture.create_from_image(img)


static func _shard_texture() -> Texture2D:
	var size := 20
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1640
	var pts := PackedVector2Array()
	for k in 5:
		var ang := TAU * k / 5.0 + rng.randf_range(-0.4, 0.4)
		pts.append(Vector2(size, size) * 0.5 + Vector2.RIGHT.rotated(ang) * rng.randf_range(4.0, 9.5))
	for y in size:
		for x in size:
			var inside := Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts)
			img.set_pixel(x, y, Color(1, 1, 1, 1.0 if inside else 0.0))
	return ImageTexture.create_from_image(img)
