class_name JuiceParticles
extends RefCounted
## Fábrica de ráfagas GPUParticles2D con estética barroca (lacre, tinta, oro,
## polvo de pergamino). Usa ParticleProcessMaterial: turbulencia para que el
## polvo, la ceniza y las motas floten de forma orgánica, estelas en los
## destellos dorados y mezcla aditiva en el oro para que brille (sin HDR 2D
## global, que alteraba los colores de la interfaz).
##
## Las texturas se generan por código (círculo suave, esquirla, destello,
## moneda); si existe res://assets/vfx/particles/<nombre>.png se usa esa.

const TEX_DIR := "res://assets/vfx/particles/"

const WAX := Color(0.6, 0.06, 0.07)
const WAX_DARK := Color(0.3, 0.02, 0.03)
const INK := Color(0.06, 0.04, 0.06)
const GOLD := Color(1.0, 0.72, 0.28)
const GOLD_PALE := Color(1.0, 0.93, 0.7)
const PARCHMENT := Color(0.42, 0.3, 0.18)    # polvo sepia: se ve sobre el mapa
const ASH := Color(0.6, 0.57, 0.55)

static var _textures: Dictionary = {}


## Lista de tipos de ráfaga disponibles (para la demo y la documentación).
static func kinds() -> Array[StringName]:
	return [&"dust", &"wax", &"ink", &"gold", &"coins", &"glint", &"stamp"]


## Crea (sin añadir al árbol) un emisor one-shot del tipo `kind`.
## `amount_scale` permite rebajar la densidad (p. ej. con movimiento reducido).
## La duración total de la ráfaga queda en la meta "juice_life".
static func make_burst(kind: StringName, amount_scale: float = 1.0, speed_scale: float = 1.0) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	var m := ParticleProcessMaterial.new()
	p.process_material = m
	p.one_shot = true
	p.explosiveness = 0.92
	p.local_coords = false
	p.visibility_rect = Rect2(-500, -500, 1000, 1000)
	m.particle_flag_disable_z = true
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	m.emission_sphere_radius = 6.0
	m.spread = 180.0
	m.direction = Vector3(0, -1, 0)
	m.gravity = Vector3.ZERO
	match kind:
		&"dust":   # polvo de pergamino: lento, se arremolina y se disipa
			_setup(p, m, 22, 1.2, &"soft", 0.35, 0.9, Color(PARCHMENT, 0.75))
			_velocity(m, 20, 80, speed_scale)
			m.gravity = Vector3(0, -25, 0)
			_damping(m, 20, 40)
			m.emission_sphere_radius = 14.0
			_turbulence(m, 0.8, 1.6)
		&"wax":    # esquirlas de lacre: saltan, giran y caen
			_setup(p, m, 24, 0.95, &"shard", 0.7, 1.35, WAX, WAX_DARK)
			_velocity(m, 120, 280, speed_scale)
			m.gravity = Vector3(0, 560, 0)
			m.angular_velocity_min = -540; m.angular_velocity_max = 540
			m.angle_min = 0; m.angle_max = 360
		&"ink":    # salpicadura de tinta: sale rápida, frena en seco y se corre
			_setup(p, m, 26, 0.9, &"soft", 0.25, 0.9, INK)
			_velocity(m, 90, 260, speed_scale)
			_damping(m, 260, 420)
			_turbulence(m, 0.4, 3.0)
		&"gold":   # destellos dorados con estela: suben y titilan
			_setup(p, m, 48, 1.3, &"spark", 0.35, 0.9, GOLD_PALE, GOLD)
			_velocity(m, 110, 340, speed_scale)
			m.gravity = Vector3(0, -30, 0)
			_damping(m, 80, 160)
			m.angular_velocity_min = -180; m.angular_velocity_max = 180
			_turbulence(m, 0.5, 2.0)
			_additive(p)
			p.trail_enabled = true
			p.trail_lifetime = 0.18
			p.trail_sections = 6
		&"coins":  # monedas: saltan hacia arriba, giran y caen
			_setup(p, m, 12, 0.85, &"coin", 0.45, 0.75, GOLD)
			_velocity(m, 150, 250, speed_scale)
			m.spread = 35.0
			m.gravity = Vector3(0, 620, 0)
			m.angular_velocity_min = -360; m.angular_velocity_max = 360
		&"glint":  # brillo pequeño para invitar a abrir un lacre resuelto
			_setup(p, m, 7, 0.9, &"spark", 0.3, 0.65, GOLD_PALE, GOLD)
			_velocity(m, 10, 40, speed_scale)
			m.emission_sphere_radius = 22.0
			_additive(p)
		&"stamp":  # anillo de tinta al sellar/enviar
			_setup(p, m, 28, 0.6, &"soft", 0.18, 0.4, INK)
			_velocity(m, 150, 175, speed_scale)
			_damping(m, 300, 340)
			m.emission_sphere_radius = 2.0
		_:
			push_warning("JuiceParticles: tipo desconocido %s" % kind)
			_setup(p, m, 10, 0.6, &"soft", 0.2, 0.4, Color.WHITE)
	p.amount = maxi(1, int(round(p.amount * amount_scale)))
	p.set_meta(&"juice_life", p.lifetime * 1.4 + 0.3)
	return p


## Emisor continuo a pantalla completa (ceniza en la derrota, motas doradas en
## la victoria). `rect` es el área visible.
static func make_ambient(kind: StringName, rect: Rect2, amount_scale: float = 1.0) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	var m := ParticleProcessMaterial.new()
	p.process_material = m
	p.local_coords = false
	p.position = rect.get_center()
	p.visibility_rect = Rect2(-rect.size, rect.size * 2.0)
	m.particle_flag_disable_z = true
	m.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	m.emission_box_extents = Vector3(rect.size.x * 0.5, rect.size.y * 0.5, 1)
	match kind:
		&"ash":
			_setup(p, m, 90, 9.0, &"shard", 0.3, 0.75, ASH)
			m.direction = Vector3(0.3, 1, 0)
			m.spread = 25
			_velocity(m, 15, 45, 1.0)
			m.gravity = Vector3(4, 8, 0)
			m.angular_velocity_min = -60; m.angular_velocity_max = 60
			_turbulence(m, 1.2, 0.6)
		&"motes":
			_setup(p, m, 110, 8.0, &"spark", 0.25, 0.6, GOLD_PALE, GOLD)
			m.direction = Vector3(0, -1, 0)
			m.spread = 40
			_velocity(m, 8, 30, 1.0)
			m.gravity = Vector3(0, -6, 0)
			_turbulence(m, 1.0, 0.5)
			_additive(p)
		_:
			push_warning("JuiceParticles: ambiente desconocido %s" % kind)
	p.preprocess = p.lifetime
	p.amount = maxi(1, int(round(p.amount * amount_scale)))
	return p


# --- Configuración común ------------------------------------------------------

static func _setup(p: GPUParticles2D, m: ParticleProcessMaterial, amount: int, lifetime: float,
		tex: StringName, scale_min: float, scale_max: float, color: Color,
		color_end: Color = Color(0, 0, 0, 0)) -> void:
	p.amount = amount
	p.lifetime = lifetime
	p.texture = texture(tex)
	m.lifetime_randomness = 0.35
	m.scale_min = scale_min
	m.scale_max = scale_max
	var end := color if color_end.a == 0.0 else color_end
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(end, 0.0))
	ramp.add_point(0.6, Color(end, 0.85 * color.a))
	var ramp_tex := GradientTexture1D.new()
	ramp_tex.gradient = ramp
	ramp_tex.use_hdr = true
	m.color_ramp = ramp_tex
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(1, 0.5))
	var curve_tex := CurveTexture.new()
	curve_tex.curve = curve
	m.scale_curve = curve_tex


static func _velocity(m: ParticleProcessMaterial, vmin: float, vmax: float, speed_scale: float) -> void:
	m.initial_velocity_min = vmin * speed_scale
	m.initial_velocity_max = vmax * speed_scale


static func _damping(m: ParticleProcessMaterial, dmin: float, dmax: float) -> void:
	m.damping_min = dmin
	m.damping_max = dmax


## Mezcla aditiva: el oro "emite luz" sobre el mapa sin necesidad de glow.
static func _additive(p: GPUParticles2D) -> void:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = mat


static func _turbulence(m: ParticleProcessMaterial, strength: float, noise_scale: float) -> void:
	m.turbulence_enabled = true
	m.turbulence_noise_strength = strength
	m.turbulence_noise_scale = noise_scale
	m.turbulence_influence_min = 0.05
	m.turbulence_influence_max = 0.2


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


static func clear_cache() -> void:
	_textures.clear()
